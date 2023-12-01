globals [
  row            ;; this variable is the current row processed by the CA
  colors         ;; the colors corresponding to the 8 states of the CA
  min-xcor-init  ;; the minimum x-coordinate used for the input patches of the initial state
  result         ;; the result of the computation - equals the square of the input
  boards         ;; number of times you've run setup-continue
]

;; the following patch variables refer to the colors of the 3 focal patches in a neighborhood
patches-own [ state left-state center-state right-state ]

;; initializes the model
to setup
   clear-all

  ;; give user a message if not enough columns to compute the result
  if input ^ 2 + input + 5 > world-width [user-message "y=You need to increase the world width to compute the square." stop]

  set row max-pycor
  set boards 0
  set colors [grey 15 25 35 45 55 65 white]

  ;; identify the last patch before the input patches
  set min-xcor-init min-pxcor + 2

  create-input-row input ;; create input row
  set result "none"

  reset-ticks
end

;; runs the CA from top to bottom of the world
to go
  if (row = min-pycor) [ stop ]  ;; stop at the last row

  ask patches with [pycor = row] [
    ;;; process the current row and set the states of the next row
    let next-state get-rule-state
    ask patch-at 0 -1 [set state next-state colorize-states]
  ]

  if finished-computation? [
    ;; the number of red patches (state = 1) in the last row is the result
    set result count patches with [pycor = row and pcolor = red]
    ;; label the final row on the leftmost patch
    ask patch (min-pxcor + 2) (row - 1) [set plabel-color white set plabel (max-pycor - row)]
    stop
  ]

  set row (row - 1)
  tick
end

to create-input-row [number]
  ask patches [set state -1]  ;; set plabel black (for debugging)
  ; set top patches to their default state
  ask patches with [pycor = max-pycor] [ set state 0 ]
  ; set top patches with x = 1,2, ... input to state 1
  ask patches with [pycor = max-pycor and pxcor > min-xcor-init and pxcor <= min-xcor-init + input] [set state 1]
  ; set top patches with x = input + 1 to state 3
  ask patches with [pycor = max-pycor and pxcor = min-xcor-init + input + 1] [set state 3]
  ask patches with [state >= 0 ] [colorize-states ]
end


;; reports whether we've finished the computation for the current setup
to-report finished-computation?
  report
  ;; all patches in the current row are boundary states (state = 0 or state = 2) or final states (state = 1),
  ;; so the results are in
  all? patches with [pycor = row] [pcolor = orange or pcolor = red or pcolor = grey]
end

to colorize-states
  set pcolor item state colors
end

;; get the state of the patch below
to-report get-rule-state  ;; patch procedure
  ;; assign values to patch variables based on current state of the row
  set left-state [state] of patch-at -1 0
  set center-state state
  set right-state [state] of patch-at 1 0
  if left-state =   0 and right-state =  3                     [report 0]
  if center-state = 2 and right-state =  3                     [report 3]
  if center-state = 1 and right-state =  4                     [report 4]
  if left-state =   0 and center-state = 4                     [report 7]
  if left-state =   1 and center-state = 4                     [report 6]
  if left-state =   1 and center-state = 3                     [report 5]
  if left-state =   2 and center-state = 3                     [report 5]
  if left-state =   1 and center-state = 1 and right-state = 3 [report 4]
  if left-state =   5 and center-state = 1                     [report 6]
  if left-state =   6 and center-state = 1                     [report 6]
  if left-state =   5 and center-state = 2                     [report 5]
  if left-state =   6 and center-state = 2                     [report 5]
  if left-state =   5 and center-state = 0 and right-state = 0 [report 1]
  if left-state =   6 and center-state = 0 and right-state = 0 [report 1]
  if left-state =   7 and center-state = 2 and right-state = 6 [report 3]
  if left-state =   7                                          [report 7]
  if center-state = 1                                          [report 1]
  if center-state = 2                                          [report 2]
  if center-state = 5                                          [report 2]
  if center-state = 6                                          [report 1]
  if center-state = 7 and right-state = 1                      [report 1]
  if center-state = 7 and right-state = 2                      [report 2]
  report 0 ; default
