#import "../template.typ": *

= Deep Learning

#rect(stroke: 2pt + red, fill: red.transparentize(70%))[
  #todo

  Contribute to open #link("https://github.com/Favo02/algorithms-for-massive-datasets/pull/14")[pull request \#14] approving or improving this chapter.
]

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

// TODO: end of convulutional

== Recurrent Neural Network

Autoregressive.

We take $x$ characters as input, and put $x-1$ of these as output.
We are interested in the last one that gets generated.
Then we move all and generate the next character and so forth.

We add an output layer to have a probability distribution on each possible character and not a crisp output.
So that we get the probability of prediction of each character for the next one.
If we always pick the character with the highest probability, we get a deterministic generation.
Or we can simulate an extraction based on the probabilities.
Usually some mechanism that mix these two approach are used, both probabilistic but not on all the characters.

Recurrent NN are history.
In the last 10 years, transformers and LLM are the new form of deep learning and are much more efficient.

== transformer

A trasnformer is an highly structured Neural network.
It is not complex (uses all things we already saw), but is complicated (there are a lot of them in a complex structure).

A big advantage is that they can be trained on parallel hardware, GPU.
But they are very very big, the training is very very expensive.

HuggingFace: repository of pre-trained neural networks (and transformers).

Take a pre-trained model and fine-tune it: adapt the structure of the model to a specific context and retrain only a small part of the parameters of the model.

We will use an autorecurrent approach.
We start with the input and an output string as output.

IN the same way as before, we take the generated token and append to the output.
We don't have a sliding window, the input always stays there and the output icnreases step by step (and never decreases).

- Tokenization: divide the input in tokens
- Vectorization: transform each token in a number so that it can be processed by the model

The main problem of RNN is that they have a short memory (because of the sliding window thing).
To overcome this problem, the attention mechanism is introduced.

Exists multiple architectures of transformers, some with only decoder, some with only encoder and some with both.

=== Embeddings

Take a string length $n$ from an alphabet and trasform it into a matrix $n times d$.
Each character is trasformed in a vector, so the string is a matrix.
$d$ is typically 512, this will be important for the whole process.

Not only encode a word in a vector, but also similarity as proximity.

=== Positional Encoding

Because of the next steps are independent of order, we need to inject manually order so that it will be understood.
So we add like a progressive sequence to each embedding.

=== Encoding

Multiple encoding blocks.
Learning meaningful representation of the data.

- MHSA: learning dependencies between the tokens (even dependencies from far tokens)
- Normalization
- Feed Forward Neural Network (FFNN)
- Normalization

Other than that, some rediduals connections (that skips some blocks) are added.
This is useful to counteract vanishing and exploding gradients.

=== Self Attention mechanism

Dealing with long term context and disambiguation.

The idea is to move the vectors of something, based on the context we are in.

E.g. the embedding of Apple can be close to organe or bananas, but also close the google or microsoft.
Based on the current context, we move the embedding closer to one or to the other (fruits or tech).

To do that, we compute the similarity between all pairs of words in the sentence. // TODO: ???

Usually, similarity is well caught by inner products, but there are some problems:
- product tend to increase a lot with the dimension of the embedding, so we normalize
- product can be negative, so we apply softmax

$ X^"att" = "softmax"((X X^T)/sqrt(d)) dot X $

=== MUlti-head self attention

But the same word could have multiple meanings "I was eating an apple at the apple store".

The idea is to use multiple embeddings and calculate attention for all of these.
That poses multiple problems:
- good embeddings are difficult to find
- big dimensionality

To fix that problem, we keep only one real embedding and then applying linear transformations.
This "moves" around the points of the space, so that the points are closer in similar ways.

We apply attention to the embedding with different linear transformations.
The output of all attentions is concatenated.
The size of each one is smaller so that the concatenation gives back to the dimension $d$.

=== Masked attention

Because the output is not full, we place empty string.
But that must be encoded into a valid vector, and computing the attention for that vector gives gibberish (the attention is computer for the whole output).

So, we mask that by placing $-infinity$ where the output token is not yet generated.

=== Training

These are trained using back-propagation, like NN.

All the parameters that can be decided are trained (the linear transformation, the neurons, ...).

These can be trained using self-supervising techniques.
The web is full of text sequences (like wikipedia articles).
The first part of the sequence is fed and the continuation is the part that needs to be generated.
