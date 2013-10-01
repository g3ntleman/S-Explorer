#! /usr/bin/env chibi-scheme -xscheme.base


;; Simple R7RS repl server, using (srfi 18) threads and the
;; run-net-server utility from (chibi net server).

(import (scheme base)
    (scheme write) 
    (srfi 38)
    (scheme process-context)
    (scheme repl)
    (chibi net server) 
    (scheme eval))

;; evaluate the input from line-port and write the result to output port out.
(define (repl-handler in out sock addr)
  (let ((line (read-line in)))
    (cond
     ((not (or (eof-object? line) (equal? line "")))
      (display "read: ") (write line) (newline)
      (let* (
          (line-port (open-input-string line))
          (result (eval (read/ss line-port) (interaction-environment))))
        (write/ss result out)
        (newline out)
        (flush-output-port out))))))


(display (command-line))
(newline)
;; Start the server on localhost:5556 dispatching clients to repl-handler.
(run-net-server 5556 repl-handler)
