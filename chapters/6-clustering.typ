#import "../template.typ": *

= Clustering

Unsupervised learning: observations not paired with labels.
Group these observation into some not specificated groups.

What happens to classical algorithms when the size grows up in two directions:
- the number of items grows a lot
- the dimension of one element grow a lot (eg DNA)

In the latter case, the "curse of dimensionality" starts messing up.
When the dimension grows up, it starts to lose meaning.

Assume we are in an euclidean space $RR^d$ and using euclidean distance.
When $d$ is very big, all the distances tends to be the same.
This is beacuse, over all $d$, very probably at least one is very big or very small, making all the distances similar.

Let's try other distances: cosine distance.
The product is centered around $0$ and, summing up a lot of times, we basically obtain a normal distribution, meaning all the distances will be $0$.

== Clustering Basics

Most clustering algorithms belong to one of two categories:
- Agglomerative: each observation belongs to its own cluster at the start, then clusters are merged iteratively, deciding which clusters to each using proximity.
  This can be calculated using multiple ways:
  - using centrodis: the two closest clusters (distance between centroids) are merged, this gives a tree called Dendogram
  - minumum distance between clusters: calculate pairwise distance between the points of the clusters.
    Merge the two clusters that have the minimal distance between any two points (the minimum space to be traveled to pass from a cluster to another)
  - using radius: calcualte the radius of merging any two clusters, the effectively merging the two clusters that gives the smallest new radius
- Point assignm: for each observation, it assign it to a cluster

/ Centroid: in an Euclidean space, it is the average of all points of a cluster (it is still a valid point).
  We can compute the distance between clusters by computing the distance between the two centroids.

/ Radius: maximal distance between a point and the centroid

A lot of algorithms need to know the number of clusters to obtain at the end of the process.
The idea is to progressively increasing the number of clusters $k$ until we obtain a "bad" cluster and stop.
Most of times we don't increase linearly $k$, but, like a binary search, start by increasing a lot $k$ and the tweaking to a decent solution.

Most of this does NOT work with non-Euclidean spaces, because we can't have a centroid.
We still have a distance function, but it is not guaranteed that the center of a cluster is a point of the space, so we need a clustroid.

/ Clustroid: the center of a cluster, it is one of the elements of the cluster.
  This can be computer by selecting the point that minimizes the distance between it and all other points.

== K-means Algorithm

Basic algorithm that do not work for big data

#todo

== Bradley, Fayyad, Reina Algorithm (BFR)

Algorithm that works with big data, like a replacement for K-means, so a point asssign algorithm and works on euclidian space (the points are vectors).

Based on a multi-variate Gaussian (a vector of indepdendent gaussian variables, possibly with different variables).

We need to fix $k$ at the start.

We can work with chunks of data, bringing it into main memory and running a classical clustering algorithm.
The idea is to load chunk after chunk and assign each point to a cluster.

But there is a problem: some points could be better to not assign them to an existing cluster, because they will be assigned to a cluster that will appear later on during the load of another chunk.

So, each point will be assigned to a set:
- discard set: points that definetely belong to a cluster (these points are done and can be discarded from main memory)
- retain set: points that will be assigned to another cluster that will arise later on (these need to be retained in RAM)
- compressed set: in between discard and retain, they are pretty close but not enough to form a cluster, usually called mini-clusters.
  Are promising and it is probable that these can be promoted to clusters.

For k-means the only thing we need are the positions of the centroids.
With BFR, we store slightly different representation of each cluster:
- $n$: number of items in a cluster
- sum: sum of the points of a cluster
- sumsq: sum of the points squared (component-wise), if we divide by $n$, we obtain a centroid.
  Can be also used to approximate the variance of the cluster

When a point is assigned to a cluster, we update the representation of a cluster, updating the three values.

#note[
  The representation heavily relies on sums (instead of multiplications) for two reasons:
  - faster
  - less error prone (the noise in the data grows less that with multiplications)
]

When assigning a point, we do not use distance, but by maximising probability density.
We try to maximise the density of each cluster.
The density is a proxy/approximation for probability.

$ f(x) = 1/ ((2 pi)^(d/2) product_(i = 1)^d sigma_i) exp (- sum_(i=1)^d 1/2 ((x_i - mu_i)/(sigma_i))^2) $

We use the Mahalobis Distance to calcualate the distance between a point and a cluster:
$ d(x, underbrace(c, "centroid")) = sum_(i=1)^d ((x_i - c_i)/sigma_i)^2 $

If a point is too distant to all the clusters, we don't want to assign that to any cluster.
We set a treshold, and if a point is over that treshold for all clusters, we put into the retain set.

Then we try to generate clusters from the retain set (we expect these points to be few, so we can do that using a main memory approach).

But this is somehow counterintuitive, don't have we fixed $k$? Aren't we adding more clusters?
The algotihm can, in fact, add more clusters.

=== Non-Euclidean: GRGPF

We don't have centroids, but we need to use a clustroid: a real point to represent the cluster.

