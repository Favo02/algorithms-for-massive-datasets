#import "../template.typ": *

= Data Streams

Streams are a continuous flow of data.
If it is not _processed_ or _stored_ immediately, then it's lost forever.
Systems that analyze streams must process data in *real time*.

#note[
  We must assume that data arrives so rapidly that it's impossible (or too expensive) to store it in a conventional database to analyze later.
  Storing the data is used only for _archival_ purposes, not for real time querying.
]

#example[
  Stream data arises naturally in various scenarios:
  - *Sensor Data:* E.g., ocean surface height sensors producing a reading every tenth of a second, generating a few megabytes per day.
    With a lot of sensors, a million (not unrealistic, the ocean is very big), we generate terabytes of data daily.
  - *Image Data:* E.g., Satellites or surveillance cameras sending continuous image streams.
  - *Internet and Web Traffic:* E.g., search engines tracking billions of queries and clicks to detect trends.
]

Stream processors (not actual CPUs, but software) are data management systems where any number of _streams_ enters the system.
Each stream provides elements at its own schedule and the arrival rate is not under the system's control.
The system works with a limited amount of RAM and a storage used for archival purposes.

#figure(
  cetz.canvas({
    import cetz.draw: *

    // Input streams (left side)
    let input-streams = (
      (name: "Stream 1", y: 2),
      (name: "Stream 2", y: 0.5),
      (name: "Stream 3", y: -1),
    )

    for stream in input-streams {
      line((-4, stream.y), (-2, stream.y), mark: (end: ">"))
      content((-4.5, stream.y), stream.name, anchor: "east")
    }

    // Stream Processor (center)
    rect((-2, -1.8), (2, 3), name: "processor")
    content((0, 3.5), text(weight: "bold")[Stream Processor], anchor: "south")

    // Standing queries inside processor
    content((0, 1.5), [Standing Query 1], fill: white)
    content((0, 0.5), [Standing Query 2], fill: white)
    content((0, -0.5), [Standing Query 3], fill: white)

    // Output streams (right side)
    line((2, 1.5), (4, 1.5), mark: (end: ">"))
    content((4.5, 1.5), [Query Results], anchor: "west")

    line((2, 0), (4, 0), mark: (end: ">"))
    content((4.5, 0), [Alerts], anchor: "west")

    // Storage boxes below processor
    rect((-2, -3.2), (0, -2.7), name: "ram")
    content((-0.99, -2.95), text(size: 0.8em)[RAM], anchor: "center")
    rect((0.15, -3.2), (2, -2.7), name: "archive")
    content((1.1, -2.95), text(size: 0.8em)[Storage], anchor: "center")

    line((1, -2.7), (1, -1.8), mark: (start: ">", end: ">"))
    line((-1, -2.7), (-1, -1.8), mark: (start: ">", end: ">"))
  }),
  caption: [Data Stream Management System],
)

#note[
  This uses the opposite architecture of a traditional system that uses a database:
  - _Pull_ (database): the data is stored on disk and the system retrieves it when needed.
  - _Push_ (stream processor): the data is continuously pushed into the system as it arrives, and the system must process it on the fly.
]

Processing streams involve a *summarization* of the stream data in some way.
Instead of trying to store every single piece of data, summarization consists of keeping continuously _updated statistics_ or highly compact data structures in Main Memory (RAM).
Summarization can be also approached by looking at only a _fixed length window_ consisting of the last $n$ elements for some large $n$, querying the window only when necessary.

#example[
  Streams are usually dumped into huge storage (e.g. Amazon S3).
  Because of the slow retrieval times, it's impossible to answer real time queries from there.

  For some purposes that require the full data but are not strictly real time (e.g., training a new ML model or an historical analysis), heavy retrieval processes are needed, but still possible.

  But for real time queries, we need to keep only a small, continuously updated summary of the stream in RAM.
]

#warning[
  From now on, all the proposed solutions does *not* involve loading past history from storage.
]

There are two primary ways queries are asked on streams:
+ *Standing Queries:*
  These queries are submitted once but execute _permanently_.
  They continuously inspect the stream as it flows and produce outputs/_alerts_ when specific conditions are met (e.g., "Alert if the temperature is $> 25°"C"$").
