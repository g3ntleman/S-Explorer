;; alist.scm -- association list utilities
;; Copyright (c) 2009 Alex Shinn.  All rights reserved.
;; BSD-style license: http://synthcode.com/license.txt

;;> Cons a new alist entry mapping @var{key} -> datum onto @var{alist}.
(define (alist-cons key value alist) (cons (cons key value) alist))

;;> Make a fresh copy of @var{alist}. This means copying each pair that 
;;> forms an association as well as the spine of the list.
(define (alist-copy alist) (map (lambda (x) (cons (car x) (cdr x))) alist))


;;> @scheme{alist-delete} deletes all associations from @var{alist} with the given key, 
;;> using key-comparison procedure @scheme{=}, which defaults to @scheme{equal?}. 
;;> The dynamic order in which the various applications of @scheme{=} are made is not specified.
;;> Return values may share common tails with the @var{alist} argument. 
;;> The result is not disordered -- elements that appear in the result alist 
;;> occur in the same order as they occur in the argument @var{alist}.
;;>
;;> The comparison procedure is used to compare the element keys ki of @var{alist}'s entries to 
;;> the key parameter in this way: @scheme{(= key ki)}. Thus, one can reliably remove all entries 
;;> of alist whose key is greater than five with @scheme{(alist-delete 5 alist <)}.
(define (alist-delete key ls . o)
  (let ((eq (if (pair? o) (car o) equal?)))
    (remove (lambda (x) (eq (car x) key)) ls)))

;;> @scheme{alist-delete!} is the linear-update variant of alist-delete. It is allowed, 
;;> but not required, to alter cons cells from the alist parameter to construct the result.
;;> This implementation does not currently yield any advantange over @scheme{alist-delete}.
(define alist-delete! alist-delete)

