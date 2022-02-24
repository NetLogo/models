globals [
  light-fur-color ; variable to hold the color for light fur
  dark-fur-color ; variable to hold the color for dark fur
]
breed [ mice mouse ]
breed [ predators predator ]
mice-own [
  genotype ; genotypes can be "aa", "Aa", "aA", or "AA"
  partner ; mating partner of an opposite sex
  sex ; male or female
  age
]

; setup the population of males and females
to setup
  clear-all
  ask patches [ set pcolor brown ] ; sets the background to brown
  set light-fur-color 39 ; sets light fur to white, this is set for the camouflage to work, equation on line 120
  set dark-fur-color 31 ; sets light fur to black, this is set for the camouflage to work, equation on line 120
  setup-mice-population
  if predation? [ create-predator-population ]
  reset-ticks
end

; setup the mice population according to initial slider values
to setup-mice-population
  create-mice initial-homozygous-dominant-males [
    set sex "male"
    set genotype "AA"
  ]
  create-mice initial-heterozygous-males [
    set sex "male"
    set genotype "Aa"
  ]
  create-mice initial-homozygous-recessive-males [
    set sex "male"
    set genotype "aa"
  ]
  create-mice initial-homozygous-dominant-females [
    set sex "female"
    set genotype "AA"
  ]
  create-mice initial-heterozygous-females [
    set sex "female"
    set genotype "Aa"
  ]
  create-mice initial-homozygous-recessive-females [
    set sex "female"
    set genotype "aa"
  ]
  ask mice [
    setxy random-xcor random-ycor
    set partner nobody
    set size 2
    set shape "mouse"
    set-fur-color
    set age 0
  ]
  ; male mice are slightly bigger than female mice
  ask mice with [ sex = "male" ] [ set size 2.5 ]
end

to set-fur-color ; mice procedure
  ifelse genotype = "AA" or genotype = "Aa" or genotype = "aA" [
    set color dark-fur-color ; set the mouse's fur color to black if there is a big A allele
  ][
    set color light-fur-color ; set the mouse's fur color to white if there isn't a big A allele
  ]
end

; number of predators in the model are set according to 'chance-of-predation'
to create-predator-population
  create-predators chance-of-predation * 100 [
    setxy random-xcor random-ycor
    set shape "bird"
    set color red
    set size 5
  ]
end


to go
  if not any? mice [ stop ] ; stops if all mice die
  ask mice [
    move
    age-and-die
    die-if-predated
  ]
  ask mice [ reproduce ]
  ifelse predation? [
    maintain-predator-population
    ask predators [
      move
    ]
  ][
    ask predators [ die ]
  ]
  tick
end

to move ; mice procedure
  rt random 360
  lt random 360
  fd 5
end

to age-and-die ; mice procedure
  set age age + 1 ; ages the mouse by 1
  if age > 10 [
    if random-float 1 > 0.95  [ die ] ; 5% chance to die when age is over 10
  ]
end

to die-if-predated ; mice procedure
  ; variable that holds a difference between a mouse color and color of its neighboring patches
  ; increases the closer mouse color is compared to the color of its neighboring patches
  let camouflage  ( 1 / ( abs ( mean [ pcolor ] of neighbors  - [ color ] of self ) ) )
  ; chance of predation reduces if a mouse is camouflaged
  ifelse predation? and ( random-float 1 < ( chance-of-predation - camouflage ) ) [
    die ; dies if mouse is predated
  ] [
    search-a-partner ; if the mouse does not die, it finds a partner to reproduce
  ]

end

to search-a-partner ; mice procedure
  if sex = "male" [
    let females mice with [ sex = "female" ]
    ; if there aren't too many mice nearby, pick a partner
    if ( count females in-radius 5 >= 1 ) and (count females in-radius 10 < 10 )   [
      set partner one-of females in-radius 5 ; sets the partner to a neighboring female

      ifelse [ partner ] of partner != nobody [
        set partner nobody
        stop                        ; just in case two males find the same partner
      ][
        ask partner [ set partner myself ]
      ]
    ]
  ]
  if sex = "female" [
    let males mice with [ sex = "male" ]
    if ( count males in-radius 5 >= 1 )and (count males in-radius 10 < 10 )   [
      set partner one-of males in-radius 5 ; sets the partner to a neighboring male
      ifelse [ partner ] of partner != nobody [
        set partner nobody
        stop                        ; just in case two females find the same partner
      ][
        ask partner [ set partner myself ]
      ]
    ]
  ]

end

