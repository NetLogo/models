globals [
  ;; By always keeping track of how much sand is on the table, we can compute the
  ;; average number of grains per patch instantly, without having to count.
  total
  ;; Keep track of avalanche sizes so we can histogram them
  sizes
]

;; n is how many grains of sand are on this patch
patches-own [ n ]

;; The input task says what each patch should do at setup time
;; to compute its initial value for n.  (See the Tasks section
;; of the Programming Guide for information on tasks.)
to setup [ setup-task ]
  clear-all
  ask patches [
    ;; n is set to the result of running the initial-task
    ;; (which is an input to the set procedure)
    set n runresult setup-task
    recolor
  ]
  set total sum [ n ] of patches
  ;; set this to the empty list so we can add items to it later
  set sizes []
  reset-ticks
end

;; For example, "setup-uniform 2" gives every patch a task which reports 2.
to setup-uniform [initial-value]
  setup [ -> initial-value ]
end

;; Every patch uses a task which reports a random value.
to setup-random
  ;; this creates a nameless procedure that, when executed, run "random 4"
  setup [ -> random 4 ]
end

;; patch procedure; the colors are like a stoplight
to recolor
  ifelse n <= 3
    [ set pcolor item n [black green yellow red] ]
    [ set pcolor white ]
end

to go
  ;; drop-patch reports a single patch.  initially, the set of active
  ;; patches contains just that one patch.
  let active-patches patch-set drop-patch
  ;; update-n adds or subtracts sand. here, we add 1.
  ask active-patches [ update-n 1 ]
  ;; we want to count how many patches became overloaded at some point
  ;; during the avalanche, and also flash those patches. so as we go, we'll
  ;; keep adding more patches to to this initially empty set.
  let avalanche-patches no-patches
  while [any? active-patches] [
    let overloaded-patches active-patches with [n > 3]
    ask overloaded-patches [
      ;; subtract 4 from this patch
      update-n -4
      ;; edge patches have less than four neighbors, so some sand may fall off the edge
      ask neighbors4 [ update-n 1 ]
    ]
    if animate-avalanches? [ display ]
    ;; add the current round of overloaded patches to our record of the avalanche
    ;; the patch-set primitive combines agentsets, removing duplicates
    set avalanche-patches (patch-set avalanche-patches overloaded-patches)
    ;; find the set of patches which *might* be overloaded, so we will check
    ;; them the next time through the loop
    set active-patches patch-set [neighbors4] of overloaded-patches
  ]
  ;; compute the size of the avalanche and throw it on the end of the sizes list
  if any? avalanche-patches [
    set sizes lput (count avalanche-patches) sizes
  ]
  if animate-avalanches? [
    ask avalanche-patches [ set pcolor white ]
    ;; repeated to increase the chances the white flash is visible even when fast-forwarding
    ;; (which means some view updates are being skipped)
    display display display
    ask avalanche-patches [ recolor ]
  ]
  tick
end

;; patch procedure. input might be positive or negative, to add or subtract sand
to update-n [how-much]
  set n n + how-much
  set total total + how-much
  recolor
end

to-report drop-patch
  ifelse drop-location = "center"
    [ report patch 0 0 ]
    [ report one-of patches ]
end


; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
345
10
757
423
-1
-1
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
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "if ticks mod 100 = 0 and not empty? sizes [\n  plot-pen-reset\n  let counts n-values (1 + max sizes) [0]\n  foreach sizes [ i ->\n    set counts replace-item i counts (1 + item i counts)\n  ]\n  let avalanche-size 0\n  foreach counts [ num-avalanches ->\n    if (avalanche-size > 0 and num-avalanches > 0) [\n      plotxy (log avalanche-size 10) (log num-avalanches 10)\n    ]\n    set avalanche-size avalanche-size + 1\n  ]\n]"

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
## ACKNOWLEDGMENT

