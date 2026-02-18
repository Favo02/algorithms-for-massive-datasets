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

$ sum_(j=1)^n (y^((j)) - hat(y)^((j)))^2 = sum_(j=1)^n (y^((j)) - w x^((j)))^2 = ell(w) $

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

How do I find the minimum? I need to take the derivative and set it to zero.
*What is the derivative of a vector expression?*

The partial derivative is nothing but what I obtain by fixing a constant and treating the rest as a variable I can derive.

#informally[
  Recall that for a scalar function, the derivative of $(a x - y)^2$ is $2a(a x - y)$.
  In matrix calculus, the gradient of $||X w - y||^2$ follows a similar pattern involving the transpose.
]

The gradient of the loss function is:
$ nabla_w ||X w - y||^2 = 2 X^T (X w - y) $

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

1.  *Small $d$, Small $n$*: I will be able to do all in Main Memory (MM). Trivial (not for our course).
2.  *Big $d$, Small $n$*: This requires *Dimensionality Reduction*. If each sample is too big to be computed, I have to compress data to reach a reasonable dimensionality containing all the information (we'll see PCA later).
3.  *Small $d$, Big $n$*: This is our focus for *Massive Datasets*.

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