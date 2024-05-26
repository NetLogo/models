globals [
  tick-delta
  max-tick-delta
  gravity
  min-piston-height
  piston-height
  piston-vel
  piston-mass
  pressure
  init-avg-speed
  flask-bottom-ycor
  flask-abs-xcor
  flask-height
  balloon-bottom-ycor
  balloon-abs-xcor
  Zn-increment
  init-gas-speed
  height-history
]

;; Describe different agent breeds
breed [ Zns Zn ]
breed [ Zn-ions Zn-ion ]
breed [ hydroniums hydronium ]
breed [ dihydrogens dihydrogen ]
breed [ pistons piston ]
breed [ flashes flash ]

;; Describe breed internal variables

hydroniums-own [ speed ]
Zn-ions-own [ speed ]
dihydrogens-own [
  speed mass energy
  last-collision
]
pistons-own [ speed mass energy ]
flashes-own [ birthday ]


to setup
  clear-all

  initialize-variables

  make-flask-and-water
  make-balloon
  make-piston

  make-Zn
  make-HCl

  reset-ticks
end

to go
  if piston-height >= max-pycor - balloon-bottom-ycor [
    user-message "The balloon reached the top of the chamber. The simulation will stop."
    stop
  ]

  ask hydroniums [
    bounce-flask
    move
  ]
  ask hydroniums [ check-for-reaction-hydronium ]

  ask Zn-ions [
    bounce-flask
    move
  ]

  ask dihydrogens [
    if if-flask? [bounce-flask]
    if in-balloon? [bounce-balloon]
    move
  ]
  ask dihydrogens with [in-balloon?]  [ check-for-collision ]


  ask Zns [sink]
  move-piston
  update-balloon

  ;; Utility and updating
  tick-advance tick-delta

  simulate-brownian-motion

  calculate-tick-delta
  ;; we check for pcolor = black to make sure flashes that are left behind by the piston die
  ask flashes with [ticks - birthday > 0.4 or pcolor = black] [ die ]

end

;; ----- VARIABLE MANIPULATION -----

to initialize-variables
  set flask-bottom-ycor -35
  set flask-height 20
  set flask-abs-xcor 15
  set balloon-bottom-ycor (flask-bottom-ycor + flask-height - 1)
  set balloon-abs-xcor 6
  set Zn-increment 5 ;; increment for the num-Zn slider
  set-default-shape turtles "circle"
  set-default-shape flashes "square"
  set init-gas-speed 10
  set max-tick-delta 1 / (init-gas-speed + 1)
  set gravity 0.05
  set min-piston-height 3
  set piston-height min-piston-height
  set piston-vel 0
  set piston-mass 600
  set height-history n-values 10 [0]
end

to calculate-tick-delta
  ;; tick-delta is calculated in such way that even the fastest
  ;; particle (or the piston) will jump at most 1 patch length in a
  ;; tick. As particles jump (speed * tick-delta) at every
  ;; tick, making tick length the inverse of the speed of the
  ;; fastest particle (1/max speed) assures that. Having each particle
  ;; advance at most one patch-length is necessary for them not to
  ;; "jump over" a wall or the piston.
  let turtles-with-speed turtles with [(breed != Zns) and (breed != flashes)]
  ifelse any? turtles-with-speed with [speed > 0]
    [ set tick-delta min list
                            (1 / (ceiling max ([speed] of turtles-with-speed)))
                            max-tick-delta ]
    [ set tick-delta max-tick-delta ]
end

to calculate-height
  set height-history lput piston-height but-first height-history
end

;; ----- BOUNDARY SETUP -----

to make-flask-and-water
  let flask-top flask-bottom-ycor + flask-height
  ;; bottom
  ask patches with [
    (abs pxcor <= flask-abs-xcor) and
    (pycor = flask-bottom-ycor) ] [
      set pcolor white
  ]
  ;; walls
  ask patches with [
    (abs pxcor = flask-abs-xcor) and
    (pycor >= flask-bottom-ycor) and
    (pycor <= flask-top) ] [
      set pcolor white
  ]
  ;; top
  ask patches with [
    (abs pxcor <= flask-abs-xcor) and
    (abs pxcor >= balloon-abs-xcor) and
    (pycor = flask-top) ] [
      set pcolor white
  ]
  ;; water in the flask
  ask patches with [
    (abs pxcor < flask-abs-xcor) and
    (pycor > flask-bottom-ycor) and
    (pycor < flask-top) ] [
      set pcolor blue
  ]
