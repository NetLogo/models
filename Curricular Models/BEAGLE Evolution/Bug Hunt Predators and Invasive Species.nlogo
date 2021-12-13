globals
[
  birds-color     ;; color of birds
  bugs-color      ;; color of bugs
  grass-color     ;; color of patches/grass
  dirt-color      ;; color of areas that have no grass right now, but will grow grass back shortly
  invasive-color  ;; color of invaders
  bugs-stride     ;; how much a bug moves in each simulation step
  invaders-stride ;; how much an invader moves in each simulation step
  birds-stride    ;;  how much a bird moves in each simulation step
  bird-size       ;; size of birds
  bug-size        ;; size of bugs
  invader-size    ;; size of invaders

  bug-reproduce-age      ;;  min age of bugs before they can reproduce
  invader-reproduce-age  ;;  min age of invaders before they can reproduce
  bird-reproduce-age     ;;  min age of birds before they can reproduce
  max-bugs-age           ;;  max age of bugs before they automatically die
  max-birds-age          ;;  max age of birds before they automatically die
  max-invaders-age       ;;  max age of invaders before they automatically die

  birds-energy-gain-from-bugs     ;; how much energy birds gain from eating bugs
  birds-energy-gain-from-invaders ;; how much energy birds gain from eating invaders
  min-reproduce-energy-bugs       ;; energy required for reproduction by bugs
  min-reproduce-energy-invaders   ;; energy required for reproduction by invaders
  max-bugs-offspring              ;; maximum number of offspring per reproductive event for a bug
  max-birds-offspring             ;; maximum number of offspring per reproductive event for a bird
  max-invaders-offspring          ;; maximum number of offspring per reproductive event for an invader

  max-plant-energy                ;; maximum amount of energy a plant can "grow" to store in a patch
  sprout-delay-time               ;; delay time before a plant begins to grow back, after all of its foliage has been eaten
  plant-growth-rate               ;; amount of energy the plant stores as food per tick as it grows back
]

breed [ bugs bug ]
breed [ invaders invader ]
breed [ birds bird ]

breed [ disease-markers disease-marker ]  ;;  turtles that mark the location of where a bug was removed from disease.
breed [embers ember]  ;;  turtles that mark the location of the flames and embers of the fire.


turtles-own [ energy current-age max-age ]       ;; these three variables are used for bugs, invaders, and birds

;; fertile? are patches that can grow grass
;; plant-energy keeps track of the amount of food or foliage at that patch
;; countdown keeps track of how much longer until the sprout-delay-time has elapsed for this patch
patches-own [ fertile?  plant-energy  countdown]


to setup
  clear-all
  set max-plant-energy 100
  set plant-growth-rate 10
  set sprout-delay-time 25
  set bugs-stride 0.3
  set invaders-stride 0.3
  set birds-stride 0.4
  ;;  a larger birds-stride than bugs-stride leads to scenarios where less birds
  ;;  can keep a larger number of bugs in balance.
  set bug-reproduce-age 20
  set invader-reproduce-age 20
  set bird-reproduce-age 40
  set max-birds-age 100
  set max-invaders-age 100
  set max-bugs-age 100
  set birds-energy-gain-from-bugs 25
  set birds-energy-gain-from-invaders 25
  set min-reproduce-energy-bugs 10
  set min-reproduce-energy-invaders 10
  set max-bugs-offspring 3
  set max-invaders-offspring 3
  set max-birds-offspring 2
  set bird-size 2.5
  set bug-size 1.2
  set invader-size 1.5
  set birds-color  (red - 1)
  set bugs-color (violet)
  set invasive-color (blue - 3)
  set grass-color (green)
  set dirt-color (white)
  set-default-shape bugs "bug"
  set-default-shape birds "bird"
  set-default-shape invaders "mouse"
  add-starting-grass
  add-bugs
  add-birds
  reset-ticks
end


