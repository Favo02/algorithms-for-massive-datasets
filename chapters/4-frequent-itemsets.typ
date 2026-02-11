#import "../template.typ": *

= Frequent Itemsets

The study of frequent itemsets originated from techniques designed to analyze customer behavior. The fundamental objective is to *exploit statistical patterns* in purchasing data to understand how items relate to one another.

Patterns often emerge in "baskets" (the set of items a customer buys in a single transaction):
- *Predictable associations:* Customers buying hamburgers are statistically likely to buy ketchup.
- *Unintuitive associations:* Data analysis famously revealed "Beer and Diapers" or "Torch-lights and Lollipops" as statistically significant pairs. 

#example[
This could also be used for items suggested by Amazon or Netflix in the homepage
Spoiler it is not used, not beacuse it does not work, but because there are even more effective strategies.
One of these is User Collaborative Filtering, using similar items (last chapters).
Items are users, and after finding similar users simply suggest the same things bought by similar users.

Not only for commercial purpouse, but also medical.
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
If we have 1,000,000 baskets, the support of the rule $"torch" -> "lollipop"$ is the exact number of times both items appear together. This helps us ignore rare, coincidental occurrences.
]

Now we can define the *confidence* of an association rule $A -> b$.

#theorem("Confidence")[
The *confidence* of a rule $A -> b$ is the ratio:
$ "Conf"(A -> b) = ("Supp"(A union {b}))/("Supp"(A)) $
]

#note[
  A confidence of $0.2$ means that $20%$ of the time a customer buys a torch, they also buy a lollipop. This conditional probability allows us to gauge the predictive power of the rule.
]

Of course, the denominator is always bigger than the numerator.
When the ratio is closer to $1$, we are pretty confident that the rule is good.

  #warning[
    There are exceptions!
    We can have a association rule with an high condidence but are useless.

    #example[
      Each rule with $"item" -> "plastic bag"$.
      A plastic bag is associated with any basket.
      Regardless of the item, the plastic bag is associated with it.
    ]

    So we need another metric.
  ]

#theorem("interest")[
  the *interest* of a rule $A -> b$ is defined as thee difference between its confidence and its expected probability based on the overall frequency of $b$.

  $ "Interest"(A -> b) = "Confidence"(A -> b) - "Supp"({b})/("number of baskets") $

]

  - *Positive Interest:* The presence of $A$ increases the probability of finding $b$. This is our primary target for finding meaningful associations.
  - *Negative Interest:* The presence of $A$ makes $b$ *less* likely (items are "competing" or mutually exclusive).

=== Frequent Itemsets

Before generating rules, we must find *Frequent Itemsets*.

#theorem("frequent itemset")[
  An itemset $I$ is "frequent" if its support exceeds a chosen threshold $s$:
  $ "Supp"(I)>=s $
]

#note[
  Once we identify a frequent itemset $I$, we can generate candidate rules by testing every $j in I$
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
  For a marketing campaign, we dont need all possible itemsets, but a few pairs of interesting items are enough.
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

here we want to find *all* frequent sets exactly.
To escape the quadratic memory wall without losing accuracy, we need to filter the itemsets we track.

This leads us to a family of algorithms designed to prune the search space, starting with the fundamental *A-Priori Algorithm*.

== Apriori Algorithms

It is organized into two distinct main steps.

#warning[
  #note[
    Each step requires a full pass over the basket file. Since the file sits in mass memory (hard disk), the execution time is dominated by Input/Output (I/O) operations.
  ]
   For these reasons, We will measure the complexity of these algorithms as number of passes over the baskets.
]

The apriori algorithms has a complexity of $2$.

=== Pass 1

The goal of the first pass is to *identify which individual items are frequent*

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

we check which items exceed the support threshold $s$.

- *Non-Frequent items:* Labeled as `-1` (or discarded).
- *Frequent items:* Assigned a new, dense progressive ID ranging from $1$ to $m$ (where $m < N$).

#note[
How does this scale? Linearly with the number of *distinct* items.
Even in a worst-case scenario with 1 million distinct items, we are talking about *Megabytes* (maybe 100MB), not Gigabytes. We are using a tiny fraction of RAM, leaving plenty of free space for the heavy lifting in Pass 2.
]

