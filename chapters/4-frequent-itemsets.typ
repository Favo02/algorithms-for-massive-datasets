#import "../template.typ": *

= Frequent Itemsets

The study of frequent itemsets originated from techniques designed to analyze customer behavior.
The fundamental objective is to *exploit statistical patterns* in purchasing data to understand how items relate to one another.

Patterns often emerge in "baskets" (the set of items a customer buys in a single transaction):
- *Predictable associations:* Customers buying hamburgers are statistically likely to buy ketchup.
- *Unintuitive associations:* Data analysis famously revealed "Beer and Diapers" or "Torch-lights and Lollipops" as statistically significant pairs.

#example[
  This could also be used for items suggested by Amazon or Netflix in the homepage.
  Spoiler: it is not used, not because it does not work, but because there are even more effective strategies.
  One of these is User Collaborative Filtering, using similar items (last chapters).
  Items are users, and after finding similar users simply suggest the same things bought by similar users.

  Not only for commercial purposes, but also medical.
]

== Formalization

To transform these observations into actionable knowledge, we define an *Association Rule*.

#theorem("Association Rule")[
  The form of an association rule is:

  $ underbrace(A, "set of items") -> underbrace(b, "item") $
  Where:
  - $A$ is a *set of items* (the antecedent).
  - $b$ is a *single item* (the consequent).
]

#informally[
  The implication of this rule is that if all of the items in $A$ appear in some basket, then $b$ is "likely" to appear in that basket as well.
]

To formalize the notion of "likely", we first define the *support* of an itemset.

#theorem("Support")[
  The *support* of an itemset is the count of baskets that contain all items in it. For a rule $A -> b$, we define:
  $ "Supp"(A union {b}) = |{B in cal(B) : A union {b} subset.eq B}| $

  where $cal(B)$ is the set of all baskets.
]

#note[
  If we have 1,000,000 baskets, the support of the rule $"torch" -> "lollipop"$ is the exact number of times both items appear together.
  This helps us ignore rare, coincidental occurrences.
]

Now we can define the *confidence* of an association rule $A -> b$.

#theorem("Confidence")[
  The *confidence* of a rule $A -> b$ is the ratio:
  $ "Conf"(A -> b) = ("Supp"(A union {b}))/("Supp"(A)) $
]

#note[
  A confidence of $0.2$ means that $20%$ of the time a customer buys a torch, they also buy a lollipop.
  This conditional probability allows us to gauge the predictive power of the rule.
]

Of course, the denominator is always bigger than the numerator.
When the ratio is closer to $1$, we are pretty confident that the rule is good.

#warning[
  There are exceptions!
  We can have an association rule with a high confidence but that is useless.

  #example[
    Each rule with $"item" -> "plastic bag"$.
    A plastic bag is associated with any basket.
    Regardless of the item, the plastic bag is associated with it.
  ]

  So we need another metric.
]

#theorem("Interest")[
  The *interest* of a rule $A -> b$ is defined as the difference between its confidence and its expected probability based on the overall frequency of $b$.

  $ "Interest"(A -> b) = "Confidence"(A -> b) - "Supp"({b})/("number of baskets") $

]

- *Positive Interest:* The presence of $A$ increases the probability of finding $b$.
  This is our primary target for finding meaningful associations.
- *Negative Interest:* The presence of $A$ makes $b$ *less* likely (items are "competing" or mutually exclusive).

=== Frequent Itemsets

Before generating rules, we must find *Frequent Itemsets*.

#theorem("Frequent Itemset")[
  An itemset $I$ is "frequent" if its support exceeds a chosen threshold $s$:
  $ "Supp"(I)>=s $
]

#note[
  Once we identify a frequent itemset $I$, we can generate candidate rules by testing every $j in I$.
]

But how do we find frequent itemsets?

== Why Brute Force Fails

The "Naive" approach would be to scan the basket file and maintain a counter for every possible itemset.
However, we quickly run into a *Space Complexity* wall.

- With $n$ distinct items, there are $2^n$ possible itemsets.
- A small grocery store has hundreds of items, but a giant like Amazon has millions.
  $2^n$ becomes astronomically large, far exceeding the RAM (or even disk space) of any modern system.

If we limit ourselves to finding only *frequent pairs*, the complexity drops to:
$ binom(n, 2) = (n(n-1))/(2) approx (n^2)/(2) $

