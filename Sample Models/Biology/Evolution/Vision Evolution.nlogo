breed [fov  a-fov]      ; Field of View breed for visualization
breed [food a-food]     ; Invertebrate organisms that are preyed upon
breed [fish a-fish]     ; Vertebrates about to make the leap to terrestrial life

fish-own [
  eye-size              ; Size of the eye determines the size of the vision radius (between 1 and max-eye-size)
  land-mobility         ; Determines how fast and efficiently the organism can move on land (between 0 and 1)
  land-food-preference  ; Each fish has a preference towards food on land vs food in water (between 0 and 1)
  energy                ; Each fish has an energy level
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; SETUP PROCEDURES ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  ; Half the world is water, and the other half is land
  ask patches [
    ifelse (pycor <= 0)
    [ set pcolor blue ]
    [ set pcolor brown ]
  ]

  ; Fish has a 360 vision
  set-default-shape fov "circle"

  set-default-shape food "circle"
  create-food initial-number-food [
    ; create the food, then initialize their variables
    set color black
    set size 1
    setxy random-xcor random-ycor
  ]

  set-default-shape fish "fish"
  create-fish initial-number-fish [
    ; create the fish, then initialize their variables
    set size 3.5
    set energy random-float (2 * energy-gain-from-food)
    set eye-size 1                           ; Initially have the smallest eye size
    set land-mobility 0                      ; Initially adapted to move under water
    set land-food-preference random-float 1  ; Random preference for food on land vs water
    setxy random-xcor -1 * random max-pycor  ; Initially underwater
    ; The shade of its color represents the land-mobility value of the fish
    set color scale-color red land-mobility 2.5 -1
  ]

  ask fish [ produce-fov ] ; For visualization

  reset-ticks
end


to produce-fov
  ; Each fish has a fov turtle tied to it
  let rad eye-size
  hatch-fov 1 [
    set color fov-color
    set size (rad-size rad) * 2
    create-link-from myself [ tie ]
  ]
end


to-report fov-color
  ; Sets the transparency of the fov
  let transparency ifelse-value show-vision?
    [ [155 155 155 50] ]
    [ [155 155 155 0] ]
  report transparency
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; GO PROCEDURES ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  if not any? fish [ stop ]

  ask fish [
    move
    consume-energy
    eat-food
    death
    reproduce
  ]
  replenish-food

  tick
end


to move
  ; Determine the step size based on the land-mobility parameter
  let step-size ifelse-value ycor < 0 [ 1 - land-mobility ] [ land-mobility ]
  ; Add a random element so that fish can make some progress on land even when land-mobility is 0
  set step-size step-size + random-float 0.1

  let radius rad-size eye-size
  let weight land-food-preference

  ; Choose the closest target based on preference
  let prey min-one-of (food in-radius radius) [ weighted-distance weight ]

  ifelse prey != nobody [
    ; If there's a prey in its field of vision, go towards it
    face prey
    ifelse distance prey < step-size [
      move-to prey
    ] [
      fd step-size
    ]
  ] [
    ; Else move randomly
    rt random 50
    lt random 50
    ; Prevents the fish from getting stuck at a border
    ifelse can-move? step-size ; Checks if a fish is headed to a border
      [ fd step-size ]         ; If not, continue forward
      [ lt random-float 180    ; If so, turn a random amount again
        fd step-size ]
  ]

  ; Changes the size of the field of vision if it steps on land
  ask out-link-neighbors [
    set size 2 * radius
    set color fov-color
  ]
end

to consume-energy
  ; Moving consumes energy, organisms adapted to water consume more energy on land
  ifelse ycor < 0
    [ set energy energy - abs(land-mobility * 10 - 0.5) ]
    [ set energy energy - abs((1 - land-mobility) * 10 - 0.5) ]
  ; Having large eyes also consumes energy
  set energy energy - abs((eye-size - 1) / (11 - eye-cost))
end


to eat-food
  let prey one-of food-here                       ; Catch a prey thats close
  if prey != nobody                               ; If caught,
    [ ask prey [ die ]                            ; kill it
      set energy energy + energy-gain-from-food ] ; get energy from eating
end


to reproduce
  if ( random 100 < reproduction-rate ) and ( energy > (100 / reproduction-rate) * energy-gain-from-food ) [
    set energy (energy / 2)               ; Divide energy between parent and offspring
    hatch 1 [
      ; Mutates eye-size, land-mobility, and land-food-preference
      set eye-size mutate eye-size (mutation-rate * 3) 1 max-eye-size
      set land-mobility mutate land-mobility mutation-rate 0 1
      set land-food-preference mutate land-food-preference mutation-rate 0 1
      set color scale-color red land-mobility 2.5 -1
      produce-fov ; for visualization
      ]
    move
    ]
end


to-report mutate [ var rate lower upper ]
  ; Mutates the given variable value based on mutation rate
  ; The variable must remain in its viable range
  let value ( var + random-float ( 2 * rate ) - rate )
  if value < lower [ set value lower ]
  if value > upper [ set value upper ]
  report value
end


to death
  ; If out of energy, die
  if energy < 0 [
    ask out-link-neighbors [ die ]
    die
  ]
end


to replenish-food
  ; Replenish the food source
  if random 100 < food-replenish-rate [
    create-food 1 [
      set color black
      setxy random-xcor random-ycor
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; OBSERVABLES / HELPERS ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report avg-eye-size [ agentset ]
  let val ifelse-value any? agentset
    [ mean [ eye-size ] of agentset ]
    [ 1 ]
  report val
end


to-report rad-size [ eye ]
  ; Eye size determines the radius of the field of vision
  ; The effect of eye size on the field of vision under water vs on land is vastly different
  report ifelse-value ycor < 0 [ eye / max-eye-size + 3 ] [ ( eye ) ^ 2 + 3 ]
end


to-report weighted-distance [ weight ]
  ; Distance is weighted based on preference
  ; This is a multiplier used to emphasize the effect of the preference
  let mult 3
  ; Exponentials are used to model the weight of the food prefence
  ; Being close to 0.5 has little effect, but getting closer to one or zero has big effects
  let dist ifelse-value ycor < 0
  [ (distance myself) * exp ((weight - 0.5)* mult) ]
  [ (distance myself) * exp ((0.5 - weight)* mult) ]
  report dist
end


; Copyright 2018 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
610
10
1123
524
-1
-1
5.0
1
14
1
1
1
0
1
0
1
-50
50
-50
50
1
1
1
ticks
30.0

SLIDER
185
10
360
43
initial-number-food
initial-number-food
0
250
80.0
1
1
NIL
HORIZONTAL

SLIDER
5
10
180
43
initial-number-fish
initial-number-fish
0
250
50.0
1
1
NIL
HORIZONTAL

SLIDER
5
80
180
113
energy-gain-from-food
energy-gain-from-food
0.0
300.0
100.0
1.0
1
NIL
HORIZONTAL

BUTTON
5
45
85
78
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
100
45
180
78
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

PLOT
5
370
360
545
Population Size
Time
Population
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Fish" 1.0 0 -6759204 true "" "plot count fish"
"Food" 1.0 0 -10402772 true "" "plot count food"

SWITCH
185
45
360
78
show-vision?
show-vision?
0
1
-1000

PLOT
365
10
605
185
Land Mobility Histogram
Land Mobility
Number of Fish
0.0
1.0
0.0
10.0
false
false
"set-plot-x-range 0 1\nset-plot-y-range 0 count fish\nset-histogram-num-bars 10" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [land-mobility] of fish"

PLOT
365
190
605
365
Eye Size Histogram
Eye Size
Number of Fish
1.0
5.0
0.0
10.0
false
false
"set-plot-x-range 1 max-eye-size\nset-plot-y-range 0 count fish\nset-histogram-num-bars 10" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [eye-size] of fish"

SLIDER
5
115
180
148
food-replenish-rate
food-replenish-rate
0
100
65.0
1
1
%
HORIZONTAL

SLIDER
185
115
360
148
mutation-rate
mutation-rate
0
1
0.1
0.01
1
NIL
HORIZONTAL

PLOT
365
370
605
545
Food Preference Histogram
Food Pref
Number of Fish
0.0
1.0
0.0
10.0
false
false
"set-plot-x-range 0 1\nset-plot-y-range 0 count fish\nset-histogram-num-bars 10" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [land-food-preference] of fish"

PLOT
5
190
360
365
Average Eye Size
Time
Avg Eye Size
0.0
100.0
0.0
3.0
true
true
"set-plot-y-range 1 max-eye-size" "set-plot-y-range 1 max-eye-size"
PENS
"Terrestrial" 1.0 0 -2674135 true "" "plot avg-eye-size (fish with [ land-mobility >= 0.5 ])"
"Aquatic" 1.0 0 -13345367 true "" "plot avg-eye-size (fish with [ land-mobility < 0.5 ])"

SLIDER
185
150
360
183
max-eye-size
max-eye-size
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
185
80
360
113
reproduction-rate
reproduction-rate
0
100
35.0
1
1
%
HORIZONTAL

SLIDER
5
150
180
183
eye-cost
eye-cost
0
10
9.0
0.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model explores the potential relationship between our early ancestors' transition from water to land and the evolution of their eyes.

Around 385 million years ago, vertebrates inhabiting underwater environments began to evolve to live on land. A recent study by MacIver et al. (2017) suggests that the radical fin-to-limb transformation of early tetrapods (vertebrates with four limbs) was accompanied by a radical change in eye size. This would have dramatically increased the visual perception space of these tetrapods, allowing them to observe the abundant food sources on land, and thus aiding their selection for limbs. In this model, we investigate the interplay between eye size and the fin-to-limb transformation, as well as the emergence of terrestrial vertebrates with large eyes.

## HOW IT WORKS

This model aims to simulate the transition of vertebrates from life underwater to life on land. Thus half the world in our simulation is underwater, and the other half is land. The agents in our model are fish initially swimming underwater. We refer to the agents in this model as fish for simplicity purposes, however we think about them more of as vertebrates that are on the brink of transitioning to terrestrial life. At the beginning of our simulation, we can indeed think of these agents as aquatic tetrapods, however as time goes by, they evolve and some of them transition to life on land.

In addition there are other organisms that these fish prey upon. We refer to them as food in our model, but we can think of them as invertebrates that inhabit water as well as land.

Each agent or fish has certain characteristics. These are listed below.

* EYE-SIZE: This is a real number between 1 and the parameter MAX-EYE-SIZE set by the user. Eye-size determines the radius of the field of vision of the fish. For the sake of simplicity, we assume that fish have a field of vision of 360 degrees. Since a typical field of vision of fish is 305 degrees, this assumption is justified. We note that the radius of the field of vision also depends on whether the fish is on land or underwater. Since visibility is very poor underwater, the radius of the field of vision underwater is significantly smaller than it is on land. Furthermore, an increase in eye-size provides little improvement to the radius of the field of vision underwater, but provides a dramatic improvement to the radius of the field of vision on land.

* LAND-MOBILITY: This characteristic is a real number between 0 and 1, and it models how well adapted the fish is to life underwater or on land. This characteristic aims to capture the morphology of the fish (or vertebrate) as it undergoes the fin-to-limb transformation, and how this relates to its locomotion. If this characteristic is 0, this means that the fish is completely adapted to life underwater and is likely to have fins. It means that the fish can move underwater quickly and without a lot of effort. However, it can hardly move on land and would have to spend a lot of energy to cover a small distance on land. Similarly, if land-mobility is 1 the organism is adapted to life on land and is likely to have limbs. For example, applying this characteristic to real world species we could suppose that a clown fish would have a land-mobility value of almost 0, a crocodile would have a land-mobility value of approximately 0.25, a frog would have a land-mobility value of 0.5, and finally a cat would have a land-mobility value of almost 1.

* LAND-FOOD-PREFERENCE: This value is also a real number between 0 and 1. This characteristic aims to capture the food preference of the fish–specifically whether it prefers food on land or food underwater. The intuition behind this characteristic is that a terrestrial animal would be more likely to hunt and eat another terrestrial animal and would be less likely to hunt an aquatic animal.

* ENERGY: This characteristic is used to model the level of nutrition of the fish, which is in a sense, the level of energy of the fish. Fish gain energy from consuming food, and lose energy as they move, and as they reproduce.

Initially, the fish are located underwater, because they have not made the transition to land yet. They have the smallest eye size possible since visibility is very low underwater. And they are completely adapted to life underwater, so they move fast and consume little energy underwater. This means that they move very slowly and consume a lot of energy on land. Each fish has a random preference towards food on land or underwater water. This could be explained by genetic variability and the scarcity of food underwater compared to that of on land.

At each time step, each fish moves. If there is food in the field of vision of the fish, then it moves toward the food, otherwise it just moves randomly. The speed of their movement depends upon their land-mobility value and whether they are on land or underwater. Fish with low land-mobility values move fast underwater and slowly on land. The food remain stationary. As the fish move, they consume energy. How much energy they consume, again depends on their land-mobility value and whether they are underwater or on land. Fish with low land-mobility values consume less energy underwater than on land.

Energy consumption also depends on the eye size of the fish. Having larger eyes cost more energy, since they require more resources to operate. If a fish reaches food, it kills the food and gains energy. There is a fixed probability that a new food appears at each time step.

If the energy value of a fish goes below zero, it dies. The fish reproduce at a fixed rate: if their  energy level exceeds a certain threshold. When a fish reproduces, its energy is divided between it and its offspring. Furthermore, the offspring genetically inherits the other characteristics of its parent, however each of these characteristics are mutated. The rate of mutation is determined by the user.

## HOW TO USE IT

The SETUP button initializes the model.

The GO button runs the model.

Use the INITIAL-NUMBER-FISH slider to set the initial amount of fish.

Use the INITIAL-NUMBER-FOOD slider to set the initial amount of food.

Use the SHOW-VISION switch to toggle on or off the visualization of the field of view of each fish.

Use the FOOD-REPLENISH-RATE slider to set the probability that a new food appears at each time step.

Use the ENERGY-GAIN-FROM-FOOD slider to set how many units of energy a fish gains when it eats a food.

Use the REPRODUCTION-RATE slider to set the probability that a fish reproduces at each time step, and how much energy is required for reproduction.

Use the MUTATION-RATE slider to set how much each characteristic of the offspring could mutate when a fish reproduces.

Use the EYE-COST slider to set how much energy having large eyes costs.

Use the MAX-EYE-SIZE slider to set the maximum size the eyes of a fish can evolve to.

The shade of each fish represents the land-mobility value of that fish. The lighter colored fish have lower land mobility values (i.e. they’re more adapted to live underwater). Similarly, the darker colored fish have higher land-mobility values, that is they’re more adapted to live on land.

The plot of the average eye size displays the average eye size of two populations as a function of time. The terrestrial population consists of fish with land-mobility values greater than 0.5, while the aquatic population consists of fish with land-mobility values less than 0.5.

The Population Size plot represents the size of both the fish population (displayed in cyan) and the amount of available food (displayed in brown). The x-axis represents the passage of time, and the y-axis is the population size.

The Land Mobility Histogram depicts the emergence of distinct fish populations, where land-mobility values range from 0 to 1 along the x-axis. Recall that a land-mobility value of 0 represents fish that are completely adapted to live in water, while a land-mobility value of 1 represents fish that are completely adapted to live on land. The y-axis represents the number of fish with each land-mobility value at the current time step.

The Eye Size Histogram depicts the eye size of all the fish at the current time step. Along the x-axis, eye size ranges from 1 (smallest) to MAX-EYE-SIZE (biggest). The y-axis represents the number of fish with the given eye size value at the current time step.

The Food Preference Histogram depicts the food source preferences of all fish at the current time step. Along the x-axis food preference value of 0 indicates that the fish strongly prefers aquatic food sources, whereas a food preference value of 1 indicates that the fish strongly prefers terrestrial food sources. The y-axis represents the number of fish with the given food preference value at the current time step.

## THINGS TO NOTICE

Notice that after the food population size peaks, a sudden jump in the fish population size follows and fish start to move on land. After that point, notice how the histogram of the land-mobility characteristic tends to have two peaks at the ends of the spectrum indicating two populations: terrestrials and aquatics.

Notice that after a while, the average eye size of the terrestrial population triples in size, where the eye size of the aquatic population tends to stay small.

## THINGS TO TRY

Under what conditions does a terrestrial population with larger eyes not emerge? Why?

Is there a condition in which the transition from water to land does not happen?

Try changing the initial population sizes, ENERGY-GAIN-FROM-FOOD, FOOD-REPLENISH-RATE, and REPRODUCTION-RATE? How do these changes affect the population dynamics?

## EXTENDING THE MODEL

There are various ways this model can be extended and improved. One of them is adding a depth component so that fish can peak above the water line and look towards the shore.

A more realistic field of vision could be used, where the field of vision is narrower, and the distance to the food source could only be measured in a field of binocular vision where both eyes are used.

Another way is to introduce a new characteristic that determines the location of the eye on the head. Then modeling how this changes the field of view and the depth perception of the fish.

Another exciting extension of this model would be using LevelSpace such that each agent has an actual neural network that tells it where to go based on its inputs. This would allow one to investigate how an increase in the visual perception space might affect the intelligence of the agents by allowing them to plan.

## NETLOGO FEATURES

The TIE primitive is used to tie a turtle to every fish for visualizing the field of vision of each fish.

The IN-RADIUS primitive is used to find every food source in a fish's field of vision.

## RELATED MODELS

* BEAGLE Evolution Curricular Models
* Bug Hunt Models

## CREDITS AND REFERENCES

MacIver, Malcolm & Schmitz, Lars & Mugan, Ugurcan & D. Murphey, Todd & D. Mobley, Curtis. (2017). Massive increase in visual range preceded the origin of terrestrial vertebrates. Proceedings of the National Academy of Sciences. 114. 201615563. 10.1073/pnas.1615563114.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Gurkan, C., Head, B., Woods, P. and Wilensky, U. (2018).  NetLogo Vision Evolution model.  http://ccl.northwestern.edu/netlogo/models/VisionEvolution.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2018 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2018 Cite: Gurkan, C., Head, B., Woods, P. -->
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