Before Pass 2, we need a theoretical justification for ignoring certain pairs.

Given two baskets (sets of items), one subset of the other:
$ A, B, quad A subset.eq B quad --> quad "supp"(A) >= "supp"(B) $
if $B$ is a frequent itemset, means that the support of $B$ is greather that the treshold:
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
If a single item inside a basket is not frequent, it *cannot* be part of a frequent pair. There is no point in counting pairs involving that item.

=== Pass 2

Now we perform the second scan of the basket file.

For each basket, we look at the items inside. Thanks to the renumbering in Pass 1, the algorith only process items that have a valid ID:

$ forall i in B | i " is frequent", forall j in B | j "is frequent", i != j, quad "consider pair" (i, j) $

The trivial way is to organize the indexes as a matrix $C$, so $c_(i j) += 1$.

*are we wasting space?*

==== Triangular Matrix Optimization

If we use a standard matrix for $C$, we have two problems:

1. *Symmetry:* $C[i, j]$ is the same as $C[j, i]$. We don't need to store both.
2. *Sparseness:* We only care about frequent items (which we solved by remapping IDs), but a full square matrix still scales quadratically.

Instead of using $c_(i j)$ with $i j$ as ID, we can use $c_(tilde(i) tilde(j))$ with $tilde(i), tilde(j)$ as the new ID.

But We are still wasting a lot of time, because the matrix both contains $tilde(i) tilde(j)$ and $tilde(j) tilde(i)$.

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

The problem for the trivial algorithm was that the number of counters was too much, so we applied a filter on the pairs we count.
But we have no guaranteed that this filtering actually reduces enough the number of pairs processed.

So, if the algorithm works, we have a correct solution, but the algorithm could crash because of the amount of RAM required is too much.

We could also have items that are frequent alone but are never bought togheter, so we could have some $0$ entries in the triangular matrix.

We need something robust to sparseness.

We already seen something similar during PageRank, instead of storing a matrix we store a triple $(tilde(i), tilde(j), "counter")$.
Where the counter is $0$ we discard the triple.

With this representation, we have to find the triple in memory (if it exists) and modify it.
We don't have immediate access anymore.
We could use hash functions to build an index on these indices to get immediate access to the location of the triples.





// favo's notes

=== Hash Table Approach for Triples

For this end, we build an HashMap that hashes the two indices $i, j$ into a bucket.
Collisions are handled using a linked list on each bucket.
This gives us a quasi-constant access time and can handle sparsity.

Which approach is better?
Space used:
- triangular: 1 integer per each entry
- triple: 3+ integers per each entry (the space for the pointers and the space for the hashmap)

The best approach depends on the sparseness of the matrix.
If the matrix has less than $1/3$ of empty entries, then the triangulat matrix is preferable.

#example[
  $n = 100.000$ items, $b = 10.000.000$ baskets (10 items each)
  ...

  Even considering the worst case, using the hashmap approach is preferable as there are more than $1/3$ empty.
]

=== Expanding beyond pairs

In line of principle, we can apply the same idea to triples $(i, j, k)$, adding a new pass.
We increase the counter related to ${i, j, k}$ if and only if:
- ${i}, {j}, {k}$ should be frequent as singletons
- ${i,j}, {j, k}, {i, k}$ should be frequent as pairs

#note[
  The main property exploited by this approach is monotonicity.
]

We can build up to any cardinality of the sets, simply by continuing iterating from the previous step.

Each stage is composed of two steps.
The first step works as:
- 1° step:
  - start with a set of canditate singletons (that might or might not be frequent)
  - calculate the frequency of each singleton
  - filter out only the singletons that have at least a fixed frequency
- 2° step:
  - scan all the frequent singletons and build pairs that are frequent

This process can be generalized to any cardinality of the sets, just by concatenating stages.
Each stage increases the dimension by $1$.

Each stage needs to do one compelte pass on the baskets, so the complexity scales linearly with the cardinality of the resulting sets wanted.

#note[
  The data structures should be adapted for higher dimensions, we can use pyramidal matrices and quadruples instead of triples.
]

