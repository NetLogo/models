breed [ cutters cutter ]
breed [ stitchers stitcher ]
breed [ finishers finisher ]
breed [ storages storage ]
breed [ robots robot ]
breed [ robot-rooms robot-room ]
breed [ loading-docks loading-dock ]
breed [ orders order ]

turtles-own   [
  product             ; the finished product the turtle has
  supply              ; the amount of material used to create a product
  turtles-present     ; the total number of turtles here
]

finishers-own
[
  deluxe-level        ; whether an order is luxurious or standard, which effects processing time at the finishers.
  build-counter       ; finishers process orders in different times based on if it is a standard, or a luxurious order,
                      ;      build-counter keeps track of that build time as the finisher processes
  queued-supply       ; finishers do not instantly process supply, this store the supply that robots bring to a finisher for future processing.
  processing-order?   ; the finisher can receive luxurious or standard orders, this boolean keeps track of the current order type
]
robots-own
[
  energy              ; what robots use to drive with
  laden?              ; whether the robot is carrying anything
  destination         ; where the robot is current going
  idleness            ; a counter of time this robot has spend idle
  product-type        ; keeps track of the order type in a string
]

orders-own [
  type-of-order       ; an order can be standard or luxurious, this keeps track of that for each order created.
]


to setup ; imports the base image from the folder, sets up the color of the factory, adds the processing machines, and robots.

  clear-all

  import-drawing "Robotic Factory Base Image.png"

  ask patches [ set pcolor grey + 4 ]

  ; There are two each of cutters, stitchers and finishers
  create-cutters 1 [ setxy 10 -6  set color blue set shape "x" ]
  create-cutters 1 [ setxy 10 -11 set color blue set shape "x" ]

  create-stitchers 1 [ setxy 4 8 set color red set shape "box 2" ]
  create-stitchers 1 [ setxy 4 3 set color red set shape "box 2" ]

  create-finishers 1 [ setxy 0 -4 set color green set deluxe-level 1 set shape "circle" set processing-order? false ]
  create-finishers 1 [ setxy 2 -8 set color green set deluxe-level 2 set shape "circle" set processing-order? false ]

  create-storages 1 [ setxy -6 4 set shape "box" set color magenta]

  create-robot-rooms 1 [ setxy -11 -7 set shape "box" set color yellow ]

  create-loading-docks 1 [ setxy 13 4 set shape "box" set color black set supply 10 set shape "box 2"]

  create-robots number-of-robots  [ ; creates a variable number of robots and sets their values
    setxy random-xcor random-ycor
    set color grey
    set destination "none"
    set laden? false
    set energy full-charge
  ]
  ask robots [set destination one-of loading-docks] ; sends all the robots to the loading dock to start

  reset-ticks
end

to go ; the simulation loops that repeats forever

  make-garments
  set-robots-destination
  return-home
  recharge
  deliver-more-material-sheets
  shift-change
  label-agents

  ask turtles [
    set turtles-present count turtles-here
    ifelse make-trails? [ pen-down ] [ pen-up ]
  ]

  tick
end


