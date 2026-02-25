#import "../template.typ": *

= Regression

The labels are numbers, typically countious.
Supervised learning.

Notation:
- $x$ is the data
- $y$ is the label
- ${(x^((1)), y^((1))), ..., (x^((n)), y^((n)))}$ is the dataset
- $hat(y)$ is the prediction
- typically $x^((j))$ is a vector $in RR^d$
- so $x_i^((j))$ is the $i$th element of the $j$th observation

== Linear Regression

We use linear function to predict the label:
$ hat(y)^((j)) = w dot x^((j)) $

This is simple, but sometimes it works pretty well.

Furthermore, we can keep the structure of a linear classifier and adding non-linearity in another way: extracting featuing combining multiple points: // TODO: what???? why?

$
  (a_1, a_2) --> a_1^2, sqrt(2) a_1 a_2, a_2^2 \
  (b_1, b_2) --> b_1^2, sqrt(2) b_1 b_2, b_2^2 \
  ...
  = (a_1 b_1 + a_2 b_2)^2 = underline(a) underline(b)
$

Injecting complexity in the original data, so that are not anymore linearly something, incrementing the dimensions, so that can be separated by a linear regressor.
This is kernel *methods*.

#informally[
  Data that can not be linearly separated 2d (like a circle), can be in a 3d space (using height?).
]

Loss function: // TODO: what is that?

$
  sum_(j=1)^n (y^((j)) - hat(y)^((j)))^2 = sum_(j=1)^n (y^((j)) - w x^((j)))^2 = ell(w)
$

$ w^* = arg min_w ell(w) = arg min_w || y - X w ||^2 $

But how to calculate these things? the derivative of a vector is the gradient $nabla$
$ nabla f = [(d f) / (d x_i)]_i $
$ nabla ||v||^2 = [(d ||v||^2) / (d v_i)]_i = 2 underline(v) $
$
  nabla ||X w - y||^2 = 2 (X w - y) underbrace(J(X w - y), "Jacobian") = underbrace(2 X^T ( X w - y), "order matters for dimensionality match")
$

#note[
  The Jacobian of something is a close concept of a second derivative
  // TODO: ok, what?
  $
    J(X w) = [(d(X w)_j) / (d w_i)]_(i, j) \
    = [ d / (d w_i) sum_(overline(i)=1)^d x_(j overline(i)) w_overline(i)]_(i, j) \
    = [x_(j i)]_(i j) \
    = X^T
  $
]

We put that to zero and move around things:
$
  X^T X w = X^T u \
  w = underbrace((underbrace(X^T, d times n) underbrace(X, n times d))^(-1), d times d) underbrace(X^T, d times n) underbrace(y, n)
$

Space complexity: $O(d^2 + n d)$

Time complexity: $O(underbrace(d^3, "matrix inversion") + underbrace(d^2 n, "calculating the matrix"))$

Everything boils down to the dimensionality of the data $d$ and the number of the data $n$:
- small $d$, small $n$: everything in main memory
- small $d$, big $n$:
- big $d$, big $n$
- big $d$, big $n$:

// TODO: my pc turned off: small d, big n part addressed

Our loss function: $ ell = sum_(j=1)^n (w x^((j)) - y^((j)))^2 $
We want to minimize $w$.

=== Gradient Descent

Let's start with an algorithm to find the the local minimum of 1-variable function.

- we start by choosing a random value $x_0$
- we compute the first derivative of that point $f'(x_0)$
- we move to a point that depends on the derivative and its steepness $x_1 = x_0 - f'(x_0)$
- if the functions "well behaves", we will get closer and closer to the local minimum of that function
- when we reach the local minimum, the derivative is $0$ and it stops

We need to work on the "size" of the steps:
- too big: we can jump out of that local valley, and even start diverging
- too small: it will take a lot of time to reach the minimum

The biggest problem of this algorithm is that finds a local minumum, not the overall minimum.

This same idea can be applied to functions with a lot of variables:
$ x_(i+1) = x_i - gradient f(x_i) $
The gradient works as the derivative, it points to the opposite of the local minimum.
We also can apply a "learning rate", tweaking the size of the steps:
$ x_(i+1) = x_i - mr(alpha) gradient f(x_i) $

It is usually fixed, but it can be also depend ot the iteration: we start by taking big steps, then while the iterations progress, taking smaller steps:
$
  x_(i+1) = x_i - alpha_i gradient f(x_i), quad alpha_i = alpha_0 1/(n sqrt(i))
$

// TODO: understand how the contour plot can be used to draw functions of multiple variables.
// TODO: example with the contour plot and visualize the steps

