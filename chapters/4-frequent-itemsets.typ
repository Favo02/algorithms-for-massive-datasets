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
