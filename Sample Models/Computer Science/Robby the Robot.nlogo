;; Each candidate strategy is represented by one individual.
;; These individuals don't appear in the view; they are an invisible source
;; of strategies for Robby to use.
breed [individuals individual]
individuals-own [
  chromosome   ;; list of procedure names
  fitness      ;; average final score
  scaled-fitness ;; Used for display functions
  allele-distribution
]

;; This is Robby.
;; Instead of making a separate variable to keep his current score in, we just
;; use the built-in variable "label", so we can see his score as he moves around.
breed [robots robot]
robots-own [strategy]

breed [cans can]

globals [
  can-density
  can-reward
  wall-penalty
  pick-up-penalty
  best-chromosome
  best-fitness
  step-counter ;; used for keeping track of Robby's movements in the trial
  visuals?     ;; only true when the set up environment button (SETUP-VISUALS procedure) is called. During the regular GA runs we
               ;; skimp on visuals to get greater speed.
  min-fit
  max-fit
  x-offset       ; For placing individuals in world
  tournament-size ; Size of "tournament" used to choose each parent.
  num-environments-for-fitness ; Number of environments for Robby to run in to calculate fitness
  num-actions-per-environment; Number of actions Robby takes in each environment for calculating fitness
]

;;; setup procedures


to setup
  clear-all
  reset-ticks
  ask patches [set pcolor white]
  set visuals? false
  initialize-globals
  set-default-shape robots "person"
  set-default-shape cans "dot"
  set-default-shape individuals "person"
  create-individuals population-size [
    set color 19
    set size .5

    ;; A situation consists of 5 sites, each of which can contain 3 possibilities (empty, can, wall).
    ;; So 243 (3^5) is the chromosome length allowing any possible situation to be represented.
    set chromosome n-values 243 [random-action]
    ;; calculate the frequency of the 7 basic actions (or "alleles") in each chromosome
    set allele-distribution map [ action -> occurrences action chromosome ] ["move-north" "move-east" "move-south" "move-west" "move-random" "stay-put" "pick-up-can"]
  ]
  calculate-population-fitnesses
  let best-individual max-one-of individuals [fitness]
  ask best-individual [
    set best-chromosome chromosome
    set best-fitness fitness
    output-print (word "generation " ticks ":")
    output-print (word "  best fitness = " fitness)
    output-print (word "  best strategy: " map action-symbol chromosome)
  ]
  display-fitness best-individual

  plot-pen-up

  ; plots are initialized to begin at an x-value of 0, this moves the plot-pen to
  ; the point (-1,0) so that best-fitness for generation 0 will be drawn at x = 0
  plotxy -1 0

  set-plot-y-range (precision best-fitness 0) (precision best-fitness 0) + 3
  plot best-fitness
  plot-pen-down
end

to initialize-globals
  set can-density 0.5
  set wall-penalty 5
  set can-reward 10
  set pick-up-penalty 1
  set min-fit  -100; For display.  Any fitness less than min-fit is displayed at the same location as min-fit.
  set max-fit 500 ; (approximate) maximum possible fitness that an individual could obtain assuming approx. 50 cans per environment.
  set x-offset 0
  set tournament-size 15
  set num-environments-for-fitness 20
  set num-actions-per-environment 100
end

;; randomly distribute cans, one per patch
to distribute-cans
  ask cans [ die ]
  ask patches with [random-float 1 < can-density] [
    sprout-cans 1 [
      set color orange
      if not visuals? [hide-turtle]
    ]
  ]
end

to draw-grid
  clear-drawing
  ask patches [
    sprout 1 [
      set shape "square"
      set color blue + 4
      stamp
      die
    ]
  ]
end

to-report random-action
  report one-of ["move-north" "move-east" "move-south" "move-west"
                 "move-random" "stay-put" "pick-up-can"]
end

;; converts action string to its associated symbol
to-report action-symbol [action]
  if action = "move-north"  [ report "↑" ]
  if action = "move-east"   [ report "→" ]
  if action = "move-south"  [ report "↓" ]
  if action = "move-west"   [ report "←" ]
  if action = "move-random" [ report "+" ]
  if action = "stay-put"    [ report "x" ]
  if action = "pick-up-can" [ report "●" ]
end

