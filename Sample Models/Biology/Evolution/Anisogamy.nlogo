globals [
  average-lifetime       ; the average lifetime of adults, used to pick a random lifetime for each adult and gamete when they are born
  total-red-pop       ; to calculate the running average of the proportion of the red gametes in the last 5000 ticks
  total-blue-pop      ; to calculate the running average of the proportion of the blue gametes in the last 5000 ticks
]

breed [adults adult]
breed [gametes gamete]   ; gametes are produced by adults for reproductive purposes
breed [zygotes zygote]   ; a zygote forms when two gametes fuse. they then incubate and grow into adults
breed [dead-zygotes dead-zygote] ; this pseudo-breed is used to visualize zygote deaths

adults-own [
  mating-type        ; this variable denotes the pseudo-sex of each adult, either red or yellow
  gamete-size        ; each adult has its own evolutionary strategy for the gamete size, which is a decimal number
  remaining-lifetime ; adults have limited lifetimes
]

zygotes-own [
  mating-type
  gamete-size
  remaining-incubation-time  ; zygotes have to incubate (approximately adult life / 5) before turning into adults or dying
]

gametes-own [
  mating-type
  remaining-lifetime   ; gametes have limited lifetime, too (approximately adult life / 10)
]


to setup
  clear-all

  set total-red-pop 0
  set total-blue-pop 0

  ; create the blue background that represents a marine environment
  ask patches [ set pcolor 87 + random 5 - random 5 ]
  repeat 20 [ diffuse pcolor 0.25 ]

  ; initialize global variables
  set average-lifetime 500

  ; create the initial adult population
  create-adults population-size [
    set shape "adult"
    setxy random-xcor random-ycor

    ; choose the mating type randomly and change the color accordingly
    set mating-type one-of [ red blue ]
    set color mating-type

    ; all adults begin with the same gamete size strategy, which is the reproduction budget / 2.
    set gamete-size (size * gamete-production-budget) / 200

    ; adult lifetime is drawn from a normal distribution with a standard deviation that is 1/10th of the average lifetime.
    set remaining-lifetime round (random-normal average-lifetime (average-lifetime / 10))
  ]

  reset-ticks
end

to go

  let my-speed 1 ; the default speed for all agents

  ask adults[
    if adults-move? [
      wiggle-and-move my-speed
    ]
    maybe-produce-gametes
    age-and-maybe-die
  ]

  ask gametes [
    if speed-size-relation? [
      set my-speed precision (gamete-production-budget / (size)) 2
    ]
    wiggle-and-move my-speed
    maybe-fuse
    age-and-maybe-die
  ]

  ask zygotes [
    incubate
  ]

  ask dead-zygotes[
    slowly-disappear
  ]

  enforce-carrying-capacity

  ; if behaviorspace is running, calculate the averages after 15000 ticks
  if behaviorspace-run-number != 0 [
    ifelse behaviorspace-experiment-name != "critical-mass200k" [
      if ticks > 15000 [
        set total-red-pop total-red-pop + (count gametes with [color = red])
        set total-blue-pop total-blue-pop + (count gametes with [color = blue])
      ]
    ][
      if ticks > 195000 [
        set total-red-pop total-red-pop + (count gametes with [color = red])
        set total-blue-pop total-blue-pop + (count gametes with [color = blue])
      ]
    ]
  ]

  tick
end

;;;; gamete & adult procedure
;;;;   simulates a random walk
to wiggle-and-move [ my-speed ]
  rt random 360
  fd my-speed
end

;;;; gamete and adult procedure
;;;;   counts down the remaining lifetime of an agent and asks it to die when it has no lifetime remaining
to age-and-maybe-die
    set remaining-lifetime remaining-lifetime - 1
    if remaining-lifetime < 1 [ die ]
end


