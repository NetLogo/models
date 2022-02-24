breed [ seeds seed ]    ; these are the circles in the middle of the polygons
breed [ movers mover ]  ; these are the turtles that move around, forming the edges

to setup
  clear-all

  ; create the seeds and randomly distribute them
  create-seeds num-seeds [
    set shape "circle"
    set size 2
    setxy random-xcor random-ycor
  ]

  ; create the turtles and randomly distribute them
  create-movers num-turtles [
    set size 0.75
    setxy random-xcor random-ycor
  ]

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;
;;; Go procedures ;;;
;;;;;;;;;;;;;;;;;;;;;

to go
  separate-seeds
  run (word "go-" go-mode)
  ; tick-advance is used in place of tick to allow the go-mode methods to be
  ; executed multiple times per whole tick. This results in the view updating
  ; less frequently giving the turtles the appearance of moving faster.
  tick-advance 0.2
end

; check to make sure that the seeds are not too close together, as this interferes
; with the emergent Voronoi pattern
to separate-seeds
  ask seeds [
    ask other seeds in-radius 2 [
      face myself
      rt 180
      fd 1
    ]
  ]
end

; report the seeds that are the closest to the turtle
; (rounding the distance to the nearest tenth)
to-report nearby-seeds ;; turtle reporter
  report seeds with-min [ precision (distance myself) 1 ]
end

; have the turtles move, but not change their heading based on the nearest seed
to go-random
  ask movers [
    ; the turtle first finds the seeds that are the closest to it
    ; (rounding the distance to the nearest tenth), next, it checks to see how many
    ; seeds are closest. If there is only one, the turtle then moves forward.
    ; If there is more than one, it stops as it has found a midpoint between seeds.
    if count nearby-seeds = 1 [ fd 0.04 ]
    rt 0.5 - random-float 1
   ]
end

