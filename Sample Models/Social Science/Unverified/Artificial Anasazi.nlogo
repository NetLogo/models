breed [ historical-settlements historical-settlement ] ; historical occupation
breed [ households household ]
breed [ water-points water-point ]

patches-own [
  water-source
  zone
  zone-pcolor
  apdsi
  hydro
  quality
  maize-zone
  yield
  base-yield
  num-occupying-farms
  num-occupying-households
]

historical-settlements-own [
  sarg                 ; an ID number relating to data collected by the
                       ;   "Southwestern Anthropological Research Group"
                       ;   (unused by the simulation, left for reference)
  meter-north          ; real world location measurements
  meter-east           ; real world location measurements
  start-date           ; historical start date
  end-date             ; historical end date
  median-date          ; historical median date
  settlement-type      ; extra historical data from the file (unused)
  settlement-size      ; extra historical data from the file (unused)
  description          ; extra historical data from the file (unused)
  room-count           ; extra historical data from the file (unused)
  elevation            ; extra historical data from the file (unused)
  baseline-households  ; baseline number of households
  number-of-households ; "current" number of households
]

households-own [
  farm-x
  farm-y
  farm-plot
  last-harvest
  estimate
  age
  fertility-age
  aged-corn-stocks
  nutrition-need
  nutrition-need-remaining]

water-points-own [
  sarg
  meter-north
  meter-east
  water-type
  start-date
  end-date
]

globals [
  year
  min-death-age
  max-death-age
  min-fertility-ends-age
  max-fertility-ends-age
  min-fertility
  max-fertility
  household-min-nutrition-need
  household-max-nutrition-need
  min-fertility-age
  max-fertility-age
  household-min-initial-age
  household-max-initial-age
  household-min-initial-corn
  household-max-initial-corn
  potential
  potential-farms
  best-farm streams-exist?
  alluvium-exist?
  farm-sites-available
  total-households
  historical-total-households
  environment-data
  apdsi-data
  map-data
  settlements-data
  water-data
  typical-household-size
  base-nutrition-need
  maize-gift-to-child
  water-source-distance
  years-of-stock
]

to setup
  clear-all
  set-default-shape historical-settlements "house"
  set-default-shape households "person"
  load-map-data
  set streams-exist? false
  set alluvium-exist? false
  set year 800

  ; variable that count the number of sites available for farming
  set farm-sites-available 0

  ask patches [
    set water-source 0
    set quality ((random-normal 0 1) * harvest-variance) + 1.0
    if quality < 0 [ set quality 0 ]
  ]
  set typical-household-size 5 ; a household consist of 5 persons
  set base-nutrition-need 160   ; a person needs 160 kg of food (corn) each year

  ; The original model allowed for many of these parameters to take on a range of
  ; values, rather than just a single value. To simplify the model interface, and
  ; keep the number of parameters modest, most of these "min- and max-"  variables
  ; are set to matching values during SETUP. The min/max variables are left here in
  ; the code, in case you want to explore more variation in these parameters.
  set household-min-nutrition-need (base-nutrition-need * typical-household-size)
  set household-max-nutrition-need (base-nutrition-need * typical-household-size)

  ; when household agents can start to reproduce. (reproduction means here
  ; that a daughter leaves the household to start a new household)
  set min-fertility-age 16

  set max-fertility-age 16
  set min-death-age death-age ;maximum age of a household
  set max-death-age death-age
  set min-fertility-ends-age fertility-ends-age ; agent stop reproducing at this age
  set max-fertility-ends-age fertility-ends-age
  set min-fertility fertility ; probability that a fertile agent reproduces
  set max-fertility fertility
  set maize-gift-to-child 0.33 ; a new household gets part of the storage of the parent household
  set water-source-distance 16.0 ; agents like to live within a certain distance of the water
  set years-of-stock 2 ; number of years corn that can be stored.
  set household-min-initial-age 0 ; to determine ages of initial households
  set household-max-initial-age 29
  set household-min-initial-corn 2000 ; to determine storage of initial households
  set household-max-initial-corn 2400

  ask historical-settlements [ hide-turtle ] ; don't show historical sites
  water ; calculate water availability for initial timestep
  calculate-yield ; calculate yeild
  ask patches [ set base-yield yield * quality ]

  determine-potential-farms ; determine how many farms could be on the land
  ; initialization of 14 households (based on the initial data) and put them randomly on the landscape
  create-households 14 [
    set farm-x random 80
    set farm-y random 120
    init-household
  ]
  estimate-harvest
  show-settlements-on-map
  set historical-total-households 0
  if historic-view? [ show-historical-population ]
  reset-ticks