=== Correctness

We said that this algorithm is exact.
An algorithm is exact if it gives the right answer for each input instance.

When this algorithm ends, it gives always the right output.
Are we sure that it always ends?

No, we could have too many frequent items and run out of space for the counters, resulting in a crash of the algorithm.

We can use other algorithms, based on Apriori algorithms that perform more aggressive filtering.

== Park-Chen-Yu Algorithm (PCY)

The idea is to exploit the free memory at the end of the first phase (when we still dont have a trinagular or sparse counters in memory).

It builds another auxiliary data structure during the first phase.

We see the free memory as a long vector of integers (all starting from $0$).
And an hash function $h$ that hashes a pair of items $(i, j)$ into a position in the integers array.

The first two structures are constructed as for the Apriori algorithm, but during the scan also increment the integer at the position of the items hashed $h(i, j) forall i, j in B forall B in "baskets"$.

At the end of the scan, we can have two situations for each cell of the array:
- $h(i,j) < s$: we know for sure that the pair $i, j$ can be discarded, as its support is for sure less than the treshold $s$
- $h(i,j) >= s$: we don't have any actual information on the pair (as a cell could be point pointed by multiple pairs because of collisions), but we keep it for further processing

The further processing now implies a new condition:
- ${i}$ is frequent
- ${j}$ is frequent
- $h(i, j) >= s$

Objection: we filled the whole remaining memory with the vector, where do we store the triangular matrix for the counters?

We can compress the vector, instead of storing a whole integer, we can simply store if the value was $>= s$ or less.
This way we compress the vector by a factor of $32$ (a bit instead of $4$ bytes).

We have less space for the matrix of counters because we have this vector of bits (called bitmap) that takes $1/32$ of the available remaining memory and the matrix of counters thakes the $31/32$ remeaning counters.

After generating the counters matrix/hashtable, we can compress that using the same idea: a *bitmap*.

This way we can store information about previous passes using _little_ space.
Each iteration adds a bitmap, eventually we won't have enough space to perform another pass and store the hashmap.

This approach is called *multi-stage*.

=== Multi-Hash

Instead of using only one vector of integers, with one hash function that points to that vector, we divide the remeaning memory in two vectors and use two different hash functions that increase the counters of pairs.

Then, the two vectors are compressed and stored, using the exact same space as before.

But, considered alone, each function is less powerful as before, because having half the buckets means more collisions and so more false positive pairs.

== Another Approach: Sampling

If we could store all the baskets in main memory, then we would be able to compute the frequency of each triple, quadruple of any cardinality by just doing some scans of the Apriori algorithm.

If we sample the baskets and put that sample in memory, we have no guarantee that the algorithm is exact anymore.
This can be seen as a predictor, it outputs some sets which it expects to be frequent.
We have the two classical errors:
- False Positive (FP): sets that are not frequent but are output of the algorithm
- False Negative (FN): actual frequent sets that are not in output of the algorithm

Again, FP are less bad than FN, because the output can be checked and verified (at the price of a single scan of the whole basket file).

A simple effective way for sampling is to just select each basket with a certain probability.

Once the sample is in RAM, we can run Apriori algorithm, given that we have enought free space to store the auxiliary data structures.

=== Savasere-Omiecinski-Navathe Algorithm (SON)

We virtually divide the baskets file into chuncks of equal size.
Each chunks is brought into RAM and the Apriori algorithm is run.

#note[
  We need to scale the Support treshold $s$, dividing it by the number of chunks, resulting in $p s$.
]

Each Apriori algorithm run on each chunk will output a set of candidates.
These sets are merged into a single candidates set, on which a FP positive removal stage is run (with the restored original treshold $s$).


Is that an exact algorithm?
It is obvious that we cannot have FP, as we explicitely removed it.
But for FN?

Let's suppose that a FN $I$ exists.
$I$ is frequent in the basket file, but $I$ is not in the output.
Meaning it was never in output of the processing of each chunk, $I$ is not frequent in *any* chunk.
$ forall "chunck" c, quad "Supp"_(c)(I) < p s $

