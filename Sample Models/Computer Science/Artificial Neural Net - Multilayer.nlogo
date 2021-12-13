links-own [ weight ]

breed [ bias-nodes bias-node ]
breed [ input-nodes input-node ]
breed [ output-nodes output-node ]
breed [ hidden-nodes hidden-node ]

turtles-own [
  activation     ;; Determines the nodes output
  err            ;; Used by backpropagation to feed error backwards
]

globals [
  epoch-error    ;; measurement of how many training examples the network got wrong in the epoch
  input-node-1   ;; keep the input and output nodes
  input-node-2   ;; in global variables so we can
  output-node-1  ;; refer to them directly
]

;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  ask patches [ set pcolor gray ]
  set-default-shape bias-nodes "bias-node"
  set-default-shape input-nodes "circle"
  set-default-shape output-nodes "output-node"
  set-default-shape hidden-nodes "output-node"
  set-default-shape links "small-arrow-shape"
  setup-nodes
  setup-links
  propagate
  reset-ticks
end

to setup-nodes
  create-bias-nodes 1 [ setxy -4 6 ]
  ask bias-nodes [ set activation 1 ]
  create-input-nodes 1 [
    setxy -6 -2
    set input-node-1 self
  ]
  create-input-nodes 1 [
    setxy -6 2
    set input-node-2 self
  ]
  ask input-nodes [ set activation random 2 ]
  create-hidden-nodes 1 [ setxy 0 -2 ]
  create-hidden-nodes 1 [ setxy 0  2 ]
  ask hidden-nodes [
    set activation random 2
    set size 1.5
  ]
  create-output-nodes 1 [
    setxy 5 0
    set output-node-1 self
    set activation random 2
  ]
end

to setup-links
  connect-all bias-nodes hidden-nodes
  connect-all bias-nodes output-nodes
  connect-all input-nodes hidden-nodes
  connect-all hidden-nodes output-nodes
end

to connect-all [ nodes1 nodes2 ]
  ask nodes1 [
    create-links-to nodes2 [
      set weight random-float 0.2 - 0.1
    ]
  ]
end

to recolor
  ask turtles [
    set color item (step activation) [ black white ]
  ]
  ask links [
    set thickness 0.05 * abs weight
    ifelse show-weights? [
      set label precision weight 4
    ] [
      set label ""
    ]
    ifelse weight > 0
      [ set color [ 255 0 0 196 ] ] ; transparent red
      [ set color [ 0 0 255 196 ] ] ; transparent light blue
  ]
end

;;;
;;; TRAINING PROCEDURES
;;;

to train
  set epoch-error 0
  repeat examples-per-epoch [
    ask input-nodes [ set activation random 2 ]
    propagate
    backpropagate
  ]
  set epoch-error epoch-error / examples-per-epoch
  tick
end

;;;
;;; FUNCTIONS TO LEARN
;;;

to-report target-answer
  let a [ activation ] of input-node-1 = 1
  let b [ activation ] of input-node-2 = 1
  ;; run-result will interpret target-function as the appropriate boolean operator
  report ifelse-value run-result
    (word "a " target-function " b") [ 1 ] [ 0 ]
end

;;;
;;; PROPAGATION PROCEDURES
;;;

;; carry out one calculation from beginning to end
to propagate
  ask hidden-nodes [ set activation new-activation ]
  ask output-nodes [ set activation new-activation ]
  recolor
end

;; Determine the activation of a node based on the activation of its input nodes
to-report new-activation  ;; node procedure
  report sigmoid sum [ [ activation ] of end1 * weight ] of my-in-links
end

;; changes weights to correct for errors
to backpropagate
  let example-error 0
  let answer target-answer

  ask output-node-1 [
    ;; `activation * (1 - activation)` is used because it is the
    ;; derivative of the sigmoid activation function. If we used a
    ;; different activation function, we would use its derivative.
    set err activation * (1 - activation) * (answer - activation)
    set example-error example-error + ((answer - activation) ^ 2)
  ]
  set epoch-error epoch-error + example-error

  ;; The hidden layer nodes are given error values adjusted appropriately for their
  ;; link weights
  ask hidden-nodes [
    set err activation * (1 - activation) * sum [ weight * [ err ] of end2 ] of my-out-links
  ]
  ask links [
    set weight weight + learning-rate * [ err ] of end2 * [ activation ] of end1
  ]
end

;;;
;;; MISC PROCEDURES
;;;

;; computes the sigmoid function given an input value and the weight on the link
to-report sigmoid [input]
  report 1 / (1 + e ^ (- input))
