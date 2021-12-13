globals [
  chamber1patches  ; stores the coordinates for the left chamber
  chamber2patches  ; stores the coordinates for the right chamber
  record-now?  ; a boolean to record the rollypolly distribution at a given time point
]

breed [ rollypollies rollypolly ]

to setup
  clear-all
  setup-chambers
  add-rollypollies
  set record-now? False
  reset-ticks
end

to setup-chambers
  ask patch -17 0 [  ; delineating the area for chamber 1 (left)
    ask patches in-radius 18 [set pcolor white]
    set chamber1patches patches in-radius 18 with [pxcor < 0]
  ]
  ask patch 17 0 [  ; delineating the area for chamber 2 (right)
    ask patches in-radius 18 [set pcolor white]
    set chamber2patches patches in-radius 18 with [pxcor > 0]
  ]
  name-chambers
  update-conditions  ; updates the color of each chamber according to the selected conditions
end

to name-chambers  ; displays the labels above each chamber
  ask patch -12 20 [set plabel "Chamber 1"]
  ask patch 22 20 [set plabel "Chamber 2"]
end

to add-rollypollies
  create-rollypollies number-of-rollypollies [
    set shape "rollypolly"
    set size 5
    set color grey
  ]
end

to go
  ask rollypollies [
    if not (member? patch-here chamber1patches or member? patch-here chamber2patches) [
      move  ; if a rollypolly is in the middle, it will move randomly (scatters them after the initial setup)
    ]
    move-depending-on-the-preference  ; determines the randomness of rollypolly movements based on their position and the preferred condition
  ]
  tick
end

to move-depending-on-the-preference
  if (member? patch-here chamber1patches) [
    ifelse member? condition-in-chamber1 preferred-condition [
      if random 100 > 50 [  ; if the rollypolly is in Chamber 1 and in the preferred condition, there is only a 50% chance it will move randomly
        move
      ]
    ]
    [
      move  ; otherwise, move randomly
    ]
  ]
  if (member? patch-here chamber2patches) [
    ifelse member? condition-in-chamber2 preferred-condition [
      if random 100 > 50 [  ; if the rollypolly is in Chamber 2 and in the preferred condition, there is only a 50% chance it will move randomly
        move
      ]
    ]
    [
      move  ; otherwise, move randomly
    ]
  ]
end

to move  ; turtle procedure
  rt random 30
  lt random 30
  fd 1
  avoid-leaving-a-chamber ; ensures that rollypollies do not move into the black space surrounding the chambers
end

to avoid-leaving-a-chamber
  if [pcolor] of patch-ahead 2 = black [rt 90]
end

to update-conditions  ; colors the chambers white if they are dry, light-blue if they are moist
  ask chamber1patches [ set pcolor (ifelse-value
    condition-in-chamber1 = "dry" [white]
    condition-in-chamber1 = "moist" [98]
    )
  ]
  ask chamber2patches [ set pcolor (ifelse-value
    condition-in-chamber2 = "dry" [white]
    condition-in-chamber2 = "moist" [98]
    )
  ]
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
200
20
613
254
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-40
40
-22
22
1
1
1
ticks
30.0

BUTTON
15
175
186
208
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
15
315
185
352
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
15
68
186
113
condition-in-chamber1
condition-in-chamber1
"dry" "moist"
1

CHOOSER
15
123
186
168
condition-in-chamber2
condition-in-chamber2
"dry" "moist"
0

SLIDER
14
18
187
51
number-of-rollypollies
number-of-rollypollies
0
50
20.0
1
1
NIL
HORIZONTAL

BUTTON
15
365
185
398
update conditions
update-conditions
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
619
21
925
197
Rollypollies in chamber 1
time
number
0.0
10.0
0.0
10.0
false
false
"set-plot-y-range 0 number-of-rollypollies\n" "set-plot-y-range 0 number-of-rollypollies\nset-plot-x-range 0 ticks + 1"
PENS
"default" 1.0 0 -16777216 true "" "plot count rollypollies-on chamber1patches"

PLOT
618
260
927
436
Rollypollies in chamber 2
time
number
0.0
10.0
0.0
10.0
false
false
"set-plot-y-range 0 number-of-rollypollies\n" "set-plot-y-range 0 number-of-rollypollies\nset-plot-x-range 0 ticks + 1"
PENS
"default" 1.0 0 -16777216 true "" "plot count rollypollies-on chamber2patches"

INPUTBOX
15
225
188
298
preferred-condition
moist
1
1
String

MONITOR
619
207
763
252
Rollypollies in Chamber1
count rollypollies-on chamber1patches
17
1
11

MONITOR
782
207
926
252
Rollypollies in Chamber2
count rollypollies-on chamber2patches
17
1
11

PLOT
198
259
612
437
Rollypolly Distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"chamber1" 1.0 1 -13345367 true "" "if record-now? [\nplot count rollypollies-on chamber1patches\n]"
"chamber2" 1.0 1 -5825686 true "" "if record-now? [\nplot count rollypollies-on chamber2patches\nset record-now? False\n]"

