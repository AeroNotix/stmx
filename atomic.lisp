;; -*- lisp -*-

(in-package :stmx)

(eval-always
  (enable-pf-reader))


;;;; ** Defining

(defmacro transactional ((defclass class direct-superclasses direct-slots &rest class-options))
  "Define a new transactional class called CLASS.

use this macro to wrap a normal defclass as follows:
\(TRANSACTIONAL (DEFCLASS class-name (superclasses) (slots) [options]))
the effect is the same as DEFCLASS, plus the default metaclass is
TRANSACTIONAL-CLASS, slots are transactional by default, and it inherits
from TRANSACTIONAL-OBJECT by default."
;  (let1 direct-superclasses (or direct-superclasses '(transactional-object))
    `(eval-always
       (,defclass ,class ,direct-superclasses
         ,direct-slots
         ,@class-options
         (:metaclass transactional-class))))


(defmacro transaction ((defun-or-defmethod func args &body body))
  "Define a new atomic function or method called FUNC.

use this macro to wrap a normal defun or defmethod as follows:
\(TRANSACTION (DEFUN function-name (arguments) body))
the effect is the same as DEFUN - or DEFMETHOD, plus the body is wrapped
inside (atomic ...)."
    `(eval-always
       (,defun-or-defmethod ,func ,args
         (atomic
           ,@body))))



;;;; ** Running

(defmacro atomic (&body body)
  `(run-atomic (lambda () ,@body)))



(defun run-once (tx)
  (declare (type function tx))
  (with-new-tlog log
    (log:trace "Tlog ~A created" (~ log))
    (log:trace "Transaction ~A starting..." (~ tx))
    ;; TODO: handler-case to capture errors signaled by tx!
    (let1 x (catch 'retry (multiple-value-list (funcall tx)))
      (etypecase x
        (tlog
         (log:debug "Transaction ~A wants to retry" (~ tx))
         (values t x))
        (list
         (log:debug "Transaction ~A wants to commit, returned: ~{~A ~}" (~ tx) x)
         (values nil log x))))))


(defun run-atomic (tx)
  (declare (type function tx))

  (when (recording?)
    (return-from run-atomic (funcall tx)))

  (prog (x-tlog x-values)

   execute
   (multiple-value-bind (retry? log values) (run-once tx)
     (unless (valid? log)
         (log:trace "Transaction ~A has invalid log, re-executing it immediately" (~ tx))
         (go execute))
     (when retry?
       (log:trace "Transaction ~A will wait, then will retry (re-execute)" (~ tx))
       (wait-tlog log)
       (go execute))
     (setq x-tlog   log
           x-values values)
     (go commit))

   commit
   (when (commit x-tlog)
       (go done))
   (log:trace "Transaction ~A could not commit, re-executing it immediately" (~ tx))
   (go execute)

   done
   (return-from run-atomic (values-list x-values))))




;;;; ** Composing

(defun run-orelse (tx1 tx2)
  (declare (type function tx1 tx2))
  (prog (log1 log2 x-values)

   execute-tx1
   (setq log1 nil
         log2 nil)
   (multiple-value-bind (retry? log values) (run-once tx1)
     (setf log1 log)
     (if retry?
         (progn
           (log:trace "Transaction ~A retried, trying transaction ~A" (~ tx1) (~ tx2))
           (go execute-tx2))
         (progn
           (setf x-values values)
           (go commit-tx1))))
   
   commit-tx1
   (if (not (check? log1))
       (progn
         (log:trace "Tlog ~A of transaction ~A invalid, trying transaction ~A"
                    (~ log1) (~ tx1) (~ tx2))
         (go execute-tx2))
       (if (not (commit log1))
           (progn
             (log:trace "Tlog ~A of transaction ~A not committed, trying transaction ~A"
                        (~ log1) (~ tx1) (~ tx2))
             (go execute-tx2))
           (go done)))

   execute-tx2
   (multiple-value-bind (retry? log values) (run-once tx2)
     (setf log2 log)
     (if retry?
         (progn
           (log:trace "Transaction ~A retried, retrying both ~A and ~A"
                      (~ tx2) (~ tx1) (~ tx2))
           (go wait-reexecute))
         (progn
           (setf x-values values)
           (go commit-tx2))))

   commit-tx2
   (if (not (check? log2))
       (progn
         (log:trace "Tlog ~A of transaction ~A invalid, retrying both ~A and ~A"
                    (~ log2) (~ tx2) (~ tx1) (~ tx2))
         (go wait-reexecute))
       (if (not (commit log2))
           (progn
             (log:trace "Tlog ~A of transaction ~A not committed, retrying both ~A and ~A"
                        (~ log2) (~ tx2) (~ tx1) (~ tx2))
             (go wait-reexecute))
           (go done)))

   wait-reexecute
   (progn
     (log:debug "Waiting for other threads before retrying both transactions ~A and ~A"
                (~ tx1) (~ tx2))
     (wait-tlog (merge-tlogs log1 log2))
     (go execute-tx1))
   
   done
   (return-from run-orelse (values-list x-values))))


(defmacro orelse (form1 form2)
  `(run-orelse (lambda () ,form1)
               (lambda () ,form2)))
  

(defmacro atomic-try (&body body)
  "Execute each transaction in BODY
atomically from left to right until one succeeds.

Returns the value of the transaction that succeeds."
  (reduce [list 'orelse] body :from-end t))


;;;; ** Retrying

(defun retry ()
  "Abort the current transaction and re-executes it from scratch.

The transaction will wait on all variables that have been read so
far during the transaction."
  (throw 'retry (current-tlog)))

  

;; Copyright (c) 2006 Hoan Ton-That
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;;
;;  - Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;;
;;  - Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;;
;;  - Neither the name of Hoan Ton-That, nor the names of its
;;    contributors may be used to endorse or promote products derived
;;    from this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



;; Copyright (c) 2013, Massimiliano Ghilardi
;; This file is part of STMX.
;;
;; STMX is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Lesser General Public License
;; as published by the Free Software Foundation, either version 3
;; of the License, or (at your option) any later version.
;;
;; STMX is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty
;; of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;; See the GNU Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public
;; License along with STMX. If not, see <http://www.gnu.org/licenses/>.