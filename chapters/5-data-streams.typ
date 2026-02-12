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


// jack's note, 10/02/2026

= Data Streams

We speak of *data streams* when the data we want to analyze is not provided in a complete batch. Instead, data arrives in a continuous, temporal sequence.

*The main problem with streams:*

They are never-ending. We cannot store everything in memory.

To query them, we often use *standing queries* (never-stopping queries) instead of traditional ad hoc queries.

#example[
  *Tsunami Sensor:* \
  Imagine measuring the water level in the sea to prevent tsunamis. 
  - If a single sensor outputs 4 bytes, 10 times per second, it produces roughly 3.5 MB a day.
  - If we have 1 million sensors, that's 3.5 TB per day. We cannot store this indefinitely; we must process it on the fly.
]

== Ad Hoc Queries & Sampling

Sometimes we need to run specific queries on streams, which requires sampling.

#example[
  Let's suppose we take a *10% sample* of our stream.
  Suppose we are looking for simple events ($s$) and paired/double events ($d$).
  
  If we sample at 10%:
  - Simple events $s$ will appear in our sample as $s/10$.
  - For double events $d$ (pairs), what is the probability of capturing both parts, or just one?
    - Probability of capturing both: $1/10 * 1/10 = 1/100$
    - Probability of capturing exactly one: $2 * (1/10) * (9/10) = 18/100$
  
  This drastically distorts the ratios of events in our sample compared to the true stream
]

To fix this, we can sample by *User* or *Key* instead of by individual query. 
- If we keep a list of sampled users in Main Memory (MM), we can check if a new query belongs to a sampled user.
- *Problem:* Storing users takes up too much memory.
- *Solution:* Use a *Hash Function* as a pseudo-random generator

Hash the User ID into one of $B$ buckets. 
If we want a 10% sample, and we have 100 buckets, we accept the user if their hash falls into buckets $0$ through $9$. 
- This is *hot-swappable*: If we run out of memory, we can dynamically lower the threshold (only accept buckets $0$ through $4$) to reduce the sample to 5%, democratically "killing" elements to free up RAM.

== Filtering (Set Membership)

Given a universe of items and a trusted subset $S$, we want to answer: *Is $x in S$?*

#example[
  *Rudimentary Email Filtering:* \
  Let $S$ be a list of trusted email addresses ($|S| = 10^9$). We only have 1 GB of RAM. A standard search tree won't fit.
]

=== Bloom Filters

A Bloom filter is a bit-vector (bitmap) coupled with hash functions.
- *Goal:* We accept False Positives (FP) (occasionally delivering spam to the inbox) but strictly NO False Negatives (FN). We never want to drop a trusted email.

*Construction:*
1. Initialize an array of $m$ bits to 0.
2. Choose $k$ independent hash functions.
3. For every key in $S$, hash it with all $k$ functions. Set the bit at those resulting indices to 1.
   $ forall x in S, "and" forall i in [1, k], quad b[h_i (x)] = 1 $

*Querying:*
To check if $x$ is in $S$, hash $x$ with all $k$ functions. 
- If *all* corresponding bits are 1, we predict $x in S$.
- If *any* bit is 0, we know for certain $x in.not S$ (No False Negatives).

*False Positive Rate Math:*
- Probability a specific bit is *not* flipped to 1 by a single hash function: $(1 - 1/m)$
- Probability a bit is *not* flipped after inserting $n$ elements using $k$ hash functions: $(1 - 1/m)^(k n)$
- Using the limit for $m$ to infinity, we approximate this as: $e^(-k n/m)$
- Therefore, the probability that a bit *is* 1 is: $1 - e^(-k n/m)$
- For a false positive to occur, all $k$ hash functions must hit a bit that is 1. The False Positive Rate (FPR) is:
  $ "FPR" = (1 - e^(-k n/m))^k $

