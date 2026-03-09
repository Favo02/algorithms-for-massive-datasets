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

Then we construct $k$-grams (or $k$-shingles or only shingle): a sequence of $k$ consecutive *tokens* (characters, words, or other units).
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
  While this introduces some collisions, meaning two different shingles will be considered the same one, it works really well because _most_ of the possible shingles _never occur_ (such as "kxsdw" string).
]

#example[
  Using $9$-shingles requires $72$ bits of storage, but hashing reduces this to just $32$ bits.
  This matches the space needed for _unhashed_ $4$-shingles, yet hashing $9$-shingles provides *better differentiation* quality: while $4$-shingles account also for very *rare* shingles, hashed $9$-shingles *uniformly distribute* rare shingles across buckets, improving effectiveness.
]

=== Characteristic Matrix

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
- the *union*: number of rows that have at least one $1$

This idea works, but the characteristic matrix is *too big* to fit in memory.
We need to _compress_ this matrix, being able to compute the similarity without decompressing it.

=== Min Hash Function

We introduce a function that hashes a *document* into a *shingle*.
$ h : {"docs"} -> {"shingles"} $

To calculate a Min Hash Function three steps are done:
+ Fix a _row permutation_ (of the shingles) of the characteristic matrix
+ _Apply_ the permutation to the characteristic matrix
+ For each document, the resulting shingle is the _row with the first $1$_ in the permuted column

#example[
  A hash function $h_1$ with the documents from the last example:
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

=== Signature Matrix and Jaccard Similarity <sig-matrix-jaccard-sim>

Given a signature matrix, we can estimate the Jaccard similarity between two documents without accessing the full characteristic matrix.

#set math.equation(numbering: "(1.1)", supplement: "EQ")

The key insight is that if we apply a _random_ hash function $H$ to two documents $S$ and $T$, the probability that they produce the same result equals the Jaccard similarity:
$ PP(H(S) = H(T)) = J(S, T) $<jaccard-sim-probability>

#set math.equation(numbering: none, supplement: "EQ")

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
  $ hat(J)(S,U) = 1/3 approx 0.33 quad (h_2 "matches") $
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
This matrix is divided into $b$ *bands*, each containing $r$ *rows* (with $b dot r = k$).

For each band, hash the $r$-element column vector of each document into a bucket.
Two documents end up in the same bucket for a band if and only if their signature values in that band are *identical* (neglecting collisions).

Each document is sent to $b$ buckets (one per band).
Any pair of documents that *shares a bucket* (they contain the same values in at least one band) becomes a _candidate pair_.

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

  We can assume independence between events (rows) because we use random sampling (the parameters of the linear transformation should be selected randomly), thus:
  $
    PP(S "and" T "match in all rows of a band") & = s^r \
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

==== Choice of $b$ and $r$: the threshold $t$

The choice of the number of bands $b$ and rows per band $r$ (such that $r b = k$) modifies how the filter behaves.
We need to introduce the *threshold* $t$: the similarity level where a pair of documents has a *50% chance* of passing the LSH filter.

#example[
  With $t = 0.8$, documents that have a Jaccard similarity of $0.8$, pass the filter only $50%$ of the time.
  This is _not good_ if we want to identify documents with 80% similarity, as only approximately half are detected.
]

To determine the exact value of the threshold, we can analyze the behaviour of function $p(s)$, the probability of passing the LSH.
The function $p(s) = 1 - (1-s^r)^b$ has a *sigmoid-like* shape: it starts flat near $0$, rises steeply in the middle, then flattens near $1$.
The threshold, where the trend changes, is the *steepest* point of that function.

// TODO: add sigmoid graph: Figure 3.8 on the book

To find the steepest point, first compute the _first derivative_, that gives us the steepness of the function.
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
- fix a threshold $t$ so that almost all of these documents pass the filter
- adjust $r$ and $b$ to match that threshold

