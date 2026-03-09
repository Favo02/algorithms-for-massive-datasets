#import "../template.typ": *

= Frequent Itemsets

The study of frequent itemsets originated from techniques designed to analyze customer behavior.
The fundamental objective is to *exploit statistical patterns* in purchasing data to understand how items relate to one another.

Patterns often emerge in "baskets" (the set of items a customer buys in a single transaction):
- *Predictable associations:* Customers buying hamburgers are statistically likely to buy ketchup.
- *Unintuitive associations:* Data analysis famously revealed "Beer and Diapers" or "Torch-lights and Lollipops" as statistically significant pairs.

#example[
  This could also be used for items suggested by Amazon or Netflix on the homepage.

  _Spoiler:_ it is not used, not because it does not work, but because there are even more effective strategies.
  One of these is User Collaborative Filtering, that leverages the similar items analysis from the previous chapter.
  The technique treats users as items and suggests products bought by similar users.
]

== Formalization

To transform these observations into actionable knowledge, we define an association rule.

/ Association Rule:
  The form of an association rule is:
  $ underbrace(A, "set of items") -> underbrace(b, "item") $
  Where:
  - $A$ is a *set of items* (the antecedent).
  - $b$ is a *single item* (the consequent).

  #informally[
    The implication of this rule is that if all of the items in $A$ appear in some basket, then $b$ is "likely" to appear in that basket as well.
  ]

To formalize the notion of "likely", we first define the support of an itemset.

/ Support:
  The support of an itemset is the count of baskets that contain a full set of items $X$.
  $ "Supp"(X) = |{B in cal(B) : forall x in X, x in B}| $
  $ "Supp"(X) = |{B in cal(B) : X subset.eq B}| $

  For an associaton rule $A -> b$, we define:
  $ "Supp"(A union {b}) = |{B in cal(B) : A union {b} subset.eq B}| $
  where $cal(B)$ is the set of all baskets.

  #note[
    Since the empty set is a subset of every set, the support of $emptyset$ is the number of baskets.
  ]

  #example[
    Considering the following baskets:
    + {Torch, Lollipop, Batteries}
    + {Torch, Batteries}
    + {Lollipop, Candy}
    + {Torch, Lollipop}
    + {Torch, Batteries, Lollipop}
    + {Candy}

    The support for various association rules is:
    For the association rule :
    - ${"Torch"} -> "Lollipop" quad = quad "Supp"({"Torch", "Lollipop"}) = 3$
    - ${"Torch", "Batteries"} -> "Lollipop" quad = quad "Supp"({"Torch", "Batteries", "Lollipop"}) = 2$
  ]

Now we can define the two main _metrics_ to evaluate an association rule, confidence and interest.

/ Confidence:
  The confidence of a rule $A -> b$ is the ratio:
  $ "Conf"(A -> b) = ("Supp"(A union {b}))/("Supp"(A)) $

  This conditional probability quantifies the predictive strength of the rule.

  #example[
    A confidence of $0.2$ indicates that in $20%$ of baskets containing a torch, a lollipop is also present.
  ]

  Of course, the denominator is always greater than or equal to the numerator.
  When the ratio is closer to $1$, we are pretty confident that the rule is *good*.

  #warning[
    There are exceptions!
    We can have an association rule with a high confidence but that is useless.
    So we need another metric.

    #example[
      Consider any rule of the form $"item" -> "plastic bag"$.
      Since virtually every customer receives a plastic bag regardless of what they buy, the confidence of this rule is nearly 1 for any antecedent, yet it reveals nothing meaningful.
    ]
  ]

/ Interest:
  The interest of a rule $A -> b$ is defined as the difference between its confidence and its expected probability based on the overall frequency of $b$:
  $ "Interest"(A -> b) = "Confidence"(A -> b) - "Supp"({b})/("number of baskets") $

  - *Positive Interest:* The presence of $A$ increases the probability of finding $b$.
    This is our primary target for finding meaningful associations.
  - *Negative Interest:* The presence of $A$ makes $b$ *less* likely (items are "competing" or mutually exclusive).

#example[
  Considering the following baskets:
  + {Milk, Bread}
  + {Milk, Diapers, Beer}
  + {Bread, Diapers, Beer}
  + {Milk, Bread, Diapers, Beer}
  + {Bread, Beer}
  + {Milk, Diapers}

  Evaluate the rule ${"Milk"} -> "Beer"$:
  $ "Conf"({"Milk"} -> "Beer") = ("Supp"({"Milk", "Beer"}))/("Supp"({"Milk"})) = 0.5 $
  $ "Interest"({"Milk"} -> "Beer") approx -0.17 $

  - Confidence: 50% of customers who buy milk also buy beer
  - Negative interest: milk buyers are actually less likely to buy beer

  Now for the rule ${"Bread"} -> "Beer"$:
  $ "Conf"({"Bread"} -> "Beer") = 0.75 $
  $ "Interest"({"Bread"} -> "Beer") approx 0.08 $

  - Confidence: 75% of customers who buy bread also buy beer
  - Positive interest: bread buyers are slightly more likely to buy beer
]

