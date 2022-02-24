globals [
  collision-precision ; Determines how accurate the location of collisions will be

  ; Determines how much we round the angles when bouncing off the obstacle.
  ; This is necessary, because small errors in angle should be ignored.
  angle-precision

  speed ; All balls have the same speed

  ; We don't want to change `heading` until all collisions have been
  ; factored in. This is because the ball's `heading` affects the
  ; adjustments made to the ball's position to find the exact spot
  ; a collision took place. See `correct-collision-position`.
  ; So, the ball's heading after collision is stored in NEW-HEADING
  ; until after all collisions have been taken into account.
  new-heading

  ; These are used to track which agent is being dragged and what part of that agent
  ; is being dragged.
  target-agent
  set-target-attribute
  get-target-attribute
  target-attribute-value
]

breed [ obstacles obstacle ]
breed [ balls ball ]

; General setup procedure
; It takes two anonymous procedures: the first configures obstacles, the second configures the ball.
; See SETUP-RANDOM, SETUP-PERIODIC-X, and SETUP-PERIODIC-QUILT for examples.
to setup [ obstacle-placement ball-placement ]
  clear-all

  set-default-shape obstacles "circle-with-border"

  ; Create obstacle so that it's completely inside the world
  create-obstacles num-obstacles [
    set color grey - 3
    ; First, set the size of the obstacle so that it fits in the world and doesn't take up all the space
    set size max list 1 random-float (0.75 * min list world-width world-height)
    run obstacle-placement ; run the anonymous procedure to place the obstacle
  ]

  set-default-shape balls "circled-default"
  create-balls 1 [
    set color red
    run ball-placement ; run the anonymous procedure to place the ball
    if two-balls? [
      hatch 1 [
        set heading random 360
        fd 0.05
        set heading [ heading ] of myself
        set color blue
      ]
    ]
  ]

  set collision-precision 64 ; Collisions will be within speed / (2 ^ 64) of the correct position
  set angle-precision 1000 ; Round to 1000th of a degree
  set speed 0.05

  reset-dragging

  reset-ticks
end

to setup-random
  setup [->
    ; Place obstacles randomly so that they're completely inside the world
    place-randomly-inside-walls
  ] [->
    ; Place the ball in the walls and then makes sure it's not overlapping with any obstacles.
    place-randomly-inside-walls
    while [ any? obstacles with [ overlap myself > 0 ] ] [  ; keep placing, checking for overlap, until there is none
      place-randomly-inside-walls
    ]
  ]
end

to setup-periodic-x
  set num-obstacles 1
  setup [-> setxy 0 0 set size 3 ] [-> setxy 6 8 facexy 0 2 ]
end

to setup-periodic-quilt
  set num-obstacles 1
  setup [-> setxy 0 8 set size 1 ] [-> setxy 0 7 facexy -8 -6 ]
end

to go
  repeat 5 [
    ask balls [
      set pen-mode ifelse-value trace-path? [ "down" ] [ "up" ]
      fd speed

      set new-heading heading

      if colliding-with-floor-or-ceiling? [
        correct-collision-position [-> colliding-with-floor-or-ceiling?]
        set new-heading 180 - new-heading
      ]

      if colliding-with-walls? [
        correct-collision-position [-> colliding-with-walls?]
        set new-heading 360 - new-heading
      ]

      foreach-agent obstacles [ an-obstacle ->
        if colliding-with? an-obstacle [
          bounce-off an-obstacle
        ]
      ]

      set heading new-heading
      pen-up
    ]
  ]
  tick
end

; A custom control structure that works like FOREACH, but operates
; on agentsets instead of lists.
to foreach-agent [ agentset command ]
  foreach [ self ] of agentset [ agent ->
    (run command agent)
  ]
end

; Turtle procedure
; Because the balls travel in steps of size `speed`, they won't detect
; a collision at the right location. This corrects that by moving the
; ball back and forth by ever smaller amounts to get as close as possible
; to the exact position of collision. This technique is called a
; "binary search".
to correct-collision-position [ colliding? ]
  refine-collision-position colliding? speed collision-precision
end

; This is helper procedure for `correct-collision-position`.
to refine-collision-position [ colliding? dist n ]
  ifelse runresult colliding? [
    bk dist
  ][
    fd dist
  ]
  if n > 0 [
    refine-collision-position colliding? (dist / 2) (n - 1)
  ]
