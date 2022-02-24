globals [
  adult-sex-ratio-list     ; tracks adult-sex-ratio at each tick to compute running average and standard deviation
  age-list                 ; list of ages of dead individuals
  adult-age                ; tracks the age of adulthood
]

breed [ males male ]
breed [ females female ]

females-own [
  partner                ; a variable to temporarily store a mating-partner
  carrying?              ; a boolean to track if a female is carrying a child after mating
  male-child-chance      ; this is a trait variable that influences the probability of giving birth to a male child
  temp-male-child-chance ; stores male-child-chance for a particular father-mother pair
  gestation              ; tracks the time of carrying a child till a female reaches gestation-period
  age                    ; to keep track of age
  longevity              ; gets assigned at birth - age up to which an individual lives
  num-of-exes            ; tracks mating partners an individual had in its life
  num-of-children        ; tracks how many children an individual had
  adult?                 ; boolean to flag if this agent is an adult
]

males-own [
  partner               ; a variable to temporary store a mating-partner
  male-child-chance     ; this is a trait variable that influences the probability of giving birth to a male child
  age                   ; tracks of age
  longevity             ; gets assigned at birth - age up to which an individual lives
  num-of-exes           ; tracks mating partners an individual had in its life
  num-of-children       ; track how many children it has
  adult?                ; boolean to flag if this agent is an adult
]

; setup the population of males and females
to setup
  clear-all
  set-default-shape males "dot"
  set-default-shape females "dot"

  ; Create male agents and initialize them
  create-males round ( (initial-adult-sex-ratio / 100  ) * initial-population-size ) [
    setxy random-xcor random-ycor
    set size 2
    set color green

    ; males are assigned initial male-child-chance from a random-normal distribution
    set male-child-chance random-normal initial-average-male-child-chance 0.05

    ; curtail negative or greater-than-1 probabilities
    if male-child-chance < 0 [ set male-child-chance 0 ]
    if male-child-chance > 1 [ set male-child-chance 1 ]

    ; initialize turtle variables
    set age int (random-normal (mean-longevity / 2) (mean-longevity / 10))
    set longevity int (random-normal mean-longevity (mean-longevity / 10))
    set partner nobody
    set num-of-exes 0
    set num-of-children 0
    set adult? True
  ]

  ; Create female agents and initialize them
  create-females initial-population-size - count males [
    setxy random-xcor random-ycor
    set size 2
    set color blue
    set partner nobody
    set carrying? false

    ; females are assigned initial male-child-chance from a random-normal distribution
    set male-child-chance random-normal initial-average-male-child-chance 0.05
    ; curtail negative or greater-than-1 probabilities
    if male-child-chance < 0 [ set male-child-chance 0 ]
    if male-child-chance > 1 [ set male-child-chance 1 ]

    ; initialize rest of turtle variables
    set gestation 0
    set age int (random-normal (mean-longevity / 2) (mean-longevity / 10))
    set longevity int (random-normal mean-longevity (mean-longevity / 10))
    set num-of-exes 0
    set num-of-children 0
    set adult? True
  ]

  set adult-sex-ratio-list []
  set age-list []
  set adult-age int (0.15 * mean-longevity) ; Agents with age more than 25% of mean-longevity are considered adult

  reset-ticks
end

to go
  if not any? turtles [ stop ]

  ask turtles [ check-if-dead ]

  ask males [
    move
    if [age] of self > adult-age [ set adult? True ]
  ]

  ask males with [adult?] [ search-for-an-adult-partner ]

  ask females [
    if not carrying? [ move ]
    if [age] of self > adult-age [ set adult? True ]
  ]

  ask females with [adult?] [reproduce]

  update-adult-sex-ratio-list
  tick
end

; procedure to move randomly
to move ; turtle procedure
  rt random 60
  lt random 60
  fd 0.1
end

