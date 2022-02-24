globals
[
  tick-advance-amount                  ;; actual tick length
  max-tick-advance-amount              ;; the largest a tick length is allowed to be
  box-edge-y                   ;; location of the end of the box
  box-edge-x                   ;; location of the end of the box
  number-forward-reactions     ;; keeps track number of forward reactions that occur
  number-reverse-reactions     ;; keeps track number of backward reactions that occur
  pressure                     ;; pressure at this point in time
  pressure-history             ;; list of the last 10 pressure values

  length-horizontal-surface    ;; the size of the wall surfaces that run horizontally - the top and bottom of the box - used for calculating pressure and volume
  length-vertical-surface      ;; the size of the wall surfaces that run vertically - the left and right of the box - used for calculating pressure and volume
  walls                        ;; agent set containing patches that are the walls of the box
  heatable-walls               ;; the walls that could transfer heat into our out of the box when INSULATED-WALLS? is set to off
  piston-wall                  ;; the patches of the right wall on the box (it is a moveable wall)
  outside-energy               ;; energy level for isothermal walls
  min-outside-energy           ;; minimum energy level for an isothermal wall
  max-outside-energy           ;; minimum energy level for an isothermal wall
  energy-increment             ;; the amount of energy added to or subtracted from the isothermal wall when the WARM UP WALL or COOL DOWN WALL buttons are pressed
  piston-position              ;; xcor of piston wall
  piston-color                 ;; color of piston
  wall-color                   ;; color of wall
  insulated-wall-color         ;; color of insulated walls
  run-go?                      ;; flag of whether or not its safe for go to run - it is used to stop the simulation when the wall is moved
  volume                       ;; volume of the box
  scale-factor-temp-to-energy  ;; scale factor used to convert kinetic energy of particles to temperature
  scale-factor-energy-to-temp  ;; scale factor used to convert temperature of gas convert to kinetic energy of particles
  temperature                  ;; temperature of the gas
  difference-bond-energies     ;; amount of energy released or absorbed in forward or reverse reaction
  activation-energy            ;; amount of energy required to react
  particle-size
]

breed [ particles particle ]
breed [ flashes flash ]        ;; visualization of particle hits against the wall

particles-own
[
  speed mass energy          ;; particle info
  momentum-difference        ;; used to calculate pressure from wall hits
  last-collision             ;; last particle that this particle collided with
  molecule-type              ;; type of molecule (H2, N2, or NH3)
]

flashes-own [birthday ]      ;; keeps track of when it was created (which tick)

patches-own [insulated? wall?]     ;; insulated patches do not transfer energy into or out of particles

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SETUP PROCEDURES   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
  clear-all
  set run-go? true
  set number-forward-reactions 0
  set number-reverse-reactions 0

  set scale-factor-energy-to-temp 4
  set scale-factor-temp-to-energy (1 / scale-factor-energy-to-temp)
  set outside-energy initial-gas-temp * scale-factor-temp-to-energy

  set difference-bond-energies 20    ;; describes how much energy is lost or gained in the transition from products to reactants.
                                     ;; a negative value states that energy is lost (endothermic) for the forward reaction
                                     ;; a positive value states that energy is gained (exothermic) for the forward reaction
  set activation-energy 80
  set energy-increment 5
  set min-outside-energy 0
  set max-outside-energy 100

  set particle-size 1.3
  set-default-shape particles "circle"
  set-default-shape flashes "square"
  set piston-color green
  set insulated-wall-color yellow


  set max-tick-advance-amount 0.1
  ;; box has constant size...
  set box-edge-y (max-pycor - 1)
  set box-edge-x (max-pxcor - 1)
  ;;; the length of the horizontal or vertical surface of
  ;;; the inside of the box must exclude the two patches
  ;;; that are the where the perpendicular walls join it,
  ;;; but must also add in the axes as an additional patch
  ;;; example:  a box with an box-edge of 10, is drawn with
  ;;; 19 patches of wall space on the inside of the box
  set piston-position init-wall-position - box-edge-x
  draw-box-piston
  recalculate-wall-color
  calculate-volume
  make-particles
  set pressure-history []  ;; plotted pressure will be averaged over the past 3 entries
  calculate-pressure-and-temperature
  reset-ticks
end


to make-particles
  create-particles #-H2  [ setup-hydrogen-particle]
  create-particles #-N2  [ setup-nitrogen-particle]
  create-particles #-NH3 [ setup-ammonia-particle ]
  calculate-tick-advance-amount
