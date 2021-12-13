globals
[
  bugs-stride ;; how much a bug moves in each simulation step
  bug-size    ;; the size of the shape for a bug
  bird-size
  invader-size
  bug-reproduce-age ;; age at which bug reproduces

  max-bugs-age
  min-reproduce-energy-bugs ;; how much energy, at minimum, bug needs to reproduce
  max-bugs-offspring ;; max offspring a bug can have

  max-plant-energy ;; the maximum amount of energy a plant in a patch can accumulate
  sprout-delay-time ;; number of ticks before grass starts regrowing
  grass-level ;; a measure of the amount of grass currently in the ecosystem
  grass-growth-rate ;; the amount of energy units a plant gains every tick from regrowth

  invaders-stride ;; how much an invader moves in each simulation step
  birds-stride    ;;  how much a bird moves in each simulation step


  invader-reproduce-age  ;;  min age of invaders before they can reproduce
  bird-reproduce-age     ;;  min age of birds before they can reproduce
  max-birds-age          ;;  max age of birds before they automatically die
  max-invaders-age       ;;  max age of invaders before they automatically die

  birds-energy-gain-from-bugs     ;; how much energy birds gain from eating bugs
  birds-energy-gain-from-invaders ;; how much energy birds gain from eating invaders
  min-reproduce-energy-invaders   ;; energy required for reproduction by invaders
  min-reproduce-energy-birds      ;; energy required for reproduction by birds
  max-birds-offspring             ;; maximum number of offspring per reproductive event for a bird
  max-invaders-offspring          ;; maximum number of offspring per reproductive event for an invader


  bug-color-region-1
  bug-color-region-2
  bird-color-region-1
  bird-color-region-2
  invader-color-region-1 ;; color of invaders
  invader-color-region-2 ;; color of invaders
  grass-color
  dirt-color
  rock-color
  graph-values-for
  max-y-value-graph-1
  max-y-value-graph-2
  region-boundaries
]

breed [rocks rock]

breed [ bugs bug ]
breed [ invaders invader ]
breed [ birds bird ]

breed [ dividers divider ]