end

to make-balloon
  ask patches with [
    (abs pxcor = balloon-abs-xcor) and
    (pycor > balloon-bottom-ycor + 1) and
    (pycor <= balloon-bottom-ycor + min-piston-height) ] [
      set pcolor orange
  ]
end

to update-balloon
  ask patches with [pycor > [pycor] of one-of pistons] [ set pcolor black ]
  ask patches with [(pycor = [pycor] of one-of pistons) and (abs pxcor = balloon-abs-xcor)] [ set pcolor orange ]
end

;; ----- PARTICLE PROCEDURES -----

to-report if-flask?
  report [pcolor] of patch-here = blue
end

to-report in-balloon?
  report [pcolor] of patch-here = black
end

to sink ; Zn procedure
  set heading 180
  if [pcolor = blue and not any? Zns-here] of patch-ahead 1 [
    fd 1
  ]
end

to simulate-brownian-motion
  if floor ticks > floor (ticks - tick-delta) [
    ; simulate brownian motion while preserving simulation speed
    ask turtles [
      if (breed = hydroniums)  [

      ]
      if (breed = dihydrogens and [pcolor = blue] of patch-here) [
        set heading 0  ; so they float
        rt (random 180) - 90
      ]
    ]
    calculate-height
    update-plots
  ]
end

to make-Zn
  ;; define a block based on the amt-Zn slider
  let range-xcor (num-Zn / Zn-increment)
  let max-xcor (ceiling (range-xcor / 2))
  let min-xcor (max-xcor - range-xcor - 1)
  ask patches with [
    (pycor > flask-bottom-ycor) and
    (pycor <= flask-bottom-ycor + Zn-increment) and
    (pxcor > min-xcor) and
    (pxcor < max-xcor) ] [
    ;; create zinc atoms
    sprout-Zns 1 [
      set size 1
      set color gray
    ]
  ]
end

to make-HCl
  create-hydroniums num-HCl [  ; HCl is put into the flask, but it disassociatees into hydronium and chloride ions. We don't visualize the chlorides
    set speed 1
    random-position
    set color green

  ]
end

;; place particle at random location inside the water not on zinc
to random-position  ;; particle procedure
  setxy ((1 - flask-abs-xcor)  + random-float (2 * flask-abs-xcor - 2))
        ((flask-bottom-ycor + Zn-increment + 1) + random-float (flask-height - Zn-increment - 2))
end

to bounce-flask
  ;; get the coordinates of the patch we'll be on if we go forward 1
  let new-patch patch-ahead 1
  let new-px [pxcor] of new-patch
  let new-py [pycor] of new-patch

  ; if we're not about to hit a wall (patch color hasn't changed), we don't need to do any further checks
  if ([pcolor] of new-patch = blue) [ stop ]

  ; check: hitting left or right wall?
  if (abs new-px = flask-abs-xcor) [ ; if so, reflect heading around x axis
      ;;  if the particle is hitting a vertical wall, only the horizontal component of the speed vector can change.
      set heading (- heading)
  ]

  ; check: hitting bottom wall or top wall?
  if new-py = flask-bottom-ycor or (new-py = flask-bottom-ycor + flask-height) [

    ifelse breed = dihydrogens [
      ifelse [pcolor] of new-patch = white [
        ;;  if the particle is hitting a horizontal wall, only the vertical component of the speed vector can change.
        set heading (180 - heading)
      ] [
        ; if a dihydrogen is going to enter the gas phase, we speed it up
        set speed init-gas-speed
      ]
    ] [
      ;;  if the particle is hitting a horizontal wall, only the vertical component of the speed vector can change.
      set heading (180 - heading)
    ]

  ]


end

