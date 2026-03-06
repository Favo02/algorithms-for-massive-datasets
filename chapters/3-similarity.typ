#import "../template.typ": *

= Similarity

With an _equality relation_ between objects in a universe, equality is dichotomous (true or false).
Similarity, instead, is a *spectrum* (e.g., plagiarism detection).

#example[
  How does Amazon suggest products?
  It detects users _similar_ to you and recommends products that similar users bought.
]

Similarity can be defined as a function:
$ s(x, y) -> RR $

For small datasets, we can compute similarity for all object pairs with a _simple loop_.
However, with massive datasets, even simple problems become _computationally expensive_.

== Jaccard Similarity

We focus on *text documents* and use Jaccard similarity as our measure:
$ J(S, T) = (|S inter T|) / (|S union T|) $

#warning[
  This measures _syntactic_ similarity only, not _semantic_ meaning.
  Sets ignore element *order* and *quantity*.
]

The Jaccard similarity is bounded between $0$ and $1$:
- $J(S, T) = 0 quad "if" S inter T = emptyset$
- $J(S, T) = 1 quad "if" S = T$

=== $k$-grams and Shingles

This similarity is defined using sets, but text documents are not represented using sets, but using _strings_.
To convert a long string into a set of elements we _tokenize_ the document, producing a set of *shingles*.
Before this stage, the text is often *preprocessed*, removing multiple whitespaces or removing stop words and conjunctions.

#note[
  A token can be anything, a single _character_, a _word_ or even a _phrase_.

  From now on, we will consider as shingle a character.
]

Then we construct $k$-grams (or $k$-shingles or only shingle): a sequences of $k$ consecutive *tokens* (characters, words, or other units).
The set of these shingles is the set on which the similarity is applied.

#example[
  The text "Today and tomorrow will rain", with the shingles as characters and $k = 5$ generates the set: ${$"today", "oday\_", "day\_a", "ay\_an", ...$}$.
]

#warning[
  _Again,_ sets do not account for order or duplicates.
]

The parameter $k$ depends on the document type and size:
- *$k$ too small* ($k = 1$): almost all documents will generate the same set (the full alphabet).
  _Everything becomes similar._
- *$k$ too large* ($k = "document length"$): each document has one unique shingle.
  _Nothing is similar except identical documents._

A rule of thumb is that $k$ should be picked _large enough_ that the probability of any given shingle appearing in any given document is _low_.

#example[
  Working with emails, with the assumption that only $27$ characters can appear (the alphabet and the whitespace) and with $k = 5$, we can calculate the total possible $5$-grams: $ 27^5 approx 14 times 10^6 $

  A typical email is surely much smaller that $27^5$, so we would expect $k = 5$ to work well (and it does).
  But the calculation is a bit more complex, as more than $27$ characters can appear but not all with the _same probability_.
  We can approximate a probability closer to the reality by considering only $20$ possible characters.
]

In general $k = 5$ for email and $k = 9$ for larger documents are considered safe.

=== Storing Shingles

Storing each $k$-gram explicitly as a string requires $k$ bytes per shingle.
Instead, we could *hash* the shingle and store only the integer representing the bucket.
$ h("shingle") -> 32 "bits" $

#note[
  While this introduces some collisions, meaning two different shingles will be considered the same one, it works really well beacuse _most_ of the possible shingles _never occour_ (such as "kxsdw" string).
]

#example[
  Using $9$-shingles requires $72$ bits of storage, but hashing reduces this to just $32$ bits.
  This matches the space needed for _unhashed_ $4$-shingles, yet hashing $9$-shingles provides *better differentiation* quality: while $4$-shingles account also for very *rare* shingles, hashed $9$-shingles *uniformly distribute* rare shingles across buckets, improving effectiveness.
]

=== Charateristic Matrix

We can store documents using a binary matrix called the _characteristic matrix_:
- each row represents a *shingle* (identified by its hash bucket, a natural integer)
- each column represents a *document*
- an entry is $1$ if the document contains the shingle, $0$ otherwise

#example[
  Consider the documents:
  - $D_1 = "ab"$
  - $D_2 = "abc"$
  - $D_3 = "bc"$
  - $D_4 = "bcac"$

  Using $k = 2$ character shingles:
  - $D_1$: $\{"ab"\}$
  - $D_2$: $\{"ab", "bc"\}$
  - $D_3$: $\{"bc"\}$
  - $D_4$: $\{"bc", "ca", "ac"\}$

  Hashing shingles with the hash function:
  - $h("ab") = 0$
  - $h("bc") = 1$
  - $h("ca") = 2$
  - $h("ac") = 3$

  Characteristic matrix:
  #align(center)[
    #table(
      columns: 5,
      stroke: (x, y) => if x == 0 or y == 0 { none } else { .05em },
      [], [$D_1$], [$D_2$], [$D_3$], [$D_4$],
      [$0$], [1], [1], [0], [0],
      [$1$], [0], [1], [1], [1],
      [$2$], [0], [0], [0], [1],
      [$3$], [0], [0], [0], [1],
    )
  ]
]

To calculate the Jaccard similarity between two documents, we need to calculate:
- the *intersection*: number of rows that have $1$ for both documents
- the *union*: number of rows that have only one $1$