end

;; computes the step function given an input value and the weight on the link
to-report step [input]
  report ifelse-value input > 0.5 [ 1 ] [ 0 ]
end

;;;
;;; TESTING PROCEDURES
;;;

;; test runs one instance and computes the output
to test
  let result result-for-inputs input-1 input-2
  let correct? ifelse-value result = target-answer [ "correct" ] [ "incorrect" ]
  user-message (word
    "The expected answer for " input-1 " " target-function " " input-2 " is " target-answer ".\n\n"
    "The network reported " result ", which is " correct? ".")
end

to-report result-for-inputs [n1 n2]
  ask input-node-1 [ set activation n1 ]
  ask input-node-2 [ set activation n2 ]
  propagate
  report step [ activation ] of one-of output-nodes
end


; Copyright 2006 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
255
10
569
253
-1
-1
18.0
1
10
1
1
1
0
0
0
1
-8
8
-5
7
1
1
1
ticks
30.0

BUTTON
155
10
240
43
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
155
50
240
85
train
train
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
582
134
677
168
test
test
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
582
34
677
79
input-1
input-1
0 1
1

CHOOSER
582
84
677
129
input-2
input-2
0 1
0

MONITOR
512
279
569
324
output
[precision activation 2] of one-of output-nodes
3
1
11

SLIDER
10
128
240
161
learning-rate
learning-rate
0.0
1.0
0.5
1.0E-4
1
NIL
HORIZONTAL

PLOT
10
209
240
364
Error vs. Epochs
Epochs
Error
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot epoch-error"

SLIDER
10
168
240
201
examples-per-epoch
examples-per-epoch
1.0
1000.0
500.0
1.0
1
NIL
HORIZONTAL

CHOOSER
257
279
417
324
target-function
target-function
"or" "xor"
1

TEXTBOX
10
20
140
38
1. Setup neural net:
11
0.0
0

TEXTBOX
10
60
135
88
2. Train neural net:
11
0.0
0

TEXTBOX
582
14
732
32
3. Test neural net:
11
0.0
0

SWITCH
257
329
417
362
show-weights?
show-weights?
1
1
-1000

BUTTON
155
90
240
123
train once
train
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

@#$#@#$#@
## WHAT IS IT?

This is a model of a very small neural network.  It is based on the Perceptron model, but instead of one layer, this network has two layers of "perceptrons".  Furthermore, the layers activate each other in a nonlinear way. These two additions means it can learn operations a single layer cannot.

The goal of a network is to take input from its input nodes on the far left and classify those inputs appropriately in the output nodes on the far right.  It does this by being given a lot of examples and attempting to classify them, and having a supervisor tell it if the classification was right or wrong.  Based on this information the neural network updates its weight until it correctly classifies all inputs correctly.

## HOW IT WORKS

Initially the weights on the links of the networks are random.

The nodes on the left are the called the input nodes, the nodes in the middle are called the hidden nodes, and the node on the right is called the output node.

