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

Given a universe of items and a massive trusted subset $S$, we want to answer a simple question for every new element $x$ in the stream: *Is $x in S$?*

#example[
  *The Memory Problem (Email Filtering):* \
  Let $S$ be a list of trusted email addresses ($|S| = 10^9$). Storing 1 billion strings would require dozens of Gigabytes. If we only have 1 GB of RAM, a standard search tree or hash table simply won't fit. We need to drastically compress the representation of $S$.
]

=== Bloom Filters: Storing "Footprints"

A Bloom filter solves the memory problem by using a bit-vector (bitmap) coupled with hash functions. Instead of storing the actual elements, it stores their "footprints".
Because multiple elements might accidentally leave the same footprint (hash collisions), we must accept a trade-off.

- *The Trade-off:* We accept *False Positives (FP)* (e.g., occasionally predicting an unknown email is trusted, delivering spam to the inbox). However, we guarantee strictly *NO False Negatives (FN)*. If an email is truly in $S$, the filter will never drop it.

*1. Construction (Pre-processing $S$):*
1. Initialize an array of $m$ bits to 0.
2. Choose $k$ independent hash functions.
3. For every key in our trusted list $S$, hash it with all $k$ functions. Set the bits at those resulting indices to 1.
  $ forall x in S, quad forall i in [1, k], quad b[h_i (x)] = 1 $

*2. Querying the Stream (Checking $x$):*
As the stream flows, we check if a new element $x$ is in $S$ by hashing it with the same $k$ functions.
- If *any* corresponding bit is 0, the footprint is incomplete. We know for certain $x in.not S$ (Zero False Negatives).
- If *all* corresponding bits are 1, we predict $x in S$. Note that these bits might have been set to 1 by a combination of other elements, which is exactly what causes a False Positive.

=== False Positive Rate (FPR) Math
To understand how likely a False Positive is, we calculate the probability that a specific bit is 1 just by chance after inserting $n$ elements:

- Probability a specific bit is *not* flipped to 1 by a single hash function: $(1 - 1/m)$
- Probability a bit is *not* flipped after inserting $n$ elements using $k$ hash functions: $(1 - 1/m)^(k n)$
- Using the limit for $m$ to infinity, we approximate this as: $e^(-k n/m)$
- Therefore, the probability that a bit *is* 1 is: $1 - e^(-k n/m)$

For a false positive to occur, all $k$ hash functions must hit bits that are already 1. The False Positive Rate (FPR) is:
$ "FPR" = (1 - e^(-k n/m))^k $

#note[
  To lower the FPR, you either need to increase $m$ (devote more RAM to the bit array to reduce crowding) or optimize the number of hash functions $k$. Time complexity for checking an element remains constant $O(k)$, which is perfect for fast streams.
]

= Counting Distinct Elements

How do we count the number of *unique* elements in a massive stream without storing them? We use the *Flajolet-Martin Algorithm*.

*The Intuition:* If we see the same element 100 times, we don't want to count it 100 times. By applying a *Hash Function*, the same element will always produce the exact same binary string. Thus, duplicates don't affect our measurements.

We look at the binary representation of the hash values and focus on the *tail length* ($R$): the number of trailing zeroes.
For example:

- `00110` has $R = 1$.
- `01000` has $R = 3$.

#example[
  *The Coin Toss Analogy:* Getting a hash that ends in `000` (probability $1/8$) is like flipping a coin and getting tails 3 times in a row. If you see such a rare event, you can probabilistically guess you've flipped the coin about $8$ times ($2^3$).
]

=== The Algorithm
```pseudocode
max_r = 0
for all x in stream:
  r = tail_length(hash(x))
  if r > max_r:
    max_r = r
return 2^(max_r)
```

=== Why the Math Works
The probability that a single hash ends in exactly $r$ trailing zeros is $2^(-r)$.
If we have $m$ *distinct* elements, the probability that *none* of them map to a hash with $r$ trailing zeros is:
$ (1 - 2^(-r))^m approx e^(-m 2^(-r)) $

Let's look at how $m$ (number of unique elements) relates to $2^r$ (the rarity of the hash):
- If $m >> 2^r$, we have made many attempts. We will *definitely* see an element with $r$ zeros.
- If $m << 2^r$, we have made very few attempts. We will *rarely* see an element with $r$ zeros.