This idea works, but the charateristic matrix is *too big* to fit in memory.
We need to _compress_ this matrix, being able to compute the similarity without decompressing it.

=== Min Hash Function

We introduce a function that hashes a *document* into a *shingle*.
$ h : {"docs"} -> {"shingles"} $

To calculate a Min Hash Function three steps are done:
+ Fix a _row permutation_ (of the shingles) of the charateristic matrix
+ _Apply_ the permutation to the charateristic matrix
+ For each document, the resulting shingle is the _row with the first $1$_ in the permuted column

#example[
  An hash function $h_1$ with the documents from the last example:
  + fix a permutation of the rows: $[2, 0, 3, 1]$
  + permute the matrix:
    #align(center)[
      #table(
        columns: 5,
        stroke: (x, y) => if x == 0 or y == 0 { none } else { .05em },
        [], [$D_1$], [$D_2$], [$D_3$], [$D_4$],
        [$2$], [0], [0], [0], [1],
        [$0$], [1], [1], [0], [0],
        [$3$], [0], [0], [0], [1],
        [$1$], [0], [1], [1], [1],
      )
    ]
  + for each column, start traversing the column.
    The first one encountered in the column, is the result of the hash function (the shingle selected):
    $
      h_1(D_1) = 0 \
      h_1(D_2) = 0 \
      h_1(D_3) = 1 \
      h_1(D_4) = 2 \
    $

  By generating another permutation, we can obtain a different hash function $h_2$:
  + fix the permutation: $[3,1,2,0]$
  + permute the matrix:
    #align(center)[
      #table(
        columns: 5,
        stroke: (x, y) => if x == 0 or y == 0 { none } else { .05em },
        [], [$D_1$], [$D_2$], [$D_3$], [$D_4$],
        [$3$], [0], [0], [0], [1],
        [$1$], [0], [1], [1], [1],
        [$2$], [0], [0], [0], [1],
        [$0$], [1], [1], [0], [0],
      )
    ]
  + calculate the values of the hash function
    $
      h_2(D_1) = 0 \
      h_2(D_2) = 1 \
      h_2(D_3) = 1 \
      h_2(D_4) = 3 \
    $
]

#warning[
  All the values below the first one of each column are lost.
]

With that technique we are *losing* a lot of information on the documents.
The idea is to store *several* different hash functions instead of the whole matrix.

We could have one hash function for each permutation of the shingles (rows), so there exists $n!$ possible hash functions.

=== Signature Matrix

Storing _several_ hash functions is much _smaller_ than storing the entire characteristic matrix.
A *signature matrix* stores exactly this: the results of applying multiple hash functions to each document.

#example[
  The signature matrix for the documents of the last example is:
  $
    #align(center)[
      #table(
        columns: 5,
        stroke: (x, y) => if x == 0 or y == 0 { none } else { .05em },
        [], [$D_1$], [$D_2$], [$D_3$], [$D_4$],
        [$h_1$], [0], [0], [1], [2],
        [$h_2$], [0], [1], [1], [3],
      )
    ]
  $
]

#warning[
  This representation is an _approximation_, the whole characteristic matrix cannot be restored.
  The more hash functions used (rows of the signature matrix), the more accurate the approximation is.
]

The number of hash functions $n$ is a tradeoff: more functions give a better approximation of $J$ but cost more space and time.
Values in the range of 100-500 are typical in practice.

Instead, each permutation is _simulated_ by a random hash function on row numbers.
A simple and effective family is:
$ h(x) = (a x + b) mod p $
where $p$ is a prime number and $a, b$ are chosen randomly.
Such a function acts as a pseudo-random permutation of ${0, ..., p-1}$.

The characteristic matrix is _sparse_: documents contain only a small fraction of all possible shingles, so most entries are $0$.
Computing the signature matrix then only requires a single pass over it:

+ Initialize $"SIG"(i, c) = infinity$ for all hash functions $i$ and documents $c$.
+ For each row $r$ of the characteristic matrix:
  + Compute $h_i(r)$ for every hash function $i$: the hash of the _row index_ $r$ (a single integer), simulating where row $r$ would land under the $i$-th permutation.
  + For each document $c$ that has a $1$ in row $r$, update: $"SIG"(i, c) = min("SIG"(i, c), h_i(r))$.

At the end, $"SIG"(i, c)$ equals the minimum $h_i(r)$ over all rows where document $c$ has a $1$.
This is exactly the min hash value.

=== Signature Matrix and Jaccard Similarity

Given a signature matrix, we can estimate the Jaccard similarity between two documents without accessing the full characteristic matrix.

The key insight is that if we apply a _random_ hash function $H$ to two documents $S$ and $T$, the probability that they produce the same result equals the Jaccard similarity:
$ PP(H(S) = H(T)) = J(S, T) $

#warning[
  $H$ represents a _random_ hash function chosen uniformly from the set of all possible permutations, not a fixed function (the equivalent of an _aleatoric_ variable for functions).
  Each row of the signature matrix corresponds to one such random function.
]

