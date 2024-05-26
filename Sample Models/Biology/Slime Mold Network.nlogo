extensions[palette]

breed [nuclei nucleus]
breed [cytoplasm cytoplasmic-fluid]


cytoplasm-own [
  carrying-signal ; Used to modulate signal strength when particle is carrying food
  velocity ; The current velocity of the particle
]

patches-own [
  cp-fluid
  wall?
  food
]

to setup
  clear
  if setup-choice = "single-nucleus" [setup-single-nucleus]
  if setup-choice = "multi-nucleate" [setup-multi-nucleate]
  if setup-choice = "shortest-path" [setup-shortest-path shortest-path-parameters]
end


; These parameters are default because they offer a balance between performance and demonstrating the model's capabilities
to default-parameters
  set max-fluid-particles 10000
  set total-fluid-volume 50
  set diffusion-proportion 0.5
  set food-signal-boost 20
  set eat-proportion 0
  set signal-lifetime 50
  set fluid-turbulence 10
  set movement-speed 100
end


; These parameters differ to exaggerate the effect of food on the network,
; so that they may demonstrate the shortest-path finding ability in the shortest-path demo
to shortest-path-parameters
  set max-fluid-particles 3000
  set total-fluid-volume 25
  set diffusion-proportion 0.5
  set food-signal-boost 50
  set eat-proportion 0
  set signal-lifetime 100
  set fluid-turbulence 5
  set movement-speed 100
end


; resets the world state
to clear
  clear-all

  ; Initializing patch values
  ask patches [
    set wall? false
    set food 0
  ]

  reset-ticks
end



; A setup with a single nucleus in the middle; DEFAULT
to setup-single-nucleus
  create-nuclei 1 [
      set shape "circle"
      set size 5
      set color white
      setxy 0 0
    ]
  tick
end


; A slightly more elaborate setup that demonstrates the multi-nucleate
; nature of the network, as well as how it interacts with food
to setup-multi-nucleate
  create-nuclei 1 [
      set shape "circle"
      set size 5
      set color white
      setxy -30 0
    ]

  create-nuclei 1 [
      set shape "circle"
      set size 5
      set color white
      setxy 30 0
    ]

  draw-selection -5 -5 10 10 "food"

  tick
end



; A setup designed to demonstrate the ability of the network
; to find the shortest path length between food sources
to setup-shortest-path

  ; Creating the walled environment
  draw-box -50 -50 100 100 3
  draw-line -40 -17 80 57 "h"
  draw-line -38 -50 76 12 "h"

  draw-line -50 -50 20 12 "v"
  draw-line -40 -20 20 2 "v"

  draw-line 38 -50 20 12 "v"
  draw-line 38 -20 20 2 "v"

  draw-line -35 -26 70 2 "h"

  draw-line -35 -34 8 2 "v"
  draw-line -25 -34 8 2 "v"
  draw-line -15 -34 8 2 "v"
  draw-line 33 -34 8 2 "v"
  draw-line 23 -34 8 2 "v"
  draw-line 13 -34 8 2 "v"

  draw-line -30 -38 8 2 "v"
  draw-line -20 -38 8 2 "v"
  draw-line 28 -38 8 2 "v"
  draw-line 18 -38 8 2 "v"

  draw-line -14 -30 27 4 "h"
  draw-line -9 -38 19 4 "h"


  ; Placing food at path ends
  draw-selection -44 -26 6 2 "food"
  draw-selection 38 -26 6 2 "food"

  ; Placing a nucleus at the top
  create-nuclei 1 [
    set shape "circle"
    set size 5
    set color white
    setxy 0 43
  ]

end


to draw

  ; Handles the user draw function that allows for creation of
  ; the custom environment

  ; These should be drawn continuously
  if draw-choice = "Wall" [draw-wall]
  if draw-choice = "Food" [place-food]

  ; We only want one nucleus per click
  if draw-choice = "Nucleus" [
    let clicked? false
    while [mouse-down?] [
      if not clicked? [
        place-nucleus
        set clicked? true
      ]
    ]
  ]
end


;; ----- GO PROCEDURES -----



to go
  spawn-cytoplasm
  disperse-fluid
  move
  update-colors
  tick
end