We use another approach to store a cluster:
- $n$: the number of points in a the cluster
- the clustroid $c$
- the rowsum of the clustroid:
  $ "rowsum"(x) = sum_(y in C) d(x, y)^2 $
- the $k$ closest points to $c$
- the rowsums of the closest points
- the $k$ farthest points to $c$
- the rowsums of the farthest points

This algorithms uses a hybrid approach between point assignment and hierarchical approach.

The idea is that when a point gets assigned, we need to change the clustroid, the new clustroid is among the closest points to the old clustroid.

The farthest points are needed to merge clusters.

The algorithm works using a tree.
It navigates the tree to select in which point assign a point.
// TODO: explain how the tree is built and what it contains

Then we need to update the representation of the cluster:
- update the number of points $n+1$
Then we have two possible situations:
+ if the new point $x^N$ is not the new clustroid and the point is not in the $k$ clostest or farthest poinst
+ if the new point $x^N$ "enters" the representation, so it is the new clustroid or one of the $k$ closest or farthest points

In the first case (easiest one) we just need to update the rowsums.
We can do that by just summing to the current rowdistances the distance with the new points squared.

The second case is more complex: we need to calculate a new rowsum between each point and the new point, but we don't have all the points.

We can do that in an approximate way:
$ d^2 (x^N, p) approx d^2 (x^N, c) + d^2 (x, p) $
$ sum_p d^2 (x^N, p) approx N d^2 (x^N, c) + sum_p d^2 (x, p) $

By checking the distance between the new point and the $k$ closest, we can decide wether to swap or not the clustroid with one of the $k$ closest.
// TODO: how? why?

Are we sure that the tree is not too big to be store in main memory?

The algorithm also imposes a limit on the diameter of a cluster.
If it gets too big, we need to recluster it into smaller clusters.
TO do that the only option is to retrieve all the information of the points and bring it in main memory.

#note[
  The information on the points must be stored somewhere (not in RAM), otherwise we could not return the final result.
]

What if we need to merge two clusters?
$ "rowsum"_(c_1 union c_2) (p) = "rowsum"_(c_1) (p) + N_1 (d^2(p, c_1) + d^2(c_1, c_2)) + "rowsum"(c_2) $


//TODO merge jack's notes

= Clustering

Clustering is a form of *Unsupervised Learning*.
The goal is to group observations based on some concept of *similarity*.

== Curse of Dimensionality

Traditional algorithms (like K-Means) struggle when data dimensionality $d$ grows.
In high-dimensional spaces, distances lose their meaning.

#example[
  If we draw points uniformly in a high-dimensional unit hypercube, the Euclidean distance between any two random points tends to concentrate.
  $ 1 <= d(x, y) <= sqrt(d) $

  Operationally, it's worse: *all pairs of points tend to be at nearly the same distance.*
]

This implies that finding the "nearest neighbor" becomes meaningless because the nearest and farthest points are almost equidistant.
*Alternative:* Often *Cosine Distance* (angle between vectors) is more robust in high dimensions:
$ "dist"(x,y) = (x dot y) / (||x|| dot ||y||) $

== Clustering Strategies

Algorithms generally fall into two classes:
1. *Agglomerative:* Start with $N$ clusters (one per point) and merge the closest ones iteratively.
2. *Point Assignment:* Iterate through points and assign them to the best existing cluster.

=== Centroids vs Clustroids

How do we represent a cluster?

- *Centroid:* The geometric center (average) of points. Valid in Euclidean space.
- *Clustroid:* A representative point *selected from the actual data points*.
  - Used in *Non-Euclidean* spaces (where we can't compute an "average" point).
  - The clustroid is usually the point that *minimizes the sum of distances* (or max distance) to other points in the cluster.

=== Metrics for Selection

To choose the number of clusters $k$ or to decide when to stop merging, we look for an *Elbow* (or Ankle) in the graph of the objective function (for example, diameter or radius of clusters) vs $k$.

- *Radius:* Distance from representative to furthest point.
- *Diameter:* Max distance between any two points in the cluster.

== BFR Algorithm

The *BFR* algorithm is a "Big Data" replacement for K-Means.
It is designed for high-dimensional data and assumes clusters follow a *Multivariate Gaussian Distribution*.

#note[
  Clusters look like concentric ellipses (or circles, if axes are independent).
]
=== Process

We cannot load all data into RAM, so we process data in *chunks*.
For each chunk, we classify points into three sets:

1. *Discard Set*: Points that clearly belong to a cluster. We update the cluster statistics and *discard* the points themselves to save memory.
2. *Compressed Set*: Points that are close to each other but not close to any main cluster. We store them as "mini-clusters" to potentially merge later.
3. *Retained Set (RS)*: Outliers or points that don't fit anywhere. We must keep these in memory as individual points.

=== Summarizing Clusters

To discard points but keep the cluster info, we don't store the points.
We store only three sufficient statistics:

