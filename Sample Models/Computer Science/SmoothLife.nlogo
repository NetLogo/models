patches-own [
  inner-neighbors
  outer-neighbors
  inner-count
  outer-count
  inner-filling
  outer-filling
  state
]

to setup
  clear-all
  ; Plot the transition function for the current settings
  if (not netlogo-web?) [ visualize-transition ]
  ask patches [
    ; Store neighboring patches so that we don't have to calculate them each tick
    set inner-neighbors patches in-radius inner-radius
    set outer-neighbors patches in-radius outer-radius with [ distance myself > inner-radius ]
    ; Store counts so we don't have to recalculate them each tick
    set inner-count count inner-neighbors
    set outer-count count outer-neighbors
    set state random-float 0.75
    recolor
  ]
  reset-ticks
end

to go

  ; Patches add their state to their neighbors.
  ask patches with [ state > 1e-4 ] [
    let s state
    ask inner-neighbors [ set inner-filling inner-filling + s ]
    ask outer-neighbors [ set outer-filling outer-filling + s ]
  ]
  ; The obvious way of implementing the above code is:
  ; ask patches [
  ;   set inner-filling mean [ state ] of inner-neighbors
  ;   set outer-filling mean [ state ] of outer-neighbors
  ; ]
  ; However, since the majority of patches have states very close to 0 for most of
  ; the simulation the obvious implementation is unnecessarily slow. Instead, we
  ; only go over the patches with sufficiently large states (greater than 0.0001)
  ; and have them add their state to their neighbors. This makes the simulation much
  ; faster in general. Can you see why flipping the logic in this way works?

  ask patches [
    ; Since the patch behavior is made up entirely of updating their STATE variable
    ; based on the STATEs of those around them, we can encapsulate this behavior in
    ; reporter procedure. This makes the code much more flexible and easy to test.
    set state transition (outer-filling / outer-count) (inner-filling / inner-count)
    recolor
    set inner-filling 0
    set outer-filling 0
  ]
  tick
end


; Compute the next state of the patch based on state of the value of the "cell"
; centered at that patch and the surrounding neighborhood.
to-report transition [ outer inner ]
    report (sigmoid-outer outer
      (sigmoid-inner min-birth min-survive inner)
      (sigmoid-inner max-birth max-survive inner))
end


; Calculates a sigmoid (s-shaped) function with a few parameters:
; a is the location of the center of the curve
; step-width controls how gradual the curve is
to-report sigmoid [ x a step-width ]
  report 1 / (1 + exp (- (x - a) * 4 / step-width))
end


; Connects two sigmoids together, with one of the them reversed.
; In other words, this function starts at 0, curves up to 1 at B
; and then curve back down to 0 at A (assuming A < B).
to-report sigmoid-outer [ outer a b ]
  report (sigmoid outer a outer-step-width) * ( 1 - (sigmoid outer b outer-step-width))
end

; Sigmoid curve (with inner being the input) starting at STARTING-VALUE and going to
; ENDING-VALUE
to-report sigmoid-inner [ starting-value ending-value inner ]
  report starting-value * ( 1 - (sigmoid inner 0.5 inner-step-width))
       + ending-value   *       (sigmoid inner 0.5 inner-step-width)
end

; Plots the transition function used by patches
to visualize-transition
  set-current-plot-pen "transition"
  clear-plot
  ; Compute the resulting patch state for every combination of inner state and outer
  ; state. NetLogo plots don't have built-in support for displaying two dimensional
  ; images, so instead we plot an individual point for each such combination, and
  ; color the points based on the resulting patch state.
  foreach (range 0 1 0.01) [ outer-state ->
    foreach (range 0 1 0.01) [ inner-state ->
      set-plot-pen-color 10 * transition outer-state inner-state
      plotxy outer-state inner-state
    ]
  ]
end


to recolor
  set pcolor scale-color white state 0 1
end

to erase-all
  ask patches [
    set state 0
    recolor
  ]
end

to paint
  if mouse-inside? and mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      ask patches in-radius paint-radius [
        set state paint-value
        recolor
      ]
    ]
    display
  ]
end


; Copyright 2017 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
190
45
710
566
-1
-1
4.0
1
10
1
1
1
0
1
1
1
0
127
0
127
1
1
1
ticks
30.0

SLIDER
5
10
185
43
outer-radius
outer-radius
0
50
9.0
0.5
1
NIL
HORIZONTAL

BUTTON
5
80
90
113
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
80
185
113
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

SLIDER
5
115
185
148
min-birth
min-birth
0
1
0.278
0.001
1
NIL
HORIZONTAL

SLIDER
5
150
185
183
max-birth
max-birth
0
1
0.365
0.001
1
NIL
HORIZONTAL

SLIDER
5
190
185
223
min-survive
min-survive
0
1
0.267
0.001
1
NIL
HORIZONTAL

