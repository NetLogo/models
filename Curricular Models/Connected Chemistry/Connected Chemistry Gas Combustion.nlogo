globals
[
  tick-advance-amount                ;; clock variables
  max-tick-advance-amount            ;; the largest a tick length is allowed to be
  box-edge                   ;; distance of box edge from axes
  avg-speed                  ;; current average speed of gas molecules
  avg-energy                 ;; current average energy of gas molecules
  length-horizontal-surface  ;; the size of the wall surfaces that run horizontally - the top and bottom of the box
  length-vertical-surface    ;; the size of the wall surfaces that run vertically - the left and right of the box
  pressure-history           ;; average pressure over last six time steps
  pressure                   ;; pressure at this time step
  temperature                ;; the average kinetic energy of all the molecules
  box-intact?                ;; keeps track of whether the box will burst from too much pressure
  molecule-size              ;; size of the molecules
  margin-outside-box         ;; number of patches width between the edge of the box and the edge of the world
  number-oxygen-molecules
  number-hydrogen-molecules
  number-water-molecules
]

breed [ gas-molecules gas-molecule ]
breed [ flashes flash ]              ;; squares that are created temporarily to show a location of a wall hit
breed [ broken-walls broken-wall ]   ;; pieces of broken walls that fly apart when pressure limit of container is reached


flashes-own [birthday]

