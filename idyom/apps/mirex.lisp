#!/usr/bin/sbcl --script 

#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
				       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(let* ((argv sb-ext:*posix-argv*)
       (cmd (car argv))
       (args (cdr argv))
       (root (car args)))
  (when (null root)
    (let ((*debugger-hook*
	   (lambda (c v) (format t "~a~%" c) (abort c))))
      (error "USAGE: ~a <mirex-root-dir>" cmd)))
  (defvar *root* root)
  (let ((idyom-root (format nil "~a/idyom/" root))
	(*standard-output* *error-output*)) ; re-route standard output to error
    (defvar *idyom-root* idyom-root)
    (push idyom-root asdf:*central-registry*)
    (ql:quickload "idyom")))


(defun mirex (training-set-id primes-set-id basic-attributes attributes
	      &key (iterations 100) (duration 10) (units 4)
		(output-dir "results")
		use-ltms-cache?
		(method :metropolis) (models :both+))
  (let* ((primes (md:get-event-sequences (list primes-set-id)))
	 (timebase (md:timebase (first primes)))
	 (unit-duration (/ timebase units))
	 (event-density (event-density primes unit-duration))
	 (continuation-length (* event-density duration))
	 (training-set (md:get-event-sequences (list training-set-id)))
	 (viewpoints (viewpoints:get-viewpoints attributes))
	 (basic-viewpoints
	  (viewpoints:get-basic-viewpoints basic-attributes training-set))
	 (ltms
	  (resampling:get-long-term-models viewpoints training-set nil
					   training-set-id
					   (format nil "~Agen" training-set-id)
					   nil nil nil use-ltms-cache?))
	 (mvs (mvs:make-mvs basic-viewpoints viewpoints ltms)))
    (format
     t "Timebase: ~$. Unit-duration ~$. Event-density ~$. Continuation-length ~$.~%"
     timebase unit-duration event-density continuation-length)
    (mvs:set-models models)
    (dolist (prime primes)
      (format t "Sampling continuation for ~a.~%"
	      (md:description prime))
      (format t "Pitch sequence prime: ~{~a,~^ ~}~%"
	      (map 'list #'md:chromatic-pitch prime))
      (generation::initialise-prediction-cache training-set-id attributes)
      (let* ((continuation
	      (continuation mvs prime (floor continuation-length)
			    :iterations iterations
			    :method method))
	     (channel 0)
	     (duration .25)
	     (onset 0)
	     (midi-pitch
	      (mapcar #'md:chromatic-pitch continuation))
	     (morphetic-pitch
	      (mapcar #'md:morphetic-pitch continuation))
	     (path
	      (format nil "~a/~a-continued.csv" output-dir (md:description prime))))
	(with-open-file (s path :direction :output :if-exists :overwrite
			   :if-does-not-exist :create)
	  (format s "onset,midi-pitch,morphetic-pitch,duration,channel~%")
	  (loop for midp in midi-pitch
	     for morp in morphetic-pitch do
	       (format s "~a,~a,~a,~a,~a~%" onset midp morp duration channel)
	       (incf onset duration)))))))

(defun event-density (sequences unit)
  (flet ((duration (s)
	   (let* ((l (coerce s 'list))
		  (first (first l))
		  (last (car (last l)))
		  (begin (md:onset first))
		  (end (+ (md:onset last) (md:duration last))))
	     (- end begin))))
    (let* ((duration (apply #'+ (mapcar #'duration sequences)))
	   (events (apply #'+ (mapcar #'length sequences)))
	   (density (/ events duration)))
      (* density unit))))
      
(defun continuation (mvs prime continuation-length
		     &key (iterations 100) (random-state cl:*random-state*)
		       (method :metropolis))
  (dotimes (n continuation-length)
    (let* ((generation::*debug* nil)
	   (new-prime (dummy-continuation prime 1))
	   (sequence
	    (case method
	      (:metropolis
	       (generation::metropolis-sampling
		mvs new-prime iterations random-state
		:continuation-length (1+ n)))
	      (:gibbs
	       (generation::gibbs-sampling
		mvs new-prime iterations random-state
		:continuation-length (1+ n))))))
      (setf prime sequence)))
  prime)

(defun dummy-continuation (prime n)
  "Either
* Use the random algorithm to obtain a sample.
* Repeat the last note n times
* Pick something from the dataset
* Repeat the prime
"
  (let* ((prime (coerce prime 'list))
	 (last (car (last prime)))
	 (continuation))
    (dotimes (i n)
      ;;(push (md:copy-event (nth (- n i) prime)) continuation))
      (push (md:copy-event last) continuation))
;    (format t "Initial continuation: ~{~a,~^ ~}~%"
;	    (mapcar #'md:chromatic-pitch continuation))
    (append prime continuation)))

(defun temporary-database (root)
  (let ((training-data-path (format nil "~a/training-data/" root))
	(primes-path (format nil "~a/primes/" root)))
    (uiop:with-temporary-file (:pathname database)
      (format t "Using temporary database ~a.~%" database)
      (clsql:connect (list database) :if-exists :old :database-type :sqlite3)
      (idyom-db:initialise-database)
      (format t "Database initialised.~%")
      (format t "Loading training data from ~a.~%" training-data-path)
      (idyom-db:import-data :mid training-data-path "MIREX training data" 0)
      (format t "~%")
      (format t "Loading primes from ~a.~%" primes-path)
      (idyom-db:import-data :mid primes-path "MIREX primes" 1)
      (format t "~%")
      database)))

(defun fixed-database (root)
  (let ((database (format nil "~a/database.sqlite" root)))
    (format t "Using database ~a.~%" database)
    (clsql:connect (list database) :if-exists :old :database-type :sqlite3)))

(defun run (root)
  (let ((results-path (format nil "~a/results/" root)))
    (mirex 0 1
	   '(cpitch)
	   ;;'(cpitch bioi)
	   ;;'(thrfiph cpintfip (cpintfref dur-ratio))
	   ;; (cpint ioi)
	   '(cpint)
	   :output-dir results-path)))

;(fixed-database *root*)
(temporary-database *root*)
(run *root*)