#proof[
  Considering a specific hash function, for each row of the characteristic matrix, four cases exist:
  $
    mat(
      S, T;
      0, 0, quad "Z-type";
      0, 1, quad "Y-type";
      1, 0, quad "Y-type";
      1, 1, quad "X-type";
    )
  $

  The hash values $H(S)$ and $H(T)$ are equal if and only if the _first non-Z row_ is an _X-type row_.

  Computing the probabilities:
  $ PP(H(S) = H(T)) = "X-type rows" / "non-Z rows" = x / (x + y) $

  By definition, the Jaccard similarity is the intersection (both $1$s) over the union (at least one $1$):
  $ J(S, T) = (|S inter T|) / (|S union T|) = x / (x + y) space qed $
]

To estimate similarity from a signature matrix with $n$ rows, count how many rows produce equal hash values:
$ hat(J)(S, T) = "# matching rows" / n $

#example[
  For documents $S$, $T$, and $U$ with signature matrix:
  $
    mat(
      , S, T, U;
      h_1, 3, 3, 6;
      h_2, 2, 0, 2;
      h_3, 4, 4, 8;
    )
  $

  Similarities:
  $ hat(J)(S,T) = 2/3 approx 0.67 quad (h_1, h_3 "match") $
  $ hat(J)(S,U) = 1/3 approx 0.33 quad (h_1 "matches") $
]

The signature matrix solves the _space_ problem, but comparing all pairs is still quadratic in time: every couple of documents needs to be compared
$ binom(m, 2) approx m^2/2 "comparisons" $

#example[
  With $m = 10^6$ documents and $n = 250$ hash functions, the signature matrix takes roughly $1$ GB of memory, completely manageable.
  The time cost, however, is around $5 times 10^11$ comparisons: even at $1 mu s$ per comparison (far beyond current hardware), that amounts to roughly 6 days.
]

#warning[
  The signature matrix gives only an _approximation_ of the Jaccard similarity, results are not exact.
]

The solution is to avoid comparing _all_ pairs, and instead focus only on pairs that are _likely_ to be similar.

=== Locality Sensitive Hashing (LSH)

#informally[
  The signature matrix is divided into _bands_.
  If two documents share the _same values_ in at least one band, they are likely to be similar.

  To achieve that efficiently, _hashing_ is used.
]

We start with the signature matrix describing $n$ documents, generated using $k$ hash functions.
This matrix is divided $b$ *bands*, each containing $r$ *rows* (with $b dot r = k$).

For each band, hash the $r$-element column vector of each document into a bucket.
Two documents end up in the same bucket for a band if and only if their signature values in that band are *identical* (neglecting collisions).

Each document is sent to $b$ buckets (one per band).
Any pair of documents that *shares a bucket* (they contained the same values is at least one band) becomes a _candidate pair_.