+ *Ad-hoc Queries:*
  Questions asked _once_ about the current state (like a standard SQL `SELECT`).

#note[
  Since we throw away the full stream, answering *arbitrary* queries in real time is impossible.
  We can build systems that answer specific, _pre-defined_ queries (standing queries) or ad-hoc queries on a _limited sliding window_, but we cannot answer any question about the entire stream history.
]

#example[
  / Standing Query: Computing the average of a stream of numbers.

    The average of $n$ elements $x_1, ..., x_n$ is defined as:
    $ overline(x)_n = 1/n sum_(i=1)^n x_i $

    Adding one more element:
    $
      overline(x)_(n+1) & = 1/(n+1) sum_(i=1)^(n+1) x_i \
                        & = (n dot 1) / (n(n+1)) sum_(i=1)^n x_i + (x_(n+1))/(n+1) \
                        & = n / (n+1) overline(x)_n + x_(n+1) / (n+1) \
                        & = (n overline(x)_n + x_(n+1)) / (n+1)
    $

    To answer the query, we do not need to keep all the elements, only the previous average.

  / Ad-Hoc Query: Unique daily users that logged in:

    If logins are elements, we maintain a sliding window of all logins in the last day as a relation `Logins(name, time)`. The ad-hoc SQL query is:
    `SELECT COUNT(DISTINCT(name)) FROM Logins WHERE time >= t;`.
    The sliding windows drops old logins as time passes, so we only keep the relevant data for the last day in RAM.
]


Often, it is much more efficient (and sometimes absolutely necessary) to get an *approximate answer* rather than an exact solution.

== Sliding Window Approach

To allow ad-hoc queries on the _recent past_, we can store a *sliding window* in RAM: we buffer only the most recent $n$ elements, or all elements from the last $t$ minutes.
When new data enters, the oldest data falls out of the window and is discarded.

== Sampling Approach

Another technique is *sampling* the stream.
The sample should maintain the same _statistical properties_ as the original stream.

#note[
  In statistics, sampling is the selection of a _subset_ of individuals within a population to estimate characteristics of the whole population.
]

Naively, we could sample the stream by keeping an element with a fixed probability  and discarding it otherwise.
However, this approach can lead to *distortions* in the sample.

#example[
  Let's suppose we take a *$10%$ sample* of a stream of user logins ($s$) and logins + likes ($d$) events.

  - For simple login events $s$ will appear in our sample as $s/10$.
  - For login + like events $d$, what is the probability of capturing both parts, or just one?
    - Probability of capturing both: $1/10 dot 1/10 = 1/100$
    - Probability of capturing exactly one: $2 dot (1/10) dot (9/10) = 18/100$

  This drastically *distorts* the ratios of events in our sample compared to the true stream.

  / Why does this distort: Suppose in the original stream we have equal numbers of $s$ and $d$ events (ratio 1:1). But in our 10% sample:
    - Login events $s$: appear with probability $1/10$ (10% survive).
    - Complete paired events $d$: appear with probability $1/100$ (only 1% survive as intact pairs).

    The sample now contains 10 times more login only events than paired events, completely inverting the original 1:1 ratio into approximately 10:1.
]

To fix the distortion, we must sample by a _unifying property_, (e.g., sample users and then take all events of that user), rather than by individual stream elements.

#example[
  If we want a 10% sample of users, we can randomly select 10% of user IDs and then keep all events from those users.
  This way, the ratio of different event types remains intact within the sample, preserving the statistical properties of the original stream.
]

Another problem arises: storing in memory all the IDs of the users we want to sample could *saturate* our RAM.

The Solution is hashing: instead of storing IDs, we use a *hash function* $h(x)$ to map each User ID into one of $B$ buckets.
Then we only keep events from users whose hash falls into a specific subset of buckets.
This approach has two key advantages:
- A hash function is _deterministic_: the same User ID will always hash to the exact same bucket.
  Therefore, we don't need to store the IDs, only the bucket numbers.
- _Dynamic Resizing:_ we can dynamically lower the threshold of accepted buckets to adjust the sampling rate without changing the hash function or the underlying data structure.