end

to go
  if year > 1350 [ stop ]
  set historical-total-households 0
  set total-households 0
  calculate-yield

  ; potential amount of households based on level of base-yield (dependent on PSDI and water availability)
  set potential count patches with [ base-yield >= household-min-nutrition-need ]

  if historic-view? [ show-historical-population ]
  calculate-harvest-consumption
  check-death
  estimate-harvest
  ask households [
    ; agents who expect not to have sufficient food next timestep move to a new spot
    ; (if available). If no spots are available, they leave the system.
    if estimate < nutrition-need [
      ; we have to check everytime whether locations are available for moving agents.
      ; Could be implemented more efficiently by only updating selected info
      determine-potential-farms
      ask patch farm-x farm-y [ set num-occupying-farms 0 ]
      find-farm-and-settlement
    ]
  ]
  determine-potential-farms
  ask households [
    if (age > fertility-age) and
      (age <= fertility-ends-age) and
      (random-float 1.0 < fertility) [
      if length potential-farms > 0 [
        determine-potential-farms
        fissioning
      ]
    ]
  ]
  set total-households count households
  water
  show-settlements-on-map
  set year year + 1
  tick
end

to init-household
  ; Initialization of households which derive initial storage, age, amount of
  ; nutrients needed, etc. This procedure also finds a spot for the farming
  ; plots and settlements on the initial landscape
  set best-farm self
  set aged-corn-stocks []
  set aged-corn-stocks fput (household-min-initial-corn + random-float (household-max-initial-corn - household-min-initial-corn)) aged-corn-stocks
  set aged-corn-stocks fput (household-min-initial-corn + random-float (household-max-initial-corn - household-min-initial-corn)) aged-corn-stocks
  set aged-corn-stocks fput (household-min-initial-corn + random-float (household-max-initial-corn - household-min-initial-corn)) aged-corn-stocks
  set farm-plot self
  set age household-min-initial-age + random (household-max-initial-age - household-min-initial-age)
  set nutrition-need household-min-nutrition-need + random (household-max-nutrition-need - household-min-nutrition-need)
  set fertility-age min-fertility-age + random (max-fertility-age - min-fertility-age)
  set death-age min-death-age + random (max-death-age - min-death-age)
  set fertility-ends-age min-fertility-ends-age + random (max-fertility-ends-age - min-fertility-ends-age)
  set fertility min-fertility + random-float (max-fertility - min-fertility)
  set last-harvest 0
  find-farm-and-settlement
end

