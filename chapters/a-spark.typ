#import "../template.typ": *

= Spark

We will not use Hadoop (which offers both a file system and a computing framework with MapReduce), but a more modern version: Spark.

Spark is essentially a workflow system with additional features, such as a more efficient way of coping with failures and grouping tasks among compute nodes. The central data abstraction of Spark is called the Resilient Distributed Dataset (RDD).

The adjective "resilient" symbolizes the capacity to recover from the loss of any or all chunks of an RDD.

#note[ An RDD is a collection of objects of the same type, similar to the files of key-value pairs used in MapReduce systems. ]

#warning[ RDDs are distributed in the sense that an RDD is normally broken into chunks that may be held at different compute nodes. ]

#warning[ Spark does not offer a distributed file system; it only provides the processing framework. Storage needs to be handled by another technology (typically Hadoop). ]

#note[ We refer to the machine that sends commands to Spark and displays output as the driver. This machine is not meant to handle big data itself. ]

Basically, a Spark program is a sequence of transformations (operations) that modify an RDD and return a new RDD.

There is also another type of operation called actions. These take an RDD and either save it to the surrounding filesystem or produce an output to pass back to the application that called the Spark program.

#warning[ There is no restriction on the type of elements that comprise an RDD. ]

#warning[ An RDD is not persistent; it is lost as soon as the machine turns off. Results must be stored in a distributed filesystem. ]

While there are many possible operations in a Spark program, we can list the most essential ones:

- *parallelize*: transform an object that lives in RAM to a RDD

- *textFile*: transform a file into a RDD

- *map*: takes a parameter that is a function, and applies it to avery element of an RDD, producing an RDD. note that respect of the map reduce, in here a map function can apply to any object type, but it produced exactly one object as result.

- *flatMap*: like map, but flatten the result (if multi-dimensional).
  Is the analogous to the function Map of MapReduce, but without the requirement that all types be key-value pairs.

- *filter*: select only elements that satisfy a predicate.
  Takes as a parameter a predicate that applies to the type of objects in the input RDD, and returns `true` or `false` for each object.
  The final output consists of only those objects for which the filter function returns `true`

- *reduceByKey*: reduction like in functional programming.
  Is an action.
  Takes as input a function which takes two elements of some type `T` and return another element of type `T`.
  The action is applied repeatedly to each pairs of consecutive elements until it remains a single element.
  The operation should be _commutative_ and _associative_.
  It does both _shuffling_ and _reducing_ steps.
  Can be applied only if the working set is composed of pairs.

- *groupByKey*: groups values by key without aggregating them.
  Can be applied only if the working set is composed of pairs.
  Takes in input an RDD whose type is a key-value pairs.
  Produces key-value pairs where the value is a list of all values for that key.

- *join*: joins two RDDs by key. The type of each RDD must be a key-value pair, and the key types of both relations must be the same.
  Returns pairs of (key, (value1, value2)).

- *count*: count the total number of elements in the RDD.
  This is an action that returns a value to the driver.

- *collect*: bring the data from the RDD into the RAM of the driver _(use with caution!)_

- *take*: like collect, but instead of getting all the data, only selects as many random records as specified (safe alternative to `collect`)

- *distinct*: remove duplicate elements from the RDD

- *union*: combine two RDDs into a single RDD

- *cache*: cache the RDD, keeping it in the RAM instead of distributing over the whole system (applied only if possible)

- *saveAsTextFile*: save the RDD as a text file in the distributed filesystem.
  Each element is written on a separate line.
  This is the standard way to persist results beyond the Spark session.
