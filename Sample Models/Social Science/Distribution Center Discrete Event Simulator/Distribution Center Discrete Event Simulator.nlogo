__includes ["time-series.nls"]
extensions [ time csv ]

globals [
  ; Model parameters
  num-initial-employees  ; Number of employees
  sim-start-time         ; Logotime variable for date and time at which simulation starts
  sim-end-time           ; Logotime variable for date and time at which simulation ends
  walking-speed          ; The speed at which workers walk when picking orders, in patches/second
  order-fill-time        ; The time it takes, in addition to walking to bin and back, to fill an order, in minutes

  ; Display
  order-desk     ; Cell where orders are picked up
  bins           ; Agentset of bins containing stock

  ; Reporting
  performance-log        ; Record of all actions by all employees
  num-added              ; Cumulative number of workers added to shifts
  num-removed            ; Cumulative number of workers removed from shifts

  ; Global model variables
  sim-time             ; A Logotime variable for the current simulation time
  num-orders-to-fill   ; The number of orders waiting to be filled
  shift-waiting-time   ; Number of worker-minutes spent waiting, per shift
  last-log-clear-time  ; The date and time when the worker performance log was last cleared

]

turtles-own [
  shift         ; Equal to "day" (8 am to 4 pm), "swing" (4 pm to midnight), or "night" ( midnight to 8 am)
  quitting-time ; The time after which the worker can quit work, 8 hours after starting
  activity      ; Equal to "picking" (filling an order), "waiting" (waiting when no orders are in the queue), or "off" when not working
]

to setup

  ; Clear
  clear-all
  reset-ticks

  ; Initialize variables
  ; Model parameters
  set num-initial-employees  20  ; Number of employees
  set sim-start-time time:create "2020-05-01 08:00"  ; Date and time at which simulation starts. Time must be 8 am
  set sim-end-time   time:create "2020-05-31 08:00"  ; Date and time at which simulation ends
  set walking-speed   0.5       ; The speed at which workers walk when picking orders, in patches/second
  set order-fill-time 1.0       ; The time it takes, in addition to walking to bin and back, to fill an order, in minutes

  ; Global variables -- do not change
  set num-orders-to-fill 0  ; The number of orders waiting to be filled
  set shift-waiting-time  0   ; Number of worker-minutes spent waiting, per shift
  set num-added  0            ; Cumulative number of workers added to shifts
  set num-removed  0          ; Cumulative number of workers removed from shifts

  ; Display
  set order-desk patch min-pxcor 0    ; Cell where orders are picked up
  ask order-desk [ set pcolor red ]
  set bins  patches with [pxcor = max-pxcor]         ; Agentset of bins containing stock
  ask bins [ set pcolor one-of base-colors]

  ; Reporting
  set performance-log ts-create ["Shift" "Employee" "Event" "Duration (min)"] ; Record of all actions by all employees

  ; Set up time variables
  ; Makes each tick equal to 1 minute
  time:anchor-schedule sim-start-time 1 "minute"
  ; Make sim-time always equal to time value of ticks
  set sim-time time:anchor-to-ticks sim-start-time 1 "minute"

  ; Set last log clear time to model start time
  set last-log-clear-time time:copy sim-time

  ; Create employees
  create-turtles num-initial-employees [
    hide-turtle
  ]

  ; Assign employees to shifts, and schedule the start and end of their first shift
  ask n-of (num-initial-employees / 3) turtles [
    set shift "day"
    set color yellow
    ; Start work at beginning of simulation
    time:schedule-event self [ -> go-to-work ] sim-start-time
    set quitting-time time:plus sim-start-time 8 "hours"
  ]
  ask n-of (num-initial-employees / 3) (turtles with [shift != "day"]) [
    set shift "swing"
    set color orange
    ; Start work 8 hours after simulation starts
    time:schedule-event self [ -> go-to-work ] time:plus sim-start-time 8 "hours"
    set quitting-time time:plus sim-start-time 16 "hours"
  ]

  ask turtles with [shift != "day" and shift != "swing"] [
    set shift "night"
    set color blue
    ; Start work 16 hours after simulation starts
    time:schedule-event self [ -> go-to-work ] time:plus sim-start-time 16 "hours"
    set quitting-time time:plus sim-start-time 24 "hours"
  ]

  ; Initialize first actions: create the first order
  receive-an-order