;;;; adult procedure
;;;;   produces gametes at random times and passes down the gamete-size strategy with the chance of a small mutation
to maybe-produce-gametes

  ; the probability of an adult producing new gametes at each tick
  let gamete-production-probability 1.5
  ; dictates the maximum number of decimal places in the gamete size, hence limits the minimum gamete size
  let gamete-size-sensitivity 2

  if random-float 100 < gamete-production-probability [

    ; introduce a small random mutation to the gamete size for the current reproduction cycle
    let inherited-gamete-size precision (random-normal gamete-size mutation-stdev) gamete-size-sensitivity

    if inherited-gamete-size > 0 [
      ; determine the number of gametes that you will produce in the current reproduction cycle
      let number-of-gametes floor (((size * gamete-production-budget) / 100) / inherited-gamete-size)

      ; the hatch primitive automatically passes down the basic properties such as the mating type and the color
      hatch-gametes number-of-gametes [
        set size inherited-gamete-size
        set shape "default"
        set remaining-lifetime round (random-normal (average-lifetime / 10) (average-lifetime / 100))
      ]
    ]
  ]
end


;;;; gamete procedure
;;;;   if a gamete touches another gamete, they fuse and hatch a zygote
;;;;   the hatched zygote inherits the mating type and gamete-size strategies from one of the gametes randomly
to maybe-fuse
  if any? other gametes-here [
    ; because there might be multiple other gametes on the same patch, choose one of them to be your partner randomly.

    let mating-partner nobody
    ; if same type mating is allowed, any gametes here are possible mates
    ifelse same-type-mating-allowed? [
      set mating-partner one-of other gametes-here
    ]
    [ ; otherwise, we only consider gametes of a different type
      set mating-partner one-of other gametes-here with [ mating-type != [ mating-type ] of myself ]
    ]

    if mating-partner != nobody [
      ; pool the mating type and gamete size strategies that are inherited from both gametes
      let mating-type-pool list (mating-type) ([ mating-type ] of mating-partner)
      let gamete-size-pool list (size) ([ size ] of mating-partner)

      ; choose one of the parent strategies randomly
      let inherited-strategy random 2

      ; fuse into a zygote that has the combined size of the two gametes
      hatch-zygotes 1 [
        set gamete-size (item inherited-strategy gamete-size-pool)
        set mating-type (item inherited-strategy mating-type-pool)
        set color (mating-type + 3)
        set size (sum (gamete-size-pool) * 2)
        set shape "zygote"
        ; incubation time is drawn from a normal distribution
        set remaining-incubation-time round (random-normal (average-lifetime / 5) (average-lifetime / 50))
      ]

      ; after the zygote is hatched, the gametes are both taken out of the system
      ask mating-partner [ die ]
      die
    ]
  ]
end


;;;; zygote procedure
;;;;   counts down the incubation time, and then turns into an adult if the critical mass is achieved
;;;;   if critical mass is not achieved and ENFORCE-CRITICAL-MASS? is ON, the zygote turns into a dead zygote
to incubate
    set remaining-incubation-time remaining-incubation-time - 1

    if remaining-incubation-time < 1 [
      if enforce-critical-mass? [
        if (size / 2) < zygote-critical-mass [
          hatch-dead-zygotes 1 [
            set size 1
            set shape "zygote"
            set color black
          ]
          die
        ]
      ]

      set breed adults
      set color mating-type
      set shape "adult"
      set size 1
      set remaining-lifetime round (random-normal average-lifetime (average-lifetime / 10))
    ]
end

;;;; dead zygote procedure
;;;;   dead zygotes slowly shrink and then die when it's time
to slowly-disappear
  set size size - 0.05
  if size < 0.1 [ die ]
end

;;;; observer procedure
;;;;   ensures that the adult population does not exceed the carrying capacity of the system
to enforce-carrying-capacity
  if count adults > population-size [
    ask n-of (count adults - population-size) adults [ die ]
  ]
  ; if there aren't multiple adults left, stop the model
  if count adults < 2 [ stop ]
end