#example[
  With $B=100$ buckets, we can easily adjust our sampling rate by changing the number of accepted buckets:
  - If we want a $5%$ sample, we accept the event only if the hash falls into buckets $[0, 4]$.
  - If we want a $10%$ sample, we accept the event only if the hash falls into buckets $[0, 9]$.

  This can change based on the current load of the system.
]

== Filtering Streams (Set Membership)

Given a universe of items $U$ and a subset $S subset.eq U$, we want to check whether an element $x$ of the stream *is in* $S$: $x in S$?
When the size of the subset $S$ is huge, we cannot store it in RAM to check membership with a standard data structure (e.g., hash table or search tree).

#example[
  *Email Filtering:* Let $S$ be a list of trusted email addresses ($|S| = 10^9$).
  Storing 1 billion strings would require dozens of Gigabytes.
  We want to filter emails not in $S$ (e.g., spam) without storing the entire list of trusted emails in RAM.
]

=== Bloom Filters

The solution is a *Bloom Filter*, a _probabilistic_ data structure that allows us to check set membership with a compact representation, at the cost of allowing some _false positives_ (FP).

A Bloom filter solves the memory problem by using a bit-vector (_bitmap_) coupled with _hash_ functions.
Instead of storing the actual elements, it stores their _footprints_.
Because multiple elements might accidentally leave the same footprint (hash collisions), we must accept *False Positives (FP)* (e.g., occasionally predicting an unknown email is trusted, delivering spam to the inbox).
However, we guarantee strictly *no False Negatives (FN)* (e.g., if an email is truly in $S$, it will never be dropped by mistake).

+ / Construction (Pre-processing $S$):
  - Initialize an array $b$ of $m$ bits to 0.
  - Choose $k$ independent hash functions.
  - For every key in our trusted list $S$, hash it with all $k$ functions.
    Set the bits at those resulting indices to 1:
    $ forall x in S, quad forall i in [1, k], quad b[h_i (x)] = 1 $

+ / Querying the Stream (Checking $x$):
  As the stream flows, check if an element $x$ is in $S$ by hashing it with the same $k$ functions.
  - If *any* corresponding bit is 0, the footprint is incomplete: we know for certain $x in.not S$ (Zero False Negatives).
  - If *all* corresponding bits are 1, we predict $x in S$.
    Note that these bits might have been set to 1 by a combination of other elements, which is exactly what causes a False Positive.

The time complexity for checking an element is constant $O(k)$.

=== False Positive Probability

To understand how likely a False Positive is, we calculate the probability that a specific bit is 1 just by chance after inserting $n$ elements:

$
       PP("bit" = 1 | "single hash") & = 1/m \
       PP("bit" = 0 | "single hash") & = 1 - (1/m) \
          PP("bit" = 0 | "k hashes") & = (1 - 1/m)^(k) quad   &   #comment("all hashes are independent") \
  PP("bit" = 0 | "after n elements") & = (1 - 1/m)^(k n) quad & #comment("all elements are independent") \
  PP("bit" = 0 | "after n elements") & approx e^(-k n/m) quad &    #comment("approximation for large m") \
                       PP("bit" = 1) & = 1 - e^(-k n/m) \
$

Having already inserted $n$ elements, to get a False Positive, all $k$ hash functions must hit bits that are already 1:
$ PP("FP") approx (1 - e^(-k n/m))^k $

#note[
  To lower the FPR, either increase $m$ (use more RAM for the bit array to reduce crowding) or optimize the number of hash functions $k$.
]

== Counting Distinct Elements

Given a stream, we want to count the number of *unique* elements it contains.
When the amount of distinct elements is huge, we cannot store them in RAM to count them with a standard data structure (e.g., hash set or search tree).

#example[
  A search engine might want to know how many unique queries it receives in a day.
  With billions of queries, storing them all to count distinct ones is infeasible.
]

=== Flajolet-Martin Algorithm

The intuition is to exploit the randomness of *hash* functions, specifically:
- _Determinism_: the same element always produces the same hash value
- _Uniform distribution_: hash values are uniformly distributed across the binary space

We look at the binary representation of the hash values and focus on the *tail length* ($R$): the number of _trailing_ zeroes.
For example, `00110` has $R = 1$, while `01000` has $R = 3$.

