globals
[
  is-stopped?          ; flag to specify if the model is stopped
]

breed [flowers flower] ; the main food source
breed [nests nest]     ; the ants' home, where they bring food to and are born
breed [ants ant]       ; the red and blue ants
breed [queens queen]   ; the reproductive flying ants that found new colonies
breed [males male]     ; the queens' mates, required only for founding new colonies
breed [gasters gaster] ; part of the HUD display of ants
breed [boxes box]      ; the graphical element that holds the two HUD displayed ants in the top right and left of the model
breed [demos demo]     ; the other part of the HUD display



turtles-own
[
  age                  ; an ant's age
  team                 ; an ant's team
]

patches-own
[
  chemical             ; amount of chemical on this patch
  nest?                ; true on nest patches, false elsewhere
  my-color             ; determines an ant's team
  is-food?             ; whether a patch contains food
]

ants-own
[
  energy               ; each ant has energy, they die if energy is 0
  mother               ; stores the ant's mother nest
  has-food?            ; whether the ant is carrying food
  prey                 ; the target of the ant
  fighting?            ; whether this ant is currently in a fight
]


nests-own
[
  food-store            ; the total food stored inside the nest
  mother                ; stores the nest's mother nest
]

queens-own
[
  food-store            ; queens carry some food with them in fat on their body to found the new nest
]

;; setting up the model ;;
to startup  ; launches setup when the application starts
  setup
end

to setup    ; sets up two colonies in fixed locations in the world, each with 10 ants that belong to each nest
  clear-all
  initialize
  create-HUD-display-of-ants
  reset-ticks
end

to initialize ; sets up the colonies, initial flowers, grass, and gives each nest 10 ants
  set is-stopped? false
  ask patches
  [
    set nest?  false
    set is-food? false
    set my-color green - 1 set pcolor green - 1
  ]
  flowering 45 1 ; makes 45 flowers
  make-nest 1 -24 8  cyan "blue-team" ; place a blue colony
  make-nest 1 27 -7 red "red-team"      ; place a red colony
  ask nests [ hatched-ant 10 ]          ; give each colony 10 ants
  set-default-shape nests "anthill"
  ask turtles [ set age  1 ] ; keeps track of all turtles age
end
;; the model loop ;;
; Every time step ants move produce. Ants without food die, and nests without ants die.

to go                         ; repeats every time step, because the go button in the interface is set to forever.
  move-ants                   ; moves ants
  create-more-ants            ; produces more ants
  touch-input                 ; handles user touch inputs on view.
  paint-pheromone             ; recolors view from changes of pheromone level on each patch.
  flowering 1 500             ; grows more flowers for the ants to eat
  diffusion-pheromone         ; slowly evaporate pheromone trails
  death                       ; checks if ants die due to old age
  move-winged-ants            ; moves reproductive ants (queens and males), found a new colony if they run into each other.
  kill-empty-nest             ; removes nests with no ants left in them
  show-nest-food              ; places a label of food stored on nests
  go-into-nest                ; hides ants when they approach nests to simulate going inside
  control-heads-up-display-of-ants
  tick
end

;; movement procedures ;;
to move-ants ; moves ants
  ask ants
  [
    ifelse fighting? = false [ ; if the ant is not fighting
      any-body-here-to-fight? ; check if their is an ant to fight
      ifelse shape = "ant" ; if an ant
        ; and not carrying food? look for it
        [ look-for-food ]
        [ return-to-nest ] ; carrying food? take it back to nest
      wiggle ; performs a random walk to explore the map
      fd 1
    ]
    [
      blue-attack ; run attack for blue ants
      red-attack   ; run attack for red ants
      continue-fight  ; if in a fight, keep fighting
    ]
  ]
end


to move-winged-ants ; Moves winged ants. And if in an area they can found a colony, founds a colony.
  ask queens
  [
    wiggle
    fd 1
    ; makes nests in allowable areas: five patches from any other nest, and not under the black boxes in the top left and right.
    if not any? nests in-radius 5 and not any? boxes in-radius 10 [ found-colony ]
  ]
  ask males
  [
    wiggle
    fd 1
  ]
end


to return-to-nest  ; turtle procedure to return to the nest if the ant has found food

  ifelse nest?     ; if ant has food and is at their nest, drop off the food
  [
    set shape "ant"
    let delivery-point one-of nests in-radius 2

    if delivery-point != nobody
    [
      ask delivery-point [set food-store food-store + 1] ; drop food and head out again
      rt 180
      set has-food? false
    ]
  ]
  [
    set chemical chemical + 60  ; else, drop some chemical
     ; go back toward the location of the home nest with the possibility of stopping at another nest if it interrupts the path
    if mother != nobody [ face mother ]
  ]
end

to look-for-food ; turtle procedure
  if [is-food?] of patch-here = true
  [
    set energy energy + 1000    ; ant feeds herself
    rt 180                      ; and turns around to bring food back to the larva in the colony
    pickup-food-here
  ]

  ; move towards highest chemical load
  if (chemical >= 0.05) [ uphill-chemical ]
