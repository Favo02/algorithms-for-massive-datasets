#import "../template.typ": *

= HDFS and MapReduce

This course is pretty much about *big data*.
But what is big data?
It depends on the context.

#example[
  - A _normal person_ can't handle more than some thousands records (e.g. in an excel sheet)
  - Classic _computation_ can't manage a dataset that doesn't fit in _main memory_ (GB)
  - Or even bigger: a dataset that does not even fit in the _disk_ (TB)
]

In general, we talk about *big data* when something that worked with a "normal" dataset, that doesn't work anymore.

#note[
  We will work with datasets typically divided into "can/can't fit in *main memory* (RAM)" and "can/can't fit in *disk*".
  MapReduce is designed for data that is extremely regular and where there is ample opportunity to exploit parallelism.
]

We could think of buying more _powerful_ hardware to manage this data.
That does *not* work: increasing the power/memory of a computer *doesn't* scale *linearly*:
$ "price for 1x" 1000"TB computer" != "price for 1000x" 1"TB computer" $

Another huge implication is that if the single computer *fails*, everything crumbles.

== Distributed Computing

The solution is to leverage the power of *distributed computing*, that way increasing the power/memory scales *linearly*.
We have two main things to do:
- storage of the dataset
- processing of data

== Storage: Hadoop Distributed File System (HDFS)

To store the data, we can use a distributed file system, where files are distributed on different computers, scattered around a network.
One implementation of that idea is *HDFS* (Hadoop Distributed File System), an open source version of _GFS_ (Google File System).

#example[
  We have some _racks_, each rack composed of 20 full computers (_blades_).
  These racks are physically in different locations (even different cities or countries).

  The computers in a single rack are connected with a _fast connection_ (Gbit network), while the racks are connected using standard _internet facility_ (slower).
]

In a traditional file system, each file is *not* stored in a _contiguous_ part of memory, it is divided into *blocks* (of around 1KB) and then stored around the memory.
There is an external data structure that stores how these files are splitted and where each block is.

We can use the same idea for a distributed file system, dividing each file in *chunks* (of around 64MB) and distribute them over *multiple computers*.
We also need a (central) structure to manage for each file where each chunk is.

What about *damages*? Two main categories exist:
- _hardware_ failures (the computer physically breaks down)
- _network_ failures (the computer is fine, but inaccessible to the other ones)

We can prevent/fix these issues using *redudancy*, each file chunk is duplicated multiple times, each one called *replica*.
Typically we have $3$ replicas, two in the same rack and one in a far away rack.

#note[
  An important property is that, after a problem, the system will restore the *operational amount* of replicas.
  Meaning that we are at all times pretty sure that completely losing a file is really _unlikely_ (multiple computers should break down at the same time).
]

How does the system _detect_ issues and failures?
The central controller sends *heartbeats* to all computers, which expect a response.
If $n$ consecutive heartbeats are lost, then damage is assumed.

These file systems are *immutable*: the files are stored and then read as they are, they cannot be updated like we update a normal file.
_Doing something_ with these files is processing them, that is reading them and generating a result (another file), *without* modifying them.

#informally[
  Recap:
  - files are divided in chunks of \~$64"MB"$
  - chunks are scattered around multiple computers
  - chunks are replicated to prevent failures
  - the system will restore the operational amount of replicas after a failure
  - files are immutable
]

== Processing: MapReduce

Processing distributed files means reading them, compute _something_ and generate a result.
The files are not modified and the result is *another file*, stored independently in the distributed file system.

Two approaches arise:
- bring the _data_ to the _computation_: the data is moved to a dedicated node, where all the processing happens
- bring the _computation_ to the _data_: the computation is done by the CPU of the computer that stores the data (the data is not transferred through the network)

Of course, moving a huge amount of data brings a big overhead, so the second approach is chosen: the computation is done by the *distributed CPUs* over the whole network.

This is implemented using the *MapReduce* paradigm, which is typically made of multiple steps:
- *organize*: the data is organized into key-value pairs
- *map*: a mapping function is applied to the local data
- *combine*: the mapped data is combined to optimize the shuffling phase
- *shuffle*: the results of the mapping phase are redistributed over the network
- *reduce*: the groups of mapped data are processed to final result

