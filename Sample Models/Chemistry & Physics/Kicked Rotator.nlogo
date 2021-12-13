globals [ particle ]
turtles-own [ momentum angular-position ]

to setup
  clear-all

  ; create a turtle that will represent a particle
  create-turtles 1 [
    set particle self
    set shape "circle"
    set size 0.25

    set momentum initial-momentum
    set angular-position initial-position

    ; update position by converting our angular-position to Cartesian coordinates
    setxy (rad-cos angular-position) (rad-sin angular-position)
  ]

  ; create a turtle to be the rotator's pivot point (the point the particle rotates around)
  create-turtles 1 [
    create-link-with particle ; draws string between particle and pivot-point
    hide-turtle ; but hide it, since we don't need to see it
  ]

  reset-ticks
end

to go
  ; each tick, the particle gets kicked
  ask particle [ get-kicked ]
  tick
end

; Procedure to kick the particle
to get-kicked ; turtle procedure

  ; Calculate the new momentum by adding the kick-strength multiplied by the sin of
  ; the position the reason we do this is because the effect of the kick on the
  ; particle depends on where the particle is when it gets kicked.
  set momentum momentum + kick-strength * rad-sin angular-position

  ; If animate is True, then we split the particle's motion into 10 frames per second.
  ; We also draw a kick indicator that's just an arrow.
  ifelse continuous-motion? [

    let kick-indicator nobody
    hatch 1 [ ; show the kick indicator
      set kick-indicator self
      set shape "arrow"
      set color white
      set heading 270
      fd -0.25
    ]

    ; To make the motion of the particle smoother, we split it into 10 different movements.
    repeat 10 [ ; animate each frame by moving the particle 1/10th of its travel distance each 1/10th seconds
      set angular-position (angular-position + (momentum / 10)) mod (2 * pi)
      setxy (rad-cos angular-position) (rad-sin angular-position) ; update the screen
      display
    ]
    ; remove the kick indicator
    ask kick-indicator [ die ]
  ]

  ; otherwise, we just move the particle to the next position
  [ set angular-position (angular-position + momentum) mod (2 * pi)
    setxy (rad-cos angular-position) (rad-sin angular-position)
  ]
end

; Reports the sine of an angle given in radians
to-report rad-sin [ r ]
  report sin (r * 360 / (2 * pi))
end

; Reports the cos of an angle given in radians
to-report rad-cos [ r ]
  report cos (r * 360 / (2 * pi))
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
575
376
-1
-1
119.0
1
10
1
1
1
0
0
0
1
-1
1
-1
1
1
1
1
ticks
30.0

SLIDER
10
160
200
193
kick-strength
kick-strength
0
5.0
0.785
0.001
1
NIL
HORIZONTAL

BUTTON
10
120
100
153
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
105
120
200
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

PLOT
10
240
200
400
Phase Portrait
angular position
momentum
0.0
6.29
-1.0
1.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "plotxy [angular-position] of particle [momentum] of particle"

SLIDER
10
45
200
78
initial-momentum
initial-momentum
-6.28
6.28
0.785
0.001
1
NIL
HORIZONTAL

SLIDER
10
80
200
113
initial-position
initial-position
0
2 * pi
1.57
0.01
1
NIL
HORIZONTAL

BUTTON
10
10
200
43
random initial conditions
set initial-momentum precision (random-float (2 * pi)) 3\nset initial-position precision (random-float (2 * pi)) 3\nset kick-strength precision (random-float 1) 3
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
10
195
200
228
continuous-motion?
continuous-motion?
0
1
-1000

MONITOR
20
460
191
505
current momentum
[momentum] of particle
3
1
11

MONITOR
20
410
192
455
current angular position
[angular-position] of particle
3
1
11

@#$#@#$#@
## WHAT IS IT?

