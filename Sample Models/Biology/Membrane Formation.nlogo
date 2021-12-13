breed [waters water]
breed [oils oil]

globals [
  lipid-length         ;; Distance between the two particles that make up a lipid
  interaction-distance ;; Max distance at which two particles interact
  too-close-distance   ;; Distance at which particles are "too close"
]

to setup
  clear-all

  ;; Set globals -- these values produce good visual results
  set lipid-length 2.0
  set interaction-distance 4.0
  set too-close-distance 1.3

  set-default-shape turtles "circle"
  create-waters (num-water + num-lipids) [
    setxy random-xcor random-ycor
    set color blue
  ]

  ; To create the lipids, NUM-LIPIDS oil molecules are created. Each oil molecule then picks
  ; one water molecule that hasn't been linked to an oil yet. That water molecule is stored
  ; in a variable so that the oil molecule can perform a sequence of actions on it. The oil
  ; molecule first creates a link with its partner and then moves to position LIPID-LENGTH ;
  ; away from the water molecule.
  create-oils (num-lipids) [
    let partner one-of waters with [not any? my-links]

    ; Put lipid-length away from its partner in a random direction
    move-to partner
    fd lipid-length

    create-link-with partner
    set color orange
    ask partner [ set color violet ]
  ]
  reset-ticks
end

to go
  ask turtles [
    interact-with-neighbor
    repel-too-close-neighbor
    interact-with-partner
  ]
  tick
end

;;;;;;;;;;;;;;;;;;
; Turtle commands
;;;;;;;;;;;;;;;;;;

to interact-with-neighbor
  ; Select a random neighbor and interact with it
  let near one-of other turtles in-radius interaction-distance with [not link-neighbor? myself]
  if near != nobody [
    face near
    ifelse [breed] of near = breed [ fd water-water-force ] [ fd water-oil-force ]
  ]
end

to repel-too-close-neighbor
  ; Select a random neighbor that is too close and move away from it
  let too-near one-of other turtles in-radius too-close-distance
  if too-near != nobody [
    face too-near
    fd too-close-force
  ]
end

to interact-with-partner
  ; If in a lipid, stay the correct distance away from partner.
  let partner one-of link-neighbors
  if partner != nobody [
    face partner
    fd ((distance partner) - lipid-length)
  ]
  lt random 360
  fd random-force
end


; Copyright 2013 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
245
13
763
532
-1
-1
10.0
1
10
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
30
10
200
43
num-water
num-water
0
1000
750.0
1
1
NIL
HORIZONTAL

SLIDER
30
45
200
78
num-lipids
num-lipids
1
500
250.0
1
1
NIL
HORIZONTAL

BUTTON
30
90
96
123
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
135
90
200
125
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
30
135
200
168
water-water-force
water-water-force
0
2
0.2
.1
1
NIL
HORIZONTAL

SLIDER
30
170
200
203
water-oil-force
water-oil-force
-2
0
-0.7
.1
1
NIL
HORIZONTAL

SLIDER
30
205
200
238
too-close-force
too-close-force
-2
0
-0.3
.1
1
NIL
HORIZONTAL

SLIDER
30
240
200
273
random-force
random-force
0
1
0.1
.01
1
NIL
HORIZONTAL

PLOT
9
285
230
435
Hydrophobic Isolation
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"ratio" 1.0 0 -16777216 true "" "plot mean [\ncount oils in-radius interaction-distance\n/ count turtles in-radius interaction-distance with [not (link-neighbor? myself)]\n] of oils"

@#$#@#$#@
## WHAT IS IT?

This model simulates the formation of membranes in water. It shows how simple attractive and repulsive forces between different kinds of molecules can result in higher level structure. For more information about natural membranes, see https://en.wikipedia.org/wiki/Lipid_bilayer.

## HOW IT WORKS

The blue circles are water molecules. A purple circle connected to an orange circle is a lipid. The purple end is hydrophilic and the orange end is hydrophobic. The purple hydrophilic molecule is attracted to water, while the orange hydrophobic molecule repels water.

At each tick, every molecule picks another random molecule within INTERACTION-DISTANCE. If these two molecules are water, one is water and the other is hydrophilic, both are hydrophilic, or both are hydrophobic, the acting molecule moves towards the other molecule by WATER-WATER-FORCE. If one molecule is hydrophobic and the other is water, the molecule moves in the direction of the other by WATER-OIL-FORCE; since this value is negative, they move away from each other.

