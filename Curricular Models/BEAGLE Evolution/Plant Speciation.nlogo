turtles-own [ tolerance fitness flower-time seedling? will-die? ]
patches-own [ metal barrier? ]

globals [
   day                             ;; monitor value
   year                            ;; current year
   old-year                        ;; previous year
   end-of-days-counter             ;;
   transition-time?                ;;
   old-visualize-time-steps-state  ;; allows for switching between visualization modes during model run
   chance-death-per-year           ;; the probability that the plant will die this year
   chance-seed-dispersal           ;; the probability that a newborn plant grows in a patch adjacent to its parents', instead of in the same patch.
   average-number-offspring        ;; avg. number of seeds dispersed by the plant when it does disperse them
   percent-same-flowering-time
]

to setup
  clear-all
  ;; initialize globals
  set day 0
  set old-year 0
  set year 0
  set end-of-days-counter 0
  set percent-same-flowering-time 0
  set chance-death-per-year 10 ;; set to 10% by default
  set chance-seed-dispersal 50 ;; set to 50% by default
  set average-number-offspring 3
  set transition-time? false
  set old-visualize-time-steps-state visualize-time-steps

  ;color the frontier
  ask patches [
    set barrier? false
    setup-two-regions
    set pcolor calc-patch-color metal
  ]

  ;spawn the initial population -- carrying-capacity-per-patch allows more than plant at this patch
  ask patches with [pxcor = min-pxcor] [
    sprout plants-per-patch [
      if initial-tolerance = "all no tolerance" [set tolerance 0]
      if initial-tolerance = "all full tolerance" [set tolerance 100]
      if initial-tolerance = "random tolerances" [set tolerance random-float 100]
      set flower-time (365 / 2)
      set heading random 360
      fd random-float .5
      set fitness 1
      set shape "plant"
      set seedling? false
      set will-die? false
      set color calc-plant-color tolerance
    ]
  ]
  reset-ticks
end


to setup-two-regions
  ;; set the metal value based on the width designated by the frontier-sharpness slider value
  set metal precision (100 / (1 + exp (frontier-sharpness * ((max-pxcor + min-pxcor) / 2 - pxcor)))) 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; RUNTIME PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
   check-labels
   ;; if visualization switched during model run, redraw plants
   if old-visualize-time-steps-state != visualize-time-steps [
     ask turtles [
       redraw-plants-as-full-sized-plants
     ]
   ]

  if visualize-time-steps = "years" [
    set day 0 ;; always at day 0 in years mode
    set year year + 1
    ask turtles [ redraw-plants-as-full-sized-plants  ]
    do-start-of-new-year-events
  ]

  if visualize-time-steps = "days" [
    visualize-bloom
    do-end-of-days-events
  ]
  tick
end

to do-start-of-new-year-events
  if year > old-year [
    do-reproduction
    mark-turtles-to-kill
    kill-marked-turtles
    set old-year year
  ]
end

to do-end-of-days-events
  ifelse day = 365 [  ;; at end of year
    if transition-time? = false  [
      do-reproduction
      mark-turtles-to-kill
      set transition-time? true
    ]
    ;; 10 ticks of transition time will elapse between years when visualize-time-steps is in "day" mode
    ;; this transition time is for animation events to show death and growth of new plants before the next
    ;; year begins. It is done before day 0 of the new year so that these visualizations do not interfere
    ;; with flower time speciation mechanisms in the model

    if transition-time? [
      set end-of-days-counter end-of-days-counter + 1
      ;; grow the new plants to be visible for the next season
      ask turtles with [seedling?] [visualize-seedling-growth]
      ;; shrink and fade the plants that are going to die
      ask turtles with [will-die?] [set size (1 - (end-of-days-counter / 10))]

      if end-of-days-counter > 9 [  ;; start a new year
        set year year + 1
        set end-of-days-counter 0
        set transition-time? false
        set day 0
        ask turtles [turn-seedlings-into-full-plants]
        kill-marked-turtles
      ]
    ]
  ]

  ;; the else event
  [set day day + 1]
end