#example[
  From now on, we use a simple example for the paradigm: given a (huge) _text_, we want to compute the _frequency_ of each word in the text.
]

=== Organize

All the data managed by MapReduce, should be organized as a key-value *pairs*.

#warning[
  These key-value pairs behave as a collection of *tuples*, *not* as a *dictionary*.
  Multiple pairs with the _same key_ are allowed.
]

The first step of the processing is to organize the data into key-value pairs, so that even the initial data is in that format.

#note[
  _Right now_, we will _ignore_ this requirement but it will become important later on with the course.

  _Spoiler: we will be able to concatenate multiple MapReduce jobs, so the initial data is the output of another step: key-values pairs._
]

We have to make sure that no pair starts in a chunk and ends in *another* chunk!

=== Map

A *map* function is applied to _each_ key-value pair independently.
The function receives _one_ key-value pair and returns _zero, one or more_ key-value pairs:
$ (k, v) --> #rect("MAP") --> (k, v)^* $

Because of the _independent_ nature of each pair, this computation can happen anywhere.
In HDFS, the map step is performed by the computer where the chunk is stored.

#example[
  The map function will split the string into words and for each word $w$, it outputs a pair $(w, 1)$.
]

The result of the map phase (the produced key-values) is temporarily stored in the *local machine* (the one which does the computation).

=== Combine

The map phase can also include a combiner: an optimization step that merges multiple key-value pairs, to reduce the number of pairs handled by the shuffling phase (the next one).

#warning[
  This still happens in the *local* machine, so only the pairs of a single *chunk* are considered.
]

#example[
  Multiple pairs with the same key are merged into one single pair with summed value: $(w,1), (w,1), (z,1) -> (w,2), (z,1)$.
]

=== Shuffle

After the map function is applied, each generated key-value pair is *sent* to _nodes around the network_ to perform the next step of the processing: reduction.

Pairs with the *same key* are sent to the *same reduce node*.

This is achieved by using a common *hash function* (the same for all computers):
$ h : underbrace(K, "universe of keys") -> underbrace(m subset bb(N), "number of nodes") $

This function _evenly_ distributes the keys across all nodes of the network and acts as *load balancers*.
That process is called *shuffling*.

=== Reduce

The shuffled key-value pairs are then processed by a *reduce* function.
The reduce function receives a pair formed by a _single key and multiple values_ and returns _zero, one or more_ key-value pairs:
$ (k, underbrace([v_1, v_2, ..., v_n], S)) --> #rect[REDUCE] --> (k, v)^* $

#note[
  All the key-value pairs with the *same key* are processed by the *same reduce node*, so we can view all the values as an array $S$ associated with its key $k$ using the notation $(k, [v_1, v_2, ..., v_n])$.
]

#warning[
  A single node can (very likely will) handle *multiple* keys.
]

#example[
  The reduce function receives the key along with all its values $S$.
  The sum of the values $S$ is the frequency of the word, so it outputs $(k, sum S)$.
]

The result is stored in a new file in the distributed file system.

#warning[
  We cannot make assumptions on the order of the values, as mapping and shuffling phases of each pair can happen in different computers.

  Because of that, the operation applied by the reduce function should be *commutative* and *associative*.
]

=== Errors during Computation

What happens if a *failure* (hardware or network) occurs during the computation?
All the system has to do is to recompute only the computation done by the _single node_ that _failed_, NOT the whole computation.

#note[
  If a _map_ job fails, then it can simply be re-run on another node (with the same chunk).

  If a _reduce_ job fails, the system should ask all the node that performed a map job to re-shuffle the pairs.
  Because of that, the map nodes should store the _temporary_ results of the map phase until the _whole_ computation is over.
]

=== Example: Matrix Vector Multiplication

Given:
- a matrix $A = [a_(i j)]_(m times m)$ too big to be stored
- a vector $underline(v) = [v_j]_m$ storable in RAM (of each single computer involved)
- the resulting vector $A underline(v) = p, quad p_i = sum_j a_(i j) v_j$