to set-robots-destination ; sets the destination of robot based on its energy, laden? status and current location
  ask robots [ ; ask all the robots to implement the following
    (ifelse ; takes account of the type of breed of machine here to operate across several states.
      ; LOADING DOCKS
      [ breed ] of destination = loading-docks [ ; if the robot's destination is loading dock

        ifelse any? loading-docks-here [ ; Check if the robot has reached the loading doc  ;

          if [supply] of one-of loading-docks-here > 0 [; if there is a loading dock here with supply
            set product product + 1 ; increase the robots production
            set product-type "bolts" ; keep track of the type of product with a string
            set destination one-of cutters ; set the robots destination of the cutters
            ask one-of loading-docks-here [ if supply > 0 [set supply supply - 1] ] ] ; then ask the loading dock to reduce its supply by 1
        ]
        [ move ] ; otherwise, If the robot is not at its destination, it moves towards its destination.
      ]
      ; CUTTERS
      [ breed ] of destination = cutters [ ; if the destination of the robot is cutters
        ifelse any? cutters-here [ ; if the robot is at a cutter
          if product > 0 [ ; if it has some product
            set product 0 ;  drop off the product
            ask one-of cutters-here [set supply supply + 1]; and add to the cutters supply of material to process
            stop ; and leave the loop to come back next tick.
          ]
          ifelse [product] of one-of cutters-here > 0 [; if the machine has some products to pick up
            set product product + 1 ; add some product to the robot
            set product-type "cuttings" ; set the product type to cutting
            set destination one-of stitchers ; set the destination to one of the stitchers
            ask one-of cutters-here [ if supply > 0 [set supply supply - 1] ] ] ; decrement supply
          [ set destination one-of loading-docks ] ; otherwise, go back to the loading docks
        ]
        [ move ] ; otherwise, if the robot is not at its destination, it moves towards its destination.
      ]
      ; STITCHERS
      [ breed ] of destination = stitchers [ ; if the destination of the robot is stitchers
        ifelse any? stitchers-here [ ; If the robot is at a sticker
          if product > 0 [ ; we drop off some supply
            set product 0  ;  drop off the product
            ask one-of stitchers-here [set supply supply + 1] ;the supply goes to the stitcher
            stop ; and leave the loop to come back next tick.
          ]
          ifelse [product] of one-of stitchers-here > 0 [ ; if the stitcher has some product, get the robots to carry it to the correct finisher
            set product product + 1 ; increase the robots product
            if any? orders [ ;then check the lit of orders,
              let order-now one-of orders ; assign the order to one of the robots
              set product-type [type-of-order] of order-now ; the robot sets its product type to the type of order of one of the outstanding orders.
              ask order-now [die] ; we check that order off the list
            ]
            ifelse product-type = 0 [ ; if the product type is standard,
              set destination one-of finishers ; we take the supply to either of the finishers.
            ][ ; otherwise, we take the order specifically the the finisher that can handle deluxe orders.
              set destination one-of finishers with [deluxe-level = 2]
            ]
            ask one-of stitchers-here [ if supply > 0 [ set supply supply - 1 ] ] ] ; then the stitcher reduces supply
          [
            set destination one-of loading-docks ; if there isn't anything to carry the robot heads back to the loading doc.
          ]
        ]
        [ move ] ; otherwise, if the robot is not at its destination, it moves towards its destination.
      ]
      ; FINISHERS
      [ breed ] of destination = finishers [; if the destination is finisher
        ifelse any? finishers-here [ ; if the robot reaches a finisher
          if product > 0 [ ; drop off some product if the robot is carrying any
            set product 0
            ; increase the finishers supply. Importantly through the make-garments and finish functions
            ; the finishers take account of how long it takes them to process an order based on order type.
            ask one-of finishers-here [set supply supply + 1]
            stop
          ]
          ifelse [product] of one-of finishers-here > 0 [; When the finishers finish processing the order based on the finish function, and they have some supply
            set product product + 1 ; increase the robots product
            set product-type "finishing" ; set the product type to finishing
            set destination one-of storages ; and set the destination the storage room.
            ask one-of finishers-here [ finish ] ; the finisher then processes the order.
          ][
            set destination one-of loading-docks ; if not any product, head back to start.
          ]
        ]
        [ move ] ; otherwise, if the robot is not at its destination, it moves towards its destination.
      ]
      ; STORAGE
      [ breed ] of destination = storages [ ; if the robot is at the storage
        ifelse any? storages-here [ ; when it arrives
          if product > 0 [ ; dropoff what the robot is carrying
            set product 0
            ask one-of storages-here [set supply supply + 1] ; increase the storage
          ]
          set product-type "nothing" ; empty the robot
          set destination one-of loading-docks ; send it back to start.
        ]
        [ move ]
      ]
      ; ROBOT ROOM
      [ breed ] of destination = robot-rooms [ move ] ; if the destination of a robot is robot room, go to the robot room

      ; EXCEPTIONS
      [ breed ] of destination = "none" [ set destination one-of loading-docks ] ; if the destination is not set, go to the loading docks
      [ breed ] of destination = nobody [ set destination one-of robot-rooms   ] ; if the destination is empty, go to the charging station

      [ set destination one-of loading-docks ] ; if we don't have a destination, go back to the start.
    )
  ]
end


to return-home
  ; When their energy level becomes low, robots must return to a robot room to recharge.
  ask robots [ if energy < 2 [ set destination one-of robot-rooms ] ]
end

