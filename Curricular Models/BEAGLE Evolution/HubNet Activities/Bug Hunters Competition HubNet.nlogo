globals
[
  ;; global variables related to color
  bugs-color
  grass-color
  dirt-color
  invasive-color
  not-grown-back-color

  ;; global variables related to bugs
  bugs-size             ;; the shape size for a bug
  bugs-stride           ;; how much a bug moves at every tick
  bugs-reproduce-energy ;; energy at which bugs reproduce
  min-energy-of-any-bug ;; energy of the bug with the lowest energy in the population
  max-energy-of-any-bug ;; energy of the bug with the maximum energy in the population
  dead-bugs             ;; keeps count of the number of bugs that have died in a model run
  offspring-bugs        ;; keeps count of the number of bugs  reproduced by automated bugs
  bugs-energy-from-food ;; energy that the bug eat from the food (the grass) each tick
                        ;; set to 4 in this model, but is adjustable in other Bug Hunt models (such as Bug Hunt Consumers).

  ;; global variables related to grass
  max-grass-energy      ;; the most amount of grass that can grow in a single patch (determined by a max. energy threshold)
  grass-growth-rate     ;; set to 1 in this model, but is adjustable in other Bug Hunt models (such as Bug Hunt Consumers).
  competition-status    ;; updates users with a message about the status of the competition

  ;; global variables related to time and histogram
  time-remaining        ;; time left for the competition to end
  x-min-histogram
  x-max-histogram
  x-interval-histogram

  old-player-vision
]

breed [ bugs bug ]
breed [ players player ]

bugs-own    [destination-patch controlled-by-player? owned-by energy]
players-own [destination-patch user-id dead?]

patches-own [
  fertile?              ;; whether or not a grass patch is fertile is determined by the amount-grassland slider
  grass-energy          ;; energy for grass
  countdown
  ]


to startup ;; setting up hubnet
  hubnet-reset
  setup
end


to setup
  ask bugs [die]
  clear-all-plots

  ;; time variables
  set time-remaining 0


  ;; variables for the histogram
  set x-min-histogram 0
  set x-max-histogram 0
  set x-interval-histogram 0

  set old-player-vision 0

  ;; variables for grass
  set max-grass-energy 100
  set grass-growth-rate 1     ;; set to 1 by default in this model.  But in other Bug Hunt Models (such as Bug Hunt Consumers), this is adjustable
                              ;; In other Bug Hunt Models (such as Bug Hunt Consumers), grass-growth-rate has a default of 1, but is slider adjustable.

  ;; variables for bugs
  set-default-shape bugs "bug"
  set bugs-size 1.0
  set bugs-stride 0.2
  set bugs-reproduce-energy 100
  set bugs-energy-from-food 4  ;; set to 4 by default in this model.
                               ;; In other Bug Hunt Models (such as Bug Hunt Consumers), bug-energy-from-food has a default of 4, but is slider adjustable.
  set dead-bugs 0
  set offspring-bugs 0

  ;; setting colors
  set bugs-color (violet )
  set grass-color (green)
  set dirt-color (gray - 1)
  set not-grown-back-color white

  set competition-status "Get Ready"
  add-starting-grass
  if include-clients-as-bugs? [ask players [assign-bug-to-player]]
  add-bugs


  listen-clients
  check-reset-perspective
  display-labels

  reset-ticks
  set time-remaining (length-competition - ticks)
  send-all-info
end


to setup-a-new-bugs-for-a-new-player [p-user-id]
   set hidden? false
   set color (magenta - 1)
   set size 1.4  ;; easier to see
   set label-color blue

   set energy 10 * bugs-energy-from-food
   set owned-by p-user-id
   set controlled-by-player? true
   update-statistics
end


