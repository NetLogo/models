breed [ foragers forager ] ; foragers are the main agents in the model
breed [ fruit-bushes fruit-bush ] ; bushes that are foraged from
breed [ deaths death ] ; red marks representing homicides

foragers-own
[
  energy ; metabolic energy
  genome ; list encoding parameters that is heritable
  foraging? ; boolean status whether forager is foraging
  fleeing? ; boolean status whether forager is fleeing
  fleeing-turns ; number of turns remaining to flee if fleeing
  age ; age of forager in ticks
  speed ; speed attribute determines movement
  strength ; strength attribute determines fighting success
  intelligence ; intelligence attribute determines group foraging rate
  reactive-aggression ; determines likelihood to threaten on arrival
  proactive-aggression ; determines likelihood to defend
]

fruit-bushes-own
[
  amount ; amount of energy in bush
]

deaths-own
[
  age ; persistence of red-X
]

globals
[
  murder-count ; total number of homicides
  starvation-count ; total number of starvation events
  age-death-count ; total deaths from old age
  death-count ; total of all deaths
  murder-rate ; rate of murders to all deaths
  starvation-rate ; rate of starvation events to all deaths
  age-death-rate ; rate of deaths from old age to all deaths
  total-foraged ; total amount foraged
  num-forages ; total number of forages
  avg-forage ; average yield of forages
  total-population ; total foragers in all ticks
  average-population ; average foragers alive in any given tick
]

to setup ; initial setup
  clear-all
  ask patches [ set pcolor 53 ]
  grow-fruit-bushes initial-fruit-bushes
  create-foragers initial-foragers
  [
    set shape "person"
    set color gray
    set size 2
    set xcor random-xcor
    set ycor random-ycor
    set energy 100
    set genome new-genome 240
    set foraging? false
    set fleeing? false
    set strength get-strength
    set speed get-speed
    set intelligence get-intelligence
    set reactive-aggression get-reactive-aggression
    set proactive-aggression get-proactive-aggression
    set age 0
  ]
  set total-population 0
  set murder-count 0
  set death-count 0
  set murder-rate 0
  set num-forages 0
  set total-foraged 0
  set avg-forage 0
  reset-ticks
end

to grow-fruit-bushes [ num-bushes ] ; procedure to create fruit-bushes on a grid without overlap
  ask n-of num-bushes patches with ; only spawn new bushes on patches spaced 3 apart
  [
    pxcor mod 3 = 0
    and pycor mod 3 = 0
    and (abs (pycor - max-pycor)) > 1 ; avoid being to closer to the edge
    and (abs (pxcor - max-pxcor)) > 1
    and (abs (pycor - min-pycor)) > 1
    and (abs (pxcor - min-pxcor)) > 1
    and not any? fruit-bushes-here
  ]
  [
    sprout-fruit-bushes 1
    [
      set shape "Bush"
      set color one-of [ red blue orange yellow ]
      set amount 500 + random 501
      set size 3
    ]
  ]
end

to go
  if not any? foragers [ stop ]
  ask deaths ; draw red Xs on the view
  [
    set age age + 1
    if age > 10 [ die ]
  ]
  if random 100 < bush-growth-chance [ grow-fruit-bushes 1 ]
  move-foragers ; producer to handle foragers' actions
  if-else (murder-count + age-death-count + starvation-count) = 0
  [
    set murder-rate 0
    set starvation-rate 0
    set age-death-rate 0
  ]
  [
    set murder-rate 100 * murder-count / (murder-count + age-death-count + starvation-count)
    set starvation-rate 100 * starvation-count / (murder-count + age-death-count + starvation-count)
    set age-death-rate 100 * age-death-count / (murder-count + age-death-count + starvation-count)
  ]
  if-else num-forages = 0
    [ set avg-forage 0 ]
    [ set avg-forage total-foraged / num-forages ]

  set total-population total-population + count foragers
  if-else ticks = 0
    [ set average-population 0 ]
    [ set average-population total-population / ticks ]
  tick
end