To obtain rules, we must find frequent itemsets.
Once we identify a frequent itemset $I$, we can generate _candidate_ rules by testing every $j in I$.

/ Frequent Itemset:
  An itemset $I$ is "frequent" if its support meets or exceeds a chosen threshold $s$:
  $ "Supp"(I) >= s $

But how do we find frequent itemsets?

== Brute Force

The "naive" approach would be to scan the basket file and maintain a counter for every possible itemset.
However, we quickly run into a *space complexity* wall: with $n$ distinct items, there are $2^n$ possible itemsets.

#example[
  Even a small grocery store which has hundreds of items, the space necessary becomes astronomically large ($2^100 approx 10^30 approx 10^21 "GB"$, assuming each itemset occupies only 1 byte, far less than actually needed), far exceeding the RAM or even disk space of any modern system.
]

If we limit ourselves to finding only *frequent pairs*, the complexity drops to:
$ binom(n, 2) = (n(n-1))/(2) approx (n^2)/(2) $

While quadratic complexity is significantly better than exponential, it is still taxing for Big Data.

#example[
  For a marketing campaign, we don't need all possible itemsets, but a few pairs of interesting items are enough.
  But this is a very specific use case, most of the times, pairs are not enough.
]

#example[
  Suppose we have 2 GB of RAM ($2^31$ bytes) and use 4-byte integer counters.
  To store counters for all pairs:
  $ 4 dot (n^2)/(2) = 2n^2 $
  Setting $2n^2 <= 2^31$ gives $n <= sqrt(2^30) approx 32768$.

  A supermarket with 33,000 items might barely fit its pair-counters into RAM, but any larger inventory will crash the system.
]

We want to find *all* frequent sets exactly.
To improve memory performances without losing accuracy, we need to *filter* the itemsets we track.

This leads us to a family of algorithms designed to prune the search space, starting with the fundamental Apriori Algorithm.

== Apriori Algorithm

The Apriori algorithm is organized into two distinct main steps.

#warning[
  Each step requires a _full_ pass over the basket file.
  Since the file sits in mass memory (hard disk), the execution time is dominated by Input/Output (I/O) operations.
  For these reasons, we will measure the *complexity* of these algorithms as number of passes over the baskets.
]

The Apriori algorithm requires $2$ passes over the basket file.

=== Apriori Pass 1

The goal of the first pass is to identify which *individual items are frequent* by building two auxiliary data structures:
+ *Item Dictionary:* a mapping between item names and a progressive set of natural numbers (progressive IDs)
+ *Frequency Table:* A table where `Column 1` is the ID and `Column 2` is the absolute frequency counter for that item.

As we scan the baskets, we build these dynamically:
- If an item is new, assign it a new ID.
- If it exists, increment the counter.

#note[
  These structures are in the order of millions, so in the order of megabytes.
  We have plenty of free RAM for the second pass.
]

We now do some filtering, exploiting the monotonicity property.

We check which items exceed the support threshold $s$ by scanning the frequency table:
- *Non-Frequent items:* Labeled as `-1` (or discarded).
- *Frequent items:* Assigned a new, dense progressive ID ranging from $1$ to $m$ (where $m < N$).

#note[
  How does this scale? Linearly with the number of *distinct* items.
  Even in a worst-case scenario with 1 million distinct items, we are talking about *megabytes* (maybe 100MB), not gigabytes.
  We are using a tiny fraction of RAM, leaving plenty of free space for pass 2.
]

Before pass 2, we need a theoretical justification for ignoring certain pairs.

#theorem(title: "Monotonicity")[
  Given an itemset $B$ that is frequent, every subset $A subset.eq B$ is also frequent.

  #proof[
    The support of a subset is at least as big as the support of the superset:
    $ A subset.eq B quad -> quad "supp"(A) >= "supp"(B) $
    If $B$ is a frequent itemset, it means that the support of $B$ is greater than the threshold:
    $ "supp"(B) >= s $
    meaning also $A$ is:
    $ "supp"(A) >= s $
    meaning $A$ is *frequent* $qed$.

  ]

  We can invert this logic to build a *filter*:
  #theorem(title: "Theorem")[
    First order logic theorem:
    $ (A -> B) <--> (not B -> not A) $
  ]

  $ A "is not frequent" -> B "is not frequent" $
  If a single item inside a basket is not frequent, it *cannot* be part of a frequent itemset.
  There is no point in counting pairs involving that item $qed$.
] <frequent-itemset-monotonicity>

