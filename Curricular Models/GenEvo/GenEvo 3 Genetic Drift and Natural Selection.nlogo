breed [ ecolis ecoli ]
globals [
  sugar-color ; a global variable to set color of patches with sugar
  carrying-capacity-multiplier  ; a variable to set sugar addition rate that determines carrying capacity
  color-list    ; list of colors of ecolis
  color-types   ; types of ecolis (of different colors) in the population
]
patches-own [ sugar? ]  ; a boolean to track if a patch has a sugar or not
ecolis-own [ energy ]   ; a variable to track energy of E. coli cells

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;SETUP PROCEDURES ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup     ; Sets up the population of bacteria (E. coli) randomly across the world.
  clear-all
  set sugar-color 2

repeat round (max-initial-population / number-of-types)[
  set color-list [ red orange brown yellow green cyan violet magenta ]
  let assign-colors-list color-list
  create-ecolis number-of-types [
    set shape "ecoli"
    set size 2
    set energy 1000
    setxy random-xcor random-ycor
    set color first  assign-colors-list
    set  assign-colors-list but-first  assign-colors-list ; each type has a unique color so we remove this color form our list
  ]
]

set-carrying-capacity-multiplier

  ask ecolis [
    if color = runresult ecoli-with-selective-advantage [
      set shape "ecoli adv"
      set size 3
    ]
  ]

  ask patches [
    set sugar? False
  ]

  ask n-of round (count patches * 0.1) patches [    ; initially sugar is added to 10% of patches
    set pcolor sugar-color
    set sugar? True
  ]

  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;RUNTIME PROCEDURES ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  add-sugar
  ask ecolis [
    move
    eat-sugar
    reproduce
    death
  ]
  tick
end

to add-sugar  ; sugar is added to the environment, using a boolean sugar? for each patch
  if count patches with [pcolor = black] > round (count patches * carrying-capacity-multiplier) [
    ; at each tick sugar is added to maximum of carrying-capacity-multiplier% of patches
    ask n-of round (count patches * carrying-capacity-multiplier) patches [
      set pcolor sugar-color
      set sugar? True
    ]
  ]
end

to move   ; E. coli cells move randomly across the world.
  rt random-float 60
  lt random-float 60
  fd 1
  set energy energy - 20     ; movement and metabolism reduces energy
end

to eat-sugar ; E.coli cells eat sugar if they are at a patch that has sugar. Their energy increases by 100 arbitrary energy units.
  ifelse natural-selection? [    ; In case of natural selection only cells with 'selective advantage' gain more energy from sugar
    ifelse color = runresult ecoli-with-selective-advantage [
      if sugar? [
        set energy energy +  100 + %-advantage
        set pcolor black
        set sugar? False
      ]
    ][
      if sugar? [
        set energy energy + 100
        set pcolor black
        set sugar? False
      ]
    ]
  ][
    if sugar? [
      set energy energy + 100
      set pcolor black
      set sugar? False
    ]
  ]
end

to reproduce  ; E. coli cells reproduce if their energy doubles.
  if energy > 2000 [
    set energy energy / 2
    hatch 1 [
      rt random-float 360
      fd 1
      set energy energy / 2
    ]
  ]
end

to death   ; E. coli cells die if their energy drops below zero.
  if energy < 0 [
    die
  ]
end

to set-carrying-capacity-multiplier
  if carrying-capacity = "very high" [
    set carrying-capacity-multiplier 0.01
  ]
  if carrying-capacity = "high" [
    set carrying-capacity-multiplier 0.008
  ]
  if carrying-capacity = "medium" [
    set carrying-capacity-multiplier 0.006
  ]
  if carrying-capacity = "low" [
    set carrying-capacity-multiplier 0.004
  ]
  if carrying-capacity = "very low" [
    set carrying-capacity-multiplier 0.002
  ]
end

to-report types
  set color-types 0
  let i 0
  repeat length color-list [
    if count ecolis with [color = item i color-list] > 0 [set color-types color-types + 1]
    set i i + 1
  ]
  report color-types

end

; to convert the string for export-interface 'date-and-time' command to work on windows machines
to-report replace-all [target replacement str]
  let acc str
  while [position target acc != false] [
    set acc (replace-item (position target acc) acc replacement)
  ]
  report acc
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
430
10
958
539
-1
-1
8.0
1
10
1
1
1
0
1
1
1
-32
32
-32
32
1
1
1
ticks
30.0

BUTTON
15
10
106
50
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
115
10
205
50
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
15
285
420
540
Population Dynamics Graph
Time
Frequency
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"red" 1.0 0 -2674135 true "" "plot count ecolis with [ color = red ]"
"orange" 1.0 0 -955883 true "" "plot count ecolis with [ color = orange ]"
"brown" 1.0 0 -6459832 true "" "plot count ecolis with [ color = brown ]"
"yellow" 1.0 0 -1184463 true "" "plot count ecolis with [ color = yellow ]"
"green" 1.0 0 -10899396 true "" "plot count ecolis with [ color = green ]"
"cyan" 1.0 0 -11221820 true "" "plot count ecolis with [ color = cyan ]"
"violet" 1.0 0 -8630108 true "" "plot count ecolis with [ color = violet ]"
"magenta" 1.0 0 -5825686 true "" "plot count ecolis with [ color = magenta ]"

SLIDER
15
100
205
133
number-of-types
number-of-types
1
8
4.0
1
1
NIL
HORIZONTAL

TEXTBOX
30
245
465
271
Each type is represented by a different color in the model. The cells\nthat have a selective advantage are represented by a blue outline.
11
0.0
1

CHOOSER
15
140
205
185
ecoli-with-selective-advantage
ecoli-with-selective-advantage
"red" "orange" "brown" "yellow" "green" "cyan" "violet" "magenta"
2