SLIDER
5
225
185
258
max-survive
max-survive
0
1
0.445
0.001
1
NIL
HORIZONTAL

SLIDER
5
265
185
298
inner-step-width
inner-step-width
0.001
0.5
0.147
0.001
1
NIL
HORIZONTAL

SLIDER
5
300
185
333
outer-step-width
outer-step-width
0.001
0.5
0.028
0.001
1
NIL
HORIZONTAL

BUTTON
645
10
710
43
NIL
paint
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
190
10
295
43
NIL
erase-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
300
10
480
43
paint-value
paint-value
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
485
10
640
43
paint-radius
paint-radius
1
10
3.0
0.5
1
NIL
HORIZONTAL

SLIDER
5
45
185
78
inner-radius
inner-radius
0
outer-radius
3.0
0.5
1
NIL
HORIZONTAL

PLOT
5
375
185
550
Transition Function
outer-state
inner-state
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"transition" 1.0 2 -7500403 true "" ""

BUTTON
5
340
185
373
visualize-transition
if (not netlogo-web?) [ every 0.5 [ visualize-transition ] ]
T
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

This model attempts to create Game of Life-like dynamics in a continuous domain. It is recommended that you be familiar with the Life model (in the models library) before looking at this one. As a reminder, in the Game of Life, each patch can either be alive or dead. Patches then update each tick as follows:

- If I am alive and I have 2 or 3 living neighbors, I stay alive.
- If I am dead and I have exactly 3 living neighbors, I become alive.
- Otherwise, I become dead.

These simple rules then lead to a remarkable diversity of emergent structures: shapes that fly across the world, shapes that produce streams of other shapes, and so forth.

The Game of Life is discrete in three ways:

- Patches are discrete cells in a grid.
- Patches have discrete states: alive or dead.
- Patches update at discrete steps in time, rather than fluctuating continuously over time.

Coming up with a continuous model that produces the rich emergent structures of the Game of Life is quite difficult. First, there are many more possible sets of rules for continuous models, and only a relatively small number are likely to produce interesting behavior. Second, continuous models are much more difficult to reason about, so it becomes harder to know which sets of rules are worth exploring.

In SmoothLife, the first two discrete ways become continuous. The system is spatially continuous in that every point in a continuous plane has as real-valued state between 0 and 1. There exists a circular "cell" of a particular radius at every point. The state of the cell is the mean of the values of the points within that cell. The neighborhood of each cell is a donut around that cell, and the state the neighborhood is the mean of the values of the points in the neighborhood. Thus, the cells and neighborhoods of the system also have continuous states. The system may also be made continuous in time, meaning that rather than updating its state in discrete steps, the system changes smoothly through time. However, this third way of making the discrete continuous is not done here. Of course, simulating a continuous plane is impossible. Instead, we approximate this plane with a discrete grid.

Points change value over time by updating based on the relationship between their cell's state and their neighborhood's state. This is roughly analogous with the Game of Life in that over or underpopulation can kill a cell, while being "just right" can give birth to a new cell.

From these rules, clear gliders (like in the Game of Life) and other structures form. Furthermore, the structures that form have a much more organic appearance than in the original Life model.

