extensions [ matrix ]

to setup
  clear-all

  let m1 matrix:from-column-list [[1 4 7][2 5 8][3 6 9]] ; 3x3 matrix
  let m2 matrix:from-row-list [[0 0 0][1 1 1][2 2 2][3 3 3]] ; 4x3 matrix
  let m3 matrix:make-identity 2 ; 2x2 identity matrix
  let m4 matrix:make-constant 5 1 100 ; 5x1 matrix, containing 100 in each entry

  output-print "m1"
  output-print m1
  output-print "m2"
  output-print m2
  output-print "m3"
  output-print m3
  output-print "m4"
  output-print m4

  output-print matrix:get m1 1 2   ; =>  (row 1, column 2), result is 6

  let mRef m2              ; mRef is another reference to the same matrix as m2
  let mCopy matrix:copy m2 ; => mCopy = new copy, not a reference to m2!

  matrix:set m2 0 1 9      ; Note mCopy remains unchanged, but m2 and mRef change

  output-print "m2 after matrix:set m2 0 1 9"
  output-print m2 ; => matrix: [[0 9 0][1 1 1][2 2 2][3 3 3]]
  output-print "mRef after matrix:set m2 0 1 9"
  output-print mRef ; same as above
  output-print "mCopy after matrix:set m2 0 1 9"
  output-print mCopy ; different -- no 9 in the first row.

  output-print "the dimensions of m4"
  output-print matrix:dimensions m4 ; => [5,1]
  output-print "m1 to a row list"
  output-print matrix:to-row-list m1 ; => [[1 2 3] [4 5 6] [7 8 9]]
  output-print "m4 to a column list"
  output-print matrix:to-column-list m4 ; => [[100][100][100][100][100]]

  let m5 matrix:plus-scalar m3 1
  output-print "m5 = m3 + scalar 1"
  output-print m5 ; => matrix:  [[2 1][1 2]]

  output-print "m3 + m5"
  output-print matrix:plus m3 m5 ; => [[3 1][1 3]]

  output-print "m5 x scalar 10"
  output-print matrix:times-scalar m5 10 ; => [[20 10][10 20]]
  output-print "matrix:times [[1 2][3 4]] [[0 1][-1 0]]"
  output-print matrix:times (matrix:from-row-list [[1 2][3 4]])
    (matrix:from-row-list [[0 1][-1 0]])  ; => {{matrix:  [ [ -2 1 ][ -4 3 ] ]}}

  output-print "matrix:times-element-wise [[1 2][3 4]] [[0 1][-1 0]]"
  output-print matrix:times-element-wise (matrix:from-row-list [[1 2][3 4]])
    (matrix:from-row-list [[0 1][-1 0]])  ; => {{matrix:    [[0 2][-3 0] ]}}

  output-print "matrix:inverse [[2 2][2 0]]"
  output-print matrix:inverse (matrix:from-row-list [[2 2][2 0]])  ; => {{matrix:  [ [ 0 0.5 ][ 0.5 -0.5 ] ]}}
  carefully [
    output-print matrix:inverse matrix:from-row-list [[0 0] [0 0]]
  ][
    output-print "Can't invert matrix: [[0 0] [0 0]]!"
  ]

  output-print "matrix:transpose m2"
  output-print matrix:transpose m2 ; => matrix: [[0 1 2 3][9 1 2 3][0 1 2 3]]
  output-print "matrix:submatrix m1 0 1 2 3"
  output-print matrix:submatrix m1 0 1 2 3 ; matrix, rowStart, colStart, rowEnd, colEnd
                                           ; rows from 0 (inclusive) to 2 (exclusive),
                                           ; columns from 1 (inclusive) to 3 (exclusive)
                                           ; => matrix: [[2 3][5 6]]
  output-print "matrix:get-row m1 2"
  output-print matrix:get-row m1 1         ; puts the second row of m1 (starting from 0) in a simple
                                           ; NetLogo list.  => [4 5 6]
  output-print "matrix:get-column m1 2"
  output-print matrix:get-column m1 1      ; puts the second column of m1 (starting from 0) in a simple
                                           ; NetLogo list.  => [2 5 8]

  output-print "create a new matrix m6 from row list [[0 0 0][1 1 1][2 2 2][3 3 3]]"
  let m6 matrix:from-row-list [[0 0 0][1 1 1][2 2 2][3 3 3]] ; 4x3 matrix
  output-print m6
  output-print "matrix:set-row m6 1 [20 21 22]"
  matrix:set-row m6 1 [20 21 22]  ; => [[0 0 0][20 21 22][2 2 2][3 3 3]]
  output-print m6
  output-print "matrix:set-column m6 2 [10 11 12 13]"
  matrix:set-column m6 2 [10 11 12 13]  ; => [[0 0 10][20 21 11][2 2 12][3 3 13]]
  output-print m6
  output-print "matrix:swap-rows m6 1 2"
  matrix:swap-rows m6 1 2  ; => [[0 0 10][2 2 12][20 21 11][3 3 13]]
  output-print m6
  output-print "matrix:swap-columns m6 2 0"
  matrix:swap-columns m6 2 0  ; => [[10 0 0][12 2 2][11 21 20][13 3 3]]
  output-print m6

  output-print "matrix:real-eigenvalues m5"
  ; recall m5 = [[2 1][1 2]]
  output-print matrix:real-eigenvalues m5 ; => [1.0000000000000002 3] NOTE: accuracy not perfect.
  output-print "matrix:imaginary-eigenvalues m5"
  output-print matrix:imaginary-eigenvalues m5 ; => [ 0 0 ]
  output-print "matrix:eigenvectors m5"
  output-print matrix:eigenvectors m5 ; => matrix:  [[0.707... 0.707...][-0.707... 0.707...]] (.707... = sqrt(2)/2 )

  let A matrix:from-row-list [[1 2][3 4]]
  let B matrix:from-row-list [[-2 1][-4 3]]
  output-print "matrix:solve [[1 2][3 4]] [[-2 1][-4 3]]"
  output-print matrix:solve A B ; => [[0 1][-1 0]]
                                ;  Solve is sort of like matrix division.
                                ;  That is, it tries to find matrix X such that  A * X = B.
                                ;  It gives a "least-squares" solution, if no perfect solution exists.

  output-print "matrix:set-and-report m1 2 2 0"
  output-print matrix:set-and-report m1 2 2 0  ;; m1 is unchanged, a new matrix is reported.
  output-print "m1 is unchanged"
  output-print m1
  set m1 matrix:set-and-report m1 2 2 0        ;; can also change m1 itself, using the reporter.

  output-print "matrix:forecast-linear-growth [20 25 28 32 35 39]  => ?? linear growth rate"
  output-print matrix:forecast-linear-growth [20 25 28 32 35 39]  ; a linear extrapolation of the next item in the list.

  output-print "matrix:forecast-compound-growth [20 25 28 32 35 39] => ~13.7% compound growth rate"
  output-print matrix:forecast-compound-growth [20 25 28 32 35 39]
  output-print "matrix:forecast-compound-growth [2 2.2 2.42 2.662 2.9282] => 10.0% compound growth rate"
  output-print matrix:forecast-compound-growth [2 2.2 2.42 2.662 2.9282]
  output-print "matrix:forecast-compound-growth [4 3.6 3.24 2.916 2.6244] => minus 10.0% compound growth rate"
  output-print matrix:forecast-compound-growth [4 3.6 3.24 2.916 2.6244]

  output-print "matrix:forecast-continuous-growth [20 25 28 32 35 39] => ~12.8% continuous growth rate"
  output-print matrix:forecast-continuous-growth [20 25 28 32 35 39]
  output-print "matrix:forecast-continuous-growth [2 2.2 2.42 2.662 2.9282] => ~9.5% continuous growth rate"
  output-print matrix:forecast-continuous-growth [2 2.2 2.42 2.662 2.9282] ; a compound growth extrapolation of the next item in the list.
  output-print "matrix:forecast-continuous-growth [4 3.6 3.24 2.916 2.6244] => ~ minus 10.5% continuous growth rate"
  output-print matrix:forecast-continuous-growth [4 3.6 3.24 2.916 2.6244]

  output-print "matrix:regress matrix:from-column-list [[2 4 5 8 10] [3 4 3 7 8] [2 3 5 8 9]]"
  output-print matrix:regress matrix:from-column-list [[2 4 5 8 10] [3 4 3 7 8] [2 3 5 8 9]]
  output-print "matrix:regress matrix:from-row-list [[2 3 2] [4 4 3] [5 3 5] [8 7 8] [10 8 9]]"
  output-print matrix:regress matrix:from-row-list [[2 3 2] [4 4 3] [5 3 5] [8 7 8] [10 8 9]]

  ; The forecasts may also be done using regress.  Here they are. Note that the next value
  ; to be forecast is for the value after the 6 observations supplied. But since lists begin with position
  ; zero, that will be for position 6.
  ; this is what happens inside matrix:forecast-linear-growth.
  output-print "long way to do the linear forecast using regress"
  let data-list [20 25 28 32 35 39]
  let indep-var (n-values length data-list [ [n] -> n ]) ; 0,1,2...,5
  let lin-output matrix:regress matrix:from-column-list (list data-list indep-var)
  let lincnst item 0 (item 0 lin-output)
  let linslpe item 1 (item 0 lin-output)
  let linR2   item 0 (item 1 lin-output)
  output-print (list (lincnst + linslpe * 6) (lincnst) (linslpe) (linR2))

  ; this is what happens inside matrix:forecast-compound-growth.
  output-print "long way to do the compound-growth forecast using regress"
  let com-log-data-list  (map [ [n] -> ln n ] [20 25 28 32 35 39])
  let com-indep-var2 (n-values length com-log-data-list [ [n] -> n ]) ; 0,1,2...,5
  let com-output matrix:regress matrix:from-column-list (list com-log-data-list com-indep-var2)
  let comcnst exp item 0 (item 0 com-output)
  let comrate exp item 1 (item 0 com-output)
  let comR2       item 0 (item 1 com-output)
  output-print (list (comcnst * comrate ^ 6) (comcnst) (comrate) (comR2))

  ; this is what happens inside matrix:forecast-continuous-growth.
  output-print "long way to do the continuous-growth forecast using regress"
  let con-log-data-list  (map [ [n] -> ln n ] [20 25 28 32 35 39])
  let con-indep-var2 (n-values length con-log-data-list [ [n] -> n ]) ; 0,1,2...,5
  let con-output matrix:regress matrix:from-column-list (list con-log-data-list con-indep-var2)
  let concnst exp item 0 (item 0 con-output)
  let conrate     item 1 (item 0 con-output)
  let conR2       item 0 (item 1 con-output)
  output-print (list (concnst * exp (conrate * 6)) (concnst) (conrate) (conR2))


  ;;NOTE: The matrix extension could be extended with more functionality,
  ;;      since the Jama library it is based on can do much more
  ;;        (e.g. LU, Cholesky, SV decompositions)

end


; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
@#$#@#$#@
GRAPHICS-WINDOW
26
77
580
112
-1
-1
26.0
1
10
1
1
1
0
1
1
1
-10
10
0
0
1
1
1
ticks
30.0

BUTTON
74
24
140
57
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

OUTPUT
9
69
739
465
12

@#$#@#$#@
## WHAT IS IT?

This model demonstrates basic usage of the matrix extension.

<!-- 2011 -->
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
NetLogo 6.0
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
