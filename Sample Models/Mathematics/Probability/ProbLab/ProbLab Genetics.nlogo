breed [ output-shapes output-shape ]
breed [ fish a-fish ]

fish-own [
  age
  my-genes
]

patches-own [
  original-color
  family
]

globals [ z-distr ]

to setup
  clear-all
  ; prepares the patch colors
  ask patches [ set pcolor red + random 3 ]
  ; the origin is moved toward the top of the view so
  ; the single row of patches with positive pycors
  ; can easily be used to display genetic information
  ; when a fish is selected in "reveal genes" mode
  ask patches with [ pycor > 0 ] [ set pcolor white ]
  ask patches [
    set original-color pcolor
    set family []
  ]
  reset-ticks
end

to add-fish [ n ]
  repeat n [
    let dummy add-custom-fish choose-random-n-z
  ]
  update-plots
end

; add a fish with the given genes and report a reference to it
to-report add-custom-fish [ child-genes ]
  let child nobody
  create-fish 1 [
    set my-genes child-genes
    express-genes
    setxy random-xcor (random-float min-pycor)
    set-next-heading
    set child self
  ]
  report child
end

to express-genes ; fish procedure
  ifelse item 3 my-genes = "1" or item 4 my-genes = "1"
    [ set color dom-color ]
    [ set color res-color ]
  ifelse item 5 my-genes = "1" or item 6 my-genes = "1"
    [ set shape dom-shape ]
    [ set shape res-shape ]
end

to-report choose-random-n-z
  report combination-to-string n-values 4 [ random 2 ]
end

to-report combination-to-string [ combination ]
  report reduce word (sentence "f" (sum combination) "-" combination)
end

to go

  ask patches [
    set pcolor original-color
    set family []
  ]

  ask fish [
    if age >= life-span [ die ]
    set age age + 1
    wander-around
  ]

  ; collides pairs of fish that are on the same patch
  foreach [ n-of 2 fish-here ] of patches with [ count fish-here > 1 ] [ parents ->
    ; make sure the first parent has a lower
    ; who number than the second parent
    collide (first sort parents) (last sort parents)
  ]
  tick
end

to collide [ parent1 parent2 ]
  if can-mate? parent1 parent2 [
    ; makes a child
    let genes1 [ my-genes ] of parent1
    let genes2 [ my-genes ] of parent2
    let child-genes create-child ([ patch-here ] of parent1) genes1 genes2
    let child add-custom-fish child-genes
    ask [ patch-here ] of parent1 [
      set pcolor yellow
      set family (sentence parent1 parent2 child family)
    ]
  ]
end

to-report can-mate? [ parent1 parent2 ]
  let same-body? ([ color ] of parent1 = [ color ] of parent2)
  let same-fin?  ([ shape ] of parent1 = [ shape ] of parent2)
  if mate-with = "Any Fish"  [ report true ]
  if mate-with = "Same Body" [ report same-body? ]
  if mate-with = "Same Fin"  [ report same-fin? ]
  if mate-with = "Same Both" [ report same-body? and same-fin? ]
  report false
end

to-report create-child [ yellow-patch genes1 genes2 ]
  ; makes the child
  let new-genes n-values 4 [ random 2 ]
  ask yellow-patch [ set family new-genes ]
  report combination-to-string (map
    [ [i new-gene parent-genes] -> read-from-string item (i + new-gene) parent-genes ]
    [ 3 3 5 5 ] new-genes (list genes1 genes2 genes1 genes2))
end

to reveal-genes
  ifelse mouse-down? [
    let x mouse-xcor
    let y mouse-ycor
    ifelse [ pcolor ] of patch x y = yellow [
      ; reveals genes -- with two fish mating, if patch is yellow
      if not any? output-shapes [
        output-genetics [ family ] of patch x y
        let fish-family turtle-set filter is-turtle? [ family ] of patch x y
        ask fish-family [ express-genes ]
        ask fish [ set hidden? (not member? self fish-family) ]
        ask patches [ set pcolor original-color ]
        ask patch x y [ set pcolor yellow ]
      ]
    ]
    [
      ; finds closest turtle if patch not yellow
      reset-display
      ask min-one-of [ fish in-radius 2 ] of patch x y [ distancexy x y ] [
        set shape my-genes
      ]
    ]
  ]
  [ reset-display ]
  display
end

