globals [
  last-action ; used to store the last user action
  mouse-has-gotten-air? ; a boolean representing whether the mouse has been released
  polygon-completed? ; a boolean representing whether the polygon is completed
  polygon-vertices ; a list of vertices for a polygon
  previous-click ; used to store the previous user click
  current-polygon-id ; stores the current polygon id
]

breed [ dots dot ]

undirected-link-breed [ edges edge ]
undirected-link-breed [ segments segment ]

edges-own [ polygon-id ]

to setup

  clear-all

  resize-world 0 width 0 height
  set-patch-size unit-size

  set last-action "none"
  set mouse-has-gotten-air? true
  set polygon-completed? false
  set polygon-vertices []
  set previous-click nobody
  set current-polygon-id 1

  ask patches [
    sprout-dots 1 [
      set color yellow
      set size 0.2
      set shape "circle"
    ]
  ]
  reset-ticks

end

to go
  if last-action != action [                                  ; Checks if user changes to a new action
    clear-current-polygon                                     ; If so, clear any incomplete polygon
    set previous-click nobody                                 ; and any incomplete segment
    set last-action action
  ]

  let candidate one-of turtles with [ distancexy mouse-xcor mouse-ycor < 0.3 ]    ; When mouse hovers over unselected dots,
  if candidate != nobody [
    if candidate != previous-click [
      ; flicker the size of the dot
      ask candidate [ set size 0.4 ]
      ask candidate [ set size 0.2 ]
    ]
  ]

  ; If user chooses action "Draw Segment", run draw-segment procedure
  ifelse action = "Draw Segment" [
    set polygon-completed? false
    set polygon-vertices []
    draw-segment
  ][ ; otherwise run draw-polygon procedure
    ifelse action = "Draw Polygon" [
      draw-polygon
    ][ ; otherwise run delete-segment procedure
      ifelse action = "Delete Segment" [
        delete-segment
      ][
        error "There is an error in this model"
      ]
    ]
  ]
end

to draw-segment
  join-candidate ([ first-point ->                 ; Run join-candidate anonymous procedure
    ask first-point [ set size 0.5  set color 87 ]   ; Make selected dot bigger & green
  ])
  ; Create segment between first and second dot selected
  ([ [first-point second-point] -> add-segment first-point second-point ])
  ([ [first-point second-point] -> second-point != nobody ])

end


to delete-segment
  if mouse-down? [
    if mouse-has-gotten-air? [
      let candidate (one-of dots with [ distancexy mouse-xcor mouse-ycor < 0.3 ])
      if candidate != nobody [
        ask segments [
          if end1 = dot [who] of candidate [die]
          if end2 = dot [who] of candidate [die]
        ]
      ]
    ]
  ]
end


to add-segment [ candidate previous ]
  ; Reset the size of previous dot and color
  ask previous [ reset ]

  if not [ segment-neighbor? previous ] of candidate [            ; Checks to make sure selected candidate is not the same as previous
    ask candidate [                                               ; If not, create segment between candidate and previous
      create-segment-with previous [
        set color segment-color
        set thickness 0.15
      ]
    ]
  ]
end

to draw-polygon
  join-candidate ([ first-point ->                          ; Run join-candidate task procedure
    ask first-point [ set size 0.5  set color 87 ]            ; Make first dot selected bigger & green
    set polygon-completed? false                              ; Notes that the polygon has not been completed
    set polygon-vertices (list first-point)                   ; Reset polygon-vertices list to first dot selected
  ])

  ; Create polygon-edge between previous and current dot selected
  ([ [first-point second-point] -> add-polygon-edge first-point second-point ])

  ; End task when the polygon is completed
([ -> polygon-completed? ])
end

