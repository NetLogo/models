;;; Global variables
globals [
  ; Global statistics
  trade-unit
  global-cash
  global-devotion
  global-tokens

  ; Global status
  asks          ; list<order>, Listed selling orders.
  bids          ; list<order>, Listed buying orders.
  latest-volume ; number, Latest average trading price (in $).
  latest-amount ; number, Latest trading amount (in $)
  latest-price  ; number, Latest average trading price (in $).
  total-volume  ; number, Total trading volume.
  total-amount  ; number, Total trading amount (in $)

  ; Some cache to improve the computational performance
  best-bid-price
  best-ask-price
  recent-price
  recent-amount
  recent-volume
  recent-change
  price-to-date
]

breed [ orders order ]  ; Each order (which is, in our case, always limited) is represented as a turtle.
orders-own [
  pending?    ; boolean, Whether the order is still pending? (and therefore, not matched yet and not visible to other pops)
  removed?    ; Whether the order has been removed? (we intend to reuse the turtle structure for optimization)
  buy-side?   ; boolean, True/Buy, False/Sell
  price       ; number, Price Limit
  quantity    ; number, Size of the order
  owner       ; turtle, Owner Turtle
  remaining   ; number, Remaining quantity of the order
]

; Each behavioral agent is represented as a turtle.
; Trader: represents a party that is capable to trade the token (representing gold, silver, stock, cryptocurrency token, etc).
breed [ traders trader ]
traders-own [
  cash       ; number, Cash at hand
  stockpile  ; table (or map) between <any, number>, Stockpile of the trader
  my-bid      ; order, The bidding order of mine
  my-ask      ; order, The asking order of mine
  belief     ; number, Constant belief of the price ($)
  utility    ; number, Cash + Belief * Stockpile ($)
  initial-utility ; number, utility value before the trading starts
  strategy   ; number, pre-defined strategy of the trader
]

;;; Backbone of the model
; setup: Initialize the model
to setup
  clear-all
  reset-ticks

  create-turtles 1 [
    set shape "circle"
  ]

  ; Create and populate traders
  create-traders honest-traders [
    set strategy "honest"
  ]
  create-traders cunning-traders [
    set strategy "cunning"
  ]

  ; Both kind of traders receive initial assets under the same rule
  ask traders [
    populate-trader
    set cash get-random-amount initial-cash
    set stockpile get-random-amount initial-tokens
    set belief get-random-amount initial-belief
    set utility cash + belief * stockpile
    set initial-utility utility
  ]
  arrange-traders

  ; Calculate the global statistics
  set global-tokens max list sum [ stockpile ] of traders 1
  set global-cash max list sum [ cash ] of traders 1

  ; Trade unit is calculated by the trade precision (e.g. precision=0, unit=1; precision=2, unit=0.01)
  set trade-unit 10 ^ (trade-precision * -1)
  render-traders
end

; go: Loop of the model
to go
  ; Clear previous orders
  let previous-price latest-price
  set asks []
  set bids []

  ; Ask people to trade
  ask traders [
    if strategy = "honest" [ honest-strategy ]
    if strategy = "cunning" [ cunning-strategy ]
    set utility cash + belief * stockpile
  ]
  matchmake-all
  calculate-info previous-price

  ; When there are no referencing prices, use the latest price to help inform traders
  ifelse length bids > 0 and length asks > 0 [
    set best-bid-price [ price ] of item 0 bids
    set best-ask-price [ price ] of item 0 asks
  ] [ calculate-best-order latest-price ]

  ; Finish the tick
  render-traders
  tick
end

; Calculate some information for the next tick
to calculate-info [ previous-price ]
  ifelse previous-price = 0 [
    set recent-change 0
    set recent-amount latest-amount
    set recent-volume latest-volume
    set recent-price latest-price
  ] [
    ifelse latest-amount > 0 [
      set recent-change moving-average recent-change ln (latest-price / previous-price)
      set recent-amount moving-average recent-amount latest-amount
      set recent-volume moving-average recent-volume latest-volume
      set recent-price recent-volume / recent-amount
    ] [
      set recent-change moving-average recent-change 0
    ]
  ]
  set price-to-date total-volume / total-amount
end

; honest-strategy: The "Honest" strategy
to honest-strategy
  if cash >= belief [
    submit-order my-bid belief 1
  ]
  if stockpile > 0 [
    ; We seek to prevent trading with oneself, and this is the easiest way - just add 0.01 to avoid it
    submit-order my-ask 0.01 + belief 1
  ]
