globals
[
  tick-advance-amount                                ;; clock variable
  max-tick-advance-amount                            ;; the largest a tick length is allowed to be
  avg-speed avg-energy                       ;; current averages
  show-rust-molecule-boundaries?
  total-iron-atoms
  total-oxygen-atoms
  reactant-count-iron-atoms
  reactant-count-oxygen-atoms
  product-count-iron-atoms
  product-count-oxygen-atoms
  mass-oxygen-molecule
  mass-iron-atom
  mass-rust-molecule
  background-color
  water-color
  particle-size
]

breed [ oxygen-molecules oxygen-molecule]
breed [ rust-molecules rust-molecule]
breed [ iron-atoms iron-atom ]

patches-own [water? radiation]

oxygen-molecules-own [ mass energy speed last-collision]
rust-molecules-own   [ mass vibrate-energy drag?]
iron-atoms-own       [ mass vibrate-energy]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SETUP PROCEDURES      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
  clear-all
  set particle-size 1.4
  set mass-oxygen-molecule 4
  set background-color black
  set water-color blue
  set show-rust-molecule-boundaries? false
  set max-tick-advance-amount 0.02
  set-default-shape iron-atoms       "iron-atom"
  set-default-shape oxygen-molecules "oxygen-molecule"
  set-default-shape rust-molecules   "rust-molecule"
  make-box
  make-iron-atom
  make-oxygen-molecules
  ask patches [set water? false]
  update-variables
  reset-ticks
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;RUNTIME PROCEDURES    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to go
  check-mouse-interactions
  ;; fade away radiation in patches after UV light is shone on them
  ask patches with [radiation > 0 and water? ] [set radiation (radiation - 5)  set pcolor (water-color +  (radiation / 20))]
  ask patches with [radiation > 0 and not water?] [set radiation (radiation - 5)  set pcolor (background-color + (radiation / 10))]

  ask oxygen-molecules [if radiation > 0 [set energy (energy + radiation) set speed speed-from-energy]]
  ask oxygen-molecules [ check-for-bounce-off-wall ]
  ask oxygen-molecules with [pxcor = max-pxcor and pxcor = min-pxcor and pycor = min-pycor and pycor = max-pycor] [remove-from-wall]
  ask oxygen-molecules [ move ]
  ask oxygen-molecules with [any? iron-atoms-here or any? rust-molecules-here] [remove-from-solid-block]

  visualize-vibrational-energy
  visualize-rust-molecule-boundaries

  ask oxygen-molecules
  [
   check-for-collision
   check-for-bounce-off-iron-atom
   check-for-reaction
  ]
  update-variables
  calculate-tick-advance-amount
  tick-advance tick-advance-amount
  update-plots
  display
end


