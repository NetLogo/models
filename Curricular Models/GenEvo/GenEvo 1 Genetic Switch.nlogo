globals [
  ; Simulation constants
  cell-width                 ; the width of the cell
  cell-height                ; the height of the cell
  cell-color                 ; the color of the cell
  cell-wall                  ; a patch set that contains the patches on the cell wall
  cell-patches               ; a patch set that contains the patches inside the cell
  operon                     ; a patch set that contains the operon patches
  promoter                   ; a patch set that contains the patches that represent the promoter
  operator                   ; a patch set that contains the patches that represent the operator
  terminator                 ; a patch set that contains the patches that represent the terminator
  LacZ-production-num        ; number of LacZ proteins produced per transcription event
  LacZ-production-cost       ; cost incurred by the cell to produce one molecule of LacZ protein
  LacY-production-num        ; number of LacZ proteins produced per transcription event
  LacY-production-cost       ; cost incurred by the cell to produce one molecule of LacZ protein
  initial-energy             ; initial energy of the cell
  lactose-upper-limit        ; a variable to set the lactose quantity in the external environment

  ; Global (cellular) properties
  energy                           ; keeps track of the energy of the cell
  ticks-at-start-of-cell-division  ; to keep track of cell division time
  ticks-at-end-of-cell-division    ; to keep track of cell division time
  cell-division-time               ; time taken for the cell to divide
  division-number                  ; a counter to keep track of number of cell division events
  inhibited?                       ; boolean for whether or not the operator is inhibited
]

breed [ LacIs LacI ]         ; the LacI repressor protein (purple proteins)
breed [ LacZs LacZ ]         ; the LacZ beta-galactosidase enzyme (light red proteins)
breed [ LacYs LacY ]         ; the LacY lactose permease enzyme (light red rectangles)
breed [ RNAPs RNAP ]         ; RNA Polymerase (brown proteins) that binds to the DNA and synthesizes mRNA
breed [ lactoses lactose ]   ; lactose molecules (gray)

breed [ mask-turtles mask-turtle ]   ; turtles to mask the background during animation of cell division
breed [ daughter-cell-turtles daughter-cell-turtle ]  ; turtles to animate cell division process

LacIs-own [
  partner                ; if it's a LacI complex, then partner is a lactose molecule
  bound-to-operator?     ; a boolean to track if a LacI is bound to DNA as an inhibitor of transcription
]

RNAPs-own [
  on-DNA?     ; a boolean to track if a RNAP is transcribing the DNA
]

lactoses-own [
  partner     ; a partner is a LacI molecule with which a lactose molecule forms a complex
  inside?     ; a boolean to track if a lactose molecule is inside the cell
]

to setup
  clear-all

  ; Set all of our constant global variables
  set cell-width 44
  set cell-height 16
  set initial-energy 1000
  set lactose-upper-limit 1500
  set LacZ-production-num 5
  set LacZ-production-cost 10
  set LacY-production-num 5
  set LacY-production-cost 10

  ; Initialize all of our global property variables
  set energy initial-energy
  set ticks-at-start-of-cell-division 0
  set division-number 0
  set inhibited? false

  draw-cell

  ; add the necessary proteins to the cell
  create-LacIs LacI-number [
    set bound-to-operator? false
    set partner nobody
    set-shape
    gen-xy-inside-inside
  ]
  create-RNAPs RNAP-number [
    set on-DNA? false
    set-shape
    gen-xy-inside-inside
  ]

  if not LevelSpace? [
    if lactose? [ update-lactose lactose-upper-limit ] ; add lactose if ON
  ]
  reset-ticks
end

to reset   ;; to reset the parameters to default setting
  set LacI-number 25
  set RNAP-number 25
  set LacI-bond-leakage 0.02
  set LacI-lactose-binding-chance 0.99991
  set LacI-lactose-separation-chance 0.001
  set LacY-degradation-chance 4.0E-4
  set LacZ-degradation-chance 1.0E-4
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;  Runtime Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  go-LacIs
  go-LacYs
  go-LacZs
  go-lactoses
  go-RNAPs

  ; if glucose? is ON, we get a steady stream of energy
  if glucose? [ set energy energy + 10 ]
  ; but it takes energy to maintain all of the proteins so consume some energy
  set energy (energy - (count RNAPs + count LacIs + count LacZs) / 100 )

  ; If we're in LevelSpace, then let the population model control division and lactose distribution.
  if not LevelSpace? [
    if lactose? [ update-lactose lactose-upper-limit ]

    ; if we've doubled our energy, then divide
    if (energy > 2 * initial-energy) [ divide-cell ]

    ; if we're out of energy, die
    if (energy < 0) [ user-message "The cell has run out of energy. It's dead!" stop ]
  ]
  show-switch-color
  tick
