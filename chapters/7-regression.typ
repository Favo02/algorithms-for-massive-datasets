#import "../template.typ": *

= Regression

#informally()[
  In supervised learning, we speak of *regression* when the labels associated with our objects are numbers (typically continuous). 
]

Unlike classification where the output is a discrete class, regression outputs fall into a continuous mathematical space.

*Notation:*
- $x$ is the data point (features).
- $y$ is the actual label (the true value).
- $hat(y)$ is our prediction.
- ${(x^((1)), y^((1))), ..., (x^((n)), y^((n)))}$ is our entire dataset of $n$ observations.
- Typically, an observation $x^((j))$ is a vector living in a $d$-dimensional space ($in RR^d$).
- Therefore, $x_i^((j))$ represents the $i$-th feature of the $j$-th observation.

== Linear Regression

The simplest approach is *Linear Regression*, where our predictor is just a linear function.
We compute the prediction by taking the dot product between a weight vector $w$ (which our model learns) and our data point $x$:

$ hat(y)^((j)) = w dot x^((j)) $

This is simple, but it is fast and often works remarkably well.

=== Affine Mapping (Adding a Bias)

Our linear function $hat(y) = w dot x$ assumes the hyperplane passes through the origin.
Often, adding a threshold or offset ($w_0$) helps a lot to fit the data properly. 
Instead of changing our entire mathematical formulation, we use a trick: we pretend there is an additional dimension in our data and set its value to 1.

$x = (x_1, ..., x_d) -> x = (1, x_1, ..., x_d)$

This brings us to an *affine mapping* while keeping the linear dot product:

$ hat(y) = w dot x = sum_(i=0)^d w_i x_i = w_0 + w_1 x_1 + ... + w_d x_d $

Nothing changes in our problem setup; we are still just searching for $w$.

=== Injecting Non-Linearity (Kernel Methods)

Sometimes data isn't easily predictable with a straight line or a flat hyperplane.
But we want to keep the math simple and use a linear model anyway.
How? By extracting new features or combining existing ones. 

Instead of just using the raw inputs, we can project them into a higher-dimensional space using polynomial expansion:
$
  (a_1, a_2) &--> a_1^2, sqrt(2) a_1 a_2, a_2^2 \
  (b_1, b_2) &--> b_1^2, sqrt(2) b_1 b_2, b_2^2 \
  ... \
  (a_1 b_1 + a_2 b_2)^2 &= underline(a) underline(b)
$

This is the foundation of *Kernel Methods*.
We inject complexity into the original data, incrementing the dimensions so that data that is not linearly separable becomes separable by a linear regressor. 
Basically: map $x -> phi(x)$ and then do $w dot phi(x)$.

#informally[
  Data that cannot be linearly separated in 2D (like a circle of red dots surrounded by blue dots), can be separated in a 3D space.
]

=== The Loss Function

To train our model, we need a way to measure how "wrong" our predictions are.
This is the *Loss Function*.
For linear regression, we use the Sum of Squared Errors (SSE):

$ ell(w) = sum_(j=1)^n (y^((j)) - hat(y)^((j)))^2 = sum_(j=1)^n (y^((j)) - w dot x^((j)))^2 $

Our ultimate goal is to find the optimal weights ($w^*$) that minimize this error:
$ w^* = arg min_w ell(w) = arg min_w || y - X w ||^2 $

Let's reformulate this using vectors and matrices.
If we stack all our $n$ objects as rows, we get a matrix $X$ of size $n times d$.
If we stack our labels, we get a vector $y$ of size $n$.

=== Finding the Minimum (Derivatives & Jacobians)

To find the minimum of a function, we take its derivative and set it to zero.
But how to calculate these things with vectors? 
The derivative of a vector is the gradient $nabla$.

$ nabla f = [(d f) / (d x_i)]_i $
$ nabla ||v||^2 = [(d ||v||^2) / (d v_i)]_i = 2 underline(v) $

First, let's recall the concept of *partial derivative*.
It is nothing but what we obtain by fixing a constant and treating the rest as a variable we can derive.

#example[
  If I have a function $f(x, y) = sin(x + y) dot x$, the partial derivative with respect to $x$ is:
  $ (partial f) / (partial x) = x dot cos(x + y) + sin(x + y) $
  *(Treating $y$ as a constant)*.
]

