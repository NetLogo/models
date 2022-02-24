to setup
  clear-all
  ask patches [
    ; Start populations at roughly even levels.
    set pcolor one-of [ red green blue black ]
  ]
  reset-ticks
end

to go
  ; This model uses an event-based approach. It calculates how many events of each type
  ; should occur each tick and then executes those events in a random order. Event type
  ; could be signified by any constant. Here, we use a the numbers 0, 1, and 2 to signify
  ; event type, but then store those numbers in variables with clear names for readability.
  let swap-event 0
  let reproduce-event 1
  let select-event 2

  ; Note that we have to compute the number of global events rather than the number of
  ; actions that each individual patch performs since the execution of those events has
  ; to be random between the patches. That is, a single patch can't perform all of their
  ; actions in one go: suppose they end up executing 5 swaps in one tick. The swaps would
  ; be shuffling things around locally rather than allowing for an organism to travel
  ; multiple steps.
  ; Hence, this code creates a list with an entry for each event type that should occur
  ; this tick, then shuffles that list so that the events are in a random order. We then
  ; iterate through the list, and random neighboring patches run the corresponding event.
  let repetitions count patches / 3 ; At default settings, there will be an average of 1 event per patch.
  let events shuffle (sentence
    n-values random-poisson (repetitions * swap-rate)      [ swap-event ]
    n-values random-poisson (repetitions * reproduce-rate) [ reproduce-event ]
    n-values random-poisson (repetitions * select-rate)    [ select-event ]
  )

  foreach events [ event ->
    ask one-of patches [
      let target one-of neighbors4
      if event = swap-event      [ swap target ]
      if event = reproduce-event [ reproduce target ]
      if event = select-event    [ select target ]
    ]
  ]
  tick
end

; Patch procedures

; Swap PCOLOR with TARGET.
to swap [ target ]
  let old-color pcolor
  set pcolor [ pcolor ] of target
  ask target [ set pcolor old-color ]
end

; Compete with TARGET. The loser becomes blank.
to select [ target ]
  ifelse beat? target [
    ask target [ set pcolor black ]
  ] [
    if [ beat? myself ] of target [
      set pcolor black
    ]
  ]
end

; If TARGET is blank, reproduce on that patch. If I'm blank, TARGET reproduces on my patch.
to reproduce [ target ]
  ifelse [ pcolor ] of target = black [
    ask target [
      set pcolor [ pcolor ] of myself
    ]
  ] [
    if pcolor = black [
      set pcolor [ pcolor ] of target
    ]
  ]
end

; Determine whether or not I beat TARGET
to-report beat? [ target ]
  report (pcolor = red   and [ pcolor ] of target = green) or
         (pcolor = green and [ pcolor ] of target = blue) or
         (pcolor = blue  and [ pcolor ] of target = red)
end

; Utility procedures

to-report rate-from-exponent [ exponent ]
  report 10 ^ exponent
end

to-report swap-rate
  report rate-from-exponent swap-rate-exponent
end

to-report reproduce-rate
  report rate-from-exponent reproduce-rate-exponent
end

to-report select-rate
  report rate-from-exponent select-rate-exponent
end

; Convert the given rate to a percentage of how much that action happens
to-report percentage [ rate ]
  report 100 * rate / (swap-rate + reproduce-rate + select-rate)
end


; Copyright 2017 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
310
10
771
472
-1
-1
3.0
1
10
1
1
1
0
1
1
1
-75
75
-75
75
1
1
1
ticks
30.0

BUTTON
5
10
100
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
115
10
210
43
NIL
go\n
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
5
55
210
88
swap-rate-exponent
swap-rate-exponent
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
5
100
210
133
reproduce-rate-exponent
reproduce-rate-exponent
-1
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
5
145
210
178
select-rate-exponent
select-rate-exponent
-1
1
0.0
0.1
1
NIL
HORIZONTAL

PLOT
5
190
305
470
Populations
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
"default" 1.0 0 -2674135 true "" "plot count patches with [ pcolor = red ]"
"pen-1" 1.0 0 -10899396 true "" "plot count patches with [ pcolor = green ]"
"pen-2" 1.0 0 -13345367 true "" "plot count patches with [ pcolor = blue ]"

MONITOR
215
50
305
95
swap-%
percentage swap-rate
2
1
11