to bounce-balloon  ;; particles procedure
  ;; get the coordinates of the patch we'll be on if we go forward 1
  let new-patch patch-ahead 1
  let new-px [pxcor] of new-patch
  let new-py [pycor] of new-patch
  ; if we're not about to hit a wall (yellow patch) or piston (orange patch)
  ; we don't need to do any further checks
  if ([pcolor] of new-patch = black)
    [ stop ]

  ; check: hitting left or right wall?
  if (abs new-px = balloon-abs-xcor)
    ; if so, reflect heading around x axis
    [
      ;;  if the particle is hitting a vertical wall, only the horizontal component of the speed
      ;;  vector can change.  The change in velocity for this component is 2 * the speed of the particle,
      ;; due to the reversing of direction of travel from the collision with the wall
      set heading (- heading) ]

  ; check: hitting top or bottom wall? (Should never hit top, but this would handle it.)
  if ((new-py = balloon-bottom-ycor) or (new-py = max-pycor))
  [
    ;;  if the particle is hitting a horizontal wall, only the vertical component of the speed
    ;;  vector can change.  The change in velocity for this component is 2 * the speed of the particle,
    ;; due to the reversing of direction of travel from the collision with the wall
    set heading (180 - heading)
  ]

  ; check: hitting piston?
  if (new-py = [pycor] of one-of pistons)
  [
    ;;  if the particle is hitting the piston, only the vertical component of the speed
    ;;  vector can change.  The change in velocity for this component is 2 * the speed of the particle,
    ;; due to the reversing of direction of travel from the collision with the wall
    ;; make sure that each particle finishes exchanging energy before any others can
    exchange-energy-with-piston
  ]
  if (new-py != balloon-bottom-ycor)
  [
    ask patch new-px new-py
      [ sprout-flashes 1 [
        set color pcolor - 2
        set birthday ticks
        set heading 0
      ]
    ]
  ]
end

to move
  if (breed = dihydrogens) and (patch-ahead (speed * tick-delta) != patch-here) [
    set last-collision nobody
  ]
  jump (speed * tick-delta)
end

to check-for-reaction-hydronium
  if count Zns-here = 1 and count other hydroniums-here >= 1 [
    hatch-dihydrogens 1 [
      set color yellow
      set size 0.8
      set mass 1
        set speed 1
        set energy (0.5 * mass * (speed ^ 2))
        set last-collision nobody
    ]

    ask one-of Zns-here [ ; the Zn turns into an ion
      set breed Zn-ions
      set size 0.7
      set speed 1
      set heading random-float 360
    ]

    ; The two hydroniums "die" (they turned into a dihydrogen)
    ask one-of other hydroniums-here [die]
    die

  ]
end


