globals [
  frequency-of-dominant-A ; variable to hold the frequency for the big A allele
  frequency-of-recessive-a ; variable to hold the frequency for the small a allele
  light-fur-color ; variable to hold the color for light fur
  dark-fur-color ; variable to hold the color for dark fur
]
breed [ mice mouse ]
mice-own [
  genotype ; genotypes can be "aa", "Aa", "aA", or "AA"
  partner ; mating partner of an opposite sex
  sex ; male or female
]

; set-up population of males and females
to setup
  clear-all
  set light-fur-color white
  set dark-fur-color black
  ask patches [ set pcolor brown ]
  setup-mice-population
  calculate-allele-frequencies
  reset-ticks
end

; set-up the mice population according to initial slider values
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
    set shape "mouse"
    set-fur-color
  ]
  ; male mice are slightly bigger than female mice
  ask mice with [ sex = "male" ] [
    set size 1.5
  ]
end

to set-fur-color ; mice procedure
  ifelse genotype = "AA" or genotype = "Aa" or genotype = "aA" [
    set color dark-fur-color ; set the mouse's fur color to black if there is a big A allele
  ][
    set color light-fur-color ; set the mouse's fur color to white if there isn't a big A allele
  ]
end

; Calculates the allele frequencies of the population
to calculate-allele-frequencies
  ; counts the number of mice with a big A allele
  set frequency-of-dominant-A  ((2 * count mice with [ genotype = "AA" ]) +
                                count mice with  [genotype = "Aa" ] +
                                count mice with [ genotype = "aA" ] ) / (2 * count mice)
  ; counts the number of mice with a small a allele
  set frequency-of-recessive-a ((2 * count mice with [ genotype = "aa" ]) +
                                count mice with [ genotype = "Aa" ] +
                                count mice with [ genotype = "aA" ] ) / (2 * count mice)
end

to go
  if not any? mice [ stop ]; stops if all mice die
  ask mice [
    move
    search-a-partner ; all the mice first search for partners
  ]
  ask mice [
    reproduce  ; all the mice then reproduce if they have found partners
  ]
  calculate-allele-frequencies
  tick
end

to move ; mice procedure (to mix mouse population for visualization and to randomize breeding)
  rt random 360
  fd 5
end

to search-a-partner   ; mice procedure
  if sex = "male" [
    let females mice with [ sex = "female" ]
    if count females in-radius 3 >= 1   [
      set partner one-of females in-radius 3 ; sets the partner to a neighboring female
      ask partner [ set partner myself ]

      if [partner] of partner != nobody [
        set partner nobody
        stop                        ; just in case two males find the same partner
      ]
    ]
  ]
  if sex = "female" [
    let males mice with [ sex = "male" ]
    if count males in-radius 3 >= 1   [
      set partner one-of males in-radius 3 ; sets the partner to a neighboring male
      ask partner [ set partner myself ]

      if [ partner ] of partner != nobody [
        set partner nobody
        stop                        ; just in case two females find the same partner
      ]
    ]
  ]

end

to reproduce  ; mice reproduce if they have partners

  if partner != nobody [ ; only reproduces if there is a partner

    let my-gametes []
    let partner-gametes []

    if genotype = "AA" [ set my-gametes [ "A" "A" ] ]
    if genotype = "Aa" or genotype = "aA" [ set my-gametes [ "A" "a" ] ]
    if genotype = "aa" [ set my-gametes [ "a" "a" ] ]
    if [ genotype ] of partner = "AA" [ set partner-gametes [ "A" "A" ] ]
    if ([ genotype ] of partner = "Aa" or [ genotype ] of partner = "aA") [ set partner-gametes [ "A" "a" ] ]
    if [ genotype ] of partner = "aa" [ set partner-gametes [ "a" "a" ] ]

    ; sets genotypes of children by receiving a gamete from each parent. Each mating pair produces 2 children.
    let my-child-genotype word (one-of my-gametes) (one-of partner-gametes)
    let partner-child-genotype word (one-of my-gametes) (one-of partner-gametes)

    ; creates each of the children and sets their fur color according to their genotype
    hatch 1 [
      set genotype my-child-genotype
      set-fur-color
      fd 5
    ]


    ask partner [
      hatch 1 [
        set genotype partner-child-genotype
        set-fur-color
        fd 5
      ]
      ; the two parent mice die
      die
    ]
    die
  ]
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
530
60
1000
531
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
517
10
675
44
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
-1
11
243
44
initial-homozygous-dominant-males
initial-homozygous-dominant-males
0
200
60.0
1
1
NIL
HORIZONTAL

BUTTON
857
10
1005
43
go forever
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
255
10
509
43
initial-homozygous-dominant-females
initial-homozygous-dominant-females
0
200
60.0
1
1
NIL
HORIZONTAL

SLIDER
-2
48
244
81
initial-heterozygous-males
initial-heterozygous-males
0
200
60.0
1
1
NIL
HORIZONTAL