to find-farm-and-settlement
  ; find a new spot for the settlement (might remain the same location as before)
  let still-hunting? true
  let x 0
  let y 0
  ifelse length potential-farms = 0 [ ; If there were no potential farms, the agent is removed from the system.
    ask patch-here [ set num-occupying-households num-occupying-households - 1 ]
    ask patch farm-x farm-y [ set num-occupying-farms 0 ]
    die
  ]
  [ ; otherwise (there are potential farm spots), we proceed to find a suitable one
    set best-farm determine-best-farm
    let best-yield [ yield ] of best-farm
    set farm-x [ pxcor ] of best-farm
    set farm-y [ pycor ] of best-farm
    set farm-plot best-farm
    ask patch farm-x farm-y [
      set num-occupying-farms 1
    ]
    if count patches with [ water-source = 1 and num-occupying-farms = 0 and yield < best-yield ] > 0 [
      ;if there are cells with water which are not farmed and in a zone that is less productive than the zone where the favorite farm plot is located
      ask min-one-of patches with [ water-source = 1 and num-occupying-farms = 0 and yield < best-yield ] [ distance best-farm ] [ ; find the most nearby spot
        if distance best-farm <= water-source-distance [set x pxcor set y pycor set still-hunting? false]
      ]
      if not still-hunting? [
        ask min-one-of patches with [ num-occupying-farms = 0 and hydro <= 0 ] [ distancexy x y ] [ ; if the favorite location is nearby move to that spot
          set x pxcor
          set y pycor
          set num-occupying-households num-occupying-households + 1
        ]
      ]
    ]
    if still-hunting? [ ; if no settlement is found yet
      ; find a location that is not farmed with nearby water (but this might be in the same zone as the farm plot)
      ask min-one-of patches with [ num-occupying-farms = 0 ] [ distance best-farm ] [
        if distance best-farm <= water-source-distance [
          set x pxcor
          set y pycor
          set still-hunting? false
        ]
      ]
      if not still-hunting?  [
        ask min-one-of patches with [ num-occupying-farms = 0 and hydro <= 0 ] [ distancexy x y ] [
          set x pxcor
          set y pycor
          set num-occupying-households num-occupying-households + 1
        ]
      ]
    ]
    if still-hunting? [ ; if still no settlement is found try to find a location that is not farmed even if this is not close to water
      ask min-one-of patches with [ num-occupying-farms = 0 ] [ distance best-farm ] [
        set x pxcor
        set y pycor
        set still-hunting? false
      ]
      if not still-hunting? [
        ask min-one-of patches with [ num-occupying-farms = 0 and hydro <= 0 ] [ distancexy x y ] [
          set x pxcor
          set y pycor
          set num-occupying-households num-occupying-households + 1
        ]
      ]
    ]
    if still-hunting? [ ;if no possible settlement is found, leave the system
      ask patch farm-x farm-y [ set num-occupying-farms 0 ]
      die ; note: once the running agent dies, it stops executing code
    ]
    set xcor x
    set ycor y
    ask patch-here [
      set num-occupying-households num-occupying-households + 1
    ]
  ]
end

to determine-potential-farms
  ;; Determine the list of potential locations for a farm to move to.
  ;; A potential location to farm is a place where nobody is farming
  ;;   and where the base-yield is higher than the minimum amount of food needed
  ;;   and where nobody has build a settlement
  set potential-farms []
  ask patches with [(zone != "Empty") and (num-occupying-farms = 0) and (num-occupying-households = 0) and (base-yield >= household-min-nutrition-need) ] [
    set potential-farms lput self potential-farms
  ]
  set farm-sites-available length potential-farms
end

to-report determine-best-farm
  ; the agent likes to go to the potential farm which is closest nearby existing farm
  let existing-farm patch farm-x farm-y
  let distance-to-best 1000
  foreach potential-farms [ farm ->
    ask farm [
      if distance existing-farm < distance-to-best [
        set best-farm self
        set distance-to-best distance existing-farm
      ]
    ]
  ]
  if length potential-farms > 0 [
    set potential-farms remove best-farm potential-farms
  ]
  report best-farm
end

to fissioning
  ; creates a new agent and update relevant info from new and parent agent. Agent will farm at a nearby available location
  let ys years-of-stock
  while [ ys > -1 ] [
    set aged-corn-stocks replace-item ys aged-corn-stocks ((1 - maize-gift-to-child) * (item ys aged-corn-stocks))
    set ys ys - 1
  ]
  hatch 1 [
    init-household
    set age 0 ;override the value derived in init-household since this will be a fresh household
    set ys years-of-stock
    while [ ys > -1 ] [
      set aged-corn-stocks replace-item ys aged-corn-stocks ((maize-gift-to-child / (1 - maize-gift-to-child)) * (item ys aged-corn-stocks))
      set ys ys - 1
    ]
  ]
end

