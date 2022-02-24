globals [
  ; Housekeeping variables
  cell-wall  ; Patch-set containing cell wall patches for boundary checking
  CRISPR     ; Patch-set containing CRISPR DNA patches for boundary checking
  the-virus  ; Stores the virus in the infection
  virus-event

  ; Bacterial attributes
  array      ; List of viral spacers currently stored in the array
]

breed [ RNAPs RNAP ]            ; Brown
breed [ cas9s cas9 ]            ; Green
breed [ guide-RNAs guide-RNA ]  ; Lime
breed [ cas-dimers cas-dimer ]  ; Orange
breed [ viruses virus ]         ; Red

guide-RNAs-own [ sequence bound? ]
viruses-own [ sequence bound? ]
RNAPs-own [ on-dna? ]
cas9s-own [ bound? ]
cas-dimers-own [ bound? ]

to setup [ CRISPR-array unbind-% rnap-processivity-% CRISPR-function-% ]
  clear-all
  ; Build cell wall
  ask patches with [ abs pxcor = max-pxcor ] [ set pcolor gray ]
  ask patches with [ abs pycor = max-pycor ] [ set pcolor gray ]
  set cell-wall patches with [ pcolor = gray ]

  ; Build DNA and CRISPR array
  ask patches with [ (abs pycor = 2) and (abs pxcor <= 10) ] [ set pcolor blue ]
  ask patches with [ (abs pxcor = 10) and (abs pycor <= 2) ] [ set pcolor blue ]
  ; Build CRISPR array (on a plasmid)
  ask patches with [ (pycor = 0) and (abs pxcor <= 2) ] [ set pcolor sky + 1 ]
  set CRISPR patches with [ pcolor = sky + 1 ]
  ask min-one-of CRISPR [ pxcor ] [ set pcolor cyan ]

  set virus-event ""
  set array CRISPR-array
  set guide-unbind-chance unbind-%
  set processivity rnap-processivity-%
  set CRISPR-function CRISPR-function-%

  set-default-shape guide-RNAs "stripe"
  set-default-shape viruses "stripe"

  ; Build polymerases
  create-RNAPs 25 [
    set shape "rnap"
    set color brown
    set on-dna? false
  ]

  ; Initialize the other agent types at steady state.
  ; Instead of needing to run the model for 1000+ ticks, we can use a shortcut:
  ; Produce tons of agents through the normal transcription process
  ; and then degrade the appropriate amount.
  ; Production and degradation of normal cell components only depend on time,
  ; not interactions between agents, so this saves us the time that would be
  ; spent processing particle motion, interactions, and visualization.
  let ticks-per-transcription CRISPR-function / 8  ; Approximate, found by trial and error.
  let transcripts-per-RNAP 5
  let transcriptions transcripts-per-RNAP * count RNAPs
  ask RNAPs [
    repeat transcripts-per-RNAP [
      if random-float 100 < CRISPR-function [ transcribe ]
    ]
  ]
  repeat transcriptions * ticks-per-transcription [ degrade ]

  ask turtles [
    ; Loop-stop construct here imitates a do-while loop.
    loop [
      setxy random-xcor random-ycor
      if not member? patch-here cell-wall [ stop ]
    ]
  ]

  update-labels
  reset-ticks
end

to go
  update-labels
  if done? [ stop ]
  ask RNAPs [ go-RNAPs ]
  ask cas9s [ go-cas9s ]
  ask guide-RNAs [ go-guide-RNAs ]
  ask cas-dimers [ go-cas-dimers ]
  ask viruses [ go-viruses ]
  degrade
  tick
end

; Simulates a virus entering the cell through the cell membrane.
to infect [ seq ] ; Observer procedure
  ask one-of cell-wall [
    sprout-viruses 1 [
      set sequence seq
      set color red
      set bound? false
      set virus-event (word "Virus " sequence " invaded the cell.")
      watch-me
      set the-virus self
    ]
  ]
end

to common-infection
  let guides remove-duplicates map [ i ->
    list (item i array) (count guide-RNAs with [sequence = (item i array)])
  ] n-values length array [ i -> i ]
  set guides sort-by [ [list1 list2] -> item 1 list1 > item 1 list2 ] guides
  let front-range ceiling (processivity / 200 * length array)
  infect item 0 one-of sublist guides 0 front-range
end

; RNAPs move randomly when not on DNA. Under certain circumstances, they
; transcribe the CRISPR array to produce new cas9 proteins, cas1-cas2 dimers,
; and one guide RNA for each spacer in the CRISPR array.
to go-RNAPs ; RNAP procedure
  ifelse on-dna? [
    ; If we are currently transcribing the CRISPR array, keep doing that.
    fd 1
    ; Once we finish, change back to normal movement and produce CRISPR elements.
    if not member? patch-here CRISPR [
      set on-dna? false
      transcribe
    ]
  ] [
    ; If we are not transcribing, move around randomly.
    diffuse-turtle 1
    ; If we end up on the CRISPR promoter, start transcribing.
    if pcolor = cyan and random-float 100 < CRISPR-function [
      set on-dna? true
      move-to patch-here
      set heading 90
    ]
  ]
