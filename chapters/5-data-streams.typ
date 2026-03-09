#import "../template.typ": *

= Data Streams

Streams are a continuous flow of data.
If it is not processed immediately or stored, then it's lost forever. 

#note[
  We must assume that data arrives so rapidly that it's impossible to store it in a conventional database to analyze later.
]

Processing streams involve a *summarization* of the stream data in some way. 
Instead of trying to store every single piece of data, summarization consists of keeping continuously updated statistics or highly compact data structures in Main Memory (RAM).

Summarization can be also approached by looking at only a fixed length window consisting of the last $n$ elements for some large $n$, querying the window only when necessary.

== Examples of Stream Sources
Stream data arises naturally in various scenarios:
- *Sensor Data:* E.g., ocean surface temperature or GPS surface height sensors producing megabytes to terabytes of data daily.
- *Image Data:* Satellites or surveillance cameras (e.g., London's millions of cameras) sending continuous image streams.
- *Internet and Web Traffic:* Switching nodes routing IP packets, or search engines tracking billions of queries and clicks to detect trends (e.g., tracking virus spread via "sore throat" searches or identifying broken links).

== Data Stream Management system

#figure(
  cetz.canvas({
    import cetz.draw: *
    
    // Input streams (left side)
    let input-streams = (
      (name: "Stream 1", y: 2),
      (name: "Stream 2", y: 0),
      (name: "Stream 3", y: -2),
    )
    
    for stream in input-streams {
      line((-4, stream.y), (-2.5, stream.y), mark: (end: ">"), stroke: blue)
      content((-4.5, stream.y), stream.name, anchor: "east")
    }
    
    // Stream Processor (center)
    rect((-2, -3), (2, 3), stroke: 2pt + olive, name: "processor")
    content((0, 3.5), text(weight: "bold")[Stream Processor], anchor: "south")
    
    // Standing queries inside processor
    content((0, 1.5), [Standing Query 1], fill: white)
    content((0, 0.5), [Standing Query 2], fill: white)
    content((0, -0.5), [Standing Query 3], fill: white)
    content((0, -1.5), [$dots.v$])
    
    // Output streams (right side)
    line((2, 1.5), (4, 2), mark: (end: ">"), stroke: maroon)
    content((4.5, 2), [Query Results], anchor: "west")
    
    line((2, 0), (4, 0), mark: (end: ">"), stroke: maroon)
    content((4.5, 0), [Alerts], anchor: "west")
    
    rect((3.5, -2), (6.5, -1), stroke: orange, name: "storage")
    content((5, -1.5), [Archival Storage])
    line((2, -1.5), (3.5, -1.5), mark: (end: ">"), stroke: orange)
  }),
  caption: [Data Stream Management System]
)

Stream processors (we're talking about software) are a kind of data management system where any number of streams can enter the system.
Each stream provides elements at its own schedule and the arrival rate is not under the system's control.

#note[
  In a normal DBMS, the data "chills" on the disk.
  It uses a *pull mechanism*, meaning the DBMS retrieves data from the disk at its own pace. 
  In a stream processor, a *push mechanism* is used: data is fired into the processor continuously and in rapid bursts ("a raffica"), forcing the system to deal with it instantly.
]

#note[
  *Archival Storage (The "dusty warehouse"):* Streams are usually dumped into huge, cheap, and slow storage (like AWS S3 or Hadoop data lakes). We assume it's impossible to answer real-time queries from here. 
  
  *Time-consuming retrieval processes (Batch processing):* If we really need historical data from the archive (e.g., for a legal audit or to train a new Machine Learning model from scratch), we must run heavy Batch Jobs (like MapReduce). These sweep through terabytes of data and can take hours or days to finish.

  *Working Storage (The "active desk"):* Since we can't wait hours to answer a stream query, we use fast, limited memory (RAM or fast SSDs) as our "desk" to store only *active summaries* (e.g., running averages, Bloom filters, or a sliding window of the last 5 minutes). When a query arrives, the system instantly reads the desk and completely ignores the warehouse.
]

== Querying the Streams

There are two primary ways queries are asked on streams:

1. *Standing Queries:* These queries are submitted once but execute *permanently*. They continuously inspect the stream as it flows and produce outputs/alerts when specific conditions are met (e.g., "Alert me if the temperature is > 25°C").

2. *Ad-hoc Queries:* Questions asked once about the current state (like a standard SQL `SELECT`). 

#warning[
  Since we throw away the stream history, answering *arbitrary* ad-hoc queries is impossible.
  If you ask "what was the max value yesterday?", the system can't answer because it didn't save yesterday's raw data.
]

=== The Sliding Window Approach

