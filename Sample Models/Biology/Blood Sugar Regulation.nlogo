; All initialization / setup values are derived from real-world figures.
; I arrived at these values using estimates of resting blood sugar levels
; (80 mg/dL), post-meal blood sugar levels (120 mg/dL), human blood volume
; (5L), daily caloric intake (2000 kcal), average nutrient absorption period
; after a meal (2 hours), and starvation time (3 weeks).  Starting with the
; observations that the model's resting blood sugar level is about 4000 and
; adding glucoses at about 400 per tick raises the stable blood sugar by
; about 1.5 times, it is possible to derive the correspondence between
; glucose particles and mg glucose as well as reasonable meal sizes, the
; correspondence between ticks and seconds, meal lengths, metabolic rates,
; and initial glucose reserves. However, this ideal correspondence results
; in an enormous initial glucose store (10.5 million) and time to starvation
; in the model (105k ticks), so I have scaled the glucose energy density
; correspondence by about 1/25. This means that one tick represents about
; 7 minutes, and one glucose represents about 25 mg of real glucose,
; equivalent to 0.1 kcal. This is a fairly high grain size for both time and
; energy.  This also means that the blood sugar levels in the model are
; unusually high if scaled up to a real person, but most other times,
; relationships, and rates correspond properly to the real world within an
; order of magnitude. Most of the inaccuracies help to mitigate the negative
; effects of the high grain size noted earlier. I also accelerated starvation
; for ease of observation by reducing the initial store of glucose.

globals [
  molecule-size     ; display scaling constant
  hormone-half-life
  hormone-mean-life
  eating?           ; keep track of meal state based on EAT button presses
  eat-time          ; keep track of ongoing meal duration
  total-glucose     ; storage variable to record combined blood and stored glucose
  glucose-baseline  ; average 'normal' number of glucoses in the blood per cell
  meal-size
  meal-length
]

; Set up different cell breeds.
; We need different cell types to behave differently.
; This is why cells are turtles rather than patches.
breed [ liver-cells liver-cell ]
breed [ pancreatic-cells pancreatic-cell ]

; Set up different molecule breeds
breed [ glucoses glucose ]
breed [ insulins insulin ]
breed [ glucagons glucagon ]

liver-cells-own [ glucose-store ]
insulins-own [ lifetime ]
glucagons-own [ lifetime ]

to setup
  clear-all

  set-default-shape turtles "circle outline"
  set molecule-size 0.25
  set eat-time 0
  set eating? false

  ; These values are calibrated to establish a reasonable correspondence for
  ; energy density and time between the model and the real world system.
  ; See the comment at the top of the file for more information.
  set glucose-baseline 3 ; Controls the normal blood glucose level.
  set hormone-half-life 2 ; Corresponds to 14 minutes, roughly twice insulin.
  set hormone-mean-life hormone-half-life / ln 2 ; From exponential distribution.
  set meal-size 7000 ; Corresponds to about 1/3 of daily caloric intake.
  set meal-length 17 ; Nutrient absorption period. Corresponds to about 2 hours.

  ; Set up organs
  make-liver
  make-pancreas

  let world-area (2 * max-pxcor + 1) * (2 * max-pycor + 1)

  ; Make initial molecules at approximately their stable concentrations.
  create-glucoses world-area * (glucose-baseline + 1) [
    random-position
    set color white
    set size molecule-size
  ]
  ; Hormones typically follow exponential decay, so their lifetimes
  ; are randomly drawn from an exponential distribution. This also
  ; makes the least assumptions, since the exponential distribution
  ; is the maximum-entropy distribution for a fixed, positive mean.
  create-insulins round (world-area / 3) [
    random-position
    set color sky
    set size molecule-size * 2
    set lifetime random-exponential hormone-mean-life
  ]
  create-glucagons round (world-area / 3) [
    random-position
    set color red
    set size molecule-size * 2
    set lifetime random-exponential hormone-mean-life
  ]

  ; keep track of the body's fuel
  set total-glucose (count glucoses) + sum ([glucose-store] of liver-cells)

  reset-ticks
end