end

to pickup-food-here ; turtle procedure
  if has-food? = false
  [
    if shape = "ant" [ set shape "ant-has-food" ]
    let food-radius 2
    if any? flowers in-radius food-radius
    [
      ask one-of flowers in-radius food-radius
      [
        ; sets the shape of the flower to one less petal everytime an ant harvest it. The flower dies when it loses all of its pedals.
        (ifelse
          shape = "flower"  [ set shape "flower2" ]
          shape = "flower2" [ set shape "flower3" ]
          shape = "flower3" [ set shape "flower4" ]
          shape = "flower4" [ set shape "flower5" ]
          shape = "flower5" [ set shape "flower6" ]
          shape = "flower6" [ set shape "flower7" ]
          shape = "flower7" [ set shape "flower8" ]
          shape = "flower8" or shape = "flower-long8"
          [
            ask patch-here
            [
              set is-food? false
              ask neighbors [ set is-food? false ]
            ]
            die
          ]
        )
      ]
    ]
  ]
end

to wiggle  ; turtle procedure. randomly turns ants within a 80 degree arc in the direction the ant is heading
  rt random 40
  lt random 40
  if not can-move? 1 [ rt 180 ]
end

to found-colony   ; turtle procedure.
                  ; The males dies and the queen burrows into the ground and makes a nest.

  let mate one-of males in-radius 7  ;Makes new colonies of ants.

  if mate != nobody [
    if [breed] of mate = males
    [
      if [color] of mate != color ;  When a female meets a male of a different color,
      [
        hatch-nests 1   ; they mate.
        [
          set mother self ; sets the colony's ID to the hatched agent so that its workers can check belonging against the mother
          set color [color] of mate
          hatched-ant 4

          set size 20
          set shape "anthill"
          ask patch-here
          [
            set nest? true
            ask neighbors [ set nest? true ]
          ]
        ]
        ask mate [ die ]
        die
      ]
    ]
  ]
end

;; reproduction procedures;;
to create-more-ants ; births some ants
  ask nests
  [ ; for red colonies, if the stored food greater than the cost to feed a baby ant to adulthood, make another ant
    if color = red   [ if food-store > red-build-cost   [ birth ] ]
    ; for blue colonies, if the stored food greater than the cost to feed a baby ant to adulthood, make another ant
    if color = cyan [ if food-store > blue-build-cost [ birth ] ]
  ]
end

to produce-gynes [some-males some-females] ; produces reproduces males and females that fly about and found-new colonies.
  hatch-males some-males    [ set shape "butterfly" set size 5  set age 0 set label "" set age 0] ; creates some males
  hatch-queens some-females [ set shape "queens"    set size 10 set age 0 set label "" set age 0] ; creates some females
  set food-store food-store - 50 ; reduces the colony's food by  50. Wow that's a lot of food for just one ant!
end

to birth
  ifelse ticks mod 100 = 1 ; once in 100 ticks, reproduce, if there is enough food.
    [ produce-gynes 1 1 ]
    [ hatched-ant 1 ]

  if color = red   [ set food-store food-store - red-build-cost ]
  if color = cyan [ set food-store food-store - blue-build-cost ]
end

to hatched-ant [ some-ants ] ; turtle procedure. This procedure hatches some ants, called by nests.

  hatch-ants some-ants
  [
    ifelse color = red
      [ set energy red-start-energy]
      [ set energy blue-start-energy]
    set mother myself
    set fighting? false
    set shape "ant"
    set has-food? false
    ifelse color = red
      [ set size red-size ]
      [ set size blue-size ]
    set label ""
    set age 0
    set prey nobody
  ]
end

to make-nest [numb x y a-color a-team] ; Creates a nest at a location, of a team, and color.
  create-nests numb [
    setxy x y
    set size 20
    set shape "anthill"
    set nest? true
    set color a-color
    set team a-team
    ask neighbors [ set nest? true ]
    ask patch-here [ set plabel precision [food-store] of myself 1 ]

    set mother self ; a way to compare to their foragers to see if they are of the same nest (something real ants do with hydrocarbons on their skin)
  ]
end

;; death procedures ;;
to death ; check to see if turtles will die,
  ask ants
  [
    set energy energy - 5 + (1 - (blue-aggression / 100))
    if energy - (age) <= 0 [ die ]
  ]

  ask nests ; eats some of the stored food
  [
    set food-store food-store - 0.001
    if food-store < -100 [ die ]
  ]

  ; increment turtles age by 1 each time step
  ask turtles [ set age age + 1 ]
end

to kill-empty-nest ; If the ants of the new nest don't return food before they all die (fail to found) the colony dies

  ask nests
  [
    if not any? ants with [mother = [mother] of myself]
    [
      ask patch-here
      [
        set nest? false
        ask neighbors [ set nest? false ]
      ]

      ask patch-at 0 -7 [set plabel ""]
      die
    ]
  ]
end

