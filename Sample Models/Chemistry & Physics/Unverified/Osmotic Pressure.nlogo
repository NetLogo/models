globals [
  left-side                                 ;; left side of the membrane
  right-side                                ;; right side of the membrane
  split                                     ;; location of membrane
  pre-split                                 ;; location of membrane in prior step, used to calculate the change in membrane location
  equilibrium                               ;; the difference in number of particles moving each direction across membrane
  tick-delta                                ;; how much we advance the tick counter this time through
  max-tick-delta                            ;; the largest tick-delta is allowed to be
  membrane-list                             ;; list of membrane locations during a model run, for computing average
]

breed [solutes solute]
breed [solvents solvent]
breed [membranes membrane]

turtles-own [
  speed
  mass
  energy
  last-collision
  old-pos
  new-pos
  stick-count                              ;; counter for solutes that are stuck to solvents
  linked?                                  ;; flag for solvents stating whether or not they are stuck
]

to setup
  clear-all
  set-default-shape solutes "circle"
  set-default-shape solvents "circle"
  set-default-shape membranes "square"
  set max-tick-delta 0.1073
  create-container
  spawn-particles
  set split 0
  set membrane-list [0]
  calculate-wall
  reset-ticks
end

to create-container
  ask patches with [pycor = max-pycor or pycor = min-pycor] [              ;; sets the walls of the container
    set pcolor blue
  ]
  ask patches with [pxcor = max-pxcor or pxcor = min-pxcor] [
    set pcolor blue
  ]
  set left-side patches with [pxcor < 0]                                   ;; defines the left and right sides of the container equally
  set right-side patches with [pxcor > 0]
  set equilibrium 0                                                        ;; sets equilibrium to starting value (the middle of the container)
  set split 0                                                              ;; sets the starting location of the membrane
  ask patches with [pxcor = 0 and pycor != max-pycor and pycor != min-pycor and abs pycor mod 2 != 0] [
    sprout-membranes 1 [                                                   ;; create the membrane
      set color red
      set size 1.3
    ]
  ]
end

to setup-particles                                                      ;; set variable values for each new particle
  set speed 10
  set mass 1
  set energy (0.5 * mass * speed * speed)
  if breed = solutes [
    set stick-count 0
    set size 1.3
  ]
  set heading random 360
  set linked? false
  set last-collision nobody
end

;; Osmotic pressure is a colligative property, meaning the number of particles matter more than the identity of the particles.
;; So when spawning particles, we have to take into account whether or not particles dissociate (break up into ions) in the solvent.
;; Covalent compounds, such as sugar, do not break up, while ionic compounds, such as sodium chloride do.  Therefore, when we create 10 solute
;; particles of sugar, 10 solute particles are created.  However, when we create 10 solute particles of sodium chloride, the particles break up into
;; sodium and chloride ions -- so for every one particle of sodium chloride, we get 2 particles of ions (in the model, these still retain the "solute"
;; breed).  Magnesium chloride breaks up into one magnesium ion, and two chloride ions (so 1 magnesium chloride gets you 3 ion particles),
;; and aluminum chloride breaks up into one aluminum ion, and three chloride ions (so 1 aluminum chloride gets you 4 ion particles).
;;
;; In the code below, this is accomplished by creating solute particles based on the slider value, and then "hatching" new solute particles based on
;; the number of ions the compound forms.  So for sodium chloride, we create the number of particles indicated by the slider, and then each solute
;; spawns an extra solute particle to make a total of two ion particles for each solute particle added.

