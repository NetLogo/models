extensions [ time ]

globals [
  %infected            ;; what % of the population is infectious
  %immune              ;; what % of the population is immune
  lifespan             ;; the lifespan of a turtle
  chance-reproduce     ;; the probability of a turtle generating an offspring each tick
  carrying-capacity    ;; the number of turtles that can be in the world at one time
  immunity-duration    ;; mean number of weeks immunity lasts
]

turtles-own [
  status  ;; equals "susceptible" (healthy but not immune), "infected" (sick and infectious), or "immune" (healthy and immune)
  age     ;; how many years old the turtle is
]

;; The setup is divided into four procedures
to setup
  clear-all
  reset-ticks
  setup-constants
  setup-turtles
  update-global-variables
  update-display
end

;; We create a variable number of turtles of which 10 are infectious,
;; and distribute them randomly
to setup-turtles

  create-turtles number-people [
    setxy random-xcor random-ycor
    set size 1.5  ;; easier to see
    set status "susceptible"
    set color green
    set age random lifespan
    ; schedule a birthday a random number of weeks in the future
    time:schedule-event self [-> get-older ] ticks + random 52
  ]

  ask n-of 10 turtles [  ;; infect 10 turtles initially
    set status "infected"
    set color red
  ]
end

;; This sets up basic constants of the model.
to setup-constants
  set lifespan 50      ;; 50 years
  set carrying-capacity 300
  set chance-reproduce 1
  set immunity-duration 52
end

to go
  ask turtles [
    move
    ifelse status = "infected" [ infect ] [ reproduce ]
  ]
  update-global-variables
  update-display
  tick                 ; Advance time by one week
  time:go-until ticks  ; Execute events scheduled for between preceding and current week
end

to update-global-variables
  if count turtles > 0 [
    set %infected (count turtles with [ status = "infected" ] / count turtles) * 100
    set %immune (count turtles with [ status = "immune" ] / count turtles) * 100
  ]
end

to update-display
  ask turtles [
    if shape != turtle-shape [ set shape turtle-shape ]
  ]
end

;;Turtle counting variables are advanced.
to get-older ;; turtle procedure
  ;; Turtles die of old age once their age exceeds the
  ;; lifespan (set at 50 years in this model).
  set age age + 1
  if age > lifespan [ die ]

  ;; Schedule another birthday in 52 weeks
  time:schedule-event self [-> get-older ] ticks + 52

end

;; Turtles move about at random.
to move ;; turtle procedure
  rt random 100
  lt random 100
  fd 1
end

;; If a turtle is sick, it infects other turtles on the same patch.
;; Immune turtles don't get sick.
to infect ;; turtle procedure
  ask other turtles-here with [ status = "susceptible" ] [
    if random-float 100 < infectiousness [
      set status "infected"
      set color red
      ; Schedule the end of infection
      time:schedule-event self [-> recover-or-die ] ticks + (random-exponential duration)
    ]
  ]
end

;; Once the turtle has been sick long enough, it
;; either recovers (and becomes immune) or it dies.
to recover-or-die ;; turtle procedure
   ifelse random-float 100 < chance-recover [  ;; either recover or die
    set status "immune"
    set color grey
    ; Schedule recovery to susceptible status
    time:schedule-event self [-> recover] ticks + random-exponential immunity-duration
  ] [
    die
  ]
end

to recover
  set status "susceptible"
  set color green
end



;; If there are fewer turtles than the carrying-capacity
;; then turtles can reproduce.
to reproduce
  if count turtles < carrying-capacity and random-float 100 < chance-reproduce [
    hatch 1 [
      set age 1
      ;; Schedule another birthday in 52 weeks
      time:schedule-event self [-> get-older ] ticks + 52
      lt 45
      fd 1
      set status "susceptible"
      set color green
    ]
  ]
end


; Copyright 2022 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
280
10
778
509
-1
-1
14.0
1
10
1
1
1
0
1
1
1
-17
17
-17
17
1
1
1
ticks
30.0

SLIDER
40
155
234
188
duration
duration
0.0
99.0
20.0
1.0
1
weeks
HORIZONTAL

SLIDER
40
121
234
154
chance-recover
chance-recover
0.0
99.0
75.0
1.0
1
%
HORIZONTAL

SLIDER
40
87
234
120
infectiousness
infectiousness
0.0
99.0
65.0
1.0
1
%
HORIZONTAL

BUTTON
62
48
132
83
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
138
48
209
84
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
345
267
509
Populations
weeks
people
0.0
52.0
0.0
200.0
true
true
"" ""
PENS
"sick" 1.0 0 -2674135 true "" "plot count turtles with [ status = \"infected\" ]"
"immune" 1.0 0 -7500403 true "" "plot count turtles with [ status = \"immune\" ]"
"susceptible" 1.0 0 -10899396 true "" "plot count turtles with [ status = \"susceptible\" ]"
"total" 1.0 0 -13345367 true "" "plot count turtles"

SLIDER
40
10
234
43
number-people
number-people
10
carrying-capacity
150.0
1
1
NIL
HORIZONTAL

MONITOR
28
298
103
343
NIL
%infected
1
1
11

MONITOR
105
298
179
343
NIL
%immune
1
1
11

MONITOR
181
299
255
344
years
ticks / 52
1
1
11

CHOOSER
65
195
210
240
turtle-shape
turtle-shape
"person" "circle"
0

@#$#@#$#@
## WHAT IS IT?

This is a modification of the "Virus" model in the Biology section of the Models Library to illustrate use of the time extension for "discrete event simulation", which makes the code simpler and faster (see THINGS TO NOTICE below).