end

;; sets up to run the next view
to setup-continue
  set boards boards + 1
  ;; copy cells from the bottom to the top
  ask patches with [pycor = max-pycor] [
    set state ([state] of patch pxcor min-pycor)
  ]

  ask patches with [pycor != max-pycor] [ ;; clear the rest of the patches
     set state -1 set pcolor grey
  ]

  set row max-pycor  ;; reset the current row to the top row
end


; Copyright 2022 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
150
10
963
656
-1
-1
7.0
1
9
1
1
1
0
1
0
1
-57
57
-45
45
1
1
1
ticks
30.0

BUTTON
20
85
125
118
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
20
240
125
273
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
20
160
125
193
NIL
setup-continue
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
20
50
145
85
Start CA from an \ninput row at the top
11
0.0
1

TEXTBOX
20
130
150
165
Start from the end\nof the previous run
11
0.0
1

SLIDER
5
10
140
43
input
input
2
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
35
285
105
358
NIL
result
1
1
18

MONITOR
5
365
63
410
row
max-pycor - row
1
1
11

MONITOR
70
365
140
410
Total rows
boards * world-height + max-pycor - row
1
1
11

BUTTON
20
200
125
234
go once
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

@#$#@#$#@
## WHAT IS IT?

This program models one particular one-dimensional cellular automaton (CA) -- the one known as the "squaring automaton". This CA takes a natural number as input and outputs its square. It is provided here in the NetLogo models library as an example of how a CA can compute arithmetic functions.

What is a Cellular automaton?

A cellular automaton (aka CA) is a computational machine that performs actions based on certain rules.  It can be thought of as a "board" which is divided into cells (such as the square cells of a checkerboard). Each cell has a value for its "state" property, such as 0, 1, 2 ... .  This is called the "state" of the cell. The board is initialized with  cells being assigned a state. A clock is then started and at each "tick" of the clock the rules are "fired" and this results in some cells  changing their state.

There are many kinds of cellular automata. In this model, we explore a one-dimensional CA -- the simplest type of CA. In this case of one-dimensional cellular automata, each row is a world. The top row is initialized so that all cells in that row have states assigned. Each cell  in the top row checks the state of itself and its neighbors to the left and right, and then sets the cell below itself to a state, one of 8 possible states, depending upon the rule. This process results in a new "world" in the second row, which becomes the focal row. This process continues filling successive rows and continues until the bottom of the board.

This model is one of a collection of 1D CA models in NetLogo. It is a more advanced CA model than many of the others, so if you are new to CA, we suggest you look at those first.

In his book, "A New Kind of Science", Stephen Wolfram argues that simple computational devices such as CA lie at the heart of nature's patterns and that CAs are a better tool
(in the sense of "better" as more closely matched to the physics of the world) than mathematical equations for the purpose of scientifically describing the world.

## HOW IT WORKS

The number of red squares in the initial row equals the input number, and the number of red squares in the final row is the result – the square of the input.

This CA has 8 states, which are referred to by the integers 0 through 7. These states are represented visually by the NetLogo colors `grey`, `red`, `orange`, `brown`, `yellow`, `green`, `lime` and `white`.

As the CA computes, each patch chooses the rule with input consisting of {state of the patch to the left, its own state, state of the patch to the right} and then sets the state of the patch below to the output value according to the CA rules represented below. Each patch looks for the first rule that matches its state and executes that rule. The notation for the rules shows a triple on the left side, the state of the patch to the left, the state of the patch itself and the state of the patch to the right. If the focal patch's state and its neighbor states match the rule, then the state of the patch directly below it becomes the value after the arrow. States marked with "-" match any state.