end

; Cas9 proteins randomly wander through the cell. If they find a guide RNA,
; they can bind to it. If they are already bound to a guide RNA, there is a
; small chance they will unbind it. If they have a guide and find a virus
; with a matching sequence, they cleave the virus.
to go-cas9s
  ; If bound to a guide RNA, several things could happen.
  if bound? [
    ; If there is a virus here, check if it matches the bound guide RNA.
    if any? viruses-here with [ not bound? ] [
      let virus-partner one-of viruses-here
      let partner-sequence [ sequence ] of one-of link-neighbors
      let virus-sequence [ sequence ] of virus-partner
      ; If it matches, destroy the virus.
      if partner-sequence = virus-sequence [
        ask virus-partner [
          set virus-event (word "Virus " sequence " was cleaved by cas9.")
          die
        ]
      ]
    ]
    ; Randomly unbind current guide at a low rate.
    if random-float 100 < guide-unbind-chance [
      ; There should only ever be one guide RNA linked to a cas9 at a time.
      let partner one-of link-neighbors
      ask my-links [ die ]
      ; Update bound? status and appearance for the cas9 and guide RNA.
      set bound? false
      ask partner [
        set bound? false
        diffuse-turtle 1
      ]
    ]
  ]
  ; Random walk through the cell.
  diffuse-turtle 1
  ; If the cas9 is unbound and near an unbound guide RNA, bind it.
  if not bound? and any? guide-RNAs-here with [ not bound? ] [
    ; Grab an unbound guide RNA in the area and tie to it.
    let partner one-of guide-RNAs-here with [ not bound? ]
    move-to partner
    create-link-with partner [ hide-link tie ]
    ; Update bound? status and appearance for the cas9 and guide RNA.
    set bound? true
    ask partner [ set bound? true ]
  ]
end

; Guide RNAs drift randomly through the cell. For more information, see go-cas9s.
to go-guide-RNAs ; Guide-RNA procedure
  if not bound? [ diffuse-turtle 1 ]
end

; Cas1-Cas2 dimers drift randomly through the cell most of the time. When they
; encounter viral genetic material, they carry it to the CRISPR array and
; incorporate a new spacer into the array to match it.
to go-cas-dimers ; Cas-dimer procedure
  ifelse bound? [
    ; If the dimer is carrying viral material, head towards the CRISPR locus.
    set heading towards one-of CRISPR
    fd 1
    ; Once the dimer gets to the locus, add an appropriate spacer and kill the virus.
    if member? patch-here CRISPR [
      let virus-partner one-of link-neighbors
      set array fput ([ sequence ] of virus-partner) array
      ask virus-partner [
        set virus-event (word "Virus " sequence " was added to the array.")
      ]
    ]
  ] [
    ; If the dimer isn't carrying viral material, wander randomly.
    diffuse-turtle 1
    ; If the dimer finds a virus, bind to it.
    if any? viruses-here with [ not bound? ] [
      let virus-partner one-of viruses-here
      move-to virus-partner
      create-link-with virus-partner [ hide-link tie ]
      set bound? true
      ask virus-partner [
        set bound? true
        set virus-event (word "Virus " sequence " was bound by cas1/2.")
      ]
    ]
  ]
end

; If the virus isn't bound to anything (meaning it isn't caught by the cell yet),
; it wanders randomly until it finds the cell's DNA and inserts itself.
to go-viruses ; Virus procedure
  if not bound? [
    ; Move slowly because of its enormous size, but generally towards the DNA.
    set heading towards one-of dna-patches
    fd 0.05
    ; Incorporate into the genome.
    if pcolor = blue [
      move-to patch-here
      set shape "square"
      set bound? true
      set virus-event (word "Virus " sequence " infected the genome.")
      watch-me
    ]
  ]
end

; Controls the random movement of all turtles.
; If you're headed towards the cell wall, just turn until you're not.
to diffuse-turtle [ speed ]  ; Turtle procedure
  rt random-float 360
  while [ wall-ahead? ] [ rt random-float 360 ]
  forward speed
end

