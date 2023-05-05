#lang rosette

(struct state (regs mem pc) #:mutable)

(define (interpret opcode imm off src dst st)
  (case opcode
    [(addi32)
     (set-pc st (add1 (get-pc st)))
     (set-reg st dst
       (zext (add (extract32 (get-reg st dst)) imm)))]))
