turtles-own [
  ready-timer  ;; timer that keeps molecules from immediately entering a reverse reaction
]

;; Setup Procedures
to setup
  clear-all
  set-default-shape turtles "circle"
  create-turtles blue-molecules [
    setup-molecules blue
  ]
  create-turtles yellow-molecules [
    setup-molecules yellow
  ]
  reset-ticks
end

;;  Sets a timer to indicate whether or not the molecule is ready
;;  to react to zero, the color of the molecule, and the position of
;;  the molecule to random x & y coordinates.
to setup-molecules [c] ;; turtle procedure
  set ready-timer 0
  set color c
  setxy random-xcor random-ycor
end


;;  Runtime Procedures

;;  Turtles wiggle then check for a reaction. Turtles that have a ready-timer also reduce it by one tick.
to go
  ask turtles [
    if ready-timer > 0 [
      set ready-timer ready-timer - 1
    ]
    wiggle

    ;; If a blue molecule meets a yellow molecule, they
    ;; respectively become green and pink molecules
    check-for-reaction blue yellow green pink

    ;; If a green molecule meets a pink molecule, they
    ;; respectively become blue and yellow molecules
    check-for-reaction green pink blue yellow

  ]
  tick
end

;; turtles are given a slight random twist to their heading.
to wiggle ;; turtle procedure
  fd 1
  rt random-float 2
  lt random-float 2
end

;; A reaction is defined by four colors: the colors of the two molecules that can potentially
;; react together (reactant-1-color and reactant-2-color) and the colors of the two molecules
;; that will be produced if such a reaction occurs (product-1-color and product-2-color.)
to check-for-reaction [ reactant-1-color reactant-2-color product-1-color product-2-color ] ;; turtle procedure
  ;; start by checking if we are ready to react and
  ;; if we are the right color for this reaction
  if ready-timer = 0 and color = reactant-1-color [
    ;; try to find a partner of the appropriate color with whom to react

    if any? turtles-here with [ color = reactant-2-color ] [
      ;; there is a reactant here, so do the reaction
      react product-1-color
      ask one-of turtles-here with [ color = reactant-2-color ] [ react product-2-color ]
    ]
  ]
end

;; When a molecule reacts, it changes its color, sets a new heading, and
;; sets a timer that will give it enough time to move out of the way
;; before reacting again.
to react [ new-color ] ;; turtle procedure
  set color new-color
  rt random-float 360
  set ready-timer 2
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
328
10
705
388
-1
-1
9.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
83
49
163
83
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
168
49
249
83
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
9
10
164
43
yellow-molecules
yellow-molecules
0.0
500.0
250.0
1.0
1
NIL
HORIZONTAL

SLIDER
168
10
323
43
blue-molecules
blue-molecules
0.0
500.0
250.0
1.0
1
NIL
HORIZONTAL

MONITOR
168
87
248
132
blues
count turtles with [color = blue]
3
1
11

MONITOR
83
87
163
132
yellows
count turtles with [color = yellow]
3
1
11

MONITOR
168
137
248
182
greens
count turtles with [color = green]
3
1
11

MONITOR
83
137
160
182
pinks
count turtles with [color = pink]
3
1
11

PLOT
10
189
324
410
Molecule amounts
ticks
number
0.0
100.0
0.0
200.0
true
true
"set-plot-y-range 0 max (list yellow-molecules blue-molecules)" ""
PENS
"yellows" 1.0 0 -1184463 true "" "plot count turtles with [color = yellow]"
"blues" 1.0 0 -13345367 true "" "plot count turtles with [color = blue]"
"greens" 1.0 0 -12087248 true "" "plot count turtles with [color = green]"
"pinks" 1.0 0 -2064490 true "" "plot count turtles with [color = pink]"

@#$#@#$#@
## WHAT IS IT?

This model shows how a simple chemical system comes to different equilibrium states depending on the concentrations of the initial reactants. Equilibrium is the term we use to describe a system in which there are no macroscopic changes.  This means that the system "looks" like nothing is happening.  In fact, in all chemical systems atomic-level processes continue but in a balance that yields no changes at the macroscopic level.

