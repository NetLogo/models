;; workarounds:
;; - #7 (box topology) - turn wrapping checkboxes on. use custom neighbors-nowrap procedure
;; - #17 (tasks) - used ordinary procedural abstraction instead
;; - #18 (display) - commented out
;; - no mouse support - mouse code removed wholesale

globals [
  ;; By always keeping track of how much sand is on the table, we can compute the 
  ;; average number of grains per patch instantly, without having to count.
  total
  ;; We don't want the average monitor to updating wildly, so we only have it 
  ;; update every tick.
  total-on-tick
  ;; Keep track of avalanche sizes so we can histogram them
  sizes
  ;; Size of the most recent run
  last-size
  ;; Keep track of avalanche lifetimes so we can histogram them
  lifetimes
  ;; Lifetime of the most recent run
  last-lifetime
  ;; These colors define how the patches look normally, after being fired, and in 
  ;; explore mode.
  default-color
  fired-color
]

patches-own [
  ;; how many grains of sand are on this patch
  n
  ;; A list of stored n so that we can easily pop back to a previous state. See
  ;; the NETLOGO FEATURES section of the Info tab for a description of how stacks
  ;; work
  n-stack
  ;; Determines what color to scale when coloring the patch. 
  base-color
  neighbors4-nowrap
]

to setup [initial random?]
  clear-all
  set default-color blue
  set fired-color red
  
  ask patches [
    set neighbors4-nowrap get-neighbors4-nowrap
    ifelse random?
      [ set n random initial ]
      [ set n initial ]
    set n-stack []
    set base-color default-color
  ]
  let ignore stabilize false
  ask patches [ recolor ]
  set total sum [ n ] of patches
  ;; set this to the empty list so we can add items to it later
  set sizes []
  set lifetimes []
  reset-ticks
end

to setup-uniform [initial]
  setup initial false
end

to setup-random
  setup 4 true
end

;; patch procedure; the colors are like a stoplight
to recolor
  set pcolor scale-color base-color n 0 4
end

to go
  let drop drop-patch
  if drop != nobody [
    ask drop [
      update-n 1
      recolor
    ]
    let results stabilize animate-avalanches?
    let avalanche-patches first results
    let lifetime last results
    
    ;; compute the size of the avalanche and throw it on the end of the sizes list
    if any? avalanche-patches [
      set sizes lput (count avalanche-patches) sizes
      set lifetimes lput lifetime lifetimes
    ]
    ;; Display the avalanche and guarantee that the border of the avalanche is updated
    ask avalanche-patches [ recolor ask neighbors4-nowrap [ recolor ] ]
    ;; TODO display
    ;; Erase the avalanche
    ask avalanche-patches [ set base-color default-color recolor ]
    ;; Updates the average monitor
    set total-on-tick total
    tick
  ]
end

;; Stabilizes the sandpile. Reports which sites fired and how many iterations it took to
;; stabilize.
to-report stabilize [animate?]
  let active-patches patches with [ n > 3 ]
  
  ;; The number iterations the avalanche has gone for. Use to calculate lifetimes.
  let iters 0

  ;; we want to count how many patches became overloaded at some point
  ;; during the avalanche, and also flash those patches. so as we go, we'll
  ;; keep adding more patches to to this initially empty set.
  let avalanche-patches no-patches
  
  while [ any? active-patches ] [
    let overloaded-patches active-patches with [ n > 3 ]
    if any? overloaded-patches [
      set iters iters + 1
    ]
    ask overloaded-patches [
      set base-color fired-color
      ;; subtract 4 from this patch
      update-n -4
      if animate? [ recolor ]
      ;; edge patches have less than four neighbors, so some sand may fall off the edge
      ask neighbors4-nowrap [
        update-n 1
        if animate? [ recolor ]
      ]
    ]
    if animate? [ ] ;; TODO display ]
    ;; add the current round of overloaded patches to our record of the avalanche
    ;; the patch-set primitive combines agentsets, removing duplicates
    set avalanche-patches (patch-set avalanche-patches overloaded-patches)
    ;; find the set of patches which *might* be overloaded, so we will check
    ;; them the next time through the loop
    set active-patches patch-set [ neighbors4-nowrap ] of overloaded-patches
  ]
  report (list avalanche-patches iters)