to go
  if (total-glucose = 0) [
    user-message "The body ran out of glucose."
    stop
  ]

  ; Keeps track of the EAT button presses
  if eating? [ add-glucose ]

  ; Liver detects hormones and absorbs / releases glucose
  ask liver-cells [ adjust-glucose ]

  ; Pancreas detects glucose and maybe releases insulin / glucagon
  ask pancreatic-cells [ adjust-hormones ]

  metabolize-glucose
  signal-degradation

  ; Ask signals to move
  ask insulins [ move ]
  ask glucagons [ move ]
  ask glucoses [ move ]

  ; Keep track of the body's fuel
  set total-glucose (count glucoses) + sum ([glucose-store] of liver-cells)

  tick
end

;----------- eat button ---------------
; Adds one meal's worth of glucose over the course of the defined meal time.

; Button procedure
; Either starts a new meal or extends a current meal.
to eat
  set eating? true
  set eat-time eat-time + meal-length
end

; Implements eating process. Adds one meal's worth of glucose at
; a constant rate, spread across the whole length of a meal.
to add-glucose
  create-glucoses (meal-size / meal-length) [
    random-position
    set color white
    set size molecule-size
  ]
  set eat-time eat-time - 1
  if eat-time < 1 [ set eating? false ]
end

;------------ setup helpers ---------------

; Particle procedure
; Place molecule at random location
to random-position
  setxy (min-pxcor + random-float (max-pxcor * 2))
        (min-pycor + random-float (max-pycor * 2))
end

; Sets up liver cells
to make-liver
  ask patches with [ pxcor < round (max-pxcor / 2) ] [
    sprout-liver-cells 1 [
      set shape "square 2"
      set color brown + 2
      set glucose-store random-poisson 150 ; Enough to survive for about a week.
    ]
  ]
end

; Sets up pancreatic cells
to make-pancreas
  ask patches with [ pxcor >= round (max-pxcor / 2) ] [
    sprout-pancreatic-cells 1 [
      set shape "square 2"
      set color yellow - 1
    ]
  ]
end

; ----------- signal procedures ------------

; Molecule procedure
to move
  rt random 90
  lt random 90
  fd 1
end

; Observer procedure
to signal-degradation
  ask insulins [
    set lifetime lifetime - 1
    if (lifetime <= 0) [ die ]
  ]
  ask glucagons [
    set lifetime lifetime - 1
    if (lifetime <= 0) [ die ]
  ]
end

; Observer procedure
to metabolize-glucose
  ifelse (count glucoses >= metabolic-rate) [
    ask n-of metabolic-rate glucoses [ die ]
  ] [
    ask glucoses [ die ]
  ]
end

