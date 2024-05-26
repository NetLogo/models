globals [
  tick-delta                        ; how much we advance the tick counter this time through
  max-tick-delta                    ; the largest tick-delta is allowed to be
  init-avg-speed init-avg-energy    ; initial averages
  avg-speed avg-energy              ; current average
  avg-energy-green                  ; average energy of green particles (used to calculate the temperature)
  avg-energy-orange                 ; average energy of orange particles (used to calculate the temperature)
  avg-energy-purple                 ; average energy of purple (violet) particles (used to calculate the temperature)
  toggle-red-state                  ; keeps track of whether the toggle red wall button was pressed (and whether these walls are open or closed)
  toggle-blue-state                 ; keeps track of whether the toggle blue wall button was pressed (and whether these walls are open or closed)
  particles-to-add                  ; number of particles to add when using the mouse / cursor to add particles
  min-particle-energy
  max-particle-energy
  particle-size
  plunger-move
  plunger-up-force
  plunger-up-forces
  plunger-down-force
  plunger-down-forces

  syringe-left-x
  syringe-right-x
  syringe-top-y
  syringe-bottom-y

  syringe-region
  syringe-border
  syringe-upper
  syringe-lower

  plunger-move-factor
  plunger-plot-start
  p-force-plot-start

  area-measurement
  region1
  region-one-seed
  r1-upper
  r1-lower
  region2
  region-two-seed
  r2-upper
  r2-lower
  region-one-volume
  region-two-volume
  particles-on-1
  particles-on-2

  initial-#-particles
  initial-gas-temperature

  experiment-plunger-start-line
  experiment-running?
  experiment-stop-time

  root-url-for-export
  last-saved-filename

  last-temperature
]

breed [ particles particle ]
breed [ walls wall ]


breed [ plungers plunger ]
breed [ forces force ]
breed [ flashes flash ]
breed [ erasers eraser ]
breed [ arrowheads arrowhead ]


erasers-own [ pressure? ]
flashes-own [ birthday ]

forces-own [ my-plunger my-f ]

particles-own [
  speed mass energy          ; particles info
  last-collision
  color-type                 ; type of particle (green, orange, purple)
]

walls-own [
  energy
  valve-1?
  valve-2?
  pressure?
  surface-energy
]

to startup
  setup
end

to setup
  clear-all

  set last-saved-filename ""
  set initial-#-particles 100
  set initial-gas-temperature gas-temperature * 10
  set last-temperature gas-temperature

  set plunger-move 0
  set plunger-up-force 0
  set plunger-down-force 0
  set plunger-plot-start 0
  set p-force-plot-start 0
  set plunger-up-forces [ 0 ]
  set plunger-down-forces [ 0 ]
  set particle-size 1.0
  set max-tick-delta 0.02
  set particles-to-add 2
  set-default-shape flashes "square"
  set-default-shape walls "wall"
  set-default-shape erasers "eraser"
  set-default-shape arrowheads "default"


  set-default-shape plungers "wall"

  set min-particle-energy 0
  set max-particle-energy 10000

  create-erasers 1 [set hidden? true set pressure? true set size 3 set color white]

  make-box



  ask particles [ update-particle-speed-visualization ]

  set init-avg-speed avg-speed
  set init-avg-energy avg-energy

  update-variables

  set region1 no-patches
  set region2 no-patches
  set region-one-seed no-patches
  set region-two-seed no-patches
  set r1-upper false
  set r2-upper false
  set r1-lower false
  set r2-lower false
  set syringe-region no-patches
  set syringe-border no-patches
  set syringe-upper no-patches
  set syringe-lower no-patches
  set syringe-left-x -24
  set syringe-right-x -4
  set syringe-top-y  25
  set syringe-bottom-y -25

  set plunger-move-factor .5 ; 0.01  now that we are multiplying by tick-advance, which is at normal temps approx .02

  setup-syringe


  create-particles 30 [
    setup-particles
    move-to one-of syringe-region with [not any? other particles-here and pycor < 0 ]
  ]

  reset-ticks
end


to go

  if last-temperature != gas-temperature [
    ask particles [
      ifelse gas-temperature = 0 [ set energy 5 ][ set energy gas-temperature * 10 ] ;jamie - 0 temp should not be abs zero
      set speed speed-from-energy
    ]
    set last-temperature gas-temperature
  ]

  ;FOR TEMP visualization
  ask walls with [
      pycor = syringe-bottom-y - 1
     and pxcor > syringe-left-x + 1
     and pxcor < syringe-right-x - 1
  ][
    let redness gas-temperature * 2.5
    set color (list redness 0 (250 - redness))
  ]

  ;FOR SYRINGE --plunger-move is the amount that the plunger will move when this "turn" is up.
  set plunger-move -0.14
  set plunger-up-force 0
  set plunger-down-force 0

  mouse-action
  ask particles [ bounce ]
  ask particles [ move ]
  ask particles [ check-for-collision ]
  ask particles with [any? walls-here] [ rewind-to-bounce ]
  ask particles with [any? walls-here] [ remove-from-walls ]

  tick-advance tick-delta
  calculate-tick-delta

  ask flashes [ update-flash-visualization ]
  ask particles [ update-particle-speed-visualization ]

  update-variables
  update-plots

  ;FOR SYRINGE
  if any? plungers [ move-plunger ]
  display