*The Crossover Point:* The mathematical threshold where we go from "rarely seeing it" to "definitely seeing it" happens exactly when our number of attempts equals the rarity of the event: $m approx 2^r$.

Because of this, if the absolute longest tail we recorded during the stream is $R_"max"$, it strongly implies we processed approximately $2^(R_"max")$ distinct elements to achieve that record. Thus, $2^(R_"max")$ is our solid estimator for $m$.

#warning[
  The Outlier Problem: This basic method is extremely sensitive. One single "lucky" hash with 20 trailing zeroes will completely ruin the estimate, predicting over a million elements even if we only saw 10!

  *The Fix (Median of Averages)*:
  1. Use multiple independent hash functions.
  2. Group them into small buckets and compute the average estimate within each group (this smooths out small variations).
  3. Take the median of those group averages. The median strictly ignores extreme outliers, giving a robust final estimate.
]

= Stream Moments

Moments are statistical metrics used to capture the "shape" or frequency distribution of items in a stream.
Let $m_i$ be the number of occurrences (frequency) of the $i$-th distinct item.

The $k$-th moment is defined as the sum of all frequencies raised to the power of $k$:
$ sum_i (m_i)^k $

By changing the exponent $k$, we apply a different "magnifying glass" to our data:

- *0th Moment ($k=0$):* $sum_i (m_i)^0$
  Since any number to the power of $0$ is $1$, we are simply adding $1$ for every unique item we see, regardless of its frequency. This represents the *Number of distinct elements* (exactly what the Flajolet-Martin algorithm estimates!).

- *1st Moment ($k=1$):* $sum_i (m_i)^1$
  Since any number to the power of $1$ is itself, we are just summing all the frequencies together. This gives us the *Total length of the stream*.

- *2nd Moment ($k=2$):* $sum_i (m_i)^2$
  This is called the *Surprise Number*. By squaring the frequencies before summing them, we disproportionately amplify the weight of items that appear very often. It measures how uneven, skewed, or "surprising" the data distribution is.


#example[
  Let's see why squaring the frequencies captures the unevenness of the stream.
  Suppose a stream has 100 elements and 11 distinct item types.

  *Scenario A: Most uniform distribution* (Everything is balanced)
  10 items occur 9 times, and 1 item occurs 10 times.
  $ M_2 = 10 dot (9^2) + 1 dot (10^2) = 810 + 100 = 910 $

  *Scenario B: Least uniform distribution* (Highly skewed)
  1 item occurs 90 times, and 10 items occur 1 time.
  $ M_2 = 1 dot (90^2) + 10 dot (1^2) = 8100 + 10 = 8110 $

  The Surprise Number in Scenario B is huge because squaring $90$ creates a massive number ($8100$). This mathematically highlights that the stream is dominated by a single repeating element.
]

== The AMS Algorithm (Alon-Matias-Szegedy)

If we don't have enough Main Memory to maintain exact frequency counters for *all* distinct elements, we can't calculate the exact Second Moment.
*The Solution* is to use the AMS algorithm to *estimate* the Second (and higher) Moments by randomly sampling just a few specific positions in the stream.

*How it works:* We decide in advance to track a fixed number of variables (more variables = higher accuracy).
For each selected variable $X$, we track two things:
1. *The element* found at the randomly chosen position.
2. *The value ($v$):* A counter that tracks how many times that specific element appears from that position *onwards* until the end of the stream.

#warning[
  *Stream limitation:* I cannot access the stream like an array or vector! I only see the *current* element passing by.
  Therefore, when my chosen random position arrives, I must explicitly save that element in memory so I can compare it against all future incoming elements to increment its counter $v$.
]

