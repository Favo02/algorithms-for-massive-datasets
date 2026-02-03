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


--- jack

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
$ S u p p (I) = |{B in cal(B) : I subseteq B}| $

#note[
If we have 1,000,000 baskets, we count exactly how many times the pair "{torch, lollipop}" appears. This helps us ignore rare, coincidental occurrences.
]

==== 2. Confidence
The *Confidence* of a rule $A -> b$ measures how often the item $b$ appears in baskets that already contain the set $A$. It is defined as the ratio:
$ C o n f (A -> b) = (S u p p (A cup(b)))/(S u p p (A)) $

#nota[
A confidence of $0.2$ means that $20%$ of the time a customer buys a torch, they also buy a lollipop. This conditional probability allows us to gauge the predictive power of the rule.
]

Even with high confidence, a rule might be misleading if the item $b$ is already extremely common. To account for this, we introduce the concept of *Interest*.

The interest of a rule $A -> b$ is defined as the difference between its confidence and its expected probability based on the overall frequency of $b$:

$ I n t e r e s t (A -> b) = C o n f (A > b) -  S u p p (b)/("Total Baskets") $

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

#esempio[
Suppose we have 2 GB of RAM ($2^31$ bytes) and use 4-byte integer counters.
To store counters for all pairs:
$ 4 \times (n^2)/(2) = 2n^2 $
Setting $2n^2 <= 2^31$ gives $n <= sqrt(2^30) approx 32,768$.
]

#note[
A supermarket with 33,000 items might barely fit its pair-counters into RAM, but any larger inventory will crash the system.
]

Unlike the LSH approach where we accepted approximate solutions via hashing, here we want to find *all* frequent sets exactly. To escape the quadratic memory wall without losing accuracy, we need to filter the itemsets we track.

This leads us to a family of algorithms designed to prune the search space, starting with the fundamental *A-Priori Algorithm*.

#definizione[
The A-Priori algorithm is a constructive solution to the frequent itemset problem. It is organized into two distinct main steps.
]

#attenzione[
Each step requires a full pass over the basket file. Since the file sits in mass memory (hard disk), the execution time is dominated by Input/Output (I/O) operations.
]

=== Pass 1
The goal of the first pass is to identify which individual items are frequent. We maintain two data structures in RAM:

1.  *Item Dictionary:* Maps item names to a univocal integer ID ($0 dots N$).
2.  *Frequency Table:* A table where `Column 1` is the ID and `Column 2` is the count.

As we scan the baskets, we build these dynamically.
- If an item is new, assign it a new ID.
- If it exists, increment the counter.

Once the pass is complete, we check which items exceed the support threshold $s$.
- *Non-Frequent items:* Labeled as `-1` (or discarded).
- *Frequent items:* Assigned a new, dense progressive ID ranging from $1$ to $m$ (where $m < N$).

How does this scale? Linearly with the number of *distinct* items.
Even in a worst-case scenario with 1 million distinct items, we are talking about *Megabytes* (maybe 100MB), not Gigabytes. We are using a tiny fraction of RAM, leaving plenty of free space for the heavy lifting in Pass 2.

Before Pass 2, we need a theoretical justification for ignoring certain pairs. We exploit *Monotonicity*:
If we have a set $A$ and a superset $B$ (so $A subseteq B$), the support must satisfy:
$ S u p p (A) >= S u p p (B) $

If $B$ is a frequent itemset, then by definition $S u p p (B) >= s$. By transitivity, $ S u p p (A) >= s$, so $A$ must also be frequent.

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
1.  *Symmetry:* $C[i, j]$ is the same as $C[j, i]$. We don't need to store both.
2.  *Sparseness:* We only care about frequent items (which we solved by remapping IDs), but a full square matrix still scales quadratically.

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