to spawn-particles
  create-solvents 1000 [                                               ;; creates 1000 solvent molecules
    set color blue + 2
    setup-particles
    move-to one-of patches with [pcolor = black]                       ;; randomly distribute them throughout the world
    while [any? other turtles-here] [
      move-to one-of patches with [pcolor = black]
    ]
  ]

  if solute-type = "Sugar" [                       ;; checks to see the identity of the solute based on the chooser
    output-type "C12H22O11"                        ;; write the chemical formula in the output area
    create-solutes-and-ions 1                      ;; since sugar is covalent and it does not break into ions in solvent, one molecule is formed
  ]

  if solute-type = "Sodium Chloride" [
    output-type "NaCl"
    create-solutes-and-ions 2                      ;; Sodium Chloride breaks up into Na+ and Cl- ions, so two ions are formed
  ]

  if solute-type = "Magnesium Chloride" [
    output-type "MgCl2"
    create-solutes-and-ions 3                      ;; Magnesium Chloride breaks up into Mg2+ and two Cl- ions, so three ions are formed
  ]

  if solute-type = "Aluminum Chloride" [
    output-type "AlCl3"
    create-solutes-and-ions 4                      ;; Aluminum Chloride breaks up into Al3+ and three Cl- ions, so four ions are formed
  ]
end

to create-solutes-and-ions [ions]
  create-solutes solute-left [                              ;; create the number of particles on the left indicated by the slider
      set color white
      setup-particles
      move-to one-of left-side with [pcolor = black]        ;; move to an open space on the left side
      while [any? other turtles-here] [
        move-to one-of left-side with [pcolor = black] ]
      hatch-solutes (ions - 1) [                            ;; since one particle was already created above,
        set color white                                     ;; we hatch 1 less than the total number of ions the substance has
        setup-particles
        fd 0.2                                              ;; move forward a bit so we can see the particles better
      ]
    ]
    create-solutes solute-right [                           ;; create the number of particles on the right indicated by the slider
      set color white
      setup-particles
      move-to one-of right-side with [pcolor = black]       ;; move to an open space on the right side
      while [any? other turtles-here] [
        move-to one-of right-side with [pcolor = black] ]
      hatch-solutes (ions - 1) [
        set color white
        setup-particles
        fd 0.2
      ]
    ]
end

to-report particles
  report (turtle-set solutes solvents)
end

to particle-jump
  ask solutes with [xcor >= pre-split and xcor <= split] [       ;; check for solutes in the way of a membrane jump
    set heading 90                                                                           ;; turn proper direction and jump
    jump (split - pre-split) + 1
  ]
  ask solutes with [xcor <= pre-split and xcor >= split] [
    set heading 270
    jump (pre-split - split) + 1
  ]
end

to calculate-wall
  set pre-split split                                                  ;; save location of the membrane before it moves
  let nudge ((equilibrium * -1) / count solvents) * 50                 ;; calculates the amount to move the membrane - based on fraction of solvents passing
  set split split + nudge                                              ;; set split to be the new location of the membrane
  particle-jump                                                        ;; move solutes in the way of the membrane jump
  ask membranes [
    set xcor split                                                     ;; move membrane turtles according to nudge value
  ]

  set left-side patches with [pxcor < split]                           ;; redefine right and left sides
  set right-side patches with [pxcor > split]
  set membrane-list lput precision split 2 membrane-list
  set equilibrium 0                                                    ;; reset equilibrium so we can keep track of what happens during the next tick
end

to go
  if count turtles-on right-side = 0 or count turtles-on left-side = 0 [                    ;; stops model if membrane reaches either edge
    user-message "The membrane has burst! Make sure you have some solute on both sides!"
    stop
  ]
  ask particles [ set old-pos xcor ]                            ;; saves starting position of particles
  ask particles [ bounce ]                                      ;; all particles bounce off of walls and solutes bounce off of the membrane
  ask particles with [ linked? = false ] [ move ]               ;; only particles not linked should move -- these are "unstuck" particles
  ask links [ check-for-release ]                               ;; links have a chance of dying -- stuck particles have a chance of getting free
  ask particles [ check-for-collision ]                         ;; particles bounce off of each other
  ask solvents [ check-for-stick ]                              ;; solvent particles can stick to solute molecules

  ask solvents [
    if old-pos < split and xcor >= split [                      ;; if a solvent moves from the left of the membrane to the right of the membrane
      set equilibrium equilibrium + 1                           ;; add one to equilibrium
    ]
    if old-pos > split and xcor <= split [                      ;; if a solvent moves from the right of the membrane to the left of the membrane
      set equilibrium equilibrium - 1                           ;; subtract one from equilibrium
    ]
  ]
  tick-advance tick-delta
  update-plots
  calculate-tick-delta
  display
  calculate-wall                                                ;; recalculate the new location of the wall
