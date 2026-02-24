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