end

to go
  ; The model schedule for events happening on one-minute ticks

  ; Advance the tick to the next whole minute and execute events scheduled up to that time
  tick
  time:go-until ticks  ; This will run the discrete-event scheduler for one minute (from last tick until the current tick count, which is ticks)

  ; Do end-of-shift updates if it is time to
  if time:show sim-time "H:mm" = "8:00"  [ end-shift "night" ]
  if time:show sim-time "H:mm" = "16:00" [ end-shift "day" ]
  if time:show sim-time "H:mm" = "0:00"  [ end-shift "swing" ]

  ; Determine if it is time to stop the simulation
  if not time:is-before? sim-time sim-end-time [
    print "End of simulation"
    stop
  ]

  ; Clear the performance log once per month
  if (time:difference-between last-log-clear-time sim-time "months") > 0 [
    ; This statement erases the old log and creates column headers for a new one
    set performance-log ts-create ["Shift" "Employee" "Event" "Duration (min)"]
    set last-log-clear-time time:copy sim-time
  ]

end

to go-to-work
  ; Turtle procedure that activates worker and determines the end of its working day
  ; The worker calculates its new quitting time (when the new shift is over in 8 hrs),
  ; makes itself visible, and checks the order queue

  set quitting-time time:plus sim-time 8 "hours"
  show-turtle
  pick-an-order

end

to quit-work
  ; Turtle procedure that de-activates worker and determines when it next goes to work
  ; Workers must start 16 hours after their scheduled quitting time

  hide-turtle
  set activity "off"
  time:schedule-event self [  -> go-to-work ] time:plus quitting-time 16 "hours"

end

to receive-an-order
  ; Observer procedure that adds a new order to the order queue and schedules the next order

  set num-orders-to-fill num-orders-to-fill + 1

  ; Calculate time until next order is received (minutes)
  ; This interval is often modeled via the exponential distribution
  ; Convert the random time in seconds to minutes (equivalent to ticks)
  let time-to-next-order (random-exponential mean-order-interval) / 60

  ; Schedule the next order
  time:schedule-event "observer" [ -> receive-an-order ] ticks + time-to-next-order
  ; The following commented-out statement *should* be equivalent to the above statement
  ; but occasionally causes an error (trying to schedule an event at a time before the current time)
  ; that is apparently due to floating point precision
  ;  time:schedule-event "observer" [ -> receive-an-order ] time:plus sim-time time-to-next-order "minutes"

end

to pick-an-order
  ; A turtle procedure to start handling a new order

  ; Start by checking whether the shift is over and worker can quit for the day
  ifelse time:is-after? sim-time quitting-time
  [ ; Shift is over so quit
    set performance-log ts-add-row performance-log (list sim-time shift who "quit for day" (16 * 60))
    quit-work
  ]
  [ ; It is not time to quit so keep working

    ; Check order queue to see if there are more to fill
    ifelse num-orders-to-fill <= 0
    [ ; Order queue is empty so schedule another check in 1 minute
      set activity "waiting"
      move-to order-desk
      set performance-log ts-add-row performance-log (list sim-time shift who "wait" 1)
      set shift-waiting-time shift-waiting-time + 1
      time:schedule-event self [ -> pick-an-order ] (time:plus sim-time 1 "minute")
    ]
    [ ; There are orders to fill so "pick" (fill) the next one
      set activity "picking"
      set num-orders-to-fill num-orders-to-fill - 1

      ; Determine which bin to pick the order from and the time it will take to fill the order
      let order-bin one-of bins
      move-to order-bin
      let this-picking-time order-fill-time + ((2 * (distance order-desk) / walking-speed) / 60) ; in *minutes*
      set performance-log ts-add-row performance-log (list sim-time shift who "pick an order" this-picking-time)

      ; Determine when worker is ready to pick next order and schedule it
      time:schedule-event self [ -> pick-an-order ] (time:plus sim-time this-picking-time "minutes")
    ]
  ]

