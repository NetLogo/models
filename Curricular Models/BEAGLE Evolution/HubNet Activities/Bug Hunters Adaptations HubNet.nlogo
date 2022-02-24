extensions [bitmap]
globals
[
  predator-leader               ;; a string expressing the player who has found the most bug (or a tie if appropriate)
  predator-leader-found         ;; the number of bug the leader has found
  mate-leader                   ;; a string expressing the player who has found the most bug (or a tie if appropriate)
  mate-leader-found             ;; the number of bug the leader has found
  predator-total-found          ;; running total of the total number of bug found
  mate-total-found              ;; running total of the total number of bug found
  leader                        ;; a string expressing the player who has found the most bugs (or a tie if appropriate)
  leader-found                  ;; the number of bugs the leader has found
  total-found                   ;; running total of the total number of bugs found by everyone
  adult-age                     ;; the number of ticks before bugs are full grown
  image1                        ;; the first image uploaded by the user for the environment
  image2                        ;; the second image uploaded by the user for the environment
  image3                        ;; default image
  image4                        ;; default image
  image5                        ;; default image
  number-of-predators           ;; keeps track of the number of predators (clients that are assigned this role) in the competition
  number-of-mates               ;; keeps track of the number of mates     (clients that are assigned this role) in the competition
  host-mouse-down-released?     ;; keeps track of mouse-button release event to prevent host from holding down button and moving mouse to vacuum up bugs
  host-role                     ;; keeps track of the role the host is assigned (mate or predator)
]

;; each client controls one player turtle
;; players are always hidden in the view
breed [players player]
breed [found-spots found-spot]
breed [edges edge]
breed [bugs bug]

found-spots-own [countdown]

players-own
[
  user-name    ;; the unique name users enter on their clients
  host?        ;; all clients have this set to false...but the host is also a player, in which case this is set to true.
  role         ;; set as predator or mate
  found        ;; the number of bugs this user as found
  attempts     ;; times the user has clicked in the view trying to catch a bug
  percent      ;; percent of catches relative to the leader
]

;; gene-frequencies determine the color
;; of each bug and mutate as bugs reproduce
bugs-own
[
  red-gene    ;; gene for strength of expressing red pigment (0-255)
  blue-gene   ;; gene for strength of expressing blue pigment (0-255)
  green-gene  ;; gene for strength of expressing green pigment (0-255)
  birthday    ;; when this bug was born
]

patches-own [type-of-patch region]

;;;;;;;;;;;;;;;;;;;
;; Setup Procedures
;;;;;;;;;;;;;;;;;;;

to startup
  clear-all
  hubnet-reset
  setup-clear
end

;; this kills off all the turtles (including the players)
;; so we don't necessarily want to do this each time we setup
to setup-clear
  clear-environment
  reset-ticks
  set-default-shape bugs "moth"
  set adult-age 25
  add-host
  setup
end

;; setup the model for another round of bug catching
;; with the same group of users logged in
to setup
  clear-patches
  clear-all-plots
  reset-ticks
  ask bugs [ die ]
  ask found-spots [ die ]
  set host-mouse-down-released? false
  set total-found 0
  set leader ""
  set host-role ""
  set leader-found 0
  setup-regions
  set-default-image-filenames
  change-environment
  make-initial-bugs carrying-capacity-environment-left  1
  make-initial-bugs carrying-capacity-environment-right 2
  ;; make sure to return players to initial conditions
  ask players with [ not host? ] [ initialize-player ]
  ask players with [ host? ] [ initialize-host ]
end

to setup-regions
  let min-pycor-edge min-pycor
  let max-pycor-edge max-pycor
  let water-patches nobody
  ask edges [ die ]
  ask patches [
    set region 0
    if (pxcor = 0 or pycor = min-pycor or pycor = max-pycor or pxcor = min-pxcor or pxcor = max-pxcor) [
      set type-of-patch "outside-region"
    ]
    if pxcor < 0 and pxcor > min-pxcor and pycor < max-pycor and pycor > min-pycor [ set region 1 ]
    if pxcor > 0 and pxcor > min-pxcor and pycor < max-pycor and pycor > min-pycor [ set region 2 ]
    if type-of-patch = "outside-region" [
      sprout-edges 1 [
        set region 0
        set color white
        set shape "edges"
      ]
    ]
  ]
end

