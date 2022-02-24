globals
[
  travel-time ; travel time of last turtle to complete route
  top ; travel time of last turtle to complete top route
  bottom ; travel time of last turtle to complete bottom route
  middle ; travel time of last turtle to complete middle route
  spawn-time ; next tick to spawn a new turtle
  middle-prev ; previous status of middle route
  avg ; total average of travel time (smoothed)
  cars-spawned ; total number of active commuters
  top-prob ; probability for agent to take top route
  bottom-prob ; probability for agent to take bottom route
  middle-prob ; probability for agent to take middle route
  top-left ; patch that is the top-left node of the grid
  top-right ; patch that is the top-left node of the grid
  bottom-right ; patch that is the bottom-right node of the grid
  bottom-left ; patch that is the bottom-left node of the grid
]

breed[ commuters commuter ]

patches-own
[
  delay ; ticks turtle has to spend before leaving patch
  base-delay ; base amount of ticks for dynamic delay road
  road-type ; road with static delay or road with dynamic delay
  last-here ; tick that the a dynamic road was last occupied
]

commuters-own
[
  birth-tick ; tick number that the turtle was created
  ticks-here ; number of ticks the turtle has been at its current patch
  route ; the route the turtle is taking
]

to setup
  clear-all
  set top-left patch -22 22 ; define corner nodes of the traffic grid
  set top-right patch 22 22
  set bottom-left patch -22 -22
  set bottom-right patch 22 -22
  setup-roads ; draw all the roads between the corner nodes
  reset-ticks
end

to go
  check-middle
  spawn-commuters
  ask commuters [ commuter-move ]
  ask patches with [road-type = 1] [ determine-congestion ]
  tick
end

to commuter-move ; turtle procedure
  ifelse ticks-here > delay ; advance if the turtle has waiting long enough
  [
    set last-here ticks
    move-to patch-ahead 1
    set ticks-here 1
  ]
  [ set ticks-here ticks-here + 1 ]
  if patch-here = top-right and route = 0  [face bottom-right ] ; turn if at corner patch
  if patch-here = top-right and route = 2 [ face bottom-left]
  if patch-here = bottom-left [ face bottom-right ]
  if patch-here = bottom-right [ end-commute ]; if turtle finished route
end

to end-commute   ; turtle procedure
  ; handles reporting the travel time when the commuter reaches the end of its route
  set travel-time (ticks - birth-tick) / 450
  ifelse avg = 0
  [
    set avg travel-time
  ]
  [
    set avg ((19 * avg + travel-time) / 20)
  ]
  ifelse route = 0
  [
    ifelse top = 0
    [
      set top travel-time
    ]
    [
      set top ((travel-time) + ((smoothing - 1) * top)) / smoothing
    ]
  ]
  [
  ifelse route = 1
    [
    ifelse bottom = 0
      [
        set bottom travel-time
      ]
      [
      set bottom ((travel-time) + ((smoothing - 1) * bottom)) / smoothing
      ]
    ]
    [
      ifelse middle = 0
      [
        set middle travel-time
      ]
      [
        set middle ((travel-time) + ((smoothing - 1) * middle)) / smoothing
      ]
    ]
  ]
  die

end

to spawn-commuters  ;turtle procedure
  ; spawns new commuters and sets up their properties
  ifelse spawn-time > (250 / spawn-rate) [
    ask patch -22 22 [
      sprout-commuters 1 [
        set cars-spawned cars-spawned + 1
        set color one-of [99]
        set birth-tick ticks
        set ticks-here 1
        set route new-route
        ifelse route = 0  or route = 2 [ facexy 22 22 ][ facexy -22 -22 ]
        set size 3.5
        set shape one-of [ "car" "truck" ]
      ]
    ]
    set spawn-time 0
  ]
  [ set spawn-time spawn-time + 1 ]
end

to determine-congestion ; patch procedure that determines congestion of dynamic patches
  ifelse last-here = 0 [ ; congestion is determine based on how recently the last commuter was here
    set delay int (base-delay / 2)
  ][
    set delay floor (((250 / spawn-rate)/(ticks - last-here + 1)) * base-delay)
  ]
  let g 255 + floor (255 * (0.5 - (delay / base-delay)))
  if g < 127 [set g 127]
  if g > 255 [set g 255]
  set pcolor (list 255 g 0)
end

to check-middle ; handle opening and closing the middle route
  if middle-on? != middle-prev
  [
    ifelse middle-on?
    [
      draw-road 3 top-right bottom-left
      set middle-prev middle-on?
    ]
    [
      if count commuters with [ route = 2 ] = 0
      [
        draw-road 4 top-right bottom-left
        set middle-prev middle-on?
      ]
    ]

  ]