to reproduce ; mice procedure
  let my-gametes []
  let partner-gametes []
  if partner != nobody [ ; only reproduces if there is a partner
    ;; sets gametes to the parent's genotype and partner's genotype
    if genotype = "AA" [ set my-gametes [ "A" "A" ] ]
    if genotype = "Aa" or genotype = "aA" [ set my-gametes [ "A" "a" ] ]
    if genotype = "aa" [ set my-gametes [ "a" "a" ] ]
    if [ genotype ] of partner = "AA" [ set partner-gametes [ "A" "A" ] ]
    if ([ genotype ] of partner = "Aa" or [ genotype ] of partner = "aA") [ set partner-gametes [ "A" "a" ] ]
    if [ genotype ] of partner = "aa" [ set partner-gametes [ "a" "a" ] ]

    ; sets genotypes of children by receiving a gamete from each parent. Each mating pair produces 4 children.
    let child1-genotype word (one-of my-gametes) (one-of partner-gametes)
    let child2-genotype word (one-of my-gametes) (one-of partner-gametes)
    let child3-genotype word (one-of my-gametes) (one-of partner-gametes)
    let child4-genotype word (one-of my-gametes) (one-of partner-gametes)

    ; creates each of the 4 children and sets their fur color according to their genotype
    hatch 1 [
      set genotype child1-genotype
      set-fur-color
      fd 1
    ]
    hatch 1 [
      set genotype child2-genotype
      set-fur-color
      fd 1
    ]
    hatch 1 [
      set genotype child3-genotype
      set-fur-color
      fd 1
    ]
    hatch 1 [
      set genotype child4-genotype
      set-fur-color
      fd 1
    ]

    ; the two parent mice to die
    ask partner [ die ]
    die
  ]
end

; creates a heterozygous mutant mouse
to add-a-mutant
    create-mice 1 [
    setxy random-xcor random-ycor
    set partner nobody
    set shape "mouse"
    set sex one-of [ "male" "female" ] ; randomly assigns a sex to the mouse
    ifelse sex = "male" [ set size 2.5 ] [ set size 2 ]
    set genotype "Aa"
    set-fur-color
  ]
end

;; predator population is only for visualization. Predators do not directly interact with mice.
to maintain-predator-population
  ; number of predators in the model are set dynamically according to 'chance-of-predation'.
  ifelse count predators > chance-of-predation * 100 [ ; if there are too many predators, kill one off
    ask one-of predators [ die ]
  ][
    create-predators 1 [ ; if there aren't enough predators, create one
      setxy random-xcor random-ycor
      set shape "bird"
      set color red
      set size 5
    ]
  ]
end

; creates a light background by making majority of patches light brown and then diffusing the background to be lighter
to set-light-background
  ask patches [ set pcolor 36 ]
  ask n-of (round ( count patches / 3)) patches [ set pcolor 40 ] ; makes 1/3 of patches black
  repeat 50 [diffuse pcolor 0.1] ; diffuses so the patches colored black turn lighter and blend into the background
end

; creates a dark background by making majority of patches light brown and then diffusing the background to be darker
to set-dark-background
  ask patches [ set pcolor 34 ]
  ask n-of (round ( count patches / 3)) patches [ set pcolor 30 ]  ; makes 1/3 of patches black
  repeat 50 [ diffuse pcolor 0.1 ] ; diffuses so the patches colored black blend into the background
end

;  creates a dark background by making majority of patches light brown and then diffusing the left side
;  background to be lighter and right side background to be darker
to set-mixed-background
  ask patches [ set pcolor 35 ]
  ask n-of (round ( count patches / 1.5)) patches [ if pxcor > 0  [ set pcolor 30 ] ] ; makes 1/3 of patches on the right side black
  ask n-of (round ( count patches / 1.5)) patches [ if pxcor < 0  [ set pcolor 40 ] ] ; makes 1/3 of patches on the left side black
  ; diffuses the color, turning the patches on the left lighter and patches on the right darker to blend into the background
  repeat 50 [ diffuse pcolor 0.1 ]
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
545
55
1073
584
-1
-1
8.0
1
10
1
1
1
0
0
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
40
210
145
275
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
155
245
240
278
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
260
30
535
63
initial-homozygous-dominant-females
initial-homozygous-dominant-females
0
200
50.0
1
1
NIL
HORIZONTAL

SLIDER
10
70
255
103
initial-heterozygous-males
initial-heterozygous-males
0
200
50.0
1
1
NIL
HORIZONTAL

SLIDER
260
70
535
103
initial-heterozygous-females
initial-heterozygous-females
0
200
50.0
1
1
NIL
HORIZONTAL

SLIDER
10
108
255
141
initial-homozygous-recessive-males
initial-homozygous-recessive-males
0
200
50.0
1
1
NIL
HORIZONTAL

SLIDER
260
110
535
143
initial-homozygous-recessive-females
initial-homozygous-recessive-females
0
200
50.0
1
1
NIL
HORIZONTAL