end


to update-variables
  if any? particles [
    set avg-speed  mean [speed] of particles
    set avg-energy mean [energy] of particles
  ]
  if any? particles with [color-type = green] [
    set avg-energy-green mean [energy] of particles with [color-type = green]
  ]
  if any? particles with [color-type = orange] [
    set avg-energy-orange mean [energy] of particles with [color-type = orange]
  ]
  if any? particles with [color-type = violet] [
    set avg-energy-purple mean [energy] of particles with [color-type = violet]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;WALL INTERACTION;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to toggle-red-wall
  ifelse toggle-red-state = "closed" [
    ask walls with [valve-1?] [ set hidden? true ]
    set toggle-red-state "open"
  ] [
    ask walls with [valve-1?] [ set hidden? false ]
    set toggle-red-state "closed"
  ]

  ;need to recalculate measured regions if there were any red walls
  if any? walls with [valve-1?] [
   if any? region1 [ ask region-one-seed  [ rebuild-region-one ] ]
   if any? region2 [ ask region-two-seed  [ rebuild-region-two ] ]
  ]
end

to toggle-blue-wall
  ifelse toggle-blue-state = "closed" [
    ask walls with [valve-2?] [ set hidden? true ]
    set toggle-blue-state "open"
  ][
    ask walls with [valve-2?] [ set hidden? false ]
    set toggle-blue-state "closed"
  ]

  ;need to recalculate measured regions if there were any blue walls
  if any? walls with [valve-2?] [
   if any? region1 [ ask region-one-seed [ rebuild-region-one ] ]
   if any? region2 [ ask region-two-seed [ rebuild-region-two ] ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;GAS MOLECULES MOVEMENT;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to bounce
  let this-patch patch-here
  let new-px 0
  let new-py 0
  let hit-angle 0
  let hit-plunger-angle 0
  let visible-wall nobody
  ; NEW FOR SYRINGE
  let visible-plunger nobody
  ; get the coordinates of the patch we'll be on if we go forward 1
  let bounce-patch  min-one-of walls in-cone ((sqrt (2)) / 2) 180 with [myself != this-patch] [distance myself ]

  ; NEW FOR SYRINGE
  ;let bounce-syringe-patch min-one-of plungers in-cone ((sqrt (2)) / 2) 180 with [myself != this-patch] [distance myself ]
  let bounce-syringe min-one-of plungers in-cone ((sqrt (2)) / 2) 180  [distance myself ]

  if bounce-patch != nobody [
    set new-px [pxcor] of bounce-patch
    set new-py [pycor] of bounce-patch
    set visible-wall walls-on bounce-patch

    if any? visible-wall with [not hidden?] and distance bounce-patch != 0 [
      set hit-angle towards bounce-patch
      ifelse (hit-angle <= 135 and hit-angle >= 45) or (hit-angle <= 315 and hit-angle >= 225) [
        set heading (- heading)
      ][
        set heading (180 - heading)
      ]
    ]
  ]

  ; NEW FOR SYRINGE
  if bounce-syringe != nobody [
    set new-px [xcor] of bounce-syringe
    set new-py [ycor] of bounce-syringe

    if distancexy new-px new-py != 0 [
      let delta-y ((  (cos heading) * speed ) * plunger-move-factor)
      set plunger-move plunger-move + delta-y
      ifelse (delta-y > 0) [
        set plunger-up-force plunger-up-force + delta-y
      ][
        set plunger-down-force plunger-down-force + delta-y
      ]


      set heading (180 - heading)
    ]
  ]
end


to move-plunger
  ask forces [ set plunger-move plunger-move + my-f ]
  ; the plunger-move value is based on a tick
  ; since we're moving at fractions of ticks, we need to multiply by tick-delta
  set plunger-move plunger-move * tick-delta
  set plunger-up-forces lput plunger-up-force plunger-up-forces
  set plunger-down-forces lput plunger-down-force plunger-down-forces
  if length plunger-up-forces > 200 [ set plunger-up-forces butfirst plunger-up-forces ]
  if length plunger-down-forces > 200 [ set plunger-down-forces butfirst plunger-down-forces ]

  if plunger-move != 0 [
    let oy [ycor] of one-of plungers
    let py oy + plunger-move

    ifelse plunger-move > 0 [
      if py < syringe-top-y - 1 [
        ask particles with [
          xcor > syringe-left-x  and
          xcor < syringe-right-x and
          (abs(ycor - oy) + abs(py - ycor) = abs(py - oy))
        ][
          set ycor py + .5
        ]
        ask plungers [ set ycor py ]
      ]
    ][
      if py > syringe-bottom-y + 1 [
       ask particles with [
          xcor > syringe-left-x  and
          xcor < syringe-right-x and
          (abs(ycor - oy) + abs(py - ycor) = abs(py - oy))
        ][
          set ycor py - .5
        ]
        ask plungers [ set ycor py ]
      ]
    ]
  ]

  ask forces [
   ifelse my-f > 0 [
    set ycor [ycor] of my-plunger - .5
   ][
     set ycor [ycor] of my-plunger + .5
   ]
  ]

  set region1 (region1 with [ not member? self syringe-region ])
  set region2 (region2 with [ not member? self syringe-region ])
  let key-y round [ycor] of one-of plungers
  if (r1-upper ) [ set region1 (patch-set region1 (syringe-region with [ pycor > key-y ])) ]
  if (r1-lower ) [ set region1 (patch-set region1 (syringe-region with [ pycor < key-y ])) ]
  if (r2-upper ) [ set region2 (patch-set region2 (syringe-region with [ pycor > key-y ])) ]
  if (r2-lower ) [ set region2 (patch-set region2 (syringe-region with [ pycor < key-y ])) ]

  set region-one-volume count region1 * 10
  set region-two-volume count region2 * 10
  set particles-on-1 count particles-on region1
  set particles-on-2 count particles-on region2
end



to rewind-to-bounce  ; particles procedure
  ; attempts to deal with particle penetration by rewinding the particle path back to a point
  ; where it is about to hit a wall
  ; the particle path is reversed 49% of the previous tick-delta it made,
  ; then particle collision with the wall is detected again.
  ; and the particle bounces off the wall using the remaining 51% of the tick-delta.
  ; this use of slightly more of the tick-delta for forward motion off the wall, helps
  ; insure the particle doesn't get stuck inside the wall on the bounce.

  let bounce-patch nobody

  ; FOR SYRINGE
  let bounce-patch-syringe nobody

  let hit-angle 0
  let this-patch nobody
  let new-px 0
  let new-py 0
  let visible-wall nobody
  let visible-plunger nobody

  back (speed) * tick-delta * .49
  set this-patch  patch-here

  set bounce-patch min-one-of walls in-cone ((sqrt (2)) / 2) 180 with [self != this-patch] [distance myself ]
  set bounce-patch-syringe  min-one-of plungers in-cone ((sqrt (2)) / 2) 180 with [self != this-patch] [distance myself ]

  if bounce-patch != nobody [
    set new-px [pxcor] of bounce-patch
    set new-py [pycor] of bounce-patch
    set visible-wall walls-on bounce-patch

    if any? visible-wall with [not hidden?] and distance bounce-patch != 0 [
      set hit-angle towards bounce-patch

      ifelse (hit-angle <= 135 and hit-angle >= 45) or (hit-angle <= 315 and hit-angle >= 225) [
        set heading (- heading)
      ][
        set heading (180 - heading)
      ]

;      if show-wall-hits? [
;        ask patch new-px new-py [
;          sprout-flashes 1 [
;            set color gray - 2
;            set birthday ticks
;          ]
;        ]
;      ]
    ]
  ]

  if bounce-patch-syringe != nobody [
    set new-px [pxcor] of bounce-patch-syringe
    set new-py [pycor] of bounce-patch-syringe
    set visible-plunger plungers-on bounce-patch-syringe

    if any? visible-plunger and distance bounce-patch-syringe != 0 [
      set hit-angle towards bounce-patch-syringe

      ifelse (hit-angle <= 135 and hit-angle >= 45) or (hit-angle <= 315 and hit-angle >= 225) [
        set heading (- heading)
      ][
        set heading (180 - heading)
      ]
    ]
  ]
  fd (speed) * tick-delta * .51
end


to move  ; particles procedure
  if patch-ahead (speed * tick-delta) != patch-here [ set last-collision nobody ]
  jump (speed * tick-delta)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;GAS MOLECULES COLLISIONS;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;from GasLab

to calculate-tick-delta
  ; tick-delta is calculated in such way that even the fastest
  ; particles will jump at most 1 patch delta in a ticks tick. As
  ; particles jump (speed * tick-delta) at every ticks tick, making
  ; tick delta the inverse of the speed of the fastest particles
  ; (1/max speed) assures that. Having each particles advance at most
  ; one patch-delta is necessary for it not to "jump over" a wall
  ; or another particles.
  ifelse any? particles with [speed > 0] [
    set tick-delta min list (1 / (ceiling max [speed] of particles )) max-tick-delta
  ][
    set tick-delta max-tick-delta
  ]
end


to check-for-collision  ; particles procedure
  ; Here we impose a rule that collisions only take place when there
  ; are exactly two particles per patch.  We do this because when the
  ; student introduces new particles from the side, we want them to
  ; form a uniform wavefront.
  ;
  ; Why do we want a uniform wavefront?  Because it is actually more
  ; realistic.  (And also because the curriculum uses the uniform
  ; wavefront to help teach the relationship between particles collisions,
  ; wall hits, and pressure.)
  ;
  ; Why is it realistic to assume a uniform wavefront?  Because in reality,
  ; whether a collision takes place would depend on the actual headings
  ; of the particles, not merely on their proximity.  Since the particles
  ; in the wavefront have identical speeds and near-identical headings,
  ; in reality they would not collide.  So even though the two-particles
  ; rule is not itself realistic, it produces a realistic result.  Also,
  ; unless the number of particles is extremely large, it is very rare
  ; for three or  particles to land on the same patch (for example,
  ; with 400 particles it happens less than 1% of the time).  So imposing
  ; this additional rule should have only a negligible effect on the
  ; aggregate behavior of the system.
  ;
  ; Why does this rule produce a uniform wavefront?  The particles all
  ; start out on the same patch, which means that without the only-two
  ; rule, they would all start colliding with each other immediately,
  ; resulting in much random variation of speeds and headings.  With
  ; the only-two rule, they are prevented from colliding with each other
  ; until they have spread out a lot.  (And in fact, if you observe
  ; the wavefront closely, you will see that it is not completely smooth,
  ; because  collisions eventually do start occurring when it thins out while fanning.)

  if count  other particles-here  in-radius 1 = 1 [
    ; the following conditions are imposed on collision candidates:
    ;   1. they must have a lower who number than my own, because collision
    ;      code is asymmetrical: it must always happen from the point of view
    ;      of just one particles.
    ;   2. they must not be the same particles that we last collided with on
    ;      this patch, so that we have a chance to leave the patch after we've
    ;      collided with someone.
    let candidate one-of other particles-here with [who < [who] of myself and myself != last-collision]
    ; we also only collide if one of us has non-zero speed. It's useless
    ; (and incorrect, actually) for two particles with zero speed to collide.
    if (candidate != nobody) and (speed > 0 or [speed] of candidate > 0) [
      collide-with candidate
      set last-collision candidate
      ask candidate [ set last-collision myself ]
    ]
  ]
end

; implements a collision with another particles.
;
; THIS IS THE HEART OF THE particles SIMULATION, AND YOU ARE STRONGLY ADVISED
; NOT TO CHANGE IT UNLESS YOU REALLY UNDERSTAND WHAT YOU'RE DOING!
;
; The two particles colliding are self and other-particles, and while the
; collision is performed from the point of view of self, both particles are
; modified to reflect its effects. This is somewhat complicated, so I'll
; give a general outline here:
;   1. Do initial setup, and determine the heading between particles centers
;      (call it theta).
;   2. Convert the representation of the velocity of each particles from
;      speed/heading to a theta-based vector whose first component is the
;      particle's speed along theta, and whose second component is the speed
;      perpendicular to theta.
;   3. Modify the velocity vectors to reflect the effects of the collision.
;      This involves:
;        a. computing the velocity of the center of mass of the whole system
;           along direction theta
;        b. updating the along-theta components of the two velocity vectors.
;   4. Convert from the theta-based vector representation of velocity back to
;      the usual speed/heading representation for each particles.
;   5. Perform final cleanup and update derived quantities.
to collide-with [ other-particles ] ; particles procedure
  ;; PHASE 1: initial setup

  ; for convenience, grab  quantities from other-particles
  let mass2 [mass] of other-particles
  let speed2 [speed] of other-particles
  let heading2 [heading] of other-particles

  ; since particles are modeled as zero-size points, theta isn't meaningfully
  ; defined. we can assign it randomly without affecting the model's outcome.
  let theta (random-float 360)

  ;; PHASE 2: convert velocities to theta-based vector representation

  ; now convert my velocity from speed/heading representation to components
  ; along theta and perpendicular to theta
  let v1t (speed * cos (theta - heading))
  let v1l (speed * sin (theta - heading))

  ; do the same for other-particles
  let v2t (speed2 * cos (theta - heading2))
  let v2l (speed2 * sin (theta - heading2))

  ;; PHASE 3: manipulate vectors to implement collision

  ; compute the velocity of the system's center of mass along theta
  let vcm (((mass * v1t) + (mass2 * v2t)) / (mass + mass2) )

  ; now compute the new velocity for each particles along direction theta.
  ; velocity perpendicular to theta is unaffected by a collision along theta,
  ; so the next two lines actually implement the collision itself, in the
  ; sense that the effects of the collision are exactly the following changes
  ; in particles velocity.
  set v1t (2 * vcm - v1t)
  set v2t (2 * vcm - v2t)

  ;; PHASE 4: convert back to normal speed/heading

  ; now convert my velocity vector into my new speed and heading
  set speed sqrt ((v1t ^ 2) + (v1l ^ 2))
  set energy (0.5 * mass * speed ^ 2)
  ; if the magnitude of the velocity vector is 0, atan is undefined. but
  ; speed will be 0, so heading is irrelevant anyway. therefore, in that
  ; case we'll just leave it unmodified.
  if v1l != 0 or v1t != 0 [ set heading (theta - (atan v1l v1t)) ]

  ; and do the same for other-particle
  ask other-particles [
    set speed sqrt ((v2t ^ 2) + (v2l ^ 2))
    set energy (0.5 * mass * (speed ^ 2))
    if v2l != 0 or v2t != 0 [ set heading (theta - (atan v2l v2t)) ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;  mouse interaction procedures ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to mouse-action
  let snap-xcor 0
  let snap-ycor 0
  let orig-xcor 0
  let orig-ycor 0
  let eraser-window-walls nobody
  let eraser-window-particles nobody
  set orig-xcor mouse-xcor
  set orig-ycor mouse-ycor
  set snap-xcor round orig-xcor
  set snap-ycor round orig-ycor

  if mouse-inside? [

    ask erasers [
      if mouse-inside? [ setxy orig-xcor orig-ycor ]
      ifelse mouse-down? [
        set color [225 225 255 225]
      ][
        set color [225 225 255 150]
      ]
      if mouse-inside? [
        set shape "none"
;        if mouse-interaction = "speed up particles" or mouse-interaction = "slow down particles" [
;          ask erasers [ set shape "spray paint" ]
;        ]
      ]
      set hidden? not mouse-inside?
    ]

    if mouse-down? [
      ask patches with [pxcor = snap-xcor and pycor = snap-ycor] [
        set eraser-window-walls walls-on neighbors
        set eraser-window-walls eraser-window-walls with [not pressure?]
        set eraser-window-particles particles-on neighbors


        ;;; addition of particles by mouse / cursor actions ;;;;
;        if mouse-interaction = "add purple particles" or mouse-interaction = "add green particles" or mouse-interaction = "add orange particles" [
;          sprout particles-to-add [
;            setup-particles
;            jump random-float 2
;            if mouse-interaction = "add purple particles" [ set color-type violet color-particle-and-link ]
;            if mouse-interaction = "add orange particles" [ set color-type orange color-particle-and-link ]
;            if mouse-interaction = "add green particles"  [ set color-type green  color-particle-and-link ]
;            update-particle-speed-visualization
;          ]
;        ]



;        if mouse-interaction = "speed up particles" or mouse-interaction = "slow down particles" [
;          ask eraser-window-particles [
;            let max-speed 20
;            if mouse-interaction = "speed up particles" [ if speed < max-speed [ set speed (speed * 1.05) ] ]
;            if mouse-interaction = "slow down particles" [ set speed (speed / 1.05) ]
;          ]
;        ]
      ]
      ask particles with [any? walls-here] [ remove-from-walls ] ; deal with any walls drawn on top of particles
    ]
  ]; end mouse in view code
end

; patch procedure-externalized for when walls change
to rebuild-region-one
   ask region1 [ set pcolor black ]
       let old-region1 no-patches
       set region1 patch-set self
       let news patch-set self
       while [count region1 > count old-region1] [
         set old-region1 region1
         let old-news news
         set news no-patches
         ask old-news [; region1
           set news (patch-set news (neighbors4 with [ not member? self region1 and count ( walls-here with [hidden? = false]) = 0 and count plungers-here = 0 ]) )
         ]
         set region1 (patch-set region1 news)
         ask region1 [ set pcolor brown - 3 ]
         display
       ]
       set r1-upper false
       set r1-lower false
       ask syringe-upper [ if member? self region1 [ set r1-upper true ] ]
       ask syringe-lower [ if member? self region1 [ set r1-lower true ] ]
       ask region1 [ set pcolor black ]
end

to rebuild-region-two
    ask region2 [ set pcolor black ]
       let old-region2 no-patches
       set region2 patch-set self
       let news patch-set self
       while [count region2 > count old-region2] [
         set old-region2 region2
         let old-news news
         set news no-patches
         ask old-news [
           set news (patch-set news (neighbors4 with [ not member? self region2 and count ( walls-here with [hidden? = false]) = 0 and count plungers-here = 0 ]) )
         ]
         set region2 (patch-set region2 news)
         ask region2 [ set pcolor violet - 3 ]
         display
       ]
       set r2-upper false
       set r2-lower false
       ask syringe-upper [ if member? self region2 [ set r2-upper true ] ]
       ask syringe-lower [ if member? self region2 [ set r2-lower true ] ]
       ask region2 [ set pcolor black ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; particle speed and flash visualization procedures ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-a-flash
  sprout-flashes 1 [
    set color [150 150 150 255]
    set birthday ticks
  ]
end


to update-flash-visualization
  if (ticks - birthday > 0.4)  [ die ]
  set color lput (255 - (255 * (ticks - birthday ) / 0.4)) [150 150 150]
end


to update-particle-speed-visualization
  if visualize-particle-speed = "no" [ recolornone ]
  if visualize-particle-speed = "arrows" [ scale-arrowheads]
  if visualize-particle-speed = "different shades" [ recolorshade ]
end


to recolorshade
  let this-link my-out-links
  ask this-link [set hidden? true]
  ifelse speed < 27 [
    set color color-type - 3 + speed / 3
  ][
    set color color-type + 4.999
  ]
end


to recolornone
  let this-link my-out-links
  ask this-link [set hidden? true]
  set color color-type
end


to color-particle-and-link
  let this-link my-out-links
  let this-color-type color-type
  set color this-color-type
  ask this-link [set color this-color-type]
end


to scale-arrowheads
  let this-xcor xcor
  let this-ycor ycor
  let this-speed speed
  let this-heading heading
  let this-arrowhead out-link-neighbors
  let this-link my-out-links
  ask this-link [set hidden? false]
  ask this-arrowhead [
    set xcor this-xcor
    set ycor this-ycor
    set heading this-heading
    fd .5 + this-speed / 3
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; initialization procedures ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-box
  ask patches with [(
   pycor = min-pycor  or
   pycor = max-pycor or
   pxcor = min-pxcor or
   pxcor = max-pxcor )] [
    sprout-walls 1 [ set color yellow initialize-this-wall set pressure? true ] ]
end

to initialize-this-wall
  set valve-1? false
  set valve-2? false
  set pressure? false
end

to make-particles
  create-particles initial-#-particles [
    setup-particles
    random-position
  ]
end

to setup-particles  ; particles procedure
  set breed particles
  set shape "circle"
  set size particle-size
  set energy initial-gas-temperature
  set color-type green
  set color color-type
  set mass 10
  hatch-arrowheads 1 [ set hidden? true create-link-from myself [ tie ] ]
  set speed speed-from-energy
  set last-collision nobody
end

; Place particles at random, but they must not be placed on top of wall atoms..
to random-position
  let open-patches nobody
  let open-patch nobody
  set open-patches patches with [
    not any? turtles-here and
    pxcor != max-pxcor and
    pxcor != min-pxcor and
    pycor != min-pycor and
    pycor != max-pycor
  ] set open-patch one-of open-patches
  if open-patch = nobody [
    user-message "No open patches found.  Exiting."
    stop
  ]
  setxy ([pxcor] of open-patch) ([pycor] of open-patch)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; wall penetration error handling procedure ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; if particles actually end up within the wall
to remove-from-walls
  let this-wall walls-here with [not hidden?]
  if count this-wall != 0 [
    let available-patches patches with [not any? walls-here]
    let closest-patch nobody
    if any? available-patches [
      set closest-patch min-one-of available-patches [distance myself]
      if distance closest-patch != 0 [
        set heading towards closest-patch
        setxy ([pxcor] of closest-patch)  ([pycor] of closest-patch)
      ]
    ]
  ]

  let this-plunger plungers-here
  if count this-plunger != 0 [
    let available-patches patches with [not any? walls-here]
    let closest-patch nobody
    if any? available-patches [
      set closest-patch min-one-of available-patches [distance myself]
      if distance closest-patch != 0 [
        set heading towards closest-patch
        setxy ([pxcor] of closest-patch)  ([pycor] of closest-patch)
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;ADDED FOR SYRINGE;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-syringe
  if not any? plungers [
    ask patches with [
      (pxcor = syringe-left-x
        or pxcor = syringe-right-x)

      and (pycor >= syringe-bottom-y
        and pycor <= syringe-top-y)
    ]
    [ sprout-walls 1 [ set color gray - 2 initialize-this-wall] ]

    ask patches with [
      (
        (pxcor = syringe-left-x
          or pxcor = syringe-right-x
          or pxcor = syringe-left-x + 1
          or pxcor = syringe-right-x - 1)

        and ( pycor = syringe-bottom-y - 1
          or pycor = syringe-top-y + 1)) ]
    [
      sprout-walls 1 [ set color gray - 2 initialize-this-wall]
    ]


    ;;; add the bottom stopper
    ask patches with [
      pycor = syringe-bottom-y - 1
     and pxcor > syringe-left-x + 1
     and pxcor < syringe-right-x - 1
    ][
      let redness gas-temperature * 2.5
      sprout-walls 1 [ set color (list redness 0 (250 - redness)) initialize-this-wall] ;jamie - changed color to match start temp
    ]

    ask patches with [ (pxcor > syringe-left-x and pxcor < syringe-right-x) and ( pycor = 0 ) ] [ sprout-plungers 1 [ set color sky ] ]
    set syringe-region patches with [ pxcor > syringe-left-x and pxcor < syringe-right-x and pycor >= syringe-bottom-y and pycor <= syringe-top-y ]
    set syringe-border patches with [ (pxcor = syringe-left-x or pxcor = syringe-right-x) and pycor >= syringe-bottom-y and pycor <= syringe-top-y ]
    set syringe-upper  patches with [ pxcor > syringe-left-x and pxcor < syringe-right-x and ( pycor =  syringe-top-y + 1 or pycor = syringe-top-y)]
    set syringe-lower  patches with [ pxcor > syringe-left-x and pxcor < syringe-right-x and (pycor = syringe-bottom-y - 1  or pycor = syringe-bottom-y)]
  ]
end

to remove-all-forces
  ask forces [ die ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;REPORTERS;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report speed-from-energy
   report sqrt (2 * energy / mass)
end

to-report energy-from-speed
   report (mass * speed * speed / 2)
end

to-report limited-particle-energy
  let limited-energy energy
  if limited-energy > max-particle-energy [ set limited-energy max-particle-energy ]
  if limited-energy < min-particle-energy [ set limited-energy min-particle-energy ]
  report limited-energy
end


; Copyright 2010 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
195
10
399
446
-1
-1
7.0
1
10
1
1
1
0
0
0
1
-27
0
-30
30
1
1
1
ticks
30.0

BUTTON
10
70
175
120
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
1

BUTTON
10
10
175
56
setup/reset
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

CHOOSER
10
220
175
265
visualize-particle-speed
visualize-particle-speed
"no" "arrows" "different shades"
2

PLOT
420
10
780
435
Volume
ticks
volume (mL)
0.0
10.0
0.0
100.0
true
true
"" "if (experiment-running? != true) \n[ set-plot-x-range (round (plunger-plot-start - 1)) (round (ticks + 1)) ]"
PENS
"starting volume" 1.0 0 -7500403 true "" "plotxy ticks experiment-plunger-start-line * 2 + 50  "
"volume" 1.0 0 -2674135 true "" "plotxy ticks  precision [ycor] of one-of plungers 2 * 2 + 50"

MONITOR
10
385
175
438
Volume
word (precision ([ycor] of one-of plungers * 2 + 50) 2) \" mL\"
17
1
13

SLIDER
10
175
175
208
gas-temperature
gas-temperature
0
100
21.0
1
1
C
HORIZONTAL

BUTTON
10
132
175
165
reset temperature
set gas-temperature 23\nask walls with [\n      pycor = syringe-bottom-y - 1\n     and pxcor > syringe-left-x + 1\n     and pxcor < syringe-right-x - 1\n  ][\n    let redness gas-temperature * 2.5\n    set color (list redness 0 (250 - redness))\n  ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model enables students to investigate representations of syringe-like systems, exploring concepts related to gas particles and gas behavior.

This model is adapted from the Particulate Nature of Matter (PNoM) Curricular Unit and used in the [Kinetic Molecular Theory CT-STEM unit](https://ct-stem.northwestern.edu/curriculum/preview/2620/pem_code/56S6DY3ERPUAFH8XWDRS/). In the unit, students explore kinetic molecular theory and gas laws. They practice the skill of modeling microscopic gas particle interactions to explain the macroscopic behavior of gases. At the end of the unit, students describe the motion of gas particles and predict how changing one or more variables will impact the gaseous system.

In all of the PnoM models, gas particles are assumed to move and collide, both with each other and with other objects such as walls.

In this model, students investigate how different temperatures correspond with varying volumes in the syringe as its plunger moves up and down.

## HOW IT WORKS

### Particles
The particles are modeled as hard balls with no internal energy except that which is due to their motion. Collisions between particles are elastic. The total kinetic energy of the two particles after the encounter is equal to their total kinetic energy before the encounter. Collisions with the wall are not. When a particle hits the wall, it bounces off the wall but does not loose any energy to the wall. It does not gain any energy from the wall, either. The plunger moves according to the total force applied on it by the particles at an instance.

The exact way two particles collide is as follows:
1. A particle moves in a straight line without changing its speed, unless it collides with another particle or bounces off the wall.
2. Two particles "collide" if they find themselves on the same patch. In this model, two turtles are aimed so that they will collide at the origin.
3. An angle of collision for the particles is chosen, as if they were two solid balls that hit, and this angle describes the direction of the line connecting their centers.
4. The particles exchange momentum and energy only along this line, conforming to the conservation of momentum and energy for elastic collisions.
5. Each particle is assigned its new speed, heading and energy.

### Syringe
A syringe typically consists of a primary tube or barrel with a plunger and piston to expand and contract the volume. In this model, the piston moves up as particles collide beneath it.

## HOW TO USE IT

### Buttons
SETUP - sets up the initial conditions set on the sliders.
GO/STOP - runs and stops the model.
RESET TEMPERATURE - resets the gas temperature to 23 degrees
GAS-TEMPERATURE slider - adjusts the gas temperature with a visual cue in the colored bar (blue to red)

### Choosers
VISUALIZE-PARTICLE-SPEED? allows you to visualize particle speeds. For example, selecting "arrows" creates a representation of each particle velocity using a scalar arrow.  Selecting "shades" creates a representation of each particle speed using a brighter (faster) or darker (slower) shade of the particle's color.

## THINGS TO NOTICE

Transparency is used to model flashes of where pressure was transferred to the wall by fading away the color of the flash at locations where a particle hit the wall.

## THINGS TO TRY

Try visualizing the particle speeds as temperature rises. Observe how the length of the scalar "arrows" change.

Try quickly changing the temperataure and observe how the volume graph changes.

## EXTENDING THE MODEL

Add a slider that allows users to change the initial number of particles.

Add slider that changes the mass of the mass of the plunger.

Allow users to add gas particles outside the syringe as well.

## NETLOGO FEATURES

The model uses `set color` with a list of three RBG values to gradually change the color of the heat source as a user adjusts the temperature slider.

## RELATED MODELS

* GasLab Models
* Connected Chemistry models.
* This model is found on [page 2 in lesson 4](https://ct-stem.northwestern.edu/curriculum/preview/2624/page/2/pem_code/56S6DY3ERPUAFH8XWDRS/) of the KMT unit.
* A copy of the model integrated with the CODAP data visualization tool is found in the same lesson on [page 4](https://ct-stem.northwestern.edu/curriculum/preview/2624/page/3/pem_code/56S6DY3ERPUAFH8XWDRS/)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M., Brady, C., Holbert, N., Soylu, F. and Wilensky, U. (2010).  NetLogo Volume Temperature model.  http://ccl.northwestern.edu/netlogo/models/VolumeTemperature.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

To cite the Particulate Nature of Matter curriculum as a whole, please use:

* Novak, M., Brady, C., Holbert, N., Soylu, F. and Wilensky, U. (2010). Particulate Nature of Matter curriculum.  http://ccl.northwestern.edu/curriculum/pnom/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
Thanks to Umit Aslan and Mitchell Estberg for updating these models for inclusion the in Models Library.

## COPYRIGHT AND LICENSE

Copyright 2010 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2010 PNoM Cite: Novak, M., Brady, C., Holbert, N., Soylu, F. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

add particles
false
1
Circle -2674135 false true 60 60 180
Circle -2674135 false true 36 36 228

add wall
false
0
Rectangle -7500403 false true 90 90 210 210

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
Circle -1184463 true false 68 83 134

carbon-activated
true
0
Circle -1184463 true false 68 83 134
Line -2674135 false 135 90 135 210

carbon2
true
0
Circle -955883 true false 30 45 210

circle
false
1
Circle -2674135 true true 30 30 240

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
Circle -13791810 true false 83 165 134
Circle -13791810 true false 83 0 134
Circle -1184463 true false 83 83 134

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

eraser
false
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -1 false false 0 0 300 300

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

force
true
0
Polygon -7500403 true true 150 150 120 195 180 195 150 150
Line -7500403 true 150 180 150 300

heater-a
false
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -16777216 true false 90 90 210 210

heater-b
false
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -16777216 true false 30 30 135 135
Rectangle -16777216 true false 165 165 270 270

hex
false
0
Polygon -7500403 true true 0 150 75 30 225 30 300 150 225 270 75 270

hex-valve
false
0
Rectangle -7500403 false true 0 0 300 300
Polygon -7500403 false true 105 60 45 150 105 240 195 240 255 150 195 60

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

nitrogen
true
0
Circle -10899396 true false 83 135 134
Circle -10899396 true false 83 45 134

none
true
0

oxygen
true
0
Circle -13791810 true false 83 135 134
Circle -13791810 true false 83 45 134

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

spray paint
false
0
Circle -7500403 true true 164 67 16
Circle -7500403 true true 82 37 16
Circle -7500403 true true 127 37 16
Circle -7500403 true true 96 59 16
Circle -7500403 true true 52 82 16
Circle -7500403 true true 22 112 16
Circle -7500403 true true 52 142 16
Circle -7500403 true true 29 204 16
Circle -7500403 true true 127 112 16
Circle -7500403 true true 112 142 16
Circle -7500403 true true 81 204 16
Circle -7500403 true true 149 168 16
Circle -7500403 true true 200 40 16
Circle -7500403 true true 257 91 16
Circle -7500403 true true 207 93 16
Circle -7500403 true true 190 132 16
Circle -7500403 true true 233 161 16
Circle -7500403 true true 247 189 16
Circle -7500403 true true 135 193 16
Circle -7500403 true true 187 219 16
Circle -7500403 true true 234 232 16
Circle -7500403 true true 176 261 16
Circle -7500403 true true 144 249 16
Circle -7500403 true true 146 279 16
Circle -7500403 true true 87 249 16

spray particles
true
0
Circle -7500403 true true 54 84 42
Circle -7500403 true true 189 114 42
Circle -7500403 true true 99 174 42
Circle -7500403 true true 189 234 42
Circle -7500403 true true 159 9 42

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

valve-1
false
0
Rectangle -7500403 false true 0 0 300 300
Rectangle -7500403 false true 120 120 180 180

valve-2
false
0
Rectangle -7500403 false true 0 0 300 300
Rectangle -7500403 false true 60 120 120 180
Rectangle -7500403 false true 165 120 225 180

valve-hex
false
0
Rectangle -7500403 false true 0 0 300 300
Polygon -7500403 false true 105 60 45 150 105 240 195 240 255 150 195 60

valve-triangle
false
0
Rectangle -7500403 true true 0 0 300 300
Polygon -16777216 true false 150 45 30 240 270 240

valves
false
0
Rectangle -7500403 false true 0 0 300 300

wall
false
0
Rectangle -7500403 true true 0 0 300 300

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
0
@#$#@#$#@