#informally[
  If we see a hash with a long tail of zeroes (e.g., `000`), it is a very rare event (probability $1/8$).
  So we estimate that we must have seen about $8$ distinct elements to encounter such a rare hash.
]

#pseudocode(
  [$R_"max" <- 0$],
  [*Forall* $x$ in stream *do*],
  indent(
    [$r <-$ tail_length($h(x)$)],
    [$R_"max" <- max(R_"max", r)$],
  ),
  [*Return* $2^(R_"max")$],
)

=== Correctness Probability

The probability that a single hash ends in exactly $r$ trailing zeros is $1 / 2^r = 2^(-r)$.
If we have $m$ *distinct* elements, the probability that *none* of them map to a hash with $r$ trailing zeros is:
$ (1 - 2^(-r))^m approx e^(-m 2^(-r)) $

$
           PP("single hash has" r "trailing zeros") & = 1/2^r = 2^(-r) \
       PP("single hash has not" r "trailing zeros") & = 1 - 2^(-r) \
  PP("none of" m "elements has" r "trailing zeros") & = (1 - 2^(-r))^m) \
  PP("none of" m "elements has" r "trailing zeros") & approx e^(-m 2^(-r)) \
$

The number of distinct elements $m$ influences how likely we are to see a hash with $r$ trailing zeros:
- If $m >> 2^r$, we have made many attempts, $PP -> 1$
- If $m << 2^r$, we have made very few attempts, $PP -> 0$

Because of this, if the absolute longest tail we recorded during the stream is $R_"max"$, it implies we processed approximately $2^(R_"max")$ distinct elements to achieve that record.

#warning[
  The *outlier* Problem: This basic method is extremely sensitive to outliers.
  One single "lucky" hash with 20 trailing zeroes will completely ruin the estimate even if we have only 100 distinct elements in the stream.
]

The solution is to use multiple independent hash functions and take the *median* (not influenced by outliers) of their estimates to get a more stable and accurate result.
This poses another problem: this will result in only power of two estimates.

To fix this, usually the final estimate is calculated as the *average* of the *median* estimations from various _groups_ of hash functions, which allows for a more continuous range of estimates.

Both the space and time complexity are $O(k)$, where $k$ is the number of hash functions.

== Stream Moments

Moments are statistical metrics used to capture the _shape_ of a distribution, based on the *frequencies* of distinct items in a stream.

Let $m_i$ be the number of occurrences (frequency) of the $i$-th distinct item.
The $k$-th moment is defined as the sum of all frequencies raised to the power of $k$:
$ sum_i (m_i)^k $

By changing the exponent $k$, we inspect a different aspect of the stream's distribution:

- *0th Moment* ($k=0$): $sum_i (m_i)^0$
  Since any number to the power of $0$ is $1$, we are simply adding $1$ for every unique item we see, regardless of its frequency. This represents the *number of distinct elements* (what the Flajolet-Martin algorithm estimates).

- *1st Moment* ($k=1$): $sum_i (m_i)^1$
  Since any number to the power of $1$ is itself, we are just summing all the frequencies together. This gives us the *total length of the stream*.

- *2nd Moment* ($k=2$): $sum_i (m_i)^2$
  By squaring the frequencies before summing them, we disproportionately amplify the weight of items that appear very often.
  It measures how uneven or skewed the data distribution is.
  This is called the *surprise number*.

  #example[
    2nd Moment Example:
    Suppose a stream has 100 elements and 11 distinct item types.

    - Scenario A (almost uniform distribution):
      10 items occur 9 times, and 1 item occurs 10 times.
      $ M_2 = 10 dot (9^2) + 1 dot (10^2) = 810 + 100 = 910 $

    - Scenario B (least uniform distribution, highly skewed):
      1 item occurs 90 times, and 10 items occur 1 time.
      $ M_2 = 1 dot (90^2) + 10 dot (1^2) = 8100 + 10 = 8110 $

    The surprise number in Scenario B is huge, representing the highly skewed distribution.
  ]

Calculating the moments with enough RAM is trivial, but when the number of distinct items is huge, we cannot maintain exact frequency counters for all of them.

=== Alon-Matias-Szegedy Algorithm (AMS)