#note[
  To lower the FPR, you either need to increase $m$ (devote more RAM to the bit array) or optimize the number of hash functions $k$. Time complexity remains constant $O(k)$.
]

= Counting Distinct Elements

How do we count the number of unique elements in a stream without storing them? We use the *Flajolet-Martin Algorithm*.

We rely on hash functions and look at the binary representation of the hash values.
- We are interested in the *tail length* ($R$): the number of trailing zeroes in the binary hash.
  - For example, for `00110`, $R = 1$. For `01000`, $R = 3$.

*Algorithm:*
```pseudocode
max_r = 0
for all x in stream:
  r = tail_length(hash(x))
  if r > max_r:
    max_r = r
return 2^(max_r)
```

Why it works: The probability that a hash ends in r trailing zeros is 2(-r). If we have $m$ distinct elements, the probability that none of them map to a hash with $r$ trailing zeros is: $ (1 - 2^(-r))^m approx e^(-m 2^(-r)) $

    If m >> 2r, this probability approaches 0 (we will definitely see this r).

    If m << 2r, this probability approaches 1 (we will rarely see this r).

    The crossover point happens when mapprox2r. Thus, 2(R"max") is a good estimator for m.

#warning[ 
This basic method is extremely sensitive to outliers (one lucky hash with many zeroes ruins the estimate).

Solution: Use multiple hash functions. Group them, compute the average estimate within each group, and then take the median of those averages. The median ignores extreme outliers.
]

= Stream Moments

Moments capture the frequency distribution of items in a stream. Let $m_i$ be the number of occurrences of the i-th item.

The k-th moment is defined as: $ sum_i (m_i)^k $

    0th Moment (k=0): sum($m_i$)0= Number of distinct elements.

    1st Moment (k=1): sum($m_i$)1= Total length of the stream.

    2nd Moment (k=2): sum($m_i$)2= The Surprise Number.

The Surprise Number captures the unevenness or variance of the data.

#example[ 
Suppose a stream has 100 elements and 11 distinct item types.

Most uniform distribution: 10 items occur 9 times, 1 item occurs 10 times. $ M_2 = 10 * (9^2) + 1 * (10^2) = 810 + 100 = 910 $

Least uniform distribution (highly skewed): 1 item occurs 90 times, 10 items occur 1 time. $ M_2 = 1 * (90^2) + 10 * (1^2) = 8100 + 10 = 8110 $ ]

== The AMS Algorithm (Alon-Matias-Szegedy)

If we don't have enough space to count exact frequencies, we use AMS to estimate the Second Moment.

    Let n be the length of the stream (assumed known/counted).

    Pick a random position in the stream uniformly. Let the item at this position be X.

    Keep a counter c. Starting from that random position, count every subsequent occurrence of X in the stream.

    The estimate for the second moment is: $ n * (2c - 1) $

    To get a highly accurate result, extract many random positions, calculate this value for each, and average the results.

    

// jack's note 12/02/2026

= Data Streams: The Second Moment

Recall that items in the stream must be ordered.

#example[
  Consider the stream: $ a, b, c, b, d, a, c, d, a, b, d, c, a, a, b $
  The length of the stream is $n = 15$.
  The frequencies are:
  - $m_1 (a) = 5$
  - $m_2 (b) = 4$
  - $m_3 (c) = 3$
  - $m_4 (d) = 3$
  
  The second moment is:
  $ F_2 = sum_i m_i^2 = 25 + 16 + 9 + 9 = 59 $
]

== The AMS Algorithm

The AMS algorithm allows us to estimate $F_2$ by selecting positions in the stream uniformly at random.
We are free to choose how many positions (variables) we select; the number of positions affects the accuracy.

Let's say we pick three positions at random: the first `c`, the second `d`, and the penultimate `a`.

For each selected position, we track:
1.  The *element* at that position (for example "c").
2.  The *value* ($r$): the number of co-occurrences of that specific element from that position *onwards* until the end of the stream.