=== Apriori Pass 2

Now we perform the second scan of the basket file.
For each basket $B$, we consider the pairs formed by only two *frequent* items (any other itemset would not be frequent, as proved in #link-theorem(<frequent-itemset-monotonicity>))
$ forall i in B | i " is frequent", quad forall j in B | j "is frequent", quad i != j, quad "consider pair" (i, j) $

We count the *frequency* of each of these pairs (in how many different baskets they appear).
The trivial way is to organize the indexes as a matrix $C$, using the indices of the progressive IDs of the items as indices.

Are we *wasting space* with that representation? Yes.
1. *Symmetry:* $C[i, j]$ is the same as $C[j, i]$, we don't need to store both.
2. *Sparseness:* We only care about frequent items, but we are still using progressive IDs (not the remapped ones), so the matrix contains space for all items.

#figure(
  {
    align(center, cetz.canvas({
      import cetz.draw: *
      stroke((thickness: 0.5pt))

      // Pass 1
      rect((0, 0), (4, -8))

      rect((0.2, -0.2), (1.9, -2.5))
      content((1.05, -1.35), align(center)[Item \ names \ to \ integers])

      rect((2.1, -0.2), (3.8, -2.5))
      line((2.6, -0.2), (2.6, -2.5))
      content((2.35, -0.5), [1])
      content((2.35, -1.0), [2])
      content((2.35, -2.3), [$n$])
      content((3.2, -1.35), align(center)[Item \ counts])

      content((2, -5.25), [Unused])
      content((2, -8.6), [Pass 1])

      // Pass 2
      let off = 5.5
      rect((off, 0), (off + 4, -8))

      rect((off + 0.2, -0.2), (off + 1.9, -2.5))
      content((off + 1.05, -1.35), align(center)[Item \ names \ to \ integers])

      rect((off + 2.1, -0.2), (off + 3.8, -2.5))
      line((off + 2.6, -0.2), (off + 2.6, -2.5))
      content((off + 2.35, -0.5), [1])
      content((off + 2.35, -1.0), [2])
      content((off + 2.35, -2.3), [$n$])
      content((off + 3.2, -1.35), align(center)[Fre- \ quent \ items])

      rect((off + 0.2, -2.7), (off + 3.8, -7.8))
      content((off + 2, -5.25), align(center)[Data structure \ for counts \ of pairs])

      content((off + 2, -8.6), [Pass 2])
    }))
  },
  caption: [Memory layout for Pass 1 and Pass 2],
)

=== Triangular Matrix

Instead of using $c_(i j)$ with $i j$ as ID, we can use $c_(tilde(i) tilde(j))$ with $tilde(i), tilde(j)$ as the new *remapped* ID.

But we are still wasting a lot of space, because the matrix both contains $tilde(i) tilde(j)$ and $tilde(j) tilde(i)$.

Since the order of indices doesn't matter (the pair ${A, B}$ is the same as ${B, A}$), we can impose a *lexicographic order* (always store such that $i < j$).
This allows us to store only the lower (or upper) triangular part of the matrix.
We can linearize this 2D array (with rows of different length) into a 1D array, mapping coordinates using:
$ k(i, j) = (i-1)(n - i/2) + j - i $
This saves roughly half the space.

With this data structure the problem is solved: we can just browse the data structure and emit all pairs.
Are we missing anything?
- *False Negatives?* No.
  The monotonicity (#link-theorem(<frequent-itemset-monotonicity>)) property guarantees that we never filter out a pair that *could* have been frequent.
  If a pair was destined to be frequent, both its constituent items *must* have survived Pass 1.
- *False Positives?* No, because we are actually counting the occurrences in Pass 2.

Does it always work? No!

#note[
  The problem for the trivial algorithm was that the number of counters was too much, so we applied a filter on the pairs we count.
  But we have *no guarantee* that this filtering actually reduces enough the number of pairs processed.
]

So, if the algorithm works, we have a correct solution, but the algorithm could crash because of the amount of RAM required is too much.

#example[
  We could have items that are frequent alone but are never bought together, so we could have a lot of singleton item to consider, but a lot of $0$ entries in the triangular matrix.
]

We need something *robust to sparseness*.

=== Hash Table for Triples

We have already seen something similar during PageRank, instead of storing a matrix we store a *triple* $(tilde(i), tilde(j), "counter")$, where triplets with counter $0$ are discarded.

With this representation, we have to find the triple in memory (if it exists) and modify it.
We don't have *immediate* access anymore.
We could use *hash functions* to build an index on these indices to get immediate access to the location of the triples:
$ (i, j, k) -> h(i, j, k) -> "Bucket" $

