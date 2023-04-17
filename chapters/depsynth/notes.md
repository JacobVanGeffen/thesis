* angelic crash consistency story -- synthesis is an impl detail
    * weird because you still have to think about crashes somehow, otherwise why would you bother implementing a journal at all?
    * can we automatically figure out what data needs to be journaled/COW
        * persistent data structure synthesis, can invent new writes/structures if needed
* posix fs
    * can we do a non LFS? cow or just ext2-style
    * make it run, show it's useful -- fuse? run xfstests or something
    * show it's crash consistent -- crashmonkey or explode
* why can't a solver handle this problem?
    * what makes it different from memsynth? harder to get partial interpretations?
    * need to show that a strawman solver-aided version doesn't work
        * 10 bools per test, 10 tests = forall quantifier over 100 bools?
        * strong consistency properties are lopsided, reject almost all schedules -- should be great for CEGIS
    * understand what optimizations are necessary and why
* evaluating away the impl by using traces of writes is very powerful
    * concurrency? search doesn't care how the trace was generated. could run stateless model checker to gather lots of traces
    * get trace from real impls. don't need the model at all.
* story for hardware changes
    * PMR to SMR adds stronger ordering, so isn't super interesting (anything consistent on PMR is consistent on SMR)
    * block device to pmem device? atomicity changes, might need stronger constraints. also need to model cpu cache/eADR.
* distributed consistency -- labels look a lot like messages in a message passing system
    * neteork sequencer is equivalent of the buffer cache? but doesn't have a global view