; have the turtles move, changing their heading based on the nearest seed
to go-organized
  ask movers [
    ; the turtle first finds the seeds that are the closest to it
    ; (rounding the distance to the nearest tenth)
    let nearby nearby-seeds

    ; If the turtle only has only one closest seeds, it faces that seed and moves backward
    if count nearby = 1 [
      face one-of nearby
      bk 0.04
      ; Here we ask the turtle to slightly change its direction to introduce some
      ;   noise into the turtle's movement
      rt 0.5 - random-float 1
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Mouse procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to do-mouse-action
  run mouse-action
end

to add-new-seed
  if mouse-down? [
    ; block until the user releases the mouse button
    while [ mouse-down? ] [ ]
    ; and then create the new seed
    create-seeds 1 [
      set shape "circle"
      set size 2
      setxy mouse-xcor mouse-ycor
    ]
    display
  ]
end

to remove-seeds
  if mouse-down? [
    let candidate min-one-of seeds [ distancexy mouse-xcor mouse-ycor ]
    if [ distancexy mouse-xcor mouse-ycor ] of candidate < 1 [
      ask candidate [ die ]
      display
    ]
  ]
end

to move-seeds
   if mouse-down? [
    let candidate min-one-of seeds [ distancexy mouse-xcor mouse-ycor ]
    if [ distancexy mouse-xcor mouse-ycor ] of candidate < 1 [
      while [ mouse-down? ] [
        go
        ask candidate [ setxy mouse-xcor mouse-ycor ]
      ]
    ]
  ]
end

to add-turtles
  if mouse-down? [
    create-movers 1 [
      set size 0.75
      setxy mouse-xcor mouse-ycor
    ]
    go
  ]
end


; Copyright 2013 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
21
45
186
78
num-seeds
num-seeds
2
20
10.0
1
1
NIL
HORIZONTAL

BUTTON
21
135
91
168
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
20
90
185
123
num-turtles
num-turtles
250
2000
1000.0
50
1
NIL
HORIZONTAL

BUTTON
120
135
185
168
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

CHOOSER
20
175
185
220
go-mode
go-mode
"random" "organized"
1

CHOOSER
20
255
185
300
mouse-action
mouse-action
"add-new-seed" "remove-seeds" "move-seeds" "add-turtles"
0

BUTTON
20
305
185
338
Do Mouse Action
do-mouse-action
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

This model draws a Voronoi diagram by using turtles to define the boundaries between polygons that denote the region that is closest to a given point.  Voronoi diagrams resemble many phenomena in the world including cells, forest canopies, territories of animals, fur and shell patterns, crystal growth and grain growth, cracks in dried mud and other geological phenomena, road networks, and so on.  Voronoi diagrams are useful in computer graphics, vision and path planning for robots, marketing, and other applications.

## HOW IT WORKS

At setup, a small number of seeds (circles) and a large number of turtles are randomly placed in the view. When the go button is clicked, the turtles begin to move. While they move they keep track of the seeds around them, and when they have two or more seeds that are equidistant to them, and are the closest seeds to them, they stop moving. As a result of this behavior, the turtles stop moving along the borders between seed regions, resulting in a Voronoi diagram.

This is one of two voronoi diagram models in the models library, but the two are quite different. In the other model, the voronoi diagram is created by having each patch look to its nearest seed to decide what color to be, which produces the colored polygons. In this model on the other hand, the agents move around trying to locate positions where they do not have a single nearest seed. In other words, they are trying to locate a point that is not part of a polygon at all. In trying to find these locations, the turtles collectively end up defining the boundaries of the polygons in the diagram. The polygons emerge from the lines created by the turtles when they stop moving.

## HOW TO USE IT

Use the NUM-SEEDS slider to choose how many points you want and the NUM-TURTLES slider to determine how many turtles to add to the model, then press SETUP.  The model will place seeds and turtles randomly in the view. When you press the GO button, you will see the turtles start to move around the screen, stopping when they are equidistant from their closest seeds. As more turtles come to rest, a Voronoi diagram emerges.

The GO-MODES chooser lets you define how the turtles will move. The RANDOM mode will have the turtles move based on the random direction they were facing at setup time. The ORGANIZED mode will have each turtle face the seed that it is closest to, then move away from it. In both modes, the turtles follow the same rules for deciding when to stop moving as discussed above in the How It Works section.

Keeping the GO button pressed, you can interact with the model by selecting an option from the MOUSE-ACTIONS chooser, and clicking the DO MOUSE ACTION button. There are four mouse actions defined for the model. The ADD-NEW-SEEDs option allows you to add new seeds to the model. The REMOVE-SEEDS option lets you click on existing seeds to remove them. The MOVE-SEEDS option lets you click and drag seeds around the screen. Finally, the ADD-TURTLES option allows you to add more turtles to the model. As you interact with the model, you will see the polygons redraw based on the changing seed arrangement.

If you unclick the GO button, you can still make changes to the seeds. When you press the GO button again, you will see the turtles begin to move again, creating a new Voronoi diagram based around the changes you have made.

## THINGS TO NOTICE

The lines that are formed by the turtles between the seeds are exactly midway between them.

How many sides do the polygons formed by the turtles typically have?  (You may want to ignore the polygons around the edges.)

What is the difference between the RANDOM and ORGANIZED turtle behaviors? Do the different behaviors result in different diagrams?

Looking at the code tab, the go-random and go-organized procedures control the turtle behavior. Both of these methods are very short, the RANDOM go-mode only has 3 lines! Can you figure out what these 3 lines are doing? Are you surprised that so few lines can produce such a complicated diagram?

## THINGS TO TRY

Experiment with the effect of moving the points around, adding points, and removing points.

The turtles form polygons around the seeds - can you arrange the seeds to make the turtles form a triangle? How about a square? Or an octagon?

What happens if you arrange the seeds in a grid? Or a single straight line?

Does it always take the same amount of time for the turtles to find the boundary between points? Can you arrange the seeds in such a way that it takes the turtles a long time to find a place where they are equidistant from two points?

## EXTENDING THE MODEL

Currently, the seeds and turtles are randomly distributed. By systematically placing the seeds, you can create pattern with the turtles. Add buttons that arrange the seeds in patterns that create specific shapes in the model.

You could imagine systems where there could be different size seeds, and turtles would have a strong or weaker attraction to the seeds based on the seeds size. Implement a model that has variable size seeds and replaces the distance calculation with an attraction calculation based on the seeds size. How does this change the resulting Voronoi diagrams?

## NETLOGO FEATURES

The core procedures for the turtles are go-random and go-organized. The only difference between the two is that in go organized, we added two lines to make the turtles face the closest seed. These procedures use the `min-one-of` and `distance` reporters to find the nearest seed in a very succinct way.

The `mouse-down?`, `mouse-xcor`, and `mouse-ycor` primitives are used so the user can interact with the model.

The go method uses the `run` command to decide which behavior the turtles should follow by reading the go-mode chooser. Similarly, we use the `run` command to decide which mouse action to execute. This command allows one button (the DO MOUSE ACTION button) to produce different behaviors based on the value of the MOUSE-ACTION chooser.

`tick-advance` is used in place of tick to allow the go-mode methods to be executed multiple times per whole tick. This results in the view updating less frequently giving the turtles the appearance of moving faster.

We use the `in-radius` command to figure out if any of the seeds are too close together.

## RELATED MODELS

* Voronoi
* MaterialSim Grain Growth
* Fur
* Honeycomb
* Scatter
* Hotelling's Law

## CREDITS AND REFERENCES

For more information on Voronoi diagrams, see https://en.wikipedia.org/wiki/Voronoi.  (There are also many other sites on this topic on the web.)

This model was inspired by a Processing implementation of a Voronoi diagram, available here: https://www.openprocessing.org/sketch/7571

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Weintrop, D. and Wilensky, U. (2013).  NetLogo Voronoi - Emergent model.  http://ccl.northwestern.edu/netlogo/models/Voronoi-Emergent.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2013 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2013 Cite: Weintrop, D. -->
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
