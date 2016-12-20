breed [ leaders leader ]
breed [ followers follower ]

globals [
  nest-x nest-y    ;; location of center of nest
  food-x food-y    ;; location of center of food
]

to setup
  clear-all
  set-default-shape turtles "bug"
  set nest-x 10 + min-pxcor                      ;; set up nest and food locations
  set nest-y 0
  set food-x max-pxcor - 10
  set food-y 0
  ;; draw the nest in brown by stamping a circular
  ;; brown turtle
  ask patch nest-x nest-y [
    sprout 1 [
      set color brown
      set shape "circle"
      set size 10
      stamp
      die
    ]
  ]
  ;; draw the food in orange by stamping a circular
  ;; orange turtle
  ask patch food-x food-y [
    sprout 1 [
      set color orange
      set shape "circle"
      set size 10
      stamp
      die
    ]
  ]
  create-leaders 1
    [ set color red ]                              ;; leader ant is red and start with a random heading
  create-followers (num-ants - 1)
    [ set color yellow                             ;; middle ants are yellow
      set heading 90 ]                             ;; and start with a fixed heading
  ask turtles
    [ setxy nest-x nest-y                          ;; start the ants out at the nest
      set size 2 ]
  ask turtle (max [who] of turtles)
    [ set color blue                               ;; last ant is blue
      set pen-size 2
      pen-down ]                                   ;; ...and leaves a trail
  ask leaders
    [ set pen-size 2
      pen-down ]                                   ;; the leader also leaves a trail
  reset-ticks
end

to go
  if all? turtles [xcor >= food-x]
    [ stop ]
   ask leaders                                      ;; the leader ant wiggles and moves
     [ wiggle leader-wiggle-angle
       correct-path
       if (xcor > (food-x - 5 ))                    ;; leader heads straight for food, if it is close
         [ facexy food-x food-y ]
       if xcor < food-x                             ;; do nothing if you're at or past the food
         [ fd 0.5 ] ]
   ask followers
     [ face turtle (who - 1)                        ;; follower ants follow the ant ahead of them
       if time-to-start? and (xcor < food-x)        ;; followers wait a bit before leaving nest
         [ fd 0.5 ] ]
  tick
end

;; turtle procedure; wiggle a random amount, averaging zero turn
to wiggle [angle]
  rt random-float angle
  lt random-float angle
end

;; turtle procedure
to correct-path
  ifelse heading > 180
    [ rt 180 ]
    [ if patch-at 0 -5 = nobody
        [ rt 100 ]
     if patch-at 0 5 = nobody
        [ lt 100 ] ]
end

;; turtle reporter; if true, then the ant is authorized to move out of the nest
to-report time-to-start?
  report ([xcor] of (turtle (who - 1))) > (nest-x + start-delay + random start-delay )
end


; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
248
10
660
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

SLIDER
4
37
238
70
num-ants
num-ants
1.0
1000.0
45.0
1.0
1
NIL
HORIZONTAL

BUTTON
126
75
190
108
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
55
75
122
108
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

MONITOR
65
232
177
277
leader-heading
[ heading ] of one-of leaders
0
1
11

SLIDER
2
147
236
180
start-delay
start-delay
1.0
60.0
3.0
1.0
1
NIL
HORIZONTAL

SLIDER
2
113
236
146
leader-wiggle-angle
leader-wiggle-angle
0.0
90.0
38.0
1.0
1
degrees
HORIZONTAL

MONITOR
66
185
177
230
ants-released
count turtles with [xcor > nest-x]
3
1
11

@#$#@#$#@
## WHAT IS IT?

This project models the behavior of ants following a leader towards a food source. The leader ant moves towards the food along a random path; after a small delay, the second ant in the line follows the leader by heading directly towards where the leader is located. Each subsequent ant follows the ant ahead of it in the same manner.

Even though the leader may take a very circuitous path towards the food, the ant trail, surprisingly, adopts a smooth shape. While it is not yet clear if this model is a biologically accurate model of ant behavior, it is an interesting mathematical exploration of the emergent behavior of a series of agents following each other serially.

## HOW TO USE IT

The SETUP button initializes the model. A brown ant nest is placed on the left side of the world. Inside it are a number of ants (yellow) determined by the NUM-ANTS slider. On the right hand of the world is an orange source of food.

The GO button starts the ants moving. The leader ant (turtle 0) is set in motion roughly in the direction of the food. It wiggles as it moves. That is, it does not head directly towards the food, but changes its heading a random amount to the left or right before it takes each step.

The maximum amount the leader ant can wiggle at each step (and therefore the raggedness of the leader ant's path) is governed by the LEADER-WIGGLE-ANGLE slider. When the leader ant gets close enough to the food to "smell" it, it stops wiggling and heads directly for the food. The leader ant leaves a red trace as it moves.

Each subsequent ant follows the ant ahead of it by heading directly towards it before it takes each step. The follower ants do not leave a trace. The yellow line of ants, however, traces out a curve in the drawing. The last ant to go leaves a blue trace.

The amount of time between ants departing their nest is governed by the START-DELAY slider (plus some random factor).

The ANTS-RELEASED monitor shows you how many ants have left the nest. The other monitor shows you the heading of the lead ant.

## THINGS TO NOTICE

How does the shape of the ant line change over time?

How does the path of the initial ant compare with the path of the final ant?

## THINGS TO TRY

Try varying the maximum wiggle angle (LEADER-WIGGLE-ANGLE). How does that affect the shape of initial and final ant lines?

Try varying the delay. How does that affect the shape of initial and final ant lines?

How can you slow down the flattening out of the ant line? Can you make the path fail to converge to a straight line?

How can you speed up the flattening out of the ant line?

## EXTENDING THE MODEL

How might you keep track of, measure, or plot the flattening process?

What if you relaxed the ant following rules --- maybe add some "wiggle" to their behavior?

## NETLOGO FEATURES

Notice the use of delays based on turtle ids in the TIME-TO-START? reporter to make the turtles leave the nest one at a time.

## CREDITS AND REFERENCES

The model was inspired by the work of Alfred Bruckstein (see Bruckstein 1993: "Why the ant trails look so straight and nice", The Mathematical Intelligencer, Vol. 15, No. 2).

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Ant Lines model.  http://ccl.northwestern.edu/netlogo/models/AntLines.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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
setup
repeat 250 [ go ]
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