=== Minimize loss function

We can use the gradient descent.
$
  (d ell) / (d w_k) &= sum_(j = 1)^u 2(w dot x^((j)) - y^((j))) d/(d w_k) w x^((j)) \
  &= sum_(j = 1)^n 2 (w x^((j)) - y^((j))) x_k^((j))
$

The gradient is all these partial derivatives ranging $k$:
$ nabla ell(w) = [(d ell(w)) / (d w_k)]_(1, ..., d) $

But this gets back to the full vector:
$ = sum_(j = 1)^n 2(w x^((j)) - y^((j))) x^((j)) $

This algorithm is very distributable, as every component of the sum can be distributed on a different node.

We can broadcast

At a local level (on each node/for each map task):
Time complexity: $O(d)$
Space complexity: $O(d)$

== Logistic Regression

Regression, the labels are numbers, but it makes no sense to sum them, these are just classes.

Let's start with the simplest case: binary labels ${-1, 1}$

$ (x^((1)), y^((1))), ..., (x^((n)), y^((n))), quad y^((j)) in {-1, +1} $

We want to identify a vector $w$ that can classify all the points.
In the geometric interpretation, the vector identifies an hyperplane taht divides the space into two areas.
All the points "above" the hyperplane, will be classified as $1$, all the other $-1$.

So we are interesed in the product between the vector $w$ and the point to classify $x$ and specifically its sign: $ "sign"(w x) = hat(y) $

We rate this with a 0/1 loss function:
$ ell_("01")(z) = cases(1 "if" z < 0, 0 "if" z > 0) $

The loss will be:
$ sum_(j = 1)^n ell_("01")(w x^((j))) y^((j)) $

// TODO: graph of this loss function

This function has a problem: it is not convex.
We are not able to apply the gradient descent on a non-convex function.
Let's try to change the loss function: we define the log-loss.
$ ell_(log)(z) = ln(1 + e^(-z)) $

This is a convex function.
So will minimze the log-loss:
$ w^* arg min_w sum_(j=1)^n ell_(log)(w x^((j))) y^((j)) $

We need to compute the gradient:
First of all we need the derivative of the log-loss function:
$
  ell_(log)^' & = 1/(1+e^(-z)) (-e^(-z)) \
              & = - (e^(-z) + 1 - 1)/(1 + e^(-z)) \
              & = - (1 - 1/(1+e^(-z)))
$

Then compute the partial derivatives:
$
  (d ell) / (d w_k) = sum_(j=1)^n -(1-1/(1+e^(-w x^((j)) y^((j))))) dot mr(d / (d w_k) w x^((j)) y^((j)))
$

$ mr(d / (d w_k) w x^((j)) y^((j))) = y^((j)) x_k^((j)) $

So:
$
  (d ell) / (d w_k) = sum_(j=1)^n -(1-1/(1+e^(-w x^((j)) y^((j))))) mr(y^((j)) x_k^((j)))
$

We need to minimize that gradient:
$
  nabla ell(w) = - sum_(j=1)^n (1-1/(1+e^(-w x^((j)) y^((j))))) y^((j)) x_k^((j))
$

What's the application of that logistic?

=== Sigmoid function

A sigmoid function on $beta$:
$ f_(beta)(x) = 1/(1+e^(-beta x)) $

The logistic function is a specific sigmoid function, with $beta$ fixed to $1$.

// TODO: whats that???
$ PP(Y = +1 | X = x) = 1 / (1 + e^(-w x)) $

This is a smooth treshold, it outputs a real number between $0$ and $1$.

We want to conver that into a binary classification, to this end we can use ROC curves.

=== ROC Curves

$ "TPR" = "TP"/("TP" + "FN") $
$ "FPR" = "FP"/("TP" + "FN") = 1 - "TNR" $

// TODO: graph of the roc curve
- perfect classifier TPR = 1, TNR = 1
- always negative: TPR = 0, TNR = 1
- always positive: TPR = 1, TNR = 0
- always wrong: TPR = 0, TNR = 0
- random classifier: TPR = 1/2, TNR = 1/2
- on the diagonal, it it still random, but with a different probability on the coin flip

By changing the treshold, we can plot a trajectory on the square plane.
We can use that to decide the treshold

// No need to worry about it, I'm here to help.
// Here are Jack's fabulous notes about this part:

== Linear Regression

We speak of *regression* in supervised learning when the labels associated with my objects have numerical properties.
I talk of regression because the output is not a class (discrete), but I am in a space typically continuous with "nice" mathematical properties.