Since hash functions inevitably produce collisions, each bucket must point to a *linked list* containing the actual triples and their counts.

- *Collision Handling:* Triples falling into the same bucket are aggregated in a linked list.
- *Operation:* To increment a count, we compute the hash.
  - If the node exists in the list, we increment it.
  - If not, we append a new node.

#note[
  Strictly speaking, this is not constant time because we must traverse the linked list. However, if the number of buckets is sufficiently large relative to the number of frequent triples, the linked lists remain short and we operate in a regime of *quasi-constant access time*.
]

=== Trade-off: Triangular Matrix vs Hash Table

We now have two distinct methods for organizing counters in memory:
1. *Triangular Matrix:* Good for dense data.
2. *Hash Table:* Good for sparse data.

Space comparison:
- Triangular matrix: 1 integer per each entry
- Hash table: 3+ integers per each entry (the space for the indices, pointers, and the hashmap structure)

The best approach depends on the *sparseness* of the matrix.
If the matrix has less than $1/3$ of empty entries, then the triangular matrix is preferable.

#example[
  $n = 100000$ items, $b = 10000000$ baskets (10 items each).

  *Triangular Matrix*:
  $ binom(n, 2) approx 5 times 10^9 "counters" $

  *Hash Table (Worst Case)*:
  - Pairs per basket: $binom(10, 2) = 45$
  - Total pairs: $10^7 times 45 = 4.5 times 10^8$
  - Space per pair (approx 3 ints): $4.5 times 10^8 times 3 = 1.35 times 10^9$ integers

  The hash table requires less than $1/3$ of the space of the matrix. Even considering the worst case, using the hashmap approach is preferable as there are more than $2/3$ empty entries.
]

=== Expanding Beyond Pairs

In principle, we can apply the same idea to triples $(i, j, k)$, adding a *new pass*.
We increase the counter related to ${i, j, k}$ if and only if:
- ${i}, {j}, {k}$ are frequent as singletons
- ${i, j}, {j, k}, {i, k}$ are frequent as pairs

#note[
  The main property exploited by this approach is still *monotonicity* (#link-theorem(<frequent-itemset-monotonicity>)).
]

We can build up to any cardinality of the sets, simply by continuing iterating from the previous step. Each stage increases the dimension by $1$.

The general Apriori workflow is an iterative sequence of two operations:
1. *Filtering:* Pruning the candidates based on support.
2. *Construction:* Generating new candidates of size $k+1$ from frequent sets of size $k$.

We proceed iteratively ($L_1 -> C_2 -> L_2 -> C_3 -> ...$).
Each stage needs to do *one complete pass* on the baskets, so the complexity scales linearly with the cardinality of the resulting sets wanted.

#note[
  The data structures should be adapted for higher dimensions: we can use _pyramidal matrices_ and _quadruples_ instead of triples.
]

=== Correctness

We said that this algorithm is *exact*: it gives the right answer for each input instance.

When this algorithm *terminates*, it always gives the correct output.
Are we sure that it always terminates?
*No*, we could have too many frequent items and run out of space for the counters, resulting in a crash of the algorithm.

#warning[
  Apriori is an *exact algorithm*: if it terminates, it produces the correct result. However, it may fail before finishing due to:
  - *Integer Overflow:* Unlikely (4 bytes is usually enough for counts).
  - *Memory Exhaustion:* This is the real danger.
    Hash tables allocate memory dynamically, and we might exhaust RAM while appending new nodes to collision lists.
]

We can use other algorithms, based on Apriori algorithm that perform more aggressive filtering.

== Park-Chen-Yu Algorithm (PCY)

The idea is to exploit the free memory at the end of the first phase (when we still don't have a triangular or sparse counters in memory, just the indexing data structures).

#informally[
  During Pass 1, we only count singletons (items).
  This uses very little RAM.
  Most of the memory is idle, we should leverage that free memory.

  The idea is to keep some more information during the first phase, so that we can prune even more items.
]

=== PCY Pass 1

We utilize the idle memory to maintain an *hash table* of pair counts alongside the item counts.
We see the free memory as a long vector of integers (all starting from $0$) and use a hash function $h$ that hashes a pair of items $(i, j)$ into a position in the integers array.

The first two structures are constructed as for the Apriori algorithm, but during the scan we also *generate all* possible pairs for the items in that basket.
For each pair, we increment the integer at the position of the items hashed:
$ h(i, j) quad forall i, j in B quad forall B in "baskets" $

#warning[
  Different pairs could point to the same cell as collisions exist.
  This does not replace pass 2
]

=== Between Pass 1 and Pass 2