to add-polygon-edge [ candidate previous ]                        ; Creates edge between selected dot (candidate) and previously selected dot (prev)
  set polygon-vertices (lput candidate polygon-vertices)      ; Adds new dot to polygon-vertices list

  ; Reset dot size and color of prev
  ask previous [ reset ]

  ask candidate [                                             ; Draw an edge from candidate to prev
    create-edge-with previous [
      set color white
      set thickness 0.15
      set polygon-id current-polygon-id
    ]
    set size 0.5
    set color 87
  ]

  set previous-click candidate  ; Set current dot as previous-click

  if candidate = first polygon-vertices [ ; If selected dot matches the first element of polygon-vertices (the first dot chosen)
    assess-for-polygonality               ; then check to see if it's a polygon
    reset-previous-click                  ; and reset
  ]
end

to join-candidate [ start-task continue-task is-finished?-task ]
  ; If user clicks somewhere
  ifelse mouse-down? [
    ; and then releases the mouse,
    if (mouse-has-gotten-air?) [
       ; choose the dot that is at most 0.3 units from the user click
      let candidate (one-of turtles with [ distancexy mouse-xcor mouse-ycor < 0.3 ])

      ; If a candidate is selected and is not the previously chosen dot,
      if (candidate != nobody) and (candidate != previous-click) [
        set last-action action

        ; then run start-task if the candidate is the first dot chosen,
        ifelse previous-click = nobody [
          (run start-task candidate)
        ][
          ; or run continue-task if THE candidate is not the first dot chosen.
          (run continue-task candidate previous-click)
        ]

        ; If the task is finished, reset variables
        ifelse (runresult is-finished?-task candidate previous-click) [
          reset-previous-click
          if action = "Draw Polygon" [
            ; and assign the polygon a unique identifier
            set current-polygon-id current-polygon-id + 1
          ]
          set last-action "none"
        ][
           ; Otherwise, set the current candidate to previous candidate and run continue-task
          set previous-click candidate
        ]
      ]
    ]
    set mouse-has-gotten-air? false  ; If mouse is down, set mouse-has-gotten-air? to false
  ][
    set mouse-has-gotten-air? true   ; If mouse not down, set mouse-has-gotten-air? to true
  ]
end

to clear-current-polygon  ; Clears only the polygon user is currently working on and resets all variables
  reset-previous-click
  ask edges with [ polygon-id = current-polygon-id ] [ die ]
  set last-action "none"
  ask dots [ reset ]
end

to reset-previous-click  ; Reset size of previous dot clicked and resets previous-click variable
  if previous-click != nobody [ ask previous-click [ reset ] ]
  set previous-click nobody
end

to check-area ; Generates user message with area of current polygon when user clicks check-area button
  ifelse polygon-completed? [
    user-message (word "The area of this polygon is " abs(area) " square units.")
  ][
    ; If no current polygon is recognized, generates this error message
    user-message (word "I can only determine the area of the last polygon constructed using the 'Draw Polygon' action. If you change actions, I automatically reset.")
  ]
end

to reset ; turtle procedure
  ; reset a point's color to default size and color
  set size 0.2
  set color yellow
end

;  Area calculation based on formula from: http://mathworld.wolfram.com/PolygonArea.html
;  Area = 1/2 * (the determinant of the matrices formed by each consecutive pair of coordinates)
to-report area  ; Calls on area-helper for list of polygon-vertices
  let vertex (first polygon-vertices)
  report area-helper polygon-vertices (list 0 ([ xcor ] of vertex) ([ ycor ] of vertex))
end

; A recursive procedure that sweeps from each vertex to the next, until vertices-list is empty.
to-report area-helper [ vertices-list accumulator ]
  ; If finished with area sweep of all vertices, report the absolute value of area.
  ifelse empty? vertices-list [
    report abs first accumulator
  ][
    ; If not, maintain the partial area,
    let area-accumulator (first accumulator)
    let x (item 1 accumulator)
    let y (item 2 accumulator)

    let vertex (first vertices-list)   ; take the coordinates of the first vertex in the vertices-list
    let tail (but-first vertices-list) ; and the coordinates of the next vertex

    let vx ([ xcor ] of vertex)
    let vy ([ ycor ] of vertex)
    let determinant (x * vy - y * vx)                      ; and take the determinant of the 2x2 matrix formed by the pair of coordinates.

    let new-area (area-accumulator + (0.5 * determinant))  ; Keep adding area until vertices-list is empty

    report area-helper tail (list new-area vx vy)
  ]
