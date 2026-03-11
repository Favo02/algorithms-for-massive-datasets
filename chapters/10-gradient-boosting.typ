#import "../template.typ": *

= Gradient Boosting

#note[
  This topic (Gradient Boosting) is not strictly related to Big Data infrastructure; it is purely Machine Learning.
  It is taught in this course as there are no other courses in the curriculum that cover this technique.
]

== Boosting and Additive Modeling

In many real-world machine learning scenarios, relying on a single, highly complex predictor is not the optimal strategy.
Instead, we employ an *ensemble approach* (Boosting): instead of training one single complex model, we train a lot of simple, *weak learners*. 

The final result is the aggregation of the outputs of these single weak learners.
This approach significantly reduces the risk of overfitting while maintaining high predictive capacity.

#example[
  *Random Forest:* An aggregation (ensemble) of multiple decision trees.

  #align(center)[
    #image("/assets/random-forest.png", width: 80%)
  ]
]

=== Additive Modeling

The core concept is that multiple simple functions are summed together to approximate a complex target function.
We start with a simple function to see how it performs, then incrementally add another function to improve the modeling, and repeat:

$ F_M (x) = sum_(i=0)^M f_i (x) $

== Gradient Boosting

With Gradient Boosting, we still want to incrementally add weak learners to improve our approximation.
The main difference is that the new learner is *not* trained on the whole target dataset, but only on the *residual error* between the current approximation and the real function.

We can rewrite our additive model specifically for Gradient Boosting as:

$ F_M (x) = f_0 (x) + sum_(i=1)^M Delta_i (x) $

where $f_0$ is the baseline model and $Delta_i$ are the subsequent learner models optimizing the residuals. 

- *The Baseline ($f_0$):* We start by using a "normal" function as a baseline. For regression, this often gives us a *constant prediction* (e.g., predicting the mean of all target values in the dataset). 
- *The Refinements ($Delta_i$):* Then we start adding simple models that try to cover the distance between the baseline and the true value.

#informally[
  Like in golf, we try to get closer and closer to the hole with multiple shots, adjusting for the remaining distance each time, instead of aiming at putting it in from the very first throw.
]

=== Weak Learners: Regression Trees

The standard machine learning model used as a weak learner ($Delta_i$) is the *Regression Tree*. 
To maintain strict control over the complexity, we must use *simple* models.
We typically use *regression tree stumps*, which are the simplest regression trees, having a depth of exactly 1 (only one root node and two leaves).

#note[
  Other simple models could theoretically be used (like simple linear regressors), but tree stumps are the standard.
  The most important thing is that these must be *simple* models.
]

- *Splitting Criterion:* We choose the split for our regression stump by optimizing a specific metric, typically minimizing the variance of the residuals in the resulting child nodes.

- *Aggregation:* Each time we append a new function $Delta_i$, every data point is associated with its current residual. The final model is an agglomeration that adapts precisely to the variability of the dataset.

=== Evaluating the Result

To evaluate how well our additive model is doing, we use a Loss Function.
For continuous regression problems, we typically use *Mean Squared Error (MSE)*.
The MSE for a model with $m$ steps ($F_m$) over $n$ samples is computed as:

$ L(x, y, F_m) = "MSE"(x, y, F_m) = 1/n sum_(i=1)^n (y_i - F_m (x_i))^2 $

#warning[
  Evaluating the error strictly on the training set is not a robust estimate of performance! Because we continually add predictors, the model will eventually adapt perfectly to the training dataset's noise.
  To evaluate the model's true generalization, you *must* use a separate test set.
]

=== Incremental Shrinkage & Hyperparameters

To further prevent overfitting, we do not add the full prediction of the new tree.
We introduce a *learning rate* ($eta$), also known as _shrinkage_.

$ F_m (x) = F_(m-1) (x) + eta dot Delta_m (x) $

This introduces several *Hyperparameters* that must be tuned (usually via Validation Sets or Cross-Validation):

1. The number of functions (trees) to add ($M$).

2. The learning rate ($eta$).

3. The depth of the trees (if we use more than just stumps).

=== Stochastic Gradient Boosting

#warning[
  If we are going to train a lot of simple learners using the exact same algorithm on the exact same dataset, how can we train them differently?
  We can't use the full dataset every time, otherwise we would just get $M$ identical copies of the same tree!
]

To solve this and make the ensemble effective, we must introduce *stochasticity* (randomness) through *subsampling*.

- We train each weak learner on a random subsample of the dataset (e.g., 80% of the rows) or a random subset of the features.

- This ensures that each weak worker is specialized on a slightly different perspective of the data. Summing these specialized workers yields a much stronger and more generalized overall prediction.

=== The "Gradient" in Gradient Boosting

#informally[
  Why is this technique called *Gradient* Boosting?
]
It relates to the loss function.
When tracking the error using MSE, focusing on large residuals can lead to overfitting outliers. If we want to regularize against this, we might track only the *sign* of the error (+1 or -1) to know the direction we need to move. 

