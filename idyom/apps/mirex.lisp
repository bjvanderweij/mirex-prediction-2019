#!/usr/bin/sbcl --script

#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
				       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(let ((idyom-root (sb-ext:posix-getenv "IDYOM_ROOT")))
  (defvar *idyom-root* (or idyom-root
			   "/home/bastiaan/projects/idyom/")))

(let ((*standard-output* *error-output*)) ; re-route standard output to error
  (push *idyom-root* asdf:*central-registry*)
  (ql:quickload "idyom"))

;;(cl:in-package #:commands)

(defun connect-to-db (&optional	(database (sb-ext:posix-getenv "IDYOM_DB")))
  (clsql:connect (list database) :if-exists :old :database-type :sqlite3))