to go
  if ticks >= 1000 and constant-simulation-length? [ stop ]

  ask disease-markers [ age-disease-markers ]

  ask turtles [
    ;; we need invaders and bugs to eat at the same time
    ;; so one breed doesn't get all the tasty grass before
    ;; the others get a chance at it.
    (ifelse breed = bugs     [ bugs-live reproduce-bugs ]
            breed = invaders [ invaders-live reproduce-invaders ]
            breed = birds    [ birds-live reproduce-birds ]
                             [ ] ; anyone else doesn't do anything
    )
  ]

  ask patches [
    ;; only the fertile patches can grow grass
    set countdown random sprout-delay-time
    grow-grass
  ]

  tick
end

to remove-a-%-bugs
  let number-bugs count bugs
  ask n-of floor (number-bugs * %-of-bugs-to-remove / 100) bugs [
    hatch-disease-markers 1 [
     set current-age  0
     set size 1.5
     set color red
     set shape "x"
     ]
    die
  ]
end


to age-disease-markers
  set current-age (current-age  + 1)
  set size (1.5 - (1.5 * current-age  / 20))
  if current-age  > 25  or (ticks = 999 and constant-simulation-length?)  [die]
end


to start-fire
  ask patches [
    set countdown sprout-delay-time
    set plant-energy 0
    color-grass]
end


to add-starting-grass ;; setup patch procedure to add grass based on initial settings
  let number-patches-with-grass (floor (amount-of-grassland * (count patches) / 100))
  ask patches [
      set fertile? false
      set plant-energy 0
    ]
  ask n-of number-patches-with-grass patches  [
      set fertile? true
      set plant-energy max-plant-energy / 2;; (max-plant-energy - random max-plant-energy)
    ]
  ask patches [color-grass]
end

to add-bugs ;; setup bugs procedure to add bugs based on initial settings
  create-bugs initial-number-bugs [  ;; create the bugs, then initialize their variables
    set color bugs-color
    set energy 20 + random 20 - random 20        ;;randomize starting energies
    set current-age 0  + random max-bugs-age     ;;don't start out with everyone at the same age
    set max-age max-bugs-age
    set size bug-size
    setxy random world-width random world-height
  ]
end

to add-birds ;; setup birds procedure
  create-birds initial-number-birds  ;; create the bugs, then initialize their variables
  [
    set color birds-color
    set energy 40 + random 40 - random 40         ;;randomize starting energies
    set current-age 0  + random max-birds-age     ;;don't start out with everyone at the same age
    set max-age max-birds-age
    set size bird-size
    setxy random world-width random world-height
  ]
end

to add-invaders
  create-invaders number-invaders-to-add ;; create the bugs, then initialize their variables
  [
    set color invasive-color
    set energy 20 + random 20 - random 20            ;;randomize starting energies
    set current-age 0  + random max-invaders-age     ;;don't start out with everyone at the same age
    set max-age max-invaders-age
    set size invader-size
    setxy random world-width random world-height
   ]
end

to bugs-live ;; bugs procedure
    move-bugs
    set energy (energy - 1)  ;; bugs lose energy as they move
    set current-age (current-age + 1)
    bugs-eat-grass
    death
end

to birds-live ;; birds procedure
  move-birds
  set energy (energy - 1)  ;; birds lose energy as they move
  set current-age (current-age + 1)
  birds-eat-prey
  death
end

to invaders-live ;; invaders procedure
    move-invaders
    set energy (energy - 1)  ;; invaders lose energy as they move
    set current-age (current-age + 1)
    invaders-eat-grass
    death
end

to move-bugs  ;; bugs procedure
  rt random 50 - random 50
  fd bugs-stride
end

to move-birds  ;; birds procedure
  rt random 50 - random 50
  fd birds-stride
end

to move-invaders  ;; invaders procedure
  rt random 40 - random 40
  fd invaders-stride
end

to bugs-eat-grass  ;; bugs procedure
  ;; if there is enough grass to eat at this patch, the bugs eat it
  ;; and then gain energy from it.
  if plant-energy > amount-of-food-bugs-eat [
    ;; plants lose ten times as much energy as the bugs gains (trophic level assumption)
    set plant-energy (plant-energy - (amount-of-food-bugs-eat * 10))
    set energy (energy + amount-of-food-bugs-eat)  ;; bugs gain energy by eating
  ]
  ;; if plant-energy is negative, make it positive
  if plant-energy <=  amount-of-food-bugs-eat  [set plant-energy 0]
end


