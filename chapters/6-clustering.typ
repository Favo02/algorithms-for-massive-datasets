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
