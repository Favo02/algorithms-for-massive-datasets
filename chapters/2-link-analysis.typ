#import "../template.typ": *

#set math.equation(numbering: "(1.1)", supplement: "EQ")

= Link Analysis: PageRank

We analyze a _real world_ problem that requires the use of distributed computation (and thus MapReduce).

A *Search Engine*: given a _query_, it returns a list of _web pages_, sorted by _relevancy_.
Given the enourmous amount of web pages, no matter the query, multiple results will match that query.
Some results will be more relevant, other less relevant, and some even not relevant at all.
The goal of the search engine is to list pages that are relevant first.

/ First Approach\: Endogenous:
  The relevance is determined by some information stored *inside* the pages themself, as metadata, tags or terms.

  That was the idea implemented by _early web engines_, but consisted of a huge problem: it is easily exploitable.
  *Web spammers* could simply include all the most searched terms in the page, even if completely _unrelated_ to the real content of the page, making the search engire return their page.

/ Second Approach\: Exogenous:
  To solve this problem, we can use information that lives *outside* the page itself: the *links* connecting the web pages.

  The revolutionary idea implemented by Google to determine the importance of a page is that a page is _important_ if it is *linked* by _another important_ page.

  To calculate the importance of that other page the same process needs to be _reapplied_.
  This generates an _infinite recursion_.

  #nota[
    While this approach mostly solves the problem of web spammers, some other ways to manipulate the results have been invented (such as link spam).
  ]

We will focus on that second approach, the idea behind *PageRank* algorithm.
Some formalization is needed.

/ Web Graph: The web can be formalized as a _graph_, with pages as _nodes_ and links between them as _directed edges_.

/ Row-wise (RWS) and Column-wise (CWS) Stochastic Matrix: A matrix is row (or column)-wise stochastic if and only if:
  - the sum of each row (or column) is $1$
  - there are no negative entries
  Each row (or column) of these matrices describe a _probability distribution_.

/ Transition matrix $M$: The graph is represented by a Transition Matrix, where the entries denotes the presence/absence of an edge, with source node $s$ on columns and destination nodes $d$ on rows:
  $
    M_(d s) = cases(
      0 quad & "if" exists.not space "edge" s -> d,
      1/"outer degree"_s quad & "if" exists space "edge" s -> d
    )
  $
  The transition matrix is a _column-wise stochastic_ matrix.
  Each column is a _probability distribution_ and it denotes the destination of a surfer during the _random surfing process_ described below.

  #esempio[
    #figure(
      grid(
        columns: 2,
        gutter: 2em,
        {
          import fletcher: *

          let nodes = ("A", "B", "D", "C")
          let edges = (
            ("A", "B"),
            ("B", "A"),
            ("B", "D"),
            ("D", "B"),
            ("A", "D"),
            ("D", "C"),
            ("A", "C"),
            ("C", "A"),
          )

          diagram(
            node-stroke: .1em,
            for (i, n) in nodes.enumerate() {
              let pos = 135deg - i * 360deg / nodes.len()
              node((pos, 18mm), name: str(n), n)
            },
            for (from, to) in edges {
              let bend = if (to, from) in edges { 10deg } else { 0deg }
              edge(label(str(from)), label(str(to)), "-|>", bend: bend)
            },
          )
        },
        table(
          columns: 5,
          align: center,
          stroke: (x, y) => if x == 0 or y == 0 { none } else { .05em },
          inset: 5pt,
          [], [A], [B], [C], [D],
          [A], [$0$], [$1/2$], [$1$], [$0$],
          [B], [$1/3$], [$0$], [$0$], [$1/2$],
          [C], [$1/3$], [$0$], [$0$], [$1/2$],
          [D], [$1/3$], [$1/2$], [$0$], [$0$],
        ),
      ),
      caption: [Example graph with its Transition Matrix],
    )
  ]

== Random Surfing

To calculate the importance of a page a process called Random Surfing is used.