;;;; interface procedure
;;;;   allows the user to follow a randomly chosen gamete
;;;;   as the gametes in the model are too small to see
to follow-a-gamete [col]
  ifelse any? gametes with [ color = col and remaining-lifetime > average-lifetime / 12 ] [
    stop-inspecting-dead-agents
    let target-gamete one-of gametes with [ color = col and remaining-lifetime > average-lifetime / 12 ]
    inspect target-gamete
    watch target-gamete
  ][
    user-message "There are no more gametes to follow!"
  ]
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
280
10
750
481
-1
-1
14.0
1
8
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
20
10
86
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
95
10
158
43
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
20
55
265
88
population-size
population-size
0
400
100.0
50
1
adults
HORIZONTAL

PLOT
775
110
1100
230
population composition
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"adults" 1.0 0 -9276814 true "" "plot count adults"
"zygotes" 1.0 0 -11221820 true "" "plot count zygotes"
"gametes" 1.0 0 -2064490 true "" "plot (count gametes)"

SWITCH
20
345
265
378
same-type-mating-allowed?
same-type-mating-allowed?
1
1
-1000

SLIDER
20
95
265
128
gamete-production-budget
gamete-production-budget
0
100
50.0
5
1
%
HORIZONTAL

PLOT
775
360
1100
490
gamete size distribution (int=0.025)
NIL
NIL
-0.1
0.6
0.0
10.0
true
true
"" ""
PENS
"total" 0.05 1 -9276814 true "" "histogram [gamete-size] of adults"
"reds" 0.05 1 -2674135 true "" "histogram [gamete-size] of adults with [color = red]"
"blues" 0.05 1 -13345367 true "" "histogram [gamete-size] of adults with [color = blue]"

SLIDER
20
135
265
168
zygote-critical-mass
zygote-critical-mass
0
1
0.4
0.05
1
NIL
HORIZONTAL

SWITCH
20
390
265
423
enforce-critical-mass?
enforce-critical-mass?
0
1
-1000

SLIDER
20
175
265
208
mutation-stdev
mutation-stdev
0
0.1
0.03
0.001
1
NIL
HORIZONTAL

PLOT
775
235
1100
355
gamete population
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
"red gametes" 1.0 0 -2674135 true "" "plot count gametes with [color = red]"
"yellow gametes" 1.0 0 -13345367 true "" "plot count gametes with [color = blue]"

MONITOR
775
10
885
55
red adults
count adults with [color = red]
17
1
11

MONITOR
775
60
885
105
blue adults
count adults with [color = blue]
17
1
11

BUTTON
910
10
1100
51
follow a red gamete
follow-a-gamete red
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
20
240
190
273
speed-size-relation?
speed-size-relation?
1
1
-1000

SWITCH
20
280
190
313
adults-move?
adults-move?
0
1
-1000

BUTTON
910
60
1100
101
follow a blue gamete
follow-a-gamete blue
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

This model is a thought experiment related to the evolution of the two sexes as we know them: males producing numerous small sperm cells and females producing only a handful of big egg cells.

The model has two pseudo-sexes (red and blue). The adult organisms of each pseudo-sex begin with the same reproductive strategy: produce medium sized gametes in approximately the same quantities. Every time an adult produces new gametes, there is a chance of a small, random mutation in the gamete size strategy. These mutations introduce a competition among multiple reproductive strategies. The model explores the conditions that may lead to this competition resulting in the emergence of two evolutionarily stable reproductive strategies: 1. produce numerous small gametes and 2. produce a handful of big gametes.

This model also allows you to test many different assumptions related to the evolution of the sperm-egg dichotomy (anisogamy) from a uniform gamete size strategy by changing the various parameters.

## HOW IT WORKS

Adults move around randomly and produce gametes after random time intervals. The number of gametes produced by an adult in a given reproduction cycle depends on its reproduction budget and its gamete size strategy. The smaller the gamete size, the more gametes an adult can produce in a cycle. The larger the gamete size, the fewer gametes an adult can produce in a cycle.

