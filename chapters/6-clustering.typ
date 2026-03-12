#import "../template.typ": *

= Clustering

Clustering is the process of examining a collection of "points" and grouping them into "clusters" according to some distance measure.
The goal is that points in the same cluster have a small distance from one another, while points in different clusters are at a large distance from one another.
It is a form of *Unsupervised Learning*, meaning it works with observations that are not paired with labels.
The final number of groups might be unspecified.

== The problem of dimension

Traditional algorithms struggle when data dimensionality $d$ grows.
Typically, the data volume grows in two directions:

- the number of items grows a lot
- the dimension of one element grows a lot (e.g., DNA, document topics)

#informally[
  In the latter case, the "curse of dimensionality" becomes problematic.
  When the dimension grows, distances start to lose their meaning.
]

#warning()[
  In high-dimensional spaces, almost all pairs of points are equally far away from one another.
]

#example[
  If we draw points uniformly in a high-dimensional unit hypercube, the *Euclidean distance* between any two random points tends to concentrate.
  $ 1 <= d(x, y) <= sqrt(d) $

  Operationally, it's worse: *all pairs of points tend to be at nearly the same distance.*
]

#note[
  This implies that finding the "nearest neighbor" becomes meaningless because the nearest and farthest points are almost equidistant.
]

*Alternative:* Often *Cosine Similarity* (angle between vectors) is more robust in high dimensions:
$ "sim"(x,y) = (x dot y) / (||x|| dot ||y||) $

#note[
  *Cosine Distance* is typically defined as $1 - "sim"(x,y)$.
]

The "product" refers to the dot product at the numerator ($x dot y$).
If the components of the vectors are independent and centered around $0$ (meaning their statistical mean is $0$), the expected value of their component-wise products is $0$.
By the Central Limit Theorem, as the number of dimensions $d$ grows, the sum of these products (the dot product) strongly concentrates around $0$, with a standard deviation growing only as $sqrt(d)$.

#note[
  centered around $0$ means that their mean is $0$.
]

#note[
  This means the *Cosine Similarity* tends to $0$ (random vectors tend to be almost orthogonal, close to 90 degrees, in high dimensions), causing the *Cosine Distance* to concentrate around $1$.
]

== Clustering Strategies

Algorithms generally fall into two classes:

1. *Agglomerative*: Start with $N$ clusters (each observation belongs to its own cluster) and merge the closest one iteratively;
2. *Point Assignment*: Iterate through points and assign them to the best existing cluster.

Algorithms can also be distinguished by whether they assume a Euclidean space (where we can compute an average/centroid) or an arbitrary distance measure (where we cannot).

=== Centroids vs Clustroids

We have several ways to represent a cluster:

- *Centroid*: In a Euclidean space, it is the geometric center (average) of points. We can compute the distance between clusters by computing the distance between the two centroids;
- *Clustroid*: A representative point selected from the actual data points. It is used in *Non-Euclidean* spaces (where we can't compute an average point). It can be computed by selecting the point that minimizes the distance between it and all other points.

#note[
  The clustroid is usually the point that *minimizes the sum of distances* to other points in the cluster.
]

=== Merging clusters in Agglomerative Algorithms

We can decide which cluster to use during merging, using *proximity*.
It can be calculated in several ways:

- using *centroids*: the two closest clusters are merged, producing a tree called *Dendrogram*;
- using *radius*: effectively merging the two clusters that gives the smallest new radius
- considering the *minimum distance between clusters*:
  - calculate pairwise distance between the points of the clusters
  - merge the two clusters that have the minimal distance between any two points (minimum space to be traveled to pass from a cluster to another)

=== Metrics for selection

To choose the number of clusters $k$ or to decide when to stop merging, we look for an *Elbow* (or Ankle) in the graph of the objective function vs $k$.

- *Radius*: Maximal distance between a point and the centroid
- *Diameter*: Max distance between any two points in the cluster.

#note[
  A lot of algorithms need to know the number of clusters to obtain at the end of the process.
]

#informally[
  If we don't know the correct value of $k$, we can find it logarithmically:
  1. Run the clustering for $k = 1, 2, 4, 8, dots$
  2. Eventually, you will find two values $v$ and $2v$ between which the metric (e.g., average diameter) does *not* decrease much.
  3. This suggests that a good value of $k$ may lie between $v/2$ and $v$. Use *Binary Search* in that range to refine the choice.
]

#note[
  This is a practical heuristic, not a guarantee: the elbow may be weak or ambiguous.
]

== K-Means Basics

