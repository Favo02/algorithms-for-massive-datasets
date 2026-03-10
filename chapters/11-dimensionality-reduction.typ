#import "../template.typ": *

= Dimensionality Reduction

Data with a lot of dimensions, we want to reduce them.

$ underbrace(n in RR^d, "data space") ~~> underbrace(y in RR^d', "feature space"), quad d' << d $

It can be done _easily_ using *projection*, using mainly two approaches: finding relevant dimensions and ignoring irrelevant dimensions.

But dimensionality reduction often uses something different: *feature engineering*.

== Principal Component Analysis (PCA)

$ underbrace(M, n times d) = vec(underline(x^1), underline(x^2), ..., underline(x^n), delim: \[) $
with each $x^i$ being an $x$ in data space.

Considering the transpose:
$ M^T = [(underline(x)^1)^T | (underline(x)^2)^T | ... | (underline(x)^n)^T] $

And the product, obtaining the *variance-covariance matrix*:
$ underbrace(M^T M, d times d) = [ sum_k x_k^i x_k^j ]_(i j) $

Since the matrix is square, we can compute the eigenvalue and eigenvectors:

$ M^T M underline(e)_1 = lambda_1 underline(e)_1 $

We sorted the eigenvalues so that $lambda_1$ is the greathest.

This eivenvector $underline(e)$ identifies the *dimension* that *maximises* the variance between the data (the distances between each point and the axis we are considering).

Then we can *remove* the dimension ortogonal to this dimension.

Stacking all eigenvectors in a matrix, we obtain a linear transformation that rotates the points so that we can discard the last components of that matrix, reducing the dimensionality of the data.
$ [underline(e)_1 | underline(e)_2 | ... | underline(e)_n] $

#note[
  This is the result of the PCA, the *rotation matrix*.

  Then we can apply this matrix to any point, not only to the points we used to calculate this matrix.

  // TODO: expand in own section?
  Another technique, called T-SNE, improves (a lot) the effectivness of that, but it can be only used on the points it is calculated.
  So, it is really useful for visualization procedures, but it can't be really used on a real ML pipeline.
]

How do we compute these values when dealing with big data?
IN pagerank, we calculated the principal eigenvalue with big data, but we had the constraint that it would be $1$.

Here we have no guaranteed.
But we don't care. // TODO: why??

- fix $underline(v)_0$
- $t = 0$
- while !stop:
  - $underline(v)_(t+1) = M^T M underline(v)_t$
  - $underline(v)_...$ // TODO: complete these

But we found only the principal eigenpair $lambda_1, underline(e)_1$ of the matrix $A$.
We need all the other, we can use a trick.

Consider the matrix:
$
  A^* & = A - lambda_1 underline(e)_1 underline(e)_1^T \
  A^* underline(e)_1 & = (A - lambda_1 underline(e)_1 underline(e)_1^T) underline(e)_1 \
  &= underbrace(A underline(e)_1, lambda_1 underline(e)_1) - lambda_1 underbrace((underline(e)_1 underline(e)_1^T) underline(e)_1, underline(e)_1 ||underline(e)_1||^2) \
  & = lambda_1 underline(e)_1 - lambda_1 underline(e)_1 \
  &= underline(0)
$

Now, consider every eigenvector:
$
  A^* underline(e)_i & = (A - lambda_1 underline(e)_1 underline(e)_1^T) underline(e)_i \
  & = A underline(e)_i - underbrace(cancel(lambda_1 ( underline(e)_1 underline(e)_1^T) underline(e)_i), underline(e)_1 ( underline(e)_1^T underline(e)_i) = 0)
$

#note[
  The eigenvectors of a matrix are always ortoghonal, so their dot product is zero.
]

This means that applying the power method to $A^*$, we find its principale eigenvector, which is the second biggest eigenvalue of the original matrix $A$.
We can repeat this procedure again to find the third biggest and so on.

// TODO: content from the notebook
