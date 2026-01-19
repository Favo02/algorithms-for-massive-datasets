#import "../template.typ": *

= HDFS and MapReduce

This course in pretty much about *big data*.
But what is big data?
It depends on the context.

#example[
  - A _normal person_ can't handle more than some thousants records (e.g. in an excel sheet)
  - Classic _computation_ can't manage a dataset that doesn't fit in _main memory_ (GB)
  - Or even bigger: a dataset that does not even fit in the _disk_ (TB)
]

In general, we talk about *big data* when something that worked with a "normal" dataset, that doesn't work anymore.

#note[
  We will work with dataset tipically divided into "can/can't fit in *main memory* (RAM)" and "can/can't fint in *disk*".
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
  These racks are phisically in different locations (even different cities or countries).

  The computers in a single rack are connected with a _fast connection_ (Gbit network), while the racks are connected using standard _internet facility_ (slower).
]

In a traditional file system, each file is *not* stored in a _contiguos_ part of memory, it is divided into *blocks* (of around 1KB) and then stored around the memory.
There is an external data structure that stores how these files are splitted and where each block is.

We can use the same idea for a distributed file system, dividing each file in *chunks* (of around 64MB) and distribute them over *multiple computers*.
We also need a (central) structure to manage for each file where each chunk is.

What about *damages*? Two main categories exists:
- _hardware_ failures (the computer phisically breaks down)
- _network_ failures (the computer is fine, but inaccessible to the other ones)

We can prevent/fix these issues using *redudancy*, each file chunk is duplicated multiple times, each one called *replica*.
Typically we have $3$ replicas, two in the same rack and one in a far away rack.

#note[
  An important property is that, after a problem, the system will restore the *operational amount* of replicas.
  Meaning that we are at all times pretty sure that completely losing a file is really _unlikely_ (multiple computers should break down at the same time).
]

How does the system _detects_ issues and failures?
The central controller sends *heartbeats* to all computers, which expects a response.
If $n$ consecutive heartbits are lost, then damage is assumed.

These files systems are *immutable*: the files are stored and then read as they are, they cannot be updated like we update a normal file.
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

Processing distributed files means read them, compute _something_ and generate a result.
The files are not modified and the result is *another file*, stored indepently in the distributed file system.

Two approaches arise:
- bring the _data_ to the _computation_: the data is moved to a dedicated node, where all the processing happens
- bring the _computation_ to the _data_: the computation is done by the CPU of the computer that stores the data (the data is not transferred through the network)

Of course, moving a huge amount is data brings a big overhead, so the second approach is chosen: the computations is done by the *distributed CPUs* over the whole network.

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

A *map* function is applied to _each_ key-value pair indepently.
The function receives _one_ key-value pair and returns _zero, one or more_ key-value pairs:
$ (k, v) --> #rect("MAP") --> (k, v)^* $

Because of the _indepented_ nature of each pair, this computation can happen anywhere.
In HDFS, the map step is performed by the computer where the chunk is stored.

#example[
  The map function will split the string into words and for each word $w$, it outputs a pair $(w, 1)$.
]

The result of the map phase (the produces key-values) are temporarily stored in the *local machine* (the one which does the computation).

=== Combine

The map phase can also include a combiner: an optimization step that merges multiple key-value pairs, to reduce the number of pairs handled by the shuffling phase (the next one).

#warning[
  This still happens in the *local* machine, so only the pairs of a single *chunk* are considered.
]

#example[
  Multiple pairs with the same key are merged into one single pair with summed value: $(w,1), (w,1), (z,1) -> (w,2), (z,1)$.
]

=== Shuffle

After the map function is applied, each generated pair-values are *sent* to _nodes around the network_ to perform the next step of the processing: reduction.

Pairs with the *same key* are sent to the *same node*.

This is achieved by using a common *hash function* (the same for all computers):
$ h : underbrace(K, "universe of keys") -> underbrace(m subset bb(N), "number of nodes") $

