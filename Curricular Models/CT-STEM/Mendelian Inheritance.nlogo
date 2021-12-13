globals [ parent1 parent2  ; The male parent and female parent mouse
  number-of-dark-offspring
  number-of-light-offspring
  previous-number-of-dark-offspring
  previous-number-of-light-offspring
  trial-number ; Trial number in the experiment
]
breed [ mice mouse ] ; The turtles which represent the mice
mice-own [ genotype generation ] ; Variables that below to mice

to setup
  clear-all
  make-parent1 ; Create the male parent mouse
  make-parent2 ; Create the female parent mouse
  ask mice [ display-phenotype ] ; Shows which color the parents are
  set trial-number 0 ; reset the trial number to 0
  ask patch 12 15 [ set plabel (word "trial number: " trial-number) ]
  reset-ticks
end

; Now we make the male parent
to make-parent1
  create-mice 1 [
   set shape "mouse"
    set size 5
    setxy -7 10
    ; Set the genotype of the male parent according the user's choice
    if genotype-of-male-parent = "homozygous dominant (dark)" [
      set genotype "AA"
    ]
    if genotype-of-male-parent = "heterozygous (dark)" [
      set genotype "Aa"
    ]
    if genotype-of-male-parent = "homozygous recessive (light)" [
      set genotype "aa"
    ]
    set label "male"
    setxy -7 10
    set parent1 self
  ]
end

; Now we make the female parent
to make-parent2
  create-mice 1 [
   set shape "mouse"
    set size 5
    setxy 7 10
    ; Set the genotype of the female parent according the user's choice
    if genotype-of-female-parent = "homozygous dominant (dark)" [
      set genotype "AA"
    ]
    if genotype-of-female-parent = "heterozygous (dark)" [
      set genotype "Aa"
    ]
    if genotype-of-female-parent = "homozygous recessive (light)" [
      set genotype "aa"
    ]
    set label "female"
    setxy 7 10
    set parent2 self
  ]
end

to display-phenotype ; Turtle procedure
  ifelse member? "A" [ genotype ] of self
    [ set color grey ] ; Sets the of the color of mouse to black if they have an A allele
    [ set color white ] ; Sets the color of the mouse to white if they don't have an A allele
end

to make-F1-generation
   ; Sets the upper limit to 50ish offspring
  if count turtles > 50  [
    user-message "Too much population! Press 'setup' to start a new experiment ."
    stop
  ]

  ; Now we create the F1 generation of offspring with genotypes based off their parents
  repeat number-of-offspring [ ; Repeat for the number of offsprings specified
    create-mice 1 [
      ; Gives the offspring one of the male parent's alleles
      let male-gamete one-of
      (list  item 0 [ genotype ] of parent1 item 1 [ genotype ] of parent1 )
      ; Gives the offspring one of the female parent's alleles
      let female-gamete one-of
      (list  item 0 [ genotype ] of parent2 item 1 [ genotype ] of parent2 )
      set genotype (word male-gamete female-gamete)
      set-location
      set shape "mouse"
      set size 3
      display-phenotype
      set generation "F1"
  ]
  ]
  set trial-number trial-number + 1
  ask patch 12 15 [ set plabel (word "trial number: " trial-number) ]

  ; Counter for number of dark offspring
  set number-of-dark-offspring previous-number-of-dark-offspring +
        count mice with [ generation = "F1" and color = grey ]
  ; Counter for number of light offspring
  set number-of-light-offspring previous-number-of-light-offspring +
        count mice with [ generation = "F1" and color = white ]
  tick
end

to clear-F1-generation
  set previous-number-of-light-offspring  number-of-light-offspring
  set previous-number-of-dark-offspring number-of-dark-offspring
  ask turtles with [ycor <= 1] [die]
  ask patches with [pycor <= 3] [set plabel ""]
end

to display-genotype ; Procedure to display genotype by clicking on the mouse
  if mouse-inside? and mouse-down? [
    let selected-mouse nobody
    ask patch mouse-xcor mouse-ycor [ set selected-mouse one-of mice in-radius 2 ]
    if selected-mouse = nobody [
      user-message "Click on a mouse to know its genotype."
      stop
    ]

    ; Shows genotype for the parent if the mouse is part of the F0 generation.
    ifelse [ generation ] of selected-mouse = "F0" [
      ask patch [xcor] of selected-mouse ([ycor] of selected-mouse  + 2) [
        set plabel [ genotype ] of selected-mouse
      ]
    ] [
      ask patch [xcor] of selected-mouse ([ycor] of selected-mouse  + 2) [
        set plabel [ genotype ] of selected-mouse
      ]
    ]
  ]
end

to set-location  ; Procedure to generate mice offspring at distance from each other
  ; Randomizes the position within a specified region for the child mouse to spawn in
  setxy (random 28 - 14) (random 16 - 14)
  if count other mice in-radius 2 > 0 [ set-location ]
end

;;; Reporters

; Reports the number of dark offspring divided by the number of light offspring
; if there is more than one dark offspring
to-report dark-ratio-value
  ifelse number-of-dark-offspring = 0 or number-of-light-offspring = 0
    [ report "N/A" ]
    [ report number-of-dark-offspring / number-of-light-offspring ]

end

;Reports the light ratio as 1 if there is more than one light offspring
to-report light-ratio-value
  ifelse number-of-dark-offspring = 0 or number-of-light-offspring = 0
    [ report "N/A" ]
    [ report "1" ]
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
229
10
600
382
-1
-1
11.0
1
10
1
1
1
0
0
0
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
15
110
225
144
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
15
190
225
224
NIL
make-F1-generation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
15
10
225
55
genotype-of-male-parent
genotype-of-male-parent
"homozygous dominant (dark)" "heterozygous (dark)" "homozygous recessive (light)"
1