MONITOR
15
305
90
350
AA males
count mice with [genotype = \"AA\" and sex = \"male\"]
17
1
11

MONITOR
95
305
170
350
Aa males
count mice with [genotype = \"Aa\" and sex = \"male\"] + count mice with [genotype = \"aA\" and sex = \"male\"]
17
1
11

MONITOR
175
305
250
350
aa males
count mice with [genotype = \"aa\" and sex = \"male\"]
17
1
11

PLOT
15
355
535
580
Phenotype frequencies
generations
frequency
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Homozygous dominant" 1.0 0 -8630108 true "" "if count mice > 0 [ plot ( count mice with [genotype = \"AA\"] / count mice )]"
"Heterozygous" 1.0 0 -3425830 true "" "if count mice > 0 [plot ( ( count mice with [genotype = \"Aa\"] + count mice with [genotype = \"aA\"]) / count mice )] "
"Homozygous recessive" 1.0 0 -7500403 true "" "if count mice > 0 [plot ( count mice with [genotype = \"aa\"] / count mice )]"

MONITOR
460
305
534
350
aa females
count mice with [genotype = \"aa\" and sex = \"female\"]
17
1
11

MONITOR
380
305
454
350
Aa females
count mice with [genotype = \"Aa\" and sex = \"female\"] + count mice with [genotype = \"aA\" and sex = \"female\"]
17
1
11

MONITOR
300
305
374
350
AA females
count mice with [genotype = \"AA\" and sex = \"female\"]
17
1
11

BUTTON
545
10
715
45
NIL
set-light-background
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
730
10
890
43
NIL
set-dark-background
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
905
10
1070
43
NIL
set-mixed-background
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
320
210
465
260
Add a mutant
add-a-mutant
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
260
155
535
188
chance-of-predation
chance-of-predation
0.05
0.5
0.26
0.01
1
NIL
HORIZONTAL

SWITCH
15
155
255
188
predation?
predation?
0
1
-1000

SLIDER
10
31
255
64
initial-homozygous-dominant-males
initial-homozygous-dominant-males
0
200
50.0
1
1
NIL
HORIZONTAL

MONITOR
405
425
519
470
light-colored-mice
count mice with [genotype = \"aa\"]
17
1
11

MONITOR
405
475
519
520
dark-colored-mice
count mice with [genotype = \"AA\"] + \ncount mice with [genotype = \"aA\"] +\ncount mice with [genotype = \"Aa\"]
17
1
11

MONITOR
405
525
520
570
total mice
count mice
17
1
11

TEXTBOX
215
10
410
41
Initial settings
14
0.0
1

TEXTBOX
260
320
342
341
Data
14
0.0
1

BUTTON
155
210
240
243
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

TEXTBOX
285
265
555
291
This button adds a heterozygous mutant.
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model simulates natural selection and adaptation in populations of rock pocket mice, which are found mainly in rocky outcrops in the deserts of the southwestern United States and Mexico. This model is based on a lesson plan designed by the [Howard Hughes Medical Institute] (https://www.biointeractive.org/classroom-resources/making-fittest-natural-selection-and-adaptation).

The model simulates fur coat color changes in the population of rock pocket mice due to predation. The mice that cannot camouflage themselves have a higher chance of being predated when there are predators present. Users can investigate how the population evolves because of natural selection across various environmental conditions.

## HOW IT WORKS

Mice in this model can have two fur colors, dark and light. This fur color is decided by their genotypes with homozygous dominant and heterozygous genotypes resulting in dark fur color, whereas homozygous recessive results in light fur color. The fur color is determined by genes at a particular locus for which there are two alleles - **A** and **a**. **A** is a dominant allele, whereas **a** is a recessive allele.

Each clock tick is a generation in this model.
At each generation, the following happens:

- a mouse moves slightly in a random direction
- the mouse ages a generation
- it is possibly predated (if "predation?" is ON) based on the chance of predation and how well it can camouflage with the surroundings
- if the mouse survives predation, it finds a partner and produces 4 offspring with this partner
- the mouse and its partner both die
- if a mouse does not get to reproduce and is over 10 generations old, there is a chance that it dies from old age

Inheritance of the fur coat color genes is modeled based on the laws of Mendelian inheritance.

Each mating pair produces four children. Each child receives one of the alleles from its mother and one of its alleles from the father. Both parents die after reproduction. For simplicity, there are no overlapping generations.

## HOW TO USE IT

1. First, set the initial population by adjusting the following sliders:
  - INITIAL-HOMOZYGOUS-DOMINANT-MALES (**AA** males)
  - INITIAL-HETEROZYGOUS-MALES (**Aa**or **aA** males)
  - INITIAL-HOMOZYGOUS-RECESSIVE-MALES (**aa** males)
  - INITIAL-HOMOZYGOUS-DOMINANT-FEMALES (**AA** females)
  - INITIAL-HETEROZYGOUS-FEMALES (**Aa** or **aA** females)
  - INITIAL-HOMOZYGOUS-RECESSIVE-FEMALES (**aa** females)
2. Press the SETUP button and then select a background by pressing the SET-LIGHT-BACKGROUND, SET-DARK-BACKGROUND, or SET-MIXED-BACKGROUND button.
3. Make sure the PREDATION? switch is in the preferred setting.
4. Adjust the CHANCE-OF-PREDATION slider if PREDATION? is on.
5. Press the GO-ONCE button to advance the generations once at a time. Press the GO button to watch the generations advance indefinitely until stopped.
6. Watch the monitors and plot below the initial settings and make observations about this data.

PREDATION? is a chooser that can be ON or OFF. If PREDATION? is ON, CHANCE-OF-PREDATION can be adjusted from 0 to 0.50.

CHANCE-OF-PREDATION determines the probability of a mouse dying from predation in each generation. The predation probability reduces depending on how well a mouse camouflages, based on its fur coat color and the color of surroundings.

## THINGS TO NOTICE

Observe how the changes in the population composition (i.e. homozygous dominant, heterozygous, homozygous dominant individuals) changes under different environmental conditions.

How does the presence or absence of predators affect the changes in the population?

Does the initial composition of the population influence its genetic composition 100 generations later?

## THINGS TO TRY

Start with a completely homozygous recessive population. How does the introduction of a mutant change the population composition over time? Try this experiment with different environmental conditions.

Start with a completely heterozygous population. Try out all three possible backgrounds. What is the genetic composition of the population 100 generations later for each of these scenarios?

Try varying the CHANCE-OF-PREDATION under the environmental conditions that are favorable to one kind of mice. What can you infer about the "selection pressure" (in this case predation) affecting the rate of change of a population because of natural selection?

## CURRICULAR USE

This model is used in CT-STEM lessons
["Natural Selection: Part 1".](https://ct-stem.northwestern.edu/curriculum/preview/682/)
and
["Natural Selection: Part 2".](https://ct-stem.northwestern.edu/curriculum/preview/986/)

These lessons are part of the unit ["Evolution of Populations to Speciation (Advanced)".](https://ct-stem.northwestern.edu/curriculum/preview/681/) In these lessons, students use this model to investigate the mechanism of inheritance, effects of environmental factors on a population, and how natural selection affects the genetic constitution of a population over time. Students are encouraged to ask questions and then state an answer in the form of a hypothesis. Then to test this hypothesis, students can design and conduct an experiment, collect data, and analyze the data to come to a conclusion backed with evidence to support a claim. This unit is intended to be taught to high school biology students.

## EXTENDING THE MODEL

Try modifying the model in a way where the generations overlap.

Think about how you could study other life-history traits such as the number of offspring, or longevity.

## RELATED MODELS

Check out these other models in the Models Library:
- GenEvo 2 Genetic Drift
- GenEvo 3 Genetic Drift and Natural Selection
- Mendelian Inheritance

## CREDITS AND REFERENCES

Nachman, M. W., Hoekstra, H. E., & D'Agostino, S. L. (2003). The genetic basis of adaptive melanism in pocket mice. Proceedings of the National Academy of Sciences, 100(9), 5268-5273.

This is a model of rock pocket mice evolution based on a lesson plan designed by the Howard Hughes Medical Institute (https://www.biointeractive.org/classroom-resources/making-fittest-natural-selection-and-adaptation).

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar,S. and Wilensky, U. (2020).  NetLogo Natural Selection - Camouflage model.  http://ccl.northwestern.edu/netlogo/models/NaturalSelection-Camouflage.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

This model was developed as part of the CT-STEM Project at Northwestern University and was made possible through generous support from the National Science Foundation (grants CNS-1138461, CNS-1441041, DRL-1020101, DRL-1640201 and DRL-1842374) and the Spencer Foundation (Award #201600069). Any opinions, findings, or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the funding organizations. For more information visit https://ct-stem.northwestern.edu/.

Special thanks to the CT-STEM models team for preparing these models for inclusion
in the Models Library including: Kelvin Lao, Jamie Lee, Sugat Dabholkar, Sally Wu,
and Connor Bain.

## COPYRIGHT AND LICENSE

Copyright 2020 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2020 CTSTEM Cite: Dabholkar,S. -->
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
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

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

female fish
false
4
Polygon -13345367 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -13345367 true false 150 195 134 235 110 218 91 210 61 204 75 165
Polygon -1184463 true true 75 60 83 92 71 118 86 129 165 105 135 75
Polygon -13345367 true false 30 136 150 105 225 105 280 119 292 146 292 160 287 170 255 180 195 195 135 195 30 166
Circle -16777216 true false 215 121 30

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

male fish
false
4
Polygon -14835848 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -14835848 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1184463 true true 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -14835848 true false 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

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