; procedure to find an adult partner
to search-for-an-adult-partner  ; a male procedure

  ; enforce a spatial restriction to incorporate density-dependent growth rate
  ; this is a common empirically validated assumption in many evolution models
  if count females in-radius 1 with [not carrying? and adult?] = 1
      and count other males with [adult?] in-radius 1 = 0  [
    set partner one-of females with [adult?] in-radius 1 with [not carrying?]
  ]

  if partner = nobody [ stop ]

  ; successful mating leads to conception 100% of times in the model
  ifelse random-float 1 < mating-chance [
    ask partner [
      set partner myself
      set carrying? true
      set color orange    ; color oragne indicates carrying female
      set num-of-exes num-of-exes + 1
      ; sex of a child is determined by male-child-chance (determined by father and mother)
      ; this is a part of the fundamental assumption in Fisher's model
      ; autosomal inheritance of sex-determination-mechanism
      set temp-male-child-chance ( male-child-chance + [male-child-chance] of myself ) / 2
    ]
    ; reset partner to nobody, so that this male agent can mate with other females immediately
    set partner nobody
    set num-of-exes num-of-exes + 1
  ][ ; mating unsuccessful
    set partner nobody
  ]
  end

to reproduce ; a female procedure
  if carrying? [
    ; gestation-period can be set by user
    ; When it's over, a female gives birth to a a child, starts afresh and can have a new partner
    ; reset variables associated with pregnancy
    ifelse gestation = gestation-period [
      set gestation 0
      set carrying? false
      set color blue
      ; determine the litter size for this reproduction
      let temp-litter-size random maximum-litter-size + 1
      repeat temp-litter-size [
        ; if the case corresponds to the chance of having a male child
        ifelse random-float 1 < temp-male-child-chance [
          hatch-males 1 [
            set color green
            set partner nobody
            ; inheritance of male-child-chance is determined by father and mother.
            set male-child-chance random-normal [temp-male-child-chance] of myself 0.05
            ; curtail negative or greater-than-1 probabilities
            if male-child-chance < 0 [ set male-child-chance 0 ]
            if male-child-chance > 1 [ set male-child-chance 1 ]
            set heading random 360
            set age 0
            set longevity int (random-normal mean-longevity (mean-longevity / 10))
            set num-of-exes 0
            set num-of-children 0
          ]
        ][ ; else corresponds to the chance of having a female child
          hatch-females 1 [
            set color blue
            set partner nobody
            set carrying? false
            ; inheritance of male-child-chance is determined by father and mother.
            set male-child-chance random-normal [temp-male-child-chance] of myself 0.05
            ; curtail negative or greater-than-1 probabilities
            if male-child-chance < 0 [ set male-child-chance 0 ]
            if male-child-chance > 1 [ set male-child-chance 1 ]
            set temp-male-child-chance 0
            set heading random 360
            set gestation 0
            set age 0
            set longevity int (random-normal mean-longevity (mean-longevity / 10))
            set num-of-exes 0
            set num-of-children 0
          ]
        ]
      ]
      ; if polygamy is allowed, no need to reset "partner" of the male partner to nobody
      if partner != nobody [
        ; if the male partner still alive, update his number of children
        ask partner [set num-of-children num-of-children + temp-litter-size]
      ]
      set num-of-children num-of-children + temp-litter-size ; update my number of children
      set partner nobody ; this female agent can go find herself another man
    ][ ; else case for the reproduce procedure.
      set gestation gestation + 1  ; update the length of pregnancy
    ]
  ]
end

; if an individual is older than the assigned longevity it dies
to check-if-dead ; turtle procedure
  ifelse age > longevity [
    set age-list lput [age] of self age-list
    die
  ][
    set age age + 1
  ]
end

;;; Reporters for plotting ;;;
to-report adult-sex-ratio
  let adult-turtles turtles with [adult?]
  let adult-males males with [adult?]
  ifelse any? adult-turtles [
    report ( count males  / count adult-turtles ) * 100
  ][
    report 0
  ]
end