to reset-display
  ask output-shapes [ die ]
  ask patches with [ not empty? family ] [ set pcolor yellow ]
  ask fish [
    express-genes
    show-turtle
  ]
end

to output-genetics [ this-family ]

  ask output-shapes [ die ]

  let genes1      [ my-genes ] of item 0 this-family
  let genes2      [ my-genes ] of item 1 this-family
  let child-genes [ my-genes ] of item 2 this-family
  let top-left                    item 3 this-family
  let top-right                   item 4 this-family
  let bottom-left                 item 5 this-family
  let bottom-right                item 6 this-family

(foreach (list genes1 "small plus" genes2 "right arrow" child-genes) [ 0 0.75 1.5 2.5 3.5 ] [ [the-shape offset] ->
    create-output-shapes 1 [
      set shape the-shape
      setxy (min-pxcor + offset) max-pycor
    ]
  ])

  let left-xs  (list (- 5.25) (- 4.75))
  let right-xs (list (- 3.75) (- 3.25))
  make-frame (item top-left     left-xs ) 1.25 orange
  make-frame (item top-right    right-xs) 1.25 orange
  make-frame (item bottom-left  left-xs ) 0.75 turquoise - 1
  make-frame (item bottom-right right-xs) 0.75 turquoise - 1

end

to make-frame [ x y frame-color ]
  create-output-shapes 1 [
    set shape "frame-thicker"
    set size .5
    setxy x y
    set color frame-color
  ]
end

to wander-around ; fish procedure
  forward 1 ; moves one
  set-next-heading
end

to set-next-heading ; fish procedure
  ; choose a random heading, making sure it
  ; doesn't go out of bounds next move
  set heading random 360
  let p patch-ahead 1
  while [ p = nobody or [ pycor ] of p > (max-pycor - 1) ] [
    set heading random 360
    set p patch-ahead 1
  ]
end

to-report dom-color ; dominant gene color
  report green
end

to-report res-color ; recessive gene color
  report blue
end

to-report dom-shape
  report "fish-green-fin"
end

to-report res-shape
  report "fish-blue-fin"
end


; Copyright 2004 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
122
10
570
459
-1
-1
40.0
1
10
1
1
1
0
0
0
1
-5
5
-9
1
1
1
1
ticks
30.0

BUTTON
7
37
116
70
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
7
245
116
278
reveal genes
reveal-genes
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
8
180
116
213
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

BUTTON
7
88
116
121
add fish
add-fish 10
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
580
325
910
480
4-Block Distribution
# green squares in block
occurrences
0.0
5.0
0.0
10.0
true
true
"" "set z-distr [ read-from-string item 1 my-genes ] of fish"
PENS
"Count" 1.0 1 -16777216 true "" "let maxbar modes z-distr\nlet maxrange length (filter [ z -> z = item 0 maxbar ] z-distr )\nset-plot-y-range 0 max list 10 maxrange\nhistogram z-distr"
"Average" 1.0 0 -2674135 true "" "; plots a vertical line at mean\nplot-pen-reset\nif z-distr != [] [\n  plotxy mean z-distr plot-y-min\n  plot-pen-down\n  plotxy mean z-distr plot-y-max\n  plot-pen-up\n]"

SLIDER
5
375
114
408
life-span
life-span
1
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
840
380
905
425
Ave Block
mean z-distr
2
1
11

BUTTON
8
142
116
175
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

PLOT
577
174
907
322
Percent Fish by Properties
# of iterations
Percentage
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"G-body G-fin" 1.0 0 -10899396 true "" "plotxy ticks ifelse-value any? fish [ 100 * count fish with [ color = green and shape = dom-shape ] / count fish ] [ 0 ]"
"G-body B-fin" 1.0 0 -6459832 true "" "plotxy ticks ifelse-value any? fish [ 100 * count fish with [ color = green and shape = res-shape ] / count fish ] [ 0 ]"
"B-body G-fin" 1.0 0 -13312 true "" "plotxy ticks ifelse-value any? fish [ 100 * count fish with [ color = blue and shape = dom-shape ] / count fish ] [ 0 ]"
"B-body B-fin" 1.0 0 -13345367 true "" "plotxy ticks ifelse-value any? fish [ 100 * count fish with [ color = blue and shape = res-shape ] / count fish ] [ 0 ]"