to make-initial-bugs [carrying-capacity which-side]
  let initial-colors-of-bugs ""
  if which-side = 1 [ set initial-colors-of-bugs initial-colors-bugs-left ]
  if which-side = 2 [ set initial-colors-of-bugs initial-colors-bugs-right ]
  create-bugs carrying-capacity [
    set size adult-bug-size
    set shape "moth"
    set birthday (-1 * adult-age)
    ;; assign gene frequencies from 0 to 255, where 0 represents 0% expression of the gene
    ;; and 255 represent 100% expression of the gene for that pigment
    if initial-colors-of-bugs = "random variation" [
      set red-gene random 255
      set blue-gene random 255
      set green-gene random 255
    ]
    if initial-colors-of-bugs = "all gray" [
      set red-gene 122
      set blue-gene 122
      set green-gene 122
    ]
    if initial-colors-of-bugs = "all black or white" [
      ifelse random 2 = 0 [
         set red-gene 0
         set blue-gene  0
         set green-gene  0
      ]
      [
         set red-gene  255
         set blue-gene  255
         set green-gene 255
      ]
    ]
    if which-side = 1 [ move-to one-of patches with [ region = 1 ] ]
    if which-side = 2 [ move-to one-of patches with [ region = 2 ] ]
    set-phenotype-color
    assign-genotype-labels
  ]
end

;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures
;;;;;;;;;;;;;;;;;;;;;

to go
  grow-bugs
  reproduce-bugs
  cull-extra-bugs
  listen-host
  listen-clients
  visualize-found-spots
  tick
end

to grow-bugs
  ask bugs [
    ;; show genotypes if appropriate, hide otherwise
    assign-genotype-labels
    ;; if the bug is smaller than adult-bug-size then it's not full
    ;; grown and it should get a little bigger
    ;; so that bugs don't just appear full grown in the view
    ;; but instead slowly come into existence. as it's easier
    ;; to see the new bugs when they simply appear
    let age ticks - birthday
    ifelse age < adult-age
      [ set size adult-bug-size * (age / adult-age) ]
      [ set size adult-bug-size ]
  ]
 ;; grow the newly hatched offspring until they reach their ADULT-AGE, at which point they should be the full bug-SIZE
end

;; keep a stable population of bugs as predation rates go up or down
to reproduce-bugs
  ;; if all the bugs are removed by predators at once
  ;; make a new batch of random bugs
  if count bugs with [ region = 1 ] = 0
    [ make-initial-bugs carrying-capacity-environment-left 1 ]
  if count bugs with [ region = 2 ] = 0
    [ make-initial-bugs carrying-capacity-environment-right 2 ]
  ;; otherwise reproduce random other bugs  until
  ;; you've reached the carrying capacity
  if count bugs with [ region = 1 ] < carrying-capacity-environment-left
    [ ask one-of bugs with [ region = 1 ] [ make-one-offspring ] ]
  if count bugs with [region = 2 ] < carrying-capacity-environment-right
    [ ask one-of bugs with [ region = 2 ] [ make-one-offspring ] ]
end

to cull-extra-bugs
  ;; if all the bugs are removed by predators at once
  ;; make a new batch of random bugs
  if count bugs with [ region = 1 ] = 0
    [ make-initial-bugs carrying-capacity-environment-left 1 ]
  if count bugs with [ region = 2 ] = 0
    [ make-initial-bugs carrying-capacity-environment-right 2 ]
  ;; otherwise reproduce random other bugs  until
  ;; you've reached the carrying capacity
  if count bugs with [ region = 1 ] > carrying-capacity-environment-left
    [ ask one-of bugs with [ region = 1 ] [ die ] ]
  if count bugs with [ region = 2 ] > carrying-capacity-environment-right
    [ ask one-of bugs with [ region = 2 ] [ die] ]
end

;;;;;;;;;;;;;;;;;;;;;
;; Visualization Procedures
;;;;;;;;;;;;;;;;;;;;;

to visualize-death
  hatch 1 [
    set breed found-spots
    set hidden? false
    set shape "x"
    set size 1.6
    set countdown 15
  ]
  die
end

to visualize-mating
  hatch 1 [
    set breed found-spots
    set hidden? false
    set shape "heart"
    set size 1.8
    set countdown 15
  ]
  die
end

to visualize-found-spots
  ask found-spots [
    set countdown countdown - 1
    set color lput (countdown * 10) [255 255 255]  ;; sets the transparency of this spot to progressively more transparent as countdown decreases
    if countdown <= 0 [ die ]
  ]
end

