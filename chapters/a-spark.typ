#import "../template.typ": *

= Spark

A modern framework for big data processing is Spark, it does not provide a distributed file system, but only the *processing* framework.
Storage needs to be handled by another technology (typically _Hadoop_).
Main Spark concepts are:

/ Resilient Distributed Datasets (RDDs): the main *data* abstraction in Spark, representing a distributed collection of objects (with the same format) that can be processed in parallel.
  An RDD is partitioned in *chunks* that may be held at different compute nodes.
  RDDs are *immutable*, meaning that once created, they cannot be modified. Instead, *transformations* on RDDs produce new RDDs.

  #note[
    The adjective "resilient" symbolizes the capacity to recover from the loss of any or all chunks of an RDD.
  ]

  #note[
    Spark does *not* enforce key-value pairs as the data model for RDDs, but many operations (like reduceByKey) are designed for pair RDDs.
  ]

  #warning[
    An RDD is *not* persistent: it is lost as soon as the machine turns off.
    Results must be stored in a distributed filesystem.
  ]

/ Workflow: a sequence of *lazy transformations* and *actions* on RDDs that define a Spark program.

  #warning[
    Each operation on an RDD is lazy, meaning that it does not immediately compute a result. Instead, it builds up a graph of transformations that is executed when an action (collect, count, etc.) is called.

    Calling multiple times an action on the same RDD will trigger the execution of the entire graph of transformations each time, unless the RDD is *cached*.
  ]

/ Driver: the machine that runs the main program and coordinates the execution of tasks across the cluster.

The full #link("https://spark.apache.org/docs/latest/api/python/reference/pyspark.html")[RDD Spark API] is large, the essential operations are:

- *RDD creation*:
  - *parallelize*: creates an RDD from an in memory collection on the driver.
  - *textFile*: creates an RDD from a text file (typically in distributed storage).

- *local transformations* (no shuffle, usually faster):
  - *map*: applies a function to each element, producing exactly one output element per input element.
  - *flatMap*: like `map`, but each input element can produce zero, one, or many output elements.
  - *filter*: keeps only elements that satisfy a predicate.
  - *union*: combines two RDDs into one RDD, concatenating their elements.

- *shuffle transformations* (network communication, usually slower):
  - *reduceByKey*: for pair RDDs `(K, V)`, aggregates values per key using an associative and commutative function.
  - *groupByKey*: for pair RDDs `(K, V)`, groups all values for each key into `(K, Iterable[V])`.
  - *join*: for pair RDDs, joins by key and returns `(K, (V1, V2))`.
  - *distinct*: removes duplicates.

- *persistence*:
  - *cache*: asks Spark to persist the RDD instead of recomputing it every time it is needed (usually in memory, possibly with fallback to disk depending on storage level).

- *actions* (trigger execution and return results or write output):
  - *count*: returns the number of elements to the driver.
  - *collect*: returns all elements to the driver memory (use with caution).
  - *take*: returns the first `n` elements to the driver (safer than `collect` for inspection).
  - *saveAsTextFile*: writes the RDD to text files in distributed storage (one element per line).
