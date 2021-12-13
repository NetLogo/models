globals [
  charge-flow  ; a variable to keep track of the number of
               ;   electrons that have flowed through the cathode
  wire-patches ; a patch-set that contains all the patches that represent the wire
  previous-identity-option ; stores how students are labeled
]

breed [ students student ]
students-own [
  slice-id        ; stores which slice I represent
  left-bound      ; the left side of my slice
  right-bound     ; the right side of my slice
  my-patches      ; a set of patches that are mine
  my-average-temp ; stores average temp of my-patches

  ; variables for HubNet client options
  user-name
  selected-nuclei
  watched-electron
]

breed [ electrons electron ]
electrons-own [ speed  ]

breed [ nuclei nucleus ]

patches-own [
  temp      ; variable to store how much heat is in the patch
  slice-num ; variable to store what slice a patch belongs in
]

;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;


to startup
  hubnet-reset
  ask turtles [ die ]
  setup
end

to setup
  set charge-flow 0

  ; clear all remnants of a previous wire
  ask turtles with [not is-student? self] [ die ]
  clear-all-plots
  clear-patches

  setup-wire
  divide-wire

  ; update labels of students if you need to
  if any? students with [user-name != "" ] [
    ask students with [user-name != ""] [
      update-my-slice-label
    ]
  ]
  set previous-identity-option identify-students?

  reset-ticks
end

; procedure to setup the wire and its nuclei
to setup-wire
  set-default-shape electrons "circle 2"

  ; create wire
  set wire-patches patches with [ pycor <= 16 and pycor >= -16 ]
  ask wire-patches [
    set pcolor gray
    set temp 20
    recolor
  ]

  ; create electrons
  let total-electrons 2 * num-students * nuclei-per-slice
  create-electrons total-electrons [
    setxy random-xcor random 30 - 15
    set heading (random 271) + 135
    set color orange - 2
    set speed random-float 1
  ]

  ; create labels for the battery terminals
  create-turtles 1 [
    setxy (min-pxcor + 6) -21
    set shape "plus"
    set size 6
  ]
  create-turtles 1 [
      setxy (max-pxcor - 6) -21
      set shape "minus"
      set size 6
  ]
end

; procedure to divide the wire into the appropriate number of slices
to divide-wire
  ; calculate the width of a slice based on num-students
  let slice-width (max-pxcor - min-pxcor) / num-students
  let l 0
  let r 0

  ; define a set of acceptable colors
  let color-list [ turquoise grey red orange brown sky green cyan pink violet ]

  ; Get the user name of any student currently logged in
  let logged-in-students filter [ a-student -> a-student != "" ] [user-name] of students
  ; Clear current students
  if any? students [ ask students [ die ] ]
  ; for every student
  foreach (range 1 (num-students + 1)) [ n ->

    ; calculate the left and right bound of its slice
    set l min-pxcor + (slice-width * (n - 1))
    set r l + slice-width

    ; create a student turtle to store all the necessary info
    create-students 1 [
      set user-name ""

      ; if there are students currently logged in, make sure to assign them a slice
      if not empty? logged-in-students [
        set user-name first logged-in-students
        set logged-in-students but-first logged-in-students
      ]

      set slice-id n
      set left-bound l
      set right-bound r
      set color item (n - 1) color-list

      ; put any patches in this slice into my-patches
      set my-patches patches with [ pxcor >= l and pxcor < r and (abs pycor <= 16) ]

      ; tell the patches which slice they're in
      ask my-patches [ set slice-num n ]

      ; create a hidden person in the middle of your slice
      setxy (round ((right-bound + left-bound) / 2)) 0
      hide-turtle

      ; create the nuclei
      ask n-of nuclei-per-slice my-patches [
        sprout-a-nucleus
      ]

      ; now make sure all of our HubNet options are good to go
      initialize-hubnet-client
    ]
     ; Then create a border along the left edge of the student
     create-turtles 1 [
      setxy l 0
      set shape "line"
      set size 33
      set heading 0
      set color white
    ]
  ]

  ; If there are still students that haven't been assigned
  ;   a slice, we have to ask them to leave.
  if not empty? logged-in-students [
    foreach logged-in-students [ a-student ->
      user-message "There is no more space in the wire!\nYou may want to change the 'num-students' slider\nand then re-setup."
      hubnet-kick-client a-student
    ]
  ]

