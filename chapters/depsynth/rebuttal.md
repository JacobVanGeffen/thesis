We thank the reviewers for their helpful feedback. We will address two
common themes from the reviews, outline the changes we will make to the paper
based on the feedback, and then address reviewer-specific comments.

# Q1: Generality of a dependency-oriented approach

We acknowledge that the paper has only one detailed case study. We anonymized
that study to enable double-blind review, but the PC chairs have given us
permission to deanonymize it for this response. The "CloudKV" system we compare
against is ShardStore [Bornholt et al, SOSP 2021], a production storage node
that powers several industrial-strength systems at Amazon Web Services,
including the Amazon S3 object storage service. We built DepSynth to solve real
challenges we experienced while we were implementing and deploying ShardStore at
scale. As the case study highlights, DepSynth has proved valuable in identifying
and suggesting solutions for a number of problems in ShardStore's
implementation.

In their paper on Featherstitch [SOSP 2007], Frost et al write (emphasis ours):
"Write-before relationships [...] underlie **every mechanism** for ensuring file
system consistency and reliability from journaling to synchronous writes".
DepSynth builds on this insight by providing a synthesis tool for *automatically
developing* write-before relationships. Beyond the ShardStore case study, we
implemented a second log-structured file system (Section 6.3), and examined two
other production file systems to validate that dependency rules can prevent
crash consistency bugs there (Section 6.2). Between these results and the
FeatherStitch experience, which implemented several more dependency-based
storage system designs, we're encouraged that a dependency-based approach is a
strong foundation for a wide variety of systems. We will add a more explicit
discussion of this point to the paper.

# Q2: Developer effort and programming against the label API

With DepSynth, the user is still responsible for the crash consistency *design*,
and this is certainly not a simple task. DepSynth's synthesis-aided model allows
the user to focus on high-level design insights, and automatically fills in the
details of translating these insights into efficient crash-safe code. We've
seen, both in our own experience and that of other popular storage systems, that
this implementation effort is a frequent source of bugs and complexity even when
the consistency design itself is sound. Often these bugs arise when developers
add new optimizations to an existing implementation; we think of DepSynth as a
tool that runs not just once but every time a developer wants to make changes or
improvements to their storage system.

At the core of the DepSynth programming model are labels, which give each write
in a system an identity that we can use to apply ordering rules to them. There's
an inherent tension here, which we will make more explicit in the paper: more
labels require more effort on the part of the developer, but allow for
finer-grained and potentially higher-performance rules. As a data point, our
CloudKV case study in Section 6.1 required 13 distinct label names. These names
were generally easy to come up with; for example, writes that touch the on-disk
index should have a label that mentions the index. Based on that experience, we
think it would be feasible to automate label names either with a simple program
analysis (e.g., looking at method or module names) or at run time by inspecting
the call stack.

For label epochs, we observed that the storage systems we looked at have some
natural notion of "epoch" that we can apply. For example, a request-oriented
system like CloudKV can have an epoch per request, or a journaling file system
can have an epoch per system call. This approach may require modifications to
the implementation if it lacks an existing notion of an epoch or sequence
counter (for example, we added an epoch counter to CloudKV).

# Proposed changes

We will make the following changes to the paper based on the reviewer feedback:

1. Add an explicit discussion of performance in the case study, with data
   highlighting that there is little to no performance difference in the 1% of
   schedules that differ between CloudKV and DepSynth's rules.
2. Provide more details about the implementation effort for the case study
   (along the lines of Q2 above).
3. Better emphasize that DepSynth still requires users to come up with the
   high-level insight about their crash-consistency design.
4. Expand on how DepSynth can also guarantee durability properties (properties
   about what data *must* be on the disk after a crash) by including flushes in
   the disk model.

We will also address the lower-level feedback and changes as discussed below.
We expect all these changes to be comfortably possible within the current OOPSLA
round.

---

# Reviewer A

> Example 3.6 was a little confusing to follow. I believe that the figures have
> an “off by one” error. For instance, the (0,42) block is in $P_{initial}$
> where no crashes happen, so it should be shown in all figures. The crash
> schedule in point (4) allows the block (1,81) to be written but it is missing.
> And so on.