to make-one-offspring ;; turtle procedure
  ;; three possible random mutations can occur, one in each frequency of gene expression
  ;; the max-mutation-step determines the maximum amount the gene frequency can drift up
  ;; or down in this offspring
  let red-mutation   random (max-color-mutation + 1) - random (max-color-mutation + 1)
  let green-mutation random (max-color-mutation + 1) - random (max-color-mutation + 1)
  let blue-mutation  random (max-color-mutation + 1) - random (max-color-mutation + 1)
  hatch 1 [
     set size 0.2
     set birthday ticks
     set red-gene   limit-gene (red-gene   + red-mutation)
     set green-gene limit-gene (green-gene + green-mutation)
     set blue-gene  limit-gene (blue-gene  + blue-mutation)
     set-phenotype-color
     ;; move away from the parent slightly
     lay-offspring
   ]
end

;; used to move bug slightly away from their parent
to lay-offspring ;; bug procedure
  let this-region region
  let this-bug self
  let birth-sites-in-radius patches with [ distance this-bug <= offspring-distance ]
  let birth-sites-in-region birth-sites-in-radius with [ region = this-region ]
  if any? birth-sites-in-region and not any? edges-on birth-sites-in-region
    [ move-to one-of birth-sites-in-region ]
  set heading random 360
end

to clear-environment
  clear-drawing
  ask bugs [ set xcor xcor + 0.000001 ] ;; a way to force a display update
end

;; a visualization technique to find bugs if you are convinced they are not there anymore
to flash-bugs
  repeat 3 [
    ask bugs [ set color black ]
    display
    wait 0.1
    ask bugs [ set color white ]
    display
    wait 0.1
  ]
  ask bugs [ set-phenotype-color ]
  display
end

to assign-genotype-labels  ;; turtle procedure
  ifelse show-genes? [ set label color ] [ set label "" ]
end

;; convert the genetic representation of gene frequency
;; into a phenotype (i.e., a color, using the rgb primitive)
;; we are using rgb color rather than NetLogo colors, thus, we just
;; make a list of the red green and blue genes.
to set-phenotype-color  ;; turtle procedure
  set color rgb red-gene green-gene blue-gene
end

to listen-host
  if mouse-inside? and mouse-down? and host-mouse-down-released? [
    ask players with [ host? ] [
      set host-mouse-down-released? false
      check-found-bugs (list mouse-xcor mouse-ycor)
    ]
  ]
  set host-mouse-down-released? not mouse-down?
end

;;;;;;;;;;;;;;;;;;;;;;
;; HubNet Procedures
;;;;;;;;;;;;;;;;;;;;;;
to listen-clients
  while [ hubnet-message-waiting? ] [
    hubnet-fetch-message
    ifelse hubnet-enter-message? [
      add-player
    ]
    [
      ifelse hubnet-exit-message? [
        remove-player
      ]
      [
        if hubnet-message-tag = "View" [
          ask players with [ user-name = hubnet-message-source ] [
            check-found-bugs hubnet-message
          ]
        ]
      ]
    ]
  ]
end

;; when a client logs in make a new player
;; and give it the default attributes
to add-player
  create-players 1 [
    set user-name hubnet-message-source
    initialize-player
  ]
end

to add-host
  create-players 1 [ initialize-host ]
end

to initialize-host
  set user-name "host"
  initialize-player
  set host? true ;;changes this back to true after initial-player sets it to false by default
  set host-role role
end

to initialize-player ;; player procedure
  hide-turtle
  set number-of-mates count players with [ role = "mate" ]
  set number-of-predators count players with [ role = "predator" ]
  if players-roles = "all mates"     [ set role "mate" ]
  if players-roles = "all predators" [ set role "predator" ]
  if players-roles = "mix of mates & predators" [
    ifelse number-of-mates >= number-of-predators
      [ set role "predator" ]
      [ set role "mate" ]
  ]
  set attempts 0
  set found 0
  set host? false
  set-percent
  send-player-info
end

