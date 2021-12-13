globals [
  bob ; The pendulum bob that is shown swinging
  omega ; The angular velocity of the pendulum: sqrt (g/length-of-pendulum)
  amplitude ; The amplitude of the pendulum based on release-angle
  theta ; release-angle
  initial-position ; Where the pendulum starts its simple harmonic motion
  period-calculated? ; Has the period been calculated
]

to setup
  clear-all
  reset-ticks
  ; Create the pendulum bob and initialize its variables
  create-turtles 1 [
    set color white
    set shape "circle"
    set size 2

    ; Set the direction the bob will travel based on release-angle
    ifelse release-angle > 0 [ set heading 270 - release-angle]
                             [ set heading 90  - release-angle ]
    let adjusted-release-angle -90 + release-angle

    ; Set the initial position of the bob for release
    setxy (length-of-pendulum * cos adjusted-release-angle) (length-of-pendulum * sin adjusted-release-angle)
    set theta release-angle
    set bob self
    set initial-position (list (precision xcor 2) (precision ycor 2))
    set period-calculated? False

    ; Now we trace the bob's movement with the pen tool
    pen-down
  ]
  ; Create the link which functions as the string for the pendulum
  create-turtles 1 [
    setxy 0 0
    hide-turtle
    create-link-with bob
  ]
  ; Initialize omega with the equation ω = sqrt(g/l) for pendulum motion
  set omega sqrt (9.8 / length-of-pendulum)
  ; Use the arc length formula to set the amplitude
  set amplitude pi * length-of-pendulum * (2 * release-angle / 360)

end

to go-slowly
  ask bob [
    oscillate
    wait 0.01
  ]
  tick
end

to go
  ask bob [
    oscillate
  ]
  tick
end

to oscillate
  ask bob [
    ; Set theta using the equation θ(t) = initial θ * cos(ω * time)
    set theta release-angle * (cos (omega * ticks))
    ; Set the direction the bob will travel in based on the release-angle
    ifelse theta > 0 [ set heading 270 - theta ]
                     [ set heading 90 - theta ]

    ; Adjusted-theta is the angle needed to calculate the cartesian coordinates of the point
    ; relative to NetLogo 0 degrees which is in the north direction.
    let adjusted-theta -90 + theta
    ; Draw the new position of the bob
    setxy length-of-pendulum * cos adjusted-theta length-of-pendulum * sin adjusted-theta
  ]
end

;;; Reporters ;;;

; Reporter to return the period of the bob
to-report period
  if precision ([xcor] of bob) 2 = item 0 initial-position and
     precision ([ycor] of bob) 2 = item 1 initial-position and
     period-calculated? = False [
    set period-calculated? True
    report ticks
  ]
end

; Reporter to return the distance using the equation, distance = 2 * Amplitude * cos(ω * time)
to-report distance-from-mean-position
  report ( 2 * amplitude * cos ( omega * ticks ) )
end

; Reporter to return the change in distance using, final distance - initial distance
to-report distance-covered-in-a-step
  ; Only report this if the model has started
 if ticks > 0 [
    report
      ( ( 2 * amplitude * cos ( omega * ticks - 1 ) ) - ( 2 * amplitude * cos ( omega * ticks ) ))
    ]
end

; Reporter to return velocity using, v = (-2 * A * ω) * sin(ω * time)
to-report velocity
  report -1 * omega * ( 2 * amplitude * sin ( omega * ticks ) )
end

; Reporter to return acceleration using, a = (-2 * A * ω^2) * cos(ω * time)
to-report acceleration
  report -1 * ( 2 * amplitude * cos ( omega * ticks ) ) * omega * omega
end

; Reporter to return kinetic energy using, KE = 1/2 * m * v^2
to-report kinetic-energy
  report (1 / 2) * mass-of-bob * velocity * velocity
end

