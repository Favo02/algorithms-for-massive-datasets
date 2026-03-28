#import "../template.typ": *

= Gradient Boosting

#rect(stroke: 2pt + red, fill: red.transparentize(70%))[
  #todo

  Contribute to open #link("https://github.com/Favo02/algorithms-for-massive-datasets/pull/15")[pull request \#15] approving or improving this chapter.
]

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

- *Splitting Criterion:* We choose the split for our regression stump by optimizing a specific impurity measure, typically minimizing the variance (Squared Error) of the residuals in the resulting child nodes.

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
We introduce a *learning rate* ($eta > 0$), also known as _shrinkage_.

$ F_m (x) = F_(m-1) (x) + eta dot Delta_m (x) $

This introduces several *Hyperparameters* that must be tuned (usually evaluating our loss function over a grid via Validation Sets or Cross-Validation):

1. The number of functions (trees) to add ($M$).
2. The learning rate ($eta$).
3. The depth of the trees (if we use more than just stumps).

=== Stochastic Gradient Boosting

#warning[
  If we are going to train a lot of simple learners using the exact same algorithm on the exact same dataset, how can we train them differently?
  We can't use the full dataset every time, otherwise we would just get $M$ identical copies of the same tree!
]

To solve this and make the ensemble effective, we must introduce *stochasticity* (randomness).
We don't use all data at each iteration; instead, we perform *aggressive subsampling* (e.g., using only 50% of the data often proves effective). We can:

- Subsample *rows* (observations) before creating each tree.
- Subsample *columns* (features) before creating each tree.
- Subsample *columns* before considering each individual split within the tree.

This ensures that each weak worker is highly specialized on a slightly different perspective of the data. Summing these specialized workers yields a much stronger overall prediction.

=== The "Gradient" in Gradient Boosting: Mathematical Formulation

#informally[
  Why is this technique called *Gradient* Boosting?
]

At each iteration of gradient boosting:
$ F_m (x) = F_(m-1) (x) + eta Delta_m (x) $

Let $hat(y)_m := F_m (x)$ be our prediction at step $m$.
We can rewrite the update rule as:
$ hat(y)_m = hat(y)_(m-1) + eta r_(m-1) $
where $r_(m-1)$ denotes the target residuals that we approximate via $Delta_m (x)$.

Now, compare this update rule with the standard *Gradient Descent* optimization step:
$ x_t = x_(t-1) - eta nabla L(x_(t-1)) $

This implies that our residual $r_t$ is directly proportional to the negative gradient of the loss function:

$ r_t (x) = - nabla L(x_t) $

Thus, at each iteration, the next improvement is chosen by implicitly optimizing the loss function via gradient descent in function space.

#note[
  How this gradient looks depends on our choice of the loss function
]

==== Case 1: Mean Squared Error (MSE)

If we use MSE, we are tracking both the *sign* and the *magnitude* of the error:

$ L(x, y, F_M) prop sum_i (y_i - hat(y)_i)^2 $
Taking the partial derivative with respect to the prediction $hat(y)_k$:
$ (partial) / (partial hat(y)_k) L(y, hat(y)) prop -2(y_k - hat(y)_k) $
Therefore, the gradient is exactly proportional to the residual: $nabla L prop -2(y - hat(y))$.

==== Case 2: Mean Absolute Error (MAE)

The risk of using MSE is *chasing outliers* due to large squared magnitudes.
A solution is to only learn the *sign* of the residual.
We do this by changing our loss function to MAE:

$ L(x, y, F_M) prop sum_i |y_i - hat(y)_i| $
Taking the partial derivative:
$ (partial) / (partial hat(y)_k) L(y, hat(y)) prop -"sign"(y_k - hat(y)_k) $
Therefore, the gradient tracks only the direction: $nabla L prop -"sign"(y - hat(y))$.

#note[
  *Efficiency trick:* Even when evaluating the overall model using MAE to avoid outliers, when learning the individual regression tree stumps, we still choose the node splits according to Squared Error minimization. This is done purely for computational efficiency.
]

=== Gradient Boosting in Practice (XGBoost)
The most popular and successful implementation of gradient boosting is *XGBoost*. It provides extreme portability and scalability (it runs natively on distributed systems like Hadoop and Spark) and has proven to be highly successful in machine learning competitions like Kaggle.