end

;;;;;;;;;;;;;;;;;;;;;;
;;;; Go Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;

to go
  ; listen to HubNet clients
  listen-to-clients

  every .25 [
    ; Handle slow radiation of temperature out
    ask wire-patches [ if temp > 20 [ set temp temp - 0.75 ]] ; adds a loss-factor to the temperature of each patch due to radiation

    ; Handle diffusion of temperature from one patch to its neighbors
    spread-temp
    ask wire-patches [ recolor ]

    ; Update the stats on each client
    send-stats-to-students
  ]

  ; If there's been a change to the student label option, update the clients
  if identify-students? != previous-identity-option [
    if any? students with [user-name != "" ] [
      ask students with [user-name != ""] [
        update-my-slice-label
      ]
    ]
    set previous-identity-option identify-students?
  ]

  ask electrons [ move ]

  tick
end


; this procedure has all of the rules for how electrons move
; and how to perform simple point collisions with nuclei in
; the wire
to move ; electron procedure

  ; calculate the distance to move
  let dist max (list (speed + voltage) 1)

  ; if the electron has reached the cathode, generate a new electron and die
  if pxcor <= (min-pxcor + dist) [
    pen-up
    set charge-flow charge-flow + 1 ; increment our counter
    hatch-electrons 1 [
      set color orange - 2
      ; random ycor (the height of the wire is - 16 to 16)
      setxy (max-pxcor - random-float 1) ((random 33 - 16) + random-float 1 - .5)
      set heading (random 271) + 135
      set speed random-float 1
    ]
    die
  ]

  ; If we're going to run into a nuclei, calculate the results of the collision
  let pheat speed
  ifelse not any? nuclei in-cone dist 140 [
    ; if we aren't colliding, then we get pulled toward the cathode
    let delta (subtract-headings heading 270)
    let wdelta (delta * speed) / ( voltage + speed )
    set heading 270 + wdelta
    set speed speed + voltage
  ][
    ; rules for collsion
    let the-collider one-of nuclei in-cone dist 140
    face the-collider
    move-to the-collider
    set heading heading - 180
    fd 1
    ask patch-here [
      set temp temp + 10 * (pheat) ^ 2
    ] ; temp is proportional to square of speed
    fd .6
    set speed ( speed / 10 )
    ; denotes inelastic collision - electron loses its velocity after collision
  ]

  ; We have to be a little careful here because electrons on the far right of the wire can actually
  ; go "off the wire" to the right where there are no patches
  let my-next-patch patch-ahead speed
  if my-next-patch != nobody [
    ; if an electron is about to go off the top/bottom of the wire, wrap.
    if self = subject [ pen-up ]
    if [pycor] of my-next-patch > 16  [set ycor -16 ]
    if [pycor] of my-next-patch < -16 [ pen-up set ycor 16  ]
    if self = subject [ pen-down ]
  ]

  fd speed ; move forward
end

; a procedure to color a patch based on its temperature
to recolor ; patch procedure
  set pcolor scale-color grey temp -40 100
end

