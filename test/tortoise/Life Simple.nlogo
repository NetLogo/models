patches-own [ living? live-neighbors ]

to setup
  clear-all
  ask patches [ cell-death ]
  ask patch  0  0 [ cell-birth ]
  ask patch -1  0 [ cell-birth ]
  ask patch  0 -1 [ cell-birth ]
  ask patch  0  1 [ cell-birth ]
  ask patch  1  1 [ cell-birth ]
  reset-ticks
end

to cell-birth set living? true  set pcolor white end
to cell-death set living? false set pcolor black end

to go
  ask patches [
    set live-neighbors count neighbors with [living?] ]
  ask patches [
    ifelse live-neighbors = 3
      [ cell-birth ]
      [ if live-neighbors != 2
        [ cell-death ] ] ]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
495
316
5
5
25.0
1
10
1
1
1
0
1
1
1
-5
5
-5
5
0
0
1
ticks
30.0

BUTTON
58
108
124
141
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
81
177
144
210
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

@#$#@#$#@
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

@#$#@#$#@
NetLogo 5.0.4
@#$#@#$#@
