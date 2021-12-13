globals[
  ; phase counter
  all-phases
  all-phases-abbr
  current-phase
  current-phase-abbr
  phase-counter
  ; patch indices for building the city grid
  road-patch-all-index
  road-patch-right-index
  road-patch-left-index
  road-patch-up-index
  road-patch-down-index
  traffic-light-patch-index

  ; patch agentsets for building the city grids
  intersections            ; agentset containing the patches that are intersections
  roads                    ; agentset containing the patches that are roads
  streets                  ; agentset containing the patches that are roads excluding intersections
  traffic-lights           ; agentset containing the patches that are traffic lights
  row-traffic-lights       ; agentset containing the patches that are traffic lights on horizontal roads
  col-traffic-lights       ; agentset containing the patches that are traffic lights on vertical roads

  ; patch agentsets for districts and zones of a city
  cbd-zones
  commercial-zones
  residential-zones

  ; phase of the traffic:
  row-green?
  col-green?
]

breed [ taxicabs taxicab ]
breed [ passengers passenger ]

passengers-own [
  patience-to-wait
  been-waiting
  destination-patch-passenger
  d-xcor
  d-ycor
  num-passengers-waiting
]

taxicabs-own [
  ; vacancy flag
  vacancy?
  ; intersection flag
  prev-intersection
  num-passengers-onboard
  ; travel variables
  num-total-miles
  num-business-miles
  num-dead-miles
  num-grids-traveled-current-trip
  trip-distance-lst
  ; income variables
  num-total-trips
  total-income
  current-trip-income
  trip-income-lst
  ; time when the passenger is picked
  tick-at-pickup
  current-trip-duration
  trip-duration-lst
  ; location information about pickup road
  pickup-on-horizontal?
  pickup-on-vertical? ; destination coordinates
  d-xcor
  d-xcor2
  d-ycor
  d-ycor2 ; pickup coordinates
  pickup-xcor
  pickup-ycor
]

patches-own[
  ; patch identity check
  is-road?
  is-intersection?
  is-traffic-light?
  ; controlling the direction of the traffic for each patch
  left?
  right?
  up?
  down?
  num-directions-possible
  ; traffic rules
  green-light-up?
  ; district and zone characteristics
  is-cbd?
  is-residential?
  is-commercial?
]

; The current grid size is 65x65
; To create a grid system, for any given row and column,
; there are 9 blocks with each spans for 5 patches separate by roads which spans 2 patches
to setup
  clear-all
  setup-globals
  setup-patches
  draw-road-lines
  setup-road-direction
  setup-taxicabs
  reset-ticks
end

to go
  start-traffic-light
  report-current-phase
  taxi-demand-at-patch
  passengers-wait-for-ride
  taxicabs-movement
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Setup all patches ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-patches
  build-zones
  build-roads
  build-intersections
  build-traffic-lights
end

;;;;;;;;;;;;;;;;;;;;;;;
;; Build Urban Zones ;;
;;;;;;;;;;;;;;;;;;;;;;;
to build-zones
  ; residential zones
  set residential-zones patches with [
    (pycor < -25 or pycor > 25) or (pxcor < -25 or pxcor > 25)
  ]
  ask residential-zones[
    set is-residential? true
    set is-cbd? false
    set is-commercial? false
  ]
  ; cbd zones: center
  set cbd-zones patches with [
    pxcor > -12 and pxcor < 12 and
    pycor > -12 and pycor < 12
  ]
  ask cbd-zones [
    set is-cbd? true
    set is-residential? false
    set is-commercial? false
    set pcolor [255 188 121]
  ]
  ; commercial zones
  set commercial-zones patches with [
    pxcor > -26 and pxcor < 26 and
    pycor > -26 and pycor < 26
  ]
  set commercial-zones commercial-zones with [not member? self cbd-zones]
  ask commercial-zones [
    set is-residential? false
    set is-cbd? false
    set is-commercial? true
    set pcolor [162 200 236] ;; blue
  ]
end

; Helper that takes a list as input
; 1. turn all elements in a list negative
; 2. concatenate both negative and positive lists
to-report create-full-list [lst]
  ;; convert the input list all to negative
  let neg-lst map [i -> i * -1] lst
  ;; concatenate the negative lst with the original pos list
  let full-lst sentence neg-lst lst
  report full-lst
end

to setup-globals
  ; define the color of the neighborhoods
  ask patches [
    set pcolor [207 207 207] ;; cherry red

    ; patch identity
    set is-road? false
    set is-intersection? false
    set is-traffic-light? false

    ; patch direction
    set left? false
    set right? false
    set up? false
    set down? false
    set num-directions-possible 0
    ;; set phase for the traffic light
    set row-green? true
    set col-green? false
  ]

  ; Identify roads with positive road index number
  let road-patch-pos [3 4 10 11 17 18 24 25 31 32]

  ; Use create-full-list procedure to get all road patch index
  set road-patch-all-index create-full-list (road-patch-pos)

  ; Identify roads that can only go right
  let road-patch-right-pos [3 10 17 24 31]
  let road-patch-right-neg map[i -> (i + 1) * -1] road-patch-right-pos
  set road-patch-right-index sentence road-patch-right-pos road-patch-right-neg

  ; Identify roads that can only go left
  let road-patch-left-pos [4 11 18 25 32]
  let road-patch-left-neg map[i -> (i - 1) * -1] road-patch-left-pos
  set road-patch-left-index sentence road-patch-left-pos road-patch-left-neg

  ; Identify roads that can only go top
  set road-patch-up-index road-patch-left-index;

  ; Identify roads that can only go bottom
  set road-patch-down-index road-patch-right-index;

  ; set up all phases
  set all-phases ["AM Peak" "Midday" "PM Peak" "Evening" "Early Morning"]
  set current-phase first all-phases
  set all-phases-abbr["AM" "MD" "PM" "EVE" "EM"]
  set current-phase-abbr first all-phases-abbr

  set phase-counter 1
end