Great catch! Yes, there's an off-by-one error here; the writes from
$P_{initial}$ are always on disk.

> Line 348, “crash states” what are these? I assume just all the system states.

Yes, crash states are all the reachable system states, including those that can
only arise due to a crash. We'll clarify this definition.

> Line 679, “partial order” was called later “total order”. Please make it
> consistent.

Thanks, yes, this line should say "total order". Phase 1 constructs a total
order, and then Phase 2 removes edges from that total order to make it a partial
one.

> Line 744, “our implementation resolves cycles”. From the previous paragraphs,
> it seemed that this could be done but was not. Maybe clarify a bit.

We'll clarify the writing here. DepSynth *does* resolve cycles; the previous
paragraphs are muddy about this point.

> Were there scenarios where labeling the writes was non-trivial or required
> rewriting the implementation a little to allow for finer-granularity labeling
> (e.g., say, manipulating the epoch counter)? Do you see automating label
> generation to be feasible? (e.g., maybe all writes in the same function body
> have the same epoch).

See Q2.

> The pruning mechanism for total orders eliminates prefixes that are shown to
> violate the crash consistency property. Can one adopt a notion of
> counterexample generalization here and try to determine which part (e.g.
> subsequence) of the prefix is the real root cause of the problem so that
> subsequence (as opposed to a prefix) is used to rule out future total orders?
> You seem to hint about that in the implementation section (Line 773) with
> necessary edges.

As you rightly point out, the necessary edges pre-computation is one
instantiation of this idea. We did experiment with counterexample generalization
during the search, but found it too expensive to infer high-quality
generalizations. This is an area we're interested in exploring further, but for
now, we found empirically that our more naive backtracking approach was fastest.

# Reviewer B

> The paper lacks information on the efforts of implementing against the
> specific API (the model makes operations look independent but I suspect
> meta-data re epochs has to be managed) and for coming up with appropriate
> litmus tests, and also does not detail the consistent() predicates, neither
> qualitatively in terms of model nor quantitatively in the context of the case
> study.

See Q2 for the label API.

For litmus tests, we've found a large corpus of randomly or systematically
generated tests to be effective in practice, as suggested by other work on crash
consistency like CrashMonkey [Mohan et al, OSDI 2018]. There are off-the-shelf
tools for generating such tests, but we did not find it difficult to write our
own.

For consistency predicates, these are necessarily coupled to the design of the
storage system, but a reasonable analogy is to think about implementing a small
`fsck`-like checker (which most storage systems already have). For example, the
consistency predicate for the production CloudKV implementation in the case
study is about 87 lines of Rust code, while the predicate for our
re-implementation is about 29 lines of Racket code.

> The paper includes no performance result at all, making it hard to grasp
> whether the generic methodology and its generic form of runtime verification
> are performance-wise viable. As the evaluation shows/discusses, the original
> system compared against used a simplified internal representation of
> dependencies/conflicts which prohibited certain correct schedules, but this
> can very well have been done for performance reasons. Even with 99% same rules
> (after fixes) there may still be very important differences
> (performance-wise).

It's a great observation that small differences in rules can lead to big
differences in performance (the Featherstitch paper saw a similar effect).
DepSynth tries to address this effect by searching for a minimal happens-before
graph, on the assumption that fewer ordering edges is likely to give better
performance, but this is only a heuristic.

In our case study, we confirmed with the engineers responsible that their
simplifications weren't for performance reasons, but rather because it is more
difficult for them to reason about the correctness of the more complex graphs; a
synthesis tool like DepSynth helps alleviate this complexity–performance
trade-off. We can't make an apples-to-apples performance comparison in the case
study because our Racket re-implementation is not production quality. We did
manually inspect the remaining 1% of different schedules and don't expect them
to lead to a performance difference in practice, as the differences only involve
slightly stronger orderings on some rare metadata writes. We'll add this detail
to the paper.

