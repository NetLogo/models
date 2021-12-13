extensions [ gis ]
globals [ cities-dataset
          rivers-dataset
          countries-dataset
          elevation-dataset
          should-draw-country-labels
          should-draw-city-turtle-labels ]

breed [ country-labels country-label ]
breed [ cities city ]
cities-own [ name country population ]
breed [ citizens citizen ]
citizens-own [ cntry_name ]

patches-own [ patch-population country-name elevation ]

to setup
  clear-all
  ; Note that setting the coordinate system here is optional, as
  ; long as all of your datasets use the same coordinate system.
  gis:load-coordinate-system (word "data/" projection ".prj")
  ; Load all of our datasets
  set cities-dataset gis:load-dataset "data/cities.shp"
  set rivers-dataset gis:load-dataset "data/rivers.shp"
  set countries-dataset gis:load-dataset "data/countries.shp"
  set elevation-dataset gis:load-dataset "data/world-elevation.asc"
  ; Set the world envelope to the union of all of our dataset's envelopes
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of cities-dataset)
                                                (gis:envelope-of rivers-dataset)
                                                (gis:envelope-of countries-dataset)
                                                (gis:envelope-of elevation-dataset))
  reset-ticks
end

; Draw points for each city on the drawing layer
to draw-cities
  gis:set-drawing-color red
  gis:draw cities-dataset 1
end

; Draw the polyline rivers dataset to the drawing layer
to draw-rivers
  gis:set-drawing-color blue
  gis:draw rivers-dataset 1
end

; Draw the multi-polygon countries dataset to the drawing layer
to draw-countries
  gis:set-drawing-color white
  gis:draw countries-dataset 1
  ; Alternatively, you could use `gis:fill countries-dataset 1` to
  ; draw the countries with a solid fill
end

; Use the gis:create-turtles-from-points primitive to create one turtle
; for each city with the breed city and automatically populate its
; cities-own variables with values corresponding to the property values
; of that city. Like the create-turtles primitive, you can optionally
; add a code block to give commands to the turtles upon creation.
to make-city-turtles
  ask cities [ die ]
  gis:create-turtles-from-points cities-dataset cities [
    set color scale-color red population 5000000 1000
    set shape "circle"
  ]
end

; Highlight all city turtles with a high population. make-city-turtles
; must have been run first.
;
; Once created with the gis:create-turtles-from-points primitive,
; working with turtles created from GIS data is just the same as
; working with any other turtles.
to highlight-large-city-turtles
  ask cities with [population > 10000000] [
    set color yellow
    set size 3
  ]
end

; Draw or clear labels for city turtles. make-city-turtles
; must have been run first for the labels to display.
to draw/clear-city-turtle-labels
  if-else should-draw-city-turtle-labels = 1 [
    set should-draw-city-turtle-labels 0
    ask cities [ set label "" ]
  ] [
    set should-draw-city-turtle-labels 1
    ask cities [ set label name ]
  ]
end

; using the gis:create-turtles-inside-polygon primitive, create
; a number of turtles within the borders of each country.
;
; Just like the gis:create-turtles-from-points primitive, the
; turtles created with this primitive have any turtles-own
; variables they might have with the same names as GIS
; property names populated with their corresponding GIS
; property value.
to create-citizens-in-countries
  foreach gis:feature-list-of countries-dataset [ this-country ->
    gis:create-turtles-inside-polygon this-country citizens num-citizens-to-create [
      set shape "person"
      ; since we included cntry_name as a citizens-own variable,
      ; if we wanted to we could give each citizen a label
      ; with their corresponding cntry_name like so:

      ;; set label cntry_name
    ]
  ]
end

; Create an invisible (size 0) turtle at the centroid of each
; country and set its label to the name of the given country.
; If the labels are already drawn, remove them.
to draw/clear-country-labels
  if-else should-draw-country-labels = 1 [
    set should-draw-country-labels 0
    ask country-labels [ die ]
  ] [
    set should-draw-country-labels 1
    foreach gis:feature-list-of countries-dataset [ this-country-vector-feature ->
      let centroid gis:location-of gis:centroid-of this-country-vector-feature
      ; centroid will be an empty list if it lies outside the bounds
      ; of the current NetLogo world, as defined by our current GIS
      ; coordinate transformation
      if not empty? centroid
      [ create-country-labels 1
        [ set xcor item 0 centroid
          set ycor item 1 centroid
          set size 0
          set label gis:property-value this-country-vector-feature "CNTRY_NAME"
        ]
      ]
    ]
  ]
end

; Use gis:intersecting to find the set of patches that intersects
; a given vector feature (in this case, one of the rivers).
to display-rivers-in-patches
  ask patches [ set pcolor black ]
  ask patches gis:intersecting rivers-dataset
  [ set pcolor cyan ]
end