This model simulates two simple reactions of four molecules. The reactions can be written:

```text
        A + B =======> C + D
```

and

```text
        C + D =======> A + B
```

This can also be written as a single, reversible reaction:

```text
        A + B <=======> C + D
```

A classic real-life example of such a reaction occurs when carbon monoxide reacts with nitrogen dioxide to produce carbon dioxide and nitrogen monoxide (or, nitric oxide).  The reverse reaction (where carbon dioxide and nitrogen monoxide react to form carbon monoxide and nitrogen dioxide) is also possible. While all substances in the reaction are gases, we could actually watch such a system reach equilibrium as nitrogen dioxide (NO<sub>2</sub>) is a visible reddish colored gas. When nitrogen dioxide (NO<sub>2</sub>) combines with carbon monoxide (CO), the resulting products -- nitrogen monoxide (NO) and carbon dioxide (CO<sub>2</sub>) -- are colorless, causing the system to lose some of its reddish color. Ultimately the system comes to a state of equilibrium with some of the "reactants" and some of the "products" present.

While how much of each "reactant" and "product" a system ends up with depends on a number of factors (including, for example, how much energy is released when substances react or the temperature of the system), this model focuses on the concentrations of the reactants.

## HOW IT WORKS

In the model, blue and yellow molecules can react with one another as can green and pink molecules. At each tick, each molecule move randomly throughout the world encountering other molecules. If it meets a molecule with which it can react (for example a yellow molecule meeting a blue, or a pink meeting a green, a reaction occurs. Because blue and yellow molecules react to produce green and pink molecules, and green and pink molecules react to produce blue and yellow molecules, eventually a state of equilibrium is reached.

To keep molecules from immediately reacting twice in a row, each molecule has a "ready-timer." After a reaction, this timer is set to 2, and over two ticks, the timer is decremented back to zero, allowing the molecule to react again.

## HOW TO USE IT

The YELLOW-MOLECULES and BLUE-MOLECULES sliders determine the starting number of yellow and blue molecules respectively. Once these sliders are set, pushing the SETUP button creates these molecules and distributes them throughout the world.

The GO button sets the simulation in motion. Molecules move randomly and react with each other, changing color to represent rearrangement of atoms into different molecular structures. The system soon comes into equilibrium.

Four monitors show how many of each kind of molecule are present in the system. The plot MOLECULE AMOUNTS shows the number of each kind of molecule present over time.

## THINGS TO NOTICE

You may notice that the number of product molecules is limited by the smallest amount of initial reactant molecules. Notice that there is always the same number of product molecules since they are formed in a one-to-one correspondence with each other.

## THINGS TO TRY

How do different amounts of the two reactants affect the final equilibrium? Are absolute amounts important, is it the difference between the amounts, or is it a ratio of the two reactants that matters?

Try setting the YELLOW-MOLECULES slider to 400 and the BLUE-MOLECULES slider to 20, 40, 100, 200, and 400 in five successive simulations. What sort of equilibrium state do you predict in each case? Are certain ratios predictable?

What happens when you start with the same number of YELLOW-MOLECULES and BLUE-MOLECULES? After running the model, what is the relationship between the count of these two types of molecules?

## EXTENDING THE MODEL

What if the forward and reverse reaction rates were determined by a variable instead of initial concentrations? You could compare such a simulation with the one in this model and see if concentration and reaction rates act independently of each other, as measured by the final equilibrium state.

You could also extend the program by allowing the user to introduce new molecules into the simulation while it is running.  How would the addition of fifty blue molecules affect a system that was already at equilibrium?

## NETLOGO FEATURES

The line `if any? turtles-here with [ color = reactant-2-color ]` uses a combination of the `any?` and `turtles-here` commands to check to see if there are any other turtles of a specific type occupying the same path. This is both a succinct and easily readable way to achieve this behavior.

## RELATED MODELS

Enzyme Kinetics
Simple Kinetics 1

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Chemical Equilibrium model.  http://ccl.northwestern.edu/netlogo/models/ChemicalEquilibrium.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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
