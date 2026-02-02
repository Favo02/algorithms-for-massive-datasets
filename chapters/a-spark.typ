#import "../template.typ": *

= Spark

We will not use _Hadoop_ (which offers both file system and computing with MapReduce framework), but a more modern version: _Spark_.

#warning[
  Spark does *not* offer a _distributed file system_, but only the _processing framework_.
  The _storage_ needs to be handled by another technology (typically Hadoop).
]

#note[
  We refer to the machine that sends commands to Spark and displays output as *driver*.
  This machine is not meant to handle big data.
]

/ `spark.sparkContext`: an _entrypoint_ for all operations on a Spark dataset.
  Resilient Distributed Dataset (RDD) is the _object_ on which operations are applied.
  Once loaded, the dataset is stored inside Spark and the RDD is the _object_ on which operations are applied.
  #warning[
    An RDD is *not* persistent, it is lost as soon as the machine turns off.
    The results must be stored in a distributed filesystem.
  ]
/ `parallelize`: transform an object that lives in RAM to a RDD
/ `textFile`: transform a file into a RDD
/ `map`: the map function in map reduce, applies a transformation
/ `flatMap`: like map, but flatten the result (if multi-dimensional)
/ `filter`: select only elements that satisfy a predicate
/ `reduceByKey`: reduction like in functional programming.
  The operation should be _commutative_ and _associative_.
  It does both _shuffling_ and _reducing_ steps.
  Can be applied only if the working set is composed of pairs.
/ `groupByKey`: groups values by key without aggregating them.
  Can be applied only if the working set is composed of pairs.
  Produces key-value pairs where the value is a list of all values for that key.
/ `join`: joins two RDDs by key.
  Both RDDs must be composed of key-value pairs.
  Returns pairs of (key, (value1, value2)).
/ `count`: count the total number of elements in the RDD.
  This is an action that returns a value to the driver.
/ `collect`: bring the data from the RDD into the RAM of the driver _(use with caution!)_
/ `take`: like collect, but instead of getting all the data, only selects as many random records as specified (safe alternative to `collect`)
/ `distinct`: remove duplicate elements from the RDD
/ `union`: combine two RDDs into a single RDD
/ `cache`: cache the RDD, keeping it in the RAM instead of distributing over the whole system (applied only if possible)
/ `saveAsTextFile`: save the RDD as a text file in the distributed filesystem.
  Each element is written on a separate line.
  This is the standard way to persist results beyond the Spark session.