;;;;;;;;;;;;;;;;;
;; Build roads ;;
;;;;;;;;;;;;;;;;;
to build-roads
  set roads patches with [
    member? pycor road-patch-all-index or
    member? pxcor road-patch-all-index
  ]
  ask roads [
    set is-road? true
    set pcolor black
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Build intersections ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to build-intersections
  set intersections roads with [
    member? pycor road-patch-all-index and
    member? pxcor road-patch-all-index
  ]
  ask intersections [
    set is-intersection? true
    set is-road? true
    set pcolor black
  ]
  ; build streets which separate intersection and roads
  set streets roads with [not member? self intersections]
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Draw road lines ;;;
;;;;;;;;;;;;;;;;;;;;;;;
to draw-horizontal-line [ y gap ]
  ; We use a temporary turtle to draw the line:
  ; - with a gap of zero, we get a continuous line;
  ; - with a gap greater than zero, we get a dashed line.
  create-turtles 1 [
    setxy (min-pxcor - 0.5 ) y
    hide-turtle
    set color white
    set heading 90
    repeat world-width - 0.5 [
      pen-up
      forward gap
      pen-down
      forward (1 - gap)
    ]
    die
  ]
end

to draw-vertical-line [ x gap ]
  ; We use a temporary turtle to draw the line:
  ;   with a gap of zero, we get a continuous line;
  ;   with a gap greater than zero, we get a dashed line.
  create-turtles 1 [
    setxy x (min-pxcor - 0.5 )
    hide-turtle
    set color white
    set heading 180
    repeat world-width - 0.5 [
      pen-up
      forward gap
      pen-down
      forward (1 - gap)
    ]
    die
  ]
end

to draw-road-lines
  foreach road-patch-all-index [y-coordinate ->
    draw-horizontal-line y-coordinate 0.5
  ]
  foreach road-patch-all-index [x-coordinate ->
    draw-vertical-line x-coordinate 0.5
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Build traffic lights ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to build-traffic-lights
  ; Identify patches that are traffic lights with positive index
  let traffic-light-patch-index-pos [2 5 9 12 16 19 23 26 30]
  ; Use create-full-list procedure to get all road patch index
  set traffic-light-patch-index create-full-list (traffic-light-patch-index-pos)

  ; Create an agent set called traffic lights
  set traffic-lights roads with [
    member? pxcor traffic-light-patch-index or
    member? pycor traffic-light-patch-index
  ]
  ; Create an agent set called row traffic lights
  set row-traffic-lights traffic-lights with [
    member? pycor traffic-light-patch-index
  ]
  ; Create an agent set called col traffic lights
  set col-traffic-lights traffic-lights with [
    member? pxcor traffic-light-patch-index
  ]

  ; Set traffic light flag
  ask traffic-lights [
    set is-traffic-light? true
  ]

  ; define row and column traffic lights
  set row-traffic-lights traffic-lights with [
    member? pxcor traffic-light-patch-index
  ]
  set col-traffic-lights traffic-lights with [
    member? pycor traffic-light-patch-index
  ]
  ask row-traffic-lights [
    set pcolor green
  ]
  ask col-traffic-lights [
    set pcolor red
  ]
  ask traffic-lights[
    if pcolor = green [
      set green-light-up? true
    ]
    if pcolor = red [
      set green-light-up? false
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Draw road direction ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-road-direction
  ; first set all roads with dummy direction to false
  ask roads [
    set right? false
    set left? false
    set up? false
    set down? false
  ]

  ; change roads direction dummy according to road patch index
  ask roads[
    if member? pycor road-patch-right-index[set right? true]
    if member? pycor road-patch-left-index[set left? true]
    if member? pxcor road-patch-up-index[set up? true]
    if member? pxcor road-patch-down-index[set down? true ]
  ]

  ; Adjust corner cases
  ; if a driver at the most top roads cannot go further top
  ask roads with [pycor = 32] [set up? false]
  ; if a driver at the most bottom roads cannot go further bottom
  ask roads with [pycor = -32] [set down? false]
  ; if a driver at the most right roads cannot go further right
  ask roads with [pxcor = 32][set right? false]
  ; if a driver at the most left roads cannot go left
  ask roads with [pxcor = -32][set left? false]

  ; fix some corner cases
  ; left upper corner
  ask patch -31 32 [
    set up? false
    set left? true
  ]

  ; left lower corner
  ask patch -32 -31 [
    set left? false
    set down? true
  ]
  ask patch 32 31 [
    set right? false
    set up? true
  ]

  ; right lower corner
  ask patch 31 -32 [
    set down? false
    set right? true
  ]

  ; count the number of directions possible for each road patches
  ask patches [
    if up? [set num-directions-possible num-directions-possible + 1]
    if down? [set num-directions-possible num-directions-possible + 1]
    if right? [set num-directions-possible num-directions-possible + 1]
    if left? [set num-directions-possible num-directions-possible + 1]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Create Taxicabs ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-taxicabs
  create-taxicabs num-taxicab [
    set color yellow
    set size 2
    set vacancy? true
    set num-passengers-onboard 0
    set num-total-trips 0
    set num-total-miles 0
    set num-business-miles 0
    set num-dead-miles 0
    set num-grids-traveled-current-trip 0
    set total-income 0
    set current-trip-income 0
    set trip-distance-lst []
    set trip-income-lst []
    set trip-duration-lst []
  ]
  ; put those cabs on the road
  ; 0 up; 90 right; 180 down; 270 left
  ask taxicabs[ move-to one-of roads with [not any? taxicabs-on self] ]
  fix-taxicab-direction
end

to fix-taxicab-direction
  ask roads [
    ; multi-direction patches
    if up? and not down? and not left? and right? [
      ask taxicabs-here [
        ifelse random 100 > 50 [set heading 0][set heading 90]
      ]
    ]
    if up? and not down? and left? and not right? [
      ask taxicabs-here [
        ifelse random 100 > 50 [set heading 0][set heading 270]
      ]
    ]
    if not up? and down? and not left? and right? [
      ask taxicabs-here [
        ifelse random 100 > 50 [set heading 180][set heading 90]
      ]
    ]
    if not up? and down? and left? and not right? [
      ask taxicabs-here [ifelse random 100 > 50 [set heading 180][set heading 270]
      ]
    ]
    ; single direction patches
    if up? and not down? and not left? and not right? [ask taxicabs-here [set heading 0]]
    if not up? and down? and not left? and not right? [ask taxicabs-here [set heading 180]]
    if not up? and not down? and left? and not right? [ask taxicabs-here [set heading 270]]
    if not up? and not down? and not left? and right? [ask taxicabs-here [set heading 90]]]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Update traffic lights ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-traffic-light
  ask row-traffic-lights [
    ifelse pcolor = green [set row-green? true][set row-green? false]
  ]

  ask col-traffic-lights [
    ifelse pcolor = green [set col-green? true][set col-green? false]
  ]
end

to switch-traffic-light
  ifelse row-green? [
    set row-green? false
    set col-green? true
  ][
    set row-green? true
    set col-green? false
  ]
end

to change-traffic-light-color
  if row-green? [
    ask row-traffic-lights [
    set pcolor green]

    ask col-traffic-lights [
      set pcolor red]
  ]
  if col-green? [
    ask row-traffic-lights[
      set pcolor red]

    ask col-traffic-lights [
      set pcolor green]
  ]
end

to start-traffic-light
  update-traffic-light
  change-traffic-light-color
  if ticks mod length-of-green-light = 0 [
    switch-traffic-light
    change-traffic-light-color
  ]

  ; update patch variable of traffic lights of its color
  ask traffic-lights [
   ifelse pcolor = green [
      set green-light-up? true
    ][
      set green-light-up? false
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;
;;;; Global Clock ;;;;
;;;;;;;;;;;;;;;;;;;;;;
to report-current-phase
  ; there are a total of 5 time phases of a day
  ; so in case of the counter is exceeding 4
  ; set the counter back to 0
  if phase-counter > 4 [
      set phase-counter 0
    ]
  ; initial setting first phase is "AM Peak" and the counter is set to be 1
  ; so this will let the first phase go through the whole time period without
  ; jumping to the second phase at the very beginning
  if ticks >= length-of-time-period and ticks mod length-of-time-period = 0 [
    set current-phase item phase-counter all-phases
    set current-phase-abbr item phase-counter all-phases-abbr
    set phase-counter phase-counter + 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;
;;;; Taxi pickup ;;;;
;;;;;;;;;;;;;;;;;;;;;
; Passengers wait for ride at a specific location
; If the wait time exceed the patience
; Passenger die
to passengers-wait-for-ride
  ask passengers [
    set been-waiting been-waiting + 1
    if been-waiting >= patience-to-wait [ die ]
  ]
end

to generate-demand [some-prob origin destination]
  if random-float 1 < some-prob [
    ask n-of 1 origin [
      sprout-passengers 1 [
        set color 9.9
        set shape "person"
        set patience-to-wait random-normal wait-time-mean wait-time-sd
        set been-waiting 0
        set destination-patch-passenger one-of destination
        set d-xcor [pxcor] of destination-patch-passenger
        set d-ycor [pycor] of destination-patch-passenger
        set num-passengers-waiting random 4 + 1
      ]
    ]
  ]
end

to generate-demand-phase [phase-abbreviate]
  let cbd-roads-pickup roads with [is-cbd? and not is-intersection?]
  let commercial-roads-pickup roads with [is-commercial? and not is-intersection?]
  let residential-roads-pickup roads with [is-residential? and not is-intersection?]
  let cbd-roads-dropoff roads with [is-cbd? and not is-intersection? and not is-traffic-light?]
  let commercial-roads-dropoff roads with [
    is-commercial? and
    not is-intersection? and
    not is-traffic-light?
  ]
  let residential-roads-dropoff roads with [
    is-residential? and
    not is-intersection? and
    not is-traffic-light?
  ]

  ; cbd -> commercial
  generate-demand (runresult word "prob-cbd-cbd-" phase-abbreviate) (cbd-roads-pickup) (cbd-roads-dropoff)
  ; cbd -> residential
  generate-demand (runresult word "prob-cbd-com-" phase-abbreviate) (cbd-roads-pickup) (commercial-roads-dropoff)
  ; cbd -> cbd
  generate-demand (runresult word "prob-cbd-res-" phase-abbreviate) (cbd-roads-pickup) (residential-roads-dropoff)

  ; commercial -> cbd
  generate-demand (runresult word "prob-com-com-" phase-abbreviate) (commercial-roads-pickup) (commercial-roads-dropoff)
  ; commercial -> residential
  generate-demand (runresult word "prob-com-cbd-" phase-abbreviate) (commercial-roads-pickup) (cbd-roads-dropoff)
  ; commercial -> commercial
  generate-demand (runresult word "prob-com-res-" phase-abbreviate) (commercial-roads-pickup) (residential-roads-dropoff)

  ; residential -> cbd
  generate-demand (runresult word "prob-res-res-" phase-abbreviate) (residential-roads-pickup) (residential-roads-dropoff)
  ; residential -> commercial
  generate-demand (runresult word "prob-res-cbd-" phase-abbreviate) (residential-roads-pickup) (cbd-roads-dropoff)
  ; residential -> residential
  generate-demand (runresult word "prob-res-com-" phase-abbreviate) (residential-roads-pickup) (commercial-roads-dropoff)
end

to taxi-demand-at-patch
  generate-demand-phase current-phase-abbr
end

;;;;;;;;;;;;;;;;;;;;
;;;;Taxi Movement;;;
;;;;;;;;;;;;;;;;;;;;
to move-up
  set heading 0
  stop-for-red-else-go
end

to move-down
  set heading 180
  stop-for-red-else-go
end

to move-right
  set heading 90
  stop-for-red-else-go
end

to move-left
  set heading 270
  stop-for-red-else-go
end

to move-straight
  let cur-heading [heading] of self
  (ifelse
    cur-heading = 0 [move-up]
    cur-heading = 90 [move-right]
    cur-heading = 180 [move-down]
    cur-heading = 270 [move-left]
  )
end

; Traffic rule good citizens: stop at the red light
to stop-for-red-else-go
  ifelse (
    ; stop-condition: taxicab is at a traffic light patch and red light is up and patch ahead is an intersection
    is-traffic-light? and not green-light-up? and ([is-intersection?] of patch-ahead 1)
  ) [
    stop
  ][
    ; in case there is another taxicabs waiting for red light ahead, stop behind
    if (not any? taxicabs-on patch-ahead 1) [
      fd 1
      update-delivery-and-income
    ]
  ]
end

to make-u-turn
  ; taxicab current spatial direction and location
  let heading-up? [heading] of self = 0
  let heading-right? [heading] of self = 90
  let heading-down? [heading] of self = 180
  let heading-left? [heading] of self = 270

  if heading-up? [
    set heading 270
    fd 1
    update-delivery-and-income
    set heading 180
  ]
  if heading-down? [
    set heading 90
    fd 1
    update-delivery-and-income
    set heading 0
  ]
  if heading-right? [
    set heading 0
    fd 1
    update-delivery-and-income
    set heading 270
  ]
  if heading-left? [
    set heading 180
    fd 1
    update-delivery-and-income
    set heading 90
  ]
end

to taxicabs-movement
  ask taxicabs[
    pickup-passengers
    ifelse vacancy? [
      taxicab-move-random
    ][
      taxicab-move-deliver
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Pickup Passengers ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; procedure that instruct taxicabs to pickup passengers
to pickup-passengers
  ; setting or passing along trip-related variables
  if vacancy? [
    if any? passengers-here[
      ; identify a passenger to pickup
      let target-passenger one-of passengers-here
      ; pick up passengers and taxicab is no longer vacant
      set vacancy? false
      ; color taxicabs to indicate occupancy
      set color 117
      ; indicate number of passengers on board
      set num-passengers-onboard [num-passengers-waiting] of target-passenger
      ; tracking trip fare
      set current-trip-income first-passenger-cost +
        (num-passengers-onboard - 1) *
        each-additional-passenger-cost
      ; record ticks at the pickup moment
      set tick-at-pickup ticks
      ; record pickup coordinates
      set pickup-xcor [xcor] of self
      set pickup-ycor [ycor] of self
      ; update total number of trips
      set num-total-trips num-total-trips + 1
      ; update destination coordinates
      set d-xcor [d-xcor] of target-passenger
      set d-ycor [d-ycor] of target-passenger
      ; passengers onboard and died on roads
      ask target-passenger [die]
      ; indicate pickup road is horizontal or vertical
      set pickup-on-horizontal? (left? or right?)
      set pickup-on-vertical? (up? or down?)
      ; update destination coordinates
      update-destination-coordinates
      highlight-destination-patches 117
      change-direction-for-delivery
    ]
  ]
end

to change-direction-for-delivery
  ; Assess the destination coordinate with the current pickup coordinate
  let current-xcor [xcor] of self
  let current-ycor [ycor] of self

  let destination-xcor1 [d-xcor] of self
  let destination-xcor2 [d-xcor2] of self
  let destination-ycor1 [d-ycor] of self
  let destination-ycor2 [d-ycor2] of self

  ; current location based on the destination location
  let cur-at-top? (current-ycor > destination-ycor1) and (current-ycor > destination-ycor2)
  let cur-at-bottom? (current-ycor < destination-ycor1) and (current-ycor < destination-ycor2)
  let cur-on-right? (current-xcor > destination-xcor1) and (current-xcor > destination-xcor2)
  let cur-on-left? (current-xcor < destination-xcor1) and (current-xcor < destination-xcor2)
  let cur-same-x? (current-xcor = destination-xcor1) or (current-xcor =  destination-xcor2)
  let cur-same-y? (current-ycor = destination-ycor1) or (current-ycor = destination-ycor2)

  ; taxicab current spatial direction and location
  let heading-up? [heading] of self = 0
  let heading-right? [heading] of self = 90
  let heading-down? [heading] of self = 180
  let heading-left? [heading] of self = 270

  ; fix taxicab heading
  ; The current location is on top-right of destination
  (ifelse
  ; The current location is straight above
    cur-same-x? and cur-at-top? [
      if heading-up? [make-u-turn]
    ]
  ; The current location is straight below
    cur-same-x? and cur-at-bottom? [
      if heading-down? [make-u-turn]
    ]
  ; The current location is straight right
    cur-same-y? and cur-on-right? [
      if heading-right? [make-u-turn]
    ]
  ; The current location is straight left
    cur-same-y? and cur-on-left? [
      if heading-left? [make-u-turn]
    ]
    cur-at-top? and cur-on-right? [
      ; if the heading is not facing bottom or left, make a u-turn
      if (heading-up? or heading-right?) [make-u-turn]
    ]
  ; The current location is on top left of destination
    cur-at-top? and cur-on-left? [
      ; if the heading is not facing down or right, make a u-turn
      if (heading-up? or heading-left?) [make-u-turn]
    ]
  ; The current location is on bottom-right of destination
    cur-at-bottom? and cur-on-right? [
      ; if the heading is not facing up or left, make a u-turn
      if (heading-down? or heading-right?) [make-u-turn]
    ]
  ; The current location is on botton-left of destination
    cur-at-bottom? and cur-on-left? [
      ; if the heading is not facing up or right, make a u-turn
      if (heading-down? or heading-left?) [make-u-turn]
    ]
  )
end

; update the destination coordinates:
; so that dropoff patches can be flexible and
; road directions no longer matter
to update-destination-coordinates
  ; if destination patch has up or down sign
  ; meaning destination is in column roads so x coordinate can be flexible
  if [up? or down?] of patch d-xcor d-ycor [
    let dropoff-x-cord-1 d-xcor + 1
    let dropoff-x-cord-2 d-xcor - 1
    ifelse member? dropoff-x-cord-1 road-patch-all-index [
      set d-xcor2 dropoff-x-cord-1
    ][
      set d-xcor2 dropoff-x-cord-2
    ]
    set d-ycor2 d-ycor
  ]
  ; if destination patch has left or right sign
  ; meaning destination is in row roads so y coordinate can be flexible
  if [right? or left?] of patch d-xcor d-ycor [
    let dropoff-y-cord-1 d-ycor + 1
    let dropoff-y-cord-2 d-ycor - 1
    ifelse member? dropoff-y-cord-1 road-patch-all-index [
      set d-ycor2 dropoff-y-cord-1
    ][
      set d-ycor2 dropoff-y-cord-2
    ]
    set d-xcor2 d-xcor
  ]
end

; highlight the destination patches
to highlight-destination-patches [patch-color]
  if d-ycor2 != 0 [
    ask patch d-xcor d-ycor [set pcolor patch-color]
    ask patch d-xcor d-ycor2 [set pcolor patch-color]
  ]
  if d-xcor2 != 0 [
    ask patch d-xcor d-ycor [set pcolor patch-color]
    ask patch d-xcor2 d-ycor [set pcolor patch-color]
  ]
end

to update-delivery-and-income
  set num-total-miles num-total-miles + 1
  if vacancy? [set num-dead-miles num-dead-miles  + 1]
  if not vacancy? [
    set num-business-miles num-business-miles + 1
    set num-grids-traveled-current-trip  num-grids-traveled-current-trip  + 1
    set current-trip-income current-trip-income + each-grid-cost + each-tick-cost
    set current-trip-duration ticks - tick-at-pickup
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Passenger seeking ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
to taxicab-move-random
  ifelse num-directions-possible = 1 [
    set prev-intersection 0
    (ifelse right? [move-right]
      left? [move-left]
      up? [move-up]
      down? [move-down])
  ][
    ; turtle behavior in the intersection
    ; need to prevent taxicabs looping in the intersections
    set prev-intersection prev-intersection + 1
    ; this taxicab attribute tracks
    ; how many ticks have turtle spent on an intersection
    (ifelse
      up? and right? [
        ifelse prev-intersection = 2 [ move-right ][ifelse random 2 = 0 [ move-up ][ move-right ] ]
      ]
      up? and left? [
        ifelse prev-intersection = 2 [ move-up ][ ifelse random 2 = 0 [move-up][move-left] ]
      ]
      down? and right? [
        ifelse prev-intersection = 2 [ move-down ][ifelse random 2 = 0 [ move-down ][ move-right ] ]
      ]
      down? and left? [
        ifelse prev-intersection = 2 [ move-left ] [ ifelse random 2 = 0 [ move-down ][ move-left ] ]
      ]
    )
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Passenger Delivery ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; to deliver passengers:
; taxicabs will go with the shortest path in Manhattan distance
to taxicab-move-deliver
  ; current location coordinates
  let current-xcor [xcor] of self
  let current-ycor [ycor] of self

  ; destination location coordintes
  let destination-xcor1 [d-xcor] of self
  let destination-xcor2 [d-xcor2] of self
  let destination-ycor1 [d-ycor] of self
  let destination-ycor2 [d-ycor2] of self

  ; current location based on the destination location
  let cur-at-top? (current-ycor > destination-ycor1) and (current-ycor > destination-ycor2)
  let cur-at-bottom? (current-ycor < destination-ycor1) and (current-ycor < destination-ycor2)
  let cur-same-y? (current-ycor = destination-ycor1) or (current-ycor = destination-ycor2)
  let cur-on-right? (current-xcor > destination-xcor1) and (current-xcor > destination-xcor2)
  let cur-on-left? (current-xcor < destination-xcor1) and (current-xcor < destination-xcor2)
  let cur-same-x? (current-xcor = destination-xcor1) or (current-xcor =  destination-xcor2)

  ; drop-off coordinate road type
  let dropoff-on-vertical? (destination-ycor1 = destination-ycor2)
  let dropoff-on-horizontal? (destination-xcor1 = destination-xcor2)

  ; taxicab current spatial direction and location
  let heading-up? [heading] of self = 0
  let heading-right? [heading] of self = 90
  let heading-down? [heading] of self = 180
  let heading-left? [heading] of self = 270
  let on-intersection? member? patch-here intersections

  ; movement logic based on pickup dropoff road type
  if (pickup-on-vertical? and dropoff-on-vertical?)[
    (ifelse
      cur-on-left? [
        ifelse right? [ move-right ][ ifelse on-intersection? and heading-down? [ move-down ] [ move-straight ] ]
      ]
      cur-on-right? [
        ifelse left? [ move-left ][ ifelse on-intersection? and heading-up? [ move-up ][ move-straight ] ]
      ]
      cur-same-x? [
        (ifelse
          cur-at-top? [
            ifelse down? [ move-down ][ if heading-left? [ move-left ] ]
          ]
          cur-at-bottom? [
            ifelse up? [ move-up ] [ if heading-right? [ move-right ] ]
          ]
        )
      ]
    )
  ]

  if (pickup-on-horizontal? and dropoff-on-horizontal?) [
    (ifelse
      cur-at-top? [
        ifelse down? [move-down][move-straight]
      ]
      cur-at-bottom? [
        ifelse up? [ move-up ][ move-straight ]
      ]
      cur-same-y? [
        (ifelse
          cur-on-right? [ifelse left? [ move-left ][ if heading-up? [ move-up ]]]
          cur-on-left? [ifelse right? [ move-right ][ if heading-down? [ move-down ]]]
        )
      ]
    )
  ]

  if (pickup-on-vertical? and dropoff-on-horizontal?)[
    (ifelse
      cur-at-top? [
        ifelse down? [ move-down ][ move-straight ]
      ]
      cur-at-bottom? [
        ifelse up? [ move-up ][ move-straight ]
      ]
      cur-same-y? [
        (ifelse
          cur-on-right? [ ifelse left?  [ move-left  ][ if heading-up? [ move-up ] ] ]
          cur-on-left?  [ ifelse right? [ move-right ][ if heading-down? [ move-down ] ] ]
        )
      ]
    )
  ]
  if (pickup-on-horizontal? and dropoff-on-vertical?)[
    (ifelse
      cur-on-right? [ ifelse left? [ move-left][ move-straight ] ]
      cur-on-left? [ ifelse right? [ move-right][ move-straight ] ]
      cur-same-x? [
        (ifelse
          cur-at-top? [ ifelse down? [ move-down] [if heading-left? [ move-left ] ] ]
          cur-at-bottom? [ ifelse up? [ move-up ] [if heading-right? [ move-right ] ] ]
        )
      ]
    )
  ]

  ; dropoff passenger if reached destination
  dropoff-passenger
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Dropoff Passengers ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to dropoff-passenger
  let current-xcor [xcor] of self
  let current-ycor [ycor] of self

  let destination-xcor1 [d-xcor] of self
  let destination-xcor2 [d-xcor2] of self
  let destination-ycor1 [d-ycor] of self
  let destination-ycor2 [d-ycor2] of self

  if (current-xcor = destination-xcor1 or current-xcor = destination-xcor2) and
     (current-ycor = destination-ycor1 or current-ycor = destination-ycor2)[
    ; update total income
    set total-income total-income + current-trip-income
    ; append current trip distance
    set trip-distance-lst lput num-grids-traveled-current-trip trip-distance-lst
    set trip-income-lst lput current-trip-income trip-income-lst
    set trip-duration-lst lput current-trip-duration trip-duration-lst
    ; reset taxicab
    reset-taxicab-parameter-after-trip
  ]
end

to reset-taxicab-parameter-after-trip
  ; reset taxicab
  set vacancy? true
  set color yellow
  set num-passengers-onboard 0
  set num-grids-traveled-current-trip 0
  set current-trip-income 0
  set current-trip-duration 0
  highlight-destination-patches black
  set d-xcor 0
  set d-xcor2 0
  set d-ycor 0
  set d-ycor2 0
  set pickup-on-horizontal? 0
  set pickup-on-vertical? 0
end


; Copyright 2019 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
270
10
1188
929
-1
-1
14.0
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
-32
32
1
1
1
ticks
30.0

BUTTON
15
538
99
571
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
162
260
195
num-taxicab
num-taxicab
1
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
0
68
260
101
length-of-green-light
length-of-green-light
0
30
20.0
1
1
ticks
HORIZONTAL

BUTTON
146
539
230
573
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

BUTTON
146
585
230
619
go-once
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

MONITOR
61
12
171
57
Time of the Day
current-phase
17
1
11

SLIDER
0
114
260
147
length-of-time-period
length-of-time-period
1
5000
2000.0
100
1
NIL
HORIZONTAL

TEXTBOX
1833
484
2097
516
Spatial Flow Parameters
20
14.0
1

TEXTBOX
1532
539
1603
559
AM Peak
15
14.0
1

SLIDER
1480
565
1655
598
prob-cbd-cbd-AM
prob-cbd-cbd-AM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1480
598
1655
631
prob-cbd-com-AM
prob-cbd-com-AM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1480
630
1655
663
prob-cbd-res-AM
prob-cbd-res-AM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1479
663
1654
696
prob-com-com-AM
prob-com-com-AM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1479
695
1654
728
prob-com-cbd-AM
prob-com-cbd-AM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1479
728
1654
761
prob-com-res-AM
prob-com-res-AM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1480
760
1655
793
prob-res-res-AM
prob-res-res-AM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1477
794
1652
827
prob-res-cbd-AM
prob-res-cbd-AM
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1474
827
1649
860
prob-res-com-AM
prob-res-com-AM
0
1
0.0
0.01
1
NIL
HORIZONTAL

TEXTBOX
1718
537
1782
557
Midday
15
14.0
1

SLIDER
1667
565
1840
598
prob-cbd-cbd-MD
prob-cbd-cbd-MD
0
1
0.97
0.01
1
NIL
HORIZONTAL

SLIDER
1667
600
1841
633
prob-cbd-com-MD
prob-cbd-com-MD
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1667
633
1841
666
prob-cbd-res-MD
prob-cbd-res-MD
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1667
665
1842
698
prob-com-com-MD
prob-com-com-MD
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1665
698
1841
731
prob-com-cbd-MD
prob-com-cbd-MD
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1665
730
1841
763
prob-com-res-MD
prob-com-res-MD
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1665
762
1841
795
prob-res-res-MD
prob-res-res-MD
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1665
795
1841
828
prob-res-cbd-MD
prob-res-cbd-MD
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1665
828
1841
861
prob-res-com-MD
prob-res-com-MD
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1852
567
2025
600
prob-cbd-cbd-PM
prob-cbd-cbd-PM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1852
600
2025
633
prob-cbd-com-PM
prob-cbd-com-PM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1852
633
2025
666
prob-cbd-res-PM
prob-cbd-res-PM
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1852
665
2027
698
prob-com-com-PM
prob-com-com-PM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1852
697
2027
730
prob-com-cbd-PM
prob-com-cbd-PM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1852
730
2025
763
prob-com-res-PM
prob-com-res-PM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1852
764
2025
797
prob-res-res-PM
prob-res-res-PM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1852
797
2025
830
prob-res-cbd-PM
prob-res-cbd-PM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1852
830
2025
863
prob-res-com-PM
prob-res-com-PM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2033
568
2206
601
prob-cbd-cbd-EVE
prob-cbd-cbd-EVE
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2033
600
2206
633
prob-cbd-com-EVE
prob-cbd-com-EVE
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2033
634
2206
667
prob-cbd-res-EVE
prob-cbd-res-EVE
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2033
667
2206
700
prob-com-com-EVE
prob-com-com-EVE
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2033
700
2207
733
prob-com-cbd-EVE
prob-com-cbd-EVE
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2033
732
2207
765
prob-com-res-EVE
prob-com-res-EVE
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2033
765
2207
798
prob-res-res-EVE
prob-res-res-EVE
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2033
798
2208
831
prob-res-cbd-EVE
prob-res-cbd-EVE
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2033
830
2208
863
prob-res-com-EVE
prob-res-com-EVE
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
2217
569
2390
602
prob-cbd-cbd-EM
prob-cbd-cbd-EM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2217
602
2390
635
prob-cbd-com-EM
prob-cbd-com-EM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2217
635
2390
668
prob-cbd-res-EM
prob-cbd-res-EM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2217
668
2392
701
prob-com-com-EM
prob-com-com-EM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2217
700
2392
733
prob-com-cbd-EM
prob-com-cbd-EM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2217
732
2392
765
prob-com-res-EM
prob-com-res-EM
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
2217
765
2392
798
prob-res-res-EM
prob-res-res-EM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2217
799
2392
832
prob-res-cbd-EM
prob-res-cbd-EM
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
2217
832
2392
865
prob-res-com-EM
prob-res-com-EM
0
1
0.0
0.01
1
NIL
HORIZONTAL

TEXTBOX
1903
537
1970
557
PM Peak
15
14.0
1

TEXTBOX
2088
535
2158
555
Evening
15
14.0
1

TEXTBOX
2257
535
2362
555
Early Morning
15
14.0
1

MONITOR
1498
864
1633
909
AM Peak Marginal
prob-cbd-com-AM + prob-cbd-res-AM + prob-cbd-cbd-AM + \nprob-com-cbd-AM + prob-com-res-AM + prob-com-com-AM \n+ prob-res-cbd-AM +  prob-res-com-AM + prob-res-res-AM
2
1
11

MONITOR
1690
865
1825
910
Midday Marginal
prob-cbd-com-MD + prob-cbd-res-MD + prob-cbd-cbd-MD + \nprob-com-com-MD + prob-com-res-MD + prob-com-com-MD\n+ prob-res-cbd-MD +  prob-res-com-MD + prob-res-res-MD
2
1
11

MONITOR
1873
867
2008
912
PM Peak Marginal
prob-cbd-com-PM + prob-cbd-res-PM + prob-cbd-cbd-PM + \nprob-com-cbd-PM + prob-com-res-PM + prob-com-com-PM \n+ prob-res-cbd-PM +  prob-res-com-PM + prob-res-res-PM
2
1
11

MONITOR
2054
865
2189
910
Evening Marginal
prob-cbd-com-EVE + prob-cbd-res-EVE + prob-cbd-cbd-EVE + \nprob-com-cbd-EVE + prob-com-res-EVE + prob-com-com-EVE \n+ prob-res-cbd-EVE +  prob-res-com-EVE + prob-res-res-EVE
2
1
11

MONITOR
2237
867
2372
912
Early Morning Marginal
prob-cbd-com-EM + prob-cbd-res-EM + prob-cbd-cbd-EM + \nprob-com-cbd-EM + prob-com-res-EM + prob-com-com-EM \n+ prob-res-cbd-EM +  prob-res-com-EM + prob-res-res-EM
2
1
11

INPUTBOX
20
245
125
305
wait-time-mean
50.0
1
0
Number

INPUTBOX
130
245
248
305
wait-time-sd
10.0
1
0
Number

SLIDER
-1
392
259
425
first-passenger-cost
first-passenger-cost
0
10
0.78
0.01
1
$
HORIZONTAL

SLIDER
-1
426
259
459
each-additional-passenger-cost
each-additional-passenger-cost
0
5
0.49
0.01
1
$
HORIZONTAL

SLIDER
-1
459
259
492
each-grid-cost
each-grid-cost
0
10
0.93
0.01
1
$
HORIZONTAL

SLIDER
-1
492
259
525
each-tick-cost
each-tick-cost
0.01
5
0.5
0.01
1
$
HORIZONTAL

TEXTBOX
9
316
257
388
Fare Calculation:\n- First passenger: $1\n- Each additional passenger: $0.5\n- Each additional grid: $1\n- Every tick of time elapsed: $0.5
11
0.0
1

TEXTBOX
11
209
267
251
Passenger Patience:\nNormal Distribution Parameters
11
0.0
1

PLOT
1230
10
1795
263
Taxicabs Travelling Distance
NIL
Miles
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total Miles" 1.0 0 -16777216 true "" "plot sum [num-total-miles] of taxicabs"
"Business Miles" 1.0 0 -13840069 true "" "plot sum [num-business-miles] of taxicabs"
"Dead Miles" 1.0 0 -2674135 true "" "plot sum [num-dead-miles] of taxicabs"

PLOT
1229
260
1409
410
Trip Income Distribution
NIL
NIL
0.0
300.0
0.0
10.0
true
false
"set-histogram-num-bars 30" ""
PENS
"Trip Income" 1.0 1 -4079321 true "" "histogram reduce sentence [trip-income-lst] of taxicabs"

PLOT
1405
260
1597
410
Trip Distance Distribution
NIL
NIL
0.0
300.0
0.0
10.0
true
false
"set-histogram-num-bars 30" ""
PENS
"default" 1.0 1 -5825686 true "" "histogram reduce sentence [trip-distance-lst] of taxicabs"

PLOT
1595
260
1795
410
Trip Duration Distribution
NIL
NIL
0.0
300.0
0.0
10.0
true
false
"set-histogram-num-bars 30" ""
PENS
"default" 1.0 1 -14835848 true "" "histogram reduce sentence [trip-duration-lst] of taxicabs"

TEXTBOX
1257
537
1407
556
Origin
15
14.0
1

TEXTBOX
1353
538
1503
557
Destination
15
14.0
1

TEXTBOX
1260
570
1297
589
CBD
15
0.0
1

TEXTBOX
1377
570
1527
589
CBD
15
0.0
1

TEXTBOX
1262
603
1412
622
CBD
15
0.0
1

TEXTBOX
1354
603
1504
622
Commercial
15
0.0
1

TEXTBOX
1362
635
1512
654
Residential\n
15
0.0
1

TEXTBOX
1357
668
1507
687
Commercial
15
0.0
1

TEXTBOX
1359
734
1509
753
Residential
15
0.0
1

TEXTBOX
1377
700
1527
719
CBD
15
0.0
1

TEXTBOX
1357
770
1507
789
Residential
15
0.0
1

TEXTBOX
1378
804
1528
823
CBD
15
0.0
1

TEXTBOX
1359
835
1509
854
Commercial
15
0.0
1

TEXTBOX
1262
633
1412
652
CBD
15
0.0
1

TEXTBOX
1242
668
1392
687
Commercial
15
0.0
1

TEXTBOX
1244
700
1394
719
Commercial
15
0.0
1

TEXTBOX
1243
734
1393
753
Commercial\t
15
0.0
1

TEXTBOX
1247
772
1397
791
Residential
15
0.0
1

TEXTBOX
1248
803
1398
822
Residential
15
0.0
1

TEXTBOX
1247
835
1397
854
Residential
15
0.0
1

@#$#@#$#@
## WHAT IS IT?

The model mimics taxi cab ridership in an urban area. Users can control ridership demand, fleet size, traffic rules, and fare calculation. The model aims to reveal insights into taxi cab profitability based on trip characteristics and demand dynamics.

## HOW IT WORKS

The urban area is portrayed as a grid system, which is formed by two-lane roads and intersections. The metropolitan area consists of three regions: (1) Central Business District (in orange), (2) Commercial Zone (in blue), and (3) Residential Zone (in grey). The three regions can form nine origin-destination (OD) pairs, with six pairs of inter-regional flows and three pairs of intra-regional flows.

Since taxi demands for each type of flow can be dramatically different based on the time of a day, users can control the amount of flow from regions to regions through the interface.

Potential passenger(s) show up on roads controlled by users. When a vacant taxicab happens to pass by, it stops and pickups the passenger(s). The passenger(s) inform the taxicab of the destination coordinate, and the taxi turns light-purple and starts the trip. The taxi will travel from the pickup coordinate to the light-purple colored drop-off coordinate by the shortest Manhattan distance and complete the trip when it arrives at the destination coordinate.

After finishing a trip, the taxi becomes vacant and searches for the next passenger(s) by traveling randomly on roads.

## HOW TO USE IT

### Taxicab Demand
* Spatial Flow and Time Interval:
- _Time Interval_: The flow of residents in an urban area between regions can be quite different depending on the time of day. To indicate the differences in the spatial flow of taxi trips between regions throughout the day, a clock is created to keep track of the time in the world. Five distinct time intervals are implemented (1) AM Peak, (2) Midday, (3) PM Peak, (4) Evening, (5) Early Morning. A reporter shows the current time interval in the interface, and the length of each time interval can be controlled by a slider called LENGTH-OF-TIME-PERIOD.
- _Spatial Flow_: Demand for taxicabs in city districts can be variable, and different amounts of flows can be manipulated by users through the spatial flow sliders, which control the probability (or proportion) of trips that are going from an origin to a destination during a specific time interval. For such purposes, each time interval's marginal probabilities are shown by a reporter at the bottom of each slider column to remind the users that the marginal probability should sum to 1.

### Traffic Rules
* Traffic Lights: the length of red/green lights can be controlled by a slider in the interface called LENGTH-OF-GREEN-LIGHT.

### Passengers
* Passenger waiting time is modeled by a normal distribution. The parameters of this normal distribution can be input by users in the interface through WAIT-TIME-MEAN and WAIT-TIME-SD.

### Taxicabs
* Fleet size: taxicab fleet size can be controlled by a slider NUM-TAXICABS.

* Trip Fare: Trip fare is calculated based on Chicago Yellow Taxicab. Trip fare is mainly calculated by three different variables: (1) the number of passengers on-board, (2) the number of miles traveled, (3) the trip duration. These cost variables can be determined by users in the interface using FIRST-PASSENGER-COST, EACH-ADDITIONAL-PASSENGER-COST, EACH-GRID-COST, and EACH-TICK-COST.

## THINGS TO NOTICE

As the model runs, the trade-off between business miles and dead miles can be contrasting. The distributions of trip income, distance, and duration should be correlated, and the overall shapes of the distribution are susceptible to the changes in traffic rules and interval lengths.

## THINGS TO TRY

For a clear visualization of the pickup and dropoff process, it is suggested to start with one taxicab to see how a taxicab behaves before generating multiple taxicabs.

## EXTENDING THE MODEL

There are many ways to extend this model. Interesting avenues would be to use real-world data with the GIS extension, more complex searching strategies, such as using AI tools, and including rideshare systems such as Uber or Lyft in the model, to better understand the relation between taxicabs and the rideshare systems.

Some other meaningful extension specific to taxicabs is to figure out how to reduce the number of dead miles -- miles traveled by taxicabs with no passengers on-board. Dead miles are costly to drivers because drivers need to internalize vehicle depreciation and gasoline price while searching for passengers. Figuring out more intelligent searching strategies such as locating the next passenger immediately after the last dropoff will be meaningful to pursue.

## NETLOGO FEATURES

Each road in the model is formed by two lanes, with each lane allowing taxicabs to travel in one direction. When delivering passengers, taxicabs will make U-turns to put themselves in the right direction to start the delivery following the shortest Manhattan distance. Some workarounds can be done to avoid making the u-turns.

## RELATED MODELS

- "Traffic Basic": a simple model of the movement of cars on a highway.
- "Traffic Basic Utility": a version of "Traffic Basic" including a utility function for the cars.
- "Traffic 2 Lanes": a more sophisticated two-lane version of the "Traffic Basic" model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Ping, D. and Wilensky, U. (2019).  NetLogo Taxi Cabs model.  http://ccl.northwestern.edu/netlogo/models/TaxiCabs.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

This model was developed as part of the Spring 2019 Multi-agent Modeling course offered by Dr. Uri Wilensky at Northwestern University. For more info, visit http://ccl.northwestern.edu/courses/mam/. Special thanks to Teaching Assistants Sugat Dabholkar, Can Gurkan, and Connor Bain.

## COPYRIGHT AND LICENSE

Copyright 2019 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2019 MAM2019 Cite: Ping, D. -->
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