;; make babies
to do-reproduction
  ask turtles [
    ;; construct list of potential mates based on pollen-radius slider
    let potential-mates []
    let nearby-turtles turtles
    if (pollen-radius < (max-pxcor - min-pxcor)) [set nearby-turtles turtles in-radius pollen-radius]
    let num-candidates 10
    ifelse count nearby-turtles < 10 [ set potential-mates (sort nearby-turtles) ]
                                     [ set potential-mates (sort (n-of 10 nearby-turtles))
                                       set potential-mates (fput self potential-mates)]

    ;; pick mate randomly weighted by compatibility
    let compatibilities map [ potential-mate -> compatibility self potential-mate] potential-mates
    let mate (pick-weighted (potential-mates) (compatibilities))

    ;; spawn children
    hatch (random-poisson average-number-offspring) [
      set seedling? true
      set will-die? false
      ifelse visualize-time-steps = "days" [ set size 0.0] [set size 1.0]

      ;combine parents' genes and give average value of to the child
      if genetics-model = "avg. genotype" [
        set tolerance (tolerance + [tolerance] of mate) / 2
        set flower-time (flower-time + [flower-time] of mate) / 2
      ]

      ;mutate tolerance gene
      if (random-float 100) < chance-tolerance-mutation [
        set tolerance (tolerance + (random-normal 0 tolerance-mutation-stdev))
      ;; set tolerance (tolerance + random tolerance-mutation - random tolerance-mutation)
      ]

      ;mutate flowering time gene
      if (random-float 100) < chance-flower-time-mutation [
        set flower-time (flower-time + (random-normal 0 flower-time-mutation-stdev))
      ]

      ;; keeps values from going above a min and max
      if tolerance < 0 [ set tolerance  0 ]
      if tolerance > 100 [ set tolerance 100 ]
      if flower-time < 0 [ set flower-time 0 ]
      if flower-time > 365 [ set flower-time 365 ]

      ;change color to reflect metal tolerance
      set color calc-plant-color tolerance
      migrate-this-plant
    ]

   if plant-type = "annual" [set will-die? true] ;end of the generation
  ]
end

;kill ill-adapted turtles and fix solve overpopulation
to mark-turtles-to-kill
  ask turtles [
    let t tolerance / 100
    let m metal / 100
    ;; Fitness is a linear function dependent on tolerance whose slope and y-intercept
    ;; vary linearly with respect to an increases in metal amount.
    ;; This linear function would have the following slopes in various metal levels:
    ;; (i.e. negative slope in clean ground -> high tolerance is bad
    ;;       positive slope in dirty ground -> high tolerance is good
    ;;       zero     slope in between      -> no benefit or disadvantage to any level of tolerance )

    ;; This is a model of a "tradeoff", where specializing in one variation of trait is advantageous
    ;; in one environmental extreme, but specializing in another variation of the trait is advantageous in a different
    ;; environmental extreme. Intermediate "hybridization" or averaging between both variations is disadvantageous
    ;; in both environments or at the very least it is not advantageous in either extreme environment.
    ;; Such tradeoff models can lead to speciation when other traits permit a population to reproductively
    ;; fragment and isolate itself into non-interbreeding sub populations.

    ;; This makes for a hyperbolic paraboloid or saddle shaped function that is dependent on metal amount and
    ;; tolerance.  A general form of this fitness function would be the following:
    ;; set fitness ((1 +  (A * t * m + B * t * m - C * t * m) - ( A * t + B * m) ) )
    ;; where fitness is 1 at clean ground and no tolerance
    ;; A is the penalty (0 to 1) for having tolerance in clean ground, therefore fitness is (1 - A)
    ;; B is the penalty (0 to 1) for having the highest level of metal in the ground and no tolerance, therefore fitness is (1 - B)
    ;; C is the penalty (0 to 1) for having the highest tolerance in the highest level of metal, therefore fitness is (1 - C)
    ;; As long as C is less than both B and A, then you will have a fitness function that can be used in this section
    ;; The fitness function has been hard coded here to use A = .4 and B = .4 and C = 0

       set fitness (1 - m) * (1 - .4 * t) + m * (1 - .4 * (1 - t))

    ;; survival probability based on fitness
    if (random-float 1) > (fitness) [set will-die? true]
    ;; survival probability based on fixed number of additional deaths-a-year
    if random-float 100 < chance-death-per-year [set will-die? true]
  ]

  ;; In overpopulated patches, kill the least fit plant until we are down to the carrying capacity
  ask patches [
    let overpopulation ((count turtles-here) - plants-per-patch)
    if overpopulation > 0 [
      ask (min-n-of overpopulation turtles-here [fitness]) [
        set will-die? true
      ]
    ]
  ]
end