#informally[
  For a marketing campaign, we don't need all possible itemsets, but a few pairs of interesting items are enough.
  But this is a very specific use case.
]

While quadratic complexity is significantly better than exponential, it is still taxing for Big Data.

#example[
  Suppose we have 2 GB of RAM ($2^31$ bytes) and use 4-byte integer counters.
  To store counters for all pairs:
  $ 4 times (n^2)/(2) = 2n^2 $
  Setting $2n^2 <= 2^31$ gives $n <= sqrt(2^30) approx 32,768$.
]

#note[
  A supermarket with 33,000 items might barely fit its pair-counters into RAM, but any larger inventory will crash the system.
]

Here we want to find *all* frequent sets exactly.
To escape the quadratic memory wall without losing accuracy, we need to filter the itemsets we track.

This leads us to a family of algorithms designed to prune the search space, starting with the fundamental *A-Priori Algorithm*.

== Apriori Algorithms

It is organized into two distinct main steps.

#warning[
  #note[
    Each step requires a full pass over the basket file. Since the file sits in mass memory (hard disk), the execution time is dominated by Input/Output (I/O) operations.
  ]
  For these reasons, we will measure the complexity of these algorithms as number of passes over the baskets.
]

The Apriori algorithm has a complexity of $2$.

=== Pass 1

The goal of the first pass is to *identify which individual items are frequent*.

The first scan is meant to build two auxiliary data structures:

1. *Item Dictionary:* a mapping between items names and a progressive set of natural numbers (progressive IDs)$ "items" -> NN $

2. *Frequency Table:* A table where `Column 1` is the ID and `Column 2` is the count.

As we scan the baskets, we build these dynamically.

- If an item is new, assign it a new ID.
- If it exists, increment the counter.

#note[
  These structures are in the order of millions, so in the order of megabytes.
  We have plenty of free RAM for the second pass.
]

We now do some filtering, exploiting the monotonicity property.

We check which items exceed the support threshold $s$.

- *Non-Frequent items:* Labeled as `-1` (or discarded).
- *Frequent items:* Assigned a new, dense progressive ID ranging from $1$ to $m$ (where $m < N$).

#note[
  How does this scale? Linearly with the number of *distinct* items.
  Even in a worst-case scenario with 1 million distinct items, we are talking about *Megabytes* (maybe 100MB), not Gigabytes.
  We are using a tiny fraction of RAM, leaving plenty of free space for the heavy lifting in Pass 2.
]

Before Pass 2, we need a theoretical justification for ignoring certain pairs.

Given two baskets (sets of items), one subset of the other:
$ A, B, quad A subset.eq B quad --> quad "supp"(A) >= "supp"(B) $
If $B$ is a frequent itemset, it means that the support of $B$ is greater than the threshold:
$ "supp"(B) >= s $
meaning also $A$ is:
$ "supp"(A) >= s $
meaning $A$ is *frequent*.

#theorem("Theorem")[
  First order logic theorem:
  $ (A -> B) <--> (not B -> not A) $
]

We can invert this logic to build a *filter*:

$ A "is not frequent" --> B "is not frequent" $
If a single item inside a basket is not frequent, it *cannot* be part of a frequent pair.
There is no point in counting pairs involving that item.

=== Pass 2

Now we perform the second scan of the basket file.

For each basket, we look at the items inside. Thanks to the renumbering in Pass 1, the algorithm only processes items that have a valid ID:

$ forall i in B | i " is frequent", forall j in B | j "is frequent", i != j, quad "consider pair" (i, j) $

The trivial way is to organize the indexes as a matrix $C$, so $c_(i j) += 1$.

*Are we wasting space?*

==== Triangular Matrix Optimization

If we use a standard matrix for $C$, we have two problems:

1. *Symmetry:* $C[i, j]$ is the same as $C[j, i]$. We don't need to store both.
2. *Sparseness:* We only care about frequent items (which we solved by remapping IDs), but a full square matrix still scales quadratically.

Instead of using $c_(i j)$ with $i j$ as ID, we can use $c_(tilde(i) tilde(j))$ with $tilde(i), tilde(j)$ as the new ID.

But we are still wasting a lot of space, because the matrix both contains $tilde(i) tilde(j)$ and $tilde(j) tilde(i)$.

