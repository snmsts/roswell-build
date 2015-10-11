(ros:ignore-shebang)
(mapc (lambda (x)
        (ignore-errors (load (format nil "~A/~A~A" (uiop:getenv "ROSWELL_INSTALL_DIR") "share/common-lisp/source/roswell/" x)))
        (ignore-errors (load (merge-pathnames (format nil "lisp/~A" x)
                                              (make-pathname :defaults (ros:roswell '("roswell-internal-use" "which" "ros") :string t)
                                                             :name nil
                                                             :type nil)))))
      '("install.lisp" "install-sbcl.lisp"))

(defparameter *version* (or *version* (first (split-sequence:split-sequence #\newline (ros:roswell '("list" "versions" "sbcl"))))))

(defun extract-sbcl ()
  (let ((version *version*)
        (home (if (find :win32 *features*)
                  (format nil "~A~A" (uiop:getenv"HOMEDRIVE") (uiop:getenv "HOMEPATH"))
                  "~")))
    (format t "detected version is ~A~%" version)
    (uiop:run-program (format nil "ros install sbcl/~A --without-install" version) :output :interactive)
    (ensure-directories-exist (format nil "~A/src/" home))
    (unless (probe-file (format nil "~A/src/sbcl-~A/" home version))
      (uiop:run-program (format nil "ros roswell-internal-use tar -xf ~A -C ~A"
                                (native-namestring (format nil "~A/.roswell/archives/sbcl-~A.tar.gz" home version))
                                (native-namestring (format nil "~A/src/" home))) :output :interactive)
      (uiop:run-program (format nil "~A ~A ~A"
                                (if (find :win32 *features*)"ren" "mv")
                                (native-namestring (format nil "~A/src/sbcl-sbcl-~A/" home version))
                                (native-namestring (format nil "~A/src/sbcl-~A/" home version)))
                        :output :interactive))))

(defun build-sbcl (arch)
  (let* ((version *version*)
         (path (format nil "~~/src/sbcl-~A/" version))
         (out (make-instance 'ros.install::count-line-stream)))
    (uiop:chdir path)
    (with-open-file (out (merge-pathnames "version.lisp-expr" path) :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create)
      (format out "~S" version))
    (uiop:run-program `("bash" "make.sh" "--xc-host=ros -L sbcl-bin run"
                               ,(format nil "--arch=~A" arch)
                               #+darwin "--with-sb-thread"
                               #-win32 "--with-sb-core-compression")
                      :output out)))

(defun archive-sbcl (arch)
  (let* ((version *version*)
         (archive-name (format nil "sbcl-~A-~A-~A" version arch (uname)))
         (archive-dir (merge-pathnames (format nil "tmp/~A/" archive-name) (user-homedir-pathname))))
    (ensure-directories-exist archive-dir)
    (let ((from (truename (format nil "~~/src/sbcl-~A/" version)))
          (to archive-dir))
      (flet ((copy (from to)
               (ensure-directories-exist to)
               (uiop:copy-file from to))
             (touch (file)
               (ensure-directories-exist file)
               (with-open-file (i file
                                  :direction :probe
                                  :if-does-not-exist :create))))
        (loop :for (method . elts) :in ros.install::*sbcl-copy-files*
           :do (case method
                 (:copy (loop for elt in elts
                           do (if (and (stringp elt) (wild-pathname-p elt))
                                  (mapc (lambda (x)
                                          (copy x (make-pathname :defaults x
                                                                 :directory (append (pathname-directory to)
                                                                                    (nthcdr (length (pathname-directory from))
                                                                                            (pathname-directory x))))))
                                        (reverse (directory (merge-pathnames elt from))))
                                  (if (consp elt)
                                      (progn
                                        (copy (merge-pathnames (first elt) from)
                                              (merge-pathnames (first elt) to))
                                        (sb-posix:chmod (merge-pathnames (first elt) to) (second elt)))
                                      (copy (merge-pathnames elt from)
                                            (merge-pathnames elt to))))))
                 (:touch (loop for elt in elts
                            do (if (functionp elt)
                                   (funcall elt from to #'touch))))))
        (uiop:chdir (merge-pathnames "../" archive-dir))
        (uiop:run-program `("tar""cjf" ,(format nil "~A.tar.bz2" archive-name) ,archive-name) :output :interactive)
        (truename (merge-pathnames (format nil "../~A.tar.bz2" archive-name) archive-dir))))))