```text

{ 0, _, 3} → 0
{ _, 2, 3} → 3
{ 1, 1, 3} → 4
{ _, 1, 4} → 4
{ 1, 3, _} → 5
{ 2, 3, _} → 5
{ 0, 4, _} → 7
{ 1, 4, _} → 6
{ 7, 2, 6} → 3
{ 7, _, _} → 7
{ _, 7, 1} → 1
{ _, 7, 2} → 2
{ _, 5, _} → 2
{ _, 6, _} → 1
{ 5, 1, _} → 6
{ 6, 1, _} → 6
{ 5, 2, _} → 5
{ 6, 2, _} → 5
{ 5, 0, 0} → 1
{ 6, 0, 0} → 1
{ _, 1, _} → 1
{ _, 2, _} → 2
{ _, _, _} → 0
```

For example, if the current cell is in state 2 and its left neighbor is in state 7 and its right neighbor is in state 6, the cell below it is set to state 3 according to the rule {7, 2, 6} → 3. In the rules above '_' stands for any state. So if the current cell is in state 2 and its left neighbor is in state 6, the cell below it is set to state 5 for all 8 possible right patch states.

If you think carefully about the model you will realize that strictly speaking the rightmost patches do not have a patch that is literally to the right. What we really are referring to is a patch with an x-coordinate that is one more than its own. Because the model has horizontal wrapping this is the leftmost patch with the same y-coordinate. Similarly the concept of left is implemented by subtracting one from the x-coordinate.

## HOW TO USE IT

Initialization & Running:
First, set the INPUT input slider to the number you want to square. Press SETUP to initialize the first row which represents the initial state of the CA. Press GO ONCE to compute the next state of the CA and display it in the next row. If you press GO the computation will continue until the result is computed, or it displays the last row of patches in the view. If the last row is reached without getting a result, press SETUP-CONTINUE to clear the display of the current computed lines. You can then continue running the model in "wrapped" (last row becomes the first row in the new display) mode by pressing GO or GO ONCE. For larger inputs, you may not get a result for a while. so you'll have to press SETUP-CONTINUE multiple times.

Outputs:
The RESULT monitor displays "none" until the result has been computed, then it shows the result -- the square of the input.
The ROW monitor displays the number of rows computed in the current view.
The TOTAL ROWS monitor displays the total number of rows computed so far including rows computed in previous displays. If the computation is complete in a single invocation of GO, then ROW will equal TOTAL ROWS.

## THINGS TO NOTICE

Check that the number of red squares in the initial row equals the input number, and the number of red squares in the final row is the result -- the square of the input.

Look carefully at the pattern of colors down the rows. What do you see? Is there a pattern of the green patches? The brown patches? The white patches?

How does the number of diagonal white patches relate to the input?

How does the number or size of the groupings of green diagonals relate to the input?

How many rules can you match to patterns in output?
0 = `grey`, 1 = `red`, 2 = `orange`, 3 = `brown`, 4 = `yellow`, 5 = `green`, 6 =`lime` and 7 =`white`. For example, which rule can you combine with {6, 1, _} → 1 to explain the regions of alternating `red` and `lime`?

Can you find the rule that causes the line below to extend one red patch further to the right?

Thinking about these rules may give you some insights into how the CA works. One important thing to keep in mind is that each patch examines the rules sequentially and executes the first applicable rule. The rule { _, 2, _} → 2 says that the patch below an orange patch should be orange. So why are some patches below orange patches brown? It's because the rule { _, 2, 3} → 3 comes earlier, and that rule says that if an orange patch has a brown patch to the right, the patch below it will be brown. Can you find the rule that explains why some orange patches have green patches below them?

One difference between this NetLogo model and the corresponding CA in Wolfram's book is that the NetLogo model "wraps" around the horizontal boundaries of the world, whereas Wolfram computes the CA as an infinite grid. This model refuses to carry out the computation if the lines would "wrap" because although interesting patterns might emerge, they would not result in the computation of the square of the input. That is why you need to increase the size of the world if the input is greater than 10. You can increase the size of the world up to the available memory on your computer. However, the larger the world, the longer time it will take NetLogo to compute and display the results.

