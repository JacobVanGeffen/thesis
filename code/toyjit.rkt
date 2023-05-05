#lang rosette

; Usage:
;
; 1. Configure Boolector.  Open a terminal:
;
;    % export BOOLECTOR=/path/to/boolector
;
; 2. Run synthesis (in the same terminal):
;
;    % time racket toyjit.rkt ALU_MOV_X
;    Use Boolector: ...
;    Synthesize for BPF instruction: ALU_MOV_X
;
;    	(slli	RV_REG_T1 regmap[src] 32)
;    	(srli	regmap[dst] RV_REG_T1 32)
;
;    Then try ALU_MOV_K and ALU_ADD_K.
;
; 3. To make the sketch more general, search for "XXX" in the code.
;    These changes will likely increase the synthesis time.
;
; 4. A significant amount of time seems to be spent on synthesizing immediates
;    in the host language.  Since RISC-V has a pseudoinstruction "li rd, imm",
;    one can enable it by setting "use-pseudo-for-imm" to #t (see below).
;    This should speed up synthesis.

(require
  rosette/lib/angelic
  rosette/lib/match
  rosette/lib/roseunit
  rosette/solver/smt/boolector
  rosette/solver/smt/z3)

; configuration

(define use-pseudo-for-imm #f)

(define max-imm-depth 2)

(let ([boolector-env (getenv "BOOLECTOR")]
      [z3-env (getenv "Z3")])
  (cond
    [boolector-env
     (define boolector-path (find-executable-path boolector-env))
     (eprintf "Use Boolector: ~a\n" boolector-path)
     (current-solver (boolector #:path (find-executable-path boolector-path)))]
    [z3-env
     (define z3-path (find-executable-path z3-env))
     (eprintf "Use Z3: ~a\n" z3-path)
     (current-solver (z3 #:path (find-executable-path z3-path)
                         #:options (hash ':auto-config 'false ':smt.relevancy 0)))]))

; common

(define-generics instruction
  (instruction-run instruction state))

; bpf

(struct bpf (regs pc mem) #:transparent #:mutable)

(define (bpf-reg-ref st r)
  ((bpf-regs st) r))

(define (bpf-reg-set! st r v)
  (define f (bpf-regs st))
  (set-bpf-regs! st (lambda (x) (if (equal? r x) v (f x)))))

(define (bpf-pc-bump! st)
  (set-bpf-pc! st (bvadd (bpf-pc st) (bv 1 64))))

(define-struct ALU_MOV_X (dst src) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(ALU_MOV_X dst src)
        (bpf-reg-set! st dst (zero-extend (extract 31 0 (bpf-reg-ref st src)) (bitvector 64)))
        (bpf-pc-bump! st)]))])

(define-struct ALU_MOV_K (dst imm32) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(ALU_MOV_K dst imm32)
        (bpf-reg-set! st dst (zero-extend imm32 (bitvector 64)))
        (bpf-pc-bump! st)]))])

(define-struct ALU_ADD_K (dst imm32) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(ALU_ADD_K dst imm32)
        (bpf-reg-set! st dst (zero-extend (bvadd (extract 31 0 (bpf-reg-ref st dst)) imm32) (bitvector 64)))
        (bpf-pc-bump! st)]))])

; riscv

(struct rv64 (regs pc mem) #:transparent #:mutable)

(define (zero-reg? r)
  (equal? r (bv 0 5)))

(define (rv64-reg-ref st r)
  (if (zero-reg? r)
      (bv 0 64)
      ((rv64-regs st) r)))

(define (rv64-reg-set! st r v)
  (unless (zero-reg? r)
    (define f (rv64-regs st))
    (set-rv64-regs! st (lambda (x) (if (equal? r x) v (f x))))))

(define (rv64-pc-bump! st)
   (set-rv64-pc! st (bvadd (rv64-pc st) (bv 4 64))))

(define-struct lui (rd imm20) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(lui rd imm20)
        (rv64-reg-set! st rd (sign-extend (concat imm20 (bv 0 12))
                                          (bitvector 64)))
        (rv64-pc-bump! st)]))])

(define-struct addiw (rd rs imm12) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(addiw rd rs imm12)
        (rv64-reg-set! st rd (sign-extend (bvadd (extract 31 0 (rv64-reg-ref st rs))
                                                 (sign-extend imm12 (bitvector 32)))
                                          (bitvector 64)))
        (rv64-pc-bump! st)]))])

(define-struct add (rd rs1 rs2) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(add rd rs1 rs2)
        (rv64-reg-set! st rd (bvadd (rv64-reg-ref st rs1) (rv64-reg-ref st rs2)))
        (rv64-pc-bump! st)]))])

