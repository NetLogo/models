; Tower Defense Simulation
; A strategic defense game where players must protect against zombie waves
; using different types of towers with unique abilities and characteristics

; Define the three main agent types in our simulation
breed [towers tower]      ; Defensive structures that shoot at enemies
breed [enemies enemy]     ; Hostile zombies that attack towers
breed [projectiles projectile]  ; Bullets/missiles fired by towers

; Properties that each tower agent possesses
towers-own [
  tower-type        ; Tower classification: "basic", "sniper", "rapid", "splash"
  fire-rate         ; Ticks between shots (lower = faster firing)
  damage            ; Damage dealt per projectile
  range-distance    ; Maximum shooting range in patches
  cooldown          ; Current time remaining before next shot
  health            ; Current hit points (decreases when attacked)
  max-health        ; Maximum hit points (used for health percentage)
  under-attack?     ; Boolean flag indicating if tower is being attacked this tick
]

; Properties that each enemy (zombie) agent possesses
enemies-own [
  health            ; Current hit points (decreases when shot)
  max-health        ; Starting hit points (used for health percentage)
  speed             ; Movement speed per tick (higher = faster)
  attack-damage     ; Damage dealt to towers when attacking
  attack-cooldown   ; Ticks remaining before next attack
  target-tower      ; Reference to the tower this enemy is moving toward
]

; Properties that each projectile agent possesses
projectiles-own [
  target-enemy      ; Reference to the enemy this projectile is tracking
  projectile-damage ; Damage this projectile will deal on impact
  projectile-type   ; Type of projectile (inherited from firing tower)
]