; Reporter to return potential energy using, PE = 1/2 * spring constant (k) * x^2 and k = m * g / L
to-report potential-energy
  report (1 / 2) * (( mass-of-bob * 9.8 ) / length-of-pendulum) * distance-from-mean-position * distance-from-mean-position
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
255
10
620
516
-1
-1
7.0
1
10
1
1
1
0
0
0
1
-25
25
-60
10
1
1
1
ticks
30.0

BUTTON
10
134
232
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

BUTTON
10
255
232
289
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
10
232
43
release-angle
release-angle
-18
18
15.0
1
1
NIL
HORIZONTAL

SLIDER
10
50
232
83
length-of-pendulum
length-of-pendulum
1
50
25.0
1
1
NIL
HORIZONTAL

MONITOR
861
10
946
55
velocity
[velocity] of bob
2
1
11

MONITOR
641
10
856
55
distance from the mean position
distance-from-mean-position
2
1
11

BUTTON
10
175
119
210
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

MONITOR
950
10
1047
55
NIL
acceleration
2
1
11

MONITOR
7
465
119
510
NIL
kinetic-energy
2
1
11

MONITOR
123
465
237
510
NIL
potential-energy
2
1
11

PLOT
7
298
237
458
KE and PE
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
"PE" 1.0 0 -13840069 true "" "if ticks > 0 [ plot potential-energy ]"
"KE" 1.0 0 -2674135 true "" "if ticks > 0 [ plot kinetic-energy ] "

SLIDER
10
90
232
123
mass-of-bob
mass-of-bob
1
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
7
517
236
562
total-energy
kinetic-energy + potential-energy
2
1
11

BUTTON
125
175
230
210
go-10-ticks
repeat 10 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
640
218
1045
388
velocity vs time
ticks
velocity
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot velocity"
"pen-1" 1.0 0 -7500403 true "" "plot 0"

PLOT
641
60
1047
215
distance from the mean position vs time
ticks
distance
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [ \n  plot distance-from-mean-position\n]"
"pen-1" 1.0 0 -7500403 true "" "plot 0"

PLOT
640
392
1046
557
acceleration vs time
ticks
acceleration
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [ plot acceleration ]"
"pen-1" 1.0 0 -7500403 true "" "plot 0"

BUTTON
10
215
232
249
go slowly
go-slowly
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

This model is meant to help learners understand simple harmonic motion by exploring the motion of a simple pendulum and observing changes in motion-related parameters like displacement, velocity acceleration. In addition, users can observe changes in the mechanical–kinetic and potential–energy of the pendulum and how the total energy is conserved throughout the motion of the pendulum.

Simple harmonic motion is a periodic motion where the restoring force on the oscillating body is directly proportional to the degree of disturbance. A good approximation of simple harmonic motion that we see around us is the motion of a simple pendulum when the angle of disturbance is small. This model shows a simple pendulum with a small release angle in simple harmonic motion. The user can change the angle of release and the length of the pendulum to observe the changes in the motion of the bob (the part at the end of the string).

## HOW IT WORKS

The model represents a simple pendulum. It consists of a mass (m - also called a bob) hanging from a massless string of length (l) which is fixed at a point. The bob will be shown in simple harmonic motion where each second maps into one tick in NetLogo. When released from an initial angle the bob will swing back and forth in a periodic motion. The motion of the pendulum follows the following equations:

θ(t) = θ<sub>0</sub> cos(ω * t)
ω = sqrt(g / l)
g = acceleration due to gravity
l = length of the pendulum

## HOW TO USE IT

1. Set the RELEASE-ANGLE, LENGTH-OF-PENDULUM, and MASS-OF-BOB sliders and press the SETUP button.
2. Press the GO or GO-SLOWLY buttons to let the model run. You can also choose to press the GO-ONCE or GO-10-TICKS button to run and stop after 1 second or 10 seconds; this allows you to observe the bob's motion more closely.
3. Observe the monitor on the right side of the VIEW to see the distance the bob is from the resting (mean) position. Observe the plot on the right side of the VIEW to see the distance graphed over time.
4. Observe the velocity and acceleration monitors next to the distance monitor and then the velocity and acceleration plots below the distance plot.
5. Observe the KE and PE plot below the GO ONCE and GO-10-TICKS buttons. Look at the KE, PE, and total-energy monitors below this plot.

