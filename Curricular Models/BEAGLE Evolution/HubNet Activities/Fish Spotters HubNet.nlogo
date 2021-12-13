breed [players player]          ;; each client controls one player turtle, players are always hidden in the view
breed [fish a-fish]             ;; fish is the main agent that fish parts are attached to
breed [fish-spots a-fish-spot]  ;; fish spots are attached to the main fish body

breed [debris a-debris]         ;; debris includes any of the "moving" distractors in the tank (leaves floating about or ripples on the water surface)
breed [edges edge]              ;; square shaped agents used to cover the edges of the tank, so that ripples and leaves (debris) float behind these edges

breed [rocks rock]              ;; temporary agent used for creating a shape "stamped" image for the background
breed [plants plant]            ;; temporary agent used for creating a shape "stamped" image for the background

rocks-own   [which-tank]
patches-own [debris-spot? type-of-patch tank]


;; gene-frequencies determine the color
;; of each fish and mutate as fish reproduce
fish-own [
  red-gene                ;; gene for strength of expressing red pigment (0-100)
  blue-gene               ;; gene for strength of expressing blue pigment (0-100)
  green-gene              ;; gene for strength of expressing green pigment (0-100)
  spot-transparency-gene  ;; gene for transparency value of the spots (0-255)
  size-gene               ;; gene for the size of the fish
  motion-gene             ;; gene for how much the fish are moving
  birthday                ;; when this fish was born
]

players-own
[
  user-name    ;; the unique name users enter on their clients
  role         ;; set as predator or mate
  caught       ;; the number of fish this user as caught
  attempts     ;; times the user has clicked in the view trying to catch a fish
  percent      ;; percent of catches relative to the leader
]

