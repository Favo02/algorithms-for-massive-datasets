#import "../template.typ": *

= Gradient Boosting

#note[
  This topic is not really related to big data, it is purely machine learning.

  It is taught in this course as there are no other courses that teach this.
]

Boosting: Instead of training one single complex model, we have a lot of simple learners.
The result is the aggregation of the output of the single weak learners.
The output can be aggregated in different ways: majority vote, average, etc.

#example[
  Random forest: aggregation of a decision tree.
]

== Additive modeling

Multiple simple functions are summed to approximate something.

The idea is to start with a simple function and see how it performs.
Then start to add another function to improve the modeling.
And repeat.

$ F_(M)(x) = sum_(i=0)^M f_(i)(x) $

== Gradient Boosting

We still want to incrementally add weak learners to improve our approximation.
The main difference is that the new learner is not trained on the whole dataset, but only on the residual error between the approximation and the real function.

$ F_(M)(x) = f_0(x) + sum_(i=1)^M Delta_(i)(x) $

where $f_0$ is the baseline and $Delta_i$ are the learner models.

#informally[
  Like in golf, we try to get closer and closer the the hole instead of aiming at putting it from the first throw.
]

We start by using a "normal" function as baseline.
This gives us a constant prediction. // TODO: always?

Then we start adding *simple* models.
One of the simplest models are regression tree.
We use regressin tree stumps, the simpelst regression trees, having depth 1 (only root and two leaves).

#note[
  Other simple models could be used, like simple regressors.

  The important thing is that these must be *simple* models.
]

#warning[
  Is we are going to train a lot of simple learners, how can we train them differently?
  We can't use the full dataset, otherwise we would get the same model.

  The solution is subsampling.
]

=== Evaluating Result

Of course, using a loss function.
In this case, we use MSE.

$ L(x, y, F_m) = "MSE"(x, y, F_m) = 1/n sum_(i=1)^n (y_i - F_(m)(x_i))^2 $