;; converts action string to its associated number
to-report action-number [action]
  if action = "move-north"  [ report 1 ]
  if action = "move-east"   [ report 2 ]
  if action = "move-south"  [ report 3 ]
  if action = "move-west"   [ report 4 ]
  if action = "move-random" [ report 5 ]
  if action = "stay-put"    [ report 6 ]
  if action = "pick-up-can" [ report 7 ]
end

to go
  create-next-generation
  calculate-population-fitnesses
  let best-individual max-one-of individuals [fitness]
  display-fitness best-individual
  ask best-individual [
    set best-chromosome chromosome
    set best-fitness fitness
    output-print (word "generation " (ticks + 1) ":")
    output-print (word "  best fitness = " fitness)
    output-print (word "  best strategy: " map action-symbol chromosome)
  ]
  tick
end

to go-n-generations
  if ticks < number-of-generations [go]
end


;; scale the color of the individuals according to their fitness: the higher the fitness, the darker the color
;; also move the individuals to an x coordinate that is a function of their fitness and a y coordinate that is a function of the allele distance to the best-individual
to display-fitness [best-individual]
  ask individuals [ set label "" set color scale-color red scaled-fitness 1 -.1]
  let mid-x max-pxcor / 2
  let mid-y max-pycor / 2
  ask best-individual [
    setxy ((precision scaled-fitness 2) * max-pxcor + x-offset) mid-y
    setxy ( scaled-fitness * max-pxcor + x-offset) mid-y
    ;; place the individuals at a distance from the center based on the similarity of their chromosome to the best chromosome
    ask other individuals [
      setxy ((precision scaled-fitness 2) * max-pxcor + x-offset) mid-y
      setxy ( scaled-fitness * max-pxcor + x-offset) mid-y
      set heading one-of [0 180]
      fd chromosome-distance self myself
      ]
  ]
  ask best-individual [set heading 90 set label-color black set label (word "Best:" (precision fitness  2)) ]
end


to initialize-robot [s]
  ask robots [ die ]
  create-robots 1 [
    set label 0
    ifelse visuals? [ ; Show robot if this is during a trial of Robby that will be displayed in the view.
      set color blue
      pen-down
      set label-color black
      ]
      [set hidden? true]  ; Hide robot if this is during the GA run.
    set strategy s
  ]
end

to create-next-generation ;[best-individual]

  ; The following line of code looks a bit odd, so we'll explain it.
  ; if we simply wrote "let old-generation individuals",
  ; then old-generation would mean the set of all individuals, and when
  ; new individuals were created, they would be added to the breed, and
  ; old-generation would also grow.  Since we don't want it to grow,
  ; we instead write "(turtle-set individuals)", which makes old-generation
  ; a new agentset which doesn't get updated when new individuals are created.
  let old-generation (turtle-set individuals)

  ; The new population is created by crossover.  Each crossover creates two children.
  ; There are population-size/2 crossovers done.  (Population size is constrained to
  ; be even.)
  let crossover-count population-size / 2

  repeat crossover-count [

    ; We use "tournament selection". So for example if tournament-size is 15
    ; then we randomly pick 15 individuals from the previous generation
    ; and allow the best-individuals to reproduce.

    let parent1 max-one-of (n-of tournament-size old-generation) [fitness]
    let parent2 max-one-of (n-of tournament-size old-generation) [fitness]

    ; get a two-element list containing two new chromosomes
    let child-chromosomes crossover ([chromosome] of parent1) ([chromosome] of parent2)

    ; create the two children, with their new genetic material
    let actions ["move-north" "move-east" "move-south" "move-west" "move-random" "stay-put" "pick-up-can"]
    ask parent1 [
      hatch 1 [
        rt random 360 fd random-float 3.0
        set chromosome item 0 child-chromosomes
        ;; record the distribution of basic actions (or "alleles") for each individual
        set allele-distribution map [ action -> occurrences action chromosome ] actions
      ]
    ]
    ask parent2 [
      hatch 1 [
        rt random 360 fd random-float 3.0
        set chromosome item 1 child-chromosomes
        ;; record the distribution of basic actions (or "alleles") for each individual
        set allele-distribution map [ action -> occurrences action chromosome ] actions
       ]
    ]
  ]

  ask old-generation [ die ]
  ask individuals [ mutate ]
end