to invaders-eat-grass  ;; invaders procedure
  ;; if there is enough grass to eat at this patch, the invaders eat it
  ;; and then gain energy from it.
  if plant-energy > amount-of-food-invaders-eat  [
    ;; plants lose 10 * as much energy as the invader gains (trophic level assumption)
    set plant-energy (plant-energy - (amount-of-food-invaders-eat * 10))
    set energy energy + amount-of-food-invaders-eat  ;; bugs gain energy by eating
  ]
  ;; if plant-energy is negative, make it positive
  if plant-energy <=  amount-of-food-invaders-eat  [set plant-energy 0]
end



to birds-eat-prey  ;; birds procedure
    if (any? bugs-here and not any? invaders-here)
        [ask one-of  bugs-here
          [die]
           set energy (energy + birds-energy-gain-from-bugs)
         ]
      if (any? invaders-here and not any? bugs-here)
        [ask one-of  invaders-here
          [die]
           set energy (energy + birds-energy-gain-from-invaders)
         ]
      if (any? invaders-here and any? bugs-here)
        [ifelse random 2 = 0   ;; 50/50 chance to eat an invader or a bug if both are on this patch
           [ask one-of  invaders-here
             [die]
             set energy (energy + birds-energy-gain-from-invaders)
             ]
           [ask one-of  bugs-here
             [die]
             set energy (energy + birds-energy-gain-from-bugs)
             ]
         ]
end


to reproduce-bugs  ;; bugs procedure
  let number-offspring (random (max-bugs-offspring + 1)) ;; set number of potential offspring from 1 to (max-bugs-offspring)
  if (energy > ((number-offspring + 1) * min-reproduce-energy-bugs)  and current-age > bug-reproduce-age)
  [
    if random 2 = 1           ;;only half of the fertile bugs reproduce (gender)
    [
      set energy (energy - (number-offspring  * min-reproduce-energy-invaders)) ;;lose energy when reproducing- given to children
      hatch number-offspring
      [
        set size bug-size
        set color bugs-color
        set energy min-reproduce-energy-bugs ;; split remaining half of energy amongst litter
        set current-age 0
        rt random 360 fd bugs-stride
      ]    ;; hatch an offspring set it heading off in a random direction and move it forward a step
    ]
  ]
end


to reproduce-invaders  ;; bugs procedure
  let number-offspring (random (max-invaders-offspring + 1)) ;; set number of potential offspring from 1 to (max-invaders-offspring)
  if (energy > ((number-offspring + 1) *  min-reproduce-energy-invaders)  and current-age > invader-reproduce-age)
  [
    if random 2 = 1           ;;only half of the fertile invaders reproduce (gender)
    [
      set energy (energy - ( number-offspring * min-reproduce-energy-invaders))  ;;lose energy when reproducing - given to children
      hatch number-offspring
      [
        set size invader-size
        set color invasive-color
        set energy min-reproduce-energy-invaders ;; split remaining half of energy amongst litter
        set current-age 0
        rt random 360 fd invaders-stride
      ]    ;; hatch an offspring set it heading off in a random direction and move it forward a step
    ]
  ]
end


to reproduce-birds  ;; bugs procedure
  let number-offspring (random (max-birds-offspring + 1)) ;; set number of potential offspring from 1 to (max-invaders-offspring)
  if (energy > ((number-offspring + 1) * min-reproduce-energy-birds)  and current-age > bird-reproduce-age)
  [
    if random 2 = 1           ;;only half of the fertile bugs reproduce (gender)
    [
      set energy (energy - (number-offspring * min-reproduce-energy-birds)) ;;lose energy when reproducing - given to children
      hatch number-offspring
      [
        set current-age 0
        set size bird-size
        set color birds-color
        set energy min-reproduce-energy-birds ;; split remaining half of energy amongst litter
        set current-age 0
        rt random 360 fd birds-stride
      ]    ;; hatch an offspring set it heading off in a random direction and move it forward a step
    ]
  ]
end


to death  ;; common procedure for bugs, birds & invaders to die
  ;; die when energy dips below zero (starvation), or get too old
  if (current-age > max-age) or (energy < 0)
  [ die ]

end