globals
[
  predator-leader               ;; a string expressing the player who has caught the most fish (or a tie if appropriate)
  predator-leader-caught        ;; the number of fish the leader has caught
  mate-leader                   ;; a string expressing the player who has caught the most fish (or a tie if appropriate)
  mate-leader-caught            ;; the number of fish the leader has caught
  predator-total-found          ;; running total of the total number of fish caught
  mate-total-found              ;; running total of the total number of fish caught
  adult-age                     ;; the age at which recently hatched fish become full sized
  offspring-distance            ;; how far away offspring appear from where the parent mated
  number-of-predators           ;; keeps track of the number of predators (clients that are assigned this role) in the competition
  number-of-mates               ;; keeps track of the number of mates     (clients that are assigned this role) in the competition
  last-mouse-down-check?        ;; keeps track of last mouse-down? state
  max-color-mutation-step       ;; maximum amount the color can change from a mutation
  old-client-roles              ;; keeps track of previous state of the client-roles chooser, so ....
                                ;; that if it is changed while GO/STOP is running, roles will be reassigned to the clients
  ripple-debris-color           ;; keeps track of color of water ripple debris
  tank-1-avg-spot-transparency  ;; statistic for tank 1
  tank-2-avg-spot-transparency  ;; statistic for tank 2
  tank-1-avg-motion             ;; statistic for tank 1
  tank-2-avg-motion             ;; statistic for tank 2
  tank-1-avg-size               ;; statistic for tank 1
  tank-2-avg-size               ;; statistic for tank 2
  top-ground-previous-value     ;; keeps track of previous top-ground value from that chooser, in case it is changed while GO/STOP is running
  bottom-ground-previous-value  ;; keeps track of previous bottom-ground value from that chooser, in case it is changed while GO/STOP is running
  top-water-previous-value      ;; keeps track of previous top-water value from that chooser, in case it is changed while GO/STOP is running
  bottom-water-previous-value   ;; keeps track of previous bottom-water value from that chooser, in case it is changed while GO/STOP is running
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Setup Procedures;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to startup
  ;; standard HubNet setup
  hubnet-reset
  setup-clear
end

;; this kills off all the turtles (including the players)
;; so we don't necessarily want to do this each time we setup
to setup-clear
  clear-all
  set adult-age 20
  set offspring-distance 3
  setup
  set number-of-mates 0
  set number-of-predators 0
end

;; setup the model for another round of fish catching
;; with the same group of users logged in
to setup
  clear-patches
  clear-all-plots
  reset-ticks
  ask fish [ die ]
  ask fish-spots [die]
  ask debris [die]
  ask rocks [die]

  set old-client-roles ""
  set predator-leader ""
  set predator-leader-caught 0
  set mate-leader ""
  set mate-leader-caught 0
  set ripple-debris-color [100 100 200 100]
  set top-ground-previous-value ""
  set bottom-ground-previous-value ""
  set top-water-previous-value ""
  set bottom-water-previous-value ""
  set max-color-mutation-step 25
  set tank-1-avg-spot-transparency 0
  set tank-2-avg-spot-transparency 0
  set tank-1-avg-motion 0
  set tank-2-avg-motion 0
  set tank-1-avg-size 0
  set tank-2-avg-size 0
  set adult-age 50               ;; ensures it takes a bit over a second to grow to full size

  ;; make sure to return players to initial conditions
  ask players [ initialize-player ]
  set number-of-mates count players with [role = "mate"]
  set number-of-predators count players with [role = "predator"]

  set-default-shape fish "fish"
  set last-mouse-down-check? false
  ask patches [set debris-spot? false set pcolor [0 0 0]]

  change-bottom
  setup-regions
  check-debris-count
  ask debris [ set-debris-appearance]
  update-tank-states
  adjust-fish-population-size-to-carrying-capacity

  calculate-statistics
  ask players [
    send-player-info
    broadcast-competition-info
  ]
  tick
end

to make-one-initial-fish [in-tank]
    let target-patch one-of patches with [type-of-patch = "water" and tank = in-tank]
    move-to target-patch
    set birthday ticks  ;; start at full size
    assign-initial-color-genes
    set spot-transparency-gene 0
    set size-gene 1
    set motion-gene 2
    set heading random 360
    color-this-fish
    add-fish-spots
    grow-this-fish
end

to assign-initial-color-genes ;; fish procedure
  if (top-initial-fish = "multi-colored" and tank = 1) or (bottom-initial-fish = "multi-colored" and tank = 2) [
    set red-gene        (random 255)
    set blue-gene       (random 255)
    set green-gene      (random 255)
  ]
  if (top-initial-fish = "all gray" and tank = 1) or (bottom-initial-fish = "all gray" and tank = 2) [
    set red-gene   150
    set blue-gene  150
    set green-gene 150
  ]
  if (top-initial-fish = "black or white" and tank = 1) or (bottom-initial-fish = "black or white" and tank = 2) [
    ifelse random 2 = 0 [
       set red-gene 0
       set blue-gene 0
       set green-gene  0
    ][
       set red-gene  255
       set blue-gene  255
       set green-gene  255
    ]
  ]
end

to add-fish-spots ;; fish procedure
    hatch-fish-spots 1 [     ;;;make tail
       set size 1
       set shape "spots"
       set color (list [red-gene] of myself [green-gene] of myself [blue-gene] of myself [spot-transparency-gene] of myself) ;; set color to rgb values of attached fish
       create-link-with myself [set hidden? true set tie-mode "fixed" tie ]   ;; fish-spots will link to the fish body - thus following the fish body around as it moves
     ]
end

to color-this-fish ;; fish procedure
  set color rgb red-gene green-gene blue-gene
end

to change-bottom
  let gravel-size .6
  let bottom-patches patches with [pycor < 0]
  let top-patches patches with [pycor > 0]

  clear-drawing
  create-rocks 1 [set shape top-ground set which-tank "top tank"]
  create-rocks 1 [set shape bottom-ground set which-tank "bottom tank"]

  ask top-patches [ set pcolor ground-color top-ground ]
  ask bottom-patches [ set pcolor ground-color bottom-ground ]

  ;; 3000 repetitions ensures that the bottom looks covered with rocks or plants or sand
  repeat 3000 [
    ask rocks [
      penup
      rt random 360
      if which-tank = "top tank" [setxy random-float 100 random-float max-pycor ]
      if which-tank = "bottom tank" [setxy  random-float 100 (-1 * random-float (abs min-pycor)) ]
      if my-tank = "sand" [set size gravel-size + random-float .2 set color random-sand-color]
      if my-tank = "rock" [set size gravel-size + random-float 1.2 set color random-rock-color]
      if my-tank = "plants" [set size gravel-size + random-float 1.2 set color random-plant-color]
      stamp
    ]
  ]
  ask rocks [die]
end

to-report ground-color [ ground ]
  if ground = "rock"   [ report brown + 0.5 ]
  if ground = "sand"   [ report grey + 0.8 ]
  if ground = "plants" [ report black + 2 ]
end

to-report random-sand-color
  report approximate-hsb (30 / 255 * 360) ((10 + random-float 50) / 255 * 100) ((150 + random-float 90) / 255 * 100)
end

to-report random-rock-color
  report approximate-hsb (30 / 255 * 360) ((30 + random-float 90) / 255 * 100) ((60 + random-float 160) / 255 * 100)
end

to-report random-plant-color
  report approximate-hsb (90 / 255 * 360) ((120 + random-float 100) / 255 * 100) ((random-float 160) / 255 * 100)
end

to setup-regions
  let min-pycor-edge min-pycor let max-pycor-edge max-pycor
  let water-patches nobody
  ask edges [die]
  ask patches [
    set tank 0
    set type-of-patch "water"
     if ((pxcor = min-pxcor + 1 or pxcor = max-pxcor - 1) or (pycor = min-pxcor + 1 or pycor = max-pxcor - 1) or (pycor = -1 or pycor = 1))
        [set type-of-patch "edge"]

     if (pycor = 0 or pxcor = min-pxcor or pxcor = max-pxcor or pycor = min-pxcor or pycor = max-pxcor)
        [set type-of-patch "outside-tank"]

     if pycor >= 1 [set tank 1]
     if pycor <= -1  [set tank 2]
     if type-of-patch = "outside-tank" [
       sprout-edges 1 [
         set color black
         set shape "edges"
       ]
     ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Runtime Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  every 0.2 [ ;; these procedures do not need to be called as often
    check-change-player-roles
    adjust-fish-population-size-to-carrying-capacity
    check-debris-count
    check-changed-tank
  ]
  listen-clients
  move-debris
  wander
  ask fish [grow-this-fish]
  calculate-statistics
  tick
end

to wander ;; fish procedure
  let nearest-water-patch nobody
  let water-patches patches with [type-of-patch = "water"]
  ask fish [
    rt random 70 - random 70
    fd motion-gene / 20

    set nearest-water-patch  min-one-of water-patches [distance myself]
    if type-of-patch != "water" [
      face nearest-water-patch
      fd motion-gene / 10
    ]
   ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Reproduction and Aging Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to grow-this-fish ;; fish procedure
 ;; grow the newly hatched offspring until they reach their ADULT-AGE, at which point they should be the full fish-SIZE
    let age ticks - birthday
    ifelse age < adult-age
      [ set size size-gene * (age / adult-age)]
      [ set size size-gene ]
      ask link-neighbors [set size [size] of myself]
end

;; keep a stable population of fish as predation and mating rates go up or down
to adjust-fish-population-size-to-carrying-capacity
  let #-fish-top-tank count fish with [tank = 1]
  let #-fish-bottom-tank count fish with [tank = 2]

  ;; adjust top tank
  if #-fish-top-tank = 0 [
    ;; if all the fish are removed by predators at once, make a new batch of random fish
    create-fish tank-capacity [make-one-initial-fish 1]
  ]
  if #-fish-top-tank < tank-capacity [
    ;; reproduce random other fish until you've reached the carrying capacity
    ask one-of fish with [tank = 1][ make-one-offspring-fish ]
  ]
  if #-fish-top-tank > tank-capacity [
    ;; remove other fish until you've reached the carrying capacity
    ask one-of fish with [tank = 1][ remove-fish ]
  ]

  ;; adjust bottom tank
  if #-fish-bottom-tank = 0 [
    ;; if all the fish are removed by predators at once, make a new batch of random fish
    create-fish tank-capacity [make-one-initial-fish 2]
  ]
  if #-fish-bottom-tank < tank-capacity [
    ;; reproduce random other fish until you've reached the carrying capacity
    ask one-of fish with [tank = 2][ make-one-offspring-fish ]
  ]
  if #-fish-bottom-tank > tank-capacity [
    ;; remove other fish until you've reached the carrying capacity
    ask one-of fish with [tank = 2][ remove-fish ]
  ]
