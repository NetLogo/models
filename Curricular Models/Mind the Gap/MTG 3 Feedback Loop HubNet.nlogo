globals [
  gini-index-reserve  ; a place to store part of gini index calculation
  lorenz-points       ; a list that stores some points to plot the Lorenz Curve
]

breed [ students student ]

patches-own [
  psugar           ; the amount of sugar on this patch
  max-psugar       ; the maximum amount of sugar that can be on this patch
  true-color       ; since all the patches will appear to be grey when hiding the world, they need a variable to store their true color
]

students-own [
 user-id    ; students choose a user name when they log in whenever you receive a
            ; message from the student associated with this turtle hubnet-message-source
            ; will contain the user-id
  sugar           ; the amount of sugar this turtle has
  metabolism      ; the amount of sugar that each turtles loses each tick
  vision          ; the distance that this turtle can see in the horizontal and vertical directions
  vision-points   ; the points that this turtle can see in relative to it's current position (based on vision)
  next-task  ; the next task a turtle will run. Can be either harvest, invest, go-to-school, or chill.
  state      ; the current state a turtle is in. Used to switch between tasks. Can be either harvesting, investing, schooling, or chilling.
  my-timer   ; a countdown timer to disable movements when in a certain state, such as at school
  has-moved? ; a marker for constraining students' clicks to one click per tick. Rapid multiple clicks from one
             ; student can slow the model by keep only processing the incoming HubNet messages

  education-level      ; starts with 0 and increases by 1 after going to school each time.
  earning-coefficient  ; starts by 1 and increases by 1.3 times after going to school each
                       ; time (based on real world data of earning and education level)
]

;;;;;;;;; Setup Procedures ;;;;;;;;

to startup
  hubnet-reset          ; automatically initialize hubnet architecture upon starting the model
end

to setup
  ; clear patches and plots, instead of clear all, to preserve students' connections to the server
  clear-patches
  clear-all-plots

  setup-patches

   ask patches [
      patch-growback
      patch-recolor
    ]

  ; detect any user actions (if any student has joined, left, or clicked buttons)
  listen-clients

  ask students [
    refresh-student

    set sugar random-in-range 5 25
    set earning-coefficient 1
    set education-level 0

    hubnet-send user-id "edu-level" education-level
    hubnet-send user-id "earning-coeff" earning-coefficient
    hubnet-send user-id "message" "Welcome to SugarScape!"
  ]

  ; avoids division by 0 problem
  if sum [sugar] of students > 0 [update-lorenz-and-gini]
  reset-ticks
end

to setup-patches
  carefully [
    ; for this line to work properly, ensure the txt file is under the same directory of this model
    file-open "sugar-map.txt"
    ; read in the sugar amount of each patch from file.
    foreach sort patches [ the-patch ->
      ask the-patch [
        set max-psugar file-read
        set psugar max-psugar
        ; Hide the world from students so they don't see the global distribution of sugar
        set pcolor gray
      ]
    ]
    file-close
  ][
    print error-message
    print "Please copy sugar-map.txt to the working directory."
  ]
end

;;;;;;; Go Procedures ;;;;;;;

to go
  listen-clients
  if not any? students [ stop ]

  ask patches [
    patch-growback
    patch-recolor
  ]

  ask students [
    ; On each tick, start with has-moved = false. Once a button is clicked, set it to true,
    ; so the model stop taking new clicks within a single tick. See "execute-move" procedure for more.
    set has-moved? false
    ifelse state = "broke" [
      run next-task
    ][
      if sugar <= 0 [
        hubnet-send user-id "message" "You ran out of sugar. You will freeze for a while as a penalty and will then continue with 5 sugar."
        set my-timer 30
        set next-task [ -> resume ]
        set state "broke"
      ]
      run next-task
      ; send resulting information for this round (this tick) to clients' interface to display
      send-info-to-clients
    ]
  ]
  if sum [sugar] of students > 0 [ update-lorenz-and-gini ]
  tick
end

;;;;;; HubNet Procedures ;;;;;;;