to grow-grass  ;; patch procedure
  set countdown (countdown - 1)
  ;; fertile patches gain 1 energy unit per turn, up to a maximum max-plant-energy threshold
  if fertile? and countdown <= 0
     [set plant-energy (plant-energy + plant-growth-rate)
       if plant-energy > max-plant-energy [set plant-energy max-plant-energy]]
  if not fertile?
     [set plant-energy 0]
  if plant-energy < 0 [set plant-energy 0 set countdown sprout-delay-time]
  color-grass
end

to color-grass ;; patch procedure
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
411
10
929
529
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

SLIDER
4
161
213
194
initial-number-birds
initial-number-birds
0
200
30.0
1
1
NIL
HORIZONTAL

BUTTON
19
13
107
46
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
111
13
203
46
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
7
330
411
548
populations
ticks
populations
0.0
1000.0
0.0
200.0
true
true
"" ""
PENS
"bugs" 1.0 0 -8630108 true "" "plot count bugs"
"birds" 1.0 0 -2674135 true "" "plot count birds"
"invaders" 1.0 0 -16777216 true "" "plot count invaders"
"grass" 1.0 0 -10899396 true "" "plot (sum [plant-energy] of patches / max-plant-energy)"

MONITOR
7
281
71
326
bugs
count bugs
3
1
11

MONITOR
71
281
136
326
birds
count birds
3
1
11

SLIDER
4
126
215
159
initial-number-bugs
initial-number-bugs
0
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
4
90
216
123
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
207
207
406
240
number-invaders-to-add
number-invaders-to-add
0
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
244
283
391
316
launch an invasion
add-invaders
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
137
281
206
326
invaders
count invaders
0
1
11

SLIDER
205
242
409
275
amount-of-food-invaders-eat
amount-of-food-invaders-eat
0
8
4.0
.1
1
NIL
HORIZONTAL

SLIDER
1
241
203
274
amount-of-food-bugs-eat
amount-of-food-bugs-eat
0.1
8
4.0
.1
1
NIL
HORIZONTAL

SWITCH
3
54
215
87
constant-simulation-length?
constant-simulation-length?
0
1
-1000

BUTTON
228
10
402
43
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
226
83
403
116
remove bugs
remove-a-%-bugs
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
3
207
204
240
min-reproduce-energy-birds
min-reproduce-energy-birds
1
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
226
118
405
151
%-of-bugs-to-remove
%-of-bugs-to-remove
1
100
54.0
1
1
%
HORIZONTAL

SLIDER
227
46
404
79
%-of-grass-to-burn
%-of-grass-to-burn
1
100
50.0
1
1
%
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model explores the stability of predator-prey ecosystems and how that stability is affected when new species are introduced into the ecosystem.

## HOW IT WORKS

Birds and bugs wander randomly around the landscape.  Each step costs both animals energy and they must consume a food source (bugs must eat grass and birds must eat bugs & the invaders) to replenish their energy - when they run out of energy they die. To allow the population to continue, each bird or bug must have enough energy to have a litter of offspring and the offspring and parent split the energy amongst themselves.  Grass grows at a fixed rate, and when it is eaten, a fixed amount of grass energy is deducted from the patch (square) where the grass was eaten.

Invasive species (mice) can be introduced to this ecosystem as well.  The mice are indirect competitors of the bugs.  They also eat grass.  They reproduce following the same rules as bugs.  The eating behavior of the mice and the bugs can be adjusted.

Other disruptions such as removing a portion of the bug population (simulating a disease) or burning down the grass (removing the food source for bugs and invasive species temporarily) can also be tested to see how these disruptions affect the stability of the ecosystem.

## HOW TO USE IT

1. Adjust the slider parameters (see below), or use the default settings.
2. Press the SETUP button.
4. Press the GO button to begin the simulation.
5. View the POPULATIONS plot to watch the populations fluctuate over time.
6. View the birds/bugs and invaders monitors to view current population sizes.
7. Adjust the NUMBER-INVADERS-TO-ADD and AMOUNT-OF-FOOD-INVADERS-EAT and press LAUNCH INVASION.
8. View the POPULATIONS plot to watch the populations fluctuate over time.

Initial Settings:

