extensions [gogo-serial]

globals [
  serial-port   ;; different on different operating systems
]

to setup
  ifelse length (gogo-serial:ports) > 0
    [ set serial-port user-one-of "Select a port:" gogo-serial:ports ]
    [ user-message (word
      "There is a problem with the connection. Check if the board is "
      "on, and if the cable is connected. Otherwise, try to quit "
      "NetLogo, power cycle the GoGo Board, and open NetLogo again. "
      "For more information on how to fix connection issues, refer "
      "to the NetLogo documentation or the info tab of this model")
    stop ]
  gogo-serial:open serial-port
  repeat 5
  [ if not gogo-serial:ping
    [ user-message (word
      "There is a problem with the connection. Check if the board is "
      "on, and if the cable is connected. Otherwise, try to quit "
      "NetLogo, power cycle the GoGo Board, and open NetLogo again. "
      "For more information on how to fix connection issues, refer "
      "to the NetLogo documentation or the info tab of this model")
    ] ]
  gogo-serial:talk-to-output-ports [ "a" ]
  set-current-plot "Sensor 1"
end

to test-connection
  carefully
  [ ifelse not gogo-serial:ping
    [ user-message (word
      "There is a problem with the connection. Check if the board is "
      "on, and if the cable is connected. Otherwise, try to quit "
      "NetLogo, power cycle the GoGo Board, and open NetLogo again. "
      "For more information on how to fix connection issues, refer "
      "to the NetLogo documentation or the info tab of this model")
    ]
    [ user-message "GoGo Board connected and working!" ] ]
  [ user-message error-message
    stop ]
end


; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
@#$#@#$#@
GRAPHICS-WINDOW
505
405
815
536
1
0
100.0
1
10
1
1
1
0
1
1
1
-1
1
0
0
0
0
0
ticks
30.0

BUTTON
15
155
145
200
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

MONITOR
15
325
120
370
sensor 1
gogo-serial:sensor 1
0
1
11

PLOT
15
375
835
545
Sensor 1
NIL
NIL
0.0
10.0
0.0
1023.0
true
true
"" ""
PENS
"sensor 1" 1.0 0 -2674135 true "" "let data-point-to-plot gogo-serial:sensor 1\nif data-point-to-plot <= 1023 and data-point-to-plot >= 0\n   [ plot data-point-to-plot ]\nif refresh-rate = \"medium\" [wait 0.01]\nif refresh-rate = \"slow\" [wait 0.1]"

BUTTON
450
315
555
348
plot sensor
update-plots
T
1
T
OBSERVER
NIL
P
NIL
NIL
1

BUTTON
560
315
665
348
Clear plot
clear-plot
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
15
205
165
223
Sensors
14
15.0
0