; Implements the transcription / translation of the CRISPR array.
; The entire array is transcribed together.
to transcribe ; RNAP procedure
  ; The cas9 gene comes at the start of the CRISPR array.
  hatch-cas9s 1 [
    set color green
    set shape "cas9"
    set bound? false
    ; Distribute around the center of the cell
    setxy 0 0
    repeat 5 [ diffuse-turtle 1 ]
  ]
  ; The array also includes genes for the Cas1-Cas2 complexes.
  ; Each complex needs 2 Cas2 proteins and 4 Cas1 proteins, so
  ; on average one complex will be produced every 4 transcriptions.
  if random-float 1 < 0.25 [
    hatch-cas-dimers 1 [
      set color orange
      set shape "cas dimer"
      set bound? false
      ; Distribute around the center of the cell
      setxy 0 0
      repeat 5 [ diffuse-turtle 1 ]
    ]
  ]
  ; After the cas genes there are copies of each spacer all in a row,
  ; and we produce one guide RNA for each spacer in the array.
  foreach array [ spacer ->
    hatch-guide-RNAs 1 [
      set color turquoise
      set sequence spacer
      set bound? false
      ; Distribute around the center of the cell
      setxy 0 0
      repeat 5 [ diffuse-turtle 1 ]
    ]
    ; High processivity should mean a smaller chance to stop early.
    ; This stop exits the foreach, but not the transcribe procedure.
    if random-float 100 > processivity [ stop ]
  ]
end

; Governs the degradation of proteins and genetic elements in the cell.
to degrade ; Observer procedure
  ; These ask blocks require all turtles in the set to have the variable bound?.

  ; Degrade Cas9 proteins and guide RNAs at a low rate.
  ask (turtle-set cas9s guide-RNAs) [
    if random-float 100 < 0.05 [
      if bound? [
        ask link-neighbors [ set bound? false ]
      ]
      die
    ]
  ]
  ; Viruses and Cas1-Cas2 complexes degrade at a higher rate than Cas9s and guides.
  ; For viruses, innate immune systems like restriction enzymes increase degradation.
  ask viruses [
    if random-float 100 < 0.5 [
      if bound? [
        ask link-neighbors [ set bound? false ]
      ]
      set virus-event (word "Virus " sequence " was degraded by innate resistance.")
      die
    ]
  ]
  ; For Cas1-Cas2 complexes, the whole thing stops working if any of the 6 components
  ; stop working. This is the simplest way to account for that without trying to
  ; model each component as a separate agent.
  ask cas-dimers [
    if random-float 100 < 0.2 [
      if bound? [
        ask link-neighbors [ set bound? false ]
      ]
      die
    ]
  ]
end

to update-labels
  ifelse labels? [
    ask (turtle-set guide-RNAs viruses) [ set label sequence ]
  ] [
    ask turtles [ set label "" ]
  ]
end

; Called in the 'Plot update commands' block of the histogram plots.
; Adjusts the x and y ranges of the histogram dynamically based on the input data.
to update-histogram-ranges [ input-list interval ]
  ; If the input list is empty, let the plot use its default ranges.
  ; Otherwise, adjust the plot axis ranges to fit the input data.
  if not empty? input-list [
    ; Adjust the x range to include the whole input data set.
    ; The x range expands with the data, but never contracts.
    let plot-upper-bound max list plot-x-max (interval + max input-list)
    let plot-lower-bound min list plot-x-min min input-list
    set-plot-x-range plot-lower-bound plot-upper-bound

    ; Adjust the y range based on the input data, avoiding constant shifts.
    ; Find the max bar height using the mode(s) of the input data.
    let list-modes-unique modes input-list
    let list-modes-enumerated filter [ i -> member? i list-modes-unique ] input-list
    let max-bar-height (length list-modes-enumerated) / (length list-modes-unique)
    ; The y range should be about 150% of the max bar height, within a tolerance.
    let grow-threshold ceiling (1.05 * max-bar-height)  ; Bar > 95% of the y max
    let shrink-threshold floor (2 * max-bar-height)     ; Bar < 50% of the y max
    if (plot-y-max <= grow-threshold) or (plot-y-max >= shrink-threshold) [
      set-plot-y-range 0 ceiling (1.5 * max-bar-height) ; Bar = 67% of the y max
    ]
  ]
end

;------------------------------------------------------------------------------;
; Useful reporters

to-report wall-ahead? ; Turtle procedure
  report (member? patch-ahead 1 cell-wall) or (member? patch-ahead 2 cell-wall)
end

to-report dna-patches
  report patches with [pcolor = blue]
end

to-report done?
  report virus-dead? or virus-added? or dna-infected?
end

to-report virus-dead?
  report not any? viruses
end

to-report virus-added?
  ; If the virus is dead, this reporter will be false. The conditional report
  ; is required to avoid a runtime error from using 'of' on a dead agent.
  if virus-dead? [ report false ]
  report [member? patch-here CRISPR and bound?] of the-virus
end

