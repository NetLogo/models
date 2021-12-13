globals [
  instructions                          ; the user instructions that appear in the monitor on the top left

  abort-pick-dice?                      ; Boolean to preempt run-time error

  count-steps                           ; counts the number of outcomes in the current sample
  #combi-successes-per-sample-list      ; list of outcomes per sample that were exactly like
                                        ; the original combination
  #permis-successes-per-sample-list     ; list of outcomes per sample that are the original combination
                                        ; or its permutation
  samples-counter                       ; how many sample have elapsed in an experiment
  count-combi-successes                 ; counts up hits under the combi condition
  count-permis-successes                ; counts up hits under the permutation condition
  mean-combi-per-sample                 ; mean number of same-order outcomes per sample
  mean-permis-per-sample                ; mean number of either-order outcomes per sample
]

breed [ user-dice user-die ]            ; dice that the user chooses
breed [ model-dice model-die ]          ; dice that the model chooses

to startup
  initialize
  set instructions "Hi! Please read the Info tab to learn about this model, or just press Setup."
end

to initialize
  clear-all
  ask patches [ set pcolor green - 2 ]
  set abort-pick-dice? false
  set #combi-successes-per-sample-list []
  set #permis-successes-per-sample-list []
end

to setup
  initialize
  set-default-shape turtles "1"

  ; distribute the dice evenly along the x axis
  let spacing ((max-pxcor - min-pxcor) / 3)
  foreach n-values 2 [ n -> min-pxcor + (n + 1) * spacing ] [ x ->
    create-user-dice 1 [
      set size spacing
      set ycor max-pycor / 2 ; middle of top half
      set xcor x
      set color white
      set heading 0
      hatch-model-dice 1 [
        ; for each user die, we create a model dice in the bottom half of the view
        set ycor pycor * -1
        set hidden? true
      ]
    ]
  ]

  set instructions "OK. Now press [Pick Values] to set the combination of dice faces."
  reset-ticks
end

to pick-values
  if abort-pick-dice? [ stop ]
  set instructions (word
    "Click on the dice to create your combination. "
    "It goes from 1 to 6 and over again. "
    "Next, unpress [Pick Values].")
  display
  assign-face
end

; Convert any number to a shape from "1" to "6"
; (See info tab for explanations.)
to-report shape-for [ value ]
  let face-value (value - 1) mod 6 + 1
  report (word face-value)
end

; Every time you click on a die face, the procedure identifies the die's current face value,
; adds 1 to it, and assigns the corresponding new shape to the die.
to assign-face
  if mouse-down? [
    ask min-one-of user-dice [ distancexy mouse-xcor mouse-ycor ] [
      repeat 2 [ rt 45 display ] ; for visual effect!
      set shape shape-for (read-from-string shape + 1)
      repeat 2 [ rt 45 display ] ; for visual effect!
    ]
  ]
end

; procedure for generating random dice and searching for matches with the dice you picked
to search
  if samples-counter = total-samples [ stop ]

  ; managing the user-code interface
  set abort-pick-dice? true
  set instructions (word
    "The program guesses combinations randomly and tracks "
    "the number of times it discovers the dice you picked.")

  ask model-dice [
    set shape shape-for (random 6 + 1)
    show-turtle
  ]

  if single-success? [ display ] ; this would slow down the model too much in the global search

  ; Make lists of user dice shapes and model dice shapes, ordered from left to right
  let user-dice-shapes  map [ dice -> [ shape ] of dice ] sort-on [ xcor ] user-dice
  let model-dice-shapes map [ dice -> [ shape ] of dice ] sort-on [ xcor ] model-dice

  let combination-found? (model-dice-shapes = user-dice-shapes)
  let permutation-found? (sort model-dice-shapes = sort user-dice-shapes)

  set count-steps count-steps + 1

  if combination-found? [ set count-combi-successes count-combi-successes + 1 ]
  if permutation-found? [ set count-permis-successes count-permis-successes + 1 ]

  ; for 'single-success?' true, we want the program to stop after matching dice were found
  if single-success? [
    let message ""

    if permutation-found? and member? analysis-type ["Permutations" "Both"] [
      set message congratulate-permi
    ]
    if combination-found? and member? analysis-type ["Combination" "Both"] [
      set message congratulate-combi ; overwrites the "permutation" message, which is all right
    ]
    if not empty? message [
      set instructions message
      little-setup
      stop
    ]
  ]

  if count-steps = sample-size [
    set samples-counter samples-counter + 1
    set #combi-successes-per-sample-list fput count-combi-successes #combi-successes-per-sample-list
    set #permis-successes-per-sample-list fput count-permis-successes #permis-successes-per-sample-list
    tick
  ]