to load-map-data
  ifelse ( file-exists? "data/map.txt" ) [
    set map-data []
    file-open "data/map.txt"
    while [ not file-at-end? ] [
      set map-data sentence map-data (list (list file-read))
    ]
    file-close
  ]
  [ user-message "There is no map.txt file in the data directory!" ]

  ;; the map data file is stored in specific order, so we have to assign it to patches in that order,
  ;; which is accomplished by manipulating the yy and xx variables each time through the loop.
  let yy 119
  let xx 0
  foreach map-data [ map-values ->
    let map-value first map-values
    if map-value = 0  [ ask patch xx yy [ set zone-pcolor black set zone "General"     set maize-zone "Yield_2"   ] ] ; General Valley
    if map-value = 10 [ ask patch xx yy [ set zone-pcolor red   set zone "North"       set maize-zone "Yield_1"   ] ] ; North Valley
    if map-value = 15 [ ask patch xx yy [ set zone-pcolor white set zone "North Dunes" set maize-zone "Sand_dune" ] ] ; North Valley ; Dunes
    if map-value = 20 [ ask patch xx yy [ set zone-pcolor gray  set zone "Mid"
      ifelse xx <= 74
        [ ask patch xx yy [ set maize-zone "Yield_1" ] ]
        [ ask patch xx yy [ set maize-zone "Yield_2" ] ]
      ]
    ] ; Mid Valley
    if map-value = 25 [ ask patch xx yy [ set zone-pcolor white  set zone "Mid Dunes" set maize-zone "Sand_dune" ] ] ; Mid Valley ; Dunes
    if map-value = 30 [ ask patch xx yy [ set zone-pcolor yellow set zone "Natural"   set maize-zone "No_Yield"  ] ] ; Natural
    if map-value = 40 [ ask patch xx yy [ set zone-pcolor blue   set zone "Uplands"   set maize-zone "Yield_3"   ] ] ; Uplands Arable
    if map-value = 50 [ ask patch xx yy [ set zone-pcolor pink   set zone "Kinbiko"   set maize-zone "Yield_1"   ] ] ; Kinbiko Canyon
    if map-value = 60 [ ask patch xx yy [ set zone-pcolor white  set zone "Empty"     set maize-zone "Empty"     ] ] ; Empty
    ifelse yy > 0
      [ set yy yy - 1 ]
      [ set xx xx + 1 set yy 119 ]
  ]
  ask patches [ set pcolor zone-pcolor ]

  ; The order of the data from the file is:
  ;  SARG number, meters north, meters east, start date, end date, median date (1950 - x), type, size, description, room count, elevation, baseline households
  ifelse file-exists? "data/settlements.txt" [
    set settlements-data []
    file-open "data/settlements.txt"
    while [ not file-at-end? ] [
      set settlements-data sentence settlements-data (list (n-values 12 [ file-read ]))
    ]
    file-close
  ]
  [ user-message "There is no settlements.txt file in the data directory!" ]

  foreach settlements-data [ settlement-data ->
    create-historical-settlements 1 [
      set sarg item 0 settlement-data
      set meter-north item 1 settlement-data
      set meter-east item 2 settlement-data
      set start-date item 3 settlement-data
      set end-date item 4 settlement-data
      set median-date (1950 - item 5 settlement-data)
      set settlement-type item 6 settlement-data
      set settlement-size item 7 settlement-data
      set description item 8 settlement-data
      set room-count item 9 settlement-data
      set elevation item 10 settlement-data
      set baseline-households item 11 settlement-data
    ]
  ]

  ; number, meters north, meters east, type, start date, end date
  ifelse file-exists? "data/water.txt" [
    set water-data []
    file-open "data/water.txt"
    while [ not file-at-end? ] [
      set water-data sentence water-data (list (n-values 6 [file-read]))
    ]
    file-close
  ]
  [ user-message "There is no water.txt file in the data directory!" ]

  foreach water-data [ data ->
    create-water-points 1 [
      set sarg item 0 data
      set meter-north item 1 data
      set meter-east item 2 data
      set water-type item 3 data
      set start-date item 4 data
      set end-date item 5 data
    ]
  ]

  ask water-points [
    set xcor 24.5 + int ((meter-east - 2392) / 93.5)
    set ycor 45 + int (37.6 + ((meter-north - 7954) / 93.5))
    hide-turtle
  ]

  ; Import adjusted pdsi.
  ifelse file-exists? "data/adjustedPDSI.txt" [
    set apdsi-data []
    file-open "data/adjustedPDSI.txt"
    while [ not file-at-end? ] [
      set apdsi-data sentence apdsi-data (list file-read)
    ]
    file-close
  ]
  [ user-message "There is no adjustedPDSI.txt file in the data directory!" ]

 ; Import environment
 ifelse file-exists? "data/environment.txt" [
   set environment-data []
   file-open "data/environment.txt"
   while [ not file-at-end? ] [
     set environment-data sentence environment-data (list (n-values 15 [ file-read ]))
   ]
   file-close
 ]
 [ user-message "There is no environment.txt file in the data directory!" ]

 ask patches [
   set num-occupying-farms 0
   set num-occupying-households 0
 ]