to-report average-male-child-chance
  ifelse any? turtles [
    report mean [male-child-chance] of turtles
  ][
    report 0
  ]
end

to update-adult-sex-ratio-list
  set adult-sex-ratio-list lput adult-sex-ratio adult-sex-ratio-list
end

to-report female-mating-success
  report precision (mean [num-of-exes] of females) 2
end

to-report male-mating-success
  report precision (mean [num-of-exes] of males) 2
end

to-report running-average-adult-sex-ratio
  ifelse length adult-sex-ratio-list > 1000 [
    report precision mean (sublist adult-sex-ratio-list (length (adult-sex-ratio-list) - 1000) length (adult-sex-ratio-list)) 2]
  [report "NA"]
end

to-report running-sd-adult-sex-ratio
  ifelse length adult-sex-ratio-list > 1000 [
    report precision standard-deviation (sublist adult-sex-ratio-list (length (adult-sex-ratio-list) - 1000) length (adult-sex-ratio-list)) 2]
  [report "NA"]
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
265
10
801
355
-1
-1
16.0
1
10
1
1
1
0
1
1
1
-16
16
-10
10
1
1
1
ticks
30.0

BUTTON
5
360
260
450
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
5
40
260
73
initial-population-size
initial-population-size
50
1000
500.0
10
1
NIL
HORIZONTAL

SLIDER
5
79
260
112
initial-adult-sex-ratio
initial-adult-sex-ratio
0
100
35.0
1
1
%
HORIZONTAL

SLIDER
5
120
260
153
initial-average-male-child-chance
initial-average-male-child-chance
0
1
0.4
0.01
1
NIL
HORIZONTAL

BUTTON
5
460
260
555
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
805
10
1080
180
Adult Sex Ratio (ASR)
Ticks
Sex Ratio
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot adult-sex-ratio"
"pen-1" 1.0 0 -2674135 true "" "plot 50"

PLOT
805
185
1080
355
Average Male Child Chance
Ticks
Average
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot average-male-child-chance"
"pen-1" 1.0 0 -2674135 true "" "plot 0.5"

SLIDER
5
235
260
268
gestation-period
gestation-period
0
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
5
275
260
308
maximum-litter-size
maximum-litter-size
1
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
5
315
260
348
mating-chance
mating-chance
0
1
0.85
0.05
1
NIL
HORIZONTAL

PLOT
265
410
800
555
Gender Distribution
Ticks
Count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Males" 1.0 0 -13840069 true "" "plot count males"
"Carrying females" 1.0 0 -955883 true "" "plot count females with [ carrying? ]"
"Females not carrying" 1.0 0 -13345367 true "" "plot count females with [ not carrying? ]"
"All females" 1.0 0 -8630108 true "" "plot count females"

SLIDER
5
160
260
193
mean-longevity
mean-longevity
0
150
60.0
5
1
NIL
HORIZONTAL

MONITOR
405
360
600
405
Running mean of ASR
running-average-adult-sex-ratio
17
1
11

MONITOR
605
360
800
405
Running std dev of ASR
running-sd-adult-sex-ratio
17
1
11

MONITOR
265
360
400
405
Adult Sex Ratio (ASR)
adult-sex-ratio
2
1
11

PLOT
805
360
1080
555
Mating Success Ratio (Male to Female)
Ticks
Ratio
0.0
10.0
0.0
1.2
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if female-mating-success != 0 [\n  plot precision (male-mating-success / female-mating-success) 3\n]"
"pen-1" 1.0 0 -2674135 true "" "plot 1"

TEXTBOX
55
15
240
51
Population Parameters
14
0.0
1

TEXTBOX
55
210
250
246
Individual Parameters
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model investigates emergent patterns in a demographic property of a population: the adult sex ratio (ASR). ASR is defined as the ratio of males to females in the adult population. Most sexually reproducing organisms have an ASR of 1:1. Fisher (1930) explains a rationale for this phenomenon based on natural selection, irrespective of a particular mechanism of sex-determination, which is now known as Fisher’s principle (Hamilton, 1967).

