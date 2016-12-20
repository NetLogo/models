breed [ rockets rocket ]
breed [ frags frag ]

globals [
  countdown       ; how many ticks to wait before a new salvo of fireworks
]

turtles-own [
  col             ; sets color of an explosion particle
  x-vel           ; x-velocity
  y-vel           ; y-velocity
]

rockets-own [
  terminal-y-vel  ; velocity at which rocket will explode
]

frags-own [
  dim             ; used for fading particles
]

to setup
  clear-all
  set-default-shape turtles "circle"
  reset-ticks
end

; This procedure executes the model. If there are no turtles,
; it will either initiate a new salvo of fireworks by calling
; INIT-ROCKETS or continue to count down if it hasn't reached 0.
; It then calls PROJECTILE-MOTION, which launches and explodes
; any currently existing fireworks.
to go
  if not any? turtles [
    ifelse countdown = 0 [
      init-rockets
      ; use a higher countdown to get a longer pause when trails are drawn
      set countdown ifelse-value trails? [ 30 ] [ 10 ]
    ] [
      ; count down before launching a new salvo
      set countdown countdown - 1
    ]
  ]
  ask turtles [ projectile-motion ]
  tick
end

; This procedure creates a random number of rockets according to the
; slider FIREWORKS and sets all the initial values for each firework.
to init-rockets
  clear-drawing
  create-rockets (random fireworks) [
    setxy random-xcor min-pycor
    set x-vel ((random-float (2 * initial-x-vel)) - (initial-x-vel))
    set y-vel ((random-float initial-y-vel) + initial-y-vel * 2)
    set col one-of base-colors
    set color (col + 2)
    set size 2
    set terminal-y-vel (random-float 4.0) ; at what speed does the rocket explode?
  ]
end

; This function simulates the actual free-fall motion of the turtles.
; If a turtle is a rocket it checks if it has slowed down enough to explode.
to projectile-motion ; turtle procedure
  set y-vel (y-vel - (gravity / 5))
  set heading (atan x-vel y-vel)
  let move-amount (sqrt ((x-vel ^ 2) + (y-vel ^ 2)))
  if not can-move? move-amount [ die ]
  fd (sqrt ((x-vel ^ 2) + (y-vel ^ 2)))

  ifelse (breed = rockets) [
    if (y-vel < terminal-y-vel) [
      explode
      die
    ]
  ] [
    fade
  ]
end

; This is where the explosion is created.
; EXPLODE calls hatch a number of times indicated by the slider FRAGMENTS.
to explode ; turtle procedure
  hatch-frags fragments [
    set dim 0
    rt random 360
    set size 1
    set x-vel (x-vel * .5 + dx + (random-float 2.0) - 1)
    set y-vel (y-vel * .3 + dy + (random-float 2.0) - 1)
    ifelse trails?
      [ pen-down ]
      [ pen-up ]
  ]
end

; This function changes the color of a frag.
; Each frag fades its color by an amount proportional to FADE-AMOUNT.
to fade ; frag procedure
  set dim dim - (fade-amount / 10)
  set color scale-color col dim -5 .5
  if (color < (col - 3.5)) [ die ]
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
244
10
795
562
-1
-1
3.0
1
10
1
1
1
0
1
0
1
-90
90
-90
90
1
1
1
ticks
30.0

BUTTON
9
38
89
71
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
9
88
89
121
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

SWITCH
4
138
94
171
trails?
trails?
0
1
-1000

SLIDER
112
38
232
71
fireworks
fireworks
1
40
20.0
1
1
NIL
HORIZONTAL

SLIDER
112
88
232
121
fragments
fragments
5
50
30.0
1
1
NIL
HORIZONTAL

SLIDER
112
138
232
171
initial-x-vel
initial-x-vel
0.0
5.0
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
112
188
232
221
initial-y-vel
initial-y-vel
0.0
5.0
2.0
0.1
1
NIL
HORIZONTAL