end

to setup-roads
  ask patches [ ; create grass
    let g random 16 + 96
    let c (list 0 g 0)
    set pcolor c
  ]
  ask top-left [ ; setup corner patches
    set pcolor green
    set delay 10
    ask neighbors [set pcolor 5]
  ]
  ask bottom-right [
    set pcolor red
    set delay 10
    ask neighbors [set pcolor 5]
  ]
  ask bottom-left [
    set pcolor blue
    set delay 10
    ask neighbors [set pcolor 5]
  ]
  ask top-right [
    set pcolor blue
    set delay 10
    ask neighbors [set pcolor 5]
  ]
  ; Draw roads between corner nodes
  draw-road 1 top-left top-right
  draw-road 1 bottom-left bottom-right
  draw-road 0 top-left bottom-left
  draw-road 0 top-right bottom-right
  set middle-prev middle-on?
  ifelse middle-on?
  [
    draw-road 3 top-right bottom-left
  ]
  [
    draw-road 4 top-right bottom-left
  ]
end

to draw-road [type-of-road start finish]
  ; This procedure draws roads of different types between 2 patches.
  ; type-of-road in {0, 1, 3, 4}
  ; 0 - dynamic congestion road
  ; 1 - static congestion road
  ; 3 - middle road (zero congestion)
  ; 4 - deactivated middle road

  let the-heading atan ([pxcor] of finish - [pxcor] of start) ([pycor] of finish - [pycor] of start)
  if (type-of-road = 3)
  [
    set start [patch-at-heading-and-distance the-heading 1] of start
    set finish [patch-at-heading-and-distance (the-heading + 180) 1] of finish
  ]
  if (type-of-road = 4)
  [
    set start [patch-at-heading-and-distance the-heading 2] of start
    set finish [patch-at-heading-and-distance (the-heading + 180) 2] of finish
  ]
  let current-patch [patch-at-heading-and-distance the-heading 1] of start
  while [ not (current-patch = finish) ]
  [
    ask current-patch
    [
      if-else type-of-road < 4
      [
        if-else type-of-road = 1
        [
          set pcolor yellow
          set delay 5
          set road-type 1
          set base-delay 10
        ]
        [
          if-else type-of-road = 0
          [
            set pcolor orange
            set delay 10
          ]
          [
            set pcolor 9.9
            set delay 0
          ]
        ]
        ask patch-at-heading-and-distance (the-heading + 90) 1 [set pcolor 5]
        ask patch-at-heading-and-distance (the-heading - 90) 1 [set pcolor 5]
        if type-of-road = 3
        [
        ask patch-at-heading-and-distance (the-heading + 40) 1 [set pcolor 5]
        ask patch-at-heading-and-distance (the-heading - 45) 1 [set pcolor 5]
        ]
        set current-patch patch-at-heading-and-distance the-heading 1
      ]
      [
        set pcolor 2
        if (not (patch-at-heading-and-distance the-heading 1 = finish))
        [
          ask patch-at-heading-and-distance (the-heading + 40) 1 [set pcolor 2]
          ask patch-at-heading-and-distance (the-heading - 45) 1 [set pcolor 2]
        ]
        if (not (self = [patch-at-heading-and-distance the-heading 1] of start))
        and (not (patch-at-heading-and-distance the-heading 1 = finish))
        [
          ask patch-at-heading-and-distance (the-heading + 90) 1 [set pcolor 2]
          ask patch-at-heading-and-distance (the-heading - 90) 1 [set pcolor 2]
        ]
        set current-patch patch-at-heading-and-distance the-heading 1
      ]
    ]
  ]
end

to-report new-route ; turtle context reporter
 ; get route for new turtle based on selected mode
  ifelse mode = "Best Known /w Random Deviation"
  [ report best-random-route ]
  [
    ifelse mode = "Empirical Analytical"
    [ report analytical-route ]
    [
      ifelse mode = "Probabilistic Greedy"
      [report probabalistic-greedy-route ]
      [
        report 0
      ]
    ]
  ]
end