With the few (but important) exceptions noted below, this model does exactly what the original Virus model did and uses the same code. The model documentation is not duplicated here; instead, this tab only discusses the differences between the original Virus model and this discrete event implementation.

## HOW IT WORKS

A discrete event scheduler is a convenient and efficient way of programming agents to do certain actions that don't happen every tick. In many agent-based models, the agents do the same thing every tick. But, sometimes agents take certain action only occasionally. Normally, this would require checking each tick if the right amount of time has passed and then, if it has, doing the action. In the case of the Virus model, agents get sick and then only recover after a certain number of ticks. So, they have to check each tick if that amount of time has passed. A discrete event schedule avoids this by keeping a list of events that are scheduled at different times and then running those events when the time comes. In this model, when an agent gets sick, it schedules when it will recover or die. The `go` procedure of this model uses both tick-based and discrete-event based updates. Each tick, turtles move and have a chance to infect others if they are infected and a chance to reproduce if they aren't. Then the tick counter is advanced and all events that were scheduled to happen during this tick are run with the command `time:go-until ticks`. For more information on the discrete event scheduler, see https://ccl.northwestern.edu/netlogo/docs/time.html.



The differences from the original Virus model are:

  * Instead of using counter variables (`remaining-immunity`, `sick-time`) to count down how many ticks remain until a turtle becomes susceptible or recovers, this version has turtles simply schedule the future time at which those events happen. In the procedure `infect`, the newly infected turtle schedules the time at which it executes `recover-or-die`. In `recover-or-die`, the turtle schedules the time at which its immunity ends and becomes susceptible again. This scheduling eliminates the need for code to check and update the counter variables each tick.

  * Instead of separate boolean variables for whether a turtle is sick or immune, turtles have one variable `status` that has values of "susceptible" (equivalent to "healthy" in the original model), "infected" (equivalent to "sick"), or "immune".

  * The only important difference in model formulation is that the times it takes turtles to recover (switch from "infected" to "immune") and to lose immunity (switch from "immune" to "susceptible") vary randomly among individuals. Discrete event simulation makes this easy: in each of the `time:schedule-event` statements in `infect` and `recover-or-die`, the future time at which the switch occurs is drawn from a random-exponential distribution, using the parameters "duration" and "immunity-duration" as the mean length of infection and immunity. This individual variation in infection and immunity times can be turned off by simply deleting the primitive `random-exponential` from the `time:schedule-event` statements in `infect` and `recover-or-die`.

  * Age is tracked in years instead of weeks, and birthdays are scheduled as discrete events. When each turtle is created in `setup-turtles` it schedules its next birthday (the `get-older` procedure) a random number of weeks in the future. New turtles created in `reproduce` schedule their first birthday 52 weeks after their birth. On each birthday, the turtle simply schedules another execution of `get-older` 52 weeks in the future.

## HOW TO USE IT

This model's interface works exactly as the original Virus model does, with one exception:

The DURATION slider still controls the time it takes an infected person to either die or recover, but instead of always being equal to the slider's value, the duration of each turtle's illness is now drawn from an exponential distribution with the slider's value as its mean. As a result of the exponential distribution's characteristics, most turtles will remain ill for less time than the slider's value but a few will remain ill for much longer.

## THINGS TO NOTICE

The use of discrete event simulation allows the code to be shorter and simpler. This version has 4 fewer procedures than the original: `get-sick`, `get-health`, `become-immune` are replaced by the `time:schedule-event` statements. The `immune?` reporter is made unnecessary by discrete event simulation and the `status` variable.

This model also executes more rapidly than the original Virus model because it eliminates the need to check counter variables every tick. In BehaviorSpace experiments with display updates off, this version executes in 2/3 the time of the original model, even though execution time (according to the profiler extension) is dominated by interface updates and the `move` procedure. The original model spends much of its execution time in the procedures `immune?` and `get-older`, which have been removed or simplified here.

The addition of individual variation in the duration of infection and immunity qualitatively changes the model's behavior. This model produces small and shorter cycles in infection than the original Virus model.

The model illustrates only one function of the time extension, discrete event simulation. It does not use the time extension's ability to represent specific years, dates, days, etc.

## THINGS TO TRY

In addition to the experiments suggested for the original Virus model, the effects of variability in the duration of illness and immunity can be investigated with this version. For different kinds of virus (e.g., Ebola, with short duration, high infectiousness, and low recovery; AIDS, with long duration, low infectiousness, and low recovery), compare the behavior of this model with that of the original Virus model. (Or turn off this model's random variation among turtles, as explained above.)

## EXTENDING THE MODEL

The modifications suggested for the original Virus model can all be implemented for this version.

Also, you can see what happens if infectiousness, or recovery time, or the duration of immunity depend on age. For example, the COVID-19 virus was originally believed much less infectious for children, and survival was lower for older adults. Modify the procedures for these processes to make the probabilities or rates depend on `age` (which is in years).

## RELATED MODELS

This model illustrates only one of the time extension's capabilities, letting agents schedule actions at future times. The other time extension code example models illustrate the extension's other capabilities such as providing date and time variables, linking ticks to explicit time units, and reading and writing time-series data.

## CREDITS AND REFERENCES

The original Virus model was written by Uri Wilensky:

* Wilensky, U. (1998).  NetLogo Virus model.  http://ccl.northwestern.edu/netlogo/models/Virus.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Railsback, S. and Wilensky, U. (2022).  NetLogo Virus Using Discrete Event Simulator model.  http://ccl.northwestern.edu/netlogo/models/VirusUsingDiscreteEventSimulator.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2022 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2022 Cite: Railsback, S. -->
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
NetLogo 6.4.0
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
