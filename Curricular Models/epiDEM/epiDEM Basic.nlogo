globals
[
  nb-infected-previous  ;; Number of infected people at the previous tick
  beta-n                ;; The average number of new secondary
                        ;; infections per infected this tick
  gamma                 ;; The average number of new recoveries
                        ;; per infected this tick
  r0                    ;; The number of secondary infections that arise
                        ;; due to a single infected introduced in a wholly
                        ;; susceptible population
]

turtles-own
[
  infected?           ;; If true, the person is infected
  cured?              ;; If true, the person has lived through an infection.
                      ;; They cannot be re-infected.
  susceptible?        ;; Tracks whether the person was initially susceptible
  infection-length    ;; How long the person has been infected
  recovery-time       ;; Time (in hours) it takes before the person has a chance to recover from the infection
  nb-infected         ;; Number of secondary infections caused by an
                      ;; infected person at the end of the tick
  nb-recovered        ;; Number of recovered people at the end of the tick
]


;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  setup-people
  reset-ticks
end


to setup-people
  create-turtles initial-people
  [
    setxy random-xcor random-ycor
    set cured? false
    set infected? false
    set susceptible? true

    set shape "person"
    set color white

    ;; Set the recovery time for each agent to fall on a
    ;; normal distribution around average recovery time
    set recovery-time random-normal average-recovery-time average-recovery-time / 4

    ;; make sure it lies between 0 and 2x average-recovery-time
    if recovery-time > average-recovery-time * 2 [
      set recovery-time average-recovery-time * 2
    ]
    if recovery-time < 0 [ set recovery-time 0 ]

    ;; Each individual has a 5% chance of starting out infected.
    ;; To mimic true KM conditions use "ask one-of turtles" instead.
    if (random-float 100 < 5)
    [
      set infected? true
      set susceptible? false
      set infection-length random recovery-time
    ]
    assign-color
  ]
end

;; Different people are displayed in 3 different colors depending on health
;; White is neither infected nor cured (set at beginning)
;; Green is a cured person
;; Red is an infected person

to assign-color  ;; turtle procedure
  if infected?
    [ set color red ]
  if cured?
    [ set color green ]
end


;;;
;;; GO PROCEDURES
;;;


to go
  if all? turtles [ not infected? ]
    [ stop ]

  ask turtles
    [ move
      clear-count ]

  ask turtles with [ infected? ]
    [ infect
      maybe-recover ]

  ask turtles
    [ assign-color
      calculate-r0 ]

  tick
end


;; People move about at random.
to move  ;; turtle procedure
  rt random-float 360
  fd 1
end

to clear-count
  set nb-infected 0
  set nb-recovered 0
end

;; Infection can occur to any susceptible person nearby
to infect  ;; turtle procedure
   let nearby-uninfected (turtles-on neighbors)
     with [ not infected? and not cured? ]

     if nearby-uninfected != nobody
     [ ask nearby-uninfected
       [ if random-float 100 < infection-chance
         [ set infected? true
           set nb-infected (nb-infected + 1)
         ]
       ]
     ]
end

to maybe-recover
  set infection-length infection-length + 1

  ;; If people have been infected for more than the recovery-time
  ;; then there is a chance for recovery
  if infection-length > recovery-time
  [
    if random-float 100 < recovery-chance
    [ set infected? false
      set cured? true
      set nb-recovered (nb-recovered + 1)
    ]
  ]
end

to calculate-r0

  let new-infected sum [ nb-infected ] of turtles
  let new-recovered sum [ nb-recovered ] of turtles

  ;; Number of infected people at the previous tick:
  set nb-infected-previous
    count turtles with [ infected? ] +
    new-recovered - new-infected

  ;; Number of susceptibles now:
  let susceptible-t
    initial-people -
    count turtles with [ infected? ] -
    count turtles with [ cured? ]

  ;; Initial number of susceptibles:
  let s0 count turtles with [ susceptible? ]

  ifelse nb-infected-previous < 10
  [ set beta-n 0 ]
  [
    ;; This is beta-n, the average number of new
    ;; secondary infections per infected per tick
    set beta-n (new-infected / nb-infected-previous)
  ]

  ifelse nb-infected-previous < 10
  [ set gamma 0 ]
  [
    ;; This is the average number of new recoveries per infected per tick
    set gamma (new-recovered / nb-infected-previous)
  ]

  ;; Prevent division by 0:
  if initial-people - susceptible-t != 0 and susceptible-t != 0
  [
    ;; This is derived from integrating dI / dS = (beta*SI - gamma*I) / (-beta*SI):
    set r0 (ln (s0 / susceptible-t) / (initial-people - susceptible-t))
    ;; Assuming one infected individual introduced in the beginning,
    ;; and hence counting I(0) as negligible, we get the relation:
    ;; N - gamma*ln(S(0)) / beta = S(t) - gamma*ln(S(t)) / beta,
    ;; where N is the initial 'susceptible' population
    ;; Since N >> 1
    ;; Using this, we have R_0 = beta*N / gamma = N*ln(S(0)/S(t)) / (K-S(t))
    set r0 r0 * s0 ]
