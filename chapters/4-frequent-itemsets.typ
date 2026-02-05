#import "../template.typ": *

= Frequent Itemsets

Or Market-Basket Analysis (which items are we going to put in the basket to buy?).
We study the behaviour of customers, we look for patterns.
We are not really interested in explanations, but only on exploitation.

#example[
  We find the pattern that people often buy hamburger and ketchup togheter.
  It is, of course, because people eat them together, but we are not interested in that, we only care how to find these (e.g. to raise the price of both or place closer in the shelf).

  We are interested in not the obvious ones, like Beer + Diapers or Torch-Light + Lollipops.
]

This could also be used for items suggested by Amazon or Netflix in the homepage
Spoiler it is not used, not beacuse it does not work, but because there are even more effective strategies.
One of these is User Collaborative Filtering, using similar items (last chapters).
Items are users, and after finding similar users simply suggest the same things bought by similar users.

Not only for commercial purpouse, but also medical.

Formalization.

/ Association Rule:
  if in a basket I see all the items contained in $A$, we assume also the item $b$ is in the basket
  $ underbrace(A, "set of items") -> underbrace(b, "item") $

/ Degenerate Rule:
  rule of no use.
  We need some metric that measure the effectiveness of an association rule.

/ Support: given a file of all baskets, we count the number of times a set $I$ is a subset of a basket $B$
  $ "Supp"(I) = "abs. freq." I subset.eq B forall B in "baskets" $

/ Confidence: adding $b$ to the set $A$, comparing to the number
  $ "Confidence"(A -> b) = "Supp"(A union {b}) / "Supp"(A) $
  Of course, the denominator is always bigger than the numerator.
  When the ratio is closer to $1$, we are pretty confident that the rule is good.

  #warning[
    There are exceptions!
    We can have a association rule with an high condidence but are useless.

    #example[
      Each rule with ${"item"} -> "plastic bag"$.
      A plastic bag is associated with any basket.
      Regardless of the item, the plastic bag is associated with it.
    ]

    So we need another metric.
  ]

/ Interest: find items that are independent of the basket they are put in
  $ "Interest"(A -> b) = "Confidence"(A -> b) - "Supp"({b})/("number of baskets") $

  - *interest is positive*: fraction of baskets that contain A which also contain B is greather the fraction of baskets that contain b.
    When I have all the items of $A$ we have an higher probability of finding also $b$.
    So we like rules that have a high confidence and high interest.
  - *interest is negative*: having all the items of $A$, we have less probability of finding also $b$.
    It highlights items that competes with each other (e.g. Coca cola vs Pepsi).

For each frequen itemset $"Supp"(I) >= 1$, we calculate:
$ forall j in I, quad I \\ {j} -> j $

But how do we find frequent itemsets?
In theory, we can support the support for each itemset, but it is very very expensive in terms of time.

How many possible itemsets exists?
$ 2^n, quad n = "number of distincts items" $
and we need to count for each itemset its frequency, so:
$ 2^n "counters" $
These number cannot fit in RAM, so we need to do something.

#note[
  We are in a situation where a classical hard disk is more than enough to store the whole set of baskets, but we are still in the realm of big data beacuse we cannot operate on it without involving special techniques.
]

Instead of calculating that for each itemset, we just conside the most frequent pairs:
$ binom(n, 2) approx n^2/2 $
Doing some calculations with $2$Gb available, we can at most calculate at best $33000$ pairs.
We are very limited.

#informally[
  For a marketing campaign, we dont need all possible itemsets, but a few pairs of interesting items are enough.
  But this is a very specific use case.
]

== Apriori Algorithms

The algorithm is composed of two steps, each time doing a full scan of the baskets.

#note[
  We will measure the complexity of these algorithms as number of passes over the baskets.
]

The apriori algorithms has a complexity of $2$.

The first scan is meant to build two auxiliary data structures:
- a mapping between items and a progressive set of natural numbers (progressive IDs)
  $ {"items"} -> NN $
- associate each item to its frequency.
  This can be seen as a table
  $ {"ID"} -> NN ("frequency") $
- modify the second data structure, transofrming the second column of the table (the frequency) to a new sequential id, that accounts only for the items that are frequent (that exceed the frequency treshold).

These structures are in the order of millions, so in the order of megabytes.
We have plenty of free RAM for the second pass.

