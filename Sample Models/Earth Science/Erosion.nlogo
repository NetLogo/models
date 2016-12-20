globals [
  show-water?     ;; whether the water is visible
  drains          ;; agentset of all edge patches where the water drains off
  land            ;; agentset of all non-edge patches
]

patches-own [
  elevation       ;; elevation here (may be negative)
  water           ;; depth of water here
  drain?          ;; is this an edge patch?
]

to setup
  clear-all
  set show-water? true
  ask patches [
    ifelse bumpy?
       [ ifelse hill?
           [ set elevation -100 * (distancexy 0 0 / max-pxcor) + 100 + random 100 ]
           [ set elevation random 125 ] ]
       [ set elevation 100 ]
    set water 0
    set drain? false
  ]
  ;; the DIFFUSE command is useful for smoothing out the terrain
  if bumpy? [
    repeat terrain-smoothness [ diffuse elevation 0.5 ]
  ]
  ;; make the drain around the edge
  ask patches with [count neighbors != 8]
    [ set drain? true
      set elevation -10000000 ]
  set drains patches with [drain?]
  set land patches with [not drain?]
  ;; display the terrain
  ask land [ recolor ]
  reset-ticks
end

to recolor  ;; patch procedure
  ifelse water = 0 or not show-water?
    [ set pcolor scale-color white elevation -250 100 ]
    [ set pcolor scale-color blue (min list water 75) 100 -10 ]
end

to show-water
  set show-water? true
  ask land [ recolor ]
end

to hide-water
  set show-water? false
  ask land [ recolor ]
end

to go
  ;; first do rainfall
  ask land [
    if random-float 1.0 < rainfall [
      set water water + 1
    ]
  ]
  ;; then do flow;  we don't want to bias the flow in any
  ;; particular direction, so we need to shuffle the execution
  ;; order of the patches each time; using an agentset does
  ;; this automatically.
  ask land [ if water > 0 [ flow ] ]

  ;; reset the drains to their initial state
  ask drains [
    set water 0
    set elevation -10000000
  ]
  ;; update the patch colors
  ask land [ recolor ]
  ;; update the clock
  tick
end

to flow  ;; patch procedure
  ;; find the neighboring patch where the water is lowest
  let target min-one-of neighbors [elevation + water]
  ;; the amount of flow is half the level difference, unless
  ;; that much water isn't available
  let amount min list water (0.5 * (elevation + water - [elevation] of target - [water] of target))
  ;; don't flow unless the water is higher here
  if amount > 0 [
    ;; first erode
    let erosion amount * (1 - soil-hardness)
    set elevation elevation - erosion
    ;; but now the erosion has changed the amount of flow needed to equalize the level,
    ;; so we have to recalculate the flow amount
    set amount min list water (0.5 * (elevation + water - [elevation] of target - [water] of target))
    set water water - amount
    ask target [ set water water + amount ]
  ]
end


; Copyright 2004 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
263
10
675
423
-1
-1
4.0
1
10
1
1
1
0
0
0
1
-50
50
-50
50
1
1
1
ticks
30.0

BUTTON
12
185
113
234
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
12
118
245
151
terrain-smoothness
terrain-smoothness
1.0
30.0
6.0
1.0
1
NIL
HORIZONTAL

SLIDER
12
339
247
372
rainfall
rainfall
0.0
0.5
0.1
0.01
1
NIL
HORIZONTAL

BUTTON
119
185
215
234
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

TEXTBOX
9
30
139
58
Setup parameters:
11
0.0
0

TEXTBOX
8
315
233
333
Environmental parameters:
11
0.0
0

SWITCH
12
84
176
117
bumpy?
bumpy?
0
1
-1000

SLIDER
12
373
247
406
soil-hardness
soil-hardness
0.0
1.0
0.8
0.05
1
NIL
HORIZONTAL

SWITCH
12
50
176
83
hill?
hill?
1
1
-1000