; Global variables that track game state and statistics
globals [
  spawn-timer        ; Counter for enemy spawning timing
  enemies-spawned    ; Total number of enemies created
  enemies-killed     ; Total number of enemies destroyed
  towers-destroyed   ; Total number of towers lost
  game-time          ; Current simulation time in ticks
  max-game-time      ; Maximum simulation duration
  game-over?         ; Boolean flag indicating if game has ended
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Main setup procedure - initializes the entire simulation
to setup
  clear-all  ; Remove all agents and reset the world
  
  ; Initialize all global game state variables
  set spawn-timer 0              ; Reset enemy spawn counter
  set enemies-spawned 0          ; Reset enemy statistics
  set enemies-killed 0           ; Reset kill count
  set towers-destroyed 0         ; Reset tower loss count
  set game-time 0                ; Reset simulation timer
  set max-game-time simulation-duration  ; Set game duration from slider
  set game-over? false           ; Game is not over yet
  
  ; Create the battlefield environment
  setup-terrain
  
  ; Randomly distribute defensive towers across the map
  place-towers
  
  reset-ticks  ; Initialize the tick counter
end

; Creates the battlefield environment
to setup-terrain
  ; Set all patches to a light green color to represent an open battlefield
  ; The +2 makes it slightly brighter than standard green
  ask patches [ set pcolor green + 2 ]
end

; Places defensive towers across the battlefield with proper spacing
to place-towers
  ; Define the four available tower types
  let tower-types ["basic" "sniper" "rapid" "splash"]
  
  ; Create the specified number of towers (controlled by num-towers slider)
  repeat num-towers [
    ; Find a suitable location for the tower with these constraints:
    ; 1. Not too close to existing towers (minimum tower-spacing patch radius)
    ; 2. Not at the map edges (5 patch buffer from all edges)
    let valid-patch one-of patches with [
      ; When no towers exist yet, any interior patch is fine
      (count towers = 0 or (min [distance myself] of towers) >= tower-spacing) and
      pxcor > min-pxcor + 5 and pxcor < max-pxcor - 5 and
      pycor > min-pycor + 5 and pycor < max-pycor - 5
    ]
    
    ; If we found a valid spot, create the tower there
    if valid-patch != nobody [
      ask valid-patch [
        sprout-towers 1 [
          ; Randomly select one of the four tower types
          set tower-type one-of tower-types
          
          ; Configure the tower's properties based on its type
          setup-tower-properties
          
          ; Initialize tower state
          set cooldown 0    ; Ready to fire immediately
          set size 2        ; Standard tower size
        ]
      ]
    ]
  ]
end

; Configures tower properties based on the tower type
to setup-tower-properties
  ; All towers start with full health and are not under attack
  set max-health 100        ; Maximum hit points for all towers
  set health max-health     ; Start at full health
  set under-attack? false   ; Not currently being attacked
  
  ; Configure Basic Tower - balanced all-around defender
  if tower-type = "basic" [
    set color blue           ; Blue color for identification
    set fire-rate 30        ; Moderate firing speed (30 ticks between shots)
    set damage 15           ; Moderate damage per shot
    set range-distance 6    ; Medium shooting range
    set shape "circle"      ; Simple circle shape
  ]
  
  ; Configure Sniper Tower - long range, high damage, slow firing
  if tower-type = "sniper" [
    set color red            ; Red color for identification
    set fire-rate 50        ; Slow firing speed (50 ticks between shots)
    set damage 35           ; High damage per shot
    set range-distance 10   ; Long shooting range
    set shape "house"       ; House shape for fortified appearance
  ]
  
  ; Configure Rapid Tower - fast firing, short range, low damage
  if tower-type = "rapid" [
    set color yellow         ; Yellow color for identification
    set fire-rate 15        ; Fast firing speed (15 ticks between shots)
    set damage 8            ; Low damage per shot
    set range-distance 5    ; Short shooting range
    set shape "square"      ; Square shape for mechanical look
  ]
  
  ; Configure Splash Tower - area damage, medium stats
  if tower-type = "splash" [
    set color violet         ; Violet color for identification
    set fire-rate 40        ; Medium firing speed (40 ticks between shots)
    set damage 20           ; Medium damage per shot
    set range-distance 7    ; Medium shooting range
    set shape "pentagon"    ; Pentagon shape for unique appearance
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GO (MAIN LOOP)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Main simulation loop - runs every tick to update all game elements
to go
  ; Check for game end conditions first
  
  ; End game if time limit is reached
  if game-time >= max-game-time [
    set game-over? true
    show-game-stats "TIME LIMIT REACHED"
    stop
  ]
  
  ; End game if all towers have been destroyed
  if not any? towers [
    set game-over? true
    show-game-stats "ALL TOWERS DESTROYED"
    stop
  ]
  
  ; If game is over, stop the simulation
  if game-over? [ stop ]
  
  ; Reset visual indicators for this tick
  ask towers [
    set under-attack? false  ; Reset attack indicator
  ]
  
  ; Spawn new enemies if it's time
  spawn-enemies
  
  ; Update all enemy agents (movement, targeting, attacking)
  ask enemies [
    enemy-behavior
  ]
  
  ; Update all tower agents (shooting, visual updates)
  ask towers [
    tower-behavior
  ]
  
  ; Update all projectile agents (movement, collision detection)
  ask projectiles [
    projectile-behavior
  ]
  
  ; Advance game timers
  set game-time game-time + 1      ; Increment overall game time
  set spawn-timer spawn-timer + 1  ; Increment enemy spawn timer
  
  tick  ; Advance the NetLogo tick counter
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ENEMY BEHAVIOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Creates new enemy zombies at regular intervals from random map edges
to spawn-enemies
  ; Check if it's time to spawn a new enemy
  if spawn-timer >= enemy-spawn-rate [
    set spawn-timer 0  ; Reset the spawn timer
    
    ; Randomly select which edge of the map to spawn from
    ; 0=top, 1=bottom, 2=left, 3=right
    let edge random 4
    let spawn-x 0
    let spawn-y 0
    
    ; Calculate spawn coordinates based on selected edge
    if edge = 0 [  ; Top edge
      set spawn-x min-pxcor + random (max-pxcor - min-pxcor)
      set spawn-y max-pycor
    ]
    if edge = 1 [  ; Bottom edge
      set spawn-x min-pxcor + random (max-pxcor - min-pxcor)
      set spawn-y min-pycor
    ]
    if edge = 2 [  ; Left edge
      set spawn-x min-pxcor
      set spawn-y min-pycor + random (max-pycor - min-pycor)
    ]
    if edge = 3 [  ; Right edge
      set spawn-x max-pxcor
      set spawn-y min-pycor + random (max-pycor - min-pycor)
    ]
    
    ; Create the new enemy zombie
    create-enemies 1 [
      setxy spawn-x spawn-y        ; Place at calculated spawn location
      set shape "person"           ; Use person shape for zombie appearance
      set color red                ; Red color for hostile appearance
      set size 1.5                 ; Slightly larger than towers
      
      ; Generate random enemy strength (level 1-3)
      let enemy-level 1 + random 3
      set max-health 20 * enemy-level * enemy-difficulty  ; Scale with difficulty
      set health max-health        ; Start at full health
      set speed 0.1 + random-float 0.1  ; Random movement speed
      set attack-damage 2 + random 3    ; Random attack damage (2-5)
      set attack-cooldown 0        ; Ready to attack immediately
      set target-tower nobody      ; No target initially
      
      set enemies-spawned enemies-spawned + 1  ; Update spawn counter
    ]
  ]
end

; Controls the behavior of each enemy zombie every tick
to enemy-behavior
  ; Count down attack cooldown timer
  if attack-cooldown > 0 [
    set attack-cooldown attack-cooldown - 1
  ]
  
  ; Update target tower if current target is invalid or destroyed
  if target-tower = nobody or not member? target-tower towers [
    ifelse any? towers [
      ; Find the closest tower to target
      set target-tower min-one-of towers [distance myself]
    ] [
      ; No towers left, this enemy has won - remove it
      die
    ]
  ]
  
  ; Move toward the target tower
  if target-tower != nobody [
    face target-tower    ; Turn to face the target
    forward speed        ; Move forward at the enemy's speed
  ]
  
  ; Check if this enemy is within shooting range of any tower
  let in-danger? any? towers with [distance myself <= range-distance]
  
  ; Update visual appearance based on danger status
  ifelse in-danger? [
    set shape "person"   ; Person shape when in shooting range (running)
    set color red + 1    ; Slightly brighter red when in danger
  ] [
    set shape "person"   ; Person shape when safe (walking)
    set color red - 1    ; Slightly darker red when safe
  ]
  
  ; Attack nearby towers
  let nearby-tower min-one-of towers in-radius 2 [distance myself]
  if nearby-tower != nobody and attack-cooldown = 0 [
    ask nearby-tower [
      set health health - [attack-damage] of myself
      set under-attack? true
      if health <= 0 [
        set towers-destroyed towers-destroyed + 1
        die
      ]
    ]
    set attack-cooldown 30
  ]
  
  ; Check if dead
  if health <= 0 [
    set enemies-killed enemies-killed + 1
    die
  ]
  
  ; Update color based on health
  set color scale-color red health max-health 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TOWER BEHAVIOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to tower-behavior
  ; Reduce cooldown
  if cooldown > 0 [
    set cooldown cooldown - 1
  ]
  
  ; Find enemies in range and shoot
  let targets enemies in-radius range-distance
  if cooldown = 0 and any? targets [
    let target min-one-of targets [distance myself]
    shoot-at target
    set cooldown fire-rate
  ]
  
  ; Update color based on health (brighter = healthier)
  let health-percent health / max-health
  if tower-type = "basic" [ set color scale-color blue health-percent 0 1 ]
  if tower-type = "sniper" [ set color scale-color red health-percent 0 1 ]
  if tower-type = "rapid" [ set color scale-color yellow health-percent 0 1 ]
  if tower-type = "splash" [ set color scale-color violet health-percent 0 1 ]
  
  ; Pulse when under attack
  ifelse under-attack? [ set size 2.5 ] [ set size 2 ]
  
  ; Show range if enabled
  if show-tower-range? [
    ask patches in-radius range-distance [
      if pcolor = green + 2 [
        set pcolor green + 1
      ]
    ]
  ]
end

; Creates and launches a projectile from a tower toward a target enemy
to shoot-at [target]
  ; Create a new projectile agent
  hatch-projectiles 1 [
    set target-enemy target                    ; Set the target enemy
    set projectile-damage [damage] of myself   ; Inherit damage from tower
    set projectile-type [tower-type] of myself ; Inherit type from tower
    
    ; Set projectile appearance
    set shape "circle"    ; Small circle for projectile
    set size 0.5          ; Small size for projectile
    
    ; Color the projectile based on the tower type that fired it
    if projectile-type = "basic" [ set color cyan ]     ; Blue tower -> cyan projectile
    if projectile-type = "sniper" [ set color orange ]  ; Red tower -> orange projectile
    if projectile-type = "rapid" [ set color yellow ]   ; Yellow tower -> yellow projectile
    if projectile-type = "splash" [ set color magenta ] ; Violet tower -> magenta projectile
    
    face target-enemy  ; Point the projectile toward its target
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PROJECTILE BEHAVIOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to projectile-behavior
  ; Move towards target
  if target-enemy != nobody and [who] of target-enemy >= 0 [
    face target-enemy
    forward 1
    
    ; Check if hit
    if distance target-enemy < 1 [
      hit-target
      die
    ]
  ]
  
  ; Remove if target is dead or too far
  if target-enemy = nobody or distance target-enemy > 20 [
    die
  ]
end

to hit-target
  let proj-damage projectile-damage
  let proj-type projectile-type
  
  ; Deal damage to target
  ask target-enemy [
    set health health - proj-damage
  ]
  
  ; Splash damage
  if proj-type = "splash" [
    ask enemies in-radius 2 [
      set health health - (proj-damage * 0.5)
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; REPORTING & DISPLAY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to show-game-stats [reason]
  let total-enemies enemies-spawned
  let kill-rate 0
  if total-enemies > 0 [
    set kill-rate precision ((enemies-killed / total-enemies) * 100) 1
  ]
  
  let towers-remaining count towers
  let enemies-active count enemies
  
  user-message (word 
    "=== GAME OVER ===\n"
    "Reason: " reason "\n\n"
    "Time Survived: " game-time " ticks\n"
    "Towers Remaining: " towers-remaining "\n"
    "Towers Destroyed: " towers-destroyed "\n\n"
    "Zombies Killed: " enemies-killed "\n"
    "Active Zombies: " enemies-active "\n"
    "Kill Rate: " kill-rate "%\n"
    "Total Spawned: " total-enemies
  )
end

to-report time-remaining
  report max (list 0 (max-game-time - game-time))
end

@#$#@#$#@
GRAPHICS-WINDOW
210
10
975
445
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
-25
24
-14
13
1
1
1
ticks
30.0

BUTTON
20
20
103
53
Setup
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
115
20
198
53
Go
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
20
70
198
103
num-towers
num-towers
5
30
5.0
1
1
NIL
HORIZONTAL

SLIDER
20
115
198
148
enemy-spawn-rate
enemy-spawn-rate
10
100
60.0
5
1
ticks
HORIZONTAL

SLIDER
20
160
198
193
enemy-difficulty
enemy-difficulty
0.5
3
1.0
0.1
1
x
HORIZONTAL

SLIDER
20
205
198
238
simulation-duration
simulation-duration
500
5000
1500.0
100
1
ticks
HORIZONTAL

SLIDER
20
250
198
283
tower-spacing
tower-spacing
1
8
3.0
0.5
1
patches
HORIZONTAL

SWITCH
20
295
198
328
show-tower-range?
show-tower-range?
0
1
-1000

MONITOR
990
20
1085
65
Time Left
time-remaining
0
1
11

MONITOR
990
75
1085
120
Zombies Killed
enemies-killed
0
1
11

MONITOR
990
130
1085
175
Zombies Spawned
enemies-spawned
17
1
11

MONITOR
990
185
1085
230
Active Zombies
count enemies
0
1
11

TEXTBOX
25
5
175
23
Setup
12
0.0
1

TEXTBOX
995
5
1145
23
Game Stats
12
0.0
1

MONITOR
990
240
1085
285
Towers Remaining
count towers
0
1
11

MONITOR
990
295
1085
340
Towers Destroyed
towers-destroyed
0
1
11

@#$#@#$#@
## WHAT IS IT?

This is a tower defense simulation where you must defend against waves of zombies using strategically placed towers. Zombies spawn from all edges of the map and attempt to destroy your towers. Your goal is to survive as long as possible or until the time limit is reached.

## HOW IT WORKS

**Towers:**
- **Basic Tower** (Blue Circle): Balanced stats - moderate damage, range, and fire rate
- **Sniper Tower** (House): Long range and high damage, but slow fire rate
- **Rapid Tower** (Yellow Square): Fast fire rate and short range, low damage
- **Splash Tower** (Violet Pentagon): Area damage that affects multiple enemies

**Enemies:**
- Zombies appear as person shapes
- Dark red when safe/moving, bright red when in danger (within tower range)
- Attack towers when they get within 2 units
- Spawn from random edges at regular intervals

**Combat System:**
- Towers automatically target the closest enemy in range
- Projectiles travel toward their target and deal damage on impact
- Splash towers deal reduced damage to nearby enemies
- Towers take damage when enemies attack them directly

## HOW TO USE IT

1. Click "Setup" to place towers randomly on the map
2. Click "Go" to start the simulation
3. Adjust the sliders to change difficulty:
   - **num-towers**: Number of towers (5-30)
   - **enemy-spawn-rate**: How often enemies spawn (10-100 ticks)
   - **enemy-difficulty**: Enemy health multiplier (0.5-3.0)
   - **simulation-duration**: How long the game lasts (500-5000 ticks)
   - **tower-spacing**: Minimum distance between towers (1-8 patches)
4. Toggle "show-tower-range?" to see tower shooting ranges

## THINGS TO NOTICE

- Tower colors darken as they take damage
- Towers pulse when under attack
- Enemies change color when entering tower range
- Different tower types have different visual shapes and colors
- Towers are placed away from map edges to create strategic space

## THINGS TO TRY

- Experiment with different numbers of towers
- Try different enemy spawn rates to find the right difficulty
- Adjust tower spacing to create tight clusters or spread-out formations
- Watch how different tower types perform against waves
- Use the range visualization to understand tower coverage
- See how long you can survive with different configurations

## EXTENDING THE MODEL

- Add new tower types with different abilities
- Implement tower upgrades or special abilities
- Add different enemy types with unique behaviors
- Create a path system for enemies to follow
- Add resource management for building towers
- Implement wave-based spawning with increasing difficulty

## NETLOGO FEATURES

This model demonstrates:
- Multiple breeds (towers, enemies, projectiles)
- Agent properties and behaviors
- Distance-based interactions
- Color scaling for visual feedback
- Random placement with constraints
- Timer-based spawning
- Collision detection
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250 150 205 260 250

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