to spawn-cytoplasm

  ; Handles spawning behavior for cytoplasmic fluid particles

  ; Variable initialization
  ; For each tick, calculate how many fluid agents remain unspawned
  let remaining max-fluid-particles - count cytoplasm
  let proportion 0.01  ; arbitrary value; how quickly fluid agents will spawn
  let spawn-count round(remaining * proportion)

  ; If the spawn-count is rounded to zero but remaining is greater than zero,
  ; we ensure that at least one particle will spawn
  if remaining > 0 [set spawn-count spawn-count + 1]

  ; Controls how cytoplasm fluid particles spawn relative to nuclei
  ask nuclei [
    if spawn-count > 0 [
      hatch-cytoplasm spawn-count [
        set velocity 1
        set carrying-signal 0
        rt random 360
        fd random 3
        hide-turtle
      ]
    ]
  ]
end


to disperse-fluid

  ; Controls the dispersion of fluid into the network

  ; Variable initialization
  ; Determine strength of signaling molecule from nutritive fluid
  ; Determine a rate of fluid decay for each patch based on the
  ; total allowable volume of fluid per agent
  let signal-boost food-signal-boost / 100
  let decay-rate (100 - total-fluid-volume) / 1000
  let max-cp max [cp-fluid] of patches
  if max-cp = 0 [set max-cp 0.1] ; avoids initial division by zero

  ; Nuclei need to emit fluid of their own to solidify their place in the network.
  ask nuclei [
    ask patches in-radius 3 [
      set cp-fluid 1
    ]
  ]

  ; Fluid particles need to distribute fluid. Value is modulated according
  ; to presence of signaling molecule (response to nutritive fluid)
  ask cytoplasm [
    if-else carrying-signal > 0 [
      set cp-fluid 1 + (signal-boost * (carrying-signal / signal-lifetime))
    ] [
      ; Rather than setting the patch fluid value to 1, we need to ensure that we only ever RAISE it to 1.
      ; This implementation ensures a non-food carrying fluid particle never sets the fluid concentration of a patch to a value
      ; LOWER than what it currently is. This also ensures that if two fluid particles occupy the same patch and only one is
      ; carrying a food signal, the patch will always receive the higher fluid concentration as is expected.
      if cp-fluid < 1 [set cp-fluid 1]
    ]
  ]

  ; Fluid spreads out over time. Altering this value will change how
  ; tightly the walls of each tube are defined.
  diffuse cp-fluid diffusion-proportion

  ; The cytoplasmic fluid that each agent represents needs to follow
  ; them over time, trails must decay over time.
  ask patches [
    if cp-fluid > decay-rate [

      ; The rate of fluid decay must be graded relative to the maximum fluid concentration in order
      ; to give network structures some staying power. This is an attempt, albeit a very basic one,
      ; to implement the cytoskeletal tube structures of real physarum polycephalum. Without this gradation
      ; in decay rate, network structures become wildly dynamic and quite sparse, as no structure that forms
      ; has anything 'holding' it in place. This is a weak mechanism that grants highly established network
      ; structures (those with the most fluid agents constantly occupying them) some permanence within the
      ; plasmodic network.
      set cp-fluid cp-fluid - (decay-rate * (1 - cp-fluid / max-cp))
    ]
  ]

  ; Remove any fluid that seeps into walls, or was present beforehand
  ask patches with [wall?] [
    set cp-fluid 0
  ]
end


to move

  ; Handles movement of the cytoplasmic fluid particles

  ; Cytoplasmic-fluid agent control flow
  ask cytoplasm [

    ; The following can occur if the user draws over existing agents with a wall
    if wall? = true [die]

    ; Eat if we can eat
    if food > 0 [eat]

    ; Propagate food signals to other fluid agents
    propagate-signal

    ; Fluid agents only 'look' ahead in the sense that fluid flows along
    ; tubes that have already formed, far less frequently straying to create
    ; new tubes. The likelihood of agents straying to create new tubes
    ; is dictated by the wobble value.
    let r patch-right-and-ahead 45 1
    let l patch-left-and-ahead 45 1
    let f patch-ahead 1

    ; Checking if the forward patch is a wall
    if-else ([wall?] of f) [
      ; We actively turn away from / avoid walls; mold can not grow there.
      ; This may be interpreted as the fluid 'bouncing' off of the wall upon impact
      rt 180
      wobble fluid-turbulence
    ]
    [
      ; In all other cases, we move in the direction of the tube
      ; (in this case, the direction in front of us with the highest fluid concentration)
      let xset (patch-set l r f)
      face max-one-of xset [cp-fluid]

      ; Random fluid turbulence
      wobble fluid-turbulence
    ]

    ; Fluid velocity is proportional to the strength / size of the tube.
    ; larger tubes are represented by higher fluid concentrations
    set velocity cp-fluid * (movement-speed / 100)
    fd velocity
  ]