end

to calculate-tick-delta
  ;; tick-delta is calculated in such way that even the fastest
  ;; particle will jump at most 1 patch length when we advance the
  ;; tick counter. As particles jump (speed * tick-delta) each time, making
  ;; tick-delta the inverse of the speed of the fastest particle
  ;; (1/max speed) assures that. Having each particle advance at most
  ;; one patch-length is necessary for it not to "jump over" a wall
  ;; or another particle.
  ifelse any? particles with [speed > 0]
    [ set tick-delta min list (1 / (ceiling max [speed] of particles)) max-tick-delta ]
    [ set tick-delta max-tick-delta ]
end

to bounce  ;; particle procedure
  ;; get the coordinates of the patch we'll be on if we go forward 1
  let new-patch patch-ahead 1
  let new-px [pxcor] of new-patch
  let new-py [pycor] of new-patch

  ;; if hitting the membrane...
  if any? membranes in-cone 3 180 and breed = solutes
    [ set heading (- heading) ]

  ;; if we're not about to hit a wall, we don't need to do any further checks
  if not shade-of? blue [pcolor] of new-patch
    [ stop ]

  ;; if hitting left or right wall, reflect heading around x axis
  if (abs new-px = max-pxcor) or (abs new-px = min-pxcor)
    [ set heading (- heading) ]
  ;; if hitting top or bottom wall, reflect heading around y axis
  if (abs new-py = max-pycor) or (abs new-py = min-pycor)
    [ set heading (180 - heading)]
end

to move  ;; particle procedure
  if patch-ahead (speed * tick-delta) != patch-here
    [ set last-collision nobody ]
  jump (speed * tick-delta)
end

to check-for-release
  ;; there is a 2% chance that a stuck particle will become unstuck
  if random 100 <= 2 [
    ask end1 [
      set stick-count stick-count - 1                                   ;; lower the stick counter of the solute
    ]
    ask end2 [
      if [pcolor] of patch-here = blue [
        face one-of in-link-neighbors
        fd 1
      ]
      set linked? false                                                 ;; set the solvent's flag to "unstuck"
      set color color + 2                                               ;; return the color to normal
    ]
    die
  ]
end