Some entities (called *surfers*) are initially (at time $t = 0$) distributed _evenly_ on the graph (each page has the same number of surfers).
At this moment, the _probability_ that a surfer is over a node $a$ is equal for all nodes $n$:
$ PP("surfer over node" a) = 1/n space forall a in "nodes", quad n = "number of nodes" $

At each _iteration_, each surfer moves _randomly_ on the graph, choosing one of the _outgoing edges_ of their current node and moving to the pointed page.
This means the surfers are *not* anymore _equally_ distributed and the probabilities have changed.

This process goes on until it *converges* _(if it does)_.
The resulting probabilities can be interpreted as the _importance_ of that node in the graph: the _higher_ the probability is, the more important the page is.

Once again, some formalization and algebraic concepts are needed to proof the convergence.

/ Vector $underline(v)(t)$: Vector of the probabilities that a surfer is over the node $i$ at time $t$.
  $ underline(v)_(i)(t) = PP("surfer over node" i "at time" t) $

  #nota[
    The matrix $M$ and vector $underline(v)$ are *compatible* for product.
  ]


  It can be defined inductively:
  $ underline(v)_(i)(0) = 1/n space forall i in n = PP("surfer over" i "at time" 0) $
  $
    underline(v)_(i)(t+1) & = PP(union.big("surfer over" j "at time" t, "moving from" j "to" i)) #<random-surfing-union-to-sum> \
    & = underbrace(sum_j PP(j -> i | "surfer over" j "at time" t), M_(i j) space ("fixed for any time" t)) dot underbrace(PP("surver over" j "at time" t), v_(j)(t)) #<random-surfing-chain-rule> \
    & = sum_j M_(i j) dot v_(j)(t)
  $

  #nota[
    The probability of the union of _disjoint_ events is equal to their sum (#link-equation(<random-surfing-union-to-sum>)).

    The probability of each event can be destructured using the #link("https://en.wikipedia.org/wiki/Chain_rule_(probability)")[chain rule] (#link-equation(<random-surfing-chain-rule>)).
  ]

  The whole vector can be updated for each step with a single *matrix-vector product*:
  $ underline(v)(t+1) = M underline(v)(t) $ <random-surfing-next-vector>

  This can be implemented with a very simple _infinite_ while loop.
  The *stopping* mechanism can be implemented in two ways:
  - stopping at a _fixed_ iteration number
  - compute the _absolute difference_ between each iteration and when it goes below an $epsilon$ then stop

  #esempio[
    The number of existing web pages is around $10^9$.
    The matrix $M$ is around $10^18$ entries ($approx 8000000 "TB"$), while the vector $underline(v)$ is $10^9$ entries ($approx 8 "GB"$).

    We can use the matrix-vector product approach described in the previous chapter with $underline(v)$ stored in RAM. // TODO: link to section
  ]

/ Eigenvalues $lambda$ and Eigenvectors $underline(e)$:
  Given a square matrix $A$, we denote as $lambda$ an _eigenvalue_ and as $underline(e)$ the corresponding _eigenvector_ (for each eigenvalue one eigenvector exists and vice versa):
  $ A underline(e) = lambda underline(e) $ <eigenvalue-definition>

  #nota[
    A matrix is a _linear transformation_ for a vector (their product results in another vector).

    If applying the linear transformation ($A$) to the vector $underline(e)$, the _direction_ of the vector is _unchanged_ or _reversed_ (it gets only scaled by a constant quantity $lambda$), then $underline(e)$ is an eigenvector for the matrix $A$ and $lambda$ its eigenvalue.
  ]

  A matrix of dimension $n times n$, admits $n$ pairs of eigenvalues and eigenvectors.
  We can rank them by non-increasing value of the eigenvalue:
  $ (lambda_1, underline(e)_1), ..., (lambda_n, underline(e)_n) $
  $ lambda_1 >= ... >= lambda_n $

  The $n$ eigenvectors form a _linear basis_ for the $n$-dimensional vector space $RR^n$.
  $ {e_1, ..., e_n} = "linear basis" $

  #nota[
    Linear basis: each single possible vector of that space can be expressed as a linear combination (sum of scaled versions) of the basis vectors. This means any vector $underline(v) in RR^n$ can be written as $underline(v) = alpha_1 underline(e)_1 + ... + alpha_n underline(e)_n$ for some scalars $alpha_1, ..., alpha_n$.
  ]