We now do some filtering, exploiting the monotonicity property.

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

Using this theorem, we can swap negating them:
$ A "is not frequent" --> B "is not frequent" $
If we found a subset that is not frequent, it is useless to keep track of supersets that include that subset.
If a singleton (an item) is not frequent, we don't need to keep track of any pair of set that contains that item.

Second pass: foreach basketp $B$:
$ forall i in B | i " is frequent", forall j in B | j "is frequent", i != j, quad "consider pair" (i, j) $
The trivial way is to organize the indexes as a matrix $C$, so $c_(i j) += 1$.
But that's not a good idea, because indexing the $i$ and $j$ with items ID, would generate a matrix as big as all the items, including also the not frequent items.

For that reason we calculated the new ID, keeping only the items that are frequent.
Instead of using $c_(i j)$ with $i j$ as ID, we use $c_(tilde(i) tilde(j))$ with $tilde(i), tilde(j)$ as the new ID.

We are still wasting a lot of time, because the matrix both contains $tilde(i) tilde(j)$ and $tilde(j) tilde(i)$.
In other words we are considering ordered couples instead of simple couples.

The best data structure would be a "triangular" data structure, where the index of the row is always smaller then the index of the column.

We can simply build this data structure, using a long array.
We know for each column the total number of cells before it, so we can have constant access time to each cell.
The offset starting from $i, j$ is (with $n$ being the number of items):
$ (i-1)(n - i/2)+j-1 $
This data structure is called triangular matrix.

With this data structure the problem is solved: we can just browse the data structure and emit all pairs.

During that phase we also calculate the real frequecy of that couple and emit only if its good.
That way we get no *False positive*.

What about *False negative*? We don't have even False negative.

Does it always work? No.
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

// TODO: merge into Favo02 lecture notes.

== Market-Basket Analysis

The study of frequent itemsets originated from techniques designed to analyze customer behavior. The fundamental objective is to exploit statistical patterns in purchasing data to understand how items relate to one another.

Patterns often emerge in "baskets" (the set of items a customer buys in a single transaction):
- *Predictable associations:* Customers buying hamburgers are statistically likely to buy ketchup.
- *Unintuitive associations:* Data analysis famously revealed "Beer and Diapers" or "Torch-lights and Lollipops" as statistically significant pairs.

These patterns allow retailers to optimize shelf placement and inventory based on statistical rules rather than just intuition.

To transform these observations into actionable knowledge, we define an *Association Rule*:
$ A -> b $
Where:
- $A$ is a *set of items* (the antecedent).
- $b$ is a *single item* (the consequent).

However, not all generated rules are useful; some may be "degenerate" or statistically insignificant.
To filter these, we require metrics to measure the effectiveness and relevance of a rule.

=== Support and Confidence

The raw data consists of a "Basket File" containing all checkout records. Let $cal{B}$ be the set of all baskets and $I$ be a set of items.

==== 1. Support
The *Support* of an itemset $I$ is the absolute frequency (count) of baskets that contain $I$.
$ S u p p (I) = |{B in cal(B) : I subset.eq B}| $

#note[
  If we have 1,000,000 baskets, we count exactly how many times the pair "{torch, lollipop}" appears. This helps us ignore rare, coincidental occurrences.
]

==== 2. Confidence
The *Confidence* of a rule $A -> b$ measures how often the item $b$ appears in baskets that already contain the set $A$. It is defined as the ratio:
$ C o n f (A -> b) = (S u p p (A and(b)))/(S u p p (A)) $

#note[
  A confidence of $0.2$ means that $20%$ of the time a customer buys a torch, they also buy a lollipop. This conditional probability allows us to gauge the predictive power of the rule.
]

Even with high confidence, a rule might be misleading if the item $b$ is already extremely common. To account for this, we introduce the concept of *Interest*.

The interest of a rule $A -> b$ is defined as the difference between its confidence and its expected probability based on the overall frequency of $b$:

$ I n t e r e s t (A -> b) = C o n f (A > b) - S u p p (b)/("Total Baskets") $

- *Positive Interest:* The presence of $A$ increases the probability of finding $b$. This is our primary target for finding meaningful associations.
- *Negative Interest:* The presence of $A$ makes $b$ *less* likely (items are "competing" or mutually exclusive).

