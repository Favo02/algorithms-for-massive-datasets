#import "../template.typ": *

= Recommendation Systems
Recommendation systems aim to suggest items to users based on their predicted interests, maximizing the likelihood of user interest.

#example[
  In a bookstore, we receive _non-personalized_ recommendations: typically the trending books.

  On Amazon, recommendations work differently.
  Most of the time, we receive recommendations for things we are actually interested in.

  #note[
    The effort devoted to strong recommendation systems is driven by the _long tail principle_: it is more profitable to sell less popular books than the most trending ones.

    The reason is straightforward: there are only a few trending books, while there are many less popular ones.
    A user might not be interested in any of the trending books and therefore would not purchase anything.
    However, recommending an unknown book that reflects the user's actual interests increases the chances of making a sale.
  ]
]


The two main entities of these systems are *users* and *items*.
The items will be recommended to users.

Two big approaches to recommendation systems exist:
- *Content-based approach*: Suggestions based on the *actual content*.
  Users get recommendations based on their explicit interest.
  We need to know both the *interest* of a user and a *description* of each item.
- *Collaborative filtering approach*: The system does *not know anything* on the content of items or interests of a user.
  Recommendations are based on the *similarity* between users.
  A user gets recommended the items a similar user interacted with.

#example[
  *Content-based:* A user who rates highly romantic comedies receives recommendations for other romantic comedies with similar actors, directors, or themes.

  *Collaborative filtering:* Two users who both rated the same 10 movies similarly get recommended movies that one user watched but the other hasn't seen yet.
]

== Utility Matrix

We start with some known degree of preference of some users on some items, in other words _how much a user is interested in an item_.
This relationship is represented by the *utility matrix*.

The entries of the matrix could be binary (like / don't like), an integer scale (e.g. 1-5) or a rating.

#warning[
  Most of the entries of that matrix are *empty*, the preference is *unknown*.
  This matrix is *sparse*.
]

The goal of the system is to *predict* the *missing values* of that matrix.

#note[
  Most of the times, it could _not_ be necessary to fill the _whole matrix_, but to find only some entries that are likely high and recommend these ones.
]

Without that matrix, recommendations are almost impossible.
Again, two main approaches to *populate* that matrix exist:
- Ask explicitly users to *rate items* (e.g. rating a movie), better quality (the rating has a scale) but less effective as not all users do that.
- Make *inference* from users' interactions (e.g. movies the user clicked on or watched the trailer), less quality (the value is boolean) but applicable to all users.

== Content-based Approach

We need to build a profile for both *items* and *users*.
These profiles can be defined as vectors, so that the *cosine similarity* between the user's vector and the item's profile is the degree of interest.

#note[
  Similarity techniques, such as LSH, can be used to find similar profiles and perform suggestion.
]

#note[
  Beyond those classical ways to calculate recommendations based on the content of something, we can leverage standard _machine learning_ techniques.

  We will not discuss that, but it is entirely viable.
]

=== Building Items Profile

Most of the times, items have intrinsic *boolean* properties that can be used for recommendations.

#example[
  Movies can be represented by a huge vector of all actors, where each entry is binary, describing if an actor appeared in that movie.
  The same thing can be done for directors.
]

Another class of features are the *numerical* characteristics.
It is completely fine to put these in the vector, but these numerical values need to be *scaled* so neither the boolean nor the numerical features dominate.
The scaling factor depends on the context and the semantics of the numerical value.

#example[
  Vector of a movie, with different characteristics:
  $
    [ underbrace(0\, 1\, 1\, 0\, ...\, 1\, 0, "actors"), underbrace(0\, 1\, 0\, 0\, ...\, 0\, 0\, 0, "director"), underbrace(4.6 alpha, "avg rating") ]
  $
  with $alpha$ the scaling factor for the numerical component.

  #note[
    The cosine distance ignores the positions where both vectors contain $0$.
  ]
]

=== Extracting Features from Documents: TF.IDF

Extracting features from movies or books is easy: actors, genre, etc.
What about documents?

An idea could be to identify a document by its *most significant words*, the rarest words.
First, we eliminate *stop words*: the most common words (e.g. "and", "or", "the"), which carry no topical information.
For the remaining words, we need to differentiate between rare _meaningless_ words (like "notwithstanding") and rare _meaningful_ words.
The observation is that rare meaningful words are likely to appear multiple times in the same document, while rare _meaningless_ word not.

#example[
  Both _albeit_ and _offside_ are rare words.

  If _albeit_ is used in a document, it is not more probable that it is used again.
  The opposite, if _offside_ is used in a document, it is more likely that it is used again.

  This means _albeit_ is meaningless, while _offside_ is meaningful.
]

This measure can be computed using *Term Frequency times Inverse Document Frequency (TF.IDF)* index for each word, defined as:
$ "TF"_(i j) dot "IDF"_i $

where:
- $N$: number of documents
- $n_i$: the number of documents in which word $i$ appears
- $f_(i j)$: the absolute frequency of the word $i$ in document $j$
- $"TF"_(i j)$: the frequency of a word $i$ divided by the frequency of the most frequent term:
  $ "TF"_(i j) = f_(i j) / (max_k f_(k j)) $
- $"IDF"_i$:
  $ "IDF"_i = log_(2) N/(n_i) $

Taking the words with highest TF.IDF score would be a good tagging mechanism.

=== Building User Profiles

We also need vectors describing users.
It is not trivial to extract the features of the items also for the users.

One way to achieve that is to *correlate* the data from the utility matrix with the item profile.
This technique heavily depends on the context and the semantics.

