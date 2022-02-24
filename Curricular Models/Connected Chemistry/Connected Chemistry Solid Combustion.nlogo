globals
[
  tick-advance-amount                        ;; clock variables
  max-tick-advance-amount                    ;; the largest a tick length is allowed to be
  box-edge                                   ;; distance of box edge from axes
  avg-energy                                 ;; keeps track of average kinetic energy of gas molecules
  fast medium slow                           ;; current counts
  percent-slow percent-medium percent-fast   ;; percentage of current counts
  max-energy                                 ;; maximum kinetic energy of a particle
  particle-size
  activation-energy                          ;; total kinetic energy of gas molecule involved in collision required for chemical reaction to occur
  total-oxygen-molecules                     ;; keeps track of total molecules
  total-nitrogen-molecules                   ;; keeps track of total molecules
  total-carbon-dioxide-molecules             ;; keeps track of total molecules
  total-carbon-charcoal-atoms                ;; keeps track of total molecules
]

breed [ gas-molecules gas-molecule ]
breed [ carbons carbon ]

gas-molecules-own [energy speed mass last-collision]
carbons-own       [energy]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETUP PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set particle-size 1.5
  set activation-energy 1000
  set max-tick-advance-amount 0.01
  set max-energy 10000
  set box-edge (round (max-pxcor ))
  make-box
  make-charcoal
  make-gas-molecules
  update-variables
  reset-ticks
end



to make-box
  ask patches with [ ((abs pxcor = box-edge) and (abs pycor <= box-edge)) or
                     ((abs pycor = box-edge) and (abs pxcor <= box-edge)) ]
    [ set pcolor gray ]
end


to make-charcoal
  set-default-shape carbons "carbon"
  if charcoal-geometry = "6 x 6" [
    ask patches with [ pxcor <= 3 and abs pycor <= 3 and pxcor >= -2 and pycor >= -2] [
    sprout-carbons 1 [set color yellow   set size particle-size]]
  ]
  if charcoal-geometry = "4 x 9" [
    ask patches with [ pxcor <= 2 and abs pycor <= 4 and pxcor >= -1 and pycor >= -4] [
    sprout-carbons 1 [set color yellow   set size particle-size]]
  ]
  if charcoal-geometry = "3 x 12" [
    ask patches with [ pxcor <= 1 and abs pycor <= 6 and pxcor >= -1 and pycor >= -5] [
    sprout-carbons 1 [set color yellow   set size particle-size]]
  ]
  if charcoal-geometry = "2 x 18" [
    ask patches with [ pxcor <= 1 and abs pycor <= 9 and pxcor >= 0 and pycor >= -8] [
    sprout-carbons 1 [set color yellow   set size particle-size]]
  ]
end


to make-gas-molecules
  create-gas-molecules initial-O2-molecules
  [
    setup-oxygen-molecules
    random-position
  ]
  create-gas-molecules initial-N2-molecules
  [
    setup-nitrogen-molecules
    random-position
  ]
end


to setup-oxygen-molecules  ;; gas-molecules procedure
  set shape "oxygen"
  set size particle-size
  set energy initial-gas-temp
  set mass (8 + 8)  ;; atomic masses of oxygen atoms
  set speed speed-from-energy
  set last-collision nobody
end


to setup-nitrogen-molecules  ;; gas-molecules procedure
  set shape "nitrogen"
  set size particle-size
  set energy initial-gas-temp
  set mass (7 + 7)  ;; atomic masses of oxygen atoms
  set speed speed-from-energy
  set last-collision nobody
end


;; Place gas-molecules at random, but they must not be placed on top of carbon atoms.
;; This procedure takes into account the fact that carbon molecules could have two possible arrangements,
;; i.e. high-surface area to low-surface area.
to random-position ;; gas-molecules procedure
  let open-patches nobody
  let open-patch nobody
  set open-patches patches with [not any? turtles-here and pxcor != max-pxcor and pxcor != min-pxcor and pycor != min-pycor and pycor != max-pycor]
  set open-patch one-of open-patches
  move-to open-patch
  set heading random-float 360
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; RUNTIME PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ask gas-molecules [ bounce move check-for-collision]
  ask gas-molecules with [any? carbons-here] [remove-from-matrix]
  visualize-vibrational-energy
  ask gas-molecules with [shape = "oxygen"] [ check-for-reaction ]
  calculate-tick-advance-amount
  update-variables
  tick-advance tick-advance-amount
  update-plots
  display