;; following pheromone procedures ;;
to uphill-chemical  ; turtle procedure. sniff left and right, and go where the strongest smell is
  let scent-ahead chemical-scent-at-angle   0
  let scent-right chemical-scent-at-angle  45
  let scent-left  chemical-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead)
  [
    ifelse scent-right > scent-left
      [ rt 45 ]
      [ lt 45 ]
  ]
end

to-report chemical-scent-at-angle [angle] ; reports the amount of pheromone in a certain direction
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]
  report [chemical] of p
end

to diffusion-pheromone ; adjusted the level of chemical each tick
  diffuse chemical (20 / 100)
  ask patches
  [
    set chemical chemical * (100 - (evaporation-rate )) / 100
    if chemical < 1 [ set chemical 0 ]
  ]
end

;; fight procedures;;
to any-body-here-to-fight? ; turtle procedure. Checks for other ants nearby of the other team, and makes sure the list isn't empty

  if any? other ants in-radius 1 with [team != [team] of myself] != nobody
  [ ; checks to make sure there are some other ants here
    ifelse any? other ants in-radius 1 with [team != [team] of myself]
      [ set fighting? true ] ; then fight them
      [ set fighting? false ]
  ]
end

to attack ; turtle procedure that checks if the ant it fighting, and the prey ant isn't of this ants colony, then  run away, and try to kill the ant, or stop fighting
  if prey != nobody
  [
    if fighting? = true
    [
      set prey one-of other ants-here with [team != [team] of myself]

      if prey != nobody
      [
        ask prey [ face myself ]

        if [breed] of prey = ants
        [
          if [team] of prey != team
          [
            let choice random 2
            ask prey
            [
              set chemical chemical + 60
              (ifelse
                choice = 0
                [
                  back 3 rt 90 ; backs off
                  set fighting? false
                  if random [size] of prey < random [size] of myself [die] ; and tries to kill the ant based on the size
                ]

                choice = 1 [set fighting? false] ; stop fighting
              )
            ]
          ]
        ]
      ]
    ]
  ]
end

to blue-attack ; turtle procedure calculates the blue aggression and if high enough to surpass a randomly generated number, the ant attacks this tick.
  ask ants with [team = "blue-team"] [ if blue-aggression > random 100 [ attack ] ]
end

to red-attack ; turtle procedure calculates the blue aggression and if high enough to surpass a randomly generated number, the ant attacks this tick.
  ask ants with [team = "red-team"]   [ if red-aggression > random 100 [ attack ] ]
end

to continue-fight ; handles what happens after each fight
  wiggle
  fd 1
  ask patch-here [set chemical chemical + 15]
  ifelse any? other ants in-radius 1 with [team != [team] of myself]
    [ face one-of other ants in-radius 1 ]
    [ set fighting? false ]
  if random 100 < 1 [ ask ants [ set fighting? false ] ]
end

;; flower procedures ;;
to flowering [some prob] ; adds some flowers to the view at some rate with prob likelihood.

  if random prob < 1
  [
    ask n-of some patches
    [
      sprout-flowers 1
      [
        set shape "flower"
        set size 16
        set color yellow
        ask patch-here
        [
          set is-food? true
          ask neighbors [ set is-food? true ]
        ]
      ]
    ]
  ]
end

;; Procedures for interfacing with touchscreen ;;

to touch-input; handles user touch input for chemicals, flowers, and vinegar
  if mouse-down?
  [
    ask patch mouse-xcor mouse-ycor
    [
    (ifelse
      add = "Chemical"
      [
        ask neighbors [set chemical chemical + 60  ]
      ]
      add = "Flower"
      [
        if not any? flowers in-radius 3  [sprout-flowers 1
          [
            set shape "flower"
            set color yellow
            set size 10
            set is-food? true
            ask neighbors [set is-food? true]
          ]
        ]
      ]
      add = "Vinegar"
      [
        set chemical 0 ask neighbors [set chemical 0  ]
      ]
    )
    ]
  ]
end

to paint-pheromone ; adds pheromone where the user touches the view
  ask patches
  [
    if chemical = 0 and pcolor = 55 or pcolor = 75  [set my-color pcolor]
    if chemical > 10 [set pcolor scale-color pink chemical -11 60]
    ifelse chemical > 2 [] [set pcolor my-color]
  ]
end

to-report blue-build-cost ; the amount the blue colonies need to reproduce one more ant, based on size, aggression and start energy
  let return 0
  set return blue-size / 2 + (blue-aggression / 15) + (blue-start-energy / 1000)
  report return
end

to-report red-build-cost ; the amount the red colonies need to reproduce one more ant, based on size, aggression and start energy
  let return 0
  set return red-size / 2 + (red-aggression / 15) + (red-start-energy / 1000)
  report return
end