#figure(
  {
    cetz.canvas({
      import cetz.draw: *
      set-style(stroke: (thickness: 0.5pt))

      let cw = 0.55 // column width
      let rh = 0.42 // row height

      // band-vals.at(b).at(c).at(r) = value at band b, document c, row r
      // Band 1: all three documents have different per-band vectors
      // Band 2: D1 = D2 = (2,4,1), D3 = (3,2,5)  → D1 and D2 collide
      // Band 3: all different again
      let bv = (
        (("1", "3", "2"), ("4", "1", "3"), ("2", "3", "5")),
        (("2", "4", "1"), ("2", "4", "1"), ("3", "2", "5")),
        (("4", "2", "3"), ("1", "5", "2"), ("5", "4", "1")),
      )

      let bfill = (rgb("#daeaf7"), rgb("#fef3cd"), rgb("#d5f5e3"))
      let bstroke = (rgb("#5dade2"), rgb("#d4ac0d"), rgb("#52be80"))
      let dcol = (rgb("#1a5276"), rgb("#1e8449"), rgb("#922b21"))

      let mw = 3 * cw
      let mh = 9 * rh

      // column headers
      for c in range(3) {
        content(((c + 0.5) * cw, 0.28), text(size: 7.5pt, fill: dcol.at(c))[$D_#(c + 1)$])
      }

      // matrix bands
      for b in range(3) {
        let y0 = -(b * 3 * rh)
        let y1 = -((b + 1) * 3 * rh)
        rect((0, y0), (mw, y1), fill: bfill.at(b), stroke: (paint: bstroke.at(b), thickness: 0.55pt))
        content((-0.6, (y0 + y1) / 2), text(size: 6.5pt)[band #(b + 1)], anchor: "mid-east")
        for c in range(3) {
          for r in range(3) {
            content(
              ((c + 0.5) * cw, -((b * 3 + r) * rh + rh / 2)),
              text(size: 6pt, fill: dcol.at(c))[#bv.at(b).at(c).at(r)],
            )
          }
        }
      }

      // column dividers
      for c in range(1, 3) {
        line((c * cw, 0), (c * cw, -mh), stroke: (paint: luma(165), thickness: 0.25pt))
      }
      content((mw / 2, -mh - 0.25), text(size: 6.5pt)[signature matrix])

      // ---- Buckets (stacked vertically within each band) ----
      let bkx = mw + 0.7 // left edge of bucket column
      let bkw = 0.62 // bucket width
      let bkpad = 0.04 // arrow-tip clearance

      for b in range(3) {
        if b == 1 {
          // D1 = D2 → shared bucket spanning rows 0+1; D3 → own bucket at row 2
          let shared_yc = -((b * 3 + 1.0) * rh) // centre between rows 0 and 1
          let shared_ht = 2 * rh - 0.06
          let d3_yc = -((b * 3 + 2.5) * rh)
          let d3_ht = rh - 0.06

          // shared bucket (thick border to signal collision)
          rect(
            (bkx, shared_yc + shared_ht / 2),
            (bkx + bkw, shared_yc - shared_ht / 2),
            fill: rgb("#fef3cd"),
            stroke: (paint: rgb("#d4ac0d"), thickness: 0.85pt),
          )
          content((bkx + bkw / 2, shared_yc + 0.14), text(size: 5.5pt, fill: dcol.at(0))[$D_1$])
          content((bkx + bkw / 2, shared_yc - 0.14), text(size: 5.5pt, fill: dcol.at(1))[$D_2$])

          // D3 bucket
          rect(
            (bkx, d3_yc + d3_ht / 2),
            (bkx + bkw, d3_yc - d3_ht / 2),
            fill: rgb("#fef3cd"),
            stroke: (paint: rgb("#d4ac0d"), thickness: 0.55pt),
          )
          content((bkx + bkw / 2, d3_yc), text(size: 5.5pt, fill: dcol.at(2))[$D_3$])

          // D1 and D2 arrows converge to shared bucket centre
          let d1_y = -((b * 3 + 0.5) * rh)
          let d2_y = -((b * 3 + 1.5) * rh)
          line(
            (mw + bkpad - 1.25, d1_y - 0.1),
            (bkx - bkpad, shared_yc),
            mark: (end: ">", size: 0.14),
            stroke: (paint: dcol.at(0), thickness: 0.45pt),
          )
          line(
            (mw + bkpad - 0.7, d2_y),
            (bkx - bkpad, shared_yc),
            mark: (end: ">", size: 0.14),
            stroke: (paint: dcol.at(1), thickness: 0.45pt),
          )
          // D3 arrow: straight horizontal
          line(
            (mw + bkpad - 0.2, d3_yc),
            (bkx - bkpad, d3_yc),
            mark: (end: ">", size: 0.14),
            stroke: (paint: dcol.at(2), thickness: 0.45pt),
          )

          // candidate pair callout
          let cann = bkx + bkw + 0.65
          line(
            (bkx + bkw + bkpad, shared_yc),
            (cann - bkpad, shared_yc),
            mark: (end: ">", size: 0.12),
            stroke: (paint: rgb("#c0392b"), thickness: 0.45pt),
          )
          content(
            (cann, shared_yc),
            box(
              fill: rgb("#fdecea"),
              stroke: (paint: rgb("#c0392b"), thickness: 0.45pt),
              inset: 3pt,
              radius: 2pt,
              text(size: 5.5pt)[$D_1, D_2$: candidate pair],
            ),
            anchor: "mid-west",
          )
        } else {
          // All three documents hash to separate buckets, one per row slot
          for c in range(3) {
            let bk_yc = -((b * 3 + c + 0.5) * rh) - 0.1
            let bk_ht = rh - 0.06
            rect(
              (bkx, bk_yc + bk_ht / 2),
              (bkx + bkw, bk_yc - bk_ht / 2),
              fill: bfill.at(b),
              stroke: (paint: bstroke.at(b), thickness: 0.55pt),
            )
            content((bkx + bkw / 2, bk_yc), text(size: 5.5pt, fill: dcol.at(c))[$D_#(c + 1)$])
            // straight horizontal arrow from matrix right edge
            line(
              (mw + bkpad - ((3 - c) * 0.45), bk_yc),
              (bkx - bkpad, bk_yc),
              mark: (end: ">", size: 0.14),
              stroke: (paint: dcol.at(c), thickness: 0.45pt),
            )
          }
        }
      }

      content((bkx + bkw / 2, -mh - 0.25), text(size: 6.5pt)[buckets])
    })
  },
  caption: [Locality Sensitive Hashing],
)

The *actual* Jaccard similarity is computed *only* for candidate pairs.
The probability that two documents $S, T$ are not filtered (pass the LSH filter), given their actual similarity $J(S, T) = s$, is:
$ p(s) = 1 - (1 - s^r)^b $

#proof[
  We start by computing the probability of matching in one row:
  $ mr(PP(S "and" T "match in one row")) = s = J(S, T) $

  We can assume independecy between events (rows) because we use random sampling (the parameters of the linear transformation should be selected randomly), thus:
  $
    PP(S "and" T "match in all row of a band") & = s^r \
    underbrace(PP(S "and" T "do not match in at least one row of the band"), = "do not match in one band") & = 1 - s^r \
    PP(S "and" T "do not match in any band") & = (1 - s^r)^b \
    underbrace(mr(PP(S "and" T "match in at least one band")), = (S, T) "pass the LSH filter") & = 1 - (1 - s^r)^b \
    & = p(s)
  $
]

#warning[
  This is an approximation algorithm, two possible error cases exist:
  - *False Positives (FP)*: pairs that pass the LSH filter but are not actually similar.
    Not a problem, as the actual similarity is computed.
  - *False Negatives (FN)*: truly similar pairs that do not share any bucket and are never compared, these are missed results.
]

==== Choice of $b$ and $r$: the treshold $t$

The choice of the number of bands $b$ and rows per band $r$ (such that $r b = k$) modifies how the filter behaves.
We need to introduce the *treshold* $t$: the similarity level where a pair of documents has a *50% chance* of passing the LSH filter.

#example[
  With $t = 0.8$, documents that have a Jacccard similarity of $0.8$, pass the filter only $50%$ of the times.
  This is _not good_ if we want to identify documents with 80% similarity, as only approximately half are individuated.
]

To determine the exact value of the treshold, we can analyze the behaviour of function $p(s)$, the probability of passing the LSH.
The function $p(s) = 1 - (1-s^r)^b$ has a *sigmoid-like* shape: it starts flat near $0$, rises steeply in the middle, then flattens near $1$.
The treshold, where the trend changes, is the *steepest* point of that function.

// TODO: add sigmoid graph: Figure 3.8 on the book

To find the steepest point, first compute the _first derivative_, that gives us the steepness of the funcion.
Then compute the _second derivative_ and _put it to zero_: the maximum point of the function (the maximum steepness)

$
   p'(s) & = b r s^(r-1) (1-s^r)^(b-1) \
  p''(s) & = -b r s^(-2 + r) (1 - s^r)^(-2 + b) (1 - s^r + r (-1 + b s^r)) \
$

The exact root is complex, but a good approximation is:
$ t approx (1/b)^(1/r) $

#informally[
  / Strict filter:
    High $r$, low $b$: documents must match on a lot of hash functions perfectly just to share one bucket.
    This is very hard.
    The threshold $t$ shifts to $1$.

  / Loose filter:
    Low $r$, High $b$: documents only need to match few hashes.
    This is very easy.
    The threshold $t$ shifts to $0$.
]

This result can be used to determine the values of $b$ and $r$:
- determine the similarity of documents that we want to make pass the filter
- fix a treshold $t$ so that almost all of these documents pass the filter
- adjust $r$ and $b$ to match that treshold

#example[
  Suppose we have $k = 100$ hash functions and we want to identify documents with Jaccard similarity at least $0.8$.

  By choosing a lower treshold $t$, we make sure pairs with 80% similarity pass the filter more often.
  We can try with:
  $ b = 20, quad r = 5, quad t = (1/20)^(1/5) approx 0.55 $

  The probability of passing the filter, for actual similarity $s$ is:
  #align(center, table(
    columns: (auto, auto),
    align: center,
    table.header[$s$][$p(s)$],
    [0.2], [0.006],
    [0.3], [0.047],
    [0.4], [0.186],
    [0.5], [0.47],
    [0.6], [0.802],
    [0.7], [0.975],
    [0.8], [0.9996],
  ))

  Documents with $80%$ similarity become a candidate pair with probability $approx 99.96%$.
]

