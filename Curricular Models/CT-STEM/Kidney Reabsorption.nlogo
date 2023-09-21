breed [molecules molecule] ; The turtles which represent molecules

globals [
  water-molecules-absorbed ; The number of water molecules absorbed
  salt-molecules-absorbed ; The number of salt molecules absorbed
]

to setup
  clear-all
  resize-lumen ; Adds the molecules and sets up the tube
  reset-ticks
end

to go
  ; Stops once all the molecules hit the bottom of the VIEW
  if not any? molecules with [ycor > min-pycor] [ stop ]
  ask molecules
  [
    ; Randomizes the direction of a molecule from 45 to 315 degrees
    set heading (random 270) + 45
    if ycor > min-pycor [ move ]
    check-if-absorbed
  ]
  tick
end

; Now we add the molecules which are shown in the view
to add-water-molecules ; Procedure to add water molecules
  create-molecules number-of-water-molecules [
    ; Randomizes the position of the water molecules at the top
    setxy (random-float (1.25 * max-pxcor) - ((1.25 * max-pxcor) / 2))
          (0.9 * max-pycor + random-float 0.5)
    set shape "dot"
    set color blue
  ]
end

to add-salt-molecules ; Procedure to add salt molecules
  create-molecules number-of-salt-molecules [
    ; Randomizes the position of the salt molecules at the top
    setxy (random-float (1.25 * max-pxcor) - ((1.25 * max-pxcor) / 2))
          (0.9 * max-pycor + random-float 0.5)
    set shape "dot"
    set color grey
  ]
end

; Moves the turtles down 0.5 steps
to move ; Turtle procedure
  fd 0.5
end

; Checks if the molecule is absorbed
to check-if-absorbed ; Turtle procedure
  ; Checks if the water molecules are absorbed
  if color = blue [
    ;  Checks if the patch under the water molecule is brown
    if [ pcolor ] of patch-here = brown [
      ifelse random 100 < chance-of-water-absorption [
        ; Changes reporter for the water molecules absorbed
        set water-molecules-absorbed water-molecules-absorbed + 1
        die
      ] [
        ; Moves the molecule towards its neighboring molecule if it is not absorbed
        if count neighbors with [ pcolor = black ] > 0 [
          face one-of neighbors with [ pcolor = black ]
          fd 1
        ]
      ]
    ]
  ]
  ; Checks if the salt molecules are absorbed
  if color = grey [
    if [ pcolor ] of patch-here = brown [ ; Checks if the patch under the salt molecule is brown
      ifelse random 100 < chance-of-salt-absorption [
        ; Changes reporter for the salt molecules absorbed
        set salt-molecules-absorbed salt-molecules-absorbed + 1
        die
      ] [
        ; Moves the molecule towards its neighboring molecule if it is not absorbed
        if count neighbors with [ pcolor = black ] > 0 [
          face one-of neighbors with [ pcolor = black ]
          fd 1
        ]
      ]
    ]
  ]
end

; Resize the lumen wall
to resize-lumen
  ; Changes the size of the patch grid
  resize-world  (-1 * (int (0.75 * diameter-of-tube)))
                int (0.75 * diameter-of-tube) min-pycor max-pycor
  ; The next two lines will create the brown walls which will absorb the molecules
  ask patches with [pxcor < -0.67 * max-pxcor] [ set pcolor brown ]
  ask patches with [pxcor > 0.67 * max-pxcor] [ set pcolor brown ]
  add-water-molecules
  add-salt-molecules
  set water-molecules-absorbed 0
  set salt-molecules-absorbed 0
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
644
10
862
457
-1
-1
6.0
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
-36
36
1
1
1
ticks
30.0

BUTTON
10
305
235
355
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
365
235
415
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
50
235
83
number-of-water-molecules
number-of-water-molecules
0
1000
100.0
10
1
NIL
HORIZONTAL

MONITOR
455
305
630
350
water molecules unabsorbed
count molecules with [color = blue]
17
1
11

SLIDER
10
175
235
208
chance-of-water-absorption
chance-of-water-absorption
0
100
80.0
1
1
NIL
HORIZONTAL

MONITOR
255
305
420
350
water molecules absorbed
water-molecules-absorbed
17
1
11