CHOOSER
5
414
114
459
mate-with
mate-with
"Any Fish" "Same Body" "Same Fin" "Same Both"
0

MONITOR
610
10
696
55
G-body G-fin
count fish with [ color = green and (read-from-string (item 5 my-genes) = 1 or read-from-string (item 6 my-genes) = 1)]
0
1
11

MONITOR
700
10
784
55
G-body B-fin
count fish with [ color = green and not (read-from-string (item 5 my-genes) = 1 or read-from-string (item 6 my-genes) = 1)]
3
1
11

MONITOR
610
62
696
107
B-body G-fin
count fish with [ color = blue and (read-from-string (item 5 my-genes) = 1 or read-from-string (item 6 my-genes) = 1)]
0
1
11

MONITOR
700
62
784
107
B-body B-fin
count fish with [ color = blue and not (read-from-string (item 5 my-genes) = 1 or read-from-string (item 6 my-genes) = 1)]
0
1
11

MONITOR
610
120
696
165
Total     G-fin
count fish with [ read-from-string (item 5 my-genes) = 1 or read-from-string (item 6 my-genes) = 1 ]
0
1
11

MONITOR
700
120
785
165
Total     B-fin
count fish with [ not (read-from-string (item 5 my-genes) = 1 or read-from-string (item 6 my-genes) = 1) ]
0
1
11

MONITOR
793
62
873
107
B-body Total
count fish with [ color = blue ]
0
1
11

MONITOR
793
10
873
55
G-body Total
count fish with [ color = green ]
0
1
11

MONITOR
793
120
873
165
Total fish
count fish
0
1
11

@#$#@#$#@
## WHAT IS IT?

This model demonstrates some connections between probability and the natural sciences.  Specifically, the model uses combinatorial space, sampling, and distribution in a genotype/phenotype analysis of fish procreation. The model allows you to look "under the hood": you can study a Mendel-type visualization of the combinations of dominant and recessive genes that underlie changes and trends in genetic distribution.

Fish vary by body and fin color, each of which can be either green or blue, so there are four different phenotypes.  Underlying this variation are dominant and recessive genes, expressed in "4-blocks."  A 4-block is a 2-by-2 array of squares, each of which can be either green or blue.  Initially, fish are randomly distributed by 4-block genotype. Then, fish seek mates and reproduce, and the genetic distribution changes.

This model is a part of the ProbLab curriculum. For more information about the ProbLab curriculum please refer to http://ccl.northwestern.edu/curriculum/ProbLab/.

## PEDAGOGICAL NOTE

Fishes' Mendel-type dominant/recessive genetic combinations are shown as "4-Blocks," such as the following:

`[B][G]` = Blue in the top left corner, Green in the top right corner
`[B][B]` = Blue in the bottom left corner, Blue in the bottom right corner

The top row of the 4-block, e.g., "B G," is the fish's genetic code for body color, and the bottom row, e.g., "B B," is for fin color. Green is the dominant gene both for body and fin color, whereas blue is the recessive gene for those attributes.  Thus, a green-green top row makes for a green body color and so does green-blue and blue-green.  Only a blue-blue top row would give a blue body color.  The same applies to the bottom row, with respect to fin color.  For example, the fish with the genes in the 4-block above, has a green body and a blue fin.

When two fish mate, the offspring's each parent contributes one genetic "square" from each of its rows.  The selection is random.  It is therefore possible for two green-bodied fishes to beget a blue-bodied fishlet.

## HOW IT WORKS

When you add fish to the pool, each fish's genotype is selected randomly from the sample space of all 16 different combinations that a 4-block can take.  Fishes' phenotype is determined directly by their genotype.  Upon activating the simulation, the fish swim around randomly.  If at least two fish are on the same square (a NetLogo "patch"), they might mate and procreate if they are matched according to the pre-set mating rules (see 'THINGS TO NOTICE').  For instance, the fish might need to have the same fin color (see 'HOW TO USE IT').

When the fish mate, the offspring's genotype, both for the body color and the fin color, is determined as a combination of the parents' genetic material (combinations of blocks from their respective 4-Blocks).  When mating is selective, certain offspring are less likely to appear, so the population distribution changes, and these changes, in turn, further impact mating chances.  The simulation enables you to witness these processes.  Interface monitors and graphs keep track of fish distribution both by genotype and phenotype.

## HOW TO USE IT