#informally[
  The full pipeline for finding similar documents:
  + *Shingling*: preprocess (strip stop-words), build $k$-shingles - pick $k$ based on document type.
  + *Min-hashing*: build the signature matrix with $n$ hash functions.
  + *LSH*: divide the signature matrix into $b$ bands of $r$ rows each and hash each band's column into a bucket.
    Tweak $b$ by exploiting the treshold value $t$.
  + *Verification*: for each candidate pair (same bucket in at least one band), compute the actual Jaccard similarity and discard pairs below the wanted similarity.
]

== Generalized Process

Given pairs of encoded documents, we want to calculate their similarity.
Instead of similarity, we can think of *distance* (similar objects are close).
The distance functions takes a pair and returns a value:
$ d : X times X -> RR $
Where some properties are verified:
+ $forall x, y in X, quad d(x, y) >= 0, quad d(x, y) = 0 space <--> space x = y$
+ commutativity: $forall x, y in X, quad d(x, y) = d(y, x)$
+ triangle inequaltiy: $forall x, y, z in X, quad d(x, y) <= d(x, z) + d(z, y)$

Distances that work on vectors of real numbers of size $d$: $X = RR^d$.
These distances are called $L_p$-distances
$ d(x, y) = (sum_(i=1)^d |x_i - y_i|^p)^(1/p) $
- Manhattan distance ($p = 1$)
- Euclidian distance ($p = 2$)

#note[
  Proving the three properties for these is pretty trivial.
]

// TODO: what are L_p distances? What have to do with the Contour plot?

Another distance: Jaccard distance // TODO: what is that used for?
$ d(A, B) = 1 - J(A, B) $

#note[
  Proving the first two properties is pretty easy.
  The triangle disequality is a bit tricky.

  #proof[
    Because of how the similarity is defined, we can rewrite the distance as:
    $ d(A, B) = PP(H(A) != H(B)) $
    We can intoduce a thrid element $C$:
    $ H(A) != H(B) --> H(A) != H(C) or H(B) != H(C) $

    #note[
      Two trivial probability properties:
      - $A --> B$ means $PP(A) <= PP(B)$
      - $PP(A union B) <= P(A) + P(B)$
    ]

    $
      PP(H(A) != H(B)) <= PP(H(A) != H(C) union H(B) != H(C)) \
      PP(H(A) != H(B)) <= PP(H(A) != H(C)) + PP(H(B) != H(C))
    $
  ]
]