BUTTON
21
270
125
303
NIL
show-water
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
127
270
225
303
NIL
hide-water
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
7
249
157
267
Display controls:
11
0.0
0

TEXTBOX
7
164
157
182
Simulation controls:
11
0.0
0

@#$#@#$#@
## WHAT IS IT?

This model is a simulation of soil erosion by water.  The user is presented with an empty terrain.  Rain falls on the terrain and starts to flow downhill.  As it flows, it erodes the terrain below.  The patterns of water flow change as the terrain is reshaped by erosion.  Eventually, a river system emerges.

## HOW IT WORKS

The soil is represented by gray patches.  The lighter the patch, the higher the elevation. Water is represented by blue patches.  Deeper water is represented by a darker blue.  Around the edge of the world is a "drain" into which water and sediment disappear.

Each patch has a certain chance per time step of receiving rain.  If it does receive rain, its water depth increases by one.

The model uses the following naive model of flowing water.  Water flows to the adjacent patch where the water level is lowest, as long as that patch is lower than the source.  The amount of flow is proportional to the difference in level, so that the water level on the two patches is (if possible) equalized.

Erosion is represented by decreasing the elevation of the source patch a bit when flow occurs.  The amount of erosion is proportional to the amount of flow.

## HOW TO USE IT

The SETUP button generates a terrain.  The smoothness of the terrain is controlled by the TERRAIN-SMOOTHNESS slider.  Lower values give rougher terrain, with more variation in elevation.  If you want a perfectly flat terrain, turn off the BUMPY? switch.  If you want to start out with a hill in the middle, turn on the HILL? switch.

The GO button runs the erosion simulation.

You can use the HIDE-WATER button to make the water vanish so you can see the terrain beneath.

The RAINFALL slider controls how much rain falls.  For example, if RAINFALL is 0.1, then each patch has a 10% chance of being rained on at each time step.

The SOIL-HARDNESS slider controls how "hard" or resistant to erosion the soil is.  Higher values will cause the soil to be harder, and less likely to erode, while lower values will cause the soil to erode more quickly.  A value of 1.0 means that the soil will not erode at all.

## THINGS TO NOTICE

Initially, the world is covered by lakes.  Then rivers start to form at the edge of the world.  Gradually, these rivers grow until they have drained all the lakes.

## THINGS TO TRY

Use the HIDE-WATER button to make the water invisible, and observe the terrain.

Experiment with the effect of the different sliders on the appearance of the resulting rivers.

See what happens when you start with a perfectly flat terrain.  (Is what happens realistic, or does it reveal limitations of the model?)

See what happens when you start with a hill.

## EXTENDING THE MODEL

Add evaporation.  Does this alter the behavior of the system in interesting ways?

Add "springs" -- point sources from which new water flows.

Add indicator turtles to show the direction and magnitude of flow on each patch.

Experiment with the rules for water flow.  Currently, all of the water simply flows to the lowest neighbor.  Would a more elaborate rule produce different results?

Add multiple soil types to the terrain, so that the land is of varying hardness, that is, varying speed of erosion.

What would it take to get river deltas to form?  You'd need to model sediment being carried by water and then deposited.

## NETLOGO FEATURES

Only patches are used, no turtles.

The code depends on agentsets always being randomly ordered.

## CREDITS AND REFERENCES

Here is an eroded volcano in Kamchatka with a strong resemblance to this model:
https://www.google.com/maps/@52.544312,157.338467,7882m/data=!3m1!1e3?dg=dbrw&newdg=1

Thanks to Greg Dunham and Seth Tisue for their work on this model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dunham, G., Tisue, S. and Wilensky, U. (2004).  NetLogo Erosion model.  http://ccl.northwestern.edu/netlogo/models/Erosion.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2004 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 2004 Cite: Dunham, G., Tisue, S. -->
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
NetLogo 6.0
@#$#@#$#@
setup
repeat 175 [ go ]
hide-water
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
0
@#$#@#$#@