to-report dna-infected?
  ; If the virus is dead, this reporter will be false. The conditional report
  ; is required to avoid a runtime error from using 'of' on a dead agent.
  if virus-dead? [ report false ]
  ; When the virus has infected the cell, it sets bound? true and changes to
  ; a square, but the square shape is the only unique identifier.
  ; If you just check for being on the DNA while bound, any time a protein
  ; binds it and moves over the DNA this reporter will be true.
  report [shape = "square"] of the-virus
end


; Copyright 2019 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
190
20
825
352
-1
-1
19.0
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
-8
8
1
1
1
ticks
30.0

BUTTON
20
20
100
60
setup
setup n-values initial-array-size [random max-virus-types] guide-unbind-chance processivity crispr-function
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
110
20
180
60
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
430
505
500
550
Viruses
count viruses
17
1
11

MONITOR
775
505
825
550
Length
length array
17
1
11

PLOT
190
355
500
495
CRISPR Elements
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
"Guide RNAs" 1.0 0 -10899396 true "" "plot count guide-RNAs"
"Total Cas9s" 1.0 0 -14835848 true "" "plot count cas9s"
"Bound Cas9s" 1.0 0 -5825686 true "" "plot count cas9s with [ bound? ]"
"Cas1/2s" 1.0 0 -955883 true "" "plot count cas-dimers"

PLOT
520
355
825
495
Guide RNAs
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"set-plot-x-range 0 max-virus-types" "update-histogram-ranges sentence ([sequence] of guide-RNAs) (array) 1"
PENS
"RNAs" 1.0 1 -16777216 true "" "histogram [sequence] of guide-RNAs"
"Array" 1.0 1 -2674135 true "" "histogram array"

SLIDER
20
300
180
333
initial-array-size
initial-array-size
1
30
15.0
1
1
NIL
HORIZONTAL

SLIDER
20
345
180
378
max-virus-types
max-virus-types
1
100
30.0
1
1
NIL
HORIZONTAL

MONITOR
520
505
765
550
Bacterial CRISPR Array
array
17
1
11

MONITOR
190
505
260
550
Guide RNAs
count guide-rnas
17
1
11

MONITOR
270
505
340
550
Cas9s
count cas9s
17
1
11

MONITOR
350
505
420
550
Cas1/2s
count cas-dimers
17
1
11

SLIDER
20
435
180
468
processivity
processivity
0
100
80.0
1
1
%
HORIZONTAL

SLIDER
20
480
180
513
CRISPR-function
CRISPR-function
0
100
100.0
1
1
%
HORIZONTAL

BUTTON
20
70
180
115
NIL
common-infection
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
20
125
180
170
random-infection
infect random max-virus-types
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
520
560
825
605
Viral sequences
sort [sequence] of viruses
17
1
11

SWITCH
20
180
180
213
labels?
labels?
1
1
-1000

MONITOR
190
560
500
605
Virus event monitor
virus-event
17
1
11

SLIDER
20
390
180
423
guide-unbind-chance
guide-unbind-chance
0
10
5.0
1
1
%
HORIZONTAL

TEXTBOX
20
220
185
295
Even after a successful\ninfection, turn labels on\nand off by toggling\nthe switch and\npressing go.
12
0.0
1

TEXTBOX
25
555
200
625
The virus event monitor\nshows what interactions\nare taking place.
12
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model illustrates the role that CRISPR plays in defending bacteria from infection by focusing on a single cell surrounded by an unseen environment. In natural environments bacteria are challenged with infectious viruses very often, so bacteria must have ways to defend themselves in order to survive. This is the LevelSpace version of the model that is meant to be controlled by the *CRISPR Ecosystem LevelSpace* model.

There are many ways in which bacteria defend themselves from viruses. Bacterial defense systems can be broadly categorized as innate and adaptive.  Innate systems are generally exploit a feature common to many or all viruses, and do not change based on the bacterium's past. A common example of this would be restriction enzymes, which slice up nucleic acids containing certain base sequences, regardless of where the nucleic acid is from. This is also analogous to our human innate immune system, where white blood cells like macrophages and neutrophils attack foreign material using nonspecific methods like reactive chemicals.

Bacteria were recently found to also employ adaptive immunity in their constant struggle against viruses. This adaptive system is called CRISPR. With it, bacteria are able keep a heritable genetic record of past infection attempts, which makes them and their descendants much more effective at fending off future infections by the same or similar viruses. This is made possible through a system that specifically recognizes the DNA of past viruses using DNA samples called **spacers** stored in a **CRISPR array** and cleaves it using a targeted protein complex.

CRISPR is often very effective in protecting bacteria from infection. However, there are many components to the system that must work together to provide this protection. All of the components are coded for in a single locus, often found on a plasmid separated from the main genome. The structure of this locus is shown below:
![Diagram of a CRISPR locus showing Cas genes and the CRISPR array.](crispr-locus.png)
The whole locus is transcribed together, moving from left to right in this diagram. After transcription, the Cas genes are translated into various Cas proteins, and the spacers in the CRISPR array are processed into guide RNAs.

