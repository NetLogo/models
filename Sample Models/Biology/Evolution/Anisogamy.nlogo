globals [
  average-adult-lifetime      ; the average lifetime of adults, used to pick a random lifetime for each adult and gamete when they are born
  gamete-provisioning-budget  ; the percentage of adults' body mass that can be allocated to producing gametes
  spawning-probability        ; the percent-chance of an adult producing new gametes at each tick

  ; The following two variables are only used if the speed-size-correlation? parameter is on
  max-gamete-size          ; used to calculate the minimum and maximum gamete speeds
  tick-advance-amount      ; varies when partial-ticks are used for the speed-size experiments

  whole-tick?              ; true on the first step after one whole tick has been completed (needs to be a global for BehaviorSpace end conditions)
]

breed [adults adult]
breed [gametes gamete]
breed [zygotes zygote]

adults-own [
  mating-type-trait    ; the pseudo-sex of each adult, designated as blue (+) or red (-)
  gamete-size-trait    ; each adult has its own separate gamete size trait
  life                 ; the number of ticks left this adult has before it will die
]

zygotes-own [
  mating-type-trait    ; inherited from either parent with equal likelihood (blue (+) or red (-))
  gamete-size-trait    ; inherited from the parent within the mating-type package
  incubation-time      ; zygotes have to incubate before turning into adults or dying
]

gametes-own [
  mating-type-trait   ; the pseudo-sex of of the gamete
  gamete-size-trait   ; actual gamete size is drawn from a normal distribution with mean of gamete-size-trait
  life                ; the number of ticks left this gamete has before it will die
  speed               ; how quickly the gamete moves foward (only used when speed-size-correlation? is true)
]


to setup

  clear-all
  initialize-globals
  create-aquatic-environment
  create-isogamous-adult-population
  reset-ticks

end