#example[
  If all the information we have for a user is which movie he clicked on (*boolean*), then we can populate its profile putting at $1$ all the actors that play in any movie he clicked on.
]

#example[
  If we have ratings data, we can build a user profile by computing each actor's influence on the user's preferences.

  First, normalize ratings by computing the user's average rating. Ratings above average indicate liked movies; ratings below indicate disliked movies.

  Then, for each actor, compute their average influence: the mean difference between their movies' ratings and the global average. Positive values indicate the actor positively influences this user's preferences.

  Example:
  User ratings: $[5, 4, 3, 2, 1]$ with average $3$.

  Julia Roberts presence: $[1, 1, 1, 0, 0]$:
  $ "JR influence" = ((5-3) + (4-3) + (3-3)) / 3 = +1 $

  Mario Rossi presence: $[0, 0, 0, 1, 1]$:
  $ "MR influence" = ((2-3) + (1-3)) / 2 = -1 $

  These influence values become entries in the user's profile vector.
  Finally, computing the similarity between a user and a movie using cosine distance:

  - Film A (actors): $[1, 1, 0, 1, 0]$
  - Film B (actors): $[0, 0, 1, 1, 0]$
  - Film C (actors): $[0, 1, 0, 0, 1]$
  - User profile (actor influence): $[+0.3, -0.2, 0, +0.3, -2.1]$

  Calculating cosine similarity:
  - Film A: mostly positive components, large positive value, small angle, high interest.
  - Film B: mix of liked and disliked actors, value close to zero, \~90° angle, moderate interest.
  - Film C: mostly negative components, large negative value, large angle (\~180°), low interest.
]

#example(title: "Complete Example: Movie Recommendations")[
  We want to recommend a new movie to a user based on their past ratings.

  + *Item Profiles:*
    Movies are represented by features: actors (A, B, C) and a numerical feature (average global rating).
    Numerical features must be scaled by a factor $alpha$ so they don't dominate the boolean features. Let $alpha = 0.5$.
    - *Movie 1* (Actors A, B; Avg Rating 4.0): $v_1 = [1, 1, 0, quad 4.0 dot 0.5] = [1, 1, 0, quad 2.0]$
    - *Movie 2* (Actors B, C; Avg Rating 2.0): $v_2 = [0, 1, 1, quad 2.0 dot 0.5] = [0, 1, 1, quad 1.0]$
    - *Movie 3* (Actor A; Avg Rating 4.0) [New]: $v_3 = [1, 0, 0, quad 4.0 dot 0.5] = [1, 0, 0, quad 2.0]$

  + *User Profile:*
    The user rated Movie 1 with $5$ stars and Movie 2 with $2$ stars.
    First, we normalize the user's ratings by subtracting their average rating to create negative weights for disliked items and positive weights for liked ones:
    $ "User Avg" = (5 + 2) / 2 = 3.5 $
    $ "Normalized" M_1 = 5 - 3.5 = +1.5 $
    $ "Normalized" M_2 = 2 - 3.5 = -1.5 $

    Next, we build the user profile by averaging the normalized ratings for each actor.
    #note[
      We omit the numerical "Avg Rating" here, as aggregating continuous features for a user profile requires a different binning strategy.
    ]
    $
      "influence"(A) & = (+1.5) / 1 = +1.5 quad    &   #comment[Only in M1] \
      "influence"(B) & = (+1.5 - 1.5) / 2 = 0 quad & #comment[In M1 and M2] \
      "influence"(C) & = (-1.5) / 1 = -1.5 quad    &   #comment[Only in M2]
    $
    User Profile: $u = [1.5, 0, -1.5]$

  + *Recommendation via Cosine Similarity:*
    We compare the User Profile $u$ to the actor profile of the new Movie 3 ($v_3' = [1, 0, 0]$):
    $
      cos(theta) = (u dot v_3') / (||u|| ||v_3'||) = (1.5 dot 1 + 0 dot 0 + (-1.5) dot 0) / (sqrt(1.5^2 + 0^2 + (-1.5)^2) dot sqrt(1^2))
    $
    $ cos(theta) = 1.5 / (sqrt(4.5) dot 1) = 1.5 / 2.12 approx 0.707 $

    A large positive cosine fraction (angle $approx 45 degree$) indicates a small cosine distance. Movie 3 is a *good recommendation* because it features an actor the user strongly likes, and none that they dislike.
]

#example(title: "Complete Example: Document Recommendations")[
  For documents (like news articles), items are represented by vectors of their highest TF.IDF words.

  + *Item Profiles:*
    Suppose our feature vocabulary is `[election, football, budget, stadium]`.
    - *Article 1* (read): $v_1 = [1, 0, 1, 0]$
    - *Article 2* (read): $v_2 = [0, 1, 0, 1]$
    - *Article 3* (new): $v_3 = [1, 0, 0, 0]$

  + *User Profile:*
    If the utility matrix contains only 1s (representing a "read" or "click" behavior), the user profile is simply the aggregate average of the profiles of the items they interacted with.
    $ u = (v_1 + v_2) / 2 = ([1, 0, 1, 0] + [0, 1, 0, 1]) / 2 = [0.5, 0.5, 0.5, 0.5] $

  + *Recommendation via Cosine Similarity:*
    We compute the cosine similarity between the user profile $u$ and the new Article 3 $v_3$:
    $
      cos(theta) = (u dot v_3) / (||u|| ||v_3||) = (0.5 dot 1 + 0 + 0 + 0) / (sqrt(0.5^2 times 4) dot 1) = 0.5 / 1.0 = 0.5
    $

    The positive cosine score indicates a topical overlap (the word "election"), meaning this article is relevant enough to surface to the user.
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
