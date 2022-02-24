extensions [ vid ]

breed [ birds bird ]
breed [ spinners spinner ]

turtles-own [ age ]

to setup
  clear-all
  create-birds 1
  create-spinner
  reset-ticks
  if vid:recorder-status = "recording" [ vid:record-view ]
end

to go
  ask birds [
    wander
    grow-old
    reproduce
  ]
  tick
  update-spinner
  if vid:recorder-status = "recording" [ vid:record-view ]
end

to grow-old
  set age age + 1
end

to wander
  right random-float 90
  forward 1
end

to reproduce
  if age > 10 and random 10 > 7 [
    hatch 2 [
      set color color - 4 + random 10
      set age 0
    ]
    die
  ]
end

; make the spinner for the upper right hand corner
to create-spinner
  create-spinners 1 [
    set shape "clock"
    setxy (max-pxcor - 3) (max-pycor - 3)
    set color gray - 1.5
    set size 6
    set heading 0
    set label 0
  ]
end

to update-spinner
  ask spinners [
    set heading ticks * 30
    set label ticks
  ]
end

to start-recorder
  carefully [ vid:start-recorder ] [ user-message error-message ]
end

to reset-recorder
  let message (word
    "If you reset the recorder, the current recording will be lost."
    "Are you sure you want to reset the recorder?")
  if vid:recorder-status = "inactive" or user-yes-or-no? message [
    vid:reset-recorder
  ]
end

to save-recording
  if vid:recorder-status = "inactive" [
    user-message "The recorder is inactive. There is nothing to save."
    stop
  ]
  ; prompt user for movie location
  user-message (word
    "Choose a name for your movie file (the "
    ".mp4 extension will be automatically added).")
  let path user-new-file
  if not is-string? path [ stop ]  ; stop if user canceled
  ; export the movie
  carefully [
    vid:save-recording path
    user-message (word "Exported movie to " path ".")
  ] [
    user-message error-message
  ]
end


; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
@#$#@#$#@
GRAPHICS-WINDOW
321
10
657
347
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
-20
20
-20
20
1
1
1
ticks
1000.0

BUTTON
25
100
100
133
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
106
100
176
133
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
25
310
300
343
save recording
save-recording
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
184
100
297
145
NIL
count birds
3
1
11

MONITOR
26
260
301
305
NIL
vid:recorder-status
3
1
11

BUTTON
165
220
301
253
reset recorder
reset-recorder
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
25
220
158
253
start recorder
start-recorder
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

This shows how to capture a movie of your model with the `vid` extension.

The model is of a population of birds.  Once a bird is 10 ticks old, it can hatch two offspring and die.  The number of birds, of course, increases exponentially.

The model provides buttons to start the movie recorder and then save your recording or reset the movie recorder if you don't like what you have recorded so far. The code for these buttons can easily be copied to any user model.

## HOW TO USE IT

The model can be used like most NetLogo models: click SETUP to initialize the model and then GO to run it.

If you want to make a movie of the model, click START RECORDER at any time. You will notice that the VID:RECORDER-STATUS monitor changes from "inactive" to "recording". Once recording is active, the recorder will capture a frame of the model each time SETUP or GO is executed.

Once you have a movie that you think you will like, you can use the SAVE RECORDING button to save it. NetLogo will prompt you for a file name and automatically add the `.mp4` extension to it if you don't add it yourself.

If you don't want to save your movie and prefer to start over, click RESET RECORDING. The recorder will "forget" everything that it has recorded so far.

If you want to add recording capabilities to your own model, copy the code for `start-recorder`, `reset-recorder` and `save-recording` to the code tab of your model and create the corresponding buttons in your interface tab. You can also add a `vid:recorder-status` monitor if you like.

## THINGS TO NOTICE

Like any model with exponential population growth, this model slows down after each iteration.  As it takes longer for NetLogo to compute each iteration, actual time gets slower and slower relative to "model time" (the number of iterations).  Thus, the gray spinner in the upper right corner of the view visibly slows down.

Creating a movie of the model solves the problem.  The movie allows us to observe the model while real time and model time progress at a consistent rate.  When we replay the movie, the spinner spins at a constant rate.

Note that the model only shows what's happening in the view; it doesn't show monitors updating, and if the model had any plots in it, they wouldn't be shown either. That's because the code uses the `vid:record-view` command, which only includes the view in the model.  You can substitute `vid:record-interface`; then the whole interface tab is grabbed.

## THINGS TO TRY

A different way of making a movie is to use BehaviorSpace.  BehaviorSpace is a tool built into NetLogo that lets you set up automated model runs.  Usually BehaviorSpace is used to do many model runs in which you experiment with different settings in a model, but it's also possible to use it to set up a single run in order to make a movie.

This model includes a sample BehaviorSpace "experiment setup" which makes a movie.  To try it, choose BehaviorSpace on the Tools menu.  In the dialog that opens you'll see an experiment called "make movies".  Select that experiment and hit the "Run" button. The model will run three times and a movie files will be generated each time. The `behaviorspace-run-number` primitive is used to give each movie a different name.

If you want to see how the experiment was set up, select the experiment in the BehaviorSpace dialog and press the "Edit" button.  You'll notice that:

- the "Setup commands" include `vid:start-recorder`
- the "Final commands" include `vid:save-recording (word behaviorspace-run-number)`

The current `setup` and `go` procedures in the model already include `if vid:recorder-status = "recording" [ vid:record-view ]`. If you were trying to record a movie for a model that didn't already have them, you could include calls to `vid:record-view` in the "Setup commands" and "Go commands" of the BehaviorSpace experiment.

Together, those commands make a complete movie.

Since it isn't a real experiment, the setup does not vary any variables, and it does not use any reporters to measure the run.

<!-- 2016 -->
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
setup repeat 175 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="make movies" repetitions="3" runMetricsEveryStep="false">
    <setup>vid:start-recorder
setup</setup>
    <go>go</go>
    <final>vid:save-recording (word behaviorspace-run-number)</final>
    <exitCondition>count turtles &gt;= 3000</exitCondition>
  </experiment>
</experiments>
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