to move-foragers ; forager procedure
  ask foragers
  [
    if-else fleeing? ; if they are fleeing only move randomly
    [
      lt (random 31) - 15
      fd (speed / 60)
      set fleeing-turns fleeing-turns - 1
      if fleeing-turns = 0 [ set fleeing? false ]
    ]
    [
      if-else any? fruit-bushes in-radius 0.1 and foraging?
      [
        forage
      ]
      [
        set foraging? false
        if-else any? fruit-bushes in-radius 5
        [ ; face nearest fruit-bush in radius of 5 units
          face min-one-of fruit-bushes in-radius 5 [distance myself]
        ]
        [
          lt (random 31) - 15
        ]
        if-else any? fruit-bushes in-radius 1
        [ ; arrive at any fruit-bush closer than 1 unit away
          move-to one-of fruit-bushes in-radius 1
          arrive
        ]
        [
          fd (speed / 60)
          set energy energy - 1
        ]
        if energy < 0
        [
          set starvation-count starvation-count + 1
          die
        ]
        if energy > 200
        [ ; reproduce
          set energy energy - 100
          hatch-foragers 1
          [
            set genome mutate [genome] of myself rate-of-mutation
            set shape "person"
            set color gray
            set size 2
            set energy 100
            set foraging? false
            set fleeing? false
            set strength get-strength
            set speed get-speed
            set intelligence get-intelligence
            set reactive-aggression get-reactive-aggression
            set proactive-aggression get-proactive-aggression
            set age 0
          ]
        ]
      ]
    ]
    set age age + 1
    if age > max-age
    [
      set age-death-count age-death-count + 1
      die
    ]
    if-else show-energy?
      [ set label precision energy 0 ]
      [ set label " " ]
    (ifelse
      visualization = "Strength"
      [
        set color scale-color red strength 0 40
      ]
      visualization = "Speed"
      [
        set color scale-color green speed 0 40
      ]
      visualization = "Intelligence"
      [
        set color scale-color blue intelligence 0 40
      ]
      visualization = "Reactive Aggression"
      [
        set color scale-color orange reactive-aggression 0 40
      ]
      visualization = "Proactive Aggression"
      [
        set color scale-color 115 proactive-aggression 0 40
      ]
      [
        set color grey
    ])
  ]
end

to arrive ; forager procedure
  if-else any? other foragers in-radius 0.1
  [
    if-else random-float 1 < (reactive-aggression / 60)
    [ ; determines whether arriving forager threatens
      let count-fighters 0
      let total-strength 0
      ask other foragers in-radius 0.1
      [
        if-else random-float 1 < (proactive-aggression / 60)
        [ ; determines if other forager fights back
          set count-fighters count-fighters + 1
          set total-strength total-strength + strength
        ]
        [ ; they relent
          set foraging? false
          set fleeing? true
          set fleeing-turns ticks-to-flee
        ]
      ]
      if-else count-fighters > 0
      [
        if-else random-float 1 < (strength / ((total-strength * 0.75) + strength))
        [
          set murder-count murder-count + count-fighters
          ask other foragers in-radius 0.1 with [foraging?]
          [
            hatch-deaths 1 [set color red set shape "x" set age 0]
            die
          ]
        ]
        [
          set murder-count murder-count + 1
          hatch-deaths 1 [set color red set shape "x" set age 0]
          die
        ]
      ]
      [
        set foraging? true
      ]
    ]
    [ ; arriving forager cooperates
      let okay? true
      if (count other foragers in-radius 0.1) = 1
      [ ; if there is more than one forager present
        ; assume they have already cooperated
        ask other foragers in-radius 0.1
        [
          if random-float 1 < (reactive-aggression / 60)
          [ ; they threaten me
            set okay? false
          ]
        ]
      ]
      if-else okay?
      [
        set foraging? true
      ]
      [
        set fleeing? true
        set fleeing-turns ticks-to-flee
      ]
    ]
  ]
  [
    set foraging? true
  ]
end

