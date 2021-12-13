extensions [ sound ]

globals [
 chromosomes ; list of all possible chromosomes
 random-who-list ; keeps a shuffled list for pretty-ness
 generations ; number of generations we've seen
]

turtles-own [
  my-chromosomes ; list to hold the chromosomes of a drummer
  my-velocity ; the (int) velocity value of a drummer
  my-instrument ; the (string) instrument for that turtle
  mutation-rate ; variable to control "reproduction"
  hits ; counts the number of drum hits for a turtle across its lifespan
  hits-since-evolve ; the number of hits since a mutation or evolution
]

breed [ low-drums low-drummer ]
breed [ med-drums med-drummer ]
breed [ high-drums high-drummer ]

to setup
  clear-all
  ; Make the view big enough to show 16 rows (each a drummer) and however many 'beats'
  resize-world 0 ((num-chromosomes * 4) - 1) 0 15
  set-globals
  set-initial-turtle-variables
  reset-ticks
  update-view
end

; Procedure to play a pattern with evolution
to go
  ask turtles [ play ]
  ; If we've reached the end of a pattern, do some evolution!
  if (ticks mod (num-chromosomes * 4) = 0) and (ticks != 0) [
    set generations generations + 1
    go-evolve
  ]
  update-view
  tick
  wait 60 / tempo-bpm / 4   ; This roughly sets tempo
end

; Procedure to play a pattern without any evolution
to go-no-evolve
  ask turtles [ play ]
  update-view
  tick
  wait 60 / tempo-bpm / 4
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PLAY FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to play-my-drum ; turtle procedure
  let temp my-velocity
  if sound? [
    if solo? [ ; If you're a soloer, play out! Otherwise, be quiet!
      ifelse who = soloer [
        set temp my-velocity + 50
      ][
        set temp my-velocity - 50
      ]
   ]
    sound:play-drum my-instrument temp
  ]
end