end

to water
  ; define for each location when water is available
  ifelse ((year >= 280 and year < 360) or (year >= 800 and year < 930) or (year >= 1300 and year < 1450))
    [ set streams-exist? 1 ]
    [ set streams-exist? 0 ]
  ifelse (((year >= 420) and (year < 560)) or ((year >= 630) and (year < 680)) or ((year >= 980) and (year < 1120)) or ((year >= 1180) and (year < 1230)))
    [ set alluvium-exist? 1 ]
    [ set alluvium-exist? 0 ]

  ask patches [
    set water-source 0
    if (alluvium-exist? = 1) and ((zone = "General") or (zone = "North") or (zone = "Mid") or (zone = "Kinbiko")) [
      set water-source 1
    ]
    if (streams-exist? = 1) and (zone = "Kinbiko") [
      set water-source 1
    ]
  ]

  ask (patch-set (patch 72 114) (patch 70 113) (patch 69 112) (patch 68 111) (patch 67 110) (patch 66 109) (patch 65 108) (patch 65 107)) [
    set water-source 1
  ]

  ask water-points [
    if water-type = 2 [
      ask patch xcor ycor [ set water-source 1 ]
    ]
    if water-type = 3 [
      if year >= start-date and year <= end-date [
        ask patch xcor ycor [ set water-source 1 ]
      ]
    ]
  ]

  if map-view = "water sources" [
    ask patches [
      ifelse water-source = 1
        [ set pcolor blue ]
        [ set pcolor white ]
    ]
  ]
end

to calculate-yield
  ; calculate the yield and whether water is available for each patch based on the APDSI and water availability data.
  let generalapdsi item (year - 200) apdsi-data
  let northapdsi item (1100 + year) apdsi-data
  let midapdsi item (2400 + year) apdsi-data
  let naturalapdsi item (3700 + year) apdsi-data
  let uplandapdsi item (3700 + year) apdsi-data
  let kinbikoapdsi item (1100 + year) apdsi-data

  let generalhydro item 1 (item (year - 382) environment-data)
  let northhydro item 4 (item (year - 382) environment-data)
  let midhydro item 7 (item (year - 382) environment-data)
  let naturalhydro item 10 (item (year - 382) environment-data)
  let uplandhydro item 10 (item (year - 382) environment-data)
  let kinbikohydro item 13 (item (year - 382) environment-data)

  ask patches [
    if zone = "General" [ set apdsi generalapdsi ]
    if zone = "North"   [ set apdsi northapdsi   ]
    if zone = "Mid"     [ set apdsi midapdsi     ]
    if zone = "Natural" [ set apdsi naturalapdsi ]
    if zone = "Upland"  [ set apdsi uplandapdsi  ]
    if zone = "Kinbiko" [ set apdsi kinbikoapdsi ]

    if zone = "General" [ set hydro generalhydro ]
    if zone = "North"   [ set hydro northhydro   ]
    if zone = "Mid"     [ set hydro midhydro     ]
    if zone = "Natural" [ set hydro naturalhydro ]
    if zone = "Upland"  [ set hydro uplandhydro  ]
    if zone = "Kinbiko" [ set hydro kinbikohydro ]

    if maize-zone = "No_Yield" or maize-zone = "Empty" [ set yield 0 ]
    if maize-zone = "Yield_1" [
      if apdsi >=  3.0 [ set yield 1153 ]
      if apdsi >=  1.0 and apdsi < 3.0 [ set yield 988 ]
      if apdsi >  -1.0 and apdsi < 1.0 [ set yield 821 ]
      if apdsi >  -3.0 and apdsi <= -1.0 [ set yield 719 ]
      if apdsi <= -3.0 [ set yield 617 ]
    ]

    if maize-zone = "Yield_2" [
      if apdsi >=  3.0 [ set yield 961 ]
      if apdsi >=  1.0 and apdsi < 3.0 [ set yield 824 ]
      if apdsi >  -1.0 and apdsi < 1.0 [ set yield 684 ]
      if apdsi >  -3.0 and apdsi <= -1.0 [ set yield 599 ]
      if apdsi <= -3.0 [ set yield 514 ]
    ]

    if maize-zone = "Yield_3" [
      if apdsi >=  3.0 [ set yield 769 ]
      if apdsi >=  1.0 and apdsi < 3.0 [ set yield 659 ]
      if apdsi >  -1.0 and apdsi < 1.0 [ set yield 547 ]
      if apdsi > -3.0 and apdsi <= -1.0 [ set yield 479 ]
      if apdsi <= -3.0 [ set yield 411 ]
    ]

    if maize-zone = "Sand_dune" [
      if apdsi >=  3.0 [ set yield 1201 ]
      if apdsi >=  1.0 and apdsi < 3.0 [ set yield 1030 ]
      if apdsi >  -1.0 and apdsi < 1.0 [ set yield 855 ]
      if apdsi >  -3.0 and apdsi <= -1.0 [ set yield 749 ]
      if apdsi <= -3.0 [ set yield 642 ]
    ]

    if map-view = "yield" [ set pcolor (40 + base-yield / 140) ]
    if map-view = "zones" [ set pcolor zone-pcolor ]
  ]