to forage ; forager procedure
  let forage-rate 0
  if-else any? other foragers in-radius 0.1 with [foraging?]
  [ ; set foraging rate based on average group intelligence and collab-bonus
    let i-n sum [intelligence] of foragers in-radius 0.1 with [foraging?]
    let i-d (count foragers in-radius 0.1 with [foraging?]) * 20
    let i-ratio i-n / i-d
    set forage-rate i-ratio * 10 * collaboration-bonus
  ]
  [
    set forage-rate 10
  ]

  ask one-of fruit-bushes in-radius 0.1
  [
    set amount amount - 10
    if (amount < 0) [ die ]
  ]
  set energy energy + forage-rate
  set num-forages num-forages + 1
  set total-foraged total-foraged + forage-rate
end

to-report new-genome [ size-of ]
  let a-genome []
  repeat size-of [set a-genome lput random 2 a-genome]
  report a-genome
end

to-report mutate [ a-genome mutation-rate ]
  let n-genome []
  foreach a-genome [ x ->
    let roll random-float 100
    if-else roll < mutation-rate [
      if-else x = 1 [set n-genome lput 0 n-genome]
      [set n-genome lput 1 n-genome]
    ]
    [
      set n-genome lput x n-genome
    ]
  ]
  report n-genome
end

to-report divider1 ; forager reporter
  let s 0
  let c 0
  repeat 60 [set s s + item c genome set c c + 1]
  report s
end

to-report divider2 ; forager reporter
  let s 0
  let c 0
  repeat 60 [ set s s + item (c + 60) genome set c c + 1 ]
  report s
end

to-report get-intelligence ; forager reporter
  report min (list divider1 divider2)
end

to-report get-speed ; forager reporter
  report abs (divider1 - divider2)
end

to-report get-strength ; forager reporter
  report 60 - (max (list divider1 divider2))
end

to-report get-reactive-aggression ; forager reporter
  let s 0
  let c 0
  repeat 60 [ set s s + item (c + 120) genome set c c + 1 ]
  report s
end

to-report get-proactive-aggression ; forager reporter
  let s 0
  let c 0
  repeat 60 [ set s s + item (c + 180) genome set c c + 1 ]
  report s
end


; Copyright 2019 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
490
10
1148
669
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
-32
32
-32
32
1
1
1
ticks
30.0

BUTTON
35
90
98
123
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

SLIDER
4
12
209
45
initial-fruit-bushes
initial-fruit-bushes
0
40
40.0
1
1
NIL
HORIZONTAL

SLIDER
4
48
209
81
initial-foragers
initial-foragers
1
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
5
440
210
473
bush-growth-chance
bush-growth-chance
0
100
6.0
1
1
NIL
HORIZONTAL

BUTTON
102
90
165
123
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

MONITOR
5
235
95
280
Population
count foragers
17
1
11

SLIDER
5
285
210
318
ticks-to-flee
ticks-to-flee
0
100
49.0
1
1
NIL
HORIZONTAL

PLOT
215
330
485
480
Types of Aggression (Histogram)
NIL
NIL
0.0
61.0
0.0
10.0
true
true
"" ""
PENS
"Reactive" 1.0 1 -817084 true "" "histogram [reactive-aggression] of foragers"
"Proactive" 1.0 1 -5825686 true "" "histogram [proactive-aggression] of foragers"

SLIDER
5
400
210
433
max-age
max-age
1
500
500.0
1
1
NIL
HORIZONTAL

PLOT
215
10
485
170
Deaths by Type
Ticks
Percent
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Murders" 1.0 0 -16777216 true "" "plot murder-rate"
"Old Age" 1.0 0 -8431303 true "" "plot age-death-rate"
"Starvation" 1.0 0 -15302303 true "" "plot starvation-rate"

PLOT
5
485
210
635
Forage Rate
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
"default" 1.0 0 -16777216 true "" "plot avg-forage"

SLIDER
5
360
210
393
collaboration-bonus
collaboration-bonus
0.1
5
5.0
0.01
1
NIL
HORIZONTAL

