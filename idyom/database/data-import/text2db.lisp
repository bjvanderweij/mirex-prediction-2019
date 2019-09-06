;;;; ======================================================================
;;;; File:       text2db.lisp
;;;; Author:     Marcus Pearce <marcus.pearce@qmul.ac.uk>
;;;; Created:    <2007-04-19 11:15:57 marcusp>
;;;; Time-stamp: <2015-03-25 23:13:35 marcusp>
;;;; ======================================================================

(cl:in-package #:text2db) 

(defparameter *duration* 24)
(defvar *timebase* 96 "Basic time units per semibreve")
(defvar *middle-c* 60 "Chromatic integer mapping for c_4")

(defmethod import-data ((type (eql :text)) path description id)
  (idyom-db:insert-dataset (text2db path description) id))

(defmethod import-data ((type (eql :txt)) path description id)
  (idyom-db:insert-dataset (text2db path description) id))

(defun text2db (path description) 
  (let ((data (get-data path)))
    (append (list description *timebase* *middle-c*) data)))

(defun get-data (path)
  (let ((pitch-sequences))
    (with-open-file (i path :direction :input)
      (do ((input (read-line i nil 'eof) (read-line i nil 'eof)))
          ((eq input 'eof))
        (let ((split-input nil))
          (cond ((find #\Tab input)
                 (setf split-input 
                       (split-string input (format nil "~C" #\Tab))))
                ((find #\Space input)
                 (setf split-input 
                       (split-string input (format nil "~C" #\Space))))
                (t (error "Unrecognised delimiter token.")))
          (push (mapcar #'parse-integer (remove "" split-input :test #'string=)) pitch-sequences))))
    (convert-pitch-sequences (nreverse pitch-sequences))))

(defun split-string (string separator)
  "Takes a string object and returns a list of strings corresponding to each
   <separator> delimited sequence of characters in that string."
  (labels ((find-words (char-list word result)
             (cond ((null char-list) (reverse (cons word result)))
                   ((not (string= (car char-list) separator))
                    (find-words (cdr char-list)
                                (concatenate 'string word (list (car char-list)))
                                result))
                   (t (find-words (cdr char-list) "" (cons word result))))))
    (find-words (coerce string 'list) "" '())))

(defun convert-pitch-sequences (pitch-sequences)
  (let ((id 0)
        (onset 0)
        (data '()))
    (dolist (pseq pitch-sequences (nreverse data))
      (let ((event-sequence ()))
        (dolist (pitch pseq)
          (push (make-event-alist pitch onset) event-sequence)
          (incf onset *duration*))
        (setf onset 0)
        (push (cons (format nil "~A" id) (nreverse event-sequence)) data))
      (incf id))))

(defun make-event-alist (pitch onset)
  (list (list :onset onset)
        (list :bioi *duration*)
        (list :dur *duration*)
        (list :deltast 0)
        (list :cpitch pitch)
        (list :voice 1)))
 