After its first move, the acting molecule then picks a random molecule in TOO-CLOSE-DISTANCE and moves in its direction by TOO-CLOSE-FORCE. Since TOO-CLOSE-FORCE is negative, this causes molecules that are too close to repel each other.

Finally, if the molecule is connected by a link to another molecule, it moves to stay exactly LIPID-LENGTH away from its partner.

The hydrophobic isolation plot shows the average percentage of each hydrophobic molecule's neighbors that are also hydrophobic . Hence, the higher this is, the more hydrophobic molecules are isolated from water and hydrophilic molecules.

## HOW TO USE IT

First choose how many water molecules and how many lipid pairs to create. Press SETUP to create molecules in random positions. Press GO to begin the simulation.

* NUM-WATER: The number of water molecules
* NUM-LIPIDS: The number of hydrophobic-hydrophilic pairs
* WATER-WATER-FORCE: How much a molecule should move when it is interacting with another molecule of the same type
* WATER-OIL-FORCE: How much a molecule should move when it is interacting with a molecule of a different type
* TOO-CLOSE-FORCE: How much a molecule should move when it's "too close" to another molecule
* RANDOM-FORCE: Each molecule will move in a random direction this amount each tick. Increasing this "heats up" the system.

## THINGS TO NOTICE

Often, the lipids will first form circular structures where their hydrophobic ends all point in towards a collection of water molecules. This is called a "micelle". Then, these micelles will join and extend, becoming a long bilayer surface. Finally, sometimes the two ends of a surface will meet, creating a membrane that separates the water on the inside from water on the outside.

Notice how the hydrophobic isolation plot generally corresponds to the presence of these structures.

## THINGS TO TRY

Try adjusting the attractive and repulsive forces between the different kinds of molecules. How much can you change the forces and still see higher level structures?

How does the concentration of lipids change what structures form? What happens when you have only lipids? Do structures still form?

How do the structures change when you set WATER-WATER-FORCE to 0? How is this reflected in the hydrophobic isolation plot? Try out various combinations of forces.

What is the neutral hydrophobic isolation? That is, what happens when both WATER-WATER-FORCE and WATER-OIL-FORCE are 0?

How does RANDOM-FORCE change the rate at which structures form? What happens when you set it really high? Can the structures hold together?

## EXTENDING THE MODEL

Try adding new types of molecules to the model. Can you get any other higher level structures to form?

Try making positive forces negative and negative forces positive.

## NETLOGO FEATURES

While the lipids act like they are "tied" together, the model doesn't actually use TIE. Since TIE maintains the relative orientation of the turtles, we would see the lipids spinning around in a crazy manner if it was used. Instead, at the end of each ticks, the molecules attached by links move towards or away from each other to make sure their distance stays at LIPID-LENGTH.

## RELATED MODELS

This model is loosely based on dissipative particle dynamics (DPD) models. These kinds of higher level structures can be observed in DPD models as well. DPD models actually take into account conservation of momentum and the fact that molecules are constantly interacting with many other molecules.

## CREDITS AND REFERENCES

Two papers that describe this work are:

* Gazzola, G., Buchanan, A., Packard, N. & Bedeau. M. (2007).  Catalysis by Self-Assembled Structures in Emergent Reaction Networks. In M. Capcarrere, A.A. Freitas, P.J. Bentley, Johnson, C.G. Johnson, & J. Timmmis (Eds). Advances in Artificial Life. Lecture Notes in Computer Science. Vol. 4648, pp. 876-885. Springer Verlag. https://link.springer.com/chapter/10.1007/978-3-540-74913-4_88#page-1

* Bedau M. A., Buchanan A., Gazzola G., Hanczyc M., Maeke T., McCaskill J. S., Poli I. and Packard N. H. (2005). Evolutionary design of a DDPD model of ligation. In Proceedings of the 7th International Conference on Artificial Evolution EA'05. Lecture Notes in Computer Science 3871, 201-212, Springer Verlag.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Head, B. and Wilensky, U. (2013).  NetLogo Membrane Formation model.  http://ccl.northwestern.edu/netlogo/models/MembraneFormation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2013 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2013 Cite: Head, B. -->
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
setup
repeat 250 [ go ]
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