#example[
  Suppose we have $k = 100$ hash functions and we want to identify documents with Jaccard similarity at least $0.8$.

  By choosing a lower threshold $t$, we make sure pairs with 80% similarity pass the filter more often.
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
    Tweak $b$ by exploiting the threshold value $t$.
  + *Verification*: for each candidate pair (same bucket in at least one band), compute the actual Jaccard similarity and discard pairs below the wanted similarity.
]

== Generalized Process

So far we have assumed that objects are strings, representable as sets of shingles.
What if we are comparing vectors, images or anything that does not map to a set?
In those cases, the shingle-based encoding and Jaccard similarity may not apply.
We need to *generalize* the approach to arbitrary data types.

=== Distance Measures

We now frame similarity in terms of *distance*: similar objects are _close_, dissimilar ones are _far_.
A distance function maps pairs of objects to non-negative real numbers:
$ d : X times X -> RR $
For $d$ to be a proper metric, it must satisfy three properties:
+ _distance to self_: $forall x, y in X, quad d(x, y) >= 0, quad d(x, y) = 0 <--> x = y$
+ _symmetry_: $forall x, y in X, quad d(x, y) = d(y, x)$
+ _triangle inequality_: $forall x, y, z in X, quad d(x, y) <= d(x, z) + d(z, y)$

#warning[
  Not all the distance measures listed below are *Euclidean spaces*.

  A property of Euclidean spaces that is simple to verify is that the _average_ of two points is still a _valid point_ in the space.

  #example[
    The average of two real points is still a real point, so that's an Euclidean space.
    That's not true for integer points.
    Likewise, the average of two strings makes no sense.
  ]
]

==== Euclidean Distances ($L_p$-distances)

Distances that work on vectors of real numbers of size $d$: $X = RR^d$.
These distances are called $L_p$-distances, with general formula:
$ d(x, y) = (sum_(i=1)^d |x_i - y_i|^p)^(1/p) $

The most famous ones are the Manhattan distance, $L_1$-norm:
$ d(x, y) = sum_(i=1)^d |x_i - y_i| $

the Euclidean distance, $L_2$-norm:
$ d(x, y) = sqrt(sum_(i=1)^d (x_i - y_i)^2) $

and the $L_infinity$-norm, where only the dimension with largest difference matters:
$ d(x, y) = max_i |x_i - y_i| $

Proving that the properties hold is trivial.

==== Jaccard Distance

#warning[
  This is the Jaccard _distance_, not the Jaccard _similarity_!
]

The *Jaccard distance* is defined as the complement of Jaccard similarity:
$ d(x, y) = 1 - J(x, y) $

Proving the first two properties is pretty easy.
The triangle inequality is a bit tricky.

#proof[
  Because of how the similarity is defined (Section #link-section(<sig-matrix-jaccard-sim>), #link-equation(<jaccard-sim-probability>)), we can rewrite the distance as:
  $ d(x, y) = PP(H(x) != H(y)) $

  #note[
    $H$ is a random hash function.
  ]

  We can introduce a third element $z$.
  If the hash of $x$ and $y$ are different, then at least one of the two is not equal to the hash of $z$:
  $ H(x) != H(y) quad -> quad H(x) != H(z) space or space H(y) != H(z) $<jaccard-distance-z>

  We need two intermediate probability results.

  #theorem(title: "Lemma")[
    If an event implies another one, then its probability is smaller.
    $ A -> B quad PP(A) <= PP(B) $
  ]<event-implication-smaller>

  #theorem(title: "Lemma")[
    The probability of the union of the events is, at most, their sum.
    $ PP(A union B) <= PP(A) + PP(B) $
  ]<probability-union-smaller-sum>

  From #link-equation(<jaccard-distance-z>):
  $
    PP(H(x) != H(y)) space &<= space PP(H(x) != H(z) union H(y) != H(z)) space &#comment("applying " + link-theorem(<event-implication-smaller>)) \
    PP(H(x) != H(y)) space & <= space PP(H(x) != H(z)) + PP(H(y) != H(z)) space qed space &#comment("applying " + link-theorem(<probability-union-smaller-sum>))
  $
]

==== Cosine Distance

The *cosine distance* can be used on vectors with a common origin (directions in space).
The resulting distance will be in the range 0 to 180 degrees regardless of the dimension of the vector.

