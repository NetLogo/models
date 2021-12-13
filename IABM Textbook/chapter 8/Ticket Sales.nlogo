extensions [ gis ]            ;; the gis extension allows us to read standard GIS data

breed [ consumers consumer ]  ;; consumers are the ones purchasing tickets
breed [ venues venue ]        ;; where the event will occur

consumers-own [
  bought?                     ;; whether or not they have bought a ticket
  my-uncertainty              ;; uncertainty in the underlying quality of the event
  my-expected-value           ;; what they expect to get out of the event
]

patches-own [
  tract-id                    ;; maps the patch on to a census track
  population                  ;; number of households on the patch
]

globals [
  event-quality-this-week     ;; the actual quality of the event
  nyc-roads-dataset           ;; GIS data file for roads
  nyc-tracts-dataset          ;; GIS data file for the census tracts
  roads-displayed?            ;; a boolean that controls whether or not the roads are being displayed
]

to setup
  clear-all
  setup-maps  ;; load in the GIS data
  ask patches with [ population > 0 ] [
    ;; create the consumers, this creates one household for every 100 in the census data in order to speed up processing
    sprout-consumers population / 100 [
      set my-uncertainty consumer-uncertainty
      set my-expected-value consumer-expected-value
      set bought? false
      set shape "person"
      set color white
      set heading random 360
      fd 0.1
    ]
  ]
  create-venue ;; create the venue for the event
  reset-ticks
end

;; create-venue chooses a random location where there is a household and places the venue there
;;  since we know that all consumers live inside the space of the model this simplifies the
;;  process of finding a point located in the gis data space
to create-venue
  create-venues 1 [
    set shape "house"
    set color yellow
    set size 2
    let target one-of consumers
    set xcor [ xcor ] of target
    set ycor [ ycor ] of target
  ]
end

;; reset-sale sets the status of all consumers to not having been bought, kills the venue and creates a new one
to reset-event
  ask consumers [
    set bought? false
    set color white
  ]
  ask venues [
    die
  ]
  create-venue
  clear-all-plots
  reset-ticks
end

to go
  ;; if all consumers have bought or if time has run out then stop the simulation
  if all? consumers [ bought? ] or fraction-of-time-left <= 0 [
    stop
  ]
  ;; consumers who have not bought are given a chance to buy
  ask consumers with [ not bought? ] [
    if random-float 1.0 < willingness-to-buy [
      buy
    ]
  ]
  tick
end

to load-patch-data
  ;; We check to make sure the file exists first
  ifelse file-exists? "data/households.txt"
  [
    file-open "data/households.txt"
    ;; Read in all the data in the file
    while [ not file-at-end? ]
    [
      let geo_id file-read
      let geo_id2 file-read
      let sumlevel file-read
      let geo_name file-read
      let household-population file-read
      ;; set the population of a patch based on the population of the tract
      ask patches with [ tract-id = geo_id2 ] [
        set population read-from-string household-population
      ]
    ]
    ;; since multiple patches could be part of the same census tract, this code divides the households up evenly among all
    ;;  patches that are part of the same census tract
    ask patches with [ population > 0 ] [
      set population population / count patches with [ tract-id = [ tract-id ] of myself ]
    ]
    ;; Done reading in patch information.  Close the file.
    file-close
  ]
  [ user-message "There is no data/households.txt file in current directory!" ]
end

to setup-maps
  ; Load all of our datasets
  set nyc-roads-dataset gis:load-dataset "data/roads.shp"
  set nyc-tracts-dataset gis:load-dataset "data/tracts.shp"
  ; Set the world envelope to the union of all of our dataset's envelopes
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of nyc-roads-dataset) (gis:envelope-of nyc-tracts-dataset))
  set roads-displayed? false

  display-roads  ;; display the roads
  display-tracts ;; display the tract borders

  ;; locate whether a patch intersects a tract, if it does assign it that tract
  foreach gis:feature-list-of nyc-tracts-dataset [ feature ->
    ask patches gis:intersecting feature [
      set tract-id gis:property-value feature "STFID"
    ]
  ]

  ;; load the census data in to the patches
  load-patch-data
end

to display-roads
  ifelse roads-displayed? [
    ;; if the roads aren't displayed clear the drawing and reload the census tract borders
    clear-drawing
    display-tracts
    set roads-displayed? false
  ][
    ;; if they are then draw the streets in red
    gis:set-drawing-color red
    set roads-displayed? true
    gis:draw nyc-roads-dataset 1
  ]
end

to display-tracts
  ;; draw the census tracts in blue
  gis:set-drawing-color blue
  gis:draw nyc-tracts-dataset 1
