#lang racket

(require file/glob)

(define dir "data")
(define file-names
  (glob
    (~a
      dir "/*{"
      "all-opts,"
      "no-opts,"
      "load-only,"
      "rwset-only"
      "}*.csv")))
(for ([fn file-names])
  (define time-hash (make-hash))

  (displayln fn)

  (define lines (file->lines fn))

  (define instrs
    (remove-duplicates
      (map
        (lambda (l) (first (string-split l ",")))
        (rest lines))))

  (for ([line lines])
    (let* ([args (string-split line ",")])
      (if (hash-has-key? time-hash (first args))
        (hash-set!
          time-hash
          (first args)
          (+ (hash-ref time-hash (first args))
             (string->number (third args))))
        (hash-set!
          time-hash
          (first args)
          (string->number (third args))))))

  (define fout (open-output-file fn #:exists 'replace))
  (displayln "instructions,time(s)" fout)
  (define time-passed 0)
  (displayln "0.0" fout)
  (for ([instr instrs]
        [numi (length instrs)])
    (set! time-passed (+ time-passed (hash-ref time-hash instr)))
    (displayln (~a (add1 numi) "," (quotient time-passed 1000)) fout))
  (close-output-port fout))