end

; honest-strategy: The "Cunning" strategy
to cunning-strategy
  ; Get the best selling price and use it, if it is lower than my belief
  let purchase-price belief
  if best-ask-price != 0 and best-ask-price < purchase-price [ set purchase-price best-ask-price ]
  ; Get the best buying price and use it, if it is higher than my belief
  let sell-price belief + 0.01
  if best-bid-price > sell-price [ set sell-price best-bid-price ]
  ; Submit the orders
  if (cash >= purchase-price) [
    submit-order my-bid purchase-price 1
  ]
  if (stockpile > 0) [
    submit-order my-ask sell-price 1
  ]
end

;;; Helper: Distribution
; random-amount: Get a random amount of a uniform distribution from [amount/2, amount]
to-report get-random-amount [ amount ]
  report random amount * 0.5 + amount * 0.5
end

; moving-average: Get exponentially weighted moving average. 0 is impossible for price, so we treat it as NULL.
to-report moving-average [ existing-value new-value ]
  let weight 0.1
  report existing-value * (1 - weight) + new-value * weight
end

;;; Helper: Renderer
; Render all traders.
to render-traders
  if latest-amount = 0 [ stop ]
  ; Traders
  ask traders [
    set label precision stockpile trade-precision
  ]
  ; Market
  ask turtle 0 [
    set size sqrt latest-amount
    ifelse recent-change > 0 [
      set color scale-color red (recent-change / recent-price) 200 0
    ] [
      set color scale-color green (recent-change / recent-price) -200 0
    ]
  ]
end

; Arrange the traders in a circle.
to arrange-traders
  if behaviorspace-run-number != 0 [ stop ]
  let index 0
  let angle 360 / count traders
  ; We want to keep traders in the same order even when you dynamically introduce new trader.
  ; With "ask turtles", once new traders get introduced, we would get into trouble.
  foreach sort-on [who] traders [
    the-trader ->
      ask the-trader [
        setxy 0 0
        set heading index * angle
        fd max-pxcor * 0.9
      ]
      set index index + 1
  ]
end

; The following code is the basis of the matchmake mechanism
;;; Mechanism-related code
; This serves as a constructor which needs to be executed to initialize the trader
to populate-trader
  set my-bid spawn-order true
  set my-ask spawn-order false
  set size 2
end

; Spawn an order and return it / turtle-context
to-report spawn-order [ s ]
  let current 0
  hatch-orders 1 [
    set buy-side? s
    set pending? false
    set removed? true
    set hidden? true
    set current self
    set owner myself
  ]
  report current
end

; We are trying to re-use orders to boost the performance of traders
; s accepts an order; p means price; q means quantity.
to submit-order [ s p q ]
  if p <= 0 [ error "Price cannot go below zero!" ]
  if q <= 0 [ error "Quantity cannot go below zero!" ]
  ask s [
    set removed? false
    set pending? true
    set price p
    set quantity q
    set remaining q
  ]
end

; Matchmake all pending? orders
; All pending? orders are randomly sent to the market and get matched
; See the info tab for more details
to matchmake-all
  set latest-amount 0
  set latest-volume 0
  calculate-best-order 0
  let eligible-orders orders with [ removed? = false and pending? = true ]
  ask eligible-orders [ matchmake ]
  if latest-amount > 0 [ set latest-price latest-volume / latest-amount ]
end

; Matchmake a single pending? order
; If a trader run out of money/stockpile, the orders we touched will be cancelled
to matchmake
  set pending? false
  ; Deal with the order: if the order is fully fulfilled, we stop and skip the listing process
  ifelse buy-side? [
    ; Remove impossible orders to optimize the performance
    if price < best-ask-price [
      set removed? true
      stop
    ]
    ; Buy order
    while [ length asks > 0 and [ price ] of first asks < price ] [
      execute-order self first asks
      if removed? = true [ stop ]
    ]
  ] [
    ; Remove impossible orders to optimize the performance
    if price > best-bid-price [
      set removed? true
      stop
    ]
    ; Sell order
    while [ length bids > 0 and [ price ] of first bids > price ] [
      execute-order first bids self
      if removed? = true [ stop ]
    ]
  ]
  ; Finish the process and list this offer
  ; Here, we linearly find the proper position of this offer, and insert it
  ifelse buy-side? [
    let len length bids
    ifelse len = 0 [
      set bids (list self)
    ] [
      let index 0
      while [ index < len and [ price ] of (item index bids) > price ] [ set index index + 1 ]
      set bids insert-item index bids self
    ]
  ] [
    let len length asks
    ifelse len = 0 [
      set asks (list self)
    ] [
      let index 0
      while [ index < len and [ price ] of (item index asks) < price ] [ set index index + 1 ]
      set asks insert-item index asks self
    ]
  ]