This model is based on Fisher's assumptions of biparentism and [Mendelian inheritance](https://en.wikipedia.org/wiki/Mendelian_inheritance).
It allows user to explore the emergence of the Fisherian Sex Ratio (1:1) across a wide range of initial sex-ratios and life-history traits.

## HOW IT WORKS

This is a population dynamics model of sexually reproducing organisms. The demographic changes in the population as well as the adult sex ratio are plotted as the time progresses.

There are two types of individuals in the model:
- *Males* (Indicated by green color)
- *Females* (Indicated by blue color if not carrying a child and indicated by orange color if carrying a child)

At every time-step the individuals:
- Age and check if dead – a random value of longevity is assigned at birth if an agent’s age is more than that value it dies
- Move randomly
- Search for an adult partner if *male*. This procedure involves mating, which is dependent on the assigned value of the mating chance. If agents mate, the *female* carries. (For simplicity, the mating chance in this model incorporates conception-chance as well.)
- Reproduce if *female*

The genetic mechanism of influencing the proportion of *male* children in the litter is abstracted as a parameter, called MALE-CHILD-CHANCE. Each *male* and *female* carry a trait called MALE-CHILD-CHANCE. This determines the probability of a child being *male*. In this basic model, the sex of the child is equally influenced by the MALE-CHILD-CHANCE values of both the parents.

A child inherits this trait from its parents with a mutation. The inherited value for the trait is drawn from a random normal distribution with a mean equal to the average of MALE-CHILD-CHANCE of the parents.

## HOW TO USE IT

Using the sliders, set your desired initial population and individual values (see the **Sliders** section below for more details). Click the SETUP button to setup the population. To run the model, click the GO button.

The plots and monitors allow users to observe population-level changes and see the emergence of the Fisherian sex-ratio equilibrium.

### Sliders

INITIAL-POPULATION-SIZE: the initial number of individuals in the population
INITIAL-ADULT-SEX-RATIO: the initial adult-sex-ratio (number of males/number individual * 100) in the population
INITIAL-AVERAGE-MALE-CHILD-CHANCE: the initial average male-child-chance of all the individuals in the population
MEAN-LONGEVITY: the average longevity (number of ‘ticks’ an individual lives)
GESTATION-PERIOD: the number of 'ticks' a female is going to carry a child
MAXIMUM-LITTER-SIZE: the maximum number of children a female would give birth to after she completes gestation
MATING-CHANCE: the probability that a female mates with a male when a male finds a female partner

### Plots
ADULT SEX RATIO: shows the percentage of male agents
POPULATION AVERAGE MALE-CHILD-CHANCE: shows how the population's male-child-chance changes over time
GENDER DISTRIBUTION: shows numbers of agents of both sexes
MATING SUCCESS RATIO (MALE TO FEMALE): shows how the ratio of male mating success to female mating success changes over time

### Monitors

ADULT SEX RATIO (ASR): the proportion of male agents, at the moment
RUNNING MEAN OF ASR: the average of adult sex ratio in the past 1000 ticks
RUNNING STD DEV OF ASR: standard deviation of adult sex ratio in the past 1000 ticks

## THINGS TO NOTICE

When you run the model, notice how the number of males and females vary in the GENDER DISTRIBUTION plot. Also, notice that for a wide range of parameter values, if you run the simulation long enough (4000 to 5000 ticks), the ASR converges to 50% as seen in the ADULT-SEX-RATIO plot.

Notice that the average value of the trait male-child-chance across all agents in the AVERAGE MALE-CHILD-CHANCE plot also converges to 0.5 for a wide range of parameters.

Also notice that once the ASR reaches 50%, it is stable around the 50% point. The AVERAGE MALE-CHILD-CHANCE is also stable around the value of 0.5.

Vary the INITIAL-SEX-RATIO and INITIAL-AVERAGE-MALE-CHILD-CHANCE, which are the two variables that affect the sex ratio the most in this model. How do these variables relate to the mating success of each sex?