$
  "Supp"(I) & = sum_c "Supp"_c (I) \
            & < sum_c p s \
            & < p s 1/p \
            & < s
$

Because $I$ is frequent, it must be $"Supp"(I) >= s$, which is a contradiction $qed$.

#note[
  This is not really a sampling algorithm, as the whole baskets file is processed.
]

=== Implementation: MapReduce

In the case that the basket file is so big that it cannot even fit on the disk, we can compute these using MapReduce.

$ "chunk" --> #rect[1st MAP] --> (1, underbrace(C, "candidate set")) space forall "candidate set" c $

#note[
  All the chunks share the same key!
]

Then we remove duplicate sets using a reduce:
$ (1, (C_1, C_2, ...)) --> #rect[1st REDUCE] --> (1, C'_1), ..., (1, C'_k) $

$ "chunk" --> #rect[2nd MAP] --> (c, v) $

$ (c, (v_1, v_2, ...)) --> #rect[2nd REDUCE] --> (c, sum v_i) "if" sum_i v_i >= s $

== Toivonen Algorithm

Like the Apriori algorithm, it gives exact results.
But on certain inputs, it cannot calculate a result (it does not crash or goes in an infinite loop, it just stops without producing a result).

It brings in RAM a basket sample of relative size $p$.
It runs Apriori algorithm (or a varian) with treshold $p s alpha$, with $0 < alpha < 1$.

The idea is that by playing with $alpha$ we play with the fact that the algorithm could not end.

Then, on the candidates sets we run compute an negative border: a group of sets that are *not* frequent, but whose immediate subsets are frequent in the sample.

#note[
  / Immediate subset: subset obtained by removing only exactly one element.
]

#note[
  Empty set is frequent.
]

#example[
  Items: $ A, B, C, D, E $
  Frequent sets: $ {A}, {B}, {C}, {D}, {B, C}, {C, D} $
  The negative border: $ {E}, {A, B}, {A, C}, {A, D}, {B, D} $
]

The idea of the negative border is to scan the baskets file and we keep track of the actual support for all the candidates set and the negative border.

The support for the candidates is used to remove FP.
If the actual support for all the negative border is less than the treshold, then the result is correct and the candidates are outputted.
If at least one of the negative border is a FN, then no output is produced as it would not be exact.


// jack's notes of secod part 05/02/2026

05/02/2026 massive datasets

In the previous lecture, we analyzed the *Triangular Matrix* approach for storing pair counters. The key advantage of the triangular matrix is that it guarantees *constant access time*, $O(1)$, for any pair $(i, j)$ via a direct index calculation function.

However, when we need to count *triples* (sets of 3 items) or when the data is extremely sparse, a dense matrix becomes inefficient. We need a structure that maintains quasi-constant access time but handles sparsity better.

=== 1.1 Hash Table Approach for Triples
To store triples $(i, j, k)$, we can introduce a hash function $h$.
The general mapping flow is:
$ (i, j, k) -> h(i, j, k) -> "Bucket" {b_0, b_1, dots} $

Since hash functions inevitably produce collisions, each bucket must point to a *linked list* containing the actual triples and their counts.
- *Structure:* A hash map where buckets store pointers to linked lists.
- *Collision Handling:* We aggregate triples falling into the same bucket in a linked list.
- *Operation:* To increment a count, we compute the hash. If the node exists in the list, we increment it. If not, we append a new node.

*Access Time Analysis:*
Strictly speaking, this is not constant time because we must traverse the linked list. However, if the number of buckets is sufficiently large relative to the number of frequent triples, the linked lists remain short.
- The variance of access times is small.
- We operate in a regime of *quasi-constant access time*.

=== 1.2 Trade-off: Triangular Matrix vs. Hash Table
We now have two distinct methods for organizing counters in memory:
1.  *Triangular Matrix:* Good for dense data.
2.  *Hash Table:* Good for sparse data (exploits sparsity).

*Which one should we prefer?*
It depends entirely on the *sparseness* of the candidate pairs.
- *Matrix:* Allocates 1 integer per possible pair.
- *Hash Table:* Allocates at least 3 integers per pair (indices $i, j$ + pointer + hash overhead).