end


; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
644
13
1102
472
-1
-1
18.0
1
10
1
1
1
0
1
1
1
-12
12
-12
12
1
1
1
hours
30.0

BUTTON
233
112
316
145
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
333
112
416
145
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
46
14
315
47
initial-people
initial-people
50
400
100.0
5
1
NIL
HORIZONTAL

PLOT
342
165
636
295
Populations
hours
# of people
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plot count turtles with [ infected? ]"
"Not Infected" 1.0 0 -10899396 true "" "plot count turtles with [ not infected? ]"

PLOT
15
307
334
443
Infection and Recovery Rates
hours
rate
0.0
0.2
0.0
0.2
true
true
"" ""
PENS
"Infection Rate" 1.0 0 -2674135 true "" "plot (beta-n * nb-infected-previous)"
"Recovery Rate" 1.0 0 -10899396 true "" "plot (gamma * nb-infected-previous)"

SLIDER
46
60
314
93
infection-chance
infection-chance
10
100
30.0
5
1
NIL
HORIZONTAL

SLIDER
332
15
599
48
recovery-chance
recovery-chance
10
100
60.0
5
1
NIL
HORIZONTAL

PLOT
15
165
333
293
Cumulative Infected and Recovered
hours
% total pop
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"% infected" 1.0 0 -2674135 true "" "plot (((count turtles with [ cured? ] + count turtles with [ infected? ]) / initial-people) * 100)"
"% recovered" 1.0 0 -10899396 true "" "plot ((count turtles with [ cured? ] / initial-people) * 100)"

SLIDER
331
57
600
90
average-recovery-time
average-recovery-time
50
300
210.0
10
1
NIL
HORIZONTAL

MONITOR
427
352
506
397
R0
r0
2
1
11

@#$#@#$#@
## WHAT IS IT?

This model simulates the spread of an infectious disease in a closed population. It is an introductory model in the curricular unit called epiDEM (Epidemiology: Understanding Disease Dynamics and Emergence through Modeling). This particular model is formulated based on a mathematical model that describes the systemic dynamics of a phenomenon that emerges when one infected person is introduced in a wholly susceptible population. This basic model, in mathematical epidemiology, is known as the Kermack-McKendrick model.

The Kermack-McKendrick model assumes a closed population, meaning there are no births, deaths, or travel into or out of the population. It also assumes that there is homogeneous mixing, in that each person in the world has the same chance of interacting with any other person within the world. In terms of the virus, the model assumes that there are no latent or dormant periods, nor a chance of viral mutation.

Because this model is so simplistic in nature, it facilitates mathematical analyses and also the calculation of the threshold at which an epidemic is expected to occur. We call this the reproduction number, and denote it as R_0. Simply, R_0 stands for the number of secondary infections that arise as a result of introducing one infected person in a wholly susceptible population, over the course of the infected person's contagious period (i.e. while the person is infective, which, in this model, is from the beginning of infection until recovery).

This model incorporates all of the above assumptions, but each individual has a 5% chance of being initialized as infected. This model shows the disease spread as a phenomenon with an element of stochasticity. Small perturbations in the parameters included here can in fact lead to different final outcomes.

Overall, this model helps users
1) engage in a new way of viewing/modeling epidemics that is more personable and relatable
2) understand how the reproduction number, R_0, represents the threshold for an epidemic
3) think about different ways to calculate R_0, and the strengths and weaknesses in each approach
4) understand the relationship between derivatives and integrals, represented simply as rates and cumulative number of cases, and
5) provide opportunities to extend or change the model to include some properties of a disease that interest users the most.

## HOW IT WORKS

Individuals wander around the world in random motion. Upon coming into contact with an infected person, by being in any of the eight surrounding neighbors of the infected person or in the same location, an uninfected individual has a chance of contracting the illness. The user sets the number of people in the world, as well as the probability of contracting the disease.

An infected person has a probability of recovering after reaching their recovery time period, which is also set by the user. The recovery time of each individual is determined by pulling from an approximately normal distribution with a mean of the average recovery time set by the user.

The colors of the individuals indicate the state of their health. Three colors are used: white individuals are uninfected, red individuals are infected, green individuals are recovered. Once recovered, the individual is permanently immune to the virus.