By changing our approach this way, we are effectively switching our loss evaluation from MSE to *Mean Absolute Error (MAE)*. 
Mathematically, the residual we compute at each step is actually the *negative gradient* of the chosen loss function (MSE, MAE, etc.) with respect to the model's predictions.
Therefore, training a tree on the residuals is equivalent to performing *Gradient Descent in function space*.

== Dimensionality Reduction & PCA

Dimensionality reduction maps data from a high-dimensional Data Space ($RR^d$) to a lower-dimensional Feature Space ($RR^(d')$ where $d' < d$).
The most standard feature engineering approach to achieve this is *Principal Component Analysis (PCA)*.

=== The Variance-Covariance Matrix
Let's assume we have a dataset with $N$ elements, where each data point is a vector in $RR^d$. We stack these row vectors vertically to create an $N times d$ matrix $M$:

$ M = mat(
  (x^1)^T;
  (x^2)^T;
  dots.v;
  (x^N)^T
) $

We compute the variance-covariance matrix by multiplying $M^T M$, which results in a $d times d$ square matrix. The element at position $(i,j)$ represents the covariance between feature $i$ and feature $j$:

$ (M^T M)_(i,j) = sum_(k=1)^N x_k^i x_k^j $

=== The Principal Eigenvector & Geometric Meaning

Since $M^T M$ is a symmetric square matrix, we can compute its eigenvectors ($e$) and eigenvalues ($lambda$).
Let's focus on the principal eigenvector $e_1$ (associated with the largest eigenvalue $lambda_1$):

$ M^T M e_1 = lambda_1 e_1 $

*Geometric meaning:* Imagine your data is scattered roughly along a 45-degree line in a 2D space. The principal eigenvector $e_1$ identifies the specific direction in that space that *maximizes the variance* of your projected data. 
Outside of this primary direction, the variance is very small and can often be treated as noise. By describing the data purely along this simple direction, we successfully mold and compress the dimensionality of our space.

=== The Power Method

How do we efficiently find this principal eigenvector starting from the data points? We use an iterative numerical algorithm called the *Power Method*:

```pseudocode
 Initialize a random non-zero vector $v_0$
 Set $t = 0$
 while not converged:
   $v_(t+1) = M^T M v_t$
   $v_(t+1) = v_(t+1) \/ norm(v_(t+1))$ 
   $t = t + 1$
```

This process guarantees convergence to the principal eigenvector $e_1$.

=== Matrix Deflation (Finding Subsequent Eigenvectors)

#informally[
  Once we have found the first pair $(lambda_1, e_1)$, how do we find the second highest eigenvalue and its eigenvector?
]

We use a mathematical trick called *Matrix Deflation*.
We construct a new matrix $A^*$:

$ A^* = M^T M - lambda_1 e_1 e_1^T $

Let's prove why this works.
*What happens if we multiply $A^*$ by our first eigenvector $e_1$?*

$ A^* e_1 = (M^T M - lambda_1 e_1 e_1^T) e_1 $
$ A^* e_1 = M^T M e_1 - lambda_1 (e_1 e_1^T) e_1 $

Because matrix multiplication is associative, we can rewrite $(e_1 e_1^T) e_1$ as $e_1 (e_1^T e_1)$.
Since $e_1$ is a normalized unit vector, its squared norm is 1 ($e_1^T e_1 = 1$).
Furthermore, we know $M^T M e_1 = lambda_1 e_1$.

$ A^* e_1 = lambda_1 e_1 - lambda_1 e_1 (1) = 0 $

The result is the null vector.
This means $e_1$ has been "deflated" and is now associated with an eigenvalue of $0$.

*What happens if we multiply $A^*$ by any other eigenvector $e_i$ (where $i > 1$)?*

$ A^* e_i = M^T M e_i - lambda_1 e_1 (e_1^T e_i) $

Because eigenvectors of a symmetric matrix are orthogonal to each other, the dot product $e_1^T e_i = 0$.

$ A^* e_i = lambda_i e_i - 0 = lambda_i e_i $

This proves that $e_i$ is *still* an eigenvector of $A^*$, with its original eigenvalue $lambda_i$.
Because $lambda_1$ has been reduced to $0$, the new highest eigenvalue in $A^*$ is now $lambda_2$.

#note[
  To find it, we simply apply the Power Method again on $A^*$
]

=== Extracting the Two Parameters (Projecting the Data)

By repeating the deflation and power method, we can extract the top two parameters: the first two principal eigenvectors $e_1$ and $e_2$ (corresponding to $lambda_1$ and $lambda_2$).

If we want to reduce our massive dataset down to a 2-dimensional space for visualization or compression, we use these two vectors to build a projection matrix $P$:

$ P = [e_1, e_2] $

#note[
  This is a $d times 2$ matrix
]

To compress any original data point $x$ (which is $d$-dimensional) into a new 2-dimensional point $x'$, we simply project it:

$ x' = P^T x $