end

; Calculate "Best" orders (the buying order with the highest price; the selling order with the lowest price)
to calculate-best-order [ default ]
  let best-bid max-one-of orders with [ removed? = false and buy-side? = true ] [ price ]
  set best-bid-price ifelse-value best-bid = nobody [ default * 0.999 ] [ [ price ] of best-bid ]
  let best-ask min-one-of orders with [ removed? = false and buy-side? = false ] [ price ]
  set best-ask-price ifelse-value best-ask = nobody [ default * 1.001 ] [ [ price ] of best-ask ]
end

; Order sorter (by price, asc)
; Implicit tiebreaker: time of the order (older orders get prioritized)
to-report min-order [ order1 order2 ]
  if order1 = nobody or [ removed? ] of order1 [
    ifelse order2 = nobody or [ removed? ] of order2
      [ report nobody ]
      [ report order2 ]
  ]
  if order2 = nobody or [ removed? ] of order2 [ report order1 ]
  ifelse [ price ] of order1 > [ price ] of order2
  [ report order2 ]
  [ report order1 ]
end

; Order sorter (by price, descending)
; Implicit tiebreaker: time of the order (older orders get prioritized)
to-report max-order [ order1 order2 ]
  if order1 = nobody or [ removed? ] of order1 [
    ifelse order2 = nobody or [ removed? ] of order2
      [ report nobody ]
      [ report order2 ]
  ]
  if order2 = nobody or [ removed? ] of order2 [ report order1 ]
  ifelse [ price ] of order1 < [ price ] of order2
  [ report order2 ]
  [ report order1 ]
end

; Try to execute the two orders
to execute-order [ bid-order ask-order ]
  let bidder [ owner ] of bid-order
  let asker [ owner ] of ask-order
  ; For now, the lowest price will be used
  let deal-price min (list [ price ] of bid-order [ price ] of ask-order)
  ; Calculate the maximum available
  let bidder-maximum floor-to-unit ([ [ cash ] of bidder / deal-price ] of bid-order)
  if bidder-maximum <= 0 [ ask bid-order [ remove-order ] stop ]
  let asker-maximum [ stockpile ] of asker
  if asker-maximum <= 0 [ ask ask-order [ remove-order ] stop ]
  ; Calculate the amount
  let deal-amount min (list
    [ remaining ] of bid-order
    [ remaining ] of ask-order
    bidder-maximum asker-maximum
  )
  ; Deal!
  ask bidder [
    set cash cash - deal-amount * deal-price
    set stockpile stockpile + deal-amount
  ]
  ask asker [
    set cash cash + deal-amount * deal-price
    set stockpile stockpile - deal-amount
  ]
  ; Record it
  set latest-amount latest-amount + deal-amount
  set total-amount total-amount + deal-amount
  set latest-volume latest-volume + deal-amount * deal-price
  set total-volume total-volume + deal-amount * deal-price
  ; Change the orders
  ask (turtle-set bid-order ask-order) [
    set remaining remaining - deal-amount
    check-order
  ]
end

; Check whether a given order is done and needs to be removed
to check-order
  if remaining = 0 [ remove-order ]
end

; Forcibly remove an order.
to remove-order
  ifelse buy-side? [
    set bids remove self bids
  ] [
    set asks remove self asks
  ]
  set pending? false
  set removed? true
end

; Clamp the number between a range.
to-report clamp [ min-value source max-value ]
  ifelse source > max-value [ report max-value ]
  [ ifelse source < min-value [ report min-value ] [ report source ] ]
end

; Floor to individual trade units
to-report floor-to-unit [ source ]
  report floor (source / trade-unit) * trade-unit
end


; Copyright 2021 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
203
10
744
552
-1
-1
13.0
1
13
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
15
11
95
44
NIL
setup\n
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
43
95
76
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

BUTTON
100
10
185
75
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

MONITOR
960
35
1073
80
Price to Date$
price-to-date
2
1
11

MONITOR
760
35
863
80
Latest Price$
latest-price
2
1
11

MONITOR
856
35
961
80
Latest Volume$
latest-volume
2
1
11

