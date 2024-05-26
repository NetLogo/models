breed [unsaturated-mers unsaturated-mer] ;; unsaturated-mers don't have full bonds. These are usually monomers.
breed [radical-mers radical-mer] ;; the mer at the end of a propagating chain has a free radical, and is therefore a radical mer
breed [saturated-mers saturated-mer]  ;; any mer in a polymer that is not at the end has its bonds saturated
breed [radical-initiators radical-initiator]  ;; initiators in the model start out as radical initiators
breed [initiators initiator] ;; once they bond, the initiators lose their free radical, turning into just an initiator

turtles-own [
  chain-id ;; identification number for each polymer for calculating molecular weight
]

initiators-own [
  molecular-weight ;; molecular weight of polymer the initiator is part of
  track-mw? ;; boolean for whether or not molecular weight is counted in plot; to avoid double counting polymers with initiators on both ends
]

globals [
  current-chain-id ;; chain-id given to next created radical-initiator
  num-avg-molecular-weight ;; the number average molecular weight uses the number fraction of polymers
  wgt-avg-molecular-weight ;; the weight average molecular weight uses the weight fraction of polymers
]

to setup
  clear-all
  setup-default-shapes
  setup-agents
  reset-ticks
end


to setup-default-shapes
  ;; mers are circles, initiators are squares
  set-default-shape unsaturated-mers "circle"
  set-default-shape radical-mers "circle"
  set-default-shape saturated-mers "circle"

  set-default-shape radical-initiators "square"
  set-default-shape initiators "square"
end

to setup-agents
  ;; create agents on unoccupied patches
  create-turtles num-monomers [
    change-to-unsaturated-mer
    move-to one-of patches with [not any? turtles-here]
  ]

  set current-chain-id 1 ;; start chain-ids at 1
  create-turtles num-radical-initiators [
    change-to-radical-initiator
    move-to one-of patches with [not any? turtles-here]
    ;; the chain-ids are initially given to radical initiators because each propagating chain starts with a radical initiator
    set chain-id current-chain-id
    set current-chain-id current-chain-id + 1
  ]
end

to change-to-unsaturated-mer
  set breed unsaturated-mers
  set color sky + 2
end

to change-to-radical-mer
  set breed radical-mers
  set color magenta
end

to change-to-saturated-mer
  set breed saturated-mers
  set color sky - 1
end

to change-to-radical-initiator
  set breed radical-initiators
  set color orange + 2
end

to change-to-initiator
  set breed initiators
  set color orange - 2
  ;; molecular weight is tracked using initiators because each polymer will have at least one initiator
  set track-mw? true
end



to go
  ask radicals [interact]
  ask turtles [move]
  calculate-molecular-weights
  tick
end

to-report radicals
  report (turtle-set radical-initiators radical-mers)
end


to interact
  ;; neighbors4 here because when a diagonal link is created, if there is a link between the two adjacent turtles, the links can get crossed
  let bondable-neighbors (turtles-on neighbors4) with [bondable?]
  if any? bondable-neighbors [
    ;; determines the bond, and breed changes for both the initiating agent and the neighbor agent
    ;; changes the neighbor agent's breed first to make the ifelse logic clear
    ask one-of bondable-neighbors [bond-and-change-breed]
    change-breed-myself
  ]
end

to bond-and-change-breed
  ;; called by the neighbor of the agent initiating bonding who is "myself" in this context
  (ifelse
    monomer? [ ;; radical agent interacting with a monomer
      create-link-with myself
      set chain-id [chain-id] of myself
      change-to-radical-mer
    ]
    breed = radical-initiators [ ;; radical agent interacting with a radical-initiator
      create-link-with myself
      ;; when agents with different chain-ids combine, the turtles with the chain-id of the neighbor agent change their chain-id
      ;;    to the initiating agent's, to have the chain-id uniform throughout the polymer
      set chain-id [chain-id] of myself
      change-to-initiator
      set track-mw? false  ;; since this initiator is the 2nd of the polymer, it does not track molecular weight to avoid double counting
    ]
    breed = radical-mers [ ;; radical agent interacting with a radical-mer. In this case the reaction depends on the type of radical.
      (ifelse
        [breed] of myself = radical-initiators [combine-chains]  ;; radical-initiator interacting with a radical-mer -> combine chains
        [breed] of myself = radical-mers [  ;; two radical-mers interacting -> either disproportionate or combine chains
          ;; radical-mer interacting with another radical-mer -> combination or disproportionation termination occurs depending on disproportionation-prob
          ifelse random-float 1 <= disproportionation-prob [
            ;; disproportionation termination is the only interaction where a bond is not formed
            ;; the initiating mer takes a hydrogen to become a saturated mer (which will happen change-breed-myself)
            ;; the neighbor mer gives up a hydrogen to become an unsaturated mer and reaches stability through a double bond
            change-to-unsaturated-mer
          ] [
            ;; combination termination, the propagating chains combine to form one polymer
            combine-chains
          ]
        ]
      )
    ]
  )
