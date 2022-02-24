breed [ cars car ]
breed [ arrowheads arrowhead ]

cars-own [
  velocity
  previous-velocity ; tracks our previous velocity

  my-x ; track our theoretical position when we go off screen

  my-velocity-arrow ; an arrow to track our velocity
  my-accel-arrow ; an arrow to track our acceleration
]

globals [
  delta-t ; a variable used to deal discrete time chunks
  any-movement? ; keeps track of if there was any movement in the model
]

to setup
  clear-all
  set delta-t 0.1

  ; Set the origin of the starting line and makes it yellow.
  ask patches with [pxcor = 0] [set pcolor yellow]

  create-cars 1 [                              ; Creates the cars, shape, color, size and initial conditions.
    ifelse initial-velocity < 0 [ set shape "car-backward" ][ set shape "car"]
    set color red
    set size 15
    set velocity initial-velocity
    ; Set our previous velocity so that we don't have any "infinite acceleration"
    set previous-velocity velocity - (delta-t * acceleration * draw-interval)

    ; The arrowheads below are just for visualization
    hatch-arrowheads 1 [
      set heading 90
      set color cyan
      set size 10
      set hidden? true
      ask myself [ set my-velocity-arrow myself ]
      create-link-with myself [
        set thickness 2
        set color cyan
        set hidden? true
      ]
    ]
    hatch-arrowheads 1 [
      setxy 0 15
      set heading 90
      set color orange
      set size 10
      set hidden? true
      ask myself [ set my-accel-arrow myself ]
      create-link-with myself [
        set thickness 2
        set color orange
        set hidden? true
      ]
    ]
  ]

  ; Reset the clock back to 0
  reset-ticks
end

to go
  ask cars [
    move

    ; Update our motion map every "draw-interval" ticks
    if ticks mod draw-interval = 0 [
      set previous-velocity velocity
      if on-screen?[
        draw-velocity-arrow
        draw-accel-arrow
      ]

    ]
  ]

  tick
end

; This controls the motion of the car
to move ; turtle procedure

  ; calculate our new position to save
  set my-x my-x + ((velocity * delta-t) + (.5 * acceleration * delta-t * delta-t))

  ; Update our velocity according to any acceleration we're under going
  set velocity velocity + acceleration * delta-t

  ; Make sure we're not beyond the boundary of the model
  ifelse on-screen? [
    show-turtle
    ; Move forward based on our current velocity and any acceleration we're under going
    forward (velocity * delta-t) + (.5 * acceleration * delta-t * delta-t)

    ; Face the car forwards or backwards depending on its velocity
    ifelse velocity < 0 [ set shape "car-backward" ] [ set shape "car" ]

    ; Update our motion map drawing helpers
    update-velocity-arrow
    update-acceleration-arrow
  ] [ hide-turtle ]
end


;;;; HELPER PROCEDURES ;;;;

; Handles the logic to draw our arrows
to update-velocity-arrow ; turtle procedure
                         ; Draw Velocity Arrow
  ask my-velocity-arrow [

    ; Set the direction
    ifelse [velocity] of myself < 0 [
      set ycor 15
      set heading 270
    ][
      set ycor -30
      set heading 90
    ]

    ; Ask the model to stop if we are at the edge of the world
    ifelse ([xcor] of myself + [velocity] of myself * 10 * delta-t) < min-pxcor or
    ([xcor] of myself + [velocity] of myself * 10 * delta-t) > max-pxcor [
      ; do nothing
    ][

      ; Update the velocity arrow's magnitude
      set xcor [xcor] of myself + [velocity] of myself * 10 * delta-t
    ]
  ]
end

to update-acceleration-arrow ; turtle procedure
  ask my-accel-arrow [
    ; If we have a positive velocity, draw on the upper part of the map
    ; otherwise, draw on the lower part of the map.
    ifelse [velocity] of myself < 0 [ set ycor -30 ][ set ycor 15 ]
    ifelse acceleration < 0 [ set heading 270 ] [ set heading 90 ]

    ; Calculate the length of the vector (with a little scaling)
    let delta-v ([velocity] of myself - [previous-velocity] of myself ) * 20 * delta-t

    ; If we're going off the edge of the world
    ifelse ([xcor] of myself + delta-v) < min-pxcor or ([xcor] of myself + delta-v) > max-pxcor [
      ; do nothing
    ][
      set xcor [xcor] of myself + delta-v
    ]
  ]