== Convergence of Random Surfing

#teorema("Theorem")[
  The random surfing process will *converge* on a CWS matrix.
  In other words, the vector $underline(v)$ will converge to a _non-null_ value.

  #dimostrazione[
    For this proof, we need a few intermediate results:
    - the vector $underline(v)$ aligns with $lambda_1^t a_1 underline(e)_1$ (#link-teorema(<random-surfing-power-method>))
    - the main _eigenvalue_ should be $lambda_1 = 1$ (#link-teorema(<random-surfing-principal-eigenvalue-1>))
    - a CWS matrix admits $lambda = 1$ as eigenvalue (#link-teorema(<random-surfing-admits-lambda>))
    - a matrix and its transpose share the same eigenvalues (#link-teorema(<random-surfing-transpose-eigenvalues>))
    - the product of a matrix $A^k$ produce $lambda^k$ eigenvalue (#link-teorema(<random-surfing-power-eigenvalues>))
    - given a RWS matrix $A$, $A^k$ is still RWS (#link-teorema(<random-surfing-ak-still-rws>))
    - the principal eigenvalue of a CWS matrix is $lambda_1 = 1$ (#link-teorema(<random-surfing-lambda-1>))

    In particular, by #link-teorema(<random-surfing-principal-eigenvalue-1>) and #link-teorema(<random-surfing-lambda-1>), the vector converges, so the algorithm converges to a non-null vector of importances.
  ]
]

_The intermediate results shown below are commented with some _informal_ reasoning on why are we pursuing that result._

#teorema("Theorem (Power Method)")[
  When $t$ increases, the vector $underline(v)(t)$ *aligns* with the $lambda_1^t a_1 underline(e)_1$.

  #dimostrazione[
    Because $underline(v) in RR^n$, then we can rewrite it as a _linear combination_ of the basis:
    $ underline(v)(0) = alpha_(1) underline(e)_1 + ... + alpha_n underline(e)_n $

    Then we can multiply by the matrix $A$ to get the next vector (as per #link-equation(<random-surfing-next-vector>)):
    $
      underline(v)(1) & = mr(A)(alpha_(1) underline(e)_1 + ... + alpha_n underline(e)_n) \
      & = alpha_1 mr(A) underline(e)_1 + ... + alpha_n mr(A) underline(e)_n & #comment[by distributing $mr(A)$] \
      & = alpha_1 mr(lambda_1) underline(e)_1 + ... + alpha_n mr(lambda_n) underline(e)_n & #comment[by eigenvalue definition #link-equation(<eigenvalue-definition>)] \
      \
      underline(v)(2) & = mb(A)(alpha_1 lambda_1 underline(e)_1 + ... + alpha_n lambda_n underline(e)_n) \
      & = alpha_1 lambda_1 mb(A) underline(e)_1 + ... + alpha_n lambda_n mb(A) underline(e)_n \
      & = alpha_1 lambda_1^mb(2) underline(e)_1 + ... + alpha_n lambda_n^mb(2) underline(e)_n \
    $
    Generalized over $t$:
    $
      underline(v)(t) & = alpha_1 lambda_1^t underline(e)_1 + ... + alpha_n lambda_n^t underline(e)_n \
      & = mr(lambda_1^t)(alpha_1 underline(e)_1 + ... + (alpha_n lambda_n^t underline(e)_n)/mr(lambda_1^t)) & #comment[by factoring $mr(lambda_1^t)$] \
      & = mr(lambda_1^t)(alpha_1 underline(e)_1 + ... + alpha_n (lambda_n / mr(lambda_1))^mr(t) underline(e)_n)
    $

    Because the eigenvalues are sorted, $lambda_1^t$ will always be the biggest $lambda_n^t$.
    When $t$ increases, the other terms will go to $0$, meaning the vector will *align* with $lambda_1^t a_1 underline(e)_1$:
    $
      underline(v)(t -> infinity) & = lambda_1^t (alpha_1 underline(e)_1 + ... + alpha_n mr(0) underline(e)_n) \
                                  & = lambda_1^t a_1 underline(e)_1 space qed
    $

    #attenzione[
      We cannot speak of _convergence_ as $t$ is still in the equation, so we say _align_.
    ]
  ]
] <random-surfing-power-method>

_When is that result useful? We need to calculate the importance of the pages, the vector must converge._

#teorema("Theorem")[
  The algorithm will be _useful_ only when the principal eigenvalue of the matrix $A$ is $lambda_1 = 1$.

  #dimostrazione[
    Let's analyze the behaviour of $lambda_1$ when $t$ increases:
    $
      lambda_1^t =_(t->infinity) cases(
        infinity & quad "if" lambda_1 > 1,
        0 & quad "if" lambda_1 < 1,
        1 & quad "if" lambda_1 = 1,
      )
    $

    This means the probability vector will converge for $lambda_1 < 1$ and $lambda_1 = 1$.

    But when $lambda_1 < 1$ the vector will converge to $0$, meaning _all_ the pages of the web will have _importance_ $0$, making the whole algorithm _useless_.
    The only useful case is $lambda_1 = 1 space qed$.
  ]
] <random-surfing-principal-eigenvalue-1>

_Does the matrix $A$ even admits $lambda = 1$ as eigenvalue?_

#teorema("Theorem")[
  A column-wise stochastic (CWS) matrix $A$ admits $lambda = 1$ as an eigenvalue.

  #dimostrazione[
    A CWS matrix has the property that each column sums to $1$:
    $ sum_i A_(i j) = 1 quad forall j $

    Consider the vector formed by all ones $underline(1) = (1, ..., 1)^T$.
    Multiplying $A$ by this vector:
    $ (A underline(1))_i = sum_j A_(i j) dot 1 = sum_j A_(i j) = 1 $

    Therefore:
    $ A underline(1) = underline(1) $

    This means $underline(1)$ is an eigenvector of $A$ with corresponding eigenvalue $lambda = 1 space qed$.
  ]
] <random-surfing-admits-lambda>