to check-found-bugs [ msg ]
  ;; extract the coords from the hubnet message
  let clicked-xcor (item 0 msg)
  let clicked-ycor (item 1 msg)
  let this-region 0
  if clicked-ycor > 0 [ set this-region 1 ]
  if clicked-ycor < 0 [ set this-region 2 ]
  let this-player-role role

  set this-region region
  set xcor clicked-xcor      ;; go to the location of the click
  set ycor clicked-ycor
  set attempts attempts + 1  ;; each mouse click is recorded as an attempt for that player

  ;;  if the players clicks close enough to a bug's location, they catch it
  ;;  the in-radius (bug-size / 2) calculation helps make sure the user catches the bug
  ;;  if they click within one shape radius (approximately since the shape of the bug isn't
  ;;  a perfect circle, even if the size of the bug is other than 1)
  let candidates bugs with [ distance myself < size / 2 and region = this-region ]
  let num-region-bugs count bugs with [ region = this-region ]
  ifelse any? candidates and num-region-bugs >= 2 [ ;; must have at least 2 bugs in the region
    ;; randomly select one of the bugs you clicked on
    let found-bug one-of candidates
    set found found + 1
    ifelse this-player-role = "mate"
      [ set mate-total-found mate-total-found + 1 ]
      [ set predator-total-found predator-total-found + 1 ]
    ask found-bug [
      ;; if you are a mate, kill of a random bug, make two offspring from your mating, and the selected mate is killed off too
      if this-player-role = "mate" [
        repeat 2 [ make-one-offspring ]
        visualize-mating
        ask one-of other bugs with [ region = this-region ] [ die ]
        die
      ]
      ;; if you are a predator, make an offspring from another random bug, then remove the one you selected
      if this-player-role = "predator" [
        ask one-of other bugs with [ region = this-region ] [
          make-one-offspring
        ]
        visualize-death
      ]
    ]
    ask players [ send-player-info ]
  ]
  [ ;; even if we didn't catch a bug we need to update the attempts monitor
    send-player-info
  ]
end

to broadcast-competition-info
  hubnet-broadcast "# of predators" count players with [ role = "predator" ]
  hubnet-broadcast "Top predator" predator-leader
  hubnet-broadcast "Top predator's catches" predator-leader-found
  hubnet-broadcast "# of mates" count players with [ role = "mate" ]
  hubnet-broadcast "Top mate" mate-leader
  hubnet-broadcast "Top mate's matings" mate-leader-found
end

;; when clients log out simply get rid of the player turtle
to remove-player
  ask players with [ user-name = hubnet-message-source and not host? ] [
    die
  ]
end

to eat-bugs
  ;; extract the coords from the hubnet message
  let clicked-xcor (item 0 hubnet-message)
  let clicked-ycor (item 1 hubnet-message)

  ask players with [ user-name = hubnet-message-source ] [
    set xcor clicked-xcor      ;; go to the location of the click
    set ycor clicked-ycor
    set attempts attempts + 1  ;; each mouse click is recorded as an attempt
                               ;; for that player

    ;;  if the players clicks close enough to a bug's location, they catch it
    ;;  the in-radius (adult-bug-size / 2) calculation helps make sure the user catches the bug
    ;;  if they click within one shape radius (approximately since the shape of the bug isn't
    ;;  a perfect circle, even if the size of the bug is other than 1)
    let candidates bugs in-radius (adult-bug-size / 2)
    ifelse any? candidates [
      let doomed-bug one-of candidates
      set found found + 1
      set total-found total-found + 1
      ask doomed-bug [ visualize-death ]
      ;; all the players have monitors
      ;; displaying information about the leader
      ;; so we need to make sure that gets updated
      ;; when the leader changed
      ask players [
        set-percent
        send-player-info
      ]
    ]
    [ ;; even if we didn't catch a bug we need to update the attempts monitor
      send-player-info
    ]
  ]
end

;; calculate the percentage that this player found to the leader
to set-percent ;; player procedure
  ;; make sure we don't get a divide by 0 error
  ifelse leader-found > 0
    [ set percent (found / leader-found) * 100]
    [ set percent 0 ]
end

;; update the monitors on the client
to send-player-info ;; player procedure
  hubnet-send user-name "Your name" user-name
  hubnet-send user-name "Your role" role
  hubnet-send user-name "You have found" found
  hubnet-send user-name "# Attempts"  attempts
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Image Loading  and Combining Procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set-default-image-filenames
  set image3 "seashore.jpg"
  set image4 "glacier.jpg"
  set image5 "poppyfield.jpg"
end

to upload-image1
  set image1 user-file
end

to upload-image2
  set image2 user-file
end