PLOT
215
485
485
635
Traits over Time
Ticks
 Values
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Strength" 1.0 0 -2674135 true "" "plot mean [strength] of foragers"
"Speed" 1.0 0 -13840069 true "" "plot mean [speed] of foragers"
"Intelligence" 1.0 0 -13345367 true "" "plot mean [intelligence] of foragers"

SLIDER
5
323
210
356
rate-of-mutation
rate-of-mutation
0
10
1.0
0.1
1
NIL
HORIZONTAL

MONITOR
95
235
205
280
Avg Population
precision average-population 3
17
1
11

PLOT
215
175
485
325
Types of Aggression (Mean)
Ticks
Value
0.0
10.0
0.0
60.0
true
true
"" ""
PENS
"Reactive" 1.0 0 -817084 true "" "plot mean [reactive-aggression] of foragers"
"Proactive" 1.0 0 -5825686 true "" "plot mean [proactive-aggression] of foragers"

SWITCH
35
130
177
163
show-energy?
show-energy?
1
1
-1000

CHOOSER
20
170
182
215
visualization
visualization
"None" "Reactive Aggression" "Proactive Aggression" "Strength" "Speed" "Intelligence"
1

@#$#@#$#@
## WHAT IS IT?

The Fruit Wars model is intended to demonstrate how non-zero-sum economic environments can encourage cooperation and discourage violence. The foragers wander the map looking for fruit bushes. When they arrive at a fruit bush they gain energy through foraging until the fruit bush is exhausted of resources. These animals reproduce and pass on their characteristics to their offspring after gathering a certain amount of energy. They also make decisions based on heritable parameters about how to interact with other foraging animals. The foragers can choose to cooperate, threaten, fight or flee under different circumcstances.

In the model, foragers can either cooperate or fight based on heritable aggression attributes. The COLLABORATION-BONUS parameter in the model controls how beneficial cooperation is in terms of foraging and so one should expect to see the evolutionary equilbrium of the system move toward foragers with less violent tendencies when the model is run with higher COLLABORATION-BONUS settings.

## HOW IT WORKS

__Foragers__ in the model have 240-bit binary genomes:

- The sum of the first 120 bits determines the __strength__, __speed__ and __intelligence__ of the __foragers__. These three stats can have any values between 0 and 60, but their sum must always be 60.

- The sum of bits 120 to 180 determine the __forager__'s __reactive-aggression__, which determines the tendency to threaten when arriving at a bush and the tendency to threaten new arrivals when already at a bush. The sum of bits 180 to 240 determine the forager's __proactive-aggression__, which determines the tendency to fight back when threatened.

__Each Tick in the Model:__

_For each Forager:_

- If no bushes are very nearby or my status is __fleeing__, move randomly based on the __speed__ attribute. Consume 1 energy.

- If there is a bush nearby, move toward it a distance based on the __speed__ attribute. Consume 1 energy.

- If I am very close to a bush, do the __arrival__ procedure.

- If my status is __foraging__, gain some energy and take that energy away from the bush. If the bush runs out of energy, make it die, and remove the __foraging__ status from all other __foragers__ at that bush.

- If my energy is above 200, reproduce, lose 100 energy.

- If out of energy or older than the max-age parameter, die.

_The arrival procedure:_

- If there are no other __foragers__ at the fruit bush, set status to __foraging__.

- If there are other __foragers__ at the bush, the arriving __forager__ chooses to threaten or collaborate probabalistically based on its __reactive-aggression__ value.

- If my choice is __threaten__, other __foragers__ at the bush choose to __flee__ or __fight back__ according to their __proactive-aggression__ parameter.

    - If any __fight back__, the arriving __forager__ wins with a probability based on the difference of the arriving __forager__'s __strength__ and the aggregate __strength__ of all the other __foragers__ choosing to __fight back__. If the arriving forager wins all of the __foragers__ choosing to __fight back die__, otherwise the arriving __forager__ dies.

    - If all the other __foragers__ __flee__, the arriving __forager__ sets its status to __foraging__.

