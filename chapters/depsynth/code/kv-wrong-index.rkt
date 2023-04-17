(define (put k v) ...)
(define (get k) ...)
(define (flush) ...)
(define (clean)
  (let* ([old-index-data (read! index 0 #:len (length! index))]
         [new-index-entries (remove-duplicate-entries old-index-data)])
    (zero! index) // Overwrite index with all 0s
    (for ([entry new-index-entries])
         (append! index entry))))