The graph INFECTION AND RECOVERY RATES shows the rate of change of the cumulative infected and recovered in the population. It tracks the average number of secondary infections and recoveries per tick. The reproduction number is calculated under different assumptions than those of the Kermack McKendrick model, as we allow for more than one infected individual in the population, and introduce aforementioned variables.

At the end of the simulation, the R_0 reflects the estimate of the reproduction number, the final size relation that indicates whether there will be (or there was, in the model sense) an epidemic. This again closely follows the mathematical derivation that R_0 = beta*S(0)/ gamma = N*ln(S(0) / S(t)) / (N - S(t)), where N is the total population, S(0) is the initial number of susceptibles, and S(t) is the total number of susceptibles at time t. In this model, the R_0 estimate is the number of secondary infections that arise for an average infected individual over the course of the person's infected period.

## HOW TO USE IT

The SETUP button creates individuals according to the parameter values chosen by the user. Each individual has a 5% chance of being initialized as infected. Once the model has been setup, push the GO button to run the model. GO starts the model and runs it continuously until GO is pushed again.

Note that in this model each time-step can be considered to be in hours, although any suitable time unit will do.

What follows is a summary of the sliders in the model.

INITIAL-PEOPLE (initialized to vary between 50 - 400): The total number of individuals in the simulation, determined by the user.
INFECTION-CHANCE (10 - 100): Probability of disease transmission from one individual to another.
RECOVERY-CHANCE (10 - 100): Probability of an infected individual to recover once the infection has lasted longer than the person's recovery time.
AVERAGE-RECOVERY-TIME (50 - 300): The time it takes for an individual to recover on average. The actual individual's recovery time is pulled from a normal distribution centered around the AVERAGE-RECOVERY-TIME at its mean, with a standard deviation of a quarter of the AVERAGE-RECOVERY-TIME. Each time-step can be considered to be in hours, although any suitable time unit will do.

A number of graphs are also plotted in this model.

CUMULATIVE INFECTED AND RECOVERED: This plots the total percentage of infected and recovered individuals over the course of the disease spread.
POPULATIONS: This plots the total number of people with or without the flu over time.
INFECTION AND RECOVERY RATES: This plots the estimated rates at which the disease is spreading. BetaN is the rate at which the cumulative infected changes, and Gamma rate at which the cumulative recovered changes.
R_0: This is an estimate of the reproduction number, only comparable to the Kermack McKendrick's definition if the initial number of infected were 1.

## THINGS TO NOTICE

As with many epidemiological models, the number of people becoming infected over time, in the event of an epidemic, traces out an "S-curve." It is called an S-curve because it is shaped like a sideways S. By changing the values of the parameters using the slider, try to see what kinds of changes make the S curve stretch or shrink.

Whenever there's a spread of the disease that reaches most of the population, we say that there was an epidemic. As mentioned before, the reproduction number indicates the number of secondary infections that arise as a result of introducing one infected person in a totally susceptible population, over the course of the infected person's contagious period (i.e. while the person is infected). If it is greater than 1, an epidemic occurs. If it is less than 1, then it is likely that the disease spread will stop short, and we call this an endemic.

## THINGS TO TRY

Try running the model by varying one slider at a time. For example:
How does increasing the number of initial people affect the disease spread?
How does increasing the recovery chance the shape of the graphs? What about changes to average recovery time? Or the infection rate?

What happens to the shape of the graphs as you increase the recovery chance and decrease the recovery time? Vice versa?

Notice the graph Cumulative Infected and Recovered, and Infection and Recovery Rates. What are the relationships between the two? Why is the latter graph jagged?

## EXTENDING THE MODEL

Try to change the behavior of the people once they are infected. For example, once infected, the individual might move slower, have fewer contacts, isolate him or herself etc. Try to think about how you would introduce such a variable.

In this model, we also assume that the population is closed. Can you think of ways to include demographic variables such as births, deaths, and travel to mirror more of the complexities that surround the nature of epidemic research?

## NETLOGO FEATURES

Notice that each agent pulls from a truncated normal distribution, centered around the AVERAGE-RECOVERY-TIME set by the user. This is to account for the variation in genetic differences and the immune system functions of individuals.

Notice that R_0 calculated in this model is a numerical estimate to the analytic R_0. In the special case of one infective introduced to a wholly susceptible population (i.e., the Kermack-McKendrick assumptions), the numerical estimations of R0 are very close to the analytic values.

## RELATED MODELS

HIV, Virus and Virus on a Network are related models.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Yang, C. and Wilensky, U. (2011).  NetLogo epiDEM Basic model.  http://ccl.northwestern.edu/netlogo/models/epiDEMBasic.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Yang, C. -->
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

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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
0
@#$#@#$#@