Since the order of indices doesn't matter (the pair ${A, B}$ is the same as ${B, A}$), we can impose a *Lexicographic Order* (always store such that $i < j$).
This allows us to store only the lower (or upper) triangular part of the matrix.
Instead of a 2D array, we can map the 2D coordinates to a 1D array index:
$ k = (i-1)(n - i/2) + j - i $
This saves roughly half the space.

With this data structure the problem is solved: we can just browse the data structure and emit all pairs.

Are we missing anything?

- *False Negatives?* No. The monotonicity property guarantees that we never filter out a pair that *could* have been frequent. If a pair was destined to be frequent, both its constituent items *must* have survived Pass 1.

- *False Positives?* No, because we are actually counting the occurrences in Pass 2.

Does it always work? No!

#note[
  The problem for the trivial algorithm was that the number of counters was too much, so we applied a filter on the pairs we count.
  But we have no guarantee that this filtering actually reduces enough the number of pairs processed.
]

So, if the algorithm works, we have a correct solution, but the algorithm could crash because of the amount of RAM required is too much.

We could also have items that are frequent alone but are never bought together, so we could have some $0$ entries in the triangular matrix.

*We need something robust to sparseness*.

We already seen something similar during PageRank, instead of storing a matrix we store a triple $(tilde(i), tilde(j), "counter")$.
Where the counter is $0$ we discard the triple.

With this representation, we have to find the triple in memory (if it exists) and modify it.
We don't have immediate access anymore.
We could use hash functions to build an index on these indices to get immediate access to the location of the triples.

=== Hash Table Approach for Triples

To store triples $(i, j, k)$, we introduce a hash function $h$ that maps the triple to a bucket.

$ (i, j, k) -> h(i, j, k) -> "Bucket" $

Since hash functions inevitably produce collisions, each bucket must point to a *linked list* containing the actual triples and their counts.

- *Collision Handling:* Triples falling into the same bucket are aggregated in a linked list.
- *Operation:* To increment a count, we compute the hash. If the node exists in the list, we increment it. If not, we append a new node.

#note[
  Strictly speaking, this is not constant time because we must traverse the linked list. However, if the number of buckets is sufficiently large relative to the number of frequent triples, the linked lists remain short and we operate in a regime of *quasi-constant access time*.
]

=== Trade-off: Triangular Matrix vs. Hash Table

We now have two distinct methods for organizing counters in memory:
1. *Triangular Matrix:* Good for dense data.
2. *Hash Table:* Good for sparse data (exploits sparsity).

/ Space comparison:
  - Triangular matrix: 1 integer per each entry
  - Hash table: 3+ integers per each entry (the space for the indices, pointers, and the hashmap structure)

The best approach depends on the sparseness of the matrix.
If the matrix has less than $1/3$ of empty entries, then the triangular matrix is preferable.

#example[
  $n = 100,000$ items, $b = 10,000,000$ baskets (10 items each).

  *Option A: Triangular Matrix*
  $ binom(n, 2) approx 5 times 10^9 "counters" $

  *Option B: Hash Table (Worst Case)*
  - Pairs per basket: $binom(10, 2) = 45$
  - Total pairs: $10^7 times 45 = 4.5 times 10^8$
  - Space per pair (approx 3 ints): $4.5 times 10^8 times 3 = 1.35 times 10^9$ integers

  The hash table requires less than $1/3$ of the space of the matrix. Even considering the worst case, using the hashmap approach is preferable as there are more than $2/3$ empty entries.
]

=== Expanding Beyond Pairs

In principle, we can apply the same idea to triples $(i, j, k)$, adding a new pass.
We increase the counter related to ${i, j, k}$ if and only if:
- ${i}, {j}, {k}$ are frequent as singletons
- ${i, j}, {j, k}, {i, k}$ are frequent as pairs

#note[
  The main property exploited by this approach is *monotonicity*.
]

We can build up to any cardinality of the sets, simply by continuing iterating from the previous step. Each stage increases the dimension by $1$.

The general A-Priori workflow is an iterative sequence of two operations:
1. *Filtering:* Pruning the candidates based on support.
2. *Construction:* Generating new candidates of size $k+1$ from frequent sets of size $k$.

We proceed iteratively ($L_1 -> C_2 -> L_2 -> C_3 -> ...$). Each stage needs to do one complete pass on the baskets, so the complexity scales linearly with the cardinality of the resulting sets wanted.

