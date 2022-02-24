breed [ sites site ]
breed [ scouts scout ]

sites-own [
  quality discovered?
  scouts-on-site
]
scouts-own [

  my-home          ; a bee's original position
  next-task        ; the code block a bee is running
  task-string      ; the behavior a bee is displaying
  bee-timer        ; a timer keeping track of the length of the current state
                   ;   or the waiting time before entering next state
  target           ; the hive that a bee is currently focusing on exploring
  interest         ; a bee's interest in the target hive
  trips            ; times a bee has visited the target

  initial-scout?   ; true if it is an initial scout, who explores the unknown horizons
  no-discovery?    ; true if it is an initial scout and fails to discover any hive site
                   ;   on its initial exploration
  on-site?         ; true if it's inspecting a hive site
  piping?          ; a bee starts to "pipe" when the decision of the best hive is made.
                   ;   true if a be observes more bees on a certain hive site than the
                   ;   quorum or when it observes other bees piping

  ; dance related variables:

  dist-to-hive     ; the distance between the swarm and the hive that a bee is exploring
  circle-switch    ; when making a waggle dance, a bee alternates left and right to make
                   ;   the figure "8". circle-switch alternates between 1 and -1 to tell
                   ;   a bee which direction to turn.
  temp-x-dance     ; initial position of a dance
  temp-y-dance
]

