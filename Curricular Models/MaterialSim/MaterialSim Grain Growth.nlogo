;; two different materials or phases
breed [ element1s element1 ]  ;; element1 is the main material
breed [ element2s element2 ]  ;; element2 is the materials which is
                              ;; dispersed inside element1 (second-phase particles)

element1s-own [
  neighbors-6   ;; agentset of 6 neighboring cells
]

turtles-own [
  neighboring-turtles  ;; agentset of surrounding atoms
  sides-exposed        ;; number of sides exposed to walls  (between 0 and 4)
]

globals [
  logtime                          ;; log of time
  colors                           ;; used both to color turtles, and for histogram
  xmax                             ;; max x size
  ymax                             ;; max y size
  average-grain-size               ;; average grain size
  logaverage-grain-size            ;; log of average grain size (for plotting)
  initial-loggrain-size            ;; For grain growth exponent calculation and graphing
  initial-logtime                  ;; For grain growth exponent calculation and graphing
  grain-growth-exponent            ;; Grain growth exponent
  update-plots?                    ;; boolean for updating plots immediately
]

;; setup checks whether user has chosen "import image" or random in the chooser-widget
to setup
  if starting-point = "Random Arrangement" [
    makes-initial-box-random
  ]
  if starting-point = "Import Image" [
    import-image
  ]
  reset-ticks
end

to setup-hex-grid
  ;; setup the hexagonal grid in which atoms will be placed
  ;; and creates turtles
  set-default-shape element2s "square 2"

  ask patches [
    sprout 1 [
      ;; if there is a second element, create the corresponding atoms
      ifelse (percent-element2 > random 100) [
        ;; element2 is the fixed second-phase particle
        set breed element2s
        set color white
        set heading 360
      ]
      [
        ;; element1 is the main material which grows grains
        set breed element1s
        set shape atom-shape
        set color random 139
        ;; to ensure that the colors are distinct, we only let
        ;; colors deviate from base color by plus or minus 3
        set color one-of base-colors - 3 + random 6
        set heading color
      ]
      ;; shift even columns down
      if pxcor mod 2 = 0  [ set ycor ycor - 0.5 ]
    ]
  ]

  ; the two lines below are for NetLogo 3D. Uncomment them, if you are using NetLogo 3D.
  ; ask element1s [ set shape3d "sphere" ]
  ; ask element2s [ set shape3d "cube" ]

  ;; now set up the neighbors6 agentsets
  ask element1s [
    ;; define neighborhood of atoms
    ifelse pxcor mod 2 = 0
      [ set neighbors-6 element1s-on patches at-points [[0 1] [1 0] [1 -1] [0 -1] [-1 -1] [-1 0]] ]
      [ set neighbors-6 element1s-on patches at-points [[0 1] [1 1] [1  0] [0 -1] [-1  0] [-1 1]] ]
  ]
end

;; makes initial box for image import
to makes-initial-box
  setup-hex-grid
end

;; makes initial box for random arrangement
to makes-initial-box-random
  clear-all
  setup-hex-grid
end

;; import image into turtles
to import-image
  clear-all
  let file user-file
  if file = false [ stop ]
  ;; imports image into patches
  import-pcolors file
  ;; converts the square grid to an hex grid
  makes-initial-box

  ;; transfers the image to the turtles. Rounds the color values to be integers.
  ask turtles [
    set color round pcolor
    set heading color
  ]

  ;; erases the patches (sets their color back to black),
  ask patches [ set pcolor black ]
  reset-ticks
end


to define-neighboring-turtles
  ;; defines neighboring turtles. Some are "off" because atoms are in hexagons
  ask turtles [
    set neighboring-turtles (turtles at-points [
      [-1  1] [ 0  1] [1  1]
      [-1  0] [ 0  0] [1  0]
      [-1 -1] [ 0 -1] [1 -1]
    ])
  ]
end


to go
  ;;initiates grain growth
  let total-atoms count turtles

  ;; stops when there is just one grain
  if average-grain-size >= total-atoms [ stop ]

  ;;limits grain growth to element1, element2 represent the stationary second-phase particles
  ask element1s [grain-growth]

;  ;; calculates grain variables at a given frequency to save CPU processing
;  ;; we + 1 to ticks to put it in sync with plots (that are updated in 'tick')
;  if remainder (ticks + 1) ticks-per-measurement = 0 [
;    count-grains-and-measure-grain-size
;  ]

  ;; advance Monte Carlo Steps (simulation time)
  ;; one Monte Carlo Step represents 'n' reorientation attemps,
  ;; where 'n' is the total number of atoms
  tick
