breed [algae alga]
breed [bacteria bacterium]
breed [flagella flagellum]
breed [dividers divider]
breed [mouse-cursors mouse-cursor]

directed-link-breed [connectors connector]
directed-link-breed [cursor-drags cursor-drag]

flagella-own      [direction]
bacteria-own      [variation energy]
mouse-cursors-own [time-since-last-move old-xcor old-ycor]

globals [
  region-1-boundary-color         ;; color of region 1 boundary
  region-2-boundary-color         ;; color of region 2 boundary
  region-divider-color            ;; color of divider between regions
  algae-color                     ;; color of algae
  bacteria-default-color          ;; color of bacteria when visualize variation setting doesn't apply the 6 color values
  fixed-cursor-color              ;; color of the mouse cursor when picking up and dragging bacterium
  rotating-cursor-color           ;; color of the mouse cursor when getting ready to rotate a bacterium
  fixed-cursor-shape              ;; shape of cursor when picking up and dragging bacterium
  rotating-cursor-shape           ;; shape of cursor when rotating a bacterium
  region-divider-shape            ;; shape of divider between left and right region
  bacteria-size                   ;; size  of bacterium (and flagellum)

  sprout-delay-time               ;; time delay before resprouting algae in a water spot after it has been completely consumed
  max-algae-energy                ;; maximum amount of algae (food energy) in a patch
  min-reproduce-energy-bacteria   ;; minimum amount of energy required before bacteria reproduce
  bacteria-stride                 ;; how far a bacteria moves forward for every flagella it has, every time step

  algae-growth-rate-region-1      ;; how fast algae grows back in region 1  - could be adjusted to represent different light levels
  algae-growth-rate-region-2      ;; how fast algae grows back in region 2  - could be adjusted to represent different light levels
  amount-of-algae-bacteria-eat    ;; amount of algae that bacteria eat every time step in the patch they are in
  regrowth-variability            ;; controls the variability in regrowth rates
  base-metabolism                 ;; the amount of energy every bacteria loses, regardless of the number of flagella it had
  right-turn                      ;; the fixed amount of right turn that every bacterium takes every time step

  new-mouse-down-event?           ;; keeps track of whether the state of the mouse click (down or up) has changed since last time the go procedure was run
]

patches-own [fertile? algae-energy countdown region]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;SETUP PROCEDURES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  set algae-color             green
  set bacteria-default-color  [100 100 100 200]
  set fixed-cursor-color      [0 0 0 50]
  set rotating-cursor-color   [255 0 0 50]
  set region-1-boundary-color gray - 1.5
  set region-2-boundary-color gray - 3.5
  set region-divider-color    gray + 1

  set-default-shape bacteria "bacteria"
  set-default-shape flagella "flagella"
  set fixed-cursor-shape     "circle"
  set rotating-cursor-shape  "circle 2"
  set region-divider-shape   "block"

  set bacteria-size 1
  set min-reproduce-energy-bacteria 100
  set sprout-delay-time 25
  set max-algae-energy 100
  set amount-of-algae-bacteria-eat 5
  set bacteria-stride 0.01
  set algae-growth-rate-region-1 25
  set algae-growth-rate-region-2 25
  set base-metabolism .30
  set right-turn 1
  set new-mouse-down-event? false

  setup-mouse-cursor
  setup-regions
  setup-bacteria
  reset-ticks
end