Applying the chain rule to our vector loss function:
$ nabla ||X w - y||^2 = 2 (X w - y) underbrace(J(X w - y), "Jacobian") = underbrace(2 X^T (X w - y), "order matters for dimensionality match") $

#note[
  - *Gradient* ($nabla$): The first derivative of a scalar function (outputs a vector).
  - *Jacobian* ($J$): The first derivative of a vector function (outputs a matrix). It's a close concept to a second derivative.
  
  $ J(X w) &= [(d(X w)_j) / (d w_i)]_(i, j) \
           &= [ d / (d w_i) sum_(overline(i)=1)^d x_(j overline(i)) w_overline(i)]_(i, j) \
           &= [x_(j i)]_(i j) \
           &= X^T $
]

We set the gradient to zero to find the minimum:
$ 2 X^T (X w - y) = 0 \
  X^T X w - X^T y = 0 \
  X^T X w = X^T y $

This is the *Normal Equation*.
If we assume $(X^T X)$ is invertible, we move around things and solve for $w$:
$ w = underbrace((underbrace(X^T, d times n) underbrace(X, n times d))^(-1), d times d) underbrace(X^T, d times n) underbrace(y, n) $

=== Overfitting and Ridge Regression

Real-world data is *dirty*.
If we aim for the absolute smallest loss on our dataset, we might memorize the noise rather than the underlying pattern.
This is called *overfitting*.
Following *Occam's razor*, we want to find the right balance between model complexity and error. We can do this by penalizing large weights.
This is called *Ridge Regression*.

We add a regularization term $lambda ||w||_2^2$ to our loss function:
$ w = arg min_w || X w - y ||_2^2 + lambda || w ||_2^2 $

This slightly modifies our closed-form Normal Equation solution by adding the Identity matrix $I_d$:
$ w = (X^T X + lambda I_d)^(-1) X^T y $

=== The Machine Learning Pipeline

What is $lambda$? It's a *hyper-parameter*.
We cannot learn it directly from the optimization formula; we have to tune it. 
To do this without overfitting, we use data splitting.
We divide our observations into three distinct sets:

- *Training set:* used to train the models (find $w$).
- *Validation set:* used for model selection (tune $lambda$).
- *Test set:* used at the very end to assess the final machine learning output on unseen data.

*Assessment Metrics:*
We evaluate the model's error using the Mean Squared Error (MSE) or its root (RMSE):
$ "MSE" = 1/n sum_(j=1)^n (hat(y)^((j)) - y^((j)))^2 $
$ "RMSE" = sqrt("MSE") $

*The Full Pipeline:*

1. Fix a set of possible values for $lambda$ (e.g., ${lambda_1, ..., lambda_o}$).
2. For each $lambda_k$: train the model on the *Training set*, then compute the MSE on the *Validation set*.
3. Pick the $lambda^("opt")$ that gave the lowest error.
4. Retrain the model using $lambda^("opt")$ on the combined Training + Validation sets.
5. Assess the overall learning process by computing the final MSE on the *Test set*.

=== Complexity Analysis

Solving this exact equation has a cost:
- *Space Complexity:* $O(d^2 + n d)$. We must store the data and the $d times d$ matrix.

- *Time Complexity:* $O(underbrace(d^3, "matrix inversion") + underbrace(n d^2, "calculating the matrix"))$.

So we have to focus on the dimensionality of the data ($d$) and the number of data points ($n$):
- *Small $d$, Small $n$:* Everything fits in Main Memory. Easy.
- *Big $d$, Small $n$:* We need Dimensionality Reduction (like PCA) to shrink $d$.
- *Small $d$, Big $n$:* The Massive Datasets scenario, let's address this specific case.

=== Computing with Small $d$, Big $n$ (The MapReduce Approach)

Let's analyze the complexity in the *Small $d$, Big $n$* case.
We can fit the final result $w$ and the matrix $X^T X$ ($d times d$) in Main Memory, but we cannot possibly compute the transpose and the product locally if $X$ ($n times d$) is a massive dataset.