_We just showed that $lambda = 1$ is an eigenvalue for $A$, but is it the principal one?
For this we need another two intermediate result on matrices._

#teorema("Lemma")[
  A matrix $A$ and its transpose $A^T$ share the same *eigenvalues* (not eigenvectors).
  $ A underline(w) = lambda underline(w) $
  $ A^T underline(u) = lambda underline(u) $
] <random-surfing-transpose-eigenvalues>

#teorema("Lemma")[
  If $underline(w)$ is an eigenvector of matrix $A$ with eigenvalue $lambda$, then:
  $ A underline(w) = lambda underline(w) $
  $ A^k underline(w) = lambda^k underline(w) $
  for any positive integer $k$.
] <random-surfing-power-eigenvalues>

#teorema("Theorem")[
  If a matrix $A$ is row-wise stochastic (RWS), then $A^k$ is also RWS for any positive integer $k$.

  #nota[
    - $a_(i j)$: element of the original matrix $A$

    - $a_(i j)^((k))$: element of the matrix $A^(k)$

    - $a_(i j)^((k+1))$: element of the matrix $A^(k+1)$
  ]

  #dimostrazione[
    We prove by induction on $k$.

    / Base case ($k = 1$): $A^1 = A$ is RWS by assumption $qed$.

    / Induction step: We assume $A^k$ is RWS:
      $ sum_j a^((k))_(i j) = 1 quad forall i $

      We need to prove that $A^(k+1) = A^k dot A$ is RWS:
      $ sum_j a^((k+1))_(i j) = 1 quad forall i $

      Expanding the matrix-matrix multiplication:
      $ a^((k+1))_(i j) = sum_s a^((k))_(i s) a_(s j) $

      For fixed $i$:
      $
        sum_j a_(i j)^((k+1)) & = sum_j sum_s a_(i s)^((k)) a_(s j) \
        & = sum_s a_(i s)^((k)) underbrace(sum_j a_(s j), = 1) quad& #comment[$=1$ by original assumption] \
        & = sum_s a_(i s)^((k)) dot 1 \
        & = underbrace(sum_s a_(i s)^((k)), = 1) & #comment[$=1$ by induction hypothesis] \
        & = 1 quad forall i space qed
      $
  ]
] <random-surfing-ak-still-rws>

