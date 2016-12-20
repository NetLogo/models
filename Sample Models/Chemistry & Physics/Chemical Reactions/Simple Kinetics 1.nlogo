breed [reactants reactant]    ;; reactants are green, products are red
breed [products product]

to setup
  clear-all
  set-default-shape reactants "molecule1"
  set-default-shape products "molecule2"
  create-reactants number
    [ set color green
      setxy random-xcor random-ycor ]
  reset-ticks
end

to go
  ask turtles
    [ rt random-float 10 - random-float 10  ;; wander around randomly
      fd 1 ]
  ask turtles
    [ ifelse (breed = reactants)
        [ react-forward ]  ; reactants
        [ react-backward ] ; products
    ]
  tick
end

to react-forward
  if (any? other reactants-here) and
     ;; multiply Kb by 2 because 2 molecules are involved
     random-float 1000 < (Kb * 2)
    [ ask one-of other reactants-here
        [ die ]
      set breed products
      set color red ]
end

to react-backward
  if (random-float 1000) < Ku
    [ set breed reactants    ;; change back to reactant
      set color green
      hatch 1 ]         ;; then split into two reactants
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
274
10
632
369
-1
-1
14.0
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

SLIDER
12
101
261
134
Kb
Kb
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
12
136
261
169
Ku
Ku
0
100
64.0
1
1
NIL
HORIZONTAL

BUTTON
12
22
79
55
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
82
22
144
55
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
3
195
271
391
Concentration
time
# molecules
0.0
35.0
0.0
300.0
true
true
"set-plot-y-range 0 number" ""
PENS
"reactants" 1.0 0 -10899396 true "" "plot count reactants"
"products" 1.0 0 -2674135 true "" "plot count products"

SLIDER
12
66
261
99
number
number
1
1000
300.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the kinetics of a simple reversible reaction. It demonstrates numerically that the application of the Principle of Stationary Concentrations is valid in this case.

In this model there are two kinds of molecules, green and red.  Green turtles turn into red turtles bimolecularly whereas red turtles turn back into pairs of green turtles monomolecularly.  You can control the rate at which this changes occur with sliders Kb and Ku.

The reaction here is a reversible reaction of the type:

```text
                         Kb
        A + A <=======> B
                         Ku
```

An example of such a reaction would be dimerization of acetic acid:

```text
                                  Kb
        2 H C-COOH <=======> H C-COOH~...~HOOC-C H
       3           Ku     3                 3
```

This reaction is an example of a complex reaction which consists of two elementary reactions.  The forward bimolecular reaction

```text
                        Kb
        A + A --------> B
```

is characterized by the constant Kb and the reverse unimolecular reaction

```text
             Ku
        B ---------> A + A
```

is characterized by the constant Ku.

The system of ordinary differential equations (ODE) that describes the concentrations of A and B is given below:

```text
        dA           2
        -- = -2Kb * A  + 2Ku * B        (1)
        dt


        dB         2
        -- = Kb * A  - Ku * B           (2)
        dt
```

The usual initial conditions are A(0) = Ao and B(0) = 0.  While it is possible to solve this system of ODE analytically, chemists usually apply the Principle of Stationary Concentrations when they investigate the kinetics of reactions of this type.  The Principle says that one can assume that the concentrations of the species stop changing from some point on after the system reaches equilibrium.  If concentrations are stationary, the derivatives

```text
        dA               dB
        --  and  --
        dt               dt
```

are zero.  Hence one can replace the system of ODE above with the system of algebraic equations below:

```text
                    2
        0 = -2Kb * A*   + 2Ku * B*              (1')

                  2
        0 = Kb * A*  - Ku * B*                  (2')
```

where concentrations marked with * are stationary concentrations.  The second equation (2') is linearly dependent on the first equation (1').  Luckily we also have another equation coming from the law of the conservation of mass:

```text
        A* + 2 * B* = Ao                        (3)
```

From equation (2') we can express B* in terms of A* :

```text
                  Kb    2
        B*  = --  A*                    (4)
                  Ku
```

We can now plug in expression (4) into (3) and then we will have a quadratic equation in terms of A*:

```text
                  Kb   2
        A*  + -- A*  = Ao               (5)
          Ku
```

whose solution is:

```text
             _____________
             |
             |             Kb
             |  1 + 4 * --  - 1
            \|          Ku
           --------------------         (6)
                  Kb
                         2 * --
                                 Ku
```

One can now find the stationary concentration of B using equation (4).

## HOW TO USE IT

Choose the values of Ku and Kb with appropriate sliders:
- Kb controls the rate of the forward reaction by which two green turtles turn bimolecularly into a single red turtle.
- Ku controls the rate of the reverse reaction, by which a red turtle turns unimolecularly into two green turtles.

Having chosen appropriate values of the constants, press SETUP to clear the world and create an initial number of green turtles.  Note: we do not create red turtles initially, although this could be done in principle.

Press GO to start the simulation.

## THINGS TO NOTICE

You will see turtles wandering around the world and changing color.  Pay more attention to the plot of the concentrations.  Do the plots soon reach stationary concentrations?

## THINGS TO TRY

How do the stationary concentrations depend on the values of Kb and Ku?   You can change Ku and Kb while the model is running.   See if you can predict what the stationary concentrations will be with various combinations of Kb and Ku.

## EXTENDING THE MODEL

Try to implement the following reaction:

```text
                 Kb         K2
        A + A <======> B -------> C
                 Ku
```

This reaction underlines a vast number of microbiological processes (e.g. fermentation).  You can read about its kinetics in any book on Biochemistry.  Look up the so-called Michaeles-Menten equation.  Does it check numerically?

Try to implement the following reaction:

```text
                 Kb         K2
        A + B <======> C -------> D
                 Ku
```

## RELATED MODELS

Enzyme Kinetics
Chemical Equilibrium
Simple Kinetics 2
Simple Kinetics 3

## CREDITS AND REFERENCES

Thanks to Mike Stieff for his work on this model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Simple Kinetics 1 model.  http://ccl.northwestern.edu/netlogo/models/SimpleKinetics1.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1998 2001 -->
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

molecule1
true
0
Circle -7500403 true true 80 80 142
Circle -1 true false 52 195 61

molecule2
true
0
Circle -7500403 true true 78 79 146
Circle -1 true false 40 41 69
Circle -1 true false 194 42 71

molecule3
true
0
Circle -7500403 true true 92 92 118
Circle -1 true false 120 32 60
Circle -1 true false 58 183 60
Circle -1 true false 185 183 60

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