=== Frequent Itemsets
Before generating rules, we must find *Frequent Itemsets*. An itemset $I$ is "frequent" if its support exceeds a chosen threshold $s$:
$ S u p p (I) >= s $

#note[
  Once we identify a frequent itemset $I$, we can generate candidate rules by testing every $j in I$
]

== Why Brute Force Fails

The "Naive" approach would be to scan the basket file and maintain a counter for every possible itemset. However, we quickly run into a *Space Complexity* wall.

- With $n$ distinct items, there are $2^n$ possible itemsets.
- A small grocery store has hundreds of items, but a giant like Amazon has millions. $2^n$ becomes astronomically large, far exceeding the RAM (or even disk space) of any modern system.

If we limit ourselves to finding only *frequent pairs*, the complexity drops to:
$ binom(n, 2) = (n(n-1))/(2) approx (n^2)/(2) $

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

Unlike the LSH approach where we accepted approximate solutions via hashing, here we want to find *all* frequent sets exactly. To escape the quadratic memory wall without losing accuracy, we need to filter the itemsets we track.

This leads us to a family of algorithms designed to prune the search space, starting with the fundamental *A-Priori Algorithm*.

The A-Priori algorithm is a constructive solution to the frequent itemset problem. It is organized into two distinct main steps.


#warning[
  Each step requires a full pass over the basket file. Since the file sits in mass memory (hard disk), the execution time is dominated by Input/Output (I/O) operations.
]

=== Pass 1
The goal of the first pass is to identify which individual items are frequent. We maintain two data structures in RAM:

1. *Item Dictionary:* Maps item names to a univocal integer ID ($0 dots N$).
2. *Frequency Table:* A table where `Column 1` is the ID and `Column 2` is the count.

As we scan the baskets, we build these dynamically.
- If an item is new, assign it a new ID.
- If it exists, increment the counter.

Once the pass is complete, we check which items exceed the support threshold $s$.
- *Non-Frequent items:* Labeled as `-1` (or discarded).
- *Frequent items:* Assigned a new, dense progressive ID ranging from $1$ to $m$ (where $m < N$).

How does this scale? Linearly with the number of *distinct* items.
Even in a worst-case scenario with 1 million distinct items, we are talking about *Megabytes* (maybe 100MB), not Gigabytes. We are using a tiny fraction of RAM, leaving plenty of free space for the heavy lifting in Pass 2.

Before Pass 2, we need a theoretical justification for ignoring certain pairs. We exploit *Monotonicity*:
If we have a set $A$ and a superset $B$ (so $A subset.eq B$), the support must satisfy:
$ S u p p (A) >= S u p p (B) $

If $B$ is a frequent itemset, then by definition $S u p p (B) >= s$. By transitivity, $S u p p (A) >= s$, so $A$ must also be frequent.

We can invert this logic to build a filter:
$ A $ is NOT frequent $-> B$ is NOT frequent
If a single item inside a basket is not frequent, it *cannot* be part of a frequent pair. There is no point in counting pairs involving that item.

=== Pass 2
Now we perform the second scan of the basket file.
For each basket, we look at the items inside. Thanks to our renumbering in Pass 1, we metaphorically "blind" ourselves to non-frequent items. We only process items that have a valid ID.

For every pair of frequent items $i, j$ in the basket (where $i != j$):
$ C[i, j] <- C[i, j] + 1 $

*Wait, are we wasting space?*
If we use a standard matrix for $C$, we have two problems:
1. *Symmetry:* $C[i, j]$ is the same as $C[j, i]$. We don't need to store both.
2. *Sparseness:* We only care about frequent items (which we solved by remapping IDs), but a full square matrix still scales quadratically.

*The Triangular Matrix Optimization:*
Since the order of indices doesn't matter (the pair ${A, B}$ is the same as ${B, A}$), we can impose a *Lexicographic Order* (always store such that $i < j$).
This allows us to store only the lower (or upper) triangular part of the matrix.
Instead of a 2D array, we can map the 2D coordinates to a 1D array index:
$ k = (i-1)(n - i/2) + j - i $
This saves roughly half the space.

=== Conclusion on Correctness
Are we missing anything?
- *False Negatives?* No. The monotonicity property guarantees that we never filter out a pair that *could* have been frequent. If a pair was destined to be frequent, both its constituent items *must* have survived Pass 1.
- *False Positives?* No, because we are actually counting the occurrences in Pass 2.
