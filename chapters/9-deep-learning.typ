#import "../template.typ": *

= Deep Learning

== Neural Network

Complex aggregation of networks, inspired by the human brain.
A huge number of single cells, which behaviour can be described very simply

/ Neuron: an input/output system, a computational thing.
  It depends on the stimuli that comes from the outside (inputs) but also from some internal state.
  Each input is connected, and has a weight, that increases or decreases the perception of that input.

/ Activation function: ???. Most of the times it is non-linear.

The computational power is not because of the power of the simple cell, but because of the huge number of them and the strong interconnection.

We will see a NN that does image classifications of digits.

For this example, we use for classification, but it can also be used for regression.

The dataset:
- the digits are not rotated
- the digits are equivalently distributed (10% 0, 10% 1, ...)

/ Tensor: multi-dimensional vector

To get the classification of an image is to linarize the image, run throught the network and look at the values of the output neurons.
But this is slow.

To leverage the power of SIMD instruction of the GPU, we want to process multiple images in parallel.
So we stack multiple digits one over the other to form a matrix of multiple images to process.

Thanks to this representation, we can multiply it by the matrix representing the weights of the connections, which are compatible for product.
Then we add the bias and we get the result ready to be passed to an activation function:
$ L = X dot W + b $

One common activation function is the softmax:
$ "softmax"(L_n) = (e^(L_n))/(|| e^L ||) $

To check how good is a network, we can use a loss function.

How do we "train" the NN?
We initialize the weights of all the connections to some value and then we apply some local gradient descent to optimize the loss function.

In practice, we can do that using `keras` metalibrary of `tensoflow` that lets use reason directly in terms of layers instead of single neurons.

We intialize a NN specifying the layers.
In out example, we have $28 times 28$ input neuros for the input layer and a layer of $10$ neurons for the output.
These are strongly interconnected, so it is a dense layer.

```python
da notebook // TODO
```

Instead of computing the derivatives and then using the analytical form for the training, modern ml libraries use a technique called back-propagation.
We will see this better next lecture.

/ Epoch: unit of measure for time.
  Continuing the optimization by processing the train data several times.
  Once the whole dataset has been used, an epoch expired.

With a simple neural model, we get like 90% accuracy, which is not enough.
We can stack more layers to improve accuracy.

A simple model, with no hidden layers, can separate only linearly separable binary datasets.
Models with hidden layers, can separate any binary function.

Each hidden layer reduces the number of neurons in that layer.
The idea is that each neuron of a layer represents a feature present in the data of the previous layer.
So they tend to become less and less, by classifying these features.

How do we know how many layers and how many neurons per layer? Open problem: just try and evaluate the results.

It is really easy to grow the number of parameters with hidden layers.
Each parameter is an unknown in the loss function that needs to be minimized.

If we use sigmoid for activation function in the hidden layers, we get a problem: vanishing. // TODO???.
Instead of that, we can use ReLU as activation function.

We see that there an overfitting trend is starting.

/ Learning rate: the gradient gives us the direction where to move, but it does not specify how much.
  The learning rate is how much we move into that direction, which is also how fast the model learns.
  Typically we start with an high learning rate and esponentially lower it with epochs increasing.

The more complex is the model, the more it is plastic: it can adapt to more complex data.
But this calls for overfitting.
To fight overfitting, historically we used penalization, a more modert technique is drop out.

/ Drop out: when updating weights in backpropagation, we toss a coin and update only if the coin is ok (the coin is not 50%).

== Convolutional NN

Linearization does not work well if we want to identify features that are in a certain area.

We do not linearize the image.

We start by fixing a small part of the image and compute the value of the neuron.
Then we start by moving the area and do that for another portion of the image.
But WITHOUT changing the weights of the connections, so that we are calculating the amount of a fixed feature in a certain area.

We do that for all areas (not forced by moving of 1px), with even padding for borders so that the new layer is as big as the original one.

Then we can do many sublayers, recognizing different features.
Each of these layers is called a convolutional network.

Sooner of later, we need to linearize things. // TODO: why?
- we can add a layer with no weight that just moves from a 3d neurons into a linear layer
- each convolutional layer can be converted into a single output, the amount of that feature in the original input