BUTTON
160
155
290
200
test connection
test-connection
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
450
145
555
180
a-on
gogo-serial:talk-to-output-ports [ \"a\" ]\ngogo-serial:output-port-on
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
565
145
670
180
a-off
gogo-serial:talk-to-output-ports [ \"a\" ]\ngogo-serial:output-port-off
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
450
190
670
223
a-reverse direction
gogo-serial:talk-to-output-ports [ \"a\" ]\ngogo-serial:output-port-reverse
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
450
235
555
268
set-a-power
gogo-serial:talk-to-output-ports [ \"a\" ]\ngogo-serial:set-output-port-power a-power
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
565
235
755
268
a-power
a-power
0
7
7
1
1
NIL
HORIZONTAL

TEXTBOX
450
10
725
28
Output Port Controls:
14
15.0
0

TEXTBOX
15
10
165
28
Initialize & test
14
15.0
1

TEXTBOX
15
230
400
315
Sensor values are arbitrary units that go from 0 to 1023.\nTo get \"real\" units such as degrees (for temperature),\nyou need to look at the sensor documentation or use\na real thermometer to build a conversion table or graph.\nYou can add up to eight sensor monitors, but each \nadditional monitor makes NetLogo slightly slower.
11
0.0
1

TEXTBOX
15
30
405
145
To use this model, you should have connected the USB cable to\nthe computer and to the GoGo Board, and installed the\nUSB-Serial drivers. Most connection problems are solved by\n(1) closing NetLogo, (2) turning the GoGo Board off,\n(3) Waiting 5 seconds, (4) turning the board back on,\n(5) waiting 5 seconds, (6) opening NetLogo again.\nRefer to the NetLogo documentation for more information.  \n(NOTE: Pressing \"setup\" twice on Mac OS may cause a crash)
11
0.0
1

TEXTBOX
450
30
770
146
You can control motors, LEDs, small light bulbs or\nrelays: turn them on and off, reverse the polarity\n(which causes motors to reverse direction), and\nchange the power level. In this model, we only\ncontrol output port A, but you can control up to\nfour ports (A, B, C and D). To use more than one\nmotor, use batteries or an external power supply.
11
0.0
1

TEXTBOX
450
290
600
310
Plotting
14
15.0
1

MONITOR
305
155
425
200
Connected to:
serial-port
17
1
11

CHOOSER
670
305
790
350
refresh-rate
refresh-rate
"fast" "medium" "slow"
1

@#$#@#$#@
## WHAT IS IT?

This simple model communicates with the sensors and output ports of a GoGo Board, an open source, easy-to-build, low cost, general purpose circuit board designed for educational projects. It uses the [`gogo-serial` extension](https://github.com/NetLogo/GoGo-Serial-Extension), which uses USB-serial communications to communicate with the GoGo board.

This model helps you test your connection to your GoGo Board, and serves as a starting point for building NetLogo activities that interact with the physical world. For a more complete version of this model, try the GoGoMonitor.

This model uses the old extension that connects to serial ports. For the new version, see the GoGo HID models.

## HOW IT WORKS

The GoGo Extension for NetLogo provides primitives for communicating with a Gogo Board
connected to your computer's USB or serial port. You can get information from sensors and control motors, LEDs, light, and relays.

## HOW TO USE IT

Connect a GoGo Board to your computer's serial or USB port (depending on the version of the board you have). Then connect sensors, motors, LEDs, relays, and lights to the board.

Press SETUP to begin communicating with the GoGo board.  When prompted, enter the name of the serial port that is connected to your board (should be the first one you see on the drop-down list). The port should be automatically detected, but if you are not sure, go to the Control Panel -> System -> Device Manager (Windows) or to the System Preferences (Mac).

Press TEST CONNECTION to check if NetLogo is communicating with your GoGo Board.

The sensor monitor shows the value of sensor 1.

The output port controls let you control the motors and lights connected to the output ports "A" of your GoGo board.

A-ON turns the output port(s) on.

A-OFF turns the output port(s) off.

A-REVERSE-DIRECTION reverses the direction of current to the output port(s). For motors, it will make it turn the other way. For LEDs, it will make the LED turn on or off (if the ports was turned on previously) because LEDs are polarized.

To change the amount of current going to the output port(s), set the A-POWER slider, then press the SET-A-POWER button.

To plot sensor 1 values, start the PLOT SENSOR forever button.  At any time, you can clear the plot with the CLEAR PLOT button.  Changing the REFRESH RATE chooser adds small delay between each data point, effectively decreasing the sampling rate.  The "FAST" mode adds no delay (resulting in 500 Hz on a fast computer), the "MEDIUM" mode adds 0.01 seconds of delay (resulting in approximately 80 Hz), and the "SLOW" mode adds 0.1 second between each measure (approximately 10 Hz). A high refresh rate ("FAST" mode) is better for data that change very quickly, but it is prone to have more noise and result in a huge data set. Slow refresh rates will result in a smoother line, but you might miss some data in between recorded data points. To export the data in your plot, right-click (on Macs, control-click) on the plot and choose "Export...".

## THINGS TO TRY

Try connecting different sensors to the GoGo Board: temperature sensors, light sensors, pressure sensors, etc.

Connect various motors, lights, and other circuits to the GoGo Board's output ports.

Change the refresh rates by editing the code in the plot, and modifying the wait time (default value is 0.01 or 0.1, higher values would cause the sampling rate to decrease).

To find out where to buy sensors and motors, go to the GoGo Board website (www.gogoboard.org)

## EXTENDING THE MODEL

Modify the plot to plot more sensors.
Add filters and normalization to the sensor data.
Using a light sensor, make a turtle move forward when it's dark, and stop when there is light.

## NETLOGO FEATURES

This model uses the NetLogo GoGo Extension. For more information, see the GoGo Extension section of the NetLogo User Manual.

## CREDITS AND REFERENCES

To learn about GoGo Boards, see http://gogoboard.org.

This model was created by Paulo Blikstein at Stanford's [Transformative Learning Technologies Lab](https://tltl.stanford.edu/).

<!-- 2012 -->
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
NetLogo 5.3.1
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
