breed [removal-spots removal-spot]
breed [bacteria  bacterium]
breed [flagella  flagellum]
breed [predators predator]

directed-link-breed [connectors connector]

bacteria-own [variation]
removal-spots-own [countdown]

globals [
  bacteria-caught           ;;  count of total bacteria caught
  wiggle?                   ;;  boolean for whether the bacteria wiggle back and forth randomly as they move
  camouflage?               ;;  boolean that keeps track of whether the predator (mouse cursor) is visible to the bacteria
  tick-counter              ;;  counter to keep track of how long the predator (mouse cursor) has remained stationary
  predator-location         ;;  patch where the predator (the player) has placed the mouse cursor
  speed-scalar              ;;  scales the speed of all bacteria movement
  predator-color-visible    ;;  color of predator when bacteria can detect it
  predator-color-invisible  ;;  color of predator when bacteria can not detect it
  bacteria-default-color    ;;  color of bacteria when color is not used in visualize-variation setting
  flagella-size             ;;  size of the flagella
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;  Setup Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  set predator-color-visible   [255 0 0 100]
  set predator-color-invisible [200 200 200 100]
  set bacteria-default-color   [100 100 100 200]

  set-default-shape bacteria "bacteria"
  set-default-shape flagella "flagella"
  set-default-shape removal-spots "x"

  set bacteria-caught 0
  set speed-scalar 0.04
  set flagella-size 1.2
  set wiggle? true
  set camouflage? true
  ask patches [ set pcolor white ]

  setup-bacteria
  setup-predator
  reset-ticks
end

to setup-bacteria
  foreach [1 2 3 4 5 6] [ this-variation ->
    create-bacteria initial-bacteria-per-variation [
      set label-color black
      set size 1
      set variation this-variation
      make-flagella
      setxy random-xcor random-ycor
    ]
  ]
  visualize-bacteria
end

to setup-predator
  create-predators 1 [
    set shape "circle"
    set color predator-color-visible
    set size 1
    set heading 315
    bk 1
    hide-turtle
  ]
end

to make-flagella ;; bacteria procedure
  let flagella-shape word "flagella-" variation
  hatch 1 [
    set breed flagella
    set color bacteria-default-color
    set label ""
    set shape flagella-shape
    bk 0.4
    set size flagella-size
    create-connector-from myself [
      set hidden? true
      tie
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;  Runtime Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  check-caught
  move-predator
  move-bacteria
  ask flagella [ move-flagella ]
  visualize-bacteria
  visualize-removal-spots
  tick
end

to death
  ;; mark where a bacterium was caught and then remove the bacterium and its attached flagella
  set bacteria-caught bacteria-caught + 1
  make-a-removal-spot
  ask out-link-neighbors [die]
  die
end

to make-a-removal-spot
  hatch 1 [
    set breed removal-spots
    set size 1.5
    set countdown 30
  ]
end

to move-bacteria
  ask bacteria [
    if wiggle? [ right (random-float 25 - random-float 25) ]
    fd variation * speed-scalar
    let predators-in-front-of-me predators in-cone 2 120
    if not camouflage? and any? predators-in-front-of-me [
      face one-of predators-in-front-of-me
      right 180
    ]
  ]
end

to move-predator
  ifelse patch mouse-xcor mouse-ycor = predator-location
    [ set tick-counter tick-counter + 1 ]
    [ set predator-location patch mouse-xcor mouse-ycor set tick-counter 0 ]
  ask predators [
    ifelse tick-counter < 100
      [ set camouflage? false set color predator-color-visible ]
      [ set camouflage? true set color predator-color-invisible ]
    setxy mouse-xcor mouse-ycor
    ;; only show the predator if the mouse pointer is actually inside the view
    set predator-location patch xcor ycor
    set hidden? not mouse-inside?
  ]
end

to move-flagella
  let flagella-swing 15 ;; magnitude of angle that the flagella swing back and forth
  let flagella-speed 60 ;; speed of flagella swinging back and forth
  let new-swing flagella-swing * sin (flagella-speed * ticks)
  let my-bacteria one-of in-link-neighbors
  set heading [ heading ] of my-bacteria + new-swing
end

to check-caught
  if not mouse-down? or not mouse-inside? [ stop ]
  let prey [bacteria in-radius (size / 2)] of one-of predators
  if not any? prey [ stop ] ;; no prey here? oh well
  ask one-of prey [ death ] ;; eat only one of the bacteria at the mouse location
  ;; replace the bacterium that was eating with a offspring selected from a random parent remaining in the remaining population
  ask one-of bacteria [ hatch 1 [ rt random 360 make-flagella ] ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;visualization procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to visualize-bacteria
  ask bacteria [
    ifelse visualize-variation = "# flagella as label"
      [ set label word variation "     " ]
      [ set label "" ]
    ifelse member? visualize-variation ["flagella and color" "as color only"]
      [ set color item (variation - 1) [violet blue green brown orange red] ]
      [ set color bacteria-default-color ]
  ]
  ask flagella [
    set hidden? member? visualize-variation ["as color only" "# flagella as label" "none"]
  ]
end

to visualize-removal-spots
  ask removal-spots [
    set countdown countdown - 1
    set color lput (countdown * 4) [0 100 0]  ;; sets the transparency of this spot to progressivley more transparent as countdown decreases
    if countdown <= 0 [die]
  ]
end


; Copyright 2015 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
280
10
752
483
-1
-1
16.0
1
10
1
1
1
0
1
1
1
-14
14
-14
14
1
1
1
ticks
30.0

BUTTON
10
10
135
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
145
10
270
43
go/pause
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
350
270
505
# of bacteria for each variation
# of flagella
# of bacteria
0.0
8.0
0.0
10.0
true
false
"" ";; the HISTOGRAM primitive can't make a multi-colored histogram,\n;; so instead we plot each bar individually\nclear-plot\nforeach [1 2 3 4 5 6] [ this-variation ->\n  set-current-plot-pen word this-variation  \" \"\n  plotxy this-variation count bacteria with [variation = this-variation]\n]"
PENS
"1 " 1.0 1 -8630108 true "" ""
"2 " 1.0 1 -13345367 true "" ""
"3 " 1.0 1 -10899396 true "" ""
"4 " 1.0 1 -3355648 true "" ""
"5 " 1.0 1 -955883 true "" ""
"6 " 1.0 1 -2674135 true "" ""

PLOT
10
190
270
345
Avg. # of flagella per bacteria
time
# of flagella
0.0
1000.0
1.0
6.0
true
false
"" ""
PENS
"pen 1" 1.0 0 -16777216 true "" "if any? bacteria [plotxy ticks mean [variation] of bacteria ]"

SLIDER
10
50
270
83
initial-bacteria-per-variation
initial-bacteria-per-variation
1
10
5.0
1
1
NIL
HORIZONTAL

CHOOSER
10
85
270
130
visualize-variation
visualize-variation
"flagella and color" "flagella only" "as color only" "# flagella as label" "none"
0

MONITOR
10
140
135
185
# alive
count bacteria
17
1
11

MONITOR
145
140
270
185
# caught
bacteria-caught
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is a natural/artificial selection model that shows the result of two competing forces from natural selection related to the speed of a prey.

Which force dominates the outcome from natural selection depends on the behavior of the predator(s).

One force is that predators that chase prey, tend to catch slower moving prey more often, thereby selecting for removing prey that are slower, leaving behind faster prey to have offspring. This leads to progressively faster prey in the population over time.

Another force is that predators who wait for their prey without moving, tend to catch prey that are moving faster more often, because these prey run into them more frequently than the slow moving prey. In this manner, they thereby select for removing prey that are faster, leaving behind slow prey to have offspring. This leads to progressively slower prey in the population over time.

A player can intentionally cause bacteria to become faster over time, simply by trying to chase after them, clicking (eating) any bacteria that player can catch. And they can unintentionally cause bacteria to become slower over time, simply by waiting for bacteria to come to them and clicking (eating) any bacteria that travel under where that player is situated.

## HOW IT WORKS

You assume the role of a predator (such as a nematode) amongst a population of single celled bacteria. To begin your pursuit of bacteria as a predator, press SETUP to create a population of bacteria, determined by six times the INITIAL-BACTERIA-PER-VARIATION slider. These bacteria that are created are randomly distributed around the world and assigned a variation (the number of flagella they posses [1 through 6])

When you press GO the bacteria begin to move at speed proportional to the number of flagella they posses. As they move around, try to eat as many bacteria as fast as you can by clicking on them. Alternatively, you may hold the mouse button down and move the predator over the bacteria.

The six different variations in the population are initially equally distributed amongst six sub-populations of the bacteria. With each bacteria you catch, a new bacteria is randomly chosen from the population to produce one offspring. Flagella number is an inherited trait. The offspring that is chosen, therefore, is an exact duplicate of the parent (in its number of flagella as well in its location in the world). The creation of new offspring keeps the overall population of the bacteria constant.

Initially, there are equal numbers of each sub-population of bacteria (e.g. five bacteria with each variation). With each new bacteria you eat, the distribution of the bacteria will tend to change, as shown in the # OF BACTERIA FOR EACH VARIATION histogram. In the histogram, you might see the distribution shift to the left (showing that more bacteria with less flagella are surviving [these are the slower ones]) or to the right (showing that more bacteria with more flagella are surviving [these are the faster ones]). Sometimes all the bacteria with a given variation will be wiped out completely. At this point, no other bacteria of this speed can be created in the population.

Bacteria turn around (to face in the opposite direction) when they detect your mouse cursor (as a predator) in their detection cone (an arc of 120 degrees that has a range of 2 units). They are not able to detect you when your mouse cursor has turned gray (after a couple seconds of inactivity).

Bacteria can detect the predator only in this arc in front of them, and so will not react to the mouse cursor when caught or chased from behind.

## HOW TO USE IT

INITIAL-BACTERIA-PER-VARIATION is the number of bacteria you start with in each of the six possible variations in flagella number. The overall population of bacteria is determined by multiplying this value by 6.

VISUALIZE-VARIATION helps you apply different visualization cues to see which variation each a bacterium has. These are the options you can set this chooser to:

 * **flagella only** - shows the different number of flagella that each bacterium has as "wiggling" hair-like appendages on the bacterium.

 * **as color** - shows 6 distinct colors for the 6 different trait variations (number of flagella) a bacterium might have (red = 6, orange = 5, yellow = 4, green = 3, blue = 2, and violet = 1).

 * **flagella and color** - shows both of the above at the same time.

 * **# flagella as label** - shows a number as a label, corresponding to the number of flagella the bacterium has. But the actual flagella themselves are invisible and each bacterium is colored gray.

 * **none** - each bacteria is colored gray, with no flagella visible, nor any label shown. The bacteria still travel at different speeds based on the number of flagella they have, regardless of whether they are visible or not.

Some of these visualization settings are designed to remove elements that may distract the person running the mode (who is also playing the role of the predator), from unintentionally attending to one visualization cue over another and selecting bacteria based on certain visualization cues (e.g. purposely going after the red ones).

\# OF BACTERIA EACH VARIATION is a histogram showing the distribution of bacteria with different number of flagella (which also corresponds to the relative speed of movement).

AVG. # OF FLAGELLA PER BACTERIA is a bivariate graph of the average number of flagella per bacteria in the population over time. This tends to increase when bacteria are chased after by the player mouse and this tends to decrease when

\# ALIVE is a monitor showing the total number of bacteria currently in the world.

\# CAUGHT is a monitor showing the total number of bacteria caught.

## THINGS TO NOTICE

The # OF BACTERIA EACH VARIATION histogram tends to shift to the right (corresponding to an increasing average speed in the population) if you assume the role of chasing easy prey.

The # OF BACTERIA EACH VARIATION histogram tends to shift to the left (corresponding to an decreasing average speed in the population) if you assume the role of waiting for prey come to you. The same effect can also be achieved by moving the predator around the world randomly.

## THINGS TO TRY

Setup the model up with INITIAL-BACTERIA-PER-VARIATION set to 1. Slow the model down and watch where new bacteria come from when you eat a bacteria. You should see a new bacteria hatch from one of the five remaining and it should be moving at the same speed as its parent.

Setup the model with more initial bacteria. Chase bacteria around trying to catch the bacteria nearest you at any one time by holding the mouse button down and moving the predator around the view after the nearest bacteria.

Setup and run the model again. This time wait in one location for the bacteria to come to you by placing the predator in one location and holding down the mouse button. All bacteria that run into you will be eaten.

## EXTENDING THE MODEL

A HubNet version of the model with adjustable starting populations of bacteria would help show what happens when two or more competitors assume similar vs. different hunting strategies on the same population at the same time.

## RELATED MODELS

Bug Hunters Camouflage
Bacteria Food Hunt
Previous versions of this model were referred to as Bug Hunt Speeds

## CREDITS AND REFERENCES

This model is part of the Evolution unit of the ModelSim curriculum, sponsored by NSF grant DRL-1020101.

For more information about the project and the curriculum, see the ModelSim project website: http://ccl.northwestern.edu/modelsim/.

Inspired by EvoDots software: http://faculty.washington.edu/herronjc/SoftwareFolder/EvoDots.html/

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2015).  NetLogo Bacteria Hunt Speeds model.  http://ccl.northwestern.edu/netlogo/models/BacteriaHuntSpeeds.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2015 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2015 Cite: Novak, M. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

1-flagella
true
0
Rectangle -7500403 true true 144 150 159 225

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
Polygon -7500403 false true 60 60 60 210 75 270 105 300 150 300 195 300 225 270 240 225 240 60 225 30 180 0 150 0 120 0 90 15
Polygon -7500403 false true 75 60 75 225 90 270 105 285 150 285 195 285 210 270 225 225 225 60 210 30 180 15 150 15 120 15 90 30

bird
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -16777216 true false 151 125 134 124 128 188 140 198 161 197 174 188 166 125
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Circle -16777216 true false 144 55 7
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

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
Circle -2674135 false false 90 90 120

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

flagella
true
0
Rectangle -7500403 true true 144 150 159 225

flagella-1
true
0
Line -7500403 true 150 150 150 285

flagella-2
true
0
Line -7500403 true 135 150 105 285
Line -7500403 true 165 150 180 285

flagella-3
true
0
Line -7500403 true 150 150 150 285
Line -7500403 true 120 150 60 270
Line -7500403 true 180 150 240 270

flagella-4
true
0
Line -7500403 true 135 150 105 285
Line -7500403 true 165 150 180 285
Line -7500403 true 195 135 255 255
Line -7500403 true 105 135 45 255

flagella-5
true
0
Line -7500403 true 150 150 150 285
Line -7500403 true 120 150 60 270
Line -7500403 true 15 210 105 120
Line -7500403 true 180 150 240 270
Line -7500403 true 285 210 195 120

flagella-6
true
0
Line -7500403 true 135 150 105 285
Line -7500403 true 165 150 180 285
Line -7500403 true 195 135 255 255
Line -7500403 true 105 135 45 255
Line -7500403 true 300 195 210 105
Line -7500403 true 0 195 90 105

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
1
@#$#@#$#@
