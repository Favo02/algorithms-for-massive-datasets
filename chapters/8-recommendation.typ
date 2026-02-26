#import "../template.typ": *

= Recommendation

Recommend products to users.

In a book store, if we the store owner does not know us, we get a "random" recommendation: likely the trending one.

On amazon, it works in a different way.
The long tail principle works there: it is more remunerative to sell the less-selling books that the most trending one.
That's because the low selling books are much much more that the few high selling books.

== Utility Matrix

The entry is a number that represent how much is a user interested on an item.
This matrix is of course much sparse.

Two big approaches:
- content-based approach: suggestions based on the content, we need descriptions of each items
- collaborative-based filtering approach: finding out similar users, without any idea on the content of the items, so that we can recommend the things bought by one user to the other

== Content-based Approach

We need to build a profile for both items and users.
The idea is that both profiles are a vector, so the closeness of a vector of a user with the vector of an item suggests interest on that item.

#example[
  A huge vector for identifying movies: binary vector for which users are in that movie.
]

But to avoid huge vectors, we save only the relevant information.

/ TF.IDF: composed of two factors // TODO: what is that semantically?
  $ "TF"_(i j) dot "IDF"_i $

/ TF:
  $ f_(i j) = "absolute frequency of word " i "in document" j $
  $ "TF"_(i j) = f_(i j) / (max_k f_(k j)) $

/ Inverse document frequency IDF:
  $ "IDF"_i = log_2 (N)/n_i $
  where $N$ = number of documents and $n_i$ = number of documents containing $i$

To understand what a user likes, we take all its votes and compute the average.
Then, everything above is liked, everything below is not liked.

We can correlate these values with the some binary attribute.

#example[
  Rating for Movies: $5, 4, 3, 2, 1$
  Presence of Julia Robets: $1,1,1,0,0$

  Average rating: $3$, everything above $3$ is liked by the user.
  We take the difference between the score of a movie with JR and the average.
  If that number is $>0$ then JR influences positively the films the user likes.

  $ ((5-3) + (4-3) + (3-3)) / 3 = 1 $
  Julia robets has a score $>1$, specifically $1$.

  We can compute that for all the actors of a film and sum it up.
  That determines wheter the user will like that movie or not.
]

#note[
  Beyond that classical ways to calculate recommendations based on the content of something, we can leverage the content using standard machine learning techniques.

  We will not discuss that, but it is entirely viable.
]

== Collaborative Filtering

We describe a user based on the ratings he espressed: a row of the matrix.

Similarly, a column, so the ratings of users to a product can describe the product.

Finding similar users means finding similar rows in that matrix.
We can try using different similarity measures:

- Jaccard distance:
  how do we turn a row of ratings (that can contain some null values) into a set?
  We can construct a set of only the movies that are rated (ignoring the actual rating).
  This is not a really good idea exactly because of that, we can have users really similar that rated the same movies, but in a completely different way, so we discart that idea.
- Cosine distance:
  how do we compute the distance for values that are null? we can treat that as zeros.

We have no definitive recipe, there are a lot of variables:
- some user might use a different scale (be more tight on the ratings or more relaxed), users have different rating abits
- we need to tweak the missing values

So, instead of doing similarity on ratings, we apply a tresholding approach.
All values equal or above the treshold become $1$, all the others $0$.
After that, we can simply use similarity like Jaccard to compute the similarity.

Another approach that keeps in mind the fact that users can have different rating habits.
All ther rating of a user gets "normalized" based on the average ratings of that user.

=== Actual Recommendation

What we do once we know that two things are very similar?
Too similar can be negative: we don't want to buy two things that are very very similar.

So, how do we actually perform recommendation?

...

Similarity can be difficult because the rows are very very sparse.
So we apply before a clustering process.

After clustering, we can obtain a "compressed" matrix.
We can decide the dimension on which to cluster (it can be very different).

#example[
  A song is tipycally of one genre (a song cannot be both classical and rock).
  So a cluster of classical and rock songs is very unlikely.

  But a user can like both rock and classical, so a cluster can exist.
]

But how do we get back to recommendantion to a specific user after applying similarity on the compressed matrix?

...

== Alternating List Squares Algorithm (ALS) - $U$-$V$ Decomposition

We have an utility matrix $M$, with some gaps, which are the recommendations we need to perform.

Instead of directly associating a movie to a user, we try to find some latent dimension, for example the genre.
Then we can use that latent dimension to perform suggestions.

To do that, we try to "decompose" the matrix into two smaller matrices (that must be product compatible):
$ underbrace(M, r times c) = underbrace(U, r times d) dot underbrace(V, d times c) $

If we can find, even approximately, the entries of $U$ and $V$, then we can calculate the actual product and find the missing values of $M$.

We need to calculate the distance between two matrices, to understan how the product of the two smaller matrices is similar to the actual matrix $M$.
$ "RMSE"(M, P) = sqrt(mr(1/(r c)) sum_(i,j) (u_(i k) - p_(i j))^2) $

Instead of $1/(r c)$, we should put the number of known entries, and we iterate only over known entries.

But how do we come up with $U$ and $V$?

- We start naively: $U$ and $V$ are initally both formed by all $1$s.
  Then calculate the RMSE.

- Then we select and element of the first matrix $U$, and replace $1$ with a value $x$ that brings the value of the product matrix closer to the actual matrix $M$.

  Changing a value of the first row of $U$, changes the values only of the first row of the product $M'$.
  To minimize the RMSE, we can compute only the part that changes and calculate the first derivative.
  Then we choose that value for $x$.

- Changing a value of the second matrix $V$, only a column of the product matrix changes.
  We repeat the same thing, we nullify the first derivative and find the best new value.

We can generalize that process of changing values of $u$ or $v$:
$ underbrace(U, n times d) dot underbrace(V, d times m) = underbrace(P, n times m) $
$ P_(r j) = sum_(w=1)^d u_(r k) v_(k j) = sum_(k != s) u_(r k) v_(k j) + u_(r s) v_(s j) $

We want to minimize the difference with the original matrix:
$
  Delta(x) = sum_j (m_(r j) - p_(r j))^2 \
  Delta'(x) = sum_j - cancel(2) (m_(r j) sum_(u != s) u_(r k) v_(k j) - x v_(s j)) v_(s j) = 0
$
...

So an element of the matrix $U$ can be changed with $x$:
$ x = (sum_j (m_(r j) - sum_(k != s) u_(r k) v_(k j)) v_(s j)) / (sum_j v_(s j)^2) $

Same thing for $V$ and $y$:
$ y = (sum_i (u_(i r)(m_(i s) - sum_(k != r) u_(i k) v_(k s)))) / (sum_i u_(i r)^2) $

A small improvement: instead of starting with matrices of all $1$s, we start with all $sqrt(overline(m)/d)$.
This is an heuristic, it is not guaranteed to perform well.

We have all elements, and we can start optimizing the values of $U$ and $V$, various approach are possible:
- update all values of $U$ and then all values of $V$
- pick a random matrix and pick a random column/row and update that

We stop when the difference between the product matrix and the original matrix is "small enough" (or we get stuck).
This is another local optimization, we could get stuck, to avoid that we could apply different techniques:
- start all over again, with a different intialization (and some noise)
- run the algorithm several times and use an average as the result