#example[
  *Step 1: The True Moment (for comparison)* \
  Consider a stream of length $n=15$:
  $ a, b, c, b, d, a, c, d, a, b, d, c, a, a, b $

  The true frequencies are:
  - $m(a)=5$
  - $m(b)=4$
  - $m(c)=3$
  - $m(d)=3$

  The exact second moment is:
  $ F_2 = sum_i (m_i)^2 = 25 + 16 + 9 + 9 = 59 $

  *Step 2: The AMS Estimation* \
  Let's say we only have memory to track 3 variables. We pick 3 random positions uniformly:
  - Position 3 (element `c`)
  - Position 8 (element `d`)
  - Position 14 (element `a`)

  Now we count their occurrences *from that point forward* ($v$):
  - For pos 3 (`c`): It appears at pos 3, 7, 12. So, $v_1 = 3$.
  - For pos 8 (`d`): It appears at pos 8, 11. So, $v_2 = 2$.
  - For pos 14 (`a`): It appears at pos 14, 15 (Wait, the 15th is 'b'. 'a' only appears at 14). So, $v_3 = 1$.
]

=== The Estimator (Second Moment)

Now that we have our sample variables, how do we turn a simple counter $v$ into an estimate of the entire stream's Second Moment? We use the *Estimator formula*.

For each selected position, we define a random variable $X$:
$ X = n (2v - 1) $
Where:
- $n$ is the total stream length (which we assume is known and tracked with a basic counter).
- $v$ is the count of the element from the chosen position onwards.

#note[
  *Why this formula?* The mathematical proof (shown below) guarantees that the *expected value* (the statistical average) of this random variable $X$ is exactly the true Second Moment ($F_2$).
]

*Applying the formula to our example ($n=15$):*
Let's calculate the estimate $X$ for each of the 3 positions we picked.

- *Variable 1 (pos 3, `c`):* From pos 3 onwards, `c` appears 3 times ($v=3$).
  $ X_1 = 15(2 dot 3 - 1) = 15(5) = 75 $

- *Variable 2 (pos 8, `d`):* From pos 8 onwards, `d` appears 2 times ($v=2$).
  $ X_2 = 15(2 dot 2 - 1) = 15(3) = 45 $

- *Variable 3 (pos 13, penultimate `a`):* From pos 13 onwards, `a` appears 2 times (at pos 13 and 14). So, $v=2$.
  $ X_3 = 15(2 dot 2 - 1) = 15(3) = 45 $

=== The Final Estimate
A single variable $X$ is just a rough guess. To get a highly accurate and stable result, we calculate the average of all our independent estimates:

$ "Average Estimate" = (X_1 + X_2 + X_3) / 3 = (75 + 45 + 45) / 3 = 55 $

As we can see, our estimate of $55$ is a very solid approximation of the true $F_2$ ($59$). We achieved this by tracking only 3 elements instead of maintaining counts for the entire stream!

=== Proof of Expectation

Our goal is to prove that our estimator is unbiased, meaning its expected value $E[X]$ is exactly equal to the true Second Moment $F_2 = sum m_i^2$.

==== *Step 1: The Expected Value over all positions*
The probability of uniformly selecting any specific position $p$ in a stream of length $n$ is $1/n$.
By definition, the expected value is the sum over all possible positions $p$ of the probability times the variable's value:
$ E[X] = sum_(p=1)^n P("picking position " p) dot (n(2v_p - 1)) $
$ E[X] = sum_(p=1)^n 1/n dot n(2v_p - 1) = sum_(p=1)^n (2v_p - 1) $

==== *Step 2: The Grouping Trick*

Instead of summing position by position (chronologically), we can rearrange this massive sum by grouping the terms by *distinct elements*.

Let's look at element `a`, which appears $m_a=5$ times in total. If we read the stream from right to left (end to start), the values of $v$ for `a` will naturally be:
- The last `a` seen: $v=1$
- The second to last `a`: $v=2$
- ...
- The very first `a` seen: $v=5$

So, for any distinct item $i$ that appears $m_i$ times, its total contribution to the sum is:
$ sum_(j=1)^(m_i) (2j - 1) $
Notice that $(2j - 1)$ generates the sequence of odd numbers: $1, 3, 5, 7, ...$

#theorem(title: "Sum of Odd Numbers")[
  A known mathematical property states that the sum of the first $k$ odd numbers is exactly equal to $k^2$.
  $ sum_(j=1)^k (2j - 1) = k^2 $
]