to migrate-this-plant ;; turtle procedure
  ;; Some plants grow in patch adjacent to the parent plant. This represents migration from seed dispersal
  if (random-float 100) < chance-seed-dispersal [
    move-to one-of neighbors
    rt random 360  fd random-float 0.45  ;;spread out plants that are on the same patch
  ]
end

to kill-marked-turtles
    ask turtles with [will-die?] [die]
end

to turn-seedlings-into-full-plants
         if seedling? [set seedling? false]
         redraw-plants-as-full-sized-plants
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; visualization procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to check-labels
  ask patches [
  ifelse show-labels-as = "metal in soil"
    [set plabel metal]
    [set plabel ""]
  ]
  ask turtles [
    if show-labels-as = "metal tolerance" [set label precision tolerance 0]
    if show-labels-as = "flower time"  [set label precision flower-time 0 ]
    if show-labels-as = "none" [set label ""]
  ]
end

to redraw-plants-as-full-sized-plants ;; turtle procedure
  set shape "plant"
  set size 1
end

to visualize-seedling-growth ;; turtle procedure
  if seedling? [set size (end-of-days-counter / 10) ]
end

to visualize-bloom
  ask turtles [
    ;; If day of the year is greater than this plants flower time and less than the flower time plus the length of flower time, then it is in the
    ;; the flowering time window and a flower should be located here
    ifelse day >= (flower-time  ) and day <= (flower-time + (flower-duration)  )
       [ set shape "flower"]
       [ set shape "plant" ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;; reporters  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; make a random choice from <options> weighted by <weights>
;; where highly weighted choices are more likely to be selected than others
to-report pick-weighted [ options weights ]
  let wsum 0
  foreach weights [ weight ->
    set wsum (wsum + weight)
  ]
  let wret wsum * (random-float 1)
  let ret 0
  set wsum 0
  foreach weights [ weight ->
    set wsum (wsum + weight)
    if wsum > wret [ report (item ret options) ]
    set ret (ret + 1)
  ]
end

;; compatibility is a decreasing function of the difference in flowering times
;; since plants that have more of an overlap between flower-times are more likely
;; they will pollinate one another
to-report compatibility [ t1 t2 ]
  let diff abs ([flower-time] of t1 - [flower-time] of t2)
  ifelse diff < flower-duration [ report (flower-duration - diff) ] [ report 0 ]
end

;; calculate the patch color based on the presence of metal in the soil
to-report calc-patch-color [ m ]
  report rgb 0 (255 * (1 - (m / 100)) / 2) (255 * (m / 100) / 2)
end

to-report calc-plant-color [ t ]
  let black-pcolor rgb 0 0 0
  ifelse barrier?
    [report black-pcolor]
    [report rgb 0 (255 * (1 - (t / 100)) ) (255 * (t / 100) )]
end


; Copyright 2012 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
512
10
1196
279
-1
-1
26.0
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
25
0
9
1
1
1
ticks
30.0

BUTTON
8
10
71
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
74
10
163
43
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
385
308
587
341
chance-tolerance-mutation
chance-tolerance-mutation
0
100
10.0
1
1
%
HORIZONTAL

SLIDER
385
342
587
375
tolerance-mutation-stdev
tolerance-mutation-stdev
0
50
20.0
1
1
NIL
HORIZONTAL

PLOT
345
60
510
180
tolerances
metal tolerance
#
0.0
110.0
0.0
50.0
true
false
"" ""
PENS
"left" 5.0 1 -10899396 true "" "histogram [tolerance] of turtles with [xcor < (min-pxcor + max-pxcor) / 2]"
"right" 5.0 1 -13345367 true "" "histogram [tolerance] of turtles with [xcor > (min-pxcor + max-pxcor) / 2]"

SLIDER
9
273
161
306
plants-per-patch
plants-per-patch
1
5
2.0
1
1
NIL
HORIZONTAL

SLIDER
9
241
162
274
frontier-sharpness
frontier-sharpness
.1
2
1.0
.1
1
NIL
HORIZONTAL

PLOT
167
60
345
180
flower-times
flowering time
#
0.0
380.0
0.0
10.0
true
false
"" ""
PENS
"left" 15.0 1 -10899396 true "" "histogram [flower-time ] of turtles with [xcor < (min-pxcor + max-pxcor) / 2]"
"right" 15.0 1 -13345367 true "" "histogram [flower-time ] of turtles with [xcor > (min-pxcor + max-pxcor) / 2]"

SLIDER
167
307
381
340
chance-flower-time-mutation
chance-flower-time-mutation
0
100
10.0
1
1
%
HORIZONTAL

SLIDER
168
342
380
375
flower-time-mutation-stdev
flower-time-mutation-stdev
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
8
307
162
340
pollen-radius
pollen-radius
0
50
30.0
1
1
NIL
HORIZONTAL

PLOT
345
179
510
299
avg. tolerance
generations
tolerance
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"left" 1.0 0 -10899396 true "" "if any? turtles with [ xcor < (min-pxcor + max-pxcor) / 2] [\n  plotxy year (mean [tolerance] of turtles with [xcor < (min-pxcor + max-pxcor) / 2])\n  ]"
"right" 1.0 0 -13345367 true "" "if any? turtles with [ xcor > (min-pxcor + max-pxcor) / 2] [\n  plotxy year (mean [tolerance] of turtles with [xcor > (min-pxcor + max-pxcor) / 2])\n  ]"

PLOT
167
180
346
300
simultaneous flowering
generations
%
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if any? turtles with [ xcor > (min-pxcor + max-pxcor) / 2] and any? turtles with [ xcor < (min-pxcor + max-pxcor) / 2]  [\n  let n 0\n  let m 0\n  let avg mean [tolerance] of turtles\n  repeat 500 [\n    let r one-of turtles with [xcor > (min-pxcor + max-pxcor) / 2]\n    let s one-of turtles with [xcor < (min-pxcor + max-pxcor) / 2]\n    if ( abs ([flower-time] of r - [flower-time] of s) < flower-duration ) [ set m (m + 1) ]\n    set n (n + 1)\n  ]\n  set percent-same-flowering-time precision ((m / n) * 100) 1\n  plotxy year (m / n) * 100\n]"

SLIDER
8
342
163
375
flower-duration
flower-duration
0
30
20.0
1
1
days
HORIZONTAL

MONITOR
318
10
375
55
NIL
day
1
1
11

MONITOR
372
10
474
55
years
year
17
1
11

CHOOSER
12
187
158
232
show-labels-as
show-labels-as
"none" "metal in soil" "metal tolerance" "flower time"
0

CHOOSER
164
10
315
55
visualize-time-steps
visualize-time-steps
"days" "years"
1

CHOOSER
11
49
157
94
plant-type
plant-type
"perennial" "annual"
1

CHOOSER
11
95
158
140
initial-tolerance
initial-tolerance
"all no tolerance" "all full tolerance" "random tolerances"
0

CHOOSER
11
141
158
186
genetics-model
genetics-model
"avg. genotype" "sex linked genes"
0

@#$#@#$#@
## WHAT IS IT?

This is a model of parapatric speciation, where two subpopulations of a species split into two non-interbreeding species while still remaining in contact with each other. This is in contrast to allopatric speciation, where two geographically separated subpopulations of a species diverge into two separate species. The specific situation modeled is that of the speciation of a metal-tolerant variety of plant on the boundary between clean and contaminated ground.

The model is inspired by a paper by Antonovics (2006) which describes a real-life example of a subpopulation of a species of grass on the boundary of a contaminated region that has developed an offset flowering time from the surrounding grass.

For a short relevant background reading try https://en.wikipedia.org/wiki/Speciation

## HOW IT WORKS

The model simulates individual plant organisms that inhabit a rectangular grid of patches. Each tick, the model simulates either one day in a year of a plant or one year (a complete generation of plant life): the currently existing plants fertilize each other, produce offspring, and may die (depending if the plants are set to be annual or perennial plants).

The environment the plants inhabited has two zones: the left zone (green) is normal earth, but the right zone (blue) is contaminated with metals from a nearby mine. The initial population can live there but has little tolerance for metals and prefers the clean zone on the left. Tolerance for metals is a heritable attribute that can change via mutation and recombination over the generations. Plants with a low tolerance for metals are best suited to live on the left side of the environment, and those with a high tolerance are best suited to live on the right side.

Plants also have a flowering time, which determines which other plants the plant can fertilize and be fertilized by. Plants that do not flower during any of the same days of the year cannot fertilize each other.  Plants that flower on more of the same days have a better chance of fertilizing each other than plants that flower on less of the same days.  While plants can fertilize themselves, only plants within a certain radius can fertilize each other.

Metal tolerance and flowering time are represented as real numbers; metal tolerance is always between 0.0 (very low tolerance) and 1.0 (very high tolerance).

The key mechanism that drives speciation to emerge in this model is a fitness function. This fitness function (f) is dependent on metal in the ground (m) and tolerance of the plant to metal (t).  Metal tolerance slows plant growth down in healthy soil, but allows it to survive and grow in soil with heavy metal concentrations.

Fitness is a hyperbolic paraboloid function that can be visualized as a linear function dependent on tolerance whose slope and y-intercept also vary linearly with respect to increases in metal in the soil.  This linear function would have the following slopes in various metal levels:

  - negative slope in clean ground -> high tolerance is bad
  - positive slope in dirty ground -> high tolerance is good
  - slope of zero: in between -> no benefit or disadvantage to any tolerance level

This is a model of a "tradeoff", where specializing in one variation of a trait is advantageous in one environmental extreme, but specializing in another variation of the trait is advantageous in a different environmental extreme. Intermediate "hybridization," or averaging between both variations, is disadvantageous in both environments or at least not advantageous in any.  Such tradeoff models can lead to speciation when other traits permit a population to reproductively fragment and isolate itself into non-interbreeding sub populations.

The hyperbolic paraboloid or saddle shaped function that is used in the model is dependent on metal amount and tolerance.  A general form of this fitness function would be the following:
  fitness =  (1 +  (A * t * m + B * t * m - C * t * m) - ( A * t + B * m) )

  - where fitness is 1 at clean ground and no tolerance
  - A is the penalty (0 to 1) for having tolerance in clean ground: so fitness is (1 - A)
  - B is the penalty (0 to 1) for having the highest level of metal in the ground and no tolerance, so  fitness is (1 - B)
  - C is the penalty (0 to 1) for having the highest tolerance in the highest level of metal, so fitness is (1 - C)

As long as C is less than both B and A, then you will have a fitness function that may drive the emergence of speciation. The fitness function has been hard coded in the model to use A = .4 and B = .4 and C = 0 :

       set fitness (1 - m) * (1 - .4 * t) + m * (1 - .4 * (1 - t))

## HOW TO USE IT

PLANT-TYPE: When set to "annual", all old plants die at the end of the year. "Perennial" allows some old plants to remain behind to re-flower the next year.

VISUALIZE-TIME-STEPS: This can be set to "days" so that the flowering of the plants can be visualized during the year and the growth of seedlings and death of old plants can be visualized at the end of the year.  When set to "years" the model skips these visualizations and runs much quicker.

GENETICS-MODEL: Allows you to change the recombination rules for sexual reproduction.  If set to "avg. genotype", the parent genotypes are averaged in the offspring.  This is a simplification of hybridization outcomes. Speciation should be more difficult to achieve at this setting since variation is removed more readily than using Mendelian genetics models (that retain variation in genotype over many generations through recessive alleles).  However, speciation can still emerge at this setting.  If set to "sex linked genes" the genotype is inherited from the male (pollen) only.

SHOW-LABELS-AS: Shows the value for "metal in soil" for each patch, the "metal tolerance" for each plants", or the "flowering time" for each plant.

FRONTIER-SHARPNESS: Controls the width of the gradient between the clean and contaminated sides of the environment.

FLOWER-DURATION: This slider determines how long a flower is open--two plants whose flowering times are separated by more than this margin cannot fertilize each other. Even when two plants flower close enough together to fertilize each other, fertilization is less likely the larger the difference in flowering time.

PLANTS-PER-PATCH: The maximum number of plants that can live on the same patch. If there are too many plants in a patch those least fitted to the local metal concentrations will die.

CHANCE-TOLERANCE-MUTATION, CHANCE-FLOWER-TIME-MUTATION, FLOWER-TIME-MUTATION-STDEV, AND TOLERANCE-MUTATION-STDEV:  These sliders control the probability and magnitude of mutations in metal tolerance and flowering time.



There are a variety of plots. The histograms show the distribution of metal tolerance and flowering time for plants on the left and right side of the environment. Graphs on the right show the mean tolerance and flowering time for the left and right sides of the environment over time. The "simultaneous flowering" graph shows the probability that a randomly chosen plant from the left flowers at the same time as a randomly chosen plant from the right--that is, the probability that they can fertilize each other. If this nears 0 speciation has occurred--the left and right sides are no longer interbreeding. Though the model only rarely reaches this value as 0, it does often achieve stable states very close to 0, showing that the first step in speciation has been achieved -- that a population has split into two sub-populations that are co-evolving behavior to reinforce sexual isolation from one another.

## THINGS TO NOTICE

The simplest case is to turn off all recombination and run the model with the default settings.  Notice that metal tolerance mutations will accumulate in a few individuals before simultaneous flower time begins to drop.  Speciation (sexual isolation) emerges after specialization of the population into two groups, to decrease gene flow between the groups and further increase odds of survival for offspring.

When the whole population interbreeds there is a homogenizing force that keeps the plants on the right from becoming too metal tolerant--their genes are constantly diluted by genes from the intolerant left-side plants. Eventually, there will be a runaway effect where the left and right sides develop somewhat different flowering times (due to genetic drift), which decreases the flow of genes between the sides allowing the right to develop higher metal tolerance. This makes it increasingly disadvantageous to breed with left-side plants, creating selection pressure to increase the difference in flowering times further until the left and right are completely non-interbreeding and thus might be called separate species--this is called "reproductive isolation", the last step of speciation.

## THINGS TO TRY

If you decide to run the model with plants as annuals, decrease the DEATH-PER-YEAR (to around 10%) so that enough plants (including seedlings) are alive for the next generation, and increase the DEATH-PER-YEAR value if running with plants as perennials (so that old plants die off more readily and don't remain in ground blocking out new arrivals).

If you change the FRONTIER-SHARPNESS to make a more gradual shift in metal concentrations between the left and right sides of the environment, speciation will still emerge.

Sometimes flower-times for one population become isolated between two sub-groups in the other population, making for 3 effectively non-interbreeding sub-populations.  This shows how one speciation event can fragment the reproductive compatibility of the other population leading to even more possible species.

Because of what is described above, parapatric speciation (in which two budding species continue to exchange genes as they diverge) is a rare form of speciation. More commonly accepted is the idea of allopatric speciation, which avoids these difficulties by positing that species arise when two subpopulations are separated completely, so that they cannot exchange genes and there is no homogenizing force preventing them from developing reproductive isolation. However, the process observed in the model where partial reproductive isolation allows increased differentiation due to selection, which in turn encourages more complete reproductive isolation, is often held to "reinforce" allopatric speciation when the two separated subpopulations come back into contact with each other.

Playing with the other parameters of the model can alter the details of what happens; in particular the flow of genes between the sides is affected by fertilization-radius and flower-duration in proportion to the world size.

## EXTENDING THE MODEL

Allopatric speciation could be modeled by introducing physical barriers into the environment.

## NETLOGO FEATURES

Complex plotting procedures:  The histograms plot the populations of two regions each with a different color pen.

## RELATED MODELS

All the models from the BEAGLE curriculum.

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

Antonovics, J. (2006). "Evolution in closely adjacent plant populations X: long-term persistence of reproductive isolation at a mine boundary". Heredity, 97(1), p33-37.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M., McGlynn, G. and Wilensky, U. (2012).  NetLogo Plant Speciation model.  http://ccl.northwestern.edu/netlogo/models/PlantSpeciation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2012 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2012 Cite: Novak, M., McGlynn, G. -->
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
6
Line -13840069 true 84 255 146 267
Line -13840069 true 123 241 136 264
Line -13840069 true 121 193 152 202
Line -13840069 true 150 225 180 210
Line -13840069 true 180 210 204 160
Line -13840069 true 186 199 223 196
Line -13840069 true 171 214 224 226
Line -13840069 true 151 277 200 254
Line -13840069 true 122 192 85 168
Line -13840069 true 138 199 114 147
Line -13840069 true 122 240 94 221
Line -13840069 true 146 303 151 228
Line -13840069 true 152 224 150 105
Circle -1184463 true false 103 73 32
Circle -1184463 true false 133 103 32
Circle -1184463 true false 133 43 32
Circle -1184463 true false 163 73 32
Circle -1184463 true false 116 53 32
Circle -1184463 true false 152 53 32
Circle -1184463 true false 153 91 32
Circle -1184463 true false 115 91 32
Circle -16777216 true false 135 75 30

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
6
Line -13840069 true 84 255 146 267
Line -13840069 true 123 241 136 264
Line -13840069 true 121 193 152 202
Line -13840069 true 150 225 180 210
Line -13840069 true 180 210 204 160
Line -13840069 true 186 199 223 196
Line -13840069 true 171 214 224 226
Line -13840069 true 151 277 200 254
Line -13840069 true 122 192 85 168
Line -13840069 true 138 199 114 147
Line -13840069 true 122 240 94 221
Line -13840069 true 146 303 151 228
Line -13840069 true 152 224 150 105

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
0
@#$#@#$#@
