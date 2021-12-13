globals [
  target     ; the target line in the middle
  max-dist   ; the maximum distance to that wall
  attempts   ; the number of attempts made so far with the current strategy

  ; lists of each run's distance halfway through the run's attempts
  p-results
  v-results
  pv-results
  r-results
]

turtles-own [
  max-moves      ; the max-moves of the current throw
  best-max-moves ; the best throw of the agent (or, if no memory, the current throw)
  moves-left     ; the number of moves left until the ball comes to rest
  score          ; the current score (how far from target... lower is better)
  best-score     ; best score (or, if no memory, current throw)
]

to setup
  clear-all

  ; the target is the line in the center of the screen, one patch thick
  set target patches with [ pxcor = 0 ]

  set-default-shape turtles "circle-arrow"
  set max-dist world-width

  create-turtles number-of-players [
    set size (world-height / number-of-players)
    set color color + 0.1 ; to make trails a little easier to see
  ]
  spread-out-turtles-evenly

  ; initialize result lists
  set p-results  []
  set v-results  []
  set pv-results []
  set r-results  []

  setup-run
  setup-attempt
  reset-ticks
end

to spread-out-turtles-evenly
  let d (world-height / count turtles)
  let y (min-pycor - 0.5 + (d / 2))
  foreach sort turtles [ t ->
    ask t [ set ycor round y ]
    set y (y + d)
  ]
end

to setup-run
  set attempts 0
  ; random strategies lets you keep the simulation running
  ; picking from the available strategies at random
  if randomize-strategy-each-run? [
    set strategy one-of [ "Random" "Piagetian" "Vygotskiian" "P-V" ]
  ]
  ask turtles [
    set score (max-dist + 1) ; start with a dummy score that is sure to be beaten
    set best-score score
    ; their max-moves are randomly distributed over the length of the playing field
    set max-moves random max-dist
  ]
end

to-report get-strategy-color
  if strategy = "Random"      [ report green ]
  if strategy = "Piagetian"   [ report blue  ]
  if strategy = "Vygotskiian" [ report red   ]
  if strategy = "P-V"         [ report grey  ]
end

to setup-attempt
  clear-patches
  ask target [
    set pcolor get-strategy-color
  ]
  ; place turtles at starting line
  ask turtles [
    set heading 90
    set xcor min-pxcor
  ]
end

to go

  if attempts >= attempts-per-run [ setup-run ]
  setup-attempt

  ; move all the turtles forward to their max-moves spot
  move-turtles

  ; the score is their distance from the target line
  ask turtles [ set score distancexy 0 ycor ]

  ; act according to the strategy, e.g,. in Vygotskiian, you compare
  ; your scores to a neighbor and possibly update your score
  ask turtles [ adjust ]

  set attempts (attempts + 1)
  if attempts = round (attempts-per-run / 2) [ record-result ]
  tick
  if attempts >= attempts-per-run and stop-after-each-run? [
    stop
  ]

end

to move-turtles
  ; move all the turtles forward to their max-moves spot.
  ; we can't just say "forward max-moves" because we want
  ; them to bounce off the wall and leave a dissipating trail
  ask turtles [ set moves-left limit-legal-distance max-moves ]
  let moving-turtles turtles with [ moves-left > 0 ]
  while [ any? moving-turtles ] [
    set moving-turtles turtles with [ moves-left > 0 ]
    ask moving-turtles [
      move-x
      if trails? [
        set pcolor (color - 5) + (10 * (max-moves - moves-left) / max-moves)
      ]
    ]
  ]
end

to record-result
  let current-mean mean [ score ] of turtles
  if strategy = "Random"      [ set  r-results lput current-mean  r-results ]
  if strategy = "Piagetian"   [ set  p-results lput current-mean  p-results ]
  if strategy = "Vygotskiian" [ set  v-results lput current-mean  v-results ]
  if strategy = "P-V"         [ set pv-results lput current-mean pv-results ]
end

to move-x
  set moves-left moves-left - 1
  forward 1
  if pxcor >= (max-pxcor - 1) [
    set heading 270
    forward 2
  ]
end

to-report limit-legal-distance [ val ]
  report min (list (max-dist - 1) max (list 0 val))
end

to adjust
  if strategy = "Random" [
    r-adjust
    set max-moves best-max-moves
    stop
  ]
  if strategy = "Piagetian" [ p-adjust ]
  if strategy = "Vygotskiian" [ v-adjust ]
  if strategy = "P-V" [ pv-adjust ]

  if strategy = "Vygotskiian" [
    set max-moves limit-legal-distance
      (best-max-moves + (random-normal 0 (move-error * best-score / max-dist)))
    stop
  ]

  ifelse xcor > 0 [
    set max-moves limit-legal-distance
      (best-max-moves +  (- abs random-normal 0 (move-error * best-score / max-dist)))
  ] [
    set max-moves limit-legal-distance
      (best-max-moves + (abs random-normal 0 (move-error * best-score / max-dist)))
  ]
end

to p-adjust
  ; if your score is better, that's your new best, otherwise stick with the old
  if score < best-score [ ; note that lower scores are better (closer to target line)
    set best-score score
    set best-max-moves max-moves
  ]