to recharge
  ; They recharge at a rate of 5 units per simulation cycle.
  let choice 0

  ask robot-rooms [
    ask robots in-radius 2 [
      set laden? false
      set product 0
      set product-type 0
      set energy energy + 5
      set idleness idleness + 1

      if energy >= full-charge [
        set choice one-of [1 2 ]
        ifelse choice = 1 [
          set destination (one-of turtles with [turtles-present = robot-supply-need ])
        ][
          set destination (one-of loading-docks)
        ]
      ]
    ]
    if sum [supply] of loading-docks > 0 [ ; if robots are needed for immediate tasks, interrupt some charging and send a robot.
      if any? robots-here [
        ask one-of robots-here [
          ; note: this could be changed to a different heuristic, like selecting the robot
          ; with the most energy.
          if energy > just-in-time-supply-robot [ set destination one-of loading-docks ]
        ]
      ]
    ]
  ]
end

to make-garments ; Machines process supply into product at a rate of 1 per tick.
  ask cutters   [
    if supply > 0 [
      set product product + 1
      set supply supply - 1
    ]
  ]
  ask stitchers [
    if supply > 0 [
      set product product + 1
      set supply supply - 1
    ]
  ]
  ; There are two qualities of goods in the model, luxurious and standard. This only impacts the finishers.
  ; These are processed at a rate of once for 7 ticks and once per 4 ticks, respectively.
  finish
end


; there is external supply of new materials. In this model we simplify this, and every so often add a random additional supply to the loading dock
to controller-sends-garments
  ask loading-docks [ set supply supply + random 10 ]
end

to deliver-more-material-sheets ; 3% of the time, when the supply at the loading dock gets low, add some more supply to the loading dock.
  if random 100 < 3 [ if sum [supply] of loading-docks < 3 [ controller-sends-garments ] ]

  ask loading-docks [
    if random 100 < 3 [ ; additionally, orders come in 3% of the time that can be luxurious, or standard.
      hatch-orders random 3 [
        set type-of-order random 2
        set size 1 set shape "box"
      ]
    ]
  ]
end

; Robots move toward their destination set by the set-robots-destination procedure
to move
  if can-move? 1 [forward 1 face destination]
  ifelse product > 0 [ ; if the are carrying something, robots lose two energy
    set laden? true
    set energy energy - 2
  ]
  [
    set laden? false ; otherwise, if they are not carrying something they lose 1 energy,
    set energy energy - 1
    set idleness idleness + 1 ; and increase their idleness score by 1 each tick.
  ]
end




to finish ; the two finishers can hand either luxurious or standard orders. The one that does higher end orders, takes 7 ticks to process supply. The other one takes 4.
  ask finishers [
    if supply > 0 [
      set queued-supply queued-supply + 1 ; the finishers stores supply as its delivered for future processing.
      set supply supply - 1
    ]
    if queued-supply > 1 and not processing-order? and build-counter = 0 [
      ifelse deluxe-level = 1 [ set build-counter 4 ] [ set build-counter 7 ]
    ]
    if build-counter > 0 [
      set processing-order? true
      set build-counter build-counter - 1
    ]
    if build-counter = 0 and processing-order? [
      set product product + 1
      set processing-order? false
      set queued-supply queued-supply - 1
    ]
  ]
end

to shift-change ; occasionally, move robots back to the loading dock to initiate a new shift.
  if random 100 < 2 [ ask n-of 3 robots [ set destination one-of loading-docks ] ]
end

to label-agents ; places tbhe labels on the agents if switched on
  ifelse show-agent-name? [
    ask turtles [ set label (word breed " "  who) set label-color black ]
  ]
  [ ask turtles [ set label "" ] ]

end

to-report robot-supply-need
  let return nobody
  set return min [ turtles-present ] of turtles with [breed != robots]
  report return
end


; Copyright 2021 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1010
811
-1
-1
24.0
1
10
1
1
1
0
0
0
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
30
10
95
43
setup
setup\nsetup
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
100
10
163
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

MONITOR
20
105
175
150
Products Ready for Van
sum [ supply ] of storages
17
1
11

SLIDER
5
215
205
248
full-charge
full-charge
0
1000
350.0
1
1
energy
HORIZONTAL

PLOT
1026
12
1226
162
Percentage Time Robots Idle
Time
Percentage of Time
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [ \n  plot (sum [ idleness ] of robots ) / ticks\n]"

SWITCH
5
335
205
368
make-trails?
make-trails?
0
1
-1000

MONITOR
20
55
175
100
New Sheets
sum [ supply ] of loading-docks
17
1
11

PLOT
1026
168
1226
318
Robots' Energy
Time
Percent of Robots
0.0
600.0
0.0
4.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ energy ] of robots"

