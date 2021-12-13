;; SETUP colors the patches so that roughly half are red and half are green
to setup
  clear-all
  ask patches [
    set pcolor one-of [ red green ]
  ]
  reset-ticks
end

;; GO-1 sets the labels of red patches to a small random number (0-4)
;; and the labels of green patches to a larger random number (5-9)
;; provided that there are at least 5 patches of the other color.
to go-1
  ask patches with [ pcolor = red ] [
    if count patches with [ pcolor = green ] > 5 [
      set plabel random 5
    ]
  ]
  ask patches with [ pcolor = green ] [
    if count patches with [ pcolor = red ] > 5 [
      set plabel 5 + random 5
    ]
  ]
  tick
end

;; GO-2 has the same behavior as GO-1 above, but it is more
;; efficient as it computes each of the agentsets only once.
to go-2
  let red-patches patches with [ pcolor = red ]
  let green-patches patches with [ pcolor = green ]
  ask red-patches [
    if count green-patches > 5 [
      set plabel random 5
    ]
  ]
  ask green-patches [
    if count red-patches > 5 [
      set plabel 5 + random 5
    ]
  ]
  tick
end

;; GO-3 explores what happens if patch colors are changed on the fly.
;; GO-3 results in the entire world becoming green.
to go-3
  ask patches with [ pcolor = red ] [
    if count patches with [ pcolor = green ] > 5 [
      set pcolor green
    ]
  ]
  ask patches with [ pcolor = green ] [
    if count patches with [ pcolor = red ] > 5 [
      set pcolor red
    ]
  ]
  tick
end

;; GO-4 explores what happens if you first keep track
;; of which patches are red and which are green.
;; GO-4 results in the patches swapping their colors.
to go-4
  let red-patches patches with [ pcolor = red ]
  let green-patches patches with [ pcolor = green ]
  ask red-patches [
    if count green-patches > 5 [
      set pcolor green
    ]
  ]
  ask green-patches [
    if count red-patches > 5 [
      set pcolor red
    ]
  ]
  tick
end

;; This procedure measures the time it takes to
;; run GO-1 and GO-2, 100 times each.
to-report test-1-2
  setup
  let n 100 ;; the number of times to run each procedure
  reset-timer
  repeat n [ go-1 ]
  let result1 timer ;; the number of seconds it took to run GO-1 n times
  reset-timer
  repeat n [ go-2 ]
  let result2 timer ;; the number of seconds it took to run GO-2 n times
  report list result1 result2
end


; Copyright 2008 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
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
70
65
140
98
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
70
120
140
153
NIL
go-1
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
70
160
140
193
NIL
go-2
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
70
200
140
233
NIL
go-3\n
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
70
240
140
273
NIL
go-4
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

@#$#@#$#@
## ACKNOWLEDGMENT

This model is from Chapter Five of the book "Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo", by Uri Wilensky & William Rand.

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

This model is in the IABM Textbook folder of the NetLogo Models Library. The model, as well as any updates to the model, can also be found on the textbook website: http://www.intro-to-abm.com/.

## UPDATES TO THE MODEL SINCE TEXTBOOK PUBLICATION

The code for this model differs from the code in the textbook. The code here is the most up to date version. The code for the agentset efficiency model in the book (pages 219-222) should be replaced with the code in this model.

## WHAT IS IT?

This model addresses a couple of concerns that can arise when using agentsets, in particular when filtering them using the "`with`" primitive. The first of these concerns has to do with efficiency: it is best to avoid building the same agentset multiple times. The second concern has to do with the timing of side effects: rebuilding an agentset using the same condition can lead to different results if the state of the agents has changed in the meanwhile.

## HOW IT WORKS

SETUP creates a world where roughly half the patches are red and half the patches are green.

GO-1 sets the labels of red patches to a small random number (0-4) and the labels of green patches to a larger random number (5-9). It only sets the label of each patch if there are at least 5 patches of the other color.

GO-2 is a more efficient implementation of GO-1, as it only computes the `red-patches` and `green-patches` agentsets once instead of recomputing the green patches again for each red patch and recomputing the red patches again for each green patch.