end

; Ball procedures
; These do collision detection. They ensure that the ball is facing the
; object being collided with, otherwise you can get into weird situations
; when the ball is very close or colliding with two objects.

to-report colliding-with-floor-or-ceiling?
  report (dy > 0 and ycor > max-pycor) or (dy < 0 and ycor < min-pycor)
end

to-report colliding-with-walls?
  report (dx > 0 and xcor > max-pxcor) or (dx < 0 and xcor < min-pxcor)
end

to-report colliding-with? [ agent ]
  ; Gets the ball's heading as an angle between -180 and 180.
  ; We only consider the ball to be colliding with an obstacle if it's
  ; generally facing that obstacle.
  let h abs ((heading - towards agent + 180) mod 360 - 180)
  report h < 90 and overlap agent > 0
end

; Modifies the ball's NEW-HEADING in reaction to bouncing off the
; given obstacle.
to bounce-off [ an-obstacle ]
  correct-collision-position [-> colliding-with? an-obstacle ]

  ; We can't just use `dx` and `dy` here as we want to base these
  ; on `new-heading` rather than `heading`.
  let d-x sin new-heading
  let d-y cos new-heading

  ; These are the components of the vector pointing from the
  ; obstacle to the ball.
  let rx xcor - [ xcor ] of an-obstacle
  let ry ycor - [ ycor ] of an-obstacle

  ; This code reflects the vector of the ball's new heading around
  ; the vector pointing from the obstacle to the ball.
  let v-dot-r rx * dx + ry * dy
  let new-dx d-x - 2 * v-dot-r * rx / (rx * rx + ry * ry)
  let new-dy d-y - 2 * v-dot-r * ry / (rx * rx + ry * ry)

  set new-heading round-to (atan new-dx new-dy) angle-precision
end

; Ball or obstacle procedure
to-report overlap [ agent ]
  report (size + [size] of agent) / 2 - distance agent
end

; Ball or obstacle procedure
; Positions the agent randomly in the world such that
to place-randomly-inside-walls
  set xcor min-pxcor - 0.5 + size / 2 + random-float (world-width - size)
  set ycor min-pycor - 0.5 + size / 2 + random-float (world-height - size)
end

to-report round-to [ x p ]
  report round (x * p) / p
end

; Observer procedure
; This handles all the dragging code. The logic flow is as follows:
; If nothing is selected, and pick the closest agent. If the mouse is close to
; the center of the agent, prepare to set the agent's position. If the mouse is
; close to the edge of the agent, prepare to set a different attribute (size in
; the case of obstacles and direction in the case of balls).
; If something is already selected, set the selected attribute.
to drag
  ifelse mouse-down? [
    ifelse target-agent = nobody [
      ask min-one-of turtles [ min list (distancexy mouse-xcor mouse-ycor) (distancexy-to-edge mouse-xcor mouse-ycor) ] [
        let edge-dist distancexy-to-edge mouse-xcor mouse-ycor
        let center-dist distancexy mouse-xcor mouse-ycor
        if edge-dist < 1 or center-dist < size / 2 [
          set target-agent self
          ifelse center-dist < edge-dist or edge-dist > 1 [
            set set-target-attribute [[x y] ->
              ; There's a chance of x and y being outside of the world bounds.
              ; We just ignore the error if that's the case.
              carefully [ setxy x y ] []
            ]
            set get-target-attribute [[x y] -> (word "Position: " xcor ", " ycor)]
          ][
            ifelse breed = balls [
              set set-target-attribute [[x y] -> set heading towardsxy x y]
              set get-target-attribute [[x y] -> (word "Facing: " x ", " y)]
            ] [
              set set-target-attribute [[x y] -> set size round-to (2 * (distancexy mouse-xcor mouse-ycor)) 10]
              set get-target-attribute [[x y] -> (word "Size: " size) ]
            ]
          ]
        ]
      ]
    ][
      if mouse-inside? [
        ask target-agent [
          (run set-target-attribute (round-to mouse-xcor 10) (round-to mouse-ycor 10))
          set label (runresult get-target-attribute (round-to mouse-xcor 10) (round-to mouse-ycor 10))
          set target-attribute-value label
        ]
        display
      ]
    ]
  ][
    reset-dragging
  ]
