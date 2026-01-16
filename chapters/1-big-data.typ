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

#todo

=== Example: Product between matrix and vector

- $A = [a_(i j)]_(m times m)$ matrix, too big to be storable
- $underline(v) = [v_j]_m$ vector, storable in RAM (of each single computer involved)
- $A underline(v) = p$
- $p_j = sum_j a_(i j) v_j$

With $m = 10^9$, we have $10^18$ entries, each one of $8$ bytes, so that cannot fit in memory.

We need to store the data in a distributed file system:
- organize the data:
  Convert each entry into a triple $(i, j, a_(i j))$, row index, column index, entry value.
  We can assume $i$ is the key and $(j, a_(i j))$ the value, we dont care
- map:
  Apply the transformation: $(i, j, a_(i j)) -> (i, a_(i j) v_j)$.
  How can we apply that if we don't have $v$ in the pair?
  We said that $v$ can be stored in RAM, so we can just fetch its value from there.
- shuffling:
  Each key-value is sent based on $i$, and each reduce node receives: $(i, underbrace([a_(i 1) v_1, a_(i 2) v_2, ...], S))$
- reduce:
  Just sum the values: $(i, sum S) = (i, p_i)$

This approach works for every matrix, even if the matrix is very small, but the overhead is obviously not worth it.

=== Example: Product between matrix and vector 2

Same example as before, but not even the vector $underline(v)$ is storable in memory.
The assumption is that *half* of $underline(v)$ is storable in RAM.
The two halves are $v_u$ and $v_l$.
Because we split the vector, let's also split the matrix into $A_L$ and $A_R$.

The halves are compatible, as the numbers of columns of the half matrix are the same of the rows of the half vector (the vector is vertical).

$ [A_L | A_R] dot [underline(v)_u / underline(v)_l] = A_L underline(v)_u + A_R underline(v)_l $

Then we only need to expand up the *map* part, the reduce part can be left untouched.
The reduce sums up by row number, but both parts of the matrix (left and right) keep the line number untouched, so it works.

=== Example: Relational Algebra

Concept of relational algebra:
- Relation $R(A, B) subset A times B$: an SQL table
- Attributes $A, B$: columnds of a SQL table
- Row of a SQL table: $(a, b) in R$

Operations of relational algebra:
- Selection: $sigma_(c)(R) -> R$: filtering the rows of the table based on some criterion
- Projection: $pi_(A, B, ...)(R) -> R$: filtering the columns of the table
- Union: _same as set theory_
- Difference: _same as set theory_
- Intersection: _same as set theory_
- Join
- Grouping

If the relation is too big, then we can't use a traditional DBMS, but we can use MapReduce:
- Selection:\
  $t in R -> "MAP" -> cases((t,t) &"if" c(t) = T, emptyset &"otherwise")$\
  $(t, t) -> "REDUCE" -> (t, t)$
  #note[
    All the results from Map and Reduce are a pair $(t,t)$ because we are forced to generate a key-value pair, so we just make up the other element of the pair.
  ]
- Projection:\
  $t -> "MAP" -> (t', t')$\
  $(t', [(t', ..., t')]) -> "REDUCE" -> (t', t')$
- Union: #todo
// TODO: from book
- Difference:
  $ R, S quad t in R \\ S quad "iff" t in R and t in.not S $
  - map phase:
    #informally[
      Until now, we used the same map function for all the pairs.
      In this example, we need to apply a different map function for the pairs of R and the pairs of S.

      We differentiate the tuples that comes from R and the tuples that comes from S.
      To do that we add an identifier that identifies the relation (not the relation itself)!
    ]
    $ forall t in R #rect[$"MAP"_R$] --> (t, \'R\') $
    $ forall t in S #rect[$"MAP"_S$] --> (t, \'S\') $
  - reduce phase:
    $ (t, ['R']) --> #rect[REDUCE] --> (t, t) $
    $ (t, ['R', 'S']) --> #rect[REDUCE] --> emptyset $
    $ (t, ['S']) --> #rect[REDUCE] --> emptyset $
- Grouping/Aggregation:
  $ R(A, B) quad gamma_(A, theta(B)) $
  - map phase
    $ forall (a, b) in R --> #rect[MAP] --> (a, b) $
  - reduce phase
    $ (a, [b_1, ..., b_m]) --> #rect[REDUCE] --> (a, omega(b_1, ..., b_m)) $