At the end of Pass 1, we analyze the hash buckets against the support threshold $s$:
- If $"Array"[h(i,j)] < s$: we know for sure that the pair $(i, j)$ can be *discarded*, as its support is for sure less than the threshold $s$.
- If $"Array"[h(i,j)] >= s$: we don't have any actual information on the pair (as a cell could be pointed by multiple pairs because of collisions), so we *keep* it for further processing.

#warning[
  Objection: we *filled* the whole remaining memory with the vector, where do we store the triangular matrix for the counters?
]

*Compression:* We do not need the actual counts for Pass 2, only the boolean status (Frequent/Not Frequent).
We compress the integer array into a *Bitmap*:
- If count $>= s ->$ bit = 1
- If count $< s ->$ bit = 0

*Space Gain:* An integer (32 bits) is replaced by 1 bit.
We reclaim $31/32$ of the memory to use for the actual counters in Pass 2.

=== PCY Pass 2

Now we proceed the same way as Apriori algorithm, with one further constraint.
Pair $(i, j)$ is counted only if:
1. $i$ and $j$ are both frequent singletons
2. The bit corresponding to $h(i, j)$ is 1

This "advanced filtering" allows us to discard many candidate pairs that Apriori would have counted, allowing us to handle larger datasets or lower support thresholds without running out of RAM.

#figure(
  {
    set text(size: 10pt)
    align(center, cetz.canvas({
      import cetz.draw: *
      stroke((thickness: 0.5pt))

      // Pass 1
      rect((0, 0), (4, -8))

      rect((0.2, -0.2), (1.9, -2.5))
      content((1.05, -1.35), align(center)[Item \ names \ to \ integers])

      rect((2.1, -0.2), (3.8, -2.5))
      line((2.6, -0.2), (2.6, -2.5))
      content((2.35, -0.5), [1])
      content((2.35, -1.0), [2])
      content((2.35, -2.3), [$n$])
      content((3.2, -1.35), align(center)[Item \ counts])

      rect((0.2, -2.7), (3.8, -7.8))
      content((2, -5.25), align(center)[Hash table \ for bucket \ counts])

      content((2, -8.6), [Pass 1])

      // Pass 2
      let off = 5.5
      rect((off, 0), (off + 4, -8))

      rect((off + 0.2, -0.2), (off + 1.9, -2.5))
      content((off + 1.05, -1.35), align(center)[Item \ names \ to \ integers])

      rect((off + 2.1, -0.2), (off + 3.8, -2.5))
      line((off + 2.6, -0.2), (off + 2.6, -2.5))
      content((off + 2.35, -0.5), [1])
      content((off + 2.35, -1.0), [2])
      content((off + 2.35, -2.3), [$n$])
      content((off + 3.2, -1.35), align(center)[Fre- \ quent \ items])

      rect((off + 0.2, -2.7), (off + 3.8, -3.3))
      content((off + 2, -3.0), [Bitmap])

      rect((off + 0.2, -3.5), (off + 3.8, -7.8))
      content((off + 2, -5.65), align(center)[Data structure \ for counts \ of pairs])

      content((off + 2, -8.6), [Pass 2])
    }))
  },
  caption: [Memory layout for PCY Algorithm Pass 1 and Pass 2],
)

=== Expanding Beyond Pairs

Using the same idea as before, we can construct itemsets bigger than pairs.

After generating the counters matrix/hashtable, we can compress it using the same idea: a *bitmap*, retaining information about the previous pass in very little space.
Repeating this pattern (hashing pairs into a new table, compressing into another bitmap, and filtering more aggressively) is the core idea of the *Multistage Algorithm*.

=== Multistage and Multihash Algorithm

Even with PCY, the bitmap might not filter enough pairs if there are too many collisions (i.e., too many "false positive" buckets).