#warning[
  I cannot access the stream like a vector! I only have access to the *last* element seen. Therefore, I need to store the element itself to check for future matches.
]

=== The Estimator

For each selected position $i$, we define a random variable $X$:
$ X = n (2 dot r - 1) $
Where:
- $n$ is the total stream length.
- $r$ is the count of the element from the chosen position onwards.

In our example ($n=15$):
- If we picked the first `c`: it appears 3 times from there. $X_1 = 15(2 dot 3 - 1) = 75$.
- If we picked the second `b`: it appears 2 times from there. $X_2 = 15(2 dot 2 - 1) = 45$.
- If we picked the last `c`: it appears 1 time. $X_3 = 15(2 dot 1 - 1) = 15$.

We basically create a specification of a random variable whose expected value is the second moment. If we average multiple estimates, the value converges to the true $F_2$.

=== Proof of Expectation

We want to prove that $E[X] = F_2 = sum m_i^2$.

The probability of selecting any specific position $i$ in a stream of length $n$ is $1/n$.
So, the expected value is the sum over all possible positions $p$:
$ E[X] = sum_(p=1)^n P("picking " p) dot (n(2r_p - 1)) $
$ E[X] = sum_(p=1)^n 1/n dot n(2r_p - 1) = sum_(p=1)^n (2r_p - 1) $

We can rearrange this sum by grouping not by position, but by *element*.
Let's look at element `a`. It appears $m_a = 5$ times.
Working from right to left (end of stream to start), the values of $r$ for `a` will be:
- Last `a`: $r=1$
- Second to last `a`: $r=2$
- ...
- First `a`: $r=5$

So for each distinct item $i$, the contribution to the total sum is:
$ sum_(j=1)^(m_i) (2j - 1) $

#theorem("Sum of Odd Numbers")[
  The sum of the first $k$ odd numbers is equal to $k^2$.
  $ sum_(j=1)^k (2j - 1) = k^2 $
]

Substituting this back into our expectation:
$ E[X] = sum_(i in "items") (sum_(j=1)^(m_i) (2j - 1)) = sum_(i in "items") m_i^2 = F_2 $

This confirms that $X$ is an unbiased estimator for the second moment.

== Handling Infinite Streams (Reservoir Sampling)

In the proof above, we assumed we knew $n$ (the stream length). But in a real stream, $n$ grows continuously and we don't know when it ends.
If we run out of memory, we can't just "add" more counters.

*Solution:* We maintain a fixed number of counters $s$ (based on RAM) and use *Reservoir Sampling*.

1.  *Initialization:* Store the first $s$ positions with probability 1.
2.  *Invariant:* At any time $n$, every position seen so far has been chosen with probability $s/n$.
3.  *Update:* When the $(n+1)$-th element arrives:
    - We keep it with probability $s/(n+1)$.
    - If kept, we discard one of the existing $s$ counters uniformly at random.

=== Proof of Uniform Probability

We need to prove that after processing element $n+1$, the probability of any specific previous element remaining in the sample is still uniform ($s/(n+1)$).

Let's use the *Law of Total Probability*. A stored element survives if:
1.  It was already in the memory (Prob: $s/n$).
2.  AND it was NOT evicted.

It is NOT evicted if:
- The new element was not picked (Prob: $1 - s/(n+1)$).
- OR the new element was picked, but the random index chosen to be replaced was *not* our element.

$ P("survive") = underbrace(s/n, "was in") dot [ underbrace((1 - s/(n+1)), "new ignored") + underbrace(s/(n+1) dot (s-1)/s, "new kept, other swapped") ] $

Simplifying the term in brackets:
$ 1 - s/(n+1) + (s-1)/(n+1) = (n + 1 - s + s - 1)/(n+1) = n/(n+1) $

So the total probability is:
$ s/n dot n/(n+1) = s/(n+1) $

The invariant holds. We can estimate moments on infinite streams without running out of memory.