globals
[
  ;; variables used to assign colors and shape to clients
  shape-names                     ;; list that holds the names of the shapes a critter can have
  colors                          ;; list that holds the colors used for clients' critters
  color-names                     ;; list that holds the names of the colors used for clients' critters
  max-possible-codes              ;; total number of possible unique shape/color combinations
  longevity-leader-info           ;; holds user-id and if the species is not extinct, the shape and color name
  longevity-leader-age-and-status ;; holds age of the species and whether it is extinct or alive
  max-critter-lifespan            ;; the max number of ticks a critter can live
  birth-cost                      ;; the amount of energy needed to give birth
  dt                              ;; a time scaling unit used in the simulation to adjust how quickly events are rendered.
  player-spam-countdown           ;; the number of ticks a player must wait before placing a new species
  #-environment-changes           ;; the number of times the environment has changed
  events                          ;; a string holding a description of all the automatic environment changes that occurred in grass growth and max-grass
  total-species-created           ;; the total number of species created
  max-species-age                 ;; the maximum age of all species created
]


breed [ clients client]            ;; one for each client that logs in, for book-keeping
breed [ species-logs species-log ] ;; one for each client, that logs in.  It keeps track of all the species that have been created and tested by the client.
breed [ critters critter ]         ;; all the creatures in the ecosystem


clients-own
[
  user-id                        ;; unique id, input by the client when they log in, to identify each client turtle
  ; we have to keep track of the values from the client interface, whenever they change
  ; although we do not pass them on to critters they have already created.
  gray-out-others?               ;; if false, only this client's critters will be colored
  show-energy?                   ;; if true, display the energy level for each individual critter of this client's species
  placing-spam-countdown         ;; the number of ticks this client must wait before placing a new species
  placements-made                ;; the number of species this client has placed

  population-size                ;; the number of critters this client has
  current-longevity              ;; the age of this client's current species
  max-longevity                  ;; the age of the oldest species this client has created

  speed                          ;; how fast this client's critters move
  behavior-dna                   ;; the pattern of steps that this client's critters move in
  birthing-level                 ;; the energy level each individual must reach before reproducing as well as
                                 ;; how much energy is split between the parent and the offspring when this occurs
  carnivore?                     ;; if true, this client's species can eat other critters
]

critters-own
[
  age                            ;; the number of ticks this critter has been alive for
  energy                         ;; this critter's energy level
  creator-id                     ;; number to identify the creator of this critter
  species-id                     ;; number to identify this species

  ;;these variables are similar to the variables in clients-own with the same name
  speed
  behavior-dna
  birthing-level
  carnivore?

  current-action                 ;; this critter's current action from their behavior-dna
  action-index                   ;; the list index of this critter's current action in their behavior-dna
  movement-counter               ;; a counter that ticks down for a certain number of tics for each action in the
                                 ;; critters movement.  This allows the participants to be able to see the critters turning
                                 ;; and sliding forward or backward fluidly.
  movement-delta                 ;; the distance the critter moves
  species-start-tick             ;; the time (number of ticks) when this critter was made
]

species-logs-own
[
  creator-id                     ;; number to identify the creator of this species
  species-id                     ;; number to identify this species
  age                            ;; the number of ticks this species has been alive for
  created-on                     ;; the time (number of ticks) when this species was made
  last-alive-on                  ;; the time (number of ticks) when this species was last alive
  extinct?                       ;; if true, this species is no longer alive
]