Distance taht can be used on vectors with common origin (directions on the space): *Cosine* distance.
Given two vectors $x$ and $y$ with angle $theta$:
$ d(x, y) = theta_(x y) = arccos (x y)/(||x|| ||y||) $

#note[
  Two vectors with the same direction but different magnitude are considered the same vector.
]

#informally[
  A simple trick to check if a space is Euclidian is to check if the midpoint between two elements is a point of the space.

  E.g. Strings.
]

For strings: Lehvehnstein distance.
Repeatedly apply one of the operations:
- adding character
- modifying character
- deleting character
the distance is the minimum numner of operations to get from one string to another.

For binary words with same length: Hamming distance:
Number of positions with different bits between two binary words.

#note[
  Hamming distance can be generalized over any alphabet e.g. "sad" vs "sun" would give distance $2$.
]

== LSH with Generic Distance

The LSH method divided documents into bands and then two documents were similar if two document shared the same band, with probability:
$ PP(f(x) = f(y)) $

We needed a family of min hash functions for that end.

We define a property that we would like for our families of hash function.\
The family $cal(F)$ is $(d_1, d_2, p_1, p_2)$-sensitive if (where $d_1, d_2$ refer to distances and $p_1, p_2$ refer to probabilities):
$
  forall f in cal(F), quad forall x, y in X, \
  d(x, y) <= d_1 --> PP(f(x) = f(y)) >= p_1 \
  d(x, y) >= d_2 --> PP(f(x) = f(y)) <= p_2
$

#note[
  We talk of probability because we have some randomness in the family.
]

#example[
  $cal(F)$: min hash, $d$: Jaccard
  $
    d(x, y) <= d_1 --> 1- J(x, y) <= d_1 \
    J(x, y) >= 1- d_1 --> PP(h(x) = h(y)) >= underbrace(1 - d_1, = p_1)
  $
  with $h$ being one random hash function from the family.

  This proves that this follows the property.
]

=== $"AND"$-Construction and $"OR"$-Construction

Given a $cal(F)$, we want to get an $cal(F)_"and"$ that is better in terms of $(d_1, d_2, p_1, p_2)$

#note[
  $cal(F)$ can be both finite and infinite
]

$ cal(F) = {f_1, f_2, ...} $
Propertly elaborating the functions in $cal(F)$ we can get to a $cal(F)_"and"$ family.
We want to extract $r in NN$ functions from $cal(F)$ (not in order):
$ f' in cal(F)_"and" -> f' = (f_1 in cal(F), ..., f_r in cal(F)) $

We are only interested in $PP(f(x) = f(y))$:
$ (f'(x) = f'(y)) <--> forall j in [1, r] f_(i j)(x) = f_(i j)(y) $

Why do we do this?
We have $cal(F)$ that enjoys the property, but we are not satisfied by the values of $p_1, p_2$.

$
  PP(f'(x) = f'(y)) = PP(inter.big_(j=1)^r {f_(i j)(x) = f_(i j)(y)}) = product_(j=1)^r underbrace(PP(f_(i j)(x) = f_(i j)(y)), >= p_1) >= p_1
$

...

$ d(x, y) <= d_1 --> PP(f'(x) = f'(y)) >= p_1^r $
$ d(x, y) >= d_2 --> PP(f'(x) = f'(y)) <= p_2^r $

...

$ f'(x) = f'(y) <--> exists j = 1, r f_(i j)(x) = f_(i j)(y) $
$
  forall j quad d(x, y) <= d_1 --> & PP(f_(i j)(x) = f_(i j)(y)) >= p_1 \
                                   & PP(f_(i j)(x) != f_(i j)(y)) <= 1 - p_1
$

$ PP(forall j space { f_(i j)(x) != f_(i j)(y)}) = product_(j = 1)^r PP(f_(i j) f(x) != f_(i j)(y)) $

So:
$
    d(x, y) <= d_1, \
  PP(f'(x) = f'(y)) & = PP(exists j f_(i j)(x) = f_(i j)(y)) \
                    & = 1 - PP(forall j f_(i j)(x) != f_(i j)(y)) \
                    & >= 1 - ( 1- p_1)^r
$

The analogous thing can be done with the other parts of the property (with $d_2$ and $p_2$).

#informally[
  Recap: if $x$ and $y$ are similar (less than $d_1$), using my original family o function I woul have that the prob that selecting them was higher tha $p_1$.
  Now using the extended family, the probabolity of selecting them is $1 - ( 1- p_1)^r$.

  We can increase the probability at the cost of increasing also the other treshold.
]

#informally[
  What happens if I apply the OR transformation to the AND family?

  With this construction we obtain $(d_1, d_2, 1-(1-p_1^k)^k, 1-(1-p_2^k)^k)$-sensitive.

  Because of the non-linearity of the functions we used, we raised $p_1$ and lowered $p_2$.
  We can apply this idea indefinitely times, we are only limited by the number of functions in the original family $cal(F)$.

  This construction is independent of the function.
]