end

; controls the random movement of all turtles. If you're headed towards the cell wall, just turn until you're not
to move ; turtle procedure
  rt random-float 360
  while [ (member? patch-ahead 1 cell-wall) or (member? patch-ahead 2 cell-wall) ] [ rt random-float 360 ]
  forward 1
end

; procedure for movement and molecular interactions of LacI proteins
to go-LacIs

  ; a LacI bound with the operator might dissociate from the operator
  ask LacIs with [ bound-to-operator? ] [
    if (random-float 1 < LacI-bond-leakage) [
      dissociate-from-operator
    ]
  ]

  ; LacIs with partners might dissociate from their partners
  ask LacIs with [ partner != nobody ] [
     if (random-float 1 < LacI-lactose-separation-chance) [
      ask partner [
        set partner nobody
        move-to myself
        set-shape
        forward 1
      ]
      set partner nobody
      set-shape
      forward -1
    ]
  ]

  ; LacIs without partners either bind with the operator
  ask LacIs with [ partner = nobody ] [
    ifelse (not inhibited?) and ((member? patch-here operator) or (member? patch-ahead 1 operator)) [
      set bound-to-operator? true
      set inhibited? true
      set heading 0
      setxy -12 1
    ] [ ; or maybe bind with a lactose
      if (count lactoses-here with [ partner = nobody ] > 0  and (random-float 1 < LacI-lactose-binding-chance)) [
        set partner one-of lactoses-here with [ partner = nobody ]
        set-shape
        ask partner [
          set partner myself
          set-shape
        ]
        dissociate-from-operator ; if necessary, dissociate from the operator
      ]
    ]
  ]

  ask LacIs with [ not bound-to-operator? ] [ move ]
end

; procedure for LacIs to dissociate from the operator
to dissociate-from-operator ; LacI procedure
  if (bound-to-operator?) [
    set bound-to-operator? false
    set inhibited? false
    forward 3
  ]
end

; procedure for movement and interactions of LacY proteins
to go-LacYs
  ask LacYs [
    ; if LacY hits the cellwall, it gets installed on the cell wall
    ifelse (member? patch-ahead 2 cell-wall) [
      ask patch-ahead 2 [ set pcolor (red + 2) ]
      die
    ]
    ; otherwise we just move normally
    [ move ]
  ]
  ; each tick, the installed LacYs have a chance of degrading
  ask patches with [pcolor = (red + 2)] [
    if (random-float 1 < LacY-degradation-chance) [ set pcolor cell-color ]
  ]
end

; procedure for movement and interactions of LacZ proteins
to go-LacZs
  ; LacZs near lactose can digest that lactose and produce energy
  ask LacZs with [ any? lactoses in-radius 1 with [ partner = nobody ] ] [
    ask lactoses in-radius 2 with [ partner = nobody ] [
      set energy energy + 10
      die
    ]
  ]
  ask LacZs [
    move
    if (random-float 1 < LacZ-degradation-chance) [ die ] ; there's a chance LacZ degrades
  ]
end

; procedure for movement and interactions of lactose molecules
to go-lactoses
  ; any lactoses near an installed LacY get pumped into the cell
  ask lactoses with [ ([ pcolor ] of patch-ahead 2 = (red + 2)) and not inside? ] [
    move-to patch-ahead 2 set heading towards patch 0 0 ; make sure the lactose gets inside the cell
    fd 3
    set inside? true
  ]

  ask lactoses [ move ]
end