See this [YouTube playlist](https://www.youtube.com/playlist?list=PL69EDA11384365494) for many videos of SmoothLife and related models by the original creator.

## HOW IT WORKS

Each patch has a number between 0 and 1 associated with it. The state of the cell centered at each patch (with a radius OUTER-RADIUS / RADIUS-RATIO) is the mean of the values of patches inside that cell. The neighborhood of the cell is the donut of patches between OUTER-RADIUS / RADIUS-RATIO and OUTER-RADIUS of the center patch. The state of the cell's neighborhood is the mean of the values of the patches in the neighborhood.

A patch updates its value based on the state of the cell centered on it and the neighborhood of that cell. This update function is similar to the one in Life, except that it's fuzzy: when the state of the cell and neighborhood have the cell on the border between life and death, the patch takes on a value in the middle of 0 and 1. Intuitively:

- If the inner state of a patch is closer to 0, the patch will become alive (get closer to 1) if its neighborhood state is between MIN-BIRTH and MAX-BIRTH.
- If the inner state of a patch is closer to 1, the patch will stay alive (remain close to 1) if its neighborhood state is between MIN-STAY-ALIVE and MAX-STAY-ALIVE. Otherwise it will die (become closer to 0).
- If the inner state of a patch is closer to 0.5, the boundaries at which becomes closer to 0 or 1 are somewhere between MIN-BIRTH and MIN-STAY-ALIVE, and MAX-BIRTH and MAX-STAY-ALIVE.

In order achieve the transition between dead and alive in a continuous fashion, the [sigmoid function](https://en.wikipedia.org/wiki/Sigmoid_function) is used. The sigmoid function is shaped like an "S", where the bottom of the "S" starts at 0 and the top ends at 1. Thus, the sigmoid function is like a step function that jumps from 0 to 1, except that it takes on intermediate values between 0 and 1 near the place where it would otherwise jump. The sigmoid function is also used to transition between the amount that the MIN-BIRTH/MAX-BIRTH and MIN-STAY-ALIVE/MAX-STAY-ALIVE ranges are used. The actual transition function used can be visualized with VISUALIZE-TRANSITION. See HOW TO USE IT for details.

## HOW TO USE IT

Press SETUP to initialize the world randomly and GO to run the model.

OUTER-RADIUS controls the radius of each cell's neighborhood and RADIUS-RATIO determines how much that radius the cell itself takes up. Thus, the cells have radius OUTER-RADIUS / RADIUS-RATIO.

The precise meaning of the various parameters is somewhat complicated, but intuitively:

- MIN-BIRTH and MAX-BIRTH define the range of neighborhood states in which a dead cell (a cell with state less than 0.5) will become alive.
- MIN-SURVIVE and MAX-SURVIVE define the range of neighborhood states in which a living cell (a cell with state more than 0.5) will remain alive.
- INNER-STEP-WIDTH controls how "fuzzy" the transition function is with respect to the cell's state. The smaller the INNER-STEP-WIDTH, the closer to 0 or 1 the patches will be.
- OUTER-STEP-WIDTH controls how "fuzzy" the transition function is with respect to the neighborhood's state. The smaller the OUTER-STEP-WIDTH, the closer to 0 or 1 the patches will be.

VISUALIZE-TRANSITION and the TRANSITION FUNCTION plot show the actual transition function being used. The plot shows which new patch state different combinations of inner and outer states result in. Black corresponds to 0 and white to 1, as in the model's View. The white band in the center shows what will result in the patch getting a state close to 1. Note that because the band stretches from the top of the plot to the bottom, a patch can always become alive depending on the state of its neighborhood. The fat part of the band at the top is the range of values for which the patch will remain close to 1 (i.e. stay alive). The skinnier part of the band at the bottom is the range of values for which the patch will become 1 (i.e. be born). The plot will be updated for the current settings when SETUP is pressed. When VISUALIZE-TRANSITION is running, the plot updates in real-time, allowing you to change the model settings and immediately see how the transition function changes. This is very helpful for understanding the impact each setting has on the transition function.

PAINT allows you to change the state of cells using the mouse. When you press the mouse button while in the view, all patches within PAINT-RADIUS will have their STATEs set to PAINT-VALUE. ERASE-ALL sets all patches to 0 if you want to paint your own state from scratch.

## THINGS TO NOTICE

Objects that appear to glide across the screen will quickly appear when starting from an initial random configuration. Much like in the Game of Life, these gliders are in fact continuously recreating themselves at adjacent positions. Can you figure out how they work?

With small fluctuations, a glider object can either split into multiple gliders or die out.

Many of the emergent structures in this model consist of curved, organic-looking membranes of living cells. Why might this be?

When you decrease OUTER-RADIUS, the gliders and other structures become smaller. Why might this be? If you decrease OUTER-RADIUS too much, the structures won't form anymore. Why not?

## THINGS TO TRY

Using the paint functionality, can you create a glider? Can you create any other stable structures?

Can you find parameters for the model that produce other types of emergent structures?

## EXTENDING THE MODEL

While the TRANSITION FUNCTION plot visualizes the state transitions, it's very small and computationally intensive. Can you figure out another way to visualize the state transitions? Hint: try using patches.

The paper describing the SmoothLife model also includes a way of making the model continuous in time as well as in space and value. See the CREDITS AND REFERENCES section. Can you make this model continuous in time?

## NETLOGO FEATURES

This is a computationally intensive model. In order to keep things fast, the model stores the inner and outer neighborhoods of each patch at SETUP. Furthermore, the model only looks at patches with a significantly large STATE when computing the inner and outer neighborhood values. That is, many patches will have STATE close to, but not quite at 0 (less than 0.0001). For performance, we treat those patches as though they have STATE 0.

The plot in this model shows how to visualize a function that takes two inputs and outputs a single number. It does so by plotting a grid of tightly spaced points, where the color of the points corresponds to the output of the function. However, this is a very computationally intensive method and is not recommended for general use.

## RELATED MODELS

- Life

## CREDITS AND REFERENCES

Rafler, S. (2011). Generalization of Conway's "Game of Life" to a continuous domain-SmoothLife. arXiv preprint arXiv:1111.1567.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Head, B. and Wilensky, U. (2017).  NetLogo SmoothLife model.  http://ccl.northwestern.edu/netlogo/models/SmoothLife.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2017 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2017 Cite: Head, B. -->
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
NetLogo 6.2.2
@#$#@#$#@
setup repeat 25 [ go ]
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
