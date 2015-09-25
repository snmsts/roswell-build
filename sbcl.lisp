(ros:ignore-shebang)
(mapc (lambda (x)(load (format nil "~A/~A~A" (uiop:getenv "ROSWELL_INSTALL_DIR") "share/common-lisp/source/roswell/"x)))
      '("install.lisp" "install-sbcl.lisp"))

(defparameter *version* (first (split-sequence:split-sequence #\newline (ros:roswell '("list" "versions" "sbcl")))))

(defun extract-sbcl ()
  (let ((version *version*))
    (format t "detected version is ~A~%" version)
    (uiop:run-program (format nil "ros install sbcl/~A --without-install" version) :output :interactive)
    (ensure-directories-exist "~/src/")
    (unless (probe-file (format nil "~~/src/sbcl-~A/" version))
      (uiop:run-program (format nil "tar xf ~~/.roswell/archives/sbcl-~A.tar.gz -C ~~/src/" version) :output :interactive)
      (uiop:run-program (format nil "mv ~~/src/sbcl-sbcl-~A ~~/src/sbcl-~A" version version) :output :interactive))))

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
  ;;not yet
  (let* ((version *version*)
         (archive-name (format nil "sbcl-~A-~A-~A" version arch (uname)))
         (archive-dir (merge-pathnames (format nil "tmp/~A/" archive-name) (homedir))))
    (ensure-directories-exist archive-dir)))
