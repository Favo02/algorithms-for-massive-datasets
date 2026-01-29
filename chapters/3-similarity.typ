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

#warning[
  This is an approximation algorithm, it returns an approximate solution:
  - False Positive (FP): a pair that passes the LSH filter but is not similar
  - False Negative (FN): similar documents that does not pass LSH

  False Positives are not a big problem, the pairs that passes the filter are then processed anyway, we their similarity will be calculated in any case.
]

We need to fix a *treshold* over which the pairs are similar and below that are discarded.
We can leverage the shape of the function $p$ to change this treshold.

The $p$ function has a sigmoid like shape between $0$ and $1$ with $s$ on the $x$ axis.
A sigmoid is a continous relaxation of a treshold.
On that function we could fix a treshold $t$ in an analytic way.

A sigmoid starts with a flat function, then it starts increasing with a certain rate, until it stops increasing and stops increasing.
To fint a decent treshold, we can compute the first derivative and find the steepest point of the function (where it changes steepness) and use that as treshold $t$.

$ ... $

Plotting out the first derivative we get a bell.
To find the maximum of that we calculate the second derivative and nullify it.
$
  (r-1) s^(r-2) (1-s^r) = (b-1) r s^(2r ) \
  (r-1)/r = (s^r)/(1-s^r) (b-1)
$

The root of that are very complex, we consider an approximation.
$ s^* = (1/b)^(1/r) $

$ (r-1)/r = (1/b)/(1-(1/b)) (b-1) $

So we can fix a similarity treshold $t$ (the maximul of the first derivative):
$ t = (1/b)^(1/r) $

We need to fix the parameters of LSH $b$ and $r$ so that the treshold is equal to $t$ (keeping the constrait that $b r = n$)

#informally[
  Recap:
  - we start from documents
  - preprocess: whatever (we strip out stop words, ...)
  - we decide the shingles
  - based on that we decide $k$ for $k$-grams
  - we create the signature matrix, choosing $n$ (the number of hash functions or rows of the matrix)
  - we decide the parameters $b$ and $r$ so that we have the best treshold $t$
  - we apply LSH with $b$ adn $r$
  - some documents will pass LSH (with treshold $t$), some not
  - compute the similarity of documents that passed LSH
]

What happens if the document is not a string? E.g. a vector of values.

The encoding in terms of set and the Jaccard similarity could not be efficient anymore.
We need to *abstract* the process.

== Generalized Process

Given pairs of encoded documents, we want to calculate their similarity.
Instead of similarity, we can think of *distance* (similar objects are close).
The distance functions takes a pair and returns a value:
$ d : X times X -> RR $
Where some properties are verified:
+ $forall x, y in X, quad d(x, y) >= 0, quad d(x, y) = 0 space <--> space x = y$
+ commutativity: $forall x, y in X, quad d(x, y) = d(y, x)$
+ triangle inequaltiy: $forall x, y, z in X, quad d(x, y) <= d(x, z) + d(z, y)$

Distances that work on vectors of real numbers of size $d$: $X = RR^d$.
These distances are called $L_p$-distances
$ d(x, y) = (sum_(i=1)^d |x_i - y_i|^p)^(1/p) $
- Manhattan distance ($p = 1$)
- Euclidian distance ($p = 2$)

#note[
  Proving the three properties for these is pretty trivial.
]

// TODO: what are L_p distances? What have to do with the Contour plot?

Another distance: Jaccard distance // TODO: what is that used for?
$ d(A, B) = 1 - J(A, B) $

#note[
  Proving the first two properties is pretty easy.
  The triangle disequality is a bit tricky.

  #proof[
    Because of how the similarity is defined, we can rewrite the distance as:
    $ d(A, B) = PP(H(A) != H(B)) $
    We can intoduce a thrid element $C$:
    $ H(A) != H(B) --> H(A) != H(C) or H(B) != H(C) $

    #note[
      Two trivial probability properties:
      - $A --> B$ means $PP(A) <= PP(B)$
      - $PP(A union B) <= P(A) + P(B)$
    ]

    $
      PP(H(A) != H(B)) <= PP(H(A) != H(C) union H(B) != H(C)) \
      PP(H(A) != H(B)) <= PP(H(A) != H(C)) + PP(H(B) != H(C))
    $
  ]
]

Distance taht can be used on vectors with common origin (directions on the space): *Cosine* distance.
Given two vectors $x$ and $y$ with angle $theta$:
$ d(x, y) = theta_(x y) = arccos (x y)/(||x|| ||y||) $