;; each individual takes NUM-ACTIONS-PER-ENVIRONMENT actions according to its strategy on NUM-ENVIRONMENTS-FOR-FITNESS random environments
to calculate-population-fitnesses
  foreach sort individuals [ current-individual ->
    let score-sum 0
    repeat num-environments-for-fitness [
      initialize-robot [chromosome] of current-individual
      distribute-cans
      repeat num-actions-per-environment [
        ask robots [ run item state strategy ]
      ]
      set score-sum score-sum + sum [label] of robots
    ]
    ask current-individual [
      set fitness score-sum / num-environments-for-fitness
      ifelse fitness < min-fit
        [set scaled-fitness 0]
        [set scaled-fitness (fitness + (abs min-fit)) / (max-fit + (abs min-fit))]
    ]
  ]
end

;; This reporter performs one-point crossover on two chromosomes.
;; That is, it chooses a random location for a splitting point.
;; Then it reports two new lists, using that splitting point,
;; by combining the first part of chromosome1 with the second part of chromosome2
;; and the first part of chromosome2 with the second part of chromosome1;
;; it puts together the first part of one list with the second part of
;; the other.

to-report crossover [chromosome1 chromosome2]
  let split-point 1 + random (length chromosome1 - 1)
  report list (sentence (sublist chromosome1 0 split-point)
                        (sublist chromosome2 split-point length chromosome2))
              (sentence (sublist chromosome2 0 split-point)
                        (sublist chromosome1 split-point length chromosome1))
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; This procedure causes random mutations to occur in a solution's chromosome.
;; The probability that each item will be replaced is controlled by the
;; MUTATION-RATE slider.  In the MAP, "[?]" means "return the same value".

to mutate   ;; individual procedure
  set chromosome map [ action ->
    ifelse-value random-float 1 < mutation-rate
      [random-action]
      [action]
  ] chromosome
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; robot procedures

;; These procedures are called an extremely high number of times as the GA runs, so it's
;; important they be fast.  Therefore they are written in a style which maximizes
;; execution speed rather than maximizing clarity for the human reader.

;; Each possible state is encoded as an integer from 0 to 242 and then used as an index
;; into a strategy (which is a 243-element list).  Here's how the encoding works.  There
;; are five patches Robby can sense.  Each patch can be in one of three states, which
;; we encode as 0 (empty), 1 (can), and 2 (wall).  Putting the five states in an arbitrary
;; order (N, E, S, W, patch-here), we get a five digit number, for example 10220 (can
;; to the north, walls to the south and west, nothing to the east and here).  Then we
;; interpret this number in base 3, where the first digit is the 81s place,
;; the second digit is the 27s place, the third is the 9s place, the fourth is the 3s place,
;; and the fifth is the 1s place.  For speed, we do this math using a compact series of
;; nested IFELSE-VALUE expressions.
to-report state
  let north patch-at 0 1
  let east patch-at 1 0
  let south patch-at 0 -1
  let west patch-at -1 0
  report (ifelse-value is-patch? north [ifelse-value any? cans-on north [81] [0]] [162]) +
         (ifelse-value is-patch? east  [ifelse-value any? cans-on east  [27] [0]] [ 54]) +
         (ifelse-value is-patch? south [ifelse-value any? cans-on south [ 9] [0]] [ 18]) +
         (ifelse-value is-patch? west  [ifelse-value any? cans-on west  [ 3] [0]] [  6]) +
         (ifelse-value any? cans-here [1] [0])
end

;; Below are the definitions of Robby's seven basic actions
to move-north  set heading   0  ifelse can-move? 1 [ fd 1 ] [ set label label - wall-penalty ]  end
to move-east   set heading  90  ifelse can-move? 1 [ fd 1 ] [ set label label - wall-penalty ]  end
to move-south  set heading 180  ifelse can-move? 1 [ fd 1 ] [ set label label - wall-penalty ]  end
to move-west   set heading 270  ifelse can-move? 1 [ fd 1 ] [ set label label - wall-penalty ]  end
to move-random run one-of ["move-north" "move-south" "move-east" "move-west"] end
to stay-put    end  ;; Do nothing


to pick-up-can
  ifelse any? cans-here
    [ set label label + can-reward ]
    [ set label label - pick-up-penalty ]
  ask cans-here [
    ;; during RUN-TRIAL, leave gray circles behind so we can see where the cans were
    if visuals? [
      set color gray
      stamp
    ]
    die
  ]
end