=== Functions for distance

Starting from a distance, what kind of functions can I use?

==== Hamming Distance $h$

Words of lenght $d$

$ forall i = 1, ..., d, quad f_(i)(x) = x_i $
$ PP(f_i(x) = f_i(y)) = 1 - h(x, y) / d $

Hamming id $(d_1, d_2, 1 - d_1/d, 1- d_2/d)$-sensitive

#note[
  This is an example where the original family is limited, we have as much functions as components in the vector.
]

==== Cosine Distance

Directions in space, so vectors but only the direction of the vector (not the magnitude)

#informally[
  The idea is that given a direction $f$, we need to check if the two vectors are in a same half-plane, meaning $f(x) = f(y)$.
]

In the special case when $x$ and $y$ point in the same direction: $d(x, y) = 0, PP = 1$.
In the opposite case, when they are on the same direction but point to opposite sides: $PP = 0$.

The probability linearly decreases while the angle grows from $0$ to $pi$, so the $PP$ is $PP = 1 - d/pi$.

So the cosine couple with this family is $(d_1, d_2, 1- d_1/pi, 1- d_2/pi)$-sensitive.




---

// what jack's brain has accomplished

== Recap: LSH and the "S-Curve"
We were talking about the similarity pipeline for massive datasets. The main goal is to avoid the $O(n^2)$ complexity of comparing every single pair of documents.

In particular, we focused on the probability that a pair of documents $(S, t)$ end up in the same bucket. If we use $b$ bands and $r$ rows per band, the probability $p(s)$ that two docs with Jaccard similarity $s$ match in at least one band is:

$ P(S, T "match at least in one band") = 1 - (1 - s^r)^b = p(s) $

This function gives us the *sigmoid graph* (the S-curve).
- *FP (False Positives):* non-similar docs that pass LSH.
- *FN (False Negatives):* similar docs that don't pass LSH.

=== Finding the Threshold
If we take the derivative of the sigmoid graph, we obtain a *bell-shaped curve*. To find the exact maximum point (the "steepest" part of the S-curve), we should technically look at the second derivative, but for our purposes, an approximation $s^*$ is enough.

We can fix a similarity threshold $t$ as:
$ t approx (1/b)^(1/r) $

Now, if we want to ensure that our $s^*$ is equal to a specific threshold we fixed (we only care about docs with Jaccard $> t o t$), we need to select $b$ and $r$ carefully. Since we also know that $b dot r = n$ (where $n$ is the number of rows in the signature matrix), we just solve a system of two equations in two unknowns ($b$ and $r$).

== Review of the Overall Process
1. *Shingling:* Start from the document, strip stop-words, and decide the $k$-shingles size depending on the category of docs.
2. *Min-Hashing:* Create the signature matrix, deciding how many rows $n$ to use.
3. *Parameters:* Fix the threshold $t$ and solve the system to get optimal values for $b$ and $r$.
4. *LSH:* Divide the matrix into $b$ bands and apply hashing.
5. *Verification:* For each candidate pair, compute the actual Jaccard similarity and eliminate pairs that don't surpass $t$.

== Distances
What happens when the documents are not strings? For example, if we use a table to avoid duplicated records, the document is basically a vector. Jaccard might not be applicable here.

We need to measure the degree of similarity using *distances*. Distance is the dual of similarity:
- Similarity is big $arrow$ Distance is small.
- Similarity is small $arrow$ Distance is big.

A function $d(x, y)$ is a distance if it satisfies:
- *Positivity:* $d(x, y) >= 0$ and $d(x, y) = 0$ iff $x = y$.
- *Symmetry:* $d(x, y) = d(y, x)$.
- *Triangle Inequality:* $d(x, y) <= d(x, z) + d(z, y)$.

=== Typical Distances
1. *Euclidean Distance ($L_2$):* The length of the segment joining two points in $RR^d$. It's part of the $L_p$ family:
  $ d(x, y) = (sum_{i=1}^d |x_i - y_i|^p)^(1/p) $
  *Note:* If $p=1$ we get the *Manhattan distance*. If we plot $d(x,y)=1$ for $p=2$ we get a circle; for Manhattan, we get a square.



2. *Jaccard Distance:* Defined as $1 - "Jaccard Similarity"$.
  *Triangle inequality proof:* Recall $J(A, B) = P(h(A) = h(B))$, so $d(A, B) = P(h(A) != h(B))$. If $h(A) != h(B)$, then for any third set $C$, $h(C)$ must be different from either $h(A)$ or $h(B)$. In terms of probability:
  $ P(h(A) != h(B)) <= P(h(A) != h(C) " or " h(B) != h(C)) <= d(A, C) + d(B, C) $

3. *Cosine Distance:* Objects are vectors starting from a common origin (directions).
  $ d(x, y) = theta = arccos((x dot y) / (||x|| dot ||y||)) $
  It's basically the angle between vectors.

4. *Edit Distance (Levenshtein):* Minimum number of atomic operations (add, delete, modify char) to transform string $s$ into $t$.