SLIDER
254
49
509
82
initial-heterozygous-females
initial-heterozygous-females
0
200
60.0
1
1
NIL
HORIZONTAL

SLIDER
-2
87
244
120
initial-homozygous-recessive-males
initial-homozygous-recessive-males
0
200
200.0
1
1
NIL
HORIZONTAL

SLIDER
253
87
508
120
initial-homozygous-recessive-females
initial-homozygous-recessive-females
0
200
200.0
1
1
NIL
HORIZONTAL

MONITOR
12
162
74
207
AA males
count mice with [genotype = \"AA\" and sex = \"male\"]
17
1
11

MONITOR
12
211
74
256
Aa males
count mice with [genotype = \"Aa\" and sex = \"male\"] + count mice with [genotype = \"aA\" and sex = \"male\"]
17
1
11

MONITOR
11
260
74
305
aa males
count mice with [genotype = \"aa\" and sex = \"male\"]
17
1
11

PLOT
87
126
508
325
Allele frequencies
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
"Allele A " 1.0 0 -8630108 true "" "plot frequency-of-dominant-A"
"Allele a" 1.0 0 -9276814 true "" "plot frequency-of-recessive-a"

PLOT
87
331
508
544
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
"Homozygous dominant" 1.0 0 -8630108 true "" "plot ( count turtles with [genotype = \"AA\"] / count turtles )"
"Heterozygous" 1.0 0 -3425830 true "" "plot ( ( count turtles with [genotype = \"Aa\"] + count turtles with [genotype = \"aA\"]) / count turtles ) "
"Homozygous recessive" 1.0 0 -7500403 true "" "plot count turtles with [genotype = \"aa\"] / count turtles"

MONITOR
4
420
74
465
aa females
count mice with [genotype = \"aa\" and sex = \"female\"]
17
1
11

MONITOR
4
368
74
413
Aa females
count mice with [genotype = \"Aa\" and sex = \"female\"] + count mice with [genotype = \"aA\" and sex = \"female\"]
17
1
11

MONITOR
4
316
75
361
AA females
count mice with [genotype = \"AA\" and sex = \"female\"]
17
1
11

MONITOR
1024
55
1103
100
p-squared
frequency-of-dominant-A ^ 2
2
1
11

MONITOR
1026
157
1105
202
q-squared
frequency-of-recessive-a ^ 2
2
1
11

MONITOR
1025
106
1104
151
2pq
2 * frequency-of-dominant-A * frequency-of-recessive-a
2
1
11

MONITOR
1026
253
1103
298
AA
( count turtles with [genotype = \"AA\"] / count turtles )
2
1
11

MONITOR
1027
306
1104
351
Aa
( ( count turtles with [genotype = \"Aa\"] + count turtles with [genotype = \"aA\"]) / count turtles )
2
1
11

MONITOR
1028
359
1106
404
aa
count turtles with [genotype = \"aa\"] / count turtles
2
1
11

TEXTBOX
1016
19
1176
47
Allele frequency \nHardy-Weinberg values
11
0.0
1

TEXTBOX
1014
230
1159
248
Genotype frequencies
11
0.0
1

BUTTON
688
10
843
43
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

MONITOR
1031
447
1151
492
light-colored-mice
count mice with [ genotype = \"AA\" ] \n+ count mice with [ genotype = \"Aa\" ]\n+ count mice with [ genotype = \"aA\" ]
17
1
11

MONITOR
1031
497
1151
542
dark-colored-mice
count mice with [genotype = \"aa\"]
17
1
11

TEXTBOX
1015
423
1131
441
Phenotypes
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model allows users to explore the inheritance of fur coat color in a population of rock pocket mice to investigate the [Hardy-Weinberg Principle](https://en.wikipedia.org/wiki/Hardy–Weinberg_principle). Users can set up the initial genetic composition of the mouse population and then can track genotype and phenotype frequencies in the population as the mice reproduce obeying the assumptions underlying Hardy- Weinberg equilibrium. As the populations reproduce, after just a few generations, the population reaches Hardy-Weinberg equilibrium.

The context for this model is the evolution of fur coat color in rock pocket mice that are mainly found in rocky outcrops in the deserts of the southwestern United States and Mexico. This context is developed into a lesson plan by the [Howard Hughes Medical Institute] (https://www.biointeractive.org/classroom-resources/making-fittest-natural-selection-and-adaptation). The genetics is modeled on the basis of the [research](https://www.pnas.org/content/100/9/5268.) on the rock pocket mice populations.
The specifics of the model are designed on the basis of an Advanced Placement (AP) Biology Lab, so that students can computationally investigate the emergence of Hardy-Weinberg equilibrium values in a population that obeys Hardy-Weinberg equilibrium assumptions.

## HOW IT WORKS

Mice in this model can have two fur colors, dark and light. This fur color is decided by their genotypes. Homozygous dominant and heterozygous mice have dark fur color, whereas homozygous recessive mice have light fur color. The fur color is determined by genes at a particular locus for which there are two alleles - A and a. A is a dominant allele, whereas a is a recessive allele. p is a frequency of the dominant allele (A) and q is a frequency of the recessive allele (a).

Each clock tick is a generation in this model.

At each generation, the following happens:
- a mouse moves in a random direction
- if it finds a partner,
- it produces 2 offspring with the partner
- the mouse and its partner both die

Hardy-Weinberg values, p and q, and phenotype frequencies are calculated for every generation.

Inheritance of the fur coat color genes is modeled based on the laws of Mendelian inheritance.

Each mating pair produces two children. Each child receives one of the alleles from the mother and one of the alleles from the father. Both parents die after reproduction. For simplicity, there are no overlapping generations.

## HOW TO USE IT

1. First, set the initial population by adjusting the following sliders:
  - INITIAL-HOMOZYGOUS-DOMINANT-MALES (AA males)
  - INITIAL-HETEROZYGOUS-MALES (Aa/aA males)
  - INITIAL-HOMOZYGOUS-RECESSIVE-MALES (aa males)
  - INITIAL-HOMOZYGOUS-DOMINANT-FEMALES (AA females)
  - INITIAL-HETEROZYGOUS-FEMALES (Aa/aA females)
  - INITIAL-HOMOZYGOUS-RECESSIVE-FEMALES (aa females)
2. Press the SETUP button
3. Press the GO-ONCE button to advance one generation. Press the GO-FOREVER button to observe the passage of many generations.
4. Watch the monitors and plots to see allele frequencies, phenotype frequencies, and population count
5. Watch the monitors to the right of the VIEW to see Hardy-Weinberg values, genotype frequencies, and a counter for phenotypes

INITIAL-HOMOZYGOUS-DOMINANT-MALES, INITIAL-HETEROZYGOUS-MALES, INITIAL-HOMOZYGOUS-RECESSIVE-MALES, INITIAL-HOMOZYGOUS-DOMINANT-FEMALES, INITIAL-HETEROZYGOUS-FEMALES, and INITIAL-HOMOZYGOUS-RECESSIVE-FEMALES are all sliders that determine the initial population of the mice population, these sliders can range from 0 to 200.

When you click GO-ONCE, the model simulates the change of a generation.
You can click GO-FOREVER, to observe the passage of many generations.

## THINGS TO NOTICE

Take note of the Hardy-Weinberg values after setup. Run the model slowly by pressing the GO-ONCE button multiple times. Notice, how the genotype and the phenotype frequencies change after each generation.

## THINGS TO TRY

Start with a completely heterozygous population. How does the population look 100 generations later? What about 1000 generations later?

Try out different initial compositions of the population. Are there any compositions where the allele frequencies are stable and don't change after thousands of generations? What about unstable compositions?

## CURRICULAR USE

This model is used in CT-STEM lesson [Hardy Weinberg Equilibrium](https://ct-stem.northwestern.edu/curriculum/preview/965/).

In this lesson, students can use this model to investigate the mechanism of inheritance and come to understand the basic idea of Hardy Weinberg Equilibrium. Students can also learn to calculate phenotype frequencies both mathematically and computationally (using a computational model). Students are encouraged to ask questions and then state an answer in the form of a hypothesis. Then to test this hypothesis, students can design and conduct an experiment, collect data, and analyze the data to come to a conclusion backed with evidence to support a claim.

This unit is intended to be taught to Advance Placement (AP) and university biology students.

This lesson is part of the unit [Evolution of Populations to Speciation (Advanced)](https://ct-stem.northwestern.edu/curriculum/preview/961/). The curricular unit is designed for students to investigate and learn how populations evolve by studying the case of pocket mice. Students use computational models to explain the connection between genetic drift, natural selection, and speciation.

## EXTENDING THE MODEL

Try modifying the model in a way where the mice generations overlap.

Could you add an extra allele of the gene, similar to how human blood type has three different alleles?

Think about how you could add another gene into this model and how that gene's allele frequencies would look.

How about simulating the inheritance of two traits that are genetically not linked? Or linked?

## RELATED MODELS

Look at GenEvo 2 Genetic Drift, GenEvo 2 Natural Selection, Mendelian Inheritance, and Natural Selection - Camouflage.

## CREDITS AND REFERENCES

* https://www.pnas.org/content/100/9/5268
* https://www.biointeractive.org/classroom-resources/making-fittest-natural-selection-and-adaptation
* An AP Biology Lab from Central Catholic HS which is no longer available publicly.
* AP Biology laboratory manual for students. (2001). New York, NY: Advanced Placement Program, The College Board.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S. and Wilensky, U. (2020).  NetLogo Hardy Weinberg Equilibrium model.  http://ccl.northwestern.edu/netlogo/models/HardyWeinbergEquilibrium.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

<!-- 2020 CTSTEM Cite: Dabholkar, S. -->
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
