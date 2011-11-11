globals [
  ;; By always keeping track of how much sand is on the table, we can compute the 
  ;; average number of grains per patch instantly, without having to count.
  total
  ;; Keep track of avalanche sizes so we can histogram their sizes
  sizes
]

;; n is how many grains of sand are on this patch
patches-own [n]

;; The input task says what each patch should do at setup time.
to setup [setup-task]
  clear-all
  ask patches [
    set n runresult setup-task
    recolor
  ]
  set total sum [n] of patches
  set sizes []
  reset-ticks
end

to setup-uniform [initial]
  setup task [initial]
end

to setup-random
  setup task [random 4]
end

to recolor  ;; patch procedure
  ifelse n <= 3
    [ set pcolor item n [black green yellow red] ]
    [ set pcolor white ]
end

to go
  let active-patches patch-set drop-patch
  ask active-patches [ update-folders 1 ]
  let avalanche-patches no-patches
  while [any? active-patches] [
    let overloaded-patches active-patches with [n > 3]
    ask overloaded-patches [
      update-folders -4
      ask neighbors4 [ update-folders 1 ]
    ]
    if animate-avalanches? [ display ]
    set avalanche-patches (patch-set avalanche-patches overloaded-patches)
    ;; the patch-set primitive combines agentsets, removing duplicates
    set active-patches patch-set [neighbors4] of overloaded-patches
  ]
  if any? avalanche-patches [
    set sizes lput (count avalanche-patches) sizes
  ]
  if animate-avalanches? [
    ask avalanche-patches [ set pcolor white ]
    ;; repeated to increase the chances the white flash is visible even when fast-forwarding
    display display display
    ask avalanche-patches [ recolor ]
  ]
  tick
end

;; patch procedure. input might be positive or negative, to add or subtract folders
to update-folders [how-much]
  set n n + how-much
  set total total + how-much
  recolor
end

to-report drop-patch
  ifelse drop-location = "center"
    [ report patch 0 0 ]
    [ report one-of patches ]
end
@#$#@#$#@
GRAPHICS-WINDOW
345
10
759
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
0
0
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
20
90
155
123
NIL
setup-uniform 0
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
200
55
278
88
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
15
260
325
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
375
310
420
average
total / count patches
4
1
11

SWITCH
65
200
247
233
animate-avalanches?
animate-avalanches?
0
1
-1000

BUTTON
20
55
155
88
NIL
setup-uniform 2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
90
150
228
195
drop-location
drop-location
"center" "random"
1

BUTTON
20
20
155
53
NIL
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
770
250
970
400
Avalanche sizes
log count
log size
0.0
18.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "if ticks mod 100 = 0 and not empty? sizes [\n  plot-pen-reset\n  foreach n-values (log (max sizes) 2) [?] [\n    let exponent ?\n    plot length filter [? >= 2 ^ exponent and ? < 2 ^ (exponent + 1)] sizes\n  ]\n]\n"

BUTTON
820
410
937
443
clear size data
set sizes []\nset-plot-y-range 0 1
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

The Bak–Tang–Wiesenfeld sandpile model demonstrates the concept of "self-organized criticality". It further demonstrates that complexity can emerge from simple rules and that a system can arrive at a critical state spontaneously rather than through the fine tuning of precise parameters.

## HOW IT WORKS

Imagine a table with sand on it. The surface of the table is a grid of squares. Each square can comfortably hold up to three grains of sand.

Now drop grains of sand on the table, one at a time. When a square reaches the overload threshold of four or more grains, all of the grains (not just the extras) are redistributed to the four neighboring squares.  The neighbors may in turn become overloaded, triggering an "avalanche" of further redistributions.

Sand grains can fall off the edge of the table, helping ensure the avalanche eventually ends.

Real sand grains, of course, don't behave quite like this. You might prefer to imagine that each square is a bureaucrat's desk, with folders of work piling up. When a bureaucrat's desk fills up, she clears her desk by passing the folders to her neighbors.

