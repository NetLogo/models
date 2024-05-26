extensions [ rnd ]

breed [ non-learners non-learner ]       ;; Non-learning population
breed [ random-learners random-learner ] ;; Random learning popluation
breed [ smart-learners smart-learner ]   ;; Smart learning population

globals [ target-phenotype ]

turtles-own [
  genotype  ;; The genetic make-up of the organism
  phenotype ;; The observable characteristic of the organism
  fitness   ;; The fitness value
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; SETUP PROCEDURES ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  ;; Produce a random target phenotype
  set target-phenotype n-values gene-length [ one-of [ 0 1 ] ]
  set-default-shape turtles "circle"
  ;; Randomly initialize each population
  setup-random-learners
  setup-non-learners
  setup-smart-learners
  reset-ticks
end

to setup-random-learners
  create-random-learners num-pop [
    ;; assign a random a genotype
    set genotype produce-gene
    ;; determine phenotype from genotype
    set phenotype init-phenotype genotype
    ;; determine fitness from phenotype
    set fitness fitness-of phenotype
    ;; place the agent, ycor is based on fitness
    set ycor fitness * 100
    set xcor get-xcor random-learners
    set size 2
    ;; the tone of the color is based on plasticity
    set color scale-color red plasticity-freq -0.3 1.3
  ]
end

to setup-smart-learners
  create-smart-learners num-pop [
    ;; assign a random a genotype
    set genotype produce-gene
    ;; determine phenotype from genotype
    set phenotype init-phenotype genotype
    ;; determine fitness from phenotype
    set fitness fitness-of phenotype
    ;; place the agent, ycor is based on fitness
    set ycor fitness * 100
    set xcor get-xcor smart-learners
    set size 2
    ;; the tone of the color is based on plasticity
    set color scale-color blue plasticity-freq -0.3 1.3
  ]
end

to setup-non-learners
  create-non-learners num-pop [
    ;; assign a random a genotype
    set genotype init-phenotype produce-gene
    ;; the phenotype and the genotype are the same for non-learners because they have no plasticity
    set phenotype genotype
    ;; determine fitness from phenotype
    set fitness fitness-of phenotype
    ;; place the agent, ycor is based on fitness
    set ycor fitness * 100
    set xcor get-xcor non-learners
    set size 2
    set color gray
  ]
end

to-report produce-gene
  ;; Produces a random gene of specified length and plasticity
  let gene-list n-values gene-length ["x"]
  report map [a -> ifelse-value (random-float 1 < plasticity) [ a ] [ one-of [ 0 1 ] ] ] gene-list
end

to-report init-phenotype [gene-list]
  ;; Initializes a random phenotype based on the gene
  report map [a -> ifelse-value (a = "x") [ one-of [ 0 1 ] ] [ a ] ] gene-list
end

to-report get-xcor [agentset]
  ;; Groups organisms to three columns on the view based on their population type
  ;; and determine the xcor in each column based on the number of correct alleles in their genotype
  let var 20
  report (ifelse-value
    agentset = random-learners [
      (correct-allele-freq - 0.5) * var
    ]
    agentset = smart-learners [
      28 + (correct-allele-freq - 0.5) * var
    ] [  ; non-learners
      -28 + (correct-allele-freq - 0.5) * var
    ]
  )
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; RUNTIME PROCEDURES ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; Organisms in each population die and reproduce
  ;; and they learn according to the learning rule of their population
  ask random-learners [ random-learn ]
  select random-learners
  reproduce random-learners

  ask smart-learners [ smart-learn ]
  select smart-learners
  reproduce smart-learners

  ;; non-learners just reproduce instead of learning
  ask non-learners [
    set fitness fitness-of phenotype
    set ycor fitness * 100
  ]
  select non-learners
  reproduce non-learners

  tick
end

to random-learn
  ;; Random learning algorithm,
  ;; randomly assigns a value to plastic alleles at each iteration
  ;; Keeps the new phenotype if it has a better fitness than the previous one
  let avg 0
  set fitness fitness-of phenotype
  repeat num-trials [
    let new-phenotype map [ a -> ifelse-value (a = "x") [ one-of [ 0 1 ] ] [ a ] ] genotype
    let new-fitness fitness-of new-phenotype
    if new-fitness > fitness [
      set phenotype new-phenotype
      set fitness new-fitness
    ]
    set avg avg + fitness
  ]
  ;; The fitness of an organism is the average of all learning trials
  set fitness avg / num-trials
  set ycor fitness * 100
  set color scale-color red plasticity-freq -0.3 1.3
end

to smart-learn
  ;; Smart learning algorithm,
  ;; Values assigned to a plastic allele is determined probalistically
  ;; based on the fitness of the previous best phenotype
  ;; Keeps the new phenotype if it has a better fitness than the previous one
  let avg 0
  set fitness fitness-of phenotype
  repeat num-trials [
    let new-phenotype (map [ [ a1 a2 ] ->
      ifelse-value (a1 = "x") [
        ifelse-value (random-float 1 < fitness) [ a2 ] [ one-of [ 0 1 ] ]
      ] [
        a1
      ]
    ] genotype phenotype)
    let new-fitness fitness-of new-phenotype
    if new-fitness > fitness [
      set phenotype new-phenotype
      set fitness new-fitness
    ]
    set avg avg + fitness
  ]
  ;; The fitness of an organism is the average of all learning trials
  set fitness avg / num-trials
  set ycor fitness * 100
  set color scale-color blue plasticity-freq -0.3 1.3
end

to-report fitness-of [current-phenotype]
  ;; Measures how similar the given phenotype is to the target phenotyoe
  ;; The difference is the Hamming distance
  let difference sum (map [ [ a1 a2 ] -> ifelse-value (a1 = a2) [ 0 ] [ 1 ] ] current-phenotype target-phenotype)

  ;; The value is normalized between 0 and 1
  let fit (gene-length - difference) / gene-length

  ;; Based on the smoothness of the fitness landscape,
  ;; returns 0 if the difference is below a threshold, and returns the normalized difference otherwise.
  report ifelse-value (fit >= (1 - smoothness)) [ fit ] [ 0 ]
end

to reproduce [agentset]
  ;; Reproduction algorithm
  ;; Reproduction is sexual with uniform crossover
  ;; A tournament style model is used
  ;; 20% of population size offsprings are produced at each iteration
  repeat num-pop * 0.2 [
    ;; 30% of the population is chosen randomly
    ;; Parents are chosen stochastically from this subset based on their fitness
    let selected rnd:weighted-n-of 2 (n-of (0.3 * num-pop) agentset) [ fitness ]

    let [genotype1 genotype2] [genotype] of selected

    ;; Alleles in the new genotype is chosen from either parent with equal probability
    let new-genotype (map [ [ a1 a2 ] -> one-of list a1 a2 ] genotype1 genotype2)

    ;; Mutates the alleles in the new gene based on the mutation rate
    set new-genotype map [a ->
      ifelse-value (random-float 1 > mutation-rate / 1000)
      [ a ]
      [ ifelse-value agentset = non-learners [ one-of [ 0 1 ] ] [ one-of [ 0 1 "x" ] ]]
    ] new-genotype

    ;; Produces offspring with the new gene
    ask one-of selected [
      hatch 1 [
        set genotype new-genotype
        set phenotype init-phenotype genotype
        set ycor fitness * 100
        set xcor get-xcor agentset
      ]
    ]
  ]
end

to select [agentset]
  ;; The worst 20% of the population dies
  ask min-n-of (num-pop * 0.2) agentset [fitness] [die]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; OBSERVABLES ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report plasticity-freq
  ;; Reports the relative frequency of plastic alleles of the agent's genotype
  report (length filter [ a -> a = "x" ] genotype) / (length genotype)
end

to-report correct-allele-freq
  ;; Reports the relative frequency of correct alleles of the agent's genotype
  let matches (map [ [ a1 a2 ] -> ifelse-value (a1 = a2) [ 1 ] [ 0 ] ] genotype target-phenotype)
  report (sum matches) / (length genotype)
end

to-report percentage-plastic-alleles [agentset]
  ;; Percentage of plastic alleles of the given population
  report mean [plasticity-freq * 100] of agentset
end

to-report percentage-correct-alleles [agentset]
  ;; Percentage of correct alleles of the given population
  report mean [correct-allele-freq * 100] of agentset
end


; Copyright 2023 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
645
10
977
463
-1
-1
4.0
1
10
1
1
1
0
0
0
1
-40
40
-5
105
1
1
1
ticks
30.0

BUTTON
20
130
100
163
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
120
130
195
163
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

PLOT
210
10
639
280
Average Fitness
Generations
Average Fitness
0.0
10.0
0.4
1.0
true
true
"" ""
PENS
"Smart Learners" 1.0 0 -13345367 true "" "plot mean [ fitness ] of smart-learners"
"Random Learners" 1.0 0 -2674135 true "" "plot mean [ fitness ] of random-learners"
"Non-Learners" 1.0 0 -7500403 true "" "plot mean [ fitness ] of non-learners"

SLIDER
20
10
195
43
num-pop
num-pop
1
500
200.0
1
1
NIL
HORIZONTAL

SLIDER
20
50
195
83
gene-length
gene-length
1
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
20
90
195
123
plasticity
plasticity
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
20
170
195
203
num-trials
num-trials
1
100
20.0
1
1
NIL
HORIZONTAL

PLOT
20
290
322
465
Percentage of Plastic Alleles
Generations
% Plastic Alleles
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Smart Learners" 1.0 0 -13345367 true "" "plot percentage-plastic-alleles smart-learners"
"Random Learners" 1.0 0 -2674135 true "" "plot percentage-plastic-alleles random-learners"

PLOT
325
290
635
465
Percentage of Correct Alleles
Generations
% Correct Alleles
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Smart Learners" 1.0 0 -13345367 true "" "plot percentage-correct-alleles smart-learners"
"Random Learners" 1.0 0 -2674135 true "" "plot percentage-correct-alleles random-learners"
"Non-Learners" 1.0 0 -7500403 true "" "plot percentage-correct-alleles non-learners"

SLIDER
20
210
195
243
mutation-rate
mutation-rate
0
10
5.0
0.1
1
E-4
HORIZONTAL

SLIDER
20
250
195
283
smoothness
smoothness
0
1
0.15
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

The purpose of this model is to investigate, in a quantitative manner, how learning can affect evolution. This model aims to demonstrate that "better learning" organisms, in certain environments, are more effective in expediting the evolutionary search to find good genotypes, even when the specific adaptations that are learned are not communicated to the genotype.

The relationship between evolution and learning has been debated at length. The two concepts are most commonly related by what is known as the Baldwin effect. The Baldwin effect suggests that phenotypic plasticity, a more general term that includes learning, can enhance evolution. More specifically the Baldwin effect states: (1) organisms adapt to the environment individually, (2) genetic factors produce hereditary characteristics similar to the ones made available by individual adaptation, and (3) these hereditary traits are favoured by natural selection and spread in the population.

Using a computational model, Hinton & Nowlan (1996) influentially suggested that learning can qualitatively speed up evolution. Taking Hinton & Nowlan’s study as a starting point, in addition to showing the difference between the evolution of learning and non-learning populations, this model considers three populations: two populations that learn in different ways such that one population is better at learning than the other one and one non-learning population. In other words, this model investigates to what extent the Baldwin effect might manifest itself with different learning abilities.

## HOW IT WORKS

At each timestep, each agent

* tries to learn phenotypes of high fitness based on their learning rules
* has a chance of dying if it has a low fitness value
* has a chance of reproducing if they have a high fitness value.

A genotype refers to the genetic makeup of an organism (its complete set of alleles), whereas a phenotype refers to the observable physical properties of an organism, including its behavior. Because the phenotype is determined by both an organism’s genotype and by environmental influences upon the genotype, organisms with identical genotypes can ultimately express non-identical phenotypes. In this model, each organism has a genotype (a sequence of symbols) and a phenotype associated with their modeled nervous system. In this model, each symbol in a genotype is an allele. Each allele could be one of the three following symbols: 0, 1, X. Alleles determine the connections in the organism's nervous system. Where 0 means there is no connection, 1 means there is a connection, and X means the connection value is undecided and will be set through learning. We refer to the X alleles as plastic alleles, since they don’t have a definite value (they’re “plastic” in that they are set as the model unfolds rather than at the outset). The nervous system only determines the phenotype, which relates to the reproductive fitness of the organism. In this model, we will represent a nervous system by a sequence of symbols as explained above. We will refer to these nervous systems as phenotypes, which are sequences of symbols that only consist of 0s and 1s. This means that a genotype might have plastic alleles, but a phenotype won’t. For example, if an organism has the genotype 01X1, it’s phenotype could either be 0111 or 0101 and nothing else. There is a single ideal target phenotype (set randomly) that has the optimal fitness. The reproductive fitness of the organism is modeled by a function that measures the similarity between the phenotype of the organism and the target phenotype. We call this value “fitness” and note that it is bounded between 0 and 1.

The function that reports the fitness of an organism is affected by the smoothness of the fitness landscape. A fitness landscape can be regarded as a mapping between phenotypes and fitness values. A smooth fitness landscape would indicate that similar phenotypes would have similar fitness values whereas a rugged fitness landscape would indicate that similar phenotypes can have very different fitness values. For example, the phenotypes 0111 and 1111 might have fitness values of 0.5 and 0.6 respectively in a smooth fitness landscape. The same phenotypes might have fitness values of 0 and 1 respectively in a rugged fitness landscape. The smoothness is set by the user and is bounded between 0 and 1. If the smoothness is set to 0, then the fitness value of an organism is either 0 or 1. That is, if the organism's phenotype is exactly the target phenotype its fitness would be 1, otherwise it would have a fitness of 0. If the smoothness is set to 1 however, the organism’s fitness maybe any range of values between 0 and 1, depending on how similar its phenotype is to the target phenotype.

There are three populations, Smart Learners, Random Learners and Non-learners. At each time step, the organisms undergo several learning trials, the number of which is determined by the user. At each trial, the random learners learn by setting all plastic alleles randomly to either 0 or 1, with equal probability. At each trial, two potential phenotypes (one previously generated and one new, randomly generated) are compared to the ideal phenotype. If the reproductive fitness of the new phenotype is lower than the phenotype from the previous time step, then the organism discards this new attempt and continues to explore randomly. However, if the new phenotype has a higher fitness than that of the previous time step, then the organism uses this setting as a point of comparison in the next trials.

The smart learners learn by setting the value of plastic alleles probabilistically. That is, they have probability *f* that X will be set to the corresponding allele in the previous phenotype configuration, and probability 1-*f* that it will be set randomly with equal probability to either 0 or 1, where *f* is the fitness of the phenotype of the previous configuration. So a smart learning organism is more likely to keep the values of plastic alleles that yield a higher fitness.

The number of learning trials for each organism is set by the user. None of the learned traits are passed on to the offspring, so an offspring inherits only the locked in 0's and 1's, but continues to have X's in all the same places as their parents. Reproduction is proportional to fitness and is sexual. Every child is a recombination of its parent's' genotype, taking the value of each allele randomly from one of the parents. During reproduction, each allele has a chance to randomly mutate. All three populations start with the same number of individuals determined by the user.

## HOW TO USE IT

The SETUP button initializes the model.

The GO button runs the model.

Use the NUM-POP slider to set the initial number of organisms in each population.

Use the GENE-LENGTH slider to set the length of the genotype and phenotype of each organism.

Use the PLASTICITY slider to set the probability *p* that each allele in the initial genotypes is plastic. For example, if plasticity is 1, every allele will be plastic. If plasticity is 0.2, then 20% of the alleles will be plastic, and the rest will be locked in 0’s and 1’s.

Use the NUM-TRIALS slider to set the number of learning trials each organism undergoes at each time step.

Use the MUTATION-RATE slider to set the probability that an allele in the genotype of an offspring undergoes mutation when an offspring is produced.

Use the SMOOTHNESS slider to make the fitness landscape more smooth or rugged. If the slider is set to 1, the landscape is smooth, if it is set to 0, the landscape consists of a single spike. Specifically, this slider determines the threshold that the fitness of an organism is non zero.

The blue dots in the VIEW represent smart learners, the red dots represent random learners, and the grey dots represent non-learners. The vertical location of each dot indicates that organism's fitness value. The dots at the very top indicate maximum fitness. The shade of the dots indicates the number of plastic alleles that organism has. The lighter the color, the more plastic alleles that organism has. Horizontally, the organisms are placed in three bins based on their learning type. Within each bin, the horizontal placement of each organism depends on the number of correct alleles in their genotype. The higher the number of correct alleles, the more to the right an organism is placed.

The plot titled Average Fitness depicts the average reproductive fitness of the organisms in three different populations as a function of time. In this model, each time step is a generation. The blue line indicates the average fitness of the smart learning population, whereas the red line and the grey line indicate the average fitness of the random learning population and the non-learning population, respectively.

The plot titled Percentage of Plastic Alleles depicts the percentage of plastic alleles in the genotypes of the smart learners and random learners as a function of time steps. The blue line and the red line indicate smart learners and random learners, respectively.

The plot titled Percentage of Correct Alleles depicts the percentage of locked in alleles that match with those of the target phenotype as a function of time steps. Note that this plot only counts the locked in alleles and not the plastic ones towards the number of correct alleles. The blue, red and grey lines indicate smart learners, random learners, and non-learners respectively.

## THINGS TO NOTICE

Which population tends to reach a better phenotype the fastest? Which population generally reaches the highest fitness values?

How are the number of plastic alleles and the number of correct alleles related?

## THINGS TO TRY

How does the initial population size affect the average fitness of each population over time? Which population has a comparative advantage against the others as the gene length, plasticity, and number of learning trials change? How does smoothness affect the fitness of each population? Which populations tend to reach high fitness values when smoothness is low?

## EXTENDING THE MODEL

There are various ways this model can be extended. One of them is changing how smart learners learn, or adding another population that learns differently.

Adding a different method of reproduction, adding a different fitness function, or adding a way that enables the populations to interact with each other are all plausible extensions of this model. Another possibility is to model the change in environment and investigate which organisms are more adaptable.

Another exciting extension of this model would be using LevelSpace such that each agent has an actual neural network to model its nervous system, and some properties of the network is passed on to the offspring, such as the connections in the network. Then each offspring determines the weights in the network by using different learning strategies.

## NETLOGO FEATURES

The `scale-color` primitive is used to visualize the number of plastic alleles of each organism in smart learners and random learners. The more plastic alleles an organism has, the lighter it looks.

The `rnd:weighted-n-of` primitive from the rnd extension to select organisms to reproduce probabilistically based on their fitness.

## RELATED MODELS

* GenDrift Sample Models
* GenEvo Curricular Models
* Echo

## CREDITS AND REFERENCES

Baldwin, J. (1896). A New Factor in Evolution. The American Naturalist, 30(354), 441-451. Retrieved from http://www.jstor.org/stable/2453130.

Geoffrey E. Hinton and Steven J. Nowlan. 1996. How learning can guide evolution. In Adaptive individuals in evolving populations, Richard K. Belew and Melanie Mitchell (Eds.). Santa Fe Institute Studies In The Sciences Of Complexity, Vol. 26. Addison-Wesley Longman Publishing Co., Inc., Boston, MA, USA 447-454.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Gurkan, C. and Wilensky, U. (2023).  NetLogo Baldwin Effect model.  http://ccl.northwestern.edu/netlogo/models/BaldwinEffect.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2023 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2023 Cite: Gurkan, C. -->
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
NetLogo 6.4.0
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
