extensions [import-a fetch]  ; extensions to read files and URLs

globals [
  tick-delta        ; how much simulation time will pass in this step
  box-edge          ; distance of box edge from origin
  collisions        ; list used to keep track of future collisions
  particle1         ; first particle currently colliding
  particle2         ; second particle currently colliding

  gravity-acceleration ; to represent the movement of the water molecules (doesn't work for H2 gas pairs)

  ; -- extensions to the base particles model, adding set sizes for: --
  h-size   ; hydrogen
  o-size   ; oxygen
  k-size   ; potassium
  ca-size  ; calcium
  i-size   ; iodine

  bond-broken? ; if any bonds between molecules have been broken
  bond-made?   ; if any bonds between molecules have been formed

  current-material ; we don't want users to change the value in runtime and cause confusion
  outside-energy   ; energy outside of the calorimeter (based on outside-temperature)
  wall-energy      ; energy along the walls (based on outside-temperature)

  container-color ; color for the walls
  outside-color   ; color for the area outside of the calorimeter

  ; reporter values for all three sensors
  sensor-1-val
  sensor-2-val
  sensor-3-val

  avg-temperature ; average temperature across the entire system

  ; variables for iterating through the list of three sensors
  ; needed these variables because we cannot use loop or while in NetLogo Web (for curricular use)
  placing-a-sensor?
  current-sensor

  sensor-avg-list

  hit-speed-threshold ; the speed at which bonds are broken or formed
]

breed [particles particle]
breed [sensors sensor]

patches-own [
  patch-kind ; can be "none", "outside", "wall", "inside"
]

particles-own [
  speed
  mass
  energy
  kind ; this can be H (1), O (8), K (19), Ca(20), I (53)
       ; the molecules will be composed of the particles/atoms above
       ; e.g. h2o >> 1 + 1 + 8 = 10
  exchange-energy-at-this-tick?
]

sensors-own [
  my-number
  my-reading
  my-readings
  my-ave-reading
  sensor-kind
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; setup procedures ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; not using clear-all because we want to preserve the sensors
to clear-custom
  clear-patches
  clear-ticks
  clear-all-plots
  clear-output

  output-print ">> Set-up done. Follow this console for messages ..."

  ask particles [die]
  ask sensors [ set label "" set my-reading 0]

  set sensor-1-val 0
  set sensor-2-val 0
  set sensor-3-val 0
  set avg-temperature 0
end


to setup
  clear-custom

  set-default-shape particles "circle"
  set-default-shape sensors "sensor"

  set gravity-acceleration 9.8
  set outside-energy round (outside-temperature / 10)
  set wall-energy round (outside-temperature / 10)
  set sensor-avg-list (list 0)

  set h-size 0.5
  set o-size 1
  set i-size 1.5
  set k-size 2.5
  set ca-size 3

  set hit-speed-threshold 0.115 ; this is an arbitrary number and fixed for all collisions

  ask patches [ set patch-kind "inside" ] ; the container & outside will be overwritten later on

  make-box

  make-water

  set bond-broken? false
  set bond-made? false

  set particle1 nobody
  set particle2 nobody

  set placing-a-sensor? false
  set current-sensor nobody

  reset-ticks
  reset-collisions
end

; draw the walls
to make-box
  set current-material container-material
  set container-color white ; "styrofoam"
  if current-material = "glass" [ set container-color cyan + 4 ]
  if current-material = "steel" [ set container-color gray - 2 ]
  if current-material = "iron" [ set container-color brown - 3 ]
  if current-material = "aluminum" [ set container-color gray + 3 ]
  if current-material = "diamond" [ set container-color pink + 3 ]

  set box-edge max-pxcor - 5

  ; box/container patches
  ask patches with [(abs pxcor = box-edge or abs pycor = box-edge)
                 and abs pxcor <= box-edge and abs pycor <= box-edge]
  [
    set pcolor container-color
    set patch-kind "wall"
  ]

  ; outside patches
  set outside-color blue - 3.5
  ask patches with [(abs pxcor > box-edge or abs pycor > box-edge)] [
    set pcolor outside-color
    set patch-kind "outside"
  ]
end

; create the water molecules
to make-water
  create-particles number-of-water-molecules [
    set shape "h2o"
    set kind 10
    set speed 0.1
    set size o-size + (h-size * 2)
    set mass (size * size)
    set energy kinetic-energy
    ; now position the particle at an empty spot
    while [ overlapping? ] [ position-randomly ]
  ]
end

to reset-collisions
  set collisions []
  ask particles [ check-for-wall-collision ]
  ask particles [ check-for-particle-collision ]
end

; create the potassium iodide molecules
to add-KI
  let particles-added 0
  let could-place? true

  create-particles KI-to-add [
    set shape "ki"
    set kind 19 + 53
    set size k-size + i-size
    set mass (size * size)
    set speed sqrt (2  / (mass * 50)) ; because we want all the particles to have initial KE of 2 (equiv 22 degrees C)
    set energy kinetic-energy ; (0.5 * mass * speed * speed * 100)

    ; position the particle at an empty spot (if possible)
    let trials 0
    while [ overlapping? and trials < 20] [ position-randomly set trials trials + 1 ]
    if trials >= 20 [ set could-place? false die ]

    set particles-added particles-added + 1
  ]

  if not could-place? [
    output-print (word "!>> There was not enough space to add " KI-to-add " particles. Added " particles-added " instead.")
    stop
  ]

  reset-collisions
end

; create the calcium molecules
to add-Ca
  let particles-added 0
  let could-place? true

  create-particles Ca-to-add [
    set shape "ca"
    set kind 20
    set size ca-size
    set mass (size * size)
    set speed sqrt (2  / (mass * 50)) ; because we want all the particles to have initial KE of 2 (equiv 22 degrees C)
    set energy kinetic-energy

    ; now position the particle at an empty spot
    let trials 0
    while [ overlapping? and trials < 10] [ position-randomly set trials trials + 1]
    if trials >= 10 [ set could-place? false die ]

    set particles-added particles-added + 1
  ]

  if not could-place? [
    output-print (word "!>> There was not enough space to add " Ca-to-add " particles. Added " particles-added " instead.")
    stop
  ]

  reset-collisions
end

to-report overlapping?  ; particle procedure
  ; here, we use IN-RADIUS just for improved speed; the real testing is done by DISTANCE
  report ((any? other particles in-radius (size + 1 ) ;+0.5 because I don't want touching
                              with [distance myself < (size + [size] of myself) / 2])
    or any? patches in-radius (size + 2 ) with [patch-kind = "wall" or patch-kind = "outside"]

    )
end

to position-randomly  ; particle procedure
  ; place particle at random location inside the box
  setxy one-of [1 -1] * random-float (box-edge - i-size - size / 2)
        one-of [1 -1] * random-float (box-edge - i-size - size / 2)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; go procedures  ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ask particles [set exchange-energy-at-this-tick? false]
  choose-next-collision
  ask particles [ jump speed * tick-delta ]

  perform-next-collision
  tick-advance tick-delta
  recalculate-particles-that-just-collided

  if bond-broken? or bond-made? [
    reset-collisions
  ]

  ask particles with [exchange-energy-at-this-tick?][
    perform-energy-exchange-with-wall
  ]

  contain-particles
  walls-exchange-energy-with-outside
  update-sensor-readings
  update-plots
  set bond-broken? false
  set bond-made? false

end

; makes sure that particles stay within the calorimeter
to contain-particles
  let extraneous particles with [patch-kind = "wall" or patch-kind = "outside"]
  if any? extraneous [
    ask extraneous [
      back speed
      rt 90
      if patch-kind = "wall" or patch-kind = "outside" [ rt 90 ]
    ]
  ]
end

to recalculate-particles-that-just-collided
  ; Since only collisions involving the particles that collided most recently could be affected,
  ; we filter those out of collisions.  Then we recalculate all possible collisions for
  ; the particles that collided last.  The ifelse statement is necessary because
  ; particle2 can be either a particle or a string representing a wall.  If it is a
  ; wall, we don't want to invalidate all collisions involving that wall (because the wall's
  ; position wasn't affected, those collisions are still valid.
  ifelse is-turtle? particle2 [
      set collisions filter [ the-collision ->
        item 1 the-collision != particle1 and
        item 2 the-collision != particle1 and
        item 1 the-collision != particle2 and
        item 2 the-collision != particle2
      ] collisions
      ask particle2 [ check-for-wall-collision ]
      ask particle2 [ check-for-particle-collision ]
    ][
      set collisions filter [ the-collision ->
        item 1 the-collision != particle1 and
        item 2 the-collision != particle1
      ] collisions
    ]
  if particle1 != nobody [ ask particle1 [ check-for-wall-collision ] ]
  if particle1 != nobody [ ask particle1 [ check-for-particle-collision ] ]
  ; Slight errors in floating point math can cause a collision that just
  ; happened to be calculated as happening again a very tiny amount of
  ; time into the future, so we remove any collisions that involves
  ; the same two particles (or particle and wall) as last time.
  set collisions filter [ the-collision ->
    item 1 the-collision != particle1 or
    item 2 the-collision != particle2
  ] collisions
  ; All done.
  set particle1 nobody
  set particle2 nobody
end

; check-for-particle-collision is a particle procedure that determines the time it takes
; to the collision between two particles (if one exists).  It solves for the time by representing
; the equations of motion for distance, velocity, and time in a quadratic equation of the vector
; components of the relative velocities and changes in position between the two particles and
; solves for the time until the next collision
to check-for-particle-collision
  let my-x xcor
  let my-y ycor
  let my-particle-size size
  let my-x-speed speed * dx
  let my-y-speed speed * dy

  ask other particles [
    let dpx (xcor - my-x)   ; relative distance between particles in the x direction
    let dpy (ycor - my-y)    ; relative distance between particles in the y direction
    let x-speed (speed * dx) ; speed of other particle in the x direction
    let y-speed (speed * dy) ; speed of other particle in the x direction
    let dvx (x-speed - my-x-speed) ; relative speed difference between particles in x direction
    let dvy (y-speed - my-y-speed) ; relative speed difference between particles in y direction
    let sum-r (((my-particle-size) / 2 ) + (([size] of self) / 2 )) ; sum of both particle radii

    ; To figure out what the difference in position (P1) between two particles at a future
    ; time (t) will be, one would need to know the current difference in position (P0) between the
    ; two particles and the current difference in the velocity (V0) between the two particles.
    ;
    ; The equation that represents the relationship is:
    ;   P1 = P0 + t * V0
    ; we want find when in time (t), P1 would be equal to the sum of both the particle's radii
    ; (sum-r).  When P1 is equal to is equal to sum-r, the particles will just be touching each
    ; other at their edges (a single point of contact).
    ;
    ; Therefore we are looking for when:   sum-r =  P0 + t * V0
    ;
    ; This equation is not a simple linear equation, since P0 and V0 should both have x and y
    ; components in their two dimensional vector representation (calculated as dpx, dpy, and
    ; dvx, dvy).
    ;
    ; By squaring both sides of the equation, we get:
    ;   (sum-r) * (sum-r) =  (P0 + t * V0) * (P0 + t * V0)
    ; When expanded gives:
    ;   (sum-r ^ 2) = (P0 ^ 2) + (t * PO * V0) + (t * PO * V0) + (t ^ 2 * VO ^ 2)
    ; Which can be simplified to:
    ;   0 = (P0 ^ 2) - (sum-r ^ 2) + (2 * PO * V0) * t + (VO ^ 2) * t ^ 2
    ; Below, we will let p-squared represent:   (P0 ^ 2) - (sum-r ^ 2)
    ; and pv represent: (2 * PO * V0)
    ; and v-squared represent: (VO ^ 2)
    ;
    ;  then the equation will simplify to:     0 = p-squared + pv * t + v-squared * t^2

    let p-squared   ((dpx * dpx) + (dpy * dpy)) - (sum-r ^ 2)   ; p-squared represents difference
    ; of the square of the radii and the square of the initial positions

    let pv  (2 * ((dpx * dvx) + (dpy * dvy)))  ; vector product of the position times the velocity
    let v-squared  ((dvx * dvx) + (dvy * dvy)) ; the square of the difference in speeds
    ; represented as the sum of the squares of the x-component
    ; and y-component of relative speeds between the two particles

    ; p-squared, pv, and v-squared are coefficients in the quadratic equation shown above that
    ; represents how distance between the particles and relative velocity are related to the time,
    ; t, at which they will next collide (or when their edges will just be touching)

    ; Any quadratic equation that is a function of time (t) can be represented as:
    ;   a*t*t + b*t + c = 0,
    ; where a, b, and c are the coefficients of the three different terms, and has solutions for t
    ; that can be found by using the quadratic formula.  The quadratic formula states that if a is
    ; not 0, then there are two solutions for t, either real or complex.
    ; t is equal to (b +/- sqrt (b^2 - 4*a*c)) / 2*a
    ; the portion of this equation that is under a square root is referred to here
    ; as the determinant, d1.   d1 is equal to (b^2 - 4*a*c)
    ; and:   a = v-squared, b = pv, and c = p-squared.
    let d1 pv ^ 2 -  (4 * v-squared * p-squared)

    ; the next test tells us that a collision will happen in the future if
    ; the determinant, d1 is > 0,  since a positive determinant tells us that there is a
    ; real solution for the quadratic equation.  Quadratic equations can have solutions
    ; that are not real (they are square roots of negative numbers).  These are referred
    ; to as imaginary numbers and for many real world systems that the equations represent
    ; are not real world states the system can actually end up in.

    ; Once we determine that a real solution exists, we want to take only one of the two
    ; possible solutions to the quadratic equation, namely the smaller of the two the solutions:
    ;  (b - sqrt (b^2 - 4*a*c)) / 2*a
    ;  which is a solution that represents when the particles first touching on their edges.
    ;  instead of (b + sqrt (b^2 - 4*a*c)) / 2*a
    ;  which is a solution that represents a time after the particles have penetrated
    ;  and are coming back out of each other and when they are just touching on their edges.

    let time-to-collision  -1

    if d1 > 0
      [ set time-to-collision (- pv - sqrt d1) / (2 * v-squared) ]        ; solution for time step

    ; if time-to-collision is still -1 there is no collision in the future - no valid solution
    ; note:  negative values for time-to-collision represent where particles would collide
    ; if allowed to move backward in time.
    ; if time-to-collision is greater than 1, then we continue to advance the motion
    ; of the particles along their current trajectories.  They do not collide yet.

    if time-to-collision > 0
    [
      ; time-to-collision is relative (ie, a collision will occur one second from now)
      ; We need to store the absolute time (ie, a collision will occur at time 48.5 seconds.
      ; So, we add clock to time-to-collision when we store it.
      ; The entry we add is a three element list of the time to collision and the colliding pair.
      set collisions fput (list (time-to-collision + ticks) self myself)
                          collisions
    ]
  ]
end

; determines when a particle will hit any of the four walls
to check-for-wall-collision  ; particle procedure
  ; right & left walls
  let x-speed (speed * dx)
  if x-speed != 0
    [ ; solve for how long it will take particle to reach right wall
      let right-interval (box-edge - 0.5 - xcor - size / 2) / x-speed
      if right-interval > 0
        [ assign-colliding-wall right-interval "right wall" ]
      ; solve for time it will take particle to reach left wall
      let left-interval ((- box-edge) + 0.5 - xcor + size / 2) / x-speed
      if left-interval > 0
        [ assign-colliding-wall left-interval "left wall" ] ]
  ; top & bottom walls
  let y-speed (speed * dy)
  if y-speed != 0
    [ ; solve for time it will take particle to reach top wall
      let top-interval (box-edge - 0.5 - ycor - size / 2) / y-speed
      if top-interval > 0
        [ assign-colliding-wall top-interval "top wall" ]
      ; solve for time it will take particle to reach bottom wall
      let bottom-interval ((- box-edge) + 0.5 - ycor + size / 2) / y-speed
      if bottom-interval > 0
        [ assign-colliding-wall bottom-interval "bottom wall" ] ]
end


to assign-colliding-wall [time-to-collision wall]  ; particle procedure
  ; this procedure is used by the check-for-wall-collision procedure
  ; to assemble the correct particle-wall pair
  ; time-to-collision is relative (ie, a collision will occur one second from now)
  ; We need to store the absolute time (ie, a collision will occur at time 48.5 seconds.
  ; So, we add clock to time-to-collision when we store it.
  let colliding-pair (list (time-to-collision + ticks) self wall)
  set collisions fput colliding-pair collisions
end

to choose-next-collision
  if collisions = [] [ stop ]
  ; Sort the list of projected collisions between all the particles into an ordered list.
  ; Take the smallest time-step from the list (which represents the next collision that will
  ; happen in time).  Use this time step as the tick-delta for all the particles to move through
  let winner first collisions
  foreach collisions [ the-collision ->
    if first the-collision < first winner [ set winner the-collision ]
  ]
  ; winner is now the collision that will occur next
  let dt item 0 winner
  ; If the next collision is more than 1 in the future,
  ; only advance the simulation one tick, for smoother animation.
  set tick-delta dt - ticks
  if tick-delta > 1
    [ set tick-delta 1
      set particle1 nobody
      set particle2 nobody
      stop ]
  set particle1 item 1 winner
  set particle2 item 2 winner
end

to perform-next-collision
  ; deal with 3 possible cases:
  ; 1) no collision at all
  if particle1 = nobody [ stop ]

  ; 2) particle meets wall
  if is-string? particle2 [
    if particle2 = "left wall" or particle2 = "right wall" [
        ask particle1 [
          set heading (- heading)
          set exchange-energy-at-this-tick? true ;; umit code
        ]
        stop
      ]
      if particle2 = "top wall" or particle2 = "bottom wall" [
          ask particle1 [
            set heading 180 - heading
            set exchange-energy-at-this-tick? true ;; umit code
          ]
          stop
      ]
  ]
  ; 3) particle meets particle
  ask particle1 [ collide-with particle2 ]
end

to collide-with [other-particle]  ; particle procedure
  ;; PHASE 1: initial setup
  ; for convenience, grab some quantities from other-particle
  let mass2 [mass] of other-particle
  let speed2 [speed] of other-particle
  let heading2 [heading] of other-particle
  let kind2 [kind] of other-particle
  let energy2 [energy] of other-particle
  ; modified so that theta is heading toward other particle
  let theta towards other-particle

  ;; PHASE 2: convert velocities to theta-based vector representation
  ; now convert my velocity from speed/heading representation to components
  ; along theta and perpendicular to theta
  let v1t (speed * cos (theta - heading))
  let v1l (speed * sin (theta - heading))
  ; do the same for other-particle
  let v2t (speed2 * cos (theta - heading2))
  let v2l (speed2 * sin (theta - heading2))

  ;; PHASE 3: manipulate vectors to implement collision
  ; compute the velocity of the system's center of mass along theta
  let vcm (((mass * v1t) + (mass2 * v2t)) / (mass + mass2) )
  ; now compute the new velocity for each particle along direction theta.
  ; velocity perpendicular to theta is unaffected by a collision along theta,
  ; so the next two lines actually implement the collision itself, in the
  ; sense that the effects of the collision are exactly the following changes
  ; in particle velocity.
  set v1t (2 * vcm - v1t)
  set v2t (2 * vcm - v2t)

  ;; PHASE 4: convert back to normal speed/heading
  ; now convert my velocity vector into my new speed and heading
  set speed sqrt ((v1t * v1t) + (v1l * v1l))
  ; if the magnitude of the velocity vector is 0, atan is undefined. but
  ; speed will be 0, so heading is irrelevant anyway. therefore, in that
  ; case we'll just leave it unmodified.
  set energy kinetic-energy

  if v1l != 0 or v1t != 0
    [ set heading (theta - (atan v1l v1t)) ]
  ; and do the same for other-particle
  ask other-particle [
    set speed sqrt ((v2t ^ 2) + (v2l ^ 2))
    set energy kinetic-energy

    if v2l != 0 or v2t != 0
      [ set heading (theta - (atan v2l v2t)) ]
  ]
  ; calculate the total energy so that we can divide it between the particle
    ; it can be either preserved, increased, or decreased based on the collision
    ; but it respects the total KE of the system
  let total-energy energy + [energy] of other-particle

  ; MAKE the H2 BONDS IF THE COLLISION IS CORRECT
  if kind = 1 and kind2 = 1 [
    hatch 1 [
      set kind 1 + 1 ; H +
      set size (h-size * 2)
      set shape "h2"
      set mass (size * size)
      set speed sqrt ((total-energy ) / (mass * 50)) ; because we want all the particles to not increase/decrease the current temperature
      set energy kinetic-energy
    ]
    set bond-made? true
    ask other-particle [die]
    die
  ]

  ; MAKE the Ca(OH) BONDS IF THE COLLISION IS CORRECT
  if (kind = 20 and kind2 = 10) [
    ; find how fast the water molecule is hitting the KI
    let hit-speed speed
    if kind != 10 [ set hit-speed speed2 ]
    if  (hit-speed > hit-speed-threshold)  [ ;; this is an arbitrary threshold
      hatch 1 [
        set kind 20 + 8 + 1 ; Ca + 2 * ( O + H)
        set size (ca-size + o-size + h-size) / 1.5
        set shape "caoh"
        set mass (size * size)
        set speed sqrt ((total-energy * 0.6) / (mass * 50)) ; because we want all the particles to not increase/decrease the current temperature
        set energy kinetic-energy
        left 45
      ]

      hatch 1 [
        set kind 1
        set size h-size * 1.5
        set shape "h"
        set mass (size * size)
        set speed sqrt ((total-energy * 0.4) / (mass * 50)) ; because we want all the particles to not increase/decrease the current temperature
        set energy kinetic-energy
        right 45
      ]
      set bond-made? true
      ask other-particle [die]
      die
    ]
  ]

  ; MAKE the Ca(OH)2 BONDS IF THE COLLISION IS CORRECT
  if (kind = 29 and kind2 = 10) [
    ; find how fast the water molecule is hitting the KI
    let hit-speed speed
    if kind != 10 [ set hit-speed speed2 ]
    if  (hit-speed > hit-speed-threshold)  [ ;; the hit speed of the water molecule is arbitrary now
      let increased-energy total-energy + 3
      hatch 1 [
        set kind 29 + 8 + 1 ; CaOH + OH
        set size (ca-size + 2 * (o-size + h-size)) / 2 + 0.1
        set shape "caoh2"
        set mass (size * size)
        set speed sqrt ((increased-energy * 0.6) / (mass * 50))
        set energy kinetic-energy
        left 45
      ]

      hatch 1 [
        set kind 1
        set size h-size * 1.5
        set shape "h"
        set mass (size * size)
        set speed sqrt ((increased-energy * 0.4) / (mass * 50))
        set energy kinetic-energy
        right 45
      ]
      set bond-made? true
      ask other-particle [ die]
      die
    ]
  ]

  ; BREAK the KI BONDS IF THE COLLISION IS CORRECT
  ; we are only interested in H2O hitting the KI molecules
  ; when H20 molecules hit the KI with enough speed and correct angle
  ; the KI molecules will break into K+ and I- ions
  if (kind = 19 + 53 and kind2 = 10) [
    ; find how fast the water molecule is hitting the KI
    let hit-speed speed
    if kind != 10 [ set hit-speed speed2 ]

    ; the theta's here are arbitrary
    if  (hit-speed > hit-speed-threshold)  [
      ; the bond should break only when the impact is strong enough
      let molecule-to-break other-particle
      let molecule-to-slow self
      if kind = 19 + 53 [ set molecule-to-break self set molecule-to-slow other-particle]

      let decreased-energy total-energy - 3
      if decreased-energy < 0 [ set decreased-energy 0 ]

      hatch 1 [ ; create a potassium ion
        set kind 19
        set size k-size * 1.3 ; this 1.3 is to make sure that the resulting particles don't shrink
        set shape "k"
        set mass (size * size)
        set speed sqrt ((decreased-energy * 0.4) / (mass * 50))
        set energy kinetic-energy
        lt 90   fd 1.05   rt 90 ; preserve the actual position relative to the bonded molecule
      ]

      hatch 1 [ ; create iodine ion
        set kind 53
        set size i-size * 1.2 ; this 1.2 is to make sure that the resulting particles don't shrink
        set shape "i"
        set mass (size * size)
        set speed sqrt ((decreased-energy * 0.3) / (mass * 50))
        set energy kinetic-energy
        rt 90   fd 0.35    lt 90 ; preserve the actual position relative to the bonded molecule
      ]

      set bond-broken? true
      ask molecule-to-slow [
        set speed sqrt ((decreased-energy * 0.3) / (mass * 50))
        set energy kinetic-energy
      ]
      ask molecule-to-break [ die ]
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; time reversal procedure  ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Here's a procedure that demonstrates time-reversing the model.
; You can run it from the command center.  When it finishes,
; the final particle positions may be slightly different because
; the amount of time that passes after the reversal might not
; be exactly the same as the amount that passed before; this
; doesn't indicate a bug in the model.
; For larger values of n, you will start to notice larger
; discrepancies, eventually causing the behavior of the system
; to diverge totally. Unless the model has some bug we don't know
; about, this is due to accumulating tiny inaccuracies in the
; floating point calculations.  Once these inaccuracies accumulate
; to the point that a collision is missed or an extra collision
; happens, after that the reversed model will diverge rapidly.
to test-time-reversal [n]
  setup
  ask particles [ stamp ]
  while [ticks < n] [ go ]
  let old-ticks ticks
  reverse-time
  while [ticks < 2 * old-ticks] [ go ]
  ask particles [ set color white ]
end

to reverse-time
  ask particles [ rt 180 ]
  set collisions []
  ask particles [ check-for-wall-collision ]
  ask particles [ check-for-particle-collision ]
  ; the last collision that happened before the model was paused
  ; (if the model was paused immediately after a collision)
  ; won't happen again after time is reversed because of the
  ; "don't do the same collision twice in a row" rule.  We could
  ; try to fool that rule by setting particle1 and
  ; particle2 to nobody, but that might not always work,
  ; because the vagaries of floating point math means that the
  ; collision might be calculated to be slightly in the past
  ; (the past that used to be the future!) and be skipped.
  ; So to be sure, we force the collision to happen:
  perform-next-collision
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; reporters ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report kinetic-energy
   report (0.5 * mass * speed * speed * 100)
end

to-report current-temperature
  report 300 - ((count particles with [kind = 19]) / 5)
end

;; ENERGY exchange functions
;; depending on the wall type, the particles may loose some of their energy
;; to their surroundings
to walls-exchange-energy-with-outside
  let diff wall-energy - outside-energy  ; negative means the wall is gaining energy
  if (precision diff 3) = 0 [ stop ] ; don't bother if the numbers are too small

  ; no energy loss
  if current-material = "styrofoam" [
    ; do nothing
  ]

  if current-material = "glass" [
    set wall-energy (wall-energy - (diff * 0.04 * 0.01)) ; 0.01 because this is happening on a continuous basis
    set outside-energy (outside-energy + (diff * 0.04 * 0.01))
  ]

  if current-material = "steel" [
    set wall-energy (wall-energy - (diff * 0.1 * 0.01))
    set outside-energy (outside-energy + (diff * 0.1 * 0.01))
  ]

  if current-material = "iron" [
    set wall-energy (wall-energy - (diff * 0.16 * 0.01))
    set outside-energy (outside-energy + (diff * 0.16 * 0.01))
  ]

  if current-material = "aluminum" [
    set wall-energy (wall-energy - (diff * 0.4 * 0.01))
    set outside-energy (outside-energy + (diff * 0.4 * 0.01))
  ]

  if current-material = "diamond" [
    set wall-energy (wall-energy - (diff * 0.9 * 0.01))
    set outside-energy (outside-energy + (diff * 0.9 * 0.01))
  ]
end

to exchange-energy-with-wall-by [percentage]
  ;; if wall is WARMer, I will gain some of that energy & speed up
  ;; if wall is COLDer, I will loose some energy & slow down
  let ediff (energy - wall-energy)

  if (precision ediff 3) = 0 [ stop ] ; don't bother if the numbers are too small
  set energy (energy - ediff * (percentage)) ; increase/decrease energy according to the calc

  if energy < 0 [ set energy 0 ]
  set speed sqrt ((energy) / (mass * 50)) ; recalculate the speed based on energy exchange
  ; add/remove the energy to/from the wall
  set wall-energy wall-energy + ((ediff * (percentage)) / sqrt (sum [mass] of particles))
end

to perform-energy-exchange-with-wall
  ; no energy loss
  if current-material = "styrofoam" [
    ; do nothing
  ]

  if current-material = "glass" [
    exchange-energy-with-wall-by 0.04
  ]

  if current-material = "steel" [
  exchange-energy-with-wall-by 0.1
  ]

  if current-material = "iron" [
    exchange-energy-with-wall-by 0.16
  ]

  if current-material = "aluminum" [
    exchange-energy-with-wall-by 0.3
  ]

  if current-material = "diamond" [
    exchange-energy-with-wall-by 0.9
  ]
end


;; SENSOR functions
to update-sensor-readings
  ; update the reading
  ask sensors with [sensor-kind = "inside"] [

    ; am I touching any particles?
    let sensed-particles (particles in-radius (size / 2))
    if any? sensed-particles [
      ; 11 because it is 22 / 2, where
      ;                              2 is the average KE of the particles initially
      ;                              and 22 degrees C is the room temperature
      set my-reading (precision ((mean [energy] of sensed-particles) * 11) 2)
    ]
  ]

  ask sensors with [sensor-kind = "wall"][
    set my-reading ((precision (wall-energy * 11) 2) - 11)
  ]

  ask sensors with [sensor-kind = "outside"][
    set my-reading ((precision (outside-energy * 11) 2) - 11)
  ]

  ask sensors [
    update-my-readings
    if my-number = 1 [ set sensor-1-val my-ave-reading]
    if my-number = 2 [ set sensor-2-val my-ave-reading]
    if my-number = 3 [ set sensor-3-val my-ave-reading]
  ]
  set avg-temperature (precision ((mean [energy] of particles) * 11) 2)
end

to place-sensor [placing-by-hand?]
  if not placing-a-sensor? [
    let new-sensor-number 1

    if not any? sensors with [my-number = 3] [ set new-sensor-number 3 ]
    if not any? sensors with [my-number = 2] [ set new-sensor-number 2 ]
    if not any? sensors with [my-number = 1] [ set new-sensor-number 1 ]

    if count sensors > 2 [ user-message "You used all of your sensors." stop ]

    let sensor-color blue + 1
    if new-sensor-number = 2 [set sensor-color green + 1 ]
    if new-sensor-number = 3 [set sensor-color orange + 1 ]

    set current-sensor nobody

    create-sensors 1 [
      set current-sensor self

      set color sensor-color

      set my-number new-sensor-number
      set size sensor-radius
    ]
    set placing-a-sensor? true
  ]

  if placing-by-hand? and current-sensor != nobody [
    if placing-a-sensor? [
      ask current-sensor [
        setxy mouse-xcor mouse-ycor
      ]
      display
      if mouse-down? [

        ask current-sensor [

          output-print (word ">> Sensor " my-number " placed.")

          let r (sensor-radius / 2)

          let p-on-wall patches in-radius r with [patch-kind = "wall"]
          let p-on-outside patches in-radius r with [patch-kind = "outside"]
          let p-on-inside patches in-radius r with [patch-kind = "inside"]

          let on-wall? any? p-on-wall
          let on-outside? any? p-on-outside
          let on-inside? any? p-on-inside

          if on-inside? and (not on-wall?) [
            set sensor-kind "inside"
            set shape "sensor"
            print-multi-line ">>"  "Particle sensor placed."
          ]
          if on-wall? and not (on-inside? or on-outside?) [
            set sensor-kind "wall"
            set shape "sensor wall"
            print-multi-line ">>"  "Wall sensor placed."
          ]
          if on-outside? and not (on-wall?) [
            set sensor-kind "outside"
            set shape "sensor outside"
            output-print ">> Outside sensor placed."
          ]
          if on-inside? and on-wall? [ ;; can't be inside and outside without being on wall
            ifelse sensor-radius > 10 [ ; if the sensor is really large it's gotta be about particles
              set sensor-kind "inside"
              set shape "sensor"
              print-multi-line "!>>"
                "You placed the sensor on both a wall and inside the container. It will ignore the wall and only measure the particles' temperature."
            ][
              let n-walls count p-on-wall
              let n-inside count p-on-inside
              ifelse n-inside > n-walls * 2 [
                set sensor-kind "inside"
                set shape "sensor"
                print-multi-line "!>>"
                  "You placed the sensor on both a wall and inside the container. It will ignore the wall and only measure the particles' temperature."
              ][
                set sensor-kind "wall"
                set shape "sensor wall"
                print-multi-line "!>>"
                  "You placed the sensor on both a wall and inside the container. It will ignore the particles and only measure the wall's temperature."

              ]
            ]
          ]
          if on-wall? and on-outside? and not on-inside? [
            ifelse sensor-radius > 8 [
              set sensor-kind "outside"
              set shape "sensor outside"
              print-multi-line "!>>"
                "You placed the sensor on both a wall and outside the container. It will ignore the wall and only measure the outside temperature."

            ][

              let n-walls count p-on-wall
              let n-outside count p-on-outside
              ifelse n-outside > n-walls * 2 [
                set sensor-kind "outside"
                set shape "sensor outside"
                print-multi-line "!>>"
                  "You placed the sensor on both a wall and outside the container. It will ignore the wall and only measure the outside's temperature."

              ][

                set sensor-kind "wall"
                set shape "sensor wall"
                print-multi-line "!>>"
                  "You placed the sensor on both a wall and inside the container. It will ignore the particles and only measure the wall's temperature."

              ]

            ]
          ]
        ]
        set placing-a-sensor? false
        set current-sensor nobody
        stop
      ]
    ]
  ]

end

;; OUTPUT procedure
to print-multi-line [prefix str]
  let phrase-length 108
  let len length str

  if phrase-length > len [
    output-print (word prefix " " str)
    stop
  ]

  let num-phrases len / phrase-length

  output-print (word prefix " " substring str 0 phrase-length)

  let pos 1
  repeat num-phrases [
    let start-pos (phrase-length * pos)
    let end-pos phrase-length * (pos + 1)

    if end-pos > len [ set end-pos len ]

    output-print (word "....... " substring str start-pos end-pos)
    set pos pos + 1
  ]

  output-print ""

end

; sensor procedure
to update-my-readings
  if not is-list? my-readings [
    set my-readings (list my-reading)
  ]

  ifelse length my-readings < 5 [
    set my-readings lput my-reading my-readings
    set my-ave-reading mean my-readings
  ][
    set my-readings lput my-reading (butfirst my-readings)
    set my-ave-reading mean my-readings
  ]

end

to remove-sensor [number]
  let target-sensors (sensors with [my-number = number])
  if any? target-sensors [
    ask target-sensors [ die ]
    if number = 1 [ set sensor-1-val 0]
    if number = 2 [ set sensor-2-val 0]
    if number = 3 [ set sensor-3-val 0]
    display
  ]
end

to exchange-outside-energy-by [amount]
  set outside-energy outside-energy + amount
end

to-report sensor-avg
  ; take the mean of just the existing sensors
  ifelse any? sensors [
    set sensor-avg-list lput (precision (mean ([my-reading] of sensors)) 2) sensor-avg-list
    if length sensor-avg-list > 1000 [
      set sensor-avg-list butfirst sensor-avg-list
    ]
    report mean sensor-avg-list
  ][
    report 0
  ]
end


; Copyright 2021 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
250
10
685
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
-30
30
-30
30
1
1
1
ticks
30.0

BUTTON
6
143
99
193
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
112
143
235
193
run/pause
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
103
235
136
number-of-water-molecules
number-of-water-molecules
0
100
40.0
1
1
NIL
HORIZONTAL

BUTTON
141
228
236
261
Add KI >>
add-KI
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
6
228
135
261
KI-to-add
KI-to-add
0
20
10.0
1
1
NIL
HORIZONTAL

CHOOSER
5
10
235
55
container-material
container-material
"styrofoam" "glass" "steel" "iron" "aluminum" "diamond"
0

BUTTON
5
385
235
435
Place sensor >>
place-sensor true
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
343
235
376
sensor-radius
sensor-radius
2
50
20.0
1
1
NIL
HORIZONTAL

PLOT
695
10
1120
295
Sensor readings over time
ticks
temperature (C)
0.0
10.0
0.0
2.0
true
false
"" ""
PENS
"s1" 1.0 0 -13345367 true "" "plot sensor-1-val"
"s2" 1.0 0 -10899396 true "" "plot sensor-2-val"
"s3" 1.0 0 -955883 true "" "plot sensor-3-val"

MONITOR
695
325
830
370
sensor-1
sensor-1-val
1
1
11

MONITOR
840
325
975
370
sensor-2
sensor-2-val
1
1
11

MONITOR
985
325
1120
370
sensor-3
sensor-3-val
1
1
11

BUTTON
840
380
975
413
Remove Sensor 2
remove-sensor 2
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
695
380
830
413
Remove Sensor 1
remove-sensor 1
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
985
380
1120
413
Remove Sensor 3
remove-sensor 3
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
810
310
857
350
•
36
105.0
1

TEXTBOX
1090
310
1159
351
•
36
25.0
1

TEXTBOX
955
310
995
356
•
36
55.0
1

BUTTON
990
460
1122
505
Save Experiment
export-world (word (user-input \"Enter the name of your project\") \".model\")
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
990
510
1122
550
Load Experiment
fetch:user-file-async import-a:world
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
141
270
236
303
Add Ca >>
add-CA
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
6
270
136
303
Ca-to-add
Ca-to-add
0
20
11.0
1
1
NIL
HORIZONTAL

OUTPUT
5
460
975
575
13

SLIDER
5
63
235
96
outside-temperature
outside-temperature
0
35
23.0
1
1
C
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model explores the relationships between chemical reactions and change in temperature. It does so by simulating a calorimeter, an instrument for measuring the amount of heat produced from chemical reactions. More specifically, this model focuses on the following reactions:

Ca<sub>(s)</sub> + H<sub>2</sub>O<sub>(l)</sub> → Ca(OH)<sub>2(aq)</sub> + H<sub>2(g)</sub>

Adding calcium to water produces calcium hydroxide. This is an exothermic reaction, meaning it gives off heat as the calcium molecules bond with the water molecules.

KI<sub>(s)</sub> + H<sub>2</sub>O<sub>(l)</sub> → K<sub>(aq)</sub> + I<sub>(aq)</sub>

Adding potassium iodide to water breaks the KI bonds. This is an endothermic reaction, meaning it absorbs heat as the potassium iodide bonds break.

This model is also built off of one in a series of GasLab models. They use the same basic rules for simulating the behavior of gases.  Each model integrates different features in order to highlight different aspects of gas behavior. This model is different from the other GasLab models in that the collision calculations take the circular shape and size of the particles into account, instead of modeling the particles as dimensionless points.

## HOW IT WORKS

#### Calorimetry

Initially, all the particles have the same speed but random directions. As the particles repeatedly collide, they exchange energy and head off in new directions, and the speeds are dispersed -- some particles get faster, some get slower. In order to break potassium iodide bonds or form calcium hydroxide bonds, the collision with water molecules must be correct. The model analyzes the speed of collisions and after a certain threshold, we can observe the transformations. These reactions either release or absorb heat. Changes in temperature are recorded by three sensors. Each sensor can be adjusted according to size and placement. Temperatures can be observed outside of the calorimeter, within the calorimeter, and along the walls. The rate of temperature exchanged between all three areas is also dependent on the material selected for the walls.

#### Particles

The model determines the resulting motion of particles that collide, with no loss in their total momentum or total kinetic energy (an elastic collision).

To calculate the outcome of collision, it is necessary to calculate the exact time at which the edge of one particle (represented as a circle) would touch the edge of another particle (or the walls of a container) if the particles were allowed to continue with their current headings and speeds.

By performing such a calculation, one can determine when the next collision anywhere in the system would occur in time.  From this determination, the model then advances the motion of all the particles using their current headings and speeds that far in time until this next collision point is reached.  Exchange of kinetic energy and momentum between the two particles, according to conservation of kinetic energy and conservation of momentum along the collision axis (a line drawn between the centers of the two particles), is then calculated, and the particles are given new headings and speeds based on this outcome.

## HOW TO USE IT

1. Use the sliders to select CONTAINER-MATERIAL, OUTSIDE-TEMPERATURE, and NUMBER-OF-WATER-MOLECULES.
2. Press SETUP. The following message should appear in the console at the bottom: "Set-up done. Follow this console for messages ..."
3. Press RUN/PAUSE to start and stop the model. You should see the water molecules moving freely within the calorimeter.

As the model runs:

1. You can add KI and Ca molecules. Select the number of KI-TO-ADD and CA-TO-ADD before pressing ADD-KI or ADD-CA.
2. You can place sensors outside, within, or along the walls of the calorimeter. Select the desired sensor size with the SENSOR-RADIUS slider. Then click PLACE-SENSOR. A circular sensor should follow your mouse until you click to stamp it in the desired location. Sensors that reach multiple areas will automatically be assigned the area that is covered the most (a message should appear within the console at the bottom).
3. All sensors can be removed in any order. Click the corresponding REMOVE-SENSOR button; each is located beneath its monitor and also labeled by number.

If you would like to pick up where you left off, feel free to use the SAVE-EXPERIMENT feature. This will save the model as a .model file. You can later use the LOAD-EXPERIMENT button to upload that saved model.

Plots/Monitors:
- The graph on the right records all three sensor readings over time
- The observed temperatures for each sensor can also be seen in the monitors beneath the graph

## THINGS TO NOTICE

How do the different calorimeter materials affect the transfer of heat/energy between the interior and exterior?

One of the materials in the list is diamond. Given that it is not possible to make cups from diamond, why do you think this hypothetical material is useful to have?

With particles of different sizes, you may notice some fast moving particles have lower energy than medium speed particles. How can the difference in the mass of the particles account for this?

## THINGS TO TRY

To see what the approximate mass of each particle is, type this in the command center:

    ask particles [ set label precision mass 0 ]

## CURRICULAR USE

This model is primarily designed for an "Energy in Chemical Reactions" unit hosted at ct-stem.northwestern.edu and authored by Carole Namowicz, but is also designed for other relevant units.

#### Goals
- Simulating realistic molecule representation (including ions), movement, and collision.
- Simulating realistic energy in chemical reactions.
- Simulating a calorimeter by placing sensors in the model and measuring the energy change in the closed system.
- Simulating different calorimeter wall materials (e.g., glass, foam, aluminum)
- Simulating different energy sources

## EXTENDING THE MODEL

You can try to add initial-water-temperature as an additional, adjustable variable to extend the sandbox.

You can modify this model to simulate other endothermic or exothermic reactions.

You can implement a bifocal extension using the Arduino or GoGo extensions. For example, you can connect three temperature sensors and place them inside, outside, and on the wall of a real-world calorimeter. You can then feed the sensor information to the model so that the virtual particles behave like the real particles inside the calorimeter.

Collisions between boxes and circles could also be explored (changing particle shapes).  Variations in size between particles could be investigated or variations in the mass of some of the particle could be made to explore other factors that affect the outcome of collisions.

## NETLOGO FEATURES

This model includes a separate output console to help guide users as they setup, run the model, and add sensors. It does so through NetLogo's `output-print` command.

The model also uses the `import-a` and `fetch` extensions to save and upload experiments.

Instead of advancing one tick at a time as in most models, the tick counter takes on fractional values, using the `tick-advance` primitive.  (In the Interface tab, it is displayed as an integer, but if you make a monitor for `ticks` you'll see the exact value.)

## RELATED MODELS

This model is an extension of the GasLab Circular Particles model.

Look at the other GasLab models to see collisions of "point" particles, that is, the particles are assumed to have an area or volume of zero.

## CREDITS AND REFERENCES

* Wilensky, U. (2005). NetLogo GasLab Circular Particles model. http://ccl.northwestern.edu/netlogo/models/GasLabCircularParticles. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
* Wilensky, U. (1997). NetLogo GasLab Gas in a Box model. http://ccl.northwestern.edu/netlogo/models/GasLabGasinaBox. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Aslan, U., Namowicz, C., Levites, L. and Wilensky, U. (2021).  NetLogo Calorimetry model.  http://ccl.northwestern.edu/netlogo/models/Calorimetry.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

This model was developed as part of the CT-STEM Project at Northwestern University and was made possible through generous support from the National Science Foundation (grants CNS-1138461, CNS-1441041, DRL-1020101, DRL-1640201 and DRL-1842374) and the Spencer Foundation (Award #201600069). Any opinions, findings, or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the funding organizations. For more information visit https://ct-stem.northwestern.edu/.

Special thanks to the CT-STEM models team for preparing these models for inclusion
in the Models Library including: Kelvin Lao, Jamie Lee, Sugat Dabholkar, Sally Wu,
and Connor Bain.

## COPYRIGHT AND LICENSE

Copyright 2021 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2021 CTSTEM Cite: Aslan, U., Namowicz, C., Levites, L. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

ca
true
0
Circle -13345367 true false 18 15 270

caoh
true
0
Circle -13345367 true false 13 14 272
Circle -2674135 true false 0 90 120
Circle -1 true false 30 45 60

caoh2
true
0
Circle -13345367 true false 13 14 272
Circle -2674135 true false 180 90 120
Circle -2674135 true false 0 90 120
Circle -1 true false 210 195 60
Circle -1 true false 30 45 60

circle
false
0
Circle -7500403 true true 1 1 298

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

container
false
0
Rectangle -7500403 false false 0 75 300 225
Rectangle -7500403 true true 0 75 300 225
Line -16777216 false 0 210 300 210
Line -16777216 false 0 90 300 90
Line -16777216 false 150 90 150 210
Line -16777216 false 120 90 120 210
Line -16777216 false 90 90 90 210
Line -16777216 false 240 90 240 210
Line -16777216 false 270 90 270 210
Line -16777216 false 30 90 30 210
Line -16777216 false 60 90 60 210
Line -16777216 false 210 90 210 210
Line -16777216 false 180 90 180 210

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

h
true
0
Circle -1 true false 18 15 270

h2
true
0
Circle -1 true false 6 48 204
Circle -1 true false 96 48 204

h2o
true
0
Circle -2674135 true false 60 90 180
Circle -1 true false 15 60 90
Circle -1 true false 195 60 90

hexagonal prism
false
0
Rectangle -7500403 true true 90 90 210 270
Polygon -1 true false 210 270 255 240 255 60 210 90
Polygon -13345367 true false 90 90 45 60 45 240 90 270
Polygon -11221820 true false 45 60 90 30 210 30 255 60 210 90 90 90

hit and broken
false
0
Line -7500403 true 150 30 150 270
Line -7500403 true 90 150 210 150
Circle -7500403 true true 135 135 30
Line -7500403 true 165 165 180 195
Line -7500403 true 135 165 120 195
Line -7500403 true 165 135 180 105
Line -7500403 true 135 135 120 105

hit but ok
false
0
Line -7500403 true 150 120 150 180
Line -7500403 true 90 150 210 150

i
true
0
Circle -8630108 true false 18 15 270

k
true
0
Circle -955883 true false 18 15 270

ki
true
0
Circle -955883 true false 69 42 216
Circle -8630108 true false 6 93 114

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

o
true
0
Circle -2674135 true false 18 15 270
Circle -1 false false 17 15 270

o2
true
0
Circle -2674135 true false 117 60 180
Circle -1 false false 117 60 180
Circle -2674135 true false 3 60 180
Circle -1 false false 2 60 180

sensor
false
0
Line -7500403 true 150 300 150 0
Line -7500403 true 0 150 300 150
Circle -7500403 false true 89 89 122
Circle -7500403 false true 0 0 300
Circle -7500403 true true 143 143 14

sensor outside
false
0
Line -7500403 true 150 300 150 0
Line -7500403 true 0 150 300 150
Circle -7500403 false true 89 89 122

sensor wall
false
0
Circle -7500403 false true 0 0 300
Rectangle -7500403 true true 75 75 225 225
Circle -1 true false 142 142 16

speed vector
true
0
Line -6459832 false 150 150 150 300
Polygon -7500403 true true 120 195 180 195 150 135

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

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

vector
true
0
Line -7500403 true 150 15 150 150
Polygon -7500403 true true 120 30 150 0 180 30 120 30

x
true
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