to listen-clients
  while [ hubnet-message-waiting? ] [   ; if there are any HubNet messages
    hubnet-fetch-message                ; retrieve a message
    ifelse hubnet-enter-message? [      ; if a new student joins
      create-new-student                ; create a new student
    ][
      ifelse hubnet-exit-message? [     ; if a student exits
        remove-student                  ; remove the student
      ][
        ask students with [user-id = hubnet-message-source][      ; otherwise
          execute-command hubnet-message-tag                      ; execute the input that the student made
        ]
      ]
    ]
  ]
end
; procedure to create a new student
to create-new-student
  create-students 1 [
    set user-id hubnet-message-source     ; assign a user-id to the student who just entered
    set color gray                        ; set student color and label gray so it blends into the gray background
    set label user-id
    set label-color gray

    set sugar random-in-range 5 25
    set earning-coefficient 1
    set education-level 0

    refresh-student
  ]
end

; procedure to set a student back to the initial conditions
to refresh-student ; turtle procedure
  ; randomly assign a metabolism and vision
  set metabolism random-in-range 1 3
  set vision random-in-range 1 6

  set shape "default"
  set has-moved? false
  set size 1
  ; randomly choose one empty patch to place the student
  move-to one-of patches with [not any? other turtles-here]

  set vision-points nobody
  visualize-view-points

  set next-task [ -> chill ]
  ; chilling is the default state, with which students start when they join or after going broke
  set state "chilling"
  send-info-to-clients
end

; procedure to remove a student
to remove-student
  ask students with [ user-id = hubnet-message-source ] [ die ]
end

; procedure to handle student action requests
to execute-command [ command ]
  if command = "up"           [ execute-move 0 ]
  if command = "down"         [ execute-move 180 ]
  if command = "right"        [ execute-move 90 ]
  if command = "left"         [ execute-move 270 ]
  if command = "harvest"      [ harvest-pressed ]
  if command = "go-to-school" [ go-to-school-pressed ]
end

to send-info-to-clients ; student procedure
  ; set the client view to follow the agent so it's always at the
  ; center of the view (showing 7 patches in each direction around the agent).
  hubnet-send-follow user-id self 7
  hubnet-send user-id "sugar" sugar
end

; procedure to handle a student's request to "go to school"
to go-to-school-pressed ; student procedure
  ifelse sugar > tuition [
    ifelse education-level < 5 [  ; a maximum of 5 times schooling is allowed
      ifelse state = "schooling" [
        hubnet-send user-id "message" "you are already at school"
      ][
        ifelse state = "chilling" [
          set state "schooling"
          set my-timer 50
          ; each student pays a one-time tuition upon entering school
          set sugar sugar - tuition
          ; student's avatar changes into a book, symbolizing s/he is at school
          set shape "book"
          set size 2
          set next-task [ -> school ]
          hubnet-send user-id "message" "at school..."
        ][
          hubnet-send user-id "message" word "can't go to school because you are" state
        ]
      ]
    ][
      hubnet-send user-id "message" "You already have the highest level of education"
    ]
  ][
    hubnet-send user-id "message" word "you need " word tuition " sugar for tuition"
  ]
end

; procedure to handle a student being in school
to school ; student procedure
  ifelse my-timer > 0 [
    set my-timer my-timer - 1
  ][
    ifelse education-level <= 5 [
      ; each time a student goes to school, his/her earning per harvest increases by 30%
      set earning-coefficient precision (earning-coefficient * 1.3) 1
      set education-level education-level + 1
      visualize-view-points
      ifelse vision < 6 [
        ; each time a student goes to school, his/her vision expands by 1 in all 4 directions (if it
        ; does not have the maximum vision of 6 yet)
        set vision vision + 1
        hubnet-send user-id "message" "You graduated with expanded vision and 130% earning power"
      ][
        hubnet-send user-id "message" "You graduated with 130% earning power"
      ]
      set next-task [ -> chill ]
      set state "chilling"
      set shape "default"
      set size 1
      hubnet-send user-id "earning-coeff" earning-coefficient
      hubnet-send user-id "edu-level" education-level
    ][
      hubnet-send user-id "message" "You already have the highest level of education"
    ]
  ]
end

;;;;;;;;; HubNet Commands ;;;;;;

to calculate-view-points [ dist ] ; student procedure
  ; find out the patches to the north, south, east, and west in the vision radius
  set vision-points patches at-points sentence
    map [ n -> list n 0 ] (range (-1 * dist) (dist + 1))
    map [ n -> list 0 n ] (range (-1 * dist) (dist + 1))
