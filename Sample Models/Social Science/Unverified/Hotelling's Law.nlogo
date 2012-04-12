turtles-own [
            store-color ;; Color of the store
            area-count  ;; Keeps track of the area (market share) a store holds
            price       ;; How much each store charges for its product
            chosen-move ;; Prepares the stores to change location
            chosen-price-change ;; Prepares the stores to change price

            old-area    ;; The area (market share) that a store held at the end of the last tick
            old-position ;; The location a store was on at the end of the last tick
            old-price   ;; The price the store was charging at the end of the last tick
            ] 
            
patches-own [
            preferred-store ;; The store with the smallest sum of price and distance
            ]


;;;;;;;;;;;;;;;;;;;;;;;
;;; setup procedure ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to setup        
  clear-all
  setup-stores
  recalculate-area
  reset-ticks
end

to setup-stores 
  let index 5 ;; Variable that determines color of each store
  create-turtles store-number 
  [
     set shape "Circle (2)" 
     set size 2 
     set color index ;; Set color from the color palette with the corresponding number
     ifelse layout = "line"
         [setxy 0 round random-ycor]
         [setxy round random-xcor round random-ycor]
     set price 10
     set store-color (word "store" color)
     set index index + 10 ;; Change color
     pendown
     set pen-size 5
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;
;;; turtle procedure ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go    
  ask turtles [ 
    set old-area area-count 
    set old-price price
    set old-position patch-here
    set chosen-move nobody
    set chosen-price-change 0
  ]
  
  if rules != "pricing-only" ;; Under the rules normal and moving-only, stores prepare to move
  [
    ask turtles [penup do-movement] 
  ]
 
  if rules != "moving-only" ;; Under the rules normal and pricing-only, stores prepare to change price
  [
    ask turtles [do-prices] 
  ]  
  
  ask turtles ;; To make sure there is simultaneous decision-making, all movements and price-changes take place here
  [
    pendown
    if (chosen-move != nobody)
    [ move-to chosen-move ]
    set price price + chosen-price-change
  ]
  
  recalculate-area
  tick  
end

to do-movement ;; Stores consider the benefits of taking a unit step in each of the four cardinal directions 
               
  let candidate-moves (list (list old-position old-area))
  
  ;; Calculate and store position and market share associated with that move, for each of the four hypothetical moves
  foreach [self] of neighbors4 [
    move-to ?
    recalculate-area
    set candidate-moves fput (list ? area-count) candidate-moves
  ]
  move-to old-position
  
  ;; Sort candidate moves in order of the market share area they acheive, from largest to smallest
  let sorted-candidates sort-by [ (last ?1) > (last ?2) ] (candidate-moves)
  
  let best-move (first (first sorted-candidates)) 
  let best-move-area (last (first sorted-candidates))
  
  if (best-move-area > old-area)
  [
    set chosen-move best-move
  ]
  if (best-move-area = old-area and best-move-area = 0)
  [ 
    set chosen-move best-move
  ]
end

to do-prices ;; Here, each turtle considers the revenue from hypothetically increasing or decreasing its price by one unit
  let old-revenue (old-area * old-price)
  
  set price old-price + 1
  recalculate-area
  let up-revenue (area-count * price)
  
  set price old-price - 1
  recalculate-area  
  let down-revenue (area-count * price)
  
  set price old-price

  ;; The three measured revenues are compared here, and the store selects the most profitable one
  if old-revenue = up-revenue and up-revenue = down-revenue and price > 1 and old-revenue = 0 ;; If the store gets "stranded" it goes into an emergency procedure
    [set chosen-price-change -1 stop]
  
  if old-revenue >= up-revenue and old-revenue >= down-revenue
    [set chosen-price-change 0 stop]    
  
  if up-revenue > old-revenue and up-revenue = down-revenue ;; A tie causes a random increase or decrease
    [ set chosen-price-change one-of [-1 1] stop]
    
  if up-revenue > old-revenue and up-revenue > down-revenue
    [set chosen-price-change 1 stop]
    
  if down-revenue > old-revenue
    [set chosen-price-change -1 stop]    
end


;;;;;;;;;;;;;;;;;;;;;;;
;;; patch procedure ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to recalculate-area
  ;; In general, NetLogo will complain if a turtle asks all turtles in the world to perform some action 
  ;; (because this situation is often indicative of a programming error). 
  ;; However in this model, we actually do need every turtle to be able to run this recalculate-area procedure, 
  ;; which in turn asks all turtles and all patches to perform an action. To work around NetLogo's overzealous 
  ;; error-checking, we use the idiosyncracy of writing "turtles with [true]" and "patches with [true]", 
  ;; which includes all agents without NetLogo complaining.
  
  ask turtles with [true] [set area-count 0]
  
  if layout = "plane"
  [
      ask patches with [true]
      [  
        set preferred-store min-one-of turtles [(price) + (distance myself)] ;; consumers select the store with the best deal
        ;; Each consumer (patch) indicates its preference by taking on the color of the store, and the store updates its area-count (market share)  
        set pcolor ([color] of preferred-store + 2)
        ask preferred-store [set area-count area-count + 1]
      ]
  ]
  
  if layout = "line"
  [
      ask patches with [pxcor = 0]
      [  
        set preferred-store min-one-of turtles [(price) + (distance myself)] ;; consumers select the store with the best deal
        ;; Each consumer (patch) indicates its preference by taking on the color of the store, and the store updates its area-count (market share)  
        set pcolor ([color] of preferred-store + 2)
        ask preferred-store [set area-count area-count + 1]
      ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
285
10
849
595
20
20
13.5122
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
180
75
280
108
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
180
125
280
158
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
1

BUTTON
180
175
280
208
go once
go
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
855
400
1190
595
revenues
time
revenue
0.0
10.0
0.0
10.0
true
false
"" "ask turtles \n[ \n set-current-plot-pen store-color\n plot (area-count *  price)\n ]"
PENS
"store5" 1.0 0 -7500403 true "" ""
"store15" 1.0 0 -2674135 true "" ""
"store25" 1.0 0 -955883 true "" ""
"store35" 1.0 0 -6459832 true "" ""
"store45" 1.0 0 -1184463 true "" ""
"store55" 1.0 0 -10899396 true "" ""
"store65" 1.0 0 -13840069 true "" ""
"store75" 1.0 0 -14835848 true "" ""
"store85" 1.0 0 -11221820 true "" ""
"store95" 1.0 0 -13791810 true "" ""

TEXTBOX
40
50
152
68
setup variables
13
0.0
1

SLIDER
10
75
165
108
store-number
store-number
2
10
2
1
1
NIL
HORIZONTAL

PLOT
855
10
1190
205
prices
time
price
0.0
10.0
0.0
10.0
true
false
"" "ask turtles \n[ \n set-current-plot-pen store-color\n plot (price)\n ]"
PENS
"store5" 1.0 0 -7500403 true "" ""
"store15" 1.0 0 -2674135 true "" ""
"store25" 1.0 0 -955883 true "" ""
"store35" 1.0 0 -6459832 true "" ""
"store45" 1.0 0 -1184463 true "" ""
"store55" 1.0 0 -10899396 true "" ""
"store65" 1.0 0 -13840069 true "" ""
"store75" 1.0 0 -14835848 true "" ""
"store85" 1.0 0 -11221820 true "" ""
"store95" 1.0 0 -13791810 true "" ""

PLOT
855
205
1190
400
areas
time
area
0.0
10.0
0.0
10.0
true
false
"" "ask turtles \n[ \n set-current-plot-pen store-color\n plot (area-count)\n ]"
PENS
"store5" 1.0 0 -7500403 true "" ""
"store15" 1.0 0 -2674135 true "" ""
"store25" 1.0 0 -955883 true "" ""
"store35" 1.0 0 -6459832 true "" ""
"store45" 1.0 0 -1184463 true "" ""
"store55" 1.0 0 -10899396 true "" ""
"store65" 1.0 0 -13840069 true "" ""
"store75" 1.0 0 -14835848 true "" ""
"store85" 1.0 0 -11221820 true "" ""
"store95" 1.0 0 -13791810 true "" ""

CHOOSER
10
165
165
210
rules
rules
"normal" "moving-only" "pricing-only"
0

CHOOSER
10
115
165
160
layout
layout
"plane" "line"
0

@#$#@#$#@
## WHAT IS IT?


This model is a representation of Hotelling's law (1929), which examines the optimal placement of stores and pricing of their goods in order to maximize profit. In Hotelling's original paper, the stores were confined to a single dimension.  This model replicates and extends Hotelling's law, by allowing the stores to move freely on a plane.
   
In this model, several stores attempt to maximize their profits by moving and changing their prices.  Each consumer chooses their store of preference based on the distance to the store and the price of the goods it offers.


## HOW IT WORKS


Each consumer adds up the price and distance from each store, and then chooses to go to the store that offers the lowest sum. In the event of a tie, the consumer chooses randomly. The stores can either be constrained to one dimension, in which case all stores operate on a line, or they can be placed on a plane. Under the normal rule, each store tries to move randomly in the four cardinal directions to see if it can gain a larger market share; if not, it does not move. Then each store checks if it can earn a greater profit by increasing or decreasing the price of their goods; if not, it does not change the price. This decision is made without any knowledge of their competitors' strategies. There are two other conditions under which one can run this model: stores can either only change prices, or only move their location.


## HOW TO USE IT


Press SETUP to create the stores and a visualization of their starting market share areas.    
Press GO to have the model run continuously.
Press GO-ONCE to have the model run once.
The STORE-NUMBER slider decides how many stores are in the world.

If the LAYOUT chooser is on LINE, then the stores will operate only on one dimension. If it is on PLANE, then the stores will operate in a two dimensional space.

If the RULES chooser is on PRICING-ONLY, then stores can only change their price.  If it is on MOVING-ONLY, then the stores can only move.  If it is on NORMAL, all stores can change their prices and move.


## THINGS TO NOTICE


On the default settings, notice that the two stores end up in very close contact and with minimal prices. This is because each store tries to cut into their competitor's fringe consumers by moving closer and reducing their prices.

Also notice how the shapes of the boundaries end up as perpendicular bisectors or hyperbolic arcs. The distance between the stores and their difference in prices determines the eccentricity of these arcs.

Try increasing the store number to three or more, and notice how the store with the most area is not necessarily the most profitable.

Plots show the prices, areas, and revenues of all stores.


## THINGS TO TRY


Try to see how stores behave differently when they are either prohibited from moving or changing their prices.

Try increasing the number of stores. Examine how they behave differently and watch which ones are the most successful.  What patterns emerge?


## EXTENDING THE MODEL


In this model, information is free, but this is not a realistic assumption. Can you think of a way to add a price when stores try to gain information?

In this model, the stores always seek to increase their profits immediately instead of showing any capacity to plan. They are also incapable of predicting what the competitors might do. Making the stores more intelligent would make this model more realistic.

As of now, the consumers are very static. Is there a way to make the consumers move as well or react in some manner to the competition amongst the stores?

Is there a way to include consumer limitations in their spending power or ability to travel? That is, if all stores charge too much or are too far, the consumer could refuse to go to any store.

In this model, if two or more stores are identical from a consumer's point of view, the consumer will choose to go to one of those at random. If the stores are only slightly different for the consumer, is it possible to have the consumer go to either one? 

One can extend this model further by introducing a different layout. How would the patterns change, for example, if the layout of the world were circular?


## NETLOGO FEATURES


Each store can move up to two distance units per time unit, as each store does a test step, in one cardinal direction and back, when deciding on its moving strategy. However, as this model is tick based, the user only sees one step per store. This also comes into play when recalculating the market share area as the world may partition itself up to fifty-one times per tick, but the user only sees it occurring once.

Also, when recalculating the market share area, a slight work-around was necessary. In general, NetLogo will complain if a turtle asks all turtles in the world to perform some action, because this situation is often indicative of a programming error. However in this model, every turtle does need to be able to run the RECALCULATE-AREA procedure, which in turn asks all turtles and all patches to perform an action. To work around NetLogo's overzealous error-checking, we use the idiosyncracy of writing "turtles with [TRUE]" and "patches with [TRUE]", which includes all agents without NetLogo complaining.


## RELATED MODELS


Voronoi


## CREDITS AND REFERENCES

Hotelling, Harold. (1929). "Stability in Competition." The Economic Journal 39.153: 41 -57. (Stable URL: http://www.jstor.org/stable/2224214 ).
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
Polygon -7500403 true true 165 285 300 225 300 75 300 225
Polygon -7500403 true true 150 135 15 75 150 135 285 75
Polygon -7500403 true true 0 90 0 240 135 300 0 240
Polygon -7500403 true true 240 150 210 150 210 105 180 180 210 225 210 195 240 195 225 150 240 150 240 195 225 195 225 150 210 195 210 165 210 150

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

circle (2)
false
0
Circle -16777216 true false 0 0 300
Circle -7500403 true true 15 15 270

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
NetLogo 5.0
@#$#@#$#@
setup
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Pricing and moving" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean prices</metric>
    <metric>max prices</metric>
    <metric>min prices</metric>
    <metric>max areas</metric>
    <metric>min areas</metric>
    <metric>mean nearest-distances</metric>
    <metric>max nearest-distances</metric>
    <metric>min nearest-distances</metric>
    <metric>duels</metric>
    <enumeratedValueSet variable="rules">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-number">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Layout">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Start-on-line?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="World-size">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Pricing only(regular)" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean prices</metric>
    <metric>max prices</metric>
    <metric>min prices</metric>
    <metric>max areas</metric>
    <metric>min areas</metric>
    <metric>mean nearest-distances</metric>
    <metric>max nearest-distances</metric>
    <metric>min nearest-distances</metric>
    <metric>duels</metric>
    <enumeratedValueSet variable="rules">
      <value value="&quot;pricing-only&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-number">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Layout">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Start-on-line?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="World-size">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Moving only" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean prices</metric>
    <metric>max prices</metric>
    <metric>min prices</metric>
    <metric>max areas</metric>
    <metric>min areas</metric>
    <metric>mean nearest-distances</metric>
    <metric>max nearest-distances</metric>
    <metric>min nearest-distances</metric>
    <metric>duels</metric>
    <enumeratedValueSet variable="rules">
      <value value="&quot;moving-only&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-number">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Layout">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Start-on-line?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="World-size">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Pricing only(2-D linear)" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean prices</metric>
    <metric>max prices</metric>
    <metric>min prices</metric>
    <metric>max areas</metric>
    <metric>min areas</metric>
    <metric>mean nearest-distances</metric>
    <metric>max nearest-distances</metric>
    <metric>min nearest-distances</metric>
    <metric>duels</metric>
    <enumeratedValueSet variable="rules">
      <value value="&quot;pricing-only&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-number">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Layout">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Start-on-line?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="World-size">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Pricing only(1-D linear)" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean prices</metric>
    <metric>max prices</metric>
    <metric>min prices</metric>
    <metric>max areas</metric>
    <metric>min areas</metric>
    <metric>mean nearest-distances</metric>
    <metric>max nearest-distances</metric>
    <metric>min nearest-distances</metric>
    <metric>duels</metric>
    <enumeratedValueSet variable="rules">
      <value value="&quot;pricing-only&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-number">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Layout">
      <value value="&quot;line&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Start-on-line?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="World-size">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="21X21" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean prices</metric>
    <metric>max prices</metric>
    <metric>min prices</metric>
    <metric>max areas</metric>
    <metric>min areas</metric>
    <metric>mean nearest-distances</metric>
    <metric>max nearest-distances</metric>
    <metric>min nearest-distances</metric>
    <metric>duels</metric>
    <enumeratedValueSet variable="rules">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-number">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Layout">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Start-on-line?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="World-size">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="81X81" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean prices</metric>
    <metric>max prices</metric>
    <metric>min prices</metric>
    <metric>max areas</metric>
    <metric>min areas</metric>
    <metric>mean nearest-distances</metric>
    <metric>max nearest-distances</metric>
    <metric>min nearest-distances</metric>
    <metric>duels</metric>
    <enumeratedValueSet variable="rules">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-number">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Layout">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Start-on-line?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="World-size">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="circle" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean prices</metric>
    <metric>max prices</metric>
    <metric>min prices</metric>
    <metric>max areas</metric>
    <metric>min areas</metric>
    <metric>mean nearest-distances</metric>
    <metric>max nearest-distances</metric>
    <metric>min nearest-distances</metric>
    <metric>duels</metric>
    <enumeratedValueSet variable="rules">
      <value value="&quot;normal&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-number">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Layout">
      <value value="&quot;circle&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Start-on-line?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="World-size">
      <value value="20"/>
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