to setup-regions
  let region-1-patches patches with [ pxcor > min-pxcor and pycor < max-pycor and pycor > min-pycor and pxcor < -1 ]
  let region-2-patches patches with [ pxcor < max-pxcor and pycor < max-pycor and pycor > min-pycor and pxcor > 1 ]
  let number-patches-with-algae-region-1 (floor (left-resource-distribution *  (count region-1-patches) / 100))
  let number-patches-with-algae-region-2 (floor (right-resource-distribution * (count region-2-patches) / 100))
  let patches-in-this-region-with-algae nobody

  let region-height world-height
  let region-width (world-width - 2) / 2
  let region-area (region-height * region-width)

  ask patches [
    set fertile? false
    set algae-energy 0
    set pcolor white
  ]
  ask region-1-patches [ set region 1 ]
  ask region-2-patches [ set region 2 ]

  ;; setup boundary walls around each region
  ask patches with [ region != 1 and region != 2 and pxcor < 0 ] [ set pcolor region-1-boundary-color ]
  ask patches with [ region != 1 and region != 2 and pxcor > 0 ] [ set pcolor region-2-boundary-color ]
  ask patches with [ pxcor = 0 ] [
    sprout 1 [
      set breed dividers
      set shape region-divider-shape
      set color region-divider-color
      set size 1
    ]
  ]

  ;; setup distribution of resources in left region
  if left-resource-location = "anywhere" [
    set patches-in-this-region-with-algae n-of number-patches-with-algae-region-1 region-1-patches
  ]
  if left-resource-location = "around a central point" [
    set patches-in-this-region-with-algae min-n-of number-patches-with-algae-region-1 region-1-patches [ distance patch floor (min-pxcor / 2) 0]
  ]
  if left-resource-location = "vertical strip left side" [
    set patches-in-this-region-with-algae region-1-patches with [ pxcor < min-pxcor + round (region-width * left-resource-distribution / 100) ]
  ]
  if left-resource-location = "vertical strip right side" [
    set patches-in-this-region-with-algae region-1-patches with [ pxcor > 0 - round (region-width * left-resource-distribution / 100) ]
  ]
  if left-resource-location = "horizontal strip" [
    set patches-in-this-region-with-algae region-1-patches with [ abs pycor < round ((region-height / 2) * left-resource-distribution / 100) ]
  ]
  ask patches-in-this-region-with-algae [
    set fertile? true
    set algae-energy max-algae-energy / 2
  ]

  ;; setup distribution of resources in right region
  set patches-in-this-region-with-algae nobody

  if right-resource-location = "anywhere" [
    set patches-in-this-region-with-algae n-of number-patches-with-algae-region-2 region-2-patches
  ]
  if right-resource-location = "around a central point" [
    set patches-in-this-region-with-algae min-n-of number-patches-with-algae-region-2 region-2-patches [ distance patch (floor (max-pxcor / 2) + 1) 0 ]
  ]
  if right-resource-location = "vertical strip left side" [
    set patches-in-this-region-with-algae region-2-patches with [ pxcor < 0 + round (region-width * right-resource-distribution / 100) ]
  ]
  if right-resource-location = "vertical strip right side" [
    set patches-in-this-region-with-algae region-2-patches with [ pxcor > max-pxcor - round (region-width * right-resource-distribution / 100) ]
  ]
  if right-resource-location = "horizontal strip" [
    set patches-in-this-region-with-algae region-2-patches with [ abs pycor < round ((region-height / 2) * right-resource-distribution / 100) ]
  ]
  ask patches-in-this-region-with-algae [
    set fertile? true set algae-energy max-algae-energy / 2
  ]

  ask patches [ color-water-spots-and-add-algae ]
  ask patches [ grow-algae ]
end

;; make patches blue (water colored) and hatch algae in water spots
to color-water-spots-and-add-algae
  if fertile? [
    set pcolor [180 200 230]
    sprout 1 [
      set breed algae
      set shape "algae"
      set color [90 140 90 150]
    ]
  ]
end

to setup-mouse-cursor
  create-mouse-cursors 1 [
    set shape fixed-cursor-shape
    set color fixed-cursor-color
    set size 2
    set hidden? true
  ]
end

;; make all the initial variations of the bacteria in each region
to setup-bacteria
  foreach [1 2 3 4 5 6] [ this-variation ->
    foreach [1 2] [ this-region ->
      create-bacteria initial-#-bacteria-per-variation [
        set variation this-variation
        set energy (min-reproduce-energy-bacteria / 2)
        make-flagella
        move-to one-of patches with [ region = this-region ]
      ]
    ]
  ]
  visualize-bacteria
end

to make-flagella
  let old-heading heading
  let cell-variation variation
  hatch 1 [
    set breed flagella
    set color bacteria-default-color
    set label ""
    set shape (word "flagella-" cell-variation)
    bk 0.4
    set size 1.2
    set direction 0
    create-connector-from myself [
      set tie-mode "fixed"
      set hidden? true
      tie
    ]
  ]
  set heading old-heading
end