*Decision Criterion:*
To choose, we need an estimation of the number of counters required.
*Example:*
- $N = 100,000$ ($10^5$) items.
- $M = 10,000,000$ ($10^7$) baskets.
- Average basket size = 10 items.

*Option A: Triangular Matrix*
We must reserve space for every possible pair:
$ binom(N, 2) approx 5 times 10^9 text(" counters (integers)") $

*Option B: Hash Table (Worst Case)*
Upper bound for distinct pairs: Assume every pair in every basket is unique.
- Pairs per basket: $binom{10}{2} = 45$.
- Total pairs: $10^7 times 45 = 4.5 times 10^8$.
- Space per pair (approx 3 ints): $4.5 times 10^8 times 3 = 1.35 times 10^9$ integers.

*Conclusion:* In this scenario, the hash table requires less than $1/3$ of the space of the matrix. The hash approach is superior here due to sparsity.

---

== 2. Extending A-Priori (Triples and Beyond)
So far, we have focused on pairs. In principle, we need to find frequent triples, quadruples, etc., to derive complex Association Rules.

*The Monotonicity Property* holds for any cardinality: if a set $S$ is frequent, all subsets of $S$ must be frequent.

=== 2.1 The General A-Priori Workflow
The algorithm is an iterative sequence of two operations:
1.  *Filtering:* Pruning the candidates based on support.
2.  *Construction:* Generating new candidates of size $k+1$ from frequent sets of size $k$.

*Pass 3 (Finding Triples):*
To count triples, we need a third pass over the data. This is computationally expensive as reading from disk is the bottleneck.
For every basket $B$, and for each triple $\{i, j, k\} subset.eq B$, we increment $c(i, j, k)$ *if and only if*:
1.  $\{i\}, \{j\}, \{k\}$ are frequent (from Pass 1).
2.  $\{i, j\}, \{i, k\}, \{j, k\}$ are frequent (from Pass 2).

We proceed iteratively ($L_1 \to C_2 \to L_2 \to C_3 \to dots$). The complexity scales linearly with the maximum cardinality of frequent sets we wish to find.

=== 2.2 Correctness and Failure
A-Priori is an *exact algorithm*: if it terminates, it produces the correct result. However, it may fail (e.g., Segmentation Fault) before finishing.
*Why?*
- *Integer Overflow:* Unlikely (4 bytes is usually enough for counts).
- *Memory Exhaustion:* This is the real danger.
    - Unlike the matrix, hash tables allocate memory dynamically.
    - We might exhaust RAM while appending new nodes to collision lists.
    - We have no guarantee that the free memory is sufficient for all candidates.

If A-Priori fails due to memory, we need a more memory-efficient approach.

---

== 3. The PCY Algorithm (Park-Chen-Yu)
PCY extends A-Priori by optimizing the *First Pass*.
*Observation:* During Pass 1, we only count singletons (items). This uses very little RAM. Most of the memory is idle.

=== 3.1 PCY Pass 1
We utilize the idle memory to maintain a *Hash Table* of pair counts alongside the item counts.
- We treat the free memory as a large array of integers (buckets).
- For every basket, for every pair $(i, j)$ in the basket:
  $ "bucket" = h(i, j) \pmod "array size"} $
  $ "Array"["bucket"] += 1 $

=== 3.2 Between Pass 1 and Pass 2
At the end of Pass 1, we analyze the hash buckets against the support threshold $s$.
- If $"Array"[b] < s$: No pair hashing to bucket $b$ can be frequent.
- If $"Array"[b] \ge s$: Pairs hashing to $b$ *might* be frequent (collisions possible).

*Compression:*
We do not need the actual counts for Pass 2, only the boolean status (Frequent/Not Frequent). We compress the integer array into a *Bitmap*:
- If count $>= s ->$ bit = 1.
- If count $< s \to$ bit = 0.

*Space Gain:* An integer (32 bits) is replaced by 1 bit. We reclaim $31/32$ of the memory to use for the actual counters in Pass 2.

=== 3.3 PCY Pass 2
We now count pairs $(i, j)$ only if:
1.  $i$ and $j$ are frequent items.
2.  The bit corresponding to $h(i, j)$ is 1.

