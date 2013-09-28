
;; Simple R7RS repl server, using (srfi 18) threads and the
;; run-net-server utility from (chibi net server).

(import (scheme base) (scheme write) (srfi 18) (srfi 38) (chibi net server) (scheme eval))

;; Copy each input line to output.
(define (repl-handler in out sock addr)
  (let ((line (read-line in)))
    (cond
     ((not (or (eof-object? line) (equal? line "")))
      (display "read: ") (write line) (newline)
      (let* (
        (line-port (open-input-string line))
        (result (eval (read/ss line-port) (scheme-report-environment 7))))
        (write/ss result out))
      (newline out)
      (flush-output-port out)))))

;; Start the server on localhost:5556 dispatching clients to repl-handler.
(run-net-server 5556 repl-handler)