to go

  ; check if 1 whole tick has passed since the last tick
  ;    this mechanism is needed to facilitate the speed-size relationship algorithm
  ;    the world view and the plots are updated each time a 'whole tick' passes
  set whole-tick? floor ticks > floor (ticks - tick-advance-amount)

  if whole-tick? [

    ask adults [

      set heading random-float 360
      forward 1

      if random-float 100 < spawning-probability [
        produce-gametes
      ]

      set life life - 1
      if life < 1 [ die ]

    ]

    ask zygotes [
      set incubation-time incubation-time - 1
      if incubation-time < 1 [
        become-adult
      ]
    ]

    ; make sure there is no exponential growth in the tiny world of this model
    ;   only applies to adults
    enforce-carrying-capacity

  ]

  ; If speed-size-correlation? is off, advance ticks by 1 at each step
  ;   If it is on, calculate the amount of ticks that needs to pass at this step
  ;     based on the size of the smallest gamete in the environment
  ;   This must be updated after new gametes are produced and before gametes act
  ;     because the size of the smallest gamete may have changed
  if speed-size-correlation? [
    calculate-tick-advance-amount
  ]

  ask gametes [

    set heading random 360
    forward speed * tick-advance-amount

    fuse-if-touching-another-gamete

    set life life - tick-advance-amount
    if life <= 0 [ die ]
  ]

  ; the tick-advance amount is 1 by default
  ;   but it may be less than 1 if speed-size-correlation parameter is on
  tick-advance tick-advance-amount

  ; Update the view and the plots each time a 'whole (1)' tick passes.
  ;   unless the model is running as part of a behaviorspace experiment
  if whole-tick? and behaviorspace-run-number = 0 [
    update-plots
    display
  ]

  ; stop the model if all turtles died (extinction)
  if not any? turtles [ stop ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP BUTTON SUBPROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Edit the values in the following procedure
;; to change model parameters that are not exposed in the interface
to initialize-globals

  ; the average lifetime of adults.
  ; this variable is also used to calculate the incubation time of zygotes and lifetime of gametes
  set average-adult-lifetime 500

  ; adults have a fixed budget to use for producing gametes
  set gamete-provisioning-budget 0.5

  ; at each tick, each adult has 1.5% chance of producing new gametes
  set spawning-probability 1.5

  ; for the partial ticks algorithm that is used
  ;  when the speed-size-relation? parameter is on
  set max-gamete-size (2 * sqrt(gamete-provisioning-budget / pi))
  set tick-advance-amount 1
  set whole-tick? false

end


to create-aquatic-environment

  ; resize the world if the world-size parameter was changed
  let max-coor (world-size - 1) / 2
  if max-coor != max-pxcor [
    let min-coor (max-coor * -1)
    resize-world min-coor max-coor min-coor max-coor
    set-patch-size (421 / world-size)
  ]

  ; create the blue background that resembles a marine environment
  ;    but ignore this code if the model is running in headless (non-gui) mode
  if behaviorspace-run-number = 0 [
    ask patches [ set pcolor 89 + random-float 1 - random-float 2 ]
    repeat 10 [ diffuse pcolor 0.5 ]
  ]

end


to create-isogamous-adult-population

  create-adults max-adults [
    set shape "adult"
    setxy random-xcor random-ycor
    set mating-type-trait one-of [ red blue ]
    set color mating-type-trait + 1

    ; all adults begin with the same gamete size trait,
    ;   which is half of the global gamete production budget parameter
    set gamete-size-trait (gamete-provisioning-budget / 2)

    ; adult lifetime is selected randomly from a normal distribution
    ;   with a standard deviation that is 1/10th of the average lifetime
    set life (random-normal average-adult-lifetime (average-adult-lifetime / 10))
  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GO BUTTON SUBPROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Necessary procedure to calculate 'partial-ticks' for the speed-size relation algorithm
;;   because moving ticks one-by-one results in fast gametes 'jumping' around
;;   this algorithm guarantees realistic collision detection
to calculate-tick-advance-amount

  ; if there are any gametes in the world, we will calculate the tick-advance-amount
  ifelse any? gametes [
    ; Gamete speed is gamete-production-budget / size,
    ;   so the max speed is the budget divided by the smallest size.
    ; The ceiling operation provides a buffer to ensure gametes always move <= 1 per tick-advance.
    set tick-advance-amount (1 / (max-gamete-size / (min [size] of gametes)))
  ][
    ; otherwise, the adults always move with speed 1
    set tick-advance-amount 1
  ]

end


;;;; adult procedure
;;;;   produces gametes at random times and passes down the gamete size trait with the chance of a small mutation
to produce-gametes

  ; introduce a small random mutation to the gamete size for the current reproduction cycle,
  ;   this code allows for sizes larger than the production budget, too,
  ;   but because it leads to 0 gametes produced, that strategy never passes to next generations
  let instantaneous-gamete-size (random-normal gamete-size-trait mutation-σ)

  ; produce new gametes only if the instantaneous gamete size trait is higher than the minimum viable gamete size
  if instantaneous-gamete-size >= gamete-fitness-threshold [

    ; determine the number of gametes that will be hatched,
    ;   the 'floor' primitive means we're discarding the extra material
    let number-of-gametes floor (gamete-provisioning-budget / instantaneous-gamete-size)

    ; the hatch primitive automatically passes down the basic properties such as the mating type and the color
    hatch-gametes number-of-gametes [

      set gamete-size-trait instantaneous-gamete-size                   ; this is the trait that will be passed down to the zygote

      set size (2 * sqrt(gamete-size-trait / pi))  ; the actual size of the gamete in the 2d world, calculated as follows:
                                                   ;  mass (m) of a gamete is not taken as the [size] of a gamete, but the total 2d area
                                                   ;  hence a conversion between m <-> A is necessary for realistic modeling
                                                   ;  [size/diameter] = 2r and mass = A = π(r^2),
                                                   ;   which means r = square-root (m / π),
                                                   ;   and [size] = 2r = 2 * square-root (m / π)
      set shape "gamete"
      set color color - 2

      set life (random-normal (average-adult-lifetime / 10) (average-adult-lifetime / 100))

      ; if speed-size-correlation? parameter is on,
      ;    set the gamete's speed inversely proportional to its size
      ;    so, smaller gametes move faster
      ; otherwise, move with speed 1

      ifelse speed-size-correlation? [
        set speed (max-gamete-size / (size))
      ][
        set speed 1
      ]

    ]
  ]

end


;;;; gamete procedure
;;;;   if a gamete touches another gamete, they fuse and form a zygote
;;;;   the newly formed zygote inherits the mating type and gamete size traits from one of the gametes randomly as a bundle
to fuse-if-touching-another-gamete

  ; following two-line algorithm is basically a "touching?" algorithm
  ;   it works as follows: if the distance between the centers of two agents are
  ;      smaller than the half of the sum of the diameters (size) of two agents
  ;      they are considered as touching each other
  ;   we are only testing collision with gametes on the same patch
  ;      and on the 8 neighboring patches
  ;      because no gamete can be bigger than 1 unit-lengths
  let gametes-around-me other (turtle-set (gametes-here) (gametes-on neighbors))
  let potential-mating-partners gametes-around-me with [distance myself < (size / 2) + (([size] of myself) / 2)]

  ; if fusion between same type gametes is not allowed,
  ;   exclude them from the partner pool
  if not allow-assortative-fusion? [
    set potential-mating-partners potential-mating-partners with [ mating-type-trait != [ mating-type-trait ] of myself ]
  ]

  if any? potential-mating-partners [

    ; because there might be multiple other gametes touching this gamete,
    ;   we choose one of them randomly to initiate fusion.
    let mating-partner one-of potential-mating-partners

    ; pool the mating type and gamete size traits that are inherited from both gametes
    ;    we use lists because we want to preserve the order of traits in both lists
    let mating-type-pool (list mating-type-trait [mating-type-trait] of mating-partner)
    let gamete-size-pool (list gamete-size-trait [gamete-size-trait] of mating-partner)

    ; hatch a new zygote if if the zygote size is greater than the threshold
    ;   set the threshold value to 0 to allow all zygotes to survive into adulthood
    let n 1
    let zygote-size sum gamete-size-pool
    if zygote-size < zygote-fitness-threshold [
      set n 0
    ]

    ; choose one of the parent strategies randomly as either 0 or 1
    let inherited-strategy random 2

    ; fuse into a zygote that has the combined size of the two gametes
    hatch-zygotes n [

      set gamete-size-trait (item inherited-strategy gamete-size-pool)
      set mating-type-trait (item inherited-strategy mating-type-pool)

      set color (mating-type-trait + 3)  ;; just a lighther red or blue for visibility
      set size ((2 * sqrt(zygote-size / pi))) ;; refer to the 'maybe-produce-gametes' procedure above
      set shape "zygote"

      ; incubation time is drawn from a normal distribution
      set incubation-time (random-normal (average-adult-lifetime / 5) (average-adult-lifetime / 50))
    ]

    ; after the zygote is hatched, remove the gamete agents from the model
    ask mating-partner [ die ]
    die

  ]

end


;;;; zygote procedure
to become-adult

  set breed adults
  set color mating-type-trait + 1
  set shape "adult"
  set size 1
  set life (random-normal average-adult-lifetime (average-adult-lifetime / 10))

  ; other traits, such as gamete-size-trait, are preserved

end


;;;; observer procedure
;;;;   ensures that the adult population does not exceed the carrying capacity of the system
to enforce-carrying-capacity

  if count adults > max-adults [
    ask n-of (count adults - max-adults) adults [ die ]
  ]

end


;;;; to revert the interface controls back to the default parameter configuration
to restore-default-parameters
  set zygote-fitness-threshold 0.45
  set gamete-fitness-threshold 0.01
  set mutation-σ 0.025
  set speed-size-correlation? false
  set allow-assortative-fusion? false
  set max-adults 100
  set world-size 65
end


; Copyright 2023 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
300
10
698
409
-1
-1
6.0
1
8
1
1
1
0
1
1
1
-32
32
-32
32
1
1
1
ticks
30.0

BUTTON
10
10
95
50
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
105
10
190
50
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
995
240
1240
410
number adults
t
n
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"+" 1.0 0 -13345367 true "" "plot count adults with [mating-type-trait = blue]"
"-" 1.0 0 -2674135 true "" "plot count adults with [mating-type-trait = red]"

SWITCH
10
260
247
293
allow-assortative-fusion?
allow-assortative-fusion?
1
1
-1000

PLOT
995
10
1240
230
gamete-size trait distribution
m
n
0.0
0.5
0.0
10.0
true
true
"" "set-plot-y-range 0 20"
PENS
"+" 0.02 1 -13345367 true "" "histogram [gamete-size-trait] of adults with [mating-type-trait = blue]"
"-" 0.02 1 -2674135 true "" "histogram [gamete-size-trait] of adults with [mating-type-trait = red]"

SLIDER
10
60
285
93
zygote-fitness-threshold
zygote-fitness-threshold
0
gamete-provisioning-budget
0.45
0.01
1
NIL
HORIZONTAL

SLIDER
10
140
250
173
mutation-σ
mutation-σ
0
0.1
0.025
0.001
1
NIL
HORIZONTAL

PLOT
710
240
985
410
number of gametes
t
n
0.0
100.0
0.0
10.0
true
true
"" ""
PENS
"+" 1.0 0 -13345367 true "" "plot count gametes with [mating-type-trait = blue]"
"-" 1.0 0 -2674135 true "" "plot count gametes with [mating-type-trait = red]"

SWITCH
10
300
250
333
speed-size-correlation?
speed-size-correlation?
1
1
-1000

PLOT
710
10
985
230
average gamete-size trait (µm)
t
m
0.0
10.0
0.0
0.5
true
true
"" ""
PENS
"+" 1.0 0 -13345367 true "" "plot mean [gamete-size-trait] of adults with [mating-type-trait = blue]"
"-" 1.0 0 -2674135 true "" "plot mean [gamete-size-trait] of adults with [mating-type-trait = red]"

SLIDER
10
100
285
133
gamete-fitness-threshold
gamete-fitness-threshold
0.01
zygote-fitness-threshold + 0.01
0.01
0.01
1
NIL
HORIZONTAL

BUTTON
10
340
212
381
NIL
restore-default-parameters
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
10
180
250
213
max-adults
max-adults
10
500
100.0
10
1
NIL
HORIZONTAL

SLIDER
10
220
250
253
world-size
world-size
1
97
65.0
8
1
^ 2
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Anisogamy, or gamete dimorphism, is a reproductive strategy involving one group of adults producing numerous small gametes (i.e., sperm, pollen) while the other group produces a few large gametes (i.e., egg, ovum). The former group is commonly called males, and the latter is called females. When two gametes from opposite sexes fuse, they form a _zygote_ that inherits genetic material for the development and biomaterial for the survival of the zygote from both gametes. However, although both parents contribute an equal amount of genetic material (n+n chromosomes) to their offspring, the females exclusively provide the biomaterial.

Anisogamy is equally fascinating and important in evolutionary biology because all animals and plants are anisogamous except a few algal and fungal species. Even species that exhibit hermaphroditism (e.g., roses, snails) reproduce via many small gametes and a handful of large gametes. Moreover, such hermaphroditic species often have secondary adaptations that suppress fusion between the gametes produced by the same individual. Thus, scientists agree that anisogamy must have preceded many biological traits such as oogamy, internal fertilization, sex roles, parental caring, and competition for mating partners.

Unfortunately, we may never know precisely how anisogamy evolved in the first place and how it became so prevalent because there is no fossil record. However, we can develop robust models to test various theoretical ideas and map out plausible evolutionary pathways from no sexual differentiation between mating types (isogamy) to gamete dimorphism (anisogamy). This model attempts to realistically simulate the conditions that may have given rise to the emergence of anisogamy as an evolutionarily stable strategy (ESS) within an initially isogamous population. It also allows testing the impact of various factors on the evolutionary process.

## HOW IT WORKS

**NOTE**: This model has been updated since it was originally published in the models library.

This model has three kinds of agents: adults, gametes, and zygotes.

Adults move around randomly and release gametes to the environment at random intervals. Although each adult has an inherited gamete-size trait, every time they produce new gametes, there is a chance of a small mutation in size. In addition, all adults have the same amount of biomaterial (gamete production budget) to produce gametes. So, there is an inversely proportional relationship between gamete size and quantity. An adult with a small gamete-size trait can produce more gametes and vice versa. In addition, every adult has a limited lifetime. When an adult reaches its lifetime, it dies.

Each gamete carries simple genetic information that includes two phenotypical traits for reproductive strategy: _mating-type_ and _gamete-size_. Once released to the environment, gametes start moving around randomly. When two gametes physically contact each other, they initiate a fusion process to form a zygote. If a gamete reaches its lifetime without being able to fuse with another gamete, it dies.

A zygote inherits the total size of the two gametes that form it as a proxy for the sum of the genetic material it needs to develop and the biomaterial it needs to survive during development. If a zygote inherits biomaterial less than the survival threshold, it dies immediately (for simplicity). If it inherits enough biomaterial, it incubates without moving for a while and becomes an adult.

Each new adult randomly inherits its reproductive strategy traits (gamete size and mating type) from either parent with equal likelihood. In other words, it inherits these traits as a bundle without intermixing. For example, if a _small+_ gamete and a _large-_ gamete fuse, the resulting zygote either inherits the _small+_ or _large-_ strategy; it cannot inherit the _large+_ or _small-_ strategies.

When we run the model, the population lives in perpetuity until we stop it again. Adults produce new gametes, gametes fuse zygotes, zygotes turn into new adults, and some agents die while others continue living.

## HOW TO USE IT

The SETUP button creates the initial adult population randomly dispersed within the two-dimensional world of the model. Each adult is randomly assigned one of the mating types (+ or -), but all have the same gamete size trait at the beginning.

The GO button runs the model. If the model is already running, clicking the GO button again pauses it.

The ZYGOTE-FITNESS-THRESHOLD slider controls the minimum size (i.e., biomaterial) a zygote must have to survive into adulthood and start producing gametes. Zygotes that are smaller than this value cannot grow into reproductive adults.

The GAMETE-FITNESS-THRESHOLD slider controls the minimum size (i.e., biomaterial) a gamete needs. If an adult's instantaneous gamete size trait happens to be below this slider's value, its gametes are considered _stillborn_.

Each adult has a fixed value for their gamete-size trait that never changes. However, every time an adult attempts to produce new gametes, an instantaneous gamete size is randomly picked over a normal distribution with the expected value as the gamete-size trait of the parent and the standard deviation as the value of the MUTATION-σ slider. Therefore, this slider allows changing the nature of mutations in the model.

The ALLOW-ASSORTATIVE-FUSION? switch controls whether any two gametes can fuse. If this switch is off, a `+` gamete can only fuse with a `-` gamete and vice versa.

The SPEED-SIZE-CORRELATION? switch manipulates the speed of gametes. If this switch is on, a gamete's speed is inversely proportional to its size, so smaller gametes move faster. Otherwise, all gametes move one unit per tick.

## THINGS TO NOTICE

Evolution is a gradual and lengthy process in this model. It may initially seem like the population is not changing much, but continue running the model for a few thousand ticks so that you can see meaningful changes.

Even if the gamete size traits of the `+` and `-` adults evolve to be dramatically different, the overall sex ratio remains roughly 1:1. There are no underlying interventions in the model's code to fix the sex ratio. Hence, maintenance of the sex ratio is an emergent property of this model.

Anisogamy always emerges as the _evolutionary stable strategy_ (ESS) (assuming default parameter values). Once it emerges, it quickly stabilizes and is never destabilized, no matter how long we run the model.

Two selective pressures in this model emerge from micro-level agent behavior. The first selective pressure emerges due to the zygotes' need for sufficient biomaterial, giving an advantage to the mutants with larger and larger gamete size traits. The second selective pressure emerges due to the advantage of producing more gametes, giving an advantage to the mutants with smaller and smaller gamete size traits. However, the latter only emerges after the first selective pressure leads to the emergence of very large gametes that can almost singlehandedly provide all the biomaterial needed for a zygote to survive.

## THINGS TO TRY

Try allowing all zygotes to survive into adulthood by changing the ZYGOTE-FITNESS-THRESHOLD. How does this change impact the evolutionary process?

Try allowing any two gametes to fuse by turning on the ALLOW-ASSORTATIVE-FUSION? switch. How does this change impact the evolutionary process?

Try giving smaller gametes a speed advantage by turning on the SPEED-SIZE-CORRELATION? switch. How does this change impact the evolutionary process?

## EXTENDING THE MODEL

This model considers an initial condition with only two mating types. However, some isogamous species have more than two mating types. For example, _Schizophyllum commune_  has some 20,000+ mating types. Try modifying the model's code to answer these questions: How would the outcome change if there were 3+ mating types?

The trait inheritance mechanism is very simple in this model. However, there are various more realistic mechanisms in nature. For example, some _haploid_ organisms may release _haploid_ gametes into their environment, but _diploid_ zygotes formed by the fusion of two _haploid_ gametes may split into two adults at the end of the incubation process. On the other hand, if we assume adults to be diploid, we would need to introduce a more accurate Mendelian mechanism with dominant and recessive alleles. Try to change the model's code to implement these modifications to see if the outcome would change.

## NETLOGO FEATURES

This model uses the RANDOM-NORMAL primitive to introduce plausible variation to agent traits such as gamete size, adult lifetime, and zygote incubation time.

This model uses the DISTANCE primitive to calculate the distance between the centers of two agents to determine whether or not two agents are colliding (touching).

This model uses the DIFFUSE primitive to create a smoothly-transitioning background with tones of cyan to represent a marine environment.

## RELATED MODELS

* Genetic drift models
* BEAGLE Evolution curricular models
* EACH curricular models
* GenEvo curricular models

## CREDITS AND REFERENCES

Aslan, U., & Wilensky, U. (2016). Restructuration in Practice: Challenging a Pop-Culture Evolutionary Theory through Agent Based Modeling. In Proceedings of the Constructionism, 2016 Conference. Bangkok, Thailand.

Aslan, U., Dabholkar, S., & Wilensky, U. (2017). Developing Multi-agent-based Thought Experiments: A Case Study on the Evolution of Gamete Dimorphism. In: Sukthankar, G., Rodriguez-Aguilar, J. (eds) Autonomous Agents and Multiagent Systems. AAMAS 2017. Lecture Notes in Computer Science(), vol 10642. Springer, Cham. https://doi.org/10.1007/978-3-319-71682-4_4

Aslan, U., Dabholkar, S., Woods, P., Noel, I. & Wilensky, U. (2017). A spatially-explicit multi-agent-based model of anisogamy with discrete time steps. Unpublished manuscript.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Aslan, U., Dabholkar, S., Woods, P., Wilensky, U. (2023).  NetLogo Anisogamy model.  http://ccl.northwestern.edu/netlogo/models/Anisogamy.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2023 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2023 Cite: Aslan, U., Dabholkar, S., Woods, P., Wilensky, U. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

adult
true
0
Circle -7500403 true true 0 0 300
Line -1 false 180 30 150 15
Line -1 false 120 30 150 15

gamete
true
0
Circle -7500403 true true 0 0 300
Polygon -1 true false 150 0 120 150 180 150

zygote
false
0
Circle -7500403 true true 15 60 178
Circle -7500403 true true 103 58 182
@#$#@#$#@
NetLogo 6.4.0
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
