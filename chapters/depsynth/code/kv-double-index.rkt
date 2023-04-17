(define (put k v)
  (define index (get-current-index))
  ...)
(define (get k)
  (define index (get-current-index))
  ...)
(define (flush)
  (flush index0)
  (flush index1)
  (flush data-store))
(define (clean)
  (let* ([old-index (get-current-index)]
         [new-index (get-other-index)]
         [old-index-data (read! old-index 0 #:len (length! old-index))]
         [new-index-entries (remove-duplicate-entries old-index-data)])
    (update! index-chooser (get-id new-index))
    (for ([entry new-index-entries])
         (append! new-index entry))))