end

to estimate-harvest
  ; calculate the expected level of food available for agent based on current stocks of corn and estimate of harvest of next year (equal to actual amount current year)
  ask households [
    let total 0
    let ys years-of-stock - 1
    while [ ys > -1 ] [
      set total total + item ys aged-corn-stocks
      set ys ys - 1
    ]
    set estimate total + last-harvest
  ]
end

to calculate-harvest-consumption
  ; calculate first for each cell the base yield, and then the actual harvest of households. Update the stocks of corn available in storage.
  ask patches [ set base-yield (yield * quality * harvest-adjustment) ]
  ask households [
    set last-harvest [ base-yield ] of patch farm-x farm-y * (1 + ((random-normal 0 1) * harvest-variance))
    set aged-corn-stocks replace-item 2 aged-corn-stocks (item 1 aged-corn-stocks)
    set aged-corn-stocks replace-item 1 aged-corn-stocks (item 0 aged-corn-stocks)
    set aged-corn-stocks replace-item 0 aged-corn-stocks last-harvest
    set nutrition-need-remaining nutrition-need
    set age age + 1
  ]

  ; for each household calculate how much nutrients they can derive from harvest and stored corn
  ask households [
    let ys years-of-stock
    while [ys > -1] [
      ifelse (item ys aged-corn-stocks) >= nutrition-need-remaining [
        set aged-corn-stocks replace-item ys aged-corn-stocks (item ys aged-corn-stocks - nutrition-need-remaining)
        set nutrition-need-remaining 0
      ]
      [ set nutrition-need-remaining (nutrition-need-remaining - item ys aged-corn-stocks)
        set aged-corn-stocks replace-item ys aged-corn-stocks 0
      ]
      set ys ys - 1
    ]
  ]
end

to check-death
  ; agents who have not sufficient food derived or are older than death-age are removed from the system
  ask households [
    if nutrition-need-remaining > 0 or age > death-age [
      ask patch farm-x farm-y [ set num-occupying-farms 0 ]
      ask patch-here [ set num-occupying-households num-occupying-households - 1 ]
      die
    ]
  ]
end

to show-historical-population
  ; define the location and amount of households according to observations.
  ask historical-settlements [
    if settlement-type = 1 [
      set number-of-households 0
      ifelse year >= start-date and year < end-date [
        show-turtle
        if year > median-date [
          if year != median-date [
            set number-of-households ceiling (baseline-households * (end-date - year) / (end-date - median-date))
            if number-of-households < 1 [
              set number-of-households 1
            ]
          ]
        ]
        if year <= median-date [
          if median-date != start-date [
            set number-of-households ceiling (baseline-households * (year - start-date) / (median-date - start-date))
            if number-of-households < 1 [
              set number-of-households 1
            ]
          ]
        ]
      ]
      [ hide-turtle ]
      set historical-total-households historical-total-households + number-of-households
      set xcor (24.5 + (meter-east - 2392) / 93.5) ; this is a translation from the input data in meters into location on the map.
      set ycor 45 + (37.6 + (meter-north - 7954) / 93.5)
      set size 2 * sqrt number-of-households ; using SQRT makes area of the turtle proportional to the number of households
    ]
  ]