The spacers in the CRISPR array are short fragments of DNA from viruses that the bacterium or its ancestors encountered in the past. When they are processed into guide RNAs, they are critical for the function of one of the protein components, Cas9. Cas9 proteins bind to one of these guides and uses it to recognize when other DNA might come from the same virus as the original spacer in the array. If the guide and the foreign DNA sequences match, indicating it is probably also a virus, the Cas9 protein is able to cut the DNA and destroy it.

Other Cas proteins are important for maintaining the library of spacers in the CRISPR array. Four Cas1 monomers and two Cas2 monomers can form a protein complex which is capable of taking small sections of DNA from viruses and adding them to the CRISPR array as new spacers. When this happens, the new spacers are added at the 'front' of the array, just after the leader sequence (see the diagram above). This means that the array is roughly ordered so that the most recently encountered viruses are closer to the Cas genes in the locus and are transcribed first. Spacers can also be lost from the array. This tends to be more likely the closer the spacer is to the end of the array, meaning that older spacers tend to be lost first.

The CRISPR system as a whole only works when each of its components is functioning properly, and each component often only works when in conjunction with other components. This model is meant to help illustrate this complex interdependence.

## HOW IT WORKS

There are several types of dynamic agent in this model: RNA polymerases, viruses, guide RNAs, cas9 proteins, and cas1-cas2 complexes. There are also three types of static agent: the bacterial genome, the CRISPR locus, and the cell wall.

The static agents are created when the model is set up and then serve only as interaction points for the dynamic agents. The cell wall is the ring of gray around the outer edge of the cell, and simply contains the other agents. The genome is the ring of darker blue near the center of the cell, representing the circular genome typical of bacteria. The CRISPR locus is the small band of light blue at the center of the cell, with a slightly lighter promoter region at one end. This represents a plasmid, which is often where CRISPR loci are found. The role of the genome and CRISPR locus will be discussed below.

All of the dynamic agents move through the cell at a speed influenced by their relative size. Small molecules like guide RNAs can diffuse very quickly, moderately sized molecules like proteins diffuse slightly more slowly, and very large molecules like viral DNA move very slowly. Viruses diffuse in the general direction of the bacterial genome, while every other dynamic agent moves via a random walk constrained by the cell wall. All of the dynamic agents also have a small chance to degrade on each tick, which is influenced by a variety of factors.

When RNA polymerases encounter the promoter region of the CRISPR locus, there is a chance that they will transcribe the locus and produce the molecular components of the CRISPR system. They do not typically have perfect processivity, meaning that they may fall off of the DNA before transcribing the entire array. In this case, only the CRISPR components that come before the drop location in the locus will be produced.

During an infection, viruses enter the cell at the cell wall. If a virus reaches the genome, it is able to incorporate into the DNA. At this point the cell is considered lost to the infection.

Cas9 proteins move through the cell until they encounter a free guide RNA. If they are not bound to anything, the Cas9 will bind to the guide RNA and begin to carry it around as it continues to move. There is a small chance each tick for the Cas9 to dissociate from the guide. If the Cas9 encounters a virus while it also has a guide RNA, it tries to cut the virus. If the guide matches the virus, the virus will be destroyed, and otherwise the virus is unaffected.

Cas1-Cas2 complexes move through the cell until they encounter a virus. When this happens, they bind to the virus and cut out a sample of it. They then carry the sample to the CRISPR locus in the center of the cell and add a new spacer to the array that matches the invading virus.

## HOW TO USE IT

This model is primarily intended for use as a child model of the CRISPR Ecosystem LevelSpace model. Despite this, it is possible to investigate many aspects of CRISPR at the cell level using this model, which are described below. However, some questions may be better served by using the CRISPR Bacterium model, also found in the Models Library.

This model can be used to investigate the effects of different CRISPR expression strategies. These strategies can involve changes to the overall expression of the locus or changes to the persistent expression of spacers from less recent infection attempts.

This model can also examine how the efficiency of CRISPR is affected by the features of the environment or the invading virus. For example, it is easy to compare how effective CRISPR is at stopping very recently encountered viruses or viruses that are more rare. Similarly, it is possible to see how effective CRISPR becomes when there is an increase or decrease in viral diversity or a change to the array size.

### Buttons

#### `SETUP`
Initializes variables and creates the cell and the CRISPR system's components.

#### `GO`
Runs the model.

#### `RANDOM-INFECTION`
Infects the cell with a random virus.

#### `COMMON-INFECTION`
Infects the cell with a common or recently seen virus, as determined by the cell's CRISPR array.

### Sliders and Switches

#### `LABELS?`
Toggles whether or not guide RNAs and viruses are labeled with their sequence.