This "advanced filtering" allows us to discard many candidate pairs that A-Priori would have counted, allowing us to handle larger datasets or lower support thresholds without running out of RAM.


---

== 4. Advanced Extensions: Multistage and Multihash
Even with PCY, the bitmap might not filter enough pairs if there are too many collisions (i.e., too many "false positive" buckets).

=== 4.1 Multistage Algorithm
*Idea:* Iterate the hashing process to filter more aggressively.
1.  *Pass 1:* Standard PCY (creates Bitmap 1).
2.  *Pass 2:* Do not count pairs yet. Instead, use a *second hash function* $h_2$ and a new hash table. Only hash pairs that pass the Bitmap 1 check.
3.  *End of Pass 2:* Create Bitmap 2.
4.  *Pass 3:* Count pairs that pass *both* Bitmap 1 and Bitmap 2.

*Trade-off:* We reduce the number of counters needed (preventing memory overflow), but we pay the price of an *extra disk scan* (Pass 2 is now just for hashing).

=== 4.2 Multihash Algorithm
*Idea:* Perform two hash filters *in parallel* to avoid the extra disk scan.
1.  *Pass 1:* Split the available memory into two halves.
2.  Run two hash functions ($h_1, h_2$) simultaneously into two separate hash tables.
3.  *End of Pass 1:* Convert both tables into two bitmaps.
4.  *Pass 2:* A pair is a candidate only if *both* $h_1(i, j)$ and $h_2(i, j)$ buckets are frequent.

*Trade-off:*
- Since we split memory, each hash table is half the size of the PCY table.
- This increases collisions within each individual table.
- However, the *intersection* of valid buckets might still be smaller than a single PCY filter.
- *Benefit:* No extra disk scan required compared to Multistage.

= Algorithms for Massive Datasets (Part 2)
*Date:* February 5, 2026
*Topic:* Sampling-Based Algorithms, SON, and Toivonen's Algorithm

---

== 5. Sampling-Based Approaches
Up to this point, we assumed we had to process the entire dataset (stored on a hard disk). However, strict exactness might be traded for efficiency by working with a *sample* of the baskets in RAM.

=== 5.1 The Concept of Sampling
Instead of scanning the entire disk, we load a random sample of the baskets into RAM.
- Let $p$ be the fraction of the total baskets we sample ($0 < p < 1$).
- We run an in-memory algorithm (like A-Priori) on this sample.
- Since the dataset size is reduced by factor $p$, the support threshold must be scaled accordingly: $s_("sample") = p dot s$.

*The Risk of Errors:*
Since we are using a statistical estimator, the output is not guaranteed to be exact. We face two types of errors:
1.  *False Positives (FP):* Itemsets that appear frequent in the sample but are not frequent in the whole dataset.
2.  *False Negatives (FN):* Itemsets that are frequent in the whole dataset but were missed in the sample.

*Managing Errors:*
- *False Positives* are "less bad" than False Negatives. Why? Because we can treat the sample output as a set of *Candidate Sets*. With one full scan of the dataset, we can verify their actual support and remove the FPs.
- *False Negatives* are fatal. If the algorithm doesn't propose a set, we cannot verify it later. It is simply lost.

*Sampling Strategy:*
To minimize variance, the sample must be truly random. Simply taking the "first $N$ rows" of a file is dangerous because files often have temporal or logical ordering (e.g., Christmas sales grouped together), which would bias the sample.

== 6. The SON Algorithm

The SON algorithm provides a way to use sampling *without* producing False Negatives. It is an exact algorithm that lends itself perfectly to parallelization (MapReduce).

=== 6.1 The Algorithm Structure
1.  *Partitioning:* Divide the massive basket file into $k$ chunks of equal size.
    - Each chunk represents a "sample" of proportion $p = 1/k$.
2.  *Local Processing:* Load each chunk into RAM and run A-Priori (or any frequent itemset algorithm) with a scaled threshold $p dot s$.
3.  *Union of Candidates:* An itemset is a *global candidate* if it is frequent in *at least one* chunk.
4.  *Verification:* Scan the entire dataset to count the support of these global candidates and filter out False Positives.