end

to show-settlements-on-map
  ; visualize the locations of farming and settlements
  if map-view = "occupancy" [
    ask patches [
      ifelse num-occupying-households > 0 [
        set pcolor red
      ]
      [ ifelse num-occupying-farms = 1
          [ set pcolor yellow ]
          [ set pcolor black ]
      ]
    ]
  ]
end


; Copyright 2010 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
480
10
808
499
-1
-1
4.0
1
10
1
1
1
0
1
1
1
0
79
0
119
1
1
1
year
30.0

BUTTON
280
30
370
63
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
280
70
370
103
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

PLOT
10
245
465
520
Population
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"sim. households" 1.0 0 -2674135 true "" "plot total-households"
"historical data" 1.0 0 -13345367 true "" "plot historical-total-households"

CHOOSER
245
165
392
210
map-view
map-view
"zones" "water sources" "yield" "occupancy"
0

SLIDER
15
145
195
178
harvest-adjustment
harvest-adjustment
0
1
0.54
0.01
1
NIL
HORIZONTAL

SLIDER
15
185
196
218
harvest-variance
harvest-variance
0
1
0.4
0.01
1
NIL
HORIZONTAL

SLIDER
20
90
192
123
death-age
death-age
26
40
38.0
1
1
NIL
HORIZONTAL

SLIDER
20
10
192
43
fertility-ends-age
fertility-ends-age
26
36
34.0
1
1
NIL
HORIZONTAL

SLIDER
20
50
192
83
fertility
fertility
0
0.2
0.155
0.001
1
NIL
HORIZONTAL

SWITCH
245
115
392
148
historic-view?
historic-view?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model simulates the population dynamics in the Long house Valley in Arizona between 800 and 1400. It is based on archaeological records of occupation in Long House Valley and shows that environmental variability alone can not explain the population collapse around 1350. The model is a replication of the work of Dean et al. (see references below).

## HOW IT WORKS

### Agents and the environment

Each agent represents a household of five persons. Each household makes annual decisions on where to farm and where to settle. A household has an age, and a stock of food surplus
previous years. Each cell represents a 100 meter by 100 meter space. Each cell is within one of the different zones of land: General Valley Floor, North Valley Floor, Midvalley Floor, Arable Uplands, Uplands Non-Arable, Kinbiko Canyon or Dunes. These zones have agricultural productivity that is determined by the Palmer Drought Severity Index (PDSI).

### Initialization

The initial number of households is 14. Each household is initialized by setting a household age from the uniform distribution [0, 29] and by setting the value of the corn stocks by the uniform distribution [2000, 2400].  The quality of the soil of the cells is initialized by adding a number drawn from the normal distribution with standard deviation specified by HARVEST-VARIANCE.


### Process overview

Every year the following sequence of calculations is performed:

  1. calculate the harvest for each household
  2. if agent derives not sufficient food from harvest and storage or the age is beyond maximum age of household the agent is removed from the system
  3. calculate the estimated harvest for next year based on corn in stock and actual harvest from current year
  4. agents who expect not to derive the required amount of food next year will move to a new farm location.
  5. find a farm plot
  6. find a plot to settle nearby
  7. if a household is older than the minimum fission age, there is a probability pf, that a new household is generated. The new household will derive an endowment of a fraction of the corn stock.
  8. update water sources based on input data
  9. the household's age increases by one year

### Design concepts
  * _Adaptation_. Agents adjust the location of farming and housing if they expect that current location is not sufficient next year.
  * _Prediction_. The prediction of harvest next year is the same as the experienced harvest from this year.
  * _Fitness_. Fitness of agent is determined by the amount of harvest derived and amount of corn in storage. An agent is either considered to be "fit" or not fit. If not sufficient food is available, it is removed from the system.
  * _Interaction_. Agents do not interact directly. Indirectly they interact by occupying potential farm plot. Agents represent households. In the model, reproduction is modeled at the household level.  Based on the age of the household and the availability of food, a household may give birth to an offspring household, which is representing a daughter who leaves the house and starts a new household (immediately with 3 children that require 160 kg corn per year).  These abstraction is simplistic, but still captures the essence of reproduction and population growth.
  * _Stochasticity_.  Initial conditions of cells and agents, and the order in which agents are updated.