The gametes also move around randomly. When two gametes touch each other, they initiate a fusion process to form a zygote. One of the zygote's parents is selected randomly to pass on both its sex and its gamete size strategy to the zygote. However, the gamete size strategy is subject to small mutations that make the target gamete size smaller or bigger.

These new zygotes are non-mobile agents. They stay put and incubate. When they reach the end of their incubation period, they become adults if their mass is equal to or larger than the critical mass. If a zygote cannot reach the critical mass, it turns black and slowly dies off.

## HOW TO USE IT

The SETUP button creates the initial adult population. Each adult in the initial population is assigned one of the mating types (red or blue) randomly. They all start with the same gamete size strategy, which is half of the fixed reproduction budged.

Once the model has been set up, you are now ready to run it by pushing the GO button. The GO button starts the simulation and runs it continuously until it is pushed again.

The POPULATION-SIZE slider determines both the initial number of adults and the carrying capacity of the ecosystem. The carrying-capacity is enforced at the end of each tick, randomly removing the necessary number of adults from the ecosystem when the total number of adults exceeds the value set by the POPULATION-SIZE slider.

The GAMETE-PRODUCTION-BUDGET slider controls the total mass an adult can use to produce gametes.

The ZYGOTE-CRITICAL-MASS slider controls the critical mass a zygote needs to achieve in order to survive.

The MUTATION-STDEV slider controls the standard deviation of the random mutation in the gamete size strategy. A standard deviation is used because the mutation algorithm is based on a normal distribution with an expected value of the gamete size of the adult.

The SPEED-SIZE-RELATION? switch allows you to decide whether smaller gametes move faster than the larger gametes or all the gametes move at the same speed.

The ADULTS-MOVE? switch allows you to decide whether adults in the system move around or not.

The SAME-TYPE-MATING-ALLOWED? switch lets you choose whether or not gametes of the same color are allowed to fuse.

The ENFORCE-CRITICAL-MASS? switch lets you override the critical mass assumption. When ON, the undersized zygotes die. When OFF, all zygotes survive regardless of their total mass.

Because the some of the gametes in the model can be very very small, it is sometimes hard to observe them. Clicking the FOLLOW A RED GAMETE or FOLLOW A BLUE GAMETE button picks a randomly chosen gamete of that color and lets you follow it until it dies or fuses with another gamete.

## THINGS TO NOTICE

It takes quite some time to see any meaningful changes in the adults’ gamete size strategies. Even if it seems like the system is stable, let the model run at least for 5000 to 10000 ticks.

Notice that even if the gamete size strategies of the red adults and the blue adults may evolve to be dramatically different, this does not disrupt the overall population balance. The number of the red adults and the number of blue adults stay relatively stable no matter what.

The number of adults and the of the zygotes stay relatively constant in the model, regardless of the changes in the gamete size strategies. However, the number of gametes may dramatically change. Keep an eye out for spikes in the number of gametes and see how these spikes correspond to changes in the distribution of the gamete size strategies.

## THINGS TO TRY

Try changing the mutation rate (MUTATION-STDEV) and see if it makes any difference in terms of the eventual outcome of the model. Is there a scenario where anisogamy does not evolve? Is there a scenario where it evolves even faster?

Would anisogamy still evolve even if gametes of the same color can fuse? Try turning on the SAME-TYPE-MATING-ALLOWED? switch and see how it affects the eventual outcome of the model.

Does the initial distribution of mating types have an impact on the eventual outcome of the model? Try to run the model multiple times and see if the initial number of red adults versus the initial number of blue adults has anything to do with the eventual outcome of the model.

The ZYGOTE-CRITICAL-MASS value defaults to 0.45, which is just 0.05 less than the total reproduction budget of adults (0.5 or 50% of the total mass). Try modifying this value to discover whether smaller and larger critical masses requirements still result in anisogamy.

