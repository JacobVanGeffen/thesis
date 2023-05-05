(struct state (regs mem pc) #:transparent)       ; Abstract register machine state.
                                                 ; Input 1/3: toy eBPF.
(struct ebpf-insn (opcode dst src off imm))      ;  - eBPF instruction format;
(define (ebpf-interpret insn st)                 ;  - eBPF interpreter for addi32.
  (define-match (ebpf-insn op dst _ _ imm) insn) ;  
  (case op                                       ; Note: addi32 does not use the src  
    [(addi32)                                    ; and off fields.
     (state  
      (reg-set st dst (concat (bv 0 32) (bvadd (extract 31 0 (reg-ref st dst)) imm)))
      (state-mem st)     
      (bvadd (state-pc st) (bv 1 64)))]))
                                                 ; Input 2/3: toy RISC-V.
(struct rv-insn (opcode rd rs1 rs2 imm))         ;  - RISC-V instruction format;
(define (rv-interpret insn st)                   ;  - RISC-V interpreter.
  (define-match (rv-insn op rd rs1 rs2 imm) insn)   
  (case op                                      
    [(lui)                                       
     (state  
      (reg-set st rd (sext64 (concat imm (bv 0 12))))
      (state-mem st)     
      (bvadd (state-pc st) (bv 4 64)))] ...))
                                                 ; Input 3/3: state mapping functions.
(define (regST r)                                ;  - Register mapping:
  (cond [(equal? r (bv 0 4)) (bv 15 5)] ...))    ;    - eBPF r0 -> RISC-V x15, ...;
(define (memST a) a)                             ;  - Memory mapping is the identity.
(define (pcST pc) (bvshl pc (bv 2 64)))          ;  - PC mapping. 