- Join
  $ R(A, B) join S(B, C) in.rev (a, b, c) quad "iif" (a, b) in R and (b, c) in S $
  - map phase
    $ forall (a, b) in R --> #rect[$"MAP"_R$] --> (b, a) $
    $ forall (b, c) in S --> #rect[$"MAP"_S$] --> (b, c) $
  - reduce phase
    $ (b, [a_1, ..., a_m, c_1, ..., c_n]) $
    #warning[
      That doesn't work as the values are NOT ordered, so we can't know if the values comes from R or S.
      Moreover, we can't match values to generate the resulting triple.
    ]
  - map phase
    $ forall (a, b) in R --> #rect[$"MAP"_R$] --> (b, (a, \'R\')) $
    $ forall (b, c) in S --> #rect[$"MAP"_S$] --> (b, (c, \'S\')) $
  - reduce phase
    $ (b, [(a_1, \'R\'), (c_8, \'S\'), (a_3, \'R\') ...]) $
    The reduce operator sorts the values based on the second element of the pair, so that we have all the R before all the S
    #note[
      One of these pairs is generated for each different value of $b$.
    ]

=== Example: Matrix Matrix Multiplication

Generalization: we can use a join to multiply two matrices

$ A_(m times n) quad B_(n, o) quad P = A dot B quad P_(i j) = sum_(k=1)^n a_(i k) b_(k j) $
$ A(I, K, V) in.rev (i, k, a_(i k)) $
$ B(K, J, W) in.rev (k, j, b_(k j)) $
$ A join B in.rev (i, j, j, a_(i k) b_(k j)) $

Map
$ forall (i, k, a_(i k)) in A --> #rect[$"MAP"_A$] --> (K, (i, a_(i k), \'A\')) $
$ forall (k, j, b_(k j)) in B --> #rect[$"MAP"_B$] --> (K, (j, b_(k j), \'B\')) $

Reduce
$ (k, [(1, a_(1 k), \'A\'), ..., (m, a_(m k), \'A\'), (1, b_(k 1), \'B\'), ..., (o, b_(k o), \'B\')]) $

#warning[
  Again, the reduce will not reduce these elements sorted, we just write them sorted for notation.

  The reduce part will use the third and second element of the triple to *sort* them.
]

We can see that result as a matrix: on the columns the (1, a1k, A) and on the rows (1, bk1, B)

The reduce generates: $((i, j), a_(i k) b_(k j)) forall i forall j$

But we are missing an important information: $k$!

The idea is that we can concatenate multiple map-reduce jobs (thats why even the input should be in key-value format).

In this case, we dont need to perform another map transormation, we just need to shuffle and reduce again.
$ ((i, j), a_(i k) b_(k j)) --> #rect[MAP2] --> ((i, j), a_(i k) b_(k j)) $

$ ((i, j), [(a_(i 1) b_(k j), ..., )]) --> #rect[REDUCE] --> ((i, j), underbrace(sum(S), p_(i j))) $

This approach uses 2 MapReduce jobs.

=== Example: Matrix Matrix Multiplication V2

To use only one job we immediately try to use the final key: (i, j), but we don't have j.
We know that j can range between $1$ and $o$, so we output one of these pairs for all possible value of $j$
$ (i, k, a_(i k)) in A --> #rect[MAP A] --> ((i, j), (j, a_(i k), \'A\')) forall j = 1, ..., o $

Same thing for B:
$ (k, j, b_(k j)) in B --> #rect[MAP B] --> ((i, j), (k, b_(k j), \'B\')) forall i = 1, ..., m $

Reduce (already sorted by $k$):
$ (i, j) [(1, a_(i 1), \'A\'), ..., (n, a_(i n), \'A\'), (1, b_(1 j), \'B\', ..., (n, b_(n j), \'B\'))] $

This new approach uses only one MapReduce job.

Using one MapReduce job comes at a price: increasing (a lot) the quantity of mapped pairs that have to be sent over the network.

Complexity: we never talked about complexity of these computations.

It is very likely that the network overhead (the exchange of pairs during shuffling phase) dominates the computation.
So we need to minimize the number of pairs generated by map phase (that are shuffled).

= Complexity: Communication Cost Model

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