The best-known point-assignment algorithm is *k-means*. 
It assumes a Euclidean space and that the number of clusters $k$ is known in advance.
The algorithm is simple:
1. Initially choose $k$ points to be the centroids of the clusters.
2. For each remaining point, assign it to the cluster with the closest centroid.
3. Adjust the centroid of that cluster to account for the new point.

=== Initializing Clusters for K-Means

To give the algorithm a good starting point, we must pick initial centroids that have a good chance of lying in different clusters.
A very effective approach is to pick points that are as far away from one another as possible:

1. Pick the first point at random.
2. While there are fewer than $k$ points, add the point whose *minimum* distance from the already selected points is *as large as possible*.

== BFR Algorithm

The *BFR* algorithm (Bradley, Fayyad, and Reina) is a "Big Data" replacement for K-Means, designed for data that does not fit in main memory.
It is designed for high-dimensional data and assumes clusters follow a *Multivariate Gaussian Distribution*.
It works on *Euclidean spaces*: the points are vectors of independent Gaussian variables.

#note[
  Clusters look like concentric ellipses (or circles if standard deviations are equal).
  A strong assumption is that the axes of the cluster *must align with the axes of the space* (dimensions are independent; the ellipse cannot be diagonally rotated).
]

=== Process

Since we cannot load all the data in RAM, we process data in *chunks*, bringing them into main memory and running a main-memory clustering algorithm on them.

To solve memory problems, for each chunk we classify the points into three sets:

1. *Discard Set*: Points that clearly belong to a cluster. We update the cluster statistics and *discard* the points themselves to save memory.
2. *Compressed Set*: Points that are close to each other but not close to any main cluster. We store them as "mini-clusters" to potentially merge later. They are promising and it is probable that these can be promoted to clusters.
3. *Retained Set (RS)*: Outliers or points that don't fit anywhere. We must keep these in memory exactly as they appear in the input file.

When processing a new chunk of points, BFR performs these steps:
1. Add points that are sufficiently close to a centroid to that cluster (updating the statistics and discarding the point).
2. Cluster the remaining points along with the old *Retained Set*. Clusters of more than one point become new *Compressed Sets* (mini-clusters). Singletons become the new *Retained Set*.
3. Merge mini-clusters with one another if they are close enough.
4. Write out the assignments of points to secondary memory.

=== Summarizing clusters

To discard points but keep the cluster info, we don't store the points. We store only three sufficient statistics ($2d + 1$ values):

- $N$: number of items in a cluster
- $text("SUM")$: vector sum of all elements (vector of length $d$).
- $text("SUMSQ")$: vector sum of the points squared (component-wise).

$ "SUMSQ"_i = sum_(x in "cluster") x_i^2 $

When a point is assigned to a cluster, we update the representation of a cluster, updating the three values.

#note[
  The representation heavily relies on sums (instead of multiplications) for these reasons:

  - *Additivity*: if we merge two clusters or add a point, we just sum their $N$, $text("SUM")$, and $text("SUMSQ")$ directly.
  - *Efficiency:* $text("SUM")$ allows calculating the Centroid ($text("SUM")/N$). $text("SUMSQ")$ allows calculating the Variance ($text("SUMSQ")/N - (text("SUM")/N)^2$) and standard deviation efficiently.
  - *Memory:* Fixed size regardless of $N$.
]

=== Mahalanobis Distance

To decide if a point belongs to a cluster (Step 1 of the Process), we don't just use Euclidean distance.
If a point is within a threshold distance, it goes to the discard set.
Otherwise, it might go to the compressed set or the retained set.

To calculate the distance between a point and a cluster we use the *Mahalanobis Distance*, which normalizes the distance by the standard deviation of the cluster in each dimension:

$ d(x, c) = sqrt(sum_(i=1)^d ((x_i - c_i)/sigma_i)^2) $

If a point is too distant to all the clusters, we don't want to assign that to any cluster.
So we set a threshold on the Mahalanobis distance, and if a point is over that threshold for all clusters, we put it into the retained set.

#note[
  In practice, the threshold is often selected using a confidence level from the $chi^2_d$ distribution (or chosen as a heuristic such as a fixed constant).
]

#informally[
  But this is somehow counterintuitive: the algorithm can, in fact, add more clusters.

  Why do I have to keep the "promising" mini-clusters (from the *Compressed Set*) if I already have the remaining ones? 
  The core idea here is to *promote mini-clusters* into full clusters once enough points accumulate and merge together.
]

=== Non-Euclidean: GRGPF

When I cluster items in a non-Euclidean space, I have to reason with *clustroids* (since I cannot compute a mean point).
We don't have centroids, but we need to use a clustroid: a real point to represent the cluster.