to check-for-collision  ;; particle procedure
  ;; Here we impose a rule that collisions only take place when there
  ;; are exactly two particles per patch.  We do this because when the
  ;; student introduces new particles from the side, we want them to
  ;; form a uniform wavefront.
  ;;
  ;; Why do we want a uniform wavefront?  Because it is actually more
  ;; realistic.  (And also because the curriculum uses the uniform
  ;; wavefront to help teach the relationship between particle collisions,
  ;; wall hits, and pressure.)
  ;;
  ;; Why is it realistic to assume a uniform wavefront?  Because in reality,
  ;; whether a collision takes place would depend on the actual headings
  ;; of the particles, not merely on their proximity.  Since the particles
  ;; in the wavefront have identical speeds and near-identical headings,
  ;; in reality they would not collide.  So even though the two-particles
  ;; rule is not itself realistic, it produces a realistic result.  Also,
  ;; unless the number of particles is extremely large, it is very rare
  ;; for three or more particles to land on the same patch (for example,
  ;; with 400 particles it happens less than 1% of the time).  So imposing
  ;; this additional rule should have only a negligible effect on the
  ;; aggregate behavior of the system.
  ;;
  ;; Why does this rule produce a uniform wavefront?  The particles all
  ;; start out on the same patch, which means that without the only-two
  ;; rule, they would all start colliding with each other immediately,
  ;; resulting in much random variation of speeds and headings.  With
  ;; the only-two rule, they are prevented from colliding with each other
  ;; until they have spread out a lot.  (And in fact, if you observe
  ;; the wavefront closely, you will see that it is not completely smooth,
  ;; because some collisions eventually do start occurring when it thins out while fanning.)

  if count other dihydrogens-here = 1
  [
    ;; the following conditions are imposed on collision candidates:
    ;;   1. they must have a lower who number than my own, because collision
    ;;      code is asymmetrical: it must always happen from the point of view
    ;;      of just one particle.
    ;;   2. they must not be the same particle that we last collided with on
    ;;      this patch, so that we have a chance to leave the patch after we've
    ;;      collided with someone.
    let candidate one-of other dihydrogens-here with
      [who < [who] of myself and myself != last-collision]
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

to collide-with [ other-particle ] ;; particle procedure
  ;;; PHASE 1: initial setup

  ;; for convenience, grab some quantities from other-particle
  let mass2 [mass] of other-particle
  let speed2 [speed] of other-particle
  let heading2 [heading] of other-particle

  ;; since particles are modeled as zero-size points, theta isn't meaningfully
  ;; defined. we can assign it randomly without affecting the model's outcome.
  let theta (random-float 360)


  ;;; PHASE 2: convert velocities to theta-based vector representation

  ;; now convert my velocity from speed/heading representation to components
  ;; along theta and perpendicular to theta
  let v1t (speed * cos (theta - heading))
  let v1l (speed * sin (theta - heading))

  ;; do the same for other-particle
  let v2t (speed2 * cos (theta - heading2))
  let v2l (speed2 * sin (theta - heading2))


  ;;; PHASE 3: manipulate vectors to implement collision

  ;; compute the velocity of the system's center of mass along theta
  let vcm (((mass * v1t) + (mass2 * v2t)) / (mass + mass2) )

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
  set energy (0.5 * mass * speed ^ 2)
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

;; ----- PISTON -----

to make-piston
  ask patches with [(pycor = balloon-bottom-ycor + min-piston-height) and
                    (abs pxcor < balloon-abs-xcor)]
  [ sprout-pistons 1
    [ set color orange
      set heading 0
      set pcolor color
      set size 0
    ]
  ]
end

to move-piston
  let old-piston-vel piston-vel
  set piston-vel (old-piston-vel - gravity * tick-delta)    ;;apply gravity
  let movement-amount ((old-piston-vel * tick-delta) - (gravity * (0.5 * (tick-delta  ^ 2))))
  ;; Setting the pcolor makes the piston look like a wall to the particles.
  ask pistons
  [ set pcolor black
    while [(piston-vel * tick-delta) >= 1.0]
      [ calculate-tick-delta ]
    ;; If the piston will end up between the minimum and maximum heights...
    ifelse ((piston-height + movement-amount <= max-pycor - 1 - balloon-bottom-ycor) and
            (piston-height + movement-amount > min-piston-height))
    [
      fd movement-amount
      set piston-height ([ycor] of one-of pistons - balloon-bottom-ycor)
    ]
    [
      ;; If the piston will exceed the maximum height...
      if (piston-height + movement-amount > max-pycor - 1 - balloon-bottom-ycor)
      [
        set ycor max-pycor
        set piston-height (max-pycor - balloon-bottom-ycor)
        if (piston-vel > 0) [ set piston-vel 0 ]
      ]
      ;; If the piston will end up below the minimum height...
      if (piston-height + movement-amount <= min-piston-height)
      [
        set ycor (balloon-bottom-ycor + min-piston-height)
        set piston-height min-piston-height
        if (piston-vel < 0) [ set piston-vel 0 ]
      ]
    ]
    set speed piston-vel ;; just used for tick-delta calculations
    set pcolor color
    if (any? dihydrogens-here)
    [
      ask dihydrogens-here
      [
        let direction -1
        ;if (old-piston-vel > 0) [ set direction 1 ]
        ;;if (old-piston-vel <= 0) [ set direction -1 ]
        set ycor (pycor + direction)
        ;;  if the particle is hitting the piston, only the vertical component of the speed
        ;;  vector can change.  The change in velocity for this component is 2 * the speed of the particle,
        ;; due to the reversing of direction of travel from the collision with the wall
        ;; make sure that each particle finishes exchanging energy before any others can
        exchange-energy-with-piston
      ]
    ]
  ]
end

to exchange-energy-with-piston  ;; particle procedure -- piston and particle exchange energy
  let vx (speed * dx)         ;;only along x-axis
  let vy (speed * dy)         ;;only along y-axis
  let old-vy vy
  let old-piston-vel piston-vel
  set piston-vel ((((piston-mass - mass) / (piston-mass + mass)) * old-piston-vel) +
                  (((2 * mass) / (piston-mass + mass)) * old-vy))
  set vy ((((2 * piston-mass) / (piston-mass + mass)) * old-piston-vel) -
         (((piston-mass - mass) / (piston-mass + mass)) * old-vy))
  set speed (sqrt ((vx ^ 2) + (vy ^ 2)))
  set energy (0.5 * mass * (speed  ^ 2))
  set heading atan vx vy
end


; Copyright 2022 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
350
10
604
481
-1
-1
6.0
1
10
1
1
1
0
1
1
1
-20
20
-38
38
1
1
1
ticks
30.0

BUTTON
5
90
85
123
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
90
90
170
123
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
5
10
177
43
num-Zn
num-Zn
0
100
50.0
Zn-increment
1
NIL
HORIZONTAL

SLIDER
5
50
177
83
num-HCl
num-HCl
0
100
50.0
1
1
NIL
HORIZONTAL

PLOT
5
135
330
280
Gas Produced
Time
Num H2
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count dihydrogens"

PLOT
5
290
330
435
Balloon Size
Time
Size
0.0
10.0
0.0
60.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean height-history"

MONITOR
190
80
282
125
H2 Molecules
count dihydrogens
2
1
11

@#$#@#$#@
## WHAT IS IT?

This model simulates the production of hydrogen gas through the reaction of zinc metal with hydrochloric acid.

## HOW IT WORKS

Zinc metal (non-moving gray circles) sits at the bottom of a flask (outlined in white) filled with an aqueous solution of hydrochloric acid (HCl). Since HCl is a relatively strong acid, in solution it dissociates into Chloride Cl<sup>-</sup> ions (not shown) and hydrogen ions which each join a water molecule to form a hydronium H<sub>3</sub>O<sup>+</sup> ion (green circles). When two of these ions encounter a zinc atom, they react to produce a ZnCl<sub>2</sub> molecule and a hydrogen H<sub>2</sub> molecule (yellow circles). The ZnCl<sub>2</sub> in solution breaks down into zinc ions (small moving gray circles) and Chloride ions (not shown). The hydrogen molecules escape the solution and begin to exert pressure on a balloon attached to the flask’s top (outlined in orange). Based on the pressure in the balloon, its size will increase or decrease.

The full reaction is normally written as follows:
> Zn(s) + 2HCl(aq) → ZnCl<sub>2</sub>(aq) + H<sub>2</sub>(g)

We can also write it with HCl and ZnCl<sub>2</sub> split into the ions they form in solution:

> Zn(s) + 2H<sub>3</sub>O<sup>+</sup>(aq) + 2Cl<sup>-</sup>(aq) → Zn<sup>2+</sup>(aq) + 2Cl<sup>-</sup>(aq) + H<sub>2</sub>(g)

Note that the Cl<sup>-</sup> ions don't change, which is why they aren't visualized in the model.

**Note**: the balloon size fluctuates a lot in the model. This is due to the very small number of hydrogen molecules in the model. Due to the small number, random fluctuations can change the instantaneous pressure on the balloon by a lot. In a real balloon, the number of hydrogen molecules is so huge that the fluctuations in pressure are negligible.

## HOW TO USE IT

### BUTTONS

`SETUP`: Creates the flask, balloon, and all of the molecules in them.
`GO`: Starts the simulation, allowing the molecules to move and react.

### INPUTS

`NUM-ZN`: Determines the number of zinc metal atoms in the flask at the start of the simulation.
`NUM-HCL`: Determines the number of hydrochloric acid molecules in the flask at the start of the simulation.


### OUTPUTS

`H2 MOLECULES`: Displays the number of hydrogen gas molecules that have been produced.
`GAS PRODUCED`: Plots the amount of hydrogen gas in the balloon over time.
`BALLOON SIZE`: Plots the height of the balloon over time.

## THINGS TO NOTICE

Pay attention to how the different molecules move.  Do some molecules move faster than others?  Do all of the molecules move in straight lines?  Try to explain each of these observations and how they relate to reality.

## THINGS TO TRY

Adjust the sliders for `NUM-ZN` and `NUM-HCL`. Pay attention to the amount of hydrogen gas produced. Can you work out how the values for `NUM-ZN` and `NUM-HCL` affect the amount of gas?

Observe the model to see where the reaction is taking place. Why isn’t it happening in other places?

## EXTENDING THE MODEL

The current implementation of the balloon is not very mechanistically realistic.  Try to improve this by adding a gas surrounding the balloon to balance the pressure from the gas inside of it.

## NETLOGO FEATURES

This model uses partial ticks and the `tick-advance` primitive to ensure that molecules never move more than one patch per update.  This makes sure they can't skip through the walls of the flask or balloon.

This model also uses a global variable as a slider parameter, in this case using `zn-increment` as the slider increment for the `MOLS-ZN` slider.  The model uses the `startup` procedure to ensure that this is properly initialized as soon as the model loads.

## RELATED MODELS

This model is similar to several of the **GasLab** and **Connected Chemistry** models in the Models Library, particularly the **GasLab Adiabatic Piston** model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Levy, S., Kelter, J. and Wilensky, U. (2022).  NetLogo Hydrogen Gas Production model.  http://ccl.northwestern.edu/netlogo/models/HydrogenGasProduction.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2022 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2022 Cite: Levy, S., Kelter, J. -->
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