; procedure for movement and molecular interactions of RNAPs
to go-RNAPs
  ; In the presence of glucose, the probability of trancription is less.
  let transcription-probability ifelse-value glucose? [ 0.1 ] [ 1 ]

  ; If any RNAPs are close to the promoter and the operator is not inhibited
  if (not inhibited?) [
    ask RNAPs with [ (member? patch-here promoter) or (member? patch-ahead 1 promoter) or (member? patch-ahead 2 promoter) ] [
      if random-float 1 < transcription-probability [
         ; then start moving along the DNA to model transcription
         setxy xcor 1
         set heading 90
         set on-dna? true
      ]
    ]
  ]

  ; If any RNAPs are in the process of transcribing (on-dna?) move them along
  ask RNAPs with [ on-dna? ] [
    forward 1
    ; when you reach the terminator, synthesize the proteins
    if (member? patch-here terminator) [
      synthesize-proteins
      set on-dna? false
      gen-xy-inside-inside
    ]
  ]

  ; Any other RNAPs just move around the cell
  ask RNAPs with [ not on-dna? ] [
    move
    ; Because our DNA is fixed within the cell,  RNAPs at both ends of the
    ; of the cell are moved to a random position inside the cell
    if (xcor > (cell-width - 3) or xcor < (- cell-width + 3)) [ gen-xy-inside-inside ]
  ]
end

; procedure to synthesize proteins upon dna transcription
to synthesize-proteins
  hatch-LacYs LacY-production-num [
    gen-xy-inside-inside
    set-shape
  ]
  hatch-LacZs LacZ-production-num [
    gen-xy-inside-inside
    set-shape
  ]
  set energy energy - (LacY-production-cost * LacY-production-num) - (LacZ-production-cost * LacZ-production-num)
end

; procedure to simulate cell division; each type of turtle (except RNAPs and LacIs) population is halved
to divide-cell
  animate-cell-division

  ask n-of (count lactoses with [ inside? and partner = nobody ] / 2) lactoses with [ inside? and partner = nobody ] [ die ]
  ask n-of (count LacYs / 2) LacYs [ die ]
  ask n-of (count LacZs / 2) LacZs [ die ]
  ask n-of (count patches with [pcolor = (red + 2) ] / 2)patches with [pcolor = (red + 2)] [set pcolor cell-color]

  set energy energy / 2
  set division-number division-number + 1
  set ticks-at-end-of-cell-division ticks
  set cell-division-time (ticks-at-end-of-cell-division - ticks-at-start-of-cell-division)
  set ticks-at-start-of-cell-division ticks
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;  Helper Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; procedure that sets patches for the cell, the cell-wall, and the
; regions of the DNA; although it looks complicated, really we're just
; addressing a bunch of patch-sets
to draw-cell
  set cell-wall ( patch-set
    ; the vertical part of the cell wall
    (patches with [
      (pycor = cell-height or pycor = (- cell-height))
       and
      (pxcor > (-(cell-width + 1)) and pxcor < (cell-width + 1))
    ])
    ; the horizontal part of the cell wall
    (patches with [
       (pxcor = cell-width or pxcor = (- cell-width))
        and
       (pycor > (-(cell-height + 1)) and pycor < (cell-height + 1))
     ])
  )
  set-cell-color brown

  ; patches inside the cell-wall are set white.
  set cell-patches patches with [
    (pycor > (- cell-height) and pycor < cell-height)
     and
    (pxcor > (- cell-width)  and pxcor < cell-width)
  ]
  ask cell-patches [ set pcolor white ]

  ; the operon patches are blue
  set operon patches with [ (pycor > -1 and pycor < 2) and (pxcor > -10 and pxcor < 17) ]
  ask operon [ set pcolor blue ]

  ; promoter is green
  set promoter patches with [ (pycor > -1 and pycor < 2) and (pxcor > -22 and pxcor < -14) ]
  ask promoter [ set pcolor green ]

  ; operator is orange
  set operator patches with [
   ((pycor = 0) and (pxcor > -15 and pxcor < -9))
    or
   (( pycor = 1) and (( pxcor = -10) or ( pxcor = -12) or ( pxcor = -14)))
  ]
  ask operator [ set pcolor orange ]

  ; the terminator patches are gray
  set terminator patches with [
    ((pycor > -1) and (pycor < 2))
     and
    ((pxcor > 16 and pxcor < 19))
  ]
  ask terminator [ set pcolor gray ]
end