; Using gis:apply-coverage to copy values from a polygon dataset
; to a patch variable
to display-population-in-patches
  gis:apply-coverage countries-dataset "POP_CNTRY" patch-population
  ask patches [
    ifelse (patch-population > 0) [
      set pcolor scale-color red patch-population 500000000 100000
    ] [
      set pcolor blue
    ]
  ]
end

; Use gis:find-one-of to find a particular VectorFeature, then using
; gis:intersects?, do something with all the features from another
; dataset that intersect that feature.
to draw-us-rivers-in-green
  let united-states gis:find-one-feature countries-dataset "CNTRY_NAME" "United States"
  gis:set-drawing-color green
  foreach gis:feature-list-of rivers-dataset [ vector-feature ->
    if gis:intersects? vector-feature united-states [
      gis:draw vector-feature 1
    ]
  ]
end

; Use gis:find-greater-than to find a list of VectorFeatures by one of their
; property values.
to draw-large-cities
  gis:set-drawing-color yellow
  foreach gis:find-greater-than cities-dataset "POPULATION" 10000000 [ vector-feature ->
    gis:draw vector-feature 3
  ]
end

; Draw a raster dataset to the NetLogo drawing layer, which sits
; on top of (and obscures) the patches. The second parameter
; is the opacity of the layer, with 0 representing fully opaque
; and 255 representing fully transparent.
to display-elevation
  gis:paint elevation-dataset 0
end

; Copy information from the elevation raster layer into the patch variable
; "elevation" and then color each patch based on that value.
to display-elevation-in-patches
  ; This is the preferred way of copying values from a raster dataset
  ; into a patch variable: in one step, using gis:apply-raster.
  gis:apply-raster elevation-dataset elevation
  ; Now, just to make sure it worked, we'll color each patch by its
  ; elevation value.
  let min-elevation gis:minimum-of elevation-dataset
  let max-elevation gis:maximum-of elevation-dataset
  ask patches [
    ; note the use of the "<= 0 or >= 0" technique to filter out
    ; "not a number" values, as discussed in the documentation.
    if (elevation <= 0) or (elevation >= 0) [
      set pcolor scale-color black elevation min-elevation max-elevation
    ]
  ]
end

; This is a second way of copying values from a raster dataset into
; patches, by asking for a rectangular sample of the raster at each
; patch. This is somewhat slower, but it does produce smoother
; subsampling, which is desirable for some types of data.
to sample-elevation-with-patches
  let min-elevation gis:minimum-of elevation-dataset
  let max-elevation gis:maximum-of elevation-dataset
  ask patches [
    set elevation gis:raster-sample elevation-dataset self
    if (elevation <= 0) or (elevation >= 0) [
      set pcolor scale-color black elevation min-elevation max-elevation
    ]
  ]
end

; This command also demonstrates the technique of creating a new, empty
; raster dataset and filling it with values from a calculation.
;
; This command uses the gis:convolve primitive to compute the horizontal
; and vertical Sobel gradients of the elevation dataset, then combines
; them using the square root of the sum of their squares to compute an
; overall "image gradient". This is really more of an image-processing
; technique than a GIS technique, but I've included it here to show how
; it can be easily done using the GIS extension.
to display-gradient-in-patches
  let horizontal-gradient gis:convolve elevation-dataset 3 3 [ 1 0 -1 2 0 -2 1 0 -1 ] 1 1
  let vertical-gradient gis:convolve elevation-dataset 3 3 [ 1 2 1 0 0 0 -1 -2 -1 ] 1 1
  let gradient gis:create-raster gis:width-of elevation-dataset gis:height-of elevation-dataset gis:envelope-of elevation-dataset
  let x 0
  repeat (gis:width-of gradient) [
    let y 0
    repeat (gis:height-of gradient) [
      let gx gis:raster-value horizontal-gradient x y
      let gy gis:raster-value vertical-gradient x y
      if ((gx <= 0) or (gx >= 0)) and ((gy <= 0) or (gy >= 0)) [
        gis:set-raster-value gradient x y sqrt ((gx * gx) + (gy * gy))
      ]
      set y y + 1
    ]
    set x x + 1
  ]
  let min-g gis:minimum-of gradient
  let max-g gis:maximum-of gradient
  gis:apply-raster gradient elevation
  ask patches [
    if (elevation <= 0) or (elevation >= 0) [
      set pcolor scale-color black elevation min-g max-g
    ]
  ]
end

; This is an example of how to select a subset of a raster dataset
; whose size and shape matches the dimensions of the NetLogo world.
; It doesn't actually draw anything; it just modifies the coordinate
; transformation to line up patch boundaries with raster cell
; boundaries. You need to call one of the other commands after calling
; this one to see its effect.
to match-cells-to-patches
  gis:set-world-envelope gis:raster-world-envelope elevation-dataset 0 0
  clear-drawing
  clear-turtles
end

