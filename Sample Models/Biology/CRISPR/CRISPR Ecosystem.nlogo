globals [
  food-color                     ; Color of food.
  bacteria-color                 ; Color of bacteria.
  virus-color                    ; Color of viruses.
  bacteria-size                  ; Size of bacteria, also virus scale factor.

  sprout-delay-time              ; Time for food to regrow after being consumed.
  max-food-energy                ; Max amount of food energy per patch.
  min-reproduce-energy           ; Min energy required for bacteria to reproduce.

  food-growth-rate               ; How fast food is replenished on average.
  food-bacteria-eat              ; Amount of food bacteria eat each time step.
  regrowth-variability           ; Adjusts regrowth rates (see replenish-food).

  virus-replication-rate         ; Number of viruses created in a lytic cycle.

  virus-history                  ; Required for plot housekeeping.
                                 ; This can be removed if 1) a primitive to get all
                                 ; current plot pens as a list is added, or 2) a
                                 ; way to remove temporary plot pens without also
                                 ; clearing the plot or that pen's trail is added.
  plot-virus                     ; Required for clean switching on coevolution plot.
]

breed [ foods food ]
breed [ bacteria bacterium ]
breed [ viruses virus ]

viruses-own [ sequence ]
bacteria-own [ energy array ]

patches-own [ food-energy countdown ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETUP PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  set food-color     [90 140 90 150]
  set bacteria-color  orange
  set virus-color     violet

  set-default-shape bacteria "bacteria"
  set-default-shape viruses  "virus"
  set-default-shape foods    "food"

  set bacteria-size 1

  set min-reproduce-energy 100
  set sprout-delay-time 25
  set max-food-energy 100
  set food-bacteria-eat 25
  set food-growth-rate 25
  set regrowth-variability 1

  set virus-replication-rate 20

  setup-world
  setup-virus-plot
  reset-ticks
end

to setup-world
  ask patches [
    set food-energy max-food-energy / 2
    set countdown 0
    ; Make patches blue (water colored) and hatch food in water spots
    set pcolor [180 200 230]
    sprout-foods 1 [ set color food-color ]
  ]

  ask patches [ grow-food ]

  create-bacteria initial-bacteria [
    set size bacteria-size
    set color bacteria-color
    set energy random-normal (min-reproduce-energy / 2) (min-reproduce-energy / 10)
    set array []
    random-position
  ]
  create-viruses initial-viruses [
    set size bacteria-size / 2
    set color virus-color
    set sequence random max-virus-types
    random-position
  ]
end

to random-position
  setxy (min-pxcor + random-float (max-pxcor * 2))
        (min-pycor + random-float (max-pycor * 2))
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; RUNTIME PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  if count bacteria < 1 [ stop ]
  if count viruses < 1 [ stop ]
  bacteria-live
  viruses-live
  ask patches [ replenish-food ]
  update-virus-plot
  tick
end

;----------------------------- BACTERIA PROCEDURES -----------------------------

to bacteria-live
  ask bacteria [
    move-bacteria
    bacteria-eat-food
    reproduce-bacteria
    spacer-loss
    if (energy <= 0 ) [ die ]
  ]
end

to move-bacteria ; Bacteria procedure
  set energy (energy - 1)  ; Bacteria lose energy as they move
  rt random-float 90
  lt random-float 90
  fd 0.25  ; The lower the speed, the less severe the population oscillations are.
end

to bacteria-eat-food ; Bacteria procedure
  ; If there is enough food on this patch, the bacteria eat it and gain energy.
  if food-energy > food-bacteria-eat [
    ; Bacteria gain 1/5 the energy of the food they eat (trophic level assumption)
    set food-energy (food-energy - food-bacteria-eat)
    set energy energy + food-bacteria-eat / 5  ; bacteria gain energy by eating
  ]
  ; If all the food is consumed in a patch, set the countdown timer
  ; to delay when the food will grow back in this patch.
  if food-energy <= food-bacteria-eat [ set countdown sprout-delay-time ]
end

to reproduce-bacteria ; Bacteria procedure
 if (energy >  min-reproduce-energy) [
    set energy (energy / 2)  ; Parent keeps half the cell's energy
    ; Variable inheritance gives the daughter half the cell's energy too
    hatch 1 [
      rt random 360
      fd 0.25
    ]
  ]
end

to spacer-loss ; Bacteria procedure
  if not empty? array and random-float 100 < spacer-loss-chance [
    ; Spacers loss is FIFO and we add to the front of the array.
    set array but-last array
  ]
end

;------------------------------ VIRUS PROCEDURES -------------------------------

to viruses-live
  ask viruses [
    move-virus
    infect
    maybe-degrade
  ]
end

to move-virus
  rt random-float 90
  lt random-float 90
  fd 0.10
end

to infect
  let target one-of bacteria-here
  if (target != nobody) and (random-float 100 < infection-chance) [
    ifelse crispr? [
      ; If the bacteria have functioning CRISPR systems...
      ifelse member? sequence ([ array ] of target) [
        ; If the bacterium has the viral sequence in its CRISPR array,
        ; there is a very large chance that the virus dies.
        let succeed-chance 8 ; % chance the virus kills the bacterium and replicates
        let degrade-chance 83 ; % chance the virus gets cleaved or degraded
        let add-chance 9     ; % chance the virus gets caught and added to the array
        let random-roll random-float (succeed-chance + degrade-chance + add-chance)
        (ifelse
          ; Sometimes the virus will successfully reproduce.
          random-roll < succeed-chance [ replicate target ]
          ; Sometimes the bacterium will catch the virus and degrade it.
          random-roll < succeed-chance + degrade-chance [ die ]
          [ ask target [ set array fput [sequence] of myself array ] die ])
      ] [
        ; If the virus isn't in the CRISPR array, it can still get caught.
        ; New chances after reducing dimer production:
        let succeed-chance 30 ; % chance the virus kills the bacterium and replicates
        let degrade-chance 55 ; % chance the virus gets cleaved or degraded
        let add-chance 15     ; % chance the virus gets caught and added to the array
        let random-roll random-float (succeed-chance + degrade-chance + add-chance)
        (ifelse
          ; Sometimes the virus will successfully reproduce.
          random-roll < succeed-chance [ replicate target ]
          ; Sometimes the bacterium will catch the virus and degrade it.
          random-roll < succeed-chance + degrade-chance [ die ]
          [ ask target [ set array fput [sequence] of myself array ] die ])
      ]
    ] [
      ; If the bacteria do not have functioning CRISPR systems, the bacteria
      ; still have non-specific antiviral defenses that may help.
      let succeed-chance 50 ; % chance the virus kills the bacterium and replicates
      let degrade-chance 50 ; % chance the virus gets cleaved or degraded
      let random-roll random-float (succeed-chance + degrade-chance)
      (ifelse
        ; Sometimes the bacterium will catch the virus and degrade it.
        random-roll < degrade-chance [ die ] [ replicate target ])
    ]
  ]
end

to replicate [ host ]
  ask host [ die ]
  ; Small chance viruses will mutate when they replicate
  ; As long as sequence is a random int, there is a ~5% chance of mutation
  if random-float 1 < 0.05 [ set sequence random max-virus-types ]
  ; Since the initial virus doesn't die in the model but would IRL, subtract 1.
  hatch virus-replication-rate - 1
end


to maybe-degrade
  if random-float 100 < 1 [ die ]
end

;------------------------------ FOOD PROCEDURES -------------------------------

; Food replenishes every time step (e.g. photosynthesis, etc.)
to replenish-food
  ; To change resource restoration variability do the following:
  ; In setup, set regrowth-variability n
  ; - 1/n chance to regrow this tick
  ; - n times as much regrowth as normal when it happens
  set countdown (countdown - 1)
  ; Fertile patches gain 1 energy unit per turn, up to max-food-energy threshold
  if countdown <= 0 and random regrowth-variability = 0 [
    set food-energy (food-energy + food-growth-rate * regrowth-variability / 10)
    if food-energy > max-food-energy [ set food-energy max-food-energy ]
  ]
  if food-energy < 0 [
    set food-energy 0
    set countdown sprout-delay-time
  ]
  grow-food
end

; Adjust the size of the food to reflect how much food is in that patch
to grow-food
  ask foods-here [
    ifelse food-energy >= 5 [
      set size (food-energy / max-food-energy)
    ] [
      set size (5 / max-food-energy)
    ]
  ]
end

;------------------------------ PLOT PROCEDURES --------------------------------

to setup-virus-plot ; Observer procedure
  set plot-virus plotted-virus
  set-current-plot "Virus Relative Abundance"
  ; Record each existing virus type.
  set virus-history remove-duplicates [sequence] of viruses
  ; Create pens for each existing virus type.
  foreach virus-history [ seq ->
    ; Cast the sequence to a string and use that as the pen's name.
    create-temporary-plot-pen word seq ""
    set-plot-pen-color one-of base-colors + one-of [-2 0 2]
    plotxy 0 (100 * (count viruses with [sequence = seq]) / (max list 1 count viruses))
  ]
end

to update-virus-plot
  set-current-plot "Virus Relative Abundance"
  ; Record any new viruses that may have arisen from mutation.
  set virus-history remove-duplicates sentence ([sequence] of viruses) virus-history
  foreach virus-history [ seq ->
    ; Cast the sequence to a string and use that as the pen's name.
    let pen-name word seq ""
    ; Switch to that pen if it exists, create a new one if it doesn't.
    ifelse plot-pen-exists? pen-name [
      set-current-plot-pen pen-name
    ] [
      create-temporary-plot-pen pen-name
      set-plot-pen-color one-of base-colors + one-of [-2 0 2]
    ]
    ; After setting the appropriate pen as current, plot the next point.
    plotxy (ticks + 1) (100 * (count viruses with [sequence = seq]) / (max list 1 count viruses))
  ]
end

; Called in the 'Plot update commands' block of the histogram plots.
; Adjusts the x and y ranges of the histogram dynamically based on the input data.
to update-histogram-ranges [ input-list interval ]
  ; If the input list is empty, let the plot use its default ranges.
  ; Otherwise, adjust the plot axis ranges to fit the input data.
  if not empty? input-list [
    ; Adjust the x range to include the whole input data set.
    ; The x range expands with the data, but never contracts.
    let plot-upper-bound max list plot-x-max (interval + max input-list)
    let plot-lower-bound min list plot-x-min min input-list
    set-plot-x-range plot-lower-bound plot-upper-bound

    ; Adjust the y range based on the input data, avoiding constant shifts.
    ; Find the max bar height using the mode(s) of the input data.
    let list-modes-unique modes input-list
    let list-modes-enumerated filter [ i -> member? i list-modes-unique ] input-list
    let max-bar-height (length list-modes-enumerated) / (length list-modes-unique)
    ; The y range should be about 150% of the max bar height, within a tolerance.
    let grow-threshold ceiling (1.05 * max-bar-height)  ; Bar > 95% of the y max
    let shrink-threshold floor (2 * max-bar-height)     ; Bar < 50% of the y max
    if (plot-y-max <= grow-threshold) or (plot-y-max >= shrink-threshold) [
      set-plot-y-range 0 ceiling (1.5 * max-bar-height) ; Bar = 67% of the y max
    ]
  ]
end


; Copyright 2019 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
810
15
1280
486
-1
-1
14.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
100
15
245
48
initial-bacteria
initial-bacteria
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
100
60
245
93
initial-viruses
initial-viruses
0
1000
250.0
10
1
NIL
HORIZONTAL

BUTTON
15
15
90
48
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
15
60
90
93
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
105
265
280
Microbe Populations
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" "; Don't scroll until the end of an autoscale window.\nif ticks > 715\n[\n  ; scroll the range of the plot so\n  ; only the last 715 ticks are visible\n  set-plot-x-range (ticks - 715) ticks\n]"
PENS
"Bacteria" 1.0 0 -955883 true "" "plot count bacteria"
"Viruses" 1.0 0 -8630108 true "" "plot count viruses"

PLOT
15
290
555
485
Virus Relative Abundance
Ticks
% Abundance
0.0
10.0
0.0
10.0
true
false
"" "; Don't scroll until the end of an autoscale window.\nif ticks > 715\n[\n  ; scroll the range of the plot so\n  ; only the last 715 ticks are visible\n  set-plot-x-range (ticks - 715) ticks\n]"
PENS

SLIDER
255
60
400
93
infection-chance
infection-chance
0
10
5.0
0.1
1
%
HORIZONTAL

SLIDER
255
15
400
48
max-virus-types
max-virus-types
1
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
590
255
695
300
Avg. Array Length
mean [length array] of bacteria
2
1
11

PLOT
565
310
800
485
Array Histogram
Array Length
Frequency
0.0
10.0
0.0
10.0
true
false
"" "update-histogram-ranges ([ length array ] of bacteria) 1"
PENS
"default" 1.0 1 -16777216 true "" "histogram [ length array ] of bacteria"

PLOT
275
105
555
280
Sequence Histogram
Sequence ID
Frequency
0.0
10.0
0.0
10.0
true
true
"" "update-histogram-ranges sentence ([sequence] of viruses) (ifelse-value empty? [array] of bacteria [ [] ] [ reduce sentence [array] of bacteria ]) 1"
PENS
"Viruses" 1.0 1 -16777216 true "" "histogram [sequence] of viruses"
"Arrays" 1.0 1 -2674135 true "" "histogram (ifelse-value empty? [array] of bacteria [ [] ] [ reduce sentence [array] of bacteria ])"

SLIDER
410
15
555
48
spacer-loss-chance
spacer-loss-chance
0
2
1.0
0.1
1
%
HORIZONTAL

MONITOR
705
255
780
300
Std. Dev.
standard-deviation [length array] of bacteria
2
1
11

SWITCH
410
60
555
93
crispr?
crispr?
0
1
-1000

PLOT
565
15
800
200
CRISPR-Virus Coevolution
NIL
% Abundance
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Viruses" 1.0 0 -16777216 true "" "plot 100 * (count viruses with [sequence = plot-virus]) / (max list 1 count viruses)"
"Arrays" 1.0 0 -2674135 true "" "let total-arrays reduce sentence [array] of bacteria\nlet virus-instances filter [ i -> i = plot-virus ] total-arrays\nplot 100 * length virus-instances / (max list 1 length total-arrays)"

BUTTON
565
210
660
243
plot-new-virus
set-current-plot \"CRISPR-Virus Coevolution\"\nclear-plot\nset plot-virus plotted-virus
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
670
210
800
243
plotted-virus
plotted-virus
0
max-virus-types - 1
35.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model illustrates the evolutionary dynamics of populations of bacteria and viruses in the presence and absence of CRISPR systems. It can be thought of as a microscope slide with about 5 nanoliters of seawater on it, resulting in a layer about 1 bacterium thick. Viruses greatly outnumber bacteria in this environment, so bacteria must have ways to defend themselves from infection in order to survive. Many bacteria have some innate, nonspecific immunity that can help them defend against viruses, but it is not always effective.

Bacteria were recently found to also employ adaptive immunity in their constant struggle against viruses. This adaptive system is called CRISPR. With it, bacteria are able keep a heritable genetic record of past infection attempts, which makes them and their descendants much more effective at fending off future infections by the same or similar viruses. This is made possible through a system that specifically recognizes the genomes of past viruses using DNA samples called **spacers** stored in a **CRISPR array** and cleaves it using a targeted protein complex.

Because CRISPR systems are very effective at protecting bacteria from viruses they have encountered before, there is high selection pressure on viruses to evade them. CRISPR systems rely on tight matching between the recorded sample in the array and the invading nucleic acid, so viruses are able to avoid recognition through mutations in their genes. Once enough mutations have accumulated, the CRISPR system will no longer recognize the virus until the bacterium gets a new DNA sample. Because viral evolution happens quickly, bacteria and viruses are locked in an evolutionary arms race surrounding bacterial defense systems like CRISPR. This process of evasion and reacquisition results in very interesting coevolutionary dynamics.

## HOW IT WORKS

There are two main types of agents in this model, which are bacteria (visualized as colored ovals) and viruses (visualized as small, spiky balls).

Bacteria wander the world randomly, eating food (visualized as green patches) to gain energy as they move. Bacteria will die if they run out of energy, for example by going too long without encountering food, and they will divide if they accumulate enough energy. When they divide, the two daughter cells each get a copy of the parent cell's CRISPR array. Bacteria also have a small chance on each clock tick to lose a spacer from their array. Spacers in an array are acquired and lost in a 'first in, first out' order, so when bacteria lose spacers they lose the oldest ones first. In real ecosystems, this helps the bacteria focus on the most recent viral threats.

Viruses also wander the world randomly. There is a small chance for them to degrade over time. When they encounter a bacterium, they have a chance to infect it. When they infect a bacterium, there are several possible outcomes. If the infection is successful, the bacterium will die and the virus will reproduce in a burst, creating many new viruses each with a chance for mutation. If the bacterium fights off the infection, either with CRISPR or its innate defenses, then the virus dies. When the bacterium defends itself successfully, there is also a small chance for it to add a spacer recognizing this virus to its CRISPR array.

There are many kinds of virus in the simulation. Each kind of virus has a different DNA sequence, which is what CRISPR systems can use to try to recognize them. If the sequence of a virus is in a bacterium's CRISPR array, it will be much more likely that the bacterium will be able to fight off the infection.

## HOW TO USE IT

This model can be used to investigate several aspects of CRISPR systems.  One example is to examine the effects of CRISPR on the coevolutionary dynamics and stability of the bacterial and viral populations.  Another example is to look at how CRISPR evolution changes when faced with different levels of viral diversity, viral infectivity, or spacer loss. See the **What is it?** section above for an explanation of spacers.

### Buttons

#### `SETUP`
Initializes variables and creates the initial bacteria and viruses.

#### `GO`
Runs the model.

#### `PLOT-NEW-VIRUS`
Resets the `CRISPR-VIRUS COEVOLUTION` plot and changes it to focus on the virus selected using the `PLOTTED-VIRUS` slider.

### Sliders and Switches

#### `INITIAL-BACTERIA`
This slider controls the number of bacteria in the initial population when the model is set up.

#### `INITIAL-VIRUSES`
This slider controls the number of viruses in the initial population when the model is set up.

#### `MAX-VIRUS-TYPES`
This slider controls the diversity of the viruses in the population.

#### `INFECTION-CHANCE`
This slider controls the probability that a virus will attempt to infect a bacterium when they are on the same patch.

#### `SPACER-LOSS-CHANCE`
This slider controls the rate at which spacers can be lost from a bacterial CRISPR array. It is the probability that a bacterium will lose a spacer on each tick.

#### `CRISPR?`
This switch controls whether or not the bacteria have functioning CRISPR systems in the model. When `CRISPR?` is on, all bacteria use CRISPR systems to fight off viral infection. When `CRISPR?` is off, bacteria must rely on innate immunity, which is often less effective.

#### `PLOTTED-VIRUS`
This slider allows the user to choose a new virus to focus on in the `CRISPR-VIRUS COEVOLUTION` plot. The plot will not switch over to the newly selected virus until the `PLOT-NEW-VIRUS` button is clicked.

### Plots and Monitors

#### `MICROBE POPULATIONS`
Plots the population sizes for bacteria and viruses over time.

#### `SEQUENCE HISTOGRAM`
Shows the absolute frequency of each virus type both in the virus population (black) and in bacterial CRISPR arrays (red).

#### `VIRUS RELATIVE ABUNDANCE`
Plots the relative abundance of each of the extant virus types as a percentage of the current total population size.

#### `CRISPR-VIRUS COEVOLUTION`
Plots the relative abundance of a single type of virus in the overall viral population and the prevalence of spacers from that viral type in the CRISPR arrays of the bacteria. This can illustrate the coevolutionary dynamics between viruses and bacteria leading to fluctuations in the prevalence of the virus over time. The virus to be plotted can be chosen using the `PLOT-NEW-VIRUS` and `PLOTTED-VIRUS` widgets.

#### `ARRAY HISTOGRAM`
Shows a histogram of the current distribution of the length of bacterial CRISPR arrays. Summary statistics are provided in the `AVG. ARRAY LENGTH` and `STD. DEV.` monitors.

#### `AVG. ARRAY LENGTH`
Shows the mean length of bacterial CRISPR arrays.

#### `STD. DEV.`
Shows the standard deviation of the lengths of bacterial CRISPR arrays.

## THINGS TO NOTICE

First, take some time to watch the agents move around and familiarize yourself with the overall patterns that emerge. When people study bacteria and viruses living in the environment, they often treat the samples as having little spatial variability, with bacteria and viruses being spread evenly throughout. Does this seem like a reasonable assumption or not? Do you see microenvironments which vary in the amount of viruses, bacteria, and food that they contain? Does this pattern stay the same over time, or does it shift?

Next, look at the Microbe Populations plot. When the population stabilizes, there should be roughly two orders of magnitude between the viral and bacterial population levels. This approximates the relative population levels in seawater. Does this surprise you? Why do you think this is the case?

After the populations stabilize, look at the Sequence Histogram. The black bars represent the virus population, and the red bars represent the population of spacers held in the bacteria's CRISPR arrays. How much do the histograms overlap? Is there a correlation between frequency in the population and frequency in the CRISPR arrays? Does this make sense based on what you know about the system?

Next look at the Virus Relative Abundance plot. As the Sequence Histogram shows the current abundance of each virus type, this plot shows the virus types' relative abundance over time. Most of the time, most of the viruses are at relatively low abundance. Do you see a pattern across the different viruses? What tends to happen after a virus becomes more abundant?

To examine this question in more detail, look at the CRISPR-Virus Coevolution plot. To make the most of this plot, use the Sequence Histogram to identify a virus that is prevalent in the population, then adjust the `PLOTTED-VIRUS` slider to match it. The virus type is the value on the x-axis of the histogram where the bar is plotted. Click the `PLOT-NEW-VIRUS` button and run the model. As the virus becomes more prevalent in the population (black line), what happens to its prevalence in CRISPR arrays (red line)? What happens to the virus when it is common in CRISPR arrays?

As time goes on, bacteria begin to accumulate spacers in their CRISPR arrays. This can be seen by watching the Array Histogram and its associated summary statistic monitors change over time. Does the distribution of array lengths seem to converge to anything over time?

## THINGS TO TRY

There are several interesting comparisons to make between a population with CRISPR and one without it. This is accomplished by toggling the `CRISPR?` switch. For example, when the bacteria have CRISPR systems, both the bacterial and viral populations are mostly constant. Is this the case when the `CRISPR?` switch is off? Does this surprise you? Similarly, when the bacteria have CRISPR, there are many types of virus which are mostly at fairly low abundance (see the Sequence Histogram and the Virus Relative Abundance plot). How does this change when CRISPR is not present?

The viral diversity in the ecosystem also has interesting effects, which can be seen by manipulating the `MAX-VIRUS-TYPES` slider. How do the stable population levels change when there is high or low viral diversity? What about the distribution of CRISPR array lengths? Does high viral diversity result in longer or shorter of CRISPR arrays on average? Is CRISPR a more effective defense when there is high or low diversity? How would you tell?

## EXTENDING THE MODEL

There are several interesting aspects of real bacterial and viral ecosystems that have been left out of this model for simplicity, but may have interesting effects. A few of these questions are listed below.

CRISPR arrays in this model are transferred between bacteria through linear descent. The only way for a bacterium to have resistance to a virus is if it or one of its direct ancestors encountered that virus. Real bacteria can transfer CRISPR systems between each other using _horizontal gene transfer_, where bacteria can share copies of their genes with other bacteria that are not part of their line of descent. How would this affect coevolutionary dynamics?

The current model has two settings with respect to the presence or absence of CRISPR. In one case, every bacterium has a working CRISPR system. In the other case, no bacteria have a working CRISPR system. In real ecosystems, the bacterial population is a mix of these two, where some but not all species use CRISPR. Does the presence of CRISPR in some species help protect those species without it, analogous to herd immunity in animals? If so, what is the threshold for this to be effective?

Sometimes viruses are able to successfully infect bacteria even when the bacterium has an active CRISPR system that recognizes that virus. In this model, when this happens, the virus reproduces like normal. In reality, the CRISPR system may be able to cleave some of the newly produced viruses before they are released, lowering the size of the resulting viral burst. How would this affect the viral population?

The viruses in this model are _lytic_, meaning when they infect a cell they reproduce until the cell dies and releases the new viral particles. While this is true for many viruses, there are also some which are _lysogenic_. These viruses can insert their DNA into the bacterium's genome. This allows them to 'reproduce' when the bacterium divides, and then revert back to the lytic process described above when their host is in poor health. After the viral DNA is inserted into the bacterial genome, CRISPR may cleave the genome, resulting in the bacterium's death, or simply suppress viral replication when the virus attempts to become lytic again. How would this capability affect the ecosystem's dynamics?

This model assumes that all bacteria regulate CRISPR in the same way, which is constant over time. In reality, different bacteria will have different regulation of CRISPR and may adapt their regulatory strategies over generations. What heritable traits could be introduced to allow the bacteria more evolutionary freedom? How might each bacterium's current store of energy affect its regulation of the CRISPR system?

In this model it is possible for bacteria to lose all of their spacers, but it is not possible for them to lose the CRISPR system entirely, and there is no cost to the bacteria for having a CRISPR system. In reality, there is a fitness cost associated with maintaining a working CRISPR system, both from the material cost of producing the components and the decreased ability to take up new beneficial genes through horizontal gene transfer. This provides a balance to the fitness benefit of increased viral resistance. If such a cost were introduced, what conditions would be necessary to maintain CRISPR in the population?

## NETLOGO FEATURES

This model makes heavy use of temporary plot pens for the `VIRUS RELATIVE ABUNDANCE` plot. This allows for plotting an arbitrary number of series on the plot and ensures that it is not necessary to know the exact number ahead of time. It also allows for changing the number of series on the plot during the run of the model.

This model employs a supplementary function to improve auto scaling behavior for histograms. By default, histograms only autoscale the y-axis. The `update-histogram-ranges` function used here implements x-axis auto scaling which can increase but never decrease the range, similar to the default y-axis auto scaling. It also implements y-axis scaling which can increase or decrease the plot's range. This makes the histogram always take up most of the plot area while keeping the entire histogram visible and minimizing the number of rescaling events.

## RELATED MODELS

CRISPR Ecosystem LevelSpace
CRISPR Bacterium
CRISPR Bacterium LevelSpace

## CREDITS AND REFERENCES

For general information about CRISPR, visit https://sites.tufts.edu/crispr/ or see the review below:

  * Barrangou, R. & Marraffini, L. A. CRISPR-Cas Systems: Prokaryotes Upgrade to Adaptive Immunity. _Molecular Cell_ **54**, 234–244 (2014).

For more information about CRISPR-driven coevolution in bacteria and viruses, see the articles below:

  * Iranzo, J., Lobkovsky, A. E., Wolf, Y. I. & Koonin, E. V. Evolutionary Dynamics of the Prokaryotic Adaptive Immunity System CRISPR-Cas in an Explicit Ecological Context. _Journal of Bacteriology_ **195**, 3834–3844 (2013).
  * Paez-Espino, D. et al. CRISPR Immunity Drives Rapid Phage Genome Evolution in _Streptococcus thermophilus_. _mBio_ **6**, e00262-15 (2015).
  * Sun, C. L. et al. Phage mutations in response to CRISPR diversification in a bacterial population: Strong selection events as host-phage populations establish. _Environmental Microbiology_ **15**, 463–470 (2013).

For more information about potential extensions to the model, see the articles below:

  * Bondy-Denomy, J. & Davidson, A. R. To acquire or resist: the complex biological effects of CRISPR–Cas systems. _Trends in Microbiology_ **22**, 218–225 (2014).
  * Edgar, R. & Qimron, U. The _Escherichia coli_ CRISPR System Protects from λ Lysogenization, Lysogens, and Prophage Induction. _Journal of Bacteriology_ **192**, 6291–6294 (2010).
  * Goldberg, G. W., Jiang, W., Bikard, D. & Marraffini, L. A. Conditional tolerance of temperate phages via transcription-dependent CRISPR-Cas targeting. _Nature_ **514**, 633–637 (2014).
  * Strotskaya, A. et al. The action of _Escherichia coli_ CRISPR–Cas system on lytic bacteriophages with different lifestyles and development strategies. _Nucleic Acids Research_ **gkx042** (2017). doi:10.1093/nar/gkx042

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Woods, P. and Wilensky, U. (2019).  NetLogo CRISPR Ecosystem model.  http://ccl.northwestern.edu/netlogo/models/CRISPREcosystem.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2019 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2019 Cite: Woods, P. -->
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

bacteria
true
0
Polygon -7500403 false true 105 300 195 300 225 270 240 210 240 60 210 15 180 0 120 0 90 15 60 60 60 210 75 270 105 300
Polygon -7500403 true true 120 15 180 15 210 30 225 60 225 225 210 270 195 285 105 285 90 270 75 225 75 60 90 30 120 15 180 15

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

food
false
0
Rectangle -7500403 true true 0 0 300 300

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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

virus
true
0
Circle -7500403 true true 45 45 210
Circle -7500403 true true 135 0 30
Circle -7500403 true true 135 270 30
Circle -7500403 true true 270 135 30
Circle -7500403 true true 0 135 30
Circle -7500403 true true 15 60 30
Circle -7500403 true true 60 15 30
Circle -7500403 true true 15 210 30
Circle -7500403 true true 60 255 30
Circle -7500403 true true 210 255 30
Circle -7500403 true true 210 15 30
Circle -7500403 true true 255 60 30
Circle -7500403 true true 255 210 30
Line -7500403 true 75 30 105 75
Line -7500403 true 150 15 150 60
Line -7500403 true 15 150 75 150
Line -7500403 true 285 150 225 150
Line -7500403 true 150 285 150 225
Line -7500403 true 30 75 75 105
Line -7500403 true 225 30 195 75
Line -7500403 true 270 75 225 105
Line -7500403 true 30 225 75 195
Line -7500403 true 75 270 105 225
Line -7500403 true 225 270 195 225
Line -7500403 true 270 225 225 195

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

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