#### `INITIAL-ARRAY-SIZE`
Controls the size of the bacterial CRISPR array when the model is initialized. This only has an effect when the model is initialized from the setup button. It does not limit this model when a parent model is interacting with it through LevelSpace.

#### `MAX-VIRUS-TYPES`
Controls the diversity of the viruses that the cell encounters. This only has an effect when interacting with the model through the graphical interface. It does not limit this model when a parent model is interacting with it through LevelSpace.

#### `PROCESSIVITY`
Controls the processivity of the cell's RNA polymerase. The value of the slider is the probability that the polymerase will fall off of the DNA before finishing transcription of the next spacer.

#### `CRISPR-FUNCTION`
Controls the level of expression of CRISPR in the cell. The value of the slider is the probability that an RNA polymerase will transcribe the CRISPR locus when it encounters its promoter.

### Plots and Monitors

#### `CRISPR ELEMENTS`
Plots the number of each component of the CRISPR system in the cell over time. These components include guide RNAs, Cas9 proteins, and Cas1-Cas2 complexes. The number of Cas9 proteins currently bound to a guide RNA is also plotted.

#### `GUIDE RNA COUNT`
Displays the current number of guide RNAs in the cell.

#### `CAS1/2 COUNT`
Displays the current number of Cas1-Cas2 complexes in the cell.

#### `CAS9 COUNT`
Displays the current number of Cas9 proteins in the cell.

#### `VIRUS COUNT`
Displays the current number of viruses in the cell.

#### `GUIDE RNAs`
Plots a histogram comparing the frequency of each guide RNA type currently in the cell (black bars) and the frequency of each viral spacer in the CRISPR array (red bars).

#### `BACTERIAL CRISPR ARRAY`
Shows the current state of the bacterium's CRISPR array. Viral spacers at the left or front of the list are the most recently added.

#### `LENGTH`
Displays the current length of the bacterium's CRISPR array.

## THINGS TO NOTICE

When the model is initially set up, all of the guide RNAs and Cas9 proteins are unbound. After starting the model, Cas9s quickly become bound to guide RNAs. Does every Cas9 have a guide RNA? Why is this the case?

Look at the CRISPR Elements plot or the monitors below it and compare the number of guide RNAs to the number of Cas9 proteins. Why is it advantageous for the cell to have more of one than the other?

Look at the CRISPR Elements plot or the monitors below it and compare the number of Cas9 proteins to the number of Cas1-Cas2 complexes. Why are there fewer Cas1-Cas2 complexes, even though each gene in the locus is transcribed the same number of times?

Look at the Guide RNA histogram. The red bars show the frequency of each type of spacer in the CRISPR array, and the black bars show the frequency of the resulting guide RNAs in the cell. If two types of spacer each occur in the array the same number of times, do they always result in the same number of guide RNAs being produced? Similarly, if one type of spacer occurs in the array many times, does it ever result in fewer guide RNAs than a spacer type that only occurs a few times? In each of these cases, what makes some spacers result in more guide RNAs than others? It may help to also look at the Bacterial CRISPR Array monitor below the plot.

The `COMMON-INFECTION` and `RANDOM-INFECTION` buttons allow the user to test how the cell fights off different types of viruses. The `RANDOM-INFECTION` button introduces a random virus within the level of diversity specified by the `MAX-VIRUS-TYPES` slider into the cell. The `COMMON-INFECTION` button introduces a virus that the cell has seen either very recently or very often (suggesting it is common in the environment) into the cell. Is there a difference in how often these two types of infection succeed? Why do you think that is?

## THINGS TO TRY

How does changing the amount of viral diversity in the external environment influence the cell's ability to fight off infections? This can be accomplished using the `MAX-VIRUS-TYPES` slider. Does it make a difference for both random and common infections, or just one of these infection types?

Changes to the cell's regulation of CRISPR can have a large influence on its efficacy. This can be seen by manipulating the `GUIDE-UNBIND-CHANCE`, `PROCESSIVITY`, and `CRISPR-FUNCTION` sliders. Try to understand what effect each slider has individually. First, the `GUIDE-UNBIND-CHANCE` slider sets how likely it is for guide RNAs to unbind from Cas9 proteins on each tick. Why do you think this might make a difference to the cell? How does changing this slider affect the proportion of Cas9s bound to a guide RNA? Secondly, the `PROCESSIVITY` slider changes how likely it is for RNA polymerases to continue on after finishing transcription of a particular spacer in the array. How does changing this slider affect the number of guide RNAs in the cell? On the Guide RNAs histogram, can you tell why this number changes? Which spacers are most strongly affected by it? Finally, how do the levels of the CRISPR components in the cell change when you increase or decrease the `CRISPR-FUNCTION` slider?