patches-own [
  sugar                          ;; the amount of nutrients available on a patch
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to startup
  clear-all
  hubnet-reset
  setup-vars
end

to reset-client-stats
      set placements-made 0
      set population-size 0
      set current-longevity 0
      set max-longevity 0
end

to setup
  clear-patches
  clear-all-plots
  clear-output

  ask clients [
    reset-client-stats
  ]
  ask critters [ die ]
  ask species-logs [die]
  reset-ticks
  setup-patches
  repeat minimum-random-species
  [
    add-random-critter
  ]

  set longevity-leader-info "-----"
  set longevity-leader-age-and-status "-----"

  set max-critter-lifespan 1000
  set birth-cost .15
  set dt .5
  set player-spam-countdown 25
  set events []
  set #-environment-changes 0
  set total-species-created 0
  set max-species-age 0
end

to setup-patches
  ask patches [
    set sugar random (max-grass / 5)
    recolor-patch
  ]
end



to add-random-critter
  create-critters 1 [
    randomize-critter
    initialize-critter
    let shape-color-code unused-shape-color-code
    set-shape-and-color-by-code shape-color-code
    set creator-id first-unused-bot-name
    set energy birthing-level * 0.75
    make-a-species-log
  ]
end

to make-a-species-log
   set total-species-created total-species-created + 1
   set species-id total-species-created
   hatch 1  [
      set breed species-logs
      set hidden? true
      set created-on ticks
      set last-alive-on ticks
      set extinct? false
      ]
end


;; just for random bot critters
to randomize-critter
  set speed (1 + random 10) / 10
  set birthing-level (5 + random 46)
  set behavior-dna reduce [ [i action-letter] -> word i action-letter] n-values 30 [random-action-letter]
  set carnivore? (random 100 < 20)  ; 20% chance of being a carnivore
end

;; initialization actions that are common to bot & player-controlled critters
to initialize-critter
  let empty-patches patches with [ not any? critters-here ]
  ifelse (any? empty-patches)
    [ move-to one-of empty-patches ]
    [ setxy random-xcor random-ycor ]
  set heading one-of [ 0 90 180 270 ]
  set age 0
  set species-start-tick ticks
  set movement-counter 0
  set action-index -1
  if (carnivore?) [ set size size * 1.4 ]
end

to-report first-unused-bot-name
  let bot-num 1
  while [any? critters with [ creator-id = (word "bot" bot-num "*") ] ]
  [ set bot-num bot-num + 1 ]
  report (word "bot" bot-num "*")
end

to-report random-action-letter
  report one-of ["F" "F" "R" "L" "*"]
end

;; initialize global variables
to setup-vars
  set shape-names [ "box" "star" "wheel" "target" "cat" "dog"
                   "butterfly" "leaf" "car" "airplane"
                   "monster" "key" "cow skull" "ghost"
                   "cactus" "moon" "heart"]
  set colors      (list (white - 1) brown red (orange + 1) (violet + 1) (magenta) (sky + 1) yellow cyan 137)
  set color-names ["white" "brown" "red" "orange" "purple" "magenta" "blue" "yellow" "cyan" "pink"]
  set max-possible-codes (length colors * length shape-names)
end


;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go
  every 0.01
  [
    calc-leader-stats
    ; possibly add a random critter of a new species at every 20th tick
    if (ticks mod 20 = 0) and (random 50 < 1 or species-count < minimum-random-species)
    [
      add-random-critter
    ]
    ;; move turtles
    ask clients [update-client-stats]
    ask critters
    [
      set age age + dt
      if (movement-counter <= 0)
      [
        set action-index (action-index + 1) mod (length behavior-dna)
        set current-action item action-index behavior-dna
        if (current-action = "f") [ set current-action "F" ]
        if (current-action = "r") [ set current-action "R" ]
        if (current-action = "l") [ set current-action "L" ]
        if (current-action = "*" or not member? current-action "FRL")
        [ set current-action one-of ["F" "R" "L"] ]
        ifelse (current-action = "F")
        [
          ifelse (speed = 0)
          [ set movement-counter 1000000 ]
          [ set movement-counter round (1.0 / (speed * dt)) ]
          set movement-delta 1.0 / movement-counter
          ; make sure we're facing one of the four cardinal directions, before moving forward
          set heading (round (heading / 90)) * 90
        ][
        if (current-action = "R" or current-action = "L")
        [
          ifelse (speed = 0)
          [ set movement-counter 1000000 ]
          [ set movement-counter round (90 / (90 * speed * dt)) ]

          set movement-delta 90 / movement-counter
        ]]

      ]
      set movement-counter movement-counter - 1
      ifelse (current-action = "F")
      [
        ;; move and expend energy
        ifelse (can-move? movement-delta)
        [
          forward movement-delta
        ]
        [
          set movement-counter 0 ; critter tried to go forward but can't, so instead of beating its head
                                 ; against the wall for a long time, it skips to its next action
        ]
        ifelse (carnivore?)
        [
          set energy energy - (speed / 5 + 0.05) * dt  ; speed is less energy-expensive for carnivores.
        ]
        [
          set energy energy - (speed + 0.05) * dt  ; lose energy based on speed, and -0.05 base metabolism
        ]
      ][
        ifelse (current-action = "R")
          [ right movement-delta ]
          [ left movement-delta ]
        ; turning costs much less energy than movement,
        set energy energy - (speed / 5) * dt
        ; we only take away base metabolism for carnivores, b/c we don't want them to sit forever!
        if (carnivore?)
        [ set energy energy - 0.02 * dt ]
      ]

      ;; eat
      ifelse (carnivore?)
      [
        ;; don't eat anything of same color
        let prey critters-here with [ color != [color] of myself ]
        if any? prey
        [
          let victim one-of prey
          set energy energy + [ energy ] of victim
          ask victim [ die ]
        ]
      ]
      [ ; herbivore
        set energy energy + sugar
        ask patch-here [
          set sugar 0
          recolor-patch
        ]
      ]
      if (energy > birthing-level)
      [
        hatch 1 [
          set heading random 360
          if (can-move? 0.3)
            [ fd 0.3  ]
          set heading one-of [0 90 180 270 ]
          set age 0
          ; extra 0.25 penalty helps balance against critter-bomb low-birth-threshold tactics
          set energy (([energy] of myself) / 2) * (1.0 - birth-cost) - 0.25
          set movement-counter 0
          set action-index -1
        ]
        set energy energy / 2
      ]
      if (energy < 0 or age > max-critter-lifespan)
      [
        add-sugar (2 + energy / 2) ; give back some nutrients to the world, as the organism decomposes
        if (carnivore?)
          [ add-sugar 3 ] ; more from a carnivore corpse
        recolor-patch
        die
      ]
    ]

    ask n-of ((grass-growth / 100)  * dt * count patches ) patches  [
      add-sugar 0.1
      recolor-patch
    ]

     update-species-logs ;; keep historical record of all species

    ; we do hubnet commands right before a tick, because the override lists get set here,
    ; and the display gets updated after a tick.
    listen-clients

    if (ticks mod 100 = 0) and random 10 = 0 and  environment-changes? [change-environmental-conditions]

    tick
  ]
end


to add-sugar [ n ]
  ifelse sugar + n > max-grass
  [ set sugar max-grass ]
  [ set sugar sugar + n ]
end


to recolor-patch
  set pcolor scale-color green sugar 0 100
end


to change-environmental-conditions
     let growth-rate-change random 100 - random 100 ;sets growth-rate-change to a number between -99 and 99
     let max-grass-change random 80 - random 80 ;sets max-grass-change to a number between -79 and 79
     let old-max-grass max-grass
     let old-grass-growth grass-growth

     set grass-growth grass-growth + growth-rate-change
     if grass-growth < 10 [set grass-growth 10]
     if grass-growth > 100 [set grass-growth 100]

     set max-grass max-grass + max-grass-change
     if max-grass > 100 [set max-grass 100]
     if max-grass < 10 [set max-grass 10]
     let this-event (word "time: " ticks )
     set events lput  ( word  this-event " ggr: " grass-growth " mgpp: " max-grass) events
     set #-environment-changes #-environment-changes + 1
      output-print (word "Environmental change (time:" ticks ", grass-growth:" grass-growth ", max-grass:" max-grass )

end


to update-species-logs
  ask species-logs [
     let this-creator-id creator-id
     let this-species-id species-id
     let this-extinct-status extinct?
     ifelse any? critters with [creator-id = this-creator-id and this-species-id = species-id]
       [set last-alive-on ticks ]
       [if not extinct? [set extinct? true]]
     set age (last-alive-on - created-on)
   ]
  if any? species-logs [ set max-species-age max [age] of species-logs ]
end


;;;;;;;;;;;;;;;;;;;;;;;
;; HubNet Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;

;; determines which client sent a command, and what the command was
to listen-clients
  while [ hubnet-message-waiting? ]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ create-new-client ]
    [
      ifelse hubnet-exit-message?
      [ remove-client ]
      [
        ask clients with [ user-id = hubnet-message-source ]
          [ execute-command hubnet-message-tag ]
      ]
    ]
  ]

  ask clients  [ send-info-to-client ]
  if any? clients [broadcast-info-to-clients]
