globals [
  mammoths-killed-by-humans         ; counter to keep track of the number of mammoths killed by humans
  mammoths-killed-by-climate-change ; counter to keep track of the number of mammoths killed by climate change
]

breed [ mammoths mammoth ]
breed [ humans human ]

humans-own [ settled? ]
turtles-own [ age ]

to setup

  clear-all
  ask patches [ set pcolor blue - 0.25 - random-float 0.25 ]
  import-pcolors "Americas.png"
  ask patches with [ not shade-of? blue pcolor ] [
    ; if you're not part of the ocean, you are part of the continent
    set pcolor green
  ]

  set-default-shape mammoths "mammoth"
  create-mammoths number-of-mammoths [
    set size 2
    set color brown
    set age random (30 * 12)  ; average mammoth age is 15
    move-to one-of patches with [ pcolor = green ]
  ]

  set-default-shape humans "person"
  create-humans number-of-humans [
    set size 2
    set color yellow
    move-to one-of patches with [ pcolor = green and pxcor <= 10 ]
    set heading -5 + random 10 ; generally head east
    set settled? false
    set age random (50 * 12) ; average human age is 25
  ]

  set mammoths-killed-by-climate-change 0
  set mammoths-killed-by-humans 0

  reset-ticks
end

to go

  ask patches with [ pcolor = green ] [
    ; at each step, patches have a small chance
    ; to become inhospitable for mammoths
    if random-float 100 < climate-change-decay-chance [
      set pcolor green + 3
    ]
  ]

  ; mammoths move and reproduce
  ask mammoths [
    move mammoth-speed
    ; mammoths reproduce after age 3
    reproduce (3 * 12) mammoth-birth-rate
  ]
  ; humans decide whether to move or settle where
  ; they are, and then they hunt and reproduce
  ask humans [
    let mammoths-nearby mammoths in-radius 5
    ; humans have a chance of settling proportional to the
    ; number of mammoths in their immediate vicinity
    if not settled? and random 100 < count mammoths-nearby [
      set settled? true
    ]
    if not settled? [
      if any? mammoths-nearby [
        face min-one-of mammoths-nearby [ distance myself ]
      ]
      move human-speed
    ]
    if any? mammoths-here [
      let r random 100
      if r < 3 [ die ] ; mammoths have a 3% chance of killing the human
      if r < 3 + odds-of-killing [
        ask one-of mammoths-here [ die ] ; successfully hunt a mammoth!
        set mammoths-killed-by-humans mammoths-killed-by-humans + 1
      ]
    ]
    reproduce (12 * 12) human-birth-rate ; humans reproduce after age 12
  ]
  die-naturally ; mammoths and humans die if they're old or crowded
  ask turtles [ set age age + 1 ]
  tick
end

to move [ dist ] ; human or mammoth procedure
  right random 30
  left random 30
  ; avoid moving into the ocean or outside the world by turning
  ; left (-10) or right (10) until the patch ahead is not an ocean patch
  let turn one-of [ -10 10 ]
  while [ not land-ahead dist ] [
    set heading heading + turn
  ]
  forward dist
end

to-report land-ahead [ dist ]
  let target patch-ahead dist
  report target != nobody and shade-of? green [ pcolor ] of target
end

to reproduce [ min-age birth-rate ]
  if age >= min-age and random 100 < birth-rate [
    hatch 1 [
      set age 0
      if breed = humans [ set settled? false ]
    ]
  ]
end

to die-naturally

  ask humans [
    ; humans have a 5% chance of dying if they're over 50
    if age > 50 * 12 and random-float 100 < 5 [ die ]
    ; they also get another 5% chance of dying if their density is too high
    if density > 0.75 and random-float 100 < 5 [ die ]
    ; in addition, all humans have a 0.33% chance of dying.
    if random-float 100 < 0.33 [ die ]
  ]

  ask mammoths [
    ; mammoths have a 5% chance of dying if they're over 30
    if age > 30 * 12 and random-float 100 < 5 [ die ]
    ; they also get another 5% chance of dying if their density is too high
    if density > 0.50 and random-float 100 < 5 [ die ]
    ; if they are on a patch affected by climate change, they get a 5% chance of dying
    if [ pcolor ] of patch-here = green + 3 and random-float 100 < 5 [
      set mammoths-killed-by-climate-change mammoths-killed-by-climate-change + 1
      die
    ]
    ; finally, all mammoths have a 0.33% chance of dying.
    if random-float 100 < 0.33 [ die ]
  ]