to go
  if ticks < length-competition  [
    set competition-status "Running"
    update-statistics
    listen-clients
    send-all-info
    ask patches [ grow-grass ]
    ask bugs [
      if automated-bugs-lose-energy? [ set energy energy - 1 ] ;; deduct energy for bugs only if bugs-lose-energy? switch is on
      if automated-bugs-reproduce? [ reproduce-bugs ]
      if automated-bugs-wander? [right random 30 left random 30]
      fd bugs-stride
      bugs-eat-grass
      bug-death
    ]
    display-labels
    check-reset-perspective
    tick
    set time-remaining (length-competition - ticks)
  ]
  if ticks = length-competition  [
    display
    set competition-status "Over"
    if time-remaining <= 0 [set time-remaining 0]
    send-all-info
    tick
  ]
end


to add-starting-grass
  ask patches [
      ifelse random 100 < amount-grassland    ;;  the maximum number of fertile patches is set by a slider
    [
      set fertile? true
      set grass-energy max-grass-energy
    ]
    [
      set fertile? false
      set grass-energy 0
    ]
    color-grass
  ]
end


to add-bugs
  create-bugs initial-#-automated-bugs  ;; create the bugs, then initialize their variables
  [
    set color bugs-color
    set size bugs-size
    set controlled-by-player? false
    set energy 10 * bugs-energy-from-food
    setxy random world-width random world-height
  ]
end


to bugs-eat-grass  ;; bugs procedure
  ;; if there is enough grass to eat at this patch, the bugs eat it
  ;; and then gain energy from it.
  if grass-energy > bugs-energy-from-food  [
    ;; grass lose ten times as much energy as the bugs gains (trophic level assumption)
    set grass-energy (grass-energy - (bugs-energy-from-food * 10))
    set energy (energy + bugs-energy-from-food)  ;; bugs gain energy by eating
  ]
  ;; if grass-energy is negative, make it positive
  if grass-energy <=  bugs-energy-from-food  [set countdown sprout-delay-time ]
end



to reproduce-bugs  ;; automated bugs procedure
  if (energy > ( bugs-reproduce-energy))
  [
    if random 2 = 1 and not controlled-by-player?          ;; only half of the fertile bugs reproduce (gender)
    [
      set energy (energy / 2)      ;; lose energy when reproducing - energy is divided between offspring and parent
      hatch  1
      [    ;; hatch an offspring set it heading off in a a random direction and move it forward a step
        set offspring-bugs (offspring-bugs + 1)
        set size bugs-size
        set color bugs-color
        rt random 360 fd bugs-stride
      ]
    ]
  ]
end


to bug-death  ;; bugs die when energy dips below zero (starvation)
  if  (energy < 0)
 [ set dead-bugs (dead-bugs + 1)
   die ]

end

to grow-grass  ;; patch procedure
  set countdown (countdown - 1)
  ;; fertile patches gain 1 energy unit per turn, up to a maximum max-grass-energy threshold
  if fertile? and countdown <= 0 [
    set grass-energy (grass-energy + grass-growth-rate)
    if grass-energy > max-grass-energy [set grass-energy max-grass-energy]
  ]
  if not fertile? [set grass-energy 0]
  if grass-energy < 0 [set grass-energy 0 set countdown sprout-delay-time]
  color-grass
end

to color-grass
  ifelse fertile? [
    ifelse grass-energy > 0
    ;; scale color of patch from whitish green for low energy (less foliage) to green - high energy (lots of foliage)
    [set pcolor (scale-color green grass-energy  (max-grass-energy * 2)  0)]
    [set pcolor not-grown-back-color]
  ]
  [set pcolor dirt-color]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; player enter / exit procedures  ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to create-new-player
  create-players 1
  [
    set dead? true
    set user-id hubnet-message-source
    set hidden? true
    assign-bug-to-player
  ]
end


to assign-bug-to-player
  if include-clients-as-bugs? [
    let p-user-id user-id
    let parent-player self
    let child-bug nobody
    setxy random-xcor random-ycor
    ask bugs with [p-user-id = owned-by] [die]
    hatch 1 [
      set breed bugs
      set child-bug self
      setup-a-new-bugs-for-a-new-player p-user-id
      ask parent-player [ create-link-from child-bug [ tie ] set dead? false]
    ]
  ]