end

; Keeps a sum of all active polygon-edges (does not measure segments)
to-report perimeter
  report sum ([ link-length ] of (link-set polygon-edges))
end

; Reports all the edges of the active polygon
to-report polygon-edges
  report edges-helper polygon-vertices []
end

; Creates a list of all edges of a polygon by taking link made by each consecutive pair of dots in vertices-list
to-report edges-helper [ vertices-list end-list ]
  let vertex (first vertices-list)
  let tail (but-first vertices-list)
  report ifelse-value empty? tail [ end-list ] [ edges-helper tail (lput ([link-with (first tail)] of vertex) end-list) ]
end

;  Polygonality code: Checks all edges and its intersections with other edges. In order to be a polygon, each edge must intersect with exactly two other edges.
to assess-for-polygonality

  let edgeset             (link-set polygon-edges)
  let self-others-pairs   ([(list self ([ self ] of (other edgeset)))] of edgeset)
  let all-intersections   (map [ an-intersection -> find-intersections (item 0 an-intersection) (item 1 an-intersection) ] self-others-pairs)
  let valid-intersections (map [ an-intersection -> filter [ x -> x != [] ] an-intersection ] all-intersections)

ifelse for-all ([ an-intersection -> length an-intersection = 2 ]) valid-intersections [
    set polygon-completed? true
  ] [
    user-message "This shape is not a polygon."
    clear-current-polygon
  ]
end

;  reports intersections of one edge with others
to-report find-intersections [ s others ]
  report map [ an-edge -> intersection s an-edge ] others
end

;  reports the number of intersections
to-report for-all [ t xs ]
  report (length filter t xs) = (length xs)
end

;  reports a two-item list of x and y coordinates, or an empty list if no intersection is found
to-report intersection [ t1 t2 ]

  let shared-ends (shared-link-ends t1 t2)
  if (shared-ends != []) [ report shared-ends ]

  let m1 [tan (90 - link-heading)] of t1
  let m2 [tan (90 - link-heading)] of t2
  ;  treat parallel/collinear lines as non-intersecting
  if m1 = m2 [ report [] ]
  ;  is t1 vertical? if so, swap the two turtles
  if abs m1 = tan 90 [
    ifelse abs m2 = tan 90
      [ report [] ]
      [ report intersection t2 t1 ]
  ]
  ;  is t2 vertical? if so, handle specially
  if abs m2 = tan 90 [
      ;  represent t1 line in slope-intercept form (y=mx+c)
      let c1 [ link-ycor - link-xcor * m1 ] of t1
      ;  t2 is vertical so we know x already
      let x [ link-xcor ] of t2
      ;  solve for y
      let y m1 * x + c1
      ;  check if intersection point lies on both segments
      if not [ x-within? x ] of t1 [ report [] ]
      if not [ y-within? y ] of t2 [ report [] ]
      report list x y
  ]
  ;  now handle the normal case where neither turtle is vertical;
  ;  start by representing lines in slope-intercept form (y=mx+c)
  let c1 [ link-ycor - link-xcor * m1 ] of t1
  let c2 [ link-ycor - link-xcor * m2 ] of t2
  ;  now solve for x
  let x (c2 - c1) / (m1 - m2)
  ;  check if intersection point lies on both segments
  if not [ x-within? x ] of t1 [ report [] ]
  if not [ x-within? x ] of t2 [ report [] ]

  report list x (m1 * x + c1)
end

