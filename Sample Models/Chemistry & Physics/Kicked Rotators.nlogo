extensions [ ls ]
turtles-own [ angular-position momentum ]

to setup
  clear-all
  ls:reset ; clears all LevelSpace child models
  ask patches [ set pcolor white ]

  ; make a bunch of turtles, each representing a different rotator in an initial random state
  create-turtles num-rotators [
    set shape "circle" set size 1 set color (random 13) * 10 + 7
    set angular-position random-float (2 * pi) ; range of possible values is [0, 2pi)
    set momentum (random-float (4 * pi)) - (2 * pi) ; range of possible values is [-2pi, 2pi)
    ; this range is not strictly needed for kicked rotators, but it works well with the "standard map"
  ]
  reset-ticks
end

to go
  ask turtles [ get-kicked ] ; at each tick, kick each rotator
  tick
end

to get-kicked ; turtle procedure

  ; Calculate the new momentum by adding the kick-strength multiplied by the sine of the position
  ; the reason we do this is because the effect of the kick on the particle depends on
  ; where the particle is when it gets kicked
  set momentum momentum + kick-strength * rad-sin angular-position
  set angular-position (angular-position + momentum) mod (2 * pi)

  ; graph the current momentum and angular-position by normalizing each measure to the view
  setxy (min-pxcor + angular-position * world-width / (2 * pi)) (min-pycor + momentum  * world-height / (2 * pi))

  ; ask the turtle to mark its current trajectory on the graph
  stamp
end

; procedure to "add" a new rotator to the display with random initial conditions
to add-rotator
  create-turtles 1 [
    set shape "circle" set size 1.5 set color (random 13) * 10 + 7
    set angular-position random-float (2 * pi)
    set momentum (random-float (4 * pi)) - (2 * pi) ; range of possible values is [-2pi, 2pi)
    ; catch the new rotator up to the current ticks counter
    repeat ticks [ get-kicked ]
  ]
  set num-rotators num-rotators + 1
end

; procedure to display a separate Kicked Rotator model for any given initial conditions
to inspect-rotator
  if mouse-inside? and mouse-down? [

    ; ls:let variables can be seen by the Kicked Rotator model that we create
    ls:let parent-ticks ticks
    ls:let parent-kick-strength kick-strength

    ; convert the mouse coordinates into an initial momentum and angular-position
    ls:let parent-momentum ((mouse-ycor) / (world-height - 1) * (2 * pi))
    ls:let parent-position (mouse-xcor - min-pxcor) / (world-width - 1) * (2 * pi)

    ; create a new Kicked Rotator model with the appropriate initial conditions
    ls:create-interactive-models 1 "Kicked Rotator.nlogo"
    ls:ask last ls:models [
      ; ask the model to start with the given conditions
      set continuous-motion? false
      set kick-strength precision parent-kick-strength 3
      set initial-position precision parent-position 3
      set initial-momentum precision parent-momentum 3

      setup
      repeat parent-ticks [ go ]    ; then asks it catch up to the current ticks
      set continuous-motion? true
    ]

  ]
end

; reports the sine of an angle given in radians
to-report rad-sin [ r ]
  report sin (r * 360 / (2 * pi))
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
188
10
710
533
-1
-1
2.0
1
1
1
1
1
0
1
1
1
-128
128
-128
128
1
1
1
ticks
30.0

BUTTON
8
87
111
120
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
7
48
179
81
kick-strength
kick-strength
0
5
0.785
0.001
1
NIL
HORIZONTAL

BUTTON
113
87
180
120
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

SLIDER
6
11
179
44
num-rotators
num-rotators
1
500
200.0
1
1
NIL
HORIZONTAL

BUTTON
8
126
179
159
NIL
add-rotator
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
9
163
179
196
NIL
inspect-rotator
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