_Now we can prove that $lambda = 1$ is the _principal_ eigenvalue for a CWS matrix._

#teorema("Theorem")[
  For a column-wise stochastic (CWS) matrix $A$, the eigenvalue $lambda = 1$ is the principal eigenvalue.

  #dimostrazione[
    Prove by contradiction: assume there exists an eigenvalue $lambda > 1$:
    $ A underline(u) = lambda underline(u) $

    Consider $B = A^T$, since $A$ is CWS, $B$ is RWS.
    By #link-teorema(<random-surfing-transpose-eigenvalues>), they share the same eigenvalue:
    $ B underline(w) = lambda underline(w) $

    Consider $C = B^k$, by #link-teorema(<random-surfing-ak-still-rws>) is still a RWS matrix.
    By #link-teorema(<random-surfing-power-eigenvalues>), for any positive integer $k$:
    $ B^k underline(w) = C underline(w) = lambda^k underline(w) $

    Let $w_max = max(w_1, ..., w_n)$.
    Component-wise for any $i$:
    $
      lambda^k w_i & = sum_j c_(i j) w_j             &                  #comment[by definition] \
                   & <= sum_j c_(i j) w_max \
                   & <= w_max mr(sum_j c_(i j)) quad & #comment[$w_max$ does not depend on $j$] \
                   & <= w_max dot mr(1) quad         &           #comment[by definition of RWS] \
    $

    Meaning:
    $ lambda^k w_i <= w_max $

    But we can chose an arbitrary big $k$, obtaining
    $ lambda^k w_i > w_max $
    which is a contradiction, therefore no eigenvalue $lambda > 1$ exists and $lambda = 1$ must be the principal eigenvalue $qed$.
  ]
] <random-surfing-lambda-1>

_Result: page-rank always converges if we run it on a column-wise stochastic._

== Structure of the Web

The internet graph is *not* column wise stochastic.

The web resembles a _bowtie_, with as main components:
- _Strongly connected component_ (SCC): a central part with strongly connected pages
- _In-bound component_: pages that can reach the SCC (but cannot be reached from the SCC)
- _Out-bound component_: pages that can be reached from the SCC (but cannot reach the SCC)
- _Tendrils_: pages that that reach out from the in-bound component or pages that reach in from the out-bound component
- _Tubes_: pages that can reach the out-bound component from the in-bound component
- _Disconnected components_: isolated pages

#figure(
  image("../assets/web-structure.png", width: 50%),
  caption: [Structure of the web],
)

In particular, exist structural problems that violate the column-wise stochastic property:
- _Dead ends_: nodes with out-degree equal to $0$.
  Surfers reaching dead ends are *trapped* (it is impossible for them to exit the node), causing the total amount of surfers to decrease.
  Over iterations, the number of surfers decreases until the result vector converges to *zero*, making the algorithm useless.
- _Spider traps_: cycles with no outgoing edges to *other components*.
  Once surfers enter a spider trap, they remain trapped indefinitely.
  Eventually, all surfers will end un *in the trap*, skewing the importance ranking.

Both issues prevent the transition matrix from being column-wise stochastic, breaking the convergence guarantee.
The solution is to introduce *teleportation*.

== Teleportation

At each _iteration_, a surfer either continues following links (with probability $beta$) or teleports to a random page (with probability $1 - beta$).
This process is called *teleportation* or *taxation* (a part of the surfers is reserved to be teleported, like a tax).