end

to-report willingness-to-buy
  ;; willingness-to-buy is a factor of the uncertainty the consumer has in the event, the time left, and how close the consumer
  ;;   is to the venue
  let my-discounted-certainty (1 - my-uncertainty) * fraction-of-time-left
  let nearness (1 - distance-sensitivity) ^ (distance one-of venues)
  report my-expected-value * my-discounted-certainty * nearness
end

;; this normalizes the amount of time left between 0 and 1
to-report fraction-of-time-left
  report (event-week - ticks) / (event-week)
end

;; to buy update the variables and change the color of the consumer
to buy
  set bought? true
  set color green
end


; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
261
10
774
774
-1
-1
5.0
1
10
1
1
1
0
1
1
1
0
100
0
150
1
1
1
ticks
30.0

BUTTON
15
185
100
218
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
105
185
240
218
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
285
240
435
Tickets vs. Time
Time
Tickets
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count consumers with [ bought? ]"

SLIDER
15
60
240
93
consumer-uncertainty
consumer-uncertainty
0
1.0
0.15
.01
1
NIL
HORIZONTAL

SLIDER
15
100
240
133
consumer-expected-value
consumer-expected-value
0
1
1.0
.01
1
NIL
HORIZONTAL

SLIDER
15
20
240
53
event-week
event-week
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
15
140
240
173
distance-sensitivity
distance-sensitivity
0
1.0
0.15
0.01
1
NIL
HORIZONTAL

BUTTON
105
225
240
258
toggle road display
display-roads
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
15
225
100
258
NIL
reset-event
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
## ACKNOWLEDGMENT

This model is from Chapter Eight of the book "Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo", by Uri Wilensky & William Rand.

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

This model is in the IABM Textbook folder of the NetLogo Models Library. The model, as well as any updates to the model, can also be found on the textbook website: http://www.intro-to-abm.com/.

## WHAT IS IT?

The general intent of this model is to simulate how individuals within a limited geographic region decide to buy tickets to a live event.

## HOW IT WORKS

During setup, census tract definitions and census tract data are read from external files. The GIS extension is used to read in the tract definitions. The data is read from census files. After this data is read in, households are created in each patch to represent the underlying population present in those location. Finally, a venue is randomly created somewhere in the space.

Once the model runs, in each time step, agents who have not bought tickets calculate the expected utility of attending the event. Then, based on that probability, they decide whether or not to buy the ticket at that time step. This random draw simulates the fact that the particular period in which they decide or not to buy the ticket is stochastic. To make it more realistic you can elaborate the model so that it determines who buys early and who buys late.

## HOW TO USE IT

To run the model, simply set the parameters and let the model run. If after running the model you want to view a different setup with the same parameters, use the RESET-SALE button. Since the GIS data can take a while to load this is a faster way to examine multiple runs.

EVENT-WEEK controls how many weeks until the event occurs.

CONSUMER-UNCERTAINTY controls how uncertain the consumers are in the quality of the event.

CONSUMER-EXPECTED-VALUE controls what value the consumers expect to get out of attending the event.

DISTANCE-SENSITIVITY controls how sensitive consumers are about the distance they are from the event.

## THINGS TO NOTICE

The basic pattern grows outward from the venue.

The density of sales decreases as we get further away from the venue.

The number of sales increases quickly at first, and then slows down.

## THINGS TO TRY

Adjust the CONSUMER-UNCERTAINTY and CONSUMER-EXPECTED-VALUE and see how it affects the results. Number of sales should increase as uncertainty decreases and should decrease as the expected value decreases.

## EXTENDING THE MODEL

Make the process of when consumers buy less stochastic.

Add pricing tiers.

## NETLOGO FEATURES

This model demonstrates the use of the NetLogo GIS extension. It uses the extension to load two GIS datasets for New York City: one for the census tracts and one for the roads. Information about the population in the various census tracts is then loaded from a text file using NetLogo's `file-*` primitives.

## RELATED MODELS

GIS General Examples

## CREDITS AND REFERENCES

This model was inspired by the work of Peggy Tseng and Wendy Moe. Especially, Peggy's dissertation:

Tseng, P. (2009) Effects of Performance Schedules on Event Ticket Sales. Dissertation, University of Maryland Robert H. Smith School of Business. Chair: Moe, W.

## HOW TO CITE

This model is part of the textbook, “Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo.”

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rand, W. & Wilensky, U. (2011).  NetLogo Ticket Sales model.  http://ccl.northwestern.edu/netlogo/models/TicketSales.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the textbook as:

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Rand, W. & Wilensky, U. -->
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