To allow ad-hoc queries on the *recent past*, we can store a *sliding window* in the Working Storage. 
Instead of keeping everything, we buffer only the most recent $n$ elements, or all elements from the last $t$ minutes.
When new data enters, the oldest data falls out of the window. 
We can then treat this temporary window just like a standard relational table and run normal ad-hoc SQL queries on it.

#example[  
  *Standing Query Example - Computing the average:*
  The average of $n$ elements is:
  $ x_1, ..., x_n --> overline(x)_n = 1/n sum_(i=1)^n x_i $

  Adding one more element:
  $
    overline(x)_(n+1) = 1/(n+1) sum_(i=1)^(n+1) x_i = (n dot 1) / (n(n+1)) sum_(i=1)^n x_i + (x_(n+1))/(n+1) = n / (n+1) overline(x)_n + x_(n+1) / (n+1) = (n overline(x)_n + x_(n+1)) / (n+1)
  $
  We do not need to keep all the elements, only the previous average.

  *Ad-Hoc Query Example - Unique Monthly Users:*
  A website wants to report unique users over the past month. If logins are elements, we maintain a sliding window of all logins in the last month as a relation `Logins(name, time)`. The ad-hoc SQL query is:

  `SELECT COUNT(DISTINCT(name)) FROM Logins WHERE time >= t;`
]

=== Issue with Stream Processing

Data streams often deliver data very rapidly.
Streams can be processed efficiently only if the necessary data stays in main memory.
Thus many problems could be solved if we had enough main memory, but realistic hardware limitations force us to use new techniques.

There are two general rules for stream algorithms:

1. Often, it is much more efficient (and sometimes absolutely necessary) to get an *approximate answer* rather than an exact solution.
2. Techniques related to *hashing* are incredibly useful. They introduce randomness to produce approximate answers that are very close to the true result.

One major technique is *sampling*.

#note[
  In statistics, sampling is the selection of a _subset_ of individuals within a population to estimate characteristics of the whole population.
]

#example[
  Let's suppose we take a *10% sample* of our stream.
  Suppose we are looking for simple events ($s$) and paired/double events ($d$).
  
  If we sample at 10%:
  - Simple events $s$ will appear in our sample as $s/10$.
  - For double events $d$ (pairs), what is the probability of capturing both parts, or just one?
    - Probability of capturing both: $1/10 * 1/10 = 1/100$
    - Probability of capturing exactly one: $2 * (1/10) * (9/10) = 18/100$
  
  This drastically *distorts* the ratios of events in our sample compared to the true stream.
]

=== Fixing the Distortion: Sampling by Key

To fix the distortion (like splitting paired events), we must sample by a unifying property, like *User ID* or *Search Key*, rather than by individual, independent stream elements.

So our goal is either we process *all* events from a specific User, or *none* of them.

*Naive Approach:* We randomly select 10% of users and keep a list of their IDs in Main Memory. When a new event arrives, we check if its User ID is on our "accepted" list.

#warning[
Storing millions of user IDs would quickly exhaust our RAM.
]

The Solution is hashing.

Instead of storing IDs, we use a *Hash Function* $h(x)$ to map each User ID into one of $B$ buckets (e.g., $B = 100$). 
- A hash function is deterministic: the same User ID will *always* hash to the exact same bucket. Therefore, we don't need to remember the user; the hash calculates their "group" on the fly.
- If we want a *10% sample*, we accept the event only if the hash falls into buckets $0$ through $9$.
- *Dynamic Resizing:* If the stream volume spikes and we run out of memory, we can dynamically lower the threshold. By accepting only buckets $0$ through $4$, we instantly reduce our sample to 5% without needing to recalculate anything or modify data structures. We democratically "kill" 50% of the currently tracked users to free up RAM.

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
1.  *The element* found at the randomly chosen position.
2.  *The value ($v$):* A counter that tracks how many times that specific element appears from that position *onwards* until the end of the stream.

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

$ P("survive") = underbrace(s/n, "was in at " n) dot [ underbrace((1 - s/(n+1)), "Scenario A: new ignored") + underbrace(s/(n+1) dot (s-1)/s, "Scenario B: new kept, other swapped") ] $

*Simplifying the math (the term in brackets):*
Notice how the $s$ safely cancels out in Scenario B: $s/(n+1) dot (s-1)/s = (s-1)/(n+1)$.
Now we can easily add the fractions inside the bracket:
$ 1 - s/(n+1) + (s-1)/(n+1) = (n + 1 - s + s - 1)/(n+1) = n/(n+1) $

*The Final Conclusion:*
Multiply the prerequisite probability by our newly simplified survival probability:
$ s/n dot n/(n+1) = s/(n+1) $

The $n$ perfectly cancels out! The invariant holds. We can successfully estimate moments on infinite, unbounded streams dynamically, without ever running out of memory and without introducing sampling bias.