Given two vectors $x$ and $y$, the cosine distance is defined exploiting the dot product and normalization:
$ d(x, y) = theta_(x y) = arccos (x y)/(||x|| ||y||) $

#warning[
  Two vectors with the same direction but different *magnitude* are considered the same.
]

==== Levenshtein Distance (Edit Distance)

When the points are strings, Levenshtein or Edit distance can be used.
It is defined as the minimum number of character operations (_insertion_, _deletion_, _substitution_) to _transform_ one string into the other.

#note[
  Given strings $x$ and $y$, the edit distance can be computed as:
  $ |x| + |y| - 2 |"LCS"(x, y)| $
  where $"LCS"$ is their #link("https://en.wikipedia.org/wiki/Longest_common_subsequence")[longest common subsequence].
]

#example[
  Given $x = "abcde"$, $y = "acfdeg"$, the conversion is:
  + delete $"b"$
  + insert $"f"$
  + insert $"g"$
  Therefore, the Levenshtein distance is $3$.
]

==== Hamming Distance

Primarily used when the vectors are boolean, but it can be used on vectors of any component.
The distance is defined as the number of components that differ.

#example[
  Hamming distance between $d(1101, 1000) = 2$, $d("luca", "lace") = 2$.
]

=== LSH with Generic Distance

To generalize LSH beyond Jaccard similarity, we need to characterize what makes a _family of hash functions_ suitable for a given distance.
Recall that in LSH, two items are declared *candidate pairs* if they collide under at least one hash function.

#note[
  Some prerequisites are assumed on the hash functions of the family:
  - _statistical independence_, it is possible to estimate the probability of more events by multiplying each event
  - _efficiency_, faster than comparing each pair (faster than quadratic)
  - _combinable_ to build functions that are better at avoiding FP and FN
]

The _effectiveness_ of the family depends on how the collision probability relates to the distance between items.
We say the family $cal(F)$ is *$(d_1, d_2, p_1, p_2)$-sensitive* (with $d_1 < d_2$ and $p_1 > p_2$) if:
$
  forall f in cal(F), quad forall x, y in X, \
  d(x, y) <= d_1 space -> space PP(f(x) = f(y)) >= p_1 \
  d(x, y) >= d_2 space -> space PP(f(x) = f(y)) <= p_2
$

#informally[
  The probability of collision:
  - is higher than $p_1$ for pairs closer than $d_1$
  - is lower than $p_2$ for pairs more distant than $d_2$
]

// TODO: @alsacchi draw this in typst
#figure(
  image("../content/03-d1d2p1p2-sensitive-function.png", width: 70%),
  caption: [Behaviour of $(d_1, d_2, p_1, p_2)$-sensitive function],
)

#example[
  Take $cal(F)$ as the minhash family and $d$ as the Jaccard distance.
  For a random hash function $h$:
  $
    d(x, y) <= d_1 & space -> space 1 - J(x, y) <= d_1 \
                   & space -> space J(x, y) >= 1 - d_1 \
                   & space -> space PP(h(x) = h(y)) >= underbrace(1 - d_1, = p_1)
  $
  The same argument holds for $d_2$, confirming that the minhash family is $(d_1, d_2, 1-d_1, 1-d_2)$-sensitive.
]

==== $"AND"$-Construction and $"OR"$-Construction

In practice the raw sensitivity of a family is often _not good_ enough.
AND and OR constructions let us *amplify* these probabilities.
Multiple constructions can be applied by *composition*.

#example[
  With min-hash and Jaccard, choosing $d_1 = 0.1$ and $d_2 = 0.9$ yields a $(0.1, 0.9, 0.9, 0.1)$-sensitive family: similar pairs collide with probability $90%$, which is too low for massive datasets.
]

#note[
  $cal(F)$ can be both finite and infinite.
  With a finite family (e.g. Hamming over $d$ dimensions), the number of applicable constructions is limited by the size of $cal(F)$.
]

