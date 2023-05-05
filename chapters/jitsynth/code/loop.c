struct tgt_insn *compile(struct src_insn *insn,
                         struct tgt_insn *tgt_prog) {
  switch (insn->op) {
    case 0x0:
      tgt_insn[0] = F0(insn);
      tgt_insn[1] = F1(insn);
      (*@{\vdots}@*) 
      break;
    case 0x1:
      (*@{\vdots}@*)
  }
  return tgt_prog;
}
