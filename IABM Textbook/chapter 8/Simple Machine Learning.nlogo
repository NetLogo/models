;; turtles have a strategy
turtles-own [ strategy ]

;; we need to keep track of the goal and what operators and inputs the agents can use
globals [ goal operators inputs ]

to setup
  clear-all
  set operators [ "+ " "- " "* " ]  ;; set up the usable operators
  set inputs [ "heading " "xcor " "1 " "2 " "10 " ]  ;; set up the usable inputs

  ;; create the first generation of turtles and have them put their pens down
  ;;   so we can see them when they draw
  create-turtles 20 [
    set strategy random-strategy
  ]

  ;; set the goal to the upper right corner
  set goal patch max-pxcor max-pycor
  reset-ticks
end

;; create a new strategy of how to set the heading for each turtle
to-report random-strategy
  ;; each strategy starts consists of 5 inputs and 4 operators alternating
  let strat (list one-of inputs)
  repeat 5 [ set strat (sentence strat one-of operators one-of inputs) ]
  report strat
end

to go
  if ticks > 0 [
    ;; kill off 75% of the turtles with the least fitness
    ;; (i.e., the ones further from the goal)
    let number-to-replace round (0.75 * count turtles)
    ask min-n-of number-to-replace turtles [ fitness ] [ die ]
    ;; store turtles that survived in an agentset that won't expand when
    ;; we hatch new turtles (as would the special `turtles` agentset).
    let best-turtles turtle-set turtles
    ;; hatch new mutant turtles
    repeat number-to-replace [
      ask one-of best-turtles [
        hatch 1 [
          set strategy mutate strategy
          ;; pick a new color that may not be the same as the parent's color
          set color one-of base-colors
        ]
      ]
    ]
  ]
  clear-drawing ;; clear the trails of the killed turtles
  ask turtles [
    reset-positions ;; send all the turtles back to the center of the world
  ]
  ask turtles [
    ;; each turtle runs its strategy and moves forward 25 times
    repeat 25 [
      set heading run-result reduce word strategy
      fd 1
    ]
    set label precision fitness 2  ;; visualize the fitness of each turtle
  ]
  tick
end

;; turtle procedure, set position to origin with random heading
to reset-positions
  home
  set heading random 360
  pen-down ;; put the pen down to draw the turtle's movement
end

;; mutate a strategy by replacing one of its inputs or one of its operators
to-report mutate [strat]
  ifelse random 2 = 0
    [ set strat replace-item (2 * random 6) strat one-of inputs ]
    [ set strat replace-item (1 + 2 * random 5) strat one-of operators ]
  report strat
end

;; The greater the distance a turtle is to the goal, the smaller the fitness
;; of the turtle. Using this formula, a turtle that reaches the goal has a
;; fitness of zero. Turtles that don't reach the goal have a negative fitness.
to-report fitness  ;; turtle procedure
  report distance goal * -1
end


; Copyright 2008 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
303
10
740
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
100
65
190
98
NIL
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
100
120
190
153
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
100
210
190
255
best fitness
max [fitness] of turtles
1
1
11

PLOT
5
275
297
425
Average Fitness vs. Time
ticks
fitness
0.0
10.0
0.0
0.0
true
false
"" ""
PENS
"avg-fitness" 1.0 0 -16777216 true "" "plot mean [fitness] of turtles"

@#$#@#$#@
## ACKNOWLEDGMENT

This model is from Chapter Eight of the book "Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo", by Uri Wilensky & William Rand.

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

This model is in the IABM Textbook folder of the NetLogo Models Library. The model, as well as any updates to the model, can also be found on the textbook website: http://www.intro-to-abm.com/.

## WHAT IS IT?

This model illustrates how to integrate machine learning with agent-based modeling. The model creates a set of turtles whose goal is to get to the upper right corner of the world. The turtles start with random strategies, but the model then uses an evolutionary approach they improve their strategies over time to reach this corner.

## HOW IT WORKS

The model initially creates 20 agents and a list of inputs, such as `HEADING` and `XCOR`, and operators, such as `+`, `-`, etc. It then sets the strategy for each of the agents to a random set of five input / operator combinations. Each strategy results in the turtle changing its heading. When the model runs, each agent executes their strategy twenty five times, moves forward 1 after execution of its strategy, and measures its fitness. On the basis of this measurement, the worst 75% of the turtles in terms of performance are killed and replaced by mutated copies of the top performing 25%. This process is then repeated.

## HOW TO USE IT

Press SETUP to create the agents and strategies.

Press GO to run the agent strategies and see their evolution over time time.

The BEST FITNESS monitor shows the maximum fitness for agents in the current generation. Fitness is defined here as the distance between the turtle and its goal, expressed as a negative value: the closer this value is to zero, the closer the turtle is to the goal, and thus, the more "fit" it is.

The AVERAGE FITNESS VS. TIME plot shows the evolution of the average fitness of the whole population, which should increase over time.

## THINGS TO NOTICE

Do all the agents do the same thing? Can you tell the difference between the different strategies? Do you understand how inputs and operators combine to produce a heading for the turtle?

Do the best turtles reach their goal? Do they reach it _exactly_? If they don't succeed in achieving a distance of zero, why do you think that is? Is there any modification that you could make to the model to allow such a result to be achieved?

Do the strategies seem to converge over time? You should notice that, even when they do, there is still some variation in the population because mutations are introduced with each new generation.

Finally, have you noticed that not every run of the model produces the same "best fitness". Sometimes, the population gets stuck in what we call a "local maximum". This happens when the best turtles in the population have sub-optimal fitness, but every single mutation their offsprings can have actually makes them worse. To reach the "global maximum", they would need many successive mutations, but the current model does not allow that: turtles that are worse then their parent get eliminated right away.

## EXTENDING THE MODEL

Change the list of inputs and operators and see how that affects the results of the model. Can you find a combination of inputs and operators that allow the turtles to reach their goal exactly?

Think about the "local maximum" problem mentioned in the previous section. Can you think of a way out of it? In the current model, only the best 25% of turtles get to reproduce, but maybe this does not have to be the case. Do you think it could be helpful to give other turtles a small chance to reproduce as well?

## NETLOGO FEATURES

This model uses the NetLogo's [`runresult`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#runresult) primitive, which allows you to execute a piece code stored in a string and report its result.

Our strategies are not directly stored as strings, however: they are stored as _lists_ of strings. To turn a strategy into a single string that can be handled by `runresult`, we use the [`reduce`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#reduce) primitive, which can turn a list of values into a single value by repeatedly applying a reporter to combine elements of the list. In this case, the reporter used is [`word`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#word), which simply concatenates the strings.

The `runresult` primitive can also be used with [tasks](http://ccl.northwestern.edu/netlogo/docs/programming.html#tasks) instead of strings. See the Sandpile model in the library for an example.

## HOW TO CITE

This model is part of the textbook, “Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo.”

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rand, W. & Wilensky, U. (2008).  NetLogo Simple Machine Learning model.  http://ccl.northwestern.edu/netlogo/models/SimpleMachineLearning.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the textbook as:

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2008 Cite: Rand, W. & Wilensky, U. -->
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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