SLIDER
112
238
232
271
gravity
gravity
0.0
3.0
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
112
288
232
321
fade-amount
fade-amount
0.0
10.0
1.5
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This program models the action of fireworks.  Rockets begin at the bottom of the view, shoot upwards into the sky and then explode, emitting showers of falling sparks.

## HOW IT WORKS

Each rocket, represented by a turtle, is launched upward with an initial x and y velocity.  At a certain point in the sky, an explosion occurs, which is represented by a series of turtle hatches.  Each hatched turtle inherits the velocity from the original rocket in addition to velocity from the explosion itself.  The result is a simulation of a fireworks display.

## HOW TO USE IT

SETUP sets up the model according to the values indicated by all the sliders and the switch. GO is a forever button that executes the model continually.

FIREWORKS creates a random number of fireworks between 0 and the number indicated on the slider.

FRAGMENTS determines how many particle fragments will emerge after the explosion of a single firework.

GRAVITY determines the gravitational strength in the environment.  A larger value will give a greater gravitational acceleration, meaning that particles will be forced to the ground at a faster rate.  The inverse is true for smaller values.

INIT-X-VEL sets the initial x-velocity of each rocket to a random number between the negative and positive value of the number indicated on the slider.

INIT-Y-VEL sets the initial y-velocity of each rocket to a random number between 0 and the number indicated on the slider plus ten.  This is to ensure that there is a range of difference in the initial y-velocities of the fireworks.

FADE-AMOUNT determines the rate at which the explosion particles fade after the explosion.

TRAILS allows the user to turn the trails left by the explosion particles on or off.  In other words, if the TRAILS switch is ON, then the turtles will leave trails.  If it is OFF, then they will not leave trails.

This model has been constructed so that all changes in the sliders and switches will take effect in the model during execution.  So, while the GO button is still down, you can change the values of the sliders and the switch, and you can see these changes immediately in the view.

## THINGS TO NOTICE

Experiment with the INIT-X-VEL and INIT-Y-VEL sliders.  Observe that at an initial x-velocity of zero, the rockets launch straight upwards.  When the initial x-velocity is increased, notice that some rockets make an arc to the left or right in the sky depending on whether the initial x-velocity is negative or positive.

With the initial y-velocity, observe that, on a fixed GRAVITY value, the heights of the fireworks are lower on smaller initial y-velocities and higher on larger ones.  Also observe that each rocket explodes at a height equal to or a little less than its apex.

## THINGS TO TRY

Observe what happens to the model when the GRAVITY slider is set to different values.  Watch what happens to the model when GRAVITY is set to zero.  Can you explain what happens to the fireworks in the model?  Can you explain why this phenomenon occurs?  What does this say about the importance of gravity?  Now set the GRAVITY slider to its highest value.  What is different about the behavior of the fireworks at this setting?  What can you conclude about the relationship between gravity and how objects move in space?

## EXTENDING THE MODEL

The fireworks represented in this model are only of one basic type.  A good way of extending this model would be to create other more complex kinds of fireworks.  Some could have multiple explosions, multiple colors, or a specific shape engineered into their design.

Notice that this model portrays fireworks in a two-dimensional viewpoint.  When we see real fireworks, however, they appear to take a three-dimensional form.  Try extending this model by converting its viewpoint from 2D to 3D.

## NETLOGO FEATURES

An important aspect of this model is the fact that each particle from an explosion inherits the properties of the original firework.  This informational inheritance allows the model to adequately represent the projectile motion of the firework particles since their initial x and y velocities are relative to their parent firework.

To visually represent the fading property of the firework particles, this model made use of the reporter `scale-color`.  As the turtle particles fall to the ground, they hold their pens down and gradually scale their color to black.  As mentioned above, the rate of fade can be controlled using the FADE-AMOUNT slider.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Fireworks model.  http://ccl.northwestern.edu/netlogo/models/Fireworks.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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
set trails? true
set fireworks 30
random-seed 3
setup
repeat 50 [ go ]
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
