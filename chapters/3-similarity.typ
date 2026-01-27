#import "../template.typ": *

= Similarity

#informally[
  Detecting similary between objects.

  With an equality relation between the universe of where the objects live, the equality is a dicotomic relation (true or false).

  Similarity on the other hand is a spectrum (e.g. plagiarism).

  #example[
    How does amazon suggest other things to buy?
    It detects other users that are _similar_ to you, suggesting things that similar users bought.
  ]
]

It can be defines as:
$ s(x, y) -> RR $

For each object, compute the similarity compared to another object (a simple for loop).
But when the dataset is massive, even simple problems become complex.

We will focus on very specific type of objects: text documents.
There are many similarity measures for text documents, we decide to use the Jaccard similarity, defined as:
$ J(S, T) = (|S inter T|) / (|S union T|) $

#note[
  We dont represent text as sets, but as strings.
  We need to define intersection and union over strings.
  We will do that in a moment.
]

The Jaccard similarity is bounded:
- if $S inter T = emptyset quad -> J(S, T) = 0$
- if $S = T quad -> J(S, T) = 1$

#warning[
  With this tecnique, we are considering only a "sintactic" similarity, we are not considering "semantics" of the text.

  We are working with sets, they do not depend on the order of elements.
]

To calculate these, we need to convert text into a set.
We divide the text into *shingles*: a not particularly defined _part_ or _fragment_ of a text.
For example, we can divide the text into words.

#note[
  Most of the time, it is better not to work with the text as it was provided.
  For example, removing or ignoring conjunctions and stop words.
  In this case, a shingle is a non-stop word with the two words that succed it.

  #example[
    "Today and tomorrow will..."
    "Buy X-cola"
    The only shingle is "and tomorrow will".
  ]
]

We will use k-grams, $k$ following elements.
An element could be either a character, a word or even a whole sentence.

#example[
  "Today and tomorrow will..."
  "Buy X-cola"
  with $k = 5$ characters, we will get:
  "today", "oday ", "day a", "ay an", ...
]

#warning[
  These are sets, not multisets!
]

How do we choose $k$?
It depends on the type of text.
Lets see what happens with big or small values for $k$:
- $k = 1$ unigrams: independently of the document, it is very likely we are ending up with the same set: the full alphabet.\
  *Anything is similar*
- $k = k_max$ the lenght of the document: we will extract only one shingle. The only documents that will have similarity differnt than $0$ is if the document is compared with itself.\
  *Nothing is similar*

A good idea is to calculate the probability of a shingle to be contained in a document.

#example[
  We are working with email messages.
  For simplicity, the only allowed characters are 27 (the alphabet + a white space).

  With $k = 5$, there exists $27^5 approx 14 dot 10^6$.
  This number also accounts for very unlikey 5-grams.

  The length of the email is an upper bound to the number of different k-grams (independently of $k$).

  If that number is much smaller than $27^5$, then most of the possible k-grams cannot appear.
]

The naive way is to store each k-gram explicitly, needing $k$ bytes.

But that wastes a lot of space, we could use hash functions.
$ h(x) -> 32 $

=== Charateristic Matrix

We need to store the information we have:
- one dimension (x) is for the documents
- one dimension (y) is for the shingle. The shingle is hashed, so it is represent by an integer
- each entry is $1$ or $0$, if the shingle is included in the document or not

#example[$
  mat(
    , D_1, D_2, D_3;
    0, 0, 1, 1;
    1, 1, 0, 1;
    2, 1, 1, 1;
    3, 0, 0, 1
  )
$]

To calculate the similarity between two documents, we can simply count the rows with both $1$ (intersection) or at least one $1$ (union).
But we cannot do that because we cannot fit the whole matrix into memory.

#note[
  We need to compress this matrix, but we need to be able to compute the similarity without decompressing it.
]

=== Min Hash Function

An hash function that hash document into shingles
$ h : {"docs"} -> {"shingles"} $

#warning[
  This function is not deterministic.
  But not that the same function will return different result: a fixed function IS deterministic.

  But we will pick randomly a function.
]

+ Fix a row permutation of the CM
+ Apply the permutation to the CM
+ For each document, select the first one in the permuted column

#example[
  An hash function $h_1$ for the previous matrix example:
  + we fix $[2, 0, 3, 1]$:
  + permute the matrix:
    $
      mat(
        , D_1, D_2, D_3;
        2, 1, 1, 1;
        0, 0, 1, 1;
        3, 0, 0, 1;
        1, 1, 0, 1;
      )
    $
  + for each column, start traversing the column.
    The first one encountered in the column, is the result of the hash function (the shingle selected):
    $ h_1(D_1) = 2, quad h_1(D_2) = 2, quad h_1(D_3) = 2 $


  Another hash function $h_2$:
  + we fix $[0, 2, 3, 1]$:
  + permute the matrix:
    $
      mat(
        , D_1, D_2, D_3;
        0, 0, 1, 1;
        2, 1, 1, 1;
        3, 0, 0, 1;
        1, 1, 0, 1;
      )
    $
  + for each column, start traversing the column.
    The first one encountered in the column, is the result of the hash function (the shingle selected):
    $ h_2(D_1) = 2, quad h_2(D_2) = 0, quad h_2(D_3) = 0 $
]

We could have exactly one hash function for each permutation of shingles, so we have $n!$ possible hash functions.

#warning[
  All the values below the first one of each column are lost.
]

=== Signature Matrix

Storing _some_ hash functions is smaller than storing the whole matrix.
This is called a signature matrix.
$
  mat(
    , D_1, D_2, D_3;
    h_1, 2, 2, 2;
    h_2, 2, 0, 0;
  )