end


to propagate-signal
  ; Agents that are carrying molecular signal must spread that signal to other agents
  if carrying-signal > 0 [

    ; The signal received by other turtles should be the maximum between what
    ; they currently have and what they are passing by. Turtles with higher signal
    ; values should not inherit lower ones
    let spread carrying-signal

    ask other cytoplasm-here [

      ; Transmission of the signal must also reduce its strength,
      ; as the molecule must travel some additional distance to reach the target of transmission.

      ; This does not violate conservation of matter; the fluid particle should not be conceived of as inheriting
      ; some quantity of matter, but rather something akin to being tagged by a trace chemical agent
      ; with a very specific lifetime / half life.
      set carrying-signal max (list carrying-signal (spread - 1))
    ]

    ; Signal lifetime must decrement once per tick.
    ; The molecular signal strength is inversely proportional its
    ; current distance travelled from its own point of origin (where the food is)
    set carrying-signal carrying-signal - 1
  ]
end


to eat

  ; This functions controls the eating behavior of fluid agents

  ; Remove food from the patch
  set food food - eat-proportion

  ; Fluid is now carrying the molecular signal
  set carrying-signal signal-lifetime
end



to wobble [x]
  ; This function controls the random movements of the fluid agents
  rt random x
  lt random x
end




to update-colors

  ; Mold networks can be visualized 'realistically' or
  ; proportional to the local velocities.

  if-else visualize-velocity? [

  ; real-time visualization of the varying velocities of
  ; cytoplasmic fluid particles within the network. Color is representative
  ; of the maximal fluid particle velocity for a given patch

    if any? cytoplasm [
      let highest max [velocity] of cytoplasm
      ask patches [
        let x max-one-of cytoplasm-here [velocity]
        if-else x != nobody [
          let v ([velocity] of x) / highest
          set pcolor palette:scale-gradient [[0 255 25] [255 255 0] [255 0 0]] v 0.7 1
        ]
        [
          set pcolor black
        ]
      ]
    ]
  ]


  ; 'realistic' representation of the slime-mold
  [
    ask patches
    [
      let signal-boost food-signal-boost / 100
      if-else cp-fluid <= 1 [
        ; Gradient represents the strength of the tube / fluid concentration
        set pcolor palette:scale-gradient [[0 0 0] [255 255 255]] cp-fluid 0 1
      ]
      [
        ; Identify fluid carrying the signaling molecule
        if-else visualize-signaling-molecule?
        [set pcolor yellow]
        [set pcolor white]
      ]
    ]
  ]

  ; In either visualization case, we want to render both food
  ; and walls individually.
  ask patches [
    if food > 0 [set pcolor yellow]
    if wall? = true [set pcolor red]
  ]
end

to draw-wall

  ; This function allows the user to draw walls
  ; that the mold will be forced to avoid

  while [mouse-down?] [
    ask patch mouse-xcor mouse-ycor [
      ask patches in-radius brush-size [
        if-else eraser
        [set wall? false]
        [set wall? true]
      ]
    ]
    update-colors
    tick
  ]
end

to place-nucleus

  ; This allows the user to place mold nuclei. P. Polycephalum are
  ; multi-nucleate organisms, so multiple nuclei can exist simultaneously

  if mouse-down? [
    create-nuclei 1 [
      set shape "circle"
      set size 5
      set color white
      setxy mouse-xcor mouse-ycor
    ]
    tick
  ]
end

