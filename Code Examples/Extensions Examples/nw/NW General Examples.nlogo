extensions [ nw ]

; we have two different kinds of link breeds, one directed and one undirected, just
; to show what the different networks look like with directed vs. undirected links
directed-link-breed [ directed-edges directed-edge ]
undirected-link-breed [ undirected-edges undirected-edge ]

globals [
  highlighted-node                ; used for the "highlight mode" buttons to keep track of the currently highlighted node
  highlight-bicomponents-on       ; indicates that highlight-bicomponents mode is active
  stop-highlight-bicomponents     ; indicates that highlight-bicomponents mode needs to stop
  highlight-maximal-cliques-on    ; indicates highlight-maximal-cliques mode is active
  stop-highlight-maximal-cliques  ; indicates highlight-maximal-cliques mode needs to stop
]

to setup
  clear-all
  set-current-plot "Degree distribution"
  set-default-shape turtles "circle"
  reset-ticks
end

;; Reports the link set corresponding to the value of the links-to-use combo box
to-report get-links-to-use
  report ifelse-value links-to-use = "directed"
    [ directed-edges ]
    [ undirected-edges ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Layouts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to layout-turtles
  if layout = "radial" and count turtles > 1 [
    let root-agent max-one-of turtles [ count my-links ]
    layout-radial turtles links root-agent
  ]
  if layout = "spring" [
    let factor sqrt count turtles
    if factor = 0 [ set factor 1 ]
    layout-spring turtles links (1 / factor) (14 / factor) (1.5 / factor)
  ]
  if layout = "circle" [
    layout-circle sort turtles max-pxcor * 0.9
  ]
  if layout = "tutte" [
    layout-circle sort turtles max-pxcor * 0.9
    layout-tutte max-n-of (count turtles * 0.5) turtles [ count my-links ] links 12
  ]
  display
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Clusterers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Colorizes each node according to which component it is part of
to weak-component
  nw:set-context turtles get-links-to-use
  color-clusters nw:weak-component-clusters
end

; Colorizes each node according to the community it is part of
to community-detection
  nw:set-context turtles get-links-to-use
  color-clusters nw:louvain-communities
end

; Allows the user to mouse over and highlight all bicomponents
to highlight-bicomponents

  if stop-highlight-bicomponents = true [
    ; we're asked to stop - do so
    set stop-highlight-bicomponents false
    set highlight-bicomponents-on false
    stop
  ]
  set highlight-bicomponents-on true ; we're on!
  if highlight-maximal-cliques-on = true [
    ; if the other guy is on, he needs to stop
    set stop-highlight-maximal-cliques true
  ]

  if mouse-inside? [
    nw:set-context turtles get-links-to-use
    highlight-clusters nw:bicomponent-clusters
  ]
  display
end

; Allows the user to mouse over and highlight all maximal cliques
to highlight-maximal-cliques
  if (links-to-use != "undirected") [
    user-message "Maximal cliques only work with undirected links."
    stop
  ]
  if stop-highlight-maximal-cliques = true [
    ; we're asked to stop - do so
    set stop-highlight-maximal-cliques false
    set highlight-maximal-cliques-on false
    stop
  ]
  set highlight-maximal-cliques-on true ; we're on!
  if highlight-bicomponents-on = true [
    ; if the other guy is on, he needs to stop
    set stop-highlight-bicomponents true
  ]

  if mouse-inside? [
    nw:set-context turtles undirected-edges
    highlight-clusters nw:maximal-cliques
  ]
  display
end

; Colorizes the biggest maximal clique in the graph, or a random one if there is more than one
to find-biggest-cliques
  if links-to-use != "undirected" [
    user-message "Maximal cliques only work with undirected links."
    stop
  ]
  nw:set-context turtles undirected-edges
  color-clusters nw:biggest-maximal-cliques
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Highlighting and coloring of clusters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Allows the user to mouse over different nodes and
; highlight all the clusters that this node is a part of
to highlight-clusters [ clusters ]
  ; get the node with neighbors that is closest to the mouse
  let node min-one-of turtles [ distancexy mouse-xcor mouse-ycor ]
  if node != nobody and node != highlighted-node [
    set highlighted-node node
    ; find all clusters the node is in and assign them different colors
    color-clusters filter [ cluster -> member? node cluster ] clusters
    ; highlight target node
    ask node [ set color white ]
  ]
end

to color-clusters [ clusters ]
  ; reset all colors
  ask turtles [ set color gray ]
  ask links [ set color gray - 2 ]
  let n length clusters
  ; Generate a unique hue for each cluster
  let hues n-values n [ i -> (360 * i / n) ]

  ; loop through the clusters and colors zipped together
  (foreach clusters hues [ [cluster hue] ->
    ask cluster [ ; for each node in the cluster
                  ; give the node the color of its cluster
      set color hsb hue 100 100
      ; Color links contained in the cluster slightly darker than the cluster color
      ask my-links with [ member? other-end cluster ] [ set color hsb hue 100 75 ]
    ]
  ])
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Centrality Measures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to betweenness
  centrality [ -> nw:betweenness-centrality ]
end

to eigenvector
  centrality [ -> nw:eigenvector-centrality ]
end

to closeness
  centrality [ -> nw:closeness-centrality ]
end

; Takes a centrality measure as a reporter task, runs it for all nodes
; and set labels, sizes and colors of turtles to illustrate result
to centrality [ measure ]
  nw:set-context turtles get-links-to-use
  ask turtles [
    let res (runresult measure) ; run the task for the turtle
    ifelse is-number? res [
      set label precision res 2
      set size res ; this will be normalized later
    ]
    [ ; if the result is not a number, it is because eigenvector returned false (in the case of disconnected graphs
      set label res
      set size 1
    ]
  ]
  normalize-sizes-and-colors
end

; We want the size of the turtles to reflect their centrality, but different measures
; give different ranges of size, so we normalize the sizes according to the formula
; below. We then use the normalized sizes to pick an appropriate color.
to normalize-sizes-and-colors
  if count turtles > 0 [
    let sizes sort [ size ] of turtles ; initial sizes in increasing order
    let delta last sizes - first sizes ; difference between biggest and smallest
    ifelse delta = 0 [ ; if they are all the same size
      ask turtles [ set size 1 ]
    ]
    [ ; remap the size to a range between 0.5 and 2.5
      ask turtles [ set size ((size - first sizes) / delta) * 2 + 0.5 ]
    ]
    ask turtles [ set color scale-color red size 0 5 ] ; using a higher range max not to get too white...
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generators
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to generate [ generator-task ]
  if clear-before-generating? [ setup ]
  ; we have a general "generate" procedure that basically just takes a task
  ; parameter and runs it, but takes care of calling layout and update plots
  run generator-task
  layout-turtles
  update-plots
end

to preferential-attachment
  generate [ -> nw:generate-preferential-attachment turtles get-links-to-use nb-nodes 1 ]
end

to ring
  generate [ -> nw:generate-ring turtles get-links-to-use nb-nodes ]
end

to star
  generate [ -> nw:generate-star turtles get-links-to-use nb-nodes ]
end

to wheel
  ifelse links-to-use = "directed" [
    ifelse spokes-direction = "inward" [
      generate [ -> nw:generate-wheel-inward turtles get-links-to-use nb-nodes ]
    ]
    [ ; if it's not inward, it's outward
      generate [ -> nw:generate-wheel-outward turtles get-links-to-use nb-nodes ]
    ]
  ]
  [ ; for an undirected network, we don't care about spokes
    generate [ -> nw:generate-wheel turtles get-links-to-use nb-nodes ]
  ]
end

to lattice-2d
  generate [ -> nw:generate-lattice-2d turtles get-links-to-use nb-rows nb-cols wrap ]
end

to small-world-ring
  generate [ -> nw:generate-watts-strogatz turtles get-links-to-use nb-nodes neighborhood-size rewire-prob ]
end

to small-world-lattice
  generate [ -> nw:generate-small-world turtles get-links-to-use nb-rows nb-cols clustering-exponent wrap ]
end

to generate-random
  generate  [ -> nw:generate-random turtles get-links-to-use nb-nodes connection-prob ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Saving and loading of network files
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to save-matrix
  nw:set-context turtles get-links-to-use
  nw:save-matrix "matrix.txt"
end

to load-matrix
  generate [ -> nw:load-matrix "matrix.txt" turtles get-links-to-use ]
end

to save-graphml
  nw:set-context turtles get-links-to-use
  nw:save-graphml "demo.graphml"
end

to load-graphml
  nw:set-context turtles get-links-to-use
  nw:load-graphml "demo.graphml"
end


; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
@#$#@#$#@
GRAPHICS-WINDOW
630
10
1133
514
-1
-1
15.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
0
ticks
30.0

BUTTON
510
30
620
63
NIL
betweenness
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
305
10
455
28
Clusterers & Cliques
12
0.0
1

SLIDER
10
150
290
183
nb-nodes
nb-nodes
0
1000
100.0
1
1
NIL
HORIZONTAL

TEXTBOX
510
10
660
28
Centrality
12
0.0
1

BUTTON
10
10
95
55
setup/clear
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
10
185
170
218
preferential attachment
preferential-attachment
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
10
445
115
478
lattice 2D
lattice-2d
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
120
410
290
443
nb-rows
nb-rows
0
20
8.0
1
1
NIL
HORIZONTAL

SLIDER
120
445
290
478
nb-cols
nb-cols
0
20
8.0
1
1
NIL
HORIZONTAL

SWITCH
10
410
115
443
wrap
wrap
1
1
-1000

TEXTBOX
15
125
165
143
Generators
12
0.0
1

BUTTON
510
65
620
98
NIL
eigenvector
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
10
275
95
308
random
generate-random
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
100
275
290
308
connection-prob
connection-prob
0
1
0.2
0.01
1
NIL
HORIZONTAL

BUTTON
10
480
115
513
kleinberg
small-world-lattice
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
120
480
290
513
clustering-exponent
clustering-exponent
0
10
2.0
0.1
1
NIL
HORIZONTAL

BUTTON
510
100
620
133
NIL
closeness
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
305
30
495
63
weak component clusters
weak-component
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
100
10
290
55
links-to-use
links-to-use
"undirected" "directed"
0

PLOT
305
305
620
465
Degree distribution
Degrees
Nb nodes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [ count my-links ] of turtles"

BUTTON
305
225
390
258
save matrix
save-matrix
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
305
260
390
293
load matrix
load-matrix
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
390
470
475
515
NIL
count turtles
17
1
11

MONITOR
305
470
385
515
NIL
count links
17
1
11

BUTTON
305
170
495
203
biggest maximal cliques
find-biggest-cliques
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
175
185
230
218
NIL
ring
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
10
225
95
270
NIL
wheel
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
235
185
290
218
NIL
star
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
480
470
620
515
Mean path length
nw:mean-path-length
3
1
11

CHOOSER
190
60
290
105
layout
layout
"spring" "circle" "radial" "tutte"
0

BUTTON
100
60
185
105
layout once
layout-turtles
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
10
60
95
105
layout
layout-turtles
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
305
100
495
133
highlight bicomponents
highlight-bicomponents
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
305
135
495
168
highlight maximal cliques
highlight-maximal-cliques
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
100
225
290
270
spokes-direction
spokes-direction
"inward" "outward"
1

TEXTBOX
310
205
460
223
Files
12
0.0
1

BUTTON
395
225
495
258
save GraphML
save-graphml
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
395
260
495
293
load GraphML
load-graphml
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
305
65
495
98
detect communities
community-detection
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
10
360
95
393
small world
small-world-ring
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
10
325
290
358
neighborhood-size
neighborhood-size
0
floor ((nb-nodes - 1) / 2)
3.0
1
1
NIL
HORIZONTAL

SLIDER
100
360
290
393
rewire-prob
rewire-prob
0
1
0.1
0.01
1
NIL
HORIZONTAL

SWITCH
95
115
290
148
clear-before-generating?
clear-before-generating?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model demonstrates various features of the Netlogo NW extension: it allows you to generate various kinds of networks, lay them out on screen, and get information about them.

## HOW TO USE IT

The SETUP/CLEAR button initializes the model and clears any existing networks.

The LINKS-TO-USE chooser allow you to specify whether you want to use directed or undirected links: all the generators use the kind of links selected in the chooser. You can generate different networks with different kinds of links without clearing everything in between.

The value of LINKS-TO-USE is used by the different clusterers and measures as well. Be careful to use the right value for the network you are interested in. For example, if you ask for betweenness centrality with "directed links" selected in the chooser, but the network on the screen is undirected, the betweenness centrality values will all be zero, because the algorithm only takes directed links into account.

There is another chooser called LAYOUT. NetLogo currently offers four different kinds of layouts (this is not new in the NW extension - they were all available before):

- [circle](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#layout-circle)

- [radial](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#layout-radial)

- [spring](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#layout-spring)

- [tutte](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#layout-tutte)

Clicking the LAYOUT forever button will ensure that the chosen layout is applied continuously. This is especially useful in the case of the spring layout. For other layouts, you can also use the LAYOUT ONCE button.

### Generators

The first thing that you will see in the **Generators** section of the model is a slider labeled NB-NODES. It allows you to specify the number of nodes you want to have in your network. The first six generator buttons (PREFERENTIAL ATTACHMENT, RING, STAR, WHEEL, RANDOM, and SMALL WORLD) will take the value of that slider into account.

By default, using one of the generators will clear the current network first. You can disable this using the CLEAR-BEFORE-GENERATING? switch. Note that at any time, you can press the SETUP/CLEAR button to erase everything and start over.

Here is a description of each of generator.

PREFERENTIAL ATTACHMENT

Generates a new network using the [Barabási–Albert](https://en.wikipedia.org/wiki/Barab%C3%A1si%E2%80%93Albert_model) algorithm. This network will have the property of being "scale free": the distribution of degrees (i.e. the number of links for each turtle) should follow a power law.

Turtles are added, one by one, each forming one link to a previously added turtle, until _nb-nodes_ is reached. The more links a turtle already has, the greater the probability that new turtles form links with it when they are added.

RING

Generates a [ring network](https://en.wikipedia.org/wiki/Ring_network) of NB-NODES turtles, in which each turtle is connected to exactly two other turtles.

STAR

Generates a [star network](https://en.wikipedia.org/wiki/Star_graph) in which there is one central turtle and every other turtle is connected only to this central node. The number of turtles can be as low as one, but it won't look much like a star.

WHEEL

Generates a [wheel network](https://en.wikipedia.org/wiki/Wheel_graph), which is basically a [ring network](https://en.wikipedia.org/wiki/Ring_network) with an additional "central" turtle that is connected to every other turtle. The number of nodes must be at least four.

On the right side of the WHEEL button, you will see a chooser allowing you the select either "inward" or "outward". This will allow to specify if the "spokes" of the wheel point toward the central turtle (inward) or away from it (outward). This is, of course, meaningful only in the case of a directed network.

RANDOM

Generates a new random network of NB-NODES turtles in which each one has a  connection probability (between 0 and 1) of being connected to each other turtles (this is specified through the CONNECTION-PROB slider). The algorithm uses the [Erdős–Rényi model](https://en.wikipedia.org/wiki/Erd%C5%91s%E2%80%93R%C3%A9nyi_model).

SMALL WORLD

Generates a new [Watts-Strogatz small-world network](https://en.wikipedia.org/wiki/Watts_and_Strogatz_model). The algorithm begins by creating a ring of nodes, where each node is connected to NEIGHBORHOOD-SIZE nodes on either side. Then, each link is rewired with probability REWIRE-PROB.

LATTICE 2D

Generates a new 2D [lattice network](https://en.wikipedia.org/wiki/Lattice_graph) (basically, a grid) of NB-ROWS rows and NB-COLS columns. The grid will wrap around itself if the WRAP switch is set to "on".

KLEINBERG

Generates a new [small-world network](https://en.wikipedia.org/wiki/Small-world_network) using the [Kleinberg Model](https://en.wikipedia.org/wiki/Small_world_routing#The_Kleinberg_Model).

The generator uses the same sliders and switch as the lattice 2D generator, namely, NB-ROWS, NO-COLS and WRAP. The algorithm proceeds by generating a lattice of the given number of rows and columns (the lattice will wrap around itself if WRAP is "on"). The "small world effect" is created by adding additional links between the nodes in the lattice. The higher the CLUSTERING-EXPONENT, the more the algorithm will favor already close-by nodes when adding new links. A clustering exponent of `2.0` is typically used.

### Clusters and cliques

Now that you have generated one or more networks, there are things that you might want to know about them.

WEAK COMPONENT CLUSTERS

This button will assign a different color to all the "weakly" [connected components](https://en.wikipedia.org/wiki/Connected_component_%28graph_theory%29) in the current network. A weakly connected component is simply a group of nodes where there is a path from each node to every other node. A "strongly" connected component would be one where there is a _directed_ path from each node to every other. The extension does not support the identification of strongly connected components at the moment.

DETECT COMMUNITIES

Detects community structure present in the network. It does this by maximizing modularity using the [Louvain method](https://en.wikipedia.org/wiki/Louvain_Modularity).

HIGHLIGHT BICOMPONENTS

Clicking on this button will put you in a mode where you use your mouse to highlight the different [bicomponent clusters](https://en.wikipedia.org/wiki/Biconnected_component) in the current network. A bicomponent (also known as a maximal biconnected subgraph) is a part of a network that cannot be disconnected by removing only one node (i.e. you need to remove at least two to disconnect it).

Note that one turtle can be a member of more than one bicomponent at once. If it is the case, all the bicomponents that the target turtle is part of will be highlighted when you move your mouse pointer near it, but they will be of different color.

HIGHLIGHT MAXIMAL CLIQUES

The general usage for this is the same as for the **highlight bicomponents** mode. Note you should not try to use both highlight modes at the same time.

A [clique](https://en.wikipedia.org/wiki/Clique_%28graph_theory%29) is a subset of a network in which every node has a direct link to every other node. A maximal clique is a clique that is not, itself, contained in a bigger clique.

BIGGEST MAXIMAL CLIQUES

This simply highlights the biggest of all the maximal cliques in the networks. If there are multiple cliques that are equally big (as is often the case), it will highlight them with different colors.

### Centrality measures

Besides all the clusterers and the clique finder, you can also calculate some centrality measures on your networks. All the centrality measures will label the nodes will the result of the calculation and adjust their size and color to reflect that result.

BETWEENNESS

To calculate the [betweenness centrality](https://en.wikipedia.org/wiki/Betweenness_centrality) of a turtle, you take every other possible pairs of turtles and, for each pair, you calculate the proportion of shortest paths between members of the pair that passes through the current turtle. The betweenness centrality of a turtle is the sum of these.

EIGENVECTOR

The [Eigenvector centrality](https://en.wikipedia.org/wiki/Centrality#Eigenvector_centrality) of a node can be thought of as the proportion of its time that an agent forever "walking" at random on the network would spend on this node. In practice, turtles that are connected to a lot of other turtles that are themselves well-connected (and so) get a higher Eigenvector centrality score.

Eigenvector centrality is only defined for connected networks, and will report `false` for disconnected graphs.

CLOSENESS

The [closeness centrality](https://en.wikipedia.org/wiki/Centrality#Closeness_centrality) of a turtle is defined as the inverse of the sum of it's distances to all other turtles.

Note that this primitive reports the _intra-component_ closeness of a turtle, that is, it takes into account only the distances to the turtles that are part of the same [component](https://en.wikipedia.org/wiki/Connected_component_%28graph_theory%29) as the current turtle, since distance to turtles in other components is undefined. The closeness centrality of an isolated turtle is defined to be zero.

### Files

LOAD / SAVE MATRIX

Finally, you can save and load your networks. This can be done through the use of simple text files containing an [adjacency matrix](https://en.wikipedia.org/wiki/Adjacency_matrix).

The model currently always save the network to your NetLogo directory in a file called `matrix.txt` when you click the SAVE MATRIX button. When you click the LOAD MATRIX button, it reads from the same location and creates a new network from the file.

LOAD / SAVE GRAPHML

You can also save and load GraphML files. Please see the [extension's documentation](http://ccl.northwestern.edu/netlogo/docs/nw.html#save-graphml) for more detail on handling GraphML files. The demo simply saves the current network to (and can load from) the file `demo.graphml` in your default directory.

## THINGS TO NOTICE

- When you generate preferential attachment networks, notice the distribution of node degrees in the histogram. What does it look like? What happens if you generate a network with more nodes, or multiple preferential attachment networks?

- When you generate a small world network, what is the MEAN PATH LENGTH value that you can see on the monitor? How does it compare the a random network with the same number of nodes?

## THINGS TO TRY

- In general, different layouts work best for different kind of graphs. Can you try every combination of graph/layout? Which layout do you prefer for each kind of graph? Why?

- Try the spring layout with a lattice 2D network, with WRAP set to off. How does it look? Now try it with WRAP set to on. Can you explain the difference?

- Generate a small world network with a low clustering exponent (e.g., 0.1). What is the size of the biggest maximal clique? Now try it with a big exponent (e.g. 10.0). What is the size? Try it multiple times. Do you see a pattern? What if you crank up the number of rows and columns?

## EXTENDING THE MODEL

The current version of the demo does not take link weights into account. You can add a "weight" variable to each link breed. Can you add a button assigning random weights to the links? Can you make it so that link thickness reflects the "weight" of the link? Look at the extensions documentation for primitive that take weights into account. Can you integrate those in the demo?

## NETLOGO FEATURES

This model demonstrates the `nw` extension primitives.

But aside from that, notice the interesting use it makes of tasks for the centrality buttons. We have only one `centrality` procedure in the code that does all the hard work, and the other procedures call it with a `measure` reporter task as a parameter, that the `centrality` primitive then runs with `runresult`. This removes a lot of code duplication.

Another nice tidbit is how the `foreach` command is used in the `color-clusters` primitive. Notice how it loops over both the `clusters` list and the `colors` and then uses the `cluster` and `cluster-color` arguments to access members of each pair of cluster/color.

## RELATED MODELS

A couple of models already in the model library, namely the "Giant Component" model and the "Small World" model could be build much more easily by using the primitives in the network extension. Such versions of these two models are included in the "demo" folder of the extension, but trying to make the modifications yourself would be an excellent exercise.

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

wolf
false
0
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
setup
nw:generate-watts-strogatz
  turtles undirected-edges 200 4 0.1
community-detection
set layout "circle"
layout-turtles
set layout "spring"
repeat 300 [ layout-turtles ]
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
