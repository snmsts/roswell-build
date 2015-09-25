(ros:ignore-shebang)
(mapc (lambda (x)(load (format nil "~A/~A~A" (uiop:getenv "ROSWELL_INSTALL_DIR") "share/common-lisp/source/roswell/"x)))
      '("install.lisp" "install-sbcl.lisp"))

(defparameter *version* (first (split-sequence:split-sequence #\newline (ros:roswell '("list" "versions" "sbcl")))))

(defun extract-sbcl ()
  (let ((version *version*))
    (format t "detected version is ~A~%" version)
    (uiop:run-program (format nil "ros install sbcl/~A --without-install" version) :output :interactive)
    (ensure-directories-exist "~/.roswell/src/")
    (unless (probe-file (format nil "~~/.roswell/src/sbcl-~A/" version))
      (uiop:run-program (format nil "tar xf ~~/.roswell/archives/sbcl-~A.tar.gz -C ~~/.roswell/src/" version) :output :interactive)
      (uiop:run-program (format nil "mv ~~/.roswell/src/sbcl-sbcl-~A ~~/.roswell/src/sbcl-~A" version version) :output :interactive))))

(defun build-sbcl (arch)
  (let* ((version *version*)
         (path (format nil "~~/.roswell/src/sbcl-~A/" version))
         (*standard-output* (make-instance 'ros.install::count-line-stream)))
    (uiop:chdir path)
    (with-open-file (out (merge-pathnames "version.lisp-expr" path) :direction :output :if-exists :overwrite)
      (format out "~S" version))
    (uiop:run-program `("bash" "make.sh" "--xc-host=ros -L sbcl-bin run"
                               ,(format nil "--arch=~A" arch)) :output t)))

(defun archive-sbcl (arch)
  ;;not yet
  (let* ((version *version*)
         (archive-dir (merge-pathnames (format nil "tmp/sbcl-~A-~A-~A/" version arch (uname)) (homedir))))
    (ensure-directories-exist archive-dir)))