/ Multistage Algorithm:
  Iterate the hashing process to filter more aggressively.
  + *Pass 1:* Standard PCY (creates Bitmap 1).
  + *Pass 2:* Do not count pairs yet.
    Instead, use a *second hash function* $h_2$ and a new hash table.
    Only hash pairs that pass the Bitmap 1 check.
  + *End of Pass 2:* Create Bitmap 2.
  + *Pass 3:* Count pairs that pass *both* Bitmap 1 and Bitmap 2.

  *Trade-off:* We reduce the number of counters needed (preventing memory overflow), but we pay the price of an *extra disk scan* (Pass 2 is now just for hashing).

  #figure(
    {
      align(center, cetz.canvas({
        import cetz.draw: *
        stroke((thickness: 0.5pt))

        // Pass 1
        rect((0, 0), (4, -8))

        rect((0.2, -0.2), (1.9, -2.5))
        content((1.05, -1.35), align(center)[Item \ names \ to \ integers])

        rect((2.1, -0.2), (3.8, -2.5))
        line((2.6, -0.2), (2.6, -2.5))
        content((2.35, -0.5), [1])
        content((2.35, -1.0), [2])
        content((2.35, -2.3), [$n$])
        content((3.2, -1.35), align(center)[Item \ counts])

        rect((0.2, -2.7), (3.8, -7.8))
        content((2, -5.25), align(center)[Hash table \ for bucket \ counts])

        content((2, -8.6), [Pass 1])

        // Pass 2
        let off2 = 5.5
        rect((off2, 0), (off2 + 4, -8))

        rect((off2 + 0.2, -0.2), (off2 + 1.9, -2.5))
        content((off2 + 1.05, -1.35), align(center)[Item \ names \ to \ integers])

        rect((off2 + 2.1, -0.2), (off2 + 3.8, -2.5))
        line((off2 + 2.6, -0.2), (off2 + 2.6, -2.5))
        content((off2 + 2.35, -0.5), [1])
        content((off2 + 2.35, -1.0), [2])
        content((off2 + 2.35, -2.3), [$n$])
        content((off2 + 3.2, -1.35), align(center)[Fre- \ quent \ items])

        rect((off2 + 0.2, -2.7), (off2 + 3.8, -3.3))
        content((off2 + 2, -3.0), [Bitmap 1])

        rect((off2 + 0.2, -3.5), (off2 + 3.8, -7.8))
        content((off2 + 2, -5.65), align(center)[Second \ hash table \ for bucket \ counts])

        content((off2 + 2, -8.6), [Pass 2])

        // Pass 3
        let off3 = 11.0
        rect((off3, 0), (off3 + 4, -8))

        rect((off3 + 0.2, -0.2), (off3 + 1.9, -2.5))
        content((off3 + 1.05, -1.35), align(center)[Item \ names \ to \ integers])

        rect((off3 + 2.1, -0.2), (off3 + 3.8, -2.5))
        line((off3 + 2.6, -0.2), (off3 + 2.6, -2.5))
        content((off3 + 2.35, -0.5), [1])
        content((off3 + 2.35, -1.0), [2])
        content((off3 + 2.35, -2.3), [$n$])
        content((off3 + 3.2, -1.35), align(center)[Fre- \ quent \ items])

        rect((off3 + 0.2, -2.7), (off3 + 3.8, -3.3))
        content((off3 + 2, -3.0), [Bitmap 1])

        rect((off3 + 0.2, -3.5), (off3 + 3.8, -4.1))
        content((off3 + 2, -3.8), [Bitmap 2])

        rect((off3 + 0.2, -4.3), (off3 + 3.8, -7.8))
        content((off3 + 2, -6.05), align(center)[Data structure \ for counts \ of pairs])

        content((off3 + 2, -8.6), [Pass 3])
      }))
    },
    caption: [Memory layout for Multistage Algorithm (Pass 1, Pass 2, and Pass 3)],
  )

A more efficient implementation that uses the same idea is to use two hash functions in parallel during the first pass.
Instead of using only one vector of integers with one hash function, we divide the remaining memory in two vectors and use two different hash functions that increase the counters of pairs.

/ Multihash Algorithm:
  Perform two hash filters *in parallel* to avoid the extra disk scan.
  + *Pass 1:* Split the available memory into two halves.
  + Run two hash functions ($h_1, h_2$) simultaneously into two separate hash tables.
  + *End of Pass 1:* Convert both tables into two bitmaps.
  + *Pass 2:* A pair is a candidate only if *both* $h_1(i, j)$ and $h_2(i, j)$ buckets are frequent.

  *Trade-off:*
  - Since we split memory, each hash table is half the size of the PCY table.
  - This increases collisions within each individual table.
  - However, the *intersection* of valid buckets might still be smaller than a single PCY filter.
  - *Benefit:* No extra disk scan required compared to Multistage.

  #figure(
    {
      align(center, cetz.canvas({
        import cetz.draw: *
        stroke((thickness: 0.5pt))

        // Pass 1
        rect((0, 0), (4, -8))

        rect((0.2, -0.2), (1.9, -2.5))
        content((1.05, -1.35), align(center)[Item \ names \ to \ integers])

        rect((2.1, -0.2), (3.8, -2.5))
        line((2.6, -0.2), (2.6, -2.5))
        content((2.35, -0.5), [1])
        content((2.35, -1.0), [2])
        content((2.35, -2.3), [$n$])
        content((3.2, -1.35), align(center)[Item \ counts])

        rect((0.2, -2.7), (3.8, -5.15))
        content((2, -3.925), [Hash Table 1])

        rect((0.2, -5.35), (3.8, -7.8))
        content((2, -6.575), [Hash Table 2])

        content((2, -8.6), [Pass 1])

        // Pass 2
        let off = 5.5
        rect((off, 0), (off + 4, -8))

        rect((off + 0.2, -0.2), (off + 1.9, -2.5))
        content((off + 1.05, -1.35), align(center)[Item \ names \ to \ integers])

        rect((off + 2.1, -0.2), (off + 3.8, -2.5))
        line((off + 2.6, -0.2), (off + 2.6, -2.5))
        content((off + 2.35, -0.5), [1])
        content((off + 2.35, -1.0), [2])
        content((off + 2.35, -2.3), [$n$])
        content((off + 3.2, -1.35), align(center)[Fre- \ quent \ items])

        rect((off + 0.2, -2.7), (off + 3.8, -3.3))
        line((off + 2.0, -2.7), (off + 2.0, -3.3))
        content((off + 1.1, -3.0), [Bitmap 1])
        content((off + 2.9, -3.0), [Bitmap 2])

        rect((off + 0.2, -3.5), (off + 3.8, -7.8))
        content((off + 2, -5.65), align(center)[Data structure \ for counts \ of pairs])

        content((off + 2, -8.6), [Pass 2])
      }))
    },
    caption: [Memory layout for Multihash Algorithm (Pass 1 and Pass 2)],
  )

