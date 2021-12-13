globals [
  ; these are setup-only variables, used to make changing the model easier
  min-price
  population
  sales-per-tick
  starting-asking-price
  starting-willing-to-pay
  amount-high
  amount-low

  ; these variables track data as the model runs
  avg-per-buyer
  avg-per-seller
  total-sales
  remaining-supply
  starting-money-actual
]

breed [ shadows shadow ]
breed [ sellers seller ]
breed [ buyers buyer ]
breed [ pops pop ]

turtles-own [
  money        ; keeps track of the amount of money the turtle has
  next-xcor    ; the x-coordinate of the next position
  next-ycor    ; the y-coordinate of the next position
  percent
  my-shadow    ; the shadow of the turtle
]

sellers-own [
  items-for-sale ; the quantity that the seller has to sell
  asking-price
  starting-supply
  behavior-after-sale ; the behavior of seller after a sale
  behavior-no-sale ; the behavior of the seller after a no sale
  sold ; the quantity that the seller has sold
]

buyers-own [
  want-to-buy ; the quantity the buyer wants to buy
  willing-to-pay
  starting-demand
  behavior-after-purchase
  behavior-no-purchase ; the behavior of the buyer after not buying
  bought ; the quantity that the buyer has bought
]

to setup
  clear-all

  ; set the global variables
  set min-price 0.01
  set population 50
  set total-sales 0
  set starting-asking-price 100
  set starting-willing-to-pay 10
  set amount-high 50
  set amount-low 25

  ; now create the sellers
  create-ordered-sellers population [
    forward 8
    set my-shadow nobody
    set money 0
    set items-for-sale get-random-amount supply-distribution supply-amount
    set starting-supply items-for-sale
    set asking-price get-starting-value starting-asking-price
    ; we set the behavior using anonymous procedures to make the usage during the run simple
    ; the behavior depends on the settings of the model
    let mix-behavior ifelse-value seller-behavior = "mix of all" [random 3] [-1]
    ifelse seller-behavior = "normal" or mix-behavior = 0 [
      set behavior-after-sale [         -> change-price 2.5 ]
      set behavior-no-sale    [ hide? -> if (not hide?) [ change-price -2.0 ] ]
    ] [
      ifelse seller-behavior = "desperate" or mix-behavior = 1 [
        set behavior-after-sale [         -> change-price 0.7 ]
        set behavior-no-sale    [ hide? -> if (not hide?) [ change-price -5.0 ] ]
      ] [
        ; "random" or mix-behavior = 2
        set behavior-after-sale [     -> change-price (random 11 - 5)]
        set behavior-no-sale    [     -> change-price (random 11 - 5)]
    ] ]
  ]

  ; now create the buyers
  create-ordered-buyers population [
    forward 13
    facexy 0 0
    set my-shadow nobody
    set want-to-buy get-random-amount demand-distribution demand-amount
    set starting-demand want-to-buy
    set money get-starting-value starting-money
    set willing-to-pay get-starting-value starting-willing-to-pay
    ; we set the behavior using anonymous procedures to make the usage during the run simple
    ; again, the behavior depends on the settings of the model
    let mix-behavior ifelse-value buyer-behavior = "mix of all" [random 3] [-1]
    ifelse buyer-behavior = "normal" or mix-behavior = 0 [
      set behavior-after-purchase [-> change-payment -2.0 ]
      set behavior-no-purchase    [-> change-payment  2.5 ]
    ] [
      ifelse buyer-behavior = "desperate" or mix-behavior = 1 [
        set behavior-after-purchase [-> change-payment -0.5 ]
        set behavior-no-purchase    [-> change-payment  7.5 ]
      ] [
          ; "random"  or mix-behavior = 2
          set behavior-after-purchase [-> change-payment (random 11 - 5)]
          set behavior-no-purchase    [-> change-payment (random 11 - 5)]
      ]
    ]
  ]

  ; create a shadow for all of our turtles
  create-ordered-shadows population [
    set color 2
    ask one-of sellers with [my-shadow = nobody] [ set my-shadow myself ]
  ]
  create-ordered-shadows population [
    set color 2
    ask one-of buyers with [my-shadow = nobody] [ set my-shadow myself ]
  ]

  ; update our tracking variables
  set avg-per-buyer (sum [starting-demand] of buyers) / (count buyers)
  set avg-per-seller (sum [starting-supply] of sellers) / (count sellers)

  ask sellers [
    update-seller-display
    ; seller shadow sizes are set at the start and do not change
    let shadow-size 1 + (items-for-sale / avg-per-seller)
    ask my-shadow [
      move-to myself
      set heading [heading] of myself
      set size shadow-size
    ]
  ]

  ask buyers [ update-buyer-display ]

  set starting-money-actual sum [money] of buyers

  reset-ticks