end


to create-new-client
  create-clients 1
  [
    setup-client-vars
    send-info-to-client
  ]
end


;; sets the turtle variables to appropriate initial values
to setup-client-vars  ;; turtle procedure
  hide-turtle
  set user-id hubnet-message-source
  change-shape-and-color
  setxy random-xcor random-ycor
  set heading one-of [0 90 180 270]
  set speed 1.0
  set behavior-dna "FFFFL"
  set birthing-level 25
  set carnivore? false
  set gray-out-others? false
  set show-energy? false
  set placing-spam-countdown 0
  reset-client-stats
end


to execute-command [command]
  if command = "speed"
  [ set speed hubnet-message           stop  ]
  if command = "behavior-dna"
  [ set behavior-dna hubnet-message    stop  ]
  if command = "birthing-level"
  [ set birthing-level hubnet-message  stop  ]
  if command = "carnivore?"
  [ set carnivore? hubnet-message      stop  ]
  if command = "gray-out-others?"
  [
    set gray-out-others? hubnet-message
    if (gray-out-others? = false)
    [ hubnet-clear-override user-id critters "color" ]
    stop
  ]
  if command = "show-energy?"
  [
    set show-energy? hubnet-message
    if (show-energy? = false)
    [ hubnet-clear-override user-id critters "label" ]
    stop
  ]
  if command = "Place New Species"
  [
    if (placing-spam-countdown = 0) and (placements-made < #-placements-per-client)
    [
      ; we make them wait a while before hitting PLACE again.
      set placing-spam-countdown player-spam-countdown
      set placements-made placements-made + 1
      ask my-critters [ die ]
      hatch-critters 1 [
        ; inherits variables: speed, behavior-dna, birthing-level, carnivore?, and color
        ; automatically from the client, via the hatch-critters statement
        set shape [shape] of myself ; shape not inherited via "hatch-critters"
        set creator-id user-id-to-creator-id ([user-id] of myself)
        set energy 30
        initialize-critter
        show-turtle ; otherwise critter inherits invisibility from the client
        make-a-species-log
      ]
    ]
    stop
  ]
  if command = "Change Shape"
  [
    change-shape-and-color
    stop
  ]
  if command = "follow-a-critter?"
  [
    ifelse (hubnet-message)
    [
      if any? my-critters
        [ hubnet-send-follow user-id (one-of my-critters) 10 ]
    ]
    [ hubnet-reset-perspective user-id ]
    stop
  ]
end

to remove-client
  ask clients with [user-id = hubnet-message-source]
  [
    ask my-critters [
      set creator-id (word creator-id "*")
    ]
    die
  ]
end




to set-shape-and-color-by-code [ code ]
  set shape item (code mod length shape-names) shape-names
  set color item (code / length shape-names) colors
end



to update-client-stats
  set population-size count-my-critters
  set current-longevity longevity-of-this-species
  set max-longevity max-longevity-of-all-my-species
end



;; sends the appropriate monitor information back to the client
to send-info-to-client
  if (placing-spam-countdown > 0) [ set placing-spam-countdown placing-spam-countdown - 1 ]
  hubnet-send user-id "Countdown until you can place again:" placing-spam-countdown
  hubnet-send user-id "# of species left you can introduce" (#-placements-per-client - placements-made)
  hubnet-send user-id "Your Current Species Size" population-size
  hubnet-send user-id "Your Current Species Longevity"  current-longevity
  hubnet-send user-id "Your Max. Species Longevity"  max-longevity

  if (gray-out-others?)  [ hubnet-send-override user-id critters with [ creator-id != (user-id-to-creator-id [user-id] of myself)] "color" [gray - 2] ]
  if (show-energy?)      [ hubnet-send-override user-id my-critters "label" [ (word round energy "     ") ]  ]
end


to broadcast-info-to-clients
  if any? clients [
    hubnet-broadcast "# Alive Species" species-count
    hubnet-broadcast "# Extinct Species" count species-logs with [extinct?]

    hubnet-broadcast "Species Longevity Leader" longevity-leader-info
    hubnet-broadcast "Longevity Record" longevity-leader-age-and-status
    hubnet-broadcast "time" ticks
  ]
end


to calc-leader-stats
  if any? species-logs [
    let leader-log max-one-of species-logs [age]  ;; pull out a log
    let leader-species-extinct? [extinct?] of leader-log
    let leader-id [creator-id] of leader-log
    let leader-shape ""
    let leader-status ""
    ifelse leader-species-extinct?
       [set leader-shape "" set leader-status "extinct"]
       [set leader-shape  [(word (color-string color) " " shape)] of one-of critters with [creator-id = leader-id] set leader-status "alive"]

    set longevity-leader-age-and-status (word [age] of leader-log " (" leader-status ")")
    set longevity-leader-info (word leader-id ": " leader-shape)
  ]
end


to change-shape-and-color
  set-shape-and-color-by-code unused-shape-color-code
  hubnet-send user-id "Your critter shape:" (word (color-string color) " " shape)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Reporters   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report longevity-of-this-species
  let p-user-id user-id
  let p-value-to-report 0
  if any? species-logs with [creator-id = p-user-id and extinct? = false] [
   set p-value-to-report [age] of species-logs with [creator-id = p-user-id and extinct? = false]
   set p-value-to-report item 0 p-value-to-report
  ]
  report p-value-to-report
end


to-report max-longevity-of-all-my-species
  let p-user-id user-id
  let p-value-to-report 0
  if any? species-logs with [creator-id = p-user-id] [
   set p-value-to-report max [age] of species-logs with [creator-id = p-user-id]
  ]
  report p-value-to-report
end


to-report my-critters
  report critters with [ creator-id = (user-id-to-creator-id [user-id] of myself )]
end


to-report count-my-critters
  report count my-critters
end


to-report age-of-my-critters
    ifelse any? critters with [ creator-id = (user-id-to-creator-id [user-id] of myself )]
        [report max [age] of critters with [ creator-id = (user-id-to-creator-id [user-id] of myself )]]
        [report 0]
end


;; translates a client turtle's shape and color into a code
to-report my-shape-color-code
  let shape-pos (position shape shape-names)
  let color-pos (position color colors)
  if (shape-pos = false or color-pos = false)
    [ report false ]
  report shape-pos + (length shape-names) * color-pos
end


to-report unused-shape-color-code
  let used-codes remove-duplicates ([my-shape-color-code] of turtles)
  let new-code random max-possible-codes
  while [ member? new-code used-codes ]
  [ set new-code random max-possible-codes ]
  report new-code
end


to-report user-id-to-creator-id [ uid ]
  report remove "*" uid
end


;; report the string version of the turtle's color
to-report color-string [color-value]
  report item (position color-value colors) color-names
end


to-report species-list
  report remove-duplicates [ creator-id ] of critters
end


to-report species-count
  report length species-list
end


; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
505
10
1068
514
-1
-1
15.0
1
10
1
1
1
0
1
1
1
-18
18
-16
16
1
1
1
ticks
30.0

BUTTON
115
10
225
43
go/stop
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
162
225
195
minimum-random-species
minimum-random-species
0
25
0.0
1
1
NIL
HORIZONTAL

BUTTON
5
10
115
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

SLIDER
120
45
225
78
max-grass
max-grass
10
100
42.0
5
1
NIL
HORIZONTAL

SLIDER
5
45
120
78
grass-growth
grass-growth
1
100
31.0
1
1
NIL
HORIZONTAL

MONITOR
130
470
255
515
# alive species
species-count
17
1
11

PLOT
231
10
501
470
population
time
percent of living critters
0.0
500.0
0.0
100.0
true
true
"" "if (ticks mod 5 = 0 and ticks != 0) [\n  if (ticks mod 2000 = 0)\n  [\n    clear-all-plots\n    set-plot-x-range (ticks) / dt (ticks + 500) / dt\n  ]\n  if (ticks mod 2000) > 500  ; don't change the range until we've plotted all the way across once\n  [\n    set-plot-x-range (ticks - 500) / dt ticks / dt  ; only show the last 500 ticks\n  ]\n\n  foreach sort species-list [ the-creator-id ->\n    let crits critters with [ creator-id = the-creator-id ]\n    ; create-temporary-plot-pen will either create the pen, or set it current if it exists\n    create-temporary-plot-pen the-creator-id\n\n    let col [color] of one-of crits\n    if (col mod 10 > 7) ; make the whitish colors more visible on the plot\n      [ set col col - 1 ]\n    set-plot-pen-color col\n    plotxy (ticks / dt) (count crits) * 100 / count critters\n  ]\n  ]"
PENS
"-players-" 1.0 0 -16777216 true "" ""

SLIDER
4
197
224
230
#-placements-per-client
#-placements-per-client
0
25
10.0
1
1
NIL
HORIZONTAL

MONITOR
380
470
500
515
time
ticks
17
1
11

SWITCH
5
80
225
113
environment-changes?
environment-changes?
0
1
-1000

MONITOR
5
116
172
161
# environmental changes
#-environment-changes
17
1
11

MONITOR
5
470
130
515
# extinct species
count species-logs - species-count
17
1
11

MONITOR
255
470
380
515
 longevity record
longevity-leader-age-and-status
17
1
11

PLOT
5
350
225
470
# extinct species
% of competition time
#
0.0
100.0
0.0
5.0
true
false
"" "set-current-plot-pen \"extinct\"\nhistogram ([100 * age / ticks] of species-logs with [extinct?])"
PENS
"extinct" 5.0 1 -8053223 true "" ""

PLOT
5
232
225
352
# alive species
% of competition time
#
0.0
100.0
0.0
5.0
true
false
"" "set-current-plot-pen \"alive\"\nhistogram ([100 * age / ticks] of species-logs with [not extinct?])"
PENS
"alive" 5.0 1 -10899396 true "" ""

OUTPUT
5
515
500
575
10

@#$#@#$#@
## WHAT IS IT?

This model simulates competition between many different species in a complex ecosystem. The outcome of the competition shows that when all individuals in a population are identical to each other, the competitive advantage of a species will continue to change compared to other species when the environmental conditions keep changing.

The model can be set so that the computer randomly adds new species into the ecosystem as well.  Since different species outcompete each other at different times in a changing environment, this tends to result in the eventual disappearance of some species in the ecosystem over time.

Any attempt by a participant to create an "optimal design" for a species is doomed to eventual failure and extinction if the model is run long enough.  This outcome suggests that the inclusion of evolutionary mechanisms (such as random mutations in offspring) might lead to some species that can survive longer in the ecosystem without going extinct than any species with a purposefully designed combination of unchanging traits.

## HOW IT WORKS

### Species

Participants use the HubNet client interface to interact with the model and design new types of critters to test in the ecosystem. A single critter can be designed and then released into the environment at a time.  As this critter gains energy, it can reproduce offspring, which in turn can reproduce more offspring when they gain enough energy.  Each new offspring will have identical trait variations as the original ancestor critter, as each offspring is reproduced asexually from a single parent. All the descendants from the first ancestor critter are defined as being part of the same species.

New critter species can be designed to follow different patterns of movement, have different speeds at which they move around the ecosystem, and have different energy levels required for giving birth to an offspring. Each new design you test can be either a herbivore or a carnivore.  A single individual is what is released into the ecosystem by the participants when a participant tests a new critter design.  Since your entire species of critters will have identical traits, the same shape and color of all the offspring of the critter design you test will also look the same.

When a participant releases an individual with a new critter design into the ecosystem, all of the critters of the previous species are instantly removed from the ecosystem.

### Ecosystem

Activity leaders use the model interface to set up the ecosystem. The interface allows them to set the amount of grass that can grow and how fast it grows. These changes are attempting to represent the effects of variation of rainfall in time and space. The environmental conditions can be set to be fixed or varying in the ecosystem. When environmental conditions vary, the grass growth and speed values shift from time to time.

As new critters are added and/or as the environmental conditions change, the stability of the ecosystem changes. New selective pressures may emerge with each change, which in turn leads to different levels of competitive advantage for a given combinations of traits. Over time, a design that gave a competitive advantage in one environment is likely to have less of a competitive advantage in another environment.

Since individuals show no trait variation different from their ancestors, evolution does not occur in this model. When evolution does not occur, species designed to have a strong competitive edge for one set of environmental conditions are destined to go extinct when environmental changes are large enough or frequent enough. So, all species introduced into the ecosystem eventually go extinct as the environment keeps changing and new species are introduced.

In the real world, the traits of individuals in a species don't remain fixed.  New traits that have never appeared before emerge in populations.  This occurs because offspring can incur mutations that give them different traits from their ancestors.  Though mutations are random, they introduce new trait variations into a population.   In a way, mutation serves like a "random design changer".  As many minor random design changes emerge in a population from mutations, some are bound to result in individuals that have a greater competitive advantage than the ancestors.  This permits species to keep "unintentionally" experimenting with alternate design plans as the environment changes.  Some such species continue to evolve over time, so that offspring can appear and behave very differently than their original ancestors.  In the real world then, while some species may go extinct, others continue to evolve to accumulate beneficial trait variations as the environment keeps changing.

## HOW TO USE IT

### Activity Leader

In the HubNet Control Center, press SETUP and GO once all clients have connected to the model. Once the model is running place a check mark next to both "Mirror 2D view on clients" and "Mirror plots on clients (experimental)". _Note: these options should always be unchecked before you press SETUP._  If you don't follow this order for checking these options after pressing SETUP an error will occur in the experimental plotting code.

#### Model sliders and switches:

GRASS-GROWTH controls how fast the grass grows back on each patch.

MAX-GRASS sets the % of patches that grow grass. 50% would allow only half the patches to grow grass.

ENVIRONMENT-CHANGES? when turned to "off" keeps MAX-GRASS and GRASS-GROWTH levels set to whatever values the user left them at in the interface. When turned to "on", those levels will shift occasionally to random values picked by the computer.

MINIMUM-RANDOM-SPECIES adjusts the number of random species the computer adds. When one of the species goes extinct, another randomly generated species replaces it. When set to 0, only species that client participants add will be in the ecosystem.

\# ENVIRONMENTAL CHANGES keeps track of the number of automatic (computer selected) shifts in the MAX-GRASS and GRASS-GROWTH levels occurred.

PLACEMENTS-PER-CLIENT sets the maximum number of critter designs each client can release and test in the ecosystem.

\# ALIVE SPECIES is a histogram of the number of current species that are alive by % of time that they are alive for the simulation.  For short model runs, there may be some species that are alive for 100% of the time the simulation ran.  For long model runs it becomes progressively less likely that any species will be alive for 100% of the time of the model run.  The histogram will cluster to the left the longer the model runs.

\# EXTINCT SPECIES is a histogram of the number of species that died by % of time that they are alive for the simulation.  The longer the model runs, the smaller the percent of time that the extinct species were alive for.  Species that came into existence at the start of the model run and went extinct just before the model run ended will appear clustered toward the right side of the histogram.  Species that came into existence at any point in the model run and then went extinct shortly after will tend to cluster toward the left side of the histogram.

### HubNet Participant

Open up a HubNet client on your machine and type your user name, select this activity and press ENTER.

#### Client sliders, input boxes, and buttons:

CHANGE SHAPE randomly changes the shape of the critters you are going to release. The newly assigned shape will show up in the YOUR CRITTER SHAPE monitor.

BEHAVIOR-DNA allows you to input a string of characters that describe the pattern of steps that the critters move in (F = forward, L = left, R = right, * = random).

SPEED controls how fast the critters move. Faster moving critters use up energy more quickly.

BIRTHING-LEVEL controls the energy level each individual must reach before reproducing as well as how much energy is split between the parent and the offspring when this occurs.

CARNIVORE? controls whether the species eats other critters (set the value to "On") or the species eats grass (set the value to "Off").

PLACE NEW SPECIES this button releases one new individual that has the trait variations specified by YOUR CRITTER SHAPE, BEHAVIOR-DNA, SPEED, BIRTHING-LEVEL, and CARNIVORE?. When a new species is placed, that client's old species is automatically removed from the ecosystem.

#### Client Switches:

GRAY-OUT-OTHERS? controls whether to display the colors of all the species for the client (set the value to "On") or keep the color of client's species visible and turning all other species gray (set the value to "Off").

FOLLOW-A-CRITTER? controls whether the client's view remains looking at the entire ecosystem (set the value to "Off") or attaches to a single randomly selected critter (set the value of "On").

SHOW-ENERGY? displays the energy level for each individual critter of your species when set to "On".

#### Client Monitors:

YOUR CURRENT SPECIES LONGEVITY reports how long the current species has existed (elapsed time) in the ecosystem.

YOUR MAX. SPECIES LONGEVITY reports the longest existence for any species you have tested in this ecosystem for this model run.

YOUR CURRENT SPECIES SIZE reports how many individuals are in the current species.

SPECIES LONGEVITY LEADER reports which participant has the record for the longest lasting species.

### Common to Both Participant Leader and Client Views

POPULATION graphs all the population percentages for each species on the same axis (percent of living creatures vs. time). Population percentages are a calculation of what number of individuals in the ecosystem belong to this species / total individuals in all species in the ecosystem * 100. So a level of 50% for one species graph would mean that half of the individuals from all species in the ecosystem are of that one species.

LONGEVITY RECORD reports the record for the longest lasting species (elapsed time) in this model run.

TIME reports how much time has elapsed in this model run.

ALIVE SPECIES reports how many species are currently in this ecosystem.

EXTINCT SPECIES reports how many species have died out completely in this ecosystem.

## THINGS TO NOTICE

No matter how successful a critter design is at one instant in the ecosystem, its level of success will soon change as the ecosystem starts changing. Eventually, if the new species are continually being "tested out" in the environment enough times, one of them will end up outcompeting the current "native species".

The important evolutionary outcome here is that if species can't evolve, they are doomed to extinction if they must go head to head with alternate "designs" in a changing environment. Also, people who test multiple designs within the environment are more likely to strike upon a relatively successful design (at least in the short term), than those who stick with only one design.

And the most intentional design by a participant will still eventually get outcompeted and driven to extinction by many random designs thrown into the competition over a long period of time by the computer.

## THINGS TO TRY

Use the model with an entire class to serve as an introduction to the topic of the mechanisms of evolution. If a student develops a successful design (that lasts for an entire simulation run or until the end of the lesson), keep the model running overnight with a large value set for MINIMUM-RANDOM-SPECIES and with the ENVIRONMENT-CHANGE? switch set to "On".

## EXTENDING THE MODEL

One or more computer generated species could be given the ability to generate mutations that cause minor changes in the traits of the offspring. Longevity experiments could be conducted to compare the success of computer generated, evolving species to the success of purposefully designed "fixed trait" species created by participants.

## NETLOGO FEATURES

The population graph updates to have a continually rolling x-axis.  This means that when a new maximum x-value is reached, that x-value becomes the new x-minimum value and the plots are wiped clean and the x-axis is reset with same x range as before, but the new minimum and maximum values.

The command hubnet-send-override is used to change the appearance of agents in the client view, so that each client can customized what is displayed for that client.  This allows clients to "gray out" species that aren't their own in their client view or turn on labels for the agents in their view only.

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Stonedahl, F., Novak, M. and Wilensky, U. (2011).  NetLogo Critter Designers HubNet model.  http://ccl.northwestern.edu/netlogo/models/CritterDesignersHubNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the HubNet software as:

* Wilensky, U. & Stroup, W. (1999). HubNet. http://ccl.northwestern.edu/netlogo/hubnet.html. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Stonedahl, F., Novak, M. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

android
true
0
Polygon -7500403 true true 210 90 240 195 210 210 165 90
Circle -7500403 true true 110 3 80
Polygon -7500403 true true 105 88 120 193 105 240 105 298 135 300 150 210 165 300 195 298 195 240 180 193 195 88
Rectangle -7500403 true true 127 81 172 96
Rectangle -16777216 true false 135 33 165 60
Polygon -7500403 true true 90 90 60 195 90 210 135 90

box
true
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

butterfly
true
0
Rectangle -7500403 true true 92 135 207 224
Circle -7500403 true true 158 53 134
Circle -7500403 true true 165 180 90
Circle -7500403 true true 45 180 90
Circle -7500403 true true 8 53 134
Line -16777216 false 43 189 253 189
Rectangle -7500403 true true 135 60 165 285
Circle -7500403 true true 165 15 30
Circle -7500403 true true 105 15 30
Line -7500403 true 120 30 135 60
Line -7500403 true 165 60 180 30
Line -16777216 false 135 60 135 285
Line -16777216 false 165 285 165 60

cactus
true
0
Rectangle -7500403 true true 135 30 175 177
Rectangle -7500403 true true 67 105 100 214
Rectangle -7500403 true true 217 89 251 167
Rectangle -7500403 true true 157 151 220 185
Rectangle -7500403 true true 94 189 148 233
Rectangle -7500403 true true 135 162 184 297
Circle -7500403 true true 219 76 28
Circle -7500403 true true 138 7 34
Circle -7500403 true true 67 93 30
Circle -7500403 true true 201 145 40
Circle -7500403 true true 69 193 40

car
true
0
Polygon -7500403 true true 180 0 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 300 165 300 225 300 225 0 180 0
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

cat
true
0
Line -7500403 true 285 240 210 240
Line -7500403 true 195 300 165 255
Line -7500403 true 15 240 90 240
Line -7500403 true 285 285 195 240
Line -7500403 true 105 300 135 255
Line -16777216 false 150 270 150 285
Line -16777216 false 15 75 15 120
Polygon -7500403 true true 300 15 285 30 255 30 225 75 195 60 255 15
Polygon -7500403 true true 285 135 210 135 180 150 180 45 285 90
Polygon -7500403 true true 120 45 120 210 180 210 180 45
Polygon -7500403 true true 180 195 165 300 240 285 255 225 285 195
Polygon -7500403 true true 180 225 195 285 165 300 150 300 150 255 165 225
Polygon -7500403 true true 195 195 195 165 225 150 255 135 285 135 285 195
Polygon -7500403 true true 15 135 90 135 120 150 120 45 15 90
Polygon -7500403 true true 120 195 135 300 60 285 45 225 15 195
Polygon -7500403 true true 120 225 105 285 135 300 150 300 150 255 135 225
Polygon -7500403 true true 105 195 105 165 75 150 45 135 15 135 15 195
Polygon -7500403 true true 285 120 270 90 285 15 300 15
Line -7500403 true 15 285 105 240
Polygon -7500403 true true 15 120 30 90 15 15 0 15
Polygon -7500403 true true 0 15 15 30 45 30 75 75 105 60 45 15
Line -16777216 false 164 262 209 262
Line -16777216 false 223 231 208 261
Line -16777216 false 136 262 91 262
Line -16777216 false 77 231 92 261

cow skull
true
0
Polygon -7500403 true true 150 90 75 105 60 150 75 210 105 285 195 285 225 210 240 150 225 105
Polygon -16777216 true false 150 150 90 195 90 150
Polygon -16777216 true false 150 150 210 195 210 150
Polygon -16777216 true false 105 285 135 270 150 285 165 270 195 285
Polygon -7500403 true true 240 150 263 143 278 126 287 102 287 79 280 53 273 38 261 25 246 15 227 8 241 26 253 46 258 68 257 96 246 116 229 126
Polygon -7500403 true true 60 150 37 143 22 126 13 102 13 79 20 53 27 38 39 25 54 15 73 8 59 26 47 46 42 68 43 96 54 116 71 126

dog
true
0
Polygon -7500403 true true 165 0 195 0 210 30 204 117 240 120 270 135 300 135 300 180 240 300 165 255 90 225 45 225 15 195 45 165 45 135 15 120 15 75 30 45 30 75 60 90 90 75 105 75
Polygon -16777216 true false 240 300 300 180 300 135 285 135 285 180 221 290
Line -16777216 false 60 90 45 120
Line -16777216 false 45 210 90 210
Line -16777216 false 90 210 105 195
Line -16777216 false 105 195 60 165
Line -16777216 false 45 210 60 165
Line -16777216 false 60 165 45 165
Line -16777216 false 203 119 203 149
Line -16777216 false 201 150 171 195
Circle -16777216 true false 88 95 34
Circle -16777216 false false 162 9 30

ghost
true
0
Polygon -7500403 true true 30 165 13 164 -2 149 0 135 -2 119 0 105 15 75 30 75 58 104 43 119 43 134 58 134 73 134 88 104 73 44 78 14 103 -1 193 -1 223 29 208 89 208 119 238 134 253 119 240 105 238 89 240 75 255 60 270 60 283 74 300 90 298 104 298 119 300 135 285 135 285 150 268 164 238 179 208 164 208 194 238 209 253 224 268 239 268 269 238 299 178 299 148 284 103 269 58 284 43 299 58 269 103 254 148 254 193 254 163 239 118 209 88 179 73 179 58 164
Line -16777216 false 189 253 215 253
Circle -16777216 true false 102 30 30
Polygon -16777216 true false 165 105 135 105 120 120 105 105 135 75 165 75 195 105 180 120
Circle -16777216 true false 160 30 30

heart
true
0
Circle -7500403 true true 152 19 134
Polygon -7500403 true true 150 105 240 105 270 135 150 270
Polygon -7500403 true true 150 105 60 105 30 135 150 270
Line -7500403 true 150 270 150 135
Rectangle -7500403 true true 135 90 180 135
Circle -7500403 true true 14 19 134

key
true
0
Rectangle -7500403 true true 120 0 150 210
Rectangle -7500403 true true 135 0 195 30
Rectangle -7500403 true true 135 75 195 105
Circle -7500403 true true 60 150 150
Circle -16777216 true false 90 180 90

leaf
true
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

monster
true
0
Polygon -7500403 true true 75 150 90 195 210 195 225 150 255 120 255 45 180 0 120 0 45 45 45 120
Circle -16777216 true false 165 60 60
Circle -16777216 true false 75 60 60
Polygon -7500403 true true 225 150 285 195 285 285 255 300 255 210 180 165
Polygon -7500403 true true 75 150 15 195 15 285 45 300 45 210 120 165
Polygon -7500403 true true 210 210 225 285 195 285 165 165
Polygon -7500403 true true 90 210 75 285 105 285 135 165
Rectangle -7500403 true true 135 165 165 270

moon
true
0
Polygon -7500403 true true 289 208 252 99 206 51 146 31 84 56 37 108 21 153 16 209 43 161 87 121 129 105 175 106 208 121 242 149

star
true
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
true
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60
Rectangle -7500403 true true 135 15 165 150

wheel
true
0
Circle -7500403 true true 15 15 270
Circle -16777216 true false 30 30 240
Line -7500403 true 150 270 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 90 255
Line -7500403 true 40 84 255 210
Line -7500403 true 40 216 255 90
Line -7500403 true 84 40 210 255
Circle -7500403 true true 120 0 60
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
247
46
728
475
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
-16
16

SLIDER
107
157
240
190
speed
speed
0.0
2.0
1
0.01
1
NIL
HORIZONTAL

MONITOR
6
10
142
59
Your critter shape:
NIL
3
1

BUTTON
144
10
239
43
Change Shape
NIL
NIL
1
T
OBSERVER
NIL
NIL

MONITOR
12
525
201
574
Your Current Species Size
NIL
3
1

BUTTON
114
303
241
336
Place New Species
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
13
301
115
364
WARNING: placing a new species will remove all your current critters.
11
14.0
1

INPUTBOX
9
87
234
147
behavior-dna
FFFFL
1
1
String

TEXTBOX
17
68
247
86
F=Forward, R=Right, L=Left, *=Random
10
93.0
1

TEXTBOX
5
162
105
192
More speed uses energy more quickly.
10
93.0
1

SLIDER
107
199
240
232
birthing-level
birthing-level
5.0
50.0
25
1.0
1
NIL
HORIZONTAL

TEXTBOX
5
204
122
234
Energy collected for reproduction.
10
23.0
1

SWITCH
250
10
410
43
gray-out-others?
gray-out-others?
1
1
-1000

MONITOR
474
478
586
527
# Alive Species
NIL
3
1

SWITCH
409
10
575
43
follow-a-critter?
follow-a-critter?
1
1
-1000

SWITCH
106
244
238
277
carnivore?
carnivore?
1
1
-1000

MONITOR
202
526
442
575
Species Longevity Leader
NIL
3
1

MONITOR
13
477
202
526
Your Current Species Longevity
NIL
3
1

PLOT
732
10
1020
572
population
time
percent of living critters
0.0
500.0
0.0
100.0
true
true
"" ""
PENS
"-players-" 1.0 0 -16777216 true "" ""

MONITOR
10
363
235
412
Countdown until you can place again:
NIL
3
1

TEXTBOX
5
244
104
289
Carnivores won't eat critters of their own color.
10
53.0
1

SWITCH
575
10
725
43
show-energy?
show-energy?
1
1
-1000

MONITOR
204
477
442
526
Your Max. Species Longevity
NIL
3
1

MONITOR
10
413
235
462
# of species left you can introduce
NIL
3
1

MONITOR
615
527
724
576
time
NIL
3
1

TEXTBOX
7
284
247
302
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
11
0.0
1

MONITOR
590
477
699
526
# Extinct Species
NIL
3
1

MONITOR
446
528
614
577
Longevity Record
NIL
3
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