; procedure to animate the process of cell division
to animate-cell-division

  create-mask-turtles 1 [
    set size 1000
    set color black
    set shape "square"
  ]

  ask cell-wall [
    sprout-daughter-cell-turtles 1 [
      set color cell-color + 2
      set shape "square"
      set size 2
      set heading 45
    ]
  ]

  ask cell-wall [
    sprout-daughter-cell-turtles 1 [
      set color cell-color + 2
      set shape "square"
      set size 2
      set heading 225
    ]
  ]

  ask cell-patches [
    sprout-daughter-cell-turtles 1 [
      set color pcolor
      set shape "square"
      set size 2
      set heading 45
    ]
  ]

  ask cell-patches [
    sprout-daughter-cell-turtles 1 [
      set color pcolor
      set shape "square"
      set size 2
      set heading 225
    ]
  ]

  ask (patch-set operon promoter operator terminator) [
    sprout-daughter-cell-turtles 1 [
      set color [ pcolor ] of myself + 2
      set shape "square"
      set size 2
      set heading 45
    ]
  ]

  ask (patch-set operon promoter operator terminator) [
    sprout-daughter-cell-turtles 1 [
      set color [ pcolor ] of myself + 2
      set shape "square"
      set size 2
      set heading 225
    ]
  ]

  ask (turtle-set LacYs LacZs RNAPs LacIs lactoses with [inside?]) [
    hatch 1 [
      gen-xy-inside-inside
      set breed daughter-cell-turtles
      set shape [shape] of myself
      set color [color] of myself + 2
      set heading 45
    ]
  ]

  ask (turtle-set LacYs LacZs RNAPs LacIs lactoses with [inside?]) [
    hatch 1 [
      gen-xy-inside-inside
      set breed daughter-cell-turtles
      set shape [shape] of myself
      set color [color] of myself + 2
      set heading 225
    ]
  ]

  repeat 23 [
    ask daughter-cell-turtles [ fd 1 ]
    display
  ]

  ask mask-turtles [ die ]
  ask daughter-cell-turtles [ die ]
end


; procedure that assigns a specific shape to an agent based on breed
to set-shape ; turtle procedure
  if breed = LacIs [
    set size 6
    ifelse partner = nobody [
      set shape "LacI"
    ][ ; if you have a partner, you're a LacI-lactose-complex
      set shape "LacI-lactose-complex"
      set size 6
    ]
  ]
  if breed = RNAPs [
    set size 5
    set shape "RNAP"
    set color brown
  ]
  if breed = lactoses [
    ifelse partner = nobody [
      set size 2
      set shape "pentagon"
      set hidden? false
    ][ ; if you have a partner, you're invisible!
      set hidden? true
     ]
  ]
  if breed = LacYs [
    set shape "pump"
    set color (red + 2)
    set size 3
  ]
  if breed = LacZs [
    set shape "protein2"
    set color (red + 2)
    set size 4
  ]
end

; to keep the lactose amount constant if the lactose? switch is on
to update-lactose [ upper-limit ]
    let num-lactose-outside count lactoses with [ not inside? ]
    ifelse num-lactose-outside > upper-limit [
      ask n-of (num-lactose-outside - upper-limit) lactoses with [ not inside? ] [ die ]
    ][
      create-lactoses (upper-limit - num-lactose-outside) [
        gen-xy-inside-outside
        set inside? false
        set partner nobody
        set-shape
      ]
    ]
end

; procedure to place a molecule inside the cell
to gen-xy-inside-inside ; turtle procedure
  setxy random-xcor random-ycor
  while [ not member? patch-here cell-patches] [
    setxy random-xcor random-ycor
  ]
end

; procedure to place a molecule outside the cell
to gen-xy-inside-outside ; turtle procedure
  setxy random-xcor random-ycor
  while [(member? patch-here cell-wall) or (member? patch-here cell-patches)] [
    setxy random-xcor random-ycor
  ]
end

; procedure to set the color of the cell wall. (this is a separate procedure because
; in LevelSpace, the cell wall color needs to be assigned)
to set-cell-color [ the-color ]
  set cell-color the-color
  ask cell-wall [ set pcolor the-color ]
end

to show-switch-color
  if count lacZs <= 10 [
    ask cell-patches [ set pcolor white ]
  ]
  if count lacZs > 10 and count lacZs <= 20 [
    ask cell-patches [ set pcolor 99 ]
  ]
  if count lacZs > 20 and count lacZs <= 30 [
    ask cell-patches [ set pcolor 98 ]
  ]
  if count lacZs > 30 [
    ask cell-patches [ set pcolor 97 ]
  ]
  ask operon [ set pcolor blue ]
  ask promoter [ set pcolor green ]
  ask operator [ set pcolor orange ]
  ask terminator [ set pcolor gray ]
end


