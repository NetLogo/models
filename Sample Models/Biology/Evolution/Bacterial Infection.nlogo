breed [ antibiotics antibiotic ]
breed [ bacterias bacteria ]
breed [ dividers divider ]

bacterias-own [
  variation
  age
  my-target-patch
]

patches-own [
  region
  port-type
  my-bacteria
]

globals [
  antibiotic-flow-rate
  fever-factor?
  #-minutes
  #-hours
  #-days
  bacteria-counts-region-a
  bacteria-counts-region-b
  doses-given-to-a
  doses-given-to-b
  a-wiped-out?
  b-wiped-out?
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; initial setup procedures  ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  set-default-shape bacterias "bacteria"
  set-default-shape dividers "block"

  set fever-factor? false
  set antibiotic-flow-rate 0.2
  set #-hours 0
  set #-days 0
  set #-minutes 0

  set doses-given-to-a 0
  set doses-given-to-b 0
  set a-wiped-out? false
  set b-wiped-out? false

  setup-regions
  setup-initial-bacteria

  reset-ticks
end

to setup-regions

  let input-port-color red - 2
  let output-port-color yellow - 2
  let divider-color gray - 1
  let region-a-color blue - 1
  let region-b-color gray - 3.5
  let blood-stream-color rgb 255 215 215

  ask patches [
    set port-type "none"
    set my-bacteria nobody
  ]
  ask patches with [ pxcor < 0 ] [ set pcolor region-a-color ]
  ask patches with [ pxcor > 0 ] [ set pcolor region-b-color ]
  ask patches with [ pxcor > min-pxcor and pxcor < -1 ] [ set region "A" ]
  ask patches with [ pxcor < max-pxcor and pxcor >  1 ] [ set region "B" ]
  ask patches with [ region = "A" or region = "B" ] [ set pcolor blood-stream-color ]

  ask patches with [ not member? pxcor (list min-pxcor -1 1 max-pxcor) ] [
    if pycor = max-pycor [
      set pcolor input-port-color
      set port-type "input"
    ]
    if pycor = min-pycor [
      set pcolor output-port-color
      set port-type "output"
    ]
  ]

  ask patches with [ pxcor = 0 ] [
    sprout 1 [
      set breed dividers
      set color divider-color
      set size 1
      set pcolor white
    ]
  ]
end

to setup-initial-bacteria
  let which-variations (list 3 4 5 6)
  let #init-of-each-variation-in-region-a (list init#-3pores-a init#-4pores-a init#-5pores-a init#-6pores-a)
  let #init-of-each-variation-in-region-b (list init#-3pores-b init#-4pores-b init#-5pores-b init#-6pores-b)
  (foreach #init-of-each-variation-in-region-a which-variations [ [n v] -> make-bacteria n v "A" ])
  (foreach #init-of-each-variation-in-region-b which-variations [ [n v] -> make-bacteria n v "B" ])
  update-bacteria-counts
end

to make-bacteria [ number-of-bacteria which-variation which-region ]
  create-bacterias number-of-bacteria [
    let this-bacteria self
    set variation which-variation
    set shape (word "bacteria-holes-" variation)
    set my-target-patch one-of patches with [ region = which-region and my-bacteria = nobody ]
    move-to my-target-patch
    ask my-target-patch [ set my-bacteria this-bacteria ]
    set age (reproduce-every * 60)
    set size 1
    set color variation-color variation
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; runtime procedures  ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  reproduce-bacteria-into-available-space
  ask bacterias [ move-bacteria ]
  move-antibiotics
  dose-each-region
  update-bacteria-counts
  tick
  update-time
end

to dose-each-region
  if not any? bacterias with [ region = "A" ] and not a-wiped-out? [ set a-wiped-out? true ]
  if not any? bacterias with [ region = "B" ] and not b-wiped-out? [ set b-wiped-out? true ]
  auto-dose
end

to update-time
  ; one tick = 1 minute in simulated time
  set #-minutes ticks
  set #-hours floor (ticks / 60)
  set #-days (floor (#-hours / 2.4) / 10)
end

to update-bacteria-counts
  ; Update the global variables used by the four plots showing the
  ; population of different bacteria variations in the two regions.
  ; We use global variables and do this here instead of inside the
  ; plots so we can compute it just once (and save a ton of time).
  let a [ 0 0 0 0 ]
  let b [ 0 0 0 0 ]
  ask bacterias [
    let i variation - 3
    if region = "A" [ set a replace-item i a (item i a + 1) ]
    if region = "B" [ set b replace-item i b (item i b + 1) ]
  ]
  set bacteria-counts-region-a a
  set bacteria-counts-region-b b
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; bacteria  procedures  ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to bacteria-death
  let this-bacteria self
  if is-patch-set? my-target-patch [
    ask my-target-patch [
      set my-bacteria nobody
    ]
  ]
  die
end

to move-bacteria
  let my-distance-to-my-patch-center distance my-target-patch
  let is-ahead-patch-water? false
  let speed-scalar 0.15 ; scales the speed of motion of the bacteria
  if my-distance-to-my-patch-center > 0.2 [
    set heading towards my-target-patch
    forward 0.1 * speed-scalar
    set age 0
  ]
  check-bounce-off-walls
  set age age + 1
end

to check-bounce-off-walls ; turtle procedure
  if member? pxcor (list (min-pxcor + 1) -2 2 (max-pxcor - 1)) [
    if member? [ pxcor ] of patch-ahead 0.5 (list min-pxcor -1 1 max-pxcor) [
      back antibiotic-flow-rate
      set heading (- heading) ; if so, reflect heading around x axis
    ]
  ]
end

to reproduce-bacteria-into-available-space
  let count-of-bacteria count bacterias
  let all-bacteria-that-can-reproduce bacterias with [ can-reproduce? count-of-bacteria ]
  let this-fever-factor 1

  if reproduce? [
    ask all-bacteria-that-can-reproduce [
      let this-region region
      let available-patches neighbors with [ my-bacteria = nobody and this-region = region ]
      let this-bacteria self
      if any? available-patches [
        hatch 1 [
          set my-target-patch one-of available-patches
          ask my-target-patch [ set my-bacteria this-bacteria ]
        ]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; antibiotic procedures  ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to auto-dose
  if give-dose? dose-a-every a-wiped-out? auto-dose-a? doses-given-to-a [
    dose-region "A" a-dosage
    set doses-given-to-a doses-given-to-a + 1
  ]
  if give-dose? dose-b-every b-wiped-out? auto-dose-b? doses-given-to-b [
    dose-region "B" b-dosage
    set doses-given-to-b doses-given-to-b + 1
  ]
end

to-report give-dose? [ dose-every wiped-out? auto-dose? doses-given ]
  report
    ticks mod (dose-every * 60) = 0 and
    not wiped-out? and (
      (auto-dose? = "yes, skip no doses") or
      (auto-dose? = "yes, but skip dose 2" and doses-given != 1) or
      (auto-dose? = "yes, but skip dose 3" and doses-given != 2) or
      (auto-dose? = "yes, but skip dose 4" and doses-given != 3)
    )
end

to dose-region [ region-# dosage ]
  let input-patches patches with [ port-type = "input" and region = region-# ]
  repeat dosage [
    ask one-of input-patches [
      sprout 1 [ make-a-antibiotic-particle ]
    ]
  ]
end

to make-a-antibiotic-particle
  set breed antibiotics
  set shape "molecule"
  set size 0.7
  setxy (xcor - 0.5 + random-float 1) (ycor - 0.5 + random-float 1)
  set heading 180 + (random 35 - random 35)
  set color red
end

to move-antibiotics
  ask antibiotics [
    forward antibiotic-flow-rate
    check-bounce-off-walls
    check-antibiotic-interaction
  ]
end

to check-antibiotic-interaction ; turtle procedure
  let this-molecule self
  if any? bacterias-here [
    ask one-of bacterias-here [
      if kill-this-bacteria? [
        ask this-molecule [ die ]
        bacteria-death
      ]
    ]
    die
  ]
  ; remove 50% of antibiotics every time they flow through the system
  if port-type = "output" and (random round (2 / antibiotic-flow-rate) = 0) [ die ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; visualization procedures  ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report variation-color [ which-variation ]
  report item (which-variation - 3) [ violet green brown red orange ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; plotting procedures  ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-variation-pens [ plot-pen-mode ]
  foreach [ 3 4 5 6 ] [ v ->
    create-temporary-plot-pen (word v)
    set-plot-pen-mode plot-pen-mode ; bar mode
    set-plot-pen-color variation-color v
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;; reporters  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report kill-this-bacteria?
  ; variations go from 3 to 6, for the number of holes in the membrane,
  ; so the odds of getting into the bacteria are 30%, 40%, 50% and 60%
  report random 100 < (variation * 10)
end

to-report can-reproduce? [ total-bacteria-count ]
  let result false
  let this-fever-factor 1
  ; total-bacteria-count is used to simulate a slower growth rate for bacteria as their numbers increase in the body
  ; due to an immune system response of raising the temperature of the body as more an more bacteria above a certain
  ; threshold are detected in the body
  if total-bacteria-count > 50 and fever-factor? [
    set this-fever-factor (1 + 2 * ((total-bacteria-count - 50) / 75))
  ]
  if age >= (reproduce-every * 60 * this-fever-factor) [
    if not any? other bacterias in-radius 0.75 and my-target-patch = patch-here [
      set result true
    ]
  ]
  report result
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
415
100
1060
382
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-24
24
-10
10
1
1
1
minutes
30.0

BUTTON
40
10
115
50
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
120
10
210
51
go/pause
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
15
150
210
310
Patient A
# pores
# of indiv.
3.0
7.0
0.0
16.0
true
false
"make-variation-pens 1 ; 1 means use bar mode" ";; the `histogram` primitive can't make a multi-colored histogram,\n;; so instead we plot each bar individually\nforeach [ 3 4 5 6 ] [ v ->\n  set-current-plot-pen (word v)\n  plot-pen-reset\n  plotxy v item (v - 3) bacteria-counts-region-a\n]\nif (plot-y-max - floor plot-y-max) != 0 [\n  set-plot-y-range 0 floor plot-y-max + 1\n]"
PENS

PLOT
215
150
410
310
Patient B
# pores
# of indiv.
3.0
7.0
0.0
16.0
true
false
"make-variation-pens 1 ; 1 means use bar mode" ";; the `histogram` primitive can't make a multi-colored histogram,\n;; so instead we plot each bar individually\nforeach [ 3 4 5 6 ] [ v ->\n  set-current-plot-pen (word v)\n  plot-pen-reset\n  plotxy v item (v - 3) bacteria-counts-region-b\n]\nif (plot-y-max - floor plot-y-max) != 0 [\n  set-plot-y-range 0 floor plot-y-max + 1\n]"
PENS

TEXTBOX
825
485
1015
503
Initial Infection for Patient B
12
0.0
1

TEXTBOX
500
485
695
503
Initial Infection for Patient A
12
0.0
1

SLIDER
180
60
380
93
reproduce-every
reproduce-every
0.5
4
2.0
0.5
1
hrs
HORIZONTAL

BUTTON
415
10
555
55
manual dose A
dose-region \"A\" a-dosage\nset doses-given-to-a doses-given-to-a + 1
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
305
10
375
55
# of hrs
#-hours
17
1
11

MONITOR
235
10
300
55
# of days
#-days
17
1
11

PLOT
15
310
210
495
population in A vs. time
time (min.)
# of indiv.
0.0
100.0
0.0
16.0
true
false
"make-variation-pens 0 ; 0 means use line mode" "foreach [ 3 4 5 6 ] [ v ->\n  set-current-plot-pen (word v)\n  plotxy ticks item (v - 3) bacteria-counts-region-a\n]"
PENS

BUTTON
755
10
895
55
manual dose B
dose-region \"B\" b-dosage\nset doses-given-to-b doses-given-to-b + 1
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
415
60
555
93
a-dosage
a-dosage
50
200
50.0
50
1
mg
HORIZONTAL

SLIDER
755
60
895
93
b-dosage
b-dosage
50
200
50.0
50
1
mg
HORIZONTAL

SLIDER
560
60
715
93
dose-a-every
dose-a-every
4
24
4.0
2
1
hrs
HORIZONTAL

SLIDER
900
60
1060
93
dose-b-every
dose-b-every
4
24
4.0
4
1
hrs
HORIZONTAL

MONITOR
55
100
167
145
doses given to A
doses-given-to-a
17
1
11

MONITOR
255
100
367
145
doses given to B
doses-given-to-b
17
1
11

SWITCH
40
60
175
93
reproduce?
reproduce?
0
1
-1000

CHOOSER
560
10
715
55
auto-dose-A?
auto-dose-A?
"no, skip all dosing" "yes, skip no doses" "yes, but skip dose 2" "yes, but skip dose 3" "yes, but skip dose 4"
0

CHOOSER
900
10
1060
55
auto-dose-B?
auto-dose-B?
"no, skip all dosing" "yes, skip no doses" "yes, but skip dose 2" "yes, but skip dose 3" "yes, but skip dose 4"
0

SLIDER
425
410
575
443
init#-3pores-a
init#-3pores-a
0
16
4.0
1
1
NIL
HORIZONTAL

SLIDER
425
445
575
478
init#-4pores-a
init#-4pores-a
0
16
4.0
1
1
NIL
HORIZONTAL

SLIDER
580
410
730
443
init#-5pores-a
init#-5pores-a
0
16
4.0
1
1
NIL
HORIZONTAL

SLIDER
580
445
730
478
init#-6pores-a
init#-6pores-a
0
16
4.0
1
1
NIL
HORIZONTAL

SLIDER
755
410
905
443
init#-3pores-b
init#-3pores-b
0
16
4.0
1
1
NIL
HORIZONTAL

SLIDER
755
445
905
478
init#-4pores-b
init#-4pores-b
0
16
4.0
1
1
NIL
HORIZONTAL

SLIDER
910
410
1060
443
init#-5pores-b
init#-5pores-b
0
16
4.0
1
1
NIL
HORIZONTAL

SLIDER
910
445
1060
478
init#-6pores-b
init#-6pores-b
0
16
4.0
1
1
NIL
HORIZONTAL

PLOT
215
310
410
495
population in B vs. time
time (min).
# indiv.
0.0
100.0
0.0
16.0
true
false
"make-variation-pens 0 ; 0 means use line mode" "foreach [ 3 4 5 6 ] [ v ->\n  set-current-plot-pen (word v)\n  plotxy ticks item (v - 3) bacteria-counts-region-b\n]"
PENS

@#$#@#$#@
## WHAT IS IT?

This is a natural/artificial selection model that shows how a population of bacteria can become more antibiotic resistant over time.  The model represents an environment in a patient taking a regiment of antibiotics.

## HOW IT WORKS

Bacteria reproduce asexually, after reaching a certain age, and if there is available space (open patches next to them) for them to move into.

Antibiotics particles kill bacteria when they reach a bacterium and enter through one of its holes in its cell membrane.  Bacteria come in different variations for cell membrane porosity (different variations have different # of holes in their membranes).  The number of holes in the cell membrane affects the odds of an antibiotic entering the bacteria.

There are two patients in this model (patient A and patient B).  The environment in each patient represents the circulatory system of that patient.  The top red line represents where antibiotics enter the blood stream (e.g. through small intestine or an IV).  The bottom yellow line represents where antibiotics are broken down and removed from the blood stream (e.g. the liver or the kidneys).

## HOW TO USE IT

REPRODUCE? turns on and off bacteria reproduction in both patients.

REPRODUCE-EVERY determines how often bacteria can reproduce in both patients, when REPRODUCE? is on.

The INIT#-3PORES-A, INIT#-4PORES-A, INIT#-5PORES-A and INIT#-6PORES-A sliders determine the number of bacteria for each cell membrane variation that patient A will start with.

The INIT#-3PORES-B, INIT#-4PORES-B, INIT#-5PORES-B and INIT#-6PORES-B sliders do the same thing for patient B.

The MANUAL DOSE A and MANUAL DOSE B buttons administer a single dose of antibiotic to that patient.

A-DOSAGE and B-DOSAGE determine the amount of antibiotic administered in a dose to that patient.

AUTO-DOSE-A? and AUTO-DOSE-B? determine whether an automatically administered dosing regiment is followed for that patient.  Options include:

- "no" = no antibiotics are automatically administered
- "yes, every dose" = a dose is automatically administered at a rate determined by       the AUTO-DOSE-A-EVERY or AUTO-DOSE-B-EVERY slider
- "yes, but skip dose 2" = same as above, but dose 2 is skipped.
- "yes, but skip dose 3" = similar to previous, but dose 3 is skipped.

## THINGS TO TRY

Try growing bacteria without any antibiotics at first (set REPRODUCE? to "on" and set both AUTO-DOSE-A? and AUTO-DOSE-B? to "no, skip all dosing").   If you start with equal numbers of each variation in the population, does one variation do better by the time the entire environment is filled with bacteria?

Try not growing bacteria (set REPRODUCE to "off"), and apply a single dose of antibiotic (using the MANUAL DOSE buttons).  Does one variation tend to survive a single dose of antibiotics more often than other variations?

Try growing bacteria with regular antibiotics dosing (set REPRODUCE? to "on" and set both AUTO-DOSE-A? and AUTO-DOSE-B? to "yes, skip no doses").   What levels for A-dosage and B-dosage, seem to be the tipping point for  reliably kill off the bacteria after a few doses?

Repeat the last experiment, but with slightly lower doses, or faster reproduction (REPRODUCE-EVERY) or by changing the AUTO-DOSE-A? and AUTO-DOSE-B? to skip one of the doses. What happens to the bacteria population in these cases?

## EXTENDING THE MODEL

The model could be extended so that food resources were scattered through the environment, and bacteria would need to absorb a certain threshold of food from their surroundings in order to reproduce.  And bacteria with more pores in their cell membrane would absorb food more quickly than those that don't.

Other trait variations (like number of flagella related to speed of movement and metabolism), or cell membrane thickness (related to how fast antiseptics dissolve the cell membrane) could be added to the model.  Additional food expenditure costs could be built in for the building blocks needed from food to make these additional structures during reproduction.

See the Bacteria Food Hunt model in the models library for additional ideas.

## RELATED MODELS

Bacteria Hunt Speeds and Bacteria Food Hunt.

## CREDITS AND REFERENCES

This model is part of a high school unit on evolution, "Why Don't Antibiotics Work Like They Used To?"  The unit is freely available on https://www.nextgenstorylines.org

This model and related curricular materials were developed with funding through a grant from the Gordon and Betty Moore Foundation to Northwestern University and the University of Colorado Boulder.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Quigley, D and Wilensky, U. (2016).  NetLogo Bacterial Infection model.  http://ccl.northwestern.edu/netlogo/models/BacterialInfection.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 Cite: Novak, M. and Quigley, D -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

1-flagella
true
0
Rectangle -7500403 true true 144 150 159 225

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

algae
false
0
Rectangle -7500403 true true 0 0 300 300

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bacteria
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30

bacteria-0
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30

bacteria-1
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Polygon -7500403 true true 90 270 105 285 195 285 210 270 216 254 84 254

bacteria-2
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Polygon -7500403 true true 90 270 105 285 195 285 210 270 225 225 75 225

bacteria-2-membrane
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Rectangle -7500403 true true 75 135 90 180
Rectangle -7500403 false true 210 135 225 180
Rectangle -7500403 true true 210 135 225 180

bacteria-3
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Polygon -7500403 true true 105 285 90 270 75 225 75 195 225 195 225 225 210 270 195 285

bacteria-4
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Polygon -7500403 true true 105 285 90 270 75 225 75 165 225 165 225 225 210 270 195 285

bacteria-5
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Polygon -7500403 true true 105 285 90 270 75 225 75 135 225 135 225 225 210 270 195 285

bacteria-6
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Polygon -7500403 true true 105 285 90 270 75 225 75 105 225 105 225 225 210 270 195 285

bacteria-7
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Polygon -7500403 true true 105 285 90 270 75 225 75 75 225 75 225 225 210 270 195 285

bacteria-8
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Polygon -7500403 true true 105 286 90 271 75 226 75 61 83 44 120 45 182 46 219 46 225 61 225 226 210 271 195 286

bacteria-9
true
0
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30
Polygon -7500403 true true 105 285 90 270 75 225 75 60 90 30 120 15 180 15 210 30 225 60 225 225 210 270 195 285

bacteria-holes-1
true
0
Line -7500403 true 240 75 225 45
Line -7500403 true 240 75 240 120
Line -7500403 true 240 180 240 225
Line -7500403 true 225 255 195 285
Line -7500403 true 225 45 195 15
Line -7500403 true 75 45 105 15
Line -7500403 true 60 75 75 45
Line -7500403 true 60 75 60 180
Line -7500403 true 60 180 60 225
Line -7500403 true 60 225 75 255
Line -7500403 true 105 15 195 15
Line -7500403 true 240 225 225 255
Line -7500403 true 75 255 105 285
Line -7500403 true 105 285 195 285

bacteria-holes-2
true
0
Line -7500403 true 240 75 225 45
Line -7500403 true 240 75 240 120
Line -7500403 true 240 180 240 225
Line -7500403 true 225 255 195 285
Line -7500403 true 225 45 195 15
Line -7500403 true 75 45 105 15
Line -7500403 true 60 75 75 45
Line -7500403 true 60 75 60 120
Line -7500403 true 60 180 60 225
Line -7500403 true 60 225 75 255
Line -7500403 true 105 15 195 15
Line -7500403 true 240 225 225 255
Line -7500403 true 75 255 105 285
Line -7500403 true 105 285 195 285

bacteria-holes-3
true
0
Line -7500403 true 240 75 225 45
Line -7500403 true 240 75 240 120
Line -7500403 true 240 180 240 225
Line -7500403 true 225 255 195 285
Line -7500403 true 225 45 195 15
Line -7500403 true 195 15 180 15
Line -7500403 true 105 15 120 15
Line -7500403 true 75 45 105 15
Line -7500403 true 60 75 75 45
Line -7500403 true 60 75 60 120
Line -7500403 true 60 180 60 225
Line -7500403 true 60 225 75 255
Line -7500403 true 105 285 195 285
Line -7500403 true 240 225 225 255
Line -7500403 true 75 255 105 285

bacteria-holes-4
true
0
Line -7500403 true 240 75 225 45
Line -7500403 true 240 75 240 120
Line -7500403 true 195 285 180 285
Line -7500403 true 240 180 240 225
Line -7500403 true 225 255 195 285
Line -7500403 true 225 45 195 15
Line -7500403 true 195 15 180 15
Line -7500403 true 105 15 120 15
Line -7500403 true 75 45 105 15
Line -7500403 true 60 75 75 45
Line -7500403 true 60 75 60 120
Line -7500403 true 60 180 60 225
Line -7500403 true 60 225 75 255
Line -7500403 true 105 285 120 285
Line -7500403 true 240 225 225 255
Line -7500403 true 75 255 105 285

bacteria-holes-5
true
0
Line -7500403 true 240 75 225 45
Line -7500403 true 240 75 240 120
Line -7500403 true 195 285 180 285
Line -7500403 true 240 180 240 225
Line -7500403 true 225 255 195 285
Line -7500403 true 60 75 75 45
Line -7500403 true 60 75 60 120
Line -7500403 true 60 180 60 225
Line -7500403 true 60 225 75 255
Line -7500403 true 105 285 120 285
Line -7500403 true 240 225 225 255
Line -7500403 true 75 255 105 285
Line -7500403 true 120 15 180 15

bacteria-holes-6
true
0
Line -7500403 true 240 75 225 45
Line -7500403 true 240 75 240 120
Line -7500403 true 240 180 240 225
Line -7500403 true 60 75 75 45
Line -7500403 true 60 75 60 120
Line -7500403 true 60 180 60 225
Line -7500403 true 60 225 75 255
Line -7500403 true 240 225 225 255
Line -7500403 true 120 285 180 285
Line -7500403 true 120 15 180 15

bird
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -16777216 true false 151 125 134 124 128 188 140 198 161 197 174 188 166 125
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Circle -16777216 true false 144 55 7
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

block
false
1
Rectangle -2674135 true true 0 0 120 300
Rectangle -1 true false 150 0 180 300
Rectangle -7500403 true false 180 0 300 300
Rectangle -16777216 true false 120 0 150 300

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

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
true
0
Circle -7500403 true true 0 0 300
Polygon -16777216 true false 0 150 15 180 60 150 15 120
Polygon -16777216 true false 150 0 120 15 150 60 180 15
Polygon -16777216 true false 300 150 285 120 240 150 285 180
Polygon -16777216 true false 150 300 180 285 150 240 120 285

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

divider
false
0
Rectangle -13345367 true false 0 0 150 300
Rectangle -7500403 true true 150 0 300 300

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

flagella
true
0
Rectangle -7500403 true true 144 150 159 225

flagella-1
true
0
Line -7500403 true 150 150 150 285

flagella-2
true
0
Line -7500403 true 135 150 105 285
Line -7500403 true 165 150 180 285

flagella-3
true
0
Line -7500403 true 150 150 150 285
Line -7500403 true 120 150 60 270
Line -7500403 true 180 150 240 270

flagella-4
true
0
Line -7500403 true 135 150 105 285
Line -7500403 true 165 150 180 285
Line -7500403 true 195 135 255 255
Line -7500403 true 105 135 45 255

flagella-5
true
0
Line -7500403 true 150 150 150 285
Line -7500403 true 120 150 60 270
Line -7500403 true 15 210 105 120
Line -7500403 true 180 150 240 270
Line -7500403 true 285 210 195 120

flagella-6
true
0
Line -7500403 true 135 150 105 285
Line -7500403 true 165 150 180 285
Line -7500403 true 195 135 255 255
Line -7500403 true 105 135 45 255
Line -7500403 true 300 195 210 105
Line -7500403 true 0 195 90 105

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

hole
true
0
Polygon -7500403 true true 150 150 165 -15 135 -15

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

molecule
true
0
Circle -2674135 true false 99 129 42
Circle -13345367 true false 129 159 42
Circle -16777216 true false 129 129 42
Circle -13345367 true false 114 99 42
Circle -2674135 true false 144 84 42

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

port
false
0
Polygon -7500403 true true 150 30 15 255 285 255

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
1
@#$#@#$#@