end

to combine-chains
  ;; radical-mer procedure to combine chain with another chain that bonds with it
  create-link-with myself
  let id1 [chain-id] of myself
  let id2 chain-id
  ;; since the initiator at the end of the radical mer is the 2nd of the polymer, it does not track molecular weight to avoid double counting
  ask initiators with [chain-id = id2] [set track-mw? false]
  ask turtles with [chain-id = id2] [set chain-id id1]
  change-to-saturated-mer
end

to change-breed-myself
  ;; called by the agent initiating bonding
  (ifelse
    ;; the initiating agent is always a radical that turns into a non radical
    breed = radical-initiators [change-to-initiator]
    breed = radical-mers [change-to-saturated-mer]
  )
end

to-report bondable?
  report (
    breed = radical-mers  or
    breed = radical-initiators or
    monomer?
  )
end

to-report monomer?
  report breed = unsaturated-mers and count link-neighbors = 0
end

to move
  ;; turtle procedure
  ;; choose a heading, and before moving the mer
  face one-of neighbors
  ;; checks if the move is self-excluding or breaks the chain
  if self-excluding? and not breaking-chain? [ move-to patch-ahead 1 ]
end

to-report breaking-chain?
  ;; if my link-neighbors are not all on the neighbors of the patch-ahead, it would break the chain
  let neighbors-of-patch-ahead [neighbors] of patch-ahead 1
  report any? link-neighbors with [not member? patch-here neighbors-of-patch-ahead]
end

to-report self-excluding?
  ;; two turtles cannot occupy the same patch
  report [not any? turtles-here] of patch-ahead 1
end


to calculate-molecular-weights
  ;; for plot and monitors
  ;; only calls initiators that are tracking molecular weight
  ask initiators with [track-mw?] [
    let my-id chain-id
    set molecular-weight count turtles with [chain-id = my-id]
  ]

  let total-molecular-weight sum [molecular-weight] of initiators with [track-mw?]
  let num-polymers count initiators with [track-mw?]

  ;; to avoid division by 0 when num-polymers = 0
  if num-polymers > 0 [
    set num-avg-molecular-weight total-molecular-weight / num-polymers
    ;; sum of molecular-weights multiplied by weight fraction (mw / tmw)
    set wgt-avg-molecular-weight sum [molecular-weight * molecular-weight / total-molecular-weight] of initiators with [track-mw?]
  ]
end


to add-monomers
  ;; for additional unsaturated-mers
  create-turtles num-add [
    change-to-unsaturated-mer
    move-to one-of patches with [not any? turtles-here]
  ]
end

to add-radical-initiators
  ;; for additional radical-initiators
  create-turtles num-add [
    change-to-radical-initiator
    move-to one-of patches with [not any? turtles-here]
    set chain-id current-chain-id
    set current-chain-id current-chain-id + 1
  ]
end


; Copyright 2023 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
764
565
-1
-1
6.0
1
5
1
1
1
0
1
1
1
-45
45
-45
45
1
1
1
ticks
30.0

BUTTON
5
107
68
140
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
75
107
138
140
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

BUTTON
143
107
206
140
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
22
22
194
55
num-monomers
num-monomers
1
1000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
21
64
193
97
num-radical-initiators
num-radical-initiators
1
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
20
166
192
199
num-add
num-add
1
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
47
212
159
245
NIL
add-monomers
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
32
253
172
286
NIL
add-radical-initiators
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
19
313
193
346
disproportionation-prob
disproportionation-prob
0
100
0.0
1
1
NIL
HORIZONTAL

