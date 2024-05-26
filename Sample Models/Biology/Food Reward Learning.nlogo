turtles-own [
  alpha          ; Rate of learning
  beta           ; Responsivity to food
  food-consumed  ; Food consumed at time step
  value-low      ; Predicted value reward for low type food
  value-high     ; Predicted value reward for high type food
]

patches-own [
  food-objects   ; The food objects on the patch {HH, HL, LL}
]

to setup
  clear-all
  setup-environment
  setup-turtles
  setup-visuals
  reset-ticks
end

to setup-environment
  ; Change the number of patches in the world keeping the display size constant
  resize-world 0 (grid-size - 1) 0 (grid-size - 1)
  set-patch-size (480 / grid-size)
  ; Initialize the patches conditionally based on the food environment
  run word food-environment "-setup"
end

to random-setup
  ask patches [
    set food-objects one-of [ "HH" "HL" "LL" ]
  ]
end

to gradient-setup
  ask patches [
    ; Split world into HH on the top and LL on the bottom
    ifelse pycor < (grid-size / 2)
    [ set food-objects "LL" ]
    [ set food-objects "HH" ]
    ; Randomly add more HL patches to the right side of the world
    if random max-pxcor < pxcor [
      set food-objects "HL"
    ]
  ]
end

to uniform-setup
  ask patches [
    ; Split world into HH on the top and HL on the bottom
    ifelse pycor < (grid-size / 2)
    [ set food-objects "HL" ]
    [ set food-objects "HH" ]
  ]
end

to setup-turtles
  let turtle-ycor 0 ; Initial ycor for each turtle
  create-turtles grid-size [
    ; Set initial location to the far left of the world
    move-to patch 0 turtle-ycor
    set heading 90
    ; Set every other turtles learning rate to alpha-1 or alpha-2
    ifelse turtle-ycor mod 2 = 0 [
      set alpha alpha-2
    ] [
      set alpha alpha-1
    ]
    ; Set every other pair of turtles responsivity to beta-1 or beta-2
    ifelse (turtle-ycor mod 4) / 2 >= 1 [
      set beta beta-1
    ] [
      set beta beta-2
    ]
    set food-consumed ""
    update-visuals
    set turtle-ycor turtle-ycor + 1
  ]
end

to go
  if ticks >= grid-size - 1 [ stop ]
  ask turtles [
    move
    eat
    update-reward
    update-visuals
  ]
  tick
end

to move ; turtle procedure
  forward 1
end

to eat ; turtle procedure
  let food-choices [ food-objects ] of patch-here

  (ifelse
    ; If HH or LL consume H or L, respectively
    (food-choices = "HH") or (food-choices = "LL") [
      set food-consumed (first food-choices)
    ]
    ; If equal learned reward values, pick consumption at random
    value-low = value-high [
      set food-consumed one-of [ "H" "L" ]
    ]
    [ ; Otherwise, pick the food with more value
      set food-consumed ifelse-value value-low > value-high ["L"] ["H"]
      ; With some random chance switch to the other food type
      if (random-float 1) < 0.05 [
        set food-consumed ifelse-value food-consumed = "L" ["H"] ["L"]
      ]
    ]
  )
end

to update-reward ; turtle procedure
  ; Update learned reward value based on the food consumed using TDL algorithm
  ifelse food-consumed = "L" [
    set value-low (value-low + alpha * (beta * p-low - value-low))
  ] [
    set value-high (value-high + alpha * (beta * p-high - value-high))
  ]
end

to setup-visuals
  ask patches [
    if food-objects = "LL" [ set pcolor green ]
    if food-objects = "HL" [ set pcolor gray ]
    if food-objects = "HH" [ set pcolor black ]
  ]

  ask turtles [
    set shape ifelse-value alpha = alpha-1 ["circle"] ["square"]
  ]


end

to update-visuals ; turtle procedure
  set color scale-color orange value-high (beta-1 + 0.75) -0.25
end

to-report beta-1
  ifelse heterogeneous-responsivity?
  [ report 2.0 ]
  [ report 1.0 ]
end