end

; procedure to calculate the "vision" of each student for their client
to visualize-view-points ; student procedure
  hubnet-clear-overrides user-id
  hubnet-send-override user-id self "label" [ "" ]  ; initializes view overrides
  calculate-view-points vision
  hubnet-send-override user-id vision-points "pcolor" [ true-color ]
  hubnet-send-override user-id turtles-on vision-points "color" [red]
  hubnet-send-override user-id turtles-on vision-points "label-color" [black]
  set vision-points nobody
end

; to chill means to do nothing
to chill
end

; resume after being broke
to resume ; student procedure
  ifelse my-timer > 0 [
    ; creates the visual effect of a big red X flashing
    hubnet-clear-overrides user-id
    hubnet-send-override user-id self "label" [ "" ]
    hubnet-send-override user-id self "color" [red]
    set shape "x"
    set size 2
    visualize-view-points
    ; reduce the timer by 1 each tick until it reaches 0
    set my-timer my-timer - 1
  ][ ; when time runs out, refresh the student and let it go back to play
    set shape "default"
    set size 1

    set next-task [ -> chill ]
    set state "chilling"
    send-info-to-clients
    set sugar 5
    hubnet-send user-id "message" "Now you continue with 5 sugar."
  ]
end

; procedure to handle requests from students to move
to execute-move [new-heading] ; student procedure
  if not has-moved? [
    set has-moved? true
    ifelse state = "chilling" [
      set heading new-heading
      if can-move? 1 [
        if not any? turtles-on patch-ahead 1 [
          fd 1
          hubnet-send user-id "message" "moving..."
          visualize-view-points
          ; sugar cannot go below 0
          ifelse sugar - metabolism < 0 [set sugar 0][set sugar sugar - metabolism]
          send-info-to-clients
          hubnet-send user-id "message" ""
          stop
        ]
      ]
    ][
      hubnet-send user-id "message" word "can't move because you are " state
    ]
  ]
end

; procedure to handle a harvest request
to harvest-pressed ; student procedure
  ifelse state = "harvesting" [
    hubnet-send user-id "message" "already harvesting"
  ][
    if state != "broke" [
      set state "harvesting"
      set next-task [ -> harvest ]
    ]
  ]
end

; procedure to handle harvesting
to harvest ; student procedure
  hubnet-send user-id "message" "harvesting..."
  let net-income precision (sugar - metabolism + psugar * earning-coefficient) 1
  ifelse net-income < 0 [ set sugar 0 ][ set sugar net-income ]  ; sugar should never go below 0
  set psugar 0
  set next-task [ -> chill ]
  set state "chilling"
  hubnet-send user-id "message" ""
end

to patch-recolor ; patch procedure
  set true-color (yellow + 4.9 - psugar)
end

to patch-growback ; patch procedure
  set psugar min (list max-psugar (psugar + 1))
end

; procedure to update statistics for the plots
to update-lorenz-and-gini
  let num-people count turtles
  let sorted-wealths sort [sugar] of turtles
  let total-wealth sum sorted-wealths
  let wealth-sum-so-far 0
  let index 0
  set gini-index-reserve 0
  set lorenz-points []

  repeat num-people [
    set wealth-sum-so-far (wealth-sum-so-far + item index sorted-wealths)
    set lorenz-points lput ((wealth-sum-so-far / total-wealth) * 100) lorenz-points
    set index (index + 1)
    set gini-index-reserve gini-index-reserve + (index / num-people) - (wealth-sum-so-far / total-wealth)
  ]
end

; helper procedure to get a random number in a range
to-report random-in-range [low high]
  report low + random (high - low + 1)
end


; Copyright 2018 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
214
10
722
519
-1
-1
10.0
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
49
0
49
1
1
1
ticks
20.0

BUTTON
1
85
102
132
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
109
85
210
132
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
365
525
470
558
show-world
ask patches [ set pcolor true-color ]
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
476
525
576
558
hide-world
ask patches [ set pcolor gray ]
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
725
175
908
348
Lorenz curve
Pop %
Wealth %
0.0
100.0
0.0
100.0
false
false
"" ""
PENS
"equal" 100.0 0 -7500403 true ";; draw a straight line from lower left to upper right\nset-current-plot-pen \"equal\"\nplot 0\nplot 100" ""
"lorenz" 1.0 0 -2674135 true "" "plot-pen-reset\nif any? students [ \nset-plot-pen-interval 100 / count turtles\nplot 0\nforeach lorenz-points plot\n]"