BUTTON
15
404
185
437
record data
set record-now? True
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

This model recreates a rollypolly experiment with two chambers in conditions decided by the user. The two possible conditions are moist or dry. Users can also set which condition rollypollies prefer. The rollypollies start in the middle and move towards their preferred chambers when the experiment starts.

## HOW IT WORKS

The user selects conditions for each of the chambers using the two choosers and the preferred conditions for the rollypollies. The rollypollies will move around randomly each second (which maps to one tick in NetLogo). The only exception to this is when rollypollies are in their preferred environment. When this happens they will only move randomly half the time.

## HOW TO USE IT

1. Select the number of rollypollies in the experiment using the NUMBER-OF-ROLLYPOLLIES slider.
2. Select the condition for chamber 1 and chamber 2 using the CONDITION-IN-CHAMBER1 and CONDITION-IN-CHAMBER2 choosers. Also type in which condition should be the preferred condition in the PREFERRED-CONDITIONS input.
3. Press the SETUP button.
4. Press the GO button and observe the plots on the right.
5. It is possible to update chamber conditions and preferred conditions in the middle of the experiment. If you choose to update the chamber conditions use the CONDITION-IN-CHAMBER1 and CONDITION-IN-CHAMBER2 choosers. If you choose to update the preferred conditions use the PREFERRED-CONDITIONS input box.
6. Use the RECORD DATA button to see how the rollypollies are distributed between the two chambers. Each click corresponds with one data instance at the current time point.

NUMBER-OF-ROLLYPOLLIES is a slider that ranges from 0-50. It controls the number of rollypollies in the model.

CONDITION-IN-CHAMBER1 and CONDITION-IN-CHAMBER2 are choosers that control the condition of the chambers. The two options are dry or moist.

PREFERRED-CONDITIONS is an input box that sets the preferred condition. The user must type in `dry` or `moist` for it to be effective.

## THINGS TO NOTICE

Does changing the number of rollypollies in the chambers affect anything?

Is there a difference between the rollypollies preferring dry conditions or moist conditions?

## THINGS TO TRY

Try changing the preferred condition in the middle of the experiment. What happens as a result of this? Hint: Use the plots to help you.

Try changing the chamber conditions in the middle of the experiment. What happens as a result of this?

## CURRICULAR USE

This model was incorporated into an Animal Behavior Experimental Lab which was designed for high school Advanced Placement (AP) Biology students. Within the lab, these students simulated agent-level interactions to model their prior hands-on lab experiments.

The [associated unit](https://ct-stem.northwestern.edu/curriculum/preview/1523/) contains several iterations of this rollypolly model:

* [The basic model](https://ct-stem.northwestern.edu/curriculum/preview/1529/page/3/)
Students use the model to make observations and conduct experiments regarding habitat preference behavior of rollypollies.

* [An introductory model with suggested time intervals](https://ct-stem.northwestern.edu/curriculum/preview/1529/page/1/)
Students are asked to record data after different time intervals and across different numbers of rollypollies. They are expected to learn about the nuances of experimental design (large sample size, multiple trials, etc.).

* [The model extended with CODAP, a data science tool](https://ct-stem.northwestern.edu/curriculum/preview/1525/page/1/)
Students use a computationally enhanced data collection method to record and analyze data using CODAP, a computational tool for data visualization and analysis.

* [A NetTango version that allows students to code with programming blocks](https://ct-stem.northwestern.edu/curriculum/preview/1530/page/1/)
Students use a block-based coding environment, NetTango, to code habitat preference behavior.

## EXTENDING THE MODEL

This is a very simple model that is easy to extend. Here are some ideas on things to implement in the model:

- Try changing the percentage of the time the rollypollies don't move when they are in their preferred conditions.
- Try implementing a new condition such as `wet`.
- Try adding a new chamber into the VIEW.

## NETLOGO FEATURES

This model uses the INPUT widget of NetLogo to allow user set the PREFERRED-CONDITION by rollypollies, in effect, allowing the user to edit the code of the model without having to search through the CODE tab.

## RELATED MODELS

Checkout the Bug Hunt Speeds in the Models Library.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S., Granito, T. and Wilensky, U. (2020).  NetLogo Habitat Preference Behavior model.  http://ccl.northwestern.edu/netlogo/models/HabitatPreferenceBehavior.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

<!-- 2020 CTSTEM Cite: Dabholkar, S., Granito, T. -->
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

rollypolly
true
0
Circle -7500403 true true 90 165 120
Circle -7500403 true true 90 135 120
Line -7500403 true 150 85 80 15
Line -7500403 true 150 85 220 15
Circle -7500403 true true 90 90 118
Circle -7500403 true true 105 75 90
Circle -7500403 true true 90 60 120
Polygon -16777216 true false 90 120 90 135 210 135 210 120 90 120 90 120
Polygon -16777216 true false 90 165 90 180 210 180 210 165 90 165 90 165
Polygon -16777216 true false 90 210 90 225 210 225 210 210 90 210 90 210

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