The real bottleneck is producing and storing the intermediate matrix $X^T X$ efficiently. 
The last thing I want is a massive local matrix multiplication.

Standard matrix multiplication for $P = A B$ is defined as $P_(i j) = sum_k A_(i k) B_(k j)$.
However, we can rewrite this using the *Outer Product* approach:

$ P = A B = sum_(k=1)^c P^k = sum_(k=1)^c A_(*k) times B_(k*) $

Where $A_(*k)$ is the $k$-th column of $A$ and $B_(k*)$ is the $k$-th row of $B$.
Basically, we are summing up outer products (multiplying a column vector by a row vector gives a full matrix).

#example[
  Outer product of vectors:
  $ vec(a, b) times [c, d] = mat(a c, a d; b c, b d) $
]

Applying this logic to our specific problem $X^T X$:
- The columns of $X^T$ are simply the rows of $X$ (let's denote the $k$-th row of $X$ as $x_k$).
- The rows of $X$ are exactly the rows of $X$.

So the massive matrix multiplication elegantly simplifies into a sum of outer products of each individual data point with itself:

$ X^T X = sum_(k=1)^n x_k x_k^T $

Why is this a game-changer?
Because $x_k x_k^T$ results in a small $d times d$ matrix.
Storing these individual elements is perfectly affordable.
The computation inside this sum can be easily executed by a local machine for a single point (or a small chunk of points).

Summing $n$ matrices in a distributed way is the perfect job for *MapReduce*:
- *Map:* Each mapper takes a subset of rows (data points $x_k$), computes the local outer product $x_k x_k^T$ (which is a $d times d$ matrix), and outputs it.
- *Reduce:* The reducers simply sum up all these incoming $d times d$ matrices to produce the final $X^T X$.

Once we have the aggregated $X^T X$ (which is small, $d times d$), we can invert it locally in Main Memory and solve the regression without running out of RAM!

== Gradient Descent (When both $d$ and $n$ are Big)

When both dimensions grow, calculating and inverting $X^T X$ is mathematically impossible due to memory and time limits.
We still want to minimize our loss function $ell = sum_(j=1)^n (w dot x^((j)) - y^((j)))^2$, so we must find the minimum $w$ *iteratively* rather than analytically.

Let's start with an algorithm to find the local minimum of a 1-variable function:
1. We start by choosing a random value $x_0$.
2. We compute the first derivative of that point $f'(x_0)$.
3. We move to a point that depends on the derivative and its steepness: $x_1 = x_0 - f'(x_0)$.
4. If the function "well behaves", we will get closer and closer to the local minimum.
5. When we reach the local minimum, the derivative is $0$ and it stops.

For multi-variable functions, we use the *Gradient* instead of the derivative.
The gradient points to the steepest ascent, so it points to the opposite of the local minimum.
We also apply a "learning rate" ($alpha$) tweaking the size of the steps:
$ x_(i+1) = x_i - alpha nabla f(x_i) $

Applying this to our weights $w$:
$ w_(i+1) = w_i - alpha nabla ell(w_i) $

If the algorithm reaches the optimum, the derivative there is $0$, resulting in $w_(i+1) = w_i - 0$. 
The parameters stop updating, meaning the algorithm has successfully converged to the minimum.

#warning[
  We need to work on the "size" of the steps:
  - Too big: We can jump out of that local valley, and even start diverging.
  - Too small: It will take a lot of time to reach the minimum.
  The biggest problem of this algorithm is that it finds a *local* minimum, not necessarily the overall (global) minimum, unless the function is perfectly convex.
]

To visualize this, imagine a *contour plot* (like a topographic map of a mountain).
The concentric rings represent the loss function's values.
The gradient is always perpendicular to the contour lines, pointing straight uphill.
Our algorithm takes steps crossing these lines downwards until it reaches the center (the minimum).

*Decaying Learning Rate:*
The learning rate is usually fixed, but it can also depend on the iteration: we start by taking big steps, then while the iterations progress, we take smaller steps:
$ alpha_i = alpha_0 1 / (n sqrt(i)) $

=== Minimize Loss Function

