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
