(import (chibi ast))

(define (all-exports env)
  (let lp ((env env) (res '()))
    (if (not env)
        res
        (lp (environment-parent env) (append (env-exports env) res)))))

(define (buffer-make-completer generate)
  (lambda (ch buf out return)
    (let* ((word (buffer-previous-word buf))
           (ls (generate buf word)))
      (cond
       ((null? ls)
        (command/beep ch buf out return))
       ((= 1 (length ls))
        (buffer-insert! buf out (substring (car ls) (string-length word))))
       (else
        (newline out)
        (buffer-format-list buf out ls)
        (buffer-draw buf out))))))

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

(define (bracket-complete-string word)
    ((make-sexp-buffer-completer) ch word out return) 
)