end

to remove-fish ;; fish procedure
  ask link-neighbors [die] ;; kill fish parts first
  die
end

to make-one-offspring-fish ;; fish procedure
  hatch 1
  [
     set size 0
     if color-mutations? [mutate-body-color]
     if spot-mutations? [mutate-spot-transparency]
     if swim-mutations? [mutate-motion]
     if swim-mutations? [mutate-size]
     add-fish-spots
     color-this-fish
     grow-this-fish
     set birthday ticks
     lay-offspring
   ]
end

;; used to move fish slightly away from their parent
to lay-offspring ;; fish procedure
   let this-tank tank
   let birth-sites-in-radius patches with [distance myself <= offspring-distance]
   let birth-sites-in-tank birth-sites-in-radius with [tank = this-tank]
   if any? birth-sites-in-tank [ move-to one-of birth-sites-in-tank ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Visualization Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; a visualization technique to find fish if you are convinced they are not there anymore
;; it allows flashing without actually changing and recalculating the color attribute of the fish
to flash-fish
  repeat 3
  [
    ask fish [ set color black ask link-neighbors [set color black ]]
    wait 0.1
    display
    ask fish [ set color white ask link-neighbors [set color white ]]
    wait 0.1
    display
  ]
  ask fish [color-this-fish]
end

to check-finish-flash-predator-strike
  ask players [
    if hidden? = false and color = [0 0 0 200] [set hidden? true set color [255 255 255 200] ]
    if hidden? = false and color = [255 255 255 200] [set color [0 0 0 200]]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Environmental Debris Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-debris
  let top-debris debris with [tank = 1]
  let bottom-debris debris with [tank = 2]
  ask debris [
    if (top-water = "debris" and tank = 1) or (bottom-water = "debris" and tank = 2) [rt random-float 10 lt random-float 10] ;; drift
    if tank = 1 [fd top-flow ]
    if tank = 2 [fd bottom-flow ]
    ifelse type-of-patch = "outside-tank" [set hidden? true][set hidden? false]
    if pycor = 0 or pycor = min-pycor or pycor = max-pycor [die]
  ]
end

to check-changed-tank
  let ground-changed (top-ground != top-ground-previous-value or bottom-ground != bottom-ground-previous-value)
  let water-changed (top-water != top-water-previous-value or bottom-water != bottom-water-previous-value)
  if ground-changed or water-changed [
      if ground-changed [user-message "this change will take a few seconds" change-bottom]
      if water-changed [ask debris [set-debris-appearance] ]
      update-tank-states
  ]
end

to update-tank-states
  set top-ground-previous-value top-ground
  set bottom-ground-previous-value bottom-ground
  set top-water-previous-value top-water
  set bottom-water-previous-value bottom-water
end

to check-debris-count
  let floating-debris nobody
  let tank-patches nobody
  let target-debris 0
  foreach [1 2] [ this-tank ->
   set floating-debris debris with [tank = this-tank]
   set tank-patches patches with [tank = this-tank]
   set target-debris round ((amount-of-debris / 100) * count tank-patches)
   if target-debris > count floating-debris  ;; need more debris
     [ ask n-of (target-debris - count floating-debris) tank-patches [setup-debris-at-this-patch] ]
   if target-debris < count floating-debris  ;; need less debris
     [  ask n-of (count floating-debris - target-debris) floating-debris [ die ]  ]
  ]
end

to setup-debris-at-this-patch
  sprout-debris 1 [
    set size .5 + random-float 2
    set-debris-appearance
  ]
end

to set-debris-appearance
  if top-water = "clear" and tank = 1 [
    set heading 90
    set shape "empty"
  ]
  if bottom-water = "clear" and tank = 2 [
    set heading 90
    set shape "empty"
  ]
  if top-water = "ripples" and tank = 1 [
    set heading 0
    bk 0.5
    fd random-float 1
    set heading 90
    bk 0.5
    fd random-float 1
    set color ripple-debris-color
    set shape "ripples"
  ]
  if bottom-water = "ripples" and tank = 2 [
    set heading 0
    bk 0.5
    fd random-float 1
    set heading 90
    bk 0.5
    fd random-float 1
    set color ripple-debris-color
    set shape "ripples"
  ]
  if top-water = "debris" and tank = 1 [
    set heading random 360
    set color (list 0 (100 + random 155) 0 (50 + random 205))
    set shape "debris"
  ]
  if bottom-water = "debris" and tank = 2 [
    set heading random 360
    set color (list 0 (100 + random 155) 0 (50 + random 205))
    set shape "debris"
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; HubNet Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to listen-clients
  while [hubnet-message-waiting?] [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ add-player ]
    [
     ifelse hubnet-exit-message?
       [ remove-player ]
       [
         if ( listening? ) [
           if hubnet-message-tag = "View" [
             ask players with [ user-name = hubnet-message-source ] [check-caught-fish]
           ]
         ]
       ]
    ]
  ]
end

;; when a client logs in make a new player and give it the default attributes
to add-player
 create-players 1 [
    set user-name hubnet-message-source
    initialize-player
  ]
end

to initialize-player ;; player procedure
  hide-turtle
  set number-of-mates count players with [role = "mate"]
  set number-of-predators count players with [role = "predator"]
  if client-roles = "all mates"     [set role "mate"]
  if client-roles = "all predators" [set role "predator"]
  if client-roles = "mix of mates & predators" [
    ifelse number-of-mates >= number-of-predators
      [set role "predator"]
      [set role "mate"]
  ]
  set attempts 0
  set caught 0

  send-player-info
  broadcast-competition-info
end

to check-change-player-roles
  set number-of-mates count players with [role = "mate"]
  set number-of-predators count players with [role = "predator"]

  if old-client-roles != client-roles [
    ask players [
      set number-of-mates count players with [role = "mate"]
      set number-of-predators count players with [role = "predator"]
      if client-roles = "all mates" [set role "mate"]
      if client-roles = "all predators" [set role "predator"]
      if client-roles = "mix of mates & predators"  [
        ifelse number-of-mates >= number-of-predators [set role "predator"] [set role "mate"]
      ]
      send-player-info
      broadcast-competition-info
    ]
    set old-client-roles client-roles
  ]
end

;; when clients log out simply get rid of the player turtle
to remove-player
  ask players with [ user-name = hubnet-message-source ] [ die ]
end

to check-caught-fish
  ;; extract the coords from the hubnet message
  let clicked-xcor (item 0 hubnet-message)
  let clicked-ycor (item 1 hubnet-message)
  let this-tank 0
  if clicked-ycor > 0 [set this-tank 1]
  if clicked-ycor < 0 [set this-tank 2]

  ask players with [ user-name = hubnet-message-source ]
  [
    let this-player-role role
    set xcor clicked-xcor      ;; go to the location of the click
    set ycor clicked-ycor
    set attempts attempts + 1  ;; each mouse click is recorded as an attempt for that player

    ;;  if the players clicks close enough to a fish's location, they catch it
    ;;  the in-radius (fish-size / 2) calculation helps make sure the user catches the fish
    ;;  if they click within one shape radius (approximately since the shape of the fish isn't
    ;;  a perfect circle, even if the size of the fish is other than 1)
    let candidates fish with [(distance myself) < size / 2 and tank = this-tank]
    ifelse any? candidates
    [
      ;; randomly select one of the fish you clicked on
      let caught-fish one-of candidates
      set caught caught + 1

      ifelse this-player-role = "mate"
        [set mate-total-found mate-total-found + 1]
        [set predator-total-found predator-total-found + 1]
      ask caught-fish [
        ;; if you are a mate, kill of a random fish, make two offspring from your mating, and the selected mate is killed off too
        if this-player-role = "mate" [ make-one-offspring-fish make-one-offspring-fish ask one-of other fish with [tank = this-tank] [remove-fish ] remove-fish]
        ;; if you are a predator, make an offspring from another random fish, then remove the one you selected
        if this-player-role = "predator" [ ask one-of other fish with [tank = this-tank] [make-one-offspring-fish] remove-fish ]
      ]
      ;; if a fish is caught update the leader as it may have changed
      update-leader-stats
      ;; all the players have monitors displaying information about the leader
      ;; so we need to make sure that gets updated when the leader changed
      ask players
      [
        send-player-info
        broadcast-competition-info
      ]
    ]
    ;; even if we didn't catch a fish we need to update the attempts monitor
    [ send-player-info broadcast-competition-info]
  ]
end

;; update the monitors on the client
to send-player-info ;; player procedure
  hubnet-send user-name "Your name" user-name
  hubnet-send user-name "Your role" role
  hubnet-send user-name "You have found" caught
  hubnet-send user-name "# Attempts"  attempts
end

to broadcast-competition-info
  hubnet-broadcast "# of predators" count players with [role = "predator"]
  hubnet-broadcast "Top predator" predator-leader
  hubnet-broadcast "Top predator's catches" predator-leader-caught
  hubnet-broadcast "# of mates" count players with [role = "mate"]
  hubnet-broadcast "Top mate" mate-leader
  hubnet-broadcast "Top mate's matings" mate-leader-caught
end

;; do the bookkeeping to display the proper leader and score
to update-leader-stats
  let all-predators players with [role = "predator"]
  let all-mates players with [role = "mate"]

  if any? all-predators  [
     let predator-leaders all-predators with-max [ caught ]
     let number-predator-leaders count predator-leaders
     ifelse number-predator-leaders > 1  ;; if there is more than one leader just report a tie otherwise report the name
         [ set predator-leader word number-predator-leaders "-way tie" ]
         [ ask one-of predator-leaders [ set predator-leader user-name ] ]
         set predator-leader-caught [caught] of one-of predator-leaders
  ]
  if any? all-mates [
    let mate-leaders all-mates with-max [ caught ]
    let number-mate-leaders count mate-leaders
    ifelse number-mate-leaders > 1  ;; if there is more than one leader just report a tie otherwise report the name
       [ set mate-leader word number-mate-leaders "-way tie" ]
       [ ask one-of mate-leaders [ set mate-leader user-name ] ]
       set mate-leader-caught [caught] of one-of mate-leaders
   ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Mutation Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; three possible random mutations can occur, one in each frequency of gene expression
  ;; the max-color-mutation-step determines the maximum amount the gene frequency can drift up
  ;; or down in this offspring

to mutate-body-color ;; fish procedure
   let red-mutation   random (max-color-mutation-step + 1) - random (max-color-mutation-step + 1)
   let green-mutation random (max-color-mutation-step + 1) - random (max-color-mutation-step + 1)
   let blue-mutation  random (max-color-mutation-step + 1) - random (max-color-mutation-step + 1)
   set red-gene   limit-gene (red-gene   + red-mutation)
   set green-gene limit-gene (green-gene + green-mutation)
   set blue-gene  limit-gene (blue-gene  + blue-mutation)
end

to mutate-spot-transparency ;; fish procedure
   let max-spot-transparency 255
   let min-spot-transparency 25
   set spot-transparency-gene spot-transparency-gene + (random-float 20) - (random-float 20)
   if spot-transparency-gene > max-spot-transparency [set spot-transparency-gene max-spot-transparency]
   if spot-transparency-gene < min-spot-transparency [set spot-transparency-gene min-spot-transparency]
end

to mutate-motion ;; fish procedure
   let max-motion 10
   let min-motion 0
   set motion-gene motion-gene + (random-float .5) - (random-float .5)
   if motion-gene > max-motion [set motion-gene max-motion]
   if motion-gene < min-motion [set motion-gene min-motion]
end

to mutate-size ;; fish procedure
   let max-size 1.5
   let min-size .5
   set size-gene size-gene + (random-float .1) - (random-float .1)
   if size-gene > max-size [set size-gene max-size]
   if size-gene < min-size [set size-gene min-size]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Reporters ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; imposes a threshold limit on gene-frequency.
;; without this genes could drift into negative values
;; or very large values (any value above 100%)
to-report limit-gene [gene]
  if gene < 0   [ report 0   ]
  if gene > 255 [ report 255 ]
  report gene
end

to-report my-tank
  let value-to-report ""
  if which-tank = "top tank"    [ set value-to-report top-ground]
  if which-tank = "bottom tank" [ set value-to-report  bottom-ground]
  report value-to-report
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Statistics Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-statistics
  set tank-1-avg-spot-transparency mean [ spot-transparency-gene ] of fish with [tank = 1]
  set tank-2-avg-spot-transparency mean [ spot-transparency-gene ] of fish with [tank = 2]
  set tank-1-avg-motion mean [ motion-gene ] of fish with [tank = 1]
  set tank-2-avg-motion mean [ motion-gene ] of fish with [tank = 2]
  set tank-1-avg-size mean [ size-gene ] of fish with [tank = 1]
  set tank-2-avg-size mean [ size-gene ] of fish with [tank = 2]
end


; Copyright 2012 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
463
10
1011
559
-1
-1
20.0
1
10
1
1
1
0
1
1
1
-13
13
-13
13
1
1
1
time
30.0

BUTTON
10
10
90
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
95
10
187
43
go/pause
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
50
150
83
tank-capacity
tank-capacity
2
30
15.0
1
1
fish
HORIZONTAL

BUTTON
365
10
455
43
flash fish
flash-fish
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
153
50
328
95
client-roles
client-roles
"all mates" "all predators" "mix of mates & predators"
0

SLIDER
160
205
460
238
amount-of-debris
amount-of-debris
0
100
100.0
5
1
%
HORIZONTAL

SWITCH
10
585
160
618
spot-mutations?
spot-mutations?
0
1
-1000

SWITCH
10
330
160
363
swim-mutations?
swim-mutations?
1
1
-1000

SWITCH
10
205
155
238
color-mutations?
color-mutations?
0
1
-1000

PLOT
160
365
460
495
Avg. Fish Size
time
size
0.0
3.0
0.0
3.0
true
true
"" ""
PENS
"top tank" 1.0 0 -16777216 true "" "plot tank-1-avg-size"
"bottom tank" 1.0 0 -7500403 true "" "plot tank-2-avg-size"

PLOT
160
245
460
365
Avg. Fish Motion
time
motion
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"top tank" 1.0 0 -16777216 true "" "plot tank-1-avg-motion"
"bottom tank" 1.0 0 -7500403 true "" "plot tank-2-avg-motion"

CHOOSER
130
105
228
150
top-water
top-water
"clear" "ripples" "debris"
1

MONITOR
400
50
460
95
matings
mate-total-found
0
1
11

MONITOR
329
50
399
95
predations
predator-total-found
0
1
11

CHOOSER
230
150
340
195
bottom-ground
bottom-ground
"sand" "rock" "plants" "nothing"
2

CHOOSER
230
105
341
150
top-ground
top-ground
"sand" "rock" "plants" "nothing"
0

CHOOSER
130
150
228
195
bottom-water
bottom-water
"clear" "ripples" "debris"
2

SLIDER
11
105
131
138
top-flow
top-flow
0
.25
0.16
.01
1
NIL
HORIZONTAL

SLIDER
11
150
131
183
bottom-flow
bottom-flow
0
.25
0.06
.01
1
NIL
HORIZONTAL

PLOT
160
495
460
620
Avg. Fish Spotting
time
spotting
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"top tank" 1.0 0 -16777216 true "" "plot tank-1-avg-spot-transparency"
"bottom tank" 1.0 0 -7500403 true "" "plot tank-2-avg-spot-transparency"

SWITCH
10
460
160
493
size-mutations?
size-mutations?
0
1
-1000

CHOOSER
340
150
460
195
bottom-initial-fish
bottom-initial-fish
"multi-colored" "all gray" "black or white"
0

CHOOSER
340
105
460
150
top-initial-fish
top-initial-fish
"multi-colored" "all gray" "black or white"
0

SWITCH
245
10
361
43
listening?
listening?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is a HubNet activity of natural selection.  This selection model shows how the interaction of mates and predators on a population can generate two opposing pressures from natural selection. One of these pressures is from sexual selection and the other is from predation.

When you run the model, you can either play the role of a predator or the role of a mate.

As a predator, you will try to find fish, trying to click on them to "eat" them as fast as you can.  As you hunt it is likely that you will find more fish that are easier to see.  In other words, the more the appearance of the fish stands out from the background, the more likely it will be seen by you, the predator. In this model the fish population over many generations, pushed by predation pressures, will adapt to accumulate trait variations that make them better camouflaged and harder to find.  Such changes typically include a smaller body size, a color similar to the tank background, spotting (or lack of) that makes the fish appear to have a texture similar to the background, and movement that is similar to the movement of the debris in its environment.

As a mate, you will try to mate with fish by clicking on them.  As you mate with more and more fish, you will notice that it becomes progressively easier to find fish.  In this model the fish population over many generations, pushed by sexual selection pressures, will adapt to accumulate trait variations that make them easier to find.   Such changes typically include a larger body size, a color that is "flashier" against the background, spotting (or lack of) that makes the fish appear to have a texture different than the background, and movement that is different than the movement of the debris in its environment.  The "flashier" a male fish is, the more likely a female fish will choose him as a mate, passing his genes to the next generation. This is sexual selection at work, and it is the force that drives the fish population to greater conspicuousness.

When both predators and mates interact with a population the outcomes are more difficult to predict, since each type of interaction tends to counterbalance the effects of the other type.

Quoting from "Sex and the Single fish"  [2]:
There may be several evolutionary reasons why fishs (or fish) prefer flashier mates. On the most basic level, the male with the biggest, brightest tail spot announces most loudly, "Hey, I'm over here" to any female it can see. Flashy colors are simply easier to locate.  However, there is also research to suggest that bright colors serve as an indicator of good genes in the way the strong physique of a human athlete is a direct indicator of that individual's health and vitality.  Or, bright coloration may signal to a potential mate that he's got something else going for him. After all, he's been able to survive the very handicap -- conspicuousness to predators -- that his flashiness creates.

## HOW IT WORKS

You can assume either the role of a predator or the role of a mate.

When the HubNet simulation is started after pressing GO, participants should try to click on fish as fast as they can with the mouse.

Each participant can monitor his or her relative success compared to other participants by watching the monitors in the client that show the TOP PREDATOR (the person with most catches), how many that person caught (TOP PREDATOR'S CATCHES) or TOP MATE (the person with most catches), how many that person caught (TOP MATE'S MATINGS).

When GO is pressed, if you are a predator you should try to click on the fish, as fast as you can, in order to eat them.  Each time you click on a fish it will be removed from the fish population.  At that point, another randomly selected fish in the population will hatch an offspring to replace the one that was caught (keeping the population of fish constant).

If you are a mate (a female fish), you should try to click on the male fish as fast as you can (they are all males).  When you click on a fish that is old enough to mate, your mating will hatch an offspring that is similar in appearance to its dad.  In this way the population increases with each mating event.  But, when the population of fish exceeds the carrying capacity, a random fish will be removed.

Each new offspring fish may undergo small mutations in its genetics for its color, size, motion, and visibility of a spotting pattern (5 spots) based on the genetic information inherited from the fish clicked on (the male) only.

Predators prey on the most easily spotted individuals more often than those that are hard to spot eliminating them from the gene pool. Thus, predators cause fish populations to remain relatively drab, small, and still (with respect to colors and patterns of the environment they live in).

However, fish looking for a mate exert the opposite selection.  Relatively small drab fish are hard to find and mate with, while large fish with garish colors and patterns that move in patterns that help them stand out are easier to find.  As these fish reproduce, the frequency of their genes increases in the gene pool.

The adaptation of the population in terms of movement is sometimes harder to predict than color changes.  In environments with lots of motion (debris floating in water currents, ripples on the surface of the water) staying still might actually cause a fish to stand out, just as moving much faster than the surroundings would also make a fish stand out.

The adaptation of spotting patterns for a population is also sometimes harder to predict than color changes.  In environments with a grainy background, spotting may help the fish blend in.  However, in an environment with large regular colored shapes (rocks), spots might make the fish stand out.

In general however, the population will evolve to blend in, and/or stand out (being more easily spotted), from their environment depending on which of the selective pressures are stronger.  When there is an equal number of predators and mates, the selective pressures may not strongly push the adaptation of the population in a clear direction - the result may be a population that is balanced between having traits that help the fish stand out and traits that help the fish remain hidden.

When you run the simulation you can set up two different tank environments to compare the outcomes from the same selective pressures from mates and predators in these different surroundings.

## HOW TO USE IT

To run the activity press the GO/PAUSE button.  To start the activity over with the same group of students stop the GO/PAUSE button by pressing it again, press the SETUP button, and press GO/PAUSE again.

Make sure you select Mirror 2D view on clients in the HubNet Control Center after you press SETUP.

LISTENING? when switched "off," prevents clients from clicking on the WORLD & VIEW and selecting fishes.  Turn this switch to "on" after GO/STOP is pressed to allow clients to interact with the fishes and turn it "off" if you want to ignore any of the mouse clicks registered in the client windows.

CLIENT-ROLES can be set to "all mates", in which case every client assumes the role of a a mate, or it can be set to "all predators", in which case every client assumes the role of a predator.  This chooser can also be set to "mix of predators & mates", in which case for every client assigned the role of a predator, the next client is assigned the role of a mate.  This last setting allows you to coordinate an experiment where all the mates interact with the fish in one tank and all the predators interact with the fish in another tank.  While such coordination can be directed by the teacher, or designed by the entire class, this model is embedded within the BEAGLE curriculum, and serves as a test bed for designing an experiment by a team of students.  Decisions about how to coordinate participant roles in such an experiment is part of the challenge of the related student activities.

TANK-CAPACITY determines the size of the population in each of the two tanks on SETUP.  It also determines how many fish are in each tank at one time when GO is pressed and fish are being eaten or offspring are being produced.  Sliding it back and forth while the model runs can simulate the effects of population effects and founder effects, since it will cause the population to be culled or undergo a population boom, depending which way you slide it.

TOP-WATER specifies the type of debris in the water.  "Ripples" move from left to right, while "debris" represent leaves that drift around the tank.  TOP-FLOW specifies how fast this debris moves. BOTTOM-WATER and BOTTOM-FLOW specify these same values for the bottom tank.

TOP-GROUND specifies the type of background to draw in the top tank.  BOTTOM-GROUND specified it for the bottom tank.  While this value will often be set before the model is run, when the value of either option is changed during a model run, the environment is automatically updated.

TOP-INITIAL-FISH specifies the colors of the fish in the initial population in each tank.  "Multi-colored" sets each fish to a random set of rgb value genes, "All gray" sets each fish to have equal values of 150 150 150 for its rgb gene values.  And "Black or white" sets each fish to have either the rgb gene values of 0 0 0 (black) or 255 255 255 (white).

AMOUNT-OF-DEBRIS controls the % of debris in the tanks.  100% will populate the tank with the same amount of debris (leaves or ripples) as there are patches in the tank.

COLOR-MUTATIONS? when set to "on" allows offspring to incur mutations in their color they inherit.

SWIM-MUTATIONS? when set to "on" allows offspring to incur mutations in the amount of motion they inherit.  AVG. FISH MOTIONS keeps track of the average gene values for each population (the top tank and bottom tank)

SIZE-MUTATIONS? when set to "on" allows offspring to incur mutations in the adult body size they inherit. AVG. FISH SIZE keeps track of the average gene values for size for each population (the top tank and bottom tank)

SPOT-MUTATIONS? when set to "on" allows offspring to incur mutations in the visibility of a 5 spot pattern near its tail.  When the gene is 0, the spot pattern is completely transparent.  When the gene is 255, the spot pattern is completely opaque (black).  AVG. FISH SPOTTING keeps track of the average gene values for spotting for each population (the top tank and bottom tank)

The PREDATIONS monitor keeps track of how many fish the predators have caught.

The MATING monitor keeps track of the number of mating events that have occurred.

FLASH FISH will temporarily alternately flash the fish black and white so that they are visible.  This will last for about 3 seconds.

## THINGS TO NOTICE

Fish get smaller and harder to find over time when only predators are present.  Fish get larger and easier to find over time when only mates are present.  Fish motion depends on the amount of environmental movement in the background.  If the background has little environmental movement, then fish with a lot of movement stand out, but if the background has some amount of environmental movement, then fish with a less (or a lot more) movement stand out.

## THINGS TO TRY

If you are having trouble finding the fish, it is useful to press FLASH to show where they are (and how they are camouflaged);

Try setting up experiments where the predators prey on only fish in one tank and the mates only breed with fish in the other tank.

## EXTENDING THE MODEL

What if fish needed to move and eat food to survive?  Would that create other counter balancing selective pressure?  What if fish released pheromones for other creatures to detect?  Could that replace the need for garish appearances?   Would mates evolve pheromones that could be detected only by mates and not predators?

## NETLOGO FEATURES

IN-RADIUS is the primitive used to check if the mouse is within the graphical "footprint" of a turtle.

This model uses RGB colors, that is, colors expressed as a three item list of red, green and blue.  This gives a larger range of color possibilities than with NetLogo colors.

The background for each fish tank is created using the stamp command for turtle images of plants and rocks.

## RELATED MODELS

Bub Hunters Camouflage
Peppered Moth

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

[1] Inspired by Sex and the Single Guppy http://www.pbs.org/wgbh/evolution/sex/guppy/index.html

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2012).  NetLogo Fish Spotters HubNet model.  http://ccl.northwestern.edu/netlogo/models/FishSpottersHubNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the HubNet software as:

* Wilensky, U. & Stroup, W. (1999). HubNet. http://ccl.northwestern.edu/netlogo/hubnet.html. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2012 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2012 Cite: Novak, M. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 15 40 220 150 175 260 220

0 spots
false
15
Circle -1 true true 114 174 12

1 spots
false
15
Circle -1 true true 114 174 12

2 spots
false
15
Circle -1 true true 84 129 12
Circle -1 true true 114 174 12

4 spots
false
15
Circle -1 true true 84 129 12
Circle -1 true true 66 161 12
Circle -1 true true 159 174 12
Circle -1 true true 114 174 12

5 spots
false
15
Circle -1 true true 84 129 12
Circle -1 true true 66 161 12
Circle -1 true true 129 129 12
Circle -1 true true 159 174 12
Circle -1 true true 114 174 12

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

debris
true
0
Polygon -7500403 true true 90 180 90 225 180 180 240 90 165 90

dot
false
0
Circle -7500403 true true 90 90 120

edges
false
0
Rectangle -7500403 true true 0 0 300 300

empty
true
0

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
Polygon -7500403 true true 60 150 30 75 0 60 0 120 12 150 0 180 0 240 30 225 60 150
Polygon -7500403 true true 165 195 149 235 125 218 106 210 76 204 90 165
Polygon -7500403 true true 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 45 135 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 45 165
Circle -16777216 true false 225 105 30

fish-body
false
11
Polygon -7500403 true false 90 120 105 90 90 75 60 60 120 60 150 75 165 105
Polygon -7500403 true false 60 180 45 210 75 210 90 240 120 195
Polygon -8630108 true true 15 135 151 92 226 96 280 134 292 161 292 175 287 185 270 210 195 225 151 227 15 165
Circle -16777216 true false 236 125 34
Line -1 false 256 143 264 132

fish-fins
false
2
Polygon -955883 true true 45 0 75 45 71 103 75 120 165 105 120 30
Polygon -955883 true true 75 180 45 240 90 225 105 270 135 210

fish-spots
false
15
Circle -1 true true 84 129 12
Circle -1 true true 66 161 12
Circle -1 true true 129 129 12
Circle -1 true true 159 174 12
Circle -1 true true 114 174 12

fish-tail
false
5
Polygon -10899396 true true 150 135 105 75 45 0 75 90 105 150 75 195 45 300 105 225 150 165

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

hawk
true
0
Polygon -7500403 true true 166 230 165 255 138 289 158 304 171 304 194 289 165 255
Polygon -16777216 true false 166 222 165 247 143 285 155 295 176 294 189 285 165 247
Polygon -7500403 true true 175 164 174 151 164 144 145 143 154 152 148 171 142 203 150 240 154 262 165 296 175 264 180 240 184 201
Polygon -7500403 true true 153 175 224 159 285 179 271 183 293 199 275 200 286 213 269 213 277 223 263 220 266 227 227 232 152 229
Circle -16777216 true false 159 145 7
Polygon -16777216 true false 144 143 150 148 154 144
Polygon -7500403 true true 168 171 94 158 35 177 51 182 27 197 45 198 34 211 51 211 43 221 57 218 54 225 93 230 168 227
Polygon -7500403 true true 165 214 164 239 142 277 154 287 175 286 188 277 164 239
Polygon -16777216 true false 171 251 164 246 143 270 155 280 176 279 189 270 161 251
Polygon -7500403 true true 165 201 164 226 149 261 154 274 175 273 181 260 164 226
Polygon -16777216 false false 145 142 154 152 149 168 92 158 33 176 49 182 25 196 45 197 33 211 52 211 42 221 57 218 52 225 93 231 147 228 150 240 150 252 149 267 143 271 145 272 141 276 145 281 137 289 150 300 177 300 194 289 184 279 189 275 185 274 188 271 179 262 181 258 176 253 181 240 181 230 228 233 267 227 261 219 277 222 267 213 286 213 275 200 292 198 271 182 285 178 226 159 175 170 174 151 164 144

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

moth
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -7500403 true true 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -7500403 true true 135 90 30
Line -7500403 true 150 105 195 60
Line -7500403 true 150 105 105 60

moth-black
true
0
Polygon -16777216 true false 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -16777216 true false 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -16777216 true false 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -16777216 true false 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

moth-white
true
0
Polygon -1 true false 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -1 true false 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -1 true false 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -1 true false 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -1 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -1 true false 135 90 30
Line -1 false 150 105 195 60
Line -1 false 150 105 105 60

moth-wing-left
true
0
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 150 165

moth-wing-right
true
0
Polygon -7500403 true true 150 165 211 198 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 161 148 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 194 150 165

mud
true
0
Polygon -7500403 true true 30 165 90 225 90 270 165 225 255 225 180 150 105 180
Polygon -7500403 true true 60 45 60 135 150 90 135 75 150 45 90 75

nothing
true
0

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

plants
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

ripples
true
0
Polygon -7500403 true true 0 195 60 165 135 150 165 150 240 165 300 195 240 150 195 124 149 117 109 124 60 150
Line -1 false 300 195 240 150
Line -1 false 240 150 190 125
Line -1 false 191 125 152 117
Line -1 false 109 125 148 117
Line -1 false 60 150 110 125
Line -1 false 0 195 60 150

rock
true
0
Circle -7500403 true true 72 72 216
Circle -7500403 true true 45 45 180
Polygon -7500403 true true 49 165 97 252 249 93 167 50

sand
true
0
Circle -7500403 true true 159 24 42
Circle -7500403 true true 234 69 42
Circle -7500403 true true 249 144 42
Circle -7500403 true true 99 219 42
Circle -7500403 true true 24 144 42
Circle -7500403 true true 114 84 42
Circle -7500403 true true 204 234 42
Circle -7500403 true true 159 144 42
Circle -7500403 true true 39 54 42

spots
false
0
Polygon -7500403 true true 60 150 30 75 0 60 0 120 12 150 0 180 0 240 30 225 60 150
Polygon -7500403 true true 165 195 149 235 125 218 106 210 76 204 90 165
Polygon -7500403 true true 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 45 135 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 45 165
Circle -1 true false 125 166 30
Circle -1 true false 80 136 30
Circle -1 true false 125 106 30
Circle -1 true false 185 166 30

square
true
0
Polygon -7500403 true true 213 196 48 199 43 98 109 35 210 34

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

tank-edges
false
0
Rectangle -7500403 true true 0 0 300 300

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
MONITOR
6
10
131
59
Your name
NIL
0
1

MONITOR
156
58
281
107
You have found
NIL
3
1

MONITOR
159
10
284
59
# Attempts
NIL
0
1

MONITOR
5
202
151
251
Top predator
NIL
0
1

MONITOR
4
252
151
301
Top predator's catches
NIL
3
1

MONITOR
163
200
284
249
Top mate
NIL
3
1

MONITOR
163
250
284
299
Top mate's matings
NIL
3
1

MONITOR
8
58
132
107
Your role
NIL
3
1

MONITOR
21
150
123
199
# of predators
NIL
3
1

MONITOR
182
151
260
200
# of mates
NIL
3
1

VIEW
297
10
837
550
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
-13
13
-13
13

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