This modification transforms the transition matrix into a CWS matrix, ensuring convergence:
$
  underline(v)(t+1) = underbrace(beta M underline(v)(t), "same as before") + underbrace((1-beta)[1/n]_n, "each node has the "\ "same probability " 1/n \ "of receiving teleportation") quad beta in [0, 1]
$

The modified matrix is CWS because each column now sums to $1$, guaranteeing that the random surfing process converges to a stable importance ranking.

#nota[
  This system works with one assumption: the ranking for pages is the *same* for *all users*.
]

#set math.equation(numbering: none, supplement: "EQ")

= Lecture 4

PageRank can be generalized to rank anything that can be represented as a graph (any binary relation).

"She saw her duck" has multiple meanings:
- a woman saw the duck of another woman
- a woman saw her own duck
- a woman saw another woman ducking (abbassarsi)
- a woman cut (saw) her own duck

Even a simpler query like "Jaguar" has multiple meanings:
- the animal
- the car brand
- the macos operating system version

This is an obvious example that a query has multiple meanings.
We need to tailor the search engine for each user.
This means that every user needs a custom page rank instance.
There are abount 1 billion users, so that is obviously not feasible.
The obvious solution is to do some user clusterings.

#nota[
  Yahoo worked a little bit different that google: after the query there was also a taxonomy of categories (tree).
  After selecting the leaf of a category, the results were displayed.
]

We focus on rather a low number of categories (sports, language, religion, ...): $16$.
We can assign a category to each web page.

We also know which category the user is interested in (even just by asking, or by more complex methods like social media posts/emails, ...).
Each user is represented by a 16 bits number, each $1$ means the user in interested in that category (a bitmask).

There are $2^16 = 65536$ groups of users with the same interests.

PageRank worked in two main components: random surfing and teleportation.
We can modify only the latter part: the teleportation teleports only to pages with category that the user is interested in.

Formalization:

Given a number, $S$ are the pages that are of interest to the categories:
$ S = {"pages of interest"} $

PageRank worked that way with random surfing + teleportation:
$ underline(v)(t+1) = beta underline(v)(t) + (1-beta)[1/n]_n $

We can only change the pribability:
$
  underline(v)(t+1) = beta underline(v)(t) + (1-beta)cancel([1/n]_n) \
  underline(v)(t+1) = beta underline(v)(t) + (1-beta) underline(e)_S / (|S|)
$

$ underline(e)(s)_i = cases(1 "page" i "is of interest", 0 "otherwise") $

== Fooling pageRank

We are not web spammers.
Our end is now the one of the bad guys: we want to raise the ranking of a page (we cannot touch how pagerank works).

A page can be:
- inaccessible: we have not access at all
- accessible: the content can be controlled in part by us (like forums, social media, comments)
- controlled: pages we own (we can modify them)

We can then build a spam farm:
- we have a taget page $t$
- we have $m$ supporting pages

The target page links to all and only the supporting pages.
Each supporting page only links back to the target page.

To make this farm effective, we also add links from accessible pages to target page.
With this structure and selecting correctly supporting pages, the pagerank rank of page $t$ increases (a lot).

$ y = "PR of" t $
$ x = "PR from accessible pages" $
#nota[
  Accessible pages will have their PR score.
  After subtracting taxation (teleportation), the rest will be redistributed evenly to the links (so also to our target page): $x$.
]
$
  "PR of any supporting page" = (y overbrace(beta, "taxation")) / m + underbrace((1 - beta)(1/n), "incoming teleportation")
$

$
  "PR of" t = underbrace(x, "accessible pages") + underbrace(m beta ((y beta) / m + (1-beta)(1/n)), "supporting pages") + underbrace((1-beta)(1/n), "incoming teleportation")
$

The incoming teleportation amount is negligible.
This is still a positive quantity, so we will be understimating the PR of $t$.