#note[
  Two vectors with the same direction but different magnitude are considered the same vector.
]

#informally[
  A simple trick to check if a space is Euclidian is to check if the midpoint between two elements is a point of the space.

  E.g. Strings.
]

For strings: Lehvehnstein distance.
Repeatedly apply one of the operations:
- adding character
- modifying character
- deleting character
the distance is the minimum numner of operations to get from one string to another.

For binary words with same length: Hamming distance:
Number of positions with different bits between two binary words.

#note[
  Hamming distance can be generalized over any alphabet e.g. "sad" vs "sun" would give distance $2$.
]

== LSH with Generic Distance

The LSH method divided documents into bands and then two documents were similar if two document shared the same band, with probability:
$ PP(f(x) = f(y)) $

We needed a family of min hash functions for that end.

We define a property that we would like for our families of hash function.\
The family $cal(F)$ is $(d_1, d_2, p_1, p_2)$-sensitive if (where $d_1, d_2$ refer to distances and $p_1, p_2$ refer to probabilities):
$
  forall f in cal(F), quad forall x, y in X, \
  d(x, y) <= d_1 --> PP(f(x) = f(y)) >= p_1 \
  d(x, y) >= d_2 --> PP(f(x) = f(y)) <= p_2
$

#note[
  We talk of probability because we have some randomness in the family.
]

#example[
  $cal(F)$: min hash, $d$: Jaccard
  $
    d(x, y) <= d_1 --> 1- J(x, y) <= d_1 \
    J(x, y) >= 1- d_1 --> PP(h(x) = h(y)) >= underbrace(1 - d_1, = p_1)
  $
  with $h$ being one random hash function from the family.

  This proves that this follows the property.
]

=== $"AND"$-Construction

Given a $cal(F)$, we want to get an $cal(F)_"and"$ that is better in terms of $(d_1, d_2, p_1, p_2)$

#note[
  $cal(F)$ can be both finite and infinite
]

$ cal(F) = {f_1, f_2, ...} $
Propertly elaborating the functions in $cal(F)$ we can get to a $cal(F)_"and"$ family.
We want to extract $r in NN$ functions from $cal(F)$ (not in order):
$ f' in cal(F)_"and" -> f' = (f_1 in cal(F), ..., f_r in cal(F)) $

We are only interested in $PP(f(x) = f(y))$:
$ (f'(x) = f'(y)) <--> forall j in [1, r] f_(i j)(x) = f_(i j)(y) $

Why do we do this?
We have $cal(F)$ that enjoys the property, but we are not satisfied by the values of $p_1, p_2$.

$
  PP(f'(x) = f'(y)) = PP(inter.big_(j=1)^r {f_(i j)(x) = f_(i j)(y)}) = product_(j=1)^r underbrace(PP(f_(i j)(x) = f_(i j)(y)), >= p_1) >= p_1
$

...

$ d(x, y) <= d_1 --> PP(f'(x) = f'(y)) >= p_1^r $
$ d(x, y) >= d_2 --> PP(f'(x) = f'(y)) <= p_2^r $

...

$ f'(x) = f'(y) <--> exists j = 1, r f_(i j)(x) = f_(i j)(y) $
$
  forall j quad d(x, y) <= d_1 --> & PP(f_(i j)(x) = f_(i j)(y)) >= p_1 \
                                   & PP(f_(i j)(x) != f_(i j)(y)) <= 1 - p_1
$

$ PP(forall j space { f_(i j)(x) != f_(i j)(y)}) = product_(j = 1)^r PP(f_(i j) f(x) != f_(i j)(y)) $

So:
$
    d(x, y) <= d_1, \
  PP(f'(x) = f'(y)) & = PP(exists j f_(i j)(x) = f_(i j)(y)) \
                    & = 1 - PP(forall j f_(i j)(x) != f_(i j)(y)) \
                    & >= 1 - ( 1- p_1)^r
$

The analogous thing can be done with the other parts of the property (with $d_2$ and $p_2$).

#informally[
  Recap: if $x$ and $y$ are similar (less than $d_1$), using my original family o function I woul have that the prob that selecting them was higher tha $p_1$.
  Now using the extended family, the probabolity of selecting them is $1 - ( 1- p_1)^r$.

  We can increase the probability at the cost of increasing also the other treshold.
]



---

// what jack's brain has accomplished

== Recap: LSH and the "S-Curve"
We were talking about the similarity pipeline for massive datasets. The main goal is to avoid the $O(n^2)$ complexity of comparing every single pair of documents.