end

to draw-velocity-arrow
  ; If we have a positive velocity, draw on the upper part of the map
  ; otherwise, draw on the lower part of the map.
  ifelse velocity <= 0 [ set ycor -15 set heading 270 ][ set ycor 30 set heading 90]

  ask my-velocity-arrow [

    ; Move the arrow
    set ycor [ycor] of myself

    ; If the velocity is non-zero, draw an arrow
    if [velocity] of myself != 0 [

      ; Draw the arrow head
      set shape "default"
      set color cyan
      set hidden? false
      stamp
      set hidden? true

      ; Draw the magnitude part of the arrow
      ask my-links [
        set hidden? false
        stamp
        set hidden? true
      ]

    ]
  ]

  ; Stamp the car's position
  set shape "dot"
  set size 10
  stamp
  set size 15
  ifelse velocity < 0 [ set shape "car-backward" ][ set shape "car"]

  set ycor 0 ; reset the car's ycor
end

to draw-accel-arrow
  ; If we have a positive velocity, draw on the upper part of the map
  ; otherwise, draw on the lower part of the map.
  ifelse velocity < 0 [ set ycor -30 ] [ set ycor 15 ]
  set heading 90

  ; If the acceleration is 0, just draw a dot
  ifelse acceleration != 0  [
    ask my-accel-arrow [

      ; Draw the arrowhead
      set shape "default"
      set hidden? false
      stamp
      set hidden? true

      ; Draw the magnitude
      ask my-links [
        set hidden? false
        stamp
        set hidden? true
      ]
    ]
  ][
    ; Draw just a dot
    ask my-accel-arrow [
      set hidden? false
      set shape "dot"
      set color orange
      set size 10
      stamp
      set hidden? true
    ]
  ]
  set ycor 0 ; reset the car's ycor
end

to-report on-screen?
  ifelse my-x > max-pxcor or my-x < min-pxcor [ report false ] [ report true ]
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
229
10
1039
221
-1
-1
2.0
1
10
1
1
1
0
0
1
1
-200
200
-50
50
1
1
1
ticks
30.0

BUTTON
10
180
95
213
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
99
180
184
213
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
10
35
180
68
initial-velocity
initial-velocity
-20
20
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
12
13
232
39
Set the initial velocity for the car.
11
0.0
1

SLIDER
10
80
180
113
acceleration
acceleration
-8
8
0.0
0.5
1
NIL
HORIZONTAL

TEXTBOX
575
225
755
244
Orange = Acceleration
15
25.0
1

TEXTBOX
430
225
580
244
Cyan = Velocity
15
83.0
1

TEXTBOX
276
225
426
244
Red = Position
15
15.0
0

SLIDER
10
125
182
158
draw-interval
draw-interval
1
50
15.0
1
1
NIL
HORIZONTAL

TEXTBOX
185
40
335
58
vcarx
14
0.0
1

TEXTBOX
185
90
335
108
acarx
14
0.0
1

PLOT
10
250
345
400
Position vs. Time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks mod draw-interval = 0 [\nplotxy ticks [my-x] of one-of cars\n]"

PLOT
350
250
705
400
Velocity vs. Time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks mod draw-interval = 0 [\nplotxy ticks [velocity] of one-of cars\n]"

PLOT
710
250
1040
400
Acceleration vs. Time
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks mod draw-interval = 0 [\nplotxy ticks acceleration\n]"

@#$#@#$#@
## WHAT IS IT?

This model draws a motion map for a car moving horizontally. Motion maps are  one-dimensional plots built off of a position line. Along this horizontal axis, we can mark the car's position at any point in time while also including arrows to record its velocity and acceleration. The direction of the arrow corresponds to the direction of the velocity or acceleration while the magnitude of the arrow represents the magnitude of the velocity. Motion maps can be used to simultaneously visualize the position, velocity, and acceleration of a moving object.