SLIDER
5
250
205
283
just-in-time-supply-robot
just-in-time-supply-robot
0
300
150.0
1
1
NIL
HORIZONTAL

SWITCH
5
295
205
328
show-agent-name?
show-agent-name?
0
1
-1000

PLOT
1026
322
1319
472
Supply of Machines
Time
Supply
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Finishers" 1.0 0 -16777216 true "" "plot sum [ supply ] of finishers"
"Cutters" 1.0 0 -7500403 true "" "plot sum [ supply ] of cutters"
"Stitchers" 1.0 0 -2674135 true "" "plot sum [ supply ] of stitchers"
"Loading Docks" 1.0 0 -955883 true "" "plot sum [ supply ] of loading-docks"

PLOT
1230
12
1572
163
Outstanding Orders
Time
Orders
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total Orders" 1.0 0 -16777216 true "" "plot count orders"
"Deluxe Orders" 1.0 0 -7500403 true "" "plot count orders with [ type-of-order = 1 ]"
"Standard Orders" 1.0 0 -2674135 true "" "plot count orders with [ type-of-order = 0 ]"

SLIDER
5
180
205
213
number-of-robots
number-of-robots
3
20
5.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model demonstrates a resilient robot factory that runs autonomously, based on the principles of self-organization so prevalent in nature. In the model, a garment factory is completely automated but attached to an unpredictable external world (suppliers). The robots carry products from one machine to the next, and then out to the van to be whisked away. Nature has long experience with persisting in an interconnected world. If only humans could self organize as efficiently and resiliently as bees or ants do. We need more resilient human systems that borrow from nature, such as this model.

### The Factory, an Emergent or Sequential Process?

In order to reimagine resilient human systems, we need to redesign many systems from sequential systems, prevalent in the industrial age, to emergent processes, which are so prevalent in nature. For Chi et al. (2012) processes, can be categorized in two ways – sequential or emergent. Sequential processes can be subdivided into a sequence of events, like an assembly line where the metal is rolled, pressed, stamped, and smoothed before being turned into cans and filled with tomato sauce. This is a process with multiple agents: the machines, their operators, and a manager. It makes sense to speak of sequential processes resulting from a single agent’s actions. For example, we could say the manager increased efficiency of the assembly process by increasing the speed of the conveyor belt. Even though all the agents participated in the process, we can focus on the goal setting manager’s actions to account for the change. As a result, Chi et al. say one can give special controlling status to the agent that caused the change in a sequential process. This means if someone thinks of a process as sequential, they tend to interpret interactions at the agent level as done in order to reach the goal of the higher level (See Wilensky & Resnick, 1999). For the assembly line, this can make sense. The causal mechanism that leads to the result comes from the summing of the assembly line’s outcomes directed by the manager. But, for emergent systems, such as ant colonies, this can lead to false assumptions (like that the queen ant gives direction to all the other ants). Many people confuse this control when thinking about emergent processes, what Wilensky & Resnick call Levels Confusion.

Emergent processes, like ants searching for food, marching in orderly paths, or getting stuck in a doorway are different. These processes result from each ant taking actions, some of them random, where the result emerges from the repetition of the action, but no agent is in control. These processes are encountered in school standards such as osmosis and diffusion, electrical current and buoyancy.

This model configures a factory to be an emergent, as opposed to a sequential process, providing a novel design of a factory floor. This model is emergent because instead of operating on the processes of the factory, we set key properties that establish the emergent pattern of the model: the energy cycle. In other words, the efficiencies result from operating on the emergent, instead of operational, parameters. This is an example of humans designing an emergent system to meet business needs.

## HOW IT WORKS

The model initializes with 2 cutters, 2 stitchers, 2 finishers (one lux, one standard), a storage room, and a loading dock and places them in the correct place in the factory. Finally, it creates some robots, initializes all of these with starting parameters, and then all the robots are sent to the loading dock.

Every tick, machines process various garments by moving them through the factory. If the robots are carrying garments, then they spend more energy to move. There are two quality levels of garment "luxurious" and "standard". Each order is either "luxurious" or "standard". Both finishers can produce ‘standard’ garments but only Finisher 1 can produce the "luxurious" version. Finisher 1 takes 7 simulation cycles to complete the garment, whilst Finisher 2 takes 4 cycles. This creates a manufacturing bottleneck that induces the need for more resistant robot behavior.