The activation values of the input nodes are the inputs to the network. The activation values of the hidden nodes are equal to the activation values of inputs nodes, multiplied by their link weights, summed together, and passed through the [sigmoid function](https://en.wikipedia.org/wiki/Sigmoid_function). Similarly, the activation value of the output node is equal to the activation values of hidden nodes, multiplied by the link weights, summed together, and passed through the sigmoid function. The output of the network is 1 if the activation of the output node is greater than 0.5 and 0 if it is less than 0.5.

The sigmoid function maps negative values to values between 0 and 0.5, and maps positive values to values between 0.5 and 1.  The values increase nonlinearly between 0 and 1 with a sharp transition at 0.5.

In order for the network to learn anything, it needs to be trained. In this example, the training algorithm used is called the backpropagation algorithm. It consists of two phases: propagate and backpropagate. The propagate phase was described above: it propagates the activation values of the input nodes to the output node of the network.
In the backpropagate phase, the error in the produced value is passed back through the network layer by layer.

To do the backpropagation phase, the error is first calculated as a difference between the correct (expected) output and the actual output of the network. Since all of the hidden nodes connected to the output contribute to the error, all of the weights need to be updated. To do this, we need to calculate how much each of the nodes contributed to the overall error on the output. This is done by calculating a local gradient for each of the nodes, excluding the input nodes (since the input is the activation we provide to the network, and thus has no error associated with it).

The local gradients are calculated layer by layer. For the output nodes, it is the multiplication of the error with the result of passing the activation value to the derivative of the activation function. Since, in this model, the activation function is the sigmoid function, its simplified derivative ends up being:

    activation_value * (1 - activation_value)

If we wished to use a different activation function, we would use the derivative of that function instead.

For each hidden node, the local gradient is calculated as follows:

1. For each output node connected to the hidden node, multiply its local gradient with the weight of the link connecting them;

2. Sum all the results from the previous step;

3. Multiply that sum with the result of passing the activation value of the hidden node to the derivative of the activation function.

To update the weights of each of the links, we multiply the learning rate with the local gradient of `end2` (this will be the output node in case the link connects a hidden node with the output node) and the activation value of `end1` (this will be the hidden node in case the link connects a hidden node with the output node). The result is then added to the old weight.

The propagate and backpropagate phases are repeated for each example shown to the network.

## HOW TO USE IT

To use it press SETUP to create the network and initialize the weights to small random numbers.

Press TRAIN ONCE to run one epoch of training.  The number of examples presented to the network during this epoch is controlled by EXAMPLES-PER-EPOCH slider.

Press TRAIN to continually train the network.

In the view, the larger the size of the link the greater the weight it has.  If the link is red then it has a positive weight.  If the link is blue then it has a negative weight.

If SHOW-WEIGHTS? is on then the links will be labeled with their weights.

To test the network, set INPUT-1 and INPUT-2, then press the TEST button.  A dialog box will appear telling you whether or not the network was able to correctly classify the input that you gave it.

LEARNING-RATE controls how much the neural network will learn from any one example.

TARGET-FUNCTION allows you to choose which function the network is trying to solve.

## THINGS TO NOTICE

Unlike the Perceptron model, this model is able to learn both OR and XOR.  It is able to learn XOR because the hidden layer (the middle nodes) and the nonlinear activation allows the network to draw two lines classifying the input into positive and negative regions.  A perceptron with a linear activation can only draw a single line. As a result one of the nodes will learn essentially the OR function that if either of the inputs is on it should be on, and the other node will learn an exclusion function that if both of the inputs or on it should be on (but weighted negatively).

However unlike the perceptron model, the neural network model takes longer to learn any of the functions, including the simple OR function.  This is because it has a lot more that it needs to learn.  The perceptron model had to learn three different weights (the input links, and the bias link).  The neural network model has to learn ten weights (4 input to hidden layer weights, 2 hidden layer to output weight and the three bias weights).

## THINGS TO TRY

Manipulate the LEARNING-RATE parameter.  Can you speed up or slow down the training?

Switch back and forth between OR and XOR several times during a run.  Why does it take less time for the network to return to 0 error the longer the network runs?

## EXTENDING THE MODEL

Add additional functions for the network to learn beside OR and XOR.  This may require you to add additional hidden nodes to the network.

Backpropagation using gradient descent is considered somewhat unrealistic as a model of real neurons, because in the real neuronal system there is no way for the output node to pass its error back.  Can you implement another weight-update rule that is more valid?

## NETLOGO FEATURES

This model uses the link primitives.  It also makes heavy use of lists.

## RELATED MODELS

This is the second in the series of models devoted to understanding artificial neural networks.  The first model is Perceptron.

## CREDITS AND REFERENCES

The code for this model is inspired by the pseudo-code which can be found in Tom M. Mitchell's "Machine Learning" (1997).

See also Haykin (2009) Neural Networks and Learning Machines, Third Edition.

Thanks to Craig Brozefsky for his work in improving this model and to Marin Aglić Čuvić for info tab improvements.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rand, W. and Wilensky, U. (2006).  NetLogo Artificial Neural Net - Multilayer model.  http://ccl.northwestern.edu/netlogo/models/ArtificialNeuralNet-Multilayer.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2006 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2006 Cite: Rand, W. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bias-node
false
0
Circle -16777216 true false 0 0 300
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 120 60 150 60 165 60 165 225 180 225 180 240 135 240 135 225 150 225 150 75 135 75 150 60

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0

output-node
false
1
Circle -7500403 true false 0 0 300
Circle -2674135 true true 30 30 240
Polygon -7500403 true false 195 75 90 75 150 150 90 225 195 225 195 210 195 195 180 210 120 210 165 150 120 90 180 90 195 105 195 75

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
resize-world -7 7 -7 7 ; for square aspect ratio
setup repeat 100 [ train ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0

small-arrow-shape
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 135 180
Line -7500403 true 150 150 165 180
@#$#@#$#@
1
@#$#@#$#@
