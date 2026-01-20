#import "../template.typ": *

= Link Analysis: PageRank

Problem that needs to be solved using distributed computing (and of course MapReduce).

Search engine: there is an enourmous amount of web pages, and no matter what query, multiple results match that query.
Some results are more relevant, other less relevant, other not relevant at all.

The goal of the search engine is to list pages that are relevant first.
This is done in an *endogenous* way: it is achieved by looking for information *inside* the pages themself.

The first web engines worked taking terms from the query and returning all pages included that terms.
This can be exploited by web spammers that included a lot of terms also not related to the actual page.

To tackle this problem, we can use *exogenous* information (that lives outside the page itself).
These external information are the links.

A page is important if it is linked by an important page.
To determine the importance of the other page we need to reapply the same process.
This triggers a never ending recursion.

This can be represented by a graph with direct edges as links.

There exist random surfers (a lot of them), that move randomly on the graph.
These are initially distributed "evenly" these surfers.

Initially the probability of a surfer of being in a node is $1/n$ for each node $n$.

At each time, each surfer select a random edge (a random link) and moves to the node (page) pointed by that link.

THe surfers are not anymore randomly distributed, the probability that a surfer is over a node have changed:
$[2/12, 6/12, 4/12]$

This process goes on indefinetely.

The probabilities will converge, e.g. after 100 iterations the vector of probabilities do not change anymore (or change slightly).

This can be applied back to the importance of a graph: the higher the probability is, the more important a page is.

We need to convert this into a mathematical rigorous system so that we can proof things on it.

/ Transition matrix $M$: columns: nodes as a source, rows: nodes as a destination. $0$ where no edge exists, $1/"outer degree"$ where exist (number of outgoing nodes from that node).
  This is a *column-wise Stochastic* (c.w.s.) matrix:
  - summing the column will sum up to $1$
  - no negative entries

/ Vector $underline(v)(t)$: Vector of the probabilities of the surfers in each node at time $t$.

The matrix $M$ and vector $underline(v)$ are compatible for product.

- $ v_(i)(0) = 1/n = bb(P)("in" i "at time" 0) $
- $
    v_(i)(t+1) = bb(P)("in" i "at time" t+1) \
    = bb(P)(union.big ("in" j "at" t, "moving from" j "to" i)) \
    = sum_j bb(P)(j->i | "in" j "at" t) dot bb(P)("in" j "at" t)
  $
  We can simplify: the probability of transitioning don't change (the graph is immutable) and is equal to $M[i][j]$
  $ = sum_j M[i][j] v_(j)(t) $
  So we can compute each step of the vector in and inductive way:
  $ underline(v)(t+1) = M underline(v)(t) $
  This can be implemented with a very simple infinite while loop.

  To decide when to stop we can use any trivial way:
  - stopping at a fixed iteration number
  - compute the difference between each iteration and when it goes below an $epsilon$ then stop

There exists around $10^9$ page, so the matrix is around $10^18$ entries, each one $8$ bytes, so around $approx 10^19$ bytes.

The matrix is definitely not even close to being store in RAM (not even on disk).
The vector ($10^9 dot 8$ bytes) is definitely storable in RAM ($approx 8$ GB).

#teorema("Theorem")[
  The probabilities will converge.

  #dimostrazione[

  ]
]

== Power Method

Given a square matrix:
- eigenvalue $lambda$
- eigenvector $underline(e)$

$ <=> A underline(e) = lambda underline(e) $

#nota[
  For each eigenvalue we have one eigenvector
]

#informalmente[
  A vector multiplied by a matrix gives a vector.
  So a matrix can be seen as a transformation for a vector.

  Applying an eigenvalue to a vector, its direction stays the same, the only thing that change is its size.
]

We can rank the eigenvectors by the non-increasing value of eigenvalue.
$ (lambda_1, e_1), ..., (lambda_n, e_n) $
$ lambda_1 >= lambda_2 >= ... >= lambda_n $

The $n$ eigenvalues form a linear basis for the space.
$ {e_1, ..., e_n} = "linear basis" $

#nota[
  Linear basis: each single possible vector of that space can be expressed by a sum of the basis scaled up.
]

$
  underline(v)(0) = alpha_(1) underline(e_1) + ... + alpha_n underline(e_n)
$

$
  v(1) & = A(alpha_(1) underline(e_1) + ... + alpha_n underline(e_n)) \
       & = alpha_1 A e_1 + alpha_2 A e_2 + ... + alpha_n A e_n \
       & = alpha_1 lambda_1 e_1 + alpha_2 lambda_2 e_2 + ... + alpha_n lambda_n e_n \
       \
  v(2) & = A(alpha_1 lambda_1 e_1 + alpha_2 lambda_2 e_2 + ... + alpha_n lambda_n e_n) \
       & = alpha_1 lambda_1 A e_1 + ... + alpha_n lambda_n A e_n \
       & = alpha_1 lambda_1^2 e_1 + ... + alpha_n lambda_n^2 e_n \
       \
  v(t) & = alpha_1 lambda_1^t e_1 + ... + alpha_n lambda_n^t e_n \
       & = lambda_1^(t)(alpha_1 e_1 + alpha_2 (lambda_2 / lambda_1)^t e_2 + ... +)
