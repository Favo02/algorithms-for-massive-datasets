#import "../template.typ": *

= Dimensionality Reduction & PCA

#rect(stroke: 2pt + red, fill: red.transparentize(70%))[
  #todo

  Contribute to open #link("https://github.com/Favo02/algorithms-for-massive-datasets/pull/16")[pull request \#16] approving or improving this chapter.
]

When dealing with data having a lot of dimensions, we often want to reduce them.
Dimensionality reduction maps data from a high-dimensional Data Space $RR^d$ to a lower-dimensional Feature Space $RR^(d')$.

$ underbrace(n in RR^d, "Data Space") ~~> underbrace(y in RR^d', "Feature Space"), quad d' << d $

This reduction can be done using simple *projection* approaches: finding relevant dimensions and simply ignoring irrelevant ones.
However, true dimensionality reduction often uses a different approach: *Feature Engineering*, where new features are built as linear combinations of the original ones.

The most standard feature engineering approach to achieve this is *Principal Component Analysis (PCA)*.

== The Variance-Covariance Matrix

Let's assume we have a dataset with $n$ elements, where each data point is a row vector in $RR^d$. We stack these row vectors vertically to create an $n times d$ matrix $M$:

$
  underbrace(M, n times d) = mat(
    (x^1)^T;
    (x^2)^T;
    dots.v;
    (x^n)^T
  )
$

We compute the variance-covariance matrix by multiplying $M^T M$, which results in a $d times d$ square matrix. The element at position $(i,j)$ represents the covariance between feature $i$ and feature $j$:

$ underbrace(M^T M, d times d) = [ sum_(k=1)^n x_k^i x_k^j ]_(i j) $

== The Principal Eigenvector & Geometric Meaning

Since $M^T M$ is a symmetric square matrix, we can compute its eigenvectors ($e$) and eigenvalues ($lambda$). Let's assume we sorted the eigenvalues so that $lambda_1$ is the greatest. Let's focus on the principal eigenvector $e_1$:

$ M^T M e_1 = lambda_1 e_1 $

#note[
  *Geometric meaning:* Imagine your data is scattered roughly along a 45-degree line in a 2D space.
  The principal eigenvector $e_1$ identifies the specific *dimension* (direction) in that space that *maximizes the variance* of your projected data (i.e., it minimizes the distances between each original point and the new axis we are considering).

  Outside of this primary direction, the variance is very small and can often be treated as noise. We can then *remove* the dimensions orthogonal to this primary dimension. By describing the data purely along this simple direction, we successfully compress the dimensionality of our space.

]

== The Power Method

How do we efficiently find this principal eigenvector starting from the data points when dealing with Big Data? In PageRank, we calculated the principal eigenvalue with big data, but we had the mathematical constraint that the largest eigenvalue was exactly $lambda_1 = 1$.

Here, we have no such guarantee. *But we don't care.* Why? Because in PCA, we only care about finding the *direction* (the eigenvector $e$), not the exact eigenvalue $lambda$.

We use an iterative numerical algorithm called the *Power Method*:

```pseudocode
 Initialize a random non-zero vector $v_0$
 Set $t = 0$
 while not converged:
   $v_(t+1) = M^T M v_t$
   $v_(t+1) = v_(t+1) \/ norm(v_(t+1))$
   $t = t + 1$
```

This process guarantees convergence to the principal eigenvector $e_1$.

== Matrix Deflation (Finding Subsequent Eigenvectors)

#informally[
  Once we have found the first pair $(lambda_1,e_1)$, how do we find the second highest eigenvalue and its eigenvector?
]

We use a mathematical trick called Matrix Deflation. We construct a new matrix $A^*$:

$ A^* = M^T M - lambda_1 e_1 e_1^T $

Let's prove why this works. What happens if we multiply $A^*$ by our first eigenvector $e_1$?

$ A^* e_1 & = (M^T M - lambda_1 e_1 e_1^T) e_1 & = M^T M e_1 - lambda_1 (e_1 e_1^T) e_1 $

Because matrix multiplication is associative, we can rewrite $(e_1 e_1^T)e_1$ as $e_1(e_1^T e_1)$. Since $e_1$ is a normalized unit vector, its squared norm is 1 $(e_1^T e_1=1)$.

Furthermore, we know $M^T M e_1 = lambda_1 e_1$.

$ A^* e_1 = lambda_1 e_1 - lambda_1 e_1 (1) = 0 $

The result is the null vector.
This means $e_1$ has been "deflated" and is now associated with an eigenvalue of 0 in the new matrix.

What happens if we multiply $A^*$ by any other eigenvector $e_i$ (where i>1)?

$ A^* e_i = M^T M e_i - lambda_1 e_1 (e_1^T e_i) $

#note[
  The eigenvectors of a symmetric matrix are always orthogonal to each other, so their dot product is zero $(e_1^T e_i=0)$.
]

$ A^* e_i = lambda_i e_i - 0 = lambda_i e_i $