end


to update-variables
  set avg-energy mean [energy ] of gas-molecules
  set total-oxygen-molecules count gas-molecules with [shape = "oxygen"]
  set total-nitrogen-molecules count gas-molecules with [shape = "nitrogen"]
  set total-carbon-dioxide-molecules count gas-molecules with [shape = "co2"]
  set total-carbon-charcoal-atoms count carbons
end


to visualize-vibrational-energy
  ask carbons [ ;; visualize energy as a vibration in charcoal
      setxy pxcor +  (5 * (1 - random-float 2)) / 100  pycor + (5 * (1 - random-float 2)) / 100
 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CHEMICAL REACTION PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to check-for-reaction
   let hit-carbon one-of carbons in-cone 1 180
   let speed-loss 0
   if hit-carbon != nobody [
     let hit-angle towards hit-carbon
     ifelse (hit-angle < 135 and hit-angle > 45) or (hit-angle < 315 and hit-angle > 225)
       [set heading (- heading)]
       [set heading (180 - heading)]

   ;; oxygen has enough energy itself or oxygen has enough energy with carbon's energy to initiate the reaction

   if (shape != "co2") and ((energy > activation-energy) or [shape] of hit-carbon = "carbon-activated") [
       ask hit-carbon [die]
       set shape "co2"
       set mass (6 + 8 + 8)  ;; atomic masses of carbon, oxygen, and oxygen
       set energy energy + energy-released
       set speed sqrt (energy * 2 / mass)
     ]

  ]

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GAS MOLECULES MOVEMENT;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to bounce  ;; gas-molecules procedure
  ;; get the coordinates of the patch we'll be on if we go forward 1
  let new-patch patch-ahead 1
  let new-px [pxcor] of new-patch
  let new-py [pycor] of new-patch
  ;; if we're not about to hit a wall, we don't need to do any further checks
  if not shade-of? gray [pcolor] of new-patch
    [ stop ]
  ;; if hitting left or right wall, reflect heading around x axis
  if (abs new-px = box-edge)
    [ set heading (- heading) ]
  ;; if hitting top or bottom wall, reflect heading around y axis
  if (abs new-py = box-edge)
    [ set heading (180 - heading)]
end


to move  ;; gas-molecules procedure
  if patch-ahead (speed * tick-advance-amount) != patch-here
    [ set last-collision nobody ]
  jump (speed * tick-advance-amount)
end



to remove-from-matrix
  let available-patches patches with [not any? carbons-here]
  let closest-patch nobody
  if (any? available-patches) [
    set closest-patch min-one-of available-patches [distance myself]
    set heading towards closest-patch
    move-to closest-patch
  ]
end



to speed-up-one-molecule
  clear-drawing
  ask gas-molecules [penup]
  ask one-of gas-molecules  [
    set energy (max-energy / 2)
    set speed speed-from-energy
    pendown
  ]
  calculate-tick-advance-amount
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GAS MOLECULES COLLISIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;from GasLab

to calculate-tick-advance-amount
  ;; tick-advance-amount is calculated in such way that even the fastest
  ;; gas-molecules will jump at most 1 patch length in a clock tick. As
  ;; gas-molecules jump (speed * tick-advance-amount) at every clock tick, making
  ;; tick length the inverse of the speed of the fastest gas-molecules
  ;; (1/max speed) assures that. Having each gas-molecules advance at most
   ; one patch-length is necessary for it not to "jump over" a wall
   ; or another gas-molecules.
  ifelse any? gas-molecules with [speed > 0]
    [ set tick-advance-amount min list (1 / (ceiling max [speed] of gas-molecules)) max-tick-advance-amount ]
    [ set tick-advance-amount max-tick-advance-amount ]
end


to check-for-collision  ;; gas-molecules procedure

  if count other gas-molecules-here in-radius 1 = 1
  [
    ;; the following conditions are imposed on collision candidates:
    ;;   1. they must have a lower who number than my own, because collision
    ;;      code is asymmetrical: it must always happen from the point of view
    ;;      of just one gas-molecules.
    ;;   2. they must not be the same gas-molecules that we last collided with on
    ;;      this patch, so that we have a chance to leave the patch after we've
    ;;      collided with someone.
    let candidate one-of other gas-molecules-here with
      [self < myself and myself != last-collision]
    ;; we also only collide if one of us has non-zero speed. It's useless
    ;; (and incorrect, actually) for two gas-molecules with zero speed to collide.
    if (candidate != nobody) and (speed > 0 or [speed] of candidate > 0)
    [
      collide-with candidate
      set last-collision candidate
      let this-candidate self
      ask candidate [set last-collision this-candidate]
    ]
  ]
end

;; implements a collision with another gas-molecule.
;;
;; The two gas-molecules colliding are self and other-gas-molecules, and while the
;; collision is performed from the point of view of self, both gas-molecules are
;; modified to reflect its effects. This is somewhat complicated, so I'll
;; give a general outline here:
;;   1. Do initial setup, and determine the heading between gas-molecules centers
;;      (call it theta).
;;   2. Convert the representation of the velocity of each gas-molecule from
;;      speed/heading to a theta-based vector whose first component is the
;;      gas-molecule's speed along theta, and whose second component is the speed
;;      perpendicular to theta.
;;   3. Modify the velocity vectors to reflect the effects of the collision.
;;      This involves:
;;        a. computing the velocity of the center of mass of the whole system
;;           along direction theta
;;        b. updating the along-theta components of the two velocity vectors.
;;   4. Convert from the theta-based vector representation of velocity back to
;;      the usual speed/heading representation for each gas-molecules.
;;   5. Perform final cleanup and update derived quantities.
to collide-with [ other-gas-molecules ] ;; gas-molecules procedure
  ;;; PHASE 1: initial setup

  ;; for convenience, grab some quantities from other-gas-molecules
  let mass2 [mass] of other-gas-molecules
  let speed2 [speed] of other-gas-molecules
  let heading2 [heading] of other-gas-molecules

  ;; since gas-molecules are modeled as zero-size points, theta isn't meaningfully
  ;; defined. we can assign it randomly without affecting the model's outcome.
  let theta (random-float 360)



  ;;; PHASE 2: convert velocities to theta-based vector representation

  ;; now convert my velocity from speed/heading representation to components
  ;; along theta and perpendicular to theta
  let v1t (speed * cos (theta - heading))
  let v1l (speed * sin (theta - heading))

  ;; do the same for other-gas-molecules
  let v2t (speed2 * cos (theta - heading2))
  let v2l (speed2 * sin (theta - heading2))



  ;;; PHASE 3: manipulate vectors to implement collision

  ;; compute the velocity of the system's center of mass along theta
  let vcm (((mass * v1t) + (mass2 * v2t)) / (mass + mass2) )

  ;; now compute the new velocity for each gas-molecules along direction theta.
  ;; velocity perpendicular to theta is unaffected by a collision along theta,
  ;; so the next two lines actually implement the collision itself, in the
  ;; sense that the effects of the collision are exactly the following changes
  ;; in gas-molecules velocity.
  set v1t (2 * vcm - v1t)
  set v2t (2 * vcm - v2t)



  ;;; PHASE 4: convert back to normal speed/heading

  ;; now convert my velocity vector into my new speed and heading
  set speed sqrt ((v1t ^ 2) + (v1l ^ 2))
  set energy (0.5 * mass * speed ^ 2)
  ;; if the magnitude of the velocity vector is 0, atan is undefined. but
  ;; speed will be 0, so heading is irrelevant anyway. therefore, in that
  ;; case we'll just leave it unmodified.
  if v1l != 0 or v1t != 0
    [ set heading (theta - (atan v1l v1t)) ]

  ;; and do the same for other-gas-molecules
  ask other-gas-molecules [
    set speed sqrt ((v2t ^ 2) + (v2l ^ 2))
    set energy (0.5 * mass * (speed ^ 2))
    if v2l != 0 or v2t != 0
      [ set heading (theta - (atan v2l v2t)) ]
  ]
  penup
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;REPORTERS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report speed-from-energy
  report sqrt (2 * energy / mass)
end

to-report energy-from-speed
  report (mass * speed * speed / 2)
end


to-report last-n [n the-list]
  ifelse n >= length the-list
    [ report the-list ]
    [ report last-n n butfirst the-list ]
end


; Copyright 2007 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
305
10
663
369
-1
-1
14.0
1
10
1
1
1
0
0
0
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
90
10
180
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

BUTTON
5
10
91
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
5
80
155
113
initial-O2-molecules
initial-O2-molecules
1
100
22.0
1
1
NIL
HORIZONTAL

PLOT
4
149
304
269
Number of Molecules
time
count
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Oxygen" 1.0 0 -13345367 true "" "plotxy ticks total-oxygen-molecules"
"Carbon Dioxide" 1.0 0 -4539718 true "" "plotxy ticks total-carbon-dioxide-molecules"
"Charcoal" 1.0 0 -955883 true "" "plotxy ticks total-carbon-charcoal-atoms"
"Nitrogen" 1.0 0 -6565750 true "" "plotxy ticks total-nitrogen-molecules"

SLIDER
5
115
155
148
initial-gas-temp
initial-gas-temp
10
500
300.0
10
1
NIL
HORIZONTAL

SLIDER
155
115
305
148
energy-released
energy-released
0
5000
1000.0
100
1
NIL
HORIZONTAL

CHOOSER
185
10
305
55
charcoal-geometry
charcoal-geometry
"6 x 6" "4 x 9" "3 x 12" "2 x 18"
0

PLOT
5
270
305
390
Temperature of gas
time
temp
0.0
10.0
0.0
200.0
true
false
"" ""
PENS
"Gas" 1.0 0 -13345367 true "" "plotxy ticks (avg-energy)"

SLIDER
155
80
305
113
initial-N2-molecules
initial-N2-molecules
0
100
76.0
1
1
NIL
HORIZONTAL

BUTTON
5
45
180
78
speed up & trace a molecule
speed-up-one-molecule
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

@#$#@#$#@
## WHAT IS IT?

This model shows the chemical kinetics of the combustion reaction for burning charcoal.

The chemical reaction that charcoal undergoes in combustion releases energy (exothermic reaction) when the carbon (C) atoms that make up the charcoal react with the oxygen found in air (O2).  This reaction produces carbon dioxide CO2. This chemical reaction is represented as follows:

 C + O2 -> CO2

C and O are called the reactants and CO2 is the product of the reaction.

In this model, charcoal is modeled as a block o pure solid of 100% carbon.  The surrounding gas is modeled as oxygen and nitrogen.  Nitrogen is treated as an inert gas in this model that neither reacts with the oxygen nor the carbon.  In reality, at high temperatures, molecular nitrogen and oxygen can combine to form nitric oxide.  And at high temperatures and pressures two N2 molecules can react to become N4, which is called nitrogen diamond.  Neither of these reactions are represented in this model.

## HOW IT WORKS

For a reaction to occur, oxygen (O2) and carbon (C) must have enough energy to break the atomic bond in oxygen and allow the atoms to rearrange to make CO2.  This bond breaking energy threshold is called the activation energy.

When both the oxygen molecule and the carbon atom have a net amount of molecular kinetic energy (thermal energy) greater than or equal to the activation energy, the reaction occurs.  This tends to occur more often at higher temperatures, where molecules have higher amounts of kinetic energy.   At higher temperatures it is more likely that any set of reactants will have enough energy to break the bonds of oxygen and causing a rearrangement of the atoms from the reactants.  This bond breakage and rearrangement converts chemical potential energy of the reactants into molecular kinetic energy of the products.  This is due to the fact that the the atomic bonds of CO2 store less potential energy than those of O2.

This excess energy is called the BOND-ENERGY.  When the bond energy is increased the products heat up due to an increased transfer of bond-energy to kinetic energy in the chemical reaction.

## HOW TO USE IT

Press SETUP and then GO/STOP to run the model.

SPEED UP & TRACE A MOLECULE gives a speed boost to a single gas molecule and traces its path until the first collision it encounters.  This additional kinetic energy added to this molecule may be enough to cause a chain reaction that leads to the burning of the charcoal.  Pressing it also increases the temperature of the gas because temperature is a measure of the average kinetic energy of the molecules.

CHARCOAL-GEOMETRY determines the shape of the cluster of carbon atoms (this is referred to as the solid matrix in the procedures).

INITIAL-O2-MOLECULES determines the number of initial oxygen (O2) molecules the simulation starts with.

INITIAL-N2-MOLECULES determines the number of initial oxygen (N2) molecules the simulation starts with.  (The composition of the atmosphere has approximately 78% nitrogen and 21% oxygen).

INITIAL-GAS-TEMP sets the initial temperature of the gases.  Charcoal will not burn if the total kinetic energy of the carbon atom and oxygen molecule that are set to react is lower than the activation energy

ENERGY-RELEASED is the amount of potential chemical energy released in the burning reaction.  This energy is converted and transferred into the kinetic energy of the products.

## THINGS TO NOTICE

Why does the average speed of the molecules speed up after a few chemical reactions, continue speeding up more quickly, then start to speed up less quickly as the time progresses?

How many molecules of oxygen are needed to completely react with the 6 x 6 charcoal solid?

Why do different geometries of carbon atoms in the charcoal solid react more or less quickly, even if the number of carbon atoms is the same?

## THINGS TO TRY

Try Different ENERGY-RELEASED levels INITIAL-GAS-TEMP values to make the chemical reaction occur at different rates (or not at all).

Compare the rate of the reaction with different charcoal solid shapes.

Try adjusting the amount of oxygen to make the carbon burn faster.

Try adjusting the amount of oxygen and nitrogen to give highest final gas temperature.

Try adjusting the amount of oxygen to use up all the oxygen and charcoal in the reaction.

## EXTENDING THE MODEL

Energy is transfer to the carbon atoms in collision with gas molecules.  This energy is transferred in one discrete chunk (activation-energy).  Model the energy transfer in the solid so that different values of energy can be transferred to and from the solid in collisions.  Then add diffusion of vibrational energy through the solid (heat transfer)

Change the gas to be a mixture of molecules like in the atmosphere.

Add a pathway for incomplete combustion:  2C + 02  --> 2CO
    and the conditions it occurs under.

Add a pathway for generating nitrous oxide:  2C + 02  --> 2NO
    and the conditions it occurs under.

## NETLOGO FEATURES

Uses GasLab particle collision code.

## CREDITS AND REFERENCES

This model is part of the Connected Chemistry curriculum.  See http://ccl.northwestern.edu/curriculum/chemistry/.

We would like to thank Sharona Levy and Michael Novak for their substantial contributions to this model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2007).  NetLogo Connected Chemistry Solid Combustion model.  http://ccl.northwestern.edu/netlogo/models/ConnectedChemistrySolidCombustion.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