to-report demo-shape-case ; set the size and face of the representation in the top left and right of view based on the teams size and aggression.
  let return "sideant"
  let choice red-aggression ; sets red as the default color

  if color = cyan + 2 [ set choice blue-aggression ] ; shifts the blue for the blue display.

  (ifelse  ; case switch statement for graphics that sets the shape in the top left and right based on the team's aggression level.
    choice < 10                  [ set return "sideant" ]
    choice > 10 and choice < 20  [ set return "sideant1" ]
    choice > 19 and choice < 30  [ set return "sideant2" ]
    choice > 29 and choice < 40  [ set return "sideant3" ]
    choice > 39 and choice < 50  [ set return "sideant4" ]
    choice > 49 and choice < 60  [ set return "sideant5" ]
    choice > 59 and choice < 70  [ set return "sideant6" ]
    choice > 69 and choice < 80  [ set return "sideant7" ]
    choice > 79 and choice < 90  [ set return "sideant8" ]
    choice > 89 and choice < 101 [ set return "sideant9" ]
  )
  report return
end

to control-heads-up-display-of-ants ; There are two grey squares that show the changing aggressiveness and size.
                                    ; Here we adjust the size of these to representations based on the size and aggresssion sliders
  ask demos [ifelse color = cyan + 2
    [
      set size blue-size * 2
      set shape demo-shape-case
    ]
    [
      set size red-size * 2
      set shape demo-shape-case
    ]
    ask flowers in-radius 10   ; doesn't allow flowers under the HUD
    [
      ask patch-here
      [
        set is-food? false
        ask neighbors [set is-food? false]
      ]
      die
    ]
  ]
  ask gasters
  [
    ifelse color = cyan
    [
      set size (blue-size * 2 + (blue-start-energy / 10))
    ]
    [
      set size (red-size * 2 + (red-start-energy / 10))
    ]
  ]

end

to  show-nest-food ; places a label on the colonies to show how much food they hold
  ask nests [if food-store >= 0 [ask patch-at 0 -7 [set plabel (word "Stored Food:" " " precision [food-store] of myself  0 )]]]
end

to go-into-nest ; simulate ants entering their nest by hiding them if they are bringing in food, and showing them once they drop it off.
  ask ants [ifelse any? nests in-radius 5 and has-food? = false [hide-turtle] [show-turtle]]
end

; creates the boxes in with ants in them in the upper right and left of the view. These changed based on how the players change their ant's characteristics.
to create-HUD-display-of-ants
  create-demos 2
  [
    set shape demo-shape-case
    set heading 0
    ifelse not any? demos with [color = cyan + 2]
    [
      setxy -63 21
      set size blue-size * 2
      set color cyan + 2
    ]
    [
      setxy 63 21
      set size red-size * 2
      set color red
    ]

    ask flowers in-radius 10
    [
      ask patch-here
      [
        set is-food? false
        ask neighbors [ set is-food? false ]
      ]
      die
    ]
    hatch-boxes 1
    [
      set shape "box2"
      set size 22
      set color grey
    ]
  ]
end


; Copyright 2019 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
245
10
1018
324
-1
-1
5.0
1
12
1
1
1
0
1
1
1
-76
76
-30
30
1
1
1
ticks
30.0

BUTTON
535
390
610
424
Restart
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

PLOT
20
430
1235
635
Populations by Colony Color
Time
Population
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Blue" 1.0 0 -11221820 true "" "plot count ants with [color = cyan]"
"Red" 1.0 0 -2674135 true "" "plot count ants with [color = red]"

SLIDER
65
250
237
283
blue-aggression
blue-aggression
0
100
30.0
1
1
%
HORIZONTAL

SLIDER
1025
250
1205
283
red-aggression
red-aggression
0
100
30.0
1
1
%
HORIZONTAL

SLIDER
612
390
879
423
evaporation-rate
evaporation-rate
0
1
1.0
.01
1
% of pheromones
HORIZONTAL

BUTTON
383
390
465
424
Play |>
ifelse is-stopped? != true [go] [set is-stopped? false stop]
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
1025
210
1204
243
red-size
red-size
3
10
6.0
1
1
cm
HORIZONTAL

MONITOR
120
105
240
170
Create Cost
blue-build-cost
0
1
16

MONITOR
1025
95
1155
160
Create Cost
red-build-cost
0
1
16

SLIDER
1025
290
1242
323
red-start-energy
red-start-energy
300
2000
2000.0
1
1
calories
HORIZONTAL

SLIDER
9
290
236
323
blue-start-energy
blue-start-energy
300
2000
2000.0
1
1
calories
HORIZONTAL

MONITOR
120
40
240
105
Blue Ants
count ants with [color = cyan]
17
1
16

MONITOR
1025
30
1155
95
Red Ants
count ants with [color = red]
17
1
16

SLIDER
65
211
238
244
blue-size
blue-size
3
10
6.0
1
1
cm
HORIZONTAL

CHOOSER
385
337
524
382
Add
Add
"Flower" "Chemical" "Vinegar"
1

TEXTBOX
540
330
1220
386
You can choose to add three things: \n• chemicals (pheromones) the ants follow, \n• flowers the ants eat, or \n• vinegar that erases ant chemical trails. Once selected, click on the grass to add to the game.
11
0.0
1

BUTTON
465
390
535
424
Stop ||
set is-stopped? true
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
103
391
383
425
Press Play to Start |>
24
0.0
1