== Sampling-Based Approaches

Up to this point, we assumed we had to process the entire dataset (stored on a hard disk). However, strict exactness might be traded for efficiency by working with a *sample* of the baskets in RAM.

If we could store all the baskets in main memory, then we would be able to compute the frequency of each pairs, triple or sets of any cardinality by just doing some scans of the Apriori algorithm.

Sampling the baskets and putting the sample in memory, we have no guarantee that the algorithm is exact anymore.
This can be seen as a *predictor*: it outputs some sets which it expects to be frequent.

Since we are using a statistical estimator, the output is not guaranteed to be exact.
We have the two classical errors:
- *False Positive (FP):* sets that are not frequent but are output of the algorithm
- *False Negative (FN):* actual frequent sets that are not in output of the algorithm

#warning[
  *False Positives* are "less bad" than False Negatives.
  We can treat the sample output as a set of *Candidate Sets*.
  With one full scan of the dataset, we can verify their actual support and remove the FPs.

  *False Negatives* are fatal.
  If the algorithm doesn't propose a set, we cannot verify it later, it is simply lost.
]

=== Sampling Strategy

To minimize variance, the sample must be *truly random*.
Simply taking the "first $N$ rows" of a file is dangerous because files often have temporal or logical ordering (e.g., Christmas sales grouped together), which would bias the sample.

A simple effective way for sampling is to just select each basket with a certain probability.

Once the sample is in RAM, we can run Apriori algorithm, given that we have enough free space to store the auxiliary data structures.

== Savasere-Omiecinski-Navathe Algorithm (SON)

The SON algorithm provides a way to use sampling *without* producing False Negatives.
It is an exact algorithm that lends itself perfectly to parallelization (using MapReduce).

It consists of four main phases:
1. *Partitioning:* We virtually divide the baskets file into $k$ chunks of equal size.
  Each chunk represents a "sample" of proportion $p = 1/k$.
2. *Local Processing:* Each chunk is brought into RAM and the Apriori algorithm is run with a scaled threshold $p s$ (with $s$ being the original treshold).
3. *Union of Candidates:* An itemset is a *global candidate* if it is frequent in *at least one* chunk.
4. *Verification:* Scan the entire dataset to count the support of these global candidates and filter out False Positives.

#note[
  We need to scale the support threshold $s$, dividing it by the number of chunks, resulting in $p s$.
]

#note[
  This is not really a sampling algorithm, as the whole baskets file is eventually processed.
]

It is obvious that we cannot have FP, as we explicitly removed them in the verification step.
But what about FN?

#theorem(title: "No False Negatives in SON")[
  If an itemset $I$ is frequent in the whole dataset ($"Supp"(I) >= s$), then there exists at least one chunk $C_i$ where the support of $I$ in that chunk is at least $p s$.

  #proof[
    Let's suppose that a FN $I$ exists.
    $I$ is frequent in the basket file, but $I$ is not in the output.
    Meaning it was never in output of the processing of each chunk: $I$ is not frequent in *any* chunk.
    $ forall "chunk" c, quad "Supp"_(c)(I) < p s $

    $
      "Supp"(I) & = sum_c "Supp"_(c)(I) \
                & < sum_c p s \
                & = k dot p s \
                & = s
    $

    Because $I$ is frequent, it must be $"Supp"(I) >= s$, which is a contradiction $qed$.
  ]
]

=== Implementation with MapReduce

In the case that the basket file is so big that it cannot even fit on the disk, we can compute these using two MapReduce jobs.