to play ; turtle procedure
  if item (ticks mod (num-chromosomes * 4)) my-pattern = 1 [
    play-my-drum
    set hits hits + 1
    set hits-since-evolve hits-since-evolve + 1
  ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; END PLAY FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EVOLUTION FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go-evolve
  ; If there isn't a soloist, ask 2 of each type to evolve
  ifelse not solo? [
    ask n-of 2 low-drums [
      evolve
    ]
    ask n-of 2 med-drums [
      evolve
    ]
    ask n-of 2 high-drums [
      evolve
    ]
    ; If a drummer hasn't changed in a while, mutate
    ask turtles with [hits-since-evolve > hit-limit] [
      mutate
      set hits-since-evolve 0
    ]
  ][ ; If there is a soloist, do the same, but don't include the soloer
    ask n-of 2 low-drums with [ who != soloer ] [
      evolve
    ]
    ask n-of 2 med-drums with [ who != soloer ] [
      evolve
    ]
    ask n-of 2 high-drums with [ who != soloer ]  [
      evolve
    ]

    ; If a drummer hasn't changed in a while, mutate
    ask turtles with [ hits-since-evolve > hit-limit and who != soloer ] [
      mutate
      set hits-since-evolve 0
    ]
  ]
end

to evolve ; turtle procedure
  let mate nobody
  let list-of-fitnesses []
  let search-fitness 0

  if is-low-drummer? self [
    set list-of-fitnesses [ fitness ] of other breed
    set search-fitness select-random-weighted-fitness list-of-fitnesses
    set mate one-of other breed with [ fitness = search-fitness ]
  ]

  if is-med-drummer? self [
    set list-of-fitnesses [ fitness ] of turtles with [ breed != [ breed ] of myself ]
    set search-fitness select-random-weighted-fitness list-of-fitnesses
    set mate one-of turtles with [ (breed != [breed] of myself) and (fitness = search-fitness)]
  ]

  if is-high-drummer? self [
    set list-of-fitnesses [fitness] of other breed
    set search-fitness select-random-weighted-fitness list-of-fitnesses
    set mate one-of other breed with [fitness = search-fitness]
  ]

  let offspring-chromosomes reproduce-with mate

  ask min-one-of other breed with [who != soloer] [fitness] [
    set my-chromosomes offspring-chromosomes
    set hits-since-evolve 0
  ]
end

; This is where the basic genetic algorithm comes in
to-report reproduce-with [ mate ] ; turtle procedure
  ; The asker is 1st Parent while mate is 2nd parent
  let her-chromosomes [ my-chromosomes ] of mate

  ; Pick a random cross-over point
  let crossover-point random length my-chromosomes

  ; Combine the chromosomes
  let baby-chromosomes sentence (sublist my-chromosomes 0 crossover-point) (sublist her-chromosomes crossover-point length her-chromosomes)

  ; Do a little mutation
  let mutation-chance 0
  if is-low-drummer? self [
    set mutation-chance 50
  ]
  if is-med-drummer? self [
    set mutation-chance 25
  ]
  if is-high-drummer? self [
    set mutation-chance 10
  ]

  ; Maybe actually mutate
  if random 100 > mutation-chance [
    set baby-chromosomes mutate-chromosomes baby-chromosomes
  ]
  report baby-chromosomes
end


; FITNESS FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;
; Dependent on breed, because you can lose fitness or gain fitness by fitting to your particular proclivities
to-report fitness ; turtle procedure
  ; Arbitrary 10% window around target density
  let my-fitness 0

  ; Want to be under the hit-density and be on the downbeats
  if is-low-drummer? self [
    set my-fitness downbeat-fitness
    if my-density-fitness > (hit-density-modifier - 0.1) [
      set my-fitness my-fitness / 1.5
    ]
  ]

  ; Want to be at the hit-density and be on the off-beats
  if is-med-drummer? self [
    set my-fitness offbeat-fitness
    if (my-density-fitness < hit-density-modifier - 0.1) or (my-density-fitness > hit-density-modifier + 0.1) [
      set my-fitness my-fitness / 2
    ]
  ]

  ; Want to be above the hit-density and have lots o' clusters
  if is-high-drummer? self [
    set my-fitness offbeat-fitness
    if my-density-fitness < hit-density-modifier + 0.1 [
      set my-fitness my-fitness / 2
    ]
  ]
  ; use add 1 smoothing
  report my-fitness + 1
end

to-report my-density-fitness ; turtle procedure
  report sum my-pattern / length my-pattern
end

to-report cluster-fitness ; turtle procedure
  ; window size at 3
  let i 4
  let cluster-count 0
  while [i <= length my-pattern] [
    if (sum sublist my-pattern (i - 4) i) = 3 [
      set cluster-count cluster-count + 1
    ]
  ]
  ; Lots of clusters relative to the notes I play
  report cluster-count / sum my-pattern * 100
end

to-report offbeat-fitness ; turtle procedure
  let offbeat-count 0
  foreach range length my-pattern [ i ->
    if i mod 2 != 0 [
      if item i my-pattern = 1 [
        set offbeat-count offbeat-count + 1
      ]
    ]
  ]
  if offbeat-count = 0 [ report 0 ]
  ; You want more off-beats and less down-beats
  report offbeat-count / sum my-pattern * 100
end

to-report downbeat-fitness ; turtle procedure
  let downbeat-count 0
  foreach range length my-pattern [ i ->
    if i mod 2 = 0 [
      if item i my-pattern = 1 [
        set downbeat-count downbeat-count + 1
      ]
    ]
  ]

  if downbeat-count = 0 [ report 0 ]
  ; In other words, you want lots of downbeats in comparison to your other notes
  report downbeat-count / sum my-pattern * 100
end

to mutate ; turtle procedure
  set my-chromosomes mutate-chromosomes my-chromosomes
end

; Procedure to mutate a chromosome
to-report mutate-chromosomes [the-chromosomes]
  ; basically picks a chromosome, mutates it, returns a new set
  let new-chromosomes the-chromosomes
  repeat num-mutations [
    let temp random num-chromosomes
    set new-chromosomes replace-item temp new-chromosomes ((round (random-normal (item temp new-chromosomes) mutation-strength)) mod 16)
  ]
  report new-chromosomes
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; END EVOLUTION FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HELPER FUNCTIONS ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Converts a set of chromosomes into a binary rhythm pattern
to-report my-pattern ; turtle Procedure
  let pattern []
  foreach my-chromosomes [ n ->
   set pattern sentence pattern (get-chromosome n)
  ]
  report pattern
end

to set-globals
  set generations 0
  set random-who-list range 16
  ; this is just for looks. we keep a map of who to random-who
  if shuffle-parts? [
    set random-who-list shuffle random-who-list
    set random-who-list shuffle random-who-list
  ]
  set chromosomes []
  ; CHROMOSOME LIBRARY
  let c0 [0 0 0 0]
  let c1 [1 0 0 0]  let c2  [0 1 0 0] let c3 [0 0 1 0] let c4 [0 0 0 1]
  let c5 [1 1 0 0]  let c6  [1 0 1 0] let c7 [1 0 0 1] let c8 [0 1 1 0]
  let c9 [0 1 0 1]  let c10 [0 0 1 1]
  let c11 [1 1 1 0] let c12 [1 0 1 1] let c13 [1 1 0 1] let c14 [0 1 1 1]
  let c15 [1 1 1 1]
  set chromosomes (list c0 c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14 c15)
end

to set-initial-turtle-variables
  create-low-drums 6 [
    set my-instrument "Acoustic Bass Drum"
    set my-velocity 50
    set color red
    set mutation-rate 64
  ]

  create-med-drums 5 [
    set my-instrument "Acoustic Snare"
    set color green
    set my-velocity 50
    set mutation-rate 32
  ]

  create-high-drums 5 [
    set my-instrument "Closed Hi Hat"
    set color blue
    set my-velocity 100
    set mutation-rate 16
  ]

  ask turtles [
    set my-chromosomes (n-values num-chromosomes [ 1 ])
    hide-turtle
    set hits 0
  ]
end

; Procedure to update the view (simplified music notation)
to update-view
  ask turtles [
    let column 0
    let row item who random-who-list
    foreach my-pattern [ n ->
      ifelse n = 1 [
        ifelse solo? and (soloer = who) [
          ask patch column row [ set pcolor white ]
        ][
          ask patch column row [ set pcolor [ color ] of myself ]
        ]
      ][
        ask patch column row [ set pcolor black ]
      ]
      set column column + 1
    ]
  ]
  ; color the patches that are currently being played
  ask patches with [ pxcor = (ticks mod (num-chromosomes * 4)) ] [ set pcolor yellow ]
end

; Procedure to get a chromosomes pattern from the library
to-report get-chromosome [ index ]
  report item index chromosomes
end

; This is my version of picking a weighted random turtle
to-report select-random-weighted-fitness [ the-list ]
  let weighted-list []
  foreach the-list [ x ->
    ; add one smoothing
    foreach range round ((x / sum the-list * 100) + 1) [
      set weighted-list fput x weighted-list
    ]
  ]
  report item (random length weighted-list) weighted-list
end


; Copyright 2017 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
290
10
634
355
-1
-1
21.0
1
10
1
1
1
0
0
0
1
0
15
0
15
1
1
1
ticks
30.0

BUTTON
5
50
71
83
setup
setup\nsound:play-note \"TRUMPET\" 60 62 2\nwait 2
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
215
90
285
123
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

SLIDER
5
10
150
43
num-chromosomes
num-chromosomes
2
12
4.0
1
1
NIL
HORIZONTAL

SWITCH
155
10
285
43
shuffle-parts?
shuffle-parts?
0
1
-1000

PLOT
545
370
780
520
Hits per Drummer (total)
Drummer
Number of Hits
0.0
16.0
0.0
10.0
true
false
"" ""
PENS
"low" 1.0 1 -2674135 true "" "plot-pen-reset\nask low-drums [ plotxy who hits ]"
"med" 1.0 1 -10899396 true "" "plot-pen-reset\nask med-drums [plotxy who hits]"
"high" 1.0 1 -13345367 true "" "plot-pen-reset\nask high-drums [plotxy who hits]"

PLOT
5
370
285
520
Average Fitness
Ticks
Fitness
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"all" 1.0 0 -16777216 true "" "plot mean [fitness] of turtles"
"low" 1.0 0 -2674135 true "" "plot mean [fitness] of low-drums"
"med" 1.0 0 -10899396 true "" "plot mean [fitness] of med-drums"
"high" 1.0 0 -13345367 true "" "plot mean [fitness] of high-drums"

SLIDER
110
170
285
203
hit-density-modifier
hit-density-modifier
0
1
0.5
0.01
1
NIL
HORIZONTAL

SWITCH
5
90
108
123
sound?
sound?
0
1
-1000

SLIDER
5
210
130
243
num-mutations
num-mutations
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
135
210
285
243
mutation-strength
mutation-strength
0
8
1.0
1
1
NIL
HORIZONTAL

CHOOSER
40
310
132
355
soloer
soloer
0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
0

MONITOR
40
255
130
300
NIL
generations
17
1
11

BUTTON
110
90
210
123
NIL
go-no-evolve
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
75
50
210
83
go-once-no-evolve
repeat num-chromosomes * 4 [go-no-evolve]
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
215
50
285
83
go-once
repeat num-chromosomes * 4 [ go ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
135
315
238
348
solo?
solo?
1
1
-1000

SLIDER
5
130
285
163
tempo-bpm
tempo-bpm
40
200
135.0
1
1
NIL
HORIZONTAL

MONITOR
135
255
222
300
Density
precision (count patches with [(pcolor != black) and (pcolor != yellow)] / (count patches)) 3
17
1
11

PLOT
290
370
540
520
Hits Since Evolution
Drummer
Number of Hits
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"low" 1.0 1 -2674135 true "" "plot-pen-reset\nask low-drums [ plotxy who hits-since-evolve ]"
"pen-1" 1.0 1 -10899396 true "" "plot-pen-reset ask med-drums [ plotxy who hits-since-evolve ]"
"pen-2" 1.0 1 -13345367 true "" "plot-pen-reset ask high-drums [ plotxy who hits-since-evolve ]"

SLIDER
5
170
105
203
hit-limit
hit-limit
50
200
120.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model generates drum rhythms using a genetic algorithm. Using the rhythmic "rules" from West African drum circles, low, medium, and high-drum patterns work in concert with evolution to create jamming beats. This is the 'duple' version of the model, where there are 4 'beats' per chromosome.

In many West African countries, music serves as an integral part of culture. In Senegal in particular, drums and percussion instruments serve as both focal points of performance as well as features in ceremonial contexts. West African drum ensemble performances are grand affairs featuring costumes of loud colors, drums of all different shapes and sizes, and colorful and rhythmically intricate music. These performances are stages for rich, cross and poly-rhythmic development because many of the "songs" are simply improvisatory frameworks. In Senegal, three distinct drums make up the typical ensemble: a low drum called the dundun, a middle timbre drum called the sabar, and high timbre drum called a djembe.

During a performance, the drummers listen to and blend with their fellow performers in order to create the rich sound the audience hears. The rhythm is constantly evolving based on solos, clusters, and the attenuation of the "strong-weak beat feel." This model shows one way of attempting to generate pleasing drum rhythms automatically in the style of West African Drumming. While most attempts to automatically generate music depend on having a human select rhythms they like, this model tries to generate rhythms without explicitly asking a human whether or not they like a particular rhythm.

A [genetic algorithm](https://en.wikipedia.org/wiki/Genetic_algorithm#) is a tool used in computer science to produce solutions to optimization and search problems. It relies on biologically inspired techniques in order to "search" a parameter space for an "optimal solution." The key lies in representing the given problem using "genetic material" like chromosomes. Then, the algorithm uses the techniques of [selection](https://en.wikipedia.org/wiki/Genetic_algorithm#Selection), [crossover](https://en.wikipedia.org/wiki/Genetic_algorithm#Genetic_operators), and [mutation](https://en.wikipedia.org/wiki/Genetic_algorithm#Genetic_operators) to "evolve" the solution.

## HOW IT WORKS

### What makes these rhythms evolve?

The basic idea uses the concept of genetic algorithms in computer science. A genetic algorithm is meant to take "organisms" with "chromosomes" and simulate their evolution toward some sort of objective (so over time, organisms have higher "fitness"). In this example, drummers are our organisms and each has a set chromosomes composed of hits and rests that represent the rhythm they play.

There are 16 drums: 5 high drummers, 5 medium drummers, and 6 low drummers. Here we are using "low", "medium", and "high" to describe the pitch and timbre of a drum. Each drummer (an invisible turtle) has a set of "rhythm chromosomes" which dictate what drum pattern it plays.

In this model, each rhythmic chromosome is represented by a list of 4 binary digits. A '0' indicates a rest while a '1' indicates a hit. In this model, you can think of each of these digits as 'sixteenth-notes' such that each chromosome represents a 'beat'. This means there are 2^4 = 16 different types of chromosomes.

The number of chromosomes that make up a drummer's genetic code is specified by the user. The default number is 4 (which, for the musically inclined results in a "four-four" time signature).

At the beginning, every player starts with the exact same chromosomes (each player only plays on the downbeat). Each player plays through its chromosomes in sync with the other players (i.e. all turtles play note 0 of chromosome 0, then note 1 of chromosome 0, etc...). After the turtles have finished playing through their chromosomic rhythms, the turtles "evolve."

After each play through of their genetic rhythms, two of each type of drummer (high, medium, and low drummers) are selected to 'reproduce' and 'evolve.' Each turtle selects a mate based on a fitness function (different for each breed). Turtles with higher fitness are more likely to be selected as mates.

In West African drumming, low drummers are considered the base of the rhythm. Therefore, their fitness is determined by the number of strong-beats (i.e. the 0th and 2nd entries in each chromosome) that they play on.

Medium drummers are typically a little bit more soloistic than low drummers, but often emphasize off-beats. So their fitness is evaluated on the number of off-beats (i.e. the 1st and 3rd entries in each chromosome) that they play on.

Finally, high drummers are considered the soloists of the ensemble. They provide rhythmic tension and tend to play in clusters. Therefore, their fitness is based on the number of 3-clusters [0 1 1 1] that they play, which are considered regardless of their position in the pattern.

Once a mate pair is selected, each mate picks between 1 and 4 chromosomes to contribute to the offspring (for a total of 4). This genetic material is combined and, depending on user parameters, is subject to random mutations. This new set of genetic material is considered a new off-spring. This off-spring then replaces the least fit member of the type of drummer originally selected to evolve.

Once this evolution has taken place, the whole process repeats again!

This differs from a "pure" genetic algorithm in a few ways. Firstly, turtles that are selected to "evolve" are randomly selected. This was a design decision that should not dramatically affect the evolution of the model. In addition, we limit the population to 16 drummers by "killing" the least fit members of each breed after every round of evolution.

### What in the world is the view showing?

This model uses the NetLogo view in a non-standard way. Instead of showing agent interactions, this model uses the view to display properties of the agents. Each row of patches represents a single drummer's pattern. A colored patch represents a hit while a black patch represents a rest. This way, the user can simultaneously view the patterns of all 16 drummers.

When a user clicks any of the GO buttons, a vertical yellow bar moves across the view and indicates where in the rhythm each turtle is.

## HOW TO USE IT

The whole idea of this model is to experiment with the parameters in order to build a "great" rhythm. What makes a great rhythm is entirely up to you.

### Interface Elements
There are two interface elements that must be set before pressing the SETUP button:

1. NUM-CHROMOSOMES - This specifies the number of rhythmic chromosomes each player has
2. SHUFFLE-PARTS? - This is simply a GUI change that shuffles around the player's lines on the view (just to make things look cooler)

The SETUP button is used to create the agents and update the display. It will also cause a test tone to be played to make sure the sound extension is working and your speakers are not muted

GO-ONCE is used to ask all the turtles to play their pattern exactly once and then evolve

GO is used to loop the process of playing and evolving over and over again

GO-ONCE-NO-EVOLVE can be used to play any particular pattern exactly once with no evolution

GO-NO-EVOLVE is used to loop a pattern over and over again with no evolution

SOUND? is used to toggle sound output

TEMPO-BPM changes how fast each pattern is played (measured in beats (or chromosomes) per minute)

### Evolution Parameters

HIT-LIMIT defines how long a turtle can go without being forced to evolve in some way. Again, this differs slightly from a traditional genetic algorithm but can be used to escape "stale" rhythms

HIT-DENSITY-MODIFIER is a modifier to specify how "dense" a pattern should be (hits vs rests)

NUM-MUTATIONS is how many mutations are applied to an off-springs chromosomes

MUTATION-STRENGTH dictates how much a particular chromosome can mutate

SOLOER is a chooser that allows you to single out one drummer for a solo

SOLO? dictates whether or not to allow the SOLOER to solo. This means that the SOLOER plays its drum louder and the other turtles play their drums softer. In addition, the SOLOER will have maximum fitness

### Model Outputs

GENERATIONS counts how many generations of players we've seen

DENSITY represents the current ratio of hits to rests

The following are plots of the model:

AVERAGE FITNESS plots the average fitness of each type of turtle and the average overall fitness over time

HITS SINCE EVOLUTION is a histogram showing how long it has been since each player has 'evolved'

HITS PER DRUMMER is a histogram showing how many hits each player has done

## THINGS TO NOTICE

When you first start the model, everyone starts with the same chromosomes. So if you disable mutation by making MUTATION-STRENGTH 0, your model won't evolve! That's because the same chromosomes are just being combined together for each player.

Notice that sometimes, a single turtle sticks around for a really long time (because it's super fit!)

Checkout the Hits per Drummer plot. Do you see any general trends over the course of running the model? Why might that trend be taking place?

Notice that the SOLO function doesn't just make one player louder, it makes it so that the player doesn't evolve or mutate. How does that affect the model?

## THINGS TO TRY

Use the SOLO function to force a rhythm to evolve around a single steady player.

Try and make a rhythm where all three types of players are "equally" fit!

Try to evolve a rhythm where the high drums are very sparse.

See how creating a "complex" meter changes the way you hear the beat. An easy way to do this is to set the NUMBER-CHROMOSOMES to 5 and see if you can hear the musical phrase.

## EXTENDING THE MODEL

Try changing the instrument sounds for the turtles. Can you switch from a drum circle feel to more of a rock beat feel by just changing instruments?

Add more types of drummers. See how that changes the evolution.

Change the criteria for a mate for each breed and see how that effects the evolution of the rhythm.

Try to add the ability for turtles to play triplets! This would make the rhythms super cool, but would require warping time a bit! (Hint: check out the play-later primitive in the sound extension)

## NETLOGO FEATURES

Notice that this model purposefully slows down the NetLogo world by using the `wait` primitive. That's because music doesn't happen as fast as possible! Unfortunately, this doesn't work for the first tick, so the space between the "first beat" and "second beat" is not equal to the space between the rest of the beats.

## RELATED MODELS

Check out the Sound Machines and Drum Machine models in the Models Library!

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Bain, C. and Wilensky, U. (2017).  NetLogo GenJam - Duple model.  http://ccl.northwestern.edu/netlogo/models/GenJam-Duple.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2017 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2017 Cite: Bain, C. -->
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
set sound? False
set tempo-bpm 1000
setup
repeat 128 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
71
41
631
361
0
0
0
1
1
1
1
1
0
1
1
1
0
15
0
15

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