MONITOR
1195
35
1284
80
Total Cash$
global-cash
2
1
11

MONITOR
1071
35
1196
80
Circulating Tokens
global-tokens
2
1
11

PLOT
760
91
1285
241
Trading Prices
Ticks
Price
0.0
20.0
5.0
5.0
true
true
"" ""
PENS
"Latest" 1.0 0 -13345367 true "" "if ticks > 0 [ plot latest-price ]"

TEXTBOX
14
120
164
138
Basic Parameters
12
0.0
1

SLIDER
12
138
184
171
trade-precision
trade-precision
0
3
0.0
1
1
NIL
HORIZONTAL

TEXTBOX
13
187
163
205
Traders & Strategies
12
0.0
1

SLIDER
12
207
184
240
honest-traders
honest-traders
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
12
248
184
281
cunning-traders
cunning-traders
0
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
760
14
910
32
Market situation
12
0.0
1

TEXTBOX
762
262
912
280
Utility distribution
12
0.0
1

MONITOR
760
284
868
329
Total Utilities
sum [ utility ] of traders
0
1
11

MONITOR
867
284
984
329
Average Utilities
mean [ utility ] of traders
0
1
11

MONITOR
982
284
1068
329
Avg (Honest)
mean [ utility ] of traders with [ strategy = \"honest\" ]
0
1
11

MONITOR
1066
284
1162
329
Avg (Cunning)
mean [ utility ] of traders with [ strategy = \"cunning\" ]
0
1
11

MONITOR
1161
284
1286
329
Cunning : Honest %
mean [ utility ] of traders with [ strategy = \"cunning\" ] / mean [ utility ] of traders with [ strategy = \"honest\" ] * 100
3
1
11

PLOT
760
339
1287
489
Average Utilities Gain (%)
Ticks
Utilities
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Everyone" 1.0 0 -11053225 true "" "if count traders = 0 [ stop ]\nplot mean [ utility / initial-utility * 100 - 100 ] of traders"
"Cunning" 1.0 0 -13345367 true "" "if count traders with [ strategy = \"cunning\" ] = 0 [ stop ]\nplot mean [ utility / initial-utility * 100 - 100 ] of traders with [ strategy = \"cunning\" ]"
"Honest" 1.0 0 -10899396 true "" "if count traders with [ strategy = \"honest\" ] = 0 [ stop ]\nplot mean [ utility / initial-utility * 100 - 100 ] of traders with [ strategy = \"honest\" ]"

SLIDER
12
290
184
323
initial-cash
initial-cash
0
2000
1000.0
1
1
$
HORIZONTAL

SLIDER
12
332
184
365
initial-tokens
initial-tokens
0
200
50.0
1
1
NIL
HORIZONTAL

SLIDER
11
375
183
408
initial-belief
initial-belief
0
100
25.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model aims to reproduce phenomena that emerge in modern-day cryptocurrency markets, but is general enough to model any resource traded using the concept of a limited order book. A Limited Order Book is a simple idea: it is a record of outstanding limit orders maintained by a stock exchange. A limit order is a type of order to buy or sell a security at a specific price or better. The simple act of buying and selling in this manner creates complex behaviors at the level of the exchange.

## HOW IT WORKS

In this model, each trader holds some `cash`, some tokens (`stockpile`), and trades in the same limited order book. Tokens can be thought of as any tradable good, such as gold, silver, oil, stocks, or cryptocurrency such as Bitcoin or Ethereum. Each trader also holds a firm and constant `belief` in the value of tokens, which is randomly set somewhere in the interval [initial-belief / 2, initial-belief] during the initialization of the model.

Time is split into multiple slices and represented as ticks. In each tick, each trader uses a pre-determined strategy to put limited orders on the market. Then, the matchmaking process starts between buyers and sellers. First, we create two empty lists to store pending orders. Then, since we assume that each trader has an equal opportunity of trading, we match each order randomly, during which:

1. If it is a SELL order, we try to find if any of the unmatched BUY orders at the stated sale price or higher. If so, we will execute the order sale at the highest possible price and the two parties will exchange tokens and cash.
2. We repeat this process until there are no remaining matching BUY orders or the selling order is completely executed (this means if you sell 100 tokens, they might not all sell to the same buyer).
2. If the SELL order is not fully executed, we will put it into the unmatched list for selling orders, waiting for other buying orders to pick it up.

For BUY orders, we go through the same process but with an opposite bias. In other words, we try to match BUY orders to _cheaper_ prices.

Consequently, the market price of the token, as well as the other information available in the market, is calculated and provided to traders in the next tick.

In this fairly simplified model, we only implement two simple trading strategies.

The first one is called "honest", in which the trader will always try to buy and sell tokens at a price according to his/her belief of the value of that token.

The second strategy we call "cunning" and is slightly more complicated. Here, the trader will always buy with a price of either the best-selling-price or their belief (whichever is smaller) and sell with a price of either the best-buying-price or their belief (whichever is larger).

Note that after the matchmaking process, both strategies will cancel unfulfilled orders and issue new ones rather than keeping the orders on the exchange.

## HOW TO USE IT

### Basic Usage
* SETUP button resets the model.
* GO button allows the model to continuously simulate the market.
* GO-ONCE button asks the model to simulate the market for 1 tick.

### Parameters
The following parameters affect how the market works in this model.

* The TRADE-PRECISION slider sets the maximum precision for the number of tokens for each trade. For example, if you set it to 0, the minimum trade unit would be 10^0 = 1. If you set it to 1, the minimum trade unit would be 10^(-1) = 0.1. Default is 1. This models the fact that these currencies are often sold in very small units.
* The HONEST-TRADERS slider determines how many traders with the "honest" strategy will be spawned during the setup process.
* The CUNNING-TRADERS slider determines how many traders with the "cunning" strategy will be spawned during the setup process.

The below parameters all set the maximum amount of CASH, TOKENS, and BELIEF for each agent. Each is initialized according to a random draw from a uniform distribution on the interval [amount/2, amount]:
* The INITIAL-CASH slider sets the maximum cash each trader will receive when the model is initialized.
* The INITIAL-TOKENS slider sets the maximum tokens each trader will receive when the model is initialized.
* The INITIAL-BELIEF slider determines the maximum initial BELIEF of each trader.

### Plots and Monitors
The plots and monitors give you a set of tools to measure the market as it transacts.

* The **Trading Prices** plot allows you to watch the daily trading prices.
* The **Average Utilities Gain** plot allows you to follow the _average utility gain_ of traders with different strategies. Utility, in this model, is defined as the sum of cash and value of the stockpile (cash + belief * stockpile).

## THINGS TO NOTICE

* Notice that trading seems to stop only a few hundred ticks into running the model. Why might that be the case? How might you make trading continue longer without changing the code of the model?
* Notice that the sum of each traders' utilities is increasing, no matter how many honest or cunning traders are spawned. Why might this  happen? Does everyone in the market equally share the gains? Why or why not?

## THINGS TO TRY

* **Make all traders honest or cunning.** How fast do traders stop trading in each of these situations?
* **Try to mix honest traders with cunning ones.** What happened to the utility gains relative to each other. Why does that occur?
* **Try first giving traders lots of CASH. Then trying giving traders lots of TOKENS.** How does the market behave differently across these two scenarios?

## EXTENDING THE MODEL

Try to create a more complicated trading strategy (there are a ton of possibilities)!

* You could try to allow traders to trade more than 1 unit of TOKENS each trade.
* You could also try to allow traders to change their belief in the value of the token according to some random factors or through watching the market dynamics.

## NETLOGO FEATURES

While in many NetLogo models we want to ask turtles to do things in a random order to not introduce bias toward particular turtles, here we use `foreach sort-on [who] traders` so that the traders are deterministically called by their `who` property and always rendered in the same order.This feature enables you to dynamically introduce traders into the model and keep its visualization stable and intact.

## RELATED MODELS

See the Bidding Market, simple economy, and Sugarscape models to explore more market or economy-related models.

## REFERENCES

1. Baker, J. and Wilensky, U. (2017). NetLogo Bidding Market model. http://ccl.northwestern.edu/netlogo/models/BiddingMarket. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
2. Chen, J. (2021). Cryptocurrency Trading Model. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Chen, J. and Wilensky, U. (2021).  NetLogo Limited Order Book model.  http://ccl.northwestern.edu/netlogo/models/LimitedOrderBook.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

This model was developed as part of the Spring 2021 Multi-agent Modeling course offered by Dr. Uri Wilensky at Northwestern University. For more info, visit http://ccl.northwestern.edu/courses/mam/. Special thanks to Teaching Assistants Jacob Kelter, Leif Rasmussen, and Connor Bain.

## COPYRIGHT AND LICENSE

Copyright 2021 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2021 MAM2021 Cite: Chen, J. -->
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
setup repeat 35 [ go ]
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