@#$#@#$#@
## WHAT IS IT?

In this game, two colonies of ants forage for food. Though each ant follows a set of simple rules, the colonies as a whole act in sophisticated ways. Ant Adaptation simulates two ant colonies side by side, each controlled by a different player.

The model teaches users about complexity through play. The sensing area of the view contains five widgets for each of the two players. With Ant Adaptation, we aim to realize the promise of agent-based modeling originally illustrated by systems such as GasLab (Wilensky, 1997) or NIELS (Sengupta and Wilensky, 2009), in a rich interaction form factor for walk-up-and-play use in an informal learning space.

## HOW IT WORKS

In this model two ant colonies send out their foragers to move around and find food. If they walk over food, they pick it up and return to their colony. When the nest gets enough food, the colony produces another ant. The user can interact with the model by painting (and removing) pheromones or adding additional food to the game. While users can add food, the food (flowers) also reproduce on their own slowly. After some time, the colonies will produce new queens to found new colonies of each color. If ants of different colonies run into each other, they might fight. When ants fight, or return food from flowers, they will leave pheromone trails to attract other ants.

### WITHOUT USER INTERACTION
On setup, two ant colonies (one of red ants and one of black ants) and a number of flowers are created in the world. Ants are spawned in the ant colony and then wander until they find food, represented as flowers in the model. When they find food, they personally gain energy through eating nectar, then they return to the colony while laying down a pheromone, represented as pink trails in this model to feed the young inside the nest. Ants near pheromone trails are attracted to the strongest chemical trail. As the ants exhaust a food source, they once again begin to wander until they find another food source or another pheromone trail to follow.

When two or more ants of opposing colonies encounter each other, they fight or scare each other away also leaving chemicals that attract more ants. For the winner, this works to protect the food source from competing colonies. The ant queen reproduces when the ants in her colony collect enough food, set by the create cost for each colony. Flowers periodically grow up around the map, resupplying food in the game. Ants die if they get too old, cannot find food, or sometimes when they lose a fight. Nests die if they have no more ants living in them.

When the ants have enough surplus food, they release male and female winged ants to reproduce. When these winged ants meet they make a new colony.

### USER INTERACTION

Users can interact with the model, setting parameters for their colony and ants. Ideally each colony color would be played by an individual or team. Only a single input will be registered at any time - so teams will need to determine turn-taking practices.

The colony teams interact with this complex system in two ways. First, they can adjust the characteristics of their colony and its ants. Second, they can add or remove certain environmental features from the world.

Colony teams can decide how large and aggressive their ants are. When the size of ants increases, they become slightly faster and stronger in a fight. When players make their ants more aggressive, it increases the likelihood that ants detect opposing ants and thus the probability that they will attack. The START-ENERGY sliders set the amount of energy a new born ant has when it leaves the nest for the first time. This determines how far it can walk before finding food.

Increases in size, aggressiveness or start-energy reduces the expected population of the colony, by increasing the the cost of creating more ants, displayed in the "Create Cost" widget. The changes also increases their likelihood of fighting and winning through emergent interactions of parameters (size and aggressiveness) and agent actions (collecting food, leaving trails, and fighting).

Colony teams can adjust the environment by adding chemical trails, adding flowers, and erasing chemical trails with vinegar.

## HOW TO USE IT

![](ant_adaptation_figure.png)

There are five widgets in the center of the screen that control functions for both the red and black colony teams. As shown in the diagram above, marked 4 above, PLAY and STOP control the model’s time measured in ticks. Marked 5 in the diagram, RESTART sets the model back to initial conditions. The ADD drop down menu, marked 6 above, allows you to choose to place flowers, chemical pheromone trails, or erase trails with vinegar. To use it, select one of them, then click on the view. The EVAPORATION-RATE slider, marked 7 above, controls the evaporation rate of the chemical.

Each team decides how large and aggressive their ants are with the sliders to the left and right of the view, marked 2 in the diagram above. Then they each select how much food each new ant starts with. Once teams have decided, they should agree to click the RESTART button to set up the ant nests (with red and black flags) and the food-flowers. Clicking the PLAY button starts the simulation.

If you want to change the size, aggressiveness or starting food move your team's sliders either before pressing RESTART, or after to affect newly born ants.

Marked 1, monitors Red and Black ants at the top, counts the ants’ population named BLACK ANTS on the left, and RED ANTS on the right. Marked 2, the three sliders at the bottom left and right are sliders players can use to adjust their ant’s size, aggressiveness, and the maximum amount of energy, or basically how long ants can walk without eating. Adjusting any of these sliders will change the Create Cost. These sliders can be adjusted at any time during the game to experiment with different settings. Marked 3, in the middle, Ant Adaptation provides a monitor CREATE COST. The CREATE COST monitor shows the total value that it currently costs to produce one more ant. Specifically, the colony produces a new ant when the stored food is greater than the CREATE COST. The cost is calculated by a function of the three sliders.

## THINGS TO NOTICE