#note[
  The data structures should be adapted for higher dimensions: we can use pyramidal matrices and quadruples instead of triples.
]

=== Correctness

We said that this algorithm is exact.
An algorithm is exact if it gives the right answer for each input instance.

When this algorithm ends, it gives always the right output.
Are we sure that it always ends?

No, we could have too many frequent items and run out of space for the counters, resulting in a crash of the algorithm.

#warning[
  A-Priori is an *exact algorithm*: if it terminates, it produces the correct result. However, it may fail before finishing due to:
  - *Integer Overflow:* Unlikely (4 bytes is usually enough for counts).
  - *Memory Exhaustion:* This is the real danger. Hash tables allocate memory dynamically, and we might exhaust RAM while appending new nodes to collision lists.
]

We can use other algorithms, based on Apriori algorithms that perform more aggressive filtering.

== Park-Chen-Yu Algorithm (PCY)

The idea is to exploit the free memory at the end of the first phase (when we still don't have a triangular or sparse counters in memory).

#note[
  During Pass 1, we only count singletons (items). This uses very little RAM. Most of the memory is idle.
]

=== PCY Pass 1

We utilize the idle memory to maintain a *Hash Table* of pair counts alongside the item counts.

We see the free memory as a long vector of integers (all starting from $0$) and use a hash function $h$ that hashes a pair of items $(i, j)$ into a position in the integers array.

The first two structures are constructed as for the Apriori algorithm, but during the scan we also increment the integer at the position of the items hashed:
$ h(i, j) quad forall i, j in B quad forall B in "baskets" $

=== Between Pass 1 and Pass 2

At the end of Pass 1, we analyze the hash buckets against the support threshold $s$:
- If $"Array"[h(i,j)] < s$: we know for sure that the pair $(i, j)$ can be discarded, as its support is for sure less than the threshold $s$.
- If $"Array"[h(i,j)] >= s$: we don't have any actual information on the pair (as a cell could be pointed by multiple pairs because of collisions), but we keep it for further processing.

#note[
  Objection: we filled the whole remaining memory with the vector, where do we store the triangular matrix for the counters?
]

*Compression:* We do not need the actual counts for Pass 2, only the boolean status (Frequent/Not Frequent). We compress the integer array into a *Bitmap*:
- If count $>= s ->$ bit = 1
- If count $< s ->$ bit = 0

*Space Gain:* An integer (32 bits) is replaced by 1 bit. We reclaim $31/32$ of the memory to use for the actual counters in Pass 2.

=== PCY Pass 2

Now we count pairs $(i, j)$ only if:
1. $i$ and $j$ are frequent items
2. The bit corresponding to $h(i, j)$ is 1

This "advanced filtering" allows us to discard many candidate pairs that A-Priori would have counted, allowing us to handle larger datasets or lower support thresholds without running out of RAM.

After generating the counters matrix/hashtable, we can compress that using the same idea: a *bitmap*. This way we can store information about previous passes using little space.

Each iteration adds a bitmap, eventually we won't have enough space to perform another pass and store the hashmap.

This approach is called *multi-stage*.

=== Multistage Algorithm

Even with PCY, the bitmap might not filter enough pairs if there are too many collisions (i.e., too many "false positive" buckets).

*Idea:* Iterate the hashing process to filter more aggressively.
1. *Pass 1:* Standard PCY (creates Bitmap 1).
2. *Pass 2:* Do not count pairs yet. Instead, use a *second hash function* $h_2$ and a new hash table. Only hash pairs that pass the Bitmap 1 check.
3. *End of Pass 2:* Create Bitmap 2.
4. *Pass 3:* Count pairs that pass *both* Bitmap 1 and Bitmap 2.

*Trade-off:* We reduce the number of counters needed (preventing memory overflow), but we pay the price of an *extra disk scan* (Pass 2 is now just for hashing).

=== Multihash Algorithm

Instead of using only one vector of integers with one hash function, we divide the remaining memory in two vectors and use two different hash functions that increase the counters of pairs.

*Idea:* Perform two hash filters *in parallel* to avoid the extra disk scan.
1. *Pass 1:* Split the available memory into two halves.
2. Run two hash functions ($h_1, h_2$) simultaneously into two separate hash tables.
3. *End of Pass 1:* Convert both tables into two bitmaps.
4. *Pass 2:* A pair is a candidate only if *both* $h_1(i, j)$ and $h_2(i, j)$ buckets are frequent.