;; loads a single or combined image as environment
to change-environment
  clear-drawing
  if (left-environment = "image1" or environment-right = "image1") and (image1 = 0) [
    user-message "Please upload image 1."
    stop
  ]
  if (left-environment = "image2" or environment-right = "image2") and (image2 = 0) [
    user-message "Please upload image 2."
    stop
  ]
  if not (left-environment  = "none") [
    set-environment (match-image-input left-environment) 1
  ]
  if not (environment-right = "none") [
    set-environment (match-image-input environment-right) 2
  ]
  ask bugs [ set hidden? true ]
  let image-file-name "stitched-image.png"
  bitmap:export bitmap:from-view image-file-name
  import-drawing image-file-name
  carefully [ file-delete image-file-name ] []
  ask bugs [ set hidden? false ]
end

to set-environment [image-name region-name]
  let xcor-image 0 ;;if region is 1 this will stay as 0, if 2 it will be 400
  if region-name = 2 [ set xcor-image 400 ]
  let image-name-scaled bitmap:scaled (bitmap:import image-name) 410 410
  bitmap:copy-to-drawing image-name-scaled xcor-image 0
end

;;;;;;;;;;;;;;;;;;;;;
;; Reporters
;;;;;;;;;;;;;;;;;;;;;

to-report match-image-input [ input-image ] ;; match the choices in the chooser with images
  let target-image ""
  if input-image = "image1" [ set target-image image1 ]
  if input-image = "image2" [ set target-image image2 ]
  if input-image = "seashore" [ set target-image image3 ]
  if input-image = "glacier" [ set target-image image4 ]
  if input-image = "poppyfield" [ set target-image image5 ]
  report target-image
end

;; imposes a threshold limit on gene-frequency.
;; without this genes could drift into negative values
;; or very large values
to-report limit-gene [ gene ]
  if gene < 0   [ report 0   ]
  if gene > 255 [ report 255 ]
  report gene
end


; Copyright 2006 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
190
95
1008
514
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-40
40
-20
20
1
1
1
ticks
30.0

BUTTON
15
10
80
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
85
10
175
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
215
10
510
43
carrying-capacity-environment-left
carrying-capacity-environment-left
0
100
2.0
1
1
NIL
HORIZONTAL

CHOOSER
375
45
510
90
left-environment
left-environment
"seashore" "glacier" "poppyfield" "image1" "image2" "none"
5

BUTTON
525
50
670
86
change environments
change-environment
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
15
445
175
478
flash bugs
flash-bugs
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
15
190
175
223
adult-bug-size
adult-bug-size
0.1
2
1.5
0.1
1
NIL
HORIZONTAL

BUTTON
15
410
175
443
clear both backgrounds
clear-environment
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
15
225
175
258
max-color-mutation
max-color-mutation
0
50
20.0
1
1
NIL
HORIZONTAL

CHOOSER
215
45
370
90
initial-colors-bugs-left
initial-colors-bugs-left
"random variation" "all gray" "all black or white"
0

BUTTON
15
110
175
143
upload custom image 1
upload-image1
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
15
145
175
178
upload custom image 2
upload-image2
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
850
45
985
90
environment-right
environment-right
"seashore" "glacier" "poppyfield" "image1" "image2" "none"
5

CHOOSER
15
50
175
95
players-roles
players-roles
"all mates" "all predators" "mix of mates & predators"
1

SLIDER
685
10
985
43
carrying-capacity-environment-right
carrying-capacity-environment-right
0
100
0.0
1
1
NIL
HORIZONTAL

CHOOSER
685
45
845
90
initial-colors-bugs-right
initial-colors-bugs-right
"random variation" "all gray" "all black or white"
0

SLIDER
15
260
175
293
offspring-distance
offspring-distance
2
40
40.0
2
1
NIL
HORIZONTAL

SWITCH
15
480
175
513
show-genes?
show-genes?
1
1
-1000

MONITOR
15
305
175
350
role of the host
host-role
17
1
11

MONITOR
15
350
95
395
host found
item 0 [found] of players with [host?]
17
1
11

MONITOR
95
350
175
395
# attempts
item 0 [attempts] of players with [host?]
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is a HubNet activity of natural selection that shows how a population hunted by a predator can develop camouflaging. It can shows how a population can become progressively more garish in appearance, when sexual selection is the prevalent selective pressure on the population.

For example, in a forest with green leaves, green bugs may emerge as the predominant bug color, when predators are hunting them, while red or yellow bugs may emerge as the predominant bug color in the same green leaved forest, when only mates are seeking them.

When a predator uses color to identify the location of prey in an environment, then the prey that have heritable trait variations that allow them to blend into the background better, tend to survive longer and reproduce more often.

