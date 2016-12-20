globals [
  ticks-at-last-change  ; value of the tick counter the last time a light changed
]

breed [ lights light ]

breed [ accidents accident ]
accidents-own [
  clear-in              ; how many ticks before an accident is cleared
]

breed [ cars car ]
cars-own [
  speed                 ; how many patches per tick the car moves
]

;;;;;;;;;;;;;;;;;;;;
;;SETUP PROCEDURES;;
;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set-default-shape lights "square"
  set-default-shape accidents "fire"
  set-default-shape cars "car"
  ask patches [
    ifelse abs pxcor <= 1 or abs pycor <= 1
      [ set pcolor black ]     ; the roads are black
      [ set pcolor green - 1 ] ; and the grass is green
  ]
  ask patch 0 -1 [ sprout-lights 1 [ set color green ] ]
  ask patch -1 0 [ sprout-lights 1 [ set color red ] ]
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;
;;RUNTIME PROCEDURES;;
;;;;;;;;;;;;;;;;;;;;;;

to go
  ask cars [ move ]
  check-for-collisions
  make-new-car freq-north 0 min-pycor 0
  make-new-car freq-east min-pxcor 0 90
  ; if we are in "auto" mode and a light has been
  ; green for long enough, we turn it yellow
  if auto? and elapsed? green-length [
    change-to-yellow
  ]
  ; if a light has been yellow for long enough,
  ; we turn it red and turn the other one green
  if any? lights with [ color = yellow ] and elapsed? yellow-length [
    change-to-red
  ]
  tick
end

to make-new-car [ freq x y h ]
  if (random-float 100 < freq) and not any? turtles-on patch x y [
    create-cars 1 [
      setxy x y
      set heading h
      set color one-of base-colors
      adjust-speed
    ]
  ]
end

to move ; turtle procedure
  adjust-speed
  repeat speed [ ; move ahead the correct amount
    fd 1
    if not can-move? 1 [ die ] ; die when I reach the end of the world
    if any? accidents-here [
      ; if I hit an accident, I cause another one
      ask accidents-here [ set clear-in 5 ]
      die
    ]
  ]
end

to adjust-speed

  ; calculate the minimum and maximum possible speed I could go
  let min-speed max (list (speed - max-brake) 0)
  let max-speed min (list (speed + max-accel) speed-limit)

  let target-speed max-speed ; aim to go as fast as possible

  let blocked-patch next-blocked-patch
  if blocked-patch != nobody [
    ; if there is an obstacle ahead, reduce my speed
    ; until I'm sure I won't hit it on the next tick
    let space-ahead (distance blocked-patch - 1)
    while [
      breaking-distance-at target-speed > space-ahead and
      target-speed > min-speed
    ] [
      set target-speed (target-speed - 1)
    ]
  ]

  set speed target-speed

end

to-report breaking-distance-at [ speed-at-this-tick ] ; car reporter
  ; If I was to break as hard as I can on the next tick,
  ; how much distance would I have travelled assuming I'm
  ; currently going at `speed-this-tick`?
  let min-speed-at-next-tick max (list (speed-at-this-tick - max-brake) 0)
  report speed-at-this-tick + min-speed-at-next-tick
end

to-report next-blocked-patch ; turtle procedure
  ; check all patches ahead until I find a blocked
  ; patch or I reach the end of the world
  let patch-to-check patch-here
  while [ patch-to-check != nobody and not is-blocked? patch-to-check ] [
    set patch-to-check patch-ahead ((distance patch-to-check) + 1)
  ]
  ; report the blocked patch or nobody if I didn't find any
  report patch-to-check
end

to-report is-blocked? [ target-patch ] ; turtle reporter
  report
    any? other cars-on target-patch or
    any? accidents-on target-patch or
    any? (lights-on target-patch) with [ color = red ] or
    (any? (lights-on target-patch) with [ color = yellow ] and
      ; only stop for a yellow light if I'm not already on it:
      target-patch != patch-here)
end

to check-for-collisions
  ask accidents [
    set clear-in clear-in - 1
    if clear-in = 0 [ die ]
  ]
  ask patches with [ count cars-here > 1 ] [
    sprout-accidents 1 [
      set size 1.5
      set color yellow
      set clear-in 5
    ]
    ask cars-here [ die ]
  ]
end

to change-to-yellow
  ask lights with [ color = green ] [
    set color yellow
    set ticks-at-last-change ticks
  ]
end

to change-to-red
  ask lights with [ color = yellow ] [
    set color red
    ask other lights [ set color green ]
    set ticks-at-last-change ticks
  ]
end

; reports `true` if `time-length` ticks
; has elapsed since the last light change
to-report elapsed? [ time-length ]
  report (ticks - ticks-at-last-change) > time-length
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
175
10
568
404
-1
-1
11.0
1
10
1
1
1
0
0
0
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
8
10
98
43
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
10
170
43
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

BUTTON
105
85
170
119
switch
change-to-yellow
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
319
168
352
green-length
green-length
1
50
12.0
1
1
NIL
HORIZONTAL

SLIDER
7
125
168
158
speed-limit
speed-limit
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
7
168
168
201
max-accel
max-accel
1
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
7
201
168
234
max-brake
max-brake
1
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
7
243
168
276
freq-north
freq-north
0
100
60.0
5
1
%
HORIZONTAL

SLIDER
7
276
168
309
freq-east
freq-east
0
100
100.0
5
1
%
HORIZONTAL

SWITCH
8
85
98
118
auto?
auto?
0
1
-1000

SLIDER
7
352
168
385
yellow-length
yellow-length
0
10
3.0
1
1
NIL
HORIZONTAL