The AMS algorithm *estimates* the second (and higher) moments by randomly _sampling_ just a few specific positions in the stream.

The algorithm decides in advance to track a _fixed number_ of _variables_, the more variables used, the higher the accuracy of the estimate.
For each selected variable $X$, we track two things:
1. The *element* $e$ found at the chosen position.
2. The *number of occurrences* $v$ of that element from that position onwards until the end of the stream.

#warning[
  Because the stream is not saved (and cannot be accessed like an array), these variables needs to be defined beforehand.
]

The *estimator formula* for second moment is then applied to the counters $v$ of each variable $X$, where $n$ is the total stream length:
$ "estimate" = n (2v - 1) $

#warning[
  The algorithms needs to know the total stream length $n$ in advance to pick random positions uniformly and to apply the estimator formula correctly.
]

The second moment is estimated by taking the *average* of all the $k$ independent variables $X$ we tracked:
$ hat(F_2) = (1/k) sum_(i=1)^k "estimate"_i $

#example[
  Consider a stream of length $n = 15$:
  $ a, b, c, b, d, a, c, d, a, b, d, c, a, a, b $

  The true frequencies are:
  - $m(a)=5, space m(b)=4, space m(c)=3, space m(d)=3$

  The exact second moment is:
  $ F_2 = sum_i (m_i)^2 = 25 + 16 + 9 + 9 = 59 $

  To estimate $F_2$ with the AMS algorithm, we decide to track only 3 variables (due to RAM constraints), picking 3 random positions uniformly from the stream:
  - Position 3 (element $c$)
  - Position 8 (element $d$)
  - Position 13 (element $a$)

  Now we count their occurrences from that point forward ($v$):
  - For pos 3 ($c$): pos 3, 7, 12. $v_1 = 3$.
  - For pos 8 ($d$): pos 8, 11. $v_2 = 2$.
  - For pos 13 ($a$): pos 13 and 14. $v_3 = 2$.

  The estimates for each variable are:
  - $X_1 = 15(2 dot 3 - 1) = 15(5) = 75$
  - $X_2 = 15(2 dot 2 - 1) = 15(3) = 45$
  - $X_3 = 15(2 dot 2 - 1) = 15(3) = 45$

  The final estimate is the average:
  $ hat(F_2) = (75 + 45 + 45) / 3 = 55 $

  The estimate is close to the true $F_2$ of $59$, while tracking only 3 variables.
]

=== Algorithm Correctness

The *expected value* (the statistical average) of every random variable $X$ is exactly the true second moment $F_2$.
By tracking multiple independent variables and averaging their estimates, we can get an accurate estimate of $F_2$ with high probability.
$ E[X] = F_2 = sum m_i^2 $

#proof[
  By definition, the expected value is the sum over all possible positions $p$ of the probability times the variable's value:
  $
    E[X] & = sum_(p=1)^n mr(PP("picking position" p)) dot n(2v_p - 1) \
         & = sum_(p=1)^n cancel(mr(1/n)) dot cancel(n)(2v_p - 1) quad quad #comment("picking any position is uniform") \
         & = sum_(p=1)^n (2v_p - 1)
  $


  Instead of summing position by position (ranging $p=1$ to $n$), we can rearrange the sum by grouping the terms by *distinct elements*.

  #example[
    Given the stream:
    $ underbrace(a, p_1), underbrace(b, p_2), underbrace(a, p_3), underbrace(b, p_4) $

    The sum of the variables for these positions is:
    $ (2 v_1 -1) + (2 v_2 -1) + (2 v_3 -1) + (2 v_4 -1) $

    We can rearrange by the values of the elements:
    $ (2 v_a_1 - 1) + (2 v_a_2 - 1) + (2 v_b_1 - 1) + (2 v_b_2 - 1) $
  ]

  Reading the $v_i$, which counts the occurrences of the element from the chosen position to the end of the stream, it goes form $1$ to the actual frequency of that element $m_i$: 1, 2, ..., $m_i$.

  Each of this values of $v$ contributes to the sum with a multiplier of $(2v - 1)$, which generates the sequence of odd numbers: $1, 3, 5, 7, ..., (2m_i - 1)$.

  #theorem(title: "Lemma: Sum of Odd Numbers")[
    The sum of the first $k$ odd numbers is exactly equal to $k^2$.
    $ sum_(j=1)^k (2j - 1) = k^2 $
  ]

  Using the lemma, we can conclude that the contribution of each distinct element $i$ to the expected value is:
  $
    sum_(j=1)^(m_i) (2j - 1) & = m_i^2
  $

  Each element contributes to the expected value with its frequency squared, so when we sum over all distinct items, we get:
  $
    E[X] & = sum_(i in "items") sum_(j=1)^(m_i) (2j - 1) \
         & = sum_(i in "items") m_i^2 \
         & = F_2 space qed
  $
]