to place-food

  ; Allows the user to place nutritive fluid that stimulates the
  ; mold network, acting as a source of the signaling molecule that
  ; the mold will respond to.

  while [mouse-down?] [
    ask patch mouse-xcor mouse-ycor [
      ask patches in-radius brush-size [
        if-else eraser
        [set food 0]
        [set food 1]
      ]
    ]
    update-colors
    tick
  ]
end




;; ----- PROCEDURES FOR DRAWING WALLS -----

; draws a box wall formation
to draw-box [x y width height thick]

  ; horizontal components
  draw-line x y width thick "h"
  draw-line x (y + height - thick) width thick "h"

  ; vertical components
  draw-line x y height thick "v"
  draw-line (x + width - thick) y height thick "v"


end


; given an orientation "h" or "v" draws a line
to draw-line [x y len thick orientation]
  if orientation = "v" [
    draw-vertical-line x y len thick
    stop
  ]

  if orientation = "h" [
    draw-horizontal-line x y len thick
    stop
  ]

end


; draws a horizontal line
to draw-horizontal-line [x y len thick]
  draw-selection x y len thick "wall"
end

; draws a vertical line
to draw-vertical-line [x y len thick]
  draw-selection x y thick len "wall"
end


; fills a rectangular patch selection with either wall or food
to draw-selection [x y width height wall-or-food]

  let selected (select-rectangle x y width height)

  if-else wall-or-food = "food"
  [foreach selected [p -> ask p [set food 1]]]
  [foreach selected [p -> ask p [set wall? true]]]

  update-colors
  tick

end


; Given a starting coordinate and dimensions, returns a patch-set corresponding to that area
; ** Coordinate starts at bottom left of the selection **
to-report select-rectangle [x y width height]

  ; Initialization
  let selected []
  let x-counter 0
  let y-counter 0

  ; Double loop to grab all values in a rectangular area
  while [x-counter < width] [
    set y-counter 0
    while [y-counter < height] [
      set selected lput (patch (x + x-counter) (y + y-counter)) selected
      set y-counter y-counter + 1
    ]
    set x-counter x-counter + 1
  ]

  report selected

end


; Copyright 2021 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
210
10
821
622
-1
-1
3.0
1
10
1
1
1
0
1
1
1
-100
100
-100
100
1
1
1
ticks
30.0

SLIDER
33
80
205
113
max-fluid-particles
max-fluid-particles
0
30000
10000.0
1
1
NIL
HORIZONTAL

BUTTON
840
67
903
100
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
904
67
967
100
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
33
113
205
146
total-fluid-volume
total-fluid-volume
0
99
50.0
1
1
%
HORIZONTAL

SLIDER
33
146
205
179
diffusion-proportion
diffusion-proportion
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
933
151
1025
184
brush-size
brush-size
0
5
5.0
1
1
NIL
HORIZONTAL

SWITCH
933
185
1025
218
eraser
eraser
1
1
-1000

SLIDER
33
209
205
242
food-signal-boost
food-signal-boost
0
100
20.0
0.1
1
%
HORIZONTAL

BUTTON
840
407
1023
440
Remove-Slime-Mold
clear-turtles
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
840
441
1023
474
Remove Cytoplasmic Fluid
ask turtles with [breed = cytoplasm] [die]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
840
475
1023
520
Cytoplasmic Fluid Particles
count turtles with [breed = cytoplasm]
17
1
11

SLIDER
33
243
205
276
eat-proportion
eat-proportion
0.00
1
0.0
0.01
1
NIL
HORIZONTAL

MONITOR
840
521
1023
566
Food Particles in the Network
count cytoplasm with [carrying-signal > 0]
17
1
11

SLIDER
33
337
205
370
fluid-turbulence
fluid-turbulence
0
25
10.0
1
1
NIL
HORIZONTAL

SLIDER
33
370
205
403
movement-speed
movement-speed
1
100
100.0
0.1
1
%
HORIZONTAL

SWITCH
840
339
1023
372
visualize-velocity?
visualize-velocity?
1
1
-1000

CHOOSER
840
185
932
230
draw-choice
draw-choice
"Wall" "Food" "Nucleus"
2

BUTTON
840
151
932
184
NIL
draw
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
33
277
205
310
signal-lifetime
signal-lifetime
1
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
36
322
186
340
Fluid Movement
12
0.0
1