end

to-report get-random-amount [ dist amount ]
  report ifelse-value dist = "even" [
    1 + random (get-amount amount)
  ] [ ; "concentrated"
    1 + floor random-exponential ((get-amount amount) / 2)
  ]
end

to-report get-amount [ amount ]
  report ifelse-value amount = "high" [
    amount-high
  ] [ ; else "low"
    amount-low
  ]
end

to-report get-starting-value [ starting-value ]
  report precision ((starting-value / 2) + random (starting-value / 2)) 2
end

to go
  if (sum [items-for-sale] of sellers = 0 or (0 = count buyers with [money > 0 and want-to-buy > 0])) [ stop ]

  clear-drawing
  set sales-per-tick 0

  ; move our buyers to their next position in the circle
  ; record the positions first, since if we move before processing all of them, it screws things up
  ask buyers [
    let next ifelse-value who = (1 * population) [(2 * population) - 1] [who - 1]
    set next-xcor [xcor] of buyer next
    set next-ycor [ycor] of buyer next
  ]
  ; okay, now we can move
  ask buyers [
    set xcor next-xcor
    set ycor next-ycor
    facexy 0 0
  ]

  set remaining-supply (sum [items-for-sale] of sellers)

  let offset 1 + ticks mod population
  foreach (range 0 population) [ i ->
    let the-seller seller (population * 0 + i)
    let the-buyer buyer (population * 1 + ((i + offset) mod population))
    ask the-buyer [ do-commerce-with the-seller ]
  ]

  ask buyers [update-buyer-display]
  ask sellers [update-seller-display]
  set total-sales (total-sales + sales-per-tick)

  ask pops [
    ifelse (size < 0.1 or not stars?)
    [ die ]
    [
      set heading (atan (random-float 0.5 - 0.25) 1)
      jump 0.5
      set size size - 0.025
      set color color - 0.25
    ]
  ]

  ; sanity check
  if (any? buyers with [want-to-buy > 0 and willing-to-pay > money]) [ error "Cannot have turtles that want to pay more than their cash!" ]

  tick
end

to update-buyer-display
  if want-to-buy = 0 [
    set color 2
  ]
  set size 1 + (bought / avg-per-buyer)
  let shadow-size 1 + (want-to-buy / avg-per-buyer)
  ask my-shadow [
    move-to myself
    set heading [heading] of myself
    set size shadow-size
  ]
end

to update-seller-display
  if items-for-sale = 0 [ set color 2 ]
  set size 1 + (items-for-sale / avg-per-seller)
end

to do-commerce-with [ the-seller ]
  let asking [asking-price] of the-seller
  ifelse ([items-for-sale] of the-seller > 0 and want-to-buy > 0 and asking <= money and asking <= willing-to-pay) [
    create-link the-seller self yellow

    set sales-per-tick (sales-per-tick + 1)
    set want-to-buy (want-to-buy - 1)
    let price asking
    set money precision (money - price) 2
    set money ifelse-value money < min-price [0] [money]
    set bought (bought + 1)
    ask the-seller [
      set items-for-sale (items-for-sale - 1)
      set money precision (money + price) 2
      set sold (sold + 1)
      run behavior-after-sale
    ]
    run behavior-after-purchase
    create-star
  ] [
    ; else no purchase was made
    create-link the-seller self blue
    let hide? (sellers-ignore-full-buyers? and (want-to-buy = 0))
    ask the-seller [ (run behavior-no-sale hide?) ]
    run behavior-no-purchase
  ]
end

to create-star
  if stars? [
    hatch-pops 1 [
      set color yellow
      set shape "star"
      set size 0.5
      set label ""
    ]
  ]
end

to create-link [ some-seller some-buyer some-color ]
  ask some-seller [
    let oc color
    let x xcor
    let y ycor
    set color some-color
    set pen-size 3
    pen-down
    move-to some-buyer
    pen-up
    setxy x y
    set color oc
  ]
end

to change-price [ change ]
  let before asking-price
  set percent 1 + (change / 100)
  set asking-price check-for-min-price (precision (percent * asking-price) 2)
  if before = asking-price [
    if change < 0 and before != min-price [
      set asking-price precision (asking-price - min-price) 2
    ]
    if change > 0 [
      set asking-price precision (asking-price + min-price) 2
    ]
  ]
end

to change-payment [ change ]
  let before willing-to-pay
  set percent 1 + (change / 100)
  set willing-to-pay check-for-min-price (precision (percent * willing-to-pay) 2)
  if before = willing-to-pay [
    if change < 0 and before != min-price [
      set willing-to-pay precision (willing-to-pay - min-price) 2
    ]
    if change > 0 [
      set willing-to-pay precision (willing-to-pay + min-price) 2
    ]
  ]
  if willing-to-pay > money [ set willing-to-pay money ]