*Step 3: The Conclusion*
If we substitute this property back into our expectation, the contribution of element $i$ becomes exactly $m_i^2$.
Summing this over all distinct items gives us the exact definition of the Second Moment:
$ E[X] = sum_(i in "items") (sum_(j=1)^(m_i) (2j - 1)) = sum_(i in "items") m_i^2 = F_2 $

=== Higher-Order Moments

We estimate $k$-th moments (for $k > 2$) using the exact same logic. The only thing that changes is the mathematical formula used for the random variable estimator.

*The Pattern:* Notice that our 2nd moment multiplier $(2v - 1)$ is actually just the difference between squares: $v^2 - (v - 1)^2$.
Because of how the summation works across the stream, the sum of these differences perfectly reconstructs the total squared frequency $m^2$.

To calculate the 3rd moment, we simply replace the difference of squares with the difference of cubes:
$ v^3 - (v - 1)^3 = 3v^2 - 3v + 1 $

More generally, to estimate the $k$-th moment for any $k >= 2$, we define our estimator variable $X$ by substituting the tracked count $v$ into:
$ X = n(v^k - (v - 1)^k) $

== Handling Infinite Streams (Reservoir Sampling)

In the AMS proof above, we assumed we knew $n$ (the total stream length) in advance, so we could pick random positions uniformly with probability $1/n$.
But in a real, infinite stream, $n$ grows continuously.

- If we pick positions too early, our sample is heavily biased toward the start of the stream.
- If we wait too long to pick, we won't have enough variables populated to make a good estimate early on.

*The Solution: Reservoir Sampling*

We maintain a fixed "reservoir" of $s$ counters (dictated by our available RAM). Reservoir Sampling guarantees a powerful mathematical *Invariant*: at any exact moment in time, every element seen so far has the exact same probability of being in the reservoir.

*The Algorithm Steps:*

1. *Initialization:* Store the first $s$ elements of the stream unconditionally (probability is $1$).
2. *The Invariant:* At any current time $n$ (where $n > s$), every position seen so far has a uniform probability of $s/n$ of being currently inside our reservoir.
3. *The Update Rule:* When the $(n+1)$-th element arrives:
  - We decide to *keep it* with probability $s/(n+1)$.
  - If we decide to keep it, we must make room. We discard one of the existing $s$ counters inside the reservoir, chosen *uniformly at random*.

=== Proof of Uniform Probability (By Induction)

We must prove that if our invariant holds at step $n$ (the probability is $s/n$), it strictly holds after processing the new element at step $n+1$ (the probability must mathematically become $s/(n+1)$).

To find the probability that a specific "old" element survives step $n+1$, we use the *Law of Total Probability*.
For an element to survive, two things must happen in sequence:
1. *Prerequisite:* It was already in the memory at step $n$ (Probability: $s/n$).
2. *Survival:* AND it was NOT evicted during step $n+1$.


How can it avoid eviction? There are two mutually exclusive "lucky" scenarios:

- *Scenario A (The new element is ignored):* We simply don't pick the new $(n+1)$-th element to enter the reservoir. (Probability: $1 - s/(n+1)$).

- *Scenario B (The new element is kept, but someone else is kicked):* We DO pick the new element (Prob: $s/(n+1)$), AND the random index chosen for replacement is *not* our element's index (Prob: $(s-1)/s$).

Putting it all together into one equation:

$
  P("survive") = underbrace(s/n, "was in at " n) dot [ underbrace((1 - s/(n+1)), "Scenario A: new ignored") + underbrace(s/(n+1) dot (s-1)/s, "Scenario B: new kept, other swapped") ]
$

*Simplifying the math (the term in brackets):*
Notice how the $s$ safely cancels out in Scenario B: $s/(n+1) dot (s-1)/s = (s-1)/(n+1)$.
Now we can easily add the fractions inside the bracket:
$ 1 - s/(n+1) + (s-1)/(n+1) = (n + 1 - s + s - 1)/(n+1) = n/(n+1) $

*The Final Conclusion:*
Multiply the prerequisite probability by our newly simplified survival probability:
$ s/n dot n/(n+1) = s/(n+1) $

The $n$ perfectly cancels out! The invariant holds. We can successfully estimate moments on infinite, unbounded streams dynamically, without ever running out of memory and without introducing sampling bias.