end

to-report density ; turtle reporter
  let nearby-turtles (turtle-set turtles-on neighbors turtles-here)
  report (count nearby-turtles with [ breed = [ breed ] of myself ]) / 9
end


; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
375
15
965
606
-1
-1
6.0
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
96
0
96
1
1
1
months
30.0

MONITOR
40
355
120
400
years
ticks / 12
0
1
11

SLIDER
10
240
365
273
human-birth-rate
human-birth-rate
0
20
10.0
1
1
%
HORIZONTAL

SLIDER
10
205
365
238
mammoth-birth-rate
mammoth-birth-rate
0
10
2.0
1
1
%
HORIZONTAL

SLIDER
10
275
365
308
odds-of-killing
odds-of-killing
1
97
12.0
1
1
%
HORIZONTAL

SLIDER
10
50
365
83
number-of-humans
number-of-humans
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
10
15
365
48
number-of-mammoths
number-of-mammoths
100
2000
900.0
1
1
NIL
HORIZONTAL

BUTTON
120
95
180
128
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
205
95
265
128
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

PLOT
10
405
365
580
Population
Months
Frequency
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"mammoths" 1.0 0 -6459832 true "" "plot count mammoths"
"humans" 1.0 0 -16777216 true "" "plot count humans"

SLIDER
10
135
365
168
human-speed
human-speed
0
1
0.3
0.05
1
patches
HORIZONTAL

SLIDER
10
170
365
203
mammoth-speed
mammoth-speed
0
1
0.2
0.05
1
patches
HORIZONTAL

MONITOR
245
355
340
400
humans
count humans
17
1
11

MONITOR
125
355
240
400
mammoths
count mammoths
17
1
11

SLIDER
10
310
365
343
climate-change-decay-chance
climate-change-decay-chance
0.001
0.1
0.003
0.001
1
%
HORIZONTAL

PLOT
10
585
365
770
Cause of Mammoth Deaths
Months
Frequency
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"humans" 1.0 0 -16777216 true "" "plot mammoths-killed-by-humans"
"climate change" 1.0 0 -7500403 true "" "plot mammoths-killed-by-climate-change"

@#$#@#$#@
## WHAT IS IT?

A prevailing theory says that Native Americans descended from prehistoric hunters who walked from northeast Asia across a land bridge, formed at the end of the Ice Age, to Alaska some 12,000 years ago. Fossil evidence shows that before their arrival, there were large mammals in the Americas. The oldest mammoth fossils date the mammoths to 11,400 years ago, a little over a thousand years after the migration. This model illustrates two theories of how these megafaunal species quickly became extinict: the hunting theory and the climate change theory.

The hunting theory states that Native Americans who arrived in the "New World" were responsible for the extinction of the large mammals of the Americas such as the American lion, tiger and mammoth. This theory is advanced by Jared Diamond in his book: _The Third Chimpanzee_. The basic premise of the theory is that American large mammals evolved without human contact, so they were tame and unafraid of the migrating humans, allowing a high probability of successful hunting by the humans. This could account for the very rapid simultaneous extinction of all American large mammals at roughly the same time as the human arrival.