After investigating how using these sliders affects the state of the cell, test how these changes affect the effectiveness of the CRISPR defense system. Do any of these changes affect all types of infections equally? Do some have a greater effect on common infections than random infections or vice versa?

## EXTENDING THE MODEL

One simple extension to the model involves the way viruses are treated after being inactivated. If an invading virus is cut up either by CRISPR or by an innate defense system, it takes some time for the resulting inactive fragments to be completely disassembled. Cas1-Cas2 complexes are able to add spacers during this period, increasing the likelihood that a virus could be fought off in the future. However, the current model treats these fragments as being fully disassembled almost instantly.

This model currently focuses on the role of CRISPR in bacterial defense, and only treats the innate defenses abstractly. An updated version of the model could explicitly include different innate bacterial systems. It could also more accurately treat the cell's ability to direct CRISPR components to act non-randomly, for example by recruiting Cas9 or Cas1-Cas2 complexes to the site of an infection.

Similarly, in this model, viruses are mostly passive invaders, simply diffusing inwards until they reach the genome. In reality, they can be transcribed earlier that that, and this can allow them to actively fight back against bacterial defenses. One interesting extension of this model would be to include more active viruses to showcase the interplay between bacterial defenses and viral evasion tactics.

The model also focuses on the initial stages of a viral infection, but CRISPR can continue to have interesting effects in the later stages. For example, even if the bacterium succumbs to the infection, CRISPR may be able to destroy newly produced viruses before they can be released. To see these effects, the model could be expanded to a longer infection timeline, including viral inhibition of normal transcription, production of new viruses, and using a different criterion for determining the end of an infection. The number of viruses released or destroyed could then be passed back up to the CRISPR Ecosystem LevelSpace parent model to influence the number of new viruses added to the ecosystem.

Another interesting effect that follows naturally from a longer infection timeline would be a treatment of _lysogenic_ infections. Currently, all viruses are assumed to be _lytic_, meaning when they infect a cell they reproduce until the cell dies and releases the new viral particles. While this is true for many viruses, there are also some which are lysogenic. These viruses can insert their DNA into the bacterium's genome. This allows them to 'reproduce' when the bacterium divides, and then revert back to the lytic process described above when their host is in poor health. After the viral DNA is inserted into the bacterial genome, there are several strategies the cell can employ based on its different regulatory machinery. For example, CRISPR may cleave the cell's genome, resulting in the bacterium's death, or simply suppress viral replication when the virus attempts to become lytic again. Modeling these regulatory 'decisions' could be very interesting, and could have interesting effects on the ecosystem if this information was passed up to the CRISPR Ecosystem LevelSpace parent model. This might also require a change to the bacteria in the Ecosystem LevelSpace model.

This model could also be modified to take input from the CRISPR Ecosystem LevelSpace parent model to influence each bacterium's regulatory strategy. For example, the values associated with the `GUIDE-UNBIND-CHANCE`, `PROCESSIVITY`, and `CRISPR-FUNCTION` sliders could be hereditary in the parent model and passed to each child model when it is set up. The parent model could also pass the energy of the bacterium as input, which could be used to determine deviations from the baseline genetic strategy on a per-infection basis.

Bacteria in this model currently do not incur any energy cost from producing each component of the CRISPR system. However, in reality this cost may have important effects on the bacterium's regulatory strategy. This model could be used to calculate the aggregate energy cost to a bacterium with a regulatory strategy defined by the input values of the `GUIDE-UNBIND-CHANCE`, `PROCESSIVITY`, and `CRISPR-FUNCTION` sliders, which could then be used by the CRISPR Ecosystem LevelSpace parent model to determine a per-tick energy penalty specific to each bacterium.

A somewhat more involved modification could be a shift in the nature of the relationship between this model and the CRISPR Ecosystem LevelSpace parent model. This relationship is currently based on an 'event-zoom' paradigm. This means that when a certain event occurs in the parent (like a bacterium meeting a virus), an instance of the child model is initialized, the result of its run is used to determine the outcome of the event in the parent (whether or not the bacteria fights off the virus), and then the child model instance is discarded. An alternative option is a 'persistent child' paradigm. This would mean that each agent in the parent model would have an associated child model instance that persists until the agent is removed from the parent model. This has the potential to be much more detailed and accurate, but comes at the cost of increased computational work and slower runs. Some of the other extensions may be easier to implement in one paradigm or the other, and it is not always clear-cut which paradigm should be used. Are there extensions to the CRISPR LevelSpace model system as a whole that would require a paradigm shift of this type?

## NETLOGO FEATURES

This model is part of a system of models using the LevelSpace extension, which allows multiple NetLogo models to interact and communicate with each other. In this particular case, the 'parent' model is the CRISPR Ecosystem LevelSpace model. Each potential infection in that model is examined on a smaller scale in a 'child' model, which is an instance of this model. Information about the infection scenario is used to initialize the child model, and then the child model is run until the infection is resolved. The outcome of the infection in the child model is then used to determine the outcome of the infection in this model, the 'parent' model.