If this continues over many generations, the distribution of colors in a population may shift to become better camouflaged in the surrounding environment.

When a bug uses color to identify the location of mates in an environment, then the mates that have heritable trait variations that allow them to stand out from the background better, tend to reproduce offspring with that bug more often.

If this continues over many generations, the distribution of colors in a population may shift to become better less camouflaged and more garish in the surrounding environment.

## HOW IT WORKS

Each HubNet participant or player assumes the role of a predator or a mate. When the HubNet simulation is started after pressing GO, participants should try to click on bugs as fast as they can with the mouse.

If the player is in the role of a predator, then each bug they catch is one that they ate. If the player is in the role of a mate, then each bug they catch is one that they mate with.

Each participant can monitor his or her relative success compared to other participants by watching the monitors in the client that show the number of bugs found (YOU HAVE FOUND) or if they are the host (HOST FOUND). .

Over time a population of bugs will either become harder or easier to detect in the environment (the environment is an image file that is loaded into the model), depending on whether mates or predators are exerting a selective pressure on the population.

Camouflaging emerges from: 1) a selective pressure that results from the interaction of predator, prey, and environment, 2) the genetic representation for genes to show color, 3) and small random changes that accumulate in new offspring in the remaining population that tend to be more advantageous.

Garishness also emerges from: 1) a selective pressure that results from the interaction of predator, prey, and environment, 2) the genetic representation for genes to show color, 3) and small random changes that accumulate in new offspring in the remaining population that tend to be more advantageous.

Trying to become the most successful predator or mate (in NUMBER FOUND of bugs) in the HubNet environment helps simulate the competitive pressure for limited food resources that exists between individual predators in a population or the competitive pressure for limited mates available to mate with in a mating season. Without this simulated competition, a participant could leisurely hunt for bugs regardless of how easy they are to catch or find. This sort of interaction would not put any (or as much) selective pressure on the bug population over time, and so camouflaging or garish colors would not emerge as readily in the population in this case.

3 genes determine the heritable trait of bug color. One gene is RED-GENE, another is GREEN-GENE, and the last is BLUE-GENE. Higher values for each of these genes, represent more copies of the gene/allele. More genes for producing pigmentation, leads to more saturated and brighter colors. So for example, a high values for the red-gene, results in the production of lots of red "substance" by the bug. A value of 0 for the RED-GENE would result in no red substance being expressed by the bug.

These overall blend of pigments that results in a single phenotype for coloration is determined by an RGB [Red-Green-Blue] calculation of all the gene values.

With each bug you eat, an existing bug is randomly chosen to reproduce one offspring. The offspring's gene-frequency for each of the three pigment genes may be slightly different than the parent (as determined by the MUTATION-STEP slider).

With each bug you mate with, two new offspring are produced and the mate is removed from the population. The offspring's gene-frequency for each of the three pigment genes may be slightly different than the mate that was chosen (as determined by the MUTATION-STEP slider).

## HOW TO USE IT

To run the simulation the GO button. To start the simulation over with the same group of players stop the GO button by pressing it again, press the SETUP button, and press GO again. To run the activity with a new group of students press the RESET button in the Control Center.

Make sure you select Mirror 2D view on clients in the HubNet Control Center after you press SETUP.

PREDATOR-ROLES specifies the type of role each player is assigned (the players include all the clients as well as the host).

- when this value is set to "all mates" each player will eat bugs when they click on them.

- when this value is set to "all predators" each player will mate with bugs when they click on them

- when this value is set to "a mix of predator & mates", a player may end up being assigned the role of either a mate or predator, and then they keep that role until SETUP is pressed again. The assigned role for that player will appear in the ROLE OF HOST monitor for the host or in the YOUR ROLE monitor for the clients.

UPLOAD IMAGE 1 is a button that is used to load an image file into memory, for use as a potential background. UPLOAD IMAGE 2 does the same, but for a 2nd image. Both buttons allow you to select an image file from anywhere on your computer hard drive to use as a background image. Once the image is loaded, then changing the LEFT-ENVIRONMENT or RIGHT ENVIRONMENT chooser to "image1" or "image2" will use that loaded image as the new background when SETUP or CHANGE ENVIRONMENTS is pressed.

CARRYING-CAPACITY-ENVIRONMENT-LEFT determines the size of the population in the left environment on SETUP, and how many bugs are in the world at one time when GO is pressed and bugs are being eaten or mates with. CARRYING-CAPACITY-ENVIRONMENT-RIGHT determines the size of the population in the right environment.