end

;; patch procedure. input might be positive or negative, to add or subtract sand
to update-n [ how-much ]
  set n n + how-much
  set total total + how-much
end

to-report drop-patch
  if drop-location = "center" [ report patch 0 0 ]
  if drop-location = "random" [ report one-of patches ]
  report nobody
end

;; Save the patches state
to push-n ;; patch procedure
  set n-stack fput n n-stack
end

;; restore the patches state
to pop-n ;; patch procedure
  ; need to go through update-n to keep total statistic correct
  update-n ((first n-stack) - n)
  set n-stack but-last n-stack
end

;;; compensate for lack of box topology in Tortoise

to-report get-neighbors4-nowrap
  let my-x pxcor
  let my-y pycor
  report neighbors4 with [abs (pxcor - my-x) <= 1 and abs (pycor - my-y) <= 1]
end
@#$#@#$#@
GRAPHICS-WINDOW
330
10
744
445
50
50
4.0
1
10
1
1
1
0
1
1
1
-50
50
-50
50
1
1
1
ticks
90.0

BUTTON
5
45
150
79
setup uniform
setup-uniform grains-per-patch
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
5
100
150
133
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
0
260
310
445
Average grain count
ticks
grains
0.0
1.0
2.0
2.1
true
false
"" ""
PENS
"average" 1.0 0 -16777216 true "" "plot total / count patches"

MONITOR
245
215
310
260
average
total-on-tick / count patches
4
1
11

SWITCH
155
140
325
173
animate-avalanches?
animate-avalanches?
1
1
-1000

CHOOSER
5
140
150
185
drop-location
drop-location
"center" "random"
0

BUTTON
5
10
150
43
setup random
setup-random
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
755
240
955
390
Avalanche sizes
log size
log count
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks mod 100 = 0 and not empty? sizes [\n  plot-pen-reset\n  let counts n-values (1 + max sizes) [0]\n  foreach sizes [\n    set counts replace-item ? counts (1 + item ? counts)\n  ]\n  let s 0\n  foreach counts [\n    let c ?\n    ; We only care about plotting avalanches (s > 0), but dropping s = 0\n    ; from the counts list is actually more awkward than just ignoring it\n    if (s > 0 and c > 0) [\n      plotxy (log s 10) (log c 10)\n    ]\n    set s s + 1\n  ]\n]"

BUTTON
755
400
955
433
clear size and lifetime data
set sizes []\nset lifetimes []\nset-current-plot \"Avalanche lifetimes\"\nset-plot-y-range 0 1\nset-plot-x-range 0 1\nset-current-plot \"Avalanche sizes\"\nset-plot-y-range 0 1\nset-plot-x-range 0 1
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
755
80
955
230
Avalanche lifetimes
log lifetime
log count
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks mod 100 = 0 and not empty? lifetimes [\n  plot-pen-reset\n  let counts n-values (1 + max lifetimes) [0]\n  foreach lifetimes [\n    set counts replace-item ? counts (1 + item ? counts)\n  ]\n  let l 0\n  foreach counts [\n    let c ?\n    ; We only care about plotting avalanches (l > 0), but dropping l = 0\n    ; from the counts list is actually more awkward than just ignoring it\n    if (l > 0 and c > 0) [\n      plotxy (log l 10) (log c 10)\n    ]\n    set l l + 1\n  ]\n]"

BUTTON
155
100
325
133
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

SLIDER
155
45
325
78
grains-per-patch
grains-per-patch
0
3
0
1
1
NIL
HORIZONTAL

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

@#$#@#$#@
NetLogo 5.0.5-RC1
@#$#@#$#@
setup-random repeat 50 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