In *Linear Regression*, the predictor is a linear function.

Given a dataset of examples in a sequence ${(x_1, y_1), (x_2, y_2), ..., (x_n, y_n)}$, where each point $x$ is a vector in a $d$-dimensional space.

Let $y$ be the real value and $hat(y)$ be the prediction.
How do we compute the predictions? Since we are using linear functions, it's just a dot product between a weight vector and our item:

$ hat(y) = w dot x $

#note[
  I can also *inject non-linearities* in other ways while keeping the model linear in parameters ($w$).
  Instead of considering just the components of the vectors, I can consider all their products (polynomial expansion) or augment the dimensions of my points.

  Basically: map $x -> phi(x)$ and then do $w dot phi(x)$.
]

=== The Loss Function

At first, I need a tool to measure how well the prediction performs.
I can measure how close the various predictions are to the real values using the *Sum of Squared Errors*:

$ "SSE" = sum_(j=1)^n (y_j - hat(y)_j)^2 $

Let's recall that substituting the prediction formula, this is equal to:

$ l(w) = sum_(j=1)^n (y_j - w dot x_j)^2 $

This is what I call a *Loss Function*. My goal is to find the best weights $w^*$ that minimize this error:

$ w^* = "argmin"_w l(w) $

=== Vector Formulation & Derivation

Let's reformulate the problem in *vector form* (it's much cleaner).
I stack all the $n$ objects one on top of the other, obtaining a matrix $X$ of size $n times d$.
I can do the same with labels and obtain a vector $y$ with $n$ components.

Note that $w$ is a vector in my space ($d times 1$). It is perfectly fine to compute the product $X w$. The result will be a vector where the $j$-th component is the prediction for the $j$-th item. So this is nothing but $hat(y)$!

So, if I compute $y - X w$, it will be a vector which in each component will have the difference between the true value and the prediction.
Therefore, my loss function in matrix notation is:

$ w^* = "argmin"_w ||X w - y||^2 $

How do I find the minimum? I need to take the derivative and set it to zero. But *what is the derivative of a vector?*

First, let's recall the concept of *partial derivative*. It is nothing but what I obtain by fixing a constant and treating the rest as a variable I can derive.

#example[
  If I have a function $f(x, y) = sin(x + y) dot x$, the partial derivative with respect to $x$ is:
  $ (partial f) / (partial x) = x dot cos(x + y) + sin(x + y) $
  *(Treating $y$ as a constant)*.
]

When we move to vectors, the closest concept to the derivative is the *Jacobian Matrix* ($J$).
The Jacobian is the matrix of all first-order partial derivatives of a vector-valued function.

If $f(x)$ outputs a vector, then the Jacobian $J$ is the matrix where $J_(i j) = (partial f_i)/(partial x_j)$.

#note[
   In my raw notes, I compared this to a "second derivative".
   To be precise:
   - *Gradient* ($nabla$): First derivative of a scalar function (outputs a vector).
   - *Jacobian* ($J$): First derivative of a vector function (outputs a matrix).
]

In our specific case, we are interested in the term $X w$. Since this is a linear transformation, its derivative (the Jacobian) is constant, just like the derivative of $a x$ is $a$.

$ J_w (X w) = X $

Now, applying the Chain Rule to our loss function $|| X w - y ||^2$:

$ nabla_w ||X w - y||^2 = 2(X w - y)^T dot J(X w - y) $

Substituting the Jacobian we found:

$ nabla_w l(w) = 2 (X w - y)^T X = 2 X^T (X w - y) $

To find the minimum, I set the gradient to 0:

$ 2 X^T (X w - y) = 0 $
$ X^T X w - X^T y = 0 $

$ X^T X w = X^T y $

This is known as the *Normal Equation*. Assuming $(X^T X)$ is invertible, I can solve for $w$:

$ w = (X^T X)^(-1) X^T y $

=== Complexity Analysis

Let's analyze the costs of this operation:
- *Space Complexity:* $O(d^2 + n d)$. I need to store the data ($n d$) and the matrix $X^T X$ ($d^2$).
- *Time Complexity:* $O(n d^2 + d^3)$.
  - $n d^2$ to compute the matrix product $X^T X$.
  - $d^3$ to invert the matrix (or solve the system).

Both things can go big. We need to distinguish cases based on $N$ (number of points) and $d$ (features):