Press SETUP, and then add as many fish as you'd like, in increments of 10, by pressing ADD FISH.  Change the mating rules in the MATE-WITH chooser and the LIFE-SPAN of a fish.  Then, press GO ONCE or GO to see the fish interact.  Below are more features that will let you take full advantage of the model's capabilities.

Sliders:

LIFE-SPAN -- sets the number of "years," or time-steps, a fish will live.

Buttons:

SETUP -- initializes variables, re-colors the tiles, and resets the monitors and the graphs.

ADD FISH -- adds 10 fish to the display, updating the 4-BLOCK DISTRIBUTION histogram.

GO ONCE -- activates a single run through the 'go' procedure during which the fish move one step in the direction they were facing; if two fish land on the same patch and they are suited to mate according to the current settings of the mating rules, an offspring of the two fish is born and appears somewhere in the world. A patch turns yellow to indicate that two fish are mating on it.

GO -- forever button that keeps running through the 'go' procedure (GO ONCE runs through the procedure only once).

REVEAL GENES -- when the button is pressed, click on specific fish on the display to view their 4-Block Genotype. If you click on a mating fish (it's on a yellow patch), the genes of both of the parents and the child are revealed at the top of the display, and all other fish are temporarily hidden.

Monitors:

G-BODY G-FIN -- displays the number of fish with a green body and a green fin.

G-BODY B-FIN -- displays the number of fish with a green body and a blue fin.

B-BODY G-FIN -- displays the number of fish with a blue body and a green fin.

B-BODY B-FIN -- displays the number of fish with a blue body and a blue fin.

G-BODY TOTAL -- displays the number of fish with a green body (G-BODY G-FIN + G-BODY B-FIN).

B-BODY TOTAL -- displays the number of fish with a blue body (B-BODY G-FIN + B-BODY B-FIN).

TOTAL G-FIN -- displays the number of fish with a green fin (G-BODY G-FIN + B-BODY G-FIN).

TOTAL B- FIN -- displays the number of fish with a blue fin (G-BODY B-FIN + B-BODY B-FIN).

\# of ITERATIONS -- displays the number of time-steps the current experiment had run.

AVE BLOCK -- gives the mean number of green squares in the genetic material (4-Blocks) of the entire fish population.

Plots:

PERCENT FISH BY PROPERTIES -- keeps track of the trends of the different sub-populations over multiple time-steps.

4-BLOCK DISTRIBUTION -- histogram of fish genotype, grouped by the number of green squares in the 4-Blocks.  The vertical red line represents the AVE BLOCK.

Choosers:

MATE-WITH -- Represents the four different mating-rule choices:

1. "Any Fish" -- Any fish with another fish.
2. "Same Body" -- Only fish with the same body color.
3. "Same Fin" -- Only fish with the same fin color.
4. "Same Both" -- Only fish with the same body and fin color (same phenotype).

## THINGS TO NOTICE

Press SETUP and then press ADD FISH 10 times. Watch the group of monitors in the top-right area of the interface. What can you say about the distribution of fish by body and fin color? Why is this distribution consistent when you repeat this little activity? Why do we get this specific initial distribution?

What is the setting of the LIFE-SPAN slider that would keep the population from depleting? How, if at all, does this depend on the setting of the MATE-WITH choice button and on the initial size of the population?

If you set the MATE-WITH choice button to "SAME BODY," fish will only mate with other fish that have the same body color and they do (they could differ in fin color).  How do you expect this should affect trends in the distribution of fish by phenotype, as viewed in the PERCENT FISH BY PROPERTIES plot?

In the current version of the model, at each 'go' only two fish per patch are selected randomly for a possible mating even if more than two fish are present on that patch.  In fact, two non-matching fish may be selected even there are matches on that patch.  This constraint limits the maximum reproduction rate to the number of patches in the graphic window.  Thus, the population may reach equilibrium, rather than explode. See 'EXTENDING THE MODEL' for ideas on how to make the model more realistic.

What is the total number of fish when the population reaches equilibrium, and how does this number depend on the LIFE-SPAN?

An experiment may reach a point where the number of blue-bodied fish is 0.  However, as the experiment continues, one or more blue-bodied fish may appear.  Can you explain this? Set MATE-WITH to "Same Body" for an example of such behavior.

Note that the PERCENT FISH BY PROPERTIES plot tracks the fish population by phenotype, while the 4-BLOCK DISTRIBUTION plot represents the fish population by genotype.

Note that for low values of LIFE-SPAN, your fish population may deplete and for higher values, the population might grow sharply but eventually arrive at equilibrium, at a point that is determined by the life span.

## THINGS TO TRY

Press SETUP and then press ADD FISH 10 times.  Watch the group of monitors in the top-right area of the model.  What can you say about the distribution of fish by body and by fin color? Why is this distribution quite consistent each time you repeat this little activity?  Why do we get this specific initial distribution? What if we added a 1000 fish --would the distribution be as far off of your expectation (in terms of absolute numbers?; in proportionate terms?).

Run the model with MATE-WITH set at "Any Fish." After the model has been running for a while, will the population make-up stay the same, or will it change?  Do you expect any type of fish to dominate? Which one and why?  Which 4-Block will dominate?

Run GO with MATE-WITH set at "Same Body." After the model has been running for a while, what do you predict will happen to the fish population?

How about MATE-WITH set at "Same Fin"? Which 4-Block would dominate now? After a while, what is the relationship between the G-G and G-B population?  Do these outcomes depend on the starting population?  If so, how so?

How do you expect the setting of MATE-WITH to affect trends in the distribution of fish by phenotype, as viewed in the "Percent Fish by Properties" graph?

Run GO with MATE-WITH set at "Same Both." What do you think will happen? Is it just a faster way of getting to the same body/same fin final result? Track the 4-Block population while doing so by slowing down the model.  Over repeated trials, you may notice that the population is quite sensitive to the random configuration of fish at the starting point?  (See 'EXTENDING THE MODEL').

Is there a connection between the mating rules and the tendency of the population to die out?

## EXTENDING THE MODEL

Change the mating procedures of the model so that instead of only two fish mating per patch, all fish on a patch get an opportunity to mate.  For example, if there are 6 fish on the same patch, a total of three pairs may reproduce.  This would make the model more realistic.

The model continuously plots four different fish populations in terms of the number in each.  You may want to track different aspects of the population, such as according to the number of green squares in each fish's 4-block.  Add a plot and edit the 'update-graphs' procedure to do so.

The current interface of the model allows the user to add exactly 10 fish at a time.  Give the user more control over the number of fish to be added.  To do so, you can add a 'user-input,' asking for the number of fish to be added, or you may want to add a slider where the user can select the number of fish to be added.  A simple way of adding an exact number of fish, x, is to type 'add-fish x' in the Command Center.

What is the connection between the original set of fish, the MATE-WITH choice, and the set of fish that the population ultimately "settles" on? Can you determine any rules? To do this, you would first want to create buttons that let the user add specific types of fish, for instance a blue-bodied/blue-finned fish. You could then explore the following question, for example: if the original population set has a higher presence of  B-BODY B-FIN fish, could this phenotype become dominant under any setting of MATE-WITH?

## NETLOGO FEATURES

The model utilizes the mouse-clicking capabilities of NetLogo.  Note that a forever button must be running in order for the model to detect a mouse click.

Note the white band at the top of the view. The procedures ensure that no fish may enter the area of the white band. The origin is moved so that the white band has positive y-coordinates so bounds checking is easier.  The band was designed for this model as a unique form of output to the user, because we required output features that cannot be displayed in a standard output area.

There are 16 different 4-blocks, for each of which a new shape had to be created in order for the fish to be able to REVEAL GENES.  While drawing one shape is not a very arduous task in NetLogo's Shapes Editor, drawing 16 or more is. (And imagine the task of creating all 512 shapes of a "9-block"!)  To create the blocks, we opened the NetLogo file in WordPad, in which all shapes are represented in text as circles, polygons and lines with coordinates and colors. Using this text-based version of the graphical elements greatly simplified the task of managing and generating the entire set of desired 4-Block shapes -- we simply used a straightforward combinatorial analysis expressed in simple symbols.  When we re-loaded the file in NetLogo, the entire set of 4-blocks was there just as if we had made them in the Shapes Editor.

## RELATED MODELS

ProbLab Genetics, though it may not seem so at first glance, is very closely related to the 9-Block Stalagmite model of the ProbLab curriculum.  In that model, 4-blocks are chosen and then stacked in a "histogram," to show the distribution of the blocks by type.  Similarly, we may track the distribution of the 4-blocks, the fishes' genotype, upon adding fish and watching the 4-BLOCK DISTRIBUTION histogram update.

In terms of interactions between breeds, several NetLogo models track the number of specimens in breeds that compete over resources. For an example, see the Wolf-Sheep Predation model.

In Expected Value Advanced, a model of the ProbLab Curriculum, the same metaphor of roaming fish is used.  As in this model, where a fish carries the value of the number of green squares in its 4-block, fish in Expected Value Advanced carry an underlying monetary value that may be collected and quantified.  Additionally, the fish's appearance is dependent on their underlying value (the larger the value, the lighter the body color).

## CREDITS AND REFERENCES

This model is a part of the ProbLab curriculum. For more information about the ProbLab Curriculum please refer to http://ccl.northwestern.edu/curriculum/ProbLab/.

Thanks to Steve Gorodetskiy for his design and programming work.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Abrahamson, D. and Wilensky, U. (2004).  NetLogo ProbLab Genetics model.  http://ccl.northwestern.edu/netlogo/models/ProbLabGenetics.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2004 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 2004 Cite: Abrahamson, D. -->
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

f0-0000
false
0
Rectangle -13345367 true false 0 0 150 150
Rectangle -13345367 true false 150 0 295 150
Rectangle -13345367 true false 0 150 150 295
Rectangle -13345367 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f1-0001
false
0
Rectangle -13345367 true false 0 0 150 150
Rectangle -13345367 true false 150 0 295 150
Rectangle -13345367 true false 0 150 150 295
Rectangle -13840069 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f1-0010
false
0
Rectangle -13345367 true false 0 0 150 150
Rectangle -13345367 true false 150 0 295 150
Rectangle -13840069 true false 0 150 150 295
Rectangle -13345367 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f1-0100
false
0
Rectangle -13345367 true false 0 0 150 150
Rectangle -13840069 true false 150 0 295 150
Rectangle -13345367 true false 0 150 150 295
Rectangle -13345367 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f1-1000
false
0
Rectangle -13840069 true false 0 0 150 150
Rectangle -13345367 true false 150 0 295 150
Rectangle -13345367 true false 0 150 150 295
Rectangle -13345367 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f2-0011
false
0
Rectangle -13345367 true false 0 0 150 150
Rectangle -13345367 true false 150 0 295 150
Rectangle -13840069 true false 0 150 150 295
Rectangle -13840069 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f2-0101
false
0
Rectangle -13345367 true false 0 0 150 150
Rectangle -13840069 true false 150 0 295 150
Rectangle -13345367 true false 0 150 150 295
Rectangle -13840069 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f2-0110
false
0
Rectangle -13345367 true false 0 0 150 150
Rectangle -13840069 true false 150 0 295 150
Rectangle -13840069 true false 0 150 150 295
Rectangle -13345367 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f2-1001
false
0
Rectangle -13840069 true false 0 0 150 150
Rectangle -13345367 true false 150 0 295 150
Rectangle -13345367 true false 0 150 150 295
Rectangle -13840069 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f2-1010
false
0
Rectangle -13840069 true false 0 0 150 150
Rectangle -13345367 true false 150 0 295 150
Rectangle -13840069 true false 0 150 150 295
Rectangle -13345367 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f2-1100
false
0
Rectangle -13840069 true false 0 0 150 150
Rectangle -13840069 true false 150 0 295 150
Rectangle -13345367 true false 0 150 150 295
Rectangle -13345367 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f3-0111
false
0
Rectangle -13345367 true false 0 0 150 150
Rectangle -13840069 true false 150 0 295 150
Rectangle -13840069 true false 0 150 150 295
Rectangle -13840069 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f3-1011
false
0
Rectangle -13840069 true false 0 0 150 150
Rectangle -13345367 true false 150 0 295 150
Rectangle -13840069 true false 0 150 150 295
Rectangle -13840069 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f3-1101
false
0
Rectangle -13840069 true false 0 0 150 150
Rectangle -13840069 true false 150 0 295 150
Rectangle -13345367 true false 0 150 150 295
Rectangle -13840069 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f3-1110
false
0
Rectangle -13840069 true false 0 0 150 150
Rectangle -13840069 true false 150 0 295 150
Rectangle -13840069 true false 0 150 150 295
Rectangle -13345367 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

f4-1111
false
0
Rectangle -13840069 true false 0 0 150 150
Rectangle -13840069 true false 150 0 295 150
Rectangle -13840069 true false 0 150 150 295
Rectangle -13840069 true false 150 150 295 295
Line -1 false 150 0 150 295
Line -1 false 0 0 295 0
Line -1 false 0 295 0 0
Line -1 false 295 295 0 295
Line -1 false 295 0 295 295
Line -1 false 0 150 295 150

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

fish-blue-fin
true
0
Rectangle -7500403 true true 105 90 135 90
Polygon -7500403 true true 117 180 109 174 100 162 92 149 84 131 82 116 80 98 84 76 91 61 100 54 112 50 131 48 149 80 168 48 179 50 193 53 206 62 212 77 215 97 213 118 206 139 195 158 184 172 173 188 209 255 89 255 124 186
Polygon -2674135 true false 120 180 105 165
Circle -1 true false 97 68 30
Circle -16777216 true false 108 79 8
Polygon -13345367 true false 105 150 125 105 165 105 190 150 105 150
Polygon -1 false false 105 150 125 105 165 105 190 150 105 150
Polygon -1 false false 117 180 109 174 100 162 92 149 84 131 82 116 80 98 84 76 91 61 100 54 112 50 131 48 149 80 168 48 179 50 193 53 206 62 212 77 215 97 213 118 206 139 195 158 184 172 173 188 209 255 89 255 124 186

fish-eye-fin
true
0
Rectangle -7500403 true true 105 90 135 90
Polygon -7500403 true true 90 255 210 255 171 179 127 180 90 255
Polygon -2674135 true false 120 180 105 165
Polygon -7500403 true true 118 180 110 174 101 162 93 149 85 131 83 116 81 98 85 76 92 61 101 54 113 50 132 48 150 80 169 48 180 50 194 53 207 62 213 77 216 97 214 118 207 139 196 158 185 172 171 185 128 188
Circle -1 true false 97 68 30
Circle -16777216 true false 108 79 8
Polygon -16777216 false false 108 144 138 114 153 114 183 144 108 144

fish-green-fin
true
0
Rectangle -7500403 true true 105 90 135 90
Polygon -7500403 true true 117 180 109 174 100 162 92 149 84 131 82 116 80 98 84 76 91 61 100 54 112 50 131 48 149 80 168 48 179 50 193 53 206 62 212 77 215 97 213 118 206 139 195 158 184 172 173 188 209 255 89 255 124 186
Polygon -2674135 true false 120 180 105 165
Circle -1 true false 97 68 30
Circle -16777216 true false 108 79 8
Polygon -10899396 true false 105 150 125 105 165 105 190 150 105 150
Polygon -1 false false 105 150 125 105 165 105 190 150 105 150
Polygon -1 false false 117 180 109 174 100 162 92 149 84 131 82 116 80 98 84 76 91 61 100 54 112 50 131 48 149 80 168 48 179 50 193 53 206 62 212 77 215 97 213 118 206 139 195 158 184 172 173 188 209 255 89 255 124 186

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

frame
false
14
Rectangle -16777216 true true -8 2 18 298
Rectangle -16777216 true true 1 0 300 16
Rectangle -16777216 true true 283 2 299 300
Rectangle -16777216 true true 1 285 300 299

frame-thicker
false
0
Rectangle -7500403 true true 5 7 38 295
Rectangle -7500403 true true 7 5 296 38
Rectangle -7500403 true true 256 7 295 295
Rectangle -7500403 true true 5 256 293 295
Line -16777216 false 5 5 5 295
Line -16777216 false 5 5 295 5
Line -16777216 false 295 5 295 295
Line -16777216 false 5 295 295 295
Line -16777216 false 38 256 38 38
Line -16777216 false 38 38 256 38
Line -16777216 false 256 256 256 38
Line -16777216 false 38 256 256 256

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

plus
false
0
Rectangle -7500403 true true 120 45 180 255
Rectangle -7500403 true true 45 120 255 180

right arrow
false
15
Polygon -7500403 true false 285 150 135 90 135 135 15 135 15 165 135 165 135 210

small plus
false
15
Rectangle -7500403 true false 135 90 165 210
Rectangle -7500403 true false 90 135 210 165

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
setup add-fish 50 repeat 10 [ go ]
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