This model has specific turtle shapes that are able to combine with the shapes of other turtles to form new shapes when they are interacting. For example, when proteins bind to nucleic acids (guide RNAs or viruses), their shapes interact so that the proteins appear to be carrying the bound nucleic acid. This functionality relies on using the agent breed declarations to specify the z-ordering of how they are displayed. Specifically, agent breeds that are declared first (closer to the top of the file) will always be displayed 'under' breeds that are declared later (closer to the end of the file).

This model employs a supplementary function to improve auto scaling behavior for histograms. By default, histograms only autoscale the y-axis. The `update-histogram-ranges` function used here implements x-axis auto scaling which can increase but never decrease the range, similar to the default y-axis auto scaling. It also implements y-axis scaling which can increase or decrease the plot's range. This makes the histogram always take up most of the plot area while keeping the entire histogram visible and minimizing the number of rescaling events.

## RELATED MODELS

CRISPR Ecosystem
CRISPR Ecosystem LevelSpace
CRISPR Bacterium

## CREDITS AND REFERENCES

The image of a CRISPR locus was adapted by Merry Youle of the Small Things Considered blog for their article [Six Questions About CRISPRs](https://schaechter.asmblog.org/schaechter/2011/04/six-questions-about-crisprs.html) from Sorek, R., Kunin, V. & Hugenholz, P. CRISPR - a widespread system that provides acquired resistance against phages in bacteria and archaea. _Nature Reviews Microbiology_ **6**, 181-186 (2008).

For general information about CRISPR, visit https://sites.tufts.edu/crispr/ or see the review below:

  * Barrangou, R. & Marraffini, L. A. CRISPR-Cas Systems: Prokaryotes Upgrade to Adaptive Immunity. _Molecular Cell_ **54**, 234–244 (2014).

For information relevant to possible extensions to the model, see the articles below:

  * Edgar, R. & Qimron, U. The E_scherichia coli_ CRISPR System Protects from Lysogenization, Lysogens, and Prophage Induction. _Journal of Bacteriology_ **192**, 6291–6294 (2010).
  * Labrie, S. J., Samson, J. E. & Moineau, S. Bacteriophage resistance mechanisms. _Nature Reviews Microbiology_ **8**, 317–327 (2010).
  * Modell, J. W., Jiang, W. & Marraffini, L. A. CRISPR–Cas systems exploit viral DNA injection to establish and maintain adaptive immunity. _Nature_ **544**, 101–104 (2017).
  * Samson, J. E., Magadán, A. H., Sabri, M. & Moineau, S. Revenge of the phages: defeating bacterial defences. _Nature Reviews Microbiology_ **11**, 675–687 (2013).
  * Strotskaya, A. et al. The action of _Escherichia coli_ CRISPR–Cas system on lytic bacteriophages with different lifestyles and development strategies. _Nucleic Acids Research_ **gkx042** (2017). doi:10.1093/nar/gkx042

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Woods, P. and Wilensky, U. (2019).  NetLogo CRISPR Bacterium LevelSpace model.  http://ccl.northwestern.edu/netlogo/models/CRISPRBacteriumLevelSpace.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2019 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2019 Cite: Woods, P. -->
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

cas dimer
false
0
Polygon -7500403 true true 75 90 60 105 60 195 75 210 105 210 135 165 165 165 195 210 225 210 240 195 240 105 225 90 195 90 165 135 135 135 105 90

cas9
false
0
Polygon -7500403 true true 150 60
Polygon -7500403 true true 60 150 75 195 105 225 150 240 195 225 225 195 240 150 225 105 195 75 165 150 135 150 105 75 75 105

cas9 bound
false
0
Rectangle -2674135 true false 30 90 270 120
Rectangle -13840069 true false 30 135 270 165
Polygon -7500403 true true 150 60
Polygon -7500403 true true 60 150 75 195 105 225 150 240 195 225 225 195 240 150 225 105 195 75 165 150 135 150 105 75 75 105

cas9 guided
false
0
Rectangle -13840069 true false 30 135 270 165
Polygon -7500403 true true 150 60
Polygon -7500403 true true 60 150 75 195 105 225 150 240 195 225 225 195 240 150 225 105 195 75 165 150 135 150 105 75 75 105

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

rnap
true
0
Circle -7500403 true true 45 75 150
Circle -7500403 true true 105 75 150

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

stripe
false
0
Rectangle -7500403 true true 15 135 285 165

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
setup n-values initial-array-size [random max-virus-types] guide-unbind-chance processivity crispr-function
repeat 50 [ go ]
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