;  reports a list of the intersection of two links if they intersect at their endpoints, otherwise reports an empty list
to-report shared-link-ends [a b]
  let a-ends [ (list end1 end2) ] of a
  let b-ends [ (list end1 end2) ] of b
  let shared-ends filter [ a-end -> member? a-end b-ends ] a-ends
  report ifelse-value empty? shared-ends [
    (list)
  ] [
    (list (first shared-ends) (first shared-ends))
  ]
end


;  turtle procedure
;  reports a boolean that helps check for intersections (x-coordinate)
to-report x-within? [ x ]
  report abs (link-xcor - x) <= abs (link-length / 2 * sin link-heading)
end

;  turtle procedure
;  reports a boolean that helps check for intersections (y-coordinate)
to-report y-within? [ y ]
  report abs (link-ycor - y) <= abs (link-length / 2 * cos link-heading)
end

;  reports the x-coordinate of the midpoint of a link
to-report link-xcor
  report ([ xcor ] of end1 + [ xcor ] of end2) / 2
end

;  reports the y-coordinate of the midpoint of a link
to-report link-ycor
  report ([ ycor ] of end1 + [ ycor ] of end2) / 2
end


; Copyright 2017 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
245
15
1163
479
-1
-1
35.0
1
10
1
1
1
0
0
0
1
0
25
0
12
0
0
0
ticks
30.0

BUTTON
25
195
100
228
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

MONITOR
25
365
200
410
NIL
perimeter
3
1
11

CHOOSER
25
240
200
285
action
action
"Draw Polygon" "Draw Segment" "Delete Segment"
1

BUTTON
120
195
200
228
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

SLIDER
25
70
200
103
width
width
4
35
25.0
1
1
NIL
HORIZONTAL

SLIDER
25
110
200
143
height
height
4
25
12.0
1
1
NIL
HORIZONTAL

SLIDER
25
150
200
183
unit-size
unit-size
10
100
35.0
5
1
NIL
HORIZONTAL

TEXTBOX
25
10
265
76
To resize your world, adjust \nthese sliders.  Hit \"setup\" to\napply your changes.
14
0.0
1

INPUTBOX
25
295
200
355
segment-color
85.0
1
0
Color

BUTTON
25
460
200
493
clear-segments
ask segments [ die ]
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
25
500
200
533
clear-polygons
ask edges [ die ]
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
25
420
200
453
NIL
check-area
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

_Lattice Land - Explore_ is one of several models in the Lattice Land software suite. Lattice Land is an interactive MathLand, a microworld in which students can uncover advanced mathematical thinking through play, conjecture, and experimentation. It provides another entryway into geometry, investigating the geometry of a discrete lattice of points. In Lattice Land, there is no one right answer and no pre-determined pathway you must travel. However, even seemingly trivial exercises can quickly become rich explorations.

A lattice is an array of dots on a plane such that there is one dot at each coordinate (x,y), where x and y are integers. Thus each dot on the lattice is one unit away from each of its four closest neighbors (one above, one below, one to the left, and one to the right). A lattice polygon is a polygon whose vertices fall on dots of the lattice.

In this exploratory model, you can draw multiple polygons and segments, change the size of the world, change the magnitude of the unit of distance between dots, and check areas and perimeters of polygons. You can use this model to learn about the features of Lattice Land, define the properties of polygons, or to make lattice artwork.

## HOW IT WORKS

Using Lattice Land, students can draw any lattice polygon in addition to drawing simple line segments. Polygons do not need to be limited to just rectangles or triangles.

We've implemented a lattice in NetLogo by using agents called DOTS sprouted at the center of each patch. The segments between the dots are simply edges or links. The environment then responds to mouse clicks inside of the world and performs the specified action (either draw a side of a polygon or draw a single line segment).