gas-molecules-own
[
  speed mass energy          ;; gas-molecules info
  last-collision             ;; what was the molecule that this molecule collided with?
  molecule-type              ;; what type of molecule is this (hydrogen H2, water H20, oxygen O2)
  momentum-instant           ;; used to calculate the momentum imparted to the wall at this time step
  momentum-difference        ;; used to calculate pressure from wall hits over time
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; SETUP PROCEDURES ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set max-tick-advance-amount 0.01
  set margin-outside-box 4
  set box-edge (max-pxcor - margin-outside-box)
  set-default-shape flashes "square"
  set molecule-size 1.4
  set pressure-history [0 0 0 0 0 0]   ;; plotted pressure will be averaged over the past 6 entries
  set box-intact? true
  set length-horizontal-surface  ( 2 * (box-edge - 1) + 1)
  set length-vertical-surface  ( 2 * (box-edge - 1) + 1)

  make-box
  make-gas-molecules
  update-variables
  reset-ticks
end


to make-box
  ask patches with
  [ ((abs pxcor = (max-pxcor - margin-outside-box)) and (abs pycor <= (max-pycor - margin-outside-box))) or
    ((abs pycor = (max-pxcor - margin-outside-box)) and (abs pxcor <= (max-pycor - margin-outside-box))) ]
    [ set pcolor gray ]
end


to make-gas-molecules
  create-gas-molecules initial-oxygen-molecules
  [
    setup-initial-oxygen-molecules
    random-position
  ]

  create-gas-molecules initial-hydrogen-molecules
  [
    setup-initial-hydrogen-molecules
    random-position
  ]
end


to setup-initial-hydrogen-molecules  ;; gas-molecules procedure
  set size molecule-size
  set last-collision nobody
  set shape "hydrogen"
  set molecule-type "hydrogen"
  set mass 2    ;; approximate atomic weight of H2
  set momentum-difference 0
  set momentum-instant 0
end


to setup-initial-oxygen-molecules  ;; gas-molecules procedure
  set size molecule-size
  set last-collision nobody
  set shape "oxygen"
  set molecule-type "oxygen"
  set mass 16   ;;  approximate atomic weight of 02
  set momentum-difference 0
  set momentum-instant 0
end


;; Place gas-molecules at random, but molecules must not be placed on top of other molecules at first.
to random-position ;; gas-molecules procedure
  let open-patches nobody
  let open-patch nobody
  set open-patches patches with [abs pxcor < (max-pxcor - margin-outside-box) and abs pycor < (max-pycor - margin-outside-box)]
  set open-patch one-of open-patches
  move-to open-patch
  set heading random-float 360
  set energy initial-gas-temperature
  set speed speed-from-energy
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; RUNTIME PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  if count gas-molecules = 0 [stop]
  ifelse box-intact? [ask gas-molecules [bounce]] [shatter-box]
  ask gas-molecules [
    move
    check-for-collision
  ]
  ask gas-molecules with [molecule-type = "oxygen"] [check-for-reaction]
  update-variables
  calculate-pressure
  if pressure > (pressure-limit-container) [set box-intact? false]
  calculate-tick-advance-amount
  tick-advance tick-advance-amount
  update-flash-visualization
  update-plots
  display
end


to update-variables ;; update gas molecules variables, as well as their counts
  ifelse any? gas-molecules [
    set avg-speed  mean [speed] of gas-molecules
    set avg-energy mean [energy] of gas-molecules
    set temperature avg-energy
  ]
  [ set avg-speed 0 set avg-energy 0 set temperature 0]
  set number-oxygen-molecules   count gas-molecules with [molecule-type = "oxygen"]
  set number-hydrogen-molecules count gas-molecules with [molecule-type = "hydrogen"]
  set number-water-molecules    count gas-molecules with [molecule-type = "water"]
end


to update-flash-visualization
  ask flashes [
    if (ticks - birthday > 0.4)  [ die ]
    set color lput (255 - (255 * (ticks - birthday ) / 0.4)) [20 20 20]   ;; become progressively more transparent
  ]
end


to bounce  ;; particle procedure
  ;; get the coordinates of the patch located forward 1
  let new-patch patch-ahead 1
  let new-px [pxcor] of new-patch
  let new-py [pycor] of new-patch
  ;; if we're not about to hit a wall, no need for any further checks
  if (abs new-px != box-edge and abs new-py != box-edge)
    [stop]
  ;; if hitting left or right wall, reflect heading around x axis
  if (abs new-px = box-edge)
    [ set heading (- heading)
  ;;  if the particle is hitting a vertical wall, only the horizontal component of the velocity
  ;;  vector can change.  The change in momentum for this component is 2 * the speed of the particle,
  ;;  due to the reversing of direction of travel from the collision with the wall
      set momentum-instant  (abs (sin heading * 2 * mass * speed) / length-vertical-surface)
      set momentum-difference momentum-difference + momentum-instant
      ]
   ;; if hitting top or bottom wall, reflect heading around y axis
  if (abs new-py = box-edge)
    [ set heading (180 - heading)
  ;;  if the particle is hitting a horizontal wall, only the vertical component of the velocity
  ;;  vector can change.  The change in momentum for this component is 2 * the speed of the particle,
  ;;  due to the reversing of direction of travel from the collision with the wall
      set momentum-instant  (abs (cos heading * 2 * mass * speed) / length-horizontal-surface)
      set momentum-difference momentum-difference + momentum-instant
    ]

  if show-wall-hits? [
    ask patch new-px new-py [make-a-flash]
  ]
end


to make-a-flash
  sprout 1 [
    set breed flashes
    set color [20 20 20 255]
    set birthday ticks
  ]
end


to shatter-box
  let center-patch one-of patches with [pxcor = 0 and pycor = 0]
  ask broken-walls  [
    set heading towards center-patch
    set heading (heading + 180)
    if pxcor = max-pxcor or pycor = max-pycor or pycor = min-pycor or pxcor = min-pxcor [die]
    fd avg-speed * tick-advance-amount
  ]
  ask patches with [pcolor = gray]
  [ sprout 1 [set breed broken-walls set color gray set shape "square"] set pcolor black]
  ask flashes [die]
end


to move  ;; gas-molecules procedure
  if patch-ahead (speed * tick-advance-amount) != patch-here
    [ set last-collision nobody ]
  jump (speed * tick-advance-amount)
  ;; When particles reach the edge of the screen, it is because the box they were in has burst (failed) due
  ;; to exceeding pressure limitations.  These particles should be removed from the simulation when they escape
  ;; to the edge of the world.
  if pxcor = max-pxcor or pxcor = min-pxcor or pycor = min-pycor or pycor = max-pycor [die]
end


to calculate-pressure
  ;; by summing the momentum change for each particle,
  ;; the wall's total momentum change is calculated
  ;; the 100 is an arbitrary scalar (constant)

  set pressure 100 * sum [momentum-difference] of gas-molecules
  set pressure-history lput pressure but-first pressure-history
  ask gas-molecules
    [ set momentum-difference 0 ]  ;; once the contribution to momentum has been calculated
                                   ;; this value is reset to zero till the next wall hit
end

to calculate-tick-advance-amount
  ;; tick-advance-amount is calculated in such way that even the fastest
  ;; gas-molecules will jump at most 1 patch length in a clock tick. As
  ;; gas-molecules jump (speed * tick-advance-amount) at every clock tick, making
  ;; tick length the inverse of the speed of the fastest gas-molecules
  ;; (1/max speed) assures that. Having each gas-molecules advance at most
  ;; one patch-length is necessary for it not to "jump over" a wall
  ;; or another gas-molecules.
  ifelse any? gas-molecules with [speed > 0]
    [ set tick-advance-amount min list (1 / (ceiling max [speed] of gas-molecules)) max-tick-advance-amount ]
    [ set tick-advance-amount max-tick-advance-amount ]
end


to speed-up-one-molecule
  clear-drawing
  ask gas-molecules [penup]
  ask one-of gas-molecules  [
    set speed speed * 10
    set energy energy-from-speed
    pendown
  ]
  calculate-tick-advance-amount
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;; CHEMICAL REACTIONS PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to check-for-reaction
  let hit-hydrogen gas-molecules-here with [molecule-type = "hydrogen"]
  let this-initial-oxygen-molecules-energy energy
  let total-energy 0

  if count hit-hydrogen >= 2 [
    if speed < 0 [set speed 0]
      let hydrogen-reactants n-of 2 hit-hydrogen
      let total-energy-all-reactants (this-initial-oxygen-molecules-energy + sum [energy] of hydrogen-reactants )
      if total-energy-all-reactants > activation-energy [

        ask hydrogen-reactants [   ;;two H2 turn into two water molecules
          ifelse highlight-product?
            [set shape  "water-boosted"]
            [set shape  "water"]
          set molecule-type "water"
          set mass 10  ;; approximate atomic weight of H20
          let total-energy-products (total-energy-all-reactants + bond-energy-released )
          set energy total-energy-products / 2
             ;; distribute half the kinetic energy of the reactants and the bond energy amongst the products (two water molecules)
          set speed speed-from-energy
        ]
      die   ;; remove the oxygen molecule, as its atoms are now part of the water molecules
      ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; COLLISION PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;from GasLab
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
      ask candidate [penup]
      set last-collision candidate
      let this-candidate self
      ask candidate [set last-collision this-candidate]
    ]
  ]
end

;; This procedure implements a collision with another gas-molecules.
;;
;; The two gas-molecules colliding are self and other-gas-molecules, and while the
;; collision is performed from the point of view of self, both gas-molecules are
;; modified to reflect its effects. This is somewhat complicated, so here is a
;; general outline:
;;   1. Do initial setup, and determine the heading between gas-molecules centers
;;      (call it theta).
;;   2. Convert the representation of the velocity of each gas-molecules from
;;      speed/heading to a theta-based vector whose first component is the
;;      gas-molecules' speed along theta, and whose second component is the speed
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

  ;; convert velocity from speed/heading representation to components
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
  ;; Velocity perpendicular to theta is unaffected by a collision along theta,
  ;; so the next two lines actually implement the collision itself, in the
  ;; sense that the effects of the collision are exactly the following changes
  ;; in gas-molecules velocity.
  set v1t (2 * vcm - v1t)
  set v2t (2 * vcm - v2t)

  ;;; PHASE 4: convert back to normal speed/heading

  ;; now convert velocity vector into new speed and heading
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
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;REPORTERS;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report speed-from-energy
  report sqrt (2 * energy / mass)
end

to-report energy-from-speed
  report 0.5 * mass * speed * speed
end


; Copyright 2007 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
470
10
888
429
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
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
105
10
205
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
100
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
50
205
83
initial-oxygen-molecules
initial-oxygen-molecules
0
200
64.0
1
1
NIL
HORIZONTAL

PLOT
215
10
469
144
Number of Molecules
time
count
0.0
10.0
0.0
50.0
true
true
"" ""
PENS
"Oxygen" 1.0 0 -13345367 true "" "plotxy ticks number-oxygen-molecules"
"Hydrogen" 1.0 0 -7500403 true "" "plotxy ticks number-hydrogen-molecules"
"Water" 1.0 0 -16777216 true "" "plotxy ticks number-water-molecules"

SLIDER
5
120
205
153
initial-gas-temperature
initial-gas-temperature
0
500
200.0
1
1
NIL
HORIZONTAL

SLIDER
5
195
205
228
bond-energy-released
bond-energy-released
0
10000
3240.0
10
1
NIL
HORIZONTAL

SLIDER
5
160
205
193
activation-energy
activation-energy
0
5000
2000.0
50
1
NIL
HORIZONTAL

PLOT
215
142
469
268
Gas Temp. vs. time
time
temp.
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"gas temp." 1.0 0 -16777216 true "" "plotxy ticks temperature"

SLIDER
5
85
205
118
initial-hydrogen-molecules
initial-hydrogen-molecules
0
200
104.0
2
1
NIL
HORIZONTAL

SLIDER
5
230
205
263
pressure-limit-container
pressure-limit-container
100
10000
4000.0
100
1
NIL
HORIZONTAL

BUTTON
5
305
205
339
speed up & trace one molecule
\nspeed-up-one-molecule
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
15
375
190
408
show-wall-hits?
show-wall-hits?
0
1
-1000

SWITCH
15
340
190
373
highlight-product?
highlight-product?
0
1
-1000

PLOT
215
268
469
408
Pressure vs. time
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
"pressure" 1.0 0 -16777216 true "" "if box-intact? [plotxy ticks mean pressure-history]"

@#$#@#$#@
## WHAT IS IT?

This model shows the chemical kinetics of the combustion reaction of hydrogen and oxygen gas, which is generally used in rocket engines.

The chemical reaction that hydrogen and oxygen gas undergoes to produce water vapor is called an exothermic reaction. The hydrogen (H<sub>2</sub>) reacts with the oxygen found in air (O<sub>2</sub>), to produce water vapor (H<sub>2</sub>O). This chemical reaction is represented as follows:

2H<sub>2</sub> + O<sub>2</sub> -> 2H<sub>2</sub>O

H<sub>2</sub> and O<sub>2</sub> are called the reactants and (H<sub>2</sub>O) is the product of the reaction.  Note that two hydrogen molecules and one oxygen molecule are consumed in this reaction to make two water vapor molecules.

## HOW IT WORKS

For a reaction to occur, oxygen (O<sub>2</sub>) and hydrogen (H<sub>2</sub>) must have enough energy to break the atomic bonds in oxygen and hydrogen and allow the atoms to rearrange to make (H<sub>2</sub>O).  This bond breaking energy threshold is called the ACTIVATION-ENERGY.

When a chemical reaction occurs then, the chemical potential energy stored in the atomic configurations of the reactants is transformed into kinetic energy as a new configuration of atoms (the products) is created.  This excess energy released in the reaction is called the BOND-ENERGY-RELEASED.  When the bond energy released is increased the products will have greater thermal energy, due to their increased kinetic molecular energy that came from the bond energy released through the chemical reaction.

If BOND-ENERGY-RELEASED was set to a negative number it would model an endothermic reaction will be modeled.  This is one in which the thermal energy of the products is less than the thermal energy of the reactants due to molecular kinetic energy being converted into chemical potential energy in the chemical reaction.

For reactions that require lots of activation-energy, some reactions will not occur at low temperatures, or will occur more slowly at lower temperatures.

The autoignition point for hydrogen gas under normal pressure and presence of oxygen gas is 536C (709K).  https://en.wikipedia.org/wiki/Autoignition_temperature

The container wall is modeled as having a fixed pressure limit.  Once that pressure limit is reached the container breaks open (explodes).  The exploding container is shown simply as particles of the container flying apart and outward at a constant rate.

The phenomena of a container walls failing when hydrogen and oxygen ignite can be seen in a balloon filled with hydrogen and oxygen gas that is lit with a match as well as many historical examples in space rockets.  Some alternate energy automobiles and other transportation vehicles also use this reaction to power the piston displacement in their internal combustion engines, since it produces no carbon dioxide in the products and therefore does not contribute that green house gas to the environment through its emissions

## HOW TO USE IT

Press SETUP to set up the simulation. Press GO to run the simulation.

INITIAL-OXYGEN-MOLECULES sets the initial number of oxygen (O<sub>2</sub>) molecules.
INITIAL-HYDROGEN-MOLECULES sets the initial number of hydrogen (H<sub>2</sub>) molecules.
INITIAL-GAS-TEMPERATURE sets the temperature of the gas container.
ACTIVATION-ENERGY is the energy threshold for breaking the atomic bonds in oxygen and hydrogen molecules.
BOND-ENERGY-RELEASED is thermal energy (kinetic molecular energy) that the product molecules gain after releasing the chemical potential energy in reactants.
PRESSURE-LIMIT-CONTAINER determines the level of pressure that will cause the walls of the gas container to break or explode.
SPEED-UP-AND-TRACE-ONE-MOLECULE selects one of the hydrogen molecules at random and increases its speed by a factor of 10 times its current speed.
HIGHLIGHT-PRODUCT? helps make the water molecules that are produced easier to see when it is set to "on", as it draw each water molecule with a yellow ring drawn around it.
SHOW-WALL-HITS? helps visualize where particles hit the wall (and therefore where contributions to the pressure of the gas occur and are measured).

## THINGS TO NOTICE

At low initial gas temperatures, the two gases do not react.  One fast moving molecule however can trigger a reaction, which releases energy, which in turn, triggers more reactions, etc., showing the cascading effects of bond energy released in chemical reactions to help sustain a rapid combustion of these fuels.

Notice the shape of the curves for number of molecules.  Why do they exhibit the shape they do?  What does that say about the rate of the reaction and why would the rate change the way it does?

If the container breaks and molecules escape the system, pressure will no longer be graphed and the molecules will no longer be counted in the graphs of number of molecules once they reach the edge of the WORLD & VIEW.

## THINGS TO TRY

Try Different BOND-ENERGY-RELEASED, ACTIVATION-ENERGY, and PRESSURE-LIMIT-CONTAINER levels to make the chemical reaction occur at different rates, or not at all.

Compare rates of reactions and how long it takes the container to fail by reaching its pressure limit, for different initial gas temperatures.

## EXTENDING THE MODEL

Add a pendown feature to trace the paths of the products to see if there are any patterns in how the chemical reaction propagates energy for new chemical reactions throughout the system.

Add two "injection ports" into the container, one adds an adjustable rate of inflow of oxygen molecules, the other adds an adjustable rate of inflow of hydrogen molecules (see GasLab models for examples of how to do this).  Place an exhaust port on the container where molecules can escape.  Measure the percent of product escaping at the exhaust port and the temperature of the gas at the exhaust port.  This could serve as a useful model for combustion in some types of liquid fuel rockets that use hydrogen and oxygen gas and could help show how adjusting flow rate and container geometry can influence the efficiency of combustion (and how complete that combustion is).

Add a moving piston wall to model the behavior of a piston in a hydrogen fueled automobile engine.

Replace the hydrogen fuel with other common fuels (such as hydrocarbons) and model the production of water and carbon dioxide and carbon monoxide from the combustion of those reactants.

## NETLOGO FEATURES

Uses GasLab particle collision code.

## CREDITS AND REFERENCES

This model is part of the Connected Chemistry curriculum.  See http://ccl.northwestern.edu/curriculum/chemistry/.

We would like to thank Sharona Levy and Michael Novak for their substantial contributions to this model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2007).  NetLogo Connected Chemistry Gas Combustion model.  http://ccl.northwestern.edu/netlogo/models/ConnectedChemistryGasCombustion.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

hydrogen
true
8
Circle -1 true false 70 70 100
Circle -1 true false 130 130 100

hydrogen-boosted
true
8
Circle -1 true false 70 70 100
Circle -1 true false 130 130 100
Circle -2674135 false false 0 0 298

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

oxygen
true
0
Circle -13791810 true false 120 105 150
Circle -13791810 true false 45 30 150

oxygen-boosted
true
0
Circle -13791810 true false 120 105 150
Circle -13791810 true false 45 30 150

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

water
true
0
Circle -13791810 true false 75 90 150
Circle -1 true false 12 48 102
Circle -1 true false 192 48 102

water-boosted
true
0
Circle -13791810 true false 75 90 150
Circle -1 true false 12 48 102
Circle -1 true false 192 48 102
Circle -1184463 false false 0 0 300

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