The ant colony generally exploits the food sources in order, starting with the food closest to the nest, and finishing with the food most distant from the nest. It is more difficult for the ants to form a stable trail to the more distant food, since the chemical trail has more time to evaporate and diffuse before being reinforced.

Once the colony finishes collecting the closest food, the chemical trail to that food naturally disappears, freeing up ants to help collect the other food sources. The more distant food sources require a larger "critical number" of ants to form a stable trail.

The population of each of the two colonies is shown in the plot.  The line colors in the plot match the colors of the colonies.

Changing a team's AGGRESSIVENESS, or SIZE, changes ant behavior. It also changes the depiction of the ant in the widget marked 8 above.

Notice how proximity of food to the colony affects population growth.

Notice if too much chemical causes problems.

This model operates at two levels, both representing the individual ant, and the colony. This makes it an agent-based model of a super-organism.

## THINGS TO TRY

Try different placements for the food sources. What happens if you put flowers closer to the nests? Farther away? equidistant from the nest? When that happens in the real world, ant colonies typically exploit one source then the other (not at the same time).

Explore where you place chemical trails for ants to follow. What is the most effective placement of chemicals for ants to find food?

How long can your colony survive? How large can you make your colony?

Try different levels of being aggressive and being big. Is one more important than the other for the colony's success?

Try peacefully collecting flowers.

Try starting a fight between colonies.

## EXTENDING THE MODEL

Right now, both colonies respond to the same pheromone for food collection, and fight. Try implementing a separate pheromone (a green chemical). In the real world, ant colonies blend 21 scents to create accents for their colony. This allows them to pass secret messages to colony mates. Try extending to multiple types of pheromone and see how this changes the outcome.

Right now, ants can fight ants from the other team, what happens if ants sometimes fight ants from their own colony?

Change the code so the colonies start in different locations. Does changing the starting proximity affect the model?

Right now there is only one type of ant: forager. Try adding ant castes, such as soldiers.

## NETLOGO FEATURES

This model uses the updated variadic `ifelse` primitive.

The model was originally built for use on a 52-inch touch pad in a museum. If you are interested in using it in this context, please contact kitmartin@u.northwestern.edu and info@ccl.northwestern.edu.

## RELATED MODELS

This model extends the NetLogo Ants (Wilensky, 1997) and is based on Hölldobler and Wilson's The Ants (1990).

Hölldobler, B., & Wilson, E. O. (1990). The Ants. Belknap (Harvard University Press), Cambridge, MA.

## ACKNOWLEDGMENTS