end

to-report seller-cash
  report sum [money] of sellers
end

to-report average-price
  report (ifelse-value total-sales = 0 [ 0.00 ] [ precision (seller-cash / total-sales) 2 ])
end

to-report percent-money-taken
  report 100 * sum [money] of sellers / starting-money-actual
end

to-report percent-items-sold
  report 100 * sum [sold] of sellers / sum [items-for-sale + sold] of sellers
end

to-report percent-demand-satisfied
  report 100 * sum [bought] of buyers / sum [want-to-buy + bought] of buyers
end

to-report check-for-min-price [ value ]
  report precision ifelse-value value < min-price [min-price] [value] 2
end


; Copyright 2017 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
245
10
804
570
-1
-1
19.0
1
10
1
1
1
0
0
0
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
260
76
293
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
80
260
162
293
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
810
10
1185
160
Seller Asking Prices (min, average, max)
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" "let top (floor ifelse-value average-price = 0 [max [asking-price] of sellers] [average-price * 2])\nset-plot-y-range 0 ifelse-value top < 1 [1] [top]"
PENS
"avg-asking-price" 1.0 0 -13345367 true "" "let ss (sellers with [items-for-sale > 0])\nifelse (count ss = 0) \n[ plot 0 ]\n[ plot mean [asking-price] of ss ]"
"min-asking-price" 1.0 0 -5325092 true "" "let ss (sellers with [items-for-sale > 0])\nifelse (count ss = 0) \n[ plot 0 ]\n[ plot min [asking-price] of ss ]"
"max-asking-price" 1.0 0 -5325092 true "" "let ss (sellers with [items-for-sale > 0])\nifelse (count ss = 0) \n[ plot 0 ]\n[ plot max [asking-price] of ss ]"

BUTTON
165
260
229
294
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
812
317
1185
483
Items
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"items-for-sale" 1.0 0 -13345367 true "" "plot sum [items-for-sale] of sellers"
"want-to-buy" 1.0 0 -5825686 true "" "plot sum [want-to-buy] of buyers"
"total-sales" 1.0 0 -7500403 true "" "plot total-sales"

SLIDER
39
11
212
44
starting-money
starting-money
0
500
500.0
25
1
NIL
HORIZONTAL

MONITOR
823
493
959
538
Average Sale Price $
average-price
2
1
11

MONITOR
963
493
1130
538
% of Starting Money Used
percent-money-taken
1
1
11

PLOT
811
163
1185
314
Buyer Willing-to-Pay (min, average, max)
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" "let top floor ifelse-value average-price = 0 [max [asking-price] of sellers] [average-price * 2]\nset-plot-y-range 0 ifelse-value top < 1 [1] [top]"
PENS
"avg-willing" 1.0 0 -5825686 true "" "let bs (buyers with [want-to-buy > 0 and money > 0])\nifelse (count bs = 0) \n[ plot 0 ]\n[ plot mean [willing-to-pay] of bs ]"
"max-willing" 1.0 0 -2382653 true "" "let bs (buyers with [want-to-buy > 0 and money > 0])\nifelse (count bs = 0) \n[ plot 0 ]\n[ plot max [willing-to-pay] of bs ]"
"min-willing" 1.0 0 -2382653 true "" "let bs (buyers with [want-to-buy > 0 and money > 0])\nifelse (count bs = 0) \n[ plot 0 ]\n[ plot min [willing-to-pay] of bs ]"

CHOOSER
3
52
114
97
supply-amount
supply-amount
"high" "low"
0

CHOOSER
121
52
239
97
supply-distribution
supply-distribution
"concentrated" "even"
1

CHOOSER
3
98
114
143
demand-amount
demand-amount
"low" "high"
1

CHOOSER
121
98
239
143
demand-distribution
demand-distribution
"concentrated" "even"
1

CHOOSER
42
152
201
197
seller-behavior
seller-behavior
"normal" "desperate" "random" "mix of all"
0

CHOOSER
42
199
201
244
buyer-behavior
buyer-behavior
"normal" "desperate" "random" "mix of all"
0

SWITCH
5
350
108
383
stars?
stars?
0
1
-1000

SWITCH
5
310
231
343
sellers-ignore-full-buyers?
sellers-ignore-full-buyers?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model demonstrates a very simple bidding market, where buyers and sellers try to get the best price for goods in a competitive setting.

## HOW IT WORKS

The agents in the inner ring of represent sellers, who bring some goods they want to sell to the market. The agents in the outer ring are the buyers, who bring money to the market to buy the goods.

Each round (tick), the buyers move to their right (counter-clockwise) and are paired with a seller. Then each buyer checks its paired seller's asking price. If it's lower than their asking-price, they'll buy 1 item. If it's higher, they'll buy nothing. Then each seller individually decides to either raise prices or lower prices based on their buyer's behavior. The buyers also individually lower or raise their expectations based on their seller's behavior.