TEXTBOX
36
194
186
212
Nutritive Stimuli
12
0.0
1

TEXTBOX
34
65
223
83
Fluid Volume / Tube Strength
12
0.0
1

TEXTBOX
45
34
204
68
MODEL PARAMETERS
14
0.0
1

SWITCH
840
373
1023
406
visualize-signaling-molecule?
visualize-signaling-molecule?
1
1
-1000

CHOOSER
840
102
967
147
setup-choice
setup-choice
"single-nucleus" "multi-nucleate" "shortest-path" "clear"
1

BUTTON
50
419
188
452
Reset Parameters
default-parameters
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
846
33
1032
67
ENVIRONMENT CONTROL
14
0.0
1

TEXTBOX
854
307
1049
325
VISUALIZATION TOOLS
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model emulates the growth and reaction to nutritive stimuli of Physarum Polycephalum, an acellular multi-nucleate amoeba more commonly referred to as a slime-mold. Their growth is modulated by varying velocities of cytoplasmic fluid found within the reticluted tubes that they develop in order to explore their environment. When the slime-mold finds food, it releases a molecular signaling agent that dilates the tubes, increasing fluid velocity and flow to that region. The changing fluid velocities found within the network change how it grows and retracts over time.

## HOW PHYSARUM POLYCEPHALUM WORKS

Physarum Polycephalum explores its environment by expanding a network of reticulated tubes. These tubes contain an actin-mytosin cytoskeleton outer layer, which periodically contracts in a peristaltic wave-motion across the network to propel cytoplasmic fluid housed inside. These tube networks provide the organism with a food transport network. (Alim).

P. Polycephalum uses these basic mechanisms to demonstrate complex behavior, such as navigating mazes to find the shortest route between food sources, and using said path-finding ability to reconstruct transportation maps of different cities (Alim).

Large cities typically aim to optimize public transportation routes by reducing path length between stations, saving the city money and the passengers their time. The ability to recreate these public transport maps when given the station locations, then, should be indicative of some kind of path finding ability. When food is laid out on a flat surface with the same relative positions as the public transport stations in downtown Tokyo, Physarum Polycephalum is able to construct a plasmodic network with strongest paths that are remarkably similar in shape and structure to the actual transportation maps, indicating that it has found optimized path lengths (Alim).

## HOW THIS MODEL WORKS

Nucleus agents are responsible for spawning fluid agents, and act as the starting point of a plasmodic network.
At every tick, each nucleus agent will perform the following actions in order:

 - Determine the difference between the maximum number of fluid particles and the current number
 - Calculate some integer value of fluid particles to spawn based on a proportion of the previous value
 - Spawn that many fluid particles in its close vicinity
 - Set the amount of fluid in their current patches to 1

Fluid agents represent the cytoplasmic fluid found within the cytoskeletal tubes of the network. They have properties that correspond to the strength of the chemical signal that is released when they find food, as well as their current velocity.
At every tick, each fluid agent will perform the following actions in order:

 - Set the amount of fluid in their current patch to 1, or more than 1 if carrying a food signal. The extra amount is modulated by the food-signal-boost parameter.
 - If they currently inhabit a patch that contains a wall, die
 - If they currently inhabit a patch that contains food, they will remove some proportion of food from the current patch determined by the eat-proportion parameter, and gain a food signal value determined by the signal-lifetime parameter.
 - If carrying a food signal, other fluid agents that occupy the same patch in this tick will receive a food signal of the same value minus one. If another fluid agent in the same patch is carrying a food signal with a higher value, they will not inherit the food signal of lower value.
 - Determine the fluid concentrations (patch fluid value) of 3 patches in front of them. These patches are always a distance of 1 patch away, and are measured 45 degrees to the left of, directly in front of, and 45 degrees to the right of the agent.
 - If a wall is ahead, immediately turn 180 degrees
 - Otherwise, determine the heading with the highest fluid concentration (the max of the 3 patches measured earlier), and aim in the direction of the new heading
 - Apply a random rotation, where the upper bound of the random rotation value is determined by the fluid-turbulence parameter
 - Move 1 unit in the direction of the newly determined heading
 - If carrying a food signal, the value of the signal is decremented by 1