The *AND construction* builds a new family $cal(F)_"AND"$, where each composite function $f'$ bundles $r$ members of $cal(F)$:
$ f' = (f_(i_1), ..., f_(i_r)) quad "with each" f_(i_j) in cal(F) $

Two items match under $f'$ only if *all* $r$ components agree:
$ f'(x) = f'(y) space <--> space mr(forall j) space f_(i_j)(x) = f_(i_j)(y) $

By independence, when $d(x,y) <= d_1$ each factor is $>= p_1$, so the probability that *all* components agree is:
$
  PP(f'(x) = f'(y)) = product_(j=1)^r underbrace(PP(f_(i_j)(x) = f_(i_j)(y)), >= p_1) >= p_1^r
$

Analogously, when $d(x, y) >= d_2$ each factor is $<= p_2$, so the product is $<= p_2^r$.

The resulting family $cal(F)_"AND"$ is: *$ (d_1, d_2, p_1^r, p_2^r)"-sensitive" $*

#informally[
  Both $p_1$ and $p_2$ are raised to the $r$-th power, so both shrink.
  The AND construction trades recall (may miss more similar pairs, *more FN*) for precision (fewer false positives, *less FP*).
]

The *OR construction* does the opposite, $cal(F)_"OR"$ is defined by taking $r$ functions and matching if *any* one agrees:
$ f'(x) = f'(y) space <--> space mr(exists j) space f_(i_j)(x) = f_(i_j)(y) $

By independence, the probability that *all* components disagree is the product that each single one disagrees ($1 - p_1$):
$ PP(forall j space f_(i_j)(x) != f_(i_j)(y)) = product_(j=1)^r PP(f_(i_j)(x) != f_(i_j)(y)) <= (1-p_1)^r $

Therefore:
$
  PP(f'(x) = f'(y)) & = 1 - PP(forall j space f_(i_j)(x) != f_(i_j)(y)) \
                    & >= 1 - (1 - p_1)^r
$

The same argument applied to $d(x, y) >= d_2$ gives $PP(f'(x) = f'(y)) <= 1-(1-p_2)^r$.

The resulting family $cal(F)_"OR"$ is:
*$ (d_1, d_2, 1-(1-p_1)^r, 1-(1-p_2)^r)"-sensitive" $*

#informally[
  Both $p_1$ and $p_2$ are pushed through $1 - (1 - dot)^r$, so both grow.
  The OR construction trades precision (more dissimilar pairs collide, *more FP*) for recall (fewer similar pairs are missed, *less FN*).
]

*Combining* AND and OR (applying one inside the other) lets us push the sensitivity to extreme values.
The downside is the number of functions that are needed (the family needs to be numerous) and that needs to be applied, making it slower.

#example[
  Starting from $(0.1, 0.9, 0.9, 0.1)$, a few rounds of AND+OR can yield something like $(0.1, 0.9, 0.9998, 0.0003)$: near-certain detection of similar pairs and near-zero false-positive rate.
]

==== LSH Families for Hamming Distance

For binary words of length $d$, pick a random coordinate $i$:
$ forall i = 1, ..., d, quad f_(i)(x) = x_i $

The probability that two words agree on a random coordinate is:
$ PP(f_i(x) = f_i(y)) = 1 - d_H(x, y) / d $

This family is $(d_1, d_2, 1 - d_1/d, 1- d_2/d)$-sensitive.

#note[
  This is a case where the original family is finite: it has exactly $d$ functions, one per dimension.
  We can only apply the construction $log d$ times before running out of independent functions.
]

==== LSH Families for Cosine Distance

For vectors where only direction matters, not magnitude.

Picking a random hyperplane through the origin (identified by a random vector), gives probabilities:
- the vectors point in the same direction, any hyperplane puts them on the same side: $PP = 1$
- the vectors point in opposite directions, any such hyperplane separates them: $PP = 0$
- the probability decreases linearly with the angle from $0$ to $pi$

Resulting in:
$ PP(f_v (x) = f_v (y)) = 1 - theta_(x y) / pi = 1 - d(x, y) / pi $

This family is $(d_1, d_2, 1 - d_1/pi, 1- d_2/pi)$-sensitive.
