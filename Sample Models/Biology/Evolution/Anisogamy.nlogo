globals [
  average-lifetime         ; the average lifetime of adults, used to pick a random lifetime for each adult and gamete when they are born
  gamete-mass-precision    ; the number of decimal points that is allowed in terms of gamete size strategy when dividing the budget to gamete size right before production
  gamete-production-budget ; the percentage of adults' body mass that can be allocated to producing gametes
  gamete-production-rate   ; the percent-chance of an adult producing new gametes at each tick
  population-size          ; the number of adults that can co-exist in the system at a given time. when this number is exceeded, some adults are killed randomly


  ;; Global variables for speed-size relation
  tick-advance-amount      ; varies when partial-ticks are used for the speed-size experiments
  whole-tick?              ; true on the first step after one whole tick has been completed (needs to be a global for BehaviorSpace end conditions)

  ;; Behaviorspace experiment globals
  mean-gamete-difference-list  ; the difference between the average red gamete size and the average blue gamete size
  total-end-red-gametes        ; to calculate the running average of the proportion of the red gametes at the end of BehaviorSpace experiments
  total-end-blue-gametes       ; to calculate the running average of the proportion of the blue gametes at the end of BehaviorSpace experiments
  sum-end-red-strategy         ; sums mean red adult size strategy at the end of BehaviorSpace experiments (for averaging)
  sum-end-blue-strategy        ; sums mean blue adult size strategy at the end of BehaviorSpace experiments (for averaging)
]

breed [adults adult]
breed [gametes gamete]
breed [zygotes zygote]
breed [dead-zygotes dead-zygote] ; this pseudo-breed is used to visualize zygote deaths

adults-own [
  mating-type        ; the pseudo-sex of each adult, either red or yellow
  gamete-mass        ; each adult has its own trait for the gamete size, which is a decimal number
  remaining-lifetime
]

zygotes-own [
  mating-type
  gamete-mass
  mass
  remaining-incubation-time  ; zygotes have to incubate before turning into adults or dying
]

gametes-own [
  mating-type
  mass
  remaining-lifetime
]


to setup
  clear-all

  initialize-globals

  create-aquatic-environment

  create-initial-adult-population

  initialize-behaviorspace-defaults

  reset-ticks
end


