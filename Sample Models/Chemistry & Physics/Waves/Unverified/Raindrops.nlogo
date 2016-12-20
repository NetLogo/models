turtles-own [xpos ypos zpos delta-z neighbor-turtles]
globals [drop-width k]

to setup
  clear-all
  set-default-shape turtles "circle"
  create-turtles (max-pxcor * max-pycor) [
    set ypos (floor (who / max-pxcor))    ;Line up the turtles according to their ID
    set xpos (who - (max-pxcor * ypos))
    set xpos (xpos - (.5 * max-pxcor))    ;Center the resulting box
    set ypos (ypos - (.5 * max-pycor))
    set xcor xpos
    set ycor ypos
    set color blue
    set zpos 0
    set delta-z 0
  ]
  ask turtles [
    set neighbor-turtles turtles-on neighbors4
  ]
  set drop-width 2
  reset-ticks
end

to go    ;Listen for mouse clicks that indicating drops, while propagating waves
  if (mouse-down?)
    [ask turtles [release-drop mouse-xcor mouse-ycor]]
  ask turtles [compute-delta-z]
  ask turtles [update-position-and-color]
  tick
end

to release-drop    [drop-xpos drop-ypos]    ;Turtle procedure for releasing a drop onto the pond
  if (((xpos - drop-xpos) ^ 2) + ((ypos - drop-ypos) ^ 2) <= ((.5 * drop-width) ^ 2))
      [set delta-z (delta-z + (k * ((sum [zpos] of neighbor-turtles) -
                    ((count neighbor-turtles) * zpos) - impact)))]
end

to compute-delta-z    ;Turtle procedure
  set k (1 - (.01 * surface-tension))        ;k determines the degree to which neighbor-turtles'
  set delta-z (delta-z + (k * ((sum [zpos] of neighbor-turtles) - ((count neighbor-turtles) * zpos))))
end

to update-position-and-color  ;Turtle procedure
  set zpos ((zpos + delta-z) * (.01 * friction))    ;Steal energy by pulling the turtle closer
  set color scale-color blue zpos -40 40            ;to ground level
  ifelse three-d?
   [
     let y (zpos + (ypos * sin angle))
     let x (xpos + (ypos * cos angle))
     ifelse patch-at (x - xcor) (y - ycor) != nobody
      [ setxy x y show-turtle ]
      [ hide-turtle ]]
   [
     ifelse patch-at (xpos - xcor) (ypos - ycor) != nobody
      [ setxy xpos ypos
      show-turtle ]
      [ hide-turtle ]]
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
321
18
634
332
-1
-1
5.0
1
10
1
1
1
0
0
0
1
-30
30
-30
30
1
1
1
ticks
15.0

SWITCH
6
198
123
231
three-d?
three-d?
1
1
-1000

BUTTON
16
37
75
70
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
6
238
147
271
angle
angle
0
90
45.0
1
1
degrees
HORIZONTAL

SLIDER
173
75
294
108
impact
impact
0
60
30.0
1
1
NIL
HORIZONTAL

SLIDER
164
238
312
271
friction
friction
90
100
98.0
1
1
NIL
HORIZONTAL

TEXTBOX
6
175
117
193
3D perspective
11
0.0
0

TEXTBOX
174
41
280
69
Click on pond to\nrelease a drop
11
0.0
0

SLIDER
164
204
312
237
surface-tension
surface-tension
50
99
65.0
1
1
NIL
HORIZONTAL

TEXTBOX
175
181
287
199
Pond properties
11
0.0
0

BUTTON
79
37
139
70
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

@#$#@#$#@
## WHAT IS IT?

This model simulates raindrops falling on the surface of a pond and the waves they produce.

## HOW IT WORKS

The greater the surface tension, the slower waves travel through the water.  This is implemented in the model as a weight coefficient on the difference in height between a turtle and its neighbors.  The resulting weighted value is added to the turtles current vertical velocity (represented by the incremental value dz) and its current position to determine its next position.  To translate the earlier statement, then, the greater the surface tension, the more a particle's neighbors can pull it towards them, thus quickening the pace of a wave through the surface.

## HOW TO USE IT

SETUP initializes the model.  GO continuously propagates waves in the water while listening for drops caused by the user.  To release a drop, hold your mouse button down briefly on any point within the pond (the blue region).  That point is where the drop will land.

The FRICTION slider controls the amount of force that pulls the water particles back towards ground level, dampening waves.  SURFACE-TENSION controls how much effect the neighbors of a water particle exert on it vertically.

The IMPACT slider determines how much force a drop carries.  Drops with greater impact cause larger waves.

The THREE-D switch allows you to view the pond either from above or from an angle set by ANGLE.

## THINGS TO NOTICE

The pond is made up of a grid of turtles, each of whom, like in Wave Machine, behaves like it is connected to its neighbors by springs.  Each turtle has a vertical position and velocity, which determine how high above the sides of the pond it is or how far below, and how much that distance will change at the next time step.

When drops are released they decrease the vertical velocity of the particles under them, causing them to move downwards.  As they fall, they pull down their neighbors, who at the same time pull them up. This exchange creates a wave within the pond, centered on where the drop fell.

As the waves hit the walls, they are reflected back towards the middle, as the walls don't move up or down.  Friction causes the waves to eventually decline by pulling them closer to the surface level.

## THINGS TO TRY

Try creating multiple drops in the pool to see how they interact.  Do they cancel each other out or reinforce each other?

Change the surface tension to see how it affects the speed of waves.  Why does water with low surface tension move so slowly?  What sort of liquids in real life is it similar to?

Set friction to 100 and release some drops.  Do the waves ever dissipate?  How can the waves rise above the sides of the pond (have positive zpos's) when only downward moving forces are exerted on them?  How is a turtle's movement similar to that of a spring.  Is the friction used in this model analogous to that in a spring?

## EXTENDING THE MODEL

This model doesn't take into account water pressure.  When part of the water is pushed down on the impact of a drop, the rest of the water should feel a push from beneath.  Try adding in this mechanism.

The walls in this model don't affect waves at all.  Extend the model so that the walls impose friction on waves that brush against them, causing them to dampen.

## NETLOGO FEATURES

In order to create the visual impression of a wave, it is necessary for water above the sides of the pond (above water level) to appear more white, while water below to appear more blue.  This was accomplished using the `scale-color` primitive, which takes a color to assign, a variable, and a minimum and maximum value.  It works by comparing the value of the variable for each turtle to the two values, and the closer it is to the maximum, the lighter the shade of the color assigned to that turtle.

Water particles that fly off the top or bottom of the world are ignored in the model, which is done by using the commands hide-turtle (ht) and show-turtles (st).  Hide turtle doesn't cause the turtle to die or change in any way, but merely stops it from being drawn.  Show turtle causes it to begin being displayed again.

The model listens for raindrops using NetLogo's mouse primitives.  `go` repeatedly calls `mouse-down?` to register when the user has clicked over the pond.  When this condition reports true, it uses two reporters, `mouse-xcor` and `mouse-ycor`, to record the current coordinates of the mouse so that a drop can be released in the appropriate place.

## RELATED MODELS

For another model that demonstrates how turtles behave as a surface, see Wave Machine.  In it, turtles are connected in the same manner as outlined above, but their movement is governed by the regular sinusoidal motion of part of the surface.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Raindrops model.  http://ccl.northwestern.edu/netlogo/models/Raindrops.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1998 2001 -->
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
set three-d? true
setup
go
ask turtles [ release-drop 3 3 ]
repeat 20 [ go ]
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
