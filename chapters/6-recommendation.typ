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

#informally[
  Instead of finding similar user-item pairs based on their content and preferences, the idea is to find _similar users_ and recommend each other the items they interact with.
]

Similar users are found by looking at the _utility matrix_.
Some *preprocessing* is needed to make the matrix more suitable for similarity measures, such as _normalization_ (e.g., subtracting the user's average rating from their ratings to account for different rating habits) and _handling missing values_ (e.g., treating them as zeros or using a thresholding approach).

Different similarity measures can be applied:

- *Jaccard distance*:
  suitable for _binary_ data.
  When the utility matrix is not binary, _thresholding_ can be applied to convert ratings into binary values.

  #example[
    Different users have different _rating habits_: some rate movies with 5 stars, while others use only 1-3 stars.
    By applying a threshold (e.g., considering everything above user average as "liked" and everything below as "not liked"), we can convert the utility matrix into a binary matrix.
  ]

- *Cosine distance*:
  suitable for numerical data, where the _magnitude_ does not matter.
  The cosine distance ignores the positions where both vectors contain $0$ (good for sparse matrices), but we need to define the behavior for missing values (e.g., treating them as zeros).

  #example[
    When vectors represent the number of times a user interacted with items, the cosine distance is appropriate because it captures the similarity in interaction patterns regardless of the absolute number of interactions.

    E.g., a user that interacted 9 times with Sport and 1 time with Politics (vector [9,1]) is identical to a user that interacted 90 times with Sport and 10 times with Politics (vector [90,10]), because the _magnitude_ does not matter.
  ]

If the matrix is too big, it can be difficult to compute the similarity between all pairs of users.

#note[
  Some techniques discussed in Section #link-section(<similarity>) can be used, such as LSH.
  In this chapter we explore different approaches that try to *fill* the utility matrix.
]

=== Clustering

Both users and items can be *clustered* based on their profiles, using any technique.

This approach _aggregates_ and compresses the utility matrix: when two users are merged into a cluster, their corresponding rows in the utility matrix are merged into a single row.
If multiple entries are non-null, we can merge them by taking various approaches (e.g., averaging).

We can _repeat_ this process iteratively (clustering the resulting clusters) until the entire matrix is filled with values.
Then we can simply recommend the _top rated_ item to each user, using the rating of the cluster they belong to.

#note[
  We could cluster both on users and items, producing _different results_.
  Clustering items will produce more defined clusters, while clustering users will produce more fuzzy clusters.

  #example[
    _Items_: a song is typically of one genre (a song cannot be both classical and rock).
    So a cluster of classical and rock songs is very unlikely.

    _Users_: a user can like both rock and classical, so a cluster can exist.
  ]
]

=== $U$-$V$ Decomposition

Another approach tries to find a *latent dimension* to fill the utility matrix.
The gaps in the utility matrix are the ratings we need to _guess_.

To do that, we try to _decompose_ the matrix into two _much smaller_ matrices (that must be product compatible):
$ underbrace(M, r times c) = underbrace(U, r times d) dot underbrace(V, d times c) $

Finding some values of $U$ and $V$ that produce a product _close_ to the original matrix $M$ (for the known entries), we can use that product to fill the missing values of $M$.

To find how _close_ we are to the original matrix $M$, we can use the Root Mean Square Error (*RMSE*):
$ "RMSE"(M, P) = sqrt(1/("# entries") sum_(i,j) (m_(i j) - p_(i j))^2) $
where $M$ is the original utility matrix, $P$ is the product of $U$ and $V$, both $r times c$.

=== Alternating Least Squares Algorithm (ALS)

The ALS algorithm iteratively improves $U$ and $V$ by *optimizing* one element at a time, updating each element to minimize the RMSE.

#informally[
  The key idea: when changing a single element of $U$ or $V$, only a small part of the product matrix $P$ changes.
  We can compute the _optimal value_ for that element by finding where the _derivative_ with respect to that element _equals zero_.
]

/ Initialization:
  We start naively by initializing both $U$ and $V$ with all $1$s, then compute the initial RMSE.

  A better _heuristic_ (not guaranteed to perform well) is to initialize both matrices with $sqrt(overline(m)/d)$, where $overline(m)$ is the average of all known entries.

/ Updating element of $U$: When we change a single element $u_(r s)$ in row $r$ of $U$, only row $r$ of the product matrix $P$ changes.

  #note(title: "Only row " + $r$ + " changes?")[
    In matrix multiplication $P = U dot V$, each element of $P$ is computed as:
    $ p_(i j) = sum_k u_(i k) dot v_(k j) $

    This is the dot product of row $i$ from $U$ with column $j$ from $V$.

    When we change $u_(r s)$, it only appears in products involving row $r$ of $U$, any other row $i != r$, uses a different row of $U$.

    The same applies to columns of $V$: changing $v_(s j)$ only affects products involving column $j$ of $V$.
  ]

  We can find the optimal value $x$ by setting the derivative of the squared error (for that row) to zero:
  $ x = (sum_j (m_(r j) - sum_(k != s) u_(r k) v_(k j)) v_(s j)) / (sum_j v_(s j)^2) $

/ Updating element of $V$: Similarly, when we change a single element $v_(s j)$ in column $j$ of $V$, only column $j$ of $P$ changes.

  The optimal value $y$ is:
  $ y = (sum_i (m_(i j) - sum_(k != s) u_(i k) v_(k j)) u_(i s)) / (sum_i u_(i s)^2) $

/ Iteration:

  There are different strategies to update the elements of $U$ and $V$:
  - Alternating between an element of $U$ and an element of $V$.
  - Updating all elements of $U$ first, then all elements of $V$.
  - Updating elements in a random order.

  We stop when the RMSE between $P$ and $M$ is "small enough" or shows negligible improvement.

#warning[
  This is a *local optimization*: we may get stuck in a local minimum instead of finding the global optimum.
  To mitigate this, we can:
  - Run the algorithm multiple times with different random initializations and average the results
  - Add noise to the initialization to escape shallow local minima
  - Use different update strategies
]
