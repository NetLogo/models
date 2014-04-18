;; Tortoise workarounds:
;; - no mouse support - mouse code removed wholesale

breed [cells cell]    ;; living cells
breed [babies baby]   ;; show where a cell will be born

patches-own [
  live-neighbors  ;; count of how many neighboring cells are alive
]

to setup-blank
  clear-all
  set-default-shape cells "circle"
  set-default-shape babies "dot"
  ask patches
    [ set live-neighbors 0 ]
  reset-ticks
end

to setup-random
  setup-blank
  ;; create initial babies
  ask patches
    [ if random-float 100.0 < initial-density
      [ sprout-babies 1 ] ]
  ;; grow the babies into adult cells
  go
  reset-ticks  ;; set the tick counter back to 0
end

;; this procedure is called when a cell is about to become alive
to birth  ;; patch procedure
  sprout-babies 1
  [ ;; soon-to-be-cells are lime
    set color lime + 1 ]  ;; + 1 makes the lime a bit lighter
end

to go
  ;; get rid of the dying cells from the previous tick
  ask cells with [color = gray]
    [ die ]
  ;; babies become alive
  ask babies
    [ set breed cells
      set color white ]
  ;; All the live cells count how many live neighbors they have.
  ;; Note we don't bother doing this for every patch, only for
  ;; the ones that are actually adjacent to at least one cell.
  ;; This should make the program run faster.
  ask cells
    [ ask neighbors
      [ set live-neighbors live-neighbors + 1 ] ]
  ;; Starting a new "ask" here ensures that all the cells
  ;; finish executing the first ask before any of them start executing
  ;; the second ask.
  ;; Here we handle the death rule.
  ask cells
    [ ifelse live-neighbors = 2 or live-neighbors = 3
      [ set color white ]
      [ set color gray ] ] ;; gray cells will die next round
                           ;; Now we handle the birth rule.
  ask patches
    [ if not any? cells-here and live-neighbors = 3
      [ birth ]
    ;; While we're doing "ask patches", we might as well
    ;; reset the live-neighbors counts for the next generation.
    set live-neighbors 0 ]
  tick
end

@#$#@#$#@
GRAPHICS-WINDOW
290
10
797
538
35
35
7.0
1
10
1
1
1
0
1
1
1
-35
35
-35
35
1
1
1
ticks
15.0

SLIDER
125
72
281
105
initial-density
initial-density
0.0
100.0
35
0.1
1
%
HORIZONTAL

BUTTON
16
73
118
106
NIL
setup-random
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
17
227
121
265
go-once
go
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
127
227
231
265
go-forever
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

MONITOR
67
274
170
319
current density
(count cells\n/ count patches) * 100
2
1
11

BUTTON
16
37
118
70
NIL
setup-blank
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
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

circle
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

@#$#@#$#@
NetLogo 5.0.5
@#$#@#$#@
setup-random repeat 20 [ go ]
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