CONSTANT-SIMULATION-LENGTH:  When turned "on" the model run will automatically stop at 2500 ticks.  When turned "off" the model run will continue without automatically stopping.
AMOUNT-OF-GRASSLAND: The percentage of patches in the world & view that produce grass.
INITIAL-NUMBER-BUGS: The initial size of the bug population.
INITIAL-NUMBER-BIRDS: The initial size of the bird population.
AMOUNT-OF-FOOD-BUGS-EAT: The amount of grass consumed at each simulation step by each one of the bugs.
MIN-REPRODUCE-ENERGY-BIRDS:  The amount of energy required for a bird to accumulate before it automatically produces an offspring.

Other Settings:

GRASS-TO-BURN-DOWN:  Sets the % of designated grassland patches that will have all their grass immediately removed when the BURN THE DOWN GRASS button is pressed.
%-OF-BUGS-TO-REMOVE:  Sets the % of existing bug population that will be immediately removed when the REMOVE BUGS button is pressed.

NUMBER-INVADERS-TO-ADD: The number of the invasive species introduced when LAUNCH INVASION is pressed.
AMOUNT-OF-FOOD-INVADERS-EAT: The amount of grass consumed at each simulation step by each one of the invasive species.

## THINGS TO NOTICE

Watch as the grass, predators, and bug populations fluctuate.  How are increases and decreases in the sizes of each population related?

How does changing the attributes of the bugs (AMOUNT-OF-FOOD-BUGS-EAT) or birds (MIN-REPRODUCE-ENERGY-BUGS) affect the stability and carrying capacity of the ecosystem?

How does introducing an invasive species that has the same diet as the bugs (i.e. grass) affect the stability of the ecosystem?  How does setting the AMOUNT-OF-FOOD-INVADERS-EAT to a different value than AMOUNT-OF-FOOD-BUGS-EAT affect the stability of each population in the ecosystem?

## THINGS TO TRY

Try adjusting the parameters under various settings. How sensitive is the stability of the model to the particular parameters.  Does the parameter setting affect the amount of fluctuations, the average values of each population, or does it lead to the collapse of one of the populations in the ecosystem (death of all the bugs, birds, or invasive species)?

## EXTENDING THE MODEL

Additional invasive plant or invasive predator could be added.

The amount of food a predator or a bug eats could be adjusted so that faster food consumption also corresponds to higher metabolism (cost of energy per move per turn), so that there is a competitive disadvantage for rapid food consumption in some environments.

Traits such as amount of food a predator eats, or min-reproduction energy could be inherited in offspring and subject to slight random changes from mutations.

## NETLOGO FEATURES

scale-color is used to visualize the amount of food (energy) available for bugs or invaders at each patch.  A whitish green (color of 59.9) is used to represent little grass foliage (not much food available at this patch) and green (color of 55) is used to represents lots of foliage (max. food available at this patch).  All other values for food plant-energy are linearly scaled between this range of colors.

## RELATED MODELS

Look at the Wolf-Sheep model for a basic predator prey model example.

Look at Bug Hunt Consumers for a simpler version of this model that includes no predators or invaders.

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2011).  NetLogo Bug Hunt Predators and Invasive Species model.  http://ccl.northwestern.edu/netlogo/models/BugHuntPredatorsandInvasiveSpecies.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

aphid
true
0
Circle -7500403 true true 129 84 42
Circle -7500403 true true 96 126 108

aphid-with-parasite
true
0
Circle -7500403 true true 129 84 42
Circle -7500403 true true 96 126 108
Circle -2674135 false false 8 8 285

bird
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

bug
true
0
Circle -7500403 true true 75 116 150
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

egg
true
0
Circle -1 true false 120 95 60
Circle -1 true false 105 142 90
Polygon -1 true false 195 180 180 120 120 120 105 180