to setup-robot-visuals
  if ticks = 0 [ stop ]  ;; must run at least one generation before a best-individual exists
  clear-output
  ask individuals [hide-turtle]
  set visuals? true
  draw-grid
  distribute-cans
  initialize-robot best-chromosome
  set step-counter 1
  output-print "Setting up a new random can distribution"
end

;;display the last view of strategies seen before entering Robot view
;;this only works while in Robot view
to setup-individual-visuals
  if visuals? [
    clear-output
    clear-drawing
    ask cans [die]
    ask robots [die]
    ask patches [set pcolor white]
    ask individuals [show-turtle]
    set visuals? false
    let best-individual max-one-of individuals [fitness]
    display-fitness best-individual
    ask best-individual[
      output-print (word "generation " ticks ":")
      output-print (word "  best fitness = " fitness)
      output-print (word "  best strategy: " map action-symbol chromosome)
    ]
  ]
end


;; Robby takes one step of best strategy
to run-trial-step
  if ticks = 0 [ stop ]  ;; must run at least one generation before a best-individual exists
  if step-counter > num-actions-per-environment [set step-counter 0 set visuals? false ]
  if step-counter = 1 [output-print "Stepping through the best strategy found at this generation"]
  ask robots [
      let current-action item state strategy
      run current-action
      ifelse step-counter != num-actions-per-environment
      [output-print (word step-counter ")  " current-action " (" action-symbol current-action "), score = " label)]
      [output-print (word step-counter ")  " current-action " (" action-symbol current-action "), final-score = " label)]
      ;; we're not using the tick counter here, so force a view update
      display
      set step-counter step-counter + 1
  ]
end

;; count the number of occurrences of an item in a list
to-report occurrences [x a-list]
  report reduce [ [n the-item] -> ifelse-value the-item = x [ n + 1 ] [ n ] ] (fput 0 a-list)
end

;; measure distance between two chromosomes
;; distance is Euclidean distance between their allele distributions, scaled to fit in view
to-report chromosome-distance [individual1 individual2]
  let max-dist  273 * sqrt 2
  ;; compute the euclidean distance between allele distributions
  let dist2 sum (map [ [a1 a2] -> (a1  - a2) ^ 2 ] [allele-distribution] of individual1 [allele-distribution] of individual2)
  ;; scale the distance to fit in the view
  let dist-candidate max-pxcor * sqrt dist2 / ( max-dist / 10)
  ;; if distance is too large, report the edge of the view
  report ifelse-value dist-candidate > max-pxcor [max-pxcor] [dist-candidate]
end


; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
@#$#@#$#@
GRAPHICS-WINDOW
336
16
644
325
-1
-1
30.0
1
10
1
1
1
0
0
0
1
0
9
0
9
1
1
1
generations
90.0

SLIDER
12
262
184
295
population-size
population-size
20
500
100.0
2
1
NIL
HORIZONTAL

SLIDER
13
307
185
340
mutation-rate
mutation-rate
0
1
0.01
.001
1
NIL
HORIZONTAL

BUTTON
43
74
116
107
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

PLOT
11
357
312
557
Best Fitness
Generation
Best Fitness
0.0
5.0
-30.0
1.0
true
false
"" ""
PENS
"best" 1.0 0 -16777216 true "" "plot best-fitness"

OUTPUT
682
10
1113
552
9

TEXTBOX
1116
203
1274
346
\"↑\" =   move-north  \n \"→\"  = move-east \n \"↓\"  = move-south  \n \"←\"  = move-west\n \"+\"   = move-random\n \"x\"    =  stay-put   \n\"●\"    =  pick-up-can
13
0.0
1

TEXTBOX
9
26
258
58
Speed up speed slider or turn off\nview updates for faster response.
11
0.0
1

BUTTON
339
481
528
514
step thru best strategy
run-trial-step
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
13
220
184
253
number-of-generations
number-of-generations
1
1000
100.0
1
1
NIL
HORIZONTAL

BUTTON
13
173
156
206
NIL
go-n-generations
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
340
374
490
392
Low Fitness
11
18.0
1

TEXTBOX
456
374
606
392
Medium Fitness
11
13.0
1

TEXTBOX
588
373
738
391
High Fitness
11
10.0
1

BUTTON
339
442
532
475
view Robby's Environment
setup-robot-visuals
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
537
487
658
518
Watch Robby move\none step at a time.
10
0.0
1

TEXTBOX
540
424
676
476
Setup and view Robby's\nenvironment by randomly\ndistributing cans\nthroughout the world.
10
0.0
1

