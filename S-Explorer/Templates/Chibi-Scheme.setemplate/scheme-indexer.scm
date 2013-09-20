; Scheme Parser Program
; Nayef Copty

; find the number of statements in an s-expression.
(define (statements exp)
(cond
((null? exp) 0)
((list? (car exp)) (+ 1 (statements (car exp)) (statements (cdr exp))))
(#t (statements (cdr exp)))))

; returns the maximum number between from two arguments
(define (find_max a b)
(cond
((> a b) a)
(#t b)))

; find the maximum depth of an s-expression.
(define (depth exp)
(find_max
(cond
((null? exp) 0)
((list? (car exp)) (+ 1 (depth (car exp))))
(#t 0))
(cond
((null? exp) 0)
((null? (cdr exp)) 0)
(#t (depth (cdr exp))))))

(define (parse exp)
(cons (cons '"NumberofStatements:" (cons (statements exp) null)) (cons '"MaximumDepth:" (cons (* -1 (- 1 (depth exp))) null))))

; Statements: 1  Depth: 0
(parse '((id = id - const)))

; Statements: 2  Depth: 0
(parse '((id = id + id) (id = id - id)))

; Statements: 2  Depth: 1
(parse '((if bool then (id = const / const))))

; Statements: 3  Depth: 1
(parse '((if bool then (id = const / const)(id = id + id))))

; Statements: 4  Depth: 1
(parse '((if bool then (id = const / const))(while bool (id = a - const))))

; Statments: 7  Depth: 1
(parse '((id = id + id)(if bool then (id = const / const)(id = id + id))(while bool (id = a - const)(id = id -id))))

; Statements 9  Depth: 2
(parse '((id = id + id)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(while bool (id = a - const)(id = id -id))))

; Statements 14  Depth: 3
(parse '((id = id + id)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(while bool (id = a - const)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(id = id - id))))
; Scheme Parser Program
; Nayef Copty

; find the number of statements in an s-expression.
(define (statements exp)
(cond
((null? exp) 0)
((list? (car exp)) (+ 1 (statements (car exp)) (statements (cdr exp))))
(#t (statements (cdr exp)))))

; returns the maximum number between from two arguments
(define (find_max a b)
(cond
((> a b) a)
(#t b)))

; find the maximum depth of an s-expression.
(define (depth exp)
(find_max
(cond
((null? exp) 0)
((list? (car exp)) (+ 1 (depth (car exp))))
(#t 0))
(cond
((null? exp) 0)
((null? (cdr exp)) 0)
(#t (depth (cdr exp))))))

(define (parse exp)
(cons (cons '"NumberofStatements:" (cons (statements exp) null)) (cons '"MaximumDepth:" (cons (* -1 (- 1 (depth exp))) null))))

; Statements: 1  Depth: 0
(parse '((id = id - const)))

; Statements: 2  Depth: 0
(parse '((id = id + id) (id = id - id)))

; Statements: 2  Depth: 1
(parse '((if bool then (id = const / const))))

; Statements: 3  Depth: 1
(parse '((if bool then (id = const / const)(id = id + id))))

; Statements: 4  Depth: 1
(parse '((if bool then (id = const / const))(while bool (id = a - const))))

; Statments: 7  Depth: 1
(parse '((id = id + id)(if bool then (id = const / const)(id = id + id))(while bool (id = a - const)(id = id -id))))

; Statements 9  Depth: 2
(parse '((id = id + id)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(while bool (id = a - const)(id = id -id))))

; Statements 14  Depth: 3
(parse '((id = id + id)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(while bool (id = a - const)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(id = id - id))))
; Scheme Parser Program
; Nayef Copty

; find the number of statements in an s-expression.
(define (statements exp)
(cond
((null? exp) 0)
((list? (car exp)) (+ 1 (statements (car exp)) (statements (cdr exp))))
(#t (statements (cdr exp)))))

; returns the maximum number between from two arguments
(define (find_max a b)
(cond
((> a b) a)
(#t b)))

; find the maximum depth of an s-expression.
(define (depth exp)
(find_max
(cond
((null? exp) 0)
((list? (car exp)) (+ 1 (depth (car exp))))
(#t 0))
(cond
((null? exp) 0)
((null? (cdr exp)) 0)
(#t (depth (cdr exp))))))

(define (parse exp)
(cons (cons '"NumberofStatements:" (cons (statements exp) null)) (cons '"MaximumDepth:" (cons (* -1 (- 1 (depth exp))) null))))

; Statements: 1  Depth: 0
(parse '((id = id - const)))

; Statements: 2  Depth: 0
(parse '((id = id + id) (id = id - id)))

; Statements: 2  Depth: 1
(parse '((if bool then (id = const / const))))

; Statements: 3  Depth: 1
(parse '((if bool then (id = const / const)(id = id + id))))

; Statements: 4  Depth: 1
(parse '((if bool then (id = const / const))(while bool (id = a - const))))

; Statments: 7  Depth: 1
(parse '((id = id + id)(if bool then (id = const / const)(id = id + id))(while bool (id = a - const)(id = id -id))))

; Statements 9  Depth: 2
(parse '((id = id + id)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(while bool (id = a - const)(id = id -id))))

; Statements 14  Depth: 3
(parse '((id = id + id)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(while bool (id = a - const)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(id = id - id))))
; Scheme Parser Program
; Nayef Copty

; find the number of statements in an s-expression.
(define (statements exp)
(cond
((null? exp) 0)
((list? (car exp)) (+ 1 (statements (car exp)) (statements (cdr exp))))
(#t (statements (cdr exp)))))

; returns the maximum number between from two arguments
(define (find_max a b)
(cond
((> a b) a)
(#t b)))

; find the maximum depth of an s-expression.
(define (depth exp)
(find_max
(cond
((null? exp) 0)
((list? (car exp)) (+ 1 (depth (car exp))))
(#t 0))
(cond
((null? exp) 0)
((null? (cdr exp)) 0)
(#t (depth (cdr exp))))))

(define (parse exp)
(cons (cons '"NumberofStatements:" (cons (statements exp) null)) (cons '"MaximumDepth:" (cons (* -1 (- 1 (depth exp))) null))))

; Statements: 1  Depth: 0
(parse '((id = id - const)))

; Statements: 2  Depth: 0
(parse '((id = id + id) (id = id - id)))

; Statements: 2  Depth: 1
(parse '((if bool then (id = const / const))))

; Statements: 3  Depth: 1
(parse '((if bool then (id = const / const)(id = id + id))))

; Statements: 4  Depth: 1
(parse '((if bool then (id = const / const))(while bool (id = a - const))))

; Statments: 7  Depth: 1
(parse '((id = id + id)(if bool then (id = const / const)(id = id + id))(while bool (id = a - const)(id = id -id))))

; Statements 9  Depth: 2
(parse '((id = id + id)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(while bool (id = a - const)(id = id -id))))

; Statements 14  Depth: 3
(parse '((id = id + id)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(while bool (id = a - const)(if bool then (if bool then ( id = id + id ))(id = const / const)(id = id + id))(id = id - id))))
