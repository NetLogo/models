;; workarounds:
;; - #? (face): use heading arithmetic instead

to setup
  clear-all
  ask patches
    [ set pcolor white ]
  crt num-vants
    [ set heading 90 * random 4
      set color red
      set size 6 ]    ;; much easier to see this way
  reset-ticks
end

;; We can't use "ask turtles", because then the vants would
;; execute in a different random order each time.  So instead
;; we use SORT to get the turtles in order by who number.

to go-forward
  foreach sort turtles [
    ask ? [
      fd 1
      turn
    ] ]
  tick
end

to go-reverse
  foreach reverse sort turtles [
    ask ? [
      turn
      bk 1
    ] ]
  tick
end

to turn
  ifelse pcolor = white
    [ set pcolor black
      rt 90 ]
    [ set pcolor white
      lt 90 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
220
10
712
523
120
120
2.0
1
10
1
1
1
0
1
1
1
-120
120
-120
120
1
1
1
ticks
30.0

BUTTON
47
73
170
106
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
67
166
151
199
forward
go-forward
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
18
38
207
71
num-vants
num-vants
1
16
1
1
1
NIL
HORIZONTAL

BUTTON
67
200
151
233
reverse
go-reverse
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
NetLogo 5.0.5
@#$#@#$#@
setup
repeat 60000 [ go-forward ]
@#$#@#$#@