We need to _store_ and _process_ the data in a _distributed file system_ using _MapReduce_:
- Organize:\
  Each entry $(i, j, a_(i j))$ (row index, column index, entry value) should be converted to a pair.
  We can simply use $i$ as the key and $(j, a_(i j))$ as the value, forming the pair $(i, (j, a_(i j)))$.
- Map:\
  For each entry we need to multiply its value by the corresponding element of the vector:
  $(i, j, a_(i j)) --> #rect[MAP] --> (i, a_(i j) v_j)$.
  #note[
    How can we apply that transformation if we don't have $v$ in the pair to map?
    We said that $v$ can be stored in RAM, so we can just fetch its value from there.
  ]
- Shuffle:\
  Each key-value is shuffled based on the key, in this case $i$, and each reduce node receives: $ (i, underbrace([a_(i 1) v_1, a_(i 2) v_2, ..., a_(i n) v_n], S)) $
- Reduce:\
  Just sum the values associated with each row $i$.
  These values are the elements of the final vector:
  $ (i, underbrace([a_(i 1) v_1, a_(i 2) v_2, ..., a_(i n) v_n], S)) --> #rect[REDUCE] --> (i, sum S) $

#example[
  With $m = 10^9$, the matrix would be too big to be storable, while the vector is around $8"GB"$, so storable even in RAM.
]

=== Example: Matrix Vector Multiplication V2 (Stripes)

Same example as before, but now even the vector $underline(v)$ is NOT storable in memory.
The assumption is that only *half* of $underline(v)$ is storable in RAM.

To leverage a mathematical property we split both the vector into upper $v_u$ and lower $v_l$ and the matrix into left $A_L$ and right $A_R$.
We divide the matrix into vertical *stripes* of equal width and the vector into an equal number of horizontal stripes.

The halves are compatible, as the number of columns of the half matrix is the same as the number of rows of the half vector _(the vector is the mathematical object, so represented vertically)_.
The final product is the *sum* of the multiplication of the two halves *independently*:
$ [A_L | A_R] dot [underline(v)_u / underline(v)_l] = A_L underline(v)_u + A_R underline(v)_l $

Then we can use the same approach as before.

#note[
  This approach can be generalized: the matrix and the vector can be split into $n$ components until a single component of the vector can fit in main memory.
]

=== Example: Relational Algebra

Concepts of relational algebra:
- SQL table (relation): $R(A, B) subset A times B$
- Columns of a SQL table (attributes): $A, B$
- Row of a SQL table (tuples): $(a, b) in R$

Operations of relational algebra:
/ Selection: filtering the rows of the relation $R$ based on some criterion $c$
  $ sigma_(c)(R) -> R $
/ Projection: filtering the columns $A, B$ of the relation $R$
  $ pi_(A, B)(R) -> R $
/ Union: combining two relations $R$ and $S$ with the same schema, resulting in all tuples from both
  $ t in R union S quad "iff" t in R or t in S $
/ Difference: tuples in relation $R$ that are not in relation $S$ (same schema)
  $ t in R \\ S quad "iff" t in R and t in.not S $
/ Intersection: tuples that appear in both relations $R$ and $S$ (same schema)
  $ t in R inter S quad "iff" t in R and t in S $
/ Join: combining two relations $R(A, B)$ and $S(B, C)$ on common attributes
  $ R join S -> (a, b, c) quad "where" (a, b) in R and (b, c) in S $
/ Grouping/Aggregation: partitioning relation $R(A, B)$ by attribute $A$ and aggregating values of $B$
  $ gamma_(A, theta(B))(R) -> (a, theta(b_1, ..., b_m)) $

If the relation is too big, then we can't use a traditional DBMS, but we can use _MapReduce_.

#note[
  All results from Map and Reduce are pairs $(t,t)$ even if no additional information is needed because we are forced to adhere to the key-value format.
]

/ Selection $sigma_c (R)$: the map job filters the data, while the reduce step simply returns the data as it is
  $
    t in R -> #rect[MAP] -> cases(
      (t,t) quad & "if" c(t) = "True",
      emptyset quad & "otherwise"
    )
  $
  $ (t, [t, ..., t]) -> #rect[REDUCE] -> (t, t) $

  #note[
    Multiple values with the same key $t$ are generated only when multiple rows with the same exact content exist (no primary key exists in the table).
  ]