Let's compute the gradient for a single weight $w_k$:
$ (partial ell) / (partial w_k) &= sum_(j = 1)^n 2(w dot x^((j)) - y^((j))) dot d/(d w_k) (w dot x^((j))) \
  &= sum_(j = 1)^n 2 (w dot x^((j)) - y^((j))) x_k^((j)) $

#note[
  Notice that $2(w dot x^((j)) - y^((j)))$ is just a scalar multiplier for the feature value.
]

The gradient is all these partial derivatives ranging $k$:
$ nabla ell(w) = [(d ell(w)) / (d w_k)]_(1, ..., d) $

Getting back to the full vector:
$ nabla ell(w) = sum_(j = 1)^n 2(w dot x^((j)) - y^((j))) x^((j)) $

*The Algorithm:*
```pseudocode
fix w_0 (random initialization)
set alpha
i = 0
while not stop_condition:
    w_(i+1) = w_i - alpha * sum( 2 * (w_i * x^((j)) - y^((j))) * x^((j)) )
    i += 1
```

This algorithm is very distributable, as every component of the sum can be distributed on a different node. 
We can broadcast the weights.
At a local level (on each node/for each map task):

- Time Complexity: O(d)

- Space Complexity: O(d)

== Feature Engineering at Scale

Before passing data into a Regression or Logistic Regression model, we must ensure the features are numerical and computationally manageable.
When dealing with Massive Datasets, raw data is often categorical and extremely high-dimensional.

=== One-Hot Encoding (OHE)

Mathematical models cannot multiply weights by strings (like "cat" or "black").
We must map categorical variables to numeric vectors.
In a *One-Hot Encoding* scheme, we represent each unique `(feature, category)` tuple as a distinct binary dimension. 

#example[
  If our feature is "Color" with categories {Red, Green, Blue}, a "Green" object becomes:
  $ "Color" = "Green" -> [0, 1, 0] $
]

=== Sparse Vectors

*OHE* solves the categorical problem but introduces a massive computational issue: sparsity. 
If a dataset has `100,000` unique categories across all features, each data point becomes a vector of length `100,000` where maybe only 5 values are $1$, and `99,995` values are $0$. 

Storing this as a standard dense array is a catastrophic waste of Main Memory.
Instead, we use *Sparse Vectors*.
A Sparse Vector only stores two things: the total size, and a dictionary (or lists) mapping the *indices* of the non-zero elements to their *values*.

#informally[
  Instead of memorizing `[0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0]`, the computer just remembers: "Length 7.
  Values are 1.0 at index 2, and 1.0 at index 4".
  This allows us to perform dot products ($w dot x$) incredibly fast by skipping all the zeros
]

=== Dimensionality Reduction: Feature Hashing (The Hashing Trick)

What happens if OHE generates too many features?
For example, in Click-Through Rate (CTR) prediction, advertising data might have 33 million distinct categorical combinations.
A weight vector $w$ of size 33 million is too big to broadcast to worker nodes, let alone compute.

To reduce the dimensionality of the feature space without doing complex PCA, we use *Feature Hashing* (or the Hashing Trick).
Instead of maintaining a massive dictionary that maps every single category to a unique index, we apply a *hash function* to the raw feature string and use the modulo operator to map it to a fixed number of buckets ($N$).

$ "Index" = h("feature_string") mod N $

#note[
  *What about Hash Collisions?*
  Multiple distinct features might hash to the same bucket (collision).
  Surprisingly, machine learning models (like Logistic Regression) are highly robust to this.
  The loss of accuracy due to collisions is usually marginal, while the gains in memory and computational speed are monumental.
]

== Logistic Regression

Regression usually outputs continuous numbers, but it makes no sense to sum them when dealing with Classification (discrete classes).

Let's start with the simplest case: binary labels $y^((j)) in {-1, +1}$

We want to identify a weight vector $w$ that acts as a hyperplane, cutting the space in half.
Points on one side get classified as $+1$, the others as $-1$.
We are interested in the product between the vector $w$ and the point to classify $x$, specifically its sign:

$ hat(y) = "sign"(w dot x) $

=== The 0-1 Loss Function

To evaluate this, we define $z=y^((j))(w dot x^((j)))$.
If our prediction is correct, the signs match, so $z > 0$.
If we are wrong, the signs differ, so $z < 0$.