end

to end-shift [a-shift]
  ; Observer procedure to do updates at end of a shift

  print (word (time:show sim-time "M/d/yyyy H:mm:ss") "  End of " a-shift " shift")

  ; Add a new worker to the shift if the shift did not keep up with the orders
  ; The new worker still start when the shift resumes in 16 hours
  if num-orders-to-fill > backlog-tolerance [
    set num-added num-added + 1
    create-turtles 1 [
      set shift a-shift
      set activity "off"
      hide-turtle
      time:schedule-event self [ -> go-to-work ] time:plus sim-time 16 "hours"
      (ifelse a-shift = "day"   [ set color yellow ]
              a-shift = "swing" [ set color orange ]
                                [ set color blue   ])
    ]
  ]

  ; Reduce shift by one worker if too much time was spend waiting for orders: if the fraction
  ; of worker-minutes spent waiting exceeds waiting-tolerance
  let workers-this-shift turtles with [shift = a-shift]
  let total-worker-minutes-this-shift ((count workers-this-shift) * 8 * 60)
  if (shift-waiting-time / total-worker-minutes-this-shift) > waiting-tolerance [
    set num-removed num-removed + 1
    ask one-of workers-this-shift [ die ]
  ]

  ; Zero the waiting time counter
  set shift-waiting-time 0.0

end


to file-save-worker-performance
  ; Observer procedure that writes the worker performance log to an output file
  ; The file is overwritten. This procedure is executed by a button on the interface.

  ts-write performance-log "WorkerPerformanceLog.csv"

end


; Copyright 2022 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
582
10
780
1273
-1
-1
38.0
1
10
1
1
1
0
0
0
1
-2
2
-16
16
0
0
1
ticks
30.0

BUTTON
5
10
68
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
208
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

SLIDER
5
50
215
83
mean-order-interval
mean-order-interval
5
60
30.0
5
1
seconds
HORIZONTAL

PLOT
245
65
523
236
Orders waiting
Minutes
Orders
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot num-orders-to-fill"