CHOOSER
15
60
225
105
genotype-of-female-parent
genotype-of-female-parent
"homozygous dominant (dark)" "heterozygous (dark)" "homozygous recessive (light)"
1

SLIDER
15
150
225
183
number-of-offspring
number-of-offspring
0
10
6.0
1
1
NIL
HORIZONTAL

MONITOR
619
10
784
55
NIL
number-of-light-offspring
17
1
11

MONITOR
619
60
784
105
NIL
number-of-dark-offspring
17
1
11

TEXTBOX
659
125
784
155
RATIO (light:dark)\nin F1 generation
11
0.0
1

MONITOR
639
165
696
210
light
light-ratio-value
17
1
11

MONITOR
709
165
766
210
dark
dark-ratio-value
3
1
11

TEXTBOX
699
176
714
196
:
20
0.0
1

BUTTON
16
231
226
264
NIL
clear-F1-generation
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
15
270
225
303
turn on genotype reader
display-genotype
T
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

This model allows users to explore the rules of Mendelian Inheritance by breeding a pair of mice. There is a male parent and a female parent mouse. The genotype of the parents can be set to be homozygous recessive, heterozygous, or homozygous dominant. The genotype of their offspring is determined using Mendel’s laws of inheritance on the genotype of the parents. Users can breed different pairs of parent mice and observe patterns of fur colors in the resulting offspring in the first filial generation or F1 generation.

This model is based on the work of Dr. Sean Carroll and Dr. David Kinsley that has been explained in an educational video by HHMI. (https://www.biointeractive.org/classroom-resources/making-fittest-natural-selection-and-adaptation). Based on the [underlying genetic mechanism of ‘Mc1r gene’] (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC154334/) that determines the fur coat color in rock pocket mice, in this model, dark allele (A) is dominant over the light allele (a).

## HOW IT WORKS

The parent mice can have three different genotypes and two different phenotypes. The two phenotypes are light color and dark color. The three different genotypes are AA (dark), Aa (dark), aa (light). Each offspring gets one of their parent's alleles randomly which result in Mendelian Ratios over several trials. Users can use the “GENOTYPE READER” to know the genotype of a mouse by clicking on it.

## HOW TO USE IT

1. Select the color of the male parent and the female parent using the GENOTYPE-OF-MALE-PARENT and GENOTYPE-OF-FEMALE-PARENT chooser.
2. Press the SETUP button. Two mice with the genotypes you have chosen should show up in the VIEW.
3. Use the NUMBER-OF-OFFSPRING slider to select the number of offspring this generation will have.
4. Press the MAKE-F1-GENERATION button and observe the color of the offspring. This button can be pressed multiple times to create more offspring. The maximum limit is set to be 50, to avoid crowding.
5. Pressing the TURN-ON-GENOTYPE-READER button will allow you to click on any mouse to view their genotype.
6. To clear the F1 generation before the VIEW gets too crowded, press the CLEAR-F1-GENERATION button. * This doesn't reset the offspring counter or trial number. *
6. Look at the monitors to the right of the VIEW to see the number of light and dark offspring and the ratio between the two for this genotype cross. The ratio only appears when there are both light and dark offspring.

GENOTYPE-OF-MALE-PARENT is a chooser for the color of the mouse on the top left of the view. It has two options, dark or light.
GENOTYPE-OF-FEMALE-PARENT is a chooser for the color of the mouse on the top right of the view. It has two options, dark or light.
NUMBER-OF-OFFSPRING is a slider which lets you choose the number of offspring the parent mice will have at a time. This can range from 0 to 10.

## THINGS TO NOTICE

Does fur color of mice offspring depend on the fur color of their parents?
Are there any rules regarding the inheritance of the fur color, such as parents with light fur coat color always produce light colored offspring.

In what scenarios do light colored mice show up in the offspring? What about dark colored mice? What genotypes do the parents have when this happens?

## THINGS TO TRY

What happens when you breed two dark homozygous mice together? What about two light homozygous mice?

What happens when you cross a heterozygous mouse with a light homozygous mouse? Repeat this a few times, do you notice anything about the ratio of offspring?

What happens when you cross a heterozygous mouse with another heterozygous mouse? Repeat this a few times, do you notice anything about the ratio of offspring?

Does changing the number of offspring do anything?

Can you find different combinations that give different ratios of dark and light-colored mice?

## EXTENDING THE MODEL

This is a very simple model so here are some ways that you may add to it to enhance your understanding.

This model only has one gene modeled. Can you modify it to model mice passing two different genes? How about a gene for the eye color or the tail length?

Can you modify the model to make the big A allele show incomplete dominance instead which means the Aa genotype will display as a lighter shade instead?

## CURRICULAR USE

This model is used in the lesson ["Mendelian Inheritance".](https://ct-stem.northwestern.edu/curriculum/preview/1009/) This lesson is about investigating the mechanism of Mendelian inheritance and is designed to be used after students are introduced to the basic ideas of Mendelian inheritance, such as homozygous and heterozygous. Using this lesson, students can learn about both a monohybrid cross and a dihybrid cross using computational models.

## RELATED MODELS

Check out GenEvo 2 Genetic Drift, Natural Selection and Rock Pocket Mouse Natural Selection

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S. and Wilensky, U. (2020).  NetLogo Mendelian Inheritance model.  http://ccl.northwestern.edu/netlogo/models/MendelianInheritance.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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
setup repeat 3 [ make-F1-generation ]
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
