;;;; ======================================================================
;;;; File:       pitch.lisp
;;;; Author:     Marcus Pearce <marcus.pearce@qmul.ac.uk>
;;;; Created:    <2005-11-29 10:41:20 marcusp>
;;;; Time-stamp: <2014-11-24 20:00:06 marcusp>
;;;; ======================================================================

(cl:in-package #:viewpoints)

(defvar *octave* 12)

;; Keysig ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;  Chromatic interval of tonic from C (e.g. C major gives 0, F minor
;;  gives 5, F major also 5, Bb minor 1).
(define-viewpoint (referent derived (keysig))
    ((events md:music-sequence) element) 
  :function (let ((keysig (keysig events))
                  (mode (mode events)))
              ;(declare (type (integer -7 7) keysig) (type (integer 0 11) mode))
              (if (undefined-p keysig mode) +undefined+
                  (cond ((and (numberp keysig) (> keysig 0))
                         (mod (+ (* keysig 7) mode) 12))
                        ((and (numberp keysig) (< keysig 0))
                         (mod (+ (* (- keysig) 5) mode) 12))
                        ((numberp mode) mode)
			(t +undefined+)))) 
  :function* (viewpoint-alphabet (get-viewpoint 'keysig)))


;; Morphetic pitch ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; mpitch-class: 0-7, representing the diatonic pitch set.
(define-viewpoint (mpitch-class derived (mpitch))
    ((events md:melodic-sequence) element) 
  :function (let ((mpitch (mpitch events)))
              (cond ((undefined-p mpitch) +undefined+)
                    (t (mod mpitch 7))))
  :function* (remove-if-not #'(lambda (e) (= (mod e *octave*) element)) 
                            (viewpoint-alphabet (get-viewpoint 'mpitch))))


;; Chromatic Pitch ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; cpint: Chromatic pitch interval
(define-viewpoint (cpint derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (multiple-value-bind (e1 e2)
                (values-list (last events 2))
              (if (or (null e1) (null e2)) +undefined+
                  (let ((cpitch1 (cpitch (list e1)))
                        (cpitch2 (cpitch (list e2))))
                    (if (undefined-p cpitch1 cpitch2) +undefined+
                        (- cpitch2 cpitch1)))))
  :function* (list (+ element (cpitch (list (penultimate-element events))))))

;; cpint-size: Absolute value for cpint.
(define-viewpoint (cpint-size derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (let ((cpint (cpint events)))
              (cond ((undefined-p cpint) +undefined+)
                    (t (abs cpint))))
  :function* (let ((pitch (cpitch (list (penultimate-element events)))))
               (remove-if-not #'(lambda (a) 
                                  (or (= (+ pitch element) a)
                                      (= (- pitch element) a)))
                              (viewpoint-alphabet (get-viewpoint 'cpitch)))))

;; contour: -1 for a descending interval, 0 unison, 1 ascending
;; (equivalent to d, r and u respectively in
;; [http://en.wikipedia.org/wiki/Parsons_code Parson’s code]).
(define-viewpoint (contour derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (let ((cpint (cpint events)))
              (cond ((undefined-p cpint) +undefined+)
                    (t (signum cpint))))
  :function* (let ((pitch (cpitch (list (penultimate-element events)))))
               (remove-if #'(lambda (a) (case element
                                          (-1 (>= a pitch))
                                          (0  (not (= a pitch)))
                                          (1  (<= a pitch))))
                          (viewpoint-alphabet (get-viewpoint 'cpitch)))))

;; Returns 1 if contour is unchanged from preceding contour, 0 if it
;; is different.
(define-viewpoint (newcontour derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (let ((contour2 (contour events))
                  (contour1 (contour (butlast events 1))))
              (cond ((undefined-p contour2 contour1)
                     +undefined+)
                    ((= contour1 contour2) 1)
                    (t 0)))
  ;; TODO: function* 
  )

;; Pitch modulo 12 (so C = 0, D = 2 etc.)
(define-viewpoint (cpitch-class derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (let ((cpitch (cpitch events)))
              (cond ((undefined-p cpitch) +undefined+)
                    (t (mod cpitch *octave*))))
  :function* (remove-if-not #'(lambda (e) (= (mod e *octave*) element)) 
                            (viewpoint-alphabet (get-viewpoint 'cpitch))))

;; Equivalent to cpint modulo 12 (so both perfect unison and perfect
;; octave = 0), but preserving sign, so ascending and descending
;; intervals are still discriminated. (It looks like this was
;; originally calculated as cpcint-size and then redefined when
;; cpcint-size was added. This makes it more consistent with cpint.)
(define-viewpoint (cpcint derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (let* ((cpint (cpint events)))
              (if (or (null cpint) (undefined-p cpint)) +undefined+ 
                  (if (minusp cpint) 
                      (- (mod (abs cpint) *octave*))
                      (mod cpint *octave*))))
  :function* (let ((pitch (cpitch (list (penultimate-element events)))))
               (remove-if-not #'(lambda (e) 
                                  (let* ((cpint (- e pitch))
                                         (cpint (if (minusp cpint) 
                                                    (- (mod (abs cpint) *octave*))
                                                    (mod cpint *octave*))))
                                    (= element cpint)))
                              (viewpoint-alphabet (get-viewpoint 'cpitch)))))

;; Absolute value for cpcint.
(define-viewpoint (cpcint-size derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (let ((cpcint (cpcint events)))
              (cond ((undefined-p cpcint) +undefined+)
                    (t (abs cpcint))))
  ;; TODO: function*
  )

;; cpcint-size modulo 2.
(define-viewpoint (cpcint-2 derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (multiple-value-bind (e1 e2)
                (values-list (last events 2))
              (if (or (null e1) (null e2)) +undefined+
                  (let ((cpcint (cpcint-size (list e1 e2))))
                    (if (undefined-p cpcint) +undefined+
                        (mod cpcint 2)))))
  ;; TODO: function* 
  )

;; cpcint-size modulo 3.
(define-viewpoint (cpcint-3 derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (multiple-value-bind (e1 e2)
                (values-list (last events 2))
              (if (or (null e1) (null e2)) +undefined+
                  (let ((cpcint (cpcint-size (list e1 e2))))
                    (if (undefined-p cpcint) +undefined+
                        (mod cpcint 3)))))
  ;; TODO: function* 
  )

;; cpcint-size modulo 4.
(define-viewpoint (cpcint-4 derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (multiple-value-bind (e1 e2)
                (values-list (last events 2))
              (if (or (null e1) (null e2)) +undefined+
                  (let ((cpcint (cpcint-size (list e1 e2))))
                    (if (undefined-p cpcint) +undefined+
                        (mod cpcint 4)))))
  ;; TODO: function* 
  )
  
;; cpcint-size modulo 5.
(define-viewpoint (cpcint-5 derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (multiple-value-bind (e1 e2)
                (values-list (last events 2))
              (if (or (null e1) (null e2)) +undefined+
                  (let ((cpcint (cpcint-size (list e1 e2))))
                    (if (undefined-p cpcint) +undefined+
                        (mod cpcint 5)))))
  ;; TODO: function* 
  )

;; cpcint-size modulo 6.
(define-viewpoint (cpcint-6 derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (multiple-value-bind (e1 e2)
                (values-list (last events 2))
              (if (or (null e1) (null e2)) +undefined+
                  (let ((cpcint (cpcint-size (list e1 e2))))
                    (if (undefined-p cpcint) +undefined+
                        (mod cpcint 6)))))
  ;; TODO: function* 
  )

;;  Chromatic interval from tonic (0 = tonic, 4 mediant, 7 dominant, etc.)
(define-viewpoint (cpintfref derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (let ((cpitch (cpitch events))
                  (referent (referent events)))
              (cond ((undefined-p cpitch referent) +undefined+)
                    (t (mod (- cpitch referent) *octave*))))
  :function* (let* ((referent (referent events))
                    (pitch (mod (+ referent element) *octave*)))
               (remove-if-not #'(lambda (e) (= (mod e *octave*) pitch))
                              (viewpoint-alphabet (get-viewpoint 'cpitch)))))

;; Chromatic interval from first event in piece.
(define-viewpoint (cpintfip derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (if (< (length events) 2) +undefined+ 
                ;; (if (= (length events) 1) 0
                (let ((cpitch1 (cpitch (list (car events))))
                      (cpitch2 (cpitch events)))
                  (if (undefined-p cpitch2 cpitch1) +undefined+
                      (- cpitch2 cpitch1))))
  :function* (list (+ element (cpitch (list (car events))))))

;; Chromatic interval from first event in phrase.
(define-viewpoint (cpintfiph derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (if (= (fiph events) 1) +undefined+ 
                (let ((e1 (strip-until-true (get-viewpoint 'fiph) events)))
                  (if (null e1) +undefined+
                      (let ((cpitch1 (cpitch e1))
                            (cpitch2 (cpitch events)))
                        (if (undefined-p cpitch2 cpitch1) +undefined+
                            (- cpitch2 cpitch1))))))
  :function* (let ((e (strip-until-true (get-viewpoint 'fiph) events)))
               (list (+ element (cpitch e)))))

;; Chromatic interval from event at time 0 in bar (undefined if event
;; is itself at time 0 or if there is nothing at time 0).
(define-viewpoint (cpintfib derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (if (= (fib events) 1) +undefined+ ;; 0
                (let ((e1 (strip-until-true (get-viewpoint 'fib) events)))
                  (if (null e1) +undefined+
                      (let ((cpitch1 (cpitch e1))
                            (cpitch2 (cpitch events)))
                        (if (undefined-p cpitch2 cpitch1) +undefined+
                            (- cpitch2 cpitch1))))))
  :function* (let ((e (strip-until-true (get-viewpoint 'fib) events)))
               (list (+ element (cpitch e)))))


;; Octave number, where middle C (and the 11 notes above) is 5 (based
;; on chromatic pitch)
(define-viewpoint (octave derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (let ((cpitch (cpitch events)))
              (cond ((undefined-p cpitch) +undefined+)
                    (t (floor cpitch *octave*))))
  ;; TODO: function* 
  )

;; Based on pitch tessitura of the Soprano voice of the Bach chorales
;; (see Pearce, 2005, p. 206). 0 if more than one standard deviation
;; below the mean pitch (F# above middle C), 2 if more than one
;; standard deviation above the mean pitch (the D above middle C) and
;; 2 if between these pitches.
(define-viewpoint (tessitura derived (cpitch))
    ((events md:melodic-sequence) element) 
  :function (let ((cpitch (cpitch events)))    
              (cond ((undefined-p cpitch) +undefined+)
                    ((< cpitch 66) 0) ; from chorales 
                    ((> cpitch 74) 2) ; from chorales 
                    (t 1)))
  :function* (remove-if #'(lambda (e) 
                            (case element
                              (0 (>= e 66))
                              (1 (not (<= 66 e 74)))
                              (2 (<= e 74))))
                        (viewpoint-alphabet (get-viewpoint 'cpitch))))