end

to-report distancexy-to-edge [ x y ]
  report abs (size / 2 - distancexy x y)
end

to reset-dragging
  if is-turtle? target-agent [
    ask target-agent [
      set label ""
    ]
  ]
  set target-agent nobody
  set set-target-attribute [ -> ]
  set get-target-attribute [ -> 0 ]
  set target-attribute-value ""
end

; Additional periodic configurations

to setup-two-walls
  set num-obstacles 1
  setup [-> setxy 0 0 set size 3 ] [->  setxy 8 8 facexy 0 0]
end

to setup-corner-obstacle
  set num-obstacles 1
  setup [-> setxy -8.5 -8.5 set size 0.4] [-> setxy 8 8 facexy 0 0]
end

to setup-two-corners
  set num-obstacles 1
  setup [-> setxy 0 0 set size 8] [-> setxy 8 8 facexy 0 (0.5 + [ size / 2 ] of one-of obstacles)]
end

to setup-two-obstacles
  set num-obstacles 2
  setup [-> set size 1] [-> setxy 8 8 facexy 0 0]
  ask obstacle 0 [ setxy -.1 0 ]
  ask obstacle 1 [ setxy 0 -.1 ]
end

to setup-wall-obstacle
  set num-obstacles 3
  setup [-> set size 1 setxy -8 -8] [-> setxy 1 0 facexy -7 -8]
  ask obstacle 1 [ setxy 2 0 ]
  ask obstacle 2 [ setxy -8 8 ]
end

; Currently failing because it uses angles that don't round evenly.
to setup-triangle
  set num-obstacles 1
  setup [-> setxy 0 8 set size 1 ] [-> setxy 0 7 facexy -8 -8]
end

to setup-simple-triangle
  set num-obstacles 1
  setup [-> setxy 0 1 set size 1 ] [-> setxy 0 0 facexy -8 -8]
end


; Copyright 2017 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
135
10
568
444
-1
-1
25.0
1
10
1
1
1
0
0
0
1
-8
8
-8
8
1
1
1
ticks
30.0

BUTTON
5
85
130
118
NIL
setup-random
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
5
195
130
228
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

SWITCH
5
235
130
268
trace-path?
trace-path?
0
1
-1000

BUTTON
5
270
130
303
NIL
clear-drawing
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
5
120
130
153
NIL
setup-periodic-x
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
5
10
130
43
num-obstacles
num-obstacles
0
10
1.0
1
1
NIL
HORIZONTAL

BUTTON
5
310
130
343
NIL
drag
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
5
155
130
188
NIL
setup-periodic-quilt
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
5
45
130
78
two-balls?
two-balls?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model demonstrates a very simple chaotic system consisting of a ball bouncing inside a rectangular room with circular obstacles in it. The system can exhibit periodic behavior (in which the ball bounces in a repeating pattern), but primarily exhibits chaotic behavior.

Chaotic behavior means that any tiny change in the initial conditions (in this case, the position and heading of the ball) results in dramatically different behavior over time. Chaotic behavior makes systems very difficult to predict precisely: in order to accurately predict a chaotic system, one must have exact measurements of the system's initial conditions. However, measuring a system to that degree of accuracy is, in general, impossible.

## HOW IT WORKS

The ball bounces off the walls and obstacles. The collisions are all perfectly elastic and the obstacles remain stationary. Finally, there is no friction. This means that the balls never change speed, only direction. Note that the balls do not bounce off each other; multiple balls are just to show what happens when there are very small differences in initial position.

Collisions are detected when the ball overlaps an obstacle or the edge of the world. The position is then corrected (see the NetLogo Features section below for a more detailed discussion). Finally, because the collisions are perfectly elastic, the ball's new angle is the angle of reflection of its heading around the surface it's colliding with.

## HOW TO USE IT

Use the NUM-OBSTACLES slider to adjust the number of obstacles when using SETUP-RANDOM. With 0 obstacles, the system will *always* be periodic. Can you figure out why?

If TWO-BALLS? is on, the setup buttons will create an additional ball that will be in almost, but not quite, the same position as the first ball. Running the system with two balls will show how dramatic of an effect slight changes in initial conditions can have in chaotic systems.