end


to remove-player
  ask bugs with [owned-by = hubnet-message-source  and controlled-by-player?] [die]
  ask players with [user-id = hubnet-message-source] [ die ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Handle client interactions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to listen-clients
  while [ hubnet-message-waiting? ]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [ create-new-player ]
    [
      ifelse hubnet-exit-message?
      [ remove-player ]
      [ ask players with [user-id = hubnet-message-source] [execute-command hubnet-message-tag hubnet-message ]]
    ]
  ]
end


to check-reset-perspective
   if player-vision != old-player-vision [
     ask players [
       hubnet-reset-perspective user-id
       hubnet-send-follow user-id self player-vision
     ]
     set old-player-vision player-vision
   ]
end


to execute-command [command msg]
  if command = "View" [ orient-my-turtle command msg ]
end


to execute-turn [new-heading]
  set heading new-heading
end


to display-labels
  let b-color 0
  let energy-range (word  " [" min-energy-of-any-bug " to " max-energy-of-any-bug "]: ")

  ask bugs [
    set label-color black
    if show-labels-as = "none" [set label ""]
    if show-labels-as = "player energy"  [ set label (word round energy) ]
    if show-labels-as = "energy ranges"  [ set label (word energy-range round energy) ]
    if show-labels-as = "player name" [
      ifelse controlled-by-player? [set label owned-by] [set label ""]
    ]
    if show-labels-as = "player energy:name" [
      ifelse controlled-by-player? [set label (word round energy ":" owned-by)] [set label ""]
    ]
  ]
end


to orient-my-turtle [name coords]
  let next-destination-patch patch first coords last coords
  if patch-here != destination-patch [
    ask my-agent [ set destination-patch next-destination-patch face destination-patch ]
  ]
end


to-report my-agent
  let this-user-id user-id
  let my-bug nobody
  set my-bug bugs with [owned-by = this-user-id]
  report my-bug
end


to-report energy-of-your-bug
  let this-user-id user-id
  let this-bug-energy 0
  if any? bugs with [owned-by = this-user-id] [
    ask bugs with [owned-by = this-user-id] [set this-bug-energy energy]
  ]
  report this-bug-energy
end


to send-this-players-info ;; player procedure
  ;; update the monitors on the client
  let message-to-send ""
  let my-energy energy-of-your-bug
  let place 1 + (count bugs with [energy > my-energy])
  let num-ties count bugs with [energy = my-energy]
  let total-number-bugs count bugs
  let any-ties ""
  let out-of (word " out of " total-number-bugs "  ")
  if num-ties > 1 [set any-ties (word " [" num-ties "-way tie]") ]
  ifelse include-clients-as-bugs?
    [set message-to-send (word  place  out-of any-ties)]
    [set message-to-send "not currently in this competition"]
  hubnet-send user-id "Your Place in the Competition" message-to-send

end


to send-all-info     ;;send common info to this client
  ask players [send-this-players-info]
  hubnet-broadcast "time remaining" time-remaining
end


to update-statistics
  if any? bugs [
   set min-energy-of-any-bug precision (min [energy] of bugs ) 1
   set max-energy-of-any-bug precision (max [energy] of bugs ) 1
  ]
end


; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
405
10
913
519
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
-12
12
-12
12
1
1
1
ticks
30.0

BUTTON
0
80
60
113
setup
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
62
80
135
113
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

PLOT
0
420
400
540
Population Size
time
bugs
0.0
1000.0
0.0
10.0
true
true
"" ""
PENS
"bugs" 1.0 0 -16777216 true "" "plotxy ticks count bugs"

MONITOR
0
375
75
420
# bugs
count bugs
3
1
11

SLIDER
0
45
220
78
initial-#-automated-bugs
initial-#-automated-bugs
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
225
45
400
78
amount-grassland
amount-grassland
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
225
10
400
43
length-competition
length-competition
0
3000
500.0
100
1
NIL
HORIZONTAL