PLOT
725
355
908
520
Gini index vs. time
Time
Gini
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "if any? students [ \nplot (gini-index-reserve / count turtles) * 2\n]"

PLOT
724
10
908
169
Wealth distribution
People
Wealth
0.0
10.0
0.0
10.0
true
false
"set-plot-x-range 0 count turtles" "clear-plot\nif any? students [ \nset-plot-x-range 0 count turtles\nlet bar-list sort-on [sugar] turtles\nforeach bar-list [the-turtle -> ask the-turtle [plotxy position self bar-list sugar]]\n]"
PENS
"default" 1.0 1 -16777216 true "" ""

MONITOR
1
168
211
213
sugar-mean
mean [sugar] of students
1
1
11

SLIDER
4
11
209
44
tuition
tuition
0
100
0.0
5
1
Sugar
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This HubNet model is the third model of the MTG series. Mind the Gap (MTG) is a curricular unit revolving around a series of three agent-based participatory simulations (ABPSs). The goal of the MTG curricular unit is to help high school students understand important mechanisms of wealth inequality in the U.S. through the lens of complex systems with NetLogo HubNet-based participatory activities. For more details about the unit, refer to Mind the Gap 1 Equal Opportunities HubNet Model--the first model of the MTG series.

The goal of this model is to let students experience another type of strong force that shapes people’s course of life. Feedback loops, often called virtuous circles or vicious circles, are systematized or institutionalized forces. Unlike randomness, which is not biased against anyone, feedback loops are usually socially constructed, privileging certain groups of people at the cost of oppressing other groups. This model uses education as an example to let students experience that depending on the cost of education, it can become a force that is either closing or widening the gap between the rich and the poor.

## HOW IT WORKS

The "land" in this model is represented by a 50 by 50 world. Each patch contains a predetermined amount of sugar (2 units of sugar). The color of the patch shows the amount of sugar it contains: the darker the yellow, the more sugar it has. Each person (or agent) has a few attributes:

1. Vision: how many patches (steps) away an agent can see; a randomly assigned number between 1 and 6.

2. Endowment: how many units of sugar an agent starts with; a randomly assigned amount of sugar between 5 and 25.

3. Metabolism: how many units of sugar is needed for moving one step or doing one harvest; a randomly assigned amount of sugar between 1 and 3.

Students have some actions they can take:

1. Move: by clicking the direction buttons or the keyboard shortcuts, students can move around. Each click moves the student by one step and burns METABOLISM amount of sugar.

2. Harvest: by clicking the harvest button, students harvest all the sugar on the tile that he or she is standing on. One harvest burns METABOLISM amount of sugar.

3. Go to school: by clicking this button, students "go to school". When this happens, students' avatars turn into a book, representing being at school. Going to school has benefits and costs. Every time a student finishes school, his or her earning per harvest is boosted by 130%. If the student has less than 6 vision, going to school will also expand his or her vision by 1 step. However, going to school also has monetary and opportunity costs. When education is free or less expensive, all students can afford it to improve their vision and earning. However, when education is expensive, it becomes a virtuous circle for the rich and a vicious circle for the poor. As the result, the rich become richer and the poor become poor, closely reflecting a crucial inequality issue in the real world.

The students also have two additional measurements visible on their screen:

edu-level: edu-level shows the student's level of education (the number of schools the student attended). At the beginning of the simulation, everyone has an edu-level of 0. Each student can go to school up to 5 times.

earning-coeff: earning coefficient shows the earning power of a student. the sugar a student collects at each harvest is the product of the amount of sugar on the patch times the earning coefficient minus the metabolism. Each time a student goes to school, his or her earning coefficient multiplies by 1.3 times.

## HOW TO USE IT

Ideally, this model should be run twice: once with free education (tuition = 0) and once with a costly educational system (tuition >= 25). Doing so allows students to experience the empowering nature of education when it is affordable, and the privileges of the rich and the struggles of the poor when education is costly. Running this model with different values for tuition gives students opportunities to compare lives under these different conditions.