This model simulates a collection of [kicked rotators](https://en.wikipedia.org/wiki/Kicked_rotator) operating simultaneously and graphs their trajectories. This graph shows a divided phase space where integrable islands of stability are surrounded by a chaotic component (aka "chaotic sea"). This is what's called the [Chirikov standard](http://www.scholarpedia.org/article/Chirikov_standard_map) map, a tool in physics that can be used to describe many different dynamical systems from the motion of particles in accelerators to comet dynamics in solar systems.

For more info on what a kicked rotator is, check out the Kicked Rotator model in the models library.

## HOW IT WORKS

The model generates a number of turtles, each representing a kicked rotator with a unique starting angular position and momentum. Then, at each tick, the model 'kicks' each rotator, changing both its momentum and angular position. The turtle then 'stamps' a copy of itself onto the view with the location representing its current momentum and angular position. Each turtle repeats this process at each tick, creating an overall [phase portrait](http://mathworld.wolfram.com/PhasePortrait.html) via a [Poincare return map](https://en.wikipedia.org/wiki/Poincare_map). This continues for as long as the model is run.

For more info on how each individual rotator (turtle) works,  checkout the Kicked Rotator model.

## HOW TO USE IT

Use the NUM-ROTATORS and KICK-STRENGTH sliders to determine the number of rotators to simulate and the kick strength. Then, SETUP will generate the necessary turtles and GO will start simulating and graphing the particle trajectory for each of the rotators.

Clicking the ADD-ROTATOR button will add another rotator to the simulation. NetLogo will automatically run this rotator for the same number of ticks that your model has run.

Clicking the INSPECT-ROTATOR button and then clicking any point in the view will create a kicked rotator model with the initial momentum and angular position corresponding to the point in the view you clicked. This rotator will then 'run' until the it reaches the same number of ticks that the parent model has run for.

## THINGS TO NOTICE

Notice the circles in the middle of the phase portrait. Since angular position is graphed on the x-axis, this means that rotators with these starting conditions do not travel along the whole ring, but rather only part of the ring.

At a kick strength of 0, you just get a series of parallel lines because each rotator simply travels around the entire ring at their initial momentum. Because there is no friction, they just keep going!

Notice the smaller circles that aren't located in the center of the phase portrait. What do these smaller circles represent in terms of kicked rotator motion?

Notice that some regions of the view are chaotic, with random looking dots. These regions are called "chaotic seas".

## THINGS TO TRY

Is there a relationship between kick strength and how chaotic the phase portrait looks?

Inspect a rotator that has a circular phase portrait. Now inspect one that has a more periodic phase portrait. How do behaviors of the individual rotators differ?

Try and restrict the initial conditions (momentum and angular position) of each rotator to a different domain (e.g., [0, pi]). How does that affect the phase portrait?

Inspect two rotators next to each other in the chaotic sea (if clicking two neighbors is hard, you can manually adjust the angular positions and momenta so the two rotators are very close. Now run each of the two rotators simultaneously. What do you notice about the trajectories of these rotators that start with nearly identical locations and velocities?

## EXTENDING THE MODEL

See if you can change the model to use a different random kick strength for each pendulum.

Using LevelSpace, try to add a procedure that allows you to create a child Kicked Rotator, tweak the initial conditions, and then add that rotator into the parent model.

## NETLOGO FEATURES

This model uses the LevelSpace extension to create an individual kicked rotator model (using the INSPECT-ROTATOR button) given an initial momentum and angular position. This is different than a typical LevelSpace model since the model that gets created has no effect on the 'parent model'.

## RELATED MODELS

Check out the Kicked Rotator model for more info on what a kicked rotator is.

## CREDITS AND REFERENCES

This model was inspired by a model used in Dirk Brockmann's Complex Systems in Biology course at the Humboldt University of Berlin.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Brockmann, D., Bain, C. & Wilensky, U. (2016).  NetLogo Kicked Rotators model.  http://ccl.northwestern.edu/netlogo/models/KickedRotators.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 Cite: Brockmann, D., Bain, C. & Wilensky, U. -->
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
0
@#$#@#$#@