$
We will not be able to restore the whole matrix, we get an approximation.
The more rows of the signature matrix, the more accurate.
We can random sample the permutations to obtain a decent result.

But how many functions?

How do we extract random evenly distributed permutations?
We use another random function $p$.
Having $n$ shingles, $p$:
$ p : {0, ..., n-1} -> {0, ..., n-1} $
If $p$ is a perfect hash, then each bucket will be selected exactly by one shingle.
Reading the buckets in order, we can retrieve the shingle that pointed to that bucket.
That will result in a permutation.

This can be done efficiently using expressons like, selecting random values:
$ p(x) = 4x + 7 mod n $

#note[
  But after selecting the permutation, how can we browse the column and obtain the first one of that column?
  The matrix is too big!
  We can do that with some local queries (more on the book).
]

We can use this signature matrix to calcualte the Jaccard similarity.

We pick two docuiments $S$ and $T$ and we get the shingle returned by applying a random hash function $H$.
We can compare the result and check whether are equal and calculate the probability.
This can be proven that it is exactly the Jaccard similarity:
$ PP(H(S) = H(T)) = J(S, T) $

#warning[
  $H$ is NOT a fixed hash function (with its signature matrix), but a random function (the equivalent of an aleatoric variable).
  $H$ is ALL possible hash functions.

  For each permutation, we have an hash function.
  $ P_1 -> h_1 quad quad h_1(S) = h_1(T) $
  $ P_1 -> h_1 quad quad h_1(S) = h_1(T) $
  $ P_1 -> h_1 quad quad h_1(S) = h_1(T) $
]

#proof[
  Fixed an hash function (a specific realization of random function $Z$), four possible situations exists:
  $
    mat(
      S, T, ;
      0, 0, quad "Z type rows";
      0, 1, quad "Y type rows";
      1, 0, quad "Y type rows";
      1, 1, quad "X type rows";
    )
  $

  The equality is possible only if the first non-Z type row is an X type row:
  $ PP(H(S) = H(T)) = J(S, T) = PP("first non-Z type row is an X-type row") $

  Using basic probabilities (fav cases over total cases):
  $ = "X-type rows" / "non Z-type rows" = x / (x+y) $

  Because we can calculate the size of the union counting the number of rows with at least one $1$ and the intersection the number of rows with both $1$, the we can rewrite the Jaccard similarity as:
  $ x / (x+y) $

  Meaning the two things are equal $qed$.
]

Given a signature matrix, we can estimate the similarity considering ??? over the total number of rows.

#example[
  $
    mat(
      , S, T, U;
      h_1, 3, 3, 6;
      h_2, 2, 0, 2;
      h_3, 4, 4, 8;
    )
  $
  $ hat(J)(S,T) = 2/3 $
  $ hat(J)(S,U) = 1/3 $
]

We solved the space problem, but we still have to handle the computational time.

We need to compute the similarity for each pair of documents.
With $m$ documents, we need to perform $(m(m-1))/2$ or $binom(n, 2)$ comparisons $approx 1/2 m^2$.

If we have $10^6$ documents and we have $250$ min hash functions (rows of the signature matrix), it the end we approximately need $1$ GB to store the signature matrix (OK).

Time complexity would be: $1/2 10^12$.
Considering each comparison taking $10mu s$ (which is far beyond current tech limit), we will end up with $1/2 10^12 10^-6 s approx 5 dot 10^5$ seconds, around 6 days (NOT OK).

#note[
  Even that approach, computes only an approximation of the similarity ($hat(J)$).
]

Instead of doing a bruteforce full search, the idea is to filter only some probable similar pairs, not all one.

== Locality Sensitive Hashing (LSH)

#informally[
  Starting from a view on the overall set of documents, dividing it into several subviews
]

We the signature matrix with $n$ documents ($D_1, ..., D_n$) and $k$ hashing functions.

We will divide that matrix into $b$ *bands*, each containing $r$ rows (with $b r = k$).

For each band, each document will be sent to a bucket.
This bucket is identified by the values of the shangles of that part of the band.

Each document will be sent to $b$ buckets (one for each band).
The idea is to associate multiple documents to the same bucket, thanks to the buckets.

The Jaccard similarity will be run only on all the pairs of documents that end up in the same bucket.

To end up in the same bucket, each document will match at least in one band.
How much is that probable?
$ PP(S "and" T "match in at least one band") $

We can build up that, starting from:
$ PP(S "and" T "match in one row") = s = J(S, T) $

#note[
  We can assume independecy between events (rows) because we use random sampling (the parameters of the linear transformation should be selected randomly).

]

Because of that independence we can compute:
$ PP(S "and" T "match in all row of a band") = s^r $

$ underbrace(PP(S "and" T "match in not not match in at least one row"), = "do not match in one band") = 1 - s^r $

$ PP(S "and" T "match in not not match in all bands") = (1 - s^r)^b $

$ underbrace(PP(S "and" T "match in at least one band"), = S "and" T "are not filtered") = 1 - (1 - s^r)^b = p(s) $

The pairs that does not get filtered will continue the process into finding similar pairs.

The $p$ function has a sigmoid like shape between $0$ and $1$ with $s$ on the $x$ axis.
A sigmoid is a continous relaxation of a treshold.
On that function we could fix a treshold $t$ in an analytic way.

A sigmoid starts with a flat function, then it starts increasing with a certain rate, until it stops increasing and stops increasing.
To fint a decent treshold, we can compute the first derivative and find the steepest point of the function (where it changes steepness) and use that as treshold $t$.