1. $N$: The number of items.
2. $"SUM"$: Vector sum of all elements (vector of length $d$).
3. $"SUMSQ"$: Vector sum of squared components.

$ "SUMSQ"_i = sum_(x in "cluster") x_i^2 $

Why this representation?

- *Additivity:* If we merge two clusters, we just sum their $N$, $"SUM"$, and $"SUMSQ"$.
- *Efficiency:* $"SUM"$ allows calculating the Centroid. $"SUMSQ"$ allows calculating the Variance (and standard deviation) efficiently.
- *Memory:* Fixed size regardless of $N$.

=== Mahalanobis Distance

To decide if a point belongs to a cluster, we don't just use Euclidean distance.
We use the *Mahalanobis Distance*

If a point is within a threshold distance, it goes to the discard set. Otherwise, it might go to the compressed set or the retained set.

// jacks notes from 17/02 lecture

Why do I have to keep the "promising" clusters if I already have the remaining ones? 
The core idea here is to *promote mini-clusters*. 

When I cluster items in a non-Euclidean space, I have to reason with *clustroids* (since I cannot compute a mean point).

== GRGPF Algorithm

Each cluster is described using a representation that we have already seen. For a cluster $C$, we store:

- $N$: The number of points.
- The *clustroid* $c$ + its `rowsum`.
- The $k$ *closest* points to $c$ + their `rowsum`s.
- The $k$ *farthest* points from $c$ + their `rowsum`s.

#note[
  The *rowsum* of any point is the sum of the squared distances between that point and all other points in the cluster:
  $ "rowsum"(x) = sum_(y in C) d(x, y)^2 $
]

The algorithm follows a *hybrid approach*: clusters are created dynamically.

1. I find the new clustroid among the $k$ closest points to $c$.
2. I save the farthest points because in future moments I will have to *merge* clusters, so I need those boundary points to make good decisions.

=== Tree Structure

In the intermediate phase of the execution:
- The *leaves* will contain the full representation of all the clusters I have encountered so far.
- The *internal nodes* will contain *samples* of the clusters that appear in their children, alongside a pointer to the child nodes.

The sample is selected appropriately to save space in Main Memory (MM) while using the algorithm.

=== Updating the Representation

Once I have assigned a point to a cluster, I have to modify the representation. But *how do I compute the rowsum of the new points* without access to all previous points?

I use a special property of non-Euclidean spaces (or rather, an approximation).
If I consider the triangle formed by the new point $x$, the clustroid $c$, and another point $p$, I can see that it will surely be treated like a right-angled triangle.

#informally[
  We assume the Law of Cosines behaves such that the cross-term is negligible, approximating the Pythagorean theorem:
  $ d^2(x, p) approx d^2(x, c) + d^2(c, p) $
]

So, the sum of the squared distances from a point $x$ to all other points (the rowsum) becomes:

$ "rowsum"(x) = sum_p d^2(x, p) approx sum_p (d^2(x, c) + d^2(c, p)) $

Since $d^2(x, c)$ is constant for the summation over $p$:

$ "rowsum"(x) approx N dot d^2(x, c) + "rowsum"(c) $

In principle, all I have to do is: take a new point, travel across the tree, and when I find a leaf, I know which cluster the point belongs to, and I update the representation using this formula.

=== Handling Memory and Constraints

I have *no guarantee* that the tree won't grow too much to store it in memory! Also, a cluster can become a *macro cluster* (too big).

*How to avoid this?* The algorithm imposes a limit on the *radius* of each cluster.

What happens if at a certain point a cluster exceeds the maximum radius? 
- I have to *split* the cluster.
- I take the extra points, put them back into MM, and then cluster them into new clusters.

But when I split a cluster in two, I have to update the cluster and update the representation. Do I have enough space?
In that case, I take the whole leaf, it becomes an *internal node*, and I take two new leaves which become the children of this new internal node.

So I have to have more free memory? *Yes, I need actual RAM space.*

=== Merging Clusters

In some situations (e.g., to reduce the number of clusters or compact the tree), I have to *merge* clusters.

What will be the representation of the merged cluster?
- I can't just sum the number of points.
- I will have to select new *closest points* and new *farthest points*.

In order to do that, I cannot compute the raw sum referred to the merged cluster directly. We still use the approximation of the Pythagorean theorem.

If I merge Cluster 1 ($C_1$, clustroid $c_1$) and Cluster 2 ($C_2$, clustroid $c_2$), the new rowsum for a candidate clustroid $x$ (where $x in C_1$) is:

$ "rowsum"_"merged"(x) = sum_(p in C_1) d^2(x, p) + sum_(q in C_2) d^2(x, q) $

The first part is known (it's the old rowsum in $C_1$). The second part is approximated:

$ "rowsum"_"merged"(x) approx "rowsum"_(C_1)(x) + [N_2 dot d^2(x, c_2) + "rowsum"_(C_2)(c_2)] $

This allows me to evaluate the best new clustroid without accessing the raw data.