1. *Small $d$, Small $n$*: I will be able to do all in Main Memory (MM). Trivial (not for our course).
2. *Big $d$, Small $n$*: This requires *Dimensionality Reduction*. If each sample is too big to be computed, I have to compress data to reach a reasonable dimensionality containing all the information (we'll see PCA later).
3. *Small $d$, Big $n$*: This is our focus for *Massive Datasets*.

=== Computing with Small $d$, Big $n$

Let's analyze the complexity in the *Small $d$, Big $n$* case.
I can fit the final result $w$ and the matrix $X^T X$ ($d times d$) in MM, but I cannot think of computing the transpose and product in a local way if $X$ ($n times d$) is massive.

The real problem is producing and storing the intermediate matrix $X^T X$ efficiently.

Standard matrix multiplication for $P = A B$ is defined as $P_(i j) = sum_k A_(i k) B_(k j)$.
But I can rewrite this using the *Outer Product* approach.

$ P = A B = sum_(k=1)^c P^k = sum_(k=1)^c A_(*k) times B_(k*) $

Where $A_(*k)$ is the $k$-th column of $A$ and $B_(k*)$ is the $k$-th row of $B$.
Basically, I am summing up *outer products* (a column times a row gives a matrix).

#example[
  Outer product of vectors:
  $ vec(a, b) times [c, d] = mat(a c, a d; b c, b d) $
]

So, by applying this formula to our problem $X^T X$:
- The columns of $X^T$ are the rows of $X$ (let's call the $k$-th row of $X$ as $x_k$).
- The rows of $X$ are... well, the rows of $X$.

So the multiplication becomes a sum of outer products of each data point with itself:

$ X^T X = sum_(k=1)^n x_k x_k^T $

Why is this cool?
Because $x_k x_k^T$ is a small $d times d$ matrix. The difference is that storing these individual elements is affordable.
The thing that I do within this sum can be easily done by a local machine for a single point (or a chunk of points).

Summing $n$ matrices? This sounds like a job for my dear friend *MapReduce*.

- *Map*: Each mapper takes a subset of rows (points $x_k$), computes the local outer product $x_k x_k^T$ (a $d times d$ matrix), and outputs it.
- *Reduce*: Sums up all the $d times d$ matrices to get the final $X^T X$.

Once I have $X^T X$ (which is small, $d times d$), I can invert it locally in MM and solve the regression.


//jack's notes from 24/02/2026

=== both $n$ and $d$ grow

Remember that $n$ (or $m$) is the number of examples and $d$ is the number of dimensions/features.
We saw that finding the exact mathematical solution for Linear Regression has a time complexity of $O(n d^2 + d^3)$ and a space complexity of $O(n d + d^2)$. 

But what happens when *both* dimensions grow? 
We simply cannot compute or invert the matrix $X^T X$.
We need to change our approach: we still want to minimize the loss function, because the better our weights $w$, the lower the sum of errors.
We just need to find this minimum iteratively instead of analytically.

#informally()[
  We use *Gradient Descent*.
  The gradient of a differentiable function points in the direction of the steepest ascent.
  To find a local minimum, we take iterative steps in the opposite direction of the gradient of the loss function with respect to the parameters.
]

The update rule is:

$ w_(i+1) = w_i - alpha nabla ell(w_i) $

If the algorithm reaches the optimum, the derivative there is $0$, resulting in $w_(i+1) = w_i - 0$.
The parameters stop updating, meaning the algorithm has successfully converged to the minimum.

#warning()[
  Gradient descent is a *local* optimization algorithm.
  It moves in the direction of steepest descent towards a local minimum.
  
  To control the size of the steps we take, we scale the gradient by a constant parameter: the *learning rate* ($alpha$).

  - If $alpha$ is *too large*, the updates will overshoot the minimum, causing the loss to diverge.
  - If $alpha$ is *too small*, the convergence will be exceedingly slow or get stuck in suboptimal regions.
]

Using a fixed learning rate is often inefficient.
It is standard practice to adjust it dynamically: larger steps at the beginning of the optimization when we are far from the minimum, and progressively smaller steps as we approach convergence. 
A common time-dependent decay strategy for the learning rate is:
$ alpha_i = alpha_0 / sqrt(i) $

Let's compute the gradient mathematically for a single weight component $w_k$.
The loss function is $ell(w) = sum_(j=1)^m (w dot x^((j)) - y^((j)))^2$.

Taking the derivative with respect to $w_k$:
$ (partial ell) / (partial w_k) = sum_(j = 1)^m 2(w dot x^((j)) - y^((j))) dot (partial) / (partial w_k) (w dot x^((j))) $