SWITCH
0
165
235
198
automated-bugs-lose-energy?
automated-bugs-lose-energy?
1
1
-1000

SWITCH
0
200
235
233
automated-bugs-reproduce?
automated-bugs-reproduce?
1
1
-1000

PLOT
0
240
400
360
Energy Levels of Bugs
energy level
bugs
0.0
500.0
0.0
40.0
true
true
"let num-bars 20\n let y-axis-max-histogram  (5 + ((floor (count bugs with [floor (energy / 20) = (item 0 modes [floor (energy / 20)] of bugs)] / 5)) * 5))\n set-current-plot \"Energy Levels of Bugs\"\n plot-pen-reset       \n  ;; autoscale x axis by 500s\n set-plot-x-range (500 * floor (min-energy-of-any-bug / 500)) (500 + 500 *  (floor (max-energy-of-any-bug / 500)))\n  if y-axis-max-histogram < 10 [set y-axis-max-histogram 10]\n  ;; autoscale y axis by 5s, when above 10\n  set-plot-y-range 0 y-axis-max-histogram   \n  set-histogram-num-bars num-bars\n  set  x-min-histogram plot-x-min\n  set  x-max-histogram plot-x-max\n  set   x-interval-histogram (x-max-histogram - x-min-histogram) / num-bars\n  \n  histogram [ energy ] of bugs" "let num-bars 20\n let y-axis-max-histogram  (5 + ((floor (count bugs with [floor (energy / 20) = (item 0 modes [floor (energy / 20)] of bugs)] / 5)) * 5))\n set-current-plot \"Energy Levels of Bugs\"\n plot-pen-reset       \n  ;; autoscale x axis by 500s\n set-plot-x-range (500 * floor (min-energy-of-any-bug / 500)) (500 + 500 *  (floor (max-energy-of-any-bug / 500)))\n  if y-axis-max-histogram < 10 [set y-axis-max-histogram 10]\n  ;; autoscale y axis by 5s, when above 10\n  set-plot-y-range 0 y-axis-max-histogram   \n  set-histogram-num-bars num-bars\n  set  x-min-histogram plot-x-min\n  set  x-max-histogram plot-x-max\n  set   x-interval-histogram (x-max-histogram - x-min-histogram) / num-bars\n  \n  histogram [ energy ] of bugs"
PENS
"bugs" 20.0 1 -16777216 true "" ""

CHOOSER
260
80
400
125
show-labels-as
show-labels-as
"none" "player name" "player energy" "energy ranges" "player energy:name"
4

SLIDER
240
165
400
198
player-vision
player-vision
1
10
4.0
1
1
NIL
HORIZONTAL

MONITOR
77
375
174
420
bugs that died
dead-bugs
17
1
11

MONITOR
176
375
273
420
# offspring
offspring-bugs
17
1
11

MONITOR
153
80
246
125
time remaining
time-remaining
0
1
11

SWITCH
0
10
220
43
include-clients-as-bugs?
include-clients-as-bugs?
0
1
-1000

MONITOR
320
360
400
405
x-interval
x-interval-histogram
17
1
11

SWITCH
0
130
235
163
automated-bugs-wander?
automated-bugs-wander?
0
1
-1000

SLIDER
240
130
400
163
sprout-delay-time
sprout-delay-time
0
200
50.0
50
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model shows how competition emerges between individuals in the same population.  In a consumer / producer ecosystem, competition for shared resources emerges whenever there is a limited sappy of those resources.  Such competition may be intentional or unintentional, but similar outcomes result in either case - some individuals outcompete others for those shared resources.

Even when individuals are identical, differences in where and when shared resources in the ecosystem are available will lead to variation in competitive advantages for some individuals over time (some individuals happen to be closer to those resources than other individuals).  This variation in competitive advantage, will enable some individuals to survive while others die.

The degree of competition in an ecosystem depends on the number of individuals in the ecosystem and the amount of resources available per individual. A very small number of individuals may generate very little or no competition (individuals may have all the resources that they need).  However, many individuals will generate intensive competition for resources, such that very few resources are available for each individual and many individuals will die for lack of adequate resources.