Before starting the model, the teacher can pose a question such as "Why are rich people rich while poor people poor in this model?". After briefly showing students the interface elements on both the students' and the teacher's interface, the teacher can start the model.

Teacher's interface elements:

TUITION: the sugar required for attending school once. This slider should be set before clicking the setup button.

SETUP: prepares the model for run. make sure to click it after every student has joined.

GO: start the model, so students can participate in the simulation.

SUGAR-MEAN: the average of all students' current sugar.

SHOW-WORLD: shows the underlying sugar distribution and the locations of each agent. By default, the world is hidden, because students are not supposed to know about the resource distribution. SHOW-WORLD can be used after students played the simulation. During the discussion phase, the teacher can show students what kind of world they were in.

HIDE-WORLD: after showing the world, the teacher can hide the world again from the students, so the whole checkerboard turns grey and students’ avatars become invisible.

Wealth distribution plot: a bar chart, in which each bar represents a student's sugar, sorted from the lowest to the highest.

Lorenz curve plot: a chart that shows the cumulative percent of wealth (y axis) owned by the cumulative percentage of the population (x axis). The perfectly equal distribution is the gray diagonal line (e.g., the bottom 30% of the population owns 30% of the total wealth). The farther the red curve deviates from the diagonal line, the more unequal the wealth distribution (e.g., the bottom 30% of the population owns 1% of the total wealth). The Lorenz curve is a cumulative percentage version of the Wealth distribution plot.

Gini index vs. time: Gini index is a numerical value between 0 and 1, with 0 being perfectly equal and 1 being extremely unequal, that measure the wealth inequality. The plot shows Gini index (y axis) over time (x axis)

The plots automatically update based on real time aggregation of the amount of sugar that students own.

## THINGS TO NOTICE

At the individual level, pay attention to your initial conditions: What is your endowment? (how much sugar do you start with?); What is your vision (how far you can see, as measured in numbers of patches); What is your metabolism? (See THINGS TO TRY for tips of figuring out your metabolism).

Pay attention to the color of the patch that you are harvesting. When you harvest it, it becomes white. But it returns to yellow soon after being harvested, indicating the sugar on that patch grew back.

How does your sugar change? Pay attention to the sugar monitor on your interface.

How many times do you go to school? How does going to school help with your wealth?

At the aggregate level, pay attention to how different levels of tuition affect wealth inequality (pay attention to the three plots).

## THINGS TO TRY

Try taking one step by clicking any of the directional buttons. How much sugar does it take to move one step? That amount is your metabolism. Try clicking the harvest button. Does your total sugar increase, decrease, or stay the same? Do you know why? (Tip: each harvest burns the same amount of sugar as moving one step).

Do you want to move or not? Why? If you do want to move, do you know where to move? (Tip: what is your vision?)

How rich are you in your class? Who is the richest? How did you or they become the richest? Share your experience with the whole class.

Discuss how the simulation compare to the real world. Do you see any analogies? What do vision, endowment, and metabolism mean in the real world? Can you find a real-world story that maps onto your experience in the simulation?

## EXTENDING THE MODEL

This model uses education as an example to let students experience feedback loops--virtuous and vicious cycles. Can you think of any other feedback loops and incorporate them in the model? Things like: taxation, investment, trade, loan, etc.?

## NETLOGO FEATURES

This model initializes each patch's sugar and color by using the `file-read` primitive based on the data provided in an external file.

This model uses `hubnet-view-override` and `hubnet-send-follow` to create the view seen on the clients' interface. `hubnet-send-override` allows the clients see a view that is different that the host. In this model, clients only see a small part of the virtual world. `hubnet-send-follow` keeps the user at the center of the client's view and puts a halo around it. The user is always centered even when it's moving.

This model also makes use of *anonymous procedures*, which allow agents to change states (E.g. from "chilling" to "broke"), in which the agents follow different rules at each tick (E.g. when an agent is in the "chilling" state, at each tick, the user's button clicks are executed. However, if the agent is in the "broke" state, the user's button clicks are ignored). Users switch between states in two ways: when in the "chilling" state, if the agent runs out of sugar, it goes into the "broke" state. Meanwhile, a timer starts to count down. When to timer goes down to zero, the agent goes out of the "broke" state and enters the "chilling" state again.