Patches in this model have properties corresponding to whether or not they represent a wall, as well as how much food they contain. Wall patches are represented in bright red, and patches with any non-zero amount of food are represented in bright yellow. Patches also have a property corresponding to their fluid concentration, which is represented by a black to white gradient where pure white is the highest fluid concentration.
At every tick, each patch will perform the following actions in order:

 - Diffuse some portion of its own fluid to the 8 patches immediately adjacent to itself. The total amount dispersed is less than the amount lost by the patch, such that the diffusion of fluid causes a loss in total fluid volume of the system.
 - If occupied by a fluid agent AND contains food, remove some proportion of the food from itself determined by the eat-proportion parameter
 - If it contains a wall, set the fluid concentration to 0, and kill any agents inside

## SIMPLIFYING ASSUMPTIONS AND LIMITATIONS

This model begins with the nuclei agents, which essentially act as cytoplasmic fluid generators. This is to some extent true in real life as well---the nuclei of P. Polycephalum act as its 'body', and cutting off or removing branches would not kill the organism. Fluid agents are spawned from these nuclei, and will begin branching out because of the innate randomness in their movements.

The model makes several simplifying assumptions in order to emulate the behavior of P. Polycephalum. First, agents are not simply representative of a single fluid particle, but rather a volume of fluid that is specified in the model parameters. When the user determines a value for the total volume of fluid that an agent can represent, under the hood they are actually changing the rate of fluid removal from the system at each location. When lower fluid volumes are allowed per agent, the fluid is removed more rapidly.

Second, agents (cytoplasmic fluid) are not walled off from the outside world in the way they would be in the real slime-mold due the reticulated tubes, but the way their movement is programmed allows them to act as such. When each fluid particle is asked to move, they first determine the direction of greatest fluid concentration ahead of them within a ~90 degree cone, and then move in that direction. This allows the fluid particles to flow in directions where fluid already exists and flows strongly, which emulates the behavior of a tube that would instead physically restrict fluid movement. However, this behavior allows already existing 'tubes' to branch off far more easily than their real life counterpart, as no physical barriers exist to prevent them from doing so. Consequently, simulated P. Polycephalum in this model is far more dynamic than its real life counterpart, and will change its structure in ways that real P. Polycephalum can not, such as merging branches or circular paths.

The mechanism by which agents escape existing branches to create new ones is modeled by 'fluid turbulence', which is essentially a degree of random movement that is added to the movement behavior previously described. In adding this degree of random movement, fluid particles are enabled to create new branches provided their new randomly determined heading is in a new direction. Set this value to 0 to understand why it is necessary for proper network formation. In real physarum polycephalum, the exact mechanism by which new branches are formed and how the location of their formation is determined is not precisely understood, but it's likely that similarly random mechanisms are involved to some extent. One other thing this model misses is that the degree to which branches explore new paths is modulated by the fluid velocity found within that branch, such that bigger, stronger branches (near food) will be more exploratory and resource-intensive than their non-food-finding counterparts.

Real Physarum Polycephalum reacts to a nutritive stimulus by sending a signaling molecule out from the point of contact, that both strengthens the peristaltic contraction of the local wall, and induces the release of the signaling molecule elsewhere in the network, albeit at a lower rate. The result is that tubes near food sources are strengthened, and because the amount of fluid in the network is constant (or at least not nearly as dynamic as its structure), the tubes that fail to find food or that are far away from food sources are dramatically weakened or even disappear. Because the fluid in this simulation all moves in parallel rather than through a peristaltic motion, the presence of the signaling molecule must instead modulate fluid velocity directly (we can not change the strength of the peristaltic contraction if no walls exist to contract). When a fluid particle is carrying a food signaling chemical, it is also more attractive to its neighbors in determining their direction of motion. The strength of this relationship is modulated by the 'food-signal-bonus' parameter, and different values will have wildly different outcomes depending on the values of the other model parameters. Because the chemical signal carried by the fluid must weaken over time, it decrements at every tick and at every transmission to other fluid particles.

## VISUALIZATION

Because of the inherent relationship between the strength of a tube and the velocity of the fluid found within, it should prove useful to visualize both of these dimensions of the network independently. The default view of the network is much closer to its real life counterpart, and will show the network's fluid concentration at each location. Be careful however---tube size does not always correlate with 'strength', or velocity.

