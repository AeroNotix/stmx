;; -*- lisp -*-

;;;; * Welcome to CL-STM2

;;;; CL-STM2 depends on arnesi, bordeaux-threads, and closer-mop.

(in-package :cl-user)

(defpackage :stmx
  (:use :cl
        :arnesi
        :bordeaux-threads
        :closer-mop)
  (:shadowing-import-from :arnesi
                          #:else
                          #:specializer ; closer-mop
                          #:until)
  (:shadowing-import-from :closer-mop
                          #:defclass
                          #:standard-class
                          #:defmethod
                          #:standard-generic-function
                          #:ensure-generic-function
                          #:defgeneric)
  (:export #:atomic
           #:orelse ;; try ?
           #:retry

           #:transactional
           #:transaction

           #:sleep-after
           #:nonblock
           #:repeat

           #:tvar
           #:$
           #:bound-$?
           #:unbind-$


           #:transactional-class
           #:transactional-object))


(defpackage :stmx.util
  
  (:use :cl
        :arnesi
        :stmx)

  (:export #:counter
           #:count-of
           #:increment
           #:decrement
           #:reset
           #:swap

           #:cell
           #:empty?
           #:empty!
           #:take
           #:put
           #:try-put

           #:tqueue
           #:deq
           #:enq
           #:empty-queue?
           #:full-queue?
           #:qlength

           #:chan
           #:port
           #:read-port
           #:write-chan))

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