end


to setup-hydrogen-particle
  set shape "hydrogen"
  set molecule-type "hydrogen"
  set mass 2
  set-other-particle-attributes
end


to setup-nitrogen-particle
  set size particle-size
  set shape "nitrogen"
  set molecule-type "nitrogen"
  set mass 14
  set-other-particle-attributes
end


to setup-ammonia-particle
  set shape "nh3"
  set molecule-type "nh3"
  set mass 10
  set-other-particle-attributes
end


to set-other-particle-attributes
  set size particle-size
  set last-collision nobody
  set energy (initial-gas-temp * scale-factor-temp-to-energy)
  set speed  speed-from-energy
  random-position
end


;; place particle at random location inside the box.
to random-position ;; particle procedure
  setxy ((1 - box-edge-x)  + random-float (box-edge-x + piston-position - 3))
        ((1 - box-edge-y) + random-float (2 * box-edge-y - 2))
  set heading random-float 360
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; RUNTIME PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to go
  if not run-go? [stop]
  ask particles [
    bounce
    move
    check-for-collision
  ]

  if forward-react? [ ask particles with [molecule-type = "nitrogen"]  [check-for-forward-reaction]]
  if reverse-react? [ ask particles with [molecule-type = "nh3"]       [check-for-reverse-reaction]]

  calculate-pressure-and-temperature
  calculate-tick-advance-amount
  tick-advance tick-advance-amount
  recalculate-wall-color
  update-plots
  display
end


to calculate-tick-advance-amount
  ifelse any? particles with [speed > 0]
    [ set tick-advance-amount min list (1 / (ceiling max [speed] of particles)) max-tick-advance-amount ]
    [ set tick-advance-amount max-tick-advance-amount ]
end


to move  ;; particle procedure
  if patch-ahead (speed * tick-advance-amount) != patch-here
    [ set last-collision nobody ]
  jump (speed * tick-advance-amount)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;VISUALIZATION PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to recalculate-wall-color
  ;; scale color of walls to dark red to bright red based on their isothermal value....if the wall isn't insulated
  ;; set color of walls to all insulated-wall-color if the wall is insulated
  ifelse insulated-walls?
     [set wall-color insulated-wall-color ]
     [set wall-color (scale-color red outside-energy -60 (max-outside-energy + 100))]
     ask patches with [not insulated?] [set pcolor wall-color]
     ask flashes with [ticks - birthday > 0.4] [die ]   ;; after 0.4 ticks recolor the wall correctly and remove the flash
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;CHEMICAL REACTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to check-for-forward-reaction
  let hit-hydrogen particles with [distance myself <= 1 and molecule-type = "hydrogen"]

  if count hit-hydrogen >= 3 and random 2 = 0 [  ;; 50/50 chance of a reaction
    if speed < 0 [set speed 0]
    let reactants n-of 3 hit-hydrogen
    let total-input-energy (energy + sum [energy] of reactants )  ;; sum the kinetic energy of the N2 molecule and the three H2 molecules

    if total-input-energy > activation-energy [
      ;; an exothermic reaction
      let total-output-energy (total-input-energy + difference-bond-energies )
      ;; turn this N2 molecule into an NH3 molecule
      set molecule-type "nh3"
      set shape "nh3"
      set mass 10
      set energy (total-output-energy * 10 / 20)  ;; each of the two product molecules take half the output energy, scaled to masses out / mass in
      set speed  sqrt (2 * (energy / mass))
      ;; and also create another NH3 molecule
      hatch 1 [set heading (heading + 180) ]
      ask reactants [die] ;; reactants are used up
      set number-forward-reactions (number-forward-reactions + 1)
    ]
  ]

end