;---------------- cell procedures ---------------
; Both cell types implement signal sensitivity using the binomial distribution.
; In this context, each signal's sensitivity slider directly governs the
; probability that a cell will detect the presence of that signal when it is
; present. Lowering the sensitivity makes cells more likely to miss signals.
; The binomial distribution gives the probability that a cell will detect k signals
; when n signals are present, given a detection probability p for each signal.
; This can be used to produce likely signal counts (or k's) for a cell with n
; signal molecules present and a given signal sensitivity.

; Liver procedure
; Releases or sequesters glucose based on the local hormone concentrations.
to adjust-glucose
  ; Detect hormones according to a binomial distribution based on their sensitivities.
  let insulin-count random-binomial (count insulins-here) insulin-sensitivity
  let glucagon-count random-binomial (count glucagons-here) glucagon-sensitivity

  ; A positive net signal means we release glucose.
  ; The stronger the signal (the larger the absolute value),
  ; the more glucose is released or sequestered.
  let net-signal glucagon-count - insulin-count

  ; If there is more glucagon signal than insulin signal, release glucose.
  if net-signal > 0 [
    ifelse (glucose-store >= net-signal) [
      ; If there is a lot of glucose stored in the cell, hatch new glucose molecules.
      hatch-glucoses net-signal [
        random-position
        set color white
        set size molecule-size
      ]
      ; Account for the change in stored glucose (net-signal > 0).
      set glucose-store glucose-store - net-signal
    ] [
      ; If there is not enough glucose stored in the cell, release as much as possible.
      hatch-glucoses glucose-store [
        random-position
        set color white
        set size molecule-size
      ]
      set glucose-store 0
    ]
  ]
  ; If there is more insulin signal than glucagon signal, sequester glucose.
  if net-signal < 0 [
    ifelse (count glucoses >= abs net-signal) [
      ; If there's a lot of blood glucose, sequester what you need (net-signal < 0).
      set glucose-store glucose-store - net-signal
      ask n-of abs net-signal glucoses [ die ]
    ] [
      ; If there's not ehough blood glucose, sequester as much as possible.
      set glucose-store glucose-store + count glucoses
      ask glucoses [ die ]
    ]
  ]
end

; Pancreas procedure
; Produces hormones according to the local glucose concentration.

; Hormones typically follow exponential decay, so their lifetimes
; are randomly drawn from an exponential distribution. This also
; makes the least assumptions, since the exponential distribution
; is the maximum-entropy distribution for a fixed, positive mean.
to adjust-hormones
  ; Detect glucose according to a binomial distribution based on the sensitivity.
  let glucose-count random-binomial (count glucoses-here) glucose-sensitivity
  ; Signal strength is determined by the difference in concentration from normal.
  let signal-count abs (glucose-baseline - glucose-count)

  ; If there are too few glucoses...
  if (glucose-count < glucose-baseline) [
    ; ...release glucagon molecules.
    hatch-glucagons signal-count [
      random-position
      set color red
      set size molecule-size * 2
      set lifetime random-exponential hormone-mean-life
    ]
  ]
  ; If there are too many glucoses...
  if (glucose-count > glucose-baseline) [
    ; ...release insulin molecules.
    hatch-insulins signal-count [
      random-position
      set color sky
      set size molecule-size * 2
      set lifetime random-exponential hormone-mean-life
    ]
  ]
end

;------------- follow procedures -------------

to follow-glucose
  watch one-of glucoses
end

to follow-insulin
  watch one-of insulins
end

to follow-glucagon
  watch one-of glucagons
end

;---------------- math helpers ----------------

; Returns the outcome of a Bernoulli trial with success probability p.
; Successes are reported as 1 and failures are reported as 0.
to-report random-bernoulli [ p ]
  report ifelse-value random-float 1 < p [1] [0]
end

; Returns a random number according to the binomial distribution with parameters n and p
; where n is the number of trials and p is the probability of success in each trial.
to-report random-binomial [n p]
  if (n < 0) or not (int n = n) [
    error "Input n must be a non-negative integer."
  ]
  if (p < 0) or (p > 1) [
    error "Probability p must be between 0 and 1."
  ]

  ; Sum the number of successes in n Bernoulli trials with success probability p.
  report sum n-values n [random-bernoulli p]
end


; Copyright 2017 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
395
15
832
453
-1
-1
13.0
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

BUTTON
70
15
145
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
160
15
235
48
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
250
15
325
48
NIL
eat
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
15
105
190
138
metabolic-rate
metabolic-rate
0
200
100.0
10
1
NIL
HORIZONTAL

SLIDER
15
145
190
178
glucose-sensitivity
glucose-sensitivity
0
1
0.75
0.05
1
NIL
HORIZONTAL

SLIDER
205
105
380
138
insulin-sensitivity
insulin-sensitivity
0
1
0.75
0.05
1
NIL
HORIZONTAL

SLIDER
205
145
380
178
glucagon-sensitivity
glucagon-sensitivity
0
1
0.75
0.05
1
NIL
HORIZONTAL

PLOT
15
245
380
455
signal molecules
ticks
counts
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"glucose" 1.0 0 -16777216 true "" "plot (count glucoses)"
"insulin" 1.0 0 -13791810 true "" "plot (count insulins)"
"glucagon" 1.0 0 -2674135 true "" "plot (count glucagons)"

MONITOR
185
190
275
235
blood glucose
count glucoses
17
1
11

MONITOR
15
190
90
235
insulin
count insulins
17
1
11

MONITOR
100
190
175
235
glucagon
count glucagons
17
1
11

BUTTON
15
60
130
93
NIL
follow-glucose
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
140
60
255
93
NIL
follow-insulin
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
265
60
380
93
NIL
follow-glucagon
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
285
190
380
235
stored glucose
sum ([glucose-store] of liver-cells)
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is an agent-based model of blood glucose regulation by the liver and pancreas through the production of the hormones insulin and glucagon.

This model represents cells as square patches which are either brown (liver cells) or yellow (pancreatic cells), aligning with typical textbook depictions of these organs.  These two tissues work together to regulate the levels of the signal molecules glucose (white dots), insulin (blue dots), and glucagon (red dots) in the bloodstream.  For simplicity, the model does not explicitly show blood vessels, instead representing molecule motion through diffusion.

The model demonstrates how glucose homeostasis is maintained in the body through feedback loops even without direction from a central regulator.  It also demonstrates how a variety of conditions like physical activity, eating, or metabolic disorders can affect this homeostasis.  Under each of these conditions, the blood sugar level emerges from the interactions between cells and signal molecules.

## HOW IT WORKS

This model uses two broad classes of agents.  The first is cells, and the second is signal molecules.

Liver cells (brown squares) and pancreatic cells (yellow squares) are arranged into a body.  In response to low glucose levels, pancreatic cells produce glucagon (red dots). In response to high glucose levels, they produce insulin (blue dots).  Liver cells detect the levels of insulin and glucagon and either sequester glucose (white dots) from the bloodstream or release stored glucose depending on the balance of the hormones. Liver cells also begin with a store of glycogen within themselves which can provision the body for several days.  This system relies on feedback loops between the liver and the pancreas to regulate the level of glucose in the blood.  This creates a dynamic equilibrium which has minor fluctuations but will generally maintain a constant amount of glucose in the bloodstream.

The behavior of the cells is also dependent on their sensitivity to the different signal molecules.  When the cells are not very sensitive to a particular signal, they are not very good at detecting the presence of those signal molecules.  This means it will typically take more of those signal molecules to produce a particular response from the cell.

The signal molecules produced by the cells move through the world by a random walk that simulates their diffusion through the body in the bloodstream.

Over time, the body's metabolism will burn through the glucose in the blood and the glycogen stored in the liver cells.  This glucose can be replenished using the `EAT` button, which simulates nutrients being absorbed by the digestive system after a meal.  This means that glucose will be added in small amounts over time, like in the real world.  Eating several meals all in a row will not add glucose any more quickly, but it will increase the amount of time over which glucose is added.  This mirrors how people take longer to digest after eating more food.

The model has some unavoidable differences from the real world.  For example, real bodies will also have some blood sugar fluctuations, but the fluctuation in this model is mainly because it is has a higher grain size than a real body.  Single ticks in the model correspond to a fairly long time (about 400 seconds), meaning that adjustments in the model take much longer than they would in a real body.  Also, because there are fewer molecules in the model than there are in a body, differences of only one or two molecules can have a much larger impact in the model than they would in a body.

## HOW TO USE IT

This model can be used to examine the effects of a variety of factors on glucose homeostasis.  One of the most common factors that might affect this is activity level or exercise.  You can simulate changes in this by adjusting the `METABOLIC-RATE` slider.  Another common factor that influences homeostasis is eating, which can be simulated by pressing the `EAT` button.

Other interesting factors that can be simulated include metabolic disorders.  These can be simulated by adjusting the `GLUCOSE-SENSITIVITY`, `INSULIN-SENSITIVITY`, and `GLUCAGON-SENSITIVITY` sliders.

This model makes it easy to explore how different factors affect the body's homeostasis and how the body responds to food.  The best way to observe these changes is by looking at the `SIGNAL MOLECULES` plot in the bottom left corner.  Anything you change will affect this plot, which shows the amount of glucose, insulin, and glucagon in the blood over time.

### Buttons
`SETUP`:  Initializes variables and creates the initial cells and molecules.
`GO`:  Runs the model.
`EAT`:  Simulates eating by adding glucose to the bloodstream over a short period.

`FOLLOW-GLUCOSE`:  Highlights a glucose molecule until it is consumed or sequestered.
`FOLLOW-INSULIN`:  Highlights an insulin molecule until it is broken down.
`FOLLOW-GLUCAGON`:  Highlights a glucagon molecule until it is broken down.

### Sliders
`METABOLIC-RATE`:  The number of glucose molecules consumed by the body on each tick.
`GLUCOSE-SENSITIVITY`:  The probability that pancreatic cells will detect a glucose molecule that is present.
`INSULIN-SENSITIVITY`:  The probability that liver cells will detect an insulin molecule that is present.
`GLUCAGON-SENSITIVITY`:  The probability that liver cells will detect a glucagon molecule that is present.

### Monitors
`INSULIN`:  Shows the number of insulin molecules in the bloodstream.
`GLUCAGON`:  Shows the number of glucagon molecules in the bloodstream.
`BLOOD GLUCOSE`:  Shows the number of glucose molecules in the bloodstream.
`STORED GLUCOSE`:  Shows the number of glucose molecules stored in the liver.

### Plots
`SIGNAL MOLECULES`:  Shows the counts of glucose, insulin, and glucagon in the bloodstream.

## THINGS TO NOTICE

Look at the `SIGNAL MOLECULES` plot while the model runs.  This plot shows the amount of glucose, insulin, and glucagon in the bloodstream over time.  Do the levels of these molecules change very much over time?

The monitors just above this plot show the current level of each signal molecule in the bloodstream precisely.  The rightmost monitor shows the current amount of glucose stored in the liver.  How does this glucose reserve change over time?  How is this reserve affected by the metabolic rate?  How is it affected by eating?  How does this compare with your real world experience?

Eating can affect several parts of the body.  When you click the `EAT` button, do the glucose, insulin, and glucagon levels in the blood increase or decrease?  How big is this change compared to the baseline levels?  How long does it take before they return to their baseline levels?  Why do you think the levels of these molecules change in this specific way?

What happens if the body goes too long without eating?

Normal blood insulin levels are around 68 pmol/L and normal blood glucagon levels are around 22 pmol/L.  How does this compare to what you see in the model?  Can you explain any differences you observe?

## THINGS TO TRY

The default sensitivity values are meant to mimic a healthy metabolism.  Try to model type 2 diabetes, where the body's ability to detect insulin is dramatically reduced, by changing the sensitivity sliders.  What do you notice about the baseline glucose and hormone levels?  Are they higher or lower than in a healthy metabolism?  How much higher or lower are they?  Why do you think this happens?

When you eat there is a small spike in blood glucose.  How big is the spike compared to the baseline glucose level?  What changes about this spike in a diabetic metabolism as compared to a healthy metabolism?  Is the spike taller in a healthy metabolism or in a diabetic metabolism?  How long does each metabolism take to get back to a normal blood glucose level?

## EXTENDING THE MODEL

In this model all pancreatic cells are identical and release both hormones, but in the body they are differentiated into several types which each release only one hormone.  Does this change the model's behavior?

The sliders in this model can effectively simulate type 2 diabetes, which results from low insulin sensitivity.  How could you model type 1 diabetes, which results from insufficient production of insulin?

There are many other hormones which also play a role in metabolism.  For example, GLP-1 promotes insulin release, cortisol antagonizes insulin, and somatostatin suppresses the release of several hormones including insulin and glucagon.  Does adding more signal molecules noticeably change the regulation of blood glucose?

The bloodstream also carries other nutrients like amino acids or fatty acids, which are regulated and interconverted based on the concentrations of these hormones.  How do these nutrients affect the hormone and glucose levels?  How does the composition of food intake affect hormone and glucose levels?

## NETLOGO FEATURES

NetLogo buttons typically cause a procedure to occur exactly once when the button is pressed or 'forever', meaning once each tick until the button is pressed a second time.  The `EAT` button in conjunction with the `add-glucose` procedure allows a button to run a procedure once every tick for the next N ticks.

This model also implements a new function `random-binomial` in the style of the NetLogo primitives `random-normal`, `random-poisson`, etc. which takes in the defining parameters `n` and `p` and outputs a binomial-distributed random number. This method of combining random number generators to define a new random number generator can be applied generally to form many distributions beyond NetLogo's built in capabilities.

## RELATED MODELS

Checkout some of the other Biology models in the Models Library for similar models of other biological phenomenon.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Woods, P. and Wilensky, U. (2017).  NetLogo Blood Sugar Regulation model.  http://ccl.northwestern.edu/netlogo/models/BloodSugarRegulation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2017 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2017 Cite: Woods, P. -->
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

circle outline
false
0
Circle -16777216 true false 0 0 300
Circle -7500403 true true 30 30 240

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
Rectangle -7500403 true true 0 0 300 300

square outline
false
0
Rectangle -16777216 true false 0 0 300 300
Rectangle -7500403 true true 15 15 285 285

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