to go

  ;; first, make sure there is no overpopulation in the tiny world of this model
  enforce-carrying-capacity

  ; this is the default speed for all agents (except when a speed-size relationship for gametes is assumed)
  let my-speed 1

  ; check if 1 whole tick has passed since the last tick
  ;    the world view and the plots are updated each time a 'whole tick' passes
  set whole-tick? floor ticks > floor (ticks - tick-advance-amount)

  ask adults[
    if adults-move? [
      forward my-speed * tick-advance-amount
    ]

    ;; when a whole tick is completed,
    ;;   turn around randomly, maybe produce new gametes, and age
    if whole-tick? [
      right 360
      maybe-produce-gametes
    ]

    age-and-maybe-die
  ]

  ;; Calculate the amount of ticks that needs to pass at this step
  ;;   based on the size of the smallest gamete in the environment
  ;; This must be updated after new gametes are produced and before gametes act
  ;;   because the size of the smallest gamete may have changed
  if speed-size-relation? [ calculate-tick-advance-amount ]

  ask gametes [
    if speed-size-relation? [
      let gamete-production-size (2 * sqrt(gamete-production-budget / pi))
      set my-speed precision (gamete-production-size * 100 / (size)) gamete-mass-precision
    ]
    wiggle-and-move my-speed * tick-advance-amount
    maybe-fuse
    age-and-maybe-die
  ]

  ask zygotes [
    incubate
  ]

  ask dead-zygotes [
    slowly-disappear
  ]

  ;;; The following procedure is executed only if the model is run within a behaviorspace experiment
  run-behaviorspace-tasks

  ;; the tick-advance amount is 1 by default
  ;; but it may be less than 1 if speed-size relationship is turned on
  tick-advance tick-advance-amount

  ;; Update the view and the plots each time a 'whole (1)' tick passes.
  if whole-tick? [
    update-plots
    display
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP BUTTON SUBPROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Edit the values in the following procedure
;; to change model parameters that are not exposed in the interface
to initialize-globals

  ; the average lifetime of adults.
  ; this variable is also used to calculate the incubation time of zygotes and lifetime of gametes
  set average-lifetime 500

  ; set gamete size precision (also meaning: the minimum viable gamete size is 0.01)
  set gamete-mass-precision 2

  ; adults can use approximately half of their mass to produce gametes
  set gamete-production-budget 0.5

  ; at each tick, each adult has 1.5% chance of producing new gametes
  set gamete-production-rate 1.5

  ; the carrying capacity of the world is 100 adults
  set population-size 100

  ; for the partial ticks algorithm that is used when the "SPEED-SIZE-RELATION?" switch is turned on
  set tick-advance-amount 1
  set whole-tick? false
end


to create-aquatic-environment
  ; create the blue background that represents a marine environment
  ask patches [ set pcolor 87 + random 5 - random 5 ]
  repeat 20 [ diffuse pcolor 0.5 ]
end


to create-initial-adult-population
    ;;; create the initial adult population
    create-adults population-size [
    set shape "adult"
    setxy random-xcor random-ycor

    ; we increase the size to 2 just for the visibility in the model
    set size 2

    ; choose the mating type randomly and change the color accordingly
    set mating-type one-of [ red blue ]
    set color mating-type

    ; all adults begin with the same gamete mass trait, which is their reproduction budget / 2.
    set gamete-mass (gamete-production-budget / 2)

    ; adult lifetime is drawn from a normal distribution with a standard deviation that is 1/10th of the average lifetime.
    set remaining-lifetime round (random-normal average-lifetime (average-lifetime / 10))
  ]
end


to initialize-behaviorspace-defaults
  ;;; the following two variables are used in some BehaviorSpace experiments !they can be taken out in the Library version!
  set total-end-red-gametes  0
  set total-end-blue-gametes  0
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GO BUTTON SUBPROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Necessary procedure to calculate 'partial-ticks' for the speed-size relation algorithm
;;   because moving ticks one-by-one results in fast gametes 'jumping' around
;;   this algorithm guarantees realistic collision detection
to calculate-tick-advance-amount
  ;; if there are any gametes in the world, we will calculate the tick-advance-amount
  ifelse any? gametes [
    ;; Gamete speed is gamete-production-budget / size, so the max speed is the budget divided by the smallest size.
    ;; The ceiling operation provides a buffer to ensure gametes always move <= 1 per tick-advance.
    let gamete-production-size (2 * sqrt(gamete-production-budget / pi))
    set tick-advance-amount 1 / (ceiling ((gamete-production-size * 100) / (min [size] of gametes)))
  ]
  [
    ;; otherwise, the adults always move with speed 1, so if there are no gametes we can advance ticks normally.
    set tick-advance-amount 1
  ]
end


;;;; gamete & adult procedure
;;;;   simulates a random walk
to wiggle-and-move [ my-speed ]
  right random 360
  forward my-speed
end


;;;; gamete and adult procedure
;;;;   counts down the remaining lifetime of an agent and asks it to die when it has no lifetime remaining
to age-and-maybe-die
    set remaining-lifetime remaining-lifetime - tick-advance-amount
    if remaining-lifetime < 0 [ die ]
end


;;;; adult procedure
;;;;   produces gametes at random times and passes down the gamete-mass trait with the chance of a small mutation
to maybe-produce-gametes

  if random-float 100 < gamete-production-rate [

    ; introduce a small random mutation to the gamete size for the current reproduction cycle,
    ;   but also do not allow gametes bigger than the production budget
    let inherited-gamete-mass min list (random-normal gamete-mass mutation-stdev) (gamete-production-budget)

    ; check if the mutated gamete size is higher than the minimum viable gamete size
    if inherited-gamete-mass > gamete-critical-mass [

      ; determine the number of gametes that will be hatched,
      ;   the 'floor' primitive means we're discarding the extra material
      let number-of-gametes floor (gamete-production-budget / inherited-gamete-mass)

      ; the hatch primitive automatically passes down the basic properties such as the mating type and the color
      hatch-gametes number-of-gametes [
        set mass inherited-gamete-mass                   ; this is the trait that will be passed down to the zygote

        set size (2 * sqrt(inherited-gamete-mass / pi))  ; this is the actual size of the gamete in the 2d world
                                                         ; size is calculated as follows:
                                                         ;      mass (m) of a gamete is not the [size] of a gamete, but the total 2d area
                                                         ;      hence a conversation between m <-> A is necessary for realistic modeling
                                                         ;      [size/diameter] = 2r and mass = A = π(r^2)
                                                         ;        , which means r = square-root (m / π)
                                                         ;        , and [size] = 2r = 2 * square-root (m / π)
        set shape "gamete"
        set remaining-lifetime round (random-normal (average-lifetime / 10) (average-lifetime / 100))
      ]
    ]

  ]
end


;;;; gamete procedure
;;;;   if a gamete touches another gamete, they fuse and form a zygote
;;;;   the newly formed zygote inherits the mating type and gamete-size strategies from one of the gametes randomly
to maybe-fuse

  ;; query the potential mates
  ;; this is basically a "touching?" algorithm
  ;;      (only testing with gametes on the same patch or on the neighboring patches as no gamete can be bigger than 1 unit-lengths)
  ;;      it works as follows: if the distance between the centers of two agents are
  ;;                           smaller than the half of the sum of the sizes of the two agents
  ;;                           those two gametes are touching each other
  ;;                           even though the shape of gametes are triangles, this algorithm assumes gametes as circles
  let gametes-around-me other (turtle-set (gametes-here) (gametes-on neighbors))
  let potential-mating-partners gametes-around-me with [distance myself < (size / 2) + (([size] of myself) / 2)]


  if any? potential-mating-partners [

    ; because there might be multiple other gametes on the same patch, choose one of them to be your partner randomly.
    let mating-partner nobody

    ; if same type mating is allowed, any gametes here are possible mates
    ifelse same-type-mating-allowed? [
      set mating-partner one-of potential-mating-partners
    ]
    [
      ; otherwise, we only consider gametes of a different type
      set mating-partner one-of potential-mating-partners with [ mating-type != [ mating-type ] of myself ]
    ]

    if mating-partner != nobody [

      ; pool the mating type and gamete mass strategies that are inherited from both gametes
      let mating-type-pool list (mating-type) ([ mating-type ] of mating-partner)
      let gamete-mass-pool list (mass) ([ mass ] of mating-partner)

      ; choose one of the parent strategies randomly
      let inherited-strategy random 2

      ; fuse into a zygote that has the combined size of the two gametes
      hatch-zygotes 1 [
        set gamete-mass (item inherited-strategy gamete-mass-pool)
        set mating-type (item inherited-strategy mating-type-pool)

        set color (mating-type + 3)  ;; just a lighther red or blue for visibility

        set mass sum (gamete-mass-pool) ;; inherit the total mass of both gametes
        set size ((2 * sqrt(mass / pi))) ;; refer to the 'maybe-produce-gametes' procedure above

        set shape "zygote"

        ; incubation time is drawn from a normal distribution
        set remaining-incubation-time round (random-normal (average-lifetime / 5) (average-lifetime / 50))
      ]

      ; after the zygote is hatched, the gametes are both taken out of the model
      ask mating-partner [ die ]
      die
    ]
  ]
end


;;;; zygote procedure
;;;;   counts down the incubation time, and then turns into an adult if the critical mass is achieved
;;;;   if critical mass is not achieved and ENFORCE-CRITICAL-MASS? is ON, the zygote turns into a dead zygote
to incubate
  set remaining-incubation-time remaining-incubation-time - 1

  if remaining-incubation-time < 1 [
    if enforce-critical-mass? [

      ; if the mass of the zygote (see the previous procedure for algorithm)
      ;    is less than the critical threshold, it dies
      if mass < zygote-critical-mass [
        hatch-dead-zygotes 1 [
          set size 1
          set shape "zygote"
          set color black
        ]
        die
      ]
    ]

    ; this code only works if zygote does not die
    ; if the mass of the zygote (see the previous procedure for algorithm)
    ;    is equal to or higher than the critical threshold, it turns into an adult
    set breed adults
    set color mating-type
    set shape "adult"
    set size 2
    set remaining-lifetime round (random-normal average-lifetime (average-lifetime / 10))
        ; other traits, such as gamete-mass, are preserved
  ]
end


;;;; dead zygote procedure
;;;;   dead zygotes slowly shrink and then die when it's time
to slowly-disappear
  set size size - 0.05
  if size < 0.1 [ die ]
end


;;;; observer procedure
;;;;   ensures that the adult population does not exceed the carrying capacity of the system
to enforce-carrying-capacity
  if count adults > population-size [
    ask n-of (count adults - population-size) adults [ die ]
  ]
  ; if there aren't multiple adults left, stops the model
  if count adults < 2 [ stop ]
end


;;;; experimental procedure
;;;;    calculates the values for the variables that are used
;;;;    in the BehaviorSqpace experiments
to run-behaviorspace-tasks

  ;; don't run any of the following code if this is not a behaviorspace experiment (just a caution)
  if behaviorspace-run-number = 0 [ stop ]

  ;; For the 1-run default parameters experiment, export the screenshots of the interface
  ;;         every 500 ticks
;  if behaviorspace-experiment-name = "default-parameters-with-screenshots" [
;    if ticks mod 500 = 0 [
;      export-interface (word "screenshots/" ticks "ticks.png")
;    ]
;  ]

  ;; For the default parameters experiment, calculate a running average of the total gamete numbers
  ;;     over the last 5000 ticks
  if behaviorspace-experiment-name = "default-params-50k" [
    if ticks > 45000 [
      set total-end-red-gametes  total-end-red-gametes  + (count gametes with [color = red])
      set total-end-blue-gametes  total-end-blue-gametes  + (count gametes with [color = blue])
    ]
  ]

  ;; For the default parameters experiment, calculate a running average of the total gamete numbers
  ;;     over the last 5000 ticks
  if behaviorspace-experiment-name = "no-critical-mass-50k" [
    if ticks > 45000 [
      set total-end-red-gametes  total-end-red-gametes  + (count gametes with [color = red])
      set total-end-blue-gametes  total-end-blue-gametes  + (count gametes with [color = blue])
    ]
  ]

  ;; For the zygote critical mass experiment, calculate a running average of the total gamete numbers
  ;;     over the last 5000 ticks
  if behaviorspace-experiment-name = "critical-mass-500k" [
    if ticks > 495000 [
      set total-end-red-gametes  total-end-red-gametes  + (count gametes with [color = red])
      set total-end-blue-gametes  total-end-blue-gametes  + (count gametes with [color = blue])
    ]
  ]

  ;; For the zygote critical mass & gamete mutation heatmap experiment, calculate a running average of the total gamete numbers
  ;;     over the last 5000 ticks
  if behaviorspace-experiment-name = "zygote-critical-mass-gamete-mass-mutation-heatmap-500k" [
    if ticks > 495000 [
      set total-end-red-gametes  total-end-red-gametes  + (count gametes with [color = red])
      set total-end-blue-gametes  total-end-blue-gametes  + (count gametes with [color = blue])
    ]
  ]

  ;; For the zygote critical mass heat map experiment, calculate a running average of the total gamete numbers
  ;;     over the last 5000 ticks
  if behaviorspace-experiment-name = "gamete-zygote-critical-mass-heat-map-500k" [
    if ticks > 495000 [
      let mean-gamete-difference 0

      if count adults with [color = red] > 0 and count adults with [color = blue] > 0 [
        set mean-gamete-difference abs ((mean [gamete-mass] of adults with [color = red]) - (mean [gamete-mass] of adults with [color = blue]))
      ]

      ifelse is-list? mean-gamete-difference-list [
        set mean-gamete-difference-list lput mean-gamete-difference mean-gamete-difference-list
      ][
        set mean-gamete-difference-list list (0) (mean-gamete-difference)  ;;; We get rid of this 0 by using "but-first" in the behaviorspace reporter
      ]
    ]
  ]

  ;; For the speed-size relationship experiment
  ;;     Calculate the running average for the last 1000 whole ticks into these globals
  ;;            (the experiment is 10000 whole ticks long).
  ;;      ticks > 9000 only works for integer ticks.  ticks >= 9001 works for integer and partial ticks.
  ;;      doing ticks > 9000 in a partial-tick environment would give one extra sample.
  if behaviorspace-experiment-name = "speed-size-relationship-critical-mass" [
    if ticks >= 9001 and whole-tick? [
      set total-end-red-gametes total-end-red-gametes + (count gametes with [color = red])
      set total-end-blue-gametes total-end-blue-gametes + (count gametes with [color = blue])
      set sum-end-red-strategy sum-end-red-strategy + (mean [gamete-mass] of adults with [color = red])
      set sum-end-blue-strategy sum-end-blue-strategy + (mean [gamete-mass] of adults with [color = blue])
    ]
  ]

end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
280
10
613
344
-1
-1
5.0
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
20
10
86
43
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
95
10
158
43
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
625
10
900
145
population composition
ticks
# of agents
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Adults" 1.0 0 -9276814 true "" "plot count adults"
"Zygotes" 1.0 0 -11221820 true "" "plot count zygotes"
"Gametes" 1.0 0 -2064490 true "" "plot count gametes"

SWITCH
20
265
265
298
same-type-mating-allowed?
same-type-mating-allowed?
1
1
-1000

PLOT
905
10
1180
145
gamete mass trait distribution (int=0.025)
gamete mass
# of adults
0.0
0.5
0.0
10.0
true
true
"" ""
PENS
"Total" 0.025 1 -9276814 true "" "histogram [gamete-mass] of adults"
"MT-1" 0.025 1 -2674135 true "" "histogram [gamete-mass] of adults with [color = red]"
"MT-2" 0.025 1 -13345367 true "" "histogram [gamete-mass] of adults with [color = blue]"

SLIDER
20
55
265
88
zygote-critical-mass
zygote-critical-mass
0
1
0.45
0.01
1
NIL
HORIZONTAL

SWITCH
20
310
265
343
enforce-critical-mass?
enforce-critical-mass?
0
1
-1000

SLIDER
20
133
265
166
mutation-stdev
mutation-stdev
0
0.1
0.025
0.001
1
NIL
HORIZONTAL

PLOT
625
150
900
285
gamete population
ticks
# of gametes
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"MT-1" 1.0 0 -2674135 true "" "plot count gametes with [color = red]"
"MT-2" 1.0 0 -13345367 true "" "plot count gametes with [color = blue]"

MONITOR
625
295
772
340
# of MT-1 (red) Adults
count adults with [color = red]
17
1
11

MONITOR
780
295
937
340
# of MT-2 (blue) Adults
count adults with [color = blue]
17
1
11

SWITCH
20
180
190
213
speed-size-relation?
speed-size-relation?
1
1
-1000

SWITCH
20
220
190
253
adults-move?
adults-move?
0
1
-1000

PLOT
905
150
1180
285
average gamete mass trait
ticks
gamete mass
0.0
10.0
0.0
0.5
true
true
"" ""
PENS
"Total" 1.0 0 -9276814 true "" "plot mean [gamete-mass] of adults"
"MT-1" 1.0 0 -2674135 true "" "plot mean [gamete-mass] of adults with [color = red]"
"MT-2" 1.0 0 -13345367 true "" "plot mean [gamete-mass] of adults with [color = blue]"

SLIDER
20
93
265
126
gamete-critical-mass
gamete-critical-mass
0
zygote-critical-mass / 2 + 0.01
0.01
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Almost all of the animal and plant species that inhabit the earth today are _anisogamous_. There are only two dominant biological sexes (except the intersex individuals) and we define each sex based on the size and the quantity of the gametes they produce. Females produce few large gametes, often called _the egg_, while males produce numerous comparatively tiny gametes, called _the sperm_.

It is still not well-understood why anisogamy has evolved in the first place? Why not more than 2 sexes? Why not just one type of gamete? Why the number and size disparity between the sexes? Why anisogamy is so prevalent except only some fungi and unicellular organisms? Many theoretical models exist but none are universally accepted.

This model is a thought experiment that takes us to the world of a hypothetical vegetative ancestor (e.g., a proto-algae) that inhabited the oceans at the early stages of life on earth. The adult individuals of this ancestor are of two pseudo-sexes with the same reproductive strategy. This strategy, called _isogamy_ and observed in some fungal species today, means both mating types produce gametes of similar size and quantities.

This model allows us to explore possible evolutionary pathways that may have led to the emergence of anisogamy as an evolutionary stable strategy (ESS) within this early isogamous ancestor.

## HOW IT WORKS

Adults produce gametes at a fixed rate. The number of gametes produced by an adult is inversely proportional to the fixed gamete production budget, which is the same for all adults. In addition, each time an adult produces new gametes, the actual gamete size can be slightly different due to random mutation, which may then be passed on to this adult's offspring via its gametes.

The gametes move around randomly. When two gametes touch each other, they initiate a fusion process to form a zygote. The zygote inherits the total body mass (i.e., provisioning) of the gametes. However, it inherits the reproductive strategy (i.e., gamete size and mating type) and the corresponding color from either of the parent randomly.

The zygotes are non-mobile agents. They remain stationary and incubate for a fixed time. When they reach the end of their incubation period, they become adults if their mass is equal to or larger than the zygote critical mass. If a zygote does not have enough body mass to survive, it turns black and slowly dies off.

The two mating-types, MT-1 and MT-2, are represented with the red and blue colors respectively. The gametes are of the same colors, too. MT-1 adults produce red gametes and MT-2 adults produce blue gametes. When two gametes fuse, they form a zygote. If the zygote inherits the MT-1 mating-type trait, which is picked randomly during the fusion, it turns into a light red color. Otherwise, if it inherits the MT-2 mating type trait, it turns into a light blue color. The adults have a circle shape with a smaller black circle at the center. The gametes have an arrow-like shape. The zygotes have an egg-like shape. These shapes and colors allow us to observe the outcomes of the model more easily.

## HOW TO USE IT

The SETUP button creates the initial adult population randomly dispersed within the 2d world. Each adult in this initial population is assigned one of the mating types (MT-1 or MT-2) randomly. They all start with the same gamete size strategy, which is half of the fixed gamete production budget.

Once the model has been set up, you can press the GO button to run it. The GO button starts the simulation and runs it continuously until it is pushed again.

The ZYGOTE-CRITICAL-MASS slider controls the critical mass a zygote needs to have in order to survive into adulthood.

The MUTATION-STDEV slider controls the random mutation that may happen in gamete size every time an adult produces new gametes. A standard deviation is used because the mutation algorithm is based on a normal distribution with an expected value of the gamete size of the adult.

The SPEED-SIZE-RELATION? switch allows you to decide whether smaller gametes move faster than the larger gametes or all the gametes move at the same speed.

The ADULTS-MOVE? switch allows you to decide whether adults in the system move around or remain stationary.

The SAME-TYPE-MATING-ALLOWED? switch lets you choose whether or not gametes of the same mating type are allowed to fuse with each other.

The ENFORCE-CRITICAL-MASS? switch lets you override the critical mass assumption. When ON, the zygotes with low body mass die before reaching adulthood. When this switch is OFF, all zygotes survive regardless of the body mass.

## THINGS TO NOTICE

It takes quite some time to see any meaningful changes in the adults’ gamete size strategies. Even if it may seem like the isogamous population is stable, let the model run at least for 5000 to 10000 ticks.

Notice that even if the gamete size strategies of the red adults and the blue adults may evolve to be dramatically different, this does not disrupt the overall population balance. The number of the MT-1 adults and the number of the MT-2 adults stay relatively stable despite the dramatic shift in the gamete pool.

Notice that the number of zygotes stay relatively constant in the model, regardless of the changes in the gamete size strategies. Wait for the anisogamy to emerge as the new ESS in the model. You will notice that the number of gametes skyrocket but this does not affect the number of zygotes in the model in any substantial way.

## THINGS TO TRY

Try changing the mutation rate (MUTATION-STDEV) and see if it makes any difference in terms of the eventual outcome of the model. Is there a scenario where anisogamy does not evolve? Is there a scenario where it evolves even faster?

Would anisogamy still evolve even if gametes of the same mating type were allowed to fuse with each other (i.e., assortative mating)? Try turning on the SAME-TYPE-MATING-ALLOWED? switch and see how it affects the eventual outcome of the model.

Does the initial distribution of mating types have an impact on the eventual outcome of the model? Try to run the model multiple times and see if the initial number of red adults versus the initial number of blue adults impact the outcome of the model.

The ZYGOTE-CRITICAL-MASS value is set as 0.45 by default, which is just 0.05 less than the total reproduction budget of adults (0.5 or 50% of the total mass of an adult). Try modifying this value to discover whether smaller or larger critical masses requirements impact the evolutionary process in any significant ways.

## EXTENDING THE MODEL

There might be scenarios where a population might have more than 2 mating types. Try increasing the number of mating types in this model to explore if it will still evolve to an anisogamous state.

In the model, it is assumed that all gametes have relatively similar lifetimes. However, this is not the case for many organisms: often sperm have brief lives while eggs survive for a much longer period of time. What would happen if the smaller gametes in this model had a shorter lifetime and the larger gametes had longer lifetimes? Try to implement this in the model by creating an algorithm that calculates the lifetime of each gamete based on its size.

## NETLOGO FEATURES

The RANDOM-NORMAL primitive is used to simulate the random mutations in gamete size strategy between the generations of adults through a normal distribution. The lifetime of adults and gametes, as well as the incubation time of zygotes, are also randomly selected from a normal distribution.

The DIFFUSE primitive is used to create a background that transitions from darker to lighter tones of cyan fluidly. This background represents a marine environment.

The PRECISION primitive is used to limit the number of floating point numbers in the size of gametes. This is a synthetic measure to prevent the model from evolving to a state where too many gametes are produced and the performance of the simulation is negatively affected.

The INSPECT and the STOP-INSPECTING-DEAD-AGENTS primitives are used to allow users to follow randomly selected gametes so that they can better observe gametes’ behavior at the individual level since the gametes are often hard to see in this model.

## RELATED MODELS

* Genetic drift models
* BEAGLE Evolution curricular models
* EACH curricular models

## CREDITS AND REFERENCES

Bulmer, M. G., & Parker, G. A. (2002). The evolution of anisogamy: a game-theoretic approach. Proceedings of the Royal Society B: Biological Sciences, 269(1507), 2381–2388. https://royalsocietypublishing.org/doi/abs/10.1098/rspb.2002.2161

Togashi, T., & Cox, P. A. (Eds.). (2011). The evolution of anisogamy: a fundamental phenomenon underlying sexual selection. Cambridge University Press.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Aslan, U., Dabholkar, S., Woods, P. and Wilensky, U. (2016).  NetLogo Anisogamy model.  http://ccl.northwestern.edu/netlogo/models/Anisogamy.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 Cite: Aslan, U., Dabholkar, S., Woods, P. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

adult
false
15
Circle -1 true true 22 20 248
Circle -7500403 true false 108 106 72
Circle -16777216 true false 122 120 44

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

gamete
true
0
Polygon -7500403 true true 150 5 40 250 150 285 260 250

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

zygote
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="critical-mass-500k" repetitions="6" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500000"/>
    <metric>total-end-red-gametes / 5000</metric>
    <metric>total-end-blue-gametes / 5000</metric>
    <metric>mean [gamete-mass] of adults with [color = red]</metric>
    <metric>mean [gamete-mass] of adults with [color = blue]</metric>
    <steppedValueSet variable="zygote-critical-mass" first="0.01" step="0.01" last="0.5"/>
    <enumeratedValueSet variable="same-type-mating-allowed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforce-critical-mass?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adults-move?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-size-relation?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-stdev">
      <value value="0.025"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="default-params-50k" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>total-end-red-gametes / 5000</metric>
    <metric>total-end-blue-gametes / 5000</metric>
    <metric>mean [gamete-mass] of adults with [color = red]</metric>
    <metric>mean [gamete-mass] of adults with [color = blue]</metric>
    <enumeratedValueSet variable="same-type-mating-allowed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforce-critical-mass?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adults-move?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-size-relation?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-stdev">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zygote-critical-mass">
      <value value="0.45"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="no-critical-mass-50k" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>total-end-red-gametes / 5000</metric>
    <metric>total-end-blue-gametes / 5000</metric>
    <metric>mean [gamete-mass] of adults with [color = red]</metric>
    <metric>mean [gamete-mass] of adults with [color = blue]</metric>
    <enumeratedValueSet variable="same-type-mating-allowed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforce-critical-mass?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adults-move?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-size-relation?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-stdev">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zygote-critical-mass">
      <value value="0.45"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="zygote-critical-mass-gamete-mass-mutation-heatmap-500k" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500000"/>
    <metric>total-end-red-gametes / 5000</metric>
    <metric>total-end-blue-gametes / 5000</metric>
    <metric>mean [gamete-mass] of adults with [color = red]</metric>
    <metric>mean [gamete-mass] of adults with [color = blue]</metric>
    <steppedValueSet variable="zygote-critical-mass" first="0.05" step="0.05" last="0.5"/>
    <enumeratedValueSet variable="same-type-mating-allowed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforce-critical-mass?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adults-move?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-size-relation?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="mutation-stdev" first="0.005" step="0.005" last="0.05"/>
  </experiment>
  <experiment name="gamete-zygote-critical-mass-heat-map-500k" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500000"/>
    <metric>mean (but-first mean-gamete-difference-list)</metric>
    <enumeratedValueSet variable="same-type-mating-allowed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforce-critical-mass?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adults-move?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="gamete-critical-mass" first="0.01" step="0.01" last="0.3"/>
    <enumeratedValueSet variable="speed-size-relation?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-stdev">
      <value value="0.025"/>
    </enumeratedValueSet>
    <steppedValueSet variable="zygote-critical-mass" first="0.05" step="0.05" last="0.45"/>
  </experiment>
  <experiment name="speed-size-relationship-critical-mass" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>(ticks &gt;= 10000) and whole-tick?</exitCondition>
    <metric>total-end-red-gametes / 1000</metric>
    <metric>total-end-blue-gametes / 1000</metric>
    <metric>sum-end-red-strategy / 1000</metric>
    <metric>sum-end-blue-strategy / 1000</metric>
    <enumeratedValueSet variable="same-type-mating-allowed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforce-critical-mass?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adults-move?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gamete-critical-mass">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-size-relation?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-stdev">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zygote-critical-mass">
      <value value="0.45"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="default-parameters-with-screenshots" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go
if ticks mod 500 = 0 [ export-interface (word "output/screenshots/" ticks "ticks.png")]</go>
    <timeLimit steps="20000"/>
    <metric>mean [gamete-mass] of adults with [color = red]</metric>
    <metric>standard-deviation [gamete-mass] of adults with [color = red]</metric>
    <metric>count adults with [color = red]</metric>
    <metric>mean [gamete-mass] of adults with [color = blue]</metric>
    <metric>standard-deviation [gamete-mass] of adults with [color = blue]</metric>
    <metric>count adults with [color = blue]</metric>
    <enumeratedValueSet variable="same-type-mating-allowed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforce-critical-mass?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adults-move?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gamete-critical-mass">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-size-relation?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-stdev">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="zygote-critical-mass">
      <value value="0.45"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
