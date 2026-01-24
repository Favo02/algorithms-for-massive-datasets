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

/ Transition matrix $M$: The graph is represented by a Transition Matrix, where the entries denotes the presence/absence of an edge, with source node $s$ on columns and destination nodes $d$ on rows:
  $
    M_(d s) = cases(
      0 quad & "if" exists.not space "edge" s -> d,
      1/"outer degree"_s quad & "if" exists space "edge" s -> d
    )
  $

  This matrix is a *Column-wise Stochastic* matrix (_CWS_):
  - the sum of each column is $1$
  - there are no negative entries

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

Once again, some formalization is needed to proof the convergence.

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

#teorema("Theorem")[
  The vector $underline(v)$ will converge.

  #dimostrazione[
    For this proof, we need a few intermediate results:
    - the main _eigenvalue_ should be $lambda_1 = 1$ (#link-teorema(<random-surfing-power-method>))

    // TODO: links to intermediate results
  ]
]

== Power Method

Given a square matrix $A$, we denote as $lambda$ an *eigenvalue* and as $underline(e)$ the corresponding *eigenvector* (for each eigenvalue one eigenvector exists and vice versa):
$ A underline(e) = lambda underline(e) $

#nota[
  A matrix is a _linear transformation_ for a vector (their product results in another vector).

  If applying the linear transformation ($A$) to the vector $underline(e)$, the _direction_ of the vector is _unchanged_ or _reversed_ (it gets only scaled by a constant quantity $lambda$), then $underline(e)$ is an eigenvector for the matrix $A$ and $lambda$ its eigenvalue.
]

_Multiple_ eigenvalues and eigenvectors for a matrix could exist.
We can rank them by non-increasing value of the eigenvalue:
$ (lambda_1, underline(e)_1), ..., (lambda_n, underline(e)_n) $
$ lambda_1 >= ... >= lambda_n $

The $n$ eigenvectors form a _linear basis_ for the $n$-dimensional vector space $RR^n$.
$ {e_1, ..., e_n} = "linear basis" $

#nota[
  Linear basis: each single possible vector of that space can be expressed as a linear combination (sum of scaled versions) of the basis vectors. This means any vector $underline(v) in RR^n$ can be written as $underline(v) = alpha_1 underline(e)_1 + ... + alpha_n underline(e)_n$ for some scalars $alpha_1, ..., alpha_n$.
]

#teorema("Theorem")[
  The algorithm will be _useful_ only when the principal eigenvalue of the matrix $A$ is $lambda_1 = 1$.

  #dimostrazione[
    Because $underline(v) in RR^n$, then we can rewrite it as:
    $ underline(v)(0) = alpha_(1) underline(e)_1 + ... + alpha_n underline(e)_n $

    Then we can multiply by the matrix $A$ to get the next vector (as per #link-equation(<random-surfing-next-vector>)):
    $
      underline(v)(1) & = mr(A)(alpha_(1) underline(e)_1 + ... + alpha_n underline(e)_n) \
                      & = alpha_1 mr(A) underline(e)_1 + ... + alpha_n mr(A) underline(e)_n \
                      & = alpha_1 mr(lambda_1) underline(e)_1 + ... + alpha_n mr(lambda_n) underline(e)_n \
                      \
      underline(v)(2) & = mb(A)(alpha_1 lambda_1 underline(e)_1 + ... + alpha_n lambda_n underline(e)_n) \
                      & = alpha_1 lambda_1 mb(A) underline(e)_1 + ... + alpha_n lambda_n mb(A) underline(e)_n \
                      & = alpha_1 lambda_1^mb(2) underline(e)_1 + ... + alpha_n lambda_n^mb(2) underline(e)_n \
    $
    Generalized over $t$:
    $
      underline(v)(t) & = alpha_1 lambda_1^t underline(e)_1 + ... + alpha_n lambda_n^t underline(e)_n
    $
    Factoring $mr(lambda_1^t)$:
    $
      underline(v)(t) & = mr(lambda_1^t)(alpha_1 underline(e)_1 + ... + (alpha_n lambda_n^t underline(e)_n)/mr(lambda_1^t)) \
      & = mr(lambda_1^t)(alpha_1 underline(e)_1 + ... + alpha_n (lambda_n / mr(lambda_1))^mr(t) underline(e)_n)
    $

    Because the eigenvalues are sorted, $lambda_1^t$ will always be the biggest $lambda_n^t$.
    When $t$ increases, the other terms will go to $0$, meaning the vector will *align* with $lambda_1^t a_1 underline(e)_1$:
    $
      underline(v)(t -> infinity) & = lambda_1^t (alpha_1 underline(e)_1 + ... + alpha_n mr(0) underline(e)_n) \
                                  & = lambda_1^t a_1 underline(e)_1
    $

    #attenzione[
      We cannot speak of _convergence_ as $t$ is still in the equation, so we say _align_.
    ]

    Let's analyze the behaviour of $lambda_1$:
    $
      lambda_1^t =_(t->infinity) cases(
        infinity & quad "if" lambda_1 > 1,
        0 & quad "if" lambda_1 < 1,
        1 & quad "if" lambda_1 = 1,
      )
    $

    This means the probability vector will converge for $lambda < 1$ and $lambda = 1$.
    But when $lambda < 1$ the vector will converge to $0$, meaning all the pages of the web will have _importance_ $0$, making the whole algorithm _useless_.
    The only useful case is $lambda = 1 space qed$.
  ]
] <random-surfing-power-method>


#todo

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

The graph that describes the web is NOT strongly connected (page 181 book).
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