GO-3 is written as if the intention is to swap green patches with red patches. However, because of a bug in the code, it first changes all the red patches to green patches, and then doesn't change any patches to red. GO-3 has unexpected behavior and is given here as an example of the potential pitfalls of changing agentsets on the fly.

GO-4 is similar to GO-3, but it computes the `red-patches` and `green-patches` agentsets _before_ changing them, which avoids the problem we had with GO-3.

## HOW TO USE IT

Press SETUP to create the world of red and green patches. Then press GO-1 to see what effect it has. Now try GO-2. Is the result any different from GO-1? You can try both of them a few times to see if you notice anything.

After that press GO-3 to see what effect it has on the colors of the patches. Is that what you expected? Do you have any idea what the cause of this behavior is? Now try GO-4. Does it give the expected result? Do you understand why?

## THINGS TO NOTICE

While playing around with the model, you should have seen that GO-3 gives very different results than GO-4: instead of swapping red and green patches like we intended, it turns all the patches green! Why is that?

This has to do with the timing of "side effects". In GO-3, we start by using the following code to ask all the red patches to turn green if there are at least 5 green patches:

    ask patches with [ pcolor = red ] [
      if count patches with [ pcolor = green ] > 5 [
        set pcolor green
      ]
    ]

Then, we ask all the green patches to turn red if there are at least 5 red patches:

    ask patches with [ pcolor = green ] [
      if count patches with [ pcolor = red ] > 5 [
        set pcolor red
      ]
    ]

But since we previously turned all red patches green, "`count patches with [ pcolor = red ]`" is now 0, so they all stay green!

What is it about GO-4 that prevents this from happening? It is the fact that we constructed our agentsets (`red-patches` and `green-patches`) _before_ performing any changes on our patches. The `red-patches` agentset is insulated from the side effects of turning red patches to green, so when we run this code:

    ask green-patches [
      if count red-patches > 5 [
        set pcolor red
      ]
    ]

...the original set of green patches turn red as expected.

## THINGS TO TRY

Try running GO-1 and GO-2 a number of times. Which is faster? Sometimes, it can be hard to tell when you're just playing with a model "by hand". This why we wrote a reporter procedure called `test-1-2`. There is no button for this procedure on the interface, but you can invoke it from the command center. If you try it, you will see the patch labels flickering in the view for a while, and then, printed in the command center, the time it took to run GO-1 and GO-2 a hundred times each. Although GO-2 is somewhat faster than GO-1, the difference isn't extreme. Why is that?

As is common with a lot of NetLogo models, the bulk of the processing time is taken up by view updates: in this case, displaying all the patch labels on the screen. If you really want to measure the speed difference between two procedures, it is a good idea to turn off view updates by unchecking the corresponding checkbox in the NetLogo toolbar.

Try it. Which procedure is faster now?

Another thing that you can try is to increase the size of the world. Is the difference between GO-1 and GO-2 more noticeable when there are more patches?

## EXTENDING THE MODEL

We have used the `reset-timer` and `timer` primitives to write a test function that compares the running times of G0-1 and GO-2, but NetLogo also has a built in `profiler` extension that serves the same purpose and gives you a lot more information about the  performance of your model.

You can read the documentation for the `profiler` extension online at [http://ccl.northwestern.edu/netlogo/docs/profiler.html](http://ccl.northwestern.edu/netlogo/docs/profiler.html).

Try to replace the `test-1-2` procedure with one that is adapted from the example in the documentation of the `profiler` extension. Can you replicate the results that you had with `test-1-2`?

## HOW TO CITE

This model is part of the textbook, “Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo.”

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Rand, W., Wilensky, U. (2008).  NetLogo Agentset Efficiency model.  http://ccl.northwestern.edu/netlogo/models/AgentsetEfficiency.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the textbook as:

* Wilensky, U. & Rand, W. (2015). Introduction to Agent-Based Modeling: Modeling Natural, Social and Engineered Complex Systems with NetLogo. Cambridge, MA. MIT Press.

## COPYRIGHT AND LICENSE

Copyright 2008 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2008 Cite: Rand, W., Wilensky, U. -->
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
setup go-1
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
