breed [data-points data-point]
breed [centroids centroid]

globals [
  any-centroids-moved?
]

to setup
  clear-all
  set-default-shape data-points "circle"
  set-default-shape centroids "x"
  generate-clusters
  reset-centroids
end

to generate-clusters
  let cluster-std-dev 20 - num-clusters
  let cluster-size num-data-points / num-clusters
  repeat num-clusters [
    let center-x random-xcor / 1.5
    let center-y random-ycor / 1.5
    create-data-points cluster-size [
      setxy center-x center-y
      set heading random 360
      fd abs random-normal 0 (cluster-std-dev / 2) ;; Divide by two because abs doubles the width
    ]
  ]
end

to reset-centroids
  set any-centroids-moved? true
  ask data-points [ set color grey ]

  let colors base-colors
  ask centroids [die]
  create-centroids num-centroids [
    move-to one-of data-points
    set size 5
    set color last colors + 1
    set colors butlast colors
  ]
  clear-all-plots
  reset-ticks
end

to go
  if not any-centroids-moved? [stop]
  set any-centroids-moved? false
  assign-clusters
  update-clusters
  tick
end

to assign-clusters
  ask data-points [set color [color] of closest-centroid - 2]
end

to update-clusters
  let movement-threshold 0.1
  ask centroids [
    let my-points data-points with [ shade-of? color [ color ] of myself ]
    if any? my-points [
      let new-xcor mean [ xcor ] of my-points
      let new-ycor mean [ ycor ] of my-points
      if distancexy new-xcor new-ycor > movement-threshold [
        set any-centroids-moved? true
      ]
      setxy new-xcor new-ycor
    ]
  ]
  update-plots
end

to-report closest-centroid
  report min-one-of centroids [ distance myself ]
end

to-report square-deviation
  report sum [ (distance myself) ^ 2 ] of data-points with [ closest-centroid = myself ]
end


; Copyright 2014 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
285
10
798
524
-1
-1
5.0
1
10
1
1
1
0
0
0
1
-50
50
-50
50
1
1
1
ticks
30.0

SLIDER
5
80
280
113
num-centroids
num-centroids
1
14
7.0
1
1
NIL
HORIZONTAL

SLIDER
5
45
280
78
num-data-points
num-data-points
num-centroids + 1
1000
138.0
1
1
NIL
HORIZONTAL

BUTTON
5
115
280
148
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
5
150
140
183
Assign Points
assign-clusters
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
145
150
280
183
Update Centroids
update-clusters
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
185
280
218
Find Clusters (go)
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

BUTTON
5
220
280
253
Reset centroids
reset-centroids
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
5
255
280
495
Square Deviation of Clusters
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"ask centroids [\ncreate-temporary-plot-pen (word color)\nset-plot-pen-color color\n]" "ask centroids[\nset-current-plot-pen (word color)\nplot square-deviation * num-clusters\n]"
PENS

MONITOR
5
500
280
545
Total Square Deviation
mean [ square-deviation ] of centroids
0
1
11

SLIDER
5
11
280
44
num-clusters
num-clusters
1
14
7.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Often, when we have data about a large set of objects, we want to identify groups of similar objects within that set. For example, if we have many news articles, we may want to identify groups of articles that all have the same topic. In statistics, this task is called “cluster analysis”, or “clustering”.

This model shows the k-means clustering algorithm. a simple, but often effective approach to clustering. In this model, the k-means clustering algorithm is used to identify clusters of points on a plane. In the general case, you can represent your data objects as vectors of numbers, where each number represents a feature of the object.

The model is initialized by creating a specific number of clusters (NUM-CLUSTERS). In a real-world application, this number of clusters would be unknown. The algorithm is designed to find the clusters, and the user selects a guess, NUM-CENTROIDS, which tells the algorithm, how many clusters to search for. You can search for different numbers of clusters till you find one that best characterizes your data.

The result of the algorithm is a set of NUM-CENTROIDS points,  (each point is called a centroid), each of which is located at the average position of a corresponding cluster. The “k” in k-mean clustering refers to the guess at how many centroids to search for.