globals [
  color-list       ; colors for hives, which keeps consistency among the hive colors, plot
                   ;   pens colors, and committed bees' colors
  quality-list     ; quality of hives

  ; visualization:

  show-dance-path? ; dance path is the circular patter with a zigzag line in the middle.
                   ;   when large amount of bees dance, the patterns overlaps each other,
                   ;   which makes them hard to distinguish. turn show-dance-path? off can
                   ;   clear existing patterns
  scouts-visible?  ; you can hide scouts and only look at the dance patterns to avoid
                   ;   distraction from bees' dancing movements
  watch-dance-task ; a list of tasks
  discover-task
  inspect-hive-task
  go-home-task
  dance-task
  re-visit-task
  pipe-task
  take-off-task
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;setup;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  setup-hives
  setup-tasks
  setup-bees
  set show-dance-path? true
  set scouts-visible? true
  reset-ticks
end

to setup-hives
  set color-list [ 97.9 94.5 57.5 63.8 17.6 14.9 27.5 25.1 117.9 114.4 ]
  set quality-list [ 100 75 50 1 54 48 40 32 24 16 ]
  ask n-of hive-number patches with [
    distancexy 0 0 > 16 and abs pxcor < (max-pxcor - 2) and
    abs pycor < (max-pycor - 2)
  ] [
    ; randomly placing hives around the center in the
    ; view with a minimum distance of 16 from the center
    sprout-sites 1 [
      set shape "box"
      set size 2
      set color gray
      set discovered? false
    ]
  ]
  let i 0 ; assign quality and plot pens to each hive
  repeat count sites [
    ask site i [
      set quality item i quality-list
      set label quality
    ]
    set-current-plot "on-site"
    create-temporary-plot-pen word "site" i
    set-plot-pen-color item i color-list
    set-current-plot "committed"
    create-temporary-plot-pen word "target" i
    set-plot-pen-color item i color-list
    set i i + 1
  ]
end

to setup-bees
  create-scouts 100 [
    fd random-float 4 ; let bees spread out from the center
    set my-home patch-here
    set shape "bee"
    set color gray
    set initial-scout? false
    set target nobody
    set circle-switch 1
    set no-discovery? false
    set on-site? false
    set piping? false
    set next-task watch-dance-task
    set task-string "watching-dance"
  ]
  ; assigning some of the scouts to be initial scouts.
  ; bee-timer here determines how long they will wait
  ; before starting initial exploration
  ask n-of (initial-percentage) scouts [
    set initial-scout? true
    set bee-timer random 100
  ]
end


to setup-tasks
  watch-dance
  discover
  inspect-hive
  go-home
  dance
  re-visit
  pipe
  take-off
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;watch-dance;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to watch-dance
  set watch-dance-task [ ->
    if count scouts with [piping?] in-radius 3 > 0 [
      ; if detecting any piping scouts in the swarm, pipe too
      set target [target] of one-of scouts with [piping?]
      set color [color] of target
      set next-task pipe-task
      set task-string "piping"
      set bee-timer 20
      set piping? true
    ]
    move-around
    if initial-scout? and bee-timer < 0 [
      ; a initial scout, after the waiting period,
      ; takes off to discover new hives.
      ; it has limited time to do the initial exploration,
      ; as specified by initial-explore-time.
      set next-task discover-task
      set task-string "discovering"
      set bee-timer initial-explore-time
      set initial-scout? false
    ]
    if not initial-scout? [
      ; if a bee is not a initial scout (either born not to be
      ; or lost its initial scout status due to the failure of
      ; discovery in its initial exploration), it watches other
      ; bees in its cone of vision
      if bee-timer < 0 [
        ; idle bees have bee-timer less than 0, usually as the
        ; result of reducing bee-timer from executing other tasks,
        ; such as dance
        if count other scouts in-cone 3 60 > 0 [
          let observed one-of scouts in-cone 3 60
          if [ next-task ] of observed = dance-task [
            ; randomly pick one dancing bee in its cone of vision
            ; random x < 1 means a chance of 1 / x. in this case,
            ; x = ((1 / [interest] of observed) * 1000), which is
            ; a function to correlate interest, i.e. the enthusiasm
            ; of a dance, with its probability of being followed:
            ; the higher the interest, the smaller 1 / interest,
            ; hence the smaller x, and larger 1 / x, which means
            ; a higher probability of being seen.
            if random ((1 / [interest] of observed) * 1000) < 1 [
              ; follow the dance
              set target [target] of observed
              ; use white to a bee's state of having in mind
              ; a target  without having visited it yet
              set color white
              set next-task re-visit-task
              ; re-visit could be an initial scout's subsequent
              ; visits of a hive after it discovered the hive,
              ; or it could be a non-initial scout's first visit
              ; and subsequent visits to a hive (because non-scouts
              ; don't make initial visit, which is defined as the
              ; discovering visit).
              set task-string "revisiting"
            ]
          ]
        ]
      ]
    ]
    ; reduce bees' waiting time by 1 tick
    set bee-timer bee-timer - 1
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;discover;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to discover
  set discover-task [ ->
    ifelse bee-timer < 0 [
      ; if run out of time (a bee has limited time to make initial
      ; discovery), go home, and admit no discovery was made
      set next-task go-home-task
      set task-string "going-home"
      set no-discovery? true
    ] [
      ; if a bee finds sites around it (within a distance of 3) on its way
      ifelse count sites in-radius 3 > 0 [
        ; then randomly choose one to focus on
        let temp-target one-of sites in-radius 3
        ; if this one hive was not discovered by other bees previously
        ifelse not [discovered?] of temp-target [
          ; commit to this hive
          set target temp-target
          ask target [
            ; make the target as discovered
            set discovered? true
            set color item who color-list
          ]
          ; collect info about the target
          set interest [ quality ] of target
          ; the bee changes its color to show its commitment to this hive
          set color [ color ] of target
          set next-task inspect-hive-task
          set task-string "inspecting-hive"
          ; will inspect the target for 100 ticks
          set bee-timer 100
        ] [
          ; if no hive site is around, keep going forward
          ; with a random heading between [-60, 60] degrees
          rt (random 60 - random 60) proceed
          set bee-timer bee-timer - 1
        ]
      ] [
        rt (random 60 - random 60) proceed
      ]
      set bee-timer bee-timer - 1
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;inspect-hive;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to inspect-hive
  set inspect-hive-task [ ->
    ; after spending certain time (as specified in bee-timer, see the
    ; last comment of this task) on inspecting hives, they fly home.
    ifelse bee-timer < 0 [
      set next-task go-home-task
      set task-string "going-home"
      set on-site? false
      set trips trips + 1
    ] [
      ; while on inspect-hive task,
      if distance target > 2 [
        face target fd 1 ; a bee flies to its target hive
      ]
      set on-site? true
      ; if it counts more bees than what the quorum specifies, it starts to pipe.
      let nearby-scouts scouts with [ on-site? and target = [ target ] of myself ] in-radius 3
      if count nearby-scouts > quorum [
        set next-task go-home-task
        set task-string "going-home"
        set on-site? false
        set piping? true
      ]
      ; this line makes the visual effect of a bee showing up and disappearing,
      ; representing the bee checks both outside and inside of the hive
      ifelse random 3 = 0 [ hide-turtle ] [ show-turtle ]
      ; a bee knows how far this hive is from its swarm
      set dist-to-hive distancexy 0 0
      ; the bee-timer keeps track of how long the bee has been inspecting
      ; the hive. It lapses as the model ticks. it is set in either the
      ; discover task (100 ticks) or the re-visit task (50 ticks).
      set bee-timer bee-timer - 1
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;go-home;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go-home
  set go-home-task [ ->
    ifelse distance my-home < 1 [ ; if back at home
      ifelse no-discovery? [
        ; if the bee is an initial scout that failed to discover a hive site
        set next-task watch-dance-task
        set task-string "watching-dance"
        set no-discovery? false
        ; it loses its initial scout status and becomes a
        ; non-scout, who watches other bees' dances
        set initial-scout? false
      ] [
        ifelse piping? [
          ; if the bee saw enough bees on the target site,
          ; it prepares to pipe for 20 ticks
          set next-task pipe-task
          set task-string "piping"
          set bee-timer 20
        ] [
          ; if it didn't see enough bees on the target site,
          ; it prepares to dance to advocate it. it resets
          ; the bee-timer to 0 for the dance task
          set next-task dance-task
          set task-string "dancing"
          set bee-timer 0
        ]
      ]
    ] [
      face my-home proceed
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;dance;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; bees dance multiple rounds for a good site. After visiting the site for the first
; time, they return to the swarm and make a long dance for it enthusiastically, and
; then go back to visit the site again. When they return, they would dance for it
; for another round, with slightly declined length and enthusiasm. such cycle repeats
; until the enthusiasm is completely gone. in the code below, interest represents
; a bee's enthusiasm and the length of the dance. trips keep track of how many times
; the bee has visited the target. after each revisiting trip, the interest declines
; by [15, 19], as represented by (15 + random 5).
; interest - (trips - 1) * (15 + random 5) determines how long a bee will dance after
; each trip. e.g. when a hive is first discovered (trips = 1), if the hive quality is
; 100, i.e. the bee's initial interest in this hive is 100, it would dance
; 100 - (1 - 1) * (15 + random 5) = 100. However, after 100 ticks of dance, the bee's
; interest in this hive would reduce to [85,81].
; Assuming it declined to 85, when the bee dances for the hive a second time, it
; would only dance between 60 to 70 ticks: 85 - (2 - 1) * (15 + random 5) = [70, 66]
to dance
  set dance-task [ ->
    ifelse count scouts with [piping?] in-radius 3 > 0 [
      ; while dancing, if detecting any piping bee, start piping too
      pen-up
      set next-task pipe-task
      set task-string "piping"
      set bee-timer 20
      set target [target] of one-of scouts with [piping?]
      set color [color] of target
      set piping? true
    ] [
      if bee-timer > interest - (trips - 1) * (15 + random 5) and interest > 0 [
        ; if a bee dances longer than its current interest, and if it's still
        ; interested in the target, go to revisit the target again
        set next-task re-visit-task
        set task-string "revisiting"
        pen-up
        set interest interest - (15 + random 5) ; interest decline by [15,19]
        set bee-timer 25                        ; revisit 25 ticks
      ]
      if bee-timer > interest - (trips - 1) * (15 + random 5) and interest <= 0 [
        ; if a bee dances longer than its current interest, and if it's no longer
        ; interested in the target, as represented by interest <=0, stay in the
        ; swarm, rest for 50 ticks, and then watch dance
        set next-task watch-dance-task
        set task-string "watching-dance"
        set target nobody
        set interest 0
        set trips 0
        set color gray
        set bee-timer 50
      ]
      if bee-timer <=  interest - (trips - 1) * (15 + random 5) [
        ; if a bee dances short than its current interest, keep dancing
        ifelse interest <= 50 and random 100 < 43 [
          set next-task re-visit-task
          set task-string "revisiting"
          set interest interest - (15 + random 5)
          set bee-timer 10
        ] [
          ifelse show-dance-path? [pen-down][pen-up]
          repeat 2 [
            waggle
            make-semicircle]
        ]
      ]
      set bee-timer bee-timer + 1
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;re-visit;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to re-visit
  set re-visit-task [ ->
    ifelse bee-timer > 0 [
      ; wait a bit after the previous trip
      set bee-timer bee-timer - 1
    ] [
      pen-up
      ifelse distance target < 1 [
        ; if on target, learn about the target
        if interest = 0 [
          set interest [ quality ] of target
          set color [ color ] of target
        ]
        set next-task inspect-hive-task
        set task-string "inspecting-hive"
        set bee-timer 50
      ] [
        ; if hasn't reached target yet (distance > 1), keep flying
        proceed
        face target
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;pipe;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to pipe
  set pipe-task [ ->
    move-around
    if count scouts with [ piping? ] in-radius 5 = count scouts in-radius 5 [
      ; if every surrounding bee is piping, wait a bit (20 ticks as
      ; set in the watch-dance procedure) for bees to come back to
      ; the swarm from the hive before taking off
      set bee-timer bee-timer - 1
    ]
    if bee-timer < 0 [
      set next-task take-off-task
      set task-string "taking-off"
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;take-off;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to take-off
  set take-off-task [ ->
    ifelse distance target > 1 [
      face target fd 1
    ] [
      set on-site? true
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;run-time;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  if all? scouts [ on-site? ] and length remove-duplicates [ target ] of scouts = 1 [
  ; if all scouts are on site, and they all have the same target hive, stop.
    stop
  ]
  ask scouts [ run next-task ]
  plot-on-site-scouts
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;utilities;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to make-semicircle
  ; calculate the size of the semicircle. 2600 and 5 (in pi / 5) are numbers
  ; selected by trial and error to make the dance path look good
  let num-of-turns 1 / interest * 2600
  let angle-per-turn 180 / num-of-turns
  let semicircle 0.5 * dist-to-hive * pi / 5
  if circle-switch = 1 [
    face target lt 90
    repeat num-of-turns [
      lt angle-per-turn
      fd (semicircle / 180 * angle-per-turn)
    ]
  ]
  if circle-switch = -1 [
    face target rt 90
    repeat num-of-turns [
      rt angle-per-turn
      fd (semicircle / 180 * angle-per-turn)
    ]
  ]

  set circle-switch circle-switch * -1
  setxy temp-x-dance temp-y-dance
end

to waggle
  ; pointing the zigzag direction to the target
  face target
  set temp-x-dance xcor set temp-y-dance ycor
  ; switch toggles between 1 and -1, which makes a bee
  ; dance a zigzag line by turning left and right
  let waggle-switch 1
  ; first part of a zigzag line
  lt 60
  fd .4
  ; correlates the number of turns in the zigzag line with the distance
  ; between the swarm and the hive. the number 2 is selected by trial
  ; and error to make the dance path look good
  repeat (dist-to-hive - 2) / 2 [
    ; alternates left and right along the diameter line that points to the target
    if waggle-switch = 1 [rt 120 fd .8]
    if waggle-switch = -1 [lt 120 fd .8]
    set waggle-switch waggle-switch * -1
  ]
  ; finish the last part of the zigzag line
  ifelse waggle-switch = -1 [lt 120 fd .4][rt 120 fd .4]
end

to proceed
  rt (random 20 - random 20)
  if not can-move? 1 [ rt 180 ]
  fd 1
end

to move-around
  rt (random 60 - random 60) fd random-float .1
  if distancexy 0 0 > 4 [facexy 0 0 fd 1]
end

to plot-on-site-scouts
  let i 0
  repeat count sites [
    set-current-plot "on-site"
    set-current-plot-pen word "site" i
    plot count scouts with [on-site? and target = site i]

    set-current-plot "committed"
    set-current-plot-pen word "target" i
    plot count scouts with [target = site i]

    set i i + 1
  ]
end

to show-hide-dance-path
  if show-dance-path? [
    clear-drawing
  ]
  set show-dance-path? not show-dance-path?
end

to show-hide-scouts
  ifelse scouts-visible? [
    ask scouts [hide-turtle]
  ]
  [
    ask scouts [show-turtle]
  ]
  set scouts-visible? not scouts-visible?
end


; Copyright 2014 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
933
558
-1
-1
11.0
1
10
1
1
1
0
0
0
1
-32
32
-24
24
1
1
1
ticks
120.0

BUTTON
5
190
201
226
Setup
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
5
235
200
275
Go
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
10
201
43
hive-number
hive-number
4
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
5
50
201
83
initial-percentage
initial-percentage
5
25
12.0
1
1
NIL
HORIZONTAL

PLOT
5
415
201
579
piping-scouts
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count scouts with [piping?]"

PLOT
942
222
1252
426
on-site
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

PLOT
942
426
1252
579
watching v.s. working
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"watching bees" 1.0 0 -1398087 true "" "plot count scouts with [task-string = \"watching-dance\"]"
"working bees" 1.0 0 -7025278 true "" "plot count scouts - count scouts with [task-string = \"watching-dance\"]"

PLOT
942
10
1252
222
committed
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS

SLIDER
5
90
201
123
initial-explore-time
initial-explore-time
100
300
200.0
10
1
NIL
HORIZONTAL

BUTTON
5
305
200
345
Show/Hide Dance Path
show-hide-dance-path
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
5
350
200
390
Show/Hide Scouts
show-hide-scouts
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
130
200
163
quorum
quorum
0
50
33.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

The BeeSmart Master model shows the swarm intelligence of honeybees during their hive-finding process. A swarm of tens of thousands of honeybees can accurately pick the best new hive site available among dozens of potential choices through self-organizing behavior.

The mechanism in this model is based on Honeybee Democracy (Seeley, 2010) with some modifications and simplifications. One simplification is that this model only shows scout bees—a 3-5% population of the whole swarm that is actively involved in the decision making process. Other bees are left out because they simply follow the scouts to the new hive when a decision is made. Leaving out the non-scouts reduces the computational load and makes this model visually clearer.

This model is also the first of a series of models in a computational modeling-based scientific inquiry curricular unit “BeeSmart”, designed to help high school and university students learn complex systems principles as crosscutting concepts in science learning. Subsequent models are coming soon.

## HOW IT WORKS

At each SETUP, 100 scout bees are placed at the center of the view. Meanwhile, a certain number (determined by the “hive-number” slider) of potential hive sites are randomly placed around the swarm.

On clicking GO, initial scouts (the proportion of which are determined by the “initial-percentage” slider) fly away from the swarm in different directions to explore the surrounding space. They will explore the space for a maximum of “initial-explore-time.” If one scout stumbles upon a potential hive site, she inspects it. Otherwise, she goes back to the swarm and remains idle.

When a scout discovers a potential hive site, she inspects it to learn its location, color, and quality. Then she flies back to the swarm to advertise the site through waggle dances. The better the quality of the hive, the longer the scouts dance, the easier these dances are seen by idle bees in the swarm, and the more likely idle bees follow the dances to inspect the advertised hive site. After a newly joined bee’s inspection of the advertised site, the new bee flies back to the swarm and expresses her own opinions about the site through waggle dances. Bees revisit the sites they advocated, but their interests in the site decline after each revisit. Advertising for different sites continues in parallel in the swarm, but high quality sites attract more and more bees while low quality ones are gradually ignored.

When bees on a certain hive site observe a certain number of bees on the same site, or, in other words, when the “quorum” is reached, they fly back to the swarm and start to “pipe” to announce that a decision has been made. Any bee that hears the piping will also pipe, which causes the piping to spread across the swarm quickly. When all the bees are piping, the whole swarm takes off to move to the winning hive site and the model stops.

Typically, an initial scout goes through the states of “discover”-> “inspect-hive”-> “go-home”-> “dance”-> “re-visit”-> “pipe”; and non-initial scouts follow a slightly different sequence of states: “watch-dance”-> “re-visit” -> “inspect-hive”-> “go-home”-> “dance”-> “re-visit”-> “pipe”.

## HOW TO USE IT

Use the sliders to define the initial conditions of the model. The default values usually guarantee a successful hive finding, but users are encouraged to change these settings and see how each parameter affects the process.

Click SETUP after setting the parameters by the sliders. Then click GO and observe how the phenomenon unfolds. Toggle the “Show/Hide Dance Path” button to show or hide the waggle dance paths. Use the “Show/Hide Scouts” button to hide the bees if they block your view of the dance paths.

## THINGS TO NOTICE

Notice the three plots on the right hand of the model:

The “committed” plot shows the number of scouts that are committed to inspecting and advocating for each hive site; The “on-site” plot shows the count of bees on each site; The “watching vs. working” plot shows the change in numbers of idle and working bees.

Observe how information about multiple sites is brought to the swarm at the center of the view and how preference of the swarm changes over time.

Notice whether the timing of discovering the best hive site affects the swarm’s decision.

Zoom in and compare the “enthusiasm” of dances for high quality sites with those for low quality ones. Bees not only dance longer but also more enthusiastically (or faster, in this model, when they are making turns) for higher quality sites.

## THINGS TO TRY

Right click any scout and choose “Watch” from the right-click menu. A halo would appear around the scout to help you keep track of its movement.

Set sliders to different values and observe how these parameters affect the dynamic of the process.

Use the speed slider at the top of the model to slow down the model and observe the waggle dances.

Use “Control +” or “Command +” to zoom in and see the colors of the bees.

## EXTENDING THE MODEL

This model shows the honeybees’ hive-finding phenomenon as a continuous process. However, in reality, this process may last a few days. Bees do rest over night. Weather conditions may also affect this process. Adding these factors to the model can make it more accurately represent the phenomenon in the real world.

Currently, Site qualities cannot be controlled from the interface. Some input interface elements can be added to enable users to specify the quality of each hive.

## NETLOGO FEATURES

This model is essentially a state machine. Bees behave differently at different states. Command tasks are heavily used in this model to simplify the shifts between states and to enhance the performance of the model.

The pens in the plots are dynamically generated temporary plot pens, which match the number of hive sites that are determined by users.

The dance patterns are dynamically generated, which show the direction, distance, and quality of the hive advertised.

## RELATED MODELS

Wilensky, U. (1997). NetLogo Ants model. http://ccl.northwestern.edu/netlogo/models/Ants. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Wilensky, U. (2003). NetLogo Honeycomb model. http://ccl.northwestern.edu/netlogo/models/Honeycomb. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## CREDITS AND REFERENCES

Seeley, T. D. (2010). Honeybee democracy. Princeton, NJ: Princeton University Press.

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Guo, Y. and Wilensky, U. (2014).  NetLogo BeeSmart Hive Finding model.  http://ccl.northwestern.edu/netlogo/models/BeeSmartHiveFinding.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2014 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2014 Cite: Guo, Y. -->
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
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
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
1
@#$#@#$#@