; to convert the string for export-interface 'date-and-time' command to work on windows machines
to-report replace-all [target replacement str]
  let acc str
  while [position target acc != false] [
    set acc (replace-item (position target acc) acc replacement)
  ]
  report acc
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;  LevelSpace Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; procedure to setup the cell according to parameters passed in from the population model
to set-initial-variables [ the-list ]

  ; 'the-list' is the following list of numbers (or counts) and booleans
  ; [ cell-color initial-energy energy initial-LacYs initial-LacYs-inserted initial-LacZs
  ;    initial-LacI-lactose-complexes initial-lactose-inside initial-lactose-outside
  ;    glucose?-setting lactose?-setting ]

  ; we use NetLogo's `item` primitive to directly select elements of the list
  set LevelSpace?      true
  set-cell-color       item 0 the-list
  set initial-energy   item 1 the-list
  set energy           initial-energy
  set lactose?         item 8 the-list
  set glucose?         item 9 the-list

  ; create the necessary turtles
  ask n-of (item 3 the-list) cell-wall [ set pcolor red + 2 ]
  create-LacYs (item 2 the-list) [ gen-xy-inside-inside ]
  create-LacZs (item 4 the-list) [ gen-xy-inside-inside ]
  create-lactoses (item 6 the-list) [
    set inside? true
    set partner nobody
    gen-xy-inside-inside
  ]
  ask n-of (item 5 the-list) LacIs [
    hatch-lactoses 1 [
      set inside? true
      set partner myself
      ask partner [ set partner myself ]
    ]
  ]
  ask turtles [ set-shape ]
end

; procedure to extract list of variables to use in the population model when using LevelSpace
to-report send-variables-list
  report (list (energy) (count LacYs) (count (patches with [pcolor = red + 2])) (count LacZs)
      (count (LacIs with [ partner != nobody ])) (count (lactoses with [ (inside?) and (partner = nobody) ])) (count (lactoses with [ not inside? ])))
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
330
10
943
354
-1
-1
5.0
1
12
1
1
1
0
1
1
1
-60
60
-33
33
1
1
1
ticks
30.0

BUTTON
10
10
90
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
175
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
10
360
165
393
LacI-bond-leakage
LacI-bond-leakage
0
0.1
0.02
0.001
1
NIL
HORIZONTAL

SLIDER
10
400
325
433
LacI-lactose-binding-chance
LacI-lactose-binding-chance
0.99990
1
0.99991
0.00001
1
NIL
HORIZONTAL

SLIDER
10
480
325
513
LacY-degradation-chance
LacY-degradation-chance
0
0.01
4.0E-4
0.0001
1
NIL
HORIZONTAL

SLIDER
170
320
325
353
LacI-number
LacI-number
1
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
170
360
325
393
RNAP-number
RNAP-number
0
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
10
440
325
473
LacI-lactose-separation-chance
LacI-lactose-separation-chance
0
0.01
0.001
0.001
1
NIL
HORIZONTAL

SLIDER
10
520
325
553
LacZ-degradation-chance
LacZ-degradation-chance
0
0.01
1.0E-4
0.0001
1
NIL
HORIZONTAL

SWITCH
180
10
325
43
lactose?
lactose?
1
1
-1000

PLOT
640
360
945
555
Cell Division Time
Time
Number of Ticks
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if division-number > 0 [ plot cell-division-time ]"

SWITCH
180
45
325
78
glucose?
glucose?
0
1
-1000

PLOT
330
360
635
555
LacZ Number
Time
Frequency
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count LacZs"

SWITCH
50
180
190
213
LevelSpace?
LevelSpace?
1
1
-1000

PLOT
10
85
325
315
Energy
NIL
NIL
0.0
10.0
0.0
1000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot energy"