=== 6.2 Proof of Correctness (No False Negatives)
We must prove that if a set is frequent globally, it *must* be selected as a candidate by SON.

*Theorem:* If an itemset $I$ is frequent in the whole dataset (Support $S(I) \ge s$), then there exists at least one chunk $C_i$ where the support of $I$ in that chunk is at least $p dot s$.

*Proof (by Contradiction):*
Let's assume the opposite: $I$ is globally frequent ($S(I) \ge s$), but it is *not* frequent in any chunk.
- If $I$ is not frequent in chunk $C_i$, then $"Supp"_ (C_i)(I) < p dot s$.
- The total support is the sum of supports in all chunks:
  $ S(I) = sum_{i=1}^{k} "Supp"_(C_i)(I) $
- Substituting our assumption:
  $ S(I) < sum_{i=1}^{k} (p dot s) $
  $ S(I) < k dot (p dot s) $
- Since $p = 1/k$, then $k dot p = 1$.
  $ S(I) < s $
- *Contradiction:* We started with the premise that $S(I) \ge s$. Therefore, the assumption must be false. $I$ must be frequent in at least one chunk. Q.E.D.

=== 6.3 Distributed Implementation (MapReduce)
SON is ideal for distributed computing (MapReduce) because chunks can be processed in parallel. It requires *two* MapReduce jobs chained together.

*Job 1: Candidate Generation*
- *Map:* Read a chunk of the basket file. Run A-Priori locally with threshold $s/k$. Output key-value pairs `(1, itemset)` for every frequent itemset found.
- *Shuffle:* Group by key `1`.
- *Reduce:* Receive all local frequent itemsets. Output the set union (remove duplicates). These are the *Global Candidates*.

*Job 2: Verification*
- *Map:* Read a chunk of the basket file and the list of *Global Candidates* (broadcasted to all mappers). For each basket, count occurrences of the candidates. Output `(candidate, count)`.
- *Shuffle:* Group by `candidate`.
- *Reduce:* Sum the counts for each candidate. If `total_count >= s`, output the itemset.

== 7. Toivonen's Algorithm
Toivonen's algorithm is a *randomized algorithm*. Unlike SON, it does not guarantee finding the answer in a single run (it may fail), but if it produces an output, it is correct. It typically uses much less memory than SON/A-Priori.

=== 7.1 The Setup
1.  Load a random sample of the baskets (fraction $p$) into RAM.
2.  Run A-Priori on the sample with a *lowered* threshold.
    - Standard scaled threshold: $p dot s$.
    - Toivonen's threshold: $p dot s dot alpha$, where $0 < alpha < 1$ (e.g., 0.8 or 0.9).
3.  *Why lower the threshold?* We act "permissively" to include more candidates, reducing the chance of False Negatives caused by sampling variance.

=== 7.2 The Negative Border
Toivonen introduces a critical concept to detect failure: the *Negative Border*.
#theorem("")[
An itemset $I$ is in the Negative Border if:
  1.  $I$ is *not* frequent in the sample.
  2.  *All* immediate subsets of $I$ (sets created by removing 1 item) *are* frequent in the sample.
]
*Process:*
1.  Find frequent sets in the sample (Candidates).
2.  Construct the Negative Border.
3.  Scan the full dataset to count the support of:
    - The Candidates.
    - The Negative Border sets.

=== 7.3 Verification and Failure
After the full scan:
1.  *Filter Candidates:* Keep those with $S(I) \ge s$. (Removes False Positives).
2.  *Check Negative Border:*
    - If *no* member of the Negative Border is frequent in the full dataset, the algorithm *succeeded*.
    - If *any* member of the Negative Border turns out to be frequent ($S(I) \ge s$), the algorithm *failed*.

*Why failure?* If a set in the Negative Border is actually frequent, it means our sample threshold was not low enough—we "missed" a set that should have been a candidate. Since Monotonicity implies we might have missed its supersets too, we must discard the results, resample, and restart.

*Note:* Toivonen never produces False Negatives if it terminates successfully. We just repeat until success (usually 1 or 2 tries).