By switching on visualize-velocity?, one can directly see the velocity of fluid agents in the network via color coding. Particles moving quickly are represented in red, while particles moving slowly are represented in green, with intermediate values being represented by shades in between.

## HOW TO USE IT

To begin, press the SETUP button which will initialize the world-state. This button can be pressed again at any time to reset everything in the environment. To create the environment, use the DRAW button to place P. Polycephalum nuclei, walls, and food. Four distinct setup environments exist to demonstrate different aspects of the model:

 - Single-nucleus (default): A world with a single nucleus in the middle
 - Multi-nucleate: A world with 2 nuclei on either side of a patch of food
 - Shortest-path: A world that demonstrates the ability of P Polycephalum to select the shortest-path
 - Clear: A completely blank world state

The BRUSH-SIZE slider can be used to adjust the size of the brush used to paint walls and food, and the eraser can be used to clean up mistakes or precisely refine the environment. Once the environment is ready, the GO button can be pressed to run the model. The model can be paused at any time by pressing the GO button again. The DRAW function maintains full functionality while the model is being simulated.

If at any time the user can't find their way back to sensible model parameters, the RESET-PARAMETERS button can be used to revert the model to default parameter values.

MAX-FLUID-PARTICLES: The maximum number of fluid particles that are to be simulated at any one time. The more particles there are, the larger the networks will become. Because the environment wraps, more particles beyond a certain point will produce a more robust network, rather than a larger one.

TOTAL-FLUID-VOLUME: This variable dictates the static amount of fluid any one particle is responsible for representing in a given moment. The higher this value, the more fluid is represented by a single fluid-particle. Fluid volume per particle is modulated by changing the rate at which fluid decays from each patch.

DIFFUSION-PROPORTION: This value controls the strength of the definition of the reticulated tube network. The higher the value, the more rigidly each tube is defined, and the more structured the network is likely to become. One may also conceptualize this as how 'zoomed in' one is in viewing the network.

FOOD-SIGNAL-BOOST: This is the mechanism currently implemented for how food motivates behavioral changes within the mold. The higher this value, the more attractive signal-carrying fluid flows are. Contact with any nutritive stimulus induces the release of a signaling molecule that spreads throughout the network, disproportionately affecting shorter tubes. Because the total fluid volume of the network is limited, diversion of fluid to these tubes causes atrophy of tubes elsewhere in the network.

EAT-PROPORTION: The proportion of food that gets carried away by a fluid particle when contacted. A value of 1 means that all food present at that patch gets carried by a single fluid particle when contact is made. A value of 0 creates a permanent nutritive stimulus at the target location. This can also be conceptualized as the viscosity of the nutritive substance, where values of 1 represent a highly mobile fluid and 0 represents a solid object.

Note that an EAT-PROPORTION of 0 will be appropriate most of the time, as real Physarum Polycephalum takes a very long time to absorb and digest food that it finds. The network needs time to adapt and grow properly around the stimulus, so removing it too quickly will result in little or no change. The highly dynamic nature of the network also lends itself to quickly returning to its previous structure once the nutritive stimulus is no longer present, so the effects are transient as long as the presence of the food is transient as well. Most food sources presented in the literature are also solids (grains or oats, for example).

FLUID-TURBULENCE: The amount of random variance in fluid particle movement within the tubes. Lower values will lead to more rigid structures. Higher values will lead to more tube branches within the network.

MOVEMENT-SPEED: Controls the maximum possible fluid velocity in the network. Lowering this value from 100% tends to make networks less complex and less reactive.

SETUP: clears the model visualization, resets all patch values to baseline, kills all agents

G0: runs the model

DRAW: Allows the user to draw or place the element currently selected by draw-choice. This allows the user to create custom environments to test different behaviors of the model

 - Wall: Places a wall while the mouse is held. The slime mold can not penetrate this wall, and actively avoids contact. Use this to constrain the movement of fluid particles and guide network formation
 - Food: Places a food of size brush-size at the mouse location. Food induces release of the signaling molecule.
 - Nucleus: places a single slime-mold nucleus

BRUSH-SIZE: Controls the size of the brush used to draw walls and food

