#lang rosette

(struct state (regs mem pc) #:mutable)

; TODO take instruction object as input
(define (interpret
          opcode rd rs imm st)
  (case opcode
    [(lui)
     ; load a 20-bit value into 
     ; upper bits of a register
     (set-pc! st (+ 4 (get-pc st)))
     (set-reg!
       st rd
       (sext64
         (concat imm (zeros 12))))]
    [(addiw)
     ; Add 12-bit value to a reg;
     ; sign extend lower 32-bits
     (set-pc! st (+ 4 (get-pc st)))
     (set-reg!
       st rd
       (sext64
         (+ (sext32 imm)
            (extract32
              (get-reg st rs)))))]
    [(add)
     ; Add two registers
     (set-pc! st (+ 4 (get-pc st)))
     (set-reg!
       st rd
       (+ (get-reg st rs1)
          (get-reg st rs2)))]
    [(slli)
     ; Left shift reg by value
     (set-pc! st (+ 4 (get-pc st)))
     (set-reg!
       st rd
       (<< (get-reg st rs) imm))]
    [(srli)
     ; Logical right shift
     (set-pc! st (+ 4 (get-pc st)))
     (set-reg!
       st rd
       (>> (get-reg st rs) imm))]
    [(lw)
     ; Load word from memory
     (set-pc! st (+ 4 (get-pc st)))
     (set-reg!
       st rd
       (read-word st
                  (+ (get-reg st rs)
                     imm)))]
    [(sw)
     ; Store word to memory
     (set-pc! st (+ 4 (get-pc st)))
     (write-word st
                 (+ (get-reg st rd)
                    imm)
                 (get-reg st rs))]))