to-report beta-2
  ifelse heterogeneous-responsivity?
  [ report 0.5 ]
  [ report 1.0 ]
end


; Copyright 2023 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
660
10
1148
499
-1
-1
12.0
1
10
1
1
1
0
0
0
1
0
39
0
39
1
1
1
ticks
30.0

BUTTON
120
240
225
273
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

BUTTON
10
240
115
273
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

SLIDER
10
10
225
43
grid-size
grid-size
20
200
40.0
20
1
NIL
HORIZONTAL

SWITCH
10
165
225
198
heterogeneous-responsivity?
heterogeneous-responsivity?
0
1
-1000

TEXTBOX
15
95
216
113
Learning rate (α) values of agents
11
0.0
1

TEXTBOX
15
150
220
168
Allow food responsivity (β) to vary
11
0.0
1

SLIDER
10
290
115
323
p-low
p-low
0
0.5
0.25
0.05
1
NIL
HORIZONTAL

SLIDER
120
290
225
323
p-high
p-high
0.5
1
0.75
0.05
1
NIL
HORIZONTAL

TEXTBOX
15
275
245
293
Palatability of low and high value foods
11
0.0
1

SLIDER
120
110
225
143
alpha-2
alpha-2
0
1
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
10
110
115
143
alpha-1
alpha-1
0
1
0.3
0.1
1
NIL
HORIZONTAL

TEXTBOX
10
400
60
466
■
50
0.0
1

TEXTBOX
10
330
60
390
■
50
55.0
1

TEXTBOX
10
365
60
426
■
50
5.0
1

TEXTBOX
50
355
220
505
Two low-value food options\n\nOne high-value and one \nlow-value food option\n\nTwo high-value food options\n\nAgent (α = alpha-1)\n\nAgent (α = alpha-2)
11
0.0
1

CHOOSER
10
50
225
95
food-environment
food-environment
"random" "gradient" "uniform"
1

PLOT
240
10
650
175
Expected Palatability of High Value Food (Top)
Ticks
Average
0.0
10.0
0.0
1.25
true
true
"" ""
PENS
"alpha-1, beta-1" 1.0 0 -7500403 true "plot mean [ value-high ] of turtles with [ (alpha = alpha-1) and (beta = beta-1) and ycor >= grid-size / 2 ]" "plot mean [ value-high ] of turtles with [ (alpha = alpha-1) and (beta = beta-1) and ycor >= grid-size / 2 ]"
"alpha-2, beta-1" 1.0 0 -955883 true "plot mean [ value-high ] of turtles with [ (alpha = alpha-2) and (beta = beta-1) and ycor >= grid-size / 2 ]" "plot mean [ value-high ] of turtles with [ (alpha = alpha-2) and (beta = beta-1) and ycor >= grid-size / 2 ]"
"alpha-1, beta-2" 1.0 0 -1184463 true "plot mean [ value-high ] of turtles with [ (alpha = alpha-1) and (beta = beta-2) and ycor >= grid-size / 2 ]" "plot mean [ value-high ] of turtles with [ (alpha = alpha-1) and (beta = beta-2) and ycor >= grid-size / 2 ]"
"alpha-2, beta-2" 1.0 0 -10899396 true "plot mean [ value-high ] of turtles with [ (alpha = alpha-2) and (beta = beta-2) and ycor >= grid-size / 2 ]" "plot mean [ value-high ] of turtles with [ (alpha = alpha-2) and (beta = beta-2) and ycor >= grid-size / 2 ]"

PLOT
240
185
650
345
Average Expected Palatability of High Value Food
Ticks
Average
0.0
10.0
0.0
1.25
true
true
"" ""
PENS
"Top" 1.0 0 -2674135 true "plot mean [ value-high ] of turtles with [ ycor >= grid-size / 2 ]" "plot mean [ value-high ] of turtles with [ ycor >= grid-size / 2 ]"
"Bottom" 1.0 0 -13345367 true "plot mean [ value-high ] of turtles with [ ycor < grid-size / 2 ]" "plot mean [ value-high ] of turtles with [ ycor < grid-size / 2 ]"

TEXTBOX
95
330
150
356
Legend
12
0.0
1