end

to count-grains-and-measure-grain-size
  ;; we only do this for ticks > 0 since we can't take log of 0
  if ticks > 0 [
    set logtime log ticks 10
  ]
  grain-count
  if average-grain-size != 0 [
    set logaverage-grain-size (log (average-grain-size) 10)
  ]
  ;; we set the initial log time and grain size at 20 (we don't start
  ;; calculating grain size until then to give the system a bit of time to stabilize
  if ticks = 20 [
    set initial-logtime logtime
    set initial-loggrain-size logaverage-grain-size
  ]
  ;; only initiates grain size calculation after 20 ticks
  if ticks > 20 [
    ;; calculate the angular coefficient of the grain growth curve
    ;; since it is a log-log plot, it's the grain growth exponent
    set grain-growth-exponent (-1 * ((logaverage-grain-size - initial-loggrain-size) /
      (initial-logtime - logtime)))
  ]
end


to grain-count
  ;; count number of grains based on the number of linear intercepts

  let orientation-for-intercept-count 90 ;; direction of intercepts count
  let intercepts 0
  let total-atoms count turtles

  ;; asking only elements1 with xcor less than 24
  ;; those at 24 are on the 'edge of the world' which means
  ;; that they will never have neighbors to their right.
  ;; we therefore simply ignore them for this purpose.
  ask element1s with [ xcor < 24 ] [
    ;; checks if there is a turtle to the right for the intercept calculation
    let target-patch patch-at-heading-and-distance orientation-for-intercept-count 1
    ifelse target-patch != nobody and any? turtles-on target-patch [
      ;; If there is a turtle, checks if the heading is different.
      let right-neighbor one-of turtles-on target-patch
      if heading != [ heading ] of right-neighbor [
        ;; If heading is different, add 1 to 'intercepts'.
        set intercepts (intercepts + 1)
      ]
    ]
    [
      ;; if there is no turtle, simply add 1 to 'intercepts'.
      ;; A turtle/nothing interface is considered as grain boundary.
      set intercepts (intercepts + 1)
    ]
  ]
  ;; we add one to intercepts so that zero intercepts = one grain, one intercept = 2 grains, etc.
  set average-grain-size total-atoms / (intercepts + 1)
end


;; Grain growth procedure - free energy minimization
;; if another random crystallographic heading minimizes energy, switches headings, otherwise keeps the same.
to grain-growth
  ;; if atom has no neighbors, it is surrounded by element2s, and will not change its orientation
  if not any? neighbors-6 [ stop ]

  ;; calculates the PRESENT free energy
  let present-heading (heading)
  let present-free-energy count neighbors-6 with [ heading != present-heading ]

  ;; chooses a random orientation
  let future-heading ([heading] of (one-of neighbors-6))

  ;; calculates the FUTURE free energy, with the random orientation just chosen
  let future-free-energy count neighbors-6 with [ heading != future-heading ]

  ;; compares PRESENT and FUTURE free-energies; the lower value "wins"
  ifelse future-free-energy <= present-free-energy
    [ set heading future-heading ]
    [ if (annealing-temperature > random-float 100) [ set heading (future-heading) ] ]
  ;; this last line simulates thermal agitation (adds more randomness to the simulation)

  ;;update the color of the atoms
  set color heading
end

;; drawing procedure
to turtle-draw
  if mouse-down? [    ;; reports true or false to indicate whether mouse button is down
    ask patch mouse-xcor mouse-ycor [
      ask element1s in-radius brush-size [
        set color read-from-string draw-color
        set heading color
      ]
    ]
    display
  ]
end

;; in the drawing mode, erases the whole "canvas" with red
to erase-all
  ask element1s [
    set color red
    set heading color
  ]
end


; Copyright 2005 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
735
30
1135
431
-1
-1
8.0
1
10
1
1
1
0
0
0
1
-24
24
-24
24
1
1
1
ticks
60.0

TEXTBOX
35
10
320
80
Model starting point (you can start from a\nrandom arrangement or a picture from a\nmicroscope. You can also determine if you\nwant a certain percentage of a second\nelement, sometimes called grain refiner)
11
0.0
0

SLIDER
340
440
602
473
annealing-temperature
annealing-temperature
0.0
100.0
0.0
1.0
1
%
HORIZONTAL

BUTTON
550
325
705
359
measure grains now
count-grains-and-measure-grain-size\nset update-plots? true
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
605
50
705
95
Grain Size
average-grain-size
3
1
11

BUTTON
30
510
152
550
go
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
30
135
215
168
percent-element2
percent-element2
0
99
0.0
1
1
%
HORIZONTAL

MONITOR
605
145
705
190
Log Grain Size
logaverage-grain-size
2
1
11

MONITOR
605
98
705
143
Log time
logtime
2
1
11

MONITOR
605
250
723
295
Growth exponent
grain-growth-exponent
2
1
11

TEXTBOX
30
491
169
509
Run model
11
0.0
0

TEXTBOX
340
410
640
435
Annealing Temperature
18
14.0
1

CHOOSER
30
245
155
290
atom-shape
atom-shape
"hex" "hexline" "thin-line" "line" "spikes90" "default"
0

BUTTON
160
245
299
290
apply shape
ask element1s [set shape atom-shape]
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
30
370
152
403
draw
turtle-draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
30
409
153
454
erase all
erase-all
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
156
370
295
403
brush-size
brush-size
1.0
6.0
3.0
1.0
1
NIL
HORIZONTAL

TEXTBOX
30
320
315
361
Draw/edit grains (this is optional, you can use\nthis to \"draw\" new grain structures, or edit\nthe grains at any point during the simulation)
11
0.0
0

CHOOSER
156
409
295
454
draw-color
draw-color
"yellow" "green" "cyan" "blue" "red"
0

TEXTBOX
346
307
478
325
Grain measurement
11
0.0
0

TEXTBOX
345
10
700
35
Grain size plot and calculations
18
14.0
0

TEXTBOX
34
200
324
245
Change the shape of atoms (different shapes\nmight help visualize the atomic planes, or the\nproportion of different types of grains)
11
0.0
0

BUTTON
157
510
292
550
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

CHOOSER
30
85
215
130
starting-point
starting-point
"Random Arrangement" "Import Image"
0

BUTTON
218
85
298
168
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

TEXTBOX
345
365
555
406
This slider determines how often\nthe grain size is measured
11
0.0
1

TEXTBOX
344
478
749
553
A high annealing temperature makes some atoms randomly jump\nto the next grain. When it is zero, only the energetically favorable\njumps will happen. Temperature here is represented as a relative\nvalue -- a percentage of random jumps out of the possible jumps.\n100% means that all the jumps are random.
11
0.0
1

TEXTBOX
30
175
320
193
_____________________________________________
11
0.0
1

TEXTBOX
30
295
325
321
_____________________________________________
11
0.0
1

TEXTBOX
30
465
325
483
_____________________________________________
11
0.0
1

TEXTBOX
5
75
30
111
1
30
14.0
1

TEXTBOX
3
225
23
261
2
30
14.0
1

TEXTBOX
3
375
28
411
3
30
14.0
1

TEXTBOX
3
500
28
536
4
30
14.0
1

SLIDER
345
325
542
358
ticks-per-measurement
ticks-per-measurement
1
200
50.0
1
1
NIL
HORIZONTAL

PLOT
345
50
595
295
Grain Size (log-log)
Log time
Log grain size
0.0
1.0
0.0
1.0
true
false
"" ";; only update this as often as we have specified below\n;; we have to subtract one because the tick command is always\n;; \"one step ahead\" of the rest of the go-procedure\nif remainder ticks ticks-per-measurement != 0 and not update-plots? [ stop ]\ncount-grains-and-measure-grain-size\nset update-plots? false"
PENS
"default" 1.0 0 -16777216 true "" "plotxy logtime logaverage-grain-size"

@#$#@#$#@
## WHAT IS IT?

Most materials are not continuous arrangements of atoms. Rather, they are composed of thousands or millions of microscopic crystals, known as grains.  This model shows how the configuration and sizes of these grains change over time.  Grain size is a very important characteristic for evaluating the mechanical properties of materials; it is exhaustively studied in metallurgy and materials science.

Usually this kind of study is made by careful analysis and comparison of pictures taken in microscopes, sometimes with the help of image analysis software.  Recently, as the processing power of computers has increased, a new and promising approach has been made possible: computer simulation of grain growth.

Anderson, Srolovitz et al. proposed the most widely known and employed theory for computer modeling and simulation of grain growth, using the Monte Carlo method. Instead of considering the grains as spheres, and being obliged to make numerous geometrical approximations, Anderson proposed that the computer would simulate the behavior of each individual atom in the system. Each atom would follow a very simple rule: it will always try to have, in its immediate neighborhood, as many atoms as possible with the same orientation as it. It will do so by randomly (hence Monte Carlo) re-orienting itself and seeing if it is more stable than it was before. If it is, it will stay in its new orientation, and if not, it will revert back to its previous orientation.

This model is part of the MaterialSim (Blikstein & Wilensky, 2004) curricular package. To learn more about MaterialSim, see http://ccl.northwestern.edu/rp/materialsim/index.shtml.

## HOW IT WORKS

The basic algorithm of the simulation is simple: each atom continuously tries to be as stable as possible.  Its stability is based on the number of neighbors with similar orientations: the more similar neighbors, the more stable it is. If it has only few similar neighbors, it will try to relocate to a more stable position.  The steps for each tick in the model are:

1. Choose a random atom.
2. Ask that atom to calculate its present energy (based on its stability).  The atom does this by counting how many similar neighbors it has.
3. The atom then chooses at random one of its neighbors, and orients itself in the same direction as that neighbor.
4. The same atom then calculates its energy, based on this new, tentative orientation.
5. Finally the atom compares the energy levels in each of the two states: the lowest value "wins", i.e., the more similar neighbors, the more stable the atom is.
6. Repeat steps 1-6.

The **annealing-temperature** slider controls the probability of maintaining a reorientation that yields less stability.  The **percent-element2** slider defines the percentage of second-phase particles to be created when the user setups the simulation.  Those particles are not movable and are not subject to grain growth. Atoms with element2-particles as neighbors will see them as dissimilar.

Note that the actual number of atoms is small compared to a real metal sample.  Also, real materials are three-dimensional, while this model is 2D.

## HOW TO USE IT

### (1) Simulation starting point.
**starting-point**: You can start from a random arrangement or a picture from a microscope.  File formats accepted are: `.jpg`, `.png`, `.bmp`, and `.gif`. The image will be automatically resized to fit into the world, but maintaining its original aspect ratio. Note that the image MUST HAVE THE SAME ASPECT RATIO AS THE WORLD. In other words, if the world is square, the image should be square as well. Prior to importing the image, it is recommended to clean it up using an image editing software (increase contrast, remove noise).  Try to experiment various combinations of values for the view's size and the patch size to get the best results

**percent-element2**: You can also determine if you want a certain percentage of a second element, sometimes called grain refiner.

**setup**: Sets up the model as indicated.

### (2) Change the shape of atoms.

Different shapes might help visualize the atomic planes, or the proportion of different types of grains.

**atom-shape**: Choose which shape you want.

**apply-shape**: Re-draws all the atoms with the shape you chose.

### (3) Draw/edit grains (optional)

You can use this to "draw" new grain structures, or edit the grains at any point during the simulation.

**draw**: When this button is pressed down, you can change the color (orientation) of atoms in the model.

**brush-size**: This determines how many atoms’ orientation you change at a time.

**erase-all**:  This changes the orientation of all atoms.

**draw-color**: Here you can change the color (and orientation) that that you change atoms to, when you draw on them.

### (4) Run Model.

You can choose to have the model keep repeating the steps (as described above) or to run just one tick. Running just one tick will allow you to see more clearly what happens over time.

**annealing-temperature**: changes the probability of non-favorable orientation flips to happen.  A 10% value, for instance, means that 10% of non-favorable flips will be maintained.  This mimics the effect of higher temperatures.

### Grain size plot and calculations

**ticks-per-measurement **: to increase the model's speed, the user can choose not to calculate grain size at every time step.  If grain size is calculated at every ten time units (20, 30, 40 etc.), the performance is slightly increased.  This only affects the plot and the monitors, but not the actual simulation.

**measure grains now**: if the user feels there is too much time between each grain measurement, and wants to calculate it immediately, this button can be used.

### Plots and monitors

**Grain Size (log-log)**: Grain size vs. time, in a log-log scale.  Under normal conditions (**annealing-temperature** = 0 and **percent-element2** = 0), this plot should be a straight line with an angular coefficient of approximately 0.5.

**Grain Size**: grain size

**Log Time**: log of ticks in the simulation so far

**Log Grain Size**: Log of the grain size

**growth-exponent**: the angular coefficient of the **Grain Size (log-log)** plot.  This number should approach 0.5 with **annealing-temperature** = 0 and **percent-element2** = 0.

## THINGS TO NOTICE

When you setup with a random orientation and run the simulation, notice that the speed of growth decreases with time.  Toward the end of the simulation, you might see just two or three grains that fight with each other for along time.  One will eventually prevail, but this logarithmic decrease of speed is an important characteristic of grain growth.  That is why the **Grain Size (log-log) plot is a straight line in a "log-log" scale.
Notice also that if you draw two grains, one concave and one convex, their boundary will tend to be a straight line, if you let the simulation run long enough.  Every curved boundary is unstable because many atoms at its interface will have more different than equal neighbors.

## THINGS TO TRY

Increase the value of the **annealing-temperature** slider. What happens to the **Grain Size (log-log)** plot, and to the boundaries' shapes?

Try to increase the **percent-element2** slider to 5%.  Then choose “random arrangement” and click **setup**, and **go**. What happens to grain growth? Now try several values (1, 3, 5, 7, 9%), for instance.  What happens with the final grain size? What about the **Grain Size (log-log) plot and the **Growth Exponent**?

One advanced use of this model would be to get a digital picture of a real metallic sample, reduce noise and increase contrast with image editing programs, and load into this model using the **Import Image** feature in the starting-point chooser.  Don't forget to update the width and height of the view's size to accommodate the picture, and also to change the patch size in order to be able to see the whole sample.

## EXTENDING THE MODEL

This model assumes that the misorientation between two grains has no effect on their growth rates.  Two grains with a very similar crystallographic orientation have the same growth rate as grains whose orientations differ by a lot.  Try to take the angular misorientation into consideration.

When we insert second-phase particles, all of them have the same size.  Try to create a slider that changes the size of these particles.

## NETLOGO FEATURES

Rather than containing all of the code that updates variables used for plotting, the **Grain Size (log-log)** plot calls a procedure that does this. The reason is that there is quite a lot of code, and it would be difficult to work with inside the plot. Notice also that this code updates the global variables shown in the monitors to the right of the plot.

The model uses a hexagonal grid as opposed to the usual, square one. It also uses different shapes for different visualization purposes. Finally, it uses the `import-pcolors` primitive for image import.

## RELATED MODELS

Crystallization Basic
Crystallization Directed
Crystallization Moving

## CREDITS AND REFERENCES

This model is part of the MaterialSim (Blikstein & Wilensky, 2004) curricular package. To learn more about MaterialSim, see http://ccl.northwestern.edu/rp/materialsim/index.shtml.

Two papers describing the use of this model in education are:
Blikstein, P. & Wilensky, U. (2005) Less is More: Agent-Based Simulation as a Powerful Learning Tool in Materials Science.  The IV International Conference on Autonomous Agents and Multiagent Systems. Utrecht, Netherlands.

Blikstein, P. & Wilensky, U. (2004) MaterialSim: An agent-based simulation toolkit for Materials Science learning. (PDF, 1.5 MB) Proceedings of the International Conference on Engineering Education. Gainesville, Florida.

The core algorithm of the model was developed at the University of Sao Paulo and published in:  Blikstein, P. and Tschiptschin, A. P. Monte Carlo simulation of grain growth (II). Materials Research, Sao Carlos, 2 (3), p. 133-138, jul. 1999.

Available for download at: https://www.scielo.br/j/mr/a/78pTMnZ8Kb6Pw6XTTw3SJ8g/?lang=en. See also http://www.pmt.usp.br/paulob/montecarlo/ for more information (in Portuguese).

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Blikstein, P. and Wilensky, U. (2005).  NetLogo MaterialSim Grain Growth model.  http://ccl.northwestern.edu/netlogo/models/MaterialSimGrainGrowth.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2005 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2005 Cite: Blikstein, P. -->
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

circ
true
0
Circle -7500403 true true 10 11 278

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

hex
false
0
Polygon -7500403 true true 0 150 75 30 225 30 300 150 225 270 75 270

hexline
true
0
Polygon -7500403 true true 0 150 75 30 225 30 300 150 225 270 75 270
Rectangle -1 true false 121 47 182 252

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
Rectangle -7500403 true true 135 0 165 315

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

rectangle
true
0
Polygon -7500403 true true 67 36 67 262 235 262 235 35

spikes90
true
0
Circle -7500403 true true 61 62 177
Line -7500403 true 135 66 131 154
Rectangle -7500403 true true 135 -4 166 68
Rectangle -7500403 true true 142 132 219 134
Rectangle -7500403 true true 196 136 304 165
Rectangle -7500403 true true -9 135 68 166
Rectangle -7500403 true true 131 176 132 226
Rectangle -7500403 true true 135 225 165 313

square
false
0
Rectangle -7500403 true true 15 15 286 285
Line -1 false 6 6 293 6
Line -1 false 293 6 293 293
Line -1 false 293 292 8 292
Line -1 false 8 292 8 6

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

t
true
0
Rectangle -7500403 true true 46 47 256 75
Rectangle -7500403 true true 135 76 167 297

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

thin-line
true
0
Line -7500403 true 150 0 150 300

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
