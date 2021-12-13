globals [
  player-1 player-2 player-3 player-4       ;; player names
  player-1-cage-color player-2-cage-color   ;; colors for cages (patches) for each player
  player-3-cage-color player-4-cage-color
  player-1-tag-color  player-2-tag-color    ;; colors for tags (visualization of where the destination patch is for a moving bird)
  player-3-tag-color  player-4-tag-color

  genes-to-phenotype                        ;; a list that contains a map of genotypes to phenotypes
  parent-female  parent-male                ;; the two parents of a breeding event - used for determining genotype of any potential eggs

  frequency-allele-dominant-second-trait    ;; keeps track of allele frequencies in the gene pool of the current population (of birds, but not eggs)
  frequency-allele-dominant-first-trait
  frequency-allele-recessive-second-trait
  frequency-allele-recessive-first-trait
  frequency-allele-dominant-third-trait
  frequency-allele-recessive-third-trait
  frequency-allele-dominant-fourth-trait
  frequency-allele-recessive-fourth-trait

  #-birds-with-1-target-trait               ;; used for keeping track of phenotype frequencies
  #-birds-with-2-target-traits
  #-birds-with-3-target-traits
  #-birds-with-4-target-traits

  breeding-site-color-1                     ;; colors for the patches that are breeding sites
  breeding-site-color-2
  bird-body-color                           ;; color of the bird body shape
  bird-size                                 ;; size of bird shape
  egg-size                                  ;; size of egg shape
  current-instruction                       ;; which instruction the player is viewing

  number-of-goal-birds                      ;; keeps track of how many birds you have currently that have the phenotype combinations you have been trying to breed for.
  sequencings-performed                     ;; keeps track of the number of DNA sequencings performed
  sequencings-left                          ;; keeps track of the number of sequencings left
  number-offspring                          ;; keeps track of number of eggs laid
  number-hatchings                          ;; keeps track of number of eggs hatched at cages
  number-releases                           ;; keeps track of number of eggs and birds released into the wild (grass patches)
  number-matings                            ;; keeps track of number of matings
  number-selections                         ;; keeps track of number of releases + number of eggs hatched at cages
  new-selection-event-occurred?             ;; turns true when number-selections increments by 1.  This is used for updating the genotype and phenotype graphs
]


breed [grasses grass]                      ;; used for the shapes on the patches that are considered the "wild"
breed [DNA-sequencers DNA-sequencer]       ;; used for the shape that shows the location of where DNA tests can be conducted for eggs or birds (test tube shape)
breed [cages cage]                         ;; used for the shape of cages - black lined square
breed [selection-tags selection-tag]       ;; the selection tag is a visualization tool - it is assigned to a bird or egg that is selected with the mouse
breed [destination-flags destination-flag] ;; the destination flag is a visualization tool - it is a turtle showing the target patch where the bird or egg is headed
breed [karyotype-tags karyotype-tag]         ;; the karyotype tag is a visualization tool - it allows the genotype to be displayed off center of the bird
breed [birds bird]                         ;; the creature that is being bred
breed [eggs egg]                           ;; what is laid by birds and must be returned to cages to hatch into birds
breed [first-traits  first-trait]          ;; shape that is the crest in birds
breed [second-traits second-trait]         ;; shape that is the wings in birds
breed [third-traits  third-trait]          ;; shape that determines breast in birds
breed [fourth-traits  fourth-trait]          ;; shape that determines tail in birds
breed [players player]                     ;; one player is assigned to each participant



patches-own [site-id patch-owned-by closed? reserved?]
players-own [user-id player-number moving-a-bird? origin-patch assigned?]

birds-own [
  owned-by                                                                ;; birds are owned-by a particular user-id.
  first-genes second-genes third-genes fourth-genes fifth-genes sex-gene   ;; genetic information is stored in these five variables
  transporting? breeding? selected? just-bred? sequenced? released?       ;; the state of the bird is stored in these seven variables
  destination-patch                                                       ;; this variable is used for keeping track of where the bird is moving toward
  release-counter                                                         ;; counts down to keep track of how to visualize the "fading" out of a released bird
]

eggs-own  [
  owned-by                                                                ;; eggs are owned-by a particular user-id.
  first-genes second-genes third-genes fourth-genes fifth-genes sex-gene   ;; genetic information is stored in these five variables
  transporting? breeding? selected? just-bred? sequenced? released?       ;; the state of the egg is stored in these seven variables
  destination-patch                                                       ;; this variable is used for keeping track of where the egg is moving toward
  release-counter                                                         ;; counts down to keep track of how to visualize the "fading" out of a released egg
]

;; owned-by corresponds a particular user-id
dna-sequencers-own    [owned-by]
selection-tags-own    [owned-by]
destination-flags-own [owned-by]
first-traits-own      [owned-by first-genes  ]
second-traits-own     [owned-by second-genes ]
third-traits-own      [owned-by third-genes  ]
;; the fourth trait related to presence of feathers (head cap) is sex linked - it only appears if the individual is male)
fourth-traits-own     [owned-by fourth-genes fifth-genes sex-gene ]



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;  setup procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to startup
  setup
  hubnet-reset
  make-players
end