turtles-own [ energy current-age max-age #-offspring ]

patches-own [ fertile?  plant-energy countdown region]


to startup
    setup-regions 2
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  set max-plant-energy 100
  set grass-growth-rate 10
  set sprout-delay-time 25
  set bugs-stride 0.3
  set invaders-stride 0.3
  set birds-stride 0.4
  ;;  a larger birds-stride than bugs-stride leads to scenarios where less birds
  ;;  can keep a larger number of bugs in balance.
  set bug-reproduce-age 20
  set invader-reproduce-age 20
  set bird-reproduce-age 40
  set max-birds-age 100
  set max-invaders-age 100
  set max-bugs-age 100
  set birds-energy-gain-from-bugs 25
  set birds-energy-gain-from-invaders 25
  set min-reproduce-energy-birds 30
  set min-reproduce-energy-bugs 10
  set min-reproduce-energy-invaders 10
  set max-bugs-offspring 3
  set max-invaders-offspring 3
  set max-birds-offspring 2
  set bird-size 2.5
  set bug-size 1.2
  set invader-size 1.5


  set bird-color-region-1 (orange  )
  set bird-color-region-2 (orange - 1)
  set invader-color-region-1 (red - 3)
  set invader-color-region-2 (red - 4)
  set bug-color-region-1 (magenta)
  set bug-color-region-2 (blue )
  set grass-color (green)
  set dirt-color (white)
  set rock-color [216 212 196]
  set-default-shape bugs "bug"
  set-default-shape birds "bird"
  set-default-shape invaders "mouse"


  setup-regions 2
  add-starting-grass
  add-bugs 1
  add-bugs 2
  add-birds 1
  add-birds 2
  set graph-values-for "energy of bugs"


  reset-ticks

end



to add-starting-grass
  ask patches [
    set fertile? false
    set plant-energy 0
    set pcolor dirt-color
  ]
  add-grass-in-region 1 left-region-%-grassland
  add-grass-in-region 2 right-region-%-grassland
  add-rocks
end


to add-grass-in-region [ which-region %-grassland ]
  let region-patches patches with [ region = which-region ]
  let n floor ((%-grassland / 100) * count region-patches)
  ask n-of n region-patches [
    set fertile? true
    set plant-energy max-plant-energy / 2
    color-grass
  ]

end



to add-bugs [which-region]
  let region-patches patches with [ region = which-region ]
  let bugs-to-add item (which-region - 1) (list left-initial-bugs right-initial-bugs)
  let bug-color item (which-region - 1) (list bug-color-region-1 bug-color-region-2)
  create-bugs bugs-to-add [                  ;; create the bugs, then initialize their variables
    set color bug-color
    set size bug-size
    set energy 20 + random 20 - random 20    ;; randomize starting energies
    set current-age 0  + random max-bugs-age ;; start out bugs at different ages
    set max-age max-bugs-age
    set #-offspring 0
    move-to one-of region-patches
  ]
end


to add-birds [which-region]
  let region-patches patches with [ region = which-region ]
  let birds-to-add item (which-region - 1) (list left-initial-birds right-initial-birds)
  let bird-color item (which-region - 1) (list bird-color-region-1 bird-color-region-2)
  create-birds birds-to-add [                  ;; create the bugs, then initialize their variables
    set color bird-color
    set size bird-size
    set energy 40 + random 40 - random 40    ;; randomize starting energies
    set current-age 0  + random max-birds-age ;; start out bugs at different ages
    set max-age max-birds-age
    set #-offspring 0
    move-to one-of region-patches
  ]
end


to add-invaders [which-region]
  let region-patches patches with [ region = which-region ]
  let invaders-to-add item (which-region - 1) (list left-invaders-to-add right-invaders-to-add)
  let invader-color item (which-region - 1) (list invader-color-region-1 invader-color-region-2)
  create-invaders invaders-to-add [                  ;; create the bugs, then initialize their variables
    set color invader-color
    set size invader-size
    set energy 40 + random 40 - random 40    ;; randomize starting energies
    set current-age 0  + random max-invaders-age ;; start out bugs at different ages
    set max-age max-invaders-age
    set #-offspring 0
    move-to one-of region-patches
  ]
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; runtime procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  if ticks >= 1000 and constant-simulation-length? [ stop ]

  ask turtles [
    ;; we need invaders and bugs to eat at the same time
    ;; so one breed doesn't get all the tasty grass before
    ;; the others get a chance at it.
    (ifelse breed = bugs     [ bugs-live reproduce-bugs ]
            breed = invaders [ invaders-live reproduce-invaders ]
            breed = birds    [ birds-live reproduce-birds ]
                             [ ] ; anyone else doesn't do anything
    )
  ]

  ask patches [
    ;; only the fertile patches can grow grass
    set countdown random sprout-delay-time
    grow-grass
  ]

  tick
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; bug procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to bugs-live
    move-bugs
    set energy (energy - 1)  ;; bugs lose energy as they move
    set current-age (current-age + 1)
    bugs-eat-grass
    if (current-age > max-age) or (energy < 0) [ die ]
end

to birds-live ;; birds procedure
  move-birds
  set energy (energy - 1)  ;; birds lose energy as they move
  set current-age (current-age + 1)
  birds-eat-prey
   if (current-age > max-age) or (energy < 0) [  die ]
end

to invaders-live ;; invaders procedure
    move-invaders
    set energy (energy - 1)  ;; invaders lose energy as they move
    set current-age (current-age + 1)
    invaders-eat-grass
     if (current-age > max-age) or (energy < 0) [  die ]
end


to move-bugs
  rt random 50 - random 50
  let current-region region
  fd bugs-stride

  keep-in-region current-region
end


to move-birds  ;; birds procedure
  rt random 50 - random 50
  let current-region region
  fd birds-stride
  keep-in-region current-region
end

to move-invaders  ;; invaders procedure
  rt random 40 - random 40
  let current-region region
  fd invaders-stride
  keep-in-region current-region
end

to bugs-eat-grass  ;; bugs procedure
  ;; if there is enough grass to eat at this patch, the bugs eat it
  ;; and then gain energy from it.

  if region = 1  [
    if plant-energy > food-left-bugs-eat [
      ;; plants lose ten times as much energy as the bugs gains (trophic level assumption)
      set plant-energy (plant-energy - (food-left-bugs-eat * 10))
      set energy energy + food-left-bugs-eat  ;; bugs gain energy by eating
    ]
    ;; if plant-energy is negative, make it positive
    if plant-energy <=  food-left-bugs-eat  [set countdown sprout-delay-time ]
  ]
  if region = 2  [
    if plant-energy > food-right-bugs-eat [
      ;; plants lose ten times as much energy as the bugs gains (trophic level assumption)
      set plant-energy (plant-energy - (food-right-bugs-eat * 10))
      set energy energy + food-right-bugs-eat  ;; bugs gain energy by eating
    ]
    ;; if plant-energy is negative, make it positive
    if plant-energy <=  food-right-bugs-eat  [set countdown sprout-delay-time ]
  ]
end

to invaders-eat-grass  ;;  procedure
  ;; if there is enough grass to eat at this patch, the invaders eat it
  ;; and then gain energy from it.

  if region = 1  [
    if plant-energy > food-left-invaders-eat [
      ;; plants lose ten times as much energy as the invaders gains (trophic level assumption)
      set plant-energy (plant-energy - (food-left-invaders-eat * 10))
      set energy energy + food-left-invaders-eat  ;; invaders gain energy by eating
    ]
    ;; if plant-energy is negative, make it positive
    if plant-energy <=  food-left-invaders-eat  [set countdown sprout-delay-time ]
  ]
  if region = 2  [
    if plant-energy > food-right-invaders-eat [
      ;; plants lose ten times as much energy as the invaders gains (trophic level assumption)
      set plant-energy (plant-energy - (food-right-invaders-eat * 10))
      set energy energy + food-right-invaders-eat  ;; invaders gain energy by eating
    ]
    ;; if plant-energy is negative, make it positive
    if plant-energy <=  food-right-invaders-eat  [set countdown sprout-delay-time ]
  ]
end


to birds-eat-prey  ;; birds procedure
    if (any? bugs-here and not any? invaders-here)
        [ask one-of  bugs-here
          [ask out-link-neighbors [die] die ]
           set energy (energy + birds-energy-gain-from-bugs)
         ]
      if (any? invaders-here and not any? bugs-here)
        [ask one-of  invaders-here
          [die]
           set energy (energy + birds-energy-gain-from-invaders)
         ]
      if (any? invaders-here and any? bugs-here)
        [ifelse random 2 = 0   ;; 50/50 chance to eat an invader or a bug if both are on this patch
           [ask one-of  invaders-here
             [die]
             set energy (energy + birds-energy-gain-from-invaders)
             ]
           [ask one-of  bugs-here
             [ask out-link-neighbors [die] die ]
             set energy (energy + birds-energy-gain-from-bugs)
             ]
         ]
end


to reproduce-bugs  ;; bugs procedure
  let number-new-offspring (random (max-bugs-offspring + 1)) ;; set number of potential offspring from 1 to (max-bugs-offspring)
  if (energy > ((number-new-offspring + 1) * min-reproduce-energy-bugs)  and current-age > bug-reproduce-age)
  [
      set energy (energy - (number-new-offspring  * min-reproduce-energy-bugs))      ;;lose energy when reproducing --- given to children
      set #-offspring #-offspring + number-new-offspring
     ; set bugs-born bugs-born + number-new-offspring
      hatch number-new-offspring
      [
        set energy min-reproduce-energy-bugs ;; split remaining half of energy amongst litter
        set current-age 0
        set #-offspring 0
        move-bugs
      ]    ;; hatch an offspring set it heading off in a a random direction and move it forward a step
  ]
end


to reproduce-invaders  ;; invaders procedure
  let number-new-offspring (random (max-invaders-offspring + 1)) ;; set number of potential offspring from 1 to (max-invaders-offspring)
  if (energy > ((number-new-offspring + 1) * min-reproduce-energy-invaders)  and current-age > invader-reproduce-age)
  [
      set energy (energy - (number-new-offspring  * min-reproduce-energy-invaders))      ;;lose energy when reproducing --- given to children
      set #-offspring #-offspring + number-new-offspring
     ; set invaders-born invaders-born + number-new-offspring
      hatch number-new-offspring
      [
        set energy min-reproduce-energy-invaders ;; split remaining half of energy amongst litter
        set current-age 0
        set #-offspring 0
        move-invaders
      ]    ;; hatch an offspring set it heading off in a a random direction and move it forward a step
  ]
end

to reproduce-birds  ;; bugs procedure
  let number-offspring (random (max-birds-offspring + 1)) ;; set number of potential offspring from 1 to (max-invaders-offspring)
  if (energy > ((number-offspring + 1) * min-reproduce-energy-birds)  and current-age > bird-reproduce-age)
  [
    if random 2 = 1           ;;only half of the fertile bugs reproduce (gender)
    [
      set energy (energy - (number-offspring * min-reproduce-energy-birds)) ;;lose energy when reproducing - given to children
      hatch number-offspring
      [
        set current-age 0
        set energy min-reproduce-energy-birds ;; split remaining half of energy amongst litter
        set current-age 0
        move-birds
      ]    ;; hatch an offspring set it heading off in a random direction and move it forward a step
    ]
  ]
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; grass procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to grow-grass  ;; patch procedure
  set countdown (countdown - 1)
  ;; fertile patches gain 1 energy unit per turn, up to a maximum max-plant-energy threshold
  if fertile? and countdown <= 0
     [set plant-energy (plant-energy + grass-growth-rate)
       if plant-energy > max-plant-energy
       [set plant-energy max-plant-energy]
       ]
  if not fertile?
     [set plant-energy 0]
  if plant-energy < 0 [set plant-energy 0 set countdown sprout-delay-time]
  color-grass
end

to color-grass
  if region > 0 [
  ifelse fertile?  [
    ifelse plant-energy > 0
    ;; scale color of patch from whitish green for low energy (less foliage) to green - high energy (lots of foliage)
    [set pcolor (scale-color green plant-energy  (max-plant-energy * 2)  0)]
    [set pcolor dirt-color]
    ]
  [set pcolor rock-color]
  ]
end

to add-rocks
  ask patches with [not fertile? and (region = 1 or region = 2)] [
    sprout 1 [
       set size 1.1
       set shape "square"
       set color gray - 0.5
       stamp
       set size 1
       set heading random 360
       set shape "rock-3"
       set color gray - random-float 1 + random-float 1
       stamp
       set heading random 360
       set shape "rock-2"
       set color gray + 1 + random-float 1
       stamp
       set heading random 360
       ifelse random 2 = 0 [set shape "rock-4"][set shape "rock-0"]
       set color gray + 2 + random-float 0.5
       stamp
       die

    ]
    set pcolor rock-color
   ;; sprout 1 [set breed rocks set shape "rock-1" set color gray set heading random 360 set color (gray - random-float 1 + random-float 1)]
  ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GRAPHING;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to draw-vert-line [ xval ]
  plotxy xval plot-y-min
  plot-pen-down
  plotxy xval plot-y-max
  plot-pen-up
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; REGION MANAGEMENT CODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-regions [ num-regions ]
  ; Store our region definitions globally for faster access:
  set region-boundaries calculate-region-boundaries num-regions
  ; Set the `region` variable for all patches included in regions:
  let region-numbers n-values num-regions [ n -> n + 1 ]
  (foreach region-boundaries region-numbers [ [boundaries region-number] ->
    ask patches with [ pxcor >= first boundaries and pxcor <= last boundaries ] [
      set region region-number
    ]
  ])
  add-dividers
end

to add-dividers
  set-default-shape dividers "block"
  ask patches with [ region = 0 ] [
    sprout-dividers 1 [
      set color gray + 2
      set size 1.2
    ]
  ]
end

to-report calculate-region-boundaries [ num-regions ]
  ; The region definitions are built from the region divisions:
  let divisions region-divisions num-regions
  ; Each region definition lists the min-pxcor and max-pxcor of the region.
  ; To get those, we use `map` on two "shifted" copies of the division list,
  ; which allow us to scan through all pairs of dividers
  ; and built our list of definitions from those pairs:
  report (map [ [d1 d2] -> list (d1 + 1) (d2 - 1) ] (but-last divisions) (but-first divisions))
end

to-report region-divisions [ num-regions ]
  ; This procedure reports a list of pxcor that should be outside every region.
  ; Patches with these pxcor will act as "dividers" between regions.
  report n-values (num-regions + 1) [ n ->
    [ pxcor ] of patch (min-pxcor + (n * ((max-pxcor - min-pxcor) / num-regions))) 0
  ]
end

to keep-in-region [ which-region ] ; turtle procedure
  ; This is the procedure that make sure that turtles don't leave the region they're
  ; supposed to be in. It is your responsibility to call this whenever a turtle moves.
  if region != which-region [
    ; Get our region boundaries from the global region list:
    let region-min-pxcor first item (which-region - 1) region-boundaries
    let region-max-pxcor last item (which-region - 1) region-boundaries
    ; The total width is (min - max) + 1 because `pxcor`s are in the middle of patches:
    let region-width (region-max-pxcor - region-min-pxcor) + 1
    ifelse xcor < region-min-pxcor [ ; if we crossed to the left,
      set xcor xcor + region-width   ; jump to the right boundary
    ] [
      if xcor > region-max-pxcor [   ; if we crossed to the right,
        set xcor xcor - region-width ; jump to the left boundary
      ]
    ]
  ]
end


; Copyright 2015 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
364
185
1209
617
-1
-1
9.0
1
10
1
1
1
0
1
1
1
-46
46
-23
23
1
1
1
ticks
30.0

BUTTON
10
10
84
43
setup
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
94
10
185
44
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
12
88
358
362
Left Region Population Size vs. Time
time
population size
0.0
1000.0
0.0
1200.0
true
true
"set grass-level ( sum [plant-energy] of patches with [region = 1]/ (max-plant-energy ))\nset max-y-value-graph-1 plot-y-max\nif max-y-value-graph-2 > max-y-value-graph-1 [\n  set-plot-y-range 0 max-y-value-graph-2\n]" "set grass-level ( sum [plant-energy] of patches with [region = 1]/ (max-plant-energy ))\nset max-y-value-graph-1 plot-y-max\nif max-y-value-graph-2 > max-y-value-graph-1 [\n  set-plot-y-range 0 max-y-value-graph-2\n]"
PENS
"bugs" 1.0 0 -5825686 true "" "plot count bugs with [region = 1]"
"grass" 1.0 0 -10899396 true "" "plot grass-level"
"birds" 1.0 0 -817084 true "" "plot count birds with [region = 1]"
"invaders" 1.0 0 -13628663 true "" "plot count invaders with [region = 1]"

SLIDER
825
90
995
123
right-initial-bugs
right-initial-bugs
0
300
100.0
1
1
NIL
HORIZONTAL

SWITCH
10
48
240
81
constant-simulation-length?
constant-simulation-length?
0
1
-1000

SLIDER
388
90
558
123
left-initial-bugs
left-initial-bugs
0
300
100.0
1
1
NIL
HORIZONTAL

PLOT
12
367
358
641
Right Region Population Size vs. Time
time
population size
0.0
1000.0
0.0
1200.0
true
true
"set grass-level ( sum [plant-energy] of patches with [region = 2]/ (max-plant-energy ))\nset max-y-value-graph-2 plot-y-max\nif max-y-value-graph-1 > max-y-value-graph-2 [\n  set-plot-y-range 0 max-y-value-graph-1\n]" "set grass-level ( sum [plant-energy] of patches with [region = 2]/ (max-plant-energy ))\nset max-y-value-graph-2 plot-y-max\nif max-y-value-graph-1 > max-y-value-graph-2 [\n  set-plot-y-range 0 max-y-value-graph-1\n]"
PENS
"bugs" 1.0 0 -13345367 true "" "plot count bugs with [region = 2]"
"grass" 1.0 0 -10899396 true "" "plot grass-level"
"birds" 1.0 0 -2269166 true "" "plot count birds with [region = 2]"
"invaders" 1.0 0 -13628663 true "" "plot count invaders with [region = 2]"

TEXTBOX
779
12
799
122
|\n|
50
0.0
1

TEXTBOX
777
12
797
122
|\n|
50
5.0
1

TEXTBOX
608
164
738
182
Left Ecosystem
14
124.0
1

TEXTBOX
1050
165
1175
184
Right Ecosystem
14
105.0
1

MONITOR
388
130
438
175
bugs
count bugs with [region = 1]
0
1
11

MONITOR
839
130
889
175
bugs
count bugs with [region = 2]
17
1
11

SLIDER
390
55
560
88
food-left-bugs-eat
food-left-bugs-eat
.1
8
4.0
.1
1
NIL
HORIZONTAL

SLIDER
825
55
995
88
food-right-bugs-eat
food-right-bugs-eat
0.1
8.0
4.0
.1
1
NIL
HORIZONTAL

SLIDER
569
12
764
45
left-region-%-grassland
left-region-%-grassland
0
100
60.0
1
1
NIL
HORIZONTAL

SLIDER
1001
12
1206
45
right-region-%-grassland
right-region-%-grassland
0
100
100.0
1
1
NIL
HORIZONTAL

MONITOR
488
130
548
175
invaders
count invaders with [region = 1]
17
1
11

MONITOR
438
130
488
175
birds
count birds with [region = 1]
17
1
11

SLIDER
569
90
764
123
left-invaders-to-add
left-invaders-to-add
0
300
150.0
1
1
NIL
HORIZONTAL

SLIDER
568
55
765
88
food-left-invaders-eat
food-left-invaders-eat
0.1
8
4.0
.1
1
NIL
HORIZONTAL

BUTTON
593
127
740
160
L - launch invasion
add-invaders 1
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
889
130
939
175
birds
count birds with [region = 2]
17
1
11

MONITOR
939
130
999
175
invaders
count invaders with [region = 2]
17
1
11

SLIDER
1004
54
1206
87
food-right-invaders-eat
food-right-invaders-eat
0.1
8
4.0
0.1
1
NIL
HORIZONTAL

SLIDER
1002
89
1205
122
right-invaders-to-add
right-invaders-to-add
0
300
150.0
1
1
NIL
HORIZONTAL

BUTTON
1034
126
1181
159
R - launch invasion
add-invaders 2
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
823
12
993
45
right-initial-birds
right-initial-birds
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
389
13
559
46
left-initial-birds
left-initial-birds
0
100
29.0
1
1
NIL
HORIZONTAL

MONITOR
250
35
330
80
time
ticks
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model explores the stability of consumer producer ecosystems when different  initial populations of predator, prey, and producers are initialized into the model and when different numbers of invasive species are added to the model run.

## HOW IT WORKS

Bugs wander randomly around one of two regions (left or right).  Each region is a self contained ecosystem  in the world.  Bugs in one region never go into the other region.    As bugs reach the edge of their region, they wrap around to other side of their own region.

Each step (tick), each bug loses one unit of energy and they must consume a food source (grass) to replenish their energy. When they run out of energy, they die. To allow the population to continue, each bug must have enough energy to have an offspring.  When that threshold is reached for an individual bug, it has an offspring. The offspring and parent split the energy amongst themselves.
Different amounts of grassland can be assigned to each region using the sliders. Grass is eaten when a bug moves over that patch. When this happens a fixed amount of grass energy is deducted from the patch (square) where the grass was eaten. Within each region, grass regrows at a fixed rate.

Birds wander randomly around one of two regions (left or right), following similar movement, energy loss, and reproduction rules as the bugs. Birds eat bugs, and not grass.

An invasive species can be introduced into either ecosystem in the model. Individuals of the invasive species wander randomly around the regions in which they are introduced. Their movement, energy loss, and reproduction rules are the same as the bugs. They also eat grass.

## HOW TO USE IT

1. Adjust the slider parameters (see below), or use the default settings.
2. Press the SETUP button.
4. Press the GO button to begin the model run.
5. View the LEFT REGION POPULATION SIZE VS. TIME and RIGHT REGION POPULATION SIZE VS. TIME plot to watch the bug and grass populations fluctuate over time in each of the regions on the screen.
6. View the number of ticks the simulation has run for in the TIME monitor.

Monitors for BUGS, BIRDS, and INVADERS will report for both the left and right region, depending on where the monitors are located (the left side of the interface or the right).


Initial Settings:

CONSTANT-SIMULATION-LENGTH:  When turned "on" the model run will automatically stop at 1000 ticks.  When turned "off" the model run will continue running without automatically stopping.

LEFT-INITIAL-BIRDS and RIGHT-INITIAL-BIRDS:  Determines the initial size of the bird population in that region.

FOOD-LEFT-BUGS-EAT and FOOD-RIGHT-BUGS-EAT:  Sets the amount of energy that bugs in that region gain from eating grass at a patch as well as the amount of energy deducted from that grass patch.

LEFT-INITIAL-BUGS and RIGHT-INITIAL-BUGS:  Determines the initial size of the bug population in that region.

LEFT-REGION-%-OF-GRASSLAND and RIGHT-REGION-%-OF-GRASSLAND: The percentage of patches in the world & view that produce grass in that region.  The grass patches that don't produce grass will show "gray" rocks/gravel.

FOOD-LEFT-INVADERS-EAT and FOOD-RIGHT-INVADERS-EAT:  Sets the amount of energy that all invaders in that region gain from eating grass at a patch as well as the amount of energy deducted from that grass.

LEFT-INVADERS-TO-ADD and RIGHT-INVADERS-TO-ADD:  Determines the size of invader population to add to that region, when the corresponding LAUNCH INVASION button is pressed.

## THINGS TO NOTICE

Watch as the grass, bug, bird, and invader populations fluctuate.  How are increases and decreases in the sizes of each population related?

Different % of grassland values affect the carrying capacity (average values) for both the bugs, grass, birds, and invasive. Why?

Different food consumption values (FOOD-LEFT-BUGS-EAT and FOOD-RIGHT-BUGS-EAT and
FOOD-LEFT-INVADERS-EAT and FOOD-RIGHT-INVADERS-EAT) may lead to different levels of stability as well as whether one population (bugs vs. invaders) outcompetes the other.

## THINGS TO TRY

Try adjusting the parameters under various settings. How sensitive is the stability of the model to the particular parameters? Does the parameter setting affect the amount of fluctuations, the carrying capacity of bugs, grass, invaders, or birds, or does it lead to the collapse of one population in the ecosystem?

## NETLOGO FEATURES

The two regions in this model are represented by shapes that add another "wall" that surround the region.

## RELATED MODELS

Refer to Bug Hunt Disruptions and Bug Hunt Environmental Changes for extensions of this model that include temporary disturbances such as fire and disease.

## CREDITS AND REFERENCES

This model is part of the Ecology & Population Biology unit of the ModelSim curriculum, sponsored by NSF grant DRL-1020101.

For more information about the project and the curriculum, see the ModelSim project website: http://ccl.northwestern.edu/modelsim/.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2015).  NetLogo Bug Hunt Predators and Invasive Species - Two Regions model.  http://ccl.northwestern.edu/netlogo/models/BugHuntPredatorsandInvasiveSpecies-TwoRegions.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

block
false
1
Rectangle -2674135 true true 0 0 135 300
Rectangle -7500403 true false 195 0 300 300
Rectangle -16777216 true false 135 0 180 300
Rectangle -1 true false 165 0 195 300

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

bug-infected
true
10
Circle -7500403 true false 96 182 108
Circle -7500403 true false 110 127 80
Circle -7500403 true false 110 75 80
Line -7500403 false 150 100 80 30
Line -7500403 false 150 100 220 30

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
14
Circle -16777216 true true 0 0 300
Circle -1 false false 29 29 242

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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -1184463 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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

rock-0
false
0
Circle -7500403 true true 105 0 60
Circle -7500403 true true 174 114 42
Circle -7500403 true true 120 240 60
Circle -7500403 true true 45 90 60
Circle -7500403 true true 204 39 42
Circle -7500403 true true 24 174 42
Circle -7500403 true true 69 234 42
Circle -7500403 true true 234 129 42
Circle -7500403 true true 249 9 42
Circle -7500403 true true 249 234 42
Circle -7500403 true true -6 69 42
Circle -7500403 true true 204 219 42

rock-1
false
0
Polygon -7500403 true true 0 300 60 300 45 270 30 255 15 255
Polygon -7500403 true true 0 30 0 75 45 90 60 60 45 15 30 0
Polygon -7500403 true true 300 255 285 285 285 300 255 300 240 270 270 255
Polygon -7500403 true true 300 60 240 90 210 60 240 15 255 0

rock-2
true
0
Polygon -7500403 true true 0 105 -15 150 0 180 30 195 75 195 105 165 105 135 75 105 45 90 15 90
Polygon -7500403 true true 120 0 165 0 195 30 195 45 180 60 150 60 120 45 105 15
Polygon -7500403 true true 180 75 135 75 105 105 105 120 120 135 150 135 180 120 195 90
Polygon -7500403 true true 270 75 225 90 210 180 240 225 270 225 300 180 300 105
Polygon -7500403 true true 60 240 75 285 165 300 210 270 210 240 165 210 90 210

rock-3
true
0
Polygon -7500403 true true 180 165 135 150 105 165 90 195 75 240 105 285 165 285 195 255 195 210 195 180
Polygon -7500403 true true 30 60 75 60 105 90 105 105 90 120 60 120 30 105 15 75
Polygon -7500403 true true 120 150 120 105 90 75 75 75 60 90 60 120 75 150 105 165
Polygon -7500403 true true 240 180 195 165 165 105 180 45 240 30 270 75 270 150

rock-4
true
0
Polygon -7500403 true true 15 120 0 165 15 195 45 210 75 195 75 180 90 150 90 120 60 105 30 105
Polygon -7500403 true true 120 0 165 0 195 30 195 45 180 60 150 60 120 45 105 15
Polygon -7500403 true true 270 105 225 105 195 135 195 150 210 165 240 165 270 150 285 120
Polygon -7500403 true true 135 75 180 90 195 180 165 225 135 225 105 180 105 105
Polygon -7500403 true true 105 240 120 285 210 300 255 270 255 240 210 210 135 225

rocks-4
false
0
Circle -7500403 true true 30 60 60
Circle -7500403 true true 84 189 42
Circle -7500403 true true 129 69 42
Circle -7500403 true true 180 105 60
Circle -7500403 true true 135 240 60
Circle -7500403 true true 114 129 42
Circle -7500403 true true 204 39 42
Circle -7500403 true true 84 -6 42
Circle -7500403 true true 24 174 42
Circle -7500403 true true 69 234 42
Circle -7500403 true true 264 129 42
Circle -7500403 true true 9 249 42
Circle -7500403 true true 264 -21 42
Circle -7500403 true true 264 264 42
Circle -7500403 true true -6 -6 42
Circle -7500403 true true 204 219 42

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
