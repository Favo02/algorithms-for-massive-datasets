#import "../template.typ": *

= Implementation

We will not use Hadoop (which offers both file system and computing with MapReduce), but a more modern version: Spark.

#warning[
  Spark does NOT offer a distrbuted file system, so the storage needs to be handled by another technology.
]

Resilient distributed data set (rdd): the files in spark are stored in that system, that gets processed but is not persistent (it will likely disappear after the machine shuts down), we need to save the result somewhere.

- `spark.sparkContext`: context from where to start each action
- `parallelize`: transform an object that lives in RAM to an object that lives inside spark
- `textFile`: transform a file into a rdd
- `collect`: bring the data from the rdd into the RAM of the driver (the machine that runs, not meant to handle big data)
- `map`: exactly the map function in map reduce, applies a transformation
- `flatMap`: exactly like map, but flatten it if its multi-dimensional
- `take`: like collect, but instead of getting all the data, only selects as many random records as specified
- `reduceByKey`: reduction like in functional prorgarmming (this should be commutative and associative). It does both shuffling and reducing. It works only if the working set its applied to is in pair format
- `cache`: cache the rdd, e.g. keep it RAM instead of distributing over the whole system