- If the arriving __forager__ chooses to __collaborate__ and there is one other present __forager__, that __forager__ chooses to either allow the arriving __forager__ to join or to __threaten__ causing the arriving __forager__ to flee.

    - If there is only one __forager__ present and it doesn't __threaten__, or there are multiple __foragers__ present, the status of the arriving __forager__ is set to __foraging__.


_Reproduction_:

Each __forager__ has a binary genome which encodes the values of its parameters. When the __foragers__ reproduce (asexually), the genome is passed on to the offspring and each position in the genome has a __rate-of-mutation__ chance to flip values.

## HOW TO USE IT

1. Set the __parameters__ as desired.

2. Click SETUP.

3. Click GO.

__Setup Parameters:__

- INITIAL-FRUIT-BUSHES - The number of fruit bushes at the start.

- INITIAL-FORAGERS - The number of foragers at the start.

__Visualization Parameters:__

- SHOW-ENERGY? - displays the current energy of each individual forager in the view if enabled.

- VISUALIZATION - scales the color of the agent depending on the selection based on the value of that parameter with lighter colors representing a higher value.

__Runtime Parameters:__

- BUSH-GROWTH-CHANCE - The chance for a new fruit bush to grow at each turn.

- TICKS-TO-FLEE - When a forager flees, this is the number of ticks it must move randomly before it can seek a new fruit bush.

- RATE-OF-MUTATION - The probability that an individual bit will flip during the passage of bit genome from parent to offspring.

- COLLABORATION-BONUS - A factor used to determine the collaborative rate of foraging. Higher collaboration bonus means higher foraging rates for multiple foragers at a single bush.

- MAX-AGE - The maximum number of ticks an individual forager can live.

## THINGS TO NOTICE

Observe the behavior of the foraging animals as they move around the map. Do you notice any of them fleeing from the fruit bushes? Do you notice many fatalities due to violent encounters (marked in the view by a red X?) How large of population can be sustained by the environment?

The model also has many graphs to observe:

- A histogram of different forager attributes at each tick.

- A standard line graph of the forager attributes at each tick.

- A graph of the ratio of homicides to other deaths.

- A graph of the average foraging rate per tick.

## THINGS TO TRY

Try the different VISUALIZATION modes and observe the changes in the agent population at different model speeds and parameter settings. What sorts of patterns emerge?

Try adjusting the COLLABORATION-BONUS parameter. Oberve the behaviors and graphs discussed in the previous section. How do they vary with the COLLABORATION-BONUS parameter? How long does it generally take the model to reach a somewhat stable state, if ever?

## EXTENDING THE MODEL

Extend the model such that foragers can fight, but not necessarily die. Also, add a mechanic so that if a forager is defeated in a fight, the victorious forager can take all or most of its resources. Additionally, one might incorporate some mechanism such that the foragers' likelihood to fight is determined by some function of their hunger.

## NETLOGO FEATURES

This model makes extensive use of [mutable] (https://en.wikipedia.org/wiki/Immutable_object) NetLogo lists to implement bit genomes for agent evolution. It also uses custom turtle shapes designed in the *Turtle Shapes Editor*.

## RELATED MODELS

* Altriusm

* Cooperation

* Braess' Paradox

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rasmussen, L. and Wilensky, U. (2019).  NetLogo Fruit Wars model.  http://ccl.northwestern.edu/netlogo/models/FruitWars.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2019 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2019 Cite: Rasmussen, L. -->
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

bush
false
0
Circle -10899396 true false 178 108 94
Rectangle -6459832 true false 120 255 180 300
Circle -10899396 true false 125 66 108
Circle -10899396 true false 11 116 127
Circle -10899396 true false 45 165 120
Circle -10899396 true false 119 134 152
Circle -10899396 true false 58 73 124
Circle -7500403 true true 90 120 30
Circle -7500403 true true 120 165 30
Circle -7500403 true true 165 105 30
Circle -7500403 true true 180 165 30
Circle -7500403 true true 45 165 30
Circle -7500403 true true 75 210 30
Circle -7500403 true true 150 225 30
Circle -7500403 true true 210 210 30
Circle -7500403 true true 225 135 30

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