## RELATED MODELS

Other models in the Mind the Gap HubNet suite include:

* Mind the Gap 1 Equal Opportunities HubNet Model
* Mind the Gap 2 Random Assignment HubNet Model

The model is also related to the NetLogo SugarScape suite, including:

* Sugarscape 1 Immediate Growback
* Sugarscape 2 Constant Growback
* Sugarscape 3 Wealth Distribution

## CREDITS AND REFERENCES

Epstein, J. and Axtell, R. (1996). Growing Artificial Societies: Social Science from the Bottom Up. Washington, D.C.: Brookings Institution Press.

Li, J. and Wilensky, U. (2009). NetLogo Sugarscape 3 Wealth Distribution model. http://ccl.northwestern.edu/netlogo/models/Sugarscape3WealthDistribution. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Guo, Y. and Wilensky, U. (2018).  NetLogo MTG 3 Feedback Loop HubNet model.  http://ccl.northwestern.edu/netlogo/models/MTG3FeedbackLoopHubNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the HubNet software as:

* Wilensky, U. & Stroup, W. (1999). HubNet. http://ccl.northwestern.edu/netlogo/hubnet.html. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

To cite the Mind the Gap curriculum as a whole, please use:

* Guo, Y. & Wilensky, U. (2018). Mind the Gap curriculum. http://ccl.northwestern.edu/MindtheGap/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2018 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2018 MTG Cite: Guo, Y. -->
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

book
false
0
Polygon -7500403 true true 30 195 150 255 270 135 150 75
Polygon -7500403 true true 30 135 150 195 270 75 150 15
Polygon -7500403 true true 30 135 30 195 90 150
Polygon -1 true false 39 139 39 184 151 239 156 199
Polygon -1 true false 151 239 254 135 254 90 151 197
Line -7500403 true 150 196 150 247
Line -7500403 true 43 159 138 207
Line -7500403 true 43 174 138 222
Line -7500403 true 153 206 248 113
Line -7500403 true 153 221 248 128
Polygon -1 true false 159 52 144 67 204 97 219 82

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