MONITOR
574
70
707
115
waiting overall
count cars with [ speed = 0 ]
0
1
11

MONITOR
574
119
707
164
waiting-eastbound
count cars with [ heading = 90 and speed = 0 ]
0
1
11

MONITOR
574
168
707
213
waiting-northbound
count cars with [ heading = 0 and speed = 0 ]
0
1
11

PLOT
574
218
812
395
Waiting
time
waiting cars
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"overall" 1.0 0 -16777216 true "" "plot count cars with [ speed = 0 ]"
"eastbound" 1.0 0 -13345367 true "" "plot count cars with [ heading = 90 and speed = 0 ]"
"northbound" 1.0 0 -2674135 true "" "plot count cars with [ heading = 0 and speed = 0 ]"

BUTTON
105
45
170
78
go once
go
NIL
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

In this model the turtles are cars traveling through an intersection.  The user has the ability to control the frequency of cars coming from each direction, the speed of the cars, and the timing of the light at the traffic intersection.  Once the frequency and speed of cars is selected, the user should run the simulation and adjust the timing of the traffic light so as to minimize the amount of waiting time of cars traveling through the intersection.

## HOW IT WORKS

The rules for each car are:

- I can only go in the direction I started in, or stop.

- I stop for cars in front of me and red lights, and I stop for a yellow light if I'm not already on it.

- If I am moving quickly and I see that I will have to stop soon, I try to slow down enough to make sure I can stop in time, up to MAX-BRAKE.

- If I see that I have free space in front of me, I speed up towards the SPEED-LIMIT, up to MAX-ACCEL.

- If I am on the same space as another car, we crash and die.

## HOW TO USE IT

WAIT-TIME-OVERALL shows how many cars are waiting during the given clock tick.

WAIT-TIME-EASTBOUND shows how many eastbound cars are waiting during the given clock tick.

WAIT-TIME-NORTHBOUND shows how many northbound cars are waiting during the given clock tick.

CLOCK shows how many ticks have elapsed.

Use the FREQ-EAST slider to select how often new eastbound cars travel on the road.

Use the FREQ-NORTH slider to select how often new northbound cars travel on the road.

Use the SPEED-LIMIT slider to select how fast the cars will travel.

Use the MAX-ACCEL slider to determine how fast the cars can accelerate.

Use the MAX-BRAKE slider to determine how fast the cars can decelerate.

Use the GREEN-LENGTH slider to set how long the light will remain green.

Use the YELLOW-LENGTH slider to set how long the light will remain yellow.

Press GO ONCE to make the cars move once.

Press GO to make the cars move continuously.

To stop the cars, press the GO button again.

## THINGS TO NOTICE

Cars start out evenly spaced but over time, they form bunches. What kinds of patterns appear in the traffic flow?

Under what conditions do the cars appear to be moving backwards?

Gridlock happens when cars are unable to move because cars from the other direction are in their path.  What settings cause gridlock in this model?  What settings can be changed to end the gridlock?

## THINGS TO TRY

Try to answer the following questions before running the simulations.

Record your predictions.

Compare your predicted results with the actual results.

- What reasoning led you to correct predictions?

- What assumptions that you made need to be revised?

Try different numbers of eastbound cars while keeping all other slider values the same.

Try different numbers of northbound cars while keeping all other slider values the same.

Try different values of SPEED-LIMIT while keeping all other slider values the same.

Try different values of MAX-ACCEL while keeping all other slider values the same.

Try different values of GREEN-LENGTH and YELLOW-LENGTH while keeping all other slider values the same.

For all of the above cases, consider the following:

- What happens to the waiting time of eastbound cars?

- What happens to the waiting time of northbound cars?

- What happens to the overall waiting time?

- What generalizations can you make about the impact of each variable on the waiting time of cars?

- What kind of relationship exists between the number of cars and the waiting time they experience?

- What kind of relationship exists between the speed of cars and the waiting time they experience?

- What kind of relationship exists between the number of ticks of green light and the waiting time cars experience?

Use your answers to the above questions to come up with a strategy for minimizing the waiting time of cars.

What factor (or combination of factors) has the most influence over the waiting time experienced by the cars?

## EXTENDING THE MODEL

Find a realistic way to eliminate all crashes by only changing car behavior.

Allow different light lengths for each direction in order to control wait time better.

Is there a better way to measure the efficiency of an intersection than the current number of stopped cars?

## RELATED MODELS

- "Traffic Basic": a simple model of the movement of cars on a highway.

- "Traffic Basic Utility": a version of "Traffic Basic" including a utility function for the cars.

- "Traffic Basic Adaptive": a version of "Traffic Basic" where cars adapt their acceleration to try and maintain a smooth flow of traffic.

- "Traffic Basic Adaptive Individuals": a version of "Traffic Basic Adaptive" where each car adapts individually, instead of all cars adapting in unison.

- "Traffic 2 Lanes": a more sophisticated two-lane version of the "Traffic Basic" model.

- "Traffic Grid": a model of traffic moving in a city grid, with stoplights at the intersections.

- "Traffic Grid Goal": a version of "Traffic Grid" where the cars have goals, namely to drive to and from work.

- "Gridlock HubNet": a version of "Traffic Grid" where students control traffic lights in real-time.

- "Gridlock Alternate HubNet": a version of "Gridlock HubNet" where students can enter NetLogo code to plot custom metrics.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Traffic Intersection model.  http://ccl.northwestern.edu/netlogo/models/TrafficIntersection.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2002.

<!-- 1998 2002 -->
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
true
0
Polygon -7500403 true true 180 15 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 285 165 285 225 285 225 15 180 15
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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
1
@#$#@#$#@