Each cluster is described using a representation that we have already seen.
For a cluster $C$, we store:
- $N$: the number of points in a cluster
- the clustroid $c$ + its `rowsum`
- the $k$ closest points to $c$ + their `rowsum`s
- the $k$ farthest points to $c$ + their `rowsum`s

#note[
  The *rowsum* of any point is the sum of the squared distances between that point and all other points in the cluster:
  $ "rowsum"(x) = sum_(y in C) d(x, y)^2 $
]

This algorithm uses a hybrid approach between point assignment and a hierarchical approach: *clusters are created dynamically*.
The idea is that when a point gets assigned:

1. I find the new clustroid among the $k$ closest points to $c$.
2. I save the farthest points because later I may have to *merge* clusters, so I need those boundary points to make good decisions.

The algorithm works using a tree.

=== Tree Structure

In the intermediate phase of the execution:

- The *leaves* will contain the full representation of all the clusters I have encountered so far.
- The *internal nodes* will contain *samples* of the clusters that appear in their children, alongside a pointer to the child nodes.

The sample is selected appropriately to save space in Main Memory (MM) while using the algorithm.

It navigates the tree to select which cluster should receive a point.

=== Updating the representation

Once I have assigned a point to a cluster, I have to modify the representation.

#warning[
  How do I compute the rowsum of the new points without access to all previous points?
]

We approximate the distances using a property of triangles.
By treating the triangle formed by the new point $x$, the clustroid $c$, and another point $p$ as a right-angled triangle, we assume the cross-term in the Law of Cosines is negligible.

#note[
  *Why is it negligible?* As established in the "Curse of Dimensionality", in high-dimensional spaces, two randomly chosen vectors tend to be nearly orthogonal (angle of 90°), which causes the cosine of the angle to approach zero, effectively reducing the Law of Cosines to the Pythagorean theorem:
  $ d^2(x, p) approx d^2(x, c) + d^2(c, p) $
]

Thus, the rowsum for the new point $x$ can be efficiently estimated as:
$ "rowsum"(x) approx N dot d^2(x, c) + "rowsum"(c) $

==== Update Steps:
1. Update the total number of points: $N -> N + 1$.
2. Add the squared distance of the new point to the existing rowsums of $c$, the $k$ closest, and the $k$ farthest points:
   $ "new_rowsum"(p) = "old_rowsum"(p) + d^2(p, x) $
3. Check if $x$ belongs to the $k$ closest or $k$ farthest points. If it does, calculate its rowsum using the approximation above and insert it, displacing the point that is no longer in the top $k$.

==== *Evaluating a new Clustroid:*
#informally[
  Why do we keep track of the $k$ closest points? Because as new points are added, the "center" of the cluster shifts.
  The point that minimizes the total distance (the rowsum) might change.
  The most likely candidates to become the new clustroid are the current $k$ closest points.
  If one of these points (or the newly added point $x$) achieves a `rowsum` lower than the current clustroid $c$, we *swap* them, and that point becomes the new clustroid!
]

=== Handling Memory and Constraints (Splitting)

#warning[
  There is *no guarantee* that the tree won't grow too large for Main Memory, or that a cluster won't become too sparse (a macro-cluster).
]

To prevent this, the algorithm imposes a strict limit on the *radius* (or diameter) of each cluster.
If a cluster exceeds this maximum threshold:
- The cluster must be *split*.
- We are forced to retrieve the actual points of that cluster from disk, bring them to MM, and re-cluster them into smaller subgroups.
- The original leaf node becomes an *internal node*, and the newly formed clusters become its children leaves.

#note[
  This process requires available RAM to handle the localized re-clustering.
]

=== Merging Clusters

Conversely, to reduce the number of clusters, compact the tree, or free up memory, we may need to *merge* two existing clusters ($C_1$ and $C_2$).

We cannot simply sum the representations; we must evaluate a new clustroid and new $k$ closest/farthest points for the merged cluster $C_1 union C_2$.

Using the same Pythagorean approximation, the new rowsum for a candidate clustroid $p$ (assuming $p in C_1$) is:
$ "rowsum"_"merged"(p) = sum_(y in C_1) d^2(p, y) + sum_(q in C_2) d^2(p, q) $

Since the first part is just the old known rowsum of $p$ in $C_1$, we can approximate the distances to the points in $C_2$ via their clustroid $c_2$:
$ "rowsum"_"merged"(p) approx "rowsum"_(C_1)(p) + [N_2 dot d^2(p, c_2) + "rowsum"_(C_2)(c_2)] $

This formula elegantly allows us to estimate the merged rowsums for all candidates (the clustroids and $k$-closest points of both $C_1$ and $C_2$) and pick the one with the minimum value as the new clustroid—all without accessing the raw data on disk.