money
true
1
Rectangle -2674135 true true 180 0 195 300
Rectangle -2674135 true true 105 0 120 300
Rectangle -2674135 true true 240 75 255 90
Rectangle -2674135 true true 225 60 240 75
Rectangle -2674135 true true 135 60 150 75
Rectangle -2674135 true true 90 45 105 60
Rectangle -2674135 true true 120 45 135 60
Rectangle -2674135 true true 60 225 75 240
Rectangle -2674135 true true 45 75 60 90
Rectangle -2674135 true true 60 75 75 90
Rectangle -2674135 true true 75 60 90 75
Rectangle -2674135 true true 90 60 105 75
Rectangle -2674135 true true 210 60 225 75
Rectangle -2674135 true true 120 60 135 75
Rectangle -2674135 true true 150 60 165 75
Rectangle -2674135 true true 165 60 180 75
Rectangle -2674135 true true 60 90 75 105
Rectangle -2674135 true true 45 90 60 105
Rectangle -2674135 true true 240 90 255 105
Rectangle -2674135 true true 225 90 240 105
Rectangle -2674135 true true 225 75 240 90
Rectangle -2674135 true true 210 45 225 60
Rectangle -2674135 true true 195 60 210 75
Rectangle -2674135 true true 195 45 210 60
Rectangle -2674135 true true 165 45 180 60
Rectangle -2674135 true true 150 45 165 60
Rectangle -2674135 true true 60 210 75 225
Rectangle -2674135 true true 45 210 60 225
Rectangle -2674135 true true 75 225 90 240
Rectangle -2674135 true true 90 225 105 240
Rectangle -2674135 true true 120 225 135 240
Rectangle -2674135 true true 135 225 150 240
Rectangle -2674135 true true 150 225 165 240
Rectangle -2674135 true true 165 225 180 240
Rectangle -2674135 true true 195 225 210 240
Rectangle -2674135 true true 210 225 225 240
Rectangle -2674135 true true 240 195 255 210
Rectangle -2674135 true true 225 210 240 225
Rectangle -2674135 true true 225 195 240 210
Rectangle -2674135 true true 240 180 255 195
Rectangle -2674135 true true 225 180 240 195
Rectangle -2674135 true true 240 165 255 180
Rectangle -2674135 true true 225 165 240 180
Rectangle -2674135 true true 210 150 225 165
Rectangle -2674135 true true 225 150 240 165
Rectangle -2674135 true true 195 150 210 165
Rectangle -2674135 true true 225 135 240 150
Rectangle -2674135 true true 210 135 225 150
Rectangle -2674135 true true 60 240 75 255
Rectangle -2674135 true true 90 135 105 150
Rectangle -2674135 true true 195 135 210 150
Rectangle -2674135 true true 45 225 60 240
Rectangle -2674135 true true 165 150 180 165
Rectangle -2674135 true true 150 150 165 165
Rectangle -2674135 true true 135 150 150 165
Rectangle -2674135 true true 120 150 135 165
Rectangle -2674135 true true 90 150 105 165
Rectangle -2674135 true true 75 150 90 165
Rectangle -2674135 true true 60 150 75 165
Rectangle -2674135 true true 45 135 60 150
Rectangle -2674135 true true 60 135 75 150
Rectangle -2674135 true true 75 135 90 150
Rectangle -2674135 true true 60 120 75 135
Rectangle -2674135 true true 45 120 60 135
Rectangle -2674135 true true 60 105 75 120
Rectangle -2674135 true true 45 105 60 120
Rectangle -2674135 true true 135 150 150 165
Rectangle -2674135 true true 135 150 150 165
Rectangle -2674135 true true 135 150 150 165
Rectangle -2674135 true true 135 150 150 165
Rectangle -2674135 true true 135 150 150 165
Rectangle -2674135 true true 135 150 150 165
Rectangle -2674135 true true 135 150 150 165
Rectangle -2674135 true true 135 150 150 165
Rectangle -2674135 true true 240 60 255 75
Rectangle -2674135 true true 225 45 240 60
Rectangle -2674135 true true 240 150 255 165
Rectangle -2674135 true true 240 225 255 240
Rectangle -2674135 true true 240 210 255 225
Rectangle -2674135 true true 225 240 240 255
Rectangle -2674135 true true 60 45 75 60
Rectangle -2674135 true true 45 60 60 75
Rectangle -2674135 true true 60 60 75 75
Rectangle -2674135 true true 75 45 90 60
Rectangle -2674135 true true 135 45 150 60
Rectangle -2674135 true true 165 135 180 150
Rectangle -2674135 true true 150 135 165 150
Rectangle -2674135 true true 135 135 150 150
Rectangle -2674135 true true 120 135 135 150
Rectangle -2674135 true true 225 225 240 240
Rectangle -2674135 true true 210 240 225 255
Rectangle -2674135 true true 195 240 210 255
Rectangle -2674135 true true 165 240 180 255
Rectangle -2674135 true true 150 240 165 255
Rectangle -2674135 true true 135 240 150 255
Rectangle -2674135 true true 120 240 135 255
Rectangle -2674135 true true 90 240 105 255
Rectangle -2674135 true true 75 240 90 255
Rectangle -2674135 true true 165 0 180 300
Rectangle -2674135 true true 120 0 135 300

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
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
BUTTON
79
180
148
213
up
NIL
NIL
1
T
OBSERVER
NIL
W

BUTTON
79
224
148
257
down
NIL
NIL
1
T
OBSERVER
NIL
S

BUTTON
10
224
79
257
left
NIL
NIL
1
T
OBSERVER
NIL
A

BUTTON
148
224
217
257
right
NIL
NIL
1
T
OBSERVER
NIL
D

VIEW
226
67
666
505
0
0
0
1
1
1
1
1
0
1
1
1
0
49
0
49

MONITOR
6
10
666
59
message
NIL
0
1

MONITOR
8
111
218
160
sugar
NIL
2
1

BUTTON
11
275
218
308
harvest
NIL
NIL
1
T
OBSERVER
NIL
H

BUTTON
66
408
182
441
go-to-school
NIL
NIL
1
T
OBSERVER
NIL
G

MONITOR
10
345
96
394
edu-level
NIL
0
1

MONITOR
101
345
219
394
earning-coeff
NIL
1
1

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
