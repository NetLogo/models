globals [
  promoter-color-list       ; color list to set promoter colors based on their strengths
  rbs-color-list            ; color list to set rbs colors based on their strengths
  gene-color                ; color of the gene
  operon-transcribed?       ; a boolean to see if the operon is transcribed
  LacZ-production-num       ; number of LacZ molecules produced per transcription (this number depends on the rbs strength)
  LacZ-production-num-list  ; list of numbers to set LacZ molecules produced based on the rbs strength
  ONPG-degradation-count    ; a variable to keep track of number of ONPG molecules degraded
  energy-value              ; keeps track of the energy value of the cell
  LacI-number               ; number of LacI molecules
  RNAP-number               ; number of RNA polymerase molecules
  inhibited?                ; boolean for whether or not the operator is inhibited
  dna                       ; agentset containing the patches that are DNA
  non-dna                   ; agentset excluding the patches that are DNA
  LacZ-gene                 ; agentset containing the patches that are LacZ gene
  promoter                  ; agentset containing the patches that are for the promoter
  operator                  ; agentset containing the patches that are for the operator
  rbs                       ; agentset containing the patches that are for the rbs
  terminator                ; agentset containing the patches that are for the terminator
  total-transcripts         ; a variable to keep track of the number of transcription events
  total-proteins            ; a variable to keep track of the number of proteins produced
  ONPG-quantity             ; a variable to set ONPG quantity. This number is set to 200 in the setup procedure.
  experiment?               ; a boolean for whether a timed-experiment is being run or not
]

breed [ LacIs LacI ]  ; LacI repressor protein (violet proteins)
breed [ LacZs LacZ ]  ; LacZ beta-galactosidase enzyme (red proteins)
breed [ ONPGs ONPG ]  ; ortho-Nitrophenyl-beta-galactoside (ONPG) molecule (gray molecules) that is cleaved by beta-galactosidase to produce an intensely yellow compound.
breed [ RNAPs RNAP ]  ; RNA Polymerases (brown proteins) that bind to promoter part of DNA and synthesize mRNA from the downstream DNA

LacIs-own [
  partner                ; a partner is an ONPG molecule with which a LacI molecule binds to form a complex
  bound-to-operator?     ; a boolean to track if a LacI is bound to DNA as an inhibitor of transcription
]