## HOW TO USE IT?

If you click on SETUP the model will load the data files and initialize the model. If you click on GO the simulation will start. You can adjust a number of sliders before you click on SETUP to initialize the model for different values.
The slider HARVEST-ADJUSTMENT is the fraction of the harvest that is kept after harvesting the corn. The rest is assumed the be lost in the harvesting process. The default value is around 60%. If you increase this number much more agents than the historical record is able to live in the valley.
The slider HARVEST-VARIANCE is used to create variation of quality of cells and temporal variability in harvest for each cell. If you have variance of the harvest some agents are lucky one year and need to use their storage another year. If there is no variance many agents will leave the valley at once when there is a bad year.
The slider DEATH-AGE represents the maximum number of years an agent can exists. A lower number will reduce the population size.
The slider FERTILITY-ENDS-AGE represents the maximum age of an agent to be able to produce offspring. A lower number will reduce the population size.
The slider FERTILITY is the annual probability an agent gets offspring. A lower probability will reduce the population size.


POPULATION GRAPH: the blue line shows the historical data, while the red line the simulated population size.

**Maps**. With the MAP-VIEW chooser you can select different ways to view the landscape on the right.

  * ZONES: this will show you the different land cover zones.
    * Black: General Valley Floor
    * Red: North Valley Floor
    * White: Mid and North Dunes
    * Gray: Midvalley Floor
    * Yellow: Non-Arable Uplands
    * Blue: Arable Uplands
    * Pink: Kinbiko Canyon
  * WATER SOURCES: this will show you the different surface water sources like springs. This is changing over time due to input data on retrodicted environmental history. Households will chose new locations based on being nearby water sources.
  * YIELD: Each cell is colors on the amount of yield can be derived from the cell. The more yield the lighter the color.
  * OCCUPANCY: yellow cells are use for agriculture, red cells for settlements

If HISTORIC-VIEW? is on you will see the locations of settlements according to the data. The settlements are shown as houses, and the size (area of the house shape) is proportional the number of households on that location.

## BSD LICENSE

Copyright 1998-2007 The Brookings Institution, NuTech Solutions,Inc., Metascape LLC, and contributors.  All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
* Neither the names of The Brookings Institution, NuTech Solutions,Inc. or Metascape LLC nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## CREDITS AND REFERENCES

NetLogo replication of Artificial Anasazi model by Jeffrey S. Dean, George J. Gumerman, Joshua M. Epstein, Robert Axtell, Alan C. Swedlund, Miles Parker, and Steven McCarroll

This model is a lightly adapted version of the prior replication work of Marco Janssen (with help of Sean Bergin and Allen Lee) who reimplemented the Artificial Anasazi model in NetLogo (the original model was written in Ascape).

The code of this complex historical model is in the process of being refined by the NetLogo team, and still differs greatly from the usual standards of the Models Library.

Janssen's version of the model is available at: https://www.comses.net/codebases/2222/releases/1.1.0/. (Furthermore, this "Info tab" is adapted from the ODD model documentation that accompanies that model.)

Janssen's replication is discussed further in the following academic journal paper, which curious readers are highly encouraged to examine:

Janssen, Marco A. (2009). Understanding Artificial Anasazi. Journal of Artificial Societies and Social Simulation 12(4)13 <http://jasss.soc.surrey.ac.uk/12/4/13.html>.

Some follow-up work on calibration and sensitivity analysis of this model is published in:

Stonedahl, F., & Wilensky, U. (2010). Evolutionary Robustness Checking in the Artificial Anasazi Model. Proceedings of the AAAI Fall Symposium on Complex Adaptive Systems: Resilience, Robustness, and Evolvability. November 11-13, 2010. Arlington, VA. (Available:  http://ccl.northwestern.edu/papers/2010/Stonedahl%20and%20Wilensky.pdf)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Stonedahl, F. and Wilensky, U. (2010).  NetLogo Artificial Anasazi model.  http://ccl.northwestern.edu/netlogo/models/ArtificialAnasazi.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2010 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2010 Cite: Stonedahl, F. -->
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

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

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