This function _evenly_ distributes the keys across all nodes of the network and act as *load balancers*.
That process is called *shuffling*.

=== Reduce

The shuffled key-value pairs are then processed by a *reduce* function.
The reduce function receives a pair formed by a _single key and multiple values_ and returns _zero, one or more_ key-value pairs:
$ (k, underbrace([v_1, v_2, ..., v_n], S)) --> #rect[REDUCE] --> (k, v)^* $

#note[
  All the key-value pairs with the *same key* are processed by the *same node*, so we can view all the values as an array $S$ associated with its key $k$ using the notation $(k, [v_1, v_2, ..., v_n])$.
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
  We cannot make assumptions on the order of the values, as mapping and shuffling phase of each pair can happend in different computers.

  Because of that, the operation applied by the reduce function should be *commutative* and *associative*.
]

=== Errors during Computation

What happens if a *failure* (hardware or network) occours during the computation?
All the system have to do is to recompute only the computation done by the _single node_ that _failed_, NOT the whole computation.

#note[
  If a _map_ job fails, then it can simply be re-run on another node (with the same chunk).

  If a _reduce_ job fails, the system should ask all the node that performed a map job to re-shuffle the pairs.
  Because of that, the map nodes should store the _temporary_ results of the map phase until the _whole_ computation is over.
]

=== Example: Matrix Vector Multiplication

Given:
- a matrix $A = [a_(i j)]_(m times m)$ too big to be storable
- a vector $underline(v) = [v_j]_m$ storable in RAM (of each single computer involved)
- the resulting vector $A underline(v) = p, quad p_j = sum_j a_(i j) v_j$

We need to _store_ and _process_ the data in a _distributed file system_ using _MapReduce_:
- Organize:\
  Each entry $(i, j, a_(i j))$ (row index, column index, entry value) should be converted to a pair.
  We can simply use $i$ as the key and $(j, a_(i j))$ as the value, forming the pair $(i, (j, a_(i j)))$.
- Map:\
  For each entry we need multiplicate its value by the corresponding element of the vector:
  $(i, j, a_(i j)) --> #rect[MAP] --> (i, a_(i j) v_j)$.
  #note[
    How can we apply that transormation if we don't have $v$ in the pair to map?
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

=== Example: Matrix Vector Multiplication V2

Same example as before, but not even the vector $underline(v)$ is NOT storable in memory.
The assumption is that only *half* of $underline(v)$ is storable in RAM.

To leverage a mathematical property we split both the vector into upper $v_u$ and lower $v_l$ and the matrix into left $A_L$ and right $A_R$.
The halves are compatible, as the numbers of columns of the half matrix are the same of the rows of the half vector _(the vector is the mathematical object, so represented vertically)_.
The final product is the *sum* of the multiplication of the two halves *indepently*:
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
  All the results from Map and Reduce are a pair $(t,t)$ even if not additional information is needed because we are forced to adhere to the key-value format.
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
    Multiple values with the same key $t$ are generated only when multiple rows with the same exact content exists (no primary key exists in the table).
  ]

/ Projection $pi_(A,B) (R)$: the map job filters the columns, while the reduce step returns the data as it is
  $
    t in R -> #rect[MAP] -> (t', t')
  $
  $ (t', [t', ..., t']) -> #rect[REDUCE] -> (t', t') $
  #note[
    The map function extracts only the requested attributes $A, B$ from tuple $t$, producing $t'$.
  ]

/ Union $R union S$: multiple map functions exists, one for the relation $R$ and one for relation $S$. Both map functions output tuples that gets shuffled to reduce functions that outputs them
  $ t in R -> #rect[MAP] -> (t, t) $
  $ t in S -> #rect[MAP] -> (t, t) $
  $ (t, [t, ..., t]) -> #rect[REDUCE] -> (t, t) $