=== Higher-Order Moments

We can estimate $k$-th moments (for $k > 2$) using the exact same logic, with a different _estimator_ formula.

#note[
  The 2nd moment multiplier is just the difference between two _consecutive squares_:
  $ v^2 - (v - 1)^2 = 2v - 1 $
]

To calculate the 3rd moment, we replace the difference of squares with the difference of _cubes_:
$ v^3 - (v - 1)^3 = 3v^2 - 3v + 1 $

More generally, to estimate the $k$-th moment for any $k >= 2$, the estimator formula is:
$ "estimator" = n(v^k - (v - 1)^k) $

== Handling Infinite Streams

In the AMS algorithm above, we assumed we knew $n$ (the total stream length) in advance, so we could pick random positions uniformly with probability $1/n$.

#note[
  - If we pick positions too early, our sample is heavily biased toward the start of the stream.
  - If we wait too long to pick, we won't have enough variables populated to make a good estimate early on.
]

But in a real, infinite stream, $n$ grows continuously.
The solution is to use a *dynamic* sampling method.

=== Reservoir Sampling

The technique maintains a _reservoir_ of $s$ elements that are currently being tracked (the sample) and guarantees an *invariant*: at any exact moment in time, every element seen so far has the *same probability* of being in the reservoir.

#pseudocode(
  [*If* $n <= s$ *then* _\/\/ $n$ is the current element count, $s$ is the reservoir size_],
  indent(
    [Add the new element to the reservoir (probability $1$)],
  ),
  [*Else*],
  indent(
    [With probability $s/(n+1)$, keep the new element by replaing a random element in the reservoir],
  ),
)

1. *Initialization:* The first $s$ elements are added to the reservoir _unconditionally_, since we have enough space to store them all.
2. *The Invariant:* At any current time $n$ (where $n > s$), every position seen so far has a uniform probability of $s/n$ of being currently inside our reservoir.
3. *The Update Rule:* When the $(n+1)$-th element arrives:
  - We decide to *keep it* with probability $s/(n+1)$.
  - If we decide to keep it, we must make room: we discard one of the existing $s$ counters inside the reservoir, chosen *uniformly at random*.

The invariant holds at any time $> s$.

#proof[
  Proof by induction on the number of elements $n$ seen so far.

  / Base case:
    For $n = s$, the reservoir contains exactly the first $s$ elements.
    Each of them has the _same_ probability of $s/n = 1$ of being in the reservoir $qed$.

  / Inductive step:
    Each element will have the same probability of being in the reservoir of $s / (n+1)$.

    For an "old" element to be in the reservoir at step $n+1$:
    - It must have been in the reservoir at previous step $n$ (probability $mr(s/n)$)
    - It must survive the update process when the new element arrives
      - if the new element is ignored (probability $mb(1 - s/(n+1))$), the old element survives by default
      - if the new element is kept (probability $mp(s/(n+1))$), the old element survives if it is not the one randomly chosen for eviction (probability $mg((s-1)/s)$)

    $
      PP("survive") &= underbrace(mr(s/n), "was in at" n) dot ( underbrace(mb(1 - s/(n+1)), "new element"\ "ignored") + underbrace(mp(s/(n+1)) dot mg((s-1)/s), "new element kept,"\ "other swapped")) \
      &= s/n dot (1 - s/(n+1) + (s-1)/(n+1)) \
      &= s/n dot n/(n+1) \
      &= s/(n+1) space qed
    $

    The "new" element is added with probability $s/(n+1)$, so it also has the same probability of being in the reservoir as the old elements $qed$.
]