;; Algorithms for selecting routes:
to-report analytical-route ; turtle context reporter
  ifelse middle-on?
  [
    ifelse count other commuters = 0 [report random 3]
    [
      let top-score
      (count other commuters with [ route = 0 or route = 2 ] / count other commuters) * 1 + 1
      let bottom-score
      (count other commuters with [ route = 1 or route = 2 ] / count other commuters) * 1 + 1
      let middle-score
      (count other commuters with [ route = 2 ] / count other commuters) * 2
      ifelse top-score < bottom-score and top-score < middle-score
      [
        report 0
      ][
        ifelse bottom-score < middle-score and bottom-score < top-score
        [
          report 1
      ][
          ifelse top-score = bottom-score and middle-score = top-score
          [
            report random 3
          ][
            report 2
          ]
        ]
      ]
    ]
  ]
  [
    ifelse count other commuters = 0 [report random 2]
    [
      let top-score (count other commuters with [route = 0] / count other commuters) * 1 + 1
      let bottom-score (count other commuters with [route = 1] / count other commuters) * 1 + 1
      ifelse top-score < bottom-score [report 0][report 1]
    ]
  ]
end

to-report best-random-route ; turtle context reporter
  ; assigns a route to the commuter that currently has the best travel time
  ; with some random chance of deviating to a less optimal route
  ifelse middle-on?
  [
    ifelse middle = 0 or top = 0 or bottom = 0
    [
      report random 3
    ]
    [
      ifelse random 100 < 100 - randomness
      [
        ifelse middle < top and middle < bottom
        [
          report 2
        ][
          ifelse top < middle and top < bottom
          [
            report 0
          ][
            report 1
          ]
        ]
      ]
      [
        report random 3
      ]
    ]
  ]
  [
    ifelse top = 0 or bottom = 0 [report random 2]
    [
      ifelse random 100 < 100 - randomness
      [
        ifelse top < bottom
        [
          report 0
        ][
          report 1
        ]
      ]
      [
        report random 2
      ]
    ]
  ]
end

to-report probabalistic-greedy-route ; turtle context reporter
; assigns a route to the commuter with a probability proportional to
; how much better the route is than the other routes
  ifelse middle-on?
  [
    ifelse middle = 0 or top = 0 or bottom = 0 [report random 3]
    [

      let t-dif (2 - top)
      if t-dif < 0 [ set t-dif 0 ]
      set t-dif t-dif ^ (randomness / 10)
      let b-dif (2 - bottom)
      if b-dif < 0 [ set b-dif 0 ]
      set b-dif b-dif ^ (randomness / 10)
      let m-dif (2 - middle)
      if  m-dif < 0 [ set m-dif 0 ]
      set m-dif m-dif ^ (randomness / 10)
      let sigma1 0
      let sigma2 0
      if-else not ((t-dif + b-dif + m-dif) = 0 ) [
        set sigma1 t-dif / (t-dif + b-dif + m-dif)
        set sigma2 b-dif / (t-dif + b-dif + m-dif)
      ]
      [
        set sigma1 0.33
        set sigma2 0.33
      ]
      set top-prob sigma1
      set bottom-prob sigma2
      set middle-prob 1 - sigma1 - sigma2
      let split1 1000 * sigma1
      let split2 1000 * (sigma1 + sigma2)
      let rand random 1000
      ifelse rand < split1
      [
        report 0
      ][
        ifelse rand < split2
        [
          report 1
        ][
          report 2
        ]
      ]
    ]
  ]
  [
    ifelse top = 0 or bottom = 0 [report random 2]
    [
      let t-dif (2 - top) ^ (randomness / 10)
      let b-dif (2 - bottom) ^ (randomness / 10)
      let sigma t-dif / (t-dif + b-dif)
      set top-prob sigma
      set bottom-prob 1 - sigma
      let split 1000 * sigma
      ifelse random 1000 < split
      [
        report 0
      ][
        report 1
      ]
    ]
  ]
end


; Copyright 2019 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
205
10
850
656
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-24
24
-24
24
1
1
1
ticks
30.0

BUTTON
9
77
72
110
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
9
116
72
149
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

SLIDER
9
232
195
265
spawn-rate
spawn-rate
1
10
10.0
1
1
NIL
HORIZONTAL

PLOT
860
10
1280
384
Travel Time
Ticks
NIL
0.0
10.0
0.0
2.0
true
true
"" ""
PENS
"Actual Time" 1.0 1 -7500403 true "" "plot travel-time"
"Top" 1.0 0 -2674135 true "" "plot top"
"Bottom" 1.0 0 -14070903 true "" "plot bottom"
"Middle" 1.0 0 -13840069 true "" "plot middle"
"Smoothed Average" 1.0 2 -8990512 true "" "plot avg"

SWITCH
9
10
196
43
middle-on?
middle-on?
0
1
-1000

SLIDER
8
275
194
308
smoothing
smoothing
1
10
10.0
1
1
NIL
HORIZONTAL