In order to analyze the polygons in question, we use an algorithmic method of calculating the perimeter and area of the polygon based on iterating over the edges of the polygon. However, students are also expected to calculate these different properties by hand and then compare them to the algorithmic results.  For instance, students should apply the distance formula to calculate perimeter, or apply the idea of dissection to calculate area. Students should also be encouraged to come up with new ways of calculating these properties.

## HOW TO USE IT

The SETUP button creates a world with the given dimensions and size set by the sliders.

Select an ACTION.

  * DRAW POLYGON traces a path from the first dot clicked to the next dot clicked. It continues to wait for clicks until the user clicks back on the first dot. (When using this action, Lattice Land will track the perimeter of each active polygon, and will calculate its area when it is complete)

  * DRAW SEGMENT allows you to join any two dots clicked consecutively by a line segment.

  * DELETE SEGMENT allows you to delete any line segment you have drawn by selecting either endpoint of the segment. Note that this will delete ALL segments that share the selected endpoint. (This action only works on line segments, not edges of polygons.)

SEGMENT-COLOR allows you to select different colors for your segments.

Press the GO button to run an ACTION.

Press CHECK-AREA to verify the area of the last polygon you've just drawn. (Note that check-area will not work on apparent polygons created with segments, only explicit polygons).

Look at the PERIMETER monitor to see the perimeter of the polygon you've drawn.

## THINGS TO NOTICE

Polygons will always be white. This is meant to help distinguish them from segments as you dissect polygons in various ways. When using Lattice Land, it helps to use segment colors other than black and white.

You can draw some shapes using DRAW POLYGON that are not polygons. This will generate an error message. What types of lattice shapes are not lattice polygons?

## THINGS TO TRY

  *  Create as many different shapes as you can that have only 1 square unit area.
  *  Create as many different shapes as you can that have 1.5 square unit area.
  *  Create as many different shapes as you can that have 2 square units area.
  *  Keep going until you've generated a number of interesting shapes with 8 square units area.
  *  For each polygon, count and record the number of dots that are strictly inside the polygon.  Also count and record the number of dots that fall on an edge of the polygon.  Do you see a pattern?
  *  If not, just look at polygons which have no dots on the inside.  Do you see a pattern now?  Can you write a formula to describe it?
  *  Try to generalize an area formula for a lattice polygon using only the number of dots on its Boundary (B) and the number of dots on the Inside (I).


Make sure to try dissecting a polygon in different ways. For example:

  *  Slice out rectangles until you can no longer do so.
  *  Triangulate the polygon
  *  Enclose the polygon in a figure whose area you know and slice away pieces

## EXTENDING THE MODEL

Notice that the DRAW-POLYGON procedure deletes closed figures that aren't polygons. But what if you change the definition of what it means to be a polygon? Change the code to reflect this new definition. How does this alter or break the rules we currently use to understand polygons (e.g., area formulas)?

## NETLOGO FEATURES

The DRAW-SEGMENT and DRAW-POLYGON actions are programmed similarly and each call on two anonymous procedures two actually draw on the screen. However, DRAW-POLYGON has to keep a list of past vertices drawn.

The INTERSECTION reporter checks for intersections between links by converting the links into slope-intercept form and then checking for line intersections.

This model uses continuous updates, rather than tick-based updates. This means that the model does not update at regular time intervals (ticks) dictated by the code. Instead, this model updates when the user performs an action. Thus, the depth of inquiry into the mathematics of Lattice Land is dictated by the user: nothing (other than the lattice) is generated until the user draws something.

## RELATED MODELS

* Intersecting Links

## CREDITS AND REFERENCES

The area formula used for this model comes from the following site:
http://mathworld.wolfram.com/PolygonArea.html

Area = 1/2 * (the determinant of the matrices formed by each consecutive pair of coordinates)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Pei, C. and Wilensky, U. (2017).  NetLogo Lattice Land - Explore model.  http://ccl.northwestern.edu/netlogo/models/LatticeLand-Explore.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2017 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2017 Cite: Pei, C. -->
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