## HOW IT WORKS

In this model, you can have two kinds of bugs; bugs controlled by players using HubNet or automated bugs.

Each HubNet player assumes the role of a consumer.  When the HubNet simulation is started after pressing GO, players should try to eat as much grass as they can. A bug controlled by a player may be turned left or right by clicking on a destination  in the client view of the World.  As the controlled bug moves across a green patch, some of the "grass" at the spot is automatically eaten.  Grass grows at a fixed rate, and when it is eaten, a fixed amount of grass energy is deducted from the patch (square) where the grass was eaten and a fixed amount of time must pass before new grass grows back at that spot.

In addition, automated bugs can be included in the model. They wander around the world randomly, eating grass.

When bugs-lose-energy? is on, bugs lose energy at each step and they must eat grass to replenish their energy. When they run out of energy, they die. Automated bugs can be set to reproduce automatically when they have enough energy to have an offspring. In such a case, the offspring and parent split the energy amongst themselves.

## HOW TO USE IT

Make sure you select Mirror 2D view on clients in the HubNet Control Center. Once all the players have joined the simulation through hubnet, press SETUP. To run the activity, press GO.

To start the activity over with the same group of players, stop the model by pressing the GO button again, press the SETUP button, and press GO again.  To run the activity with a new group of players press the RESET button in the Control Center.

The controls included in this model are:

AMOUNT-GRASSLAND: The percentage of patches in the World & View that produce grass.

INITIAL-NUMBER-AUTOMATED-BUGS: The initial size of bug population that is not controlled by a player.

SPROUT-DELAY-TIME:  Controls how long before "eaten" grass starts sprouting and growing back.  Increase this value for large numbers of players to make the competition more difficult (and when there are no automated bugs in the ecosystem).  Decrease this value for small numbers of players and when there are lots of automated bugs in the ecosystem.

LENGTH-COMPETITION:  Determines how long the competition will last. The unit of length is ticks.

INCLUDE-CLIENTS-AS-BUGS?:  When "On", all HubNet connected clients will be given an individual bug to control that is assigned to their client when SETUP is pressed. When this is "Off", the model will run only on your local machine.

AUTOMATED-BUGS-WANDER?:  When "On", automated bugs will turn a random amount left or right (between 30 and -30 degrees from its current heading) each tick.  When "off" the automated bugs will move in a straight line.

AUTOMATED-BUGS-LOSE-ENERGY?: When "On", bugs lose one unit of energy for each tick.

AUTOMATED-BUGS-REPRODUCE?:  When "On", automated bugs will reproduce one offspring when they reach a set threshold of energy. The parent bug's energy will be split between the parent and the offspring. The count of offspring is kept track of in the monitor "# OFFSPRING".

PLAYER-VISION:  Used to set the radius shown when hubnet-send-follow is applied for sending a client view update for each player showing a radius sized Moore neighborhood around the bug the player is controlling.

SHOW-LABELS-AS:  when set to "player name" will show a player name label next to each bug controlled by a client.  When set to "energy levels" will show the amount of energy on the label next to each bug (controlled by clients and automated bugs).  When set to   "energy ranges" will show the range of energy values and the energy value of all bugs in this format "[min, max]: this bug".  When set to "player energy:name" will show the player energy for their bug followed by a colon and then their user name, for only the bugs controlled by clients.

The plots in the model are:

ENERGY LEVELS OF BUGS:  Shows a histogram of bugs and their respective energy levels.

POPULATION SIZE:  Shows the size of the bug population size over time.

X-INTERVAL:  reports whatever the x-interval is for 20 bars in the historgram range.  It is being reported for use in the classroom BEAGLE activity where students build a histogram using the same x-interval as the NetLogo ENERGY LEVELS OF BUGS graph.

Note: Grass squares grow back (become darker green) over time and accumulate more stored energy (food) as they become darker.

## THINGS TO NOTICE