5. *Hamming Distance:* Number of positions in which bits (or chars) differ.
  Example: `11010` and `10110` have distance 2.

== Formalizing LSH Families
Can we extend LSH to these distances? We need to speak about probabilities of events because the algorithm is random.

A family of functions $F$ is *$(d_1, d_2, p_1, p_2)$-sensitive* if:
- If $d(x, y) <= d_1$, then $P(f(x) = f(y)) >= p_1$ (Close things likely collide).
- If $d(x, y) >= d_2$, then $P(f(x) = f(y)) <= p_2$ (Far things unlikely collide).

We can amplify these properties:
- *AND Construction:* $f'(x) = f'(y)$ iff all $r$ functions match. It makes the probability $p^r$.
- *OR Construction:* Use bands to make it $1 - (1 - p)^b$.

  trying to use "OR" rather than "AND" to see how the probability changes... (need to finish this part)

// what jack's brain has accomplished part 2: 03/02/2026, first part of the lecture

In previous lessons, we defined a family of functions $cal{F}$ that is $(d_1, d_2, p_1, p_2)$-sensitive relative to a distance measure $d$. The goal of LSH is to design functions such that:
- If $d(x, y) <= d_1$, then $P[h(x) = h(y)] >= p_1$ (High probability for similar items).
- If $d(x, y) >= d_2$, then $P[h(x) = h(y)] <= p_2$ (Low probability for dissimilar items).

Ideally, we want $p_1$ to be very large (close to 1) and $p_2$ to be very small (close to 0). For example, using *Jaccard Similarity*, if we set $d_1 = 0.1$ and $d_2 = 0.9$, our family is $(0.1, 0.9, 0.9, 0.1)$-sensitive. While this aligns with common sense, a probability of $0.9$ is often not robust enough for massive datasets where we might require $p_1 > 99.99%$.

== Inception of Functions
To decrease the gap between "good" and "professional" probabilities, we introduce *AND* and *OR* constructions. This is essentially a "filtering" mechanism: we want the function to return a match only under specific logical constraints.

=== The AND-Construction
We create a new function $f$ by combining $k$ independent functions from $cal{F}$.
$ f(x) = (h_1(x), h_2(x), dots, h_k(x)) $
The condition $f(x) = f(y)$ holds if and only if $h_i(x) = h_i(y)$ for *all* $i = 1, dots, k$.
The new sensitivity becomes:
$(d_1, d_2, p_1^k, p_2^k)$-sensitive
*Personal Note:* This effectively lowers the probability of a false positive ($p_2$ drops quickly), but unfortunately, it also lowers $p_1$.

=== The OR-Construction
To fix the drop in $p_1$, we apply the *OR-construction*. If we take $f$ such functions, the probability of a match is:
$ 1 - (1 - p^k)^f $
This construction creates an S-curve, allowing us to sharpen the transition between "similar" and "dissimilar."

=== Inception

we can apply these constructions to the *extended* family itself. If we take an AND-family and apply an OR-construction to it, we get:
$f_(o r) (x) = f_(o r ) (y)$ i.f.f. $exists i : f_i (x) = f_i (y)$
Substituting the underlying probability $p$, the new sensitivity becomes:
$ (d_1, d_2, 1 - (1 - p_1^k)^f, 1 - (1 - p_2^k)^f) $-sensitive

By stacking these levels (like "Inception"), we can reach extreme values like $(0.1, 0.9, 0.9998, 0.0003)$.
#note[
  This works perfectly if our starting family $cal{F}$ is infinite. If the family is finite (e.g., small bit-vectors), we are limited in how many "steps" of inception we can perform before running out of unique functions.
]

== Hamming Distance
Hamming distance is defined over words of a fixed length $d$ from any alphabet.
We define a family where each function $f_i$ simply selects the $i$-th coordinate:
$f_i (x) = x_i quad$ for $i in {1, dots, d}$

If we pick an index $i$ uniformly at random, the probability that two words $x$ and $y$ match at that coordinate is:
$ P[f_i (x) = f_i (y)] = 1 - $Hamming$(x, y){d}$
This yields a $(d_1, d_2, 1 - d_1/d, 1 - d_2 /d)$-sensitive family. Again, the size of our family is limited by the dimensionality $d$ of the vectors.

== Cosine Distance

For vectors in continuous space, we use the angle between them. The LSH function is defined by picking a random hyper-plane (a random direction).

- *Logic:* A random hyper-plane either separates two vectors or it doesn't.
- *Case 1:* Vectors $x$ and $y$ lie on opposite sides of the plane $-> f(x) != f(y)$.
- *Case 2:* Vectors $x$ and $y$ lie on the same side $-> f(x) = f(y)$.

*Special Cases:*
- If $x = y$, the angle $theta = 0$, so they always lie on the same side ($P=1$).
- If $x$ and $y$ are opposite (anti-parallel), they will *always* be separated ($P=0$).

In a continuous probability space, we can select any angle between $0$ and $pi$. The probability of being on the same side decreases linearly as the angle $theta$ increases:
$ P = 1 - (theta)(pi) $
Therefore, the cosine distance is $(d_1, d_2, 1 - d_1/pi, 1 - d_2/pi)$-sensitive.
