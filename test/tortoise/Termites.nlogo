turtles-own [next steps]

to setup
  clear-all
  ask patches [
    if random 100 < density
      [ set pcolor yellow ] ]
  create-turtles number [
    set color white
    setxy random-xcor random-ycor
    set size 1.5
    set next 1
  ]
  reset-ticks
end

to go
  ask turtles
    [ ifelse steps > 0
        [ set steps steps - 1 ]
        [ action
          wiggle ]
      fd 1 ]
  tick
end

to wiggle
  rt random 50
  lt random 50
end

to action
  ifelse next = 1
    [ search-for-chip ]
    [ ifelse next = 2
      [ find-new-pile ]
      [ ifelse next = 3
        [ put-down-chip ]
        [ get-away ] ] ]
end

to search-for-chip
  if pcolor = yellow
    [ set pcolor black
      set color orange
      set steps 20
      set next 2 ]
end

to find-new-pile
  if pcolor = yellow
    [ set next 3 ]
end

to put-down-chip
  if pcolor = black
   [ set pcolor yellow
     set color white
     set steps 20
     set next 4 ]
end

to get-away
  if pcolor = black
    [ set next 1 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
236
10
696
491
12
12
18.0
1
10
1
1
1
0
1
1
1
-12
12
-12
12
1
1
1
ticks
30.0

BUTTON
43
120
109
153
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
116
120
179
153
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
1

SLIDER
8
39
219
72
number
number
1
1000
50
1
1
NIL
HORIZONTAL

SLIDER
8
73
219
106
density
density
0.0
100.0
25
1.0
1
%
HORIZONTAL

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

@#$#@#$#@
NetLogo 5.0.4
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
