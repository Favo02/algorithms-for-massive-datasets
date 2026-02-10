#import "../template.typ": *

= Data Streams

Compute the average of a data stream:

The average of $n$ elements is:
$ x_1, ..., x_n --> overline(x)_n = 1/n sum_(i=1)^n x_i $

Adding one more element:
$
  overline(x)_(n+1) = 1/(n+1) sum_(i=1)^(n+1) x_i = (n dot 1) / (n(n+1)) sum_(i=1)^n x_i + (x_(n+1))/(n+1) = n / (n+1) overline(x)_n + x_(n+1) / (n+1) = (n overline(x)_n + x_(n+1)) / (n+1)
$
We do not need to keep all the elements, only the previous average.

That's a standing query: a query that keeps running indefinetely, even if the data stream is infinite.

Then there are queries that cannot be computed in that "easy" way, we need to think of a specific solution for each one: ad hoc queries.

The idea is to apply sampling.

We apply $10%$ sampling.

- whole stream: $s$ "simple" queries $+$ $d$ double queries $ = d / (d+s) $
- sampling: $s/10$ original simple queries $+ d/100$ originally occourring twice $+ 1/10 9/10 + 9/10 1/10$ originally double queries occurring once $ = d / (10s +19d) $

#note[
  Of the double queries, some could be sampled only the first one, some only the second one, so the sampled version is $1/100$ ($\/10$ for the first sampling, $\/10$ for the second sampling).

  Same if only one of the two gets sampled.
]

We are off by one order of magnitude using sampling.

Because of issues like synchronization and programmatically sampling (not good), sampling can be bad.
The bullet-proof way of sampling is pseudo random numbers.
For each element, extract the number and if the random number is $<0.1$ then take, otherwise do not take.

Another approach: instead of sampling queries, we sample users.
When a new element arrives, we check wheter or not the user have been sampled.
The disadvantage is the necessity of space for storing the users.

Instead of pseudo random generation, we use hash functions!
Given an hash function with $10$ buckets, keep elements of only users being hashed to the first bucket.

But even with that sampling, we could run out of memory for the queries of sampled users.
When this happens, the idea is to sample at a smaller fraction.

The sampling is hot-swappable: we can change ratio by swapping the hash function.
But the already stored elements are still in memory.

We store everything in a vector in memory.
#todo // TODO
treshold and moving the treshold

== Filtering (Set Membership)

- universe $U$
- $S subset.eq U$ (keys)
- $x in S$?

Each time we get a query, we need to search a data structure and check if we find the element $x$, if we find it, return yes.

An array would do the trick, but for example a search tree works better (log complexity).

=== Approximate Set Membership: Bloom Filter

We accept FP (but in a controlled number), we do not want FN.

A bloom filter consists of a bitmap (bit vector $b$) combined with an hash function.

Initially all the bits of the bitmap are initialized to $0$.
Then we consider each key $k$, set to $1$ the bucket obtained by hashing the key $k$ by a function $h$.

#note[
  With that approach, we can even add new keys on the way.
]

Each time a query $x in U$ arrives, we check wheter the bit array of the hashed element is equal to $1$.
If it is $1$ then it *could* be in the set of keys, otherwise it is surely not part of the set.

We are 100% sure that an element part of the keys "passes" the bloom filter, but we are not sure that an element not part of the keys gets rejected.

$ PP("pick one element") = 1/m $
$ PP("one element is not picked") = 1 - 1/m = (m-1)/m $
$
  PP("one element is not picked during filter building") & = ((m-1)/m)^n \
                                                         & = (1 - 1/m)^n \
                                                         & = (1 - 1/m)^(m n/m) \
                                                         & = ((1 - 1/m)^m)^(n/m) \
                                                         & = ((1 - 1/m)^m)^(n/m) \
                                                         & =_(m->infinity) e^(-n/m)
$

$ PP("one element picked at least one") = 1 - e^(-n/m) = underbrace("FPR", "False Positive Rate") $

#example[
  With the previous example, we have a $1/8$ FP rate.
]

We want to be able to control rate.
We have no control over $n$, but we can control $m$: the amount of RAM space that we can devote to the filter.

Another control we have over that: we can use multiple hash functions.
Each element gets hashed by multiple hash functions, so it can turn on multiple places of the array.

We denote with $p$ the number of hash functions.
$ "FPR" = (1-e^((-k n)/m))^k $

== Counting Distinct Elements

Flajolet Martin

We rely (again) on hash functions.
Hashing an element, gives us a binary number.

We are interested on the rail length of the number, the number of trailing zeros.

Foreach element in the stream $x$, hash it, compute the tail length.
Keep track of the maximum tail length.
Return $2^"max"$.

$ PP("last" r "bits ot the bucket are" 0) = 1 / (2^r) = 2^(-r) $

$ PP("none among" m "distinc elements is mapped to a bucket with" r "trailing zeros") = (1 - 2^(-r))^m $

$
  1 - (1/2^r)^m & = (1 - 1/2^r)^(m 2^r 2^(-r)) \
                & = ((1 - 1/2^r)^(2^r))^(m 2^(-r)) \
                & approx e^(-m 2^(-r))
$

- $ m >> 2^r --> m 2^(-r) approx "big" --> p -> 0 $
- $ m << 2^r --> m 2^(-r) approx 0 --> p -> 1 $

Because we dont want to be in neither of that cases, we select $m$ as:
$ m approx 2^(-underbrace(R, "max tail length")) $

#warning[
  This method is extremely sensitive to outliers.
]

To solve that problem, we use multiple counters and hash multiple hash functions.
Then we compute the median (not affected by outliers) of the results of each hash function.

But the median has other problems: it must be one of the results, so it is a power of $2$.
We could have not enough granularity.

The average could be another idea but it is affected by outliers.
So the solutions is to use both things, an average of the medians.

== Moments

The $r$-th moment is computed: $ sum_i m_i^r $

- $r = 0 --> sum_i m_i^0 = sum_"elements occurring in stream" 1 =$ number of distinct elements
- $r = 1 --> sum_i m_i =$ stream length
- $r = 2 --> sum_i m_i^2 =$ surprise number

...

=== Alon-Matias-Szegedy Algorithm (AMS)

Works by sampling the stream.
