globals
[
  bugs-stride ;; how much a bug moves in each simulation step
  bug-size    ;; the size of the shape for a bug
  bug-reproduce-age ;; age at which bug reproduces
  bugs-born ;; number of bugs born
  bugs-died ;; number of bugs that died
  max-bugs-age
  min-reproduce-energy-bugs ;; how much energy, at minimum, bug needs to reproduce
  max-bugs-offspring ;; max offspring a bug can have

  max-plant-energy ;; the maximum amount of energy a plant in a patch can accumulate
  sprout-delay-time ;; number of ticks before grass starts regrowing
  grass-level ;; a measure of the amount of grass currently in the ecosystem
  grass-growth-rate ;; the amount of energy units a plant gains every tick from regrowth

  bugs-color
  grass-color
  dirt-color
]

breed [ bugs bug ]
breed [ disease-markers a-disease-marker] ;; visual cue, red "X" that bug has a disease and will die
breed [ embers ember] ;; visual cue that a grass patch is on fire

turtles-own [ energy current-age max-age female? #-offspring]

patches-own [ fertile?  plant-energy countdown]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set bugs-born 0
  set bugs-died 0

  set bug-size 1.2
  set bugs-stride 0.3
  set bug-reproduce-age 20
  set min-reproduce-energy-bugs 10
  set max-bugs-offspring 2
  set max-bugs-age 100
  set grass-level 0

  set sprout-delay-time 25
  set grass-growth-rate 10
  set max-plant-energy 100

  set bugs-color (violet )
  set grass-color (green)
  set dirt-color (white)
  set-default-shape bugs "bug"
  set-default-shape embers "fire"
  add-starting-grass
  add-bugs
  reset-ticks
end

to add-starting-grass
  let number-patches-with-grass (floor (amount-of-grassland * (count patches) / 100))
  ask patches [
      set fertile? false
      set plant-energy 0
    ]
  ask n-of number-patches-with-grass patches  [
      set fertile? true
      set plant-energy max-plant-energy / 2
    ]
  ask patches [color-grass]
end

to add-bugs
  create-bugs initial-number-bugs  ;; create the bugs, then initialize their variables
  [
    set color bugs-color
    set size bug-size
    set energy 20 + random 20 - random 20 ;; randomize starting energies
    set current-age 0  + random max-bugs-age     ;; start out bugs at different ages
    set max-age max-bugs-age
    set #-offspring 0
    setxy random world-width random world-height
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; runtime procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
 if ticks >= 1000 and constant-simulation-length? [stop]
  ask bugs [
    bugs-live
    reproduce-bugs
    ]
  ask patches [
    set countdown random sprout-delay-time
    grow-grass
    ]   ;; only the fertile patches can grow grass
  fade-embers
  age-disease-markers
  tick
end

to remove-a-%-of-bugs
  ;; procedure for removing a percentage of bugs (when button is clicked)
  let number-bugs count bugs
  ask n-of floor (number-bugs * bugs-to-remove / 100) bugs [
    hatch 1 [
     set current-age  0
     set breed disease-markers
     set size 1.5
     set color red
     set shape "x"
     ]
    set bugs-died (bugs-died + 1)
    die
  ]
end

to start-fire
  let current-grass-patches patches with [fertile?]
  let current-burn-patches n-of floor ( (count current-grass-patches) * grass-to-burn-down / 100) current-grass-patches
  ask current-burn-patches [
    set countdown sprout-delay-time
    set plant-energy 0
    color-grass
    create-ember
    ]
end

to create-ember ;; patch procedure
  sprout 1 [
    set breed embers
    set current-age (round countdown / 4)
    set color [255 255 0 255]
    set size 1
    ]
end

to age-disease-markers
  ask disease-markers [
      set current-age (current-age  + 1)
      set size (1.5 - (1.5 * current-age  / 20))
      if current-age  > 25  or (ticks = 999 and constant-simulation-length?)  [die]
   ]
end

to fade-embers
  let ember-color []
  let transparency 0
  ask embers [
    set shape "fire"
    set current-age (current-age - 1)
    set transparency round floor current-age * 255 / sprout-delay-time
   ;; show transparency
    set ember-color lput transparency [255 155 0]
  ;;  show ember-color
    if current-age <= 0 [die]
    set color ember-color
  ]
end

to bugs-live
    move-bugs
    set energy (energy - 1)  ;; bugs lose energy as they move
    set current-age (current-age + 1)
    bugs-eat-grass
    death
end

to move-bugs
  rt random 50 - random 50
  fd bugs-stride
end

to bugs-eat-grass  ;; bugs procedure
  ;; if there is enough grass to eat at this patch, the bugs eat it
  ;; and then gain energy from it.
  if plant-energy > amount-of-food-bugs-eat  [
    ;; plants lose ten times as much energy as the bugs gains (trophic level assumption)
    set plant-energy (plant-energy - (amount-of-food-bugs-eat * 10))
    set energy energy + amount-of-food-bugs-eat  ;; bugs gain energy by eating

  ]
  ;; if plant-energy is negative, make it positive
  if plant-energy <=  amount-of-food-bugs-eat  [set countdown sprout-delay-time ]
end

to reproduce-bugs  ;; bugs procedure
  let number-new-offspring (random (max-bugs-offspring + 1)) ;; set number of potential offpsring from 1 to (max-bugs-offspring)
  if (energy > ((number-new-offspring + 1) * min-reproduce-energy-bugs)  and current-age > bug-reproduce-age)
  [
      set energy (energy - (number-new-offspring  * min-reproduce-energy-bugs))      ;;lose energy when reproducing --- given to children
      set #-offspring #-offspring + number-new-offspring
      set bugs-born bugs-born + number-new-offspring
      hatch number-new-offspring
      [
        set size bug-size
        set color bugs-color
        set energy min-reproduce-energy-bugs ;; split remaining half of energy amongst litter
        set current-age 0
        set #-offspring 0
        rt random 360 fd bugs-stride
      ]    ;; hatch an offspring set it heading off in a a random direction and move it forward a step
  ]
end

to death
  ;; die when energy dips below zero (starvation), or get too old
  if (current-age > max-age) or (energy < 0)
  [ set bugs-died (bugs-died + 1)
    die ]
end

to grow-grass  ;; patch procedure
  set countdown (countdown - 1)
  ;; fertile patches gain 1 energy unit per turn, up to a maximum max-plant-energy threshold
  if fertile? and countdown <= 0
     [set plant-energy (plant-energy + grass-growth-rate)
       if plant-energy > max-plant-energy
       [set plant-energy max-plant-energy]
       ]
  if not fertile?
     [set plant-energy 0]
  if plant-energy < 0 [set plant-energy 0 set countdown sprout-delay-time]
  color-grass
end

to color-grass
  ifelse fertile? [
    ifelse plant-energy > 0
    ;; scale color of patch from whitish green for low energy (less foliage) to green - high energy (lots of foliage)
    [set pcolor (scale-color green plant-energy  (max-plant-energy * 2)  0)]
    [set pcolor dirt-color]
    ]
  [set pcolor dirt-color]
end


; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
405
13
930
539
-1
-1
11.0
1
10
1
1
1
0
1
1
1
-23
23
-23
23
1
1
1
ticks
30.0

BUTTON
23
17
113
50
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
116
17
208
50
go/pause
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
5
207
399
414
Population Size vs. Time
time
population size
0.0
1000.0
0.0
1200.0
true
true
"" "set grass-level ( sum [plant-energy] of patches / (max-plant-energy ))"
PENS
"bugs" 1.0 0 -8630108 true "" "plot count bugs"
"grass" 1.0 0 -10899396 true "" "plot grass-level"

MONITOR
287
416
361
461
bugs
count bugs
3
1
11

SLIDER
5
135
231
168
initial-number-bugs
initial-number-bugs
1
300
30.0
1
1
NIL
HORIZONTAL

SLIDER
6
98
231
131
amount-of-grassland
amount-of-grassland
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
5
170
229
203
amount-of-food-bugs-eat
amount-of-food-bugs-eat
0
8
4.0
.1
1
NIL
HORIZONTAL

SWITCH
6
62
230
95
constant-simulation-length?
constant-simulation-length?
0
1
-1000

BUTTON
239
55
398
88
burn down the grass
start-fire
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
238
143
397
176
remove bugs
remove-a-%-of-bugs
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
236
18
398
51
grass-to-burn-down
grass-to-burn-down
1
100
75.0
1
1
%
HORIZONTAL

SLIDER
238
109
396
142
bugs-to-remove
bugs-to-remove
1
100
50.0
1
1
%
HORIZONTAL

PLOT
5
412
246
558
Distribution of Bug Values
Selected Bug Value
# bugs
0.0
100.0
0.0
10.0
true
false
"" "set-histogram-num-bars 10\nif graph-values-for = \"energy of bugs\" [ \n       set-plot-x-range 0 100\n       histogram [ energy ] of bugs ]\n     if graph-values-for = \"age of bugs\" [  \n       set-plot-x-range 0 100\n       histogram [ current-age ] of bugs ]\n     if graph-values-for = \"# of offspring of bugs\" [ \n       set-plot-x-range 0 10\n       histogram [ #-offspring ] of bugs ]"
PENS
"default" 1.0 1 -16777216 true "" ""

CHOOSER
247
512
401
557
graph-values-for
graph-values-for
"energy of bugs" "age of bugs" "# of offspring of bugs"
0

MONITOR
247
464
321
509
bugs died
bugs-died
17
1
11

MONITOR
326
463
404
508
bugs born
bugs-born
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model explores the stability of consumer producer ecosystems and how temporary disturbances and more sustained environmental changes affect the stability of the population and the ecosystem.

## HOW IT WORKS

Bugs wander randomly around the landscape.  Each step each bug loses one unit of energy and they must consume a food source (grass) to replenish their energy. When they run out of energy, they die. To allow the population to continue, each bug must have enough energy to have an offspring.  When that threshold is reached, the offspring and parent split the energy amongst themselves.  Grass grows at a fixed rate, and when it is eaten, a fixed amount of grass energy is deducted from the patch (square) where the grass was eaten.

Different disturbances can be tested in this system, including temporary removal of grass (simulating a fire) and removal of some of the bugs (simulating disease).

## HOW TO USE IT

1. Adjust the slider parameters (see below), or use the default settings.
2. Press the SETUP button.
4. Press the GO button to begin the model run.
5. View the POPULATION SIZE VS. TIME plot to watch the bug and grass populations fluctuate over time
6. View the DISTRIBUTION OF BUG VALUES plot to watch how variation in energy levels, ages, or reproduction within in population changes over time.
7. View the BUGS DIED and BUGS BORN monitors to keep track of the total number of new bugs that have been born since the model run started and the number of bugs that have died.

Initial Settings:

CONSTANT-SIMULATION-LENGTH:  When turned "on" the model run will automatically stop at 1000 ticks.  When turned "off" the model run will continue without automatically stopping.

AMOUNT-OF-GRASSLAND: The percentage of patches in the world & view that produce grass.

INITIAL-NUMBER-BUGS: The initial size of bug population.

AMOUNT-OF-FOOD-BUGS-EAT:  Sets the amount of energy that a bugs gains from eating grass at a patch as well as the amount of energy deducted from that grass.

GRASS-TO-BURN-DOWN:  Sets the % of grassland patches that will have all their grass immediately removed when the BURN THE DOWN GRASS button is pressed. These patches will grow back grass with time.

BUGS-TO-REMOVE:  Sets the % of existing bug population that will be removed when the REMOVE BUGS button is pressed.

GRAPH-VALUES-FOR:  Sets the x-axis values of the bugs that are graphed in the DISTRIBUTION OF BUG VALUES histogram.  Options include "energy of the bugs", "age of the bugs", and "# of offspring of bugs".

## THINGS TO NOTICE

Watch as the grass and bug populations fluctuate.  How are increases and decreases in the sizes of each population related?

Pressing REMOVE BUGS or BURN THE GRASS DOWN affects the size of the populations in the short term, but not in the long term. What causes this behavior?

Different AMOUNT-OF-GRASSLAND values affect the carrying capacity (average values) for both the bugs and grass.  Why?

## THINGS TO TRY

Try adjusting the parameters under various settings. How sensitive is the stability of the model to the particular parameters.  Does the parameter setting affect the amount of fluctuations, the average values of bugs and grass, or does it lead to the collapse of the ecosystem (death of all the bugs)?

## EXTENDING THE MODEL

In this model, all the bugs are identical to each other and follow the same rules. Try modeling variation in the bug population that would make it easier for some bugs to get food.

Try extending the model by introducing a predator that eats the bugs, or a competing population that also eats grass.

## NETLOGO FEATURES

The visualization of fire embers uses the transparency value for the color to gradually fade out the color of the fire and let the background show through, before the embers disappear completely.

## RELATED MODELS

Wolf Sheep Predation and Rabbits Weeds Grass are other examples of interacting predator/prey populations with different rules.

Refer to Bug Hunt Predators for extensions of this model that include predators (birds that eat bugs) and an invasive species (another population of consumers).

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2011).  NetLogo Bug Hunt Consumers model.  http://ccl.northwestern.edu/netlogo/models/BugHuntConsumers.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Novak, M. -->
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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
0
@#$#@#$#@