(define-struct slli (rd rs imm6) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(slli rd rs imm6)
        (rv64-reg-set! st rd (bvshl (rv64-reg-ref st rs) (zero-extend imm6 (bitvector 64))))
        (rv64-pc-bump! st)]))])

(define-struct srli (rd rs imm6) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(srli rd rs imm6)
        (rv64-reg-set! st rd (bvlshr (rv64-reg-ref st rs) (zero-extend imm6 (bitvector 64))))
        (rv64-pc-bump! st)]))])

(define-struct lb (rd rs imm12) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(lb rd rs imm12)
        (define M (rv64-mem st))
        (define a (bvadd (rv64-reg-ref st rs) (sign-extend imm12 (bitvector 64))))
        (rv64-reg-set! st rd (sign-extend (M a) (bitvector 64)))
        (rv64-pc-bump! st)]))])

(define-struct sb (rs1 rs2 imm12) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(sb rs1 rs2 imm12)
        (define M (rv64-mem st))
        (define a (bvadd (rv64-reg-ref st rs1) (sign-extend imm12 (bitvector 64))))
        (define v (extract 7 0 (rv64-reg-ref st rs2)))
        (set-rv64-mem! st (lambda (x) (if (equal? x a) v (M x))))
        (rv64-pc-bump! st)]))])

; pseudoinstruction
(define-struct li (rd imm) #:transparent
  #:methods gen:instruction
  [(define (instruction-run insn st)
     (match insn
       [(li rd imm)
        (rv64-reg-set! st rd (sign-extend imm (bitvector 64)))
        (rv64-pc-bump! st)
        (rv64-pc-bump! st)]))])

; mapping