This model is from Chapter Eight of the book "Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo", by Uri Wilensky & William Rand.

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

This model is in the IABM Textbook folder of the NetLogo Models Library. The model, as well as any updates to the model, can also be found on the textbook website: http://www.intro-to-abm.com/.

## WHAT IS IT?

The Bak–Tang–Wiesenfeld sandpile model demonstrates the concept of "self-organized criticality". It further demonstrates that complexity can emerge from simple rules and that a system can arrive at a critical state spontaneously rather than through the fine tuning of precise parameters. This is a simplified version of the original Sandpile model.

## HOW IT WORKS

Imagine a table with sand on it. The surface of the table is a grid of squares. Each square can comfortably hold up to three grains of sand.

Now drop grains of sand on the table, one at a time. When a square reaches the overload threshold of four or more grains, all of the grains (not just the extras) are redistributed to the four neighboring squares.  The neighbors may in turn become overloaded, triggering an "avalanche" of further redistributions.

Sand grains can fall off the edge of the table, helping ensure the avalanche eventually ends.

Real sand grains, of course, don't behave quite like this. You might prefer to imagine that each square is a bureaucrat's desk, with folders of work piling up. When a bureaucrat's desk fills up, she clears her desk by passing the folders to her neighbors.

## HOW TO USE IT

Press one of the SETUP buttons to clear and refill the table. You can start with random sand, or two grains per square, or an empty table.

The color scheme in the view is as follows: 0 grains = black, 1 grain = green, 2 grains = yellow, 3 grains = red.  If the DISPLAY-AVALANCHES? switch is on, overloaded patches are white.

Press GO to start dropping sand.  You can choose where to drop with DROP-LOCATION.

When DISPLAY-AVALANCHES? is on, you can watch each avalanche happening, and then when the avalanche is done, the areas touched by the avalanche flash white.

Push the speed slider to the right to get results faster.

## THINGS TO NOTICE

The white flashes help you distinguish successive avalanches. They also give you an idea of how big each avalanche was.

Most avalanches are small. Occasionally a much larger one happens. How is it possible that adding one grain of sand at a time can cause so many squares to be affected?

Can you predict when a big avalanche is about to happen? What do you look for?

Leaving DISPLAY-AVALANCHES? on lets you watch the pattern each avalanche makes. How would you describe the patterns you see?

Observe the AVERAGE GRAIN COUNT plot. What happens to the average height of sand over time?

Observe the AVALANCHE SIZES plot. This histogram is on a log-log scale, which means both axes are logarithmic. What is the shape of the plot for a long run? You can use the CLEAR SIZE DATA button to throw away size data collected before the system reaches equilibrium.

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
 * Sandpile
 * Sandpile 3D (in NetLogo 3D)

## CREDITS AND REFERENCES

This model is a simplified version of:

* Weintrop, D., Tisue, S., Tinker, R., Head, B. and Wilensky, U. (2011).  NetLogo Sandpile model.  http://ccl.northwestern.edu/netlogo/models/Sandpile.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

https://en.wikipedia.org/wiki/Abelian_sandpile_model

https://en.wikipedia.org/wiki/Self-organized_criticality

Bak, P. 1996. How nature works: the science of self-organized criticality. Copernicus, (Springer).

Bak, P., Tang, C., & Wiesenfeld, K. 1987. Self-organized criticality: An explanation of the 1/f noise. Physical Review Letters, 59(4), 381.

The bureaucrats-and-folders metaphor is due to Peter Grassberger.

## HOW TO CITE

This model is part of the textbook, “Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo.”

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Weintrop, D., Tisue, S., Tinker, R. Head, B. & Wilensky, U. (2011).  NetLogo Sandpile Simple model.  http://ccl.northwestern.edu/netlogo/models/SandpileSimple.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the textbook as:

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Weintrop, D., Tisue, S., Tinker, R. Head, B. & Wilensky, U. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
setup-random repeat 50 [ go ]
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