The histogram of ENERGY LEVELS OF BUGS will show that some bugs are more successful at gaining more energy from plants than others.  The histogram will show this when the bugs are intentionally being controlled by players, when they are being randomly controlled by the computer, and any combination of both.

When BUGS-LOSE-ENERGY is set to "off", the histogram will keep drifting further to the right then when it is set to "on".

For large populations of participants or large populations of automated bugs, the histogram for ENERGY LEVELS OF BUGS will tend to approximate a bell shaped curve.  When both participants and automated bugs are present, two histograms tend to form showing a bi-modal bell-shaped distribution, where the intentionally competing participants tend to be in the right shifted bell-shaped distribution and the automated bugs tend to be in the left shifted bell-shaped distribution.

## THINGS TO TRY

If you adjust the PLAYER-VISION, does changing the radius of vision for each player effect their ability to compete?  Does the shape of the histogram change for the competition?

If you adjust the AMOUNT-OF-GRASSLAND, does less grassland affect the shape of the histogram change for the competition?

How does LENGTH-OF-COMPETITION affect the spread of the distribution in the histogram?

## EXTENDING THE MODEL

The model could be extended for some player to control predators and others to control consumers.  Alternately, some players could control consumers on one team (one type of color of bugs) and some players could control consumers on another team (another type of color of bugs).  Such a competition between teams may still tend to result in similar shaped and similar shifted histograms for energy level distributions for each team of bugs.

## NETLOGO FEATURES

Each player gets a different view, attached to their own player turtle, which is in turn attached to a bug they are steering.  These customized views for following a turtle are sent to each client using the hubnet-send-follow command.

## RELATED MODELS

Look the Wolf Sheep Predation model, Bug Hunt Consumers model, Bug Hunt Predation and Bug Hunt Invasive Species model.

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2011).  NetLogo Bug Hunters Competition HubNet model.  http://ccl.northwestern.edu/netlogo/models/BugHuntersCompetitionHubNet.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

aphid
true
0
Circle -7500403 true true 129 84 42
Circle -7500403 true true 96 126 108

aphid-with-parasite
true
0
Circle -7500403 true true 129 84 42
Circle -7500403 true true 96 126 108
Circle -2674135 false false 8 8 285

bird
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -16777216 true false 151 125 134 124 128 188 140 198 161 197 174 188 166 125
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Circle -16777216 true false 144 55 7
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

bug
true
0
Circle -7500403 true true 75 116 150
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

egg
true
0
Circle -1 true false 120 95 60
Circle -1 true false 105 142 90
Polygon -1 true false 195 180 180 120 120 120 105 180

fox
false
0
Polygon -7500403 true true 72 225 94 249 109 252 119 252 111 242 99 241 87 225 91 181 62 112 43 119 28 150 29 164 58 204 50 241 74 271 84 279 99 279 98 267 87 266 67 242
Polygon -7500403 true true 210 90 204 56 214 42 222 66 211 71
Polygon -7500403 true true 181 107 213 70 226 63 257 71 260 90 300 120 289 129 249 110 218 135 209 151 204 164 192 179 169 186 154 190 129 190 89 181 69 167 60 112 124 111 160 112 170 105
Polygon -6459832 true false 252 143 242 141
Polygon -6459832 true false 254 136 232 137
Line -16777216 false 80 159 89 179
Polygon -6459832 true false 262 138 234 149
Polygon -7500403 true true 50 121 36 119 24 123 14 128 6 143 8 165 8 181 7 197 4 233 23 201 28 184 30 169 28 153 48 145
Polygon -7500403 true true 171 181 178 263 187 277 197 273 202 267 187 260 186 236 194 167
Polygon -7500403 true true 223 75 226 58 245 44 244 68 233 73
Line -16777216 false 89 181 112 185
Line -16777216 false 31 150 41 130
Polygon -16777216 true false 230 67 228 54 222 62 224 72
Line -16777216 false 30 150 30 165
Circle -1184463 true false 225 76 22
Polygon -7500403 true true 225 121 258 150 267 146 236 112