## HOW TO USE IT

Press one of the **setup** buttons to clear and refill the table. You can start with random sand, or two grains per square, or an empty table.

The color scheme in the view is as follows: 0 grains = black, 1 grain = green, 2 grains = yellow, 3 grains = red.  If the **display-avalanches?** switch is on, overloaded patches are white.

Press **go** to start dropping sand.  You can choose where to drop with **drop-location**.

When **display-avalanches?** is on, you can watch each avalanche happening, and then when the avalanche is done, the areas touched by the avalanche flash white.

Push the speed slider to the right to get results faster.

## THINGS TO NOTICE

The white flashes help you distinguish successive avalanches. They also give you an idea of how big each avalanche was.

Most avalanches are small. Occasionally a much larger one happens. How is it possible that adding one grain of sand at a time can cause so many squares to be affected?

Can you predict when a big avalanche is about to happen? What do you look for?

Leaving **display-avalanches?** on lets you watch the pattern each avalanche makes. How would you describe the patterns you see?

Observe the **Average grain count** plot. What happens to the average height of sand over time?

Observe the **Avalanche sizes** plot. This histogram is on a log-log scale, which means both axes are logarithmic. What is the shape of the plot for a long run? You can use the **clear size data** button to throw away size data collected before the system reaches equilibrium.

## THINGS TO TRY

Try all the different combinations of initial setups and drop locations. How does what you see near the beginning of a run differ?  After many ticks have passed, is the behavior still different?

Use an empty initial setup and drop sand grains in the center. This makes the system deterministic. What kind of patterns do you see? Is the sand pile symmetrical and if so, what type of symmetry is it displaying? Why does this happen? Each cell only knows about its neighbors, so how do opposite ends of the pile produce the same pattern if they can't see each other?  What shape is the pile, and why is this? If each cell only adds sand to the cell above, below, left and right of it, shouldn't the resulting pile be cross-shaped too?

## EXTENDING THE MODEL

Add code that lets you use the mouse to choose where to drop the next grain yourself. Can you find places where adding one grain will result in an avalanche? If you have a symmetrical pile, then add a few strategic random grains of sand, then continue adding sand to the center of the pile --- what happens to the pattern?

Try a larger threshold than 4.

Try including diagonal neighbors in the redistribution, too.

Try redistributing sand to neighbors randomly, rather than always one per neighbor.

This model exhibits characteristics commonly observed in complex natural systems, such as self-organized criticality, fractal geometry, 1/f noise, and power laws.  These concepts are explained in more detail in Per Bak's book (see reference below). Add code to the model to measure these characteristics.

## NETLOGO FEATURES

In the world settings, wrapping at the world edges is turned off.  Therefore the `neighbors4` primitive sometimes returns only two or three patches.

In order for the model to run fast, we need to avoid doing any operations that require iterating over all the patches. Avoiding that means keeping track of the set of patches currently involved in an avalanche. The key line of code is:

    set active-patches patch-set [neighbors4] of overloaded-patches

The same `setup` procedure is used to create a uniform initial setup or a random one. The difference is what task we pass it for each pass to run. See the Tasks section of the Programming Guide in the User Manual for more information on Tasks.

## RELATED MODELS

 * Sand
 * Sandpile 3D (in NetLogo 3D)

## CREDITS AND REFERENCES

http://en.wikipedia.org/wiki/Bak–Tang–Wiesenfeld_sandpile

http://en.wikipedia.org/wiki/Self-organized_criticality

Bak, P. 1996. How nature works: the science of self-organized criticality. Copernicus, (Springer). 

Bak, P., Tang, C., & Wiesenfeld, K. 1987. Self-organized criticality: An explanation of the 1/f noise. Physical Review Letters, 59(4), 381.

The bureaucrats-and-folders metaphor is due to Peter Grassberger.

Thanks to David Weintrop, Seth Tisue, and Robert Tinker for their work on this model.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

@#$#@#$#@
NetLogo 5.0RC4
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
1
@#$#@#$#@