*Trade-off:*
- Since we split memory, each hash table is half the size of the PCY table.
- This increases collisions within each individual table.
- However, the *intersection* of valid buckets might still be smaller than a single PCY filter.
- *Benefit:* No extra disk scan required compared to Multistage.

== Sampling-Based Approaches

Up to this point, we assumed we had to process the entire dataset (stored on a hard disk). However, strict exactness might be traded for efficiency by working with a *sample* of the baskets in RAM.

If we could store all the baskets in main memory, then we would be able to compute the frequency of each triple, quadruple of any cardinality by just doing some scans of the Apriori algorithm.

If we sample the baskets and put that sample in memory, we have no guarantee that the algorithm is exact anymore. This can be seen as a predictor: it outputs some sets which it expects to be frequent.

=== The Risk of Errors

Since we are using a statistical estimator, the output is not guaranteed to be exact. We have the two classical errors:
- *False Positive (FP):* sets that are not frequent but are output of the algorithm
- *False Negative (FN):* actual frequent sets that are not in output of the algorithm

#warning[
  *False Positives* are "less bad" than False Negatives. Why? Because we can treat the sample output as a set of *Candidate Sets*. With one full scan of the dataset, we can verify their actual support and remove the FPs.

  *False Negatives* are fatal. If the algorithm doesn't propose a set, we cannot verify it later. It is simply lost.
]

=== Sampling Strategy

To minimize variance, the sample must be truly random. Simply taking the "first $N$ rows" of a file is dangerous because files often have temporal or logical ordering (e.g., Christmas sales grouped together), which would bias the sample.

A simple effective way for sampling is to just select each basket with a certain probability.

Once the sample is in RAM, we can run Apriori algorithm, given that we have enough free space to store the auxiliary data structures.

== Savasere-Omiecinski-Navathe Algorithm (SON)

The SON algorithm provides a way to use sampling *without* producing False Negatives. It is an exact algorithm that lends itself perfectly to parallelization (MapReduce).

=== Algorithm Structure

1. *Partitioning:* We virtually divide the baskets file into chunks of equal size. Each chunk represents a "sample" of proportion $p = 1/k$.
2. *Local Processing:* Each chunk is brought into RAM and the Apriori algorithm is run with a scaled threshold $p s$.
3. *Union of Candidates:* An itemset is a *global candidate* if it is frequent in *at least one* chunk.
4. *Verification:* Scan the entire dataset to count the support of these global candidates and filter out False Positives.

#note[
  We need to scale the support threshold $s$, dividing it by the number of chunks, resulting in $p s$.
]

#note[
  This is not really a sampling algorithm, as the whole baskets file is processed.
]

=== Proof of Correctness (No False Negatives)

It is obvious that we cannot have FP, as we explicitly removed them in the verification step.
But what about FN?

#theorem("No False Negatives in SON")[
  If an itemset $I$ is frequent in the whole dataset ($"Supp"(I) >= s$), then there exists at least one chunk $C_i$ where the support of $I$ in that chunk is at least $p s$.
]

#proof[
  Let's suppose that a FN $I$ exists.
  $I$ is frequent in the basket file, but $I$ is not in the output.
  Meaning it was never in output of the processing of each chunk: $I$ is not frequent in *any* chunk.
  $ forall "chunk" c, quad "Supp"_c(I) < p s $

  $
    "Supp"(I) & = sum_c "Supp"_c(I) \
              & < sum_c p s \
              & < p s dot 1/p \
              & < s
  $

  Because $I$ is frequent, it must be $"Supp"(I) >= s$, which is a contradiction. $qed$
]

=== Implementation: MapReduce

In the case that the basket file is so big that it cannot even fit on the disk, we can compute these using MapReduce. It requires *two* MapReduce jobs chained together.

*Job 1: Candidate Generation*

$ "chunk" --> #rect[1st MAP] --> (1, underbrace(C, "candidate set")) space forall "candidate set" C $

#note[
  All the chunks share the same key!
]

Then we remove duplicate sets using a reduce:
$ (1, (C_1, C_2, ...)) --> #rect[1st REDUCE] --> (1, C'_1), ..., (1, C'_k) $

*Job 2: Verification*

$ "chunk" --> #rect[2nd MAP] --> (c, v) $