The motion of the simple pendulum is dependent on three different slider parameters.

1. RELEASE-ANGLE: is the angle from which you release the bob. The angle is measured from the resting position which is a vertical axis. For approximation purposes, the angles are kept between (-18, 18)
2. LENGTH-OF-PENDULUM: is the length of the string attached to the bob (from the center of the bob to the fixed pivot point).
3. MASS-OF-BOB: is the mass of the bob attached to the string.

## THINGS TO NOTICE

Notice the plot to the right of the VIEW, what is the maximum and minimum of it? When does it start to repeat? The time it takes to repeat is called the *period* of the pendulum.

Look at the distance from the mean position monitor, how does it change throughout the pendulum's motion. Do you notice any patterns?

Notice how the velocity peaks when the distance is 0 and the acceleration peaks when the velocity is 0. Why does this happen?

Does the total energy monitor ever change? If so, when does it change?

Why does the pendulum never stop swinging?

## THINGS TO TRY

Try keeping the MASS-OF-BOB and the RELEASE-ANGLE constant and change the LENGTH-OF-PENDULUM. What changes do you see in the pendulum's motion?

Try other combinations. What patterns do you notice?

## CURRICULAR USE

This model was incorporated into the CT-STEM [Simple Harmonic Motion - Simple Pendulum unit](https://ct-stem.northwestern.edu/curriculum/preview/1014/), a lesson plan designed for a high school physics class. In the lesson, students experiment with a progression of three pendulum models that gradually introduce more monitored variables:

1. [The base model with only distance monitored](https://ct-stem.northwestern.edu/curriculum/preview/1014/page/2/)
Students can observe the pendulum and its distance from the mean position over time.

2. [Velocity and acceleration added](https://ct-stem.northwestern.edu/curriculum/preview/1014/page/3/)
Students can now observe velocity and acceleration over time, in addition to the variables from the first model. They are asked to think about how one might use this model to conduct a computational experiment to find g, the acceleration due to gravity. They are also asked to compare their observations with a physical pendulum and the computational experimental setup in this model.

3. [This model with KE and PE added](https://ct-stem.northwestern.edu/curriculum/preview/1014/page/5/)
This final model includes all the features from the first two versions while adding monitors for kinetic energy, potential energy, and total energy. Students can study how the kinetic and the potential energy of a pendulum changes throughout its motion.

## EXTENDING THE MODEL

This is a very simple model that has a limited scope. Here are some more ideas to get you to think more and further your understanding of harmonic motion.

Do we observe the same motion of a simple pendulum in the real world?

What are our assumptions while designing a model of a simple pendulum?

What would happen if the release angle was larger? Would there be any large changes?

What would happen if the gravitational constant was changed?

How will you incorporate the other factors that affect the motion of the pendulum in the real world? [How about adding air friction in this model?](https://en.wikipedia.org/wiki/Harmonic_oscillator)

What would happen if we attach [another pendulum at the end of the original pendulum?] (https://en.wikipedia.org/wiki/Double_pendulum)

## NETLOGO FEATURES

This model uses the pen tool to trace the pendulum's motion in the VIEW. The change in location of the pendulum's bob is traced with the pen tool.

This model also uses a link between two turtles to show the string of the pendulum. There is a hidden turtle at a fixed location and a second turtle which shows up as the pendulum's bob. A link is created between these two turtles to represent the pendulum's string.

## RELATED MODELS

To learn about more advanced features of oscillatory motion, look at the Kicked Rotator and Kicked Rotators models in the Models Library.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S., Wagh, V. and Wilensky, U. (2020).  NetLogo Pendulum model.  http://ccl.northwestern.edu/netlogo/models/Pendulum.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

<!-- 2020 CTSTEM Cite: Dabholkar, S., Wagh, V. -->
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
setup repeat 10000 [ go ]
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
