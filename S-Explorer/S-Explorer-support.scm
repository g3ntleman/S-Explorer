#! /usr/bin/env chibi-scheme

; testing comments

(define test "test1" "test2")
(+ 2 3)

(import (scheme base) (chibi; comment!
ast))

(define (all-exports env)
  (let lp ((env env) (res '()))
    (if (not env)
        res
        (lp (env-parent env) (append (env-exports env) res)))))

(define (string-common-prefix-length strings)
  (if (null? strings)
      (let lp ((len (string-length (car strings)))
               (prev (car strings))
               (ls (cdr strings)))
        (if (or (null? ls) (zero? len))
            len
            (lp (min len (string-mismatch prev (car ls)))
                (car ls)
                (cdr ls))))))

(define (make-sexp-buffer-completer)
  (buffer-make-completer
   (lambda (buf word)
     (let* ((len (string-length word))
            (candidates
             (filter
              (lambda (w)
                (and (>= (string-length w) len)
                     (equal? word (substring w 0 len))))
              (map symbol->string (all-exports (interaction-environment)))))
            (prefix-len (string-common-prefix-length candidates)))
       (if (> prefix-len len)
           (list (substring (car candidates) 0 prefix-len))
           (sort candidates))))))

;(define (procedure-source-location procedure)
;  (let location-vector (bytecode-source (procedure-code procedure)))
;  (cdr (vector-ref location-vector 0)))

(define (procedure-source-location x)
(if (closure? x) (cdr (vector-ref (bytecode-source (procedure-code x)) 0)) (vector)))