(define (regST r)
  (cond
    [(equal? r (bv 0 4)) (bv 15 5)]
    [(equal? r (bv 1 4)) (bv 10 5)]
    [(equal? r (bv 2 4)) (bv 11 5)]
    [(equal? r (bv 3 4)) (bv 12 5)]
    [(equal? r (bv 4 4)) (bv 13 5)]
    [(equal? r (bv 5 4)) (bv 14 5)]
    [(equal? r (bv 6 4)) (bv 9 5)]
    [(equal? r (bv 7 4)) (bv 18 5)]
    [(equal? r (bv 8 4)) (bv 19 5)]
    [(equal? r (bv 9 4)) (bv 20 5)]
    [(equal? r (bv 10 4)) (bv 21 5)]
    [else (assert #f)]))

(define (equiv-state? bpf-st rv64-st addr)
  (define regs (map (lambda (x) (bv x 4)) (range 11)))
  (define regs-equiv (apply && (map (lambda (r) (equal? (bpf-reg-ref bpf-st r) (rv64-reg-ref rv64-st (regST r)))) regs)))
  (define pc-equiv #t) ; XXX: add pc equivalence
  ; XXX: this looks very sketchy because it's stronger(?) than what we need
  (define mem-equiv #t); XXX: (equal? ((bpf-mem bpf-st) addr) ((rv64-mem rv64-st) addr)))
  (&& regs-equiv pc-equiv mem-equiv))

(define RV_REG_T1 (bv 6 5))
(define RV_REG_T2 (bv 7 5))

; synthesis

(define (compile insn)
  (match insn
    [(ALU_MOV_X dst src)
     (build-list 2 (lambda (x) (??riscv (list dst src) #f)))]
    [(ALU_MOV_K dst imm32)
     (build-list (if use-pseudo-for-imm 3 4)
                 (lambda (x) (??riscv (list dst) imm32)))]
    [(ALU_ADD_K dst imm32)
     (build-list (if use-pseudo-for-imm 4 5)
                 (lambda (x) (??riscv (list dst) imm32)))]))

(define (??riscv regs imm32)
  (define tmpl
    (list
     (lui (??reg regs) (??imm 20 imm32))
     ; XXX: skip setting depth: (??imm 12 imm32)
     (addiw (??reg regs) (??reg regs) (??imm 12 imm32 0))
     (add (??reg regs) (??reg regs) (??reg regs))
     ; XXX: make slli/srli depend on imm32: (??imm 6 imm32)
     (slli (??reg regs) (??reg regs) (??imm 6 #f))
     (srli (??reg regs) (??reg regs) (??imm 6 #f))
     ; XXX: make lb/sb depend on imm32: (??imm 12 imm32)
     (lb (??reg regs) (??reg regs) (??imm 12 #f))
     (sb (??reg regs) (??reg regs) (??imm 12 #f))))
  (when use-pseudo-for-imm
    ; replace lui/addiw with li
    (set! tmpl (cons (li (??reg regs) (??imm 32 imm32 0)) (cddr tmpl))))
  (apply choose* tmpl))

(define (??reg regs)
  ; choose either a temporary or mapped register
  (apply choose* RV_REG_T1 (map regST regs)))

(define (??imm n imm32 [depth max-imm-depth])
  (define-symbolic* imm (bitvector n))
  ; shortcut: if imm32 is #f, no need to construct a bv expression
  (if imm32
      (extract (sub1 n) 0 (??host-imm32 imm32 depth))
      imm))

(define (??host-imm32 imm32 depth)
  (define-symbolic* host-imm (bitvector 32))
  (if (zero? depth)
      ; base: immedidate to be compiled or host immediate
      (choose* host-imm imm32)
      ; recursion
      ; XXX: add more operators
      (let ([op (choose* bvadd bvlshr)]
            [lhs (??host-imm32 imm32 (sub1 depth))]
            [rhs (??host-imm32 imm32 (sub1 depth))])
        (op lhs rhs))))

; pretty-printing

(error-print-width 1000)
(define (prettify x)
  ; This is a hacky way to tell the type of each field using bitwidth;
  ; A better way is to annotate the type in each instruction.
  (~a (cond
    ; register
    [((bitvector 5) x)(prettify-reg x)]
    ; shifting amount
    [(and ((bitvector 6) x) (! (term? x)))
     (bitvector->natural x)]
    [else x])))

(define (prettify-reg x)
  (define syms (symbolics x))
  (define r (if (= (length syms) 1) (car syms) #f))
  (cond
    [(constant? x) x]
    [(and (expression? x) r (unsat? (verify (assert (equal? x (regST r))))))
     (format "regmap[~a]" r)]
    [(eqv? x RV_REG_T1)
     'RV_REG_T1]
    [(eqv? x RV_REG_T2)
     'RV_REG_T2]
    [else x]))

; test

(define-symbolic s-mem (~> (bitvector 64) (bitvector 8)))

(define-symbolic s-bpf-regs (~> (bitvector 4) (bitvector 64)))
(define-symbolic s-bpf-pc (bitvector 64))
(define bpf-state (bpf s-bpf-regs s-bpf-pc s-mem))

(define-symbolic dst src (bitvector 4))
(define-symbolic imm32 (bitvector 32))

(define-symbolic s-rv64-regs (~> (bitvector 5) (bitvector 64)))
(define-symbolic s-rv64-pc (bitvector 64))
(define rv64-state (rv64 s-rv64-regs s-rv64-pc s-mem))

(define-symbolic addr (bitvector 64))

(define pre (&& (bvule dst (bv 10 4))
                (bvule src (bv 10 4))
                (equiv-state? bpf-state rv64-state addr)))

; get opcode from cmdline
(define argv (current-command-line-arguments))

(define opcode 'ALU_MOV_X)
(unless (zero? (vector-length argv))
  (set! opcode (string->symbol (vector-ref argv 0))))

(eprintf "Synthesize for BPF instruction: ~a\n" opcode)

(define bpf-insn
  (case opcode
    [(ALU_MOV_X) (ALU_MOV_X dst src)]
    [(ALU_MOV_K) (ALU_MOV_K dst imm32)]
    [(ALU_ADD_K) (ALU_ADD_K dst imm32)]
    [else
     (eprintf "Unknown BPF instruction\n")
     (exit 1)]))

; run bpf
(instruction-run bpf-insn bpf-state)

; compile bpf->rv64
(define rv64-insns (append (compile bpf-insn)))

; run rv64
(for ([x rv64-insns])
  (instruction-run x rv64-state))

(define post (equiv-state? bpf-state rv64-state addr))

; check asserts are trivially true
(void (check-unsat (verify (assert (apply && (asserts))))))

(define sol
  (synthesize #:forall (list s-bpf-regs s-bpf-pc s-rv64-regs s-rv64-pc s-mem addr (struct->vector bpf-insn))
              #:assume (assert pre)
              #:guarantee (assert post)))

; check there is a solution
(void (check-sat sol))

(when (sat? sol)
  (eprintf "\n")
  (for ([x rv64-insns])
    (define rv64-insn (evaluate x sol))
    (define vec (evaluate (struct->vector rv64-insn) sol))
    (define opcode (substring (symbol->string (vector-ref vec 0)) 7))
    (define args (vector-map prettify (vector-drop vec 1)))
    (eprintf "\t(~a\t~a)\n" opcode (string-join (vector->list args) " ")))
  (eprintf "\n"))