fox
false
0
Polygon -7500403 true true 72 225 94 249 109 252 119 252 111 242 99 241 87 225 91 181 62 112 43 119 28 150 29 164 58 204 50 241 74 271 84 279 99 279 98 267 87 266 67 242
Polygon -7500403 true true 210 90 204 56 214 42 222 66 211 71
Polygon -7500403 true true 181 107 213 70 226 63 257 71 260 90 300 120 289 129 249 110 218 135 209 151 204 164 192 179 169 186 154 190 129 190 89 181 69 167 60 112 124 111 160 112 170 105
Polygon -6459832 true false 252 143 242 141
Polygon -6459832 true false 254 136 232 137
Line -16777216 false 80 159 89 179
Polygon -6459832 true false 262 138 234 149
Polygon -7500403 true true 50 121 36 119 24 123 14 128 6 143 8 165 8 181 7 197 4 233 23 201 28 184 30 169 28 153 48 145
Polygon -7500403 true true 171 181 178 263 187 277 197 273 202 267 187 260 186 236 194 167
Polygon -7500403 true true 223 75 226 58 245 44 244 68 233 73
Line -16777216 false 89 181 112 185
Line -16777216 false 31 150 41 130
Polygon -16777216 true false 230 67 228 54 222 62 224 72
Line -16777216 false 30 150 30 165
Circle -1184463 true false 225 76 22
Polygon -7500403 true true 225 121 258 150 267 146 236 112

fox3
false
3
Polygon -6459832 true true 90 105 75 81 60 75 44 83 36 98 38 120 38 136 37 152 15 180 53 156 58 139 60 124 58 108 90 120
Polygon -6459832 true true 196 106 228 69 240 60 263 63 275 89 300 110 285 135 240 120 233 134 225 150 225 165 207 178 184 185 169 189 144 189 104 180 84 166 78 113 139 110 175 111 185 104
Polygon -6459832 true true 252 143 242 141
Polygon -6459832 true true 254 136 232 137
Polygon -6459832 true true 262 138 234 149
Polygon -6459832 true true 195 165 180 210 143 247 144 263 159 267 164 253 195 225 225 165
Polygon -6459832 true true 238 75 240 45 255 30 259 68 248 73
Polygon -16777216 true false 285 135 297 116 285 111
Polygon -6459832 true true 135 210 151 181 119 165 105 165 73 184 31 183 -9 205 -9 226 6 231 7 214 38 198 75 225 120 210
Polygon -6459832 true true 218 80 203 50 233 65
Polygon -6459832 true true 195 180 240 210 270 240 293 246 297 231 283 226 240 180 210 165
Polygon -6459832 true true 94 112 76 119 60 151 60 165 79 197 78 239 100 279 121 279 126 264 109 263 93 232 120 195 105 150

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

mouse
false
0
Polygon -7500403 true true 38 162 24 165 19 174 22 192 47 213 90 225 135 230 161 240 178 262 150 246 117 238 73 232 36 220 11 196 7 171 15 153 37 146 46 145
Polygon -7500403 true true 289 142 271 165 237 164 217 185 235 192 254 192 259 199 245 200 248 203 226 199 200 194 155 195 122 185 84 187 91 195 82 192 83 201 72 190 67 199 62 185 46 183 36 165 40 134 57 115 74 106 60 109 90 97 112 94 92 93 130 86 154 88 134 81 183 90 197 94 183 86 212 95 211 88 224 83 235 88 248 97 246 90 257 107 255 97 270 120
Polygon -16777216 true false 234 100 220 96 210 100 214 111 228 116 239 115
Circle -16777216 true false 246 117 20
Line -7500403 true 270 153 282 174
Line -7500403 true 272 153 255 173
Line -7500403 true 269 156 268 177

rabbit
false
4
Polygon -1184463 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -1184463 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -1184463 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -1184463 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 29 110 32
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -7500403 false 165 180 180 165
Line -7500403 false 180 165 225 165

wasp
true
0
Polygon -1184463 true false 195 135 105 135 90 150 90 210 105 255 135 285 165 285 195 255 210 210 210 150 195 135
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 135 105 120 105 60 120 45 180 45 195 60 195 120 180 135
Polygon -6459832 true false 150 0 120 15 120 45 180 45 180 15
Circle -16777216 true false 105 15 30
Circle -16777216 true false 165 15 30
Polygon -7500403 true true 180 75 270 90 300 150 300 210 285 210 255 195 210 120 180 90
Polygon -16777216 true false 135 300 165 300 165 285 135 285
Polygon -7500403 true true 120 75 30 90 0 150 0 210 15 210 45 195 90 120 120 90

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