TEXTBOX
339
393
660
435
After running the GA,  watch Robby use\nthe best evolved strategy:
14
95.0
1

BUTTON
28
123
128
156
go-forever
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

TEXTBOX
249
226
399
282
More similar \nto best strategy
11
0.0
1

TEXTBOX
250
63
400
105
Less similar\nto best strategy
11
0.0
1

TEXTBOX
249
294
399
336
Less similar \nto best strategy
11
0.0
1

TEXTBOX
254
185
404
203
Population
14
95.0
1

TEXTBOX
250
132
400
160
More similar\nto best strategy
11
0.0
1

TEXTBOX
9
10
159
28
Run the GA:
14
95.0
1

BUTTON
339
524
520
557
view strategies
setup-individual-visuals
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
535
530
670
558
Return to a view of\nthe strategies.
10
0.0
1

@#$#@#$#@
## WHAT IS IT?

Robby the Robot is a virtual robot who moves around a room and picks up cans.  This model demonstrates the use of a genetic algorithm (GA) to evolve control strategies for Robby.  The GA starts with randomly generated strategies and then uses evolution to improve them.

## HOW IT WORKS

### How Robby works

Robby's 10x10 square world contains randomly scattered cans. His goal is to pick up as many as he can.  At each time tick, Robby can perform one of seven actions: move in one of the four cardinal directions, move in a random direction, pick up a can, or stay put.

When Robby picks up a can, he gets a reward. If he tries to pick up a can where none exists, or bumps into a wall, he is penalized.  His score at the end of a run is the sum of these rewards and penalties. The higher his score, the better he did.

To decide which action to perform, Robby senses his surroundings. He can see the contents of the square he is in and the four neighboring squares.  Each square can contain a wall, a can, or neither.  That means his sensors can be in one of 3<sup>5</sup> = 243 possible combinations.

A "strategy" for Robby specifies one of his seven possible actions for each of those 243 possible situations he can find himself in.

(Advanced note: If you actually do the math, you'll realize that some of those 243 situations turn out to be "impossible", e.g., Robby will never actually find himself in a situation in which all cardinal directions contain walls.  This is no problem; the genetic algorithm essentially ignores the "impossible" situations since Robby never encounters them.)

### How the genetic algorithm works

There are many possible variations on the basic concept of a genetic algorithm. Here is the particular variant implemented in this model.

We begin with a pool of randomly generated strategies.  We load each strategy into Robby in turn, and then run that strategy in a series of randomly generated arrangements of cans ("environments").  We score Robby on how well he does in each environment. If Robby hits a wall, he loses 5 points. If he successfully picks up a can, he gains 10 points. If he tries to pick up a can, but there isn't one there, he loses 1 point.  Robby's average score across all these environments is taken as the "fitness" of that strategy.

Once we have measured the fitness of the current pool of strategies, we construct the next generation of strategies.  Each new strategy has two parents.  We pick the first parent by picking 15 random candidate parents, then choose the one with the highest fitness.  We repeat this to pick the second parent. Each pair of parents creates two new children via crossover and mutation (see below).  We keep repeating this process until we have enough new children to fill up the population (settable by the POPULATION-SIZE slider).   This "generation" of new children replaces the previous generation.  We then similarly calculate the fitness of the current generation, choose parents, and create a new generation.  This process continues as long as the GO button is pressed, or is controlled by the NUMBER-OF-GENERATIONS slider when the GO-N-GENERATIONS button is pressed.

To combine the strategies of two parents, we use "crossover".  We pick a random crossover point and combine the first part of the first parent's strategy with the second part of the other's parent's strategy.  For example, if the crossover point selected is 50, we use the first 50 entries of the first parent's strategy and the last 193 entries of the second parent's strategy.  (Each strategy is in a fixed order.)

In addition to crossover, the children's strategies are subject to occasional random mutation (settable by the MUTATION-RATE slider), in which an action is replaced by a randomly chosen action.

## HOW TO USE IT

Press SETUP to create the initial pool of random strategies.  Press GO-FOREVER to start the genetic algorithm running, or GO-N-GENERATIONS to run the genetic algorithm for a fixed number of generations (settable by the NUMBER-OF-GENERATIONS slider).

In the view, you'll see the pool of strategies (represented by "person" icons). The strategies are heterogeneous. The diversity in their fitness is visualized by color and position on the x-axis.  Their color is a shade of red, scaled by their fitness. It's  lightest when the fitness is low and darkest when it's high. In addition, the fitness of a strategy determines where it is along the x-axis, with the least fit strategies on the left, and the fittest strategies on the right.

Another aspect of diversity is the difference between the strategies. This difference is measured by counting the frequency of each of the 7 basic actions in the strategy (the "allele-diversity"), forming a 7 dimensional vector and then calculating the Euclidean distance between two such vectors.  One of the strategies with the highest fitness is placed in the center of the y-axis. The other strategies are placed at locations whose distance from the center along the y-axis is proportional to the difference between their strategy and the winning strategy.

All of this takes a fair amount of time to show, so for long runs of the GA you'll want to move the speed slider to the right or uncheck the "view updates" checkbox to get results faster.

Any time you want to pause the algorithm and see how the current best strategy behaves, press GO-FOREVER and wait for the current generation to finish.  Re-check "view updates" if you unchecked it before.  Next, press VIEW-ROBBY'S-ENVIRONMENT.  This displays the grid that Robby moves in, with a new, random distribution of cans.  Then, press STEP-THRU-BEST-STRATEGY.  Each time you press this button, Robby will use the best  strategy from the last generation to take an action in the current environment.  Keep pressing the STEP-THRU-BEST-STRATEGY button to see how the strategy works.  At any time you can press VIEW-ROBBY'S-ENVIRONMENT again to start over with a new environment of cans.  If you want to go back to the "strategy view", press the VIEW-STRATEGIES button.

## THINGS TO NOTICE

Robby's performance gradually improves.  How long does it take to get to a medium or high fitness?

How does Robby typically behave with a totally random strategy?  How does he behave once some evolution has taken place?

Does Robby's performance eventually reach a plateau?  How does he behave with the strategies that ultimately evolve?

On the way to the final plateau, were there ever any temporary plateaus?

## THINGS TO TRY

Vary the settings on the POPULATION-SIZE and MUTATION-RATE sliders.  How do these affect the best fitness in the population as well as the speed of evolution?

## EXTENDING THE MODEL

Add a slider for "crossover rate", the probability that two parents create offspring by crossover.  If they don't crossover, they simply clone themselves (and then the cloned offspring undergo possible mutation).   (You'll need to change the `crossover` procedure.)