INITIAL-COLORS-BUGS-LEFT (applies to bugs in the left environment when SETUP is pressed) and INITIAL-COLORS-BUGS-RIGHT (applies to bugs in the right environment when SETUP is pressed):

- when this value is set to "random variations", the genotype of each bug's pigment production can range from 0 to 255, for red, and for green, and for blue pigments.

- when this value is set to "all gray", the genotype of each bug's pigment production will be set to 127.

- when this value is set to "all black or white", each bug has a 50/50 chance of being black or white ( pigment production will be set to 0 for each pigment or 255 for each pigment)

LEFT ENVIRONMENT is a chooser that specifies the file name to load as a background image in the left environment on SETUP or when the CHANGE ENVIRONMENTS button is pressed. RIGHT ENVIRONMENT is a chooser that specifies the image to use in the right environment. Three default images are provided in the models library folder with the model that can be selected: "seashore", "glacier", and "poppyfield"

ADULT-BUG-SIZE is a slider that can be changed at any time during GO or before SETUP to modify the size of the shapes for the bugs. When bugs are born they start out at a size of 0, then quickly grow to the value set by ADULT-BUG-SIZE and remain at that value for the remainder of their life. This "growth" in size helps prevent the predators and mates on cueing in on "sudden" bug appearances in the environment, which diminish the survival/reproductive advantage that color variations would offer.

MAX-COLOR-MUTATION is a slider that determines how much the pigment genes can drift from their current values in each new generation. For example, a MAX-COLOR-MUTATION of 1 means that the gene frequency for any of the three pigments could go up 1, down 1, or any value in between (including 0, which would be no change) in the offspring.

OFFSPRING-DISTANCE is a slider that determines how far away (in patches) an offspring could show up from a parent. For example, a distance of 5 means the offspring could be between 0 and 5 patches away from the parent.

HOST FOUND is a monitor showing the number of bugs found by the host

HOST ATTEMPTS is a monitor showing the number of attempted clicks of the mouse button by the host, as they hunted in the environment.

CLEAR BOTH BACKGROUNDS is a button that removes the images from both background, and makes the background all black.

FLASH BUGS is a button that quickly flashes the bugs from white to black and back a few times, to show the players where the camouflaged bugs were hiding.

