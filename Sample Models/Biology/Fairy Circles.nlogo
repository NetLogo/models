; Termite colonies and termites are both breeds of turtles.
breed [ colonies colony ]
breed [ termites termite ]

globals [ grow-rate ] ; keeps track of the rate all grasses should grow

colonies-own [
  energy
] ; colonies have energy and a number of termites

termites-own [
  home-colony
  has-food?
  termite-energy
  lifetime-left
] ; termites have a home colony, keep track of if they are carrying food, energy, and a lifetime countdown.

patches-own [
  root-depth
  moisture
  alive?
] ; patches have both an amount of root depth and moisture. Patches can either be alive or not.

to setup
  clear-all
  set grow-rate 1

  ; set root-depth in patches, set as alive, and recolor based on root-depth, set moisture evenly across world
  ask patches [
    set root-depth max-root-depth
    set alive? true
    set moisture max-moisture-in-soil / 2
    color-grass
  ]

  ; create colonies based on slider, set shape, color, and move to a patch
  create-colonies initial-number-of-colonies [
    set shape "circle"
    set color 123
    move-to one-of patches with [not any? colonies-here]
    set size 2
  ]

  ; colonies hatch termites and sets that colony as home, termites are given a life-time based on slider
  ask colonies [
    hatch-termites 10 [
      set shape "ant"
      set color 53
      set home-colony myself
      set has-food? false
      set size 1
      set lifetime-left termite-lifetime
    ]
  ]
  reset-ticks
end

to go
  ; termites without food wander until they reach roots
  ask termites with [not has-food?] [
    find-food
  ]

  ; if termites have food, turn back to home
  ask termites with [has-food?] [
    return-to-colony
  ]

  ; if a termite runs into one from another colony, fight.
  ask termites [
    fight-competitor
  ]

  ; based on energy, colonies create new termites or a new colony.
  ask colonies [
    colony-death
    hatch-new-termites
    hatch-new-colony
  ]
  ; grasses absorb water, spread, and can die
  ask patches with [ alive? = True ] [
    absorb-water
    sprout-new-growth
    wither
  ]

  ask patches [
    rain
  ]

  ; diffuse water in soil
  diffuse moisture .5
  tick
end

; this is a termite procedure
to find-food
  ; termites without food move randomly
  rt random 90
  lt random 90
  fd 1

  ; if patch under termite has root-depth, termites have food
  if root-depth > 0 [
    set root-depth root-depth - energy-gain-from-roots
    set has-food? true
  ]

  ; reduce the life of termites , die if lifetime < 0
  set lifetime-left lifetime-left - random 10
  if lifetime-left <= 0 [
    die
  ]
end

; this is a termite procedure
to return-to-colony
  face home-colony
  fd 1
  set lifetime-left lifetime-left - random 10

  ; when termite reaches home, give energy to colony, termite no longer has food, randomly set heading
  if [member? self [colonies-here] of myself] of home-colony  [
    ask home-colony [ set energy energy + energy-gain-from-roots ]
    set has-food? false
    set heading random 360
  ]

  ; when termites have food, termites lose less life (eating)
  if lifetime-left <= 0 [ die ]
end