to duplicate-population [region-to-duplicate]
  let xcor-offset 0
  let region-to-eliminate 0
  if region-to-duplicate = 1 [
    set xcor-offset 34
    set region-to-eliminate 2
  ]
  if region-to-duplicate = 2 [
    set xcor-offset -34
    set region-to-eliminate 1
  ]
  ask bacteria with [ region = region-to-eliminate ] [
    death
  ]
  ask bacteria with [ region = region-to-duplicate ] [
    hatch 1 [
      make-flagella
      set xcor xcor + xcor-offset
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;RUNTIME PROCEDURES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ifelse wait-to-drag-bacteria? [
    check-mouse-interactions
  ]
  [
    bacteria-live
    ask patches [ replenish-algae ]
    visualize-bacteria
    trace-paths
  ]
  if not mouse-down? or not mouse-inside? [
    ask mouse-cursors [
      set hidden? true
      ask my-out-links [ die ]
    ]
  ]
  tick
end

to check-mouse-interactions
  ask mouse-cursors [
    setxy mouse-xcor mouse-ycor
    if region = 0 [
      ask out-link-neighbors [ death ] ;; remove bacterium if it is dragged outside a region
    ]
  ]
  if mouse-inside? [
    ask mouse-cursors [
      check-new-coordinates
      ifelse mouse-down? [
        if new-mouse-down-event? [ check-attach-bacteria-to-mouse-cursor ]
        if not new-mouse-down-event? [
          set new-mouse-down-event? true
          set time-since-last-move 0
          set shape fixed-cursor-shape
          set color fixed-cursor-color
          set heading 0
        ]
        set time-since-last-move time-since-last-move + 1
        ;; turn cursor a different color, indicating a rotation of the bacterium it is holding is about to occur
        if time-since-last-move > 30 [
          set shape rotating-cursor-shape
          set color rotating-cursor-color
          set heading 0
        ]
        ;; rotate the bacterium that the cursor is holding
        if time-since-last-move > 60 [
          set shape rotating-cursor-shape
          set color rotating-cursor-color
          set heading 0 + (time-since-last-move - 60) * 4
        ]
      ]
      [ set new-mouse-down-event? false ]
      set hidden? (not mouse-down?)
    ]
  ]
  ask mouse-cursors [ set old-xcor mouse-xcor set old-ycor mouse-ycor ]
end

;;  check to see if the mouse cursor moved?
to check-new-coordinates
  if mouse-xcor != old-xcor or mouse-ycor != old-ycor [
    set time-since-last-move 0
    set shape fixed-cursor-shape
    set color fixed-cursor-color
  ]
end

;; check to see if any bacteria is attached to the mouse cursor (being moved around or rotated)
to check-attach-bacteria-to-mouse-cursor
  let target-bacteria bacteria with [ distance myself <= 1 ]
  ask my-out-links [ die ]
  if any? target-bacteria [
    set target-bacteria min-one-of target-bacteria [ distance myself ]
    ask target-bacteria [
      setxy mouse-xcor mouse-ycor
      create-cursor-drag-from myself [
        set hidden? true
        tie
      ]
    ]
  ]
end

;; adjust the size of the algae to reflect how much food is in that patch
to grow-algae
  if fertile? [
    ask algae-here [
      ifelse algae-energy >= 5
        [ set size (algae-energy / max-algae-energy) ]
        [ set size (5 / max-algae-energy) ]
    ]
  ]
end

;; algae replenishes every time step (photosynthesis)
to replenish-algae
  set regrowth-variability 1
  ;; to change resource restoration variability do the following:
  ;; set regrowth-variability 1 - none: 100% chance regrowth every step.
  ;; set regrowth-variability 2 - 1/2 chance to regrow this step, but 2 times as much regrowth when it happens
  ;; set regrowth-variability 10 - 1/10 chance to regrow this step, but 10 times as much regrowth when it happens
  set countdown (countdown - 1)
  ;; fertile patches gain 1 energy unit per turn, up to a maximum max-algae-energy threshold
  if fertile? and countdown <= 0 and random regrowth-variability = 0 [
    if region = 1 [ set algae-energy (algae-energy + algae-growth-rate-region-1 * regrowth-variability / 10) ]
    if region = 2 [ set algae-energy (algae-energy + algae-growth-rate-region-2 * regrowth-variability / 10) ]
    if algae-energy > max-algae-energy [ set algae-energy max-algae-energy ]
  ]
  if not fertile? [ set algae-energy 0 ]
  if algae-energy < 0 [
    set algae-energy 0
    set countdown sprout-delay-time
  ]
  grow-algae
end

to bacteria-live
  ask bacteria [
    move-bacteria
    bacteria-eat-algae
    reproduce-bacteria
    if (energy <= 0 ) [death]
  ]
end

to move-bacteria
  let is-ahead-patch-water? false
  let speed-scalar 0.04 ;; scales the speed of motion of the bacteria
  let speed variation ;; the speed of the bacteria is directly proportional to the number of flagella it has
  ;; the deducation energy per turn is a linear relationship, it is function of speed, where the
  ;;  y-intercept is base-metabolism and the energy-cost-per-flagella is the slope
  let energy-deduction base-metabolism + (speed * energy-cost-per-flagella)
  set energy (energy - energy-deduction)  ;; bacteria lose energy as they move
  ask out-link-neighbors [ move-flagella ]
  right ((random-float 10 - random-float 10) + right-turn)
  fd variation * speed-scalar
  bounce
end

to bounce ;; turtle procedure
  let pxcor-patch-ahead [ pxcor ] of patch-ahead 0.1
  let pycor-patch-ahead [ pycor ] of patch-ahead 0.1
  if (pxcor-patch-ahead = min-pxcor) or (pxcor-patch-ahead = max-pxcor) or (abs pxcor-patch-ahead = 1)
    ; reflect heading around x axis
    [ set heading (- heading) ]
  if (pycor-patch-ahead = min-pycor) or (pycor-patch-ahead = max-pycor)
    ; reflect heading around y axis
    [ set heading (180 - heading) ]
end

to move-flagella
  let flagella-swing 15 ;; magnitude of angle that the flagella swing bqck and forth
  let flagella-speed 60 ;; speed of flagella swinging back and forth
  let new-swing flagella-swing * sin (flagella-speed * ticks)
  set heading bacteria-heading + new-swing
end

to reproduce-bacteria  ;; bacteria procedure
 if (energy >  min-reproduce-energy-bacteria) [
    set energy (energy / 2)     ;; split remaining half of energy between parent and offspring
    hatch 1 [
      make-flagella
      rt random 360
      fd bacteria-stride
    ]
  ]
end

to death ;; death of individual and its attached turtles (the flagella)
  ask out-link-neighbors [ die ]
  die
end

to bacteria-eat-algae  ;; bacteria procedure
  ;; if there is enough algae to eat at this patch, the bacteria eat it and then gain energy from it.
  if algae-energy > amount-of-algae-bacteria-eat [
    ;; algae lose five times as much food energy as the bacteria gains (s trophic level assumption - not 10)
    set algae-energy (algae-energy - (amount-of-algae-bacteria-eat * 5))
    set energy energy + amount-of-algae-bacteria-eat  ;; bacteria gain energy by eating
  ]
  ;; if all the food from algae is consumed in a patch, set the countdown timer to delay when the algae will grow back in this patch
  if algae-energy <= amount-of-algae-bacteria-eat [ set countdown sprout-delay-time ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;VISUALIZATION PROCEDURES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to trace-paths
  ifelse trace-paths?
    [ ask bacteria [ pendown ] ]
    [ clear-drawing
      ask bacteria [ penup ] ]
end

to visualize-bacteria
  ask flagella [
    set hidden? not member? visualize-variation ["flagella only" "flagella and color"]
  ]
  ask bacteria [
    set hidden? visualize-variation = "none"
    set color ifelse-value member? visualize-variation ["as color only" "flagella and color"]
      [ item (variation - 1) (list violet blue (green - 1) brown orange red) ]
      [ bacteria-default-color ]
    ;; the bacterium appears to be filled with different amounts of "fuel", using different shapes, based on the bacterium's energy level
    set shape word "bacteria-" energy-level
    set label-color black
    set label ifelse-value visualize-variation = "# flagella as label" [ word variation "   " ] [ "" ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;REPORTERS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; reports the heading of a bacterium for the flagellum that are attached to it
to-report bacteria-heading
  let this-bacteria-heading 0
  ask in-link-neighbors  [ set this-bacteria-heading heading ]
  report this-bacteria-heading
end

;; reports a whole number of 0 through 9 for the energy level of a bacterium
to-report energy-level
  let level 9 -  floor ((2 * min-reproduce-energy-bacteria - energy) * 10 / (2 * min-reproduce-energy-bacteria))
  if level > 9 [ set level 9 ]
  if level < 0 [ set level 0 ]
  report level
end


; Copyright 2015 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
295
115
1107
568
-1
-1
12.0
1
10
1
1
1
0
1
1
1
-33
33
-18
18
1
1
1
ticks
30.0

BUTTON
5
10
140
45
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
145
10
285
45
go/stop
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
5
315
285
455
Bacteria Population in Left Region
# of flagella
# bugs
0.0
8.0
0.0
10.0
true
false
"" ";; the HISTOGRAM primitive can't make a multi-colored histogram,\n;; so instead we plot each bar individually\nclear-plot\nforeach [1 2 3 4 5 6] [ this-variation ->\n  set-current-plot-pen word this-variation  \" \"\n  plotxy this-variation count bacteria with [variation = this-variation and region = 1]\n]\nif  ( plot-y-max - floor plot-y-max) != 0 [set-plot-y-range 0 floor plot-y-max + 1]"
PENS
"1 " 1.0 1 -8630108 true "" "plotxy 1 count bacteria with [variation = 1 and region = 1]"
"2 " 1.0 1 -13345367 true "" "plotxy 2 count bacteria with [variation = 2 and region = 1]"
"3 " 1.0 1 -10899396 true "" "plotxy 3 count bacteria with [variation = 3 and region = 1]"
"4 " 1.0 1 -8431303 true "" "plotxy 4 count bacteria with [variation = 4 and region = 1]"
"5 " 1.0 1 -955883 true "" "plotxy 5 count bacteria with [variation = 5 and region = 1]"
"6 " 1.0 1 -2674135 true "" "plotxy 6 count bacteria with [variation = 6 and region = 1]"

PLOT
5
170
285
310
Avg. # of flagella vs. Time
time
flagella
0.0
1000.0
1.0
6.0
true
true
"" ""
PENS
"left" 1.0 0 -7500403 true "" "if any? bacteria with [region = 1] [\n plotxy ticks mean [variation] of bacteria with [region = 1]]"
"right" 1.0 0 -13816531 true "" "if any? bacteria with [region = 2] [\n  plotxy ticks mean [variation] of bacteria with [region = 2]]"

MONITOR
520
55
580
100
bacteria
(count bacteria with [region = 1])
0
1
11

SLIDER
5
48
285
81
initial-#-bacteria-per-variation
initial-#-bacteria-per-variation
1
10
3.0
1
1
NIL
HORIZONTAL

PLOT
5
455
285
590
Bacteria Population in Right Region
# of flagella
# bugs
0.0
8.0
0.0
10.0
true
false
"" ";; the HISTOGRAM primitive can't make a multi-colored histogram,\n;; so instead we plot each bar individually\nclear-plot\nforeach [1 2 3 4 5 6] [ this-variation ->\n  set-current-plot-pen word this-variation \" \"\n  plotxy this-variation count bacteria with [variation = this-variation and region = 2]\n]\nif  ( plot-y-max - floor plot-y-max) != 0 [set-plot-y-range 0 floor plot-y-max + 1]"
PENS
"1 " 1.0 1 -8630108 true "set-histogram-num-bars 8" "plotxy 1 count bacteria with [variation = 1 and region = 2]"
"2 " 1.0 1 -13345367 true "set-histogram-num-bars 8" "plotxy 2 count bacteria with [variation = 2 and region = 2]"
"3 " 1.0 1 -10899396 true "set-histogram-num-bars 8" "plotxy 3 count bacteria with [variation = 3 and region = 2]"
"4 " 1.0 1 -8431303 true "set-histogram-num-bars 8" "plotxy 4 count bacteria with [variation = 4 and region = 2]"
"5 " 1.0 1 -955883 true "set-histogram-num-bars 8" "plotxy 5 count bacteria with [variation = 5 and region = 2]"
"6 " 1.0 1 -2674135 true "set-histogram-num-bars 8" "plotxy 6 count bacteria with [variation = 6 and region = 2]"

SLIDER
295
80
515
113
left-resource-distribution
left-resource-distribution
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
5
85
285
118
energy-cost-per-flagella
energy-cost-per-flagella
.05
.50
0.25
.05
1
NIL
HORIZONTAL

CHOOSER
5
120
150
165
visualize-variation
visualize-variation
"flagella and color" "flagella only" "as color only" "none"
0

SLIDER
825
80
1040
113
right-resource-distribution
right-resource-distribution
0
100
0.0
1
1
%
HORIZONTAL

CHOOSER
295
30
515
75
left-resource-location
left-resource-location
"anywhere" "around a central point" "horizontal strip" "vertical strip left side" "vertical strip right side"
0

CHOOSER
825
30
1040
75
right-resource-location
right-resource-location
"anywhere" "around a central point" "horizontal strip" "vertical strip left side" "vertical strip right side"
1

MONITOR
1045
50
1105
95
bacteria
(count bacteria with [region = 2])
17
1
11

TEXTBOX
900
10
990
28
Right Region
13
0.0
1

TEXTBOX
360
10
465
28
Left Region
13
4.0
1

SWITCH
155
120
285
153
trace-paths?
trace-paths?
1
1
-1000

BUTTON
605
80
795
113
>> Duplicate Bacteria >>
duplicate-population 1
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
605
45
795
78
<< Duplicate Bacteria <<
duplicate-population 2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
605
10
795
43
wait-to-drag-bacteria?
wait-to-drag-bacteria?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is a natural/artificial selection model that shows how counterbalancing forces of natural selection from the abiotic and biotic environment and from the distribution of resources needed for survival affect the outcomes of natural selection.

In this model the population of organisms that is effected by natural selection are single celled bacteria.  These bacteria must harvest food (algae) from the environment in order to survive.

When resources such as food or water are distributed differently and/or when the cost for exhibiting different trait variations (in terms of energy or food required to build, maintain, or operate the structures for this trait variation) varies, the outcomes of natural selection will change.

In some environments it will be more advantageous to have physical structures that enable the organism to travel quickly (but use energy faster) and in other environments it will be more advantageous to have physical structures that enable the organism to travel slowly and use energy at a slower rate.

## HOW IT WORKS

Base metabolism determines how much energy is deducted per time step in a model run for every individual bacteria.  ENERGY COST PER FLAGELLA determines how much energy is expended per flagella on each bug per step - this is a proxy for the increased amounts of kinetic required for moving faster by moving more flagella.  Though kinetic energy is a quadratic function of speed, in this model energy expenditure is a linear function of speed of movement.  More flagella result in faster movement as well as faster energy consumption.

When bacteria travel over patches with algae in them, they consume a portion of the algae in that patch each time step.  When all the food the algae produced in a patch is eaten up, it takes a short while before it begins to grow back.  Only patches that have water in them (blue) will (re)grow algae.

Bacteria gain energy from eating algae.  As bacteria gain energy the inside of them visually fills up (like a gas tank).  When they reach a maximum threshold energy level they can asexually reproduce (mitosis), splitting their energy in half between the parent and offspring.  As bacteria lose energy the energy level in them visually drains down.  When the bacteria energy level reaches 0 it will die.

## HOW TO USE IT

1. Adjust the slider parameters (see below), or use the default settings.
2. Press the SETUP button.
4. Press the GO/PAUSE button to begin the model run.
5. View the BACTERIA POPULATION IN LEFT REGION and BACTERIA POPULATION IN RIGHT REGION histograms to watch for shifts in the distribution of trait variations over time.
6. View the AVG. # OF FLAGELLA graph for further evidence of changes in the populations over time.

INITIAL-#-BACTERIA-PER-VARIATION is the number of bacteria you start with in each of the six possible variations in flagella number.  The overall population of bacteria is determined by multiplying this value by 6.

ENERGY-COST-PER-FLAGELLA determines how much energy is lost for every flagella that a bacteria has, each time step.  Bacteria with 6 flagella will lose 6 times this value, whereas bacteria with one flagellum will lose 1 times this value.  This energy loss is deducted on top of a base metabolism energy loss for all bacteria each time step.

VISUALIZE-VARIATION helps you apply different visualization cues to see which variation each a bacterium has.  When set to "flagella and color", the number of flagella will appear on each bacterium and these will flap/twist back and forth as the bacteria moves.  The color of the bacteria will correspond to how many flagella it has (red = 6, orange = 5, yellow = 4, green = 3, blue = 2, and violet = 1).  When set to either "flagella only" or "color only" then the other visualization cue is not shown.  When set to "none" neither of these cues is shown.

TRACE-PATHS? is a visualization tool that shows the path that each bacteria travels.  This can be a useful method to determine whether different variations of bacteria tend to travel in different territories, or where they tend to die out from lack of food.

AVG. # OF FLAGELLA VS. TIME shows how the average # of flagella in each region (left and right) is changing over time.  The minimum that a population can have is 1 and the maximum is 6.

BACTERIA IN LEFT REGION is a histogram showing the distribution of bacteria with different numbers of flagella (and therefore different speeds) in the left region.  Color-coding of the histograms corresponds to the number of flagella that those bacteria have (red = 6, orange = 5, yellow = 4, green = 3, blue = 2, and violet = 1).  BACTERIA IN RIGHT REGION is the corresponding histogram for the bacteria in region 2.

LEFT-RESOURCE-LOCATION describes the shape of how water is distributed in the environment.  Wherever water is distributed is also where algae can grow.  The effects of this chooser value will work in combination with the slider value of LEFT-RESOURCE-DISTRIBUTION.  For example, when the prior is set to "anywhere", a random number of spots (determined by the % set by LEFT-RESOURCE-DISTRIBUTION) are filled with water.  When set to "around a central point", the % LEFT-RESOURCE-DISTRIBUTION slider value determines relative size of the circle compared to the entire environment that the water is within.  When set to "horizontal strip", "vertical strip left side", or "vertical strip right side", the LEFT-RESOURCE-DISTRIBUTION slider value determines the relative width of the strip compared to the entire environment.   A corresponding RIGHT-RESOURCE-LOCATION chooser and RIGHT-RESOURCE-DISTRIBUTION slider determine the settings for the right environment.

WAIT-TO-DRAG? allows the user to move and rotate a bacterium with their mouse cursor when it is set to "on".  When set to "on" and GO/STOP is depressed the user can click and drag a bacteria to any location.  If the user drags a bacterium over the edge of the boundary of a region it will die.  If the user clicks and holds down the mouse button over a bacterium, without moving the cursor, the cursor will change colors in a moment, indicating it is getting ready to turn the orientation of the bacterium.  A few moments later the bacterium will start to rotate in a clockwise turn, until the user releases the mouse button.

DUPLICATE BACTERIA >> will remove all existing bacteria from the right region, and then copies an instance (duplicate) of every bacterium from the left region into the right region.

<< DUPLICATE BACTERIA   will remove all existing bacteria from the left region, and then copies an instance (duplicate) of every bacterium from the right region into the left region.

## THINGS TO NOTICE

The histogram for bacteria in each region tends to shift to the right (increasing average speed) with certain combinations of environmental conditions and tend to shift to the left with other combinations, and sometimes shift toward a middle range value for other combinations.

Some variation between model runs in outcomes can be attributed to the random distribution of bacteria in each region.  This genetic drift affects can be reduced by using the DUPLICATE BACTERIA button between regions, to compare outcomes in two regions that have the same environmental conditions and the same distribution of bacteria in the same locations.

The direction of evolutionary pressures in a region may take one direction at first, early in a model run, but then shift direction as the run progresses.  The effect can often be attributed to how the population is changing the environmental conditions.  Sometimes temporary success of one variation leads to a sudden resource collapse or bloom, which exerts an extreme counterbalancing selective pressure on the population.  This can tend to result in things like an initial tendency for a population to become faster, and the long term outcome of natural selection to be for the population to become slower (after the faster variants have been extirpated from population).

## THINGS TO TRY

Compare a uniform distribution of algae to a smaller amount around a fixed point (50% of lower).  Compare a random distribution of algae (e.g. 75% distributed) to a small amount uniformly distributed on the left side of the ecosystem (e.g. 30% on the "left side of the ecosystem")

Compare how changing the INITIAL-#-BACTERIA-PER-VARIATION slider influences the direction of the evolutionary outcome.

Can you create two different outcomes in different regions, simply by changing the distribution of where the resource is located?  How about by changing the amount of the resource?  How about changing both?

## EXTENDING THE MODEL

A sandbox version of the model could be used to give the player of the model the ability to draw the shape of the environment (walls), set region boundaries (in order to define any sub-space in the environment as a region), and modify (paint and erase) the distribution of the resources using the mouse cursor.

## RELATED MODELS

Bacteria Hunt Speeds

## CREDITS AND REFERENCES

This model is part of the Evolution unit of the ModelSim curriculum, sponsored by NSF grant DRL-1020101.

For more information about the project and the curriculum, see the ModelSim project website: http://ccl.northwestern.edu/modelsim/.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2015).  NetLogo Bacteria Food Hunt model.  http://ccl.northwestern.edu/netlogo/models/BacteriaFoodHunt.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2015 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2015 Cite: Novak, M. -->
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