; WMS stands for web mapping service, and it is a protocol that allows clients to ask
; a server for image of a section of a larger map image.
;
; The `import-wms-drawing` primitive asks a server (in this case one run by
; terrestris.de, a german GIS company that offers a WMS for the public)
; for the section of the map within the current world envelope
; and then draws it to the screen.
;
; In addition to the url of the WMS server, you must also supply the EPSG code
; for the projection you want to use and the name of the layer you want to grab
; from that server as well as a transparency parameter from 0 to 255.
; If you do not know what EPSG code to use, 4326, the code for WGS84, should
; provide good-enough results.
to download-background-image
  if-else projection = "WGS_84_Geographic" [
    gis:import-wms-drawing "https://ows.terrestris.de/osm/service?" "EPSG:4326" "OSM-WMS" 0
  ] [
    show "Only WGS_84_Geographic projections are supported. Please Change to WGS_84_Geographic in the top left drop-down."
  ]
end

; Use gis:project-lat-lon to convert latitude and longitude values
; into an xcor and a ycor and create a turtle there.
to create-turtle-at-lat-lon
  let location gis:project-lat-lon lat lon
  if not empty? location [
    let loc-xcor item 0 location
    let loc-ycor item 1 location
    create-turtles 1 [
      set xcor loc-xcor
      set ycor loc-ycor
      set shape "star"
      set size 3
    ]
  ]
end


; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
@#$#@#$#@
GRAPHICS-WINDOW
185
10
773
311
-1
-1
4.0
1
8
1
1
1
0
1
1
1
-72
72
-36
36
0
0
1
ticks
30.0

BUTTON
5
100
175
133
NIL
draw-cities
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
5
180
175
213
NIL
draw-countries
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
5
60
175
93
NIL
setup\n
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
5
140
175
173
NIL
draw-rivers
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
200
340
390
373
NIL
display-rivers-in-patches
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
200
380
390
413
NIL
display-population-in-patches
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
200
460
390
493
NIL
draw-us-rivers-in-green
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
200
500
390
533
NIL
draw-large-cities
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
5
10
175
55
projection
projection
"WGS_84_Geographic" "US_Orthographic" "Lambert_Conformal_Conic"
0

BUTTON
405
340
590
373
NIL
display-elevation
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
405
420
590
453
NIL
sample-elevation-with-patches
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
405
380
590
413
NIL
display-elevation-in-patches
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
405
500
590
533
NIL
match-cells-to-patches
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
405
460
590
493
NIL
display-gradient-in-patches
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
5
265
175
298
NIL
clear-drawing
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
605
340
790
373
NIL
download-background-image
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
5
340
185
373
NIL
make-city-turtles
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
5
380
185
413
NIL
highlight-large-city-turtles
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
5
460
185
493
NIL
create-citizens-in-countries
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
5
420
185
453
NIL
draw/clear-city-turtle-labels
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
5
220
175
255
NIL
draw/clear-country-labels
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
30
320
180
338
Vector Data -> Turtles
11
0.0
1

TEXTBOX
230
320
380
338
Vector Data -> Patches
11
0.0
1

TEXTBOX
465
320
615
338
Raster Data
11
0.0
1

TEXTBOX
680
320
830
338
Misc.
11
0.0
1

TEXTBOX
230
435
380
453
Filtering Vector Datasets
11
0.0
1

INPUTBOX
605
380
690
455
lat
42.055
1
0
Number

INPUTBOX
705
380
790
455
lon
-87.671
1
0
Number

BUTTON
605
460
790
493
NIL
create-turtle-at-lat-lon
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
5
500
185
533
num-citizens-to-create
num-citizens-to-create
0
100
50.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model was built to test and demonstrate the functionality of the GIS NetLogo extension.

## HOW IT WORKS

This model loads four different GIS datasets: a point file of world cities, a polyline file of world rivers, a polygon file of countries, and a raster file of surface elevation. It provides a collection of different ways to draw the data to the drawing layer, run queries on it, and transform it into NetLogo Turtles or Patch data.

## HOW TO USE IT

Select a map projection from the projection menu, then click the setup button. You can then use all other features of the mode. See the code tab for specific information about how the different buttons work.

## THINGS TO TRY

Most of the commands in the Code tab can be easily modified to display slightly different information. For example, you could modify `highlight-large-cities` to highlight small cities instead, by replacing `gis:find-greater-than` with `gis:find-less-than`.

## EXTENDING THE MODEL

This model doesn't do anything particularly interesting, but you can easily copy some of the code from the Code tab into a new model that uses your own data, or does something interesting with the included data. See the other GIS code example, GIS Gradient Example, for an example of this technique.

## RELATED MODELS

GIS Gradient Example provides another example of how to use the GIS extension.

<!-- 2008 -->
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
NetLogo 6.2.2
@#$#@#$#@
setup
draw-countries
make-city-turtles
set num-citizens-to-create 5
create-citizens-in-countries
display-population-in-patches
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