The market will run through rounds until no buyer who wants to buy an item has money left to spend, or until all items are bought.

### PURCHASE DISPLAY

If a purchase is made, the link from seller to buyer turns yellow and a little star animation will start. Otherwise, the link will be blue with no animation.  If the transactions still take place too quickly to be noticed, the speed slider can slow the model down a bit.

As buyers get what they want, they get bigger and fill their maximum-buy-sized gray shadow. If they fully satisfy their demand, they'll turn dark grey.

Sellers start with a size based on how many items they brought to the market.  As they sell items, they get smaller. If they sell all their items, they'll turn dark grey.

## HOW TO USE IT

Press SETUP to generate a market, then the GO-ONCE button to run a single round, or the GO button to run the market until it completes.

* Initial supply and demand can be High or Low, and distributed can be even among all buyers and sellers or concentrated among a few.
* Behavior is set when SETUP is run and can be set to one of a few options (the description given is for buyers, but mirrored for sellers):
    * Normal - buyers will increase their willing to pay by a small amount if they are unable to make a purchase, otherwise they'll lower their willing-to-pay if they do manage to buy an item.
    * Desperate - increases the amount buyers will increase thier willing-to-pay when they fail to make a purchase.
    * Random - the behavior of each buyer will be random - some will be very desperate, others might decrease the amount they're willing-to-pay when they fail to make a purchase.
    * Mix of all - each buyer will be set to one of the three above behaviors randomly.
* You can also toggle whether sellers will consider full buyers or not. A full buyer is one who has already satisfied their demand. This would simulate the sellers being able to tell who is walking past their market stall without even looking at the items' prices.

## THINGS TO NOTICE

Try slowing the tick speed down and watching a single buyer on the outside ring as it moves. See how it gets bigger when it makes a purchase and its link turns yellow, and how big it is when it turns completely dark grey (if it does).

Run the model multiple times with the same settings to get an idea of what's happening to the asking and buying prices over time.

## THINGS TO TRY

Play around with the different setup options to try the following:

* Can you get to 100% of both items sold and demand satisfied? If not, how close can you get?
* What's the longest you can get a market to run for (in number of ticks)?
* What's the highest average price you can get at the end of a round?
* Sometimes the market stops when there are buyers on the outside ring who still want to purchase things (% Demand Satisfied is not 100%) and there is still money available to spend (% Money Taken is not 100%). How this can be?

## EXTENDING THE MODEL

It's fairly easy to add new behaviors to buyers and sellers, just adjust the chooser box with a new option, then add it in the appropriate `create-ordered-sellers` or `create-ordered-buyers` block in the setup procedure.

## NETLOGO FEATURES

In order to try to keep the Asking Price and Buying Price plots displaying relevant information, we set the `plot-y-range` manually using an update command based on the most recent average price.

Behaviors for buyers and sellers are set during setup, and we use anonymous procedures stored in turtles-own variables. This allows us to very easily execute different behavior while the market is running by just using the `run` keyword with those behavior variables.

## RELATED MODELS

See the Simple Economy model or Sugarscape models to explore other economic concepts.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Baker, J. and Wilensky, U. (2017).  NetLogo Bidding Market model.  http://ccl.northwestern.edu/netlogo/models/BiddingMarket.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2017 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2017 Cite: Baker, J. -->
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
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Sample Experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-sales</metric>
    <metric>average-price</metric>
    <metric>sum [money] of buyers</metric>
    <metric>sum [money] of sellers</metric>
    <metric>mean [asking-price] of sellers with [items-for-sale &gt; 0]</metric>
    <metric>min [asking-price] of sellers with [items-for-sale &gt; 0]</metric>
    <metric>max [asking-price] of sellers with [items-for-sale &gt; 0]</metric>
    <metric>mean [willing-to-pay] of buyers with [want-to-buy &gt; 0]</metric>
    <metric>min [willing-to-pay] of buyers with [want-to-buy &gt; 0]</metric>
    <metric>max [willing-to-pay] of buyers with [want-to-buy &gt; 0]</metric>
    <enumeratedValueSet variable="nosy-neighbor">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomize-starting-demand">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-asking-price">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomize-starting-supply">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-supply">
      <value value="96"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-money">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-demand">
      <value value="96"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="starting-willing-to-pay">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="purchase-choice">
      <value value="&quot;buyer&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="buyer-sensitivity" first="5" step="5" last="25"/>
    <steppedValueSet variable="seller-sensitivity" first="5" step="5" last="25"/>
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

line
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 0 135 45
Line -7500403 true 150 0 165 45
@#$#@#$#@
1
@#$#@#$#@
