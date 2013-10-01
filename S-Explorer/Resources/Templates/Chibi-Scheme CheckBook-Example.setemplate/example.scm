#! /usr/bin/env chibi-scheme

(import (scheme write) 
     (scheme read))

; This is a fixed version of a scheme example 
; by A. Aaby <aabyan@wwc.edu> available at
; http://www.cefns.nau.edu/~edo/Classes/CS396_WWW/Misc_docs/Scheme%20Tutorial.html

;(define prompt-read (lambda (Prompt)
;   (display Prompt)
;   (read)))

(define checkbook (lambda ()

; This check book balancing program was written to illustrate
; i/o in Scheme. It uses the purely functional part of Scheme.

        ; These definitions are local to checkbook
        (letrec

            ; These strings are used as prompts

           ((IB "Enter initial balance: ")
            (AT "Enter transaction (- for withdrawal): ")
            (FB "Your final balance is: ")

            ; Define a function that displays a prompt then returns
            ; the value read:
            (prompt-read (lambda (Prompt)
                  (display Prompt)
                  (read)))

            ; This function recursively computes the new
            ; balance given an initial balance init and
            ; a new value t.  Termination occurs when the
            ; new value is 0.
            (newbal (lambda (init t)
                  (if (= t 0)
                      (begin
                        (display FB)
                        (display init)
                        (newline))
                      (transaction (+ init t)))))

            ; This function prompts for and reads the next
            ; transaction and passes the information to newbal:
            (transaction (lambda (init)
                      (newbal init (prompt-read AT)))))

; This is the body of checkbook;  it prompts for the
; starting balance:
(transaction (prompt-read IB)))))

; Run the program:
(checkbook)