CHOOSER
8
322
197
367
mode
mode
"Best Known /w Random Deviation" "Empirical Analytical" "Probabilistic Greedy"
2

SLIDER
9
380
198
413
randomness
randomness
0
100
16.0
1
1
NIL
HORIZONTAL

PLOT
860
392
1060
542
Routes Taken
NIL
Number of Cars
0.0
3.0
0.0
10.0
true
true
"" ""
PENS
"Top" 1.0 1 -2674135 true "" "clear-plot plotxy 0 count turtles with [route = 0]"
"Bottom" 1.0 1 -13345367 true "" "plotxy 1 count turtles with [route = 1]"
"Middle" 1.0 1 -13840069 true "" "plotxy 2 count turtles with [route = 2]"

PLOT
1081
392
1281
542
Probabilities
NIL
NIL
0.0
3.0
0.0
1.0
true
true
"" ""
PENS
"Top" 1.0 1 -2674135 true "" "clear-plot plotxy 0 top-prob"
"Bottom" 1.0 1 -13345367 true "" "plotxy 1 bottom-prob"
"Middle" 1.0 1 -13840069 true "" "plotxy 2 middle-prob"

@#$#@#$#@
## WHAT IS IT?

This is an agent-based model intended to demonstrate a phenomenon from game theory (a subfield of economics) called Braess' paradox. The paradoxical aspect of Braess' paradox arises when an additional route is added to a traffic network that allows for very rapid transit. When this is done the traffic pattern can be changed to one that has both worse individual and global outcomes (travel times.) In short, we can open more roads and actually make traffic worse. (Braess et al., 2005)

Braess' paradox is a counter-intuitive result that arises when analyzing specific graphs through a game theoretic lens. These graphs are usually taken to be representations of traffic networks, but Braess' paradox is actually a wide-ranging phenomenon that can be applied in many contexts outside of traffic networks. For simplicity however, we will interpret and represent these graphs only as traffic networks in this model. Given a graph of a particular traffic network we can determine a stable set of strategies (routes for commuting from one point to another) that agents (autonomous commuters in this case) will prefer to adopt over all other strategies. This is called a Nash equilibrium. The strategies adopted by the commuters in the Nash equilibrium will lead to outcomes for the commuters. In this case the amount of time it takes them to reach their destination.

## HOW IT WORKS

The commuters in this model come into existence at the starting node of the traffic network in the upper left corner. The commuters are represented graphically as a car or truck, but this is just for visual effect. All commuters adhere to the same behavioral rules. Some heuristic is used by the commuters to determine the path they will take through the network before it begins its journey through the traffic grid. The commuter then moves, one road square (patch) at a time, and remains in that patch for a number of ticks before moving on to the next patch. When the commuter reaches the ending node it reports the path it took through the network and also the total number of ticks it spent in transit. This information is saved by the model and used to generate a "traffic report" which new commuters can then incorporate into their heuristic to choose the route they take.

Certain patches in this model are selected to represent roads. There are two types of road patches: static-cost roads and dynamic-cost roads. Static-cost roads require the car to stay in that patch for a fixed amount of time before moving on. Dynamic-cost roads require the car to stay in that patch for an amount of time that is based on the number of ticks since the last turtle occupied that patch, thus simulating congestion. There is also a switch in the model which allows a middle path of road patches of near zero cost to be opened or closed. As mentioned above when commuters reach the end of the traffic network they report their route choice and the time taken in ticks.

There are three possible routes and the time reports are taken and used to determine three global variables corresponding to each route. They can be thought of as traffic reports. This information is then used by future commuters in deciding which route to take. How this information is used by the commuters depends on the active heuristic or algorithm.

In this model we have included a user adjustable parameter called SMOOTHING. If SMOOTHING is set to 1, only the last reported time for a given route will be used by commuters in their decisions. Otherwise the formula for the information that the commuters have access to is a psuedo-average that weights less recent reports lower. This parameter is added so that commuters can be made to take into account information about more than just the previous commuter to complete a given route when making their decisions about which route they would prefer to take. Adjusting the SMOOTHING parameter in the model can sometimes be useful in eradicating wild oscillations in commuter route preferences.

__*Heuristics*__

What follow are descriptions of the different modes by which commuters in the model will determine the route they take through the traffic network. These modes can be set before the model is started but they can also be changed during model execution.

* __Best Known with Random Deviation:__ When this mode is active the cars will choose the route with the lowest current average time or deviate to a random route with some probability defined by the value of the probability parameter in the model divided by one-hundred.

* __Empirical Analytical:__ In this mode the cars have knowledge of the current number of cars on the road and which routes they are taking. They use this information to analytically compute which route will be best for them to take, and then take that route.