In particular, we focused on the probability that a pair of documents $(S, t)$ end up in the same bucket. If we use $b$ bands and $r$ rows per band, the probability $p(s)$ that two docs with Jaccard similarity $s$ match in at least one band is:

$ P(S, T "match at least in one band") = 1 - (1 - s^r)^b = p(s) $

This function gives us the *sigmoid graph* (the S-curve).
- *FP (False Positives):* non-similar docs that pass LSH.
- *FN (False Negatives):* similar docs that don't pass LSH.

=== Finding the Threshold
If we take the derivative of the sigmoid graph, we obtain a *bell-shaped curve*. To find the exact maximum point (the "steepest" part of the S-curve), we should technically look at the second derivative, but for our purposes, an approximation $s^*$ is enough.

We can fix a similarity threshold $t$ as:
$ t approx (1/b)^(1/r) $

Now, if we want to ensure that our $s^*$ is equal to a specific threshold we fixed (we only care about docs with Jaccard $> t o t$), we need to select $b$ and $r$ carefully. Since we also know that $b dot r = n$ (where $n$ is the number of rows in the signature matrix), we just solve a system of two equations in two unknowns ($b$ and $r$).

== Review of the Overall Process
1. *Shingling:* Start from the document, strip stop-words, and decide the $k$-shingles size depending on the category of docs.
2. *Min-Hashing:* Create the signature matrix, deciding how many rows $n$ to use.
3. *Parameters:* Fix the threshold $t$ and solve the system to get optimal values for $b$ and $r$.
4. *LSH:* Divide the matrix into $b$ bands and apply hashing.
5. *Verification:* For each candidate pair, compute the actual Jaccard similarity and eliminate pairs that don't surpass $t$.

== Distances
What happens when the documents are not strings? For example, if we use a table to avoid duplicated records, the document is basically a vector. Jaccard might not be applicable here.

We need to measure the degree of similarity using *distances*. Distance is the dual of similarity:
- Similarity is big $arrow$ Distance is small.
- Similarity is small $arrow$ Distance is big.

A function $d(x, y)$ is a distance if it satisfies:
- *Positivity:* $d(x, y) >= 0$ and $d(x, y) = 0$ iff $x = y$.
- *Symmetry:* $d(x, y) = d(y, x)$.
- *Triangle Inequality:* $d(x, y) <= d(x, z) + d(z, y)$.

=== Typical Distances
1. *Euclidean Distance ($L_2$):* The length of the segment joining two points in $RR^d$. It's part of the $L_p$ family:
   $ d(x, y) = (sum_{i=1}^d |x_i - y_i|^p)^(1/p) $
   *Note:* If $p=1$ we get the *Manhattan distance*. If we plot $d(x,y)=1$ for $p=2$ we get a circle; for Manhattan, we get a square.



2. *Jaccard Distance:* Defined as $1 - "Jaccard Similarity"$.
   *Triangle inequality proof:* Recall $J(A, B) = P(h(A) = h(B))$, so $d(A, B) = P(h(A) != h(B))$. If $h(A) != h(B)$, then for any third set $C$, $h(C)$ must be different from either $h(A)$ or $h(B)$. In terms of probability:
   $ P(h(A) != h(B)) <= P(h(A) != h(C) " or " h(B) != h(C)) <= d(A, C) + d(B, C) $

3. *Cosine Distance:* Objects are vectors starting from a common origin (directions).
   $ d(x, y) = theta = arccos((x dot y) / (||x|| dot ||y||)) $
   It's basically the angle between vectors.

4. *Edit Distance (Levenshtein):* Minimum number of atomic operations (add, delete, modify char) to transform string $s$ into $t$.

5. *Hamming Distance:* Number of positions in which bits (or chars) differ.
   Example: `11010` and `10110` have distance 2.

== Formalizing LSH Families
Can we extend LSH to these distances? We need to speak about probabilities of events because the algorithm is random.

A family of functions $F$ is *$(d_1, d_2, p_1, p_2)$-sensitive* if:
- If $d(x, y) <= d_1$, then $P(f(x) = f(y)) >= p_1$ (Close things likely collide).
- If $d(x, y) >= d_2$, then $P(f(x) = f(y)) <= p_2$ (Far things unlikely collide).

We can amplify these properties:
- *AND Construction:* $f'(x) = f'(y)$ iff all $r$ functions match. It makes the probability $p^r$.
- *OR Construction:* Use bands to make it $1 - (1 - p)^b$.

 trying to use "OR" rather than "AND" to see how the probability changes... (need to finish this part)