$ (c, (v_1, v_2, ...)) --> #rect[2nd REDUCE] --> (c, sum v_i) "if" sum_i v_i >= s $

== Toivonen's Algorithm

Like the Apriori algorithm, it gives exact results.
But on certain inputs, it cannot calculate a result (it does not crash or goes in an infinite loop, it just stops without producing a result).

=== The Setup

1. It brings in RAM a basket sample of relative size $p$.
2. It runs Apriori algorithm (or a variant) with threshold $p s alpha$, where $0 < alpha < 1$ (e.g., 0.8 or 0.9).

#note[
  The idea is that by playing with $alpha$ we play with the fact that the algorithm could not end. We act "permissively" to include more candidates, reducing the chance of False Negatives caused by sampling variance.
]

=== The Negative Border

Then, on the candidate sets we compute a *negative border*: a group of sets that are *not* frequent, but whose immediate subsets are frequent in the sample.

#theorem("Negative Border")[
  An itemset $I$ is in the Negative Border if:
  1. $I$ is *not* frequent in the sample.
  2. *All* immediate subsets of $I$ (sets created by removing exactly one element) *are* frequent in the sample.
]

#note[
  / Immediate subset: subset obtained by removing exactly one element.

  The empty set is always considered frequent.
]

#example[
  Items: $ A, B, C, D, E $
  Frequent sets: $ {A}, {B}, {C}, {D}, {B, C}, {C, D} $
  The negative border: $ {E}, {A, B}, {A, C}, {A, D}, {B, D} $
]

=== Verification and Failure

The idea of the negative border is to scan the baskets file and keep track of the actual support for all the candidate sets and the negative border.

After the full scan:
1. *Filter Candidates:* The support for the candidates is used to remove FP. Keep those with $"Supp"(I) >= s$.
2. *Check Negative Border:*
  - If the actual support for *all* the negative border is less than the threshold, then the result is correct and the candidates are outputted.
  - If *any* member of the negative border is found to be frequent ($"Supp"(I) >= s$), the algorithm *failed* and no output is produced, as it would not be exact.

#warning[
  If a set in the Negative Border is actually frequent, it means our sample threshold was not low enough—we "missed" a set that should have been a candidate. Since Monotonicity implies we might have missed its supersets too, we must discard the results, resample, and restart.
]

#note[
  The more candidates we evaluate, the higher the probability that our algorithm will find a frequent itemset in the negative border, forcing it to restart and not terminate.
]

=== Proof of Correctness (No False Negatives)

#informally[
  If Toivonen's algorithm actually terminates and provides an output, we are mathematically guaranteed that there are no false negatives. Let's prove why.
]

#theorem("No False Negatives in Toivonen's Output")[
  If Toivonen's algorithm completes without requiring a second pass over the dataset, the output contains all true frequent itemsets (no false negatives).
]

#proof[
  Let's prove this by contradiction:
  - Assume Toivonen's algorithm provides an output, meaning every subset $T$ in the negative border of the sample is verified to be *not* frequent in the overall dataset.
  - Now, assume there exists a false negative set called $S$.
  - By definition, $S$ must be frequent in the overall dataset, but was *not* frequent in our initial sample.
  - Because $S$ is frequent in the dataset, all of its subsets must also be frequent in the dataset (monotonicity).
  - Let $T'$ be a subset of $S$ ($T' subset.eq S$) that is *not* frequent in the sample, chosen such that it has the minimal possible cardinality.
  - Because $T'$ has minimal cardinality among the non-frequent subsets, all immediate subsets of $T'$ *are* frequent in the sample.
  - Therefore, by definition, $T'$ belongs to the *negative border*.
  - But Toivonen's algorithm checks the negative border. If $T'$ is in the negative border and $T' subset.eq S$ (where $S$ is frequent), $T'$ must also be frequent in the dataset.
  - If a set in the negative border is found to be frequent in the entire dataset, the algorithm *halts and requires a new sample*.
  - This contradicts our initial assumption that the algorithm successfully provided an output. $qed$
]

#note[
  In short: If the algorithm finishes, it means no itemset in the negative border was frequent in the main dataset. If no negative border itemset is frequent, no larger set (like our hypothetical $S$) can be frequent either.

  Toivonen never produces False Negatives if it terminates successfully. We just repeat until success (usually 1 or 2 tries).
]
