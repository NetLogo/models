extensions [ csv ]         ; export clients history

breed [ sites site ]
breed [ robots robot ]
breed [ students student ]

globals [
  history                 ; a list of history of all students' dances, including [Ticks, Quality, Recruited]
]

sites-own [
  quality
  true-color              ; color after being discovered. (undiscovered sites are all grey)
]

students-own [
  dance-length            ; the number of ticks a student-controlled bee will dance
  dances-made             ; the rounds of dances a student have finished
  user-id
  supported-site
  bee-timer               ; keep track of ticks elapsed at a certain state, usually the dance length.
                          ;   the higher the target quality, the longer the dance
  recruited               ; the number of other bees recruited (influenced by its dance)
  destination             ; where the bee is headed
  message-content

  state                   ; There are 4 states a student could be in:
                          ; 1. exploring: the initial state of a student. It can be
                          ;    controlled by the direction buttons on the hubnet
                          ;    client to move around and explore new hive sites.
                          ; 2. visiting: the outbound part of an automated trip to
                          ;    a site just visited. After a student found a site and
                          ;    returned to the swarm, if the "revisit" button is hit,
                          ;    the bee automatically flies toward the site just visited.
                          ; 3. returning: the inbound part of the trip.
                          ; 4. dancing
]

robots-own [              ; variables below are the same as students'. See students-own for explanations
  destination             ; where the bee is headed
  supported-site
  bee-timer
  recruited
  state                   ; marks the current state a bee is in. 5 possible values:
                          ; 1. chilling: when a robot is in idle. a robot in this
                          ;    state is crawling and watching. it can be attracted
                          ;    by a dance nearby
                          ; 2. dancing: same as students'
                          ; 3. visiting: same as students'
                          ; 4. returning: same as students'
                          ; 5. recovering: a robot needs a certain period of time
                          ;    after a dance to rejoin the recruiting process
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;SETUP;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to startup
  hubnet-reset
  set-default-shape students "bee"
  set-default-shape robots "beebot"
  listen-clients
end

to setup
  clear-patches            ; initialize the world. didn't use clear-all to keep the HubNet connection
  clear-drawing
  clear-output
  clear-all-plots
  ask robots [ die ]
  setup-patches
  ask sites [ die ]
  setup-sites
  ask robots [ die ]
  make-robots
  listen-clients
  ask students [
    reset-students
    send-info-to-clients
  ]
  set history []
  reset-ticks
end

to make-robots
  create-robots number-of-robots [
    set color gray
    set supported-site nobody
    set state "chilling"
    fd random-float 4
  ]
end

to setup-patches
  ask patches [
    ifelse dance-floor? [
      set pcolor scale-color brown (distancexy 0 0) 0 8    ; darker center
    ] [
      set pcolor scale-color green (distancexy 0 0) 0 25   ; green gets darker towards center
    ]
  ]
end

to-report dance-floor? ; patch and turtle reporter
  report [ distancexy 0 0 ] of patch-at 0 0 < 4            ; bees only dance within the distance of 4 of the center
end

to reset-students
  hubnet-send-follow user-id self student-vision-radius    ; apply field of vision constrains
  setxy random-float 5 random-float 5
  set state "exploring"
  set supported-site nobody
  set dances-made 0
  set dance-length 0
  set recruited 0
  set message-content ""
  set color gray
end

to setup-sites
  create-sites number-of-sites [
    set color gray
    set shape "box"
    set size 2
  ]

  ; a pre-defined color list, which is color-blind safe
  let color-list [ 95 15 105 25 125 85 135 115 75 ]

  ; a pre-defined quality "seed" list to calculate quality-list, which
  ; ensures the first 4 sites have sufficient quality difference
  let input-quality-list [ 85 55 35 5 75 15 65 25 45 80 ]

  ; added randomness to the seed list and made it quadratic to
  ; amplify differences between better quality sites
  let quality-list map [ n -> round (((n + random 10 - 4) / 10) ^ 2) ] input-quality-list

  (foreach (sort sites) (n-of count sites color-list) (n-of count sites quality-list) [ [the-site the-color the-quality] ->
    ask the-site [                  ; ask the next site in the sorted list of sites
      let mycolor the-color          ; assign a color from the color list
      set true-color mycolor
      set quality the-quality          ; assign a quality from the quality list
    ]
  ])
  place-sites
end

to place-sites
  ; pick either xcor or ycor and set it as random first, and then set the other coordinate close to the edge of the world.
  ask sites [
    ifelse random 2 = 0 [
      set xcor min-pxcor + 1 + random (world-height - 2)
      set ycor one-of (list (max-pycor - 1) (min-pycor + 1))
    ] [
      set ycor min-pycor + 1 + random (world-width - 2)
      set xcor one-of (list (min-pxcor + 1) (max-pxcor - 1))
    ]
  ]
  ; if the smallest distance between two sites are less than 10, re-place sites
  if any? sites with [ min [ distance myself ] of other sites < 10 ] [
    place-sites
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;RUN TIME ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  listen-clients

  ask students with [ state = "exploring" ] [explore]
  ask students with [ state = "visiting" ] [ visit ]
  ask students with [ state = "returning" ] [ return ]
  ask students [ show-message ]

  dance

  ask robots with [ state = "chilling" ] [
    robot-move
    robot-follow
  ]
  ask robots with [ state = "visiting" ] [ visit ]
  ask robots with [ state = "returning" ] [ return ]
  ask robots with [ state = "recovering" ] [ recover ]

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;BEE PROCEDURES;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to explore; student procedure
  if any? sites in-radius 2 [
    ifelse color = gray [
      set supported-site one-of sites in-radius 2
      ask supported-site [ set color true-color ]
      set bee-timer [ quality ] of supported-site
      set color [ color ] of supported-site
      set dance-length 0
      hubnet-send user-id "target-quality" [ quality ] of supported-site
      hubnet-send user-id "interest-in-target" bee-timer
    ] [
      ; if the bee's color is not gray, which means it has a commitment
      set message-content "Dance before you can discover another site"
    ]
  ]
end

to recover ; robot procedure
  ifelse bee-timer > 0 [
    set bee-timer bee-timer - 1
  ] [
    set state "chilling"
  ]
end

to visit ; bee procedure
  ifelse distance destination < 1 [
    set supported-site destination
    set bee-timer [ quality ] of supported-site
    set color ([ color ] of supported-site)
    set state "returning"
    set destination one-of patches with [dance-floor?]
    if is-student? self [
      hubnet-send user-id "target-quality" [ quality ] of supported-site
      hubnet-send user-id "interest-in-target" bee-timer
      hubnet-send user-id "dance-length" 0
      hubnet-send user-id "bees-recruited" 0
    ]
  ] [
    fd 1
    face destination
  ]
end

to return ; bee procedure
  ifelse distance destination > 1 [
    face destination fd 1
  ] [
    move-to destination
    ifelse breed = robots [
      set state "dancing"
    ] [
      set state "exploring"
    ]
  ]
end

to robot-move ; robot procedure
  ifelse dance-floor? [
    ; if in swarm, crawl a little bit
    rt random 30 - 15
    fd random-float 0.1
  ] [
    ; if on grass, head towards dance floor
    facexy 0 0
    fd 0.1
  ]
end

to robot-follow ; robot procedure
  let bees (turtle-set students robots)
  let dancing-bees-in-sight (other bees with [ state = "dancing" ] in-cone 1 30)
  if any? dancing-bees-in-sight[
    ; if any other dancing bee is in the cone of vision
    let bee-watched one-of dancing-bees-in-sight
    if random 100 < [ [ quality ] of supported-site ] of bee-watched [
      set destination [ supported-site ] of bee-watched
      set color [ color ] of destination
      ask bee-watched [ set recruited recruited + 1 ]
      set state "visiting"
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;DANCE;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to dance ; bee procedure
  let dancers (turtle-set students robots) with [ state = "dancing" and bee-timer > 0 ]
  foreach [ 0 1 0 -1 0 ] [ n ->
    ask dancers [
      set heading (towards supported-site) + ([ quality ] of supported-site * n)
    ]
    display
    ; displays a simplified waggle dance with 5 states instead of the figure-8 waggle path
    ; the higher the quality of the supported site, the move vigorous the dance looks.
  ]
  ask dancers [
    set bee-timer bee-timer - 1
    if breed = students [
      set dance-length dance-length + 1
      hubnet-send user-id "interest-in-target" bee-timer
      hubnet-send user-id "dance-length" dance-length
      hubnet-send user-id "bees-recruited" recruited
      hubnet-send user-id "ticks" ticks
    ]
  ]
  ask students with [ done-dancing? ] [
    set state "exploring"
    set dances-made dances-made + 1
    hubnet-send user-id "dances-made" dances-made
    hubnet-send user-id "ticks" ticks
    let summary-list (list ticks [ quality ] of supported-site recruited)
    hubnet-send user-id "summary" summary-list
    set summary-list fput user-id summary-list         ; adding user id to the list
    set history lput summary-list history              ; adding personal history to the global history
    set recruited 0
    set color grey
    set destination supported-site
    set supported-site nobody
  ]
  ask robots with [ done-dancing? ] [
    set state "recovering"
    set bee-timer 20
    set color grey
    set destination nobody
    set supported-site nobody
  ]
end

to-report done-dancing?
  report state = "dancing" and bee-timer = 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;HubNet Procedures;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to listen-clients
  while [ hubnet-message-waiting? ] [
    hubnet-fetch-message
    ifelse hubnet-enter-message? [
      create-new-student
    ] [
      ifelse hubnet-exit-message? [
        remove-student
      ] [
        ask students with [ user-id = hubnet-message-source ] [
          execute-command hubnet-message-tag
        ]
      ]
    ]
  ]
end

to create-new-student
  create-students 1 [
    set user-id hubnet-message-source
    hubnet-send-follow user-id self student-vision-radius
    set state "exploring"
    set color gray
  ]
end

to remove-student
  ask students with [ user-id = hubnet-message-source ] [ die ]
end

to execute-command [ command ]
  if command = "dance" [ command-dance ]
  if command = "revisit" [ command-revisit ]
  if command = "give-up" [ command-give-up ]
  if command = "View" [ command-click ]

  if member? command [ "up" "down" "left" "right" ] [
    if state = "dancing" [ set message-content "Move after dance" ]
    if state = "visiting" or state = "returning" [
      set message-content "Move after returning to the swarm"
    ]
    if state = "exploring" [
      if command = "up"   [ execute-move   0 stop ]
      if command = "down" [ execute-move 180 stop ]
      if command = "right"[ execute-move  90 stop ]
      if command = "left" [ execute-move 270 stop ]
    ]
  ]
end

to execute-move [ new-heading ]
  set heading new-heading
  fd 1
end

to command-dance
  if state = "dancing" [
    set message-content "You are already dancing"
  ]
  if state = "returning" or state = "visiting" [
    set message-content "Dance after returning to the swarm"
  ]
  if state = "exploring" [
    ifelse dance-floor? [
      ifelse color = grey [ ;white [
        set message-content "Visit or revisit a site to dance for it"
      ] [
        set state "dancing"
        set dance-length 0
      ]
    ] [
      set message-content "You can only dance in the swarm."
    ]
  ]
end

to command-revisit
  if state = "dancing" [
    set message-content "Revisit after this dance"
  ]
  if state = "revisiting" [
    set message-content "You are revisiting a hive"
  ]

  if state = "exploring" [
    ifelse is-site? destination [
      set state "visiting"
      set color [ color ] of destination
    ] [
      ifelse is-patch? destination [
        set message-content "please dance before revisiting"
      ] [
        set message-content "I don't know which site to revisit"
      ]
    ]
  ]
end

to command-give-up
  if state = "dancing" [
    set message-content "Give up before a dance"
  ]
  if state = "returning" or state = "visiting" [
    set message-content "Give up when you are in the swarm"
  ]
  if state = "exploring" [
    ifelse dance-floor? [
      ifelse supported-site != nobody [
        ifelse [ quality ] of supported-site < 50 [
          set supported-site nobody
          set color grey
          hubnet-send user-id "target-quality" 0
          hubnet-send user-id "interest-in-target" 0
        ] [
          set message-content "You can't give up a good site"
        ]
      ] [
        set message-content "Give up a site after it's found"
      ]
    ] [
      set message-content "Return to the swarm to give up"
    ]
  ]
end

to command-click
  if state = "dancing" [
    set message-content "Click a dancer after dancing to follow it"
  ]
  if state = "visiting" or state = "returning" [
    set message-content "Click a dancer after returning to the swarm"
  ]
  if state = "exploring" [
    ifelse is-patch? destination [
      set message-content "Dance before following another dancer"
    ] [
      let close-enough? false
      let bees (turtle-set students robots)
      let choice min-one-of bees [
        distancexy item 0 hubnet-message item 1 hubnet-message
      ]
      ask choice [
        ;; click is close enough to the chosen bee, but a student
        ;; should only be able to click a dancer nearby.
        if distancexy item 0 hubnet-message item 1 hubnet-message < 0.5 [
          set close-enough? true ;; clicking anywhere gives a message asking to click on a dancer
        ]
      ]
      if close-enough? [
        ifelse [ state ] of choice =  "dancing" [
          set destination [ supported-site ] of choice
          hubnet-send user-id "target-quality" "figuring out..."
          hubnet-send user-id "interest-in-target" "figuring out..."
          set state "visiting"
          set color [color] of destination
        ] [
          set message-content "Click a DANCING bee nearby to follow it"
        ]
      ]
    ]
  ]
end

to send-info-to-clients ;; turtle procedure
  hubnet-send user-id "target-quality" 0
  hubnet-send user-id "dances-made" 0
  hubnet-send user-id "dance-length" 0
  hubnet-send user-id "interest-in-target" 0
  hubnet-send user-id "summary" ""
  hubnet-send user-id "ticks" 0
  hubnet-send user-id "bees-recruited" 0
end

to show-message
  hubnet-send user-id "Message" message-content
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;SAVE FILE;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to save-history
  csv:to-file filename history
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
699
500
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
-18
18
-18
18
1
1
1
ticks
30.0

BUTTON
14
10
94
58
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
114
10
195
58
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
10
177
195
210
student-vision-radius
student-vision-radius
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
10
95
195
128
number-of-sites
number-of-sites
2
9
9.0
1
1
NIL
HORIZONTAL

MONITOR
12
265
195
310
Best site discovered?
[ color = true-color ] of max-one-of sites [ quality ]
17
1
11

PLOT
707
10
1014
263
Current Sites Support
Sites
Bee Count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 1 -16777216 true "set-plot-x-range 0 count sites\nset-plot-y-range 0 10\nset-histogram-num-bars count sites" "let sites-by-quality sort-on [ quality ] sites ; assemble a sorted list of sites by quality\nlet supporting-bees (turtle-set students robots) with [ is-site? supported-site ]\nhistogram [ position supported-site sites-by-quality ] of supporting-bees"

PLOT
708
268
1015
521
Sites Support Over Time
Ticks
Bee Count
0.0
10.0
0.0
10.0
true
false
"ask sites [\n  create-temporary-plot-pen (word self)\n  set-plot-pen-color true-color\n]" "ask sites [\n  set-current-plot-pen (word self)\n  plot count (turtle-set students robots) with [ supported-site = myself ]\n]"
PENS

INPUTBOX
14
407
193
467
filename
history.csv
1
0
String

BUTTON
14
473
193
519
save history
save-history
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
10
136
195
169
number-of-robots
number-of-robots
0
100
100.0
10
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

BeeSmart HubNet model is part of the BeeSmart Curricular Unit. It is the HubNet version of the BeeSmart Hive Finding model in NetLogo Models library. For detailed description of honeybees hive finding phenomenon, please see the info tab of the BeeSmart Hive Finding model.

Unlike the BeeSmart Hive Finding model, the BeeSmart HubNet model allows students to see the phenomenon from bees’ perspective. Each student uses a HubNet client to control a bee. All the bees live in the same virtual space on the teacher’s server. In this way, students can interact with the environment and with each other, and experience the bees' physical and cognitive limitations.

## HOW IT WORKS

The model contains three types of agents: students, robots, and sites.

- Students are scouts that are controlled by students through HubNet clients. In the model, they are bee-shaped agents with yellow noses and white wing edges.

- Robots are automated scouts that follow similar rules as human players. They look exactly like the students, except that their noses are grey.

- Sites are potential targets that the swarm tries to pick. They are box-shaped agents that never move. At each setup, they are placed randomly in the view.

A color gradient is used in the view where the closer to the center, the darker the color. At the very center, the patches are brown, which indicates the location of the swarm.

At each tick, a robot moves around randomly and sees if there is any dancing agent within one step in its 30 degrees cone of vision. If there is, the robot may follow the dance based on a probability that is proportional to the interest (the value of the `bee-timer` variable) of the dancer. If the robot decides to follow the dance, it targets the hive site advocated by the dancer and flies out to evaluate it. When arrived at a site, the robot adjusts its interest according to the quality of the site and fly back to the swarm to dance for it.

Students generally follow the same routine but can make a few decisions. When the simulation starts, students need to "fly" out of the swarm using the direction buttons in order to discover new potential hive sites. When stumbling upon a site, students can go back to the swarm and press the dance button to perform dances in order to promote the hive they discovered. They can also give up a dance for a low quality site when they return to the swarm. As a bee dances, her interest declines. When the interest reaches zero, the bee stops dancing and turns gray. At this point, students can choose if they want to fly out and explore another hive or to stay in the swarm and follow other bees’ dances. They can follow other dances by clicking a nearby dancing bee. Once a dancer is clicked on, the student automatically flies out to the site the dance advocates, inspects the site, and flies back to the swarm. Then the student can decide whether to dance for the site, give up the dance, or follow another dance.

## HOW TO USE IT

When the model is launched, ask clients to join. After clients have joined the model, set the number of sites and radius _before_ clicking the setup button. Then click GO.

SETUP initializes the model, adding hive sites into the view.

GO starts the model. If clients joined after SETUP was clicked, They can only see themselves after GO is clicked.

SAVE HISTORY saves the history of all students' dances to a CSV file, the name of which is specified in the FILENAME input box. When used in a classroom, the teacher can save the history as a CSV file and then use Excel to open it in order to provide students with detailed data for analyzing the phenomenon.

NUMBER-OF-SITES determines how may hive sites to put in the view.

NUMBER-OF-ROBOTS determines how may robots to put in the view.

STUDENT-VISION-RADIUS determines how far the clients can see from their perspective.

The CURRENT SITE SUPPORT plot shows a histogram of the current support. The leftmost bar shows how many dancing bees are supporting the site with the lowest quality, and the rightmost, the highest, with everything else in between.

The SITE SUPPORT OVER TIME plot shows a line graph detailing the change of support over time.

On the client view:

MESSAGE shows suggestions when students attempt operations that are not allowed by the rules in this world.

DANCE, GIVE-UP, and REVISIT are only effective when a student is in the swarm (at the center brown area). A student can dance only after she inspected a site; can only give up when the quality of the site visited is less than 50; and can revisit a site only after the bee the student controls danced at least once for the site.

TARGET-QUALITY is the objective quality of the site the bee just inspected. (How bees assess the quality of a potential site is not included in this model. For more information, see Seeley 2010)

INTEREST-IN-TARGET is the interest or the extent of the bee's enthusiasm towards the target.

DANCE-LENGTH is the length of the current dance.

BEES-RECRUITED is the number of bees recruited with the current round of dance.

DANCES-MADE are rounds of dances made.

TICKS is the time elapsed in the virtual world. The TICKS monitor on the clients is only updated when a student is dancing. It stops when a dance is finished, showing when the dance stopped since the model started to run

SUMMARY shows the summary of the just finished dance. It contains three values: [T Q R], where T means ticks, or the time when the last round of dance finished; Q means target quality, by which the target that the bee just danced for can be identified; and R means the number of bees the dance has recruited.

## THINGS TO NOTICE

As the model runs, notice the change in the histogram. The leftmost bar represents the dances that support of the lowest quality site, while the rightmost bar represents the dances for the highest. Sites are discovered in random order, so the bars start out with random heights. However, as the process continues, the bars gradually shift to the right, showing a convergence of support to the highest quality site.

The SITES SUPPORT OVER TIME plot shows this dynamic over time.

## THINGS TO TRY

Play this simulation with at least 3 people. A group of 10 would be ideal because is provides enough diversity to imitate the scout bees in a beehive. Try to start with a small number of hives (around 4 to 5) but a larger vision radius (5 to 7). Talk to your partners as you play. After you are familiar with the model, reduce the vision radius and play again. You can also increase the number of hives to increase the difficulty. Finally, use a vision radius of 1 and play the model without talking to any of your partners. This way, you can experience bees' physical and cognitive limitations. After each round of play, look at the plots on the server and debrief what you and your partners did, and what happened.

## EXTENDING THE MODEL

The waggle dances in this model are represented by agents turning left and right. One possibility for extending the model is to use the actual waggle dance pattern (the figure-8 dance, included in the BeeSmart Hive Finding model) to make the dances more realistic and informative.

`hubnet-send-watch` and `hubnet-send-follow` can be used to allow students to follow a certain bee with better visual effects.

Currently, the bees dance one interest unit per tick. It would be better if the dance could expand across multiple ticks to create more detailed visual effects of the dances.

## NETLOGO FEATURES

This model uses the HubNet Architecture, especially the perspective reset feature (`hubnet-send-follow`). Notice that the layers of agents are determined by the order in which their breeds are declared. Agents of breeds declared later are on top of those declared earlier.

This model also uses dynamic plots. The histogram and the line graph are dynamically generated to show current and historical support of sites by counting the number of bees that support each target.

## RELATED MODELS

BeeSmart Hive Finding

## CREDITS AND REFERENCES

Seeley, T. D. (2010). Honeybee democracy. Princeton, NJ: Princeton University Press.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Guo, Y. and Wilensky, U. (2016).  NetLogo BeeSmart HubNet model.  http://ccl.northwestern.edu/netlogo/models/BeeSmartHubNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the HubNet software as:

* Wilensky, U. & Stroup, W. (1999). HubNet. http://ccl.northwestern.edu/netlogo/hubnet.html. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 Cite: Guo, Y. -->
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

bee
true
1
Polygon -2674135 true true 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -1184463 true false 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

beebot
true
1
Polygon -2674135 true true 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true false 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -7500403 false 144 100 70 87
Line -7500403 false 70 87 45 87
Line -7500403 false 45 86 26 97
Line -7500403 false 26 96 22 115
Line -7500403 false 22 115 25 130
Line -7500403 false 26 131 37 141
Line -7500403 false 37 141 55 144
Line -7500403 false 55 143 143 101
Line -7500403 false 141 100 227 138
Line -7500403 false 227 138 241 137
Line -7500403 false 241 137 249 129
Line -7500403 false 249 129 254 110
Line -7500403 false 253 108 248 97
Line -7500403 false 249 95 235 82
Line -7500403 false 235 82 144 100

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
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
300
25
729
454
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
-18
18
-18
18

BUTTON
104
82
187
115
up
NIL
NIL
1
T
OBSERVER
NIL
W

BUTTON
104
129
188
162
down
NIL
NIL
1
T
OBSERVER
NIL
S

BUTTON
9
129
87
162
left
NIL
NIL
1
T
OBSERVER
NIL
A

BUTTON
205
129
284
162
right
NIL
NIL
1
T
OBSERVER
NIL
D

BUTTON
9
185
88
218
dance
NIL
NIL
1
T
OBSERVER
NIL
Q

BUTTON
205
185
284
218
revisit
NIL
NIL
1
T
OBSERVER
NIL
R

MONITOR
11
339
142
388
dances-made
NIL
3
1

MONITOR
11
291
142
340
dance-length
NIL
3
1

MONITOR
11
243
142
292
target-quality
NIL
3
1

MONITOR
8
26
283
75
Message
NIL
3
1

MONITOR
156
243
285
292
interest-in-target
NIL
3
1

MONITOR
11
387
285
436
summary
NIL
3
1

TEXTBOX
14
441
266
469
[T    Q    R] : ticks, target-quality, recruited
11
0.0
1

MONITOR
156
339
285
388
ticks
NIL
3
1

MONITOR
156
291
285
340
bees-recruited
NIL
3
1

BUTTON
104
185
188
218
give-up
NIL
NIL
1
T
OBSERVER
NIL
G

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