ERASER: When on, switch to eraser mode. This will allow the user to erase walls and food rather than drawing them.

VISUALIZE-VELOCITY?: When on, switch visualization modes to visualize the velocity of fluid particles within the network, rather than total fluid. All particles become colored according to their velocity, where red represents the highest velocity particles in the network, and green the lowest. Velocity values are normalized to the interval [0, 1]  (with the highest and lowest velocity particles representing 1 and 0, respectively), which are then mapped to a green-red color gradient.

VISUALIZE-SIGNALING-MOLECULE?: When enabled, displays where in the plasmodic network food signal is being propagated. Because the signaling molecule produces signal strengths above what is normally possible, patches in which the signaling molecule is present are easy to identify by checking if they pass that threshold. All patches that exceed the threshold of what is normally possible are colored yellow in this visualization.

REMOVE-SLIME-MOLD: Kills all slime mold agents. Allows the user to 'reset' while preserving the custom environment.

REMOVE CYTOPLASMIC FLUID: Removes all cytoplasmic fluid (spares nuclei). Useful for preserving exact network / model setup when testing network formation from scratch with different model parameters.

## THINGS TO NOTICE

Notice how the strength of any given tube (its size) is proportional to its velocity. Switching between visualization modes is a great way to get an intuitive understanding of this mechanism. Notice how the weaker fringes of the network will appear green, and hot spots will appear red. In the standard visualization, these velocity differences will be reflected in the size of the respective tubes.

When placing nutritive stimuli (especially permanent stimuli with eat-proportion = 0), notice how the network will adapt to be significantly more developed around the area of the food source, both in the strength of the tubes surrounding the food and the number of branching paths. Use VISUALIZE-SIGNALLING-MOLECULE? to gain more precise intuitions about how this works.

## THINGS TO TRY

In order to best visualize path selection mechanisms, try to create environments in which paths have varying lengths. Remember that this is a process that occurs between food stimuli, rather than between food stimuli and nuclei.

One can visualize vastly different types of networks by changing the total fluid volume and diffusion proportion. Decreasing diffusion proportion will make tube edges harder, and increase the number of branching paths, while increasing it will make the network sparse.

All networks are highly reactive to changes in the food-signal-boost. There exists a very precise critical interval for any given set of model parameters (specifically with regard to fluid volume / diffusion) between which the behavior of the network in response to food changes dramatically. See if you can find this interval for a given set of model parameters, and watch how path formation differs across the input space for this parameter.

## EXTENSIONS

This model has fluid agents 'look ahead' only a single patch in order to determine their new heading. What would happen if this look-ahead distance was changed to 2 patches, or 3? What changes about the type of structures that are formed? Do any new patterns emerge? Does some consistent relationship exist between changes in the look ahead distance and consequent changes in network structure formation?

Right now agents can only move in one of 3 directions. What happens if agents are given more precision in the determination of their heading at each tick? What if, for example, probes for fluid concentration were not placed every 45 degrees within a 90 degree cone, but every 15 degrees within a 120 degree cone? What changes about their movement patterns?

## CREDITS AND REFERENCES

Jones, J. (2010). Characteristics of pattern formation and evolution in approximations of physarum transport networks. Artificial Life, 16(2), 127-153. https://doi.org/10.1162/artl.2010.16.2.16202

Karen Alim, Natalie Andrew, Anne Pringle, Michael P. Brenner. (2017). Mechanism of signal propagation in P. polycephalum. Proceedings of the National Academy of Sciences May 2017, 114 (20) 5136-5141; DOI: 10.1073/pnas.1618114114

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Heidacker, N. and Wilensky, U. (2021).  NetLogo Slime Mold Network model.  http://ccl.northwestern.edu/netlogo/models/SlimeMoldNetwork.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

This model was developed as part of the Spring 2021 Multi-agent Modeling course offered by Dr. Uri Wilensky at Northwestern University. For more info, visit http://ccl.northwestern.edu/courses/mam/. Special thanks to Teaching Assistants Jacob Kelter, Leif Rasmussen, and Connor Bain.

## COPYRIGHT AND LICENSE

Copyright 2021 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2021 MAM2021 Cite: Heidacker, N. -->
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
0
@#$#@#$#@
