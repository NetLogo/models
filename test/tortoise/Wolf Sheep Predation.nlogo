;; bugs:
;; - TODO: predation commented out
;; workarounds:
;; - #10 (turtle death)
;; - no set-default-shape, use "set shape" instead
;; - breeds removed:
;;   - use a string "kind" instead

globals [grass]
turtles-own [energy kind]       ;; both wolves and sheep have energy
patches-own [countdown]

to setup
  clear-all
  set grass? true
  ask patches [ set pcolor green ]
  ;; check GRASS? switch.
  ;; if it is true, then grass grows and the sheep eat it
  ;; if it false, then the sheep don't need to eat
  if grass? [
    ask patches [
      set pcolor one-of [green brown]
      if-else pcolor = green
        [ set countdown grass-regrowth-time ]
        [ set countdown random grass-regrowth-time ] ;; initialize grass grow clocks randomly for brown patches
    ]
  ]
  create-turtles initial-number-sheep  ;; create the sheep, then initialize their variables
  [
    set kind "sheep"
    set shape "sheep"
    set color white
    set size 1.5  ;; easier to see
    set label-color blue - 2
    set energy random (2 * sheep-gain-from-food)
    setxy random-xcor random-ycor
  ]
  create-turtles initial-number-wolves  ;; create the wolves, then initialize their variables
  [
    set kind "wolf"
    set shape "wolf"
    set color black
    set size 2  ;; easier to see
    set energy random (2 * wolf-gain-from-food)
    setxy random-xcor random-ycor
  ]
  display-labels
  set grass count patches with [pcolor = green]
  reset-ticks
end

to go
  if not any? turtles [ stop ]
  ask sheep [
    move
    if grass? [
      set energy energy - 1  ;; deduct energy for sheep only if grass? switch is on
      eat-grass
    ]
    death
  ]
  ask sheep [
    reproduce-sheep
  ]
  ask wolves [
    move
    set energy energy - 1  ;; wolves lose energy as they move
    ;; TODO catch-sheep
    death
  ]
  ask wolves [
    reproduce-wolves
  ]
  if grass? [ ask patches [ grow-grass ] ]
  set grass count patches with [pcolor = green]
  tick
  display-labels
end

to move  ;; turtle procedure
  rt random 50
  lt random 50
  fd 1
end

to eat-grass  ;; sheep procedure
  ;; sheep eat grass, turn the patch brown
  if pcolor = green [
    set pcolor brown
    set energy energy + sheep-gain-from-food  ;; sheep gain energy by eating
  ]
end

to reproduce-sheep  ;; sheep procedure
  if random-float 100 < sheep-reproduce [  ;; throw "dice" to see if you will reproduce
    set energy (energy / 2)                ;; divide energy between parent and offspring
    ;; hatch 1 [ rt random-float 360 fd 1 ]   ;; hatch an offspring and move it forward 1 step
  ]
end

to reproduce-wolves  ;; wolf procedure
  if random-float 100 < wolf-reproduce [  ;; throw "dice" to see if you will reproduce
    set energy (energy / 2)               ;; divide energy between parent and offspring
    ;; hatch 1 [ rt random-float 360 fd 1 ]  ;; hatch an offspring and move it forward 1 step
  ]
end

to catch-sheep  ;; wolf procedure
  let prey one-of sheep-here                    ;; grab a random sheep
  if prey != nobody                             ;; did we get one?  if so,
    [ ask prey [ die ]                          ;; kill it
      set energy energy + wolf-gain-from-food ] ;; get energy from eating
end

to death  ;; turtle procedure
  ;; when energy dips below zero, die
  if energy < 0 [ die ]
end

to grow-grass  ;; patch procedure
  ;; countdown on brown patches: if reach 0, grow some grass
  if pcolor = brown [
    ifelse countdown <= 0
      [ set pcolor green
        set countdown grass-regrowth-time ]
      [ set countdown countdown - 1 ]
  ]
end

to display-labels
  ask turtles [ set label "" ]
  if show-energy? [
    ask wolves [ set label round energy ]
    if grass? [ ask sheep [ set label round energy ] ]
  ]
end

;;; compensate for lack of breeds in Tortoise

to-report sheep
  report turtles with [kind = "sheep"]
end
to-report sheep-here
  report turtles-here with [kind = "sheep"]
end

to-report wolves
  report turtles with [kind = "wolf"]
end
to-report wolves-here
  report turtles-here with [kind = "wolf"]
end
@#$#@#$#@
GRAPHICS-WINDOW
350
10
819
500
25
25
9.0
1
14
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

SLIDER
3
150
177
183
initial-number-sheep
initial-number-sheep
0
250
100
1
1
NIL
HORIZONTAL

SLIDER
3
187
177
220
sheep-gain-from-food
sheep-gain-from-food
0.0
50.0
4
1.0
1
NIL
HORIZONTAL

SLIDER
3
222
177
255
sheep-reproduce
sheep-reproduce
1.0
20.0
4
1.0
1
%
HORIZONTAL

SLIDER
181
150
346
183
initial-number-wolves
initial-number-wolves
0
250
50
1
1
NIL
HORIZONTAL

SLIDER
181
186
346
219
wolf-gain-from-food
wolf-gain-from-food
0.0
100.0
20
1.0
1
NIL
HORIZONTAL

SLIDER
181
222
346
255
wolf-reproduce
wolf-reproduce
0.0
20.0
5
1.0
1
%
HORIZONTAL

SWITCH
5
87
99
120
grass?
grass?
1
1
-1000

SLIDER
106
88
318
121
grass-regrowth-time
grass-regrowth-time
0
100
30
1
1
NIL
HORIZONTAL

BUTTON
8
28
77
61
setup
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
28
157
61
go
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
12
312
328
509
populations
time
pop.
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"sheep" 1.0 0 -13345367 true "" "plot count sheep"
"wolves" 1.0 0 -2674135 true "" "plot count wolves"
"grass / 4" 1.0 0 -10899396 true "" "if grass? [ plot grass / 4 ]"

MONITOR
50
265
121
310
sheep
count sheep
3
1
11

MONITOR
125
265
207
310
wolves
count wolves
3
1
11

MONITOR
211
265
287
310
NIL
grass / 4
0
1
11

TEXTBOX
8
130
148
149
Sheep settings
11
0.0
0

TEXTBOX
186
130
299
148
Wolf settings
11
0.0
0

TEXTBOX
9
68
161
86
Grass settings
11
0.0
0

SWITCH
167
28
303
61
show-energy?
show-energy?
1
1
-1000

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
setup
set grass? true
repeat 75 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