to update-variables
  set avg-speed  mean [speed] of oxygen-molecules
  set avg-energy mean [energy] of oxygen-molecules
  set reactant-count-iron-atoms (count iron-atoms)
  set reactant-count-oxygen-atoms  ((count oxygen-molecules) * 2) ;; each oxygen molecule has two oxygen atoms
  set product-count-iron-atoms ((count rust-molecules) * 2) ;; each rust molecule has two iron atoms
  set product-count-oxygen-atoms  ((count rust-molecules) * 3) ;; each rust molecule has three oxygen atoms
  set total-iron-atoms (reactant-count-iron-atoms + product-count-iron-atoms)
  set total-oxygen-atoms  (reactant-count-oxygen-atoms + product-count-oxygen-atoms)
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DETECT CHEMICAL REACTION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to check-for-reaction
  let iron-pair? false
  let product-molecule-1 nobody
  let product-molecule-2 nobody
  let reactants-oxygen-molecules nobody
  let reactants-oxygen-atoms nobody
  let this-iron-atom nobody
  let product-location-1 nobody
  let product-location-2 nobody
  let other-iron-atoms nobody
  let water-catalysts 0.1

  ask iron-atoms  [
    set this-iron-atom self
   ;; reaction requires 4 iron atoms (one is the calling agent, three are on neighbors) and 3 oxygen molecules
    if ((count iron-atoms-on neighbors >= 3) and (count oxygen-molecules-on neighbors >= 3)   ) [
      set reactants-oxygen-molecules n-of 3 oxygen-molecules-on neighbors
      set water-catalysts count neighbors with [water?]
      set other-iron-atoms n-of 3 iron-atoms-on neighbors
      if (
        sum [energy] of reactants-oxygen-molecules > activation-energy or
        (sum [energy] of reactants-oxygen-molecules > activation-energy / 2 and water-catalysts > 0)
      ) [
        if rust-forms = "at oxygen locations" [  ;; have rust form right where one of the oxygen molecules were
          ask n-of 2 reactants-oxygen-molecules [
          hatch 1 [create-rust-molecule]]
        ]
        if rust-forms = "at iron locations" [  ;; have rust form right where one of the iron atoms were
          hatch 1 [create-rust-molecule]
          ask n-of 1 other-iron-atoms [
          hatch 1 [create-rust-molecule]]
        ]
        if rust-forms = "at both iron and oxygen locations" [ ;; have rust form at either where the oxygen molecule was or the iron atom was
          hatch 1 [create-rust-molecule]
          ask n-of 1 reactants-oxygen-molecules [
          hatch 1 [create-rust-molecule]]
        ]
        ask other-iron-atoms [die]  ;; remove the products
        ask reactants-oxygen-molecules [die]
        die

      ]
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ENERGY VISUALIZATION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to visualize-vibrational-energy
  let molecules-in-solid (turtle-set rust-molecules iron-atoms)
  if solid-vibration? [
    ask molecules-in-solid [ ;; visualize energy as a vibration in rust molecules
      set vibrate-energy (vibrate-energy + radiation / 50)
      if vibrate-energy >= 20 [set vibrate-energy 20]
      if vibrate-energy <= 0 [set vibrate-energy 0]
      setxy pxcor +  ((sqrt vibrate-energy) * (1 - random-float 2)) / 100 pycor + ((sqrt vibrate-energy) * (1 - random-float 2)) / 100
   ]
 ]
end



to toggle-rust-molecule-boundaries  ;; visualization technique to better see the rust molecules
  ifelse show-rust-molecule-boundaries? [set show-rust-molecule-boundaries? false ]
     [set show-rust-molecule-boundaries? true]
end

to visualize-rust-molecule-boundaries
  ifelse show-rust-molecule-boundaries? [ask rust-molecules [set shape  "rust-molecule"]]
     [ask rust-molecules [set shape "rust-molecule-boundary"]]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SETUP RELATED PROCEDURES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to make-box
  ask patches with [pxcor = min-pxcor or pxcor = max-pxcor or pycor = min-pycor or pycor = max-pycor]
    [ set pcolor gray ]
end


to make-iron-atom
  set-default-shape iron-atoms "iron-atom"

  if iron-block-geometry = "9 x 9 middle box" [
    ask patches with [ pxcor <= 4 and  pycor <= 4 and pxcor >= -4 and pycor >= -4] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
  if iron-block-geometry = "6 x 6 middle box" [
    ask patches with [ pxcor <= 3 and  pycor <= 3 and pxcor >= -2 and pycor >= -2] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
  if iron-block-geometry = "4 x 9 middle box" [
    ask patches with [ pxcor <= 2 and pycor <= 4 and pxcor >= -1 and pycor >= -4] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
  if iron-block-geometry = "3 x 12 middle box" [
    ask patches with [ pxcor <= 1 and  pycor <= 6 and pxcor >= -1 and pycor >= -5] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
  if iron-block-geometry = "2 x 18 middle box" [
    ask patches with [ pxcor <= 1 and  pycor <= 9 and pxcor >= 0 and pycor >= -8] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
  if iron-block-geometry = "19 x 1 bottom box" [
    ask patches with [ pxcor <= 9 and pxcor >= -9 and pycor > min-pxcor and pycor <= (min-pxcor + 1)] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
  if iron-block-geometry = "19 x 2 bottom box" [
    ask patches with [ pxcor <= 9 and  pxcor >= -9 and pycor > min-pxcor  and pycor <= (min-pxcor + 2)] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
  if iron-block-geometry = "19 x 3 bottom box" [
    ask patches with [ pxcor <= 9 and pxcor >= -9 and pycor > min-pxcor and pycor <= (min-pxcor + 3)] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
  if iron-block-geometry = "19 x 4 bottom box" [
    ask patches with [ pxcor <= 9 and  pxcor >= -9 and pycor > min-pxcor and pycor <= (min-pxcor + 4)] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
  if iron-block-geometry = "19 x 5 bottom box" [
    ask patches with [ pxcor <= 9 and pxcor >= -9 and pycor > min-pxcor and pycor <= (min-pxcor + 5)] [
    sprout-iron-atoms 1 [setup-iron-atom]]
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PARTICLE INITIALIZATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to create-rust-molecule
    set breed rust-molecules
    set drag? false
    set size particle-size
    set vibrate-energy ((random-float 2) * 40)
end


to setup-iron-atom
  set color gray
  set size particle-size
  set vibrate-energy (initial-gas-temperature / 10)
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MOUSE INTERACTIONS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to check-mouse-interactions
  if (mouse-interaction = "add water") [add-water-catalyst]
  if (mouse-interaction = "remove water") [remove-water-catalyst]
  if (mouse-interaction = "drag away rust") [listen-move-rust-molecules]
  if (mouse-interaction = "shine UV light on iron") [shine-uv-light]
end


to shine-uv-light
 let snap-xcor mouse-xcor
 let snap-ycor mouse-ycor
 if mouse-down? [
   ask patches with [(distancexy snap-xcor snap-ycor) <= 2 and
   pxcor != max-pxcor and pxcor != min-pxcor and pycor != min-pycor and pycor != max-pycor]
     [set radiation (radiation + 10) if radiation >= 100 [set radiation 100] ]
 ]
end


to add-water-catalyst
  let snap-mouse-xcor round mouse-xcor
  let snap-mouse-ycor round mouse-ycor
  if mouse-down? and not any? iron-atoms-on patch snap-mouse-xcor snap-mouse-ycor and not any? rust-molecules-on patch snap-mouse-xcor snap-mouse-ycor
    and snap-mouse-xcor != max-pxcor and snap-mouse-xcor != min-pxcor and snap-mouse-ycor != max-pycor and snap-mouse-ycor != min-pycor
    [ask patch snap-mouse-xcor snap-mouse-ycor [set water? true set pcolor blue]]
end


to remove-water-catalyst
  let  snap-mouse-xcor round mouse-xcor
  let snap-mouse-ycor round mouse-ycor
  if mouse-down? and snap-mouse-xcor != max-pxcor and snap-mouse-xcor != min-pxcor and snap-mouse-ycor != max-pycor and snap-mouse-ycor != min-pycor
    [ ask patch snap-mouse-xcor snap-mouse-ycor [set water? false set pcolor black]]
end


to listen-move-rust-molecules
  let snap-shot-mouse-xcor (mouse-xcor)
  let snap-shot-mouse-ycor ( mouse-ycor)

  ;; for any molecules in drag state
  if (any? rust-molecules with [drag?]) [
    ask rust-molecules with [drag?] [setxy snap-shot-mouse-xcor snap-shot-mouse-ycor]
  ]

  ;; if there are molecules here
  if (any? rust-molecules with [pxcor =  round snap-shot-mouse-xcor and pycor = round snap-shot-mouse-ycor]) [
    if (mouse-down? and not any? rust-molecules with [drag?]) [                                 ;; if none currently being dragged
      ask one-of rust-molecules with [pxcor = round snap-shot-mouse-xcor and pycor = round snap-shot-mouse-ycor] [set drag? true]
    ]
  ]
  if (not mouse-down?) [ask rust-molecules [set drag? false] ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PARTICLE PENETRATION ERROR HANDLING;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; deals with the case when a particle penetrates into the wall or the solid iron, but should not have
;; removes the particle to the nearest open patch

to remove-from-wall
  let available-patches patches with [not any? iron-atoms-here and not any? rust-molecules-here]
  let closest-patch nobody
  if (any? available-patches) [
    set closest-patch min-one-of available-patches [distance myself]
    set heading towards closest-patch
    move-to closest-patch
  ]
end


to remove-from-solid-block
  let available-patches patches with [not any? iron-atoms-here and not any? rust-molecules-here]
  let closest-patch nobody
  if (any? available-patches) [
    set closest-patch min-one-of available-patches [distance myself]
    set heading towards closest-patch
    move-to closest-patch
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;COLLISION AND REACTION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to check-for-bounce-off-iron-atom
   let hit-iron-atom one-of iron-atoms in-cone 1 180
   let hit-rust-molecule one-of rust-molecules in-cone 1 180
   let speed-loss 0
   ifelse hit-iron-atom != nobody  [
     let hit-angle towards hit-iron-atom
     ifelse (hit-angle < 135 and hit-angle > 45) or (hit-angle < 315 and hit-angle > 225)
       [set heading (- heading)] [set heading (180 - heading)]
   ]
   [if hit-rust-molecule != nobody [
      let hit-angle towards hit-rust-molecule
      ifelse (hit-angle < 135 and hit-angle > 45) or (hit-angle < 315 and hit-angle > 225)
        [set heading (- heading)] [set heading (180 - heading)]
   ]]
end



to check-for-bounce-off-wall  ;; oxygen-molecules procedure
  ;; get the coordinates of the patch we'll be on if we go forward 1
  let new-patch patch-ahead 1
  let new-px [pxcor] of new-patch
  let new-py [pycor] of new-patch
  ;; if we're not about to hit a wall, we don't need to do any further checks
  if not shade-of? gray [pcolor] of new-patch
    [ stop ]
  ;; if hitting left or right wall, reflect heading around x axis
  if (new-px = max-pxcor or new-px = min-pxcor)
    [ set heading (- heading) ]
  ;; if hitting top or bottom wall, reflect heading around y axis
  if (new-py = min-pycor or new-py = max-pycor)
    [ set heading (180 - heading)]
end


to move  ;; oxygen-molecules procedure
  if patch-ahead (speed * tick-advance-amount) != patch-here
    [ set last-collision nobody ]
  jump (speed * tick-advance-amount)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GAS MOLECULES COLLISIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;from GasLab

to calculate-tick-advance-amount
  ;; tick-advance-amount is calculated in such way that even the fastest
  ;; oxygen-molecules will jump at most 1 patch length in a clock tick. As
  ;; oxygen-molecules jump (speed * tick-advance-amount) at every clock tick, making
  ;; tick length the inverse of the speed of the fastest oxygen-molecules
  ;; (1/max speed) assures that. Having each oxygen-molecules advance at most
   ; one patch-length is necessary for it not to "jump over" a wall
   ; or another oxygen-molecules.
  ifelse any? oxygen-molecules with [speed > 0]
    [ set tick-advance-amount min list (1 / (ceiling max [speed] of oxygen-molecules)) max-tick-advance-amount ]
    [ set tick-advance-amount max-tick-advance-amount ]
end


to check-for-collision  ;; oxygen-molecules procedure
  if count other oxygen-molecules-here in-radius 1 = 1
  [
    ;; the following conditions are imposed on collision candidates:
    ;;   1. they must have a lower who number than my own, because collision
    ;;      code is asymmetrical: it must always happen from the point of view
    ;;      of just one oxygen-molecules.
    ;;   2. they must not be the same oxygen-molecules that we last collided with on
    ;;      this patch, so that we have a chance to leave the patch after we've
    ;;      collided with someone.
    let candidate one-of other oxygen-molecules-here with
      [self < myself and myself != last-collision]
    ;; we also only collide if one of us has non-zero speed. It's useless
    ;; (and incorrect, actually) for two oxygen-molecules with zero speed to collide.
    if (candidate != nobody) and (speed > 0 or [speed] of candidate > 0)
    [
      collide-with candidate
      set last-collision candidate
      let this-candidate self
      ask candidate [set last-collision this-candidate]
    ]
  ]
end

;; implements a collision with another oxygen-molecules.
;;
;;
;; The two oxygen-molecules colliding are self and other-oxygen-molecules, and while the
;; collision is performed from the point of view of self, both oxygen-molecules are
;; modified to reflect its effects. This is somewhat complicated, so I'll
;; give a general outline here:
;;   1. Do initial setup, and determine the heading between oxygen-molecules centers
;;      (call it theta).
;;   2. Convert the representation of the velocity of each oxygen-molecules from
;;      speed/heading to a theta-based vector whose first component is the
;;      oxygen-molecules' speed along theta, and whose second component is the speed
;;      perpendicular to theta.
;;   3. Modify the velocity vectors to reflect the effects of the collision.
;;      This involves:
;;        a. computing the velocity of the center of mass of the whole system
;;           along direction theta
;;        b. updating the along-theta components of the two velocity vectors.
;;   4. Convert from the theta-based vector representation of velocity back to
;;      the usual speed/heading representation for each oxygen-molecules.
;;   5. Perform final cleanup and update derived quantities.
to collide-with [ other-oxygen-molecules ] ;; oxygen-molecules procedure
  ;;; PHASE 1: initial setup

  ;; for convenience, grab some quantities from other-oxygen-molecules
  let mass2 [mass] of other-oxygen-molecules
  let speed2 [speed] of other-oxygen-molecules
  let heading2 [heading] of other-oxygen-molecules

  ;; since oxygen-molecules are modeled as zero-size points, theta isn't meaningfully
  ;; defined. we can assign it randomly without affecting the model's outcome.
  let theta (random-float 360)



  ;;; PHASE 2: convert velocities to theta-based vector representation

  ;; now convert my velocity from speed/heading representation to components
  ;; along theta and perpendicular to theta
  let v1t (speed * cos (theta - heading))
  let v1l (speed * sin (theta - heading))

  ;; do the same for other-oxygen-molecules
  let v2t (speed2 * cos (theta - heading2))
  let v2l (speed2 * sin (theta - heading2))



  ;;; PHASE 3: manipulate vectors to implement collision

  ;; compute the velocity of the system's center of mass along theta
  let vcm (((mass * v1t) + (mass2 * v2t)) / (mass + mass2) )

  ;; now compute the new velocity for each oxygen-molecules along direction theta.
  ;; velocity perpendicular to theta is unaffected by a collision along theta,
  ;; so the next two lines actually implement the collision itself, in the
  ;; sense that the effects of the collision are exactly the following changes
  ;; in oxygen-molecules velocity.
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

  ;; and do the same for other-oxygen-molecules
  ask other-oxygen-molecules [
    set speed sqrt ((v2t ^ 2) + (v2l ^ 2))
    set energy (0.5 * mass * (speed ^ 2))
    if v2l != 0 or v2t != 0
      [ set heading (theta - (atan v2l v2t)) ]
  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;CREATE AND PLACE GAS MOLECULES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-oxygen-molecules
  create-oxygen-molecules initial-oxygen-molecules
  [
    setup-oxygen-molecules
    random-position
  ]
end


to setup-oxygen-molecules  ;; oxygen-molecules procedure
  set size particle-size
  set energy initial-gas-temperature
  set mass mass-oxygen-molecule
  set speed speed-from-energy
  set last-collision nobody
end



;; Place oxygen-molecules at random, but they must not be placed on top of iron-atom atoms.
;; This procedure takes into account the fact that iron-atom molecules could have two possible arrangements,
;; i.e. high-surface area to low-surface area.
to random-position ;; oxygen-molecules procedure
  let open-patches nobody
  let open-patch nobody
  set open-patches patches with [not any? iron-atoms-here and pxcor != max-pxcor and pxcor != min-pxcor and pycor != min-pycor and pycor != max-pycor]
  set open-patch one-of open-patches
  move-to open-patch
  set heading random-float 360
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
490
10
834
355
-1
-1
16.0
1
10
1
1
1
0
1
1
1
-10
10
-10
10
1
1
1
ticks
120.0

BUTTON
80
10
174
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
0
10
75
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
0
85
175
118
initial-oxygen-molecules
initial-oxygen-molecules
1
50
40.0
1
1
NIL
HORIZONTAL

PLOT
180
10
486
280
Number of Particles
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
"Oxygen molecules" 1.0 0 -2674135 true "" "plotxy ticks count oxygen-molecules"
"Pure iron atoms" 1.0 0 -7500403 true "" "plotxy ticks count iron-atoms"
"Rust molecules" 1.0 0 -6459832 true "" "plotxy ticks count rust-molecules"

SLIDER
1
48
176
81
initial-gas-temperature
initial-gas-temperature
1
50
40.0
1
1
NIL
HORIZONTAL

SWITCH
0
300
175
333
solid-vibration?
solid-vibration?
0
1
-1000

SLIDER
0
120
175
153
activation-energy
activation-energy
0
400
400.0
1
1
NIL
HORIZONTAL

CHOOSER
0
155
175
200
iron-block-geometry
iron-block-geometry
"9 x 9 middle box" "6 x 6 middle box" "4 x 9 middle box" "3 x 12 middle box" "2 x 18 middle box" "19 x 1 bottom box" "19 x 2 bottom box" "19 x 3 bottom box" "19 x 4 bottom box" "19 x 5 bottom box"
9

CHOOSER
0
200
175
245
rust-forms
rust-forms
"at iron locations" "at oxygen locations" "at both iron and oxygen locations"
1

MONITOR
180
280
330
325
atoms of oxygen in gas
reactant-count-oxygen-atoms
0
1
11

MONITOR
330
325
485
370
atoms of iron in rust
product-count-iron-atoms
0
1
11

MONITOR
330
280
485
325
atoms of oxygen in rust
product-count-oxygen-atoms
0
1
11

MONITOR
180
325
330
370
atoms of iron in block
reactant-count-iron-atoms
0
1
11

BUTTON
0
335
175
368
toggle rust molecules
toggle-rust-molecule-boundaries
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
0
250
175
295
mouse-interaction
mouse-interaction
"none" "add water" "remove water" "shine UV light on iron" "drag away rust"
4

@#$#@#$#@
## WHAT IS IT?

This model simulates the behavior of oxygen gas particles in a closed container with solid iron.  It is one in a series of Connected Chemistry models, that the same basic rules for simulating the behavior of gases and chemical reactions.  Each model integrates different features in order to highlight different aspects of chemical reactions.

The basic principle of this rusting model is that oxygen gas particles are assumed to have three elementary actions: 1) they move, 2) they collide,  - either with other gas  particles or with any other objects such as non-reacting solid surfaces (walls), 3) and they can react with iron particles.

A basic representation of the oxidation reaction that occurs between oxygen particles and iron particles is  30<sub>2</sub> + 4Fe --> 2Fe<sub>2</sub>O<sub>3</sub>.  This represents a chemical reaction that requires three oxygen molecules and 4 iron atoms as reactants to create two rust molecules.  While this appears to be a single reaction, in reality, a series of intermediate compounds are created before rust as a product is formed.  But this simplified chemical reaction, without intermediates is often presented in introductory chemistry units and courses as a way to make sense of the initial reactants and final products in a rusting reaction.

In our everyday experiences, iron will not rust spontaneously with oxygen.  For iron to rust, three things are needed: iron, water and oxygen.  When these three type of molecules are near each other, the water acts as a catalyst for the rust reaction, acting as a good electrolyte permitting easier electron flow between atoms.

A second lesson common everyday pathway for the rusting reaction occurs in the presence of high energy UV radiation, and requires no water catalyst.  This is the rusting reaction that is believed to  occur on the surface of Mars.  The iron oxide on the surface of Mars accounts for much of its red-orange color.

Both of these pathways are represented in the model.

The catalytic role of water is simplified to be a geometric catalyst (a cluster of water molecules is represented by a blue patch).  It keeps the necessary reactants (dissolved oxygen molecules) trapped in that for a longer period of time than would occur otherwise if they were a gas.  This modeling assumption is different than representing the water an electron-transfer catalyst.

The contributing role of UV radiation is simplified to be a localized and temporary energy boost in the vibrational energy of the iron atoms, which in turn brings the reactants closer to the activation energy required for the reaction.

## HOW IT WORKS

The gas particles are modeled as hard balls with no internal energy except that which is due to their motion.  Solid particles are modeled as hard balls with internal energy represented as rotational energy.  Collisions between particles are elastic.

The basic principle of all gas behavior in the Connected Chemistry models, including this one, is the following algorithm:

1. A particle moves in a straight line without changing its speed, unless it collides with another particle or bounces off the wall.
2. Two particles "collide" if they find themselves on the same patch.
3. A random axis is chosen, as if they are two balls that hit each other and this axis is the line connecting their centers.
4. They exchange momentum and energy along that axis, according to the conservation of momentum and energy.  This calculation is done in the center of mass system.
5. Each particle is assigned its new velocity, energy, and heading.
6. If a particle finds itself on or very close to a wall of the container, it "bounces" -- that is, reflects its direction and keeps its same speed.
7. If a particle ever penetrates into the solid iron/rust matrix, it has moved too far forward in the last simulation time step, and is bounced back out to the closest open spot (patch).

## HOW TO USE IT

Initial settings:
INITIAL-GAS-TEMPERATURE: Sets the initial kinetic energy of each of the gas particles
INITIAL-OXYGEN-MOLECULES: Sets the number of initial oxygen gas particles
ACTIVATION-ENERGY: Sets the energy threshold required for a reaction to occur between the products.  The sum of the energies of the reactants must exceed this level for a reaction to occur.
IRON-BLOCK-GEOMETRY: Sets possible size and location of the iron block.
RUST-FORMS-AT: Determines whether rust molecules form within the metal block or on the surface of it or both.
MOUSE-INTERACTION: Gives the user options to "add water", "remove water", "remove rust", and "shine a UV beam on the iron".

The SETUP button will set the initial conditions.
The GO/STOP button will run the simulation.

## THINGS TO NOTICE

In this model, iron atoms adjacent to a patch with water and the necessary oxygen molecule reactants in it are pulled away from the iron metal block when rust forms.  This leads to the deposition of rust above the surface of the iron as well as pitting of the iron block.  This pitting effect occurs in reality.

As you drag away rust (using the mouse cursor), you expose more iron to the air, speeding up the rusting process.

The model demonstrates other emergent phenomena of when oxygen and iron react to form rust.  Some of these phenomena include how surface area affects the rate of the reaction, how temperature of the reactants affects the rate of the reaction, and how a catalyst (such as water) can speed up the rate of a reaction.  Other phenomena, such as atomic conservation in chemical reactions and limiting agents in chemical reactions are also visible in the model.

## THINGS TO TRY

Explore different surface geometries of iron.  How does the surface area affect the rate of the reaction?

## EXTENDING THE MODEL

Rust molecules could be knocked off the iron block when fast colliding molecules hit them.

Water could be modeled as particles (H<sub>2</sub>O molecules) instead of colored patches.  Oil is often used as a protective layer for preventing the rusting of iron.  Oil molecules (which repel water), but allow some oxygen through could be added to the model.

Salt water vs. fresh water could be added to the model, such that the salt water served as a better catalyst than fresh water.

UV light energy that is absorbed by the iron atom and converted to vibrational energy (particulate kinetic energy) could be reradiated as infra-red energy or conducted to particles in contact with each iron atom.  Currently such energy remains trapped in the iron atom unless a chemical reaction happens.

## NETLOGO FEATURES

This model shows a good way of preventing particles that bounce off the world-walls from penetrating the walls. By having a dynamic tick duration calculated every tick, it attempts that even the fastest moving particle never moves more than one patch per tick. The patch-ahead primitive can therefore always be used to check whether to change the heading of a particle that is ready to reflect or 'bounce' off of a wall.

When a gas particle is detected as having accidentally entered into the space of a patch that is a wall or has an iron particle in it, it is moved to the nearest open patch.

## CREDITS AND REFERENCES

This model is part of the Connected Chemistry curriculum.  See http://ccl.northwestern.edu/curriculum/chemistry/.

We would like to thank Sharona Levy and Michael Novak for their substantial contributions to this model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2007).  NetLogo Connected Chemistry Rusting Reaction model.  http://ccl.northwestern.edu/netlogo/models/ConnectedChemistryRustingReaction.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

02
false
0
Circle -2674135 true false 60 75 120
Circle -2674135 true false 120 120 120
Circle -16777216 false false 120 120 120

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

iron-atom
true
0
Circle -7500403 true true 69 82 136

iron-atom2
true
6
Circle -7500403 true false 99 82 136

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

oxygen-atom
true
0
Circle -13791810 true false 47 98 104

oxygen-molecule
true
0
Circle -2674135 true false 43 96 108
Circle -2064490 false false 42 95 110
Circle -2674135 true false 133 96 108
Circle -2064490 false false 132 95 110

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

rust-molecule
true
6
Circle -7500403 true false 89 7 136
Circle -1 false false 89 7 136
Circle -7500403 true false 89 157 136
Circle -1 false false 89 157 136
Circle -2674135 true false 28 201 108
Circle -1 false false 27 200 110
Circle -2674135 true false 146 96 108
Circle -1 false false 145 95 110
Circle -2674135 true false 28 -9 108
Circle -1 false false 27 -10 110

rust-molecule-boundary
true
6
Circle -7500403 true false 89 7 136
Circle -1 false false 89 7 136
Circle -7500403 true false 89 157 136
Circle -1 false false 89 157 136
Circle -2674135 true false 28 201 108
Circle -1 false false 27 200 110
Circle -2674135 true false 146 96 108
Circle -1 false false 145 95 110
Circle -2674135 true false 28 -9 108
Circle -1 false false 27 -10 110
Circle -955883 false false -30 -30 360

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

water molecule
true
0
Circle -1 true false 103 73 62
Circle -13791810 true false 133 96 108
Circle -13345367 false false 132 95 110
Circle -1 true false 103 163 62
Circle -7500403 false true 103 163 62

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