end

to v-adjust
  let fellow nobody
  while [ fellow = nobody or fellow = self ] [
    set fellow turtle (who + (- (#-vygotskiian-neighbors / 2)) + random (1 + #-vygotskiian-neighbors))
  ]
  ; look randomly to one of your neighbors

  ; if the score is better and it is within your ZPD, use their max-moves.
  ifelse (best-score > [ best-score ] of fellow) and (best-score - ZPD <= [ best-score ] of fellow) [
    set best-score [ best-score ] of fellow
    set best-max-moves [ best-max-moves ] of fellow
  ]
  [
    set best-score score
    set best-max-moves max-moves
  ]
end

to pv-adjust

  ; look randomly to one of your neighbors
  let fellow nobody
  while [ fellow = nobody or fellow = self ] [
    set fellow turtle (who + (- (#-vygotskiian-neighbors / 2)) + random (1 + #-vygotskiian-neighbors))
  ]

  ; maximize your own score and...
  if score < best-score [
    set best-score score
    set best-max-moves max-moves
  ]

  ; check it against your neighbor's score
  if (best-score > [ best-score ] of fellow) and (best-score - ZPD <= [ best-score ] of fellow) [
    set best-score [ best-score ] of fellow
    set best-max-moves [ best-max-moves ] of fellow
  ]
end

to r-adjust
  ; random strategy changes max-moves to a random number x if it's not at the wall
  ; where 0 < x < max-dist
  ; if it is at the target, it stops changing.
  ifelse abs pxcor > 0 [
    set best-max-moves (random max-dist)
  ] [
    set best-max-moves (max-dist / 2) - 1
  ]
end


; Copyright 2005 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
14
10
627
274
-1
-1
5.0
1
10
1
1
1
0
0
0
1
-60
60
-25
25
0
0
1
ticks
30.0

CHOOSER
16
391
116
436
strategy
strategy
"Random" "Piagetian" "Vygotskiian" "P-V"
3

BUTTON
15
305
125
350
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
130
305
220
350
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
324
303
629
548
Avg Distance From Target
Attempts
Distance From Target
1.0
30.0
0.0
50.0
true
true
"set-plot-x-range 1 attempts-per-run" "if attempts > 0 [\n  set-current-plot-pen strategy\n  plotxy attempts (mean [ score ] of turtles)\n]"
PENS
"Random" 1.0 0 -10899396 true "" ""
"Piagetian" 1.0 0 -13345367 true "" ""
"Vygotskiian" 1.0 0 -2674135 true "" ""
"P-V" 1.0 0 -16777216 true "" ""

SLIDER
15
355
165
388
number-of-players
number-of-players
10
50
30.0
10
1
NIL
HORIZONTAL

SLIDER
215
395
315
428
move-error
move-error
0
30
4.0
1
1
NIL
HORIZONTAL

SWITCH
225
440
315
473
trails?
trails?
0
1
-1000

BUTTON
225
305
315
350
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

SWITCH
15
480
315
513
randomize-strategy-each-run?
randomize-strategy-each-run?
0
1
-1000

PLOT
635
11
873
546
Strategy Avgs
NIL
NIL
0.0
4.0
0.0
15.0
true
true
"" ""
PENS
"Random" 1.0 1 -10899396 true "" "if not empty? r-results [\n  plot-pen-reset\n  plotxy 0 mean r-results\n]"
"Piagetian" 1.0 1 -13345367 true "" "if not empty? p-results [\n  plot-pen-reset\n  plotxy 1 mean p-results\n]"
"Vygotskiian" 1.0 1 -2674135 true "" "if not empty? v-results [\n  plot-pen-reset\n  plotxy 2 mean v-results\n]"
"P-V" 1.0 1 -16777216 true "" "if not empty? pv-results [\n  plot-pen-reset\n  plotxy 3 mean pv-results\n]"

SLIDER
15
440
220
473
#-vygotskiian-neighbors
#-vygotskiian-neighbors
2
18
4.0
2
1
NIL
HORIZONTAL

SLIDER
120
395
212
428
ZPD
ZPD
0
60
15.0
5
1
NIL
HORIZONTAL

SLIDER
170
355
315
388
attempts-per-run
attempts-per-run
1
100
30.0
1
1
NIL
HORIZONTAL

SWITCH
15
515
315
548
stop-after-each-run?
stop-after-each-run?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model is designed as a "thought experiment" to shed light on the ongoing debate between two theories of learning, constructivism and social constructivism. In it, agents "learn" through playing a game either as individuals, social interactors, or both.

This model of "learning through playing" was created with the following objectives:

1. to demonstrate the viability of agent-based modeling (ABM) for examining socio/developmental-psychological phenomena;

2. to illustrate the potential of ABM as a platform enabling discourse and collaboration between psychologists with different theoretical commitments;

3. to visualize the complementarity of Piagetian and Vygotskiian explanations of how people learn.

## HOW IT WORKS

The design problem for this model-based thought experiment was to create a single environment in which we could simulate both “Piagetian” and “Vygotskiian” learning.

We chose to model a game in which contestants all stand behind a line and each throws a marble, trying to land it as close as possible to a target line some "yards" away (30 NetLogo patches): Players stand in a row. They each roll a marble at a target line. Some players undershoot the line, some overshoot it. Players collect their marbles, adjust the force of their roll, and, on a subsequent trial, improve on their first trial—they have “learned” as individuals.

To show the difference between the “Piagetian” and “Vygotskiian” perspectives, we focus on the differential emphases they put on the contribution of the social milieu to individual learning.

We simulated four learning strategies:

- **“Random”**: a control condition, in which players’ achievement does not inform their performance on subsequent attempts, unless they are exactly on target.

- **“Piagetian”**: players learn only from their own past attempts.

- **“Vygotskiian”**: players learn only by watching other players nearby, not from their own attempts.

- **“Piagetian–Vygotskiian”**: players learn from both their own and a neighbor’s performance.

## HOW TO USE IT

To run this simulation, press SETUP and then GO. To execute the simulation one attempt at a time, press GO ONCE.

The NUMBER-OF-PLAYERS slider controls how many players there are in the game.

You can change the number of attemps that each player makes in a simulation run using the ATTEMPTS-PER-RUN slider.

To run the simulation under a particular learning mode (Random/Piagetian/Vygotskiian/Piagetian-Vygotskiian), use the STRATEGY chooser and select the strategy from its drop-down menu. Make sure the switch RANDOMIZE-STRATEGY-EACH-RUN? is set to "Off."

Adjust the value of the ZPD slider to set the maximum difference between a player's score and its selected neighbor's score that still allows the player to learn from that neighbor (applies under the Vygotskiian and Piagetian-Vygotskiian strategies).

Adjust the value of the MOVE-ERROR slider to set the level of "noise" in the players' perception and execution.

Adjust the value of the #-VYGOTSKIIAN-NEIGHBORS slider to set the number of neighbors that players see under the Vygotskiian and Piagetian-Vygotskiian strategy.

If the TRAILS? switch is "On", each player will leave a colored trail behind when they make an attempt, making it easier to see where they end up.

Set the switch RANDOMIZE-STRATEGY-EACH-RUN? to "On" in order to view multiple runs under the different conditions. This is helpful for comparing between different experimental outcomes. Note that the target line, in the middle of the view, changes color to reflect the condition you are running the simulation under -- these are the same colors as in the graph and histogram.

If the STOP-AFTER-EACH-RUN? switch is set to "On", the simulation will stop after ATTEMPTS-PER-RUN attempts have been made.

## THINGS TO NOTICE

Note that the learning process involves “feedback loops.” That is, a player’s learning—the individual “output” of a single attempt—constitutes “input” for the subsequent attempt. In the “Piagetian” condition, this is a player-specific internal loop, and in the “Vygotskiian” condition one person’s output may be another person’s input on a subsequent attempt, and so on.

Note also that over the course of a “Piagetian–Vygotskiian” run of the simulation, players might learn on one attempt from their own performance and on another from the performance of a neighbor. Both sources of information are simultaneously available for each player to act upon.

## THINGS TO TRY

The combined “Piagetian–Vygotskiian” strategy tends to be the best one, but whether the Piagetian learning is greater than the Vygotskiian learning or vice versa depends on combinations of the settings of the parameters #-VYGOTSKIIAN-NEIGHBORS, ZPD, and MOVE-ERROR. Try to find some settings under which Piagetian works better and some settings under which Vygotskiian works better. Can you explain where the difference comes from?

## EXTENDING THE MODEL

Try to implement a modified version of the “Vygotskiian” strategy, where the better performing players modify their next move to be within the ZPD of a less well performing neighbor, making a play that is worse than they know how to make, in order to help the less well performing player learn to play better.

## CREDITS AND REFERENCES

This model is a modernized version of the model presented in:

- Abrahamson, D., & Wilensky, U. (2005). "Piaget? Vygotsky? I'm game!: Agent-based modeling for psychology research". Paper presented at the annual meeting of the Jean Piaget Society. https://ccl.northwestern.edu/papers/Abrahamson_Wilensky_JPS20.pdf

The original model is available at:
http://ccl.sesp.northwestern.edu/research/conferences/JPS2005/JPS2005.nlogo

For more about the additions suggested in EXTENDING THE MODEL, see:

- Abrahamson, D., Wilensky, U. & Levin, J. (2007) "Agent-Based Modeling as a Bridge Between Cognitive and Social Perspectives on Learning". Paper presented at the annual meeting of the American Educational Research Association, Chicago, IL. http://ccl.northwestern.edu/2007/abr-wil-levin-aera2007.pdf

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Abrahamson, D. and Wilensky, U. (2005).  NetLogo Piaget-Vygotsky Game model.  http://ccl.northwestern.edu/netlogo/models/Piaget-VygotskyGame.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2005 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2005 Cite: Abrahamson, D. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

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

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

circle-arrow
true
0
Circle -7500403 true true 8 8 283
Polygon -1 true false 150 5 40 250 150 205 260 250

line
true
0
Line -7500403 true 150 0 150 300

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144
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