to check-for-reverse-reaction
  let hit-nh3 particles with [distance myself <= 1 and molecule-type = "nh3" and self != myself]

  if count hit-nh3 >= 1 and random 2 = 0 [  ;;50/50 chance of a reaction
    let reactants n-of 1 hit-nh3
    let total-input-energy (energy + sum [energy] of reactants )  ;; sum the kinetic energy of both NH3 molecules

    if total-input-energy > activation-energy [
      let total-output-energy (total-input-energy - difference-bond-energies )
      ;; make a nitrogen molecule as the one of the products

      set molecule-type "nitrogen"
      set shape "nitrogen"
      set mass 14
      set energy (total-output-energy * 14 / (20))   ;; take 14/20 th of the energy (proportional to masses of all the products)
      set speed speed-from-energy

      ;; make three H2 molecules as the rest of the products
      hatch 3 [
        set molecule-type "hydrogen"
        set shape "hydrogen"
        set mass 2
        set energy (total-output-energy * 2 / (20))  ;; take 2/20 th of the energy (proportional to masses of all the products) for each of the 3 molecules
        set speed  speed-from-energy
        set heading random 360
      ]
      ask reactants [  die ]
      set number-reverse-reactions (number-reverse-reactions + 1)
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;CHANGING ISOTHERMAL WALL PROCEDURES ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to cool
  ifelse ( outside-energy > 20 ) [ set outside-energy outside-energy - energy-increment ] [ set outside-energy 0 ]
  if (outside-energy <= 0) [
    set outside-energy min-outside-energy
    user-message (word
      "You are currently trying to cool the walls of the container below "
      "absolute zero (OK or -273C).  Absolute zero is the lowest theoretical "
      "temperature for all matter in the universe and has never been "
      "achieved in a real-world laboratory")
  ]
  recalculate-wall-color
  ask heatable-walls [set pcolor wall-color]
end


to heat
  set outside-energy outside-energy + energy-increment
  if (outside-energy > max-outside-energy) [
    set outside-energy max-outside-energy
    user-message (word "You have reached the maximum allowable temperature for the walls of the container in this model." )
  ]
  recalculate-wall-color
  ask heatable-walls [set pcolor wall-color]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CALCULATIONS P, T, V PROCEDURES  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Pressure is defined as the force per unit area.  In this context,
;;; that means the total momentum per unit time transferred to the walls
;;; by particle hits, divided by the surface area of the walls.  (Here
;;; we're in a two dimensional world, so the "surface area" of the walls
;;; is just their length.)  Each wall contributes a different amount
;;; to the total pressure in the box, based on the number of collisions, the
;;; direction of each collision, and the length of the wall.  Conservation of momentum
;;; in hits ensures that the difference in momentum for the particles is equal to and
;;; opposite to that for the wall.  The force on each wall is the rate of change in
;;; momentum imparted to the wall, or the sum of change in momentum for each particle:
;;; F = SUM  [d(mv)/dt] = SUM [m(dv/dt)] = SUM [ ma ], in a direction perpendicular to
;;; the wall surface.  The pressure (P) on a given wall is the force (F) applied to that
;;; wall over its surface area.  The total pressure in the box is sum of each wall's
;;; pressure contribution.

to calculate-pressure-and-temperature
  ;; by summing the momentum change for each particle,
  ;; the wall's total momentum change is calculated
  set pressure 15 * sum [momentum-difference] of particles
  ifelse length pressure-history > 10
    [ set pressure-history lput pressure but-first pressure-history]
    [ set pressure-history lput pressure pressure-history]
  ask particles [ set momentum-difference 0]  ;; once the contribution to momentum has been calculated
                                              ;; this value is reset to zero till the next wall hit

 if any? particles [ set temperature (mean [energy] of particles  * scale-factor-energy-to-temp) ]
end


to calculate-volume
  set length-horizontal-surface  ( 2 * (box-edge-x - 1) + 1) - (abs (piston-position - box-edge-x))
  set length-vertical-surface  ( 2 * (box-edge-y - 1) + 1)
  set volume (length-horizontal-surface * length-vertical-surface * 1)  ;;depth of 1
end

to reset-reaction-counters
  set number-forward-reactions 0
  set number-reverse-reactions 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PARTICLES BOUNCING OFF THE WALLS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to bounce  ;; particle procedure
  let new-patch 0
  let new-px 0
  let new-py 0

  ;; get the coordinates of the patch we'll be on if we go forward 1
  if (not wall? and [not wall?] of patch-at dx dy)
    [stop]
  ;; get the coordinates of the patch we'll be on if we go forward 1
  set new-px round (xcor + dx)
  set new-py round (ycor + dy)
  ;; if hitting left wall or piston (on right), reflect heading around x axis
  if ((abs new-px = box-edge-x or new-px = piston-position))
    [
      set heading (- heading)
  ;;  if the particle is hitting a vertical wall, only the horizontal component of the speed
  ;;  vector can change.  The change in velocity for this component is 2 * the speed of the particle,
  ;; due to the reversing of direction of travel from the collision with the wall
      set momentum-difference momentum-difference + (abs (sin heading * 2 * mass * speed) / length-vertical-surface) ]
  ;; if hitting top or bottom wall, reflect heading around y axis
  if (abs new-py = box-edge-y)
    [ set heading (180 - heading)
  ;;  if the particle is hitting a horizontal wall, only the vertical component of the speed
  ;;  vector can change.  The change in velocity for this component is 2 * the speed of the particle,
  ;; due to the reversing of direction of travel from the collision with the wall
      set momentum-difference momentum-difference + (abs (cos heading * 2 * mass * speed) / length-horizontal-surface)  ]

  if [isothermal-wall?] of patch new-px new-py  [ ;; check if the patch ahead of us is isothermal
     set energy ((energy +  outside-energy ) / 2)
     set speed speed-from-energy
  ]


   ask patch new-px new-py [ make-a-flash ]
end

to make-a-flash
      sprout 1 [
      set breed flashes
      set birthday ticks
      set color [0 0 0 100]
    ]
end





to check-for-collision  ;; particle procedure
  let candidate 0

  if count other particles-here = 1
  [
    ;; the following conditions are imposed on collision candidates:
    ;;   1. they must have a lower who number than my own, because collision
    ;;      code is asymmetrical: it must always happen from the point of view
    ;;      of just one particle.
    ;;   2. they must not be the same particle that we last collided with on
    ;;      this patch, so that we have a chance to leave the patch after we've
    ;;      collided with someone.
    set candidate one-of other particles-here with
      [self < myself and myself != last-collision]
    ;; we also only collide if one of us has non-zero speed. It's useless
    ;; (and incorrect, actually) for two particles with zero speed to collide.
   if (candidate != nobody) and (speed > 0 or [speed] of candidate > 0)
    [
      collide-with candidate
      set last-collision candidate
      ask candidate [ set last-collision myself ]
    ]
  ]
end




;; implements a collision with another particle.
;;
;; The two particles colliding are self and other-particle, and while the
;; collision is performed from the point of view of self, both particles are
;; modified to reflect its effects. This is somewhat complicated, so I'll
;; give a general outline here:
;;   1. Do initial setup, and determine the heading between particle centers
;;      (call it theta).
;;   2. Convert the representation of the velocity of each particle from
;;      speed/heading to a theta-based vector whose first component is the
;;      particle's speed along theta, and whose second component is the speed
;;      perpendicular to theta.
;;   3. Modify the velocity vectors to reflect the effects of the collision.
;;      This involves:
;;        a. computing the velocity of the center of mass of the whole system
;;           along direction theta
;;        b. updating the along-theta components of the two velocity vectors.
;;   4. Convert from the theta-based vector representation of velocity back to
;;      the usual speed/heading representation for each particle.
;;   5. Perform final cleanup and update derived quantities.
to collide-with [ other-particle ] ;; particle procedure
  let mass2 0
  let speed2 0
  let heading2 0
  let theta 0
  let v1t 0
  let v1l 0
  let v2t 0
  let v2l 0
  let vcm 0


  ;;; PHASE 1: initial setup

  ;; for convenience, grab some quantities from other-particle
  set mass2 [mass] of other-particle
  set speed2 [speed] of other-particle
  set heading2 [heading] of other-particle

  ;; since particles are modeled as zero-size points, theta isn't meaningfully
  ;; defined. we can assign it randomly without affecting the model's outcome.
  set theta (random-float 360)



  ;;; PHASE 2: convert velocities to theta-based vector representation

  ;; now convert my velocity from speed/heading representation to components
  ;; along theta and perpendicular to theta
  set v1t (speed * cos (theta - heading))
  set v1l (speed * sin (theta - heading))

  ;; do the same for other-particle
  set v2t (speed2 * cos (theta - heading2))
  set v2l (speed2 * sin (theta - heading2))



  ;;; PHASE 3: manipulate vectors to implement collision

  ;; compute the velocity of the system's center of mass along theta
  set vcm (((mass * v1t) + (mass2 * v2t)) / (mass + mass2) )

  ;; now compute the new velocity for each particle along direction theta.
  ;; velocity perpendicular to theta is unaffected by a collision along theta,
  ;; so the next two lines actually implement the collision itself, in the
  ;; sense that the effects of the collision are exactly the following changes
  ;; in particle velocity.
  set v1t (2 * vcm - v1t)
  set v2t (2 * vcm - v2t)



  ;;; PHASE 4: convert back to normal speed/heading

  ;; now convert my velocity vector into my new speed and heading
  set speed sqrt ((v1t ^ 2) + (v1l ^ 2))
  set energy (0.5 * mass * (speed ^ 2))
  ;; if the magnitude of the velocity vector is 0, atan is undefined. but
  ;; speed will be 0, so heading is irrelevant anyway. therefore, in that
  ;; case we'll just leave it unmodified.
  if v1l != 0 or v1t != 0
    [ set heading (theta - (atan v1l v1t)) ]

  ;; and do the same for other-particle
  ask other-particle [
    set speed sqrt ((v2t ^ 2) + (v2l ^ 2))
    set energy (0.5 * mass * (speed ^ 2))
    if v2l != 0 or v2t != 0
      [ set heading (theta - (atan v2l v2t)) ]
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Moveable wall procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to check-move-piston
 set run-go? false
  if ((mouse-down?) and (mouse-ycor < (max-pycor - 1))) [
   ;;note: if user clicks too far to the right, nothing will happen
    if (mouse-xcor >= piston-position and mouse-xcor < box-edge-x - 2)  [ piston-out ceiling (mouse-xcor - piston-position) ]
    set run-go? true
    stop
  ]
end


to piston-out [dist]
  if (dist > 0) [
    ifelse ((piston-position + dist) < box-edge-x - 1)
    [  undraw-piston
      set piston-position (piston-position + dist)
      draw-box-piston ]
    [ undraw-piston
      set piston-position (box-edge-x - 1)
      draw-box-piston ]
    calculate-volume
  ]
end


to draw-box-piston
  ask patches [set insulated? true set wall? false]
  set heatable-walls patches with [ ((pxcor = -1 * box-edge-x) and (abs pycor <= box-edge-y)) or
                     ((abs pycor = box-edge-y) and (pxcor <= piston-position) and (abs pxcor <= box-edge-x)) ]
  ask heatable-walls  [ set pcolor wall-color set insulated? false  set wall? true]

  set piston-wall patches with [ ((pxcor = (round piston-position)) and ((abs pycor) < box-edge-y)) ]
  ask piston-wall  [ set pcolor piston-color set wall? true]
  ;; make sides of box that are to right right of the piston grey



  ask patches with [(pxcor > (round piston-position)) and (abs (pxcor) < box-edge-x) and ((abs pycor) = box-edge-y)]
    [set pcolor grey set wall? true]
  ask patches with [ ((pxcor = ( box-edge-x)) and (abs pycor <= box-edge-y))]
    [set pcolor grey set wall? true]
end


to undraw-piston
  ask patches with [ (pxcor = round piston-position) and ((abs pycor) < box-edge-y) ]
    [ set pcolor black ]
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


;; reports true if there wall is at a fixed temperature
to-report isothermal-wall?
  report
    (( abs pxcor = -1 * box-edge-x) and (abs pycor <= box-edge-y)) or
    ((abs pycor = box-edge-y) and (abs pxcor <= box-edge-x)) and
    not insulated? and
    not insulated-walls?
end


; Copyright 2012 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
485
10
1013
427
-1
-1
8.0
1
10
1
1
1
0
1
1
1
-32
32
-25
25
1
1
1
ticks
30.0

BUTTON
95
10
195
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
95
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
534
455
988
488
init-wall-position
init-wall-position
5
60
6.0
1
1
NIL
HORIZONTAL

BUTTON
140
425
285
458
move wall out
check-move-piston
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
285
370
485
490
Volume vs. Time
time
volume
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -955883 true "" "plotxy ticks volume"

PLOT
285
130
485
250
Pressure vs. Time
time
press.
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if length pressure-history > 10\n    [ plotxy ticks (mean pressure-history) ]"

PLOT
285
250
485
370
Temperature vs. Time
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
"default" 1.0 0 -2674135 true "" "plotxy ticks temperature"

SLIDER
5
85
97
118
#-N2
#-N2
0
200
0.0
1
1
NIL
HORIZONTAL

SLIDER
5
130
100
163
#-H2
#-H2
0
200
0.0
5
1
NIL
HORIZONTAL

SLIDER
5
45
195
78
initial-gas-temp
initial-gas-temp
0
400
90.0
5
1
NIL
HORIZONTAL

MONITOR
100
125
195
170
H2 molecules
count particles with [molecule-type = \"hydrogen\"]
1
1
11

MONITOR
100
80
195
125
N2 molecules
count particles with [molecule-type = \"nitrogen\"]
1
1
11

MONITOR
100
170
195
215
NH3 molecules
count particles with [molecule-type = \"nh3\"]
1
1
11

SWITCH
5
235
135
268
forward-react?
forward-react?
0
1
-1000

SWITCH
5
340
136
373
reverse-react?
reverse-react?
0
1
-1000

PLOT
205
10
485
130
Number of molecules
time
number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"H2" 1.0 0 -7500403 true "" "plotxy ticks (count particles with [molecule-type = \"hydrogen\"])"
"N2" 1.0 0 -13345367 true "" "plotxy ticks (count particles with [molecule-type = \"nitrogen\"])"
"NH3" 1.0 0 -8275240 true "" "plotxy ticks (count particles with [molecule-type = \"nh3\"])"

MONITOR
5
270
134
315
% forward reaction
100 * number-forward-reactions / (number-forward-reactions + number-reverse-reactions)
0
1
11

MONITOR
5
375
135
420
% reverse reactions
100 * number-reverse-reactions / (number-forward-reactions + number-reverse-reactions)
0
1
11

TEXTBOX
15
220
130
240
N2 + 3H2 --> 2NH3
11
105.0
1

TEXTBOX
15
320
135
354
N2 + 3H2 <-- 2NH3
11
123.0
1

SLIDER
5
175
97
208
#-NH3
#-NH3
0
200
200.0
1
1
NIL
HORIZONTAL

BUTTON
5
425
140
458
reset reaction counters
reset-reaction-counters
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
140
280
285
313
insulated-walls?
insulated-walls?
0
1
-1000

BUTTON
140
315
285
348
warm walls
heat
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
140
350
285
383
cool walls
cool
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

This is a model of reversible reactions, Le Chatelier's Principle and the Haber process (used for the manufacture of ammonia).

The default settings of this model show the following exothermic (heat releasing) reaction:

> N<sub>2</sub> (g) + 3 H<sub>2</sub> (g)  &harr;  2 NH<sub>3</sub> (g)

This is an equilibrium reaction, where specific conditions favor the forward reaction and other conditions favor the reverse reaction.

Increasing the pressure causes the equilibrium position to move to the right resulting in a higher yield of ammonia since there are more gas molecules on the left hand side of the equation (4 in total) than there are on the right hand side of the equation (2). Increasing the pressure means the system adjusts to reduce the effect of the change, that is, to reduce the pressure by having fewer gas molecules.

Decreasing the temperature causes the equilibrium position to move to the right resulting in a higher yield of ammonia since the reaction is exothermic (releases heat). Reducing the temperature means the system will adjust to minimize the effect of the change, that is, it will produce more heat since energy is a product of the reaction, and will therefore produce more ammonia gas as well.

However, the rate of the reaction at lower temperatures is extremely slow, so a higher temperature must be used to speed up the reaction, which results in a lower yield of ammonia.

Literature suggests that ideal conditions for the Haber process is at around a temperature of 500 degrees Celsius, which combines the an optimal level of two competing effects that come into play with increasing or decreasing the temperature too much:

-- A high temperature increases the rate of attaining equilibrium.

-- The forward reaction is exothermic; therefore a low temperature moves the equilibrium to the right giving a higher yield of ammonia.

--  A medium temperature is used as a compromise to maximize the combined but canceling effects of going to too high or too low a temperature, yielding a high amount of product, but also doing so quickly.

Also in the Haber process, a pressure of around 200 atm is recommended, again for the competing effects that come into ply with increasing or decreasing the pressure too much.

--  A high pressure increases the rate of attaining equilibrium

--  The forward reaction results in a reduction in volume, therefore a high pressure moves the equilibrium to the right giving a higher yield of ammonia.

Thus, a medium pressure is used as a compromise to maximize the combined but canceling effects of going to too high or too low a pressure,  yielding a high amount of product, but also doing so quickly.

## HOW IT WORKS

For a reaction to occur, nitrogen (N<sub>2</sub>) and hydrogen (H<sub>2</sub>) must have enough energy to break the atomic bonds in nitrogen and hydrogen and allow the atoms to rearrange to make NH<sub>3</sub>.  This bond breaking energy threshold is called the activation energy.

This excess energy is called the DIFFERENCE-BOND-ENERGY.  When the bond energy is released the products speed up due to an increased transfer of bond-energy to kinetic energy in the chemical reaction.  When bond energy is absorbed the products slow down from the chemical reaction.

## HOW TO USE IT

\#-N2 determines the initial number of nitrogen (N<sub>2</sub>) molecules in the simulation.

\#-H2 determines the initial number of hydrogen (H<sub>2</sub>) molecules in the simulation.

\#-NH3 determines the initial number of ammonia (NH<sub>3</sub>) molecules in the simulation.

FORWARD-REACT? controls whether the forward reaction can occur.  Similarly, REVERSE-REACT? controls whether the reverse reaction can occur.  With both turned on, an equilibrium reaction is modeled.

INITIAL-WALL-POSITION changes the initial volume of the container by moving the right hand side of the wall on SETUP.

MOVE WALL OUT when pressed allows the user to click at a location to move the wall to the right (from its current location, thereby increasing the volume of the container).  The simulation will stop after this occurs.  The user should press GO/STOP again to resume the model run.

INSULATED-WALLS? when turned on, no energy exchange occurs with the walls.  When turned off, molecules can speed up or slow down, depending on whether the energy level of the walls is higher or lower than that of the molecules.  When turned off, this models an isothermal boundary for the system.  Insulated walls appear brown, isothermal walls appear a shade of red.

WARM WALLS increases the isothermal energy level of the wall.  COOL WALLS decreases the isothermal energy level of the wall. The color of the wall reflects its energy, the darker the red wall, the colder it is; the warm, the brighter red it will be.

RESET REACTION COUNTS sets the counters for number of forward reactions and number of reverse reactions to 0.  This is useful to do when you think you have reached a stable state in the system.  After resetting the reaction counts, the % FORWARD REACTIONS and % REVERSE REACTIONS should stabilize at around 50%.

## THINGS TO NOTICE

Le Chatelier's Principle can be understood as competing effects between two different contributions to when and how often certain reaction occur.  Explore high and low temperatures and high and low pressures, and try to understand why the system tends to respond to "increase the pressure" when the volume is increased.

## THINGS TO TRY

Try running the model with FORWARD-REACTIONS set to "on" and REVERSE-REACTIONS set to "off".  Then try REVERSE-REACTIONS set to "on" and FORWARD-REACTIONS set to "off".

Try running the model starting only with ammonia molecules. Try running the model with only hydrogen and nitrogen molecules to start with.

Try to find the settings for the highest yield of ammonia.  What temperature and volume combination is optimal?

## EXTENDING THE MODEL

In the Haber process in real life the inclusion of the catalyst of iron is often used.  A similar catalyst could be added here (using the same code and modeling assumption as used for the water catalyst in the iron rusting model).

The model could be extended to represent a reversible reaction of A + B &harr; C + D.

## NETLOGO FEATURES

Uses transparency in the color of the flashes, so that the underlying patch color of the walls can still be seen.

Uses GasLab particle collision code:

Wilensky, U. (1998).  NetLogo GasLab Gas in a Box model. http://ccl.northwestern.edu/netlogo/models/GasLabGasinaBox. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2012).  NetLogo Connected Chemistry Reversible Reaction model.  http://ccl.northwestern.edu/netlogo/models/ConnectedChemistryReversibleReaction.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

To cite the Connected Chemistry curriculum as a whole, please use:

* Wilensky, U., Levy, S. T., & Novak, M. (2004). Connected Chemistry curriculum. http://ccl.northwestern.edu/curriculum/chemistry/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2012 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2012 ConChem Cite: Novak, M. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

circle
false
0
Circle -7500403 true true 30 30 240

clock
true
0
Circle -7500403 true true 30 30 240
Polygon -16777216 true false 150 31 128 75 143 75 143 150 158 150 158 75 173 75
Circle -16777216 true false 135 135 30

hydrogen
true
8
Circle -1 true false 70 70 100
Circle -1 true false 130 130 100

nh3
true
0
Circle -13345367 true false 75 75 150
Circle -1 true false 12 48 102
Circle -1 true false 192 48 102
Circle -1 true false 102 198 102

nitrogen
true
0
Circle -13345367 true false 120 105 150
Circle -13345367 true false 45 30 150

nothing
true
0

oxygen
true
0
Circle -955883 true false 120 105 150
Circle -955883 true false 45 30 150

square
false
0
Rectangle -7500403 true true 0 0 297 299
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