The purpose of the model is to allow you to see how the number of data points, clusters, and centroids interact, and how the algorithm can often find many different sets of clusters for the same dataset.

## HOW IT WORKS

The algorithm works by finding the average position of the elements in NUM-CENTROIDS different clusters. It starts by simply guessing an average position for each of the NUM-CENTROIDS clusters, and then improves these guesses as it goes on.

When the model is set up, two things happen: First, NUM-DATA-POINTS data points are generated and shown in the view.  Second, NUM-CENTROIDS centroids are generated and moved to a randomly selected data point. This randomly selected point is the initial guess for each centroid.

Each tick, the model performs two steps:
1. ASSIGN POINTS: all data points assign themselves to their closest centroid, taking on its color.
2. UPDATE CENTROIDS: all centroids move to the average position of the points assigned to it.

By iterating these steps a few times, the model is usually able to identify clusters in the dataset.

## HOW TO USE IT

First choose how many clusters you want to create and with how many data points, using respectively the NUM-CLUSTERS slider and the NUM-DATA-POINTS slider. Using the NUM-CENTROIDS slider, you can decide how many centroids you will create, which is how many clusters to search for. With real data, you won’t necessarily know how many naturally occurring clusters there are. By making NUM-CLUSTERS and NUM-CENTROIDS different, you can see what the algorithm does when it’s looking for too many or not enough clusters. Finally, click SETUP to generate your dataset and your centroids.

At this point you can choose to call each of the two steps manually using the ASSIGN POINTS, and UPDATE CENTROIDS buttons. This lets you see exactly how each of the steps work.

Alternatively you can press the FIND CLUSTERS (GO) button.

The model stops when the points assigned to the centroids don’t change. When this happens, we say that the centroids have “converged”.

RESET CENTROIDS sets the position of the centroids to random points in your data set, so that you can see if the clustering algorithm finds different sets of clusters depending on its initial guesses.

## THINGS TO NOTICE

You will often get very different results, depending on the initial guesses for the centroids’ location. Try and explore each data set several times, both by resetting the centroids, and by changing the number of centroids you place in the dataset.

## THINGS TO TRY

K-means clustering won't necessarily find the best solution. In fact, there are many solutions that it can converge to. Each of these solutions will be locally optimal. In other words, you can't find a better solution by moving the centroids by a small amount. However, better solutions may still exist.

For each dataset, you will probably be able to converge on many different solutions. You can try this by clicking the RESET CENTROIDS button after your model has already converged on one set, and running it again. This becomes particularly obvious if NUM-CLUSTERS and NUM-CENTROIDS are not equal.

## EXTENDING THE MODEL

The dataset currently is distributed in clusters across a 2-d space. It could be interesting to add the ability to either import datasets and find clusters in them, or somehow allow the user to create their own datasets.

Currently, only the data points that are identified as belonging to a cluster change their color as the algorithm runs. Another interesting way to illustrate clusters might be to change the color of patches that are closest to the centroids. This would create a Voronoi diagram of the clusters (see under 'Related models' if you are curious about Voronoi diagrams).

A clustering algorithm requires a measure to assess bow well it has clustered. This model uses the square deviation of the Euclidean distance. This measure has some good properties, but it assigns better scores to higher numbers of centroids. Can you think of other measures that improve the clustering?

## NETLOGO FEATURES

_CREATE-TEMPORARY-PLOT-PEN_: The model plots the number of data points for each of the centroids. However, because this number might change during runtime (i.e. if you let the model run, change the number of clusters, and then run the model again), the model uses temporary pens that are created and die with the centroids.

## RELATED MODELS

* Voronoi
* Emergent Voronoi
* MaterialSim Grain Growth
* Fur
* Honeycomb
* Scatter
* Hotelling's Law

## REFERENCES

For more information on k-means clustering, see https://en.wikipedia.org/wiki/K-means_clustering. (There are also many other sites on this topic on the web.)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Hjorth, A., Head, B. and Wilensky, U. (2014).  NetLogo K-Means Clustering model.  http://ccl.northwestern.edu/netlogo/models/K-MeansClustering.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2014 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2014 Cite: Hjorth, A., Head, B. -->
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