; this is a termite procedure.
to fight-competitor
  if termite-aggression > 0 [
    let my-competitors other termites-here in-radius termite-aggression with [ home-colony != [home-colony] of myself ]
    ; if termite aggression is greater than 0 and they have another termite in their area from a different colony,
    ; they identify them as competitors and fight them
    if any? my-competitors [
      ; ifelse random 2 = 0 [
      ;one of the termites will randomly die
      ifelse random 2 = 0 [
        ask one-of my-competitors [ die ]
      ]
      [
        die
      ]
    ]
  ]
end

; this is a colony procedure
to colony-death
  ; colonies die if there are no termites left
  let resident-termites count termites with [home-colony = myself]
  if resident-termites = 0 [ die ]
end

; this is a colony procedure
to hatch-new-termites

  let resident-termites count termites with [home-colony = myself]

  if resident-termites < population-to-hatch-new-colony [

    ; if colonies have enough energy, hatch new termite
    if energy > energy-needed-for-new-termite [
      hatch-termites 1 [
        set shape "ant"
        set color 53
        set home-colony myself
        set has-food? false
        set size 1
        set label ""
        set lifetime-left termite-lifetime
      ]
      set energy 0
    ]
  ]
end

; this is a colony procedure
to hatch-new-colony
  let resident-termites count termites with [home-colony = myself]

  if resident-termites >= population-to-hatch-new-colony [

    ; if have enough energy and reach the population cap, create a new colony, set energy to 0 in original colony
    if energy > energy-needed-for-new-termite  [
      set energy 0

      hatch-colonies 1 [
        set shape "circle"
        set color 123
        move-to one-of patches with [not any? colonies-here ]
        set size 2
        ; new colony hatches 10 termites
        hatch-termites 10 [
          set shape "ant"
          set color 53
          set home-colony myself
          set has-food? false
          set size 1
          set label ""
          set lifetime-left termite-lifetime
        ]
      ]
    ]
  ]
end

; this is a grass procedure
to absorb-water
  ; each patch takes moisture from soil based on constant + 1/10th of root depth
  let moisture-needed 1 + (root-depth / 10)

  ifelse moisture >= moisture-needed  [
    ; if moisture, grow
    set moisture moisture - moisture-needed
    set root-depth root-depth + 1
  ][
    ; if not enough moisture shrink
    set root-depth root-depth - moisture-needed
  ]
  ; roots cannot grow more than the max root depth
  if root-depth >= max-root-depth [
    set root-depth max-root-depth
  ]
end

; this is a grass procedure
to sprout-new-growth
  ; if root-depth reaches max and there is a dead patch near it, spread into new patch
  if root-depth > max-root-depth * .75 [
    if any? neighbors with [ alive? = False ] [
      ask one-of  neighbors with [ not alive? ] [
        set alive? true
        color-grass
        set root-depth max-root-depth / 10
      ]
    ]
  ]
end

; this is a grass procedure
to wither
  ; if root-depth is zero, die, color brown
  ifelse root-depth <= 0 [
    set pcolor brown
    set alive? False
    set root-depth 0
  ][
    color-grass
  ]
end

; this is a patch procedure.
to rain
  ; if the patch is not at max moisture rate, increase the moisture by the rain rate.
  if moisture < max-moisture-in-soil [
    set moisture moisture + rain-rate
    if moisture > max-moisture-in-soil [
      set moisture max-moisture-in-soil
    ]
  ]
end

; this is a grass procedure. Recolor grass based on root-depth
to color-grass
  set pcolor (scale-color green root-depth -20 140)
end


; Copyright 2017 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
270
15
888
634
-1
-1
10.0
1
16
1
1
1
0
1
1
1
-30
30
-30
30
1
1
1
ticks
30.0

BUTTON
70
90
136
124
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
153
90
217
124
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
30
30
250
63
initial-number-of-colonies
initial-number-of-colonies
1
30
11.0
1
1
NIL
HORIZONTAL

SLIDER
25
405
250
438
max-root-depth
max-root-depth
20
100
70.0
1
1
NIL
HORIZONTAL

SLIDER
26
153
248
186
energy-gain-from-roots
energy-gain-from-roots
1
max-root-depth
31.0
1
1
NIL
HORIZONTAL

SLIDER
25
203
248
236
energy-needed-for-new-termite
energy-needed-for-new-termite
1
90
28.0
1
1
NIL
HORIZONTAL

SLIDER
25
355
250
388
population-to-hatch-new-colony
population-to-hatch-new-colony
10
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
25
455
252
488
max-moisture-in-soil
max-moisture-in-soil
1
100
41.0
1
1
NIL
HORIZONTAL

SLIDER
25
505
251
538
rain-rate
rain-rate
0
10
3.5
0.1
1
NIL
HORIZONTAL

PLOT
895
75
1095
215
Colony Count
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
"default" 1.0 0 -7858858 true "" "plot count colonies"

PLOT
895
355
1095
495
Root Depth Distribution
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
"default" 1.0 1 -8431303 true "" "histogram [ root-depth ] of patches "

PLOT
895
495
1095
635
Soil Moisture Distribution
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
"default" 1.0 1 -14070903 true "" "histogram [ moisture ] of patches"

SLIDER
25
255
249
288
termite-lifetime
termite-lifetime
0
200
133.0
1
1
NIL
HORIZONTAL

MONITOR
900
15
990
60
Dead Grasses
count patches with [ not alive? ]
17
1
11

SLIDER
25
305
250
338
termite-aggression
termite-aggression
0
12
9.0
1
1
NIL
HORIZONTAL

PLOT
895
215
1095
355
Fighting Termites
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
"default" 1.0 0 -15040220 true "" "plot count termites with [ any? other termites-here in-radius termite-aggression with [ home-colony != [home-colony] of myself ] ]"

@#$#@#$#@
## WHAT IS IT?

This model is inspired by the natural phenomenon, Fairy Circles, which can be observed in the Namib Desert in Namibia. In the real world, rings of healthy grasses with barren centers form in geometric configurations across the desert plains. These rings, with life cycles of 30-40 years, have been studied by biologists for years.

This model is based on the recent theory proposed by [Tarnita and colleagues in 2017](https://www.nature.com/articles/nature20801). Fairy circles are formed and maintained through a multi-factor process. Subterranean termites create colonies, expand, and compete when they reach a neighboring colony. These termites eat the roots of the grasses surrounding their colonies. As they create colonies and eat grasses, the soil at their colonies becomes more porous and collects water. Grasses around the colonies compete for water. The grasses closer to the colony have more consistent access to water and become healthier. With this interaction of intraspecies competition, fairy circles form and are maintained.

## HOW IT WORKS

This model creates a number of termite colonies that spawn termites. At each clock tick, termites randomly wander. If they find roots, termites will collect some of the roots and reorient towards the colony. Termites with roots take a step towards their home colony at each tick. When they reach the colony, the colony gains energy and the termite will go back to wandering. Termites die when they have reached the TERMITE-LIFETIME count. If a termite runs into a termite from another colony, they will fight and one will die.

Colonies create new termites as they gain energy. When the colony has reached a peak size and has enough energy, it will hatch a new colony in the world. Termite colonies die if all the termites are gone.

Grasses increase their root depth as they grow. They need water to maintain their growth. Grasses get water from the moisture in the soil. If grasses do not have enough water, they shrink and die if they have no roots.

## HOW TO USE IT

1. Set the INITIAL-NUMBER-OF-COLONIES.
2. Press the SETUP button.
3. Press the GO button.
4. Remaining slider parameters (see below) can be adjusted while the model is running.
5. Look at monitors to see the number of termites that are currently fighting or the number of grasses that have died.
6.  Look at the plots to see the distribution of root depth and soil moisture, or the number of colonies in the world.

### Parameters
INITIAL-NUMBER-OF-COLONIES: The initial number of termite colonies.
ENERGY-GAIN-FROM-GRASS: The amount of energy termite colonies get from grass roots.
POPULATION-NEEDED-TO-HATCH-NEW-COLONY: The amount of termites in a colony needed to create a new colony.
TERMITE-LIFETIME: The number of ticks a termite lives.
TERMITE-AGGRESSION: The range that termites will see and fight termites from another colony.
MAX-ROOT-DEPTH: The maximum depth grasses will grow.
MAX-MOISTURE-IN-SOIL: The maximum water the soil will hold.
RAIN-RATE: The amount of rain water hitting a patch at each tick.

Notes:
- Termites lose one unit of life at each tick.
- In order for plants to survive and grow, they require a base amount of water plus a proportion of water based on their root depth.

### Plots and Monitors

DEAD GRASSES: monitors the number of patches that have dead grasses
COLONY COUNT: plots the number of termite colonies present
FIGHTING TERMITES: plots the number of termites that have seen a termite from another colony.
ROOT DEPTH DISTRIBUTION: plots the distribution of root depth across all patches
SOIL MOISTURE DISTRIBUTION: plots the distribution of soil moisture across all patches

### Visualization

In this world, termite colonies are represented as magenta circles. Each colony as an initial number of green termites, a population that increases over time. While each patch is associated with both grasses and accumulated soil moisture, patches are colored to reflect the state of grasses in the world. Brown patches are those with dead grass. Green patches are those with living grass. The shade of green reflects the size of grasses. Grasses that are lighter greed have longer roots than those that are darker green.

With this representation, the focus is on the aggregate level interactions between termite colonies and grasses. As such, the termites are visualized in green to background their behavior in the model.

## THINGS TO NOTICE

Can you identify when Fairy Circles emerge in the model?  Notice where dead patches emerge in the model versus where grasses stay alive. Where do you see the healthiest grasses with the longest roots? Is this related to how water is distributed across the patches?

Why do some termite colonies appear better at gathering food around them? Which termite or colony related parameters affect this?

Watch the patterns of termite colonies emerge.  When are new colonies successful and when do they fail?

Observe the root depth of grasses in the model. Is there a relationship between soil moisture and root depth?  Observe what happens When you change the parameters related to moisture (MAX-MOISTURE-IN-SOIL, RAIN-RATE).

Why do you suppose that some variations of the model might be stable while others are not?

## THINGS TO TRY

Increase and decrease the RAIN-RATE in the model and observe the outcome in the model. How does rain impact the development of Fairy Circles? Vary the MAX-MOISTURE-IN-SOIL, does this change the impact of rain-rate in the world?

How does the MAX-ROOT-DEPTH change the size or pattern of fairy circles? Explore this parameter within the world.

Explore termite aggression in the world. How does termite aggression affect the development of Fairy Circles?

Can you find parameters that cause all termite colonies to die?

This model simplifies the naturally observed phenomenon through assumptions like how termites fight, grasses grow, or how/when it rains in the model. Can you look through the code tab to find and modify one of these assumptions to reflect your understanding of the system?

## EXTENDING THE MODEL

Can you extend the model to add in soil porosity?

Can you extend the model by making the intraspecies competition a switch that could be turned on and off?

Can you extend the model by adding in seasonality that affects the rain rate?

## RELATED MODELS

* Termites

## CREDITS AND REFERENCES

This model was inspired by the journal article:

Tarnita, C. E., Bonachela, J. A., Sheffer, E., Guyton, J. A., Coverdale, T. C., Long, R. A., & Pringle, R. M. (2017). A theoretical foundation for multi-scale regular vegetation patterns. Nature, 541(7637), 398-401.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Anton, G. and Wilensky, U. (2017).  NetLogo Fairy Circles model.  http://ccl.northwestern.edu/netlogo/models/FairyCircles.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2017 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2017 Cite: Anton, G. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

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