RNAPs-own [           ; a boolean to track if a RNAP is transcribing on the DNA
  on-dna?
]
ONPGs-own [
  partner             ; a partner is a LacI molecule with which an ONPG forms a complex
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; Setup Procedures ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set-global-variables
  set-DNA-patches
  add-proteins
  set-rbs-effect
  update-ONPG
  set experiment? False
  reset-ticks
end

to set-global-variables
  set promoter-color-list [ 62 64 65 68 ]
  set rbs-color-list [ 12 14 15 17 ]
  set gene-color 95
  set LacI-number 30
  set RNAP-number 30
  set LacZ-production-num-list [ 2 3 4 6 ]
  set inhibited? false
  set ONPG-degradation-count 0
  set total-transcripts 0
  set ONPG-quantity 200
  set operon-transcribed? false
end

to set-DNA-patches   ; a procedure to set the DNA patches in the cell and assign appropriate colors based on their strengths
  ask patches [set pcolor white]
  set dna patches with [
    pxcor >= -40 and pxcor < 30 and pycor > 3 and pycor < 6
  ]
  set promoter patches with [
    pxcor >= -40 and pxcor < -26 and pycor > 3 and pycor < 6
  ]
  set operator patches with [
     ((pycor = 4) and (pxcor > -27 and pxcor < 20)) or
     ((pycor = 5) and ((pxcor = -26) or (pxcor = -24) or (pxcor = -23) or (pxcor = -21)))
   ]
  ask operator [ set pcolor orange ]

  set rbs patches with [
    pxcor >= -20 and pxcor < -15 and pycor > 3 and pycor < 6
  ]
  set LacZ-gene patches with [
    pxcor >= -15 and pxcor < 25 and pycor > 3 and pycor < 6
  ]
  set terminator patches with [
    pxcor >= 25 and pxcor < 30 and pycor > 3 and pycor < 6
  ]

  ask promoter [ set pcolor lime ]
  ask operator [ set pcolor orange ]
  ask rbs [ set pcolor red ]
  ask LacZ-gene [ set pcolor blue ]
  ask terminator [ set pcolor gray ]

  set non-dna patches with [ pcolor = white ]
end

to set-rbs-effect        ; sets number of LacZ molecules produced per transcription event depedning on the rbs strength
   if rbs-strength = "weak" [
    set LacZ-production-num item 0 LacZ-production-num-list
  ]
  if rbs-strength = "reference" [
    set LacZ-production-num item 1 LacZ-production-num-list
  ]
  if rbs-strength = "medium" [
    set LacZ-production-num item 2 LacZ-production-num-list
  ]
  if rbs-strength = "strong" [
    set LacZ-production-num item 3 LacZ-production-num-list
  ]
end

; part of the setup procedure to create and randomly place proteins inside the cell
to add-proteins
  create-LacIs LacI-number [
    setxy random-xcor random-ycor
    set bound-to-operator? false
    set partner nobody
    setshape
  ]
  create-RNAPs RNAP-number [
    setxy random-xcor random-ycor
    set on-dna? false
    setshape
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; RUNTIME PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  go-LacIs
  go-RNAPs
  go-LacZs
  go-ONPGs
  check-transcription
  degrade-LacZ
  dissociate-complex
  recolor-patches
  update-ONPG
  tick
end

to move    ;; a random walk procedure for the proteins and ONPG molecules in the cell
  rt random-float 360
  fd 1
end

to setshape        ;; a procedure to set shapes of the molecules
  if breed = LacIs [
    set size 10
    ifelse partner = nobody
    [ set shape "laci"]
    [ set shape "laci-onpg-complex" set size 10 ]
  ]
  if breed = RNAPs [
    set size 6
    set shape "RNAPol"
    set color brown]
  if breed = ONPGs [
    ifelse partner = nobody
      [
        set shape "pentagon"
        set color gray
        set hidden? false
      ]
      [
        set hidden? true
      ]
  ]
  if breed = LacZs [
    set shape "protein 2"
    set color red
    set size 6]
end

to go-LacIs
  ask LacIs [
    ifelse bound-to-operator? [
       if (random-float 1 < LacI-bond-leakage) [ dissociate-from-operator ]
       if (count ONPGs-here with [partner = nobody] > 0 ) [ bind-to-lactose ]
    ]
    [
      move
      if (inhibited? = false) and ((member? patch-here operator) or (member? patch-ahead 1 operator)) and (partner = nobody) [ bind-to-operator ]
      if (partner = nobody) and (count ONPGs-here with [partner = nobody] > 0 ) [ bind-to-lactose ]
    ]
    setshape
  ]
end

to bind-to-operator
  set bound-to-operator? true
  set inhibited? true
  set heading 0
  setxy -23 6
end

to dissociate-from-operator
  set bound-to-operator? false
  set inhibited? false
  fd 3
end

to bind-to-lactose
  if (random-float 1 < LacI-ONPG-binding-chance) [
    set partner one-of ONPGs-here with [partner = nobody]
    setshape
    ask partner [
      set partner myself
      setshape
    ]
    if (bound-to-operator?) [          ;; if lactose binds to LacI that is bound to operator.
      set bound-to-operator? false
      set inhibited? false
      fd 1
    ]
  ]
end

; If an RNAP is close or on the promoter (green) and the operator is open, change heading and move on the DNA towards the terminator.
to go-RNAPs
  if not inhibited? [
    ask RNAPs [
      if promoter-strength = "strong" [
        if member? patch-here promoter or member? patch-ahead 9 promoter [
          start-transcription
        ]
      ]
      if promoter-strength = "medium" [
        if member? patch-here promoter or member? patch-ahead 3 promoter [
          start-transcription
        ]
      ]
      if promoter-strength = "reference" [
        if member? patch-here promoter or member? patch-ahead 2 promoter [
          start-transcription
        ]
      ]
      if promoter-strength = "weak" [
        if member? patch-here promoter or member? patch-ahead 1 promoter [
          start-transcription
        ]
      ]
    ]
  ]

  if any? RNAPS with [ on-dna? ] [
    ask RNAPs with [ on-dna? ] [
      fd 1
      if member? patch-here terminator [
        set operon-transcribed? true
        set on-dna? false
        rt random-float 360
        set total-transcripts total-transcripts + 1
      ]
    ]
  ]

  ask RNAPs with [ not on-dna? ] [
    move
  ]
end

; a turtle procedure for RNAPs
to start-transcription
  setxy xcor 5
  set heading 90
  set on-dna? true
end

to go-LacZs
  ask LacZs [
    move
    if count ONPGs-here != 0 [
      if random-float 1 < ONPG-degradation-chance
      [ ask one-of ONPGs-here [ die ]
        set ONPG-degradation-count ONPG-degradation-count + 1
      ]
    ]
  ]
end

to go-ONPGs
  ask ONPGs [
    move
  ]
end

to check-transcription
  if operon-transcribed? [
    create-LacZs LacZ-production-num [
      setxy random-xcor random-ycor
      setshape
    ]
    set total-proteins total-proteins + LacZ-production-num
    set operon-transcribed? false
  ]
end

to add-ONPG [ ONPG-number ]
   create-ONPGs ONPG-number [
    set partner nobody
    setxy random-xcor random-ycor
    setshape
   ]
end

; Change the color of the cell based on ONPG degradation
to recolor-patches
  ask non-dna [
    set pcolor scale-color yellow (1000 - ONPG-degradation-count) 0 1000
  ]
end

; Dissociate the LacI-ONPG complex
to dissociate-complex
  ask LacIs with [ partner != nobody ] [
    if random-float 1 < LacI-ONPG-separation-chance [
      let temp-x xcor
      let temp-y xcor
      ask partner [
        set partner nobody
        setxy temp-x temp-y
        setshape
        fd 1
      ]
      set partner nobody
      setshape
      fd -1
    ]
  ]
end

to degrade-LacZ
  ask LacZs [
    if random-float 1 < LacZ-degradation-chance [
      die
    ]
  ]
end

to update-ONPG
  ifelse ONPG? [
    add-ONPG (ONPG-quantity - count ONPGs)
  ]
  [
    ask ONPGs [ die ]
  ]
end

to-report number-of-transcripts-per-tick
  report precision (total-transcripts / ticks * 1000) 1
end

to-report number-of-proteins-per-tick
  report precision (total-proteins / ticks * 1000) 1
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
360
10
1013
344
-1
-1
5.0
1
10
1
1
1
0
1
1
1
-64
64
-32
32
1
1
1
ticks
30.0

BUTTON
10
60
90
95
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
100
60
185
95
go
if experiment? [ stop ]\ngo
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
10
10
185
55
promoter-strength
promoter-strength
"reference" "strong" "medium" "weak"
0

CHOOSER
190
10
355
55
rbs-strength
rbs-strength
"reference" "strong" "medium" "weak"
0

SLIDER
10
430
350
463
LacI-bond-leakage
LacI-bond-leakage
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
10
475
350
508
LacI-ONPG-binding-chance
LacI-ONPG-binding-chance
0
1
0.95
0.01
1
NIL
HORIZONTAL

SLIDER
355
430
650
463
ONPG-degradation-chance
ONPG-degradation-chance
0
1
0.95
0.01
1
NIL
HORIZONTAL

PLOT
10
195
355
419
beta-galactosidase activity
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
"default" 1.0 0 -16777216 true "" "plot ONPG-degradation-count"

TEXTBOX
435
360
1030
426
Promoter                           Operator                                    RBS\n\nlacZ Gene                          Terminator
14
0.0
1

TEXTBOX
370
300
500
442
-
100
65.0
1

TEXTBOX
545
305
655
447
-
100
25.0
1

TEXTBOX
735
300
875
444
-
100
15.0
1

TEXTBOX
370
335
500
425
-
100
105.0
1

TEXTBOX
545
335
640
477
-
100
5.0
1

SLIDER
355
475
650
508
LacI-ONPG-separation-chance
LacI-ONPG-separation-chance
0
0.01
1.0E-4
0.0001
1
NIL
HORIZONTAL

MONITOR
190
145
355
190
Translation Rate (Scaled)
number-of-proteins-per-tick
17
1
11

MONITOR
10
145
185
190
Transcription Rate (Scaled)
number-of-transcripts-per-tick
17
1
11

MONITOR
225
340
337
385
beta-gal activity
ONPG-degradation-count
17
1
11

SWITCH
190
60
355
93
ONPG?
ONPG?
0
1
-1000

SLIDER
655
430
916
463
LacZ-degradation-chance
LacZ-degradation-chance
0
1
0.003
0.001
1
NIL
HORIZONTAL

BUTTON
10
103
355
138
run experiment
if ticks >= 2500 [\nstop ] \ngo\nset experiment? True
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

This a multi-agent model of a genetic circuit in a bacterial cell and is an extension of the GenEvo 1 model. This model shows how biologists can use laboratory techniques to tweak certain aspects of a genetic circuit in order to affect the cell's behavior.

Synthetic biology allows biologists to design and test their own genetic circuits. For example, a biologist could design a genetic circuit that caused a bacterium to glow when it was placed in water with a high lead content. This kind of biological engineering is a new frontier being actively explored by scientists around the globe.

## HOW IT WORKS

The genetic circuit modelled here has the following components:

1. *promoter with a lac operator* – Transcription starts at the promoter if the repressor protein (LacI) is not bound to the lac operator region. The probability of an RNA polymerase binding to the promoter and starting transcription depends on the promoter strength.
2. *RBS* – A ribosome binding site is downstream to the promoter. The number of proteins produced per transcription depends on the strength of the RBS.
3. *lacZ gene* – A gene that codes for the LacZ protein
4. a terminator – RNA polymerase separates from the DNA when it reaches this region.
5. RNA polymerases - These are represented by brown blobs in the model. This model does not include mRNAs.
6. *LacI repressor proteins* - The purple-colored shapes in the model represent a repressor (LacI proteins). They bind to the operator region (see below) of the DNA and do not let RNAP to pass along the gene, thus stopping protein synthesis. When lactose binds to LacI, they form LacI-lactose complexes (shown by a purple shape with a grey dot attached to it). These complexes cannot bind to the operator region of the DNA.
7. *ONPG molecules* – These are grey pentagons in the model. [ONPG]( https://en.wikipedia.org/wiki/IPTG) is a chemical that mimics lactose. It is normally colorless. ONPG is hydrolyzed by LacZ enzyme to produce yellow color which is used to check for enzyme activity.  Typically, [IPTG] (https://en.wikipedia.org/wiki/ONPG), another chemical that mimics lactose, is used with ONPG. For simplicity, we have not incorporated IPTG in this model. In this model, ONPG molecules bind to LacI repressor proteins that changes the shape of LacIs preventing them binding to the operator region of DNA.

The model explicitly incorporates transcription by showing the movement of RNA polymerases across DNA. It implicitly incorporates translation and does not incorporate mRNAs or ribosomes.

A user can select the promoter and RBS strengths, add ONPG (by making 'ONPG?' ON) and run the model. The model simulates interactions between the components of the genetic circuit that results in an emergent cellular behavior. The cellular behavior of interest in this model is LacZ (beta-galactosidase) activity which can be observed in a graph and is also represented in the change in the color of the cell to yellow. Beta-galactosidase cleaves ONPG to produce an intensely yellow colored compound.

## HOW TO USE IT

Select the promoter strength and RBS strength using the two choosers.

Press SETUP to initialize the components in the model.

Press GO to run the model.

You can use the RUN EXPERIMENT button to run experiments for a specified time duration (2500 ticks). This is useful for comparing the behavior of the cell in different simulations of the same conditions. You could also use this button to run a timed experiment for different initial conditions (e.g. different promoter and RBS strengths).

‘ONPG?’ is a switch which keeps ONPG concentration constant throughout the simulation. This switch can be used to emulate situations where ONPG concentration in the medium is excess and not a limiting factor.

## THINGS TO NOTICE

Run the model with 'ONPG?' switch OFF. Notice the molecular interactions inside the cell
- interaction of the LacI protein with the operator
- RNAPs binding to promoter
- RNAPs moving along the DNA
- proteins being generated after an RNAP transcribes the DNA

Observe the same interactions when 'ONPG?' is ON.

Run the model with a set PROMOTER-STRENGTH and RBS-STRENGTH and observe changes in the scaled transcription and translation rates. Also, observe changes in the LacZ activity in the graph as well as in the simulation.
Run it multiple times and observe the differences.

## THINGS TO TRY

Change the PROMOTER-STRENGTH and RBS-STRENGTH combination and observe the behavior again.

See which combination has the most robust and optimum behavior.

Change the parameter values of LACI-BOND-LEAKAGE, ONPG-DEGRADATION-CHANCE, COMPLEX-SEPARATION-CHANCE, COMPLEX-FORMATION-CHANCE, and LACZ-DEGRADATION-CHANCE. Notice how these changes affects the behavior of the model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S. and Wilensky, U. (2016).  NetLogo Synthetic Biology - Genetic Switch model.  http://ccl.northwestern.edu/netlogo/models/SyntheticBiology-GeneticSwitch.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

To cite the GenEvo Systems Biology curriculum as a whole, please use:

* Dabholkar, S. & Wilensky, U. (2016). GenEvo Systems Biology curriculum. http://ccl.northwestern.edu/curriculum/genevo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 GenEvo Cite: Dabholkar, S. -->
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

laci
true
0
Polygon -8630108 true false 120 120 135 135 150 135 165 120 270 120 270 180 210 180 210 210 165 210 165 180 120 180 120 210 75 210 75 180 15 180 15 120 120 120

laci-lactose-complex
true
0
Polygon -8630108 true false 75 105 15 210 150 210 285 210 225 105 180 105 165 120 135 120 120 105 75 105
Polygon -1184463 true false 135 120 165 120 195 90 150 60 105 90 135 120

laci-onpg-complex
true
9
Polygon -8630108 true false 15 135 15 210 150 210 270 210 270 135 165 135 150 150 135 150 120 135 75 135
Polygon -7500403 true false 135 150 150 150 165 135 150 120 135 120 120 135

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

protein
true
0
Polygon -7500403 false true 165 75 135 75 135 90 165 105 165 75 165 60 135 105 165 120 180 120 180 90 150 75 150 105 180 135 165 135 165 120 180 120 195 135 195 105 195 105 165 105 150 105 165 90 180 75 165 75 150 90 165 105 150 120 135 150 120 150 120 165 150 165 180 165 165 135 165 135
Polygon -7500403 false true 165 150 165 165 150 180 135 165 120 195 150 210 165 180 180 165 150 165 135 150 135 165 120 165 120 210 150 195 180 195 180 180 195 165 165 150 165 150 210 165 180 210 150 180 135 210 120 225 150 225
Polygon -7500403 false true 135 120 120 120 150 135 150 150 180 150 150 120 120 135 135 105 105 105 180 135 210 150 105 120 105 135 210 195

protein 2
true
0
Polygon -7500403 true true 150 60 60 195 240 195 150 60

rnapol
true
10
Circle -13345367 true true 45 75 150
Circle -13345367 true true 105 75 150

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
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Sample-Experiment" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2500"/>
    <metric>ONPG-degradation-count</metric>
    <enumeratedValueSet variable="ONPG-degradation-chance">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="const-ONPG?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timed-expt?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="promoter-strength">
      <value value="&quot;reference&quot;"/>
      <value value="&quot;strong&quot;"/>
      <value value="&quot;medium&quot;"/>
      <value value="&quot;weak&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complex-separation-chance">
      <value value="1.0E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="complex-formation-chance">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lacI-bond-leakage">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lacZ-degradation-chance">
      <value value="0.003"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rbs-strength">
      <value value="&quot;reference&quot;"/>
      <value value="&quot;strong&quot;"/>
      <value value="&quot;medium&quot;"/>
      <value value="&quot;weak&quot;"/>
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