To cite the Connected Chemistry curriculum as a whole, please use:

* Wilensky, U., Levy, S. T., & Novak, M. (2004). Connected Chemistry curriculum. http://ccl.northwestern.edu/curriculum/chemistry/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2007 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2007 ConChem Cite: Novak, M. -->
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

carbon
true
0
Circle -955883 true false 83 83 134

carbon-activated
true
0
Circle -955883 true false 83 83 134
Line -16777216 false 150 90 150 210

carbon2
true
0
Circle -955883 true false 30 45 210

circle
false
0
Circle -7500403 true true 30 30 240

circle 2
false
0
Circle -7500403 true true 16 16 270
Circle -16777216 true false 46 46 210

clock
true
0
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 150 31 128 75 143 75 143 150 158 150 158 75 173 75
Circle -16777216 true false 135 135 30

co2
true
0
Circle -13345367 true false 90 180 120
Circle -1 false false 90 180 120
Circle -955883 true false 90 90 120
Circle -13345367 true false 90 0 120
Circle -1 false false 90 0 120

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

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

nitrogen
true
0
Circle -10899396 true false 90 45 120
Circle -1 false false 90 45 120
Circle -10899396 true false 90 135 120
Circle -1 false false 90 135 120

oxygen
true
0
Circle -13345367 true false 90 45 120
Circle -1 false false 90 45 120
Circle -13345367 true false 90 135 120
Circle -1 false false 90 135 120

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