/ Difference $R \\ S$:
  we need to differentiate the tuples that comes from R and the tuples that comes from S.
  To do that we add an identifier ($\'R\'$ or $\'S\'$) that identifies the relation (not the whole relation itself!).
  #informally[
    Until now, we used the same map function for all the pairs.
    In difference, we need to apply a different map function for the pairs of R and the pairs of S.
  ]
  $ forall t in R --> #rect[$"MAP"_R$] --> (t, \'R\') $
  $ forall t in S --> #rect[$"MAP"_S$] --> (t, \'S\') $

  Then the reduce step outputs only pairs that are only in $R$:
  $ (t, [\'R\']) --> #rect[REDUCE] --> (t, t) $
  $ (t, [\'R\', \'S\']) --> #rect[REDUCE] --> emptyset $
  $ (t, [\'S\']) --> #rect[REDUCE] --> emptyset $

/ Grouping/Aggregation $gamma_(A, theta(B))(R)$: the attributes are grouped on attribute $A$ and aggregated on $B$.
  The attributes with the same key $a$ are shuffled to the same node, so the aggregation can be performed.
  $ forall (a, b) in R --> #rect[MAP] --> (a, b) $
  $ (a, [b_1, ..., b_m]) --> #rect[REDUCE] --> (a, theta(b_1, ..., b_m)) $

/ Join $R(A, B) join S(B, C)$: two relations should share an attribute to generate tuples $(a, b, c)$.

  First let's start with an approach that *does NOT work*:
  the idea is to use the common attribute as the key, so that will be sent to the same node:
  $ forall (a, b) in R --> #rect[$"MAP"_R$] --> (b, a) $
  $ forall (b, c) in S --> #rect[$"MAP"_S$] --> (b, c) $

  Then we should simply be able to construct the resulting tuples:
  $ (b, [a_1, ..., a_m, c_1, ..., c_n]) --> #rect[REDUCE] --> (a, b, c) forall a forall c $

  #warning[
    But that does not work as values received by the reduce step are not ordered:
    $ ("key", [5, 7, 9, 1, 3, 2]) $

    We cannot differentiate which values comes from $A$ and which from $C$, so that approach does NOT work.
  ]

  So we also need to specify the relation the values come from:
  $ forall (a, b) in R --> #rect[$"MAP"_R$] --> (b, (a, \'R\')) $
  $ forall (b, c) in S --> #rect[$"MAP"_S$] --> (b, (c, \'S\')) $

  The reduce step can then sort on the second element of each pair, so that all \'R\' come before each \'S\' and then generate the result.

  $ (b, [(a_1, \'R\'), (c_8, \'S\'), (a_3, \'R\'), ...]) --> #rect[REDUCE] --> (a, b, c) forall a forall c $

=== Example: Matrix Matrix Multiplication

The same approach can be used to perform a matrix-matrix multiplication.

Given two matrices with one commond dimension $A_(m times n), B_(n times o)$, the resulting matrix $P$ will be:
$ P = A dot B, quad P_(i j) = sum_(k=1)^n a_(i k) b_(k j) $

We can transform this problem into a _natural join_, treating the two matrices as _tables_ with three attributes $("row", "column", "value")$ with the common dimension as the _common attribute_ on which to join:
$ A(I, K, V) in.rev (i, k, a_(i k)) $
$ B(K, J, W) in.rev (k, j, b_(k j)) $

The join operation will return all the tuples with a common $k$:
$ A join B in.rev (k, i, j, a_(i k), b_(k j)) $

#informally[
  The idea is to match rows with columns of the two matrices ($k$ is rows in a table and columns in the other).
]

To perform that we need to shuffle on key $k$ and keep track of which table each entry comes from:
$ forall (i, k, a_(i k)) in A --> #rect[$"MAP"_A$] --> (k, (i, a_(i k), \'A\')) $
$ forall (k, j, b_(k j)) in B --> #rect[$"MAP"_B$] --> (k, (j, b_(k j), \'B\')) $

Then we can multiply $a_(i k)$ entries with $b_(k j)$ entries to obtain:
$
  (k, [(1, a_(1 k), \'A\'), ..., (m, a_(m k), \'A\'), (1, b_(k 1), \'B\'), ..., (o, b_(k o), \'B\')]) --> #rect[REDUCE] --> ((i, j), a_(i k) b_(k j)) forall i forall j
$

#warning[
  Again, the reduce will not receive these elements _sorted_, that's why we need the labels $\'A\', \'B\'$: to be able to sort them.
]

_Multiple_ tuples with the same $(i, j)$ will be generated: the multiplication is not over yet.
These elements needs to be _summed up_ to obtain $P_(i j)$.
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

This approach uses *two* concatenated MapReduce jobs.

=== Example: Matrix Matrix Multiplication V2

We can do better in terms of number of MapReduce jobs: using only one.

#informally[
  The resulting entries will depend on the row and column $(i, j)$, so our map will definetely need to _shuffle_ on that key.

  But for each matrix we don't know one dimension, so we simply generate _all possible_ values of this unknown.
]

We immediately try to generate pairs with $(i, j)$ as key.
For matrix $A$ we don't know $j$, so we range all possible values in range $[1, o]$:
$ (i, k, a_(i k)) in A --> #rect[$"MAP"_A$] --> ((i, j), (k, a_(i k), \'A\')) space forall j in [1, o] $

Same thing for matrix $B$ in which we don't know $i$:
$ (k, j, b_(k j)) in B --> #rect[$"MAP"_B$] --> ((i, j), (k, b_(k j), \'B\')) space forall i in [1, m] $

Then the reduce function needs to match tuples from $\'A\'$ and from $\'B\'$ based on a common $k$.
To achieve that the array can be _sorted_ with a _multiple key_ comparation, first on the label $\'A\'$ and $\'B\'$ and then on the values $k$.
$
  ((i, j), [(1, a_(i 1), \'A\'), ..., (n, a_(i n), \'A\'), (1, b_(1 j), \'B\'), ..., (n, b_(n j), \'B\')]) --> #rect[REDUCE] --> ((i, j), sum_(k=1)^n a_(i k) b_(k j))
$

This new approach uses only *one* MapReduce job, but the number of pairs sent across the network is _much bigger_ than before.

#note[
  We will analyze the complexity of these examples in the next section (#link-section(<communication-cost-model>)).
]

== Complexity: Communication Cost Model <communication-cost-model>

It is very likely that the network overhead (the exchange of pairs during shuffling phase) dominates the computation.
So we need to minimize the number of pairs generated by map phase (that are shuffled).

When things are distributed, the most important complexity is space complexity.
But even that is not the most important thing.

The complexity that we study to evaluate is the network latency: The communication Cost Model.

We can describe to computation using a Computation Graph, where each node represents a computation that can start only when the predecessors are finished (when the input is ready).

We count the number of things that travel that graph, more specifically we can count bytes or number of tuples.

To compute this count, we can simply sum of size of all inputs.
The only thing we dont count with this approach is the output of final output (because all other outputs are inputs to other nodes).
But the final output is negligible (as we cannot reduce it, it is the output!).

#note[
  That's not true in Hadoop DFS, as the input for the first computation is handled locally on the same machine the chunk is stored, so it doesnt travel the network.

  But thats true in other modern frameworks, such as Spark.
]

== Examples

Join:

$ R(A, B) join S(B, C), quad |R| = r, |S| = s $

The map function generates exactly one output tuple for each input tuple, so the cost of the map step is $r + s$, so the overall cost is $O(r + s)$.

Double join:

$ R(A, B) join S(B, C) join T(C, D), quad |X| = x $

We first join R and S then we join T.
The complexity of the first join is, of course, $O(r + s)$.
To calculate complexity of the second join we need to know the cardinality of the result of the first join (which we dont know).
We can use probability to estimate that:
$ p = P((a, b) and (b, c) "match" b = b) $
Then we can calculate the complexity of the second join: the total number of possible resulting rows is $r s$ and each of this in influenced by the probability $p$:
$O(p dot r dot s + t)$

The overall complexity is then: $O(r + s + t + p r s)$

If we did the join in another order, we obtain a different complexity, we need to define another probability as we cannot assume they are the same:
$ p' = P((b, c) and (c, d) "match" c = c) $
The total complexity is:
$ O(r + s + t + p' s t) $

(We don't know which one is the best.)

This approach is called *cascade joins*.

Another approach: multi-way in which we leverage hash functions.

$ h_B : B -> {a, ..., n_B} $
$ h_C : C -> {0, ..., n_C} $
The number of buckets of these hash functions is limited by $n_B dot n_C = k = "number of nodes (computers)"$

This approach uses MAP only as a dispatcher that sends to the correct nodes the pairs where the reduce should happen:
$ forall (b, c) in S "send to" (h_B(b), h_C(c)) $
$ forall (a, b) in R "send to" (h_B(b), c) forall c in 0...n_C $
$ forall (c, d) in T "send to" (b, h_C(c)) forall b in 0...n_B $

For the tuples that we have the hash function for both elements, we send only to the correct node.
For the other, we sent to all possible nodes that can need the pair.

This ensures that all nodes receive at least all the tuples that it needs.
So we are guaranteed that the final computation is correct.

Complexity:
- map phase input: of course $s + r + t$
- reduce phase (output of map):
  - for $S$ relation: $s$
  - for $R$ relation: $r n_C$
  - for $T$ relation: $t n_B$

The total complexity becomes: $O(r + 2s + t + r n_C + t n_B)$.
We need to fix the number of buckets $n_C$ and $n_B$:
$
  min r + 2s + t + r n_C + t n_B \
  = min r n_C + t n_B quad "keeping" n_C n_B = k
$
To solve this minimization problem we can use Lagrange relaxation: when we have a minimization problem with a constraint that is an expression equal to zero, we can turn into two uncontrainted problems: a Lagrange function.

$ L = r n_C + t n_B - lambda (n_B + n_C - k) $

We need to find the minimum of that, so we need to calculate the derivative and put equal to zero.

But thats a multi-variable function, so we can't calculate "normal" derivative, we need partial defivative: we pretend that all the variables except one is constant and we calculate the derivative on the selected variable.
Once all partial derivatives have been calculated, we put all the results in a vector, called a gradient $nabla$.

We can compute the gradient for the function $L$ and then put equal to the vector $[0, 0, 0]$.

$ (d L) / (d n_B) = t - lambda n_C $
$ (d L) / (d n_C) = r - lambda n_B $

We put equal to $0$ and we obtain $t = lambda n_C$ and $r = lambda n_B$:
$
  r t = lambda^2 n_C n_B = lambda^2 k \
  lambda = sqrt((r t) / k)
$

Going back to equations for $t$ and $r$:
$ n_C = t / lambda = t sqrt(k/(r t)) = sqrt((t k) / r) $
$ n_B = r / lambda = r sqrt(k/(r t)) = sqrt((r k) / t) $

To double check things, if we multiply $n_C dot n_B$ we should obtain $k$:
$ sqrt((t k) / r dot (r k) / t) = k $

We can put back this value into the original expression:
$
  r + 2 s + t + r sqrt((t k) / r) + t sqrt((r k) / t) \
  = r + 2 s + t + 2 sqrt(r k t)
$

This approach also depends on $k$ (the number of nodes).
This was not the case for the cascade joins.

Which approach is better? It depends on the number of nodes.

== Example

Social network with $10^9$ users, each users has $300$ friends on average.
The relation (for multiple things like likes, friendship) is $R(, u, v) in.rev (u_1, u_2)$ of size $r = 3 dot 10^12$.
We want to compute $R join R join R$.

Which approach is better?
- cascade: the size of each relation is the same $r = s = t$. We also assume the result of the first join contains $30 r$ tuples. The overall complexity is $35 r$ // TODO: from book
- multi way: $2r(2 + sqrt(k))$

For which values of $k$ is better the multi way?
$ 2r (2 + sqrt(k)) < 35r $