A [kicked rotator](https://en.wikipedia.org/wiki/Kicked_rotator) is usually imagined as a particle constrained to move on a circle in a system with no friction or gravity that is periodically kicked. You can also think of it as a pendulum swinging with no gravity. The motion of this particle can be used to generate what is called the [Chirikov standard map](http://www.scholarpedia.org/article/Chirikov_standard_map), a tool in physics that can be used to describe many different dynamical systems from the motion of particles in accelerators to comet dynamics in solar systems.

The particle starts out at a random position on the circle with a random initial momentum and is periodically kicked by a "homogeneous field". Think of it as gravity being turned on for just an instant. Depending on where on the circle the particle is located, the kick affects the motion of the particle differently. For low kick strengths, the particle motion is fairly regular. However at higher kick strengths, this seemingly simple system quickly becomes chaotic, making it a perfect candidate for studying [dynamical chaos](https://en.wikipedia.org/wiki/Dynamical_systems_theory#Chaos_theory).

## HOW IT WORKS

The particle is modeled by a single turtle that is connected to an invisible pivot-point using a link agent. This particle has two variables associated with it: angular position (where it is on the circle in radians) and momentum. The particle's momentum can be positive or negative, where positive momentum indicates counter-clockwise motion and negative momentum indicates clockwise motion.

At each tick, the particle receives a kick. A kick is indicated by an arrow that is drawn where the kick occurred in the particle's motion and in the direction the force was applied.

In order to calculate the momentum of the particle after a kick, we first calculate how 'effective' the kick is by multiplying it by the sine of the angular-position of the particle. We then add this effect to the previous momentum.

## HOW TO USE IT

Use the INITIAL-POSITION, INITIAL-MOMENTUM and KICK-STRENGTH sliders to define the initial conditions of the model. Or, you can use the RAND INITIAL CONDITIONS button to start with random initial conditions.

After setting the parameters, click SETUP. Clicking GO will then start the model.

The CONTINUOUS-MOTION? switch controls whether or not NetLogo will display the motion of the particle in between kicks. This significantly slows the model because it forces NetLogo to individually draw 10 frames of motion per 1 kick to the particle.

## THINGS TO NOTICE

Notice the 'Phase Portrait' plot on the left side of the model. This plot displays angular position (in radians) on the x-axis and momentum on the y-axis. This is how physicists depict trajectories of a system over time.

Notice that changing the initial angular position and momentum of the particle but keeping the same kick-strength results in drastically different particle motion.

## THINGS TO TRY

See if you can make a rotator that travels the entire ring.

Now see if you can make a rotator that doesn't complete an entire orbit.

Try and create a rotator that has a circular phase portrait. What kind of motion does that rotator have?

Try and create a rotator that has a phase portrait that is a periodic wave. What kind of motion does that rotator have?

Try and create a rotator that has chaotic behavior.

## EXTENDING THE MODEL

Right now, the kick comes in from the right side of the model, forcing the particle to the left. Can you switch the direction of the kick so that it forces the particle to the right?

See if you can create a plot that tracks the particle's centripetal force over time.

## NETLOGO FEATURES

The kicked rotator is a continuous phenomenon in that between kicks the particle is still in motion. However, in this mode the particle is kicked at every tick meaning we just calculate the new position and move the particle there. In essence, the particle is 'transporting' from one location to another. In order to emulate continuous motion, when the CONTINUOUS-MOTION? option is on, we ask NetLogo to break down a tick into 10 separate frames. The kick occurs only in the 1st frame but the motion of the particle is split evenly amongst all 10 frames. This way, we simulate continuous motion while still using 'discrete' time.

Instead of manually drawing the string constricting the particle to the ring, we instead create a hidden 'pivot-point' turtle and then create a link between the particle and pivot-point. That way, NetLogo draws this connection for us!

NetLogo's built in primitives for sine and cosine only accept degrees. The `rad-sin` and `rad-cos` reporters first convert a parameter from radians (the unit of choice for physics) to degrees and then uses `sin` and `cos`.

Trigonometry in NetLogo is a little different from the mathematical standard. Imagine the four quadrants in the Cartesian plane. In NetLogo, quadrants 1 and 3 are the same, but quadrants 2 and 4 are switched. This is because, in NetLogo, the quadrants are considered clockwise oriented. In addition, a heading of 0 in NetLogo points the turtle due north, but in standard trig, that corresponds to  pi / 2 radians, whereas a heading of 0 in trig points due east. For this model, we don't use NetLogo trig, and instead use regular trig by explicitly calculating Cartesian coordinates instead of the usual turtle-based movements.

## RELATED MODELS

Take a look at the Kicked Rotators model to see what happens when you have many kicked rotators running in concert.

## CREDITS AND REFERENCES

This model was inspired by a model used in Dirk Brockmann's Complex Systems in Biology course at the Humboldt University of Berlin.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Brockmann, D., Bain, C., Hjorth, A. & Wilensky, U. (2016).  NetLogo Kicked Rotator model.  http://ccl.northwestern.edu/netlogo/models/KickedRotator.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 Cite: Brockmann, D., Bain, C., Hjorth, A. & Wilensky, U. -->
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