SLIDER
10
10
235
43
number-of-salt-molecules
number-of-salt-molecules
0
1000
300.0
10
1
NIL
HORIZONTAL

SLIDER
10
135
235
168
chance-of-salt-absorption
chance-of-salt-absorption
0
100
10.0
1
1
NIL
HORIZONTAL

MONITOR
255
370
420
415
salt molecules absorbed
salt-molecules-absorbed
17
1
11

MONITOR
455
370
630
415
salt molecules unabsorbed
count molecules with [color = grey]
17
1
11

SLIDER
10
255
235
288
diameter-of-tube
diameter-of-tube
5
25
23.0
1
1
NIL
HORIZONTAL

PLOT
255
10
630
290
%  absorbed
NIL
NIL
0.0
1000.0
0.0
110.0
false
false
"" ""
PENS
"water" 1.0 0 -13345367 true "" "ifelse number-of-water-molecules = 0 \n[ plot 0 ]\n[ plot (water-molecules-absorbed / number-of-water-molecules) * 100 ]"
"salt" 1.0 0 -7500403 true "" "ifelse number-of-salt-molecules = 0\n[ plot 0 ]\n[ plot (salt-molecules-absorbed / number-of-salt-molecules) * 100 ]"

TEXTBOX
55
110
205
128
Absorption parameters
11
0.0
1