> The paper really only presents 1 case study of the approach. Without trying to
> understand why the system couldn't be named, I can't understand why that
> system had to be chosen if there are enough systems to choose from where this
> methodology would be applicable/pay off. I'd find it hard to believe that the
> authors for whatever reason were connected to several industrial-strength
> systems.

See Q1.

> Independently of any of the above, while I'm sure that there are many
> candidate systems for the approach (conceptually speaking) I personally feel
> that choosing the cloud as a target scenario is suboptimal -- the cloud
> paradigm rather promotes the use of replication for providing high
> availability in the presence of failures in lieu of relying entirely on
> recovery (as the paper itself states, valid updates can get lost even if -- or
> especially when -- consistency prevails with crash recovery).

We agree. The ShardStore paper makes a similar argument that single-node crash
consistency is not critical to durability in replicated cloud storage systems
("Why be crash consistent?", page 4). They write: "We instead see crash
consistency as reducing the cost and operational impact of storage node
failures. Recovering from a crash that loses an entire storage node’s data
creates large amounts of repair network traffic and IO load across the storage
node fleet. Crash consistency also ensures that the storage node recovers to a
safe state after a crash, and so does not exhibit unexpected behavior that may
require manual operator intervention." In other words, in a replicated storage
service it's OK for recent valid updates to be lost in a crash, but it's
expensive and burdensome for the entire node's data to be rendered inaccessible
by a crash. DepSynth helps developers prevent the latter failure mode.

> def 3.2 "then the cache ensures the write to 𝑎1 does not persist
> until the write to 𝑎2 is persisted on disk." does the write
> return to the application though or is it blocked?

The write returns to the application immediately, in the same way that `write`s
to file systems today are (by default) only staged into the page cache before
returning, and so `write` returning does not say anything about durability.

> line 297 "such as providing transactional semantics" I think this sounds a lot
> easier here than it is to do (efficiently)

Agreed; an efficient transaction system does not simply fall out of this API.
Our point is just that this epoch-based model provides tools that can be helpful
for such systems. We'll clarify the writing here.

> line 391 was the \rightarrow notation introduced before?

This is logical implication between boolean variables $s_i$ and $s_j$.

> line 528 please elaborate on why synthesizing rules for a set
> of tests at once would not yield cyclic dependencies whereas by
> synthesizing rules for each of the same tests at a time that's possible
>
> line 728 please elaborate on why the rules generated for each test are
> guaranteed to be acyclic?

See lines 658-660 of the paper. The intuition is that for a single test, we only
ever consider (subsets of) total orders, which are acyclic by definition, and so
the only way cycles can arise is when generalizing from a happens-before graph
into a set of rules (line 643). The algorithm includes acyclicity checks to rule
out these cases.

When combining rules synthesized independently for multiple tests, there is
nothing preventing the union from being cyclic. For example, one test may
synthesize a rule $a \rightarrow_= b$ while another test synthesizes a
contradictory rule $b \rightarrow_= a$. Presenting both tests to the synthesizer
at once prevents this contradiction by the argument above.

> line 770 and following how is the set of necessary ordering edges computed?

For each pair of writes in a test, we use an SMT solver to check whether a graph
lacking only that edge is crash consistent; if not, we know the edge is
necessary for consistency. While this check sounds expensive ($O(n^2)$ edges
between $n$ writes), it pays off during the search as each edge might be
violated many times.

> I understand the simplifying assumption of 1 storage entity per block,
> but this hardly holds in practice. What happens then?

This simplifying assumption is only made for the overview example in Section 2.
DepSynth assumes that single-block writes are atomic (as all real-world storage
systems do), but otherwise does not make any assumptions about blocks. For
example, CloudKV often stores more than one object per block.

> Are both < and > epoch predicates necessary? Can't one be achieved via
> the other by inverting the parameters?

Not quite. Consider a rule $a \rightarrow_< b$ and two writes with labels
$l_1 = (a, 1)$ and $l_2 = (b, 2)$. This rule requires that $l_1$ persists to
disk after $l_2$. The inverted rule $b \rightarrow_> a$ still matches these
writes, but has the opposite effect: it requires that $l_2$ persists to disk
after $l_1$.