SHOW-GENES? is a switch that reveals the RGB (Red-Green-Blue) gene frequency values for each bug. The values for Red can range from 0 to 255, and this also true for Green and Blue. These numbers represent how fully expressed each pigment is (e.g. 102-255-51 would represent genetic information that expresses the red pigment at 40% its maximum value, the green pigment at 100%, and the blue pigment at 20%.

## THINGS TO TRY

Larger numbers of bugs tend to take longer to start camouflaging or becoming garish, but larger numbers of prey or mates (participants) speed up the emergence of these outcomes in larger populations.

A common response from the players when they are predators (within about 1 minute of interaction with the model) is "where did the bugs all go?" If you keep playing with the model, the user might get better at finding those hard to find bugs, but if s/he keeps trying to catch bugs quickly, even an experienced user will find that the creatures will become very hard to find in certain environments.

Each new offspring starts at zero size and grows to full size (specified by BUG-SIZE) after a while. This growth in size is included to make brand new offspring harder to detect. If newly created offspring were full sized right away, your eyes would more easily detect the sudden appearance of something new.

Sometimes two or more "near background" colors emerge as a predominant feature in a population of bugs. An example of this is the appearance of mostly green and red bugs in the poppy field, or dark blue/black and snow blue in the glacier background. Other times, the saturation of the bugs appears to be selected for. An example of this is a common outcome of "shell colored" bugs on the seashore background (e.g. light yellow, light tan, and light blue bugs similar to the shells of the seashore).

In environments that have two distinct areas (such as a ground and sky), each with their own patterns and background colors, you might see two distinct populations of different camouflaging outcomes. Often, while hunting in one area, you will be surprised to look over at the other area (after they hadn't been paying attention to that area in a while) and notice that now there are a bunch of bugs in that background that blend in this new area very well, but whose colors are distinctly different than those that blend into the original area you were hunting in.

Once you reach a point where you are having trouble finding the bugs, it is useful to either press FLASH to show where they are (and how they are camouflaged), or press CLEAR-BACKGROUND to enable you to study their color distribution and location.

## EXTENDING THE MODEL

What if the body shape of the bugs was heritable and mutated?

## NETLOGO FEATURES

The bitmap extension is used to support `bitmap:export bitmap:from-view` to build a new image file from the file selected for import, for later use by the IMPORT-DRAWING primitive.

IMPORT-DRAWING is the primitive that loads the image into the drawing, which in this case is merely a backdrop.

IN-RADIUS is the primitive used to check if the mouse is within the graphical "footprint" of a turtle.

This model uses RGB colors, that is, colors expressed as a three item list of red, green and blue. This gives a large range of colors than with NetLogo colors.

The side by side 2 environment interface is a feature that is used in many of the update evolution and population dynamics models in the BEAGLE curriculum. It is built using a breed of turtles called edges that are on a graphics layer above the bugs. When bugs travel under the edges they are relocated so that they are "wrapped" around to the other side of their respective environment, similar to the world wrapping feature in the WORLD VIEW.

It has proven useful for supporting students in comparing outcomes between different conditions/interactions in different environment, when they can see those environments and outcomes side by side.

## RELATED MODELS

Bacteria Hunt Speeds
Bug Hunt Camouflage
Bug Hunter Camouflage HubNet
Peppered Moths
Guppy Spots

## CREDITS AND REFERENCES

Inspired by this BugHunt! Macintosh freeware: https://web.archive.org/web/20101213084130/http://bcrc.bio.umass.edu/BugHunt/.

Thanks to Michael Novak for his work on the design of this model and the BEAGLE Evolution curriculum.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2006).  NetLogo Bug Hunters Adaptations HubNet model.  http://ccl.northwestern.edu/netlogo/models/BugHuntersAdaptationsHubNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the HubNet software as:

* Wilensky, U. & Stroup, W. (1999). HubNet. http://ccl.northwestern.edu/netlogo/hubnet.html. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2006 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2006 Cite: Novak, M. -->
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

edges
false
0
Rectangle -7500403 true true 0 0 300 300

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

heart
false
0
Polygon -2674135 true false 241 99 239 131 209 176 179 206 150 240 149 99
Polygon -2674135 true false 241 97 237 82 226 70 208 61 196 59 180 62 165 71 158 82 153 90 149 104 242 104
Polygon -2674135 true false 59 97 63 82 74 70 92 61 104 59 120 62 135 71 142 82 147 90 151 104 58 104
Polygon -2674135 true false 58 99 60 131 90 176 120 206 150 240 150 99
Polygon -16777216 false false 149 97 143 82 136 74 128 65 116 59 104 58 88 60 74 69 64 78 58 100 58 110 59 131 75 155 90 177 120 207 150 240 180 204 210 175 227 147 238 131 241 105 239 85 227 72 211 61 195 58 181 60 169 66 159 77 154 86

heart2
false
0
Polygon -2064490 true false 59 97 63 82 74 70 92 61 104 59 120 62 135 71 142 82 147 90 151 104 58 104
Polygon -2674135 true false 29 67 33 52 44 40 62 31 74 29 90 32 105 41 112 52 117 60 121 74 28 74
Polygon -2064490 true false 241 97 237 82 226 70 208 61 196 59 180 62 165 71 158 82 153 90 149 104 242 104
Polygon -2674135 true false 211 67 207 52 196 40 178 31 166 29 150 32 135 41 128 52 123 60 119 74 212 74
Polygon -2064490 true false 58 99 60 131 90 176 120 206 150 221 150 99
Polygon -2674135 true false 28 69 30 101 60 146 90 176 120 191 120 69
Polygon -2064490 true false 241 99 239 131 209 176 179 206 149 221 149 99
Polygon -2674135 true false 211 69 209 101 179 146 149 176 119 191 119 69

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

square
false
0
Rectangle -7500403 true true 0 0 300 300

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
Polygon -7500403 true true 75 30 30 75 105 150 30 225 75 270 150 195 225 270 270 225 195 150 270 75 225 30 150 105
Polygon -16777216 false false 30 75 105 150 30 225 75 270 150 195 225 270 270 225 195 150 270 75 225 30 150 105 75 30
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
MONITOR
5
10
130
59
Your name
NIL
0
1

MONITOR
5
120
130
169
You have found
NIL
3
1

MONITOR
5
175
130
224
# Attempts
NIL
0
1

MONITOR
5
65
130
114
Your role
NIL
3
1

VIEW
140
10
950
420
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
-40
40
-20
20

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