PLOT
784
24
1161
263
Molecular Weight Distribution
Molecular Weight
Number of Molecules
0.0
0.0
0.0
0.0
false
true
"set-plot-x-range 0 (round (num-monomers * 0.1))\nset-plot-y-range 0 (round (num-radical-initiators * 0.7))" "if (any? initiators) and (ticks mod 100) = 0 [\nset-plot-x-range 0 ([molecular-weight] of max-one-of initiators [molecular-weight])\n]"
PENS
"histogram" 1.0 1 -16777216 true "set-histogram-num-bars 8" "histogram [molecular-weight] of initiators with [track-mw?]\nif (any? initiators) and (ticks mod 100) = 0 [\nset-histogram-num-bars 8\n]"
"number avg mw" 1.0 0 -2674135 true "" "plot-pen-reset\nplotxy num-avg-molecular-weight plot-y-min\nplotxy num-avg-molecular-weight plot-y-max"
"weight avg mw" 1.0 0 -13345367 true "" "plot-pen-reset\nplotxy wgt-avg-molecular-weight plot-y-min\nplotxy wgt-avg-molecular-weight plot-y-max"

TEXTBOX
20
390
170
416
Shape & Color Key\n\n
12
0.0
1

TEXTBOX
45
415
195
433
monomers: sky blue
11
97.0
1

TEXTBOX
46
435
196
453
radical mers: magenta
11
125.0
1

TEXTBOX
45
455
195
473
saturated mers: teal
11
94.0
1

TEXTBOX
45
475
220
501
radical initiators: light orange
11
27.0
1

TEXTBOX
45
495
195
513
initiators: dark orange
11
23.0
1

MONITOR
785
277
901
322
Number Avg MW
num-avg-molecular-weight
1
1
11

MONITOR
911
277
1025
322
Weight Avg MW
wgt-avg-molecular-weight
1
1
11

MONITOR
1035
277
1161
322
Polydispersity Index
wgt-avg-molecular-weight / num-avg-molecular-weight
2
1
11

PLOT
786
337
1025
527
Monomer Concentration
ticks
# / volume
0.0
10.0
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count unsaturated-mers with [monomer?]) / (world-width * world-height)"

TEXTBOX
20
465
45
488
■
25
27.0
1

TEXTBOX
20
485
45
516
■
25
23.0
1

TEXTBOX
20
445
45
476
●
25
94.0
1

TEXTBOX
20
425
45
456
●
25
125.0
1

TEXTBOX
20
405
45
436
●
25
97.0
1

@#$#@#$#@
## WHAT IS IT?

This is a model of free-radical polymerization which is a method of polymer formation. A polymer is a long molecule made up of many repeating units known as "mers". A monomer is a single one of these unbonded units by itself. When multiple monomers bond together, they create a polymer (many mers).

Radical polymerization is initiated by free radicals, which are molecules with an unpaired valence electron, making them very reactive. These free radicals themselves have to be created by some sort of reaction that cleaves initiator molecules into two parts, at least one of which is a free radical. The free radical then bonds with a monomer and its unpaired valence electron is transferred to the mer which is then able to repeat this process with another monomer. This process continues until either a termination reaction occurs or there are no other mers present.

## HOW IT WORKS

The radical polymerization is modeled involving only local interactions on a lattice. Any global interactions are used only for monitoring purposes.

Radical agents (radical mers or radical initators) are the only agents that initiate interaction with other agents. During the `go` procedure, radicals are asked to interact, then all turtles are asked to move.

During `interact`, the radical agent randomly chooses, if available, one monomer, radical-mer, or radical-initiator from its adjacent neighbors. It then asks this agent to bond and change its breed to reflect its new status. Then, the initiating agent changes its own breed to longer be radical.

When the neighbor is asked to bond and change its breed, there are number of possibilities based on its breed:

- if it is a monomer, it bonds with the initiating agent and changes to a radical-mer.
- if it is a radical initiator, it bonds with the initiating agent and changes to an initiator
- if is a radical-mer, there are a three different possibilities:
    - if the initiating agent is a radical-initiator, it bonds with the initiating agent and changes to a saturated-mer
    - if the initiating agent is a radical-mer, the outcome depends on DISPROPORTIONATION-PROB:
        - if disproportionation occurs, the neighbor does not bond (only case where the neighbor does not bond) and changes to a unsaturated-mer (only case where an unsaturated-mer is not a monomer).
        - if disproportionation does not occur, then combination occurs. The neighbor bonds wtih the initiating agent and changes to a saturated-mer.