$
            y & = x + beta^2 y + beta (1- beta) m/n \
  (1-beta^2)y & = x + beta(1-beta) m/n \
            y & = x / (1-beta^2) + beta/(1+beta) m/n
$

$beta$ is tipically $0.85$

So the incoming PR from accessible pages $x$ is amplified by a $3.6$ factor!
The important part is that, the second part is negligible because the fraction $m/n$ (our pages / total web pages) is really small.

So PageRank is not safe.
The good thing is that the pattern of the this farm is very easy to spot.
We could simply ignore their PageRank score, but spammers would find another way to farm (with a slightly different architecture).

So we instead modify the way PageRank works: *TrustRank*.
The idea is to assign each page a safe score (which is not binary, but a spectrum) and then use it in mechanism like $S$ (teleportation only to safe page).

The we compute PageRank $"PR"$ and TrustRank $"TR"$ and if their score is too different, then the page is not safe.

== Link Analysis: Hyperlink Induced Topic Search (HITS)

In page rank we decide if pages rank are important or not.

Here, we categorize the pages in two big classes and we determine the importance in one class and then in the other class.

The two classes are:
- Hubs: repository of links to interesting pages (university page / wikipedia home)
- Authorities: pages that speaks on a topic (page of this course / wikipedia page of a topic)

A page should be either an hub or an authority.
Each page has a degree of hubbiness and a degree of authoritativeness.

A page is a good hub if links to good authorities.
A page is a good authority if it is linkeed by good hubs.

Also in this algorithm we have a never ending recursion.

Formalization:
/ Connection matrix: the representation of the graph
  $ L = [l_(i j)]_(n times n) $
  $ l_(i j) = cases(1 "if edge" i -> j, 0 "otherwise:" i arrow.not j) $

We will have two vectors, one for hubs and one for authorities
:
$ underline(h), underline(a) $


These are all the authorative nodes that are reachable from $i$:
$ h_i = (L underline(a))_i = sum_j l_(i j) a_j = sum_(i -> j "exists") a_j $

Same things (but inverted, so transposed) for authorities:
$ a_i = (L^T underline(h))_i = sum_j l^T_(i j) h_j = sum_j l_(j i) h_j = sum_(j -> i "exists") h_j $

So:
$ underline(h) = L underline(a) $
$ underline(a) = L^T underline(h) $

So:
$ underline(a) = L^T L underline(a) $
$ underline(h) = L L^T underline(h) $

To compute that we could use the same thing used for PageRank (a matrix multiplied by a vector), simply compyting the matrices $L L^T$ and $L^T L$.

But these matrices are really sparse.

#attenzione[
  This approach will NOT converge, it will *diverge*.

  Each component will increase.
  So it will diverge to infinity.
]

The different thing is that in PageRank $underline(v)$ was always a probability distribution, while that doesnt hold there.
We can impose that, normalizing:
$ underline(h) = lambda L underline(a) $
$ underline(a) = mu L^T underline(h) $

== Implementation

We will not use Hadoop (which offers both file system and computing with MapReduce), but a more modern version: Spark.

#attenzione[
  Spark does NOT offer a distrbuted file system, so the storage needs to be handled by another technology.
]

Resilient distributed data set (rdd): the files in spark are stored in that system, that gets processed but is not persistent (it will likely disappear after the machine shuts down), we need to save the result somewhere.

- `spark.sparkContext`: context from where to start each action
- `parallelize`: transform an object that lives in RAM to an object that lives inside spark
- `textFile`: transform a file into a rdd
- `collect`: bring the data from the rdd into the RAM of the driver (the machine that runs, not meant to handle big data)
- `map`: exactly the map function in map reduce, applies a transformation
- `flatMap`: exactly like map, but flatten it if its multi-dimensional
- `take`: like collect, but instead of getting all the data, only selects as many random records as specified
- `reduceByKey`: reduction like in functional prorgarmming (this should be commutative and associative). It does both shuffling and reducing. It works only if the working set its applied to is in pair format
- `cache`: cache the rdd, e.g. keep it RAM instead of distributing over the whole system