## THINGS TO TRY

Although the input slider only goes to 10 you can make it go to 11 or further. Just type
`set input 11` in the Command Center.

Notice the slider will display 11. Now press SETUP. You will get an error message.
Adjust the size of the world and try again.

Can you figure out how wide the world has to be if your input is twelve? Can you generalize your answer to any input.
Note: when you are exploring you may want to make the patch size smaller.

Plot the input versus the total number of rows. Do the points look like they lie on a line or curve? Can you estimate the total number of rows for the next larger input value? Test your answer with a computation.

## EXTENDING THE MODEL

What if you wanted to observe the behavior of a CA over many iterations without having to click continue every time the CA reaches the bottom of the view? Simply replace the `stop` with `setup-continue` in the go procedure:

      if (row = min-pycor)
        [ stop ]

with

      if (row = min-pycor)
        [ setup-continue ]

Can you change the model so that it automatically increases the size of the world to allow the computation to succeed? You may also want to decrease the patch size.

## RELATED MODELS

Life - an example of a two-dimensional cellular automaton
CA 1D Rule 30 Turtle - the basic rule 30 model implemented using turtles
CA 1D Rule 90 - the basic rule 90 model
CA 1D Rule 110 - the basic rule 110 model
CA 1D Rule 250 - the basic rule 250 model
CA 1D Elementary- a model that shows all 256 possible simple 1D cellular automata
CA 1D Totalistic - a model that shows all 2,187 possible 1D 3-color totalistic cellular automata.

## CREDITS AND REFERENCES

The first cellular automaton was conceived by John Von Neumann in the late 1940's for his analysis of machine reproduction under the suggestion of Stanislaw M. Ulam. It was later completed and documented by Arthur W. Burks in the 1960's. Other two-dimensional cellular automata, and particularly the game of "Life," were explored by John Conway in the 1970's. Many others have since researched CA's. In the late 1970's and 1980's Chris Langton, Tom Toffoli and Stephen Wolfram did some notable research. Wolfram classified all 256 one-dimensional two-state single-neighbor cellular automata. In his seminal book, "A New Kind of Science," Wolfram presents many examples of cellular automata and argues for their fundamental importance in doing science.

See also:

Von Neumann, J. and Burks, A. W., Eds, 1966. Theory of Self-Reproducing Automata. University of Illinois Press, Champaign, IL.

Toffoli, T. 1977. Computation and construction universality of reversible cellular automata. J. Comput. Syst. Sci. 15, 213-231.

Langton, C. 1984. Self-reproduction in cellular automata. Physica D 10, 134-144

Wolfram, S. 1986. Theory and Applications of Cellular Automata: Including Selected Papers 1983-1986. World Scientific Publishing Co., Inc., River Edge, NJ.
.

Wolfram, S. 2002. A New Kind of Science.  Wolfram Media Inc.  Champaign, IL.

The links below refer to the online version of the book.

A New Kind of Science [p. 639] (https://www.wolframscience.com/nks/p639--computations-in-cellular-automata/) includes a greyscale image of the computation for n = 2, 3, 4, 5 and has links to other relevant pages, including the squaring rules.
The squaring rules (presented in a more compact form than used here) are in A New Kind of Science [p. 1109](https://www.wolframscience.com/nks/notes-11-2--rules-for-the-squaring-cellular-automaton/)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U., Brandes, A. (2022).  NetLogo CA 1D-Squaring model.  http://ccl.northwestern.edu/netlogo/models/CA1D-Squaring.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2022 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2022 Cite: Wilensky, U., Brandes, A. -->
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
NetLogo 6.4.0
@#$#@#$#@
setup
repeat world-height - 1 [ go ]
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