Notice that $w dot x^((j)) = sum_{i=1}^d w_i x_i^((j))$.
If we differentiate this sum with respect to $w_k$, all terms become zero except the $k$-th term, leaving just $x_k^((j))$.
$ (partial) / (partial w_k) (w dot x^((j))) = x_k^((j)) $

So our gradient for the $k$-th component is:
$ (partial ell) / (partial w_k) = sum_(j = 1)^m 2(w dot x^((j)) - y^((j))) x_k^((j)) $

#note[
$2(w dot x^((j)) - y^((j)))$ is a scalar multiplier for the feature value)
]

*The Algorithm:*

```pseudocode
fix w_0 (random initialization)
set alpha
i = 0
while not stop_condition:
    w_{i+1} = w_i - alpha * sum( 2 * (w_i * x^{(j)} - y^{(j)}) * x^{(j)} )
    i += 1
```
Thanks to this iterative approach, computing the gradient step at the local level (for a single data point) drops the complexities drastically to:

- Time Complexity: O(d)

- Space Complexity: O(d)

== Logistic Regression

We still have our data organized in (x,y) pairs, but unlike standard regression where labels are continuous, we are now dealing with Classification.
This means our labels are discrete. 
Specifically, we assume binary labels:

$ y^((j)) in {-1, 1} $

Our model learns a weight vector `w`.
The dot product wdotx yields a scalar that can be positive, negative, or 0.
Geometrically, $w dot x=0$ defines a hyperplane that partitions the feature space into two half-spaces.

If the dataset is linearly separable (e.g., all +1 points lie on one side of the hyperplane and all −1 points on the other), we can classify new observations by checking the sign of the dot product:

$ hat(y) = "sign"(w dot x) $

=== The 0-1 Loss Function

The most intuitive error metric for classification is the 0-1 Loss.
To formalize this, we evaluate the product between the true label and the prediction score, denoted as `z`:

$ z = y^((j)) (w dot x^((j))) $

Let's analyze the properties of z:

- If the classifier makes no error (True Positive or True Negative): the true label and the prediction have the same sign. Their product is strictly positive (z>0).

- If the classifier makes an error (False Positive or False Negative): the signs differ, resulting in a negative product (z < 0).

Therefore, the 0-1 loss for a single observation is defined as:

$ ell_(0/1)(z) = cases(1 "if" z < 0, 0 "if" z > 0) $

We aim to minimize the macro loss function over the entire dataset:
$ L = sum_(j=1)^m ell_(0/1) (y^((j)) (w dot x^((j)))) $
A perfect classifier yields L=0.
The value of this macro loss function directly represents the total count of misclassified examples.

=== The Log Loss Function

Can we use Gradient Descent to minimize the 0-1 loss? No.
The 0-1 loss is a step function: it is discontinuous at 0 and its derivative is exactly zero everywhere else.
Gradient Descent requires a non-zero gradient to update the weights.

To solve this, we replace the 0-1 loss with a continuous, convex function called the *Log Loss*:

$ ell_"log"(z) = ln(1 + e^(-z)) $

We aim to minimize this differentiable function using Gradient Descent.
Let's compute its derivative using the chain rule:

$ ell'"log"(z) = d/(d z) ln(1 + e^(-z)) $
$ ell'"log"(z) = 1 / (1 + e^(-z)) dot (-e^(-z)) = (-e^(-z)) / (1 + e^(-z)) $

#note[
We can algebraically manipulate this fraction into a more convenient form for later steps:
$ (-e^(-z)) / (1 + e^(-z)) = (1 - (1 + e^(-z))) / (1 + e^(-z)) = 1 / (1 + e^(-z)) - 1 = -(1 - 1 / (1 + e^(-z))) $
]

Next, we compute the partial derivative of the loss with respect to the weight component w_k.
Recall that z=y((j))(wdotx((j))). The partial derivative of z with respect to w_k is y((j))xk((j)).

Applying the chain rule:
$ (partial ell) / (partial w_k) = sum_(j=1)^n -(1 - 1 / (1 + e^(y^((j)) w dot x^((j))))) y^((j)) x_k^((j)) $

This gives us the full gradient vector:
$ nabla ell(w) = sum_(j=1)^n -(1 - 1 / (1 + e^(- y^((j)) w dot x^((j))))) y^((j)) x^((j)) $

Because this gradient is smooth and well-defined, we can now safely optimize Logistic Regression using the Gradient Descent algorithm.

#note[
Probabilistic Interpretation:
Beyond strictly predicting a class, Logistic Regression allows us to output class probabilities. We can model the label as a random variable Y and formalize the conditional probability P(Y=+−1∣X=x).
]