BUTTON
10
45
175
78
save screenshot
export-interface (word \"GenEvo 1 Genetic Switch \" (replace-all \":\" \"-\" date-and-time) \".png\")
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
755
490
932
535
average-cell-division-time
ifelse-value (division-number > 0) [\n  precision (ticks-at-end-of-cell-division / division-number) 0\n][\n \"n/a\"\n]
17
1
11

BUTTON
10
320
165
353
reset
reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model simulates a complex phenomenon in molecular biology: the “switching” (on and off) of genes depending on environmental conditions. Through molecular interactions between specific regulatory proteins and specific DNA sequences, each regulated gene is turn on or off in response to environmental stimuli.

Specifically, it is a model of the [lac-operon](https://en.wikipedia.org/wiki/Lac_operon) of a bacterium (E. coli.), which is responsible for the uptake and digestion of lactose, when lactose is the preferred energy source in the environment. It simulates the regulation of synthesis of the enzymes [permease (LacY)](https://en.wikipedia.org/wiki/Lactose_permease) and [beta-galactosidase (LacZ)](https://en.wikipedia.org/wiki/Beta-galactosidase).

## HOW IT WORKS

This genetic switch is in essence, a positive feedback loop. It is responsible for regulating the synthesis of proteins (LacZ and LacY in this model) required to conduct the uptake and digestion of lactose.

In this model, there are in fact two sugars: glucose and lactose. Glucose is "preferred" as an energy source over lactose. When there is glucose and/or no lactose in the surrounding environment, the genetic switch is at an _off steady-state_. This is because the repressor protein [LacI](https://en.wikipedia.org/wiki/Lac_repressor) prevents (mostly) the bacteria from producing the proteins, by binding to the [operator site](https://en.wikipedia.org/wiki/Operon#General_structure) of the DNA. In this steady state, relatively little permease (LacY) and beta-galactosidase (LacZ) are produced.

When lactose is introduced to the outside environment, the lactose molecules enter into the bacterial cell through permease proteins (LacYs). Some lactose molecules that enter the cell bind to LacIs, preventing LacIs from binding to the operator site of the DNA. This, in turn, causes more LacYs to be produced. The LacYs get inserted into the cell-wall, which causes more lactose to enter the cell, thus creating a positive feedback loop. The LacZs, meanwhile digest lactose molecules inside the cell to produce energy.

The genetic switch is turned on, when there is lactose and no glucose in the environment. Turning on of the switch is represented by changing the color of the cell to shades of blue color.

The effect of glucose (through [cAMP](https://en.wikipedia.org/wiki/Cyclic_adenosine_monophosphate)) is only implicitly modelled. The rate at which LacZ and LacI are produced reduces significantly when glucose is present.

### Important Proteins
1. *RNAP* – These are RNA polymerases that synthesize mRNA from DNA. These are represented by brown blobs in the model. This model does not include mRNAs.
2. *LacI* – The purple-colored shapes in the model represent a repressor (LacI proteins). They bind to the operator region (see below) of the DNA and do not let RNAP to pass along the gene, thus stopping protein synthesis. When lactose binds to LacI, they form LacI-lactose complexes (shown by a purple shape with a grey dot attached to it). These complexes cannot bind to the operator region of the DNA.
3. *LacY* – These are shown in the model as light red rectangles. They are produced when an RNAP passes along the gene. When they hit the cell-wall, they get installed on the cell-wall (shown by light patches). Lactose (grey pentagons) from the outside environment is transported inside the cell through these light red patches.
4. *LacZ* – These are shown as light red colored proteins. They are present inside the cell. When they collide with a lactose molecule, the lactose molecule is digested and energy is produced.

### DNA Regions
There are four important DNA regions in this model:

1. *Promoter* – This region is indicated by the color green. As an RNAP binds to the promoter region and if the operator is free, it moves along DNA to start transcription.
2. *Operator* – This region is indicated by the color orange. The repressor protein, LacI, binds to this region and prevents RNAP from moving along the DNA.
3. *Operon* – This is indicated by the color blue. This is where lacY and lacZ genes are. This model includes only these two genes of the operon.
4. *Terminator* – This is indicated by the color grey. RNAP separates from the DNA when it reaches this region.

As RNAP moves along the gene, LacY and LacZ proteins are produced (five molecules per transcription). We do not show translation by ribosomes in this model.

### Energy of the cell
Producing and maintaining the protein machinery for a cell takes energy. So as a cell produces proteins and maintains those proteins (RNAPs, LacIs and LacZs), its energy decreases.

Energy of the cell increases when lactose inside the cell is digested.

### Cell division
When the energy of the cell doubles from its initial value, it splits into two daughter cells. Each of these cells has half of the energy of the original cell as well as half the number of each type of protein in the original cell.

## HOW TO USE IT

### To setup

Each slider controls a certain aspect of this genetic regulation circuit. Refer to the Sliders Section for more information on the function of each variable.

Once all the sliders are set to the desired levels, the user should click SETUP to initialize the cell.

### To run

To observe the switching behavior of the genetic switch, set GLUCOSE? to ON and LACTOSE? to OFF. Let the simulation run for a few hundred ticks. Observe the changes in the energy of the cell as time progresses and cell divides. The energy drops to half when a cell divides.

To run the simulation faster, uncheck the 'view updates' box for several thousand ticks. Observe the LacZ production in the graph. It varies because of the stochastic nature of the molecular interactions in the cell. This variability even when the switch "is off" is why genetic switches are referred to as "leaky".

Set GLUCOSE? to OFF and LACTOSE? to ON to see the behavior of the genetic switch by observing change in the LacZ production.

While molecular interactions (micro) are best observed through running the simulation with 'view updates' checked, to observe cellular behavior (macro), 'view updates' should be unchecked and the simulation should be run for several thousand ticks.

### Buttons

The SETUP button initializes the model.

The GO button runs the simulation until the cell dies.

### Switches

LACTOSE?  - If ON, lactose is added to the external medium (outside of the cell)

GLUCOSE?  - If ON, glucose is added to the external medium. Glucose is implicitly modelled meaning that when GLUCOSE? is ON, energy of a cell increases at a constant rate (10 units/tick). In addition, since glucose is a "preferred energy source", the lac promoter is less active when GLUCOSE? is ON.

### Sliders

LACI-NUMBER - Sets the number of LacIs

RNAP-NUMBER - Sets the number of RNAPs

LACI-BOND-LEAKAGE - This is the chance a LacI molecule bonded to the operator detaches from the operator

LACI-LACTOSE-BINDING-CHANCE - Sets the chance that a lactose and a LacI come together to form a LacI-lactose complex

LACI-LACTOSE-SEPARATION-CHANCE - Sets the chance that a LacI-lactose complex separates

LACY-DEGRADATION-CHANCE - Sets the chance of degradation of a LacY that is installed on the cell-wall

LACZ-DEGRADATION-CHANCE - Sets the chance of degradation of a LacZ molecules in the cell

### Plots

Energy – Plots the amount of energy in the cell over time

lacZ Number – Plots the number of LacZ molecules inside a cell

Cell Division Time – Plots the number of ticks between two cell division events. It can be used as a growth rate indicator. Shorter cell division time indicates higher growth rate.

## THINGS TO NOTICE

Notice the three parts of the molecular mechanism involved in the control of the genetic switch:
1. Uptake of lactose from outside to inside through LacY
2. Repression by LacI in absence of lactose
3. Formation of LacI-lactose complex in presence of lactose and removal of repression

Notice the changes in energy of the cells when lactose is added (that is, when LACTOSE? is ON and when LACTOSE? is OFF).

Notice the energy changes when a cell divides.

Notice the changes in the Average Cell Division Time as time progresses.

Notice the effect of changes in the environmental conditions (ON/OFF of GLUCOSE? and LACTOSE? on the Average Cell Division Time and the LacZ Number.

## THINGS TO TRY

Try to make the genetic switch more sensitive to the environmental conditions. It should be "on" only when lactose is present and "off" otherwise. You can do this be changing the slider parameters.

If the cell starts to uptake lactose and produce energy faster, does the Average Cell Division Time also decrease?

## EXTENDING THE MODEL

In real life, cells aren't flat! See if you can extend the model into three-dimensions with NetLogo 3D.

## NETLOGO FEATURES

This model uses NetLogo's `with` primitive extensively. This is because, although the different proteins are represented by different `breeds`, the proteins also exist in various states.

## RELATED MODELS

* GenEvo Curricular Models
* GenDrift Sample Models

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S., Bain, C. and Wilensky, U. (2016).  NetLogo GenEvo 1 Genetic Switch model.  http://ccl.northwestern.edu/netlogo/models/GenEvo1GeneticSwitch.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

To cite the GenEvo Systems Biology curriculum as a whole, please use:

* Dabholkar, S. & Wilensky, U. (2016). GenEvo Systems Biology curriculum. http://ccl.northwestern.edu/curriculum/genevo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 GenEvo Cite: Dabholkar, S., Bain, C. -->
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
true
0
Polygon -7500403 true true 180 15 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 285 165 285 225 285 225 15 180 15
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

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

hello
true
0

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
1
Polygon -7500403 true false 150 90 90 135 120 195 180 195 210 135

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

protein2
true
0
Polygon -7500403 true true 150 60 60 210 240 210 150 60 150 60

pump
true
0
Rectangle -7500403 true true 105 60 195 240

rnap
true
10
Circle -13345367 true true 45 75 150
Circle -13345367 true true 105 75 150

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
need-to-manually-make-preview-for-this-model
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