/ Job 1 - Candidate Generation: \
  All candidate sets are generated locally:
  $ "chunk" --> #rect[1st MAP] --> (C, 1) quad forall "candidate set" C $

  Then duplicates are removed with a reduce:
  $ (C, (1, 1, ...)) --> #rect[1st REDUCE] --> (C, 1) $

/ Job 2 - Verification: \
  Each map of the second job receives the pairs of the first reduce and loads a chunk from memory.
  It counts the frequency of that candidate set inside the chunk:
  $ ((C, 1), "chunk") --> #rect[2nd MAP] --> (C, v) $

  The reduce receives the frequency of a candidate set from all chunks, summing them up.
  The candidate set is emitted only if it exceeds the treshold:
  $ (C, (v_1, v_2, ...)) --> #rect[2nd REDUCE] --> (C, sum v_i) "if" sum_i v_i >= s $

== Toivonen's Algorithm

Sampling algorithms that gives *exact* results.
But on certain inputs, it cannot calculate a result (it does not crash or go into an infinite loop, it just stops without producing a result).

Setup of the algorithm:
+ It brings in RAM a basket sample of relative size $p$.
+ It runs Apriori algorithm (or a variant) with threshold $p s alpha$, where $0 < alpha < 1$.

#note[
  The idea is that by decreasing $alpha$ we use a more *permissive* threshold, including more candidates in the sample output, which reduces the chance of the algorithm failing to terminate due to sampling variance, at the cost of using more memory (increasing the risk of not terminating).
]

Then, the negative border of the candidate sets is computed.
The *negative border* is the group of sets that are *not* frequent, but whose immediate subsets are frequent in the sample.
Formally:

/ Negative Border:
  An itemset $I$ is in the Negative Border if:
  1. $I$ is *not* frequent in the sample.
  2. *All* immediate subsets of $I$ (sets created by removing exactly one element) *are* frequent in the sample.

  #note[
    Immediate subset are the subsets obtained by removing exactly one element from the original set.
  ]

  #warning[
    The empty set is always considered frequent.
  ]

  #example[
    Given items: $ A, B, C, D, E $
    and frequent sets: $ {A}, {B}, {C}, {D}, {B, C}, {C, D} $
    the negative border is: $ {E}, {A, B}, {A, C}, {A, D}, {B, D} $
  ]

Finally, the *full* baskets file is scanned, computing the *actual support* for all the *candidate sets* and all the *negative border*.
After the full scan:
+ *Filter Candidates:*
  The support for the candidates is used to remove FP, only the sets with $"Supp"(I) >= s$ are kept.
+ *Check Negative Border:*
  - If the actual support for *all* the negative border is *less* than the threshold, then the result is correct and the candidates are outputted.
  - If *any* member of the negative border is found to be frequent ($"Supp"(I) >= s$), the algorithm *failed* and no output is produced, as it could be *not exact*.

#warning[
  If a set in the negative border is actually frequent, it means our sample threshold was not low enough.
  We *missed* a set that should have been a candidate.
  Since monotonicity (#link-theorem(<frequent-itemset-monotonicity>)) implies we might have missed its supersets too, we must discard the results, resample, and restart.
]

#theorem(title: "No False Negatives in Toivonen's Output")[
  If Toivonen's algorithm actually terminates and provides an output, we are guaranteed that there are no false negatives.

  #proof[
    Let's prove this by contradiction:
    - Assume Toivonen's algorithm provides an output, meaning every subset $T$ in the negative border of the sample is verified to be *not* frequent in the overall dataset.
    - Assume there exists a false negative set called $S$.
    - By definition, $S$ must be frequent in the overall dataset, but was *not* frequent in our initial sample.
    - Because $S$ is frequent in the dataset, all of its subsets must also be frequent in the dataset (monotonicity #link-theorem(<frequent-itemset-monotonicity>)).
    - Let $T'$ be a subset of $S$ ($T' subset.eq S$) that is *not* frequent in the sample, chosen such that it has the minimal possible cardinality.
    - Because $T'$ has minimal cardinality among the non-frequent subsets, all immediate subsets of $T'$ *are* frequent in the sample.
    - Therefore, by definition, $T'$ belongs to the *negative border*.
    - But Toivonen's algorithm checks the negative border. If $T'$ is in the negative border and $T' subset.eq S$ (where $S$ is frequent), $T'$ must also be frequent in the dataset.
    - If a set in the negative border is found to be frequent in the entire dataset, the algorithm *halts and requires a new sample*.
    - This contradicts our initial assumption that the algorithm successfully provided an output $qed$.
  ]
]

#informally[
  In short: if the algorithm finishes, it means no itemset in the negative border was frequent in the main dataset.
  If no negative border itemset is frequent, no larger set (like our hypothetical $S$) can be frequent either.

  Toivonen never produces False Negatives if it terminates successfully.
  We just repeat until success (usually 1 or 2 tries).
]