fox3
false
3
Polygon -6459832 true true 90 105 75 81 60 75 44 83 36 98 38 120 38 136 37 152 15 180 53 156 58 139 60 124 58 108 90 120
Polygon -6459832 true true 196 106 228 69 240 60 263 63 275 89 300 110 285 135 240 120 233 134 225 150 225 165 207 178 184 185 169 189 144 189 104 180 84 166 78 113 139 110 175 111 185 104
Polygon -6459832 true true 252 143 242 141
Polygon -6459832 true true 254 136 232 137
Polygon -6459832 true true 262 138 234 149
Polygon -6459832 true true 195 165 180 210 143 247 144 263 159 267 164 253 195 225 225 165
Polygon -6459832 true true 238 75 240 45 255 30 259 68 248 73
Polygon -16777216 true false 285 135 297 116 285 111
Polygon -6459832 true true 135 210 151 181 119 165 105 165 73 184 31 183 -9 205 -9 226 6 231 7 214 38 198 75 225 120 210
Polygon -6459832 true true 218 80 203 50 233 65
Polygon -6459832 true true 195 180 240 210 270 240 293 246 297 231 283 226 240 180 210 165
Polygon -6459832 true true 94 112 76 119 60 151 60 165 79 197 78 239 100 279 121 279 126 264 109 263 93 232 120 195 105 150

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

mouse
false
0
Polygon -7500403 true true 38 162 24 165 19 174 22 192 47 213 90 225 135 230 161 240 178 262 150 246 117 238 73 232 36 220 11 196 7 171 15 153 37 146 46 145
Polygon -7500403 true true 289 142 271 165 237 164 217 185 235 192 254 192 259 199 245 200 248 203 226 199 200 194 155 195 122 185 84 187 91 195 82 192 83 201 72 190 67 199 62 185 46 183 36 165 40 134 57 115 74 106 60 109 90 97 112 94 92 93 130 86 154 88 134 81 183 90 197 94 183 86 212 95 211 88 224 83 235 88 248 97 246 90 257 107 255 97 270 120
Polygon -16777216 true false 234 100 220 96 210 100 214 111 228 116 239 115
Circle -16777216 true false 246 117 20
Line -7500403 true 270 153 282 174
Line -7500403 true 272 153 255 173
Line -7500403 true 269 156 268 177

rabbit
false
4
Polygon -1184463 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -1184463 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -1184463 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -1184463 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 29 110 32
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -7500403 false 165 180 180 165
Line -7500403 false 180 165 225 165

rocks
false
0
Polygon -7500403 true true 0 300 45 150 105 120 135 90 165 60 195 75 225 75 255 165 300 285 300 300

wasp
true
0
Polygon -1184463 true false 195 135 105 135 90 150 90 210 105 255 135 285 165 285 195 255 210 210 210 150 195 135
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 135 105 120 105 60 120 45 180 45 195 60 195 120 180 135
Polygon -6459832 true false 150 0 120 15 120 45 180 45 180 15
Circle -16777216 true false 105 15 30
Circle -16777216 true false 165 15 30
Polygon -7500403 true true 180 75 270 90 300 150 300 210 285 210 255 195 210 120 180 90
Polygon -16777216 true false 135 300 165 300 165 285 135 285
Polygon -7500403 true true 120 75 30 90 0 150 0 210 15 210 45 195 90 120 120 90

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
355
10
855
510
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
-12
12
-12
12

MONITOR
115
10
345
59
Your Place in the Competition
NIL
3
1

PLOT
10
210
345
360
Energy Levels of Bugs
energy level
bugs
0.0
500.0
0.0
10.0
true
true
"" ""
PENS
"bugs" 20.0 1 -16777216 true "" ""

MONITOR
10
10
112
59
time remaining
NIL
0
1

PLOT
10
60
345
210
Population Size
time
bugs
0.0
1000.0
0.0
10.0
true
true
"" ""
PENS
"bugs" 1.0 0 -16777216 true "" ""

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