to setup
  ;; these clear commands are used in place of clear all, because SETUP should not remove the players from the simulation
  clear-patches
  clear-drawing
  clear-all-plots
  clear-non-player-turtles
  reset-player-numbers

  set parent-female nobody
  set parent-male nobody
  set number-of-goal-birds 0
  set number-selections 0
  set number-matings 0
  set number-releases 0
  set number-hatchings 0
  set number-offspring 0
  set sequencings-performed 0
  set sequencings-left (max-#-of-DNA-tests - sequencings-performed)
  set new-selection-event-occurred? false
  set #-birds-with-1-target-trait 0
  set #-birds-with-2-target-traits 0
  set #-birds-with-3-target-traits 0
  set #-birds-with-4-target-traits 0
  set bird-body-color       [200 200 200 255]
  set breeding-site-color-1 (gray + 2.0)
  set breeding-site-color-2 (gray + 4.0)
  set player-1-cage-color   (pink + 1.5)
  set player-2-cage-color   (green + 1.5)
  set player-3-cage-color   (brown + 1.5)
  set player-4-cage-color   (turquoise + 1.5)
  set player-1-tag-color   player-1-cage-color  - 5
  set player-2-tag-color   player-2-cage-color  - 5
  set player-3-tag-color   player-3-cage-color  - 5
  set player-4-tag-color   player-4-cage-color  - 5
  set bird-size 0.8
  set egg-size  0.55

  set genes-to-phenotype [
    ;; sets crest colors
    ["AA" "set color [150 150 150 255]"]
    ["Aa" "set color [150 150 150 255]"]
    ["aA" "set color [150 150 150 255]"]
    ["aa" "set color [0 150 255 255]"]
    ;; sets wing colors
    ["BB" "set color [150 150 150 255]"]
    ["Bb" "set color [150 150 150 255]"]
    ["bB" "set color [150 150 150 255]"]
    ["bb" "set color [155 0 100 255]"]
    ;; sets chest colors
    ["CC" "set color [150 150 150 255]"]
    ["Cc" "set color [150 150 150 255]"]
    ["cC" "set color [150 150 150 255]"]
    ["cc" "set color [255 0 200 255]"]
    ;; sets tail colors
    ["DD" "set color [150 150 150 255]"]
    ["Dd" "set color [150 150 150 255]"]
    ["dD" "set color [150 150 150 255]"]
    ["dd" "set color [255 0 0 255]" ]
  ]

  set-default-shape birds "bird"
  set-default-shape first-traits "bird-cap"
  set-default-shape second-traits "bird-wing"
  set-default-shape third-traits "bird-breast"
  set-default-shape fourth-traits "bird-tail"
  set-default-shape karyotype-tags "karyotype-tag"
  set-default-shape DNA-sequencers "test-tubes"
  set-default-shape selection-tags "tag"
  set-default-shape destination-flags "flag"
  set-default-shape DNA-sequencers "test-tubes"

  ask patches [set pcolor white set reserved? false]
  setup-cages
  setup-DNA-sequencers
  setup-breeding-sites
  setup-grasses
  calculate-all-alleles

  show-instruction 1
  reset-ticks
end


to make-players
  let player-number-counter 1
  create-players 4 [
    set hidden? true  ;; players are invisible agents
    set player-number player-number-counter
    set player-number-counter player-number-counter + 1
    set user-id ""        ;; this player is currently unassigned to a participant
    set assigned? false
  ]
end


to clear-non-player-turtles
   ask grasses [die]
   ask cages [die]
   ask DNA-sequencers [die]
   ask birds [die]
   ask eggs [die]
   ask selection-tags [die]
   ask destination-flags [die]
   ask karyotype-tags [die]
   ask first-traits [die]
   ask second-traits [die]
   ask third-traits [die]
   ask fourth-traits [die]
end


to reset-player-numbers
  set player-1 ""  set player-2 ""  set player-3 ""   set player-4 ""
  ask players [
    if player-number = 1 [set player-1 user-id]
    if player-number = 2 [set player-2 user-id]
    if player-number = 3 [set player-3 user-id]
    if player-number = 4 [set player-4 user-id]
  ]

end


to setup-cages
   let these-cages nobody
   ;; make cages and birds for player 1
   set these-cages patches with [pxcor = -4 and pycor <= 3 and pycor >= -2]
   ask these-cages [set pcolor player-1-cage-color  set patch-owned-by 1 sprout 1 [set breed cages set shape "cage"]]
   ask n-of 3 these-cages  [setup-birds]
   ;; make cages and birds for player 2
   set these-cages patches with [pxcor <= 3 and pxcor >= -2 and pycor = 5]
   ask these-cages [set pcolor player-2-cage-color set patch-owned-by 2 sprout 1 [set breed cages set shape "cage"]]
   ask n-of 3 these-cages  [setup-birds]
   ;; make cages and birds for player 3
   set these-cages patches with [pxcor = 5 and pycor >= -2 and pycor <= 3]
   ask these-cages [set pcolor player-3-cage-color  set patch-owned-by 3 sprout 1 [set breed cages set shape "cage"]]
   ask n-of 3 these-cages  [setup-birds]
   ;; make cages and birds for player 4
   set these-cages patches with [pycor = -4 and pxcor >= -2 and pxcor <= 3]
   ask these-cages [set pcolor player-4-cage-color set patch-owned-by 4 sprout 1 [set breed cages set shape "cage"]]
   ask n-of 3 these-cages  [setup-birds]
end


to setup-birds
   let this-cage patch-owned-by
   sprout 1 [
     build-body-base
     set owned-by this-cage
     assign-all-genes
     build-body-parts
   ]
end


to setup-DNA-sequencers
  ask patch min-pxcor max-pycor [
    set patch-owned-by 1
    sprout 1 [set breed DNA-sequencers]
  ]
  ask patch (max-pxcor) max-pycor  [
    set patch-owned-by 2
    sprout 1 [set breed DNA-sequencers]
  ]
  ask patch max-pxcor min-pycor [
    set patch-owned-by 3
    sprout 1 [set breed DNA-sequencers]
  ]
  ask patch (min-pxcor ) min-pycor  [
    set patch-owned-by 4
    sprout 1 [set breed DNA-sequencers]
  ]
  ask DNA-sequencers [
    set color 68
    set label-color gray - 2.5
    set label (word patch-owned-by " ")
  ]
end


to setup-breeding-sites
   ask patches with [pxcor >= -2 and pxcor <= -1 and pycor <= 3 and pycor >= 1]
     [set pcolor breeding-site-color-1   set site-id 1]
   ask patches with [pxcor >= 0 and pxcor <= 1 and pycor <= 3 and pycor >= 1]
     [set pcolor breeding-site-color-2    set site-id 2]
   ask patches with [pxcor >= 2 and pxcor <= 3 and pycor <= 3 and pycor >= 1]
     [set pcolor breeding-site-color-1    set site-id 3]
   ask patches with [pxcor >= -2 and pxcor <= -1 and pycor <= 0 and pycor >= -2]
     [set pcolor breeding-site-color-2  set site-id 4]
   ask patches with [pxcor >= 0 and pxcor <= 1 and pycor <= 0 and pycor >= -2]
     [set pcolor breeding-site-color-1 set site-id 5]
   ask patches with [pxcor >= 2 and pxcor <= 3 and pycor <= 0 and pycor >= -2]
     [set pcolor breeding-site-color-2 set site-id 6]
end


to setup-grasses
  ask patches with [is-a-release-site?] [
    sprout 1 [
      set breed grasses
      set shape "grass"
      set color [50 150 50 150]
      set heading random 360
      fd random-float .45   ;; move the grass shape a bit within the patch
      set size 0.35 + random-float 0.15
   ]
   set pcolor [205 235 205]]   ;; set the color of the patch to a light green
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;  runtime procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to go
  initialize-mating
  open-eggs
  check-for-DNA-test
  update-mating-ready-visualization
;;  every 0.1 [
    ask (turtle-set birds eggs) with [released?] [release-this-bird-or-egg]
    visualize-bird-and-egg-movement
    ask selection-tags [rt 5]
    listen-clients
    if any? players with [assigned?] [send-common-info]
;;  ]
  calculate-all-alleles
  check-for-meeting-goals

  tick
end


to update-mating-ready-visualization
  ask birds  [
    ifelse just-bred?
      [ set shape (word "bird-ready-to-go-home-" which-player-bird-or-egg-is-this? self) ]
      [ ifelse is-at-mating-site?  [set shape "bird-ready-to-mate"] [set shape "bird-waiting"]]
  ]
end


to visualize-bird-and-egg-movement
  ask (turtle-set birds eggs) with [transporting? and destination-patch != nobody] [
    let bird-owned-by owned-by
    ifelse distance destination-patch < .25
      [ setxy [pxcor] of destination-patch [pycor] of destination-patch
          set transporting? false set breeding? false set selected? false
          set destination-patch nobody
          set reserved? false
          ask destination-flags-here [die]
          ask selection-tags-here [die]
          if is-a-release-site? [set released? true]
          if in-cage? [set just-bred? false]
      ]
      [set heading towards destination-patch fd .2 set heading 0]
  ]
end


to check-for-DNA-test
    set sequencings-left (max-#-of-DNA-tests - sequencings-performed)
    if sequencings-left <= 0 [set sequencings-left 0]
    ask birds with [not sequenced? and is-a-sequencer-site?] [sequence-this-bird]
end


to release-this-bird-or-egg
  let bird-transparency 0
  let color-list []
  set release-counter release-counter - 1
  let this-release-counter release-counter
  set color-list but-last color
  set bird-transparency (release-counter * 60 / 6)
  set color-list lput bird-transparency color-list
  set color color-list
  ask out-link-neighbors [
     set color-list but-last color
     set color-list lput bird-transparency color-list
     set color color-list
     ask out-link-neighbors [set color color-list]
  ]
  remove-this-bird-or-egg
end


to remove-this-bird-or-egg
  if release-counter <= 0 [
    set number-releases number-releases + 1
    ask out-link-neighbors [ask out-link-neighbors [die]]
    ask out-link-neighbors [die]
    die
  ]
end


to sequence-this-bird
  let tag-label  ( word first-genes second-genes  fourth-genes third-genes sex-gene " ")
  let this-owner owned-by
  let this-bird-wing one-of out-link-neighbors with [breed = second-traits]
  if not sequenced? and is-bird? self [
    set sequenced? true
    set heading 0
    hatch 1 [
      set breed karyotype-tags
      set hidden? false
      set heading 55
      fd .55
      set heading 0
      create-link-from this-bird-wing [set tie-mode "free" tie set hidden? true]
      set size .2
      set label tag-label
      set label-color [255 0 0]
    ]
    set sequencings-performed sequencings-performed + 1
    set sequencings-left (max-#-of-DNA-tests - sequencings-performed)
  ]
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Handle client interactions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




to listen-clients
  while [ hubnet-message-waiting? ]   [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ assign-new-player ]
    [
      ifelse hubnet-exit-message?
      [ remove-player ]
      [ ask players with [user-id = hubnet-message-source] [  execute-command hubnet-message-tag hubnet-message ]]
    ]
  ]
end


to execute-command [command msg]
  if command = "View" [check-click-on-bird-or-egg msg]
  if command = "Mouse Up" [ check-release-mouse-button msg]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; player enter / exit procedures  ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to assign-new-player
  if not any? players with [user-id = hubnet-message-source and assigned?]  [  ;; no players with this id and is assigned
    ask turtle-set one-of players with [not assigned?] [ set user-id hubnet-message-source set assigned? true]
  ]
  reset-player-numbers
end


to remove-player
  ask players with [user-id = hubnet-message-source] [ set assigned? false set user-id ""]
  reset-player-numbers
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;  send info to client procedures ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to send-common-info
  hubnet-broadcast "Player 1:" player-1
  hubnet-broadcast "Player 2:" player-2
  hubnet-broadcast "Player 3:" player-3
  hubnet-broadcast "Player 4:" player-4
  hubnet-broadcast "# eggs laid" number-offspring
  hubnet-broadcast "# of birds/eggs released" number-releases
  hubnet-broadcast "# matings" number-matings
  hubnet-broadcast "# of DNA tests remaining" sequencings-left
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;  check for meeting goals procedures ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to check-for-meeting-goals
  set new-selection-event-occurred? false
  let new-number-selections (number-releases + number-hatchings)
  ;; number-selections updates everytime an action is done that would potentially change the gene pool of the population
  if new-number-selections > number-selections [
    set number-selections new-number-selections
    set new-selection-event-occurred? true
  ]
  set number-of-goal-birds count birds with [is-goal-bird-and-in-cage?]
  if (number-of-goal-birds >= #-of-required-goal-birds)  [ announce-winner]
end


to announce-winner
  user-message (word "You met your team goal and now can sell your stock of birds to rare pet collectors! Press HALT. Then Press SETUP to play again.")
  ask patch 2 4 [set plabel "You have met your breeding goal.  Press SETUP to play again." set plabel-color black]
end



to calculate-all-alleles
  ;; check to make sure one of each allele exists somewhere in the starting population
  ;; otherwise breeding for the target bird would be impossible

  set #-birds-with-1-target-trait  count birds with [ how-many-target-traits = 1]
  set #-birds-with-2-target-traits count birds with [ how-many-target-traits = 2]
  set #-birds-with-3-target-traits count birds with [ how-many-target-traits = 3]
  set #-birds-with-4-target-traits count birds with [ how-many-target-traits = 4]

  set frequency-allele-dominant-first-trait   (count birds with [(item 0 first-genes)  = "A"]) + (count birds with [(item 1 first-genes)  = "A"])
  set frequency-allele-recessive-first-trait  (count birds with [(item 0 first-genes)  = "a"]) + (count birds with [(item 1 first-genes)  = "a"])
  set frequency-allele-dominant-second-trait  (count birds with [(item 0 second-genes) = "B"]) + (count birds with [(item 1 second-genes) = "B"])
  set frequency-allele-recessive-second-trait (count birds with [(item 0 second-genes) = "b"]) + (count birds with [(item 1 second-genes) = "b"])
  set frequency-allele-dominant-third-trait   (count birds with [(item 0 third-genes)  = "C"]) + (count birds with [(item 1 third-genes)  = "C"])
  set frequency-allele-recessive-third-trait  (count birds with [(item 0 third-genes)  = "c"]) + (count birds with [(item 1 third-genes)  = "c"])
  set frequency-allele-dominant-fourth-trait   (count birds with [(item 0 fourth-genes)  = "D"]) + (count birds with [(item 1 fourth-genes)  = "D"])
  set frequency-allele-recessive-fourth-trait  (count birds with [(item 0 fourth-genes)  = "d"]) + (count birds with [(item 1 fourth-genes)  = "d"])

  if ((both-second-trait-alleles-exist? and
    both-first-trait-alleles-exist? and
    both-fourth-alleles-exist? and
    both-third-trait-alleles-exist? and
    both-sexes-exist?) = false)
   [user-message (word "The current of birds in all the cages of all the player does not have"
    " enough genetic diversity for it to be possible for you to find a way to develop the desired breed."
    "  Press HALT then press SETUP to start the model over and try again.")
    ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;  breed birds ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to initialize-mating
  ;; when a female bird lands at a breeding site... it becomes breeding ready
  ;; when a mate lands at this location eggs are hatched....eggs have an owner (one of two parents)
  ask birds with [is-ready-for-mating?] [
    let this-site-id site-id
    let female-owned-by [owned-by] of self
    set parent-female self
    remove-eggs-at-nest
    if (has-one-mate-in-nest? this-site-id ) [
      make-eggs this-site-id
      set just-bred? true
      set breeding? false
      ask parent-male [ set just-bred? true set breeding? false]
      set number-matings number-matings + 1
    ]
  ]
end


to remove-eggs-at-nest
  let this-site-id site-id
  ask eggs with [site-id = this-site-id and not transporting?] [set number-releases number-releases + 1 die]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;  make eggs or hatch  convert eggs;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to open-eggs
  ask eggs with [in-cage? and not transporting? and not breeding? and not selected? ] [
    build-body-base
    build-body-parts
    set number-hatchings number-hatchings + 1
    reset-egg-or-bird-state
  ]
end


to make-eggs [this-site-id]  ;; make eggs in all open patches at this breeding site
   let egg-counter 0
   let number-of-existing-female-eggs 0
   let number-of-existing-male-eggs 0
   let open-patches patches with [site-id = this-site-id and not any? birds-here]  ;;;  number of open patches is equal to number of eggs created
   ask open-patches  [
     ifelse egg-counter mod 2 = 0
        [sprout 1 [make-an-egg parent-female]]   ;; every even egg (0, 2) will be owned by player who contributed the female bird
        [sprout 1 [make-an-egg parent-male]]     ;; every odd egg  (1, 3) will be owned by player who contribute the male bird
     set egg-counter egg-counter + 1
   ]
   set number-offspring number-offspring + egg-counter
end


to make-an-egg [which-bird]
  set breed eggs
  set first-genes inherited-first-genes
  set third-genes inherited-third-genes
  set second-genes inherited-second-genes
  set fourth-genes inherited-fourth-genes
  set sex-gene inherited-sex-genes
  reset-egg-or-bird-state
  set release-counter 6
  set owned-by which-player-bird-or-egg-is-this? which-bird
  set shape (word "egg-ready-to-go-home-" owned-by)
  set color [200 200 255 255]
  set size egg-size
  set label-color black
  set label owned-by
end


to reset-egg-or-bird-state
  set breeding? false
  set selected? false
  set sequenced? false
  set transporting? false
  set just-bred? false
  set released? false
  set destination-patch nobody
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;  build birds ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to build-body-base
  set breed birds
  set shape "bird-waiting"
  set size bird-size
  set color bird-body-color
  set heading 0
  set transporting? false
  set breeding? false
  set just-bred? false
  set selected? false
  set sequenced? false
  set release-counter 6
  set released? false
  set destination-patch nobody
end


to assign-all-genes
  set first-genes  (word random-first-genes random-first-genes)
  set second-genes (word random-second-genes random-second-genes)
  set third-genes  (word random-third-genes random-third-genes)
  set fourth-genes  (word random-fourth-genes random-fourth-genes)
  set sex-gene random-sex-genes
end


to build-body-parts
  let body-label owned-by
  set label ""  ;; temporarily remove the label during building the body parts (so the label is not assigned to the parts)
  set size bird-size
  set heading 0
  if is-male? [
    hatch 1 [run lookup-phenotype-for-gene first-genes set breed first-traits   create-link-from myself  [tie] ]
  ]
  hatch 1 [run lookup-phenotype-for-gene second-genes set breed second-traits  create-link-from myself  [tie] ]
  hatch 1 [run lookup-phenotype-for-gene fourth-genes  set breed fourth-traits   create-link-from myself  [tie] ]
  hatch 1 [run lookup-phenotype-for-gene third-genes  set breed third-traits   create-link-from myself  [tie] ]
  set label-color black
  set label body-label
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;  select the birds ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; when a complete mouse drag is finished here is what should occur;
;; a mouse action number is assigned to the bird or and egg  and the destination patch
;; the origin patch should hatch a destination-flag to show where the egg or bird/egg is headed.
;; A selection-tag is also attached to the bird when a bird/egg is clicked on, the bird/egg becomes
;; selected? = true and a visual selection "selection-tag" is assigned to it.

;; when a mouse drag is released the selected birds is assigned a destination patch (a bird/egg variable)
;; The patch itself also is given a "reserved?" = true state so that it can not be set as a destination patch by other
;; mouse drags nor have eggs hatched on it.  And now the bird/egg becomes unselected and becomes a "moving" bird/egg.
;; moving birds can not be stopped in mid flight (they are not valid birds to be selected)
;; once moving birds reach their destination patch, the patch is no longer reserved

;; destination patches must be different than origin patches, otherwise if it is the same, then the
;; bird/egg becomes a non selected bird/egg.

;; when a moving bird/egg reaches the destination patch (or within its radius), the reserved patches for this bird/egg are
;; cleared to be unreserved (both origin and destination).  The selected bird/egg is the agent then that is assigned
;; a patch and a destination flag for a valid destination.  Valid destination patches are then switched to reserved
;; until the bird gets to the patch.  Reserved patches then can not be destinations.


to check-click-on-bird-or-egg [msg]
  let snap-xcor round item 0 msg
  let snap-ycor round item 1 msg
  let this-player-number player-number
  let this-bird-or-egg nobody

  ;; birds-available is agent set of players birds at mouse location
  let birds-or-eggs-selectable-at-clicked-patch (turtle-set birds eggs) with [pxcor = snap-xcor and pycor = snap-ycor and is-selectable-by-me? this-player-number]
  if any? birds-or-eggs-selectable-at-clicked-patch    [
    ;; when a bird is clicked on (mouse down, that is the players bird, the bird becomes a "selected bird"
    ;; and a visual selection "selection-tag" is assigned to it. All other tags need to be wiped out
    ;; ask all birds/eggs owned to deselect
    deselect-all-my-birds-and-eggs this-player-number
    ask one-of birds-or-eggs-selectable-at-clicked-patch [
      set-as-only-selected
      set destination-patch nobody
      set this-bird-or-egg self
      hatch 1 [
        set breed selection-tags set owned-by this-player-number
        set color (lput 150 extract-rgb (player-tag-and-destination-flag-color this-player-number ) )
        set heading 0
        set size 1.0
        set label ""
        create-link-from this-bird-or-egg [set hidden? true tie]
      ]
    ]
  ]
end


to check-release-mouse-button [msg]
  let snap-xcor round item 0 msg
  let snap-ycor round item 1 msg
  let is-destination-patch-illegal? true
  let this-player-number player-number
  let this-user-id user-id
  let currently-selected-birds-or-eggs (turtle-set birds eggs) with [selected? and is-bird-or-egg-owned-by-this-player? this-player-number]

  if any? currently-selected-birds-or-eggs [
    let this-selected-bird-or-egg one-of currently-selected-birds-or-eggs
    let this-selected-is-an-egg? is-egg? this-selected-bird-or-egg
    let tag-for-this-destination-flag one-of selection-tags with [owned-by = this-player-number]
    let possible-destination-patch patch-at snap-xcor snap-ycor

    ask possible-destination-patch [set is-destination-patch-illegal? is-other-players-cage-or-occupied-site? this-player-number this-user-id ]

    ifelse is-destination-patch-illegal? [
    ;; deselect all bird and start over in detecting selection
       deselect-all-my-birds-and-eggs this-player-number
    ]
    ;; the destination patch is not illegal, so assign destination patch to the bird
    [
      ask currently-selected-birds-or-eggs [set destination-patch  possible-destination-patch set-as-only-transporting]
      ask possible-destination-patch [
        set reserved? true
        sprout 1 [
          set breed destination-flags
          set owned-by this-user-id
          set color (lput 150 extract-rgb (player-tag-and-destination-flag-color this-player-number ) )
          set size 1.0
        ]
      ]
    ]
  ]

end


to set-as-only-selected
  set transporting? false
  set selected? true
  set breeding? false
end


to set-as-only-transporting
  set transporting? true
  set selected? false
  set breeding? false
end


to set-as-only-breeding
  set transporting? true
  set selected? false
  set breeding? false
end


to deselect-all-my-birds-and-eggs [my-player-number]
   ask (turtle-set birds eggs) with [selected?] [set selected? false]
   ask selection-tags with [owned-by = my-player-number]  [die]
end


to remove-tags [bird-owned-by]
  ask selection-tags with [bird-owned-by = owned-by]  [die]
end


to remove-destination-flags [bird-owned-by]
  ask destination-flags with [bird-owned-by = owned-by]  [die]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; genotype & phenotype reporters  ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report inherited-first-genes
  let mother-loci (random 2)
  let father-loci (random 2)
  let mother-allele ""
  let father-allele ""
  ask parent-female [set mother-allele (item mother-loci first-genes)]
  ask parent-male [set father-allele  (item father-loci first-genes)]
  report (word mother-allele father-allele)
end


to-report inherited-third-genes
  let mother-loci (random 2)
  let father-loci (random 2)
  let mother-allele ""
  let father-allele ""
  ask parent-female [set mother-allele (item mother-loci third-genes)]
  ask parent-male [set father-allele  (item father-loci third-genes)]
  report (word mother-allele father-allele)
end


to-report inherited-second-genes
  let mother-loci (random 2)
  let father-loci (random 2)
  let mother-allele ""
  let father-allele ""
  ask parent-female [set mother-allele (item mother-loci second-genes)]
  ask parent-male [set father-allele  (item father-loci second-genes)]
  report (word mother-allele father-allele)
end


to-report inherited-fourth-genes
  let mother-loci (random 2)
  let father-loci (random 2)
  let mother-allele ""
  let father-allele ""
  ask parent-female [set mother-allele (item mother-loci fourth-genes)]
  ask parent-male [set father-allele  (item father-loci fourth-genes)]
  report (word mother-allele father-allele)
end


to-report inherited-sex-genes
  let mother-loci (random 2)
  let father-loci (random 2)
  let mother-allele ""
  let father-allele ""
  ask parent-female [set mother-allele (item mother-loci sex-gene)]
  ask parent-male [set father-allele  (item father-loci sex-gene)]
  report (word mother-allele father-allele)
end


to-report random-first-genes
  ifelse random 2 = 0 [report "A"] [report "a"]
end


to-report random-second-genes
  ifelse random 2 = 0 [report "B"] [report "b"]
end


to-report random-third-genes
  ifelse random 2 = 0 [report "C"] [report "c"]
end


to-report random-fourth-genes
  ifelse random 2 = 0 [report "D"] [report "d"]
end


to-report random-sex-genes  ;; sex chromosomes in birds are designated either W or Z
  ifelse random 2 = 0 [report "WZ"] [report "ZZ"]
end


to-report is-male?   ;; male birds are the homozygote (this is unlike humans where the male is XY)
  ifelse sex-gene = "ZZ" [report true] [report false]
end


to-report is-female?  ;; female birds are the heterozygote (this is unlike humans where the female is XX)
  ifelse sex-gene = "WZ" [report true] [report false]
end


to-report both-sexes-exist?
  ifelse (any? birds with [is-male?] and any? birds with [is-female?])  [report true] [report false]
end


to-report both-first-trait-alleles-exist?
  ifelse (frequency-allele-dominant-first-trait > 0 and frequency-allele-recessive-first-trait  > 0)  [report true] [report false]
end


to-report both-second-trait-alleles-exist?
  ifelse (frequency-allele-dominant-second-trait > 0 and frequency-allele-recessive-second-trait  > 0) [report true] [report false]
end


to-report both-third-trait-alleles-exist?
  ifelse (frequency-allele-dominant-third-trait > 0 and frequency-allele-recessive-third-trait  > 0) [report true] [report false]
end


to-report both-fourth-alleles-exist?
  ifelse (frequency-allele-dominant-fourth-trait > 0 and frequency-allele-recessive-fourth-trait  > 0) [report true] [report false]
end


to-report how-many-target-traits  ;; used to determine how many desirable traits a bird has, based on its genotype
   let #-target-traits 0
   if first-genes  =  "aa"  [set #-target-traits #-target-traits + 1]
   if second-genes =  "bb"  [set #-target-traits #-target-traits + 1]
   if third-genes  =  "cc"  [set #-target-traits #-target-traits + 1]
   if fourth-genes  =  "dd"  [set #-target-traits #-target-traits + 1]
   report #-target-traits
end


to-report lookup-phenotype-for-gene [x]
  let item-counter 0
  let target-phenotype 0
  let target-item 0
  repeat length genes-to-phenotype [   ;; go through the entire genes to phenotype map
    if (item 0 (item item-counter genes-to-phenotype)) = x
      [set target-phenotype (item 1 (item item-counter genes-to-phenotype))]   ;; when the genotype is find, assign the corresponding phenotype to target-phenotype
    set item-counter (item-counter + 1)
  ]
  set item-counter 0
  report target-phenotype
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; eligibility & state of bird/egg reporters  ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report has-one-mate-in-nest? [this-site-id]
  let birds-at-site-id birds-on patches with [site-id = this-site-id]
  let report? false
  let eligible-males birds-at-site-id with [is-male? and not selected? and not transporting? and not just-bred?]
  if (count eligible-males = 1)  [
    set report? true
    set parent-male one-of eligible-males
    ask eligible-males [set breeding? true]
  ]
  report report?
end


to-report in-cage?
  ifelse (patch-owned-by != 0) [report true] [report false]
end


to-report is-bird-or-egg-owned-by-this-player? [this-player-number]
  ifelse this-player-number = owned-by [report true] [report false]
end


to-report is-my-egg? [my-player-number]
  ifelse my-player-number = owned-by and breed  = eggs [report true] [ report false]
end


to-report which-player-bird-or-egg-is-this? [this-bird]
  let this-is-owned-by 0
  ask this-bird [set this-is-owned-by owned-by]
  report this-is-owned-by
end


to-report player-tag-and-destination-flag-color [this-player-number]
  let the-color 0
  if this-player-number = 1 [set the-color player-1-tag-color]
  if this-player-number = 2 [set the-color player-2-tag-color]
  if this-player-number = 3 [set the-color player-3-tag-color]
  if this-player-number = 4 [set the-color player-4-tag-color]
  report the-color
end


to-report is-selectable-by-me? [my-player-number]
  ifelse not breeding? and not selected? and not transporting? and is-bird-or-egg-owned-by-this-player? my-player-number
    [report true]
    [report false]
end


to-report is-ready-for-mating?
  let response false
  if is-female? and is-at-mating-site? and not breeding? and not transporting? and not selected? and not just-bred? and destination-patch = nobody
    [set response true]
  report response
end


to-report is-at-mating-site?
  ifelse site-id != 0 [report true][report false]
end


to-report is-goal-bird-and-in-cage?
  ifelse ( first-genes = "aa" and second-genes = "bb" and third-genes = "cc" and fourth-genes = "dd" and sex-gene = "ZZ" and breed = birds and is-a-cage?)
    [report true]
    [report false]
end


to-report is-other-players-cage-or-occupied-site? [this-player-number this-user-id ]
  let validity? false
  if ((patch-owned-by >= 1 and patch-owned-by <= 4) and patch-owned-by != this-player-number) [
    ;;You can not move a bird/egg to another players cage or dna sequencer
    set validity? true
  ]
  if (any? other birds-here or any? other eggs-here) [
    ;; You can not move a bird/egg on top of another bird/egg
    set validity? true
  ]
  report validity?
end


to-report is-a-cage?
  ifelse (patch-owned-by > 0 and patch-owned-by <= 4) [report true] [report false]
end


to-report is-a-release-site?
   ifelse (patch-owned-by = 0 and site-id = 0) [report true]  [report false]
end


to-report is-a-sequencer-site?
   ifelse (patch-owned-by = owned-by and any? DNA-sequencers-here) [report true]  [report false]
end


to-report this-players-short-name [this-owned-by]
  let name-of-player ""
  if any? players with [player-number = this-owned-by] [
     ask one-of players with [player-number = this-owned-by] [set name-of-player user-id ]]
  if length name-of-player > 6 [set name-of-player substring name-of-player 1 7 ]
  report name-of-player
end


to-report game-not-filled?
  ifelse count players with [not assigned?] < 4  [report true] [report false]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; instructions for players ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to-report current-instruction-label
  report ifelse-value (current-instruction = 0)
    [ "press setup" ]
    [ (word current-instruction " / " length instructions) ]
end

to next-instruction
  show-instruction current-instruction + 1
end

to previous-instruction
  show-instruction current-instruction - 1
end

to show-instruction [ i ]
  if i >= 1 and i <= length instructions [
    set current-instruction i
    clear-output
    foreach item (current-instruction - 1) instructions output-print
  ]
end

to-report instructions
  report [
    [
     "You will be running a selective breeding"
     "program, attempting to develop a breed "
     "of fancy looking birds."
    ]
    [
     "There are 4 players working together on"
     "a team and you are one of them.  Each "
     "player starts with 3 birds in six of the"
     "cages they own."
    ]
    [
      "To breed birds, a male and female bird"
      "must be moved to one of the 6 breeding"
      "rectangles in the middle of the world."
    ]
    [
      "To do this click on a bird and hold the"
      "mouse button down the entire time while"
      "you drag the cursor to the breeding"
      "rectangle.  Then release the mouse button."
      "Eggs will appear where birds have bred."
    ]
    [
      "You must move an egg back to your cage to "
      "hatch it.  Birds that have mated also need"
      "to be returned to a cage before it is"
      "ready to mate again"
    ]
    [
      "You can set an egg or a bird that you"
      "own free.  To do so, click the mouse"
      "button, and hold and drag the egg or "
      "bird onto one of the grassy squares."
      "Then release the mouse button."
    ]
    [
      "You ultimate goal is to breed the"
      "#-of-required-goal-birds, each"
      "having a blue head cap, pink chest,"
      "purple wing and red tail."
    ]
    [
      "See if you can accomplish your goal "
      "in less matings than other teams."
      "Press GO if you are ready to begin."
      "Good luck!"
    ]
  ]
end


; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
455
55
1023
624
-1
-1
56.0
1
10
1
1
1
0
0
0
1
-4
5
-4
5
1
1
1
ticks
30.0

BUTTON
185
45
265
78
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
265
45
365
78
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

OUTPUT
15
125
365
225
11

MONITOR
110
280
210
325
# of eggs laid
number-offspring
17
1
11

MONITOR
215
280
365
325
# of birds/eggs released
number-releases
17
1
11

PLOT
20
460
340
595
# of Recessive Alleles in Gene Pool
# of selections
#
0.0
10.0
0.0
20.0
true
true
"" ""
PENS
"a" 1.0 0 -8990512 true "plotxy number-selections frequency-allele-recessive-first-trait" "if new-selection-event-occurred? [plotxy number-selections frequency-allele-recessive-first-trait]"
"b" 1.0 0 -2674135 true "plotxy number-selections frequency-allele-recessive-second-trait" "if new-selection-event-occurred? [plotxy number-selections frequency-allele-recessive-second-trait]"
"c" 1.0 0 -1664597 true "plotxy number-selections frequency-allele-recessive-third-trait" "if new-selection-event-occurred? [plotxy number-selections frequency-allele-recessive-third-trait]"
"d" 1.0 0 -7858858 true "plotxy number-selections frequency-allele-recessive-fourth-trait" "if new-selection-event-occurred? [plotxy number-selections frequency-allele-recessive-fourth-trait]"

PLOT
20
330
340
460
# of Dominant Alleles in Gene Pool
# of selections
#
0.0
10.0
0.0
20.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "plotxy number-selections frequency-allele-dominant-first-trait" "if new-selection-event-occurred? \n[plotxy number-selections frequency-allele-dominant-first-trait]"
"B" 1.0 0 -3026479 true "plotxy number-selections frequency-allele-dominant-second-trait" "if new-selection-event-occurred? \n[plotxy number-selections frequency-allele-dominant-second-trait]"
"C" 1.0 0 -3889007 true "plotxy number-selections frequency-allele-dominant-third-trait" "if new-selection-event-occurred? \n[plotxy number-selections frequency-allele-dominant-third-trait]"
"D" 1.0 0 -9276814 true "plotxy number-selections frequency-allele-dominant-fourth-trait" "if new-selection-event-occurred? \n[plotxy number-selections frequency-allele-dominant-fourth-trait]"

PLOT
20
595
425
730
# of Birds with # of Desirable Variations
# of selections
# birds
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"1 variation" 1.0 0 -4079321 true "plotxy number-selections #-birds-with-1-target-trait" "if new-selection-event-occurred? [plotxy number-selections  #-birds-with-1-target-trait]"
"2 variations" 1.0 0 -8330359 true "plotxy number-selections #-birds-with-2-target-traits" "if new-selection-event-occurred? [plotxy number-selections  #-birds-with-2-target-traits]"
"3 variations" 1.0 0 -12087248 true "plotxy number-selections #-birds-with-3-target-traits" "if new-selection-event-occurred? [plotxy number-selections #-birds-with-3-target-traits]"
"4 variations" 1.0 0 -14333415 true "plotxy number-selections #-birds-with-4-target-traits" "if new-selection-event-occurred? [plotxy number-selections #-birds-with-4-target-traits]"

SLIDER
195
10
365
43
max-#-of-DNA-tests
max-#-of-DNA-tests
0
36
16.0
1
1
NIL
HORIZONTAL

MONITOR
200
80
365
125
# of DNA tests remaining
sequencings-left
17
1
11

MONITOR
370
340
453
385
Player 1
player-1
17
1
11

MONITOR
700
10
785
55
Player 2
player-2
17
1
11

MONITOR
1030
345
1109
390
Player 3
player-3
17
1
11

MONITOR
695
645
788
690
Player 4
player-4
17
1
11

MONITOR
15
80
200
125
# goal birds you have bred
number-of-goal-birds
17
1
11

SLIDER
15
10
200
43
#-of-required-goal-birds
#-of-required-goal-birds
1
24
12.0
1
1
NIL
HORIZONTAL

MONITOR
15
280
105
325
# of matings
number-matings
17
1
11

BUTTON
245
230
365
263
NIL
next-instruction
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
15
230
155
263
NIL
previous-instruction
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
155
230
250
275
instruction #
current-instruction-label
17
1
11

SLIDER
15
45
180
78
#-of-players
#-of-players
1
4
4.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is a model of a selective breeding program of birds.  In the scenario presented in the model the user assumes the role of a bird breeder, whose goal is to breed a line of  "fancy" looking birds through managing a selective breeding program with other breeders (players).

## HOW IT WORKS

The birds have a simple genetic representation for five traits:  Crest color, wing color, chest color, tail color, and sex.

These traits are represented with genes that have one of two possible alleles each (A or a, B or b, C or c, D or d, and W or Z, for the traits listed above).  Upper case letters represent dominant alleles and lower case represent recessive alleles?.  Therefore the three combinations AA, Aa, and aA result in expression of the trait for A (e.g. gray crest), and only aa results in the expression of the trait for a (e.g. red crest).  Males and Females are determined by whether the bird has ZZ  (male) or WZ (female) genetic information.  One trait, crest color, is sex linked.  Male birds (ZZ) display a crest on their head, while females (WZ) do not (though they still carry the genetic information for how it should be expressed if they were male).

_Here is the genotype to phenotype mapping:_
Crest color:   (AA, Aa, aA) grey   or   (aa) blue
Wing color:    (BB, Bb, bB) grey   or   (bb) purple
Chest color:   (CC, Cc, cC) grey   or   (cc) pink
Tail color:    (DD, Dd, dD) grey   or   (dd) red
Sex:            ZZ   male          or    WZ female

Along the edge of the WORLD & VIEW are cages to store birds in.  In the middle of the WORLD & VIEW are six sites to breed birds in.  In the corner of the model is a DNA sequencer that can be used to discover the genotype of a bird.  In the rest of the model are spaces with grass in them where birds or eggs can put to be released into the wild.

## HOW TO USE IT

'Mirror 2D view on clients' MUST be ticked before learners connect their HubNet clients to the model. If learners connect before this is ticked, ask them to disconnect, tick the 'Mirror 2D...' box, and ask them to reconnect.

There are 4 players in this selective breeding scenario.  Each player connects to the model using HubNet.  Each player starts with 3 birds of their own in six cages along the sides of the model. By click-and-dragging their birds to each of the 6 breeding locations (dark gray and light gray rectangles) in the middle of the world, players can breed new birds. In order to hatch the resulting eggs, players must click-and-drag each egg to one of their cages. The genetic makeup of the new birds will reflect the makeup of its parents.

_**How do you determine which birds and eggs are yours?**_
Birds and eggs have numbers (1-4) corresponding to the player number that owns them.  You can only move birds and eggs that are your player number.

_**How do you breed birds?**_
Move one male and one female bird into a breeding location.  Hearts will appear on the birds, indicating they are ready to mate.  When two birds with hearts of opposite genders are at a breeding location, they will breed and lay eggs.  After breeding, colored arrows will appear on the birds indicating that they must return to their cages before being ready to return to a new breeding site to breed again. To hatch the newly laid eggs, players must drag the eggs back to their cages. As soon as an egg is put in a player’s cage, the egg is hatched, and the player can decide to keep the bird or set it free.  Ownership of eggs is determined by the ownership of the breeding birds: If a player owns both birds, all the eggs will belong to that player, but if two birds belonging to two different learners breed, each player will own half of the eggs.

_**How do you get rid of extra birds or eggs?**_
To set a bird or egg free, just click on it and drag it into the green spaces with grass shapes in them and release the mouse button.  You can only set birds free or remove eggs if you own them (they have the same player number on them as you do).

If you move an egg to a breeding site and another bird is there, the egg will disappear (the bird that is there destroys it).  Likewise if you move a new non-parent bird to a mating site that has eggs in it still, the new bird will destroy the eggs that are at that nesting site as it gets ready to mate.

_**How can you find out the genetic information for a given bird or egg?**_
You can drag a bird or an egg to the corner location that has a picture of a test tube rack is numbered the same as your player number.  That is your DNA sequencer.  If your team of players has any DNA sequencings left, then the bird or egg you drag to the sequencer will be labeled with the genotype of that organism.  Eggs that are dragged to the DNA sequencer also hatch upon arriving there.  There is a limit to the number of times that your team can do this (set by max-#-of-DNA-tests).

_**How can you tell the male birds apart from the female birds?**_
The male birds have a crown of feather on their head, but the females do not.


**Buttons:**
SETUP:  Press this first to assign a new batch of starting birds to the players.
GO:     Press this second to start allowing the players to interact with the shared interface in the breeding challenge
NEXT-INSTRUCTION:  Use this to display the next instruction about how to user the interface and mouse interactions with the birds.
PREVIOUS-INSTRUCTION:  :  Use this to display the previous instruction about how to user the interface and mouse interactions with the birds.

**Sliders:**
 #-OF-REQUIRED-GOAL-BIRDS sets the number of goal birds that must be accumulated in the player cages in order to successfully complete the scenario.
MAX-#-OF-DNA-TEST sets the maximum limit of birds or eggs that can have their genotype shown when dragged to a DNA sequencing patch.

**Monitors:  **
DNA-TESTS-REMAINING indicates how many times left that you (or another player) can still drag an egg or bird to a DNA sequencer and get the genotype to appear on that agent.  MAX-#-OF-DNA-TEST sets the maximum limit.
 #-OF-REQUIRED-GOAL-BIRDS indicates how many goal birds have been accumulated in the player cages.
INSTRUCTION-#: displays which instruction is being displayed out of how many total instructions there are to view.
 # OF MATINGS:  keeps track of the number of times birds were mated together
 # OF EGGS LAID:  keeps track of the eggs laid.
 # OF BIRDS/EGGS RELEASED:  keeps track of the number of birds or eggs you released from the world.


**Graphs:**
NUMBER OF RECESSIVE ALLELES IN GENE POOL graphs the number of recessive alleles (a, b, c, and d) in the gene pool vs. the number of selections (the sum of the # of birds/eggs released + # of eggs hatched).
NUMBER OF DOMINANT ALLELES IN GENE POOL graphs the number of dominant alleles (A, B, C, and D) in the gene pool vs. the number of selections (the sum of the # of birds/eggs released + # of eggs hatched).
NUMBER OF BIRDS WITH # OF DESIRABLE VARIATIONS graphs all the phenotype frequencies in the population.  It graphs the number of birds that show 1, 2, 3, and 4 of the 4 possible desirable variations in the traits that you are breeding for.

## THINGS TO NOTICE

Even though birds produce four eggs when they mate, the four eggs may or may not produce the expected probabilities of a theoretical Punnett square.  This is because the expected probabilities represent what would result after an infinite set of crosses.

If additional birds occupy a nesting site, then less than four eggs will be laid, since fewer patches are available.

## THINGS TO TRY

See if you can breed for the fancy bird in the least number of generations.

Write down the breeding plan you followed to create a line of the fancy bird.  Create a pedigree diagram to show the series of generations and breeding events that led to the fancy bird.

Track the changes in the frequency of recessive and dominant alleles.  Compare the general trends in the graph to the fluctuations that appear.  What are some things that cause the fluctuations?

## EXTENDING THE MODEL

The model shows one scenarios of breeding birds.  The bird shapes could be changed to show breeding of other virtual creatures (reptiles, cats, fish, etc)

## NETLOGO FEATURES

Bird Breeders uses NetLogo lists as maps to easily keep track of how genotypes relate to phenotypes.

The order of how breeds are defined, determine which breed appears on top of the others in the WORLD & VIEW.  Earlier defined breeds (such as grasses) are on the bottom layer.  This allows later defined breeds (such as eggs or birds) to move across and in front of them as the travel from cages to breeding sites.

## RELATED MODELS

Plant Hybridization and Fish Tank Genetic Drift from the BEAGLE curricular folder.

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2011).  NetLogo Bird Breeders HubNet model.  http://ccl.northwestern.edu/netlogo/models/BirdBreedersHubNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the HubNet software as:

* Wilensky, U. & Stroup, W. (1999). HubNet. http://ccl.northwestern.edu/netlogo/hubnet.html. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Novak, M. -->
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

bird
false
0
Polygon -16777216 true false 0 128 45 98 75 98 105 128 150 128 240 143 285 128 285 143 300 158 240 158 195 173 255 203 210 203 150 218 90 203 60 188 45 143
Polygon -7500403 true true 0 120 45 90 75 90 105 120 150 120 240 135 285 120 285 135 300 150 240 150 195 165 255 195 210 195 150 210 90 195 60 180 45 135
Circle -16777216 true false 38 98 14

bird side
false
0
Polygon -7500403 true true 0 120 45 90 75 90 105 120 150 120 240 135 285 120 285 135 300 150 240 150 195 165 255 195 210 195 150 210 90 195 60 180 45 135
Circle -16777216 true false 38 98 14

bird-all
false
0
Polygon -2674135 true false 45 90 15 60 45 75 30 45 60 75 60 30 75 75 90 45 90 75 120 60 90 90 135 90 90 105
Polygon -7500403 true true 0 120 45 90 75 90 105 120 150 120 240 135 285 120 285 135 300 150 240 150 195 165 255 195 210 195 150 210 90 195 60 180 45 135
Circle -16777216 true false 38 98 14
Polygon -2674135 true false 255 195 195 165 165 150 120 150 150 180 210 195
Polygon -2674135 true false 60 180 54 163 105 180 150 210 90 195
Polygon -2674135 true false 240 150 300 150 285 135 285 120 240 135 255 135

bird-breast
false
1
Polygon -2674135 true true 55 196 76 187 105 195 150 240 90 225 60 210

bird-cap
false
1
Polygon -16777216 true false 46 115 16 85 46 100 31 70 61 100 61 55 76 100 91 70 91 100 121 85 91 115 136 115 91 130
Polygon -2674135 true true 45 120 15 90 45 105 30 75 60 105 60 60 75 105 90 75 90 105 120 90 90 120 135 120 90 135

bird-ready-to-go-home-1
false
0
Polygon -16777216 true false 0 158 45 128 75 128 105 158 150 158 240 173 285 158 285 173 300 188 240 188 195 203 255 233 210 233 150 248 90 233 60 218 45 173
Polygon -7500403 true true 0 150 45 120 75 120 105 150 150 150 240 165 285 150 285 165 300 180 240 180 195 195 255 225 210 225 150 240 90 225 60 210 45 165
Circle -16777216 true false 38 128 14
Rectangle -2064490 true false 29 245 60 265
Polygon -2064490 true false 30 285 30 225 0 255

bird-ready-to-go-home-2
false
0
Polygon -16777216 true false 0 158 45 128 75 128 105 158 150 158 240 173 285 158 285 173 300 188 240 188 195 203 255 233 210 233 150 248 90 233 60 218 45 173
Polygon -7500403 true true 0 150 45 120 75 120 105 150 150 150 240 165 285 150 285 165 300 180 240 180 195 195 255 225 210 225 150 240 90 225 60 210 45 165
Circle -16777216 true false 38 128 14
Rectangle -13840069 true false 35 254 55 285
Polygon -13840069 true false 15 255 75 255 45 225

bird-ready-to-go-home-3
false
0
Polygon -16777216 true false 0 158 45 128 75 128 105 158 150 158 240 173 285 158 285 173 300 188 240 188 195 203 255 233 210 233 150 248 90 233 60 218 45 173
Polygon -7500403 true true 0 150 45 120 75 120 105 150 150 150 240 165 285 150 285 165 300 180 240 180 195 195 255 225 210 225 150 240 90 225 60 210 45 165
Circle -16777216 true false 38 128 14
Rectangle -6459832 true false 0 245 31 265
Polygon -6459832 true false 30 285 30 225 60 255

bird-ready-to-go-home-4
false
0
Polygon -16777216 true false 0 158 45 128 75 128 105 158 150 158 240 173 285 158 285 173 300 188 240 188 195 203 255 233 210 233 150 248 90 233 60 218 45 173
Polygon -7500403 true true 0 150 45 120 75 120 105 150 150 150 240 165 285 150 285 165 300 180 240 180 195 195 255 225 210 225 150 240 90 225 60 210 45 165
Circle -16777216 true false 38 128 14
Rectangle -14835848 true false 35 240 55 271
Polygon -14835848 true false 15 270 75 270 45 300

bird-ready-to-mate
false
0
Polygon -16777216 true false 0 158 45 128 75 128 105 158 150 158 240 173 285 158 285 173 300 188 240 188 195 203 255 233 210 233 150 248 90 233 60 218 45 173
Circle -2674135 true false 15 240 30
Circle -2674135 true false 45 240 30
Polygon -2674135 true false 15 260 46 296 75 260
Polygon -7500403 true true 0 150 45 120 75 120 105 150 150 150 240 165 285 150 285 165 300 180 240 180 195 195 255 225 210 225 150 240 90 225 60 210 45 165
Circle -16777216 true false 38 128 14

bird-tail
false
1
Polygon -16777216 true false 239 189 298 202 284 174 283 157 239 174 254 174
Polygon -2674135 true true 236 179 300 195 281 164 285 135 236 164 251 164

bird-waiting
false
0
Polygon -16777216 true false 0 158 45 128 75 128 105 158 150 158 240 173 285 158 285 173 300 188 240 188 195 203 255 233 210 233 150 248 90 233 60 218 45 173
Polygon -7500403 true true 0 150 45 120 75 120 105 150 150 150 240 165 285 150 285 165 300 180 240 180 195 195 255 225 210 225 150 240 90 225 60 210 45 165
Circle -16777216 true false 38 128 14

bird-wing
false
1
Polygon -2674135 true true 270 225 195 180 150 165 120 180 135 195 210 225
Line -16777216 false 120 180 135 195
Line -16777216 false 135 195 210 225
Line -16777216 false 210 225 270 225

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

cage
false
0
Rectangle -16777216 false false 0 0 300 300

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

dragon-chest
false
13
Polygon -2064490 true true 105 90 120 120 120 150 120 180 105 210 120 240 120 270 150 285 90 285 45 240 60 180 90 150 105 120 96 91
Line -16777216 false 49 240 118 240
Line -16777216 false 60 180 120 180
Line -16777216 false 75 270 120 270
Line -16777216 false 90 150 120 150
Line -16777216 false 105 120 120 120
Line -16777216 false 52 210 106 210

dragon-tail-rope
false
0
Polygon -16777216 true false 240 285 263 264 283 240 289 218 281 206 266 209 255 195 281 193 297 207 298 228 290 248 273 268 239 289

dragon-tail-rope-spade
false
0
Polygon -16777216 true false 207 297 237 252 237 282 267 297
Polygon -16777216 true false 236 278 263 264 283 240 289 218 281 206 266 209 255 195 281 193 297 207 298 228 290 248 273 268 239 289

dragon-tail-spade
false
0
Polygon -16777216 true false 260 202 233 181 293 196 248 241

dragon-tails
false
0
Polygon -10899396 true false 207 297 237 252 237 282 267 297
Polygon -10899396 true false 236 278 263 264 283 240 289 218 281 206 266 209 255 195 281 193 297 207 298 228 290 248 273 268 239 289
Polygon -10899396 true false 260 202 233 181 293 196 248 241

dragon-teeth
false
0
Polygon -1 true false 45 60 30 60 30 120
Polygon -1 true false 75 60 60 60 60 120

dragon-wing-female
false
2
Polygon -2674135 true false 36 52 43 79 36 96 25 107 39 101 46 95 53 108 62 113 56 93 47 72 49 56
Line -955883 true -60 255 -45 270
Line -955883 true -60 255 -45 270

dragon-wing-male
false
2
Polygon -1 true false 15 60 15 105 30 60
Polygon -1 true false 60 60 60 105 75 60
Line -955883 true -60 255 -45 270
Line -955883 true -60 255 -45 270

egg
false
1
Polygon -16777216 true false 45 150 46 178 57 194 65 205 88 216 157 238 187 240 224 231 249 208 263 172 264 154
Polygon -1 true false 38 143 39 115 50 99 58 88 81 77 150 55 180 53 217 62 242 85 256 121 257 139
Polygon -16777216 true false 45 154 46 137 57 121 65 110 88 99 157 77 187 75 224 84 249 107 263 143 264 161
Polygon -2674135 true true 37 140 38 168 49 184 57 195 80 206 149 228 179 230 216 221 241 198 255 162 256 144
Polygon -2674135 true true 37 146 38 129 49 113 57 102 80 91 149 69 179 67 216 76 241 99 255 135 256 153

egg-ready-to-go-home-1
false
1
Polygon -16777216 true false 45 150 46 178 57 194 65 205 88 216 157 238 187 240 224 231 249 208 263 172 264 154
Polygon -1 true false 38 143 39 115 50 99 58 88 81 77 150 55 180 53 217 62 242 85 256 121 257 139
Polygon -16777216 true false 45 154 46 137 57 121 65 110 88 99 157 77 187 75 224 84 249 107 263 143 264 161
Polygon -2674135 true true 37 140 38 168 49 184 57 195 80 206 149 228 179 230 216 221 241 198 255 162 256 144
Polygon -2674135 true true 37 146 38 129 49 113 57 102 80 91 149 69 179 67 216 76 241 99 255 135 256 153
Polygon -2064490 true false 0 255 45 300 45 210
Rectangle -2064490 true false 45 240 90 270

egg-ready-to-go-home-2
false
1
Polygon -16777216 true false 45 150 46 178 57 194 65 205 88 216 157 238 187 240 224 231 249 208 263 172 264 154
Polygon -1 true false 38 143 39 115 50 99 58 88 81 77 150 55 180 53 217 62 242 85 256 121 257 139
Polygon -16777216 true false 45 154 46 137 57 121 65 110 88 99 157 77 187 75 224 84 249 107 263 143 264 161
Polygon -2674135 true true 37 140 38 168 49 184 57 195 80 206 149 228 179 230 216 221 241 198 255 162 256 144
Polygon -2674135 true true 37 146 38 129 49 113 57 102 80 91 149 69 179 67 216 76 241 99 255 135 256 153
Polygon -13840069 true false 45 210 0 255 90 255
Rectangle -13840069 true false 30 255 60 300

egg-ready-to-go-home-3
false
1
Polygon -16777216 true false 45 150 46 178 57 194 65 205 88 216 157 238 187 240 224 231 249 208 263 172 264 154
Polygon -1 true false 38 143 39 115 50 99 58 88 81 77 150 55 180 53 217 62 242 85 256 121 257 139
Polygon -16777216 true false 45 154 46 137 57 121 65 110 88 99 157 77 187 75 224 84 249 107 263 143 264 161
Polygon -2674135 true true 37 140 38 168 49 184 57 195 80 206 149 228 179 230 216 221 241 198 255 162 256 144
Polygon -2674135 true true 37 146 38 129 49 113 57 102 80 91 149 69 179 67 216 76 241 99 255 135 256 153
Polygon -6459832 true false 90 255 45 210 45 300
Rectangle -6459832 true false 0 240 45 270

egg-ready-to-go-home-4
false
1
Polygon -16777216 true false 45 150 46 178 57 194 65 205 88 216 157 238 187 240 224 231 249 208 263 172 264 154
Polygon -1 true false 38 143 39 115 50 99 58 88 81 77 150 55 180 53 217 62 242 85 256 121 257 139
Polygon -16777216 true false 45 154 46 137 57 121 65 110 88 99 157 77 187 75 224 84 249 107 263 143 264 161
Polygon -2674135 true true 37 140 38 168 49 184 57 195 80 206 149 228 179 230 216 221 241 198 255 162 256 144
Polygon -2674135 true true 37 146 38 129 49 113 57 102 80 91 149 69 179 67 216 76 241 99 255 135 256 153
Polygon -13791810 true false 45 300 0 255 90 255
Rectangle -13791810 true false 30 210 60 255

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
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Circle -7500403 false true 116 116 67
Polygon -7500403 true true 120 165 75 150 120 135
Polygon -7500403 true true 135 120 150 75 165 120
Polygon -7500403 true true 180 135 225 150 180 165
Polygon -7500403 true true 165 180 150 225 135 180

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

grass
false
0
Polygon -7500403 true true 120 210 150 225 165 210 165 165 165 60 150 0 150 75 120 165
Polygon -10899396 true false 150 210 150 225 165 240 180 240 195 225 195 150 225 90 255 60 300 30 225 60 165 120 150 165
Polygon -13840069 true false 90 225 105 240 120 240 150 225 135 165 120 120 90 75 45 45 15 30 60 75 90 120 105 165
Polygon -13840069 true false 270 180 210 210 195 225 180 240 150 240 150 210 180 195 225 180
Polygon -7500403 true true 0 210 45 210 90 225 105 240 135 240 150 225 120 195 60 195

heart
false
0
Circle -7500403 true true 135 43 122
Circle -7500403 true true 43 43 122
Polygon -7500403 true true 255 120 240 150 210 180 180 210 150 240 146 135
Line -7500403 true 150 209 151 80
Polygon -7500403 true true 45 120 60 150 90 180 120 210 150 240 154 135

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

karyotype-tag
false
0

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

reptile-body
false
2
Circle -1 true false 21 10 40
Polygon -955883 true true 45 30 1 50 15 60 45 60 75 75 90 60 105 120 90 150 60 180 45 240 90 285 150 285 210 255 225 225 255 210 270 210 255 195 225 195 180 210 165 225 150 225 165 165 150 105 120 45 90 30 105 0 75 15 75 30 60 30 60 15 30 0
Circle -1 true false 45 10 40
Circle -16777216 true false 46 22 14
Line -955883 true -60 255 -45 270
Line -955883 true -60 255 -45 270
Circle -16777216 true false 20 23 14

reptile-both-spine-scales
false
2
Polygon -10899396 true false 107 50 122 20 152 20 152 50 122 65
Polygon -1184463 true false 126 67 141 37 171 37 171 67 141 82
Polygon -10899396 true false 136 93 151 63 181 63 181 93 151 108
Polygon -1184463 true false 148 119 163 89 193 89 193 119 163 134
Polygon -10899396 true false 150 150 165 120 195 120 195 150 165 165
Polygon -1184463 true false 150 180 165 150 195 150 195 180 165 195
Line -955883 true -60 255 -45 270
Line -955883 true -60 255 -45 270

reptile-green-spine-scales
false
2
Polygon -10899396 true false 107 50 122 20 152 20 152 50 122 65
Polygon -10899396 true false 136 93 151 63 181 63 181 93 151 108
Polygon -10899396 true false 150 150 165 120 195 120 195 150 165 165
Line -955883 true -60 255 -45 270
Line -955883 true -60 255 -45 270

reptile-yellow-spine-scales
false
2
Polygon -1184463 true false 126 67 141 37 171 37 171 67 141 82
Polygon -1184463 true false 148 119 163 89 193 89 193 119 163 134
Polygon -1184463 true false 150 180 165 150 195 150 195 180 165 195
Line -955883 true -60 255 -45 270
Line -955883 true -60 255 -45 270

rooster-all
false
0
Polygon -955883 true false 45 30 15 45 45 60 60 165 135 240 150 240 180 210 270 180 240 135 135 120 105 75 90 45 60 30
Circle -16777216 true false 38 38 14
Polygon -2674135 true false 240 180 195 165 165 150 120 150 150 180 210 195
Polygon -2674135 true false 45 30 30 0 45 15 45 0 60 15 75 0 75 15 90 0 73 39
Polygon -2674135 true false 31 50 25 75 33 99 49 78 46 61
Polygon -2674135 true false 225 135 240 75 270 30 300 30 285 45 300 45 285 60 285 90 300 75 285 105 300 105 285 120 300 135 285 150 285 165 270 165 270 180 255 180 240 150
Line -1184463 false 135 240 120 285
Line -1184463 false 150 240 145 270
Line -1184463 false 120 285 75 285
Line -1184463 false 120 285 105 300
Line -1184463 false 120 285 150 300
Line -1184463 false 146 269 171 277
Line -1184463 false 145 270 130 270

site
false
0
Rectangle -7500403 true true 0 0 300 300

site-ne
false
0
Rectangle -7500403 true true 0 0 300 300
Line -16777216 false 300 300 300 0
Line -16777216 false 0 0 300 0

site-new
false
0
Rectangle -7500403 true true 0 0 300 300

site-nw
false
0
Rectangle -7500403 true true 0 0 300 300
Line -16777216 false 0 300 0 0
Line -16777216 false 0 0 300 0

site-se
false
0
Rectangle -7500403 true true 0 0 300 300
Line -16777216 false 300 300 300 0
Line -16777216 false -15 300 285 300

site-sw
false
0
Rectangle -7500403 true true 0 0 300 300
Line -16777216 false 0 300 0 0
Line -16777216 false 0 300 300 300

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

tag
true
0
Circle -7500403 false true 0 0 298
Polygon -7500403 true true 300 135 255 150 300 165
Polygon -7500403 true true 135 0 150 45 165 0
Polygon -7500403 true true 165 300 150 255 135 300
Polygon -7500403 true true 0 165 45 150 0 135

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

test-tubes
false
8
Circle -7500403 false false 46 37 58
Circle -7500403 false false 121 37 58
Circle -7500403 false false 196 37 58
Circle -11221820 true true 45 210 60
Circle -7500403 false false 45 211 60
Rectangle -11221820 true true 45 165 105 240
Line -16777216 false 165 90 180 90
Line -16777216 false 165 150 180 150
Line -16777216 false 165 180 180 180
Circle -11221820 true true 45 135 60
Circle -7500403 false false 45 135 60
Circle -16777216 true false 45 30 60
Circle -955883 true false 120 210 60
Circle -1184463 true false 195 210 60
Circle -7500403 false false 120 212 60
Circle -7500403 false false 195 212 60
Rectangle -955883 true false 120 165 180 240
Rectangle -1184463 true false 195 165 255 240
Circle -955883 true false 120 135 60
Circle -1184463 true false 195 135 60
Circle -7500403 false false 120 135 60
Circle -7500403 false false 195 135 60
Circle -16777216 true false 120 30 60
Circle -16777216 true false 195 30 60
Rectangle -16777216 true false 45 30 105 60
Rectangle -16777216 true false 120 30 180 60
Rectangle -16777216 true false 195 30 255 60
Circle -16777216 true false 45 8 60
Circle -16777216 true false 120 8 60
Circle -16777216 true false 195 8 60
Line -7500403 false 45 30 45 240
Line -7500403 false 105 30 105 240
Line -7500403 false 120 30 120 240
Line -7500403 false 180 30 180 240
Line -7500403 false 195 30 195 240
Line -7500403 false 255 30 255 240
Circle -7500403 false false 48 4 54
Circle -7500403 false false 123 4 54
Circle -7500403 false false 198 4 54
Rectangle -16777216 false false 0 0 300 300

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
270
345
368
394
Player 1:
NIL
3
1

MONITOR
930
345
1023
394
Player 3:
NIL
3
1

MONITOR
630
10
730
59
Player 2:
NIL
3
1

MONITOR
625
630
727
679
Player 4:
NIL
3
1

MONITOR
165
370
240
419
# eggs laid
NIL
3
1

MONITOR
10
320
165
369
# of birds/eggs released
NIL
3
1

MONITOR
10
370
165
419
# of DNA tests remaining
NIL
3
1

MONITOR
165
320
239
369
# matings
NIL
3
1

VIEW
370
65
930
625
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
-4
5
-4
5

PLOT
10
165
350
315
# of Recessive Alleles in Gene Pool
# of selections
#
0.0
10.0
0.0
20.0
true
true
"" ""
PENS
"a" 1.0 0 -8990512 true "" ""
"b" 1.0 0 -2674135 true "" ""
"c" 1.0 0 -1664597 true "" ""
"d" 1.0 0 -7858858 true "" ""

PLOT
10
10
350
160
# of Dominant Alleles in Gene Pool
# of selections
#
0.0
10.0
0.0
20.0
true
true
"" ""
PENS
"A" 1.0 0 -16777216 true "" ""
"B" 1.0 0 -3026479 true "" ""
"C" 1.0 0 -3889007 true "" ""
"D" 1.0 0 -9276814 true "" ""

PLOT
10
430
355
680
# of Birds with # of Desirable Variations
# of selections
# birds
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"1 variation" 1.0 0 -4079321 true "" ""
"2 variations" 1.0 0 -8330359 true "" ""
"3 variations" 1.0 0 -12087248 true "" ""
"4 variations" 1.0 0 -14333415 true "" ""

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
