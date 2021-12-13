extensions [ ls ]

globals [
  ; These are constant variables used to specify simulation restrictions
  global-lactose-limit         ; variable to specify lactose quantity
  initial-energy               ; variable to specify initial energy of bacterial cells
  old-models-list                  ; list of ls:models to identify newly created model
]

breed [ ecolis ecoli ]

ecolis-own [
  my-model              ; cell model (LevelSpace child model) associated with an E. coli cell
  my-model-path         ; path to locate the file to be used for creating a cell model (LevelSpace child model)

  ; these variables are used to store the corresponding statistics from the cell models
  energy                ; energy of the cell
  lactose-inside        ; lactose quantity inside a cell
  lactose-outside       ; lactose quantity in the outside environment
  lacZ-inside           ; lacZ proteins inside a cell
  lacY-inside           ; lacY proteins inside a cell
  lacY-inserted         ; lacY proteins inserted into the cell-wall
  lacI-lactose-complex  ; lacI-lactose-complex molecules inside a cell
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; SETUP PROCEDURES ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  ls:reset
  ; set the constant values
  set initial-energy 1000
  set global-lactose-limit (initial-number-of-types * 5000)
  generate-cells ; create the cells
  if lactose? [ distribute-lactose ] ; distribute lactose if the option is selected
  reset-ticks
end

; procedure to generate E. coli cells. If choose-models is OFF, default cell model is created for all the cells.
to generate-cells
  let color-list [ red orange brown yellow green cyan violet magenta ]

  let i 0
  create-ecolis initial-number-of-types [
    set color (item i color-list)
    setxy random-xcor random-ycor
    set shape "ecoli"

    ifelse choose-models? [
      user-message "Select a Genetic Switch model to use..."
      set my-model-path user-file
    ][
      set my-model-path "GenEvo 1 Genetic Switch.nlogo"
    ]

    create-my-model
    while [ test-if-switch my-model ] [
      user-message "The model must be a Genetic Switch model! Please select a Genetic Switch model again."
      ls:close my-model
      set my-model-path user-file
      create-my-model
    ]
    set i i + 1
  ]
end

to create-my-model ; turtle procedure
  ; If my-model-path is False, it means the user didn't select a file.
  ; In that case, we kill the E. coli so we this doesn't mess anything up.
  ifelse my-model-path != False [
    ls:create-interactive-models 1 my-model-path
    set my-model max ls:models
    ls:hide my-model

    ls:let initial-variables-list generate-initial-variables-list
    ls:ask my-model [
      setup
      set-initial-variables initial-variables-list
    ]
  ]
  [ die ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; RUNTIME PROCEDURES ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  distribute-lactose
  ask ecolis [
    rt random-float 360
    fd 1
    run-your-model
    maybe-reproduce
    if energy < 0 [
      ls:close my-model
      die
    ]
  ]
  if not any? ecolis [ stop ]
  tick
end

; Updates the enviornmental conditions and then runs each cell model
to run-your-model ; turtle procedure
   ls:let lactose-outside-per-cell ifelse-value lactose? [ floor ( global-lactose-limit / length ls:models ) ] [ 0 ]
   ls:let parent-glucose? glucose?
   ls:let parent-lactose? lactose?

   ls:ask my-model [
     set glucose? parent-glucose?
     set lactose? parent-lactose?
     go
   ]
end

; when lactose? is OFF, this procedure is used to update the lactose quantity in the environment in the population model
to distribute-lactose
  ifelse lactose? [
    ls:let lactose-per-model (global-lactose-limit / length ls:models)
    ask patches [ set pcolor 2 ]
    ask ecolis [ ls:ask my-model [ update-lactose lactose-per-model ] ]
  ][
    ; see how much lactose is outside all of the cells
    let total-lactose-outside sum [ count lactoses with [ not inside? ] ] ls:of ls:models

    ; color the patches based on the global lactose amount
    ifelse total-lactose-outside < (global-lactose-limit / 2) [
      ask patches [ set pcolor 1 ]
    ][
      ifelse total-lactose-outside = 0 [
        ask patches [ set pcolor 0 ]
      ][
        ask patches [ set pcolor 2 ]
      ]
    ]

    ls:let lactose-per-model (total-lactose-outside / length ls:models)
    ask ecolis [ ls:ask my-model [ update-lactose lactose-per-model ] ]
  ]
end

; procedure for E. coli cells to reproduce. A new cell is added in the population model and a new individual cell model is created.
to maybe-reproduce
  ; if there's enough energy, reproduce
  if ( [ energy ] ls:of my-model > 2 * initial-energy ) [
    ls:ask my-model [ divide-cell ]
    extract-cell-model-variables
    hatch 1 [
      rt random-float 360 fd 1 ; move it forward so they don't overlap
      create-my-model  ; Now create and setup the cell model that will simulate this new daughter cell
    ]
  ]
end

; procedure to concatenate all the necessary initial variables for a daughter cell model into a single list
to-report generate-initial-variables-list ; turtle procedure
  report (list color initial-energy lacY-inside lacY-inserted lacZ-inside lacI-lactose-complex lactose-inside lactose-outside lactose? glucose?)
end

; Extract all the necessary variables from the cell model
to extract-cell-model-variables ; turtle procedure

  let list-of-variables ([ send-variables-list ] ls:of my-model) ; grab the list

  ; now save the elements in our 'ecolis-own' variables
  set energy item 0 list-of-variables
  set lacY-inside item 1 list-of-variables
  set lacY-inserted item 2 list-of-variables
  set lacZ-inside item 3 list-of-variables
  set lacI-lactose-complex item 4 list-of-variables
  set lactose-inside item 5 list-of-variables
  set lactose-outside item 6 list-of-variables
end

; procedure to view the cell model (LevelSpace child model) associated with each cell
to inspect-cells
  if mouse-inside? and mouse-down? [
    ask ecolis with-min [ distancexy mouse-xcor mouse-ycor ] [
      ls:show my-model
    ]
  ]
end

; procedure to test whether or not a model is a Genetic Switch model
to-report test-if-switch [ a-model-number ]
  let return-value False
  carefully [
    ls:ask a-model-number [ set LevelSpace? True ]
  ][
     set return-value True
   ]
  report return-value
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
465
10
968
514
-1
-1
15.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
5
10
75
45
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
79
10
135
45
go
go\n
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
5
90
460
315
Population
Time
Frequency
0.0
10.0
10.0
10.0
true
true
"" ""
PENS
"red" 1.0 0 -2674135 true "" "plot count ecolis with [ color = red ]"
"orange" 1.0 0 -955883 true "" "if initial-number-of-types > 1 [ plot count ecolis with [ color = orange ] ]"
"brown" 1.0 0 -6459832 true "" "if initial-number-of-types > 2 [ plot count ecolis with [ color = brown ] ]"
"yellow" 1.0 0 -1184463 true "" "if initial-number-of-types > 3 [ plot count ecolis with [ color = yellow ] ]"
"green" 1.0 0 -10899396 true "" "if initial-number-of-types > 4 [ plot count ecolis with [ color = green ] ]"
"cyan" 1.0 0 -11221820 true "" "if initial-number-of-types > 5 [ plot count ecolis with [ color = cyan ] ]"
"violet" 1.0 0 -8630108 true "" "if initial-number-of-types > 6 [ plot count ecolis with [ color = violet ] ]"
"magenta" 1.0 0 -5825686 true "" "if initial-number-of-types > 7 [ plot count ecolis with [ color = magenta ] ]"

SWITCH
140
10
255
43
lactose?
lactose?
0
1
-1000

SLIDER
260
50
460
83
initial-number-of-types
initial-number-of-types
1
8
7.0
1
1
NIL
HORIZONTAL

SWITCH
140
50
255
83
glucose?
glucose?
0
1
-1000

BUTTON
5
50
135
83
inspect cells
inspect-cells
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
5
320
460
514
Type Frequency Distribution Histogram
Trait
Frequency
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"red" 1.0 1 -2674135 true "" "histogram [ 1 ] of ecolis with [ color = red ]"
"orange" 1.0 1 -955883 true "" "histogram [ 2 ] of ecolis with [ color = orange ]"
"brown" 1.0 1 -6459832 true "" "histogram [ 3 ] of ecolis with [ color = brown ]"
"yellow" 1.0 1 -1184463 true "" "histogram [ 4 ] of ecolis with [ color = yellow ]"
"green" 1.0 1 -10899396 true "" "histogram [ 4 ] of ecolis with [ color = green ]"
"cyan" 1.0 1 -11221820 true "" "histogram [ 5 ] of ecolis with [ color = cyan ]"
"violet" 1.0 1 -8630108 true "" "histogram [ 6 ] of ecolis with [ color = violet ]"
"magenta" 1.0 1 -5825686 true "" "histogram [ 7 ] of ecolis with [ color = magenta ]"

SWITCH
260
10
460
43
choose-models?
choose-models?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is a population model of competition between cells in a population of asexually reproducing bacteria E. coli for resources in an environment. Users can experiment with various parameters to learn more about two different mechanisms of evolution: natural selection and genetic drift.

## HOW IT WORKS

Using the LevelSpace extension of NetLogo, each cell in this population model is actually controlled by a genetic switch model (just like _GenEvo 1_). In LevelSpace terminology, this population model is called a _parent model_ and each cell is a _child model_. However, in this info section, we will call this model the _population model_ and each background genetic switch model a _cell model_.

Depending on the selected options, each cell model begins with a different set of initial parameters. Then, each cell model simulates the DNA-Protein interactions in the lac-operon of E. coli (check out the _GenEvo 1_ model for a refresher). In the population model, we see the competition for resources between these cells.

When a cell's energy level doubles from its initial level, the cell produces two daughter cells that inherit the cell's genetic and epigenetic information. The cells with a 'fitter' genetic circuit turn their switch on and off faster, resulting in a faster increase in the energy levels, and a faster growth rate.

Because the molecular interactions in each cell model are stochastic, the population model displays the effects of both natural and statistical selection (genetic drift).

## HOW TO USE IT

### To Setup

You can use this model in two ways.

1. The simplest way to use this model is to set CHOOSE-MODELS? to OFF. In this mode, the default Genetic Switch model is created for each cell. This method simulates genetic drift as a mechanism of evolution since each cell starts off identical.

2. If CHOOSE-MODELS? is ON, a user can manually select the NetLogo models (`.nlogo` files) to be used for each cell, allowing each cell to have a different genetic switch. This allows for variability in the population. This method simulates natural selection as well as genetic drift.

In both ways, the SETUP button sets up the population of E. coli cells (each type represented by a unique color) and randomly distributes them across the world.

### To run

After you setup the model, set the environmental conditions by setting LACTOSE? and GLUCOSE? to ON or OFF.

Click GO to run the population model (and consequently, the cell models) for around 300 ticks. Click GO again to pause the model. Click INSPECT CELLS and click on any cell to see the cell model behind it. Close the individual cell models (Always select 'run in the background' option when closing individual models). Click GO to run the model again.

Change the environmental conditions using the LACTOSE? and GLUCOSE? switches and observe the different behaviors of population. (Note: You have to run the model for a few hundred ticks in order to observe cellular behavior.)

### Buttons

SETUP - Sets up the population model and cell models

GO - Makes the simulation in the population model (and consequently the cell models) begin to tick

INSPECT-CELLS - This button allows you to inspect the cell model of any cell in the population model. Click the button first and then click on a cell to see its cell model. When you close an individual cell model, always select the 'run in the background' option.

### Switches

LACTOSE? - If ON, lactose is added to the external environment and equally distributed among the cell models. This means that the more the cells, the less lactose each cell gets. In other words, this is how we model carrying capacity.

GLUCOSE? - If ON, glucose is added to the external environment. Transport and digestion of glucose is not explicitly modeled, however since glucose is a _preferred sugar_, when glucose is present the _lac promoter_ in the Genetic Switch model is inactive. In addition, when glucose is present, the energy of each cell increases with a constant rate (10 units per tick).

### Sliders

INITIAL-NUMBER-OF-CELLS – This is the initial number of cells in the population model. If CHOOSE-MODELS? is ON, this also corresponds to the number of Genetic Switch models the user has to select.

## THINGS TO NOTICE

Notice the reproduction of cells as the time progresses. Notice how each cell model behaves with different sugar conditions.

Run the model for a few thousand ticks to see which cell type wins. Notice the cellular behavior of the Genetic Switch in the different types of cells by using the INSPECT CELLS button. Run the simulation several times with the same set of cell models to distinguish between the roles of natural selection and genetic drift. If natural selection is a stronger mechanism for evolution in a given set of cell models, then the same trait will win more frequently.

## THINGS TO TRY

See if you can make the background color of the view scale with how much lactose and glucose are in the medium.

## EXTENDING THE MODEL

See if you can modify the model to model the effect of glucose explicitly by introducing the requisite proteins.

## NETLOGO FEATURES

This model uses the LevelSpace extension to allow each cell to have its own genetic switch model controlling the protein interactions within.

## RELATED MODELS

* GenDrift Sample Models
* GenEvo Curricular Models

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Dabholkar, S. and Wilensky, U. (2016).  NetLogo GenEvo 4 Competition model.  http://ccl.northwestern.edu/netlogo/models/GenEvo4Competition.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

To cite the GenEvo Systems Biology curriculum as a whole, please use:

* Dabholkar, S. & Wilensky, U. (2016). GenEvo Systems Biology curriculum. http://ccl.northwestern.edu/curriculum/genevo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 GenEvo Cite: Dabholkar, S. -->
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

ecoli
true
0
Rectangle -7500403 true true 75 90 225 210
Circle -7500403 true true 15 90 120
Circle -7500403 true true 165 90 120

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

lactose
true
0
Polygon -7500403 true true 150 135 135 150 135 165 165 165 165 150 150 135

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
1
@#$#@#$#@