BUTTON
75
10
138
43
step
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
244
247
574
472
Worker status
Minutes
Number of workers
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Picking" 1.0 0 -13345367 true "" "plot count turtles with [activity = \"picking\"]"
"Waiting" 1.0 0 -13840069 true "" "plot count turtles with [activity = \"waiting\"]"

MONITOR
5
205
115
250
Workers added
num-added
0
1
11

MONITOR
120
205
231
250
Workers removed
num-removed
0
1
11

SLIDER
5
90
215
123
waiting-tolerance
waiting-tolerance
0
.5
0.2
.01
1
NIL
HORIZONTAL

SLIDER
5
130
215
163
backlog-tolerance
backlog-tolerance
0
200
50.0
10
1
NIL
HORIZONTAL

BUTTON
0
260
209
293
Save worker performance to file
file-save-worker-performance
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
305
10
480
59
Current simulation time
time:show sim-time \"M/d/yyyy H:mm:ss\"
17
1
12

@#$#@#$#@
## WHAT IS IT?

This model illustrates how to use the time extension for three of its purposes:

  * Representing simulated time as actual dates and times, and making time calculations such as determining the difference in time between two date-time variables;
  * Discrete event simulation: scheduling model actions (specific agents executing specific procedures) at future times that are not integer ticks; and
  * Logging events and the time they occurred to a file.

The model represents an internet retailer's distribution center, which receives and fills orders from customers. It is similar to classic discrete event simulation examples such as bank queue models.

Discrete event simulation is an alternative to NetLogo's normal "time step" scheduling method. Instead of assuming all model events happen once per tick, the time extension lets us schedule each event at its own unique time that is not necessarily on an integer tick. Discrete event simulation has the advantages of (a) not requiring all events to occur concurrently at ticks, but instead letting us represent the exact order in which individual events occur; and (b) often executing much faster because agents execute only when they need to, not each tick.

## HOW IT WORKS

The distribution center initially has 20 workers that are evenly divided among three shifts per day: day (8 am to 4 pm), swing (4 pm to midnight), and night (midnight to 8 am). At the start of each shift, its workers start work and schedule themselves to quit 8 hours later. When their quitting time arrives, they finish the order they are working on, stop work, and schedule their return to work the next day.

Orders from customers arrive at random intervals, with the mean time between arrivals set by the slider `mean-order-interval`. Each order increments the global variable representing the queue of orders waiting to be filled and shipped. Like many discrete event simulators, this model uses the random exponential distribution to represent the time between order arrivals.

Each worker starts their shift by checking whether the order queue is empty. If so, the worker schedules itself to check the queue again in one minute. If the queue is not empty, the worker "picks" the order. Each order must be picked from a bin of products; bins are chosen randomly. The time required to pick each order is equal to a constant processing time (global variable `order-fill-time`) plus the time required to walk from the order desk to the bin and back. The worker schedules itself to check the queue again when done picking the order.

At the end of each shift, the model represents how a shift manager could add or remove workers from the shift, depending on how well the shift performed. If the number of orders in the queue at the end of the shift exceeds a tolerance level set by the slider `backlog-tolerance`, then one more worker is added to the shift. That new worker starts when the same shift begins work the next day. If, instead, the fraction of time workers spent waiting for orders instead of picking them exceeds the value of the slider `waiting-tolerance`, one of the shift's workers is removed from the shift.

The management of course tracks all the workers continually. The button `Save worker performance to file` writes the worker tracking data to a file that users can analyze.

Each tick is one minute, but most events do not happen exactly at a tick. (The time extension has a precision of one millisecond, so events can be as little as 1/1000th of a second apart from each other.)

## HOW TO USE IT

Use SETUP to initialize the model, and GO to start it. Hitting GO again will pause the simulation at the end of the current minute. The STEP button executes one tick (minute) at a time.

The View shows the order desk (where orders are received) as a red patch on the left, and the bins of products as the colored bins on the right.

To slow execution down enough to see what happens from minute to minute, change "View updates" on the Interface from "continuous" to "on ticks". (The model can execute many ticks between the "continuous" view updates.)

The plots show the number of orders in the queue, and the number of workers that are picking orders and waiting for orders.

The SAVE WORKER PERFORMANCE TO FILE button writes a file (`WorkerPerformanceLog.csv`) containing the log of worker activity: the time at which each worker starts an activity (waiting, picking an order, quitting for the day) and the duration of that activity. The button can be used at any time and overwrites the file. (Remember that this log is cleared and re-started at the beginning of each month.)

The monitors WORKERS ADDED and WORKERS REMOVED report the total number of workers added and removed from shifts during the simulation. The monitor CURRENT SIMULATION TIME reports the date and time of the action being executed at the moment the monitor was updated.

By default the model runs from 1 May to 31 May 2020. These dates can be changed by editing the values of `sim-start-date` and `sim-end-date` in the `setup` procedure.

## THINGS TO NOTICE

Can you explain the very short spikes (they just look like vertical blue lines) in the "Worker Status" plot of how many workers are picking orders? (Hint: look at how workers decide when they can can quit at the end of a shift, in the procedure `pick-an-order`.)

Can you explain why there are cycles in the number of orders waiting to be picked? (Hint: look at the rules for how shift managers respond to worker performance--the order queue size and time spent waiting.)

Notice that the model executes very rapidly, because workers only execute their actions (procedures `pick-an-order`, `quit-work`, and `go-to-work`) when each individual is scheduled, instead of every turtle checking what to do every tick. Execution speed appears to be limited by the time used to show the current date and time in the Command Center (showing the time every tick instead of every hour slows the model dramatically), logging worker activity (if the code did not clear the log periodically, execution would become extremely slow), and updating the interface.

The execution speed benefit of discrete event simulation can be explored by considering the alternative of using NetLogo's standard tick-based (time step) simulation. A time step approach could coarsely approximate this model by using ticks that represent 10 seconds. With the standard parameter and slider values, there are an average of 10.4 workers over the one-month simulation. A time step model would therefore have to ask an average of 10.4 turtles to update on each of 267,840 ticks, for a total of 2,790,720 turtle updates. The discrete event simulation executes only 111,450 turtle updates (the number of lines in the worker performance log file).

## THINGS TO TRY

Vary the slider `mean-order-interval` (the average time, in seconds, between the arrival of new orders) and see how the number and activity of workers changes.

(For these explorations, you might want longer simulations. In `setup`, you can change `sim-end-time` from `"2020-05-31 08:00"` to (for example) `"2022-04-30 08:00"`.

Vary the two sliders that control management decisions about adding or removing workers (`waiting-tolerance` and `backlog-tolerance`) and try to reduce the rate at which the number of workers changes. Can you find values of these parameters that keep the number of workers steady and keep the number of orders waiting from cycling? (Consider running a BehaviorSpace experiment.) Do you think management would be happy with your solution?

Try changing ticks from representing one minute to one hour. This requires only (a) simple changes to the two time anchoring statements in `setup`, and (b) changing the conversion from seconds to ticks in one statement in `receive-an-order`. One-hour ticks have no effect on the simulation (events happen at fractions of an hour instead of fractions of a minute) but make the model execute even faster by reducing the number of ticks and outputs to the Command Center; but the plots are updated only hourly instead of each minute.

## EXTENDING THE MODEL

Users should be able to add many complexities of a real distribution center, such as variation in the time needed to fill orders. New details of how orders are filled can be added simply by having workers, when they finish one action, schedule the next one they do. For example, output on how much time is spent walking vs. packing orders could be obtained by scheduling separate events for walking to bins, packing the order, and walking back to the order desk.

The most interesting and important part of the model to extend and improve is how managers decide when to add and remove employees. Can they do a better job by looking back further and thinking ahead more, instead of only looking at what happened during the most recent shift? Or by moving more than one worker at a time?

The model's assumption that orders arrive at the same average rate around the clock is probably unrealistic. Can you think of a way to make the arrival rate change with the time of day (and, perhaps, day of the week)? The time extension's `show` primitive can report the current hour, or day of the week. How would adding daily cycles in the order arrival rate affect the best way to model how shift managers' decide to add or remove workers?

## NETLOGO FEATURES

Time extension features illustrated in this model are:

  * Using real dates and times to determine when a simulation starts and stops, and to represent the current simulation time: global variables `sim-start-time`, `sim-end-time`, and `sim-time`; `setup` procedure at lines 45, 46, and 69; `go` procedure at line 127.

  * Converting the time extension's "LogoTime" variable type (which represents a date and time) into text: Lines 122-124, 223.

  * Using primitives such as `difference-between` `is-before?`, and `is-after?` to make calculations and decisions based on times: Lines 127, 134, 187.

  * Setting ticks so each tick represents one specific unit of time (here, minutes, but the time extension supports units from milliseconds to years): `setup` procedure line 67.

  * Scheduling actions: telling specific agents or agentsets to execute specific procedures at a specific future time: the `time:schedule-event` statements throughout the code.

  * In the `go` procedure, combining traditional NetLogo ticks with discrete events executed at times between ticks. At lines 115-116, the `tick` statement advances the simulation clock to the next whole minute, and the `time:go-until` statement executes all discrete events scheduled between the previous tick and the new one.

  * Using the time-series input and output primitives associated with the time extension to write a log of events and the times they occurred: Global variable `performance-log` and lines 63, 189, 199, 211, 275.

## RELATED MODELS

The Discrete Event Mousetrap model (in the NetLogo Models Library > Code Examples > Extension Examples > time) also demonstrates use of the time extension for discrete event simulation. That model differs from this one in not using ticks at all: it has no `go` procedure; instead, *all* events in the Mousetrap model are scheduled ("triggered") by other events. It illustrates how to set up and start such a model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Railsback, S. and Wilensky, U. (2022).  NetLogo Distribution Center Discrete Event Simulator model.  http://ccl.northwestern.edu/netlogo/models/DistributionCenterDiscreteEventSimulator.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2022 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2022 Cite: Railsback, S. -->
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
NetLogo 6.4.0
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