The project gratefully acknowledges the support of the Multidisciplinary Program in Education Sciences for funding the project (Award # R305B090009).

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Martin, K. and Wilensky, U. (2019).  NetLogo Ant Adaptation model.  http://ccl.northwestern.edu/netlogo/models/AntAdaptation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2019 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2019 Cite: Martin, K. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -16777216 true false 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -16777216 true false 78 58 99 116 139 123 137 128 95 119
Polygon -16777216 true false 48 103 90 147 129 147 130 151 86 151
Polygon -16777216 true false 65 224 92 171 134 160 135 164 95 175
Polygon -16777216 true false 235 222 210 170 163 162 161 166 208 174
Polygon -16777216 true false 249 107 211 147 168 147 168 150 213 150

ant-has-food
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -16777216 true false 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -16777216 true false 78 58 99 116 139 123 137 128 95 119
Polygon -16777216 true false 48 103 90 147 129 147 130 151 86 151
Polygon -16777216 true false 65 224 92 171 134 160 135 164 95 175
Polygon -16777216 true false 235 222 210 170 163 162 161 166 208 174
Polygon -16777216 true false 249 107 211 147 168 147 168 150 213 150
Circle -1184463 true false 138 21 23

anthill
false
1
Polygon -6459832 true false 60 225 105 105 135 120 165 120 195 105 240 210 150 225
Polygon -6459832 false false 107 106 135 94 162 93 191 103 165 120 137 123
Polygon -16777216 true false 112 109 134 99 162 98 185 105 162 122 135 122
Line -7500403 false 195 105 195 30
Rectangle -2674135 true true 116 30 191 60
Polygon -2674135 true true 72 191 53 204 69 217 156 217 234 192 228 185 248 190 248 220 48 233 50 205
Polygon -2674135 true true 71 197 57 207 63 216

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bird
true
0
Polygon -955883 true false 135 195 150 165
Circle -11221820 true false 86 86 127
Circle -13791810 true false 195 150 30
Polygon -13345367 true false 210 150 195 150 255 120 225 165 255 165 210 180 225 225 195 180
Circle -13791810 true false 195 150 30
Circle -11221820 true false 90 45 60
Polygon -6459832 true false 135 210 135 240 120 225 135 255 150 210 135 210
Polygon -6459832 true false 150 210 180 255 195 225 180 240 165 210 150 210
Polygon -13791810 true false 90 135 60 120 30 105 45 150 90 165 90 135
Polygon -13791810 true false 195 105 210 60 240 105 210 120 195 105
Polygon -13345367 true false 135 60 150 30 180 75 150 90
Polygon -6459832 true false 120 45 90 30 90 75
Circle -1 true false 105 45 30
Circle -16777216 true false 103 51 18

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

box1
false
0
Rectangle -1 false false 0 45 300 240

box2
false
0
Rectangle -7500403 true true 0 45 300 270
Polygon -7500403 false true 0 60
Polygon -1 true false 0 45 300 45 285 60 0 60
Polygon -16777216 true false 300 45 300 270 285 270 285 60
Polygon -1 true false 0 45 15 45 15 255 0 270

bug
true
0
Circle -7500403 true true 90 206 90
Circle -7500403 true true 120 137 60
Circle -7500403 true true 110 60 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30
Circle -7500403 true true 135 180 30
Line -16777216 false 120 150 75 120
Line -16777216 false 135 165 90 165
Line -16777216 false 135 180 60 195
Line -16777216 false 165 150 210 105
Line -16777216 false 165 165 240 135
Line -16777216 false 165 180 210 210
Line -16777216 false 210 210 225 195

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 124 148 85 105 40 90 15 105 0 150 -5 135 10 180 25 195 70 194 124 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60
Circle -16777216 true false 116 221 67

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

flower-long
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 70 117 38
Circle -7500403 true true 177 70 38
Circle -7500403 true true 70 25 38
Circle -7500403 true true 55 70 38
Circle -7500403 true true 115 10 38
Circle -7500403 true true 81 36 108
Circle -16777216 true false 98 53 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Circle -7500403 true true 160 25 38
Polygon -7500403 true true 120 135 180 240 195 225 180 120 120 135

flower-long2
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 70 117 38
Circle -7500403 true true 70 25 38
Circle -7500403 true true 55 70 38
Circle -7500403 true true 115 10 38
Circle -7500403 true true 81 36 108
Circle -16777216 true false 98 53 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Circle -7500403 true true 160 25 38
Polygon -7500403 true true 120 135 180 240 195 225 180 120 120 135

flower-long3
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 70 117 38
Circle -7500403 true true 70 25 38
Circle -7500403 true true 55 70 38
Circle -7500403 true true 115 10 38
Circle -7500403 true true 81 36 108
Circle -16777216 true false 98 53 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 120 135 180 240 195 225 180 120 120 135

flower-long4
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 70 117 38
Circle -7500403 true true 70 25 38
Circle -7500403 true true 55 70 38
Circle -7500403 true true 81 36 108
Circle -16777216 true false 98 53 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 120 135 180 240 195 225 180 120 120 135

flower-long5
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 70 117 38
Circle -7500403 true true 70 25 38
Circle -7500403 true true 55 70 38
Circle -7500403 true true 81 36 108
Circle -16777216 true false 98 53 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 120 135 180 240 195 225 180 120 120 135

flower-long6
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 70 117 38
Circle -7500403 true true 55 70 38
Circle -7500403 true true 81 36 108
Circle -16777216 true false 98 53 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 120 135 180 240 195 225 180 120 120 135

flower-long7
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 70 117 38
Circle -7500403 true true 81 36 108
Circle -16777216 true false 98 53 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 120 135 180 240 195 225 180 120 120 135

flower-long8
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 81 36 108
Circle -16777216 true false 98 53 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240
Polygon -7500403 true true 120 135 180 240 195 225 180 120 120 135

flower2
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flower3
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flower4
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flower5
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flower6
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flower7
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flower8
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

flying-ant1
true
13
Polygon -2674135 true false 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -2674135 true false 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -2674135 true false 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -16777216 true false 80 254 107 201 149 190 150 194 110 205
Polygon -16777216 true false 235 252 210 200 163 192 161 196 208 204
Polygon -11221820 true false 135 135 75 75 45 75 15 120 30 150 135 165
Polygon -11221820 true false 165 135 225 75 255 75 285 120 270 150 165 165

flying-ant2
true
13
Polygon -2674135 true false 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -2674135 true false 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -2674135 true false 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -16777216 true false 80 254 107 201 149 190 150 194 110 205
Polygon -16777216 true false 235 252 210 200 163 192 161 196 208 204
Polygon -11221820 true false 135 165 75 225 45 225 15 180 30 150 135 135
Polygon -11221820 true false 165 165 225 225 255 225 285 180 270 150 165 135

frog
true
0
Circle -14835848 true false 86 116 127
Circle -14835848 true false 96 66 108
Circle -14835848 true false 108 47 41
Circle -14835848 true false 148 48 41
Circle -1 true false 116 53 24
Circle -1 true false 156 53 24
Circle -16777216 true false 124 64 10
Circle -16777216 true false 163 62 10
Polygon -2674135 true false 129 110 142 118 164 118 174 110
Polygon -1184463 true false 88 165 72 155 59 186 72 207 81 225 57 235 58 252 78 254 98 245 109 228
Polygon -1184463 true false 212 169 228 159 241 190 228 211 219 229 243 239 242 256 222 258 202 249 191 232
Polygon -1184463 true false 125 235 106 251 116 255 134 252 138 231 143 202 142 188 123 191
Polygon -1184463 true false 175 235 194 251 184 255 166 252 162 231 157 202 158 188 177 191

gaster
false
0
Circle -7500403 true true 239 114 56

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

queens
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 124 148 85 105 40 90 15 105 0 150 -5 135 10 180 25 195 70 194 124 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60
Circle -16777216 true false 116 221 67
Polygon -1184463 true false 140 105 117 82 143 95 135 68 148 90 167 64 154 101 188 74 168 108

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

sideant
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -1 true false 59 106 24
Circle -16777216 true false 54 104 20
Circle -1 true false 90 106 24
Circle -16777216 true false 99 102 20
Line -16777216 false 68 137 80 153
Line -16777216 false 79 152 101 153
Line -16777216 false 100 153 112 141

sideant1
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -1 true false 59 106 24
Circle -16777216 true false 54 104 20
Circle -1 true false 90 106 24
Circle -16777216 true false 99 102 20
Line -16777216 false 75 150 80 153
Line -16777216 false 79 152 101 153
Line -16777216 false 100 153 105 150

sideant2
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -1 true false 59 106 24
Circle -16777216 true false 61 109 14
Circle -1 true false 90 106 24
Circle -16777216 true false 98 109 14
Line -16777216 false 79 152 101 153

sideant3
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -1 true false 59 106 24
Circle -16777216 true false 61 109 14
Circle -1 true false 90 106 24
Circle -16777216 true false 98 109 14
Line -16777216 false 79 152 101 153
Line -16777216 false 72 155 81 153
Line -16777216 false 110 157 101 154

sideant4
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -1 true false 59 106 24
Circle -16777216 true false 63 111 10
Circle -1 true false 90 106 24
Circle -16777216 true false 100 111 10
Line -16777216 false 79 152 101 153
Line -16777216 false 72 155 81 153
Line -16777216 false 110 157 101 154
Polygon -1 true false 83 153 80 152 73 158 108 159 99 154

sideant5
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -1 true false 59 106 24
Circle -2674135 true false 63 111 10
Circle -1 true false 90 106 24
Circle -2674135 true false 100 111 10
Line -16777216 false 79 152 101 153
Line -16777216 false 72 155 81 153
Line -16777216 false 110 157 101 154
Polygon -1 true false 83 153 75 180 73 158 108 159 105 180

sideant6
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -1 true false 62 109 18
Circle -2674135 true false 66 114 4
Circle -1 true false 94 110 16
Circle -2674135 true false 98 113 8
Line -16777216 false 79 152 101 153
Line -16777216 false 72 155 81 153
Line -16777216 false 110 157 101 154
Polygon -1 true false 98 142 77 140 67 152 76 167 99 167 107 160
Line -16777216 false 69 155 101 154

sideant7
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -1 true false 62 109 18
Circle -2674135 true false 66 114 4
Circle -1 true false 94 110 16
Circle -2674135 true false 98 113 8
Line -16777216 false 79 152 101 153
Line -16777216 false 72 155 81 153
Line -16777216 false 110 157 101 154
Polygon -1 true false 105 135 75 135 67 152 76 167 99 167 107 160
Line -16777216 false 69 155 101 154
Polygon -16777216 true false 76 152 83 146 97 146 99 155 96 162 79 163

sideant8
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -1 true false 62 109 18
Circle -2674135 true false 66 114 4
Circle -1 true false 94 110 16
Circle -2674135 true false 98 113 8
Line -16777216 false 79 152 101 153
Line -16777216 false 72 155 81 153
Line -16777216 false 110 157 101 154
Polygon -1 true false 104 135 74 135 66 152 75 167 98 167 106 160
Line -16777216 false 69 155 101 154
Polygon -16777216 true false 75 155 77 139 99 139 99 155 96 162 79 163
Polygon -1 true false 75 105 60 90 60 75 75 60 75 75
Polygon -1 true false 105 105 90 90 90 75 105 60 105 75

sideant9
false
0
Circle -7500403 true true 56 101 67
Polygon -7500403 true true 118 140 132 126 193 127 206 144 218 129 231 133 231 148 245 131 245 153 230 161 210 161 202 160 177 168
Circle -7500403 true true 239 114 56
Line -16777216 false 149 141 138 95
Line -16777216 false 141 95 109 226
Line -16777216 false 164 142 173 80
Line -16777216 false 171 80 181 223
Line -16777216 false 192 148 219 82
Line -16777216 false 221 82 233 235
Circle -2674135 true false 62 109 18
Circle -16777216 true false 66 114 4
Circle -2674135 true false 94 110 16
Circle -16777216 true false 98 113 8
Line -16777216 false 79 152 101 153
Line -16777216 false 72 155 81 153
Line -16777216 false 110 157 101 154
Polygon -1 true false 113 131 62 134 66 152 68 172 98 174 111 164
Polygon -16777216 true false 70 153 75 137 99 139 100 156 98 164 79 163
Polygon -1 true false 75 105 60 90 60 75 75 60 75 75
Polygon -1 true false 105 105 90 90 90 75 105 60 105 75

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