to check-for-collision  ;; particle procedure
  ;; Here we impose a rule that collisions only take place when there
  ;; are exactly two particles per patch.  We do this because we want them to
  ;; form a uniform wavefront.
  ;;
  ;; Why do we want a uniform wavefront?  Because it is actually more
  ;; realistic.
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

  if (count other turtles-here with [breed != membranes] = 1)
  [
    ;; the following conditions are imposed on collision candidates:
    ;;   1. they must have a lower who number than my own, because collision
    ;;      code is asymmetrical: it must always happen from the point of view
    ;;      of just one particle.
    ;;   2. they must not be the same particle that we last collided with on
    ;;      this patch, so that we have a chance to leave the patch after we've
    ;;      collided with someone.
    let candidate one-of other turtles-here with [breed != membranes and who < [who] of myself and myself != last-collision]
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
;; THIS IS THE HEART OF THE PARTICLE SIMULATION, AND YOU ARE STRONGLY ADVISED
;; NOT TO CHANGE IT UNLESS YOU REALLY UNDERSTAND WHAT YOU'RE DOING!
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

to check-for-stick ;; solvent procedure
  ;; The stick code is similar to the collision code.
  ;; If there are more than one particles on the same patch,
  ;; and the solvent isn't already stuck to another particle,
  ;; the two particles have a chance to stick.
  if (count other turtles-here with [breed != membranes] = 1) and (linked? = false)
  [
    ;; the stick candidate must be a solute and not already be stuck to too many solvents
    let candidate one-of other solutes-here with [stick-count < 5]
    ;; we also only stick if one of us has non-zero speed
    ;; there is a 50% chance to stick
    if (candidate != nobody) and (speed > 0 or [speed] of candidate > 0) and (random 100 <= 50)
    [
      ask candidate [
        create-link-to myself [
          tie
          hide-link
        ]
        set stick-count stick-count + 1                                    ;; keep a running total of how many solvents are stuck
      ]
      set linked? true                                                     ;; flag the solvent as "stuck"
      set color color - 2                                                  ;; tweak the color so we can see it's stuck
    ]
  ]
end


; Copyright 2012 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
275
30
1091
367
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
-50
50
-20
20
1
1
1
ticks
30.0

BUTTON
20
10
85
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
90
10
155
43
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

CHOOSER
20
50
155
95
solute-type
solute-type
"Sugar" "Sodium Chloride" "Magnesium Chloride" "Aluminum Chloride"
0

SLIDER
20
100
145
133
solute-left
solute-left
1
100
100.0
1
1
NIL
HORIZONTAL

OUTPUT
160
50
270
95
12

MONITOR
20
140
100
185
Water # Left
count solvents with [pxcor < split]
0
1
11

MONITOR
180
140
265
185
Water # Right
count solvents with [pxcor > split]
0
1
11

PLOT
20
290
265
420
Water#
Ticks
Amount
0.0
10.0
50.0
150.0
true
true
"" ""
PENS
"left" 1.0 0 -16777216 true "" "plotxy ticks count solvents with [pxcor < split]"
"right" 1.0 0 -2674135 true "" "plotxy ticks count solvents with [pxcor > split]"

SLIDER
145
100
270
133
solute-right
solute-right
1
100
25.0
1
1
NIL
HORIZONTAL

MONITOR
105
165
175
210
Membrane
split
2
1
11

MONITOR
20
190
100
235
Solute # Left
count solutes with [pxcor < split]
17
1
11

MONITOR
180
190
265
235
Solute # Right
count solutes with [pxcor > split]
17
1
11

MONITOR
20
240
100
285
Stuck Left
count particles with [xcor < split and linked? = true]
0
1
11

MONITOR
180
240
265
285
Stuck Right
count particles with [xcor > split and linked? = true]
0
1
11

MONITOR
105
215
175
260
Average
mean membrane-list
2
1
11

@#$#@#$#@
## WHAT IS IT?

Osmotic pressure is generally defined as the amount of pressure required to bring solvent movement across a semipermeable membrane to equilibrium. This model attempts to model an agent-based description of the movement of solution particles across a semipermeable membrane and illustrate the colligative nature of osmotic pressure.

Osmotic pressure is a colligative property of a solution, meaning the number of particles matter more than the identity of the particles. Because adding pressure to the solution on one side of the membrane changes the rate at which the solvent passes through the membrane (a rate that is restricted by the presence of solute particles), osmotic pressure can be thought of as a measurement of the tendency of a solute to restrict osmosis. As a colligative property, changes in osmotic pressure are proportional to the number of solute particles, not the identity of the particles.  The colligative nature of osmotic pressure can be explored in this model by experimenting with different types and number of solute particles.

## HOW IT WORKS

In this model, blue patches represent a container divided by a semipermeable membrane (the red squares) -- a physical, porous barrier separating two solutions that allows some particles to pass but not others. Blue circles represent solvent molecules (water in this model) that can pass freely through the membrane. At setup, 1000 of these solvent molecules are created and randomly distributed throughout the container.  White circles represent particles of added solute. The amount of solute defined by the sliders is placed on the appropriate side of the membrane. If a solute is an ionic compound, it breaks apart into the appropriate number of ions.  If the solute is covalent, the compound does not break apart. Solute particles cannot pass through the membrane.

As the model runs, particles move through the container according to kinetic molecular theory using NetLogo code first defined in the GasLab suite of models.  All particles move in a straight line until they collide with another particle, the wall, or the membrane (only solute particles collide with the membrane). Particles collide with one another in an elastic collision. While solvent molecules (water represented by the blue circles) may pass through the membrane freely, solute particles (white circles) are restricted to the side they are created on. In addition, at each step solvent molecules have a 50% chance to "stick" to solute molecules occupying the same patch (solute particles can hold a maximum of five solvent molecules). "Stuck" molecules have a 2% chance to become unstuck at each step of the model. In this model, changes in volume for each side occur through the movement of the membrane.

At each tick, the membrane moves according to the difference in the number of solvent molecules moving from left to right and those moving from right to left. As the model progresses, according to the phenomenon of osmosis, the solvent (water) shows a net movement towards the side of higher solute concentration.

## HOW TO USE IT

###Initial settings

**SOLUTE:** Choose the solute to add to the solution.  The chemical formula of the solute will be printed in the output box to the right.  Each solute will act differently in solution depending on its bonding behavior.
**SOLUTE-LEFT:** This number will determine the number of solute particles added to the solution on the left side of the membrane.  Keep in mind, due to various bonding behaviors, the total number of dissolved particles may be different from this value.
**SOLUTE-RIGHT:** This number will determine the number of solute particles added to the solution on the right side of the membrane.  Keep in mind, due to various bonding behaviors, the total number of dissolved particles may be different from this value.

###Buttons

**SETUP:** Sets up the model
**GO:** Runs the model

###Monitors

**WATER # LEFT:** Shows the number of solvent particles on the left side of the membrane.
**WATER # RIGHT:** Shows the number of solvent particles on the right side of the membrane.
**SOLUTE LEFT:** Shows the number of solute particles on the left side of the membrane.
**SOLUTE RIGHT:** Shows the number of solute particles on the right side of the membrane.
**STUCK LEFT:** Shows the number of solvent particles currently stuck to solute particles on the left side of the membrane
**STUCK RIGHT:** Shows the number of solvent particles currently stuck to solute particles on the right side of the membrane
**MEMBRANE:** Shows the x-cor of the membrane. Note: The membrane moves based on the difference between the amount of particles moving across the membrane in a given direction each step.
**AVERAGE:** Shows mean of the membrane location over the entire model run.

###Plot

**WATER #:** Plots the number of solvent particles on the left and right side of the membrane over time (ticks).

## THINGS TO NOTICE

As the model runs, more solvent particles should end up on the side of the membrane with more solute particles. Because more solvent particles are free to move on the side with fewer solute particles, they are more likely to cross the membrane.

How does the membrane movement change when adding different solutes? Is there a pattern?
What happens when adding Sodium Chloride?  How is this different from adding Sugar?

## THINGS TO TRY

Try adding different solutes.  Can you get a change in the number of solute particles so that Sodium Chloride acts like Sugar?
Is there a mathematical relationship between membrane movement and the number of solute particles. Will this relationship depend on the type of solute added?  Why or why not?

## EXTENDING THE MODEL

Try making new solutes.

There are at least two other common proposals for an agent-based explanations for the process of osmosis.

 1. Solute particles "block" solvent particles from moving across the membrane. Solvent particles will then show a net movement from a side of fewer solute particles (because there are less solute particles blocking their path) to a side with more solvent particles.
 2. Solute particles are generally larger than solvent particles (usually water). The size of the solute particles leads to frequent collisions of solvent-solute particles. On the side with more solute particles, the mean free path of solvent particles will be lower, leading to a net movement of particles from the low solute side.

Can you model these alternate explanations?

## NETLOGO FEATURES

Fixed length links are simulated by first tying particles together, then applying motion rules to only the solute particles.

## RELATED MODELS

GasLab suite

## CREDITS AND REFERENCES

We thank Luis Amaral for his scientific consultation.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Holbert, N. and Wilensky, U. (2012).  NetLogo Osmotic Pressure model.  http://ccl.northwestern.edu/netlogo/models/OsmoticPressure.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2012 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2012 Cite: Holbert, N. -->
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