$

But these are sorted, so when $t$ increases, the vector *alignes* with $lambda_1^t a_1 e_1$.

#attenzione[
  We cannot speak of "converge" as $t$ is still in the equation.
]

#nota[
  Scaling an eigenvector doesnt change the eigenvalue.
]

Let's analyze
- $lambda_1 > 1: lambda_1^t$ diverge
- $lambda_1 < 1: lambda_1^t$ converge to $0$ (but to the null vector, but this means all pages have importance $0$, useless)
- $lambda_1 = 1: lambda_1^t = 1$, the vector converges to the principal eigenvector

#teorema("Theorem")[
  If a matrix is columns-wise stocastic, we can show that its principal eigenvalue is $1$.
]

Finding the eigenvalues of a squadre matrix:
- start from a matrix
- subtract lambda times the identity matrix
- put to $0$
$ det(A - lambda I) = 0 $
We can leverage the transposition:
$ det(A - lambda I)^T = det(A^T - lambda I) $

#teorema("Fact1")[
  $A and A^T$ same eigenvalue
]

#teorema("Fact2")[
  $1$ is an eigenvalue for each RSM (rowwise stochastic matrix) $A$

  #nota[
    RSM: $sum$ foreach row = $1$
  ]
]

#teorema("Fact3")[
  $A underline(1) = 1$
  Multipling the matrix for the vector $1$ results in $1$.

  So $underline(1)$ is an eigenvector and $1$ is an eigenvalue.

  So $1$ is an eigenvalue of any stochastic matrix.
]

We just showed that one eigenvalue there is one, but we need to proof that the principal eigenvector is one.

#teorema("Theorem")[
  If $A$ is RWS, $A^k$ is still RWS.

  #dimostrazione[
    Proof by induction.

    Base: $k = 1$, $A^1 = A$ trivial.

    Induction step: $A$ is rws, $A^(k+1)$
    $ A^(k+1) = A^k dot A $
    $ a^((k+1))_(i j) = sum_s a^((k))_(i s) a_(s j) $
    ...
    $ sum_j underbrace(a^((k))_(s j), = 1) = 1 $

  ]

  #dimostrazione[
    We should also talk about non-negative entries, but based on how we do construct these matrices, it is impossible that they exist.
  ]
]


$exists lambda, underline(v), quad A underline(v) = lambda underline(v), quad "with" lambda > 1, quad A "is CWS"$

The proof is by absurd, if no $lambda > 1$ exists, when the $lambda = 1$ eigenvalue must be the principal one.

$lambda$ is eigenvalue of $B = A^T$ with some associated eigenvector $underline(w)$: $B underline(w) = lambda underline(w)$

$ B^k underline(w) = underbrace(B dot ... dot B, k "times") dot underline(w) = lambda^k underline(w) $

$C = B^k, quad C underline(w) = lambda^k underline(w)$

$sum_j c_(i j) w_j = lambda^k w_i$
This holds for any value of $k$ and $lambda > 1$

Fix any $G$, then always:
$ lambda^k w_i > G $

Define $w_max = max_i w_i$, so:
$ sum_j c_(i j) w_max >= sum_j c_(i j) w_j $

So:
$ sum_j G_(i j) > G/w_max $

Recap:
- A is rws
- B is A transposed, so B is rws
- C is $B^k$, so C is rws
- so $C = 1$
- so $1 > G/w_max$, a quantity that I can fix as I want, impossible

Result: page-rank always converges if we run it on a column-wise stochastic.

But the internet graph is NOT column wise stochastic.

The graph that describes the web is NOT strongly connected.
It has a form that resembles a bowtie:
- the central component is a SCC (strongly connected component)
- two lateral components:
  - INbound component: links from them to the SCC
  - OUTbound component: links from the SCC to the OUTbound
There are more less important pages:
- Tendrils: page that from IN/OUT go to some isolated pages not in the SCC
- Tubes: from IN to OUT

Bad situations that exists in practice:
- Dead ends: node with outdegree equal to $0$.
  These make the transition matrix non cws.
  The surfers that end in a deadend are lost.
  The number of surfers at each iteration decreases (a leak): eventually the number of surfers will become $0$.
  The result vector will become the null vector.
- Spider traps: cycles with no exit.
  Random surfers gets trapped in that circle.
  Eventually all the surfers will end un in this trap.

We slightly modify the random surfing process: at each time a surfer either continues with the random surfing or gets *teleported* (also called taxation).

$ underline(v)(t+1) = , quad beta in (0, 1) $
$ underline(v)(t+1) = beta M underline(v)(t) + (1-beta)[1/n]_n $
$ ... $

#nota[
  This system works with one assumption: the ranking for pages is the same for all users.
]

#nota[
  This sytem was put in place to prevent web spamming.
  Malevolent agents found another way.
]

#text(size: 40pt)[SHE SAW HER DUCK]
