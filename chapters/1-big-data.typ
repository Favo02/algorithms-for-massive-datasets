= Big Data: HDFS, MapReduce

What is big data?
Something that worked with a "normal" dataset, that doesnt work anymore.

It depends on the context:
- a normal person can't handle more than thousant records (e.g. in an excel sheet)
- a computer scientist can manage a dataset that can fit in main memory (GB)
- even bigger: a dataset that does not even fit in the disk (TB)

Increasing the power/memory of a computer *doesnt* scale *linearly*:
1000 TB computer != one thousant 1TB computers.

Nevertheless, this if the single computer fails, everything crumbles.

It leverages the power of *distributed computing*, that way increasing the power/memory scales *linearly*.
We can use commodity hardware.

We have two main things to do:
- storage of the dataset
- processing

== Storage

HDFS (Hadoop Distributed File System), an open source version of GFS (Google File System).

What architecture for the network? We need a network to connect our computational power which is distributed between computers.

We have some racks with 20 computers each.
Each rack has internal Gbit network.
Racks are interconnected by regular internet facility.

What about damages?
- hardware failure
- network failure (the computer is fine, but inaccessible to the other ones)

We can prevent/fix that using redudancy.

In a traditional file system, each file is not store in a contiguos part of memroy, it is divided into blocks (of around 1KB) and then stored around the memory.
There should be an external data structure that manages how these files are splitted.

We can use the same idea for a distributed file system, dividing each file in chunks (of around 64MB).
We also need a structure to manage for each file where each chunk is.

These chunks are also duplicated, each one called replica.

After a damage, the system will try to restore the operational amount of replicas, so that at all times, we have a constant amount of replicas.
Meaning that we are at all times pretty sure that a catastrofe cannot happend (3 computers breaking at the same time is really rare).

How can we know that there were a damage?
The central controller sends heartbits/heartbeats which expects a response.
If $n$ heartbits are lost, then damage is assumed.

Typically we have $3$ replicas, two in the same rack and one in a far away rack.

These files systems are immutable: the files are stored and then read as they are, they cannot be updated like we update a normal file.

== Processing (MapReduce)

We can do two things:
- data -> computation (we move data to a dedicated cpu that processes data)
- computation -> data (we compute the data where is stored, with the cpu of the correspondent computer)

The implemented version is computation brought to data, the computation is distributed too, there isnt a single processing center.

// #example[
We have a text and we want to compute the frequency of each word in this text.
// ]

This is implemented using the map-reduce paradigm, which is typically made in 3 steps:
- organize the data in key-value pairs
- map step
- (combiner)
- (shuffling)
- reduce step

=== Organize the data in key-value pairs

Everything in a map-reduce, should be organized as a key-value pairs (this works as tuples, not a dictionary, multiple values for the same key are allowed!).

Even the initial data should be in a key-value state.
This requisiste is not important right now, it will be become important later.

In our example:
Right now we simply implicitly associate data with a key, e.g. each line number with the text contained in that line.

We have to make sure that no pair starts in a chunk and ends in another chunk!

=== Map (with Combiner)

Receive all the key-value pairs and process them using a *function*.
This function receives ONE key-value pair and returns ZERO o MORE key-value pairs.

In our example: split the string into words $w$ and for each work output a pair $(w, 1)$

These produced key-values are temporarily stored in the filesystem of the local machine (the one which does the computation).

This phase can also include a combiner, that already combines the multiple couples into a single couple $(w,1), (w,1), (z,1) -> (w,2), (z,1)$, to make shuffling phase lighter.

=== Shuffling

Once all map phases are finished, all key-values are processed and each key-value is sent to a node.
All pairs with the same key should be sent to the same node.
To achieve that we use an hash function (shared by all computers): functions that evenly distributes inputs to outputs (buckets, tipically integers).
The hash functions are fast and act as load balancers (as their outputs should be randomly distributed).
That process is called *shuffling*.

In out example: the inputs are the possible keys (workds), the outputs are one of our computers (integer).

=== Reduce

The reduce function receives a key with an array of values as input and outputs ZERO or MORE key-value pairs.

In our example: the reduce receives a single word with multiple ones.
The length (or sum) of the array is the frequency of that word in the text.
Then function outputs a single pair with (word, frequency).

The result is stored in a new file in the distributed file system.

The reduce should be indepented of the order of the pairs received, so the operation should be commutative and associative.

Typically, one computer could reduce more than one key, because likely the number of words is much greather than the number of computers.

=== Example

// TODO: drawing of the example

=== Errors during computation

If an hardware or network error happens during the computation?
All I have to dois recompute only the computation done by that single node, NOT the whole computation.

Also this phase has a master controller that manages the whole computation.
In case of errors, this master controller, assigns the failed job to another node (nodes can be both computation-only or both storage+computation).

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
- Projection:\
  $t -> "MAP" -> (t', t')$\
  $(t', [(t', ..., t')]) -> "REDUCE" -> (t', t')$
- Set operations:
// TODO: from book

// #note[
All the results from Map and Reduce are a pair $(t,t)$ because we are forced to generate a key-value pair, so we just make up the other element of the pair.
// ]