MONITOR
215
95
305
140
reproduce-%
percentage reproduce-rate
2
1
11

MONITOR
215
140
305
185
select-%
percentage select-rate
2
1
11

@#$#@#$#@
## WHAT IS IT?

This model explores the role of movement and space in a three species ecosystem. The system consists of three species, represented by red patches, green patches, and blue patches, which compete over space. The interactions between the species are based on the game Rock-Paper-Scissors. That is, red beats green, green beats blue, and blue beats red. Organisms compete with their neighbors, move throughout the environment, and reproduce. These interactions result in spiral patterns whose size and stability depends on the movement rate of the organisms.

The model is written in an event-based fashion, to reflect the formulation of the published model. See HOW IT WORKS and EXTENDING THE MODEL.

## HOW IT WORKS

Each patch can be occupied by one of three species or can be blank. The species are represented by three colors: red, green, and blue. Each tick, the following types of events happen at defined average rates:

- Select event: Two random neighbors compete with each other. In competition, red beats green, green beats blue, and blue beats red, like in rock paper scissors. The losing patch becomes blanks.
- Reproduce event: Two random neighbors attempt to reproduce. If one of the neighbors is blank, it acquires the color of the other. Nothing happens if neither neighbor is blank.
- Swap event: Two random neighbors swap color. This represents the organisms moving.

The exact number of, for instance, swap events that occur each tick is drawn from a [Poisson distribution](https://en.wikipedia.org/wiki/Poisson_distribution) with mean equal to `(count patches) * 10 ^ swap-rate-exponent`. A Poisson distribution defines how many times a particular event occurs given an average rate for that event assuming that the occurrences of that event are independent. Here, the occurrences of the events are approximately independent since they're being performed by different organisms.

The events occur in a random order involving random pairs of neighbors.

## HOW TO USE IT

Press SETUP to initialize the model and GO to run it.

SWAP-RATE-EXPONENT, REPRODUCE-RATE-EXPONENT, and SELECT-RATE-EXPONENT each control the rate at which their respective actions are performed. There will be an average of `count patches * 10 ^ rate-exponent` events each tick for each event type. This means that increasing a slider by `1.0` will result in that event type occurring 10 times more often, no matter what the other sliders are set to. The SWAP-%, REPRODUCE-%, and SELECT-% monitors indicate what percentage of events will be swap, reproduce, and select events (respectively) each tick.

The POPULATIONS plot shows how much of each organism there is over time.

## THINGS TO NOTICE

Running the model quickly results in a collection of interconnected spirals in which each species is chasing another species.

Global population levels of each of the species oscillate over time.

## THINGS TO TRY

- What happens as you increase SWAP-RATE-EXPONENT? What happens to the shape and size of the spirals? Why does this happen?
- What happens as you decrease SWAP-RATE-EXPONENT?
- Can you find parameter settings that result in the extinction of one of the species? What happens to the other two species?

## EXTENDING THE MODEL

- Try generalizing the model to more than three species.
- The model is written in an event-based manner. Try rewriting it in a more idiomatic agent-based way.

## NETLOGO FEATURES

The model makes heavy use of the `random-poisson` primitive. This primitive is useful when modeling events that happen at various rates. Furthermore, this model uses a technique wherein a list of events is produced and shuffled to simulate the occurrence of each event at each rate while still allowing the events to occur in arbitrary orders.

## RELATED MODELS

Wolf Sheep Predation shows a simpler predator prey model.

## CREDITS AND REFERENCES

Reichenbach, T., Mobilia, M., & Frey, E. (2008). Self-organization of mobile populations in cyclic competition. Journal of Theoretical Biology, 254(2), 368–383. https://www.sciencedirect.com/science/article/pii/S0022519308002464?via%3Dihub

Reichenbach, T., Mobilia, M., & Frey, E. (2007). Mobility promotes and jeopardizes biodiversity in rock-paper-scissors games. Nature, 448(7157), 1046–1049. https://doi.org/10.1038/nature06095

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Head, B., Grider, R. and Wilensky, U. (2017).  NetLogo Rock Paper Scissors model.  http://ccl.northwestern.edu/netlogo/models/RockPaperScissors.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2017 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2017 Cite: Head, B., Grider, R. -->
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
