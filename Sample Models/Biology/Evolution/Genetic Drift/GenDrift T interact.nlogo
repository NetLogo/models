globals [
  max-percent  ;; percent of the total population that is in the
               ;; most populous group
]

to setup
  ;; We don't use clear-all here because that would erase
  ;; any walls the user drew.
  clear-turtles
  clear-all-plots
  ;; create turtles with random colors and locations
  create-turtles number [
    set color item (random colors) [5 15 25 35 45 55 65 85 95 125]
    setxy random-xcor random-ycor
    move-off-wall
  ]
  reset-ticks
end

to go
  if (variance [color] of turtles) = 0
    [ stop ]
  ask turtles [
    rt random 50 - random 50
    meet
    ;; move, but don't step on wall
    ifelse [pcolor] of patch-ahead 0.5 = black
      [ fd 0.5 ]
      [ rt random 360 ]
  ]
  find-top-species
  tick
end

to meet    ;; turtle procedure - when two turtles are next door,
           ;; the left one changes to the color of the right one
  let candidate one-of turtles-at 1 0
  if candidate != nobody [
    set color [color] of candidate
  ]
end

to find-top-species  ;;find the percentage of the most populous species
  let winning-amount 0
  foreach base-colors [ [c] ->
    let how-many count turtles with [color = c]
    if how-many > winning-amount
      [ set winning-amount how-many ]
  ]
  set max-percent (100 * winning-amount / count turtles)
end

;; ---------------------------------------------------------------------------------
;; Below this point are procedure definitions that have to do with "walls," which
;; the user may create in order to separate groups of turtles from one another.
;; The use of walls is optional, and can be seen as a more advanced topic.
;; ---------------------------------------------------------------------------------

to place-wall
  if mouse-down? [
    ;; Note that when we place a wall, we must also place walls
    ;; at the world boundaries, so turtles can't change rooms
    ;; by wrapping around the edge of the world.
    ask patches with [abs pycor = max-pycor or
                      pycor = round mouse-ycor] [
      set pcolor white
      ;; There might be some turtles standing where the
      ;; new walls is, so we need to move them into a room.
      ask turtles-here [ move-off-wall ]
    ]
    display
  ]
end

to remove-wall
  if mouse-down? [
    ask patches with [pycor = round mouse-ycor]
      [ set pcolor black ]
    display
  ]
end

to remove-all-walls
  clear-patches
end

to move-off-wall  ;; turtle procedure
  while [pcolor != black] [
    move-to one-of neighbors
  ]
end


; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
305
10
733
439
-1
-1
12.0
1
10
1
1
1
0
1
1
1
-17
17
-17
17
1
1
1
ticks
30.0

BUTTON
98
80
171
113
go
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
18
80
95
113
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

SLIDER
158
36
287
69
colors
colors
2
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
15
36
156
69
number
number
1
1000
300.0
1
1
NIL
HORIZONTAL

PLOT
5
130
298
353
Turtle Populations
Time
Number
0.0
100.0
0.0
70.0
true
false
"set-plot-y-range 0 count turtles" ""
PENS
"color5" 1.0 0 -7500403 true "" "plot count turtles with [color = 5]"
"color15" 1.0 0 -2674135 true "" "plot count turtles with [color = 15]"
"color25" 1.0 0 -955883 true "" "plot count turtles with [color = 25]"
"color35" 1.0 0 -6459832 true "" "plot count turtles with [color = 35]"
"color45" 1.0 0 -1184463 true "" "plot count turtles with [color = 45]"
"color55" 1.0 0 -10899396 true "" "plot count turtles with [color = 55]"
"color65" 1.0 0 -13840069 true "" "plot count turtles with [color = 65]"
"color125" 1.0 0 -5825686 true "" "plot count turtles with [color = 75]"
"color85" 1.0 0 -11221820 true "" "plot count turtles with [color = 85]"
"color95" 1.0 0 -13791810 true "" "plot count turtles with [color = 95]"

MONITOR
35
151
152
196
% most populous
max-percent
2
1
11

BUTTON
5
421
95
454
NIL
place-wall
T
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
421
195
454
NIL
remove-wall
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
200
421
300
454
NIL
remove-all-walls
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
24
391
281
419
As the model runs, you may optionally create and\nremove walls that separate groups of turtles.
10
0.0
0

@#$#@#$#@
## WHAT IS IT?

This model is an example of random selection. It shows that turtles that randomly exchange colors converge on a single color.  The idea, explained in more detail in Dennett's "Darwin's Dangerous Idea", is that trait drifts can occur without any particular purpose or "selective pressure".

## HOW IT WORKS

The model starts with a random distribution of colored agents.  Turtles move by wiggling randomly across the world. When two turtles are next to each other, one turtle changes its color to the color of the other one.  Note that if a color dies out, it can never come back.

## HOW TO USE IT

The NUMBER slider sets the number of turtles. The COLORS slider selects the number of competing colors, up to ten.

The SETUP button initializes the model, and GO runs the model.

A monitor shows the percentage of turtles sharing the most common color.  When this reaches 100%, the model stops.

After pressing PLACE-WALLS, the user can "draw" walls in the world at the location where the user clicks with the mouse.  By pressing REMOVE-WALLS, the user can remove added walls.  The REMOVE-ALL-WALLS button removes all walls including the border.  (The SETUP button does not remove walls.)

## THINGS TO NOTICE

Gradually a color will gain a slight dominance. By statistical advantage, a dominant color becomes more likely to have more colors like it.  However, because the process is random, there will usually be a series of dominant colors before one color finally wins.

## THINGS TO TRY

Experiment with adding walls.

When walls are added, groups of individuals can be geographically isolated so that they can not interact with their neighbors on the other side of the wall. Groups that are geographically isolated with walls will often end up with a different dominant color than the larger population.  A group of individuals that is walled off becomes a "founding group".  The founding group of individuals has a different genetic variability and distribution than the main population, so the frequency of certain traits may end up drifting in a different direction compared with the much larger population.

## EXTENDING THE MODEL

In this model, a turtle looks one patch to its right.  If there's another turtle there, the "looking" turtle changes to that turtle's color.  Since the turtles move randomly about the world, it's a matter of chance which turtle will change to the color of its neighbor.

Think of other rules for turtle interactions, random or otherwise, by which a turtle color might "take over".

## RELATED MODELS

* GenDrift (P Global)
* GenDrift (P local)
* GenDrift (T reproduce)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo GenDrift T interact model.  http://ccl.northwestern.edu/netlogo/models/GenDriftTinteract.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1997 2001 -->
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