; this procedure defines how temperature is spread from a patch to its neighbors
to spread-temp ; patch procedure
  let your-neighbors nobody

  ask wire-patches [
    ; if the share-heat-across slices is ON, then we consider all neighbors
    ifelse share-heat-across-slices? [
      set your-neighbors neighbors with [ slice-num > 0 ]
    ][
      ; otherwise, we only consider neighbors that are in our slice
      set your-neighbors (neighbors with [ slice-num = [slice-num] of myself])
    ]

    ; if this patch is on the edge, it also has a neighbor on the other side of the wire
    ;  this is because the wire is a cylinder
    if abs pycor = 16 [
      ask your-neighbors with [ abs pycor = 16 ] [
        set your-neighbors (patch-set your-neighbors (patch pxcor (- pycor)))
      ]
      set your-neighbors (patch-set your-neighbors (patch pxcor (- pycor)))
    ]

    ; update the temperature and the patch color
    set temp temp + (diffusion-factor * (((sum [temp] of your-neighbors) / count your-neighbors) - temp))
  ]
end

; Helper procedure to label your slice based on the model options
to update-my-slice-label ; student procedure
  let slice-width right-bound - left-bound
  let r round right-bound
  let middle round ((right-bound + left-bound) / 2)

  ; either display a user-name or a slice #
  let short-name substring user-name 0
    ifelse-value (round (slice-width / 4) + 1) > length user-name
      [ length user-name ]
      [ (round (slice-width / 4) + 1) ]

  ; reset the labels
  ask patches with [ pxcor = (middle + 1) and pycor = 20] [ set plabel "" ]
  ask patches with [ pxcor = r - 1 and pycor = 20] [ set plabel "" ]

  ; now place the labels
  ifelse not identify-students? [
    ask patches with [ pxcor = (middle + 1) and pycor = 20] [ set plabel (word "#" [slice-id] of myself) ]
  ] [
    ask patches with [ pxcor = r - 1 and pycor = 20] [ set plabel short-name ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;
; HubNet Procedures ;
;;;;;;;;;;;;;;;;;;;;;

; this is the main procedure that deals with receiving HubNet messages
to listen-to-clients
  ; If there is a HubNet message waiting to be processed
  if hubnet-message-waiting? [
    ; fetch them one at a time
    hubnet-fetch-message

    ; handle them based on the type of message
    ; If it's a log-in message, create a new student-observer
    ifelse hubnet-enter-message? [
      create-new-student-observer
    ][
      ; If this is a log-out we vacate our turtle
      ifelse hubnet-exit-message? [
        ask students with [ user-name = hubnet-message-source ] [ set user-name "" ]
      ][
        ; If it's a mouse up, we lookup the selected-mouse-option and then do the appropriate operation
        ifelse hubnet-message-tag = "Mouse Up" [
        ask students with [ user-name = hubnet-message-source ] [
          let clicked-patch patch (item 0 hubnet-message) (item 1 hubnet-message)
          move-a-nucleus clicked-patch
        ]
      ][
          ; If they pressed the label button, then pick an electron to label
          if hubnet-message-tag = "label-an-electron" [
            ask students with [ user-name = hubnet-message-source ] [
              label-electron-in-my-slice
            ]
          ]
        ]
      ]
    ]
  ]
end

to move-a-nucleus [ clicked-patch ] ; student procedure
  if member? clicked-patch my-patches [
    ; if we don't have a selected nuclei and there's one here, select it
    ifelse selected-nuclei = nobody and any? [nuclei-here] of clicked-patch [
      set selected-nuclei one-of [nuclei-here] of clicked-patch
    ][
      ; if we have one selected, and it's where we clicked, deselect it
      ifelse selected-nuclei != nobody and any? [nuclei-here] of clicked-patch [
        if member? selected-nuclei [nuclei-here] of clicked-patch [ set selected-nuclei nobody ]
      ][
        ; if there is a nuclei already selected, place it on the clicked patch
        if selected-nuclei != nobody [
          ask clicked-patch [ sprout-a-nucleus ]
          ask selected-nuclei [ die ]
          set selected-nuclei nobody
        ]
      ]
    ]
  ]

  ; recolor all of the nuclei in our slice
  hubnet-send-override user-name (nuclei-on my-patches) "color" [ [color] of myself ]
  ; highlight the selected nuclei
  if selected-nuclei != nobody [ hubnet-send-override user-name selected-nuclei "color" [ yellow ] ]
end

; procedure to send temperatures and updates to the connected clients
to send-stats-to-students
  ask students [
    if watched-electron != nobody and member? [patch-here] of watched-electron my-patches [
      hubnet-send-override user-name watched-electron "label" [ precision speed 1 ]
    ]
    set my-average-temp round mean [ temp ] of my-patches
    ; If a turtle is connected to a client, send it the temp info
    if user-name != "" [
      ifelse show-temps? [ hubnet-send user-name "avg temp" my-average-temp ] [ hubnet-send user-name "avg temp" "hidden" ]
      hubnet-send user-name "timer" ticks / 50
    ]
  ]
end

; here we have a procedure that controls labeling an electron in a client interface
to label-electron-in-my-slice ; student procedure
  ; if there's already a labeled electron, remove its label
  if watched-electron != nobody [ hubnet-send-override user-name watched-electron "label" [ "" ] ]
  ; pick an electron as far right as possible and label it
  set watched-electron max-one-of electrons-on my-patches [ xcor ]
  hubnet-send-override user-name watched-electron "color" [ yellow - 1 ]
  hubnet-send-override user-name watched-electron "label" [ precision speed 1 ]
end

; helper procedure to generate a new nuclei
to sprout-a-nucleus ; nuclei procedure
  sprout-nuclei 1 [
    set size 2
    set shape "circle 2"
    set color blue

    ; Because the nuclei are size 2, we make sure none are on the border
    if (ycor = 16)  [ set ycor 15 ]
    if (ycor = -16) [ set ycor -15 ]
  ]
end

; Helper procedure to officially add a HubNet client to the model
to create-new-student-observer
  ; If there is a free wire slice, we can login; otherwise, we have to kick the incoming client
  ifelse not any? students with [ user-name = "" ] [
    user-message "There is no more space in the wire!\nYou may want to change the 'num-students' slider\nand then re-setup."
    hubnet-kick-client hubnet-message-source
  ][
    ; If there's room, assign to an open slice
    ask one-of students with [ user-name = "" ] [
      set user-name hubnet-message-source
      initialize-hubnet-client
      update-my-slice-label
    ]
  ]
end


; Procedure to reset all of the options for a HubNet client
to initialize-hubnet-client ; turtle procedure
  ; Reset HubNet Options for this student
  set watched-electron nobody
  set selected-nuclei nobody

  ; Send the new interface options to the client
  hubnet-clear-overrides user-name
  hubnet-send-follow user-name self ifelse-value 18 > (round (abs(left-bound - right-bound)) / 2) [18] [ (round (abs(left-bound - right-bound)) / 2) ]
  hubnet-send-override user-name (nuclei-on my-patches) "color" [ [color] of myself ]
  hubnet-send user-name "slice" (word "#" slice-id)
end

;;;;;;;;;;;;;
; Reporters ;
;;;;;;;;;;;;;

; Report back the name of the user with the highest slice temperature
to-report get-leader
  ifelse show-temps? [
    let the-leader max-one-of students [ my-average-temp ]
    ifelse identify-students? [
      ifelse [user-name] of the-leader != "" [
        report [user-name] of the-leader
      ][
        report "Computer"
      ]
    ] [
      report (word "Slice #" [slice-id] of the-leader)
    ]
  ][
   report "hidden"
  ]
end

; Report back the temperature of any given student
to-report get-student-temp [ num ]
  ifelse show-temps?
  [ report [my-average-temp] of one-of students with [ slice-id = num ] ]
  [ report "hidden" ]
end

; Report back the highest slice temperature
to-report get-leading-temp
  ifelse show-temps?
  [ report [my-average-temp] of max-one-of students [ my-average-temp] ]
  [ report "hidden" ]
end


; Copyright 2008 Pratim Sengupta and Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
233
12
1096
276
-1
-1
5.0
1
14
1
1
1
0
0
1
1
-85
85
-25
25
1
1
1
ticks
30.0

BUTTON
5
130
205
170
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
100
175
205
210
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
220
205
253
voltage
voltage
0.01
0.2
0.1
0.01
1
NIL
HORIZONTAL

BUTTON
6
382
206
415
Watch An Electron
ask one-of electrons with [ xcor > max-pxcor - 5 ] [\n    set color yellow\n    pen-down\n    watch-me\n]
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
6
416
206
449
Stop Watching and Erase
ask electrons [ pen-up set color orange - 2]\nreset-perspective\nclear-drawing
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
760
460
981
517
Electrons Arrived at Cathode
charge-flow
17
1
14

MONITOR
1105
55
1215
108
Timer
ticks / 50
2
1
13

PLOT
480
460
758
631
Current vs Time
Time (Seconds)
Current
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 5 [ plotxy (ticks / 50) (50 * charge-flow) / ticks ]"

SLIDER
5
254
205
287
diffusion-factor
diffusion-factor
0
0.1
0.05
0.01
1
NIL
HORIZONTAL

PLOT
215
460
465
630
Average Temperature Plot
Time (Seconds)
Temp (0-100)
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plotxy (ticks / 50) mean [temp] of wire-patches"

MONITOR
1105
330
1215
387
Avg. Temp
mean [my-average-temp] of students
2
1
14

SLIDER
5
50
205
83
nuclei-per-slice
nuclei-per-slice
1
25
15.0
1
1
nuclei
HORIZONTAL

MONITOR
1105
175
1215
228
with a temp of
get-leading-temp
17
1
13

MONITOR
1105
115
1215
168
Leader is
get-leader
1
1
13

SWITCH
5
495
205
528
show-temps?
show-temps?
0
1
-1000

BUTTON
5
175
95
210
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
0

SWITCH
5
295
205
328
share-heat-across-slices?
share-heat-across-slices?
1
1
-1000

BUTTON
6
336
206
369
Reset All Temperatures
  if user-yes-or-no? \"Are you sure you want to reset all\\ntemperatures back to 20 Temp Units?\" [\n    ask wire-patches [\n      set temp 20\n      recolor\n    ]\n  ]
NIL
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
90
205
123
num-students
num-students
3
10
3.0
1
1
students
HORIZONTAL

PLOT
216
282
1101
453
Temperature in each Slice
Slice #
Temperature
1.0
1.0
0.0
30.0
true
false
"" "clear-plot\nif not show-temps? [ stop ]\nif any? students [ set-plot-x-range 1 (count students + 1) set-plot-y-range 0 ([my-average-temp] of max-one-of students [my-average-temp]) + 15 ]"
PENS
"slice-1" 1.0 1 -14835848 true "" "plotxy 1 get-student-temp 1"
"slice-2" 1.0 1 -7500403 true "" "if count students > 1 [ plotxy 2 get-student-temp 2 ]"
"slice-3" 1.0 1 -2674135 true "" "if count students > 2 [ plotxy 3 get-student-temp 3 ]"
"slice-4" 1.0 1 -955883 true "" "if count students > 3 [ plotxy 4 get-student-temp 4 ]"
"slice-5" 1.0 1 -6459832 true "" "if count students > 4 [ plotxy 5 get-student-temp 5 ]"
"slice-6" 1.0 1 -13791810 true "" "if count students > 5 [ plotxy 6 get-student-temp 6 ]"
"slice-7" 1.0 1 -10899396 true "" "if count students > 6 [ plotxy 7 get-student-temp 7 ]"
"slice-8" 1.0 1 -11221820 true "" "if count students > 7 [ plotxy 8 get-student-temp 8 ]"
"slice-9" 1.0 1 -2064490 true "" "if count students > 8 [ plotxy 9 get-student-temp 9 ]"
"slice-10" 1.0 1 -8630108 true "" "if count students > 9 [ plotxy 10 get-student-temp 10 ]"

SWITCH
5
535
205
568
identify-students?
identify-students?
1
1
-1000

BUTTON
5
10
205
43
Complete Reset
startup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model is an extension of the _Current in a Wire_ model that adds two elements: temperature and HubNet interactivity. Just like _Current in a Wire_, this model visualizes the flow of electrons, caused by a voltage difference between two ends of a wire. The electrons are constantly accelerated by the applied voltage meaning they acquire some kinetic energy as they move towards the positive end of the wire. However, as they flow, the electrons collide with the nuclei of the material the wire is made of, in other words, they encounter _resistance_. In these collisions, some of the kinetic energy of the electrons is transformed into heat energy which is absorbed by the wire.

Because this is a HubNet model, a number of "clients" or students connect to this model via the **HubNet Client Launcher**. Every client that is connected gets to "control" a slice of the wire by placing and removing the nuclei that electrons collide with in their slice. Through a series of activities, students both interact and experiment with the idea that many macro-level phenomena like current and resistance are emergent–that they arise due to simple interactions between many micro-level objects like atoms and electrons.

## HOW IT WORKS

The wire in this model (the patches which aren't black) is composed of atoms, which in turn are made of negatively charged electrons and positively charged nuclei.  According to the Bohr model of the atom, these electrons revolve in concentric shells around the nucleus. However, in each atom, the electrons that are farthest away from the nucleus (i.e., the electrons that are in the outermost shell of each atom) behave as if they are free from the nuclear attraction. Here we represent electrons as tiny orange-colored circles.

Voltage in the wire gives rise to a constant electric field throughout the wire, imparting a steady drift to the electrons toward the positive side of the wire or the _cathode_.  In addition to this drift, the electrons also collide with the atomic nuclei that make up the wire, giving rise to electrical resistance. The nuclei are the blue circles shown in the wire that in this model causes the electrons to go around them.

When an electron collides with a nuclei, its kinetic energy is transformed into heat which is absorbed by the wire. We visualize the temperature of the wire by coloring the patches that represent the wire by how warm they are.  The warmer the patch, the closer to white its color will be. The cooler the patch, the closer to a dark-grey it will be.

The wire is divided into many "slices" so that each HubNet Client can monitor and control a single slice of the wire. Within each slice, students can click on nuclei to remove them or create a new nuclei on some other patch. In this manner, the students can control the location of the nuclei in their slice and see what the relationship is between that structure, collisions, and the temperature of their slice.

## HOW TO USE IT

When the model opens, the teacher or activity leader needs to first select the number of students that will connect by using the NUM-STUDENTS slider. They also need to select how many nuclei will be present in each slice using the NUCLEI-PER-SLICE slider. Once those two options are selected, hit the SETUP button.

The COMPLETE RESET button should only be used as a last resort because it will disconnect all students who are currently connected.

Then ask however many students you have selected to join through the HubNet Client application. If the model is not listed in the bottom of the login window, make sure to provide students with the correct IP address and port number for your model. After all students have joined, the teacher starts the model by clicking the GO button.

In addition to the NUM-STUDENTS and NUCLEI-PER-SLICE sliders, there are several other interface elements the teacher or activity leader can control in order to change the behavior of the model:

  * The VOLTAGE slider controls the voltage or the electric potential difference between the cathode and anode of the wire.
  * The DIFFUSION-FACTOR slider controls how much heat flows from one wire patch to its neighbors
  * The SHARE-TEMP-ACROSS-SLICES? switch controls whether or not heat can diffuse from one wire slice to another
  * The RESET ALL TEMPERATURES button, when clicked, sets the temperature of all patches in the wire back to their original values
  * The WATCH AN ELECTRON button, when clicked, causes the model to `follow` a single electron and visualize its path as it flows through the wire
  * The STOP WATCHING AND ERASE button, when clicked, causes the model to cease following an electron and also erases any paths left on the view

The teacher or activity leader can also control two different aspects of the HubNet part of the model:

  * The SHOW-TEMP? switch, controls whether or not the temperatures of the wire slices and the average temperature of the wire are shown (both in this model and the client interfaces)
  * The IDENTIFY-STUDENTS? switch, if on, labels all the slices with the `user-name` of the connected HubNet client who is controlling that slice (otherwise, the slices are just identified by an ID number).

Finally, there are a number of different monitors and plots:

  * The TIMER monitor shows how long the simulation has been running in "model time"
  * The HIGHEST SLICE TEMPERATURE monitor shows the current temperature of the hottest wire slice
  * The LEADER monitor shows which HubNet Client's slice has the current highest temperature (if a slice that doesn't have a client connected is hottest, it will just display "Computer"
  * The AVG. TEMP OVER ALL SLICES monitor displays the average temperature of the entire wire
  * The ELECTRONS ARRIVED AT CATHODE monitor displays the number of electrons that have flowed past the cathode of the wire
  * The TEMPERATURE IN EACH SLICE plot displays a histogram where each bar's height represents the current temperature in that slice
  * The AVERAGE TEMPERATURE plot displays the average temperature since the beginning of the simulation
  * The CURRENT VS. TIME plot displays the electrical current that has been measured from the wire since the beginning of the simulation

### Client Interface Elements

The Client Interface has a few different features that give HubNet Clients a few different options for interaction:

  * Each Client's View is limited to just their slice of the wire
  * The SLICE monitor shows the slice id that the client has been assigned so that they know which slice in the wire they are controlling
  * The AVG TEMP monitor shows the current temperature of the slice the client is controlling
  * The LABEL-AN-ELECTRON button picks an electron in the students slice and labels it with its speed so that a student can investigate how the collisions affect a single electron's speed as it travels through the wire
  * The nuclei that are located in the student's slice will be colored according to the color of the histogram bar that student's average temperature is displayed in instead of the default blue color
  * To move nuclei around, student simply click on one of the nuclei in their slice (it will be highlighted in yellow to indicate it has been selected) and then click on a patch in their slice they would like to move it to

## THINGS TO NOTICE

What happens to the movement of the electrons as VOLTAGE changes?

Notice the change of speed and movement of electrons as they collide with nuclei.

Notice that there's a relationship between the speed of the electrons as they collide and the heat the patches near this collision absorb. Watch the collisions and see if you can figure out what the relationship is. Once you have a guess, switch over to the Code Tab and see if you can find the code where this heat energy is produced and absorbed.

Are there certain formations of nuclei that seem to cause collisions that cause more heating than others?

How does increasing the DIFFUSION-FACTOR affect the spread of temperature across the wire?

## THINGS TO TRY

This model was designed for students (clients) to play three different games:

### Game 1

The goal in this game is for students to maximize the temperature in their slice of the wire. For this game, the teacher should set the SHARE-HEAT-ACROSS-SLICES? switch to the OFF position.

Once everything is setup, allow students to join and ask them to try out different strategies for maximizing the temperature in their slice. Also ask them to write down what their strategy is once they settle on one.

#### Sample Strategies and Reasoning
  1. Far-end arrangement
    * "Maybe more travel time for electrons will result in more heat"
  2. Clustering arrangement
    * "More collisions will result in more heat"

### Game 2

Game 2 is similar to Game 1, the only difference being that the SHARE-HEAT-ACROSS-SLICES? switch should be in the ON position. The teacher should also remind the students what this changes about the model.

Again, ask students to come up with a good strategy to maximize temperature and write it down. If their strategy changed from Game 1, ask them why they thought they needed to change strategies.

#### Sample Strategies and Reasoning
  1. Far-end arrangement
    * "Maybe more travel time for electrons will result in more heat"
  2. Arrangement is responsive to the right-adjacent slice (move nuclei inward from the left edge)
    * "Temperature gets up faster if it does not spill into the next slice"

### Game 3

Game 3 is the same as Game 2, except for in this game, the Teacher should allow all the students to see the main model.

#### Sample Strategies and Reasoning
  1. Hybrid strategy: Far-end + Cluster
    * "More travel time for electrons will result in more heat"
  2. Arrangement is responsive to the right-adjacent slice
    * "More collisions will result in more heat"

### After the Games
After students complete the three games, conduct a group discussion in which students discuss their strategies for maximizing temperature in their slice for Games 1, 2 and 3.

Following this group discussion, review the following with the students:
  * Mechanism of resistance
  * Relationship between collisions, heat, and light
  * Flow of electrons in a wire.

## EXTENDING THE MODEL

Currently the model randomly places nuclei within each slice of the wire. In real wires, the nuclei are much more structured. Try writing a procedure that places the nuclei in specific formations that represent a real world material.

Right now, students can only ever see their slice of the wire. See if you can add an option in the Client Interface to "peek" at the whole wire.

## NETLOGO FEATURES

This model uses the `hubnet-send-follow` primitive to give students a local view of a part of the system.

## RELATED MODELS

Checkout the other NIELS curricular models, including:

* Current in a Wire
* Electron Sink
* Electrostatics
* Parallel Circuit
* Series Circuit

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Sengupta, P., Brady, C., Bain, C. and Wilensky, U. (2008).  NetLogo Current in a Wire HubNet model.  http://ccl.northwestern.edu/netlogo/models/CurrentinaWireHubNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the HubNet software as:

* Wilensky, U. & Stroup, W. (1999). HubNet. http://ccl.northwestern.edu/netlogo/hubnet.html. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

To cite the NIELS curriculum as a whole, please use:

* Sengupta, P. and Wilensky, U. (2008). NetLogo NIELS curriculum. http://ccl.northwestern.edu/NIELS/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2008 Pratim Sengupta and Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

To use this model for academic or commercial research, please contact Pratim Sengupta at <pratim.sengupta@vanderbilt.edu> or Uri Wilensky at <uri@northwestern.edu> for a mutual agreement prior to usage.

<!-- 2008 NIELS Cite: Sengupta, P., Brady, C., Bain, C. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

anode
false
14
Rectangle -7500403 true false 0 0 255 300
Rectangle -7500403 false false 30 0 285 300
Rectangle -2674135 true false 0 0 285 300
Rectangle -1184463 false false 0 0 300 300

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

atom-pusher
true
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120
Rectangle -7500403 false true 15 15 285 30
Rectangle -7500403 true true 15 15 285 30
Rectangle -7500403 true true 15 15 15 30
Rectangle -7500403 true true 0 0 15 30
Rectangle -7500403 true true 285 0 300 30

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

cathode
false
0
Rectangle -13345367 true false 0 0 285 300
Rectangle -1184463 false false 0 0 285 300

circle
false
0
Circle -7500403 true true 0 0 300
Circle -7500403 false true -45 -45 180
Circle -16777216 false false -2 -2 304

circle 2
false
2
Circle -16777216 true false 0 0 300
Circle -955883 true true 30 30 240

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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

minus
false
14
Rectangle -1 true false 0 90 300 210

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

plus
false
0
Rectangle -1 true false 105 0 195 300
Rectangle -1 true false 0 105 300 195

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
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
9
10
522
523
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
-85
85
-25
25

MONITOR
430
530
520
579
avg temp
NIL
3
1

MONITOR
105
530
197
579
slice
NIL
3
1

MONITOR
10
530
100
579
timer
NIL
3
1

BUTTON
200
530
425
563
label-an-electron
NIL
NIL
1
T
OBSERVER
NIL
NIL

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