The climate change theory states that unexpected rapid climate changes associated with [interstadial](https://en.wikipedia.org/wiki/Stadial) warming events occurred during this period, and suggests that the metapopulation structures (e.g. habitat, food and water sources, etc.) necessary to survive such repeated and rapid climatic shifts were susceptible to human impacts.

This model is highly stylized: mammoths are a stand-in for all large mammals that were affected by hunting and climate change. In reality, there were no mammoths in South America. The way climate change operates in the model (by making random patches inhospitable for mammoths) is not realistic either. Still, the model nicely illustrates how NetLogo can be used to compare the effect of two competing processes.

## HOW IT WORKS

Humans enter North America from Alaska. They hunt mammoths and have a high chance of killing them. Mammoths also have a 3% chance of killing humans. Both humans and mammoths reproduce according to the MAMMOTH-BIRTH-RATE and HUMAN-BIRTH-RATE sliders.

Both mammoths and humans die naturally from old age or from too much overcrowding. In addition, based on the CLIMATE-CHANGE-DECAY-CHANCE, each habitable patch has a chance of being affected by climate change. Patches that are affected by climate change turn a light green color and mammoths on these patches have a higher chance of dying naturally.

## HOW TO USE IT?

The NUMBER-OF-MAMMOTHS slider sets the initial number of mammoths.

The NUMBER-OF-HUMANS slider sets the initial number of human hunters.

SETUP initializes the mammoths and people.

GO starts and stops the simulation.

The HUMAN-SPEED slider sets the distance, in patches, that a human can travel each month.

The MAMMOTH-SPEED slider sets the distance, in patches, that a mammoth can travel each month.

The MAMMOTH-BIRTH-RATE slider sets the likelihood of a mammoth reproducing each month.

The HUMAN-BIRTH-RATE slider sets the likelihood of a human reproducing each month.

The ODDS-OF-KILLING slider sets the odds that when a human encounters a mammoth, the mammoth will die.

The CLIMATE-CHANGE-DECAY-CHANCE slider sets the likelihood of a green patch being affect by climate change and becoming inhospitable for mammoths.

The YEARS monitor displays elapsed years in the model.

The COUNT HUMANS monitor shows the current number of humans, and the COUNT MAMMOTHS monitor shows the current number of mammoths.

These counts are also dynamically plotted in the POPULATION plot.

## THINGS TO NOTICE

Notice the rate of migration of the humans. How does that affect the population of mammoths?

Notice the rate of mammoth decline. How many years does it take for them to go extinct?

## THINGS TO TRY

Vary the ODDS-OF-KILLING. How does that affect the mammoth population?

Vary the ratio of MAMMOTH-SPEED and HUMAN-SPEED. How does that affect the mammoth population?

Vary the MAMMOTH-BIRTH-RATE and HUMAN-BIRTH-RATE. How does that affect the mammoth and human populations?

Vary the CLIMATE-CHANGE-DECAY-CHANCE slider. How does that affect the number of mammoth deaths due to hunting?

## EXTENDING THE MODEL

Make separate monitors for North and South America.

What if Central America weren't so narrow?  Do you think that it, or other geographical features, could block human hunters the way this model works?

How would adding islands affect the model?

Make the movement of the humans and mammoths more realistic rather than random.

## NETLOGO FEATURES

The model uses [`import-pcolors`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#import-pcolors) to load a map of the Americas. This shows how easy it is to model semi-realistic geographical features in NetLogo without having to resort to the [GIS extension](https://ccl.northwestern.edu/netlogo/docs/gis.html), which is very powerful but harder to use.

## CREDITS AND REFERENCES

This model is partly based on the theory expounded by Jared Diamond in:
Diamond, J. (1993). _The Third Chimpanzee_. Basic Books.

It is also based on the work in:
Cooper, A., Turney, C., Hughen, K., Brook, B., McDonald, H., & Bradshaw, J. (2015). "Abrubt warming events drove Late Pleistocene Holartic megafaunal turnover." _Science_. American Association for the Advancement of Science.

Thanks to Nicolas Payette for converting this model from StarLogoT to NetLogo.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Mammoths model.  http://ccl.northwestern.edu/netlogo/models/Mammoths.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

Converted from StarLogoT to NetLogo, 2016.

<!-- 1997 2016 -->
@#$#@#$#@
default
true
0
Polygon -7566196 true true 150 5 40 250 150 205 260 250

mammoth
false
0
Polygon -7500403 true true 195 181 180 196 165 196 166 178 151 148 151 163 136 178 61 178 45 196 30 196 16 178 16 163 1 133 16 103 46 88 106 73 166 58 196 28 226 28 255 78 271 193 256 193 241 118 226 118 211 133
Rectangle -7500403 true true 165 195 180 225
Rectangle -7500403 true true 30 195 45 225
Rectangle -16777216 true false 165 225 180 240
Rectangle -16777216 true false 30 225 45 240
Line -16777216 false 255 90 240 90
Polygon -7500403 true true 0 165 0 135 15 135 0 165
Polygon -1 true false 224 122 234 129 242 135 260 138 272 135 287 123 289 108 283 89 276 80 267 73 276 96 277 109 269 122 254 127 240 119 229 111 225 100 214 112

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
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