We ask the robots to check their destination against a list of options. They then move towards their destination. When they arrive they drop off supply to that machine. If the machine where the robot arrives has some product (it processes some supply), we pick it up and set our destination to the next machine.

The robots return to the robot room when they run low on power. There, they recharge at a rate of 5 units per tick.

Every so often, a new order comes in which sends materials to the loading dock, either lux, or standard. This creates a supply side bottleneck in the manufacturing. Occasionally there is a shift change. With a 3% probability (a random percentage), if the loading dock is low on supplies, we add between 1 and 10 new supplies. We also create orders on 3% of ticks. This is used for routing orders to the Finishers.

## HOW TO USE IT

Press SETUP and then GO. Examine the graphs, and watch the robots move through the factory.

The MAKE-TRAILS? switch asks Robots to trace their routes on the ground so we can inspect how they travel.

SHOW-AGENT-NAME? shows names of the different agents in the View.

The NUMBER-OF-ROBOTS slider sets how many robots are in the factory at the start.

The FULL-CHARGE slider sets what a full battery is in the model. The higher the value the longer robots go between charges, but also, the longer it takes them to charge up.

Sometimes, to keep a factory moving, a robot needs to go just when needed, even if not fully charged. The JUST-IN-TIME-ROBOT-SUPPLY sets the amount of energy a robot needs to have at the charging station to be selected to meet critical factory needs. The lower it is, the more robots will be available to meet the needs, but they also won't last very long due to their low charge. Tweak this to balance the factory.

## THINGS TO NOTICE

Even though the robots move to semi-random locations after charging, and there is no central controller tracking all the robots locations/allocating orders, the robots do a good job of moving the process through the system with internal bottlenecks.

Note how the external factor of the delivery of new material can slow or stop production.

Also notice the percent of time idle. Note when this goes up or down across various bottlenecks or model parameters.

## THINGS TO TRY

Does increasing the number of robots increase or decrease idleness?

Can you think of a way to reduce idleness in the factory?

Try changing the JUST-IN-TIME-ROBOT-SUPPLY slider up and down. How does it impact the idleness graph?

Try setting the FULL-CHARGE to the max. How does it impact the idleness graph?

## EXTENDING THE MODEL

Does reorganizing the machines change idleness? How else could you improve efficiency? Improve resilience? What happens if one of the machines occasionally breaks? For instance:

Implement shifts, so that robots recharge at two different times.

Make delivery of new sheets more random, to simulate extreme supply shortages.

Right now there is a production bottleneck at the finishers. Add additional bottlenecks in the machine processing.

Right now, robots have to go back to the charging room to recharge. Try adding recharging robots that can bring the charge to the worker robots.

The machines are in a particular arrangement, optimize for idleness or productivity by rearranging the machines.

Currently, robots can always make it back to the robot room to recharge, because they can go into negative energy. This may not be the most realistic model. Change the model so that robots can get stranded if they do not leave for the robot room in time by editing the return-home function.

Python: right now, the robots don't learn, which makes them like a conveyor belt. Using the python extension, implement some learning into the model.

## NETLOGO FEATURES

The variadic ifelse statement is used to implement the state machine (variadic means it can take a variable number of arguments, in this case, multiple conditionals). This makes the model a good demonstration of the procedure.

## RELATED MODELS

This model builds on Ant Adaptation (Martin & Wilensky, 2019), which is based on Hölldobler and Wilson's The Ants (1990).

## CREDITS AND REFERENCES

Hölldobler, B., & Wilson, E. O. (1990). The Ants. Belknap (Harvard University Press), Cambridge, MA.

Chi, M. T. H., Roscoe, R. D., Slotta, J. D., Roy, M., & Chase, C. C. (2012). Misconceived causal explanations for emergent processes. Cognitive Science, 36(1), 1-61. doi:doi:10.1111/j.1551-6709.2011.01207


Wilensky , U., & Resnick, M. (1999). Thinking in levels: A dynamic systems approach to making sense of the world. Journal of Science Education and Technology, 8(1), 3-19.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Martin, K. and Wilensky, U. (2021).  NetLogo Robotic Factory model.  http://ccl.northwestern.edu/netlogo/models/RoboticFactory.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2021 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2021 Cite: Martin, K. -->
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

box 2
false
0
Polygon -7500403 true true 150 285 270 225 270 90 150 150
Polygon -13791810 true false 150 150 30 90 150 30 270 90
Polygon -13345367 true false 30 90 30 225 150 285 150 150

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
1
@#$#@#$#@