The 0-1 loss for a single observation is defined as:

$ ell_(01)(z) = cases(1 "if" z < 0, 0 "if" z > 0) $

We aim to minimize the macro loss function over the entire dataset:
$ L = sum_(j=1)^n ell_(01) (y^((j)) (w dot x^((j)))) $

A perfect classifier yields $L=0$.
The value of this macro loss function directly represents the total count of misclassified examples.

The Problem: We are not able to apply Gradient Descent on the 0-1 loss.
It is a step function (non-convex), meaning its derivative is 0 everywhere except at the jump, where it is undefined.
Gradient Descent needs a slope to follow.
=== The Log-Loss Function

Let's try to change the loss function: we define the Log-Loss:
$ ell_(log)(z) = ln(1 + e^(-z)) $

This is a continuous, convex function.
So we will minimize the log-loss:
$ w^* = arg min_w sum_(j=1)^n ell_(log) (y^((j)) (w dot x^((j)))) $

We need to compute the gradient.
First of all, we need the derivative of the log-loss function (applying the chain rule):
$ ell_(log)^'(z) &= d / (d z) ln(1 + e^(-z)) \
&= 1/(1+e^(-z)) (-e^(-z)) \
&= (-e^(-z))/(1 + e^(-z)) $

#note[
We can algebrically manipulate this fraction into a more convenient form for later steps:
$ (-e^(-z)) / (1 + e^(-z)) &= (1 - (1 + e^(-z))) / (1 + e^(-z)) \
&= 1 / (1 + e^(-z)) - 1 \
&= -(1 - 1 / (1 + e^(-z))) $
]

Then compute the partial derivatives with respect to $w_k$:
$ (partial ell) / (partial w_k) = sum_(j=1)^n -(1-1/(1+e^(-w dot x^((j)) y^((j))))) dot d / (d w_k) (w dot x^((j)) y^((j))) $

Since $d / (d w_k) (w dot x^((j)) y^((j))) = y^((j)) x_k^((j))$, we get:

$ (partial ell) / (partial w_k) = sum_(j=1)^n -(1-1/(1+e^(-w dot x^((j)) y^((j))))) y^((j)) x_k^((j)) $

We need to minimize that gradient vector:
$ nabla ell(w) = - sum_(j=1)^n (1-1/(1+e^(-w dot x^((j)) y^((j))))) y^((j)) x^((j)) $

#note[
  *Regularized Logistic Regression:*
  Just like Ridge Regression, we can add a penalty term to our log-loss to prevent the weights from growing too much and overfitting the training data:
  $ w = arg min_w sum_(j=1)^n ell_(log) (y^((j)) (w dot x^((j)))) + lambda ||w||_2^2 $
]

What's the application of that logistic?

=== The Sigmoid Function & Probabilities

Instead of just outputting a hard $+1$ or $-1$, what if we want a smooth threshold that outputs a real number between 0 and 1?
We use a Sigmoid $beta$:

$ f_(beta)(x) = 1/(1+e^(-beta x)) $

The Logistic function is a specific sigmoid function, with $beta$ fixed to 1.

#note[
Probabilistic Interpretation:
Beyond strictly predicting a class, Logistic Regression allows us to output class probabilities. We can model the label as a random variable $Y$ and formalize the conditional probability:
$ PP(Y = +1 | X = x) = 1 / (1 + e^(-w dot x)) $
]

=== ROC Curves

We want to convert that probability into a binary classification. To this end, we can use ROC curves.
Since the model outputs a probability, we need a threshold. By changing the threshold, we can plot a trajectory on the square plane.

$ "TPR" = "TP"/("TP" + "FN") quad "How many of the actual positives did we catch?" $
$ "FPR" = "FP"/("FP" + "TN") = 1 - "TNR" quad "How many negatives did we falsely label as positive?" $

- Perfect classifier: TPR = 1, TNR = 1 (FPR = 0)

- Always negative: TPR = 0, TNR = 1 (FPR = 0)

- Always positive: TPR = 1, TNR = 0 (FPR = 1)

- Always wrong: TPR = 0, TNR = 0 (FPR = 1)

- Random classifier: TPR = 1/2, TNR = 1/2 (FPR = 1/2)