Use the SETUP-RANDOM button to initialize the system in a configuration that will most likely be chaotic. NUM-OBSTACLES obstacles of random sizes will be placed at random positions.

Use the SETUP-PERIODIC-X button to see an example of the kind of periodic behavior the system can exhibit.

Use the SETUP-PERIODIC-QUILT button to see another example of periodic behavior that has a very long period.

The GO button runs the simulation.

If the TRACE-PATH? switch is on, the paths of the balls will be traced. CLEAR-DRAWING clears the paths.

DRAG can be used to move the balls and obstacles around, as well as change the size of the obstacles and direction of the balls. Once pressed, clicking and dragging near the center of balls and obstacles will move them around. Clicking and dragging near the edge of balls will change their direction. Clicking and dragging near the edge of obstacles will change their size.

## THINGS TO NOTICE

Notice how the bouncing of the balls is fairly predictable until they hit the circle. Why do you think that is?

If you run the model without an obstacle, the behavior is always periodic, though that period might be very long. Why might that be?

If TWO-BALLS? is on, the setup buttons will create an additional ball that will be in almost, but not quite, the same position as the first ball. Running the system with two balls and an obstacle will show how dramatic of an effect slight changes in initial conditions can have in chaotic systems. This is the signature feature of a chaotic system.

It's very unlikely that a random configuration in which the ball collides with an obstacle will be periodic.

## THINGS TO TRY

Try SETUP-PERIODIC-X with TWO-BALLS? on. How do the red and blue balls behave differently?

Try SETUP-PERIODIC-QUILT with TWO-BALLS? on. When do the red and blue balls begin to diverge?

Can you find other configurations that result in periodic behavior?

## EXTENDING THE MODEL

Add obstacles of different shapes. What shapes produce chaotic behavior?

Add a slider to control the number of balls, so that you can have more than two.

Add a slider to control how far the balls start from the red ball. Does making the distance smaller or bigger change the behavior of the model?

Try to change the shape of the box.

Currently, balls do not collide against each other. Can you make it so they do? Can you find a periodic configuration in which the balls collide against each other?

## NETLOGO FEATURES

This model uses a number of advanced techniques:

First, anonymous procedures are used to make the SETUP procedure very flexible with respect to the placement of the balls and obstacles. For example, SETUP-PERIODIC-QUILT uses the following code:

```
setup [-> setxy 0 8 set size 1 ] [-> setxy 0 7 facexy -8 -6 ]
```

The first anonymous procedure configures the obstacle and the second configures the ball.

The FOREACH-AGENT procedure shows how you can use anonymous procedures to create your own control structures in NetLogo. FOREACH-AGENT works like FOREACH, but operates on agentsets instead of lists.

Second, because of the chaotic nature of this system, the collisions between objects must be handled very precisely. Because the balls move by taking steps of size SPEED each tick, the location the ball is in when it hits another object won't be the same as if the ball had been moving continuously. This error can, for instance, make what should be periodic configurations chaotic. To correct for this, the model uses a technique called [binary search](https://en.wikipedia.org/wiki/Binary_search_algorithm) to get very close to the exact location of collision very quickly. While binary search is a general algorithm, not a NetLogo feature, this model shows how you can implement a spatial binary search in NetLogo. In addition, because the ATAN reporter can introduce small imprecisions, this model rounds the heading of the ball after collisions with obstacles to the nearest 100,000th of a degree.

Finally, the code for dragging the obstacles and balls around shows how fairly sophisticated manipulation of agents can be done with the mouse.

## RELATED MODELS

- The GasLab models
- Kicked Rotator is another example of a chaotic system

## CREDITS AND REFERENCES

This model was inspired by a conversation with Dirk Brockmann who discusses this phenomenon in his Complex Systems in Biology course at the Humboldt University of Berlin.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Head, B. and Wilensky, U. (2017).  NetLogo Chaos in a Box model.  http://ccl.northwestern.edu/netlogo/models/ChaosinaBox.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

circle-with-border
false
15
Circle -7500403 true false 0 0 300
Circle -1 true true 15 15 270

circled-default
true
0
Circle -7500403 true true 2 2 297
Polygon -1 true false 150 5 40 250 150 205 260 250

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
setup-periodic-quilt
repeat 1000 [ go ]
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