## HOW IT WORKS

Given intial conditions set by the user (initial velocity, acceleration, draw interval), the car will move accordingly:

current position = previous position + (velocity * time) + (1/2 * acceleration * time<sup>2</sup>)

As the car moves, the model tracks and plots its position, velocity, and acceleration. Positions are stamped as red dots. Velocity is represented by blue arrows (vectors) that indicate both magnitude and direction. The greater the velocity, the longer the arrow. Following a standard line plot, motion to the left is negative while motion to the right is positive.

Acceleration is denoted by either orange dots or orange arrows. Orange dots are reserved for when acceleration is zero. Similar to velocity, non-zero acceleration is represented by arrows with both magnitude and direction.

The draw interval simply determines how often the model should record data in the motion map (the duration between each "stamp").

## HOW TO USE IT

1. Use the sliders to select the initial conditions: INITIAL-VELOCITY is the starting velocity, ACCELERATION is the acceleration that will remain constant, DRAW-INTERVAL is the time between recording instances.
2. Press SETUP to activate the initial conditions.
3. Press GO to start the model.
4. In addition to recording data in the motion map, this model also includes traditional, two-dimensional plots for position vs time, velocity vs time, and acceleration vs time.

Note, when the car reaches the map's boundaries it will disappear. The model will continue to run and keep track of the car's motion, but you will not see the car on the View.

## THINGS TO NOTICE

Compare the graphs of two cars moving with different initial values. How does a positive acceleration interact with a starting negative velocity? Vice versa? What patterns do you notice between the motion map and the three plots?

## THINGS TO TRY

Try setting the increments of velocity and acceleration to different values and see how the individual motions and graphs differ.

Try finding the values for velocity and acceleration that make the car reach both the right and left map boundaries before stopping.

## CURRICULAR USE

This model was incorporated into the CT-STEM 1-D Kinematics Motion Maps Unit, a lesson plan designed for a high school physics class. In the unit, students experiment with a progression of models that explore constant velocity (lesson 1) and constant acceleration (lesson 2):

1. The base model:
Students observe how different initial velocities produce different motion maps.

2. The base model with CODAP:
Students use the base model again but can also observe traditional position-time and velocity-time graphs. These graphs are recorded with CODAP, an extension for data analysis.

3. A NetTango model:
Students build their own motion maps model with programming blocks.

4. The base model with acceleration:
Students can now change both the initial velocity and acceleration.

5. Model 4 with CODAP:
With both velocity and acceleration included in the motion map, students can also see traditional position-time and velocity-time graphs.

## EXTENDING THE MODEL

Explore changing the colors for position, velocity, and acceleration.

Maybe add an additional car to see two running at the same time with different starting conditions.

## NETLOGO FEATURES

Can update many cars at once with their own individual values. This model uses links to connect data from the moving red car with the velocity arrow, acceleration arrow, and position plots. NetLogo's `stamp` method helps draw copies of the linked agents when called at specific time intervals.

## RELATED MODELS

* Free Fall Model

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* DuBrow, D., Bain, C., Schmidgall, N. and Wilensky, U. (2020).  NetLogo 1D Motion Maps model.  http://ccl.northwestern.edu/netlogo/models/1DMotionMaps.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

This model was developed as part of the CT-STEM Project at Northwestern University and was made possible through generous support from the National Science Foundation (grants CNS-1138461, CNS-1441041, DRL-1020101, DRL-1640201 and DRL-1842374) and the Spencer Foundation (Award #201600069). Any opinions, findings, or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the funding organizations. For more information visit https://ct-stem.northwestern.edu/.

Special thanks to the CT-STEM models team for preparing these models for inclusion
in the Models Library including: Kelvin Lao, Jamie Lee, Sugat Dabholkar, Sally Wu,
and Connor Bain.

## COPYRIGHT AND LICENSE

Copyright 2020 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2020 CTSTEM Cite: DuBrow, D., Bain, C., Schmidgall, N. -->
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

car-backward
false
0
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

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

wolf
false
0
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

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