Add a slider for the tournament-size. How does varying the tournament-size affect the evolution of Robby’s strategies?

Try different rules for selecting the parents of the next generation. What leads to the fastest evolution? Is there ever a tradeoff between fast evolution at the beginning and how effective the winning strategies are at the end?

Try using spatial contiguity as a factor in selecting which individuals mate.

Try to train Robby to perform a somewhat more difficult task.

## NETLOGO FEATURES

The `run` command is key here.  A chromosome is a list of strings, where each string is a procedure name.  Calling `run` on that string runs the procedure.

To represent strategies compactly, we use Unicode symbols (such as arrows).

To measure the similarity between different strategies, we use the high-level list primitives `map` and `reduce`.

## RELATED MODELS

Simple Genetic Algorithm

## CREDITS AND REFERENCES

Robby was invented by Melanie Mitchell and described in her book _Complexity: A Guided Tour_ (Oxford University Press, 2009), pages 130-142.   Robby was inspired by The "Herbert" robot developed at the MIT Artificial Intelligence Lab in the 1980s.

This NetLogo version of Robby is based on Mitchell's earlier versions in NetLogo and C.
It uses code from the Simple Genetic Algorithms model (Stonedahl & Wilensky, 2008) in the NetLogo Sample Models Library.

Robby resembles a simpler version of Richard E. Pattis' Karel the Robot, https://en.wikipedia.org/wiki/Karel_(programming_language).

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Mitchell, M., Tisue, S. and Wilensky, U. (2012).  NetLogo Robby the Robot model.  http://ccl.northwestern.edu/netlogo/models/RobbytheRobot.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

[![CC0](http://ccl.northwestern.edu/images/creativecommons/zero.png)](https://creativecommons.org/publicdomain/zero/1.0/)

Public Domain: To the extent possible under law, Uri Wilensky has waived all copyright and related or neighboring rights to this model.

<!-- 2012 CC0 Cite: Mitchell, M., Tisue, S. -->
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
Rectangle -7500403 true true 5 4 294 295

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
setup repeat 5 [ go ]
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
0
@#$#@#$#@