SLIDER
215
105
420
138
%-advantage
%-advantage
0
1
0.6
0.1
1
NIL
HORIZONTAL

SWITCH
215
10
420
43
natural-selection?
natural-selection?
0
1
-1000

TEXTBOX
220
140
465
181
%-advantage is really just an increase\nin sugar eating efficiency.
11
0.0
1

SLIDER
15
190
205
223
max-initial-population
max-initial-population
number-of-types
10 * number-of-types
12.0
number-of-types
1
NIL
HORIZONTAL

CHOOSER
215
50
420
95
carrying-capacity
carrying-capacity
"very high" "high" "medium" "low" "very low"
2

MONITOR
215
180
420
225
Number of surviving types
types
17
1
11

BUTTON
15
60
205
93
save screenshot
export-interface (word \"GenEvo 3 GD and NS \" (replace-all \":\" \"-\" date-and-time) \".png\")
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

This model allows for the exploration and comparison of two different mechanisms of evolution: natural selection and genetic drift. It models evolution in a population of asexually reproducing bacteria, E. coli.

It starts with different types of E. coli, each with a different types (trait values) represented by different colors. When ‘natural selection’ is off, the model shows that competing types of E. coli, each reproducing with equal likelihood on each turn, will ultimately converge on one type without any selection pressure forcing this convergence. This is called genetic drift, an idea explained in more detail in Dennett's _Darwin's Dangerous Idea_ that explains that genetic drifts can occur without any particular purpose or 'selecting pressure'. When ‘natural selection’ is on, one of the type of E. coli cells has a selective advantage. It gains more energy from sugar in a given time unit. This results in faster reproduction by that type of cells. An important thing to note is this model includes one mechanism of natural selection called _r-selection_.

## HOW IT WORKS

The model starts with different colored E. coli cells, randomly distributed across the world. The user can select the number of different colors (types) of cells to start with. The cells can then move randomly across the world. Then,

When Natural Selection is OFF:

Each turn, each E. coli moves randomly around the world, eats sugar if the patch it is at contains sugar. Eating sugar increases energy of E. coli cell, whereas movement and basic metabolic processes decreases energy. An E. coli cell reproduces when its energy doubles, to form to two daughter cells of its type (of the same color). If energy of an E.coli cell reduces to zero, the cell dies.
The increase in energy by eating sugar is identical for each type (color) of E. coli cell. By statistical advantage, a dominant color becomes more likely to ‘win’ and take over the population. However, because the process is random, there will usually be a series of dominant colors before one color finally wins.

When Natural Selection is ON:

A user can select which type (color) has a selective advantage in this world, causing it to gain more efficiently digest sugar and gain more energy from sugar at each time step. The cells with selective advantage are represented as cells with blue outline in the model.

This in terns causes that particular type of E. coli reproduce faster. The % advantage slider sets the percentage increase in energy gain by the cells with selective advantage. Through this selective advantage, a dominant color becomes more likely to 'win. However, if the selective advantage is low, statistical advantage might still cause another color to 'win.

Note that once a color dies out, it can never come back.

## HOW TO USE IT

The SETUP button initializes the model.

The GO button runs the model.

Use the NUMBER-OF-TYPES slider to select the number of competing colors.

Use the ECOLI-WITH-SELECTIVE-ADVANTAGE chooser to select the color (type) of E. coli that has a selective advantage.

Use the %-ADVANTAGE slider to set % increase in energy gain of "Faster reproducing E. coli" as compared to others.

Use the MAX-INITIAL-POPULATION to set maximum population of all types of E. coli bacteria at the beginning of the simulation.

Use the CARRYING-CAPACITY chooser to chose the carrying capacity that is the maximum number of individuals that survive in the given environment. This chooser changes sugar availability (rate of addition of sugar per tick) in the model.

## THINGS TO NOTICE

Notice that the E. coli cells with selective advantage often wins the race when the % selective advantage is high. When the % selective advantage is low, statistical advantage in favor of any of the other colors might result in different outcomes. Check if there is any tipping point above which % selective advantage always makes the color win.

Notice the effect of change in the carrying capacity on the natural selection process.

## THINGS TO TRY

In each simulation, the time required for a single type to become dominant varies. Check to see if an increase or decrease in the carrying capacity has any effect on how fast a color wins. Now check this same phenomenon in the presence and absence of natural selection.

## EXTENDING THE MODEL

The type of natural selection incorporated in this model is _r-selection_. The other possible type is _k-selection_. Think about how you could incorporate k-selection in this model.

## NETLOGO FEATURES

This model uses the `runresult` primitive in order to convert your color selection (a `string`) into a NetLogo color (a number).

## RELATED MODELS

* GenDrift Sample Models
* GenEvo Curricular Models

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S. and Wilensky, U. (2016).  NetLogo GenEvo 3 Genetic Drift and Natural Selection model.  http://ccl.northwestern.edu/netlogo/models/GenEvo3GeneticDriftandNaturalSelection.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

To cite the GenEvo Systems Biology curriculum as a whole, please use:

* Dabholkar, S. & Wilensky, U. (2016). GenEvo Systems Biology curriculum. http://ccl.northwestern.edu/curriculum/genevo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 GenEvo Cite: Dabholkar, S. -->
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

ecoli
true
0
Rectangle -7500403 true true 90 60 210 240
Circle -7500403 true true 90 0 120
Circle -7500403 true true 90 180 120

ecoli adv
true
0
Rectangle -13345367 true false 90 60 210 240
Circle -13345367 true false 90 0 120
Circle -13345367 true false 90 180 120
Rectangle -7500403 true true 120 75 180 240
Circle -7500403 true true 120 210 60
Circle -7500403 true true 120 45 60

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
need-to-manually-make-preview-for-this-model
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