We actually had the same question while drafting the paper (we originally did
not include the $<$ predicate), so we'll add an explicit note about this.

# Reviewer C

> The user is still required to provide labels, and in general design the
> mechanisms that lead to crash consistency (e.g., log data structures), so it
> is not clear how much of the burden is actually lifted from the user.

See Q2.

> It wasn't clear to me that a "consistent state" predicate is expressive enough
> to capture crash tolerance. Specifically, it seems that it cannot capture the
> correctness of user facing sync/flush operations, and possibly other
> guarantees that storage system provide to users (e.g., transactions).

This is correct, and gets at the distinction between consistency and durability
properties. Flush operations are durability mechanisms: they allow a system
to guarantee data is on persistent media. However, flush operations are also
often used as (crude) consistency mechanisms, as they are one way to enforce
orderings between writes (before vs after the flush).

DepSynth *can* model durability properties by adding a `flush` operation to the
disk model in Section 3.1 and extending the consistency predicates with an
oracle that is aware of what data is *expected* to be persistent. In fact, our
actual implementation does exactly this, but we elided it from the writeup for
simplicity so we could focus on illustrating consistency properties. We'll add
this detail back to the paper.

> It is not clear if the focus on write dependencies and assuming a
> dependency-aware buffer cache do not make the paper's contribution only
> applicable to a very specific class of crash-tolerant storage systems.

See Q1.

> I found the crash model of Section 3 to be very surprising. It seems that if a
> crash occurs during a write, the effect of that write is ignored, but
> afterwards the program continues to execute normally. However, in reality, a
> crash would also delete all of the in-memory data (e.g. program variables),
> and the program would not continue from the same point. Instead, a crash
> recovery procedure would be initiated that would restore the in-memory state
> from the disk (and can even perform some cleanup operations on the disk).

We model crashes this way (inspired by Yggdrasil [Sigurbjarnarson et al, OSDI
2016]) to simplify our logical encoding by removing the need to explicitly model
a program counter. The trick is that, even though the program continues
executing, it can no longer make persistent updates that will be visible after
rebooting at the end of the execution. We assume those updates are the only
possible side effects of the execution, and so the additional execution is
unobservable by the consistency predicate.

> The paper also seems to implicitly assume that writes may only depend on
> writes that were previously issued, even though that is never stated. Without
> this assumption, a dependency-aware buffer cache can never send any write to
> the disk, since there is always the potential of a future write to arrive that
> must be persisted prior to it, due to a dependency rule. In general, some form
> of static analysis would be required to ensure that for a given rule set and
> implementation code, a write can only depend on previous writes, but the paper
> does not mention such an analysis.

This is a great observation that we'll highlight better in the paper. In our
evaluation, we found that DepSynth never generated rules that used the $<$ epoch
predicate, and so we could strengthen our formalization slightly to make this
forward progress assumption explicit.

> I found the algorithm of sections 4.2 and 4.3 to be overly complex. What is
> the advantage of searching over total order and graphs, rather than directly
> searching over sets of rules? Consistency is also monotonic w.r.t. sets of
> rules.
>
> Would an algorithm that directly considers sets of rules not be more efficient
> than considering total and partial orders (many of them not realizable by
> rules)?

We originally implemented DepSynth exactly this way: a counterexample-guided
synthesis engine over the rule language. We found that while it worked for small
examples, it scaled poorly to tests that required larger rule sets. The problem
is that it's difficult to generalize a large counterexample set of rules into
feedback that guides the search towards a correct solution (e.g., if a rule is
in the counterexample set, should we remove it, flip it, mutate it some other
way, or add another rule entirely?). In contrast, the happens-before graph
approach gives us a natural feedback mechanism: at each step, we know we've only
changed one edge in the graph, and so can infer that that edge is the cause of a
consistency problem.

Also, note that our rule generation algorithm can realize any total or partial
order (it is a purely syntactic transformation from the happens-before graph).

> How many labels are there in your evaluation?

See Q2.