When the initiating agent changes its own breed, if it is a radical-initiator, it changes to an initiator, and if it is a radical-mer, it changes to a saturated-mer.

During move, each turtle chooses one of its neighboring eight patches, and if that patch is unoccupied and moving there would not break its bonds, it moves there.

## HOW TO USE IT

Before clicking the SETUP button, you first need to determine the number of initial monomers you want created using the NUM-MONOMERS slider and the number of radical initiators using the NUM-RADICAL-INITIATORS slider.

To run the model, first press the SETUP button, then press the GO button. To advance only one tick, you can press the GO ONCE button.

Once the model is running, you can add additional agents using the NUM-ADD slider to determine how many agents to add, and the ADD-MONOMERS button to add monomers, or the ADD-RADICAL-INITIATORS button to add radical initiators.

Additionally, regardless of whether the model is running or not, you can change the probability of disproportionation termination occurring (the alternative being combination termination) when two radical-mers interact using the DISPROPORTIONATION-PROB slider.

## THINGS TO NOTICE

Many different patterns can be noticed in different aspects of the model based on different ratios between monomers and radical initiators. Such as:

* the final number of monomers in each polymer after termination

* the distribution of the molecular weight of polymers
(seen through the polydispersity index & the distribution on the molecular weight plot)

* how fast the monomers are being added to polymer
(seen through the shape of the curve in the number of monomers plot)

It is also important to note that along with the ratio between monomers and radical initiators, the concentration of agents within the world must also be considered. Even with the same ratio of each agent, different patterns can be observed based on how packed the agents are in the world.

Also notice what types of agents are at the two ends of polymers and how this can change when DISPROPORTIONATION-PROB is high.

## THINGS TO TRY

Slow down the model to see each interaction occurring

Try adding a steady flow of either monomers or radical initiators, or both using the add buttons

Try increasing the dimensions of the world. Does the behavior change at all?

## EXTENDING THE MODEL

Interface additions:

* Add sliders that control the probability for each interaction so that the interactions do not occur every time

* Alternatively, a temperature slider could be added that correlates to the probability of interaction (higher temperature, more likely for agents to interact)

* Instead of the agents moving by themselves, change the code so that the user drags agents to make them interact (polymers are tied together so they move together)

* Add a switch that lets the user decide whether to add the initial monomers all at once when the model starts, or to add them in continuously at a predetermined rate

Changes to the move code:

* Have each polymer as a whole randomly move or rotate, modeling a flow in the model

* Alter the breaking-chain? code to be looser, so that a link-neighbor can be further away than 1 patch without breaking the chain

Changes to the main ideas of the model:

* Change the model to be a step growth model instead, so the mers are all active and bond with neighbors on two sides

* Change the initiation reaction so that the propagation starts on the side where the radical initiator comes in, resulting in the chain to be able to propagate on both sides

* Make a hexagonal grid instead of the current square grid to be more accurate to packing (see the MaterialSim Grain Growth model in the Models Library for a way to make a hexagonal lattice)

## NETLOGO FEATURES

Radical mers and radical initiators are the only agents that initiate in the interact code, so those two breeds are called. In order to avoid checking the breeds every time the interact code is called, a turtle-set made of radical-mers and radical-initiators was uitilized and called instead.

Auto scaling does not affect a histogram's horizontal range, so when using a histogram for the molecular weight distribution plot, an update command was implemented that adjusts the x-range periodically. This, however,  was in conflict with the "set-histogram-num-bars" pen setup command that determined the number of bars, because this would not automatically update when the x-range changed. To account for this, a pen update command was added that ran "set-histogram-num-bars" in the same period as when the x-range updated.

The Shape and Color Key uses unicode characters for circles and squares to display those shapes as text.

## RELATED MODELS

Polymer Dynamics
Radical Polymerization

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Huang, J., Kelter, J. and Wilensky, U. (2023).  NetLogo Radical Polymerization with Chains model.  http://ccl.northwestern.edu/netlogo/models/RadicalPolymerizationwithChains.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2023 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2023 Cite: Huang, J., Kelter, J. -->
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