TEXTBOX
75
230
185
248
Tube dimensions
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a model of absorption of a solute and a solvent at the wall of a tube. It illustrates selective reabsorption that happens in the kidney which is a vital part of kidney function. Reabsorption is a process by which the nephron removes water and solutes from the tubular fluid (pre-urine) and returns them to the circulating blood. This model can be used to understand differential reabsorption that happens in the different parts of the nephron in a kidney, specifically in the [Loop of Henle] (https://en.wikipedia.org/wiki/Loop_of_Henle).

The wall of the descending Loop of Henle has a high permeability to water making the chance of absorption of water high. The wall of the ascending Loop of Henle is impermeable to water but permeable to ions. Another important aspect of nephology that is modeled here is the dimensions of the tubes of a nephron (a functional unit of the kidney). An adult kidney has 1 to 1.5 million nephrons. Instead of having a small number of large nephrons, a kidney has a large number of small nephrons which significantly enhances its capacity to filter fluid. Users can change the diameter of the tube to investigate the effect of lumen size on the process of reabsorption.

## HOW IT WORKS

The motion of each molecule (salt/water) is independent and random in the model. Note that this is restricted randomization meaning molecules start towards the top and follow a general downward trajectory. The black patches are the lumen and the brown patches denote the lumen wall. In the model if a molecule (water or salt) is at the wall, it gets absorbed based on the set CHANCE-OF-ABSORPTION. The chance of absorption can be set differently for water and salt. This allows users to model different parts of the Loop of Henle. The world (lumen) when resized, affects the probability of a molecule to come in proximity of the wall.

## HOW TO USE IT

1. Adjust the slider parameters – NUMBER-OF-SALT-MOLECULES, CHANCE-OF-SALT-ABSORPTION, NUMBER-OF-WATER-MOLECULES, and CHANCE-OF-WATER-ABSORPTION.
2. Adjust the DIAMETER-OF-TUBE.
3. Press the SETUP button.
4. Press the GO button to begin the model run.
5. View the output of WATER MOLECULES ABSORBED, WATER MOLECULES UNABSORBED, SALT MOLECULES ABSORBED, and SALT MOLECULES UNABSORBED.
6. View the trend of % ABSORBED of salt (grey) and water (blue) in the right panel.

The NUMBER-OF-WATER-MOLECULES is the number of water molecules that have entered into the lumen of the nephron after passing through the glomerulus filtration. This normally depends on the consumption/production of the molecules and the body’s ability to retain it in the system.
CHANCE-OF-WATER-ABSORPTION is the chance of a water molecule to get reabsorbed when it comes in contact with the lumen wall.
WATER MOLECULES ABSORBED is the number of water molecules reabsorbed in the body through the exchange pumps so far.
WATER MOLECULES UNABSORBED is the number of molecules not (yet) reabsorbed in the body and will eventually be discarded out as urine.
SALT MOLECULES ABSORBED is the number of salt molecules reabsorbed in the body through the exchange pumps. Note, there are specific pumps for each ion which work on concentration gradients for the exchange. However, those are not modeled here.
SALT MOLECULES UNABSORBED is the number of molecules not (yet) reabsorbed in the body and will eventually be discarded out as urine.
DIAMETER-OF-TUBE is the diameter of the lumen of a section of a nephron.
PERCENTAGE ABSORPTION is the percentage of salt/water molecules absorbed with reference to the total intake.

## THINGS TO NOTICE

The number of absorbed and unabsorbed molecules (salt/water) will tend to change every time you run the model even with the same values for the number of molecules (salt/water), chances of absorption (salt/water), and diameter of the tube. This is because the chances of a molecule (salt/water) being received on a pump will depend on its probability of coming in the proximity of the pump (brown patch) and the concentration gradient.

The motion of each molecule is independent and random.

## THINGS TO TRY

Compare how changing the CHANCE-OF-ABSORPTION (salt/water) has an effect on the MOLECULES ABSORBED (salt/water) and MOLECULES UNABSORBED (salt/water) for the same value of NUMBER-OF MOLECULES (salt/water). Is there any difference between water and salt molecules when you start with the exact same values?

How can you set the values of the parameters such that you are modeling the reabsorption behavior of the descending or the ascending Loop of Henle?

Try changing the DIAMETER-OF-TUBE. How do the numbers of molecules absorbed change?

What do you infer from the observed graphical values? Are there any correlation trends?

## CURRICULAR USE

This model was incorporated into the CT-STEM lesson, [Excretory System: Reabsorption](https://ct-stem.northwestern.edu/curriculum/preview/1012/), a lesson plan designed for a high school biology class. In the lesson, students experiment with a progression of three absorption models that gradually introduce more features. The three models are:

1. [A basic model of absorption](https://ct-stem.northwestern.edu/curriculum/preview/1012/page/3/) is used on Page 3.
This basic model only asks students to vary the number of molecules and chance of absorption and observe the effect on molecules absorbed. This is intended to introduce students to model and allow them to understand the core mechanics of the system before introducing more elements to it.

2. [A model of selective reabsorption](https://ct-stem.northwestern.edu/curriculum/preview/1012/page/4/) is used on Page 4.
In this model, students can now observe two different molecules (water and salt) and modify their chance of absorption. Students are intended to change the parameters to model the reabsorption behavior of descending and ascending loops of Henle.

3. [This model with variable lumen size](https://ct-stem.northwestern.edu/curriculum/preview/1012/page/5/) is used on Page 5
This model is the closest to the Excretory Reabsorption model in the model library. It is the most complex model and has the most features. All features from previous models are kept but now students are also able to change the size of the tube and observe how this affects the number of absorbed molecules.

## EXTENDING THE MODEL

How can you extend the model to incorporate reabsorption of other solutes such as glucose or amino acids that happen in the other parts of the kidney? Can you make vertical parts of the tube such that different parts have different reabsorption properties?

Can you think of a possible parameter about the lumen other than the diameter that when changed, can affect the working of this model?

## NETLOGO FEATURES

This model uses the NetLogo's RESIZE-WORLD method to change the lumen width for the corresponding patch grid.

## RELATED MODELS

* Take a look at the first two models in the related CT-STEM unit (see the CURRICULAR USE section)
* For another model that simulates falling particles, check out the DLA Alternate Linear model in the Models Library

## CREDITS AND REFERENCES

This model is designed for the Excretion unit for class XI CBSE or Freshmen Biology.

Reference books used: “All in One Biology” for CBSE Class XI.

For more information about the countercurrent exchange for Urine formation:

- Bruce M. Koeppen MD, Ph.D., Bruce A. Stanton Ph.D., in Renal Physiology (Fifth Edition), 2013.
- https://www.khanacademy.org/test-prep/mcat/organ-systems/the-renal-system/a/renal-physiology-counter-current-multiplication

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S. and Wilensky, U. (2020).  NetLogo Kidney Reabsorption model.  http://ccl.northwestern.edu/netlogo/models/KidneyReabsorption.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

<!-- 2020 CTSTEM Cite: Dabholkar, S. -->
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
NetLogo 6.3.0
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