PLOT
240
355
650
500
Distribution of Expected Palatability (by Region)
Expected Palatability of High Value Food
Count
0.0
2.25
0.0
1.0
true
true
"" ""
PENS
"Top" 0.1 1 -2674135 true "histogram [ value-high ] of turtles with [ ycor >= grid-size / 2 ]" "histogram [ value-high ] of turtles with [ ycor >= grid-size / 2 ]"
"Bottom" 0.1 1 -13345367 true "histogram [ value-high ] of turtles with [ ycor < grid-size / 2 ]" "histogram [ value-high ] of turtles with [ ycor < grid-size / 2 ]"

TEXTBOX
13
438
47
479
●
38
24.0
1

TEXTBOX
14
465
52
506
■
38
24.0
1

BUTTON
45
205
192
238
toggle beta labels
ask turtles [\nifelse label = \"\" [\nset label beta\nset label-color black\n] [\nset label \"\"\n]\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model explores a possible mechanism through which individuals can form food preferences and the role that food environments may play in shaping these preferences. Agents repeatedly choose between two food options that differ based on where in the environment they are located.  Each agent’s expected reward value of the two food types (i.e., their expectation of how much they would enjoy eating these foods) gradually changes through consumption using a temporal difference learning algorithm.

This model is based on the original paper by Hammond et al. (2012) and can be used to replicate several of the authors findings.

## HOW IT WORKS

In the base model, there are two food types: low palatability (L) and high palatability (H). Each food type has an associated palatability between zero and one that controls the “true” reward value of the food. The model environment consists of a square lattice where each cell can contain a set of two food types: either HH (colored black), HL (colored gray), or LL (colored green).

Every agent has a learned reward value for the low and high value food types. These reward values can be thought of as the agent’s expectation of how much they would enjoy eating each food type. At the start of the model, agents have no prior expectations of the reward value of each food type and are initialized with learned reward values of zero. The value of each agent's expected palatability of high value food is represented with color, where darker colored agents have higher learned reward values than lighter colored agents.

Agents begin on the left side of the lattice and progress to the right, one cell at time, until they have reached the right side of the lattice, at which point the simulation terminates.

At each time step agents consume one of the food objects in the cell that they are currently occupying. If the cell contains either HH or LL, the agent will select H or L, respectively. However, if the cell contains both food types, the agent will select the food type that they currently perceive as having a higher value—i.e., the food type with the larger corresponding learned reward value. If the agent considers both food types to be exactly equivalent in value, they will select one of food types at random. Subsequently, there is a small probability that an agent will switch to the other food option prior to consumption, changing their mind for some reason exogenous to the model.

Finally, the agent will consume their selected food type and update one of their learned reward values, corresponding to the food type the just consumed. The learned reward values are updated using an adapted temporal difference learning algorithm as follows:

*V<sub>F</sub>*(*t* + 1) = *V<sub>F</sub>*(*t*) + *α*[*β* × *p<sub>F</sub> -  V<sub>F</sub>*(*t*)]

where:

*F*: is the food type consumed (either H or L).
*V<sub>F</sub>*(*t*): is the agent’s learned reward value of food type *F* at time *t*.
*α*: is the agent’s learning rate, the speed at which they update their learned reward value.
*β*: is the agent’s responsivity to food, a factor that modifies their reward values for each food type.
*p<sub>F</sub>*: The “true” reward value of food type *F*.

## HOW TO USE IT

The two buttons, SETUP and GO, control execution of the model. The SETUP button will initialize the food environment, agents, and other variables, preparing the model to be run. The GO button will then run the model until all agents have reached the right side of the world.

GRID-SIZE controls both the number of agents in the model (equal to the sliders value) and the size of the world (equal to the square of the slider value).

FOOD-ENVIRONMENT controls the initialization of the food types in the model.

* “random” initializes each cell randomly to HH, HL, or LL with equal probability.
* “gradient” splits the world into two environments starting in a mostly HH or LL environment and transitioning to an environment of mostly HL.
* “uniform” splits the world in half such that one environment is solely HH and the other environment is solely HL.

The slider ALPHA-1 controls the learning rate that half of all agents will be initialized with (denoted in circles), while ALPHA-2 controls the learning rate of the remaining agents (denoted in squares). If ALPHA-1 is equal to ALPHA-2 all agents will share a single learning rate.

If the HETEROGENEOUS-RESPONSIVITY? switch is "Off" all agents will share the same responsivity to food. If set to "On" responsivity to food can differ across agents with half of all agents having increased responsivity (beta-1) and the remaining agents having decreased responsivity (beta-2).

The P-LOW and P-HIGH sliders set the specific "true" reward values of high (H) and low (L) value foods.

## THINGS TO NOTICE

Early food environments can create a “lock-in” effect where current and future agent preferences are strongly influenced by initial consumption decisions and food environments. For example, if two agents are currently in identical food environments, their future consumption decisions may differ if their consumption and/or environment option set in the past was different.

The “gradient” FOOD-ENVIRONMENT demonstrates a good example of “lock-in” effects. Notice that even though agents are in identical environment cells toward the end of the model run, the food options along the paths that they took to the right side are different, resulting in different learned reward values.

This finding *could* help provide greater insight into research on eating behaviors because solely studying *current* food environments and *current* eating behaviors may not fully account for early “lock-in” effects (Hammond et al. 2012).

## THINGS TO TRY

Start by running the model with ALPHA-1 and ALPHA-2 set to 0.4. Now try running the model with different values of ALPHA-1 and ALPHA-2. What happens to the final learned reward value and how quickly do agents reach equilibrium? What happens as you change the values of the learning rate values?

Try setting HETEROGENEOUS-RESPONSIVITY? to "On". What happens to the final learned reward value and how quickly do agents reach equilibrium? What happens when HETEROGENEOUS-RESPONSIVITY? is "On" and learning rates ALPHA-1 and ALPHA-2 are not equal?

Try answering the above questions with different FOOD-ENVIRONMENTS. Are there certain food environments where the spread (or distribution) of learned reward values is greater than others? If so, can you hypothesize why this might be the case?

Try adjusting the reward values (P-LOW and P-HIGH) of the two food types. How does this change your previous findings?

## EXTENDING THE MODEL

Add other FOOD-ENVIRONMENTs to the model.

Add a reporter to calculate the time it took each group of agents to learn the reward value of each food type.

Add another food type to the model.

## NETLOGO FEATURES

World is resized dynamically based on user input.

The legend in the interface tab was created by using notes with large unicode characters and setting the text color to the desired element color.

To concisely manage the setup of different food environments, the string name of each environment (e.g., `"random"`) has a corresponding setup procedure with the suffix `"-setup"` (e.g., `to random-setup`). The command `word food-environment "-setup"` concatenates the selected environment string name with the suffix `"-setup"` to get the string name of the setup procedure. This procedure is then executed using the `run` command. This avoids having to use an `ifelse` statement in the setup to match each environment string name to a corresponding setup procedure.

## RELATED MODELS

Some other NetLogo models that explore algorithms for agent learning are the "El Farol" models and the "Piagel-Vygotsky Game". Any models using a temporal difference learning (TDL) algorithm will also be related to this model.

## CREDITS AND REFERENCES

This NetLogo model was adapted and implemented by Adam B. Sedlak and Matt Kasman, based on the original paper:

* Hammond RA et al. “A model of food reward learning with dynamic reward exposures”. *Frontiers in Computational Neuroscience*, 6:82 (2012).
* A copy of this paper is avalible at: https://joeornstein.github.io/publications/Hammond-2012.pdf

Many thanks to Ross Hammond for his helpful comments as we created this model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Sendlak, A., Kasman, M. and Wilensky, U. (2023).  NetLogo Food Reward Learning model.  http://ccl.northwestern.edu/netlogo/models/FoodRewardLearning.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2023 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2023 Cite: Sendlak, A., Kasman, M. -->
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

circle 1 dot
true
0
Circle -7500403 true true 2 2 295
Rectangle -16777216 true false 120 120 180 180

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

circle 2 dots
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 135 90 30
Circle -16777216 true false 135 165 30

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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
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