end

to-report congratulate-combi
  let steps (length #combi-successes-per-sample-list  * sample-size) + count-steps
  report (word
    "Congratulations! You discovered the hidden combination in " steps " steps. "
    "You can press [Roll Dice] again.")
end

to-report congratulate-permi
  let steps (length #permis-successes-per-sample-list  * sample-size) + count-steps
  report (word
    "Congratulations!  You discovered a permutation of the hidden combination in "
    steps " steps. You can press [Roll Dice] again.")
end

to little-setup
  set count-steps 0
  set count-combi-successes 0
  set #combi-successes-per-sample-list []
  set count-permis-successes 0
  set #permis-successes-per-sample-list []
end

to-report ratio
  ; we want the ratio to be rounded after two decimal points
  let denominator precision (mean #permis-successes-per-sample-list / mean #combi-successes-per-sample-list) 2
  report word "1 : " denominator
end


; Copyright 2004 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
430
65
801
481
-1
-1
11.0
1
12
1
1
1
0
0
0
1
-16
16
-18
18
1
1
1
ticks
30.0

MONITOR
82
196
164
241
+ # Rolls
count-steps
3
1
11

MONITOR
230
195
322
240
Combinations
count-combi-successes
3
1
11

SWITCH
275
75
420
108
single-success?
single-success?
1
1
-1000

MONITOR
9
196
79
241
#Samples
samples-counter
0
1
11

MONITOR
325
195
418
240
Permutations
count-permis-successes
3
1
11

TEXTBOX
232
177
407
195
Successes in this sample:
11
0.0
0

BUTTON
7
61
117
94
Setup
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
96
117
129
Pick Values
pick-values
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
131
117
164
Roll Dice
search
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
7
10
802
55
Instructions
instructions
0
1
11

MONITOR
10
440
125
485
Mean-Combination
mean #combi-successes-per-sample-list
2
1
11

PLOT
9
246
419
431
Successes-per-Sample Distributions
successes per sample
count
0.0
16.0
0.0
50.0
true
true
"" "if ticks > 0 [\nifelse analysis-type = \"Both\"\n  [\n    ;; this line regulates the appearance of the plot -- it centers the two histograms\n    set-plot-x-range 0  max ( list ( round 1.5 * ceiling ( mean  #permis-successes-per-sample-list ) )\n                                  ( 1 + max #permis-successes-per-sample-list ) .1 )\n  ]\n  [\n    ifelse analysis-type = \"Combination\"\n      [set-plot-x-range 0 max ( list ( 2 * ceiling ( mean  #combi-successes-per-sample-list ) )\n                                    ( 1 + max #combi-successes-per-sample-list ) .1 ) ]\n      [set-plot-x-range 0 max (list ( 2 * ceiling ( mean  #permis-successes-per-sample-list ) )\n                                    ( 1 + max #permis-successes-per-sample-list ) .1 ) ]\n  ]\n]"
PENS
"Combination" 1.0 1 -16777216 true "" "if analysis-type = \"Combination\" or analysis-type = \"Both\" [\n  plot-pen-reset\n  ifelse bars? [ set-plot-pen-mode 1 ] [ set-plot-pen-mode 0 ]\n  histogram #combi-successes-per-sample-list\n  set count-steps 0\n  set count-permis-successes 0\n  set count-combi-successes 0\n]"
"Permutations" 1.0 1 -2674135 true "" "if analysis-type = \"Permutations\" or analysis-type = \"Both\" [\n  plot-pen-reset\n  ifelse bars? [ set-plot-pen-mode 1 ] [ set-plot-pen-mode 0 ]\n  histogram #permis-successes-per-sample-list\n  set count-steps 0\n  set count-permis-successes 0\n  set count-combi-successes 0\n]"

MONITOR
125
440
247
485
Mean-Permutations
mean #permis-successes-per-sample-list
2
1
11

MONITOR
245
440
420
485
Combinations : Permutations
ratio
2
1
11

SLIDER
125
85
268
118
sample-size
sample-size
10
1000
10.0
10
1
NIL
HORIZONTAL

SLIDER
125
120
268
153
total-samples
total-samples
0
10000
5000.0
10
1
NIL
HORIZONTAL

CHOOSER
275
120
420
165
analysis-type
analysis-type
"Permutations" "Combination" "Both"
0

SWITCH
325
395
416
428
bars?
bars?
0
1
-1000

BUTTON
565
275
676
309
Hide/Reveal
ask user-dice [ set hidden? (not hidden?) ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

@#$#@#$#@
## WHAT IS IT?

"Dice" is a virtual laboratory for learning about probability through conducting and analyzing experiments. You set up an experiment by choosing a combination of face values for each dice, for instance 3 and 4 (we will use this example throughout). Then the model "rolls" two dice repeatedly and records how often its dice match your chosen combination.

The model’s dice can match your initial combination in two ways: they can show the same numbers in the same order; or they can show the same numbers regardless of order. The model collects statistics on both kinds of matches.  The plots and monitors in the model give you different perspectives on the accumulated data.

This model is a part of the ProbLab curriculum. For more information about the ProbLab Curriculum please refer to http://ccl.northwestern.edu/curriculum/ProbLab/.

## HOW IT WORKS

The user selects a face value for each dice. After pressing **Roll Dice**, the model  rolls virtual dice over and over to test how frequently the user-selected combination is rolled. The histogram, **Successes-per-Sample Distributions**, shows the frequency of successful virtual rolls.

## PEDAGOGICAL NOTE

This model introduces tools, concepts, representations, and vocabulary for describing random events.  Among the concepts introduced are "sampling" and "distribution".

The various ProbLab models use virtual computer-based "objects" to teach probability.  In this model, these objects are virtual dice, similar to the familiar, physical ones. By using familiar objects, we hope to help learners form a conceptual bridge from their everyday experience to more abstract concepts. Using the Dice model helps prepare students for experiences with other ProbLab models that use virtual objects that are less familiar.

Facilitators are encouraged to introduce this model as an enhancement of experiments with real dice. The model has several advantages over real dice. Virtual dice roll faster, and the computer can record the results instantly and accurately from multiple perspectives simultaneously.

The model attempts to involve the learner by allowing them to choose a combination before running the experiment.

## HOW TO USE IT

Press **setup**, then press **Pick Values**.  By clicking on the dice at the top of the view, you cycle through each possible face of the dice to eventually set a combination, for instance [3; 4].  When you’re finished, unpress **Pick Values**. Press **Roll Dice** to begin the experiment. If you set the **single-success?** switch to 'On,' the experiment will stop the moment the combination or a permutation of the combination you chose is rolled (depending on the **analysis-type** chosen). If **single-success?** Is 'Off,' the experiment will keep running as many times as you have set the values of the **sample-size** and **total-samples** sliders. In the plot window, you can see histograms start stacking up, showing how many times the model has rolled your pair in its original order (**Combinations**) and how many times it has discovered you pair in any order (**Permutation**).


### Buttons:

**setup**: begins new experiment

**Pick Values**: allows you to use the mouse to click on squares to pick the target dice face.  Clicking repeatedly on the same square loops the die-faces through each possible face-value option.

**Hide/Reveal**: toggles between hiding and revealing the dice you picked. This function is useful when you pose a riddle to a friend and you do not want them to know what dice you chose.

**Roll Dice**: activates the rolling of the computer's dice. The program generates random dice-faces and matches the outcome against your combination.

### Switches:

**single-success?**: stops rolling after the combination has been matched once.

**bars?**: toggles between two graphing options: "On" is a histogram, and "Off" gives a line graph.

### Choices:

**analysis-type**

  * "Permutations": Order does not matter, so '4 3' is considered the same as its permutation '3 4' (it is registered as a success)
  * "Combination": Order matters, so '4 3' is not accepted as the same as its permutation '3 4' (it is not registered as a success)
  * "Both": "Permutations" and "Combination" both count as successes

### Sliders:

**sample-size**: The number of dice rolls in a sample

**total-samples**: The number of samples you are taking throughout an experiment.

### Monitors:

**#samples**: Shows how many samples have been taken up to this point in this experiment

**+ # Rolls**: Shows how many single rolls have occurred within the current sample.

**Combinations**: Shows the number of successes (where order matters) in the current sample

**Permutations**: Shows the number of successes (where order does not matter) in the current sample

**Mean-Combinations**: The sample mean of successes (order matters). This is calculated only on full, completed samples.

**Mean-Permutations**: the sample mean of successes (order does not matter). This is calculated only on full, completed samples.

**Combinations : Permutations**: The ratio between the successful 'combination' and 'permutation' rolls. This is calculated only on full, completed samples.

### Plots:

**Successes-per-sample Distributions**: The number of successes per sample. For instance, if on the first five samples, the combination was matched 3 times, 2 times, 4 times, 7 times, and 4 times, then the "Combinations" histogram will be the same height over 2, 3, and 7, but it will be twice as highover the 4, because 4 occurred twice.

## THINGS TO NOTICE

As the experiment runs, the distributions of outcomes in the plots gradually take on a bell-shaped curve.

As the model rolls its dice, watch the monitors **Combinations** and **Permutations**. Note whether or not they are updating their values at the same pace. For most combinations that you set, **Permutations** updates much faster. This is because **Permutations** registers a success each time the model rolls the values you selected, even if they appear in a different order.

As the model rolls its dice, watch the monitor **Combinations : Permutations**. At first, it changes rapidly, and then it changes less and less frequently. Eventually, it seems to stabilize on some value. Why is that?

Unless the red histogram (showing permutations) covers the black histogram (showing combination) entirely, you will see that the permutations-histogram always becomes both wider and shorter than the combinations-histogram. Also, the permutations-histogram  typically stretches over a greater range of values than the combinations-histogram. Try to explain why the permutations-distribution has greater variance than the combinations-distribution.

Also, you may notice that the permutations- and combinations-histograms cover the same area. That is because the total area of each histogram, irrespective of their location along the horizontal axis and irrespective of their shape, indicates the number of samples. Because the two histograms represent the same number of samples they have the same area.

## THINGS TO TRY

Generally, are there always more permutations than combinations?

Run an experiment with a sample size of 20 and then run it with the same settings but with a sample size of 100 or more. In each experiment, look at the distribution of the **Successes-per-sample Distributions**. See how the experiment with the small sample resulted in half-a-bell curve, whereas the experiment with the larger sample results in a whole-bell curve. Why is that?

Pressing **Hide/Reveal** after you create a combination allows you to setup an experiment for a friend to run. Your friend will not know what the combination is and will have to analyze the graphs and monitors to make an informed guess. You may find that some combinations are harder to guess than others. Why is that? For instance, compare the case of the combination [1; 1] and [3; 4]. Is there any good way to figure out if we are dealing with a double or not? This question is also related to the following thing to try.

For certain dice values you pick, if the model rolls dice under the "Both" option of the **analysis-type** choice, you will see only a single histogram in **Successes-per-sample Distributions**. Try to pick dice combinations that produce a single histogram. What do these dice combinations have in common? Why do you think you observe only a single histogram? Where is the other histogram? How do the monitors behave when you have a single histogram?

When the combinations- and permutations-histograms do not overlap, we can speak of the distance between their means along the x-axis. Which element in the model can affect this distance between them? For instance, what should you do in order to get a bigger distance between these histograms? What makes for narrow histograms? Are they really narrower, or is it just because the maximum x-axis value is greater and so the histograms are "crowded?"

Set **sample-size** to 360 and **total-samples** to its maximum value. Pick the dice [3; 4], and run the experiment. You will get a mean of about 10 for the Combination condition (in which order matters, so only [3; 4] is considered a success), and you will get a mean of about 20 for the Permutations condition (where order does not matter, so both [3; 4] and [4; 3] are considered successes). Why 10 and 20? There are 6*6=36 different dice pairs when we take into consideration the order: [1; 1] [1; 2] [1; 3] [1; 4] [1; 5] ... [6; 4] [6; 5] [6; 6]. So samples of 36 rolls have on average a single occurrence of [3; 4] and a single occurrence of [4; 3]. Thus, samples of 360 have 10 times that: 10 occurrences of [3; 4] and 10 of [4; 3], on average.

## EXTENDING THE MODEL

Add a 7th die face. Then you can run experiments with 7-sided dice!

Add a plot of the ratio between combinations and permutations.

Currently the model just rolls dice randomly, and records when its roll is similar to the dice values you picked. Could the model use a more efficient search procedure to guess your dice? For instance, the moment one of the squares has the correct die face, the program would continue guessing only the other die. Another idea might be to create a systematic search procedure.

It should be interesting to track how long it takes the model from one success to another. Add code, monitors, and a plot to do so.

## NETLOGO FEATURES

We rely on iteration to evenly distribute the dice in the model. Rather than hard coding the x and y values of each dice, we calculate a 'spacing' between them, and iterate over the number of dice (2). The advantage to this is that if we ever want to add more dice, or if we decide to change the size of the model view, dice will still be distributed evenly.

An interesting feature of "Dice," that does not appear in many other models, is the procedure for selecting a die's face value. Look in the Shapes Editor that is in the Tools dropdown menu. You will find six die shapes: "1", "2", "3", "4", "5", and "6". To you, it is obvious that three dots means "3," and that this is the same as the number 3, but the program doesn't "know" this unless you "tell" it. This is not a problem when we check to see if the computer has found a combination, we just have to compare the names of the shapes: whether is "three", "3" or "rhinoceros", the important thing is that they match.

When we want to change the face of a die to a certain number, however, we need to convert this number to a string. NetLogo has the `word` primitive for that: `(word 3)` will convert the number `3` to the string `"3"`. So far so good, but what happens when you click on a dice and it goes to the next value? Computers are good at adding numbers, but not at adding strings! The program need to look at the name of the shape (`"3"`, in our example), convert it to a number, add `1` to it, and then convert it back to a string (`"4"`) to get the right face shape. The `read-from-string` primitive does the conversion from string to number.

And there is one further complication! What if we are already at face number 6 and we add 1 to it? We get `7`, but we want to go back to face 1. The [modulo](https://en.wikipedia.org/wiki/Modulo_operation) mathematical operation (`mod`, in NetLogo) can help us here: the result of any number `mod 6` will always be a number from `0` to `5`. To convert any number (`7`, in our example) to a die face from 1 to 6, we subtract one from the number, apply `mod 6`, add back one, and voilà! This little dance is taken care of by the `shape-for` reporter.

Hint: if you wanted to add a seventh face for the dice, like it is suggested above, you would need to modify the `shape-for` reporter...

## RELATED MODELS

The ProbLab model Random Combinations and Permutations builds on Dice. There, you can work with more than just 2 dice at a time. Also, you can work with colors instead of dice faces.

## CREDITS AND REFERENCES

This model is a part of the ProbLab curriculum. For more information about the ProbLab Curriculum please refer to http://ccl.northwestern.edu/curriculum/ProbLab/.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Abrahamson, D. and Wilensky, U. (2004).  NetLogo Dice model.  http://ccl.northwestern.edu/netlogo/models/Dice.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

1
true
15
Rectangle -1 true true 15 15 285 285
Circle -16777216 true false 116 116 67
Circle -7500403 false false 116 116 67
Rectangle -7500403 false false 15 15 285 285
Rectangle -16777216 false false 15 15 285 285

2
false
15
Rectangle -1 true true 15 15 285 285
Circle -16777216 true false 41 41 67
Circle -7500403 false false 41 41 67
Circle -16777216 true false 191 191 67
Circle -7500403 false false 191 191 67
Rectangle -16777216 false false 15 15 285 285

3
true
15
Rectangle -1 true true 15 15 285 285
Circle -16777216 true false 116 116 67
Circle -16777216 true false 41 41 67
Circle -7500403 false false 41 41 67
Circle -16777216 true false 191 191 67
Circle -7500403 false false 191 191 67
Circle -7500403 false false 116 116 67
Rectangle -16777216 false false 15 15 285 285

4
true
15
Rectangle -1 true true 15 15 285 285
Circle -16777216 true false 191 41 67
Circle -16777216 true false 41 41 67
Circle -7500403 false false 41 41 67
Circle -16777216 true false 191 191 67
Circle -7500403 false false 191 191 67
Circle -7500403 false false 191 41 67
Circle -16777216 true false 41 191 67
Circle -7500403 false false 41 191 67
Rectangle -16777216 false false 15 15 285 285

5
true
15
Rectangle -1 true true 15 15 285 285
Circle -16777216 true false 116 116 67
Rectangle -16777216 false false 15 15 285 285
Circle -16777216 true false 41 191 67
Circle -7500403 false false 41 191 67
Circle -16777216 true false 191 41 67
Circle -16777216 true false 41 41 67
Circle -7500403 false false 41 41 67
Circle -16777216 true false 191 191 67
Circle -7500403 false false 191 191 67
Circle -7500403 false false 191 41 67
Circle -7500403 false false 116 116 67

6
true
15
Rectangle -1 true true 15 15 285 285
Circle -16777216 true false 41 116 67
Circle -16777216 true false 191 116 67
Rectangle -16777216 false false 15 15 285 285
Circle -16777216 true false 41 191 67
Circle -7500403 false false 41 191 67
Circle -16777216 true false 191 41 67
Circle -16777216 true false 41 41 67
Circle -7500403 false false 41 41 67
Circle -16777216 true false 191 191 67
Circle -7500403 false false 191 191 67
Circle -7500403 false false 191 41 67
Circle -7500403 false false 41 116 67
Circle -7500403 false false 191 116 67

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

frame
false
14
Rectangle -16777216 true true -8 2 18 298
Rectangle -16777216 true true 1 0 300 16
Rectangle -16777216 true true 283 2 299 300
Rectangle -16777216 true true 1 285 300 299

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
setup search
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