## THINGS TO TRY

Try setting different values of INITIAL-ADULT-SEX-RATIO and INITIAL-AVERAGE-MALE-CHILD-CHANCE to see how that affects the emergence of the adult sex ratio equilibrium.

See if you can change the parameters and see if you can get to a different stable ASR.

## EXTENDING THE MODEL

This model implements `search-for-a-partner` by a male. See if you can change it and make it a female action.

You can also add a variety of features related to evolutionary population genetics and sex ratio equilibrium studies, such as different mortality rates for males and females, sexual selection by females.

## RELATED MODELS

- Red Queen
- Fish Tank Genetic Drift
- Plant Speciation

## CREDITS AND REFERENCES

Fisher, R. A. (1930). The genetical theory of natural selection: a complete variorum edition. Oxford University Press.

Hamilton, W. D. (1967). Extraordinary sex ratios. Science, 156(3774), 477-488

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S., Lee, J.S. and Wilensky, U. (2020).  NetLogo Sex Ratio Equilibrium model.  http://ccl.northwestern.edu/netlogo/models/SexRatioEquilibrium.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2020 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2020 Cite: Dabholkar, S., Lee, J.S. -->
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

bird
false
0
Polygon -7500403 true true 0 120 45 90 75 90 105 120 150 120 240 135 285 120 285 135 300 150 240 150 195 165 255 195 210 195 150 210 90 195 60 180 45 135
Circle -16777216 true false 38 98 14

bird-flying
false
0
Polygon -7500403 true true 195 90 150 105 105 150 75 165 45 165 75 195 90 225 105 195 165 165 195 135 210 105
Polygon -7500403 true true 105 180 90 195
Polygon -7500403 true true 225 75 225 75 240 75 225 90
Polygon -7500403 true true 90 60
Polygon -7500403 true true 105 90
Polygon -7500403 true true 135 105
Polygon -7500403 true true 195 120 135 90 90 90 30 105 105 135 165 135
Polygon -7500403 true true 120 105 90 75
Polygon -7500403 true true 195 120 195 180 180 210 135 240 150 195 150 165 165 150
Polygon -7500403 true true 60 90
Circle -7500403 true true 189 69 42

bird-nest
false
0
Polygon -7500403 true true 0 120 45 90 75 90 105 120 150 120 240 135 285 120 285 135 300 150 240 150 195 165 255 195 210 195 150 210 90 195 60 180 45 135
Circle -16777216 true false 38 98 14
Rectangle -7500403 true true 30 195 90 210
Polygon -7500403 true true 45 165 45 165 90 240 105 240 60 165 45 165
Polygon -7500403 true true 45 180 30 195 165 255 165 240 45 180
Polygon -7500403 true true 195 210 105 240 120 255 210 225 195 210
Polygon -7500403 true true 165 210 270 225 270 210 165 195 165 210
Polygon -7500403 true true 195 240 255 165 255 180 195 255 195 240
Polygon -7500403 true true 135 210 255 240 240 240 120 210 135 210
Polygon -7500403 true true 60 225 255 240 240 255 195 240 150 240 105 225 60 240 45 225
Polygon -7500403 true true 90 240 195 180 195 195 90 255 90 240
Polygon -7500403 true true 30 225 45 240 180 180 180 165 45 240
Polygon -7500403 true true 255 180
Polygon -7500403 true true 165 255 270 180 270 195 180 255 210 255

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
Circle -7500403 true true 135 135 30

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

female
true
0
Circle -7500403 false true 108 108 85
Line -7500403 true 150 195 150 240
Circle -7500403 true true 103 103 92
Line -7500403 true 135 210 165 210

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

male
true
0
Circle -7500403 false true 108 108 85
Line -7500403 true 180 120 225 75
Line -7500403 true 195 75 225 75
Line -7500403 true 225 75 225 105
Circle -7500403 true true 103 103 92

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