This proves that $e_i$ is still an eigenvector of $A^*$, with its original eigenvalue $lambda_i$. Because $lambda_1$ has been reduced to 0, the new highest eigenvalue in $A^*$ is now $lambda_2$.

#note[
  To find it, we simply apply the Power Method again on $A^*$.
  We can repeat this procedure iteratively to find the third biggest, the fourth, and so on.
]

== Extracting the Parameters: The Rotation Matrix

By repeating the deflation and power method, we can extract the top $m$ parameters: the principal eigenvectors $e_1,e_2,...,e_m$.

If we want to reduce our massive dataset down to a m-dimensional space, we stack all these eigenvectors in a matrix to build a projection matrix $E_m$:

$ E_m = [e_1 | e_2 | ... | e_m] $

#note[
  This is a $d times m$ matrix, often called the Rotation Matrix. It applies a linear transformation that rotates the original data points so that we can easily discard the last components.
]

To compress the entire dataset matrix $M$ (which is $N times d$) into a new reduced matrix $Y$ (which is $N times m$), we simply compute the matrix product:

$ Y = M dot E_m $

== Non-Linear Dimensionality Reduction: t-SNE

PCA is fast and deterministic but it is a *linear transformation*.
It tends to map distant (dissimilar) points into distant low-dimensional representations, but it does not guarantee that points which are close in the high-dimensional data space will remain close in the map space.

To solve this, we use t-SNE (t-distributed Stochastic Neighbor Embedding).
t-SNE is explicitly driven by the aim of mapping similar (close) points into close low-dimensional representations, making it good for data visualization.

=== The Concept of Similarity (Probability Distributions)

t-SNE models the concept of similarity using probability distributions in both the high-dimensional Data Space (X) and the low-dimensional Map Space (Y).

1. *Data Space Similarity (P)*
Under the hypothesis that each point $x_i$ is the mean of a Gaussian distribution, we measure the conditional probability p(j|i) that $x_i$ will choose $x_j$ as its neighbor. We then symmetrize this to obtain a joint probability p(ij):

$ p_(i j) = (p_(j|i) + p_(i|j)) / (2N) $

This creates a Similarity Matrix P for the high-dimensional data.

2. *Map Space Similarity (Q)*

In the low-dimensional map space, t-SNE uses a Cauchy distribution instead of a Gaussian. This induces a similarity matrix $Q$ where the elements q(ij) represent the probability of $y_i$ and $y_j$ being neighbors.

#note[
  === The Crowding Problem and the Cauchy Distribution

  Why use a Cauchy distribution in the map space instead of a Gaussian? This is to solve the "Crowding Problem" caused by the *curse of dimensionality*.
  In high-dimensional spaces, points tend to distribute far away from the origin (near the surface of a sphere). When projecting these points into a much smaller 2D or 3D volume, using a Gaussian distribution would cause the points to crush together in the center. The Cauchy distribution has a bell shape similar to the Gaussian but with heavier tails, preventing the map points from crowding too closely together.
]

=== Optimization: Kullback-Leibler Divergence

t-SNE chooses the map points $y$ such that the probability distribution $Q$ is as close as possible to the probability distribution $P$.
To measure the difference between these two probability distributions, t-SNE minimizes the Kullback-Leibler (KL) divergence using *Gradient Descent*:

$ "KL"(y_1, ..., y_N) = sum_(i, j) p_(i j) log(p_(i j) / q_(i j)) $

#warning[
  *PCA vs. t-SNE in Machine Learning Pipelines*

  PCA computes a definitive mathematical model (the rotation matrix $E_m$).
  The huge advantage is that you can apply this matrix to any new, unseen point, making PCA perfect for real ML pipelines (e.g., transforming new incoming data before feeding it to a classifier).

  t-SNE is stochastic (nondeterministic) and learns an embedding directly for the points it is given.
  It cannot easily map new incoming data into the existing space.
  Therefore, t-SNE is highly useful for data exploration and visualization, but rarely used directly in production ML pipelines.
]

=== Jointly using PCA and t-SNE

Running t-SNE on datasets with a huge number of dimensions (e.g., d > 1000) is computationally very expensive $(O(N^2)$.

It is highly advisable to use a _two-step_ dimensionality reduction procedure:

- First, use PCA to quickly reduce the initial high dimension down to a manageable size (e.g., m=30). This also helps get rid of noise.

- Then, feed this intermediate 30-dimensional result to t-SNE to reduce it to 2 or 3 dimensions for visualization.

#example[
  === Example Application: Word2Vec in NLP

  In Natural Language Processing (NLP), words are often initially represented as high-dimensional "one-hot encoding" vectors.
  Using a neural network, techniques like `word2vec` compress these into dense vectors (e.g., 300 dimensions) where the geometric distance between vectors represents the semantic meaning (e.g., "king" - "man" + "woman" = "queen").
  Because 300 dimensions are still too many to visualize, t-SNE is commonly applied to word2vec embeddings to project the semantic clusters of words onto a 2D plane for human analysis.
]