Initially, the adults in the model move around randomly. Try removing this ability by turning the ADULTS-MOVE? switch OFF. Does this make a difference in the model?

## EXTENDING THE MODEL

There might be scenarios where a population might have more than 2 mating types. Try increasing the number of mating types in this model to explore if it will still evolve to an anisogamous state.

In the model, it is assumed that all gametes have relatively similar lifetimes. However, this is not the case for many organisms: often sperm have brief lives while eggs survive for a much longer period of time. What would happen if the smaller gametes in this model had a shorter lifetime and the larger gametes had longer lifetimes? Try to implement this in the model by creating an algorithm that calculates the lifetime of each gamete based on its size.

## NETLOGO FEATURES

The RANDOM-NORMAL primitive is used to simulate the random mutations in gamete size strategy between the generations of adults through a normal distribution. The lifetime of adults and gametes, as well as the incubation time of zygotes, are also randomly selected from a normal distribution.

The DIFFUSE primitive is used to create a background that transitions from darker to lighter tones of cyan fluidly. This background represents a marine environment.

The PRECISION primitive is used to limit the number of floating point numbers in the size of gametes. This is a synthetic measure to prevent the model from evolving to a state where too many gametes are produced and the performance of the simulation is negatively affected.

The INSPECT and the STOP-INSPECTING-DEAD-AGENTS primitives are used to allow users to follow randomly selected gametes so that they can better observe gametes’ behavior at the individual level since the gametes are often hard to see in this model.

## RELATED MODELS

* Genetic drift models
* BEAGLE Evolution curricular models
* EACH curricular models

## CREDITS AND REFERENCES

Bulmer, M. G., & Parker, G. A. (2002). The evolution of anisogamy: a game-theoretic approach. Proceedings of the Royal Society B: Biological Sciences, 269(1507), 2381–2388. http://rspb.royalsocietypublishing.org/content/269/1507/2381

Togashi, T., & Cox, P. A. (Eds.). (2011). The evolution of anisogamy: a fundamental phenomenon underlying sexual selection. Cambridge University Press.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Aslan, U., Dabholkar, S. and Wilensky, U. (2016).  NetLogo Anisogamy model.  http://ccl.northwestern.edu/netlogo/models/Anisogamy.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 Cite: Aslan, U., Dabholkar, S. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

adult
false
15
Circle -1 true true 22 20 248
Circle -7500403 true false 108 106 72
Circle -16777216 true false 122 120 44

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

zygote
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="critical-mass200k" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200000"/>
    <metric>total-red-pop / 5000</metric>
    <metric>total-blue-pop / 5000</metric>
    <metric>mean [gamete-size] of adults with [color = red]</metric>
    <metric>mean [gamete-size] of adults with [color = blue]</metric>
    <steppedValueSet variable="zygote-critical-mass" first="0.01" step="0.01" last="0.5"/>
  </experiment>
  <experiment name="default20k" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>total-red-pop / 5000</metric>
    <metric>total-blue-pop / 5000</metric>
    <metric>mean [gamete-size] of adults with [color = red]</metric>
    <metric>mean [gamete-size] of adults with [color = blue]</metric>
  </experiment>
  <experiment name="critical-mass20k" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>total-red-pop / 5000</metric>
    <metric>total-blue-pop / 5000</metric>
    <metric>mean [gamete-size] of adults with [color = red]</metric>
    <metric>mean [gamete-size] of adults with [color = blue]</metric>
    <steppedValueSet variable="zygote-critical-mass" first="0.01" step="0.01" last="0.5"/>
  </experiment>
  <experiment name="alternativecricitalmass20k" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>total-red-pop / 5000</metric>
    <metric>total-blue-pop / 5000</metric>
    <metric>mean [gamete-size] of adults with [color = red]</metric>
    <metric>mean [gamete-size] of adults with [color = blue]</metric>
    <enumeratedValueSet variable="zygote-critical-mass">
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