* __Probabilistic Greedy:__ In this mode the commuters will choose routes with a probability that is proportional to the performance of the given route. Here the randomness parameter is used to determine how heavily the probability is distributed into the better routes. A randomness setting of zero will make no route more likely than any other regardless of the performance of the route. A randomness setting of one-hundred will make it overwhelmingly likely that the cars will only take the current best route.

## HOW TO USE IT

The SETUP button initializes the model.

The GO button runs the model.

The SPAWN-RATE slider determines how often new vehicles appear at the starting node. However, the road congestion is determined in proportion to the SPAWN-RATE -- so SPAWN-RATE will not affect travel time at all.

The MIDDLE_ON? switch determines whether or not cars can pass down the middle road. If the MIDDLE_ON? switch is turned off all vehicles currently taking the middle road will finish their trip before the middle road is disabled.

The MODE selection panel selects between the algorithms and heuristics described above for determining which route the vehicles choose.

The RANDOMNESS and SMOOTHING parameters affect different algorithms and heuristics differently. They way in which they do so is also described above.

The Top Route (red in the plots) starts at the top-left corner, goes to the top-right corner, and then procedes to its end at the bottom-right corner.

The Bottom Route (blue in the plots) starts at the top-left corner, goes to the bottom-left corner, and then goes to the bottom-right corner where it ends.

The Middle Route (when enabled; green in the plots) starts at the top-left corner and then goes to the top-right corner. Next, it takes the diagonal path to the bottom-left corner, and then goes to the bottom-right corner where it ends.

## THINGS TO NOTICE

The ROUTES TAKEN plot shows a histogram of which routes the currently active vehicles are taking. (Vehicles choose their route as soon as they come into existence.)

The PROBABILITIES plot shows a histogram of the probabilities with which new vehicles will choose a given route when a mode is selected that is probabilistic.

The main TRAVEL TIME plot displays a variety of different information. The filled grey area is the actual amount of time (in ticks) it takes an individual vehicle to travel from the starting node to the ending node. The light blue line is a smoothed average of the travel time of all the vehicles that have traveled the network with more recent vehicles weighted more strongly. The Blue, Red, and Green lines all represent the average travel time of all vehicles to have completed the corresponding routes. The average is affected by the SMOOTHING parameter which determines how strongly weighted more recent vehicles compared to less recent vehicles.

## THINGS TO TRY

Try adjusting the SMOOTHING parameter and notice how the stability of which route vehicles take varies.

To observe Braess' Paradox, try using different algorithms and heuristics and observe the average travel times when the middle route is closed and when the middle route is open.

## EXTENDING THE MODEL

New algorithms for determining which routes the vehicles take could easily be added to this model. Also the traffic network could be changed or extended to have a different topology. {give an example of one such new algorithm in a sentence}}

## NETLOGO FEATURES

To plot histograms of the different probabilities of routes being taken and the current routes that turtles are on, we use the __plotxy__ primitive because there is no way to naturally histogram across different vairables.

## RELATED MODELS

"Traffic Basic": a simple model of the movement of cars on a highway.

"Traffic Basic Utility": a version of "Traffic Basic" including a utility function for the cars.

"Traffic Basic Adaptive": a version of "Traffic Basic" where cars adapt their acceleration to try and maintain a smooth flow of traffic.

"Traffic Basic Adaptive Individuals": a version of "Traffic Basic Adaptive" where each car adapts individually, instead of all cars adapting in unison.

"Traffic 2 Lanes": a more sophisticated two-lane version of the "Traffic Basic" model.

"Traffic Intersection": a model of cars traveling through a single intersection.

"Traffic Grid Goal": a version of "Traffic Grid" where the cars have goals, namely to drive to and from work.

"Gridlock HubNet": a version of "Traffic Grid" where students control traffic lights in real-time.

"Gridlock Alternate HubNet": a version of "Gridlock HubNet" where students can enter NetLogo code to plot custom metrics.

## CREDITS AND REFERENCES

Braess, D., Nagurney, A., and Wakolbinger, T.(2005). On a paradox of traffic planning.
   _Transportation science, 39(4):446–450._

Fudenberg, D. and Tirole, J.(1991). Game theory, 1991.
   _Cambridge, Massachusetts, 393(12):80._

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rasmussen, L. and Wilensky, U. (2019).  NetLogo Braess Paradox model.  http://ccl.northwestern.edu/netlogo/models/BraessParadox.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2019 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2019 Cite: Rasmussen, L. -->
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
0
@#$#@#$#@