/ Projection $pi_(A,B) (R)$: the map job filters the columns, while the reduce step returns the data as it is.
  $
    t in R -> #rect[MAP] -> (t', t')
  $
  $ (t', [t', ..., t']) -> #rect[REDUCE] -> (t', t') $
  #note[
    The map function extracts only the requested attributes $A, B$ from tuple $t$, producing $t'$.
    *Crucial Step:* The Reduce function performs *duplicate elimination*. Since Projection can result in identical tuples, the Reducer receives $[t', t', ...]$ and must output a single $t'$ for *Set* semantics.
  ]

/ Union $R union S$: multiple map functions exist, one for the relation $R$ and one for relation $S$. Both map functions output tuples that get shuffled to reduce functions that output them.
  $ t in R -> #rect[MAP] -> (t, t) $
  $ t in S -> #rect[MAP] -> (t, t) $
  $ (t, [t, ..., t]) -> #rect[REDUCE] -> (t, t) $
  #note[
    Similar to projection, the Reducer handles duplicate elimination for *Set Union*. For *Bag Union*, the reducer would output all instances.
  ]

/ Difference $R \\ S$:
  we need to differentiate the tuples that come from R and the tuples that come from S.
  To do that we add an identifier ($\'R\'$ or $\'S\'$) that identifies the relation (not the whole relation itself!).
  #informally[
    Until now, we used the same map function for all the pairs.
    For difference, we need to apply different map functions: one for the pairs of R and one for the pairs of S.
  ]
  $ forall t in R --> #rect[$"MAP"_R$] --> (t, \'R\') $
  $ forall t in S --> #rect[$"MAP"_S$] --> (t, \'S\') $

  Then the reduce step outputs only pairs that are in $R$ but not in $S$:
  $ (t, [\'R\']) --> #rect[REDUCE] --> (t, t) $
  $ (t, [\'R\', \'S\']) --> #rect[REDUCE] --> emptyset $
  $ (t, [\'S\']) --> #rect[REDUCE] --> emptyset $

/ Grouping/Aggregation $gamma_(A, theta(B))(R)$: the attributes are grouped on attribute $A$ and aggregated on $B$.
  The attributes with the same key $a$ are shuffled to the same node, so the aggregation can be performed.
  $ forall (a, b) in R --> #rect[MAP] --> (a, b) $
  $ (a, [b_1, ..., b_m]) --> #rect[REDUCE] --> (a, theta(b_1, ..., b_m)) $
  #note[
    The reducer receives the list of values $b_1...b_m$ and applies the aggregation operator $theta$ (e.g., SUM, MAX, COUNT).
  ]

/ Join $R(A, B) join S(B, C)$: two relations should share an attribute to generate tuples $(a, b, c)$.

  First let's start with an approach that *does NOT work*:
  the idea is to use the common attribute as the key, so that will be sent to the same node:
  $ forall (a, b) in R --> #rect[$"MAP"_R$] --> (b, a) $
  $ forall (b, c) in S --> #rect[$"MAP"_S$] --> (b, c) $

  Then we should be able to construct the resulting tuples:
  $ (b, [a_1, ..., a_m, c_1, ..., c_n]) --> #rect[REDUCE] --> (a, b, c) forall a forall c $

  #warning[
    But that does not work because the values received by the reduce step are not ordered:
    $ ("key", [5, 7, 9, 1, 3, 2]) $

    We cannot differentiate which values come from $A$ and which from $C$, so that approach does NOT work.
  ]

  So we also need to specify which relation the values come from:
  $ forall (a, b) in R --> #rect[$"MAP"_R$] --> (b, (a, \'R\')) $
  $ forall (b, c) in S --> #rect[$"MAP"_S$] --> (b, (c, \'S\')) $

  The reduce step can then sort on the second element of each pair, so that all \'R\' values come before all \'S\' values, and then generate the result.

  $ (b, [(a_1, \'R\'), (c_8, \'S\'), (a_3, \'R\'), ...]) --> #rect[REDUCE] --> (a, b, c) forall a forall c $

=== Example: Matrix Matrix Multiplication (2-Step)

The same approach can be used to perform a matrix-matrix multiplication.

Given two matrices with one common dimension $A_(m times n), B_(n times o)$, the resulting matrix $P$ will be:
$ P = A dot B, quad P_(i j) = sum_(k=1)^n a_(i k) b_(k j) $

We can transform this problem into a _natural join_ followed by _grouping and aggregation_.
Treat the two matrices as _tables_ with three attributes $("row", "column", "value")$ with the common dimension as the _common attribute_ on which to join:
$ A(I, K, V) in.rev (i, k, a_(i k)) $
$ B(K, J, W) in.rev (k, j, b_(k j)) $

The join operation will return all the tuples with a common $k$:
$ A join B in.rev (k, i, j, a_(i k), b_(k j)) $

#informally[
  The idea is to match rows with columns of the two matrices ($k$ corresponds to rows in one table and columns in the other).
]

To perform that we need to shuffle on key $k$ and keep track of which table each entry comes from:
$ forall (i, k, a_(i k)) in A --> #rect[$"MAP"_A$] --> (k, (i, a_(i k), \'A\')) $
$ forall (k, j, b_(k j)) in B --> #rect[$"MAP"_B$] --> (k, (j, b_(k j), \'B\')) $

Then we can multiply $a_(i k)$ entries with $b_(k j)$ entries to obtain:
$
  (k, [(1, a_(1 k), \'A\'), ..., (m, a_(m k), \'A\'), (1, b_(k 1), \'B\'), ..., (o, b_(k o), \'B\')]) --> #rect[REDUCE] --> ((i, j), a_(i k) b_(k j)) forall i forall j
$

#warning[
  Again, the reduce will not receive these elements in sorted order; that's why we need the labels $\'A\', \'B\'$: to be able to sort them.
]

_Multiple_ tuples with the same $(i, j)$ will be generated: the multiplication is not complete yet.
These elements need to be _summed up_ to obtain $P_(i j)$.
We need another reduce phase, with a *different* key, so we need another *shuffling*.
We can *concatenate* multiple MapReduce jobs.

#note[
  That is the reason why even the initial data should be in key-value format.
  With this constraint multiple MapReduce jobs can be concatenated.
]

In this case, we don't need to perform any transformation, only to _shuffle_ data on $(i, j)$ key:
$ ((i, j), a_(i k) b_(k j)) --> #rect[MAP2] --> ((i, j), a_(i k) b_(k j)) $

Then we can simply sum up the data with the same row and column to obtain each resulting matrix cell:
$
  ((i, j), underbrace([(a_(i 1) b_(1 j)), ..., (a_(i k) b_(k j))], S)) --> #rect[REDUCE2] --> ((i, j), underbrace(sum S, = P_(i j)))
$

This approach uses *two* concatenated MapReduce jobs (Join + Grouping).

=== Example: Matrix Matrix Multiplication (1-Step)

We can do better in terms of number of MapReduce jobs: using only one.

#informally[
  The resulting entries will depend on the row and column $(i, j)$, so our map will definitely need to _shuffle_ on that key.

  But for each matrix we don't know one dimension, so we simply generate _all possible_ values of this unknown.
]

We immediately try to generate pairs with $(i, j)$ as key.
For matrix $A$ we don't know $j$, so we range all possible values in range $[1, o]$:
$ (i, k, a_(i k)) in A --> #rect[$"MAP"_A$] --> ((i, j), (k, a_(i k), \'A\')) space forall j in [1, o] $

Same thing for matrix $B$ in which we don't know $i$:
$ (k, j, b_(k j)) in B --> #rect[$"MAP"_B$] --> ((i, j), (k, b_(k j), \'B\')) space forall i in [1, m] $

Then the reduce function needs to match tuples from $\'A\'$ and from $\'B\'$ based on a common $k$.
To achieve that the array can be _sorted_ with a _multiple key_ comparison, first on the label $\'A\'$ and $\'B\'$ and then on the values $k$.
$
  ((i, j), [(1, a_(i 1), \'A\'), ..., (n, a_(i n), \'A\'), (1, b_(1 j), \'B\'), ..., (n, b_(n j), \'B\')]) --> #rect[REDUCE] --> ((i, j), sum_(k=1)^n a_(i k) b_(k j))
$

This new approach uses only *one* MapReduce job, but the number of pairs sent across the network is _much bigger_ than before.

#note[
  We will analyze the complexity of these examples in the next section (#link-section(<communication-cost-model>)).
]

== Complexity: Communication Cost Model <communication-cost-model>

#informally[
  It is very likely that the _network overhead_ (the exchange of pairs during shuffling phase) *dominates* the _computation_.
  The thing to minimize is the number of tuples sent across the network.
]

In distributed computing, both _time_ and _space_ complexity are far less important than the time taken to communicate across the network.
The complexity that we study to evaluate performances is the _network latency_: the *Communication Cost Model*.

We can describe the computation using a *Computation Graph*, where each node represents a computation that can start only when its _predecessors_ are finished (when the input for the node is ready).
The complexity of that system is the number of _things_ that _travel_ through that graph (typically the number of tuples).

To compute this count, we can simply sum the _sizes of all inputs_ to nodes.
The only thing we do _not_ get counted with this approach is the _final output_.
But the cost of the final output is _negligible_ (as we cannot reduce it, it is the output, and usually aggregated/summarized).

#note[
  This is *not* true in Hadoop DFS, as the input for the first computation is handled _locally_ on the same machine where the chunk is stored (Data Locality), so it does _not_ travel through the network.
  But that's true in other modern frameworks, such as Spark.
]

=== Example: Relational Algebra

/ Join: $R(A, B) join S(B, C), quad |R| = r, |S| = s$

  - _Map input_: the original data contains a tuple for each entry of the tables: $r + s$ tuples.
  - _Reduce input_: the map function generates as output exactly one tuple for each entry: $r + s$ tuples.

  Total overall cost: $O(r + s)$.

/ Double join (cascade): $R(A, B) join S(B, C) join T(C, D), quad |R| = r, |S| = s, |T| = t$

  We first join R and S then we join T.
  - The complexity of the _first join_ is, of course, $O(r + s)$.
  - To calculate complexity of the _second join_ we need to know the cardinality of the result of the first join (which we don't know).
    We can define as $p$ the _probability_ that two rows match (so that a row in the join result is generated):
    $ p = P[(a, b) and (b, c) "such that" b = b] $
    The cardinality of the first join is: $p dot r dot s$ ($r s$ is the cartesian product, each row multiplied by the probability of its existence).
  - The complexity of the _second join_ is the sum of the cardinality of the two tables
    $O(p r s + t)$
  - Total overall cost:
    $ O(underbrace(r + s, R join S) + underbrace(t + p r s, (R join S) join T)) $

  The join is associative so we could perform the same join in another order: $R join (S join T)$
  - _First join_ complexity: $O(s + t)$
  - We still need to define a _probability_ (different than the previous $p$):
    $ p' = P[(b, c) and (c, d) "such that" c = c] $
  - _Second join_ complexity: $O(p' s t + r)$
  - Total overall cost:
    $ O(underbrace(s + t, S join T) + underbrace(r + p' s t, R join (S join T))) $

/ Double join (multi-way): $R(A, B) join S(B, C) join T(C, D), quad |R| = r, |S| = s, |T| = t$

  Instead of performing the joins in a cascade, we leverage hash functions to calculate the result in a single pass.
  We need two _hash_ functions:
  $ h_B : B -> {0, ..., n_B} $
  $ h_C : C -> {0, ..., n_C} $

  The number of buckets of these hash functions $n_B$ and $n_C$ are _optimization_ parameters that must adhere to: $ n_B dot n_C = k = "number of nodes (computers)" $

  The nodes can be seen as a *grid*, with each computer identified by the pair $(b in {0, ..., n_B}, c in {0, ..., n_C})$.

  This approach uses the map phase as a dispatcher to send the pairs to the *correct nodes* where the reduce should happen.
  This node is identified _applying the hash functions_ where possible and to _all possible values_ otherwise:
  $
    forall (b, c) in S & "send to" (h_(B)(b), h_(C)(c)) &                     \
    forall (a, b) in R & "send to" (h_(B)(b), c)        & forall c in 0...n_C \
    forall (c, d) in T & "send to" (b, h_(C)(c))        & forall b in 0...n_B
  $

  #note[
    This ensures that all nodes receive _at least_ all the tuples that it needs.
    So we are guaranteed that the final computation is _correct_.
  ]

  Complexity of the approach:
  - _Map phase_ input: all rows for all tables $s + r + t$
  - _Reduce phase input_ (output of map):
    - for $S$ relation: $s$ (sent to exactly one reducer)
    - for $R$ relation: $r dot n_C$ (replicated to all candidate C buckets)
    - for $T$ relation: $t dot n_B$ (replicated to all candidate B buckets)

  The total complexity becomes:
  $ O(r + 2s + t + r n_C + t n_B) $

  We need to fix the number of buckets $n_C$ and $n_B$ so that the complexity is *minimized*.
  The equation to minimize is:
  $
      & min_(n_C, n_B) (r + 2s + t + r n_C + t n_B) &     quad "with" n_C dot n_B = k \
    = & min_(n_C, n_B) (r n_C + t n_B)              & quad "with" n_C dot n_B - k = 0
  $

  To solve this minimization problem we can use *Lagrange relaxation*.

  #informally[
    _Lagrange relaxation_: an optimization problem with a constraint can be converted into an *unconstrained* problem using a Lagrange function $L$ with Lagrange multipliers ($lambda$).

    The idea is that the multiplier penalizes constraint violations.
  ]

  Define the Lagrangian:
  $ L = r n_C + t n_B - lambda (n_B dot n_C - k) $

  To find the minimum of that function we can compute the derivative and set it to $0$.

  But that's a *multi-variable* function, so we can't calculate "normal" derivative, we need partial derivatives for each variable, forming a *gradient* $nabla$ and setting it to zero.

  #informally[
    _Partial derivative_ $(d f) / (d v)$: compute the derivative of function $f$ treating all variables as constants except $v$.

    _Gradient_ $nabla$: the vector of all partial derivatives.
  ]

  Calculate the gradient:
  $ (d L) / (d n_B) = t - lambda n_C $
  $ (d L) / (d n_C) = r - lambda n_B $

  $ nabla = [t - lambda n_C, r - lambda n_B] $

  Find the zeros:
  $ t = lambda n_C $
  $ r = lambda n_B $

  Solve for $lambda$:
  $
       r t & = lambda^2 n_C n_B \
           & = lambda^2 k \
    lambda & = sqrt((r t) / k)
  $

  Solve for $n_C$ and $n_B$:
  $ n_C = t / lambda = t sqrt(k/(r t)) = sqrt((t k) / r) $
  $ n_B = r / lambda = r sqrt(k/(r t)) = sqrt((r k) / t) $

  To double check things, if we multiply $n_C dot n_B$ we should obtain $k$:
  $ sqrt((t k) / r dot (r k) / t) = k $

  Going back to the complexity equation plugging in the values:
  $
    & r + 2 s + t + r sqrt((t k) / r) + t sqrt((r k) / t) \
    & = r + 2 s + t + 2 sqrt(r k t) \
    & = O(r + s + t + sqrt(r k t))
  $

  This approach depends on both the cardinality of the _tables_ and the number of _nodes_ $k$ (the cascade approach only on tables).

  Which approach is better? It depends on the number of nodes.

  #example[
    - A social network with $10^9$ users, each user has $300$ friends on average.
    - The friendship is a self relation $R(u, u) in.rev (u_1, u_2)$ of size $r approx 300 dot 10^9 approx 10^11$.
    - We want to compute the users with a second degree friendship: $R join R join R$.

    Which approach is better?
    - _Cascade_:
      $ 1.98 dot 10^13 $
    - _Multi-way_ (with $k$ nodes):
      $ 1.2 dot 10^12 + 6 dot 10^11 sqrt(k) $

    For which values of $k$ is the multi-way approach better?
    $ 1.2 dot 10^12 + 6 dot 10^11 sqrt(k) < 1.98 dot 10^13 $
    Solving for $k$, the multi-way approach is preferable when the the number of nodes $k < 961$.

    #warning[
      If we use many nodes ($> 961$), we perform worse than using fewer nodes, because the communication overhead becomes too large.
    ]
  ]