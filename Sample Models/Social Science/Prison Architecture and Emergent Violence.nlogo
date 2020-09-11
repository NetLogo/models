extensions [ nw bitmap ]

breed [ inmates inmate ]
breed [ guards guard ]

; A third breed exists solely as a helper to identify visibility
breed [ photons photon ]


globals [
  ; Used to track number of violent and kind interactions
  violent-incidents
  kind-incidents

  mean-distance-of-violent-area-to-door
  mean-distance-of-violent-area-to-guard-post
  mean-distance-of-violent-area-to-living-quarters
]

turtles-own [
  persona ; The personality type of inmates

  ; Navigation
  target-place ; The target I am trying to navigate to, randomly selected for movement
  immediate-target-place ; the place I have to reach to get to my target place
  home-base ; Home base I return to. I can go between this patch and other accessible patches

  potential-partner ; The person I am currently deciding to befriend or abuse
  social-individual-weight ; the weight of our relationship relative to neutrality

  ; How likely I am to interact with this person
  immediate-interaction-rate

  ; How likely I am to be violent or kind as default
  base-violence-propensity
  base-kindness-propensity

  ; How likely I am to be violent or kind in THIS PARTICULAR interactions
  immediate-violence-propensity
  immediate-kindness-propensity

  ; Guard disciplinary effects
  percent-conforming ; How much I am affected by guards seeing me
  guards-that-see-me ; Number of guards to which I am visible
]

links-own [ weight ] ; Quantifies nature of relationship between inmates

patches-own [
  class ; Type of patch (wall, door, guard space, etc) - color based

  distance-of-violent-area-to-door
  distance-of-violent-area-to-guard-post
  distance-of-violent-area-to-living-quarters
  violence-weight
]

to setup
  clear-all
  import-prison-layout
  color-code-prison-layout
  setup-turtle-personas
  initiate-turtle-locations
  reset-ticks
end


;;;;;;;;;;;;;;;;;;  To Progress Timestep  ;;;;;;;;;;;;;;;;;;

to go ; At each timestep

  ask turtles [ approach-target-place ] ; I approach my target place

  ask inmates [
    establish-relationships-with-other-inmates  ; Identify the inmates in vicinity
                                                ; and establish nature of relationship with them

    identify-guards ; identify the number of guards around and change my likelihood
                    ; to befriend or abuse on that basis

    fight-or-talk-or-move-on ; act on my decision to be violent, be kind, or move on
  ]

  update-link-weight
  ; Adjust appearance of links to reflect the extent of a friendship or rivalry


  ask links [ ifelse hide-links? [ hide-link ][ show-link ] ]

  tick
end

;;;;     subprocedures     ;;;;

to update-link-weight
  ask links [
    set thickness (abs (neutral-link-weight - weight) / 20 )
    ; Positive links are green, negative ones are red

    ifelse (weight - neutral-link-weight) > 0 [ set color green ][ set color red ]
  ]
end

to approach-target-place
  ; If the patch that I am on already is the immediate target I wanted to get to
  if patch-here = immediate-target-place [
    ifelse patch-here = target-place ; then check if it is also my final target
      [look-for-new-final-target] ; if it is, I look for a new final target
      [look-for-intermediate-target] ; if it isn't look for another intermediate target
  ]
  face immediate-target-place fd 0.5 ; I face my intermediate target and move there
end

to look-for-intermediate-target
  ; possible intermediate targets are all patches that aren't walls
  let possible-immediate-targets patches in-radius vision with [class != "wall"]

  ; the visible ones are the ones that return "true" for "wall not blocking"
  let visible-immediate-targets filter wall-not-blocking? (sort possible-immediate-targets)

  ; Pick the one with the minimum distance from my final target
  set immediate-target-place min-one-of (patches with [member? self visible-immediate-targets]) [distance [target-place] of myself]

  if immediate-target-place = patch-here [look-for-new-final-target] ; If this logic tells me to stay where I am, I am stuck and should find a door
end

to look-for-new-final-target
  ifelse breed = inmates ; different targets for inmates vs guards
    [ set target-place one-of patches with [class = "living-quarters" or class = "inmate-accessible"] ]
      ; if I'm an inmate, my targets are one of either the living quarters or inmate accessible areas

    [ set target-place one-of patches with [class = "guard-space"] ]
      ; if I'm a guard, my targets are one of the available guard spaces, shift posts or lounges
end

to identify-guards
  set guards-that-see-me 0 ; start with the assumption that no guards see me
  ; then I check the accuracy of this statement
  foreach ( sort guards in-radius vision ) [ guard-to-check -> ; for each guard I can see, I check
    if ( nothing-blocking? guard-to-check ) = false [ ; if nothing is blocking me from them
    set guards-that-see-me guards-that-see-me + 1 ; then I add one to the number of guards that can see me
    ]
  ]

  ; being visible to guards scares me of the repercussions of being caught perpetuating violence
  ; as such, my propensity for violence goes down in the presence of guards
  ; However, there is a certain chance I rebel because I am an outlaw-ish individual who does not care
  ; about repercussions or conforming to moral standards (only some fraction of the time, though)

  if random 100 < percent-conforming [ ; If this is the fraction of the time I conform to social standards
    ; then I will adjust my propensity for violence as expected in the presence of guards
    set immediate-violence-propensity immediate-violence-propensity / ( guards-that-see-me + 1 )
  ]
end

to establish-relationships-with-other-inmates
  ; I am most likely to interact with the closest person to me physically
  set potential-partner min-one-of other inmates in-radius vision [distance myself]

  if potential-partner != nobody [  ; If there is someone close to me like that
    ; I assess out relationship and decide to be nice, be violent or move on
    update-relationship
  ]
end

; Reports deviation of relationship from neutrality as a weighted score centered at zero
to-report evaluate-relationship [partner]
  ifelse nw:weighted-distance-to partner weight != false [  ; If there is a path to connect us
    ; Take the weighted distance between us and store it
    let weighted-distance ( nw:weighted-distance-to partner weight )
    ; Assess what our weighted distance would be if all the connections were completely neutral
    let neutral-distance ( neutral-link-weight * ( ( length nw:turtles-on-path-to partner ) - 1 ) )
    ; I then assess what the net deviation of our relationship from neutrality is
    let absolute-deviation-from-neutrality ( weighted-distance - neutral-distance )
    ; And normalize for the magnitude of our neutral link weight
    let fractional-deviation-from-neutrality ( absolute-deviation-from-neutrality / neutral-link-weight )

    report fractional-deviation-from-neutrality
  ][
    report 0
  ]

end


to update-relationship
  ifelse random 100 < percent-conforming
    [set social-individual-weight mean [evaluate-relationship ([potential-partner] of myself)] of (inmates in-radius vision)]
    [set social-individual-weight evaluate-relationship potential-partner]

  set immediate-interaction-rate stranger-interaction-rate * ( 1 + abs(social-individual-weight ) )

  ifelse social-individual-weight < 0 [
    set immediate-kindness-propensity base-kindness-propensity * ( 1 + social-individual-weight )
     set immediate-violence-propensity base-violence-propensity * ( 1 + abs (social-individual-weight) )
  ][
    set immediate-kindness-propensity base-kindness-propensity * ( 1 + abs(social-individual-weight ) )
    set immediate-violence-propensity base-violence-propensity * ( 1 + social-individual-weight )
  ]

end

to fight-or-talk-or-move-on
  if potential-partner != nobody and random 100 < immediate-interaction-rate [
    ifelse random 100 < immediate-kindness-propensity
      [ be-kind ]
      [ if random 100 < immediate-violence-propensity [be-violent] ]
  ]

end

to be-kind
  if potential-partner != nobody [
    ifelse link-neighbor? potential-partner = false
      [ create-link-with potential-partner [ set weight neutral-link-weight + 1 show-link] ]
      [ ask link who ([who] of potential-partner ) [ if weight < 2 * neutral-link-weight [set weight weight + 1 ]]]
  ]

  set kind-incidents kind-incidents + 1
end

to be-violent
  if potential-partner != nobody [
    ifelse link-neighbor? potential-partner = false
    [ create-link-with potential-partner [ set weight neutral-link-weight - 1 show-link] ]
    [ ask link who ([who] of potential-partner ) [ if weight > 1 [ set weight weight - 1 ]]]
  ]

  if show-violence-trail? [mark-violence]

  set violent-incidents violent-incidents + 1
end

to mark-violence
  ask patch-here [
    ifelse shade-of? pcolor red
    [ if pcolor > 11 [set pcolor pcolor - 1] ] ; Mark it a darker red to signify more violence
    [ set pcolor 19 ] ; Initially mark it red
  ]

  record-violent-locations
end

to record-violent-locations

  ask patches with [shade-of? pcolor red] [
    set distance-of-violent-area-to-door distance min-one-of (patches with [class = "door"]) [distance myself]
    set distance-of-violent-area-to-guard-post distance min-one-of patches with [class = "guard-space"] [distance myself]
    set distance-of-violent-area-to-living-quarters distance min-one-of patches with [class = "living-quarters"] [distance myself]
    set violence-weight (20 - pcolor) / 10
  ]
  if any? patches with [shade-of? pcolor red] = true [
    set mean-distance-of-violent-area-to-door mean [distance-of-violent-area-to-door] of patches with [shade-of? pcolor red]
    set mean-distance-of-violent-area-to-guard-post mean [distance-of-violent-area-to-guard-post] of patches with [shade-of? pcolor red]
    set mean-distance-of-violent-area-to-living-quarters mean [distance-of-violent-area-to-living-quarters] of patches with [shade-of? pcolor red]
  ]
end

;;;;;;;;;;;;;;;;;;;; SETUP ACTIONS ;;;;;;;;;;;;;;;;;;;;;;;;

;; IMPORT LAYOUT

to import-prison-layout
  ; Imports the different prison layout based on what the user decides they want
  let layout-file (ifelse-value
    prison-layout = "Radial Turtle" ["prison-turtle-layout.png"]
    prison-layout = "Courtyard" ["prison-courtyard-layout.png"]
    prison-layout = "Campus" ["prison-campus-layout.png"]
  )
  bitmap:copy-to-pcolors (bitmap:import layout-file) false
end

to color-code-prison-layout
  ; The type of patch being used in the prison layout (i.e. door or wall,
  ; can an inmate go here or not?) is designated by color. This dictionary
  ; conversion step is shown below
  ask patches with [pcolor = [255 0 255]] [set class "inmate-accessible"]
  ask patches with [pcolor = [0 0 0]] [set class "wall"]
  ask patches with [pcolor = [0 255 0]] [set class "door"]
  ask patches with [pcolor = [0 0 255]] [set class "guard-space"]
  ask patches with [pcolor = [255 150 0]] [set class "living-quarters"]

  ; For bitmap development for future iterations of the model, architects should
  ; use the color scheme based on RGB values when developing their layout
  ; However, for the purposes of the model, it is easier to convert these plan colors
  ; to netlogo approximations. This next step does that
  ask patches with [is-list? pcolor] [set pcolor approximate-rgb (item 0 pcolor) (item 1 pcolor) (item 2 pcolor)]
end

  ;; SETUP TURTLES
  ; Create inmates and guards based on numbers specified by user
  ; Set interaction parameters for different inmate personas
to setup-turtle-personas
  set-default-shape turtles "person"

  create-guards number-of-guards

  create-inmates percent-square-johns * total-inmates / 100 [
    set persona "square john"
    set base-kindness-propensity SJ-base-kindness-propensity
    ; This is how likely they are to be kind to a stranger
    set base-violence-propensity (100 - base-kindness-propensity)
    ; this is how likely they are to be violent with a stranger
    set percent-conforming 80
    ; This how often they are affected by the presence of guards and social pressure
  ]

  create-inmates percent-right-guys * total-inmates / 100 [
    set persona "right guy"
    set base-kindness-propensity RG-base-kindness-propensity
    set base-violence-propensity (100 - base-kindness-propensity)
    set percent-conforming 60
  ]

  create-inmates percent-politicians * total-inmates / 100 [
    set persona "politician"
    set base-kindness-propensity PT-base-kindness-propensity
    set base-violence-propensity (100 - base-kindness-propensity)
    set percent-conforming 70
  ]

  create-inmates percent-outlaws * total-inmates / 100 [
    set persona "outlaw"
    set base-kindness-propensity OL-base-kindness-propensity
    set base-violence-propensity (100 - base-kindness-propensity)
    set percent-conforming 40
  ]
end

  ; INITIATION AND COLOR DIFFERENTIATION
to initiate-turtle-locations
  ask inmates [
    set color orange ; Inmates are orange in color.
    set home-base one-of patches with [class = "living-quarters"]
      ;They all have a home base (living quarters) they can return to
      ; at random points throughout the day
    set target-place one-of patches with [class = "inmate-accessible"]
      ; Set an initial target to be any patch they can access
  ]

  ask guards [
    set color blue ; Guards are blue
    set target-place one-of patches with [class = "guard-space"]
    ; guards have their own spaces that represent guard lounges or shift locations
  ]

  ask turtles [
    move-to one-of patches with [class != "wall"] ; Initiate at any non-wall patch
    set size 2
    look-for-intermediate-target
  ]

  ; For tracking purposes, we have counters for violent and kind incidents
  set violent-incidents 0
  set kind-incidents 0
end




;;;;;;;;;;;; HELPER FUNCTIONS ;;;;;;;;;;;;;

; Checks that specifically a wall is not blocking. used to assess if a path to patch is feasible
to-report wall-not-blocking? [ p ]
  let res true

  hatch-photons 1 [
    set shape "dot"
    set color yellow
    face p

  while [[class] of patch-here != "wall" and (patch-here != p or distance p > 0.5)] [
    fd 0.05
  ]

  if [class] of patch-here = "wall" and [not on-edge] of patch-here [
    set res false ]

    die
  ]
  report res
end

; Used by other "is-blocking?" helper functions to see if the photons produced collide with something on their way
to-report colliding-with-something?
  report [class] of patch-here = "wall" or any? other turtles in-radius 0.1 or any? patches in-radius 0.1 with [class = "wall"]
end

; Checks if ANYTHING is blocking, including inmates
to-report nothing-blocking? [ p ]
  let res true
  let ray-casting true

  hatch-photons 1 [
    set shape "dot"
    set color yellow
    face p

  while [ray-casting] [
    if colliding-with-something? [
      set res false
      set ray-casting false
    ]

    if distance p < 0.5 [
      set ray-casting false
    ]

    fd 0.05
  ]
    die
  ]
  report res
end

; Checks to see that patches are not on the edge of the world
to-report on-edge
  report pxcor = min-pxcor or pycor = min-pycor or pxcor = max-pxcor or pycor = max-pycor
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
510
10
878
379
-1
-1
6.0
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
59
-59
0
0
0
1
ticks
30.0

SLIDER
5
130
180
163
number-of-guards
number-of-guards
0
230
39.0
1
1
NIL
HORIZONTAL

SLIDER
185
170
365
203
vision
vision
0
30
20.0
1
1
NIL
HORIZONTAL

BUTTON
375
25
505
105
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
375
110
505
190
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
5
170
180
203
speed
speed
0
2
0.92
0.01
1
NIL
HORIZONTAL

SLIDER
5
230
220
263
percent-square-johns
percent-square-johns
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
265
230
470
263
percent-right-guys
percent-right-guys
0
100
21.0
1
1
NIL
HORIZONTAL

SLIDER
5
365
220
398
percent-politicians
percent-politicians
0
100
21.0
1
1
NIL
HORIZONTAL

SLIDER
265
365
475
398
percent-outlaws
percent-outlaws
0
100
11.0
1
1
NIL
HORIZONTAL

PLOT
510
385
865
565
Ratio of Kind Incidents to Violent Incidents
ticks
violent incidents
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if not ( violent-incidents = 0 ) [plot (kind-incidents) / (violent-incidents)]"

MONITOR
1020
185
1070
230
violent
violent-incidents
17
1
11

MONITOR
970
185
1020
230
kind
kind-incidents
17
1
11

MONITOR
1070
185
1120
230
ratio
kind-incidents / violent-incidents
2
1
11

SLIDER
185
130
365
163
neutral-link-weight
neutral-link-weight
0
10
7.0
1
1
NIL
HORIZONTAL

SLIDER
5
265
220
298
SJ-base-kindness-propensity
SJ-base-kindness-propensity
0
100
65.0
1
1
NIL
HORIZONTAL

SLIDER
265
265
470
298
RG-base-kindness-propensity
RG-base-kindness-propensity
0
100
67.0
1
1
NIL
HORIZONTAL

SLIDER
5
400
220
433
PT-base-kindness-propensity
PT-base-kindness-propensity
0
100
41.0
1
1
NIL
HORIZONTAL

SLIDER
265
400
475
433
OL-base-kindness-propensity
OL-base-kindness-propensity
0
100
27.0
1
1
NIL
HORIZONTAL

SLIDER
185
90
365
123
stranger-interaction-rate
stranger-interaction-rate
0
100
10.0
1
1
NIL
HORIZONTAL

SWITCH
165
10
365
43
show-violence-trail?
show-violence-trail?
0
1
-1000

CHOOSER
5
20
143
65
prison-layout
prison-layout
"Radial Turtle" "Courtyard" "Campus"
0

PLOT
865
385
1220
566
Weighted Closeness Centrality
NIL
NIL
0.0
10.0
-0.5
0.5
true
false
"" ""
PENS
"WCC" 1.0 0 -16777216 true "" "if not empty? sort (inmates) [\nplot (mean [nw:weighted-closeness-centrality weight] of inmates) * neutral-link-weight\n]"
"WCC SJ" 1.0 0 -7500403 true "" "if not empty? sort (inmates with [persona = \"square john\"]) [\nplot (mean [nw:weighted-closeness-centrality weight] of inmates with [persona = \"square john\"]) * neutral-link-weight\n]"
"WCC RG" 1.0 0 -2674135 true "" "if not empty? sort (inmates with [persona = \"right guy\"]) [\nplot (mean [nw:weighted-closeness-centrality weight] of inmates with [persona = \"right guy\"]) * neutral-link-weight\n]"
"WCC PT" 1.0 0 -955883 true "" "if not empty? sort (inmates with [persona = \"politician\"]) [\nplot (mean [nw:weighted-closeness-centrality weight] of inmates with [persona = \"politician\"]) * neutral-link-weight\n]"
"WCC OL" 1.0 0 -6459832 true "" "if not empty? sort (inmates with [persona = \"outlaw\"]) [\nplot (mean [nw:weighted-closeness-centrality weight] of inmates with [persona = \"outlaw\"]) * neutral-link-weight\n]"

SWITCH
165
45
365
78
hide-links?
hide-links?
0
1
-1000

TEXTBOX
972
168
1187
186
Tracking Different Interactions
11
0.0
1

MONITOR
885
10
1245
55
Avg Distance of Violence to Door
mean-distance-of-violent-area-to-door
3
1
11

MONITOR
885
62
1245
107
Avg Distance of Violence to Guard Post
mean-distance-of-violent-area-to-guard-post
3
1
11

MONITOR
885
115
1245
160
Avg Distance of Violence to Living Quarters
mean-distance-of-violent-area-to-living-quarters
3
1
11

SLIDER
5
90
180
123
total-inmates
total-inmates
0
180
180.0
1
1
NIL
HORIZONTAL

SLIDER
5
300
220
333
SJ-percent-conforming
SJ-percent-conforming
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
265
300
470
333
RG-percent-conforming
RG-percent-conforming
0
100
60.0
1
1
NIL
HORIZONTAL

SLIDER
5
435
220
468
PT-percent-conforming
PT-percent-conforming
0
100
70.0
1
1
NIL
HORIZONTAL

SLIDER
265
435
475
468
OL-percent-conforming
OL-percent-conforming
0
100
40.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model simulates an abstract layout of one of the three most popular prison layouts in the US. These three layouts are the "Radial Turtle", the "Courtyard" and the "Campus" prison layouts. These three layouts account for the layouts of over 65% of all prisons in the US and so are used in this study/simulation.

Inmates are simulated with different personas at different population fractions (specifed by the user) with a different number of guards (also user specified). The ensuing social network dynamics as well as the emergent ratio of kind to violent acts is then recorded and presented.

The model attempts to explore how different factors such as the density of inmates in a prison, the guard to prison ratio, the demographic information of the prisoners in terms of their varying personalities as well as the fundamental architecture of the prison lead to different emrgent rates of violence and social cohesiveness.

## HOW IT WORKS

Turtles will randomly select a room "core" (the colored patches at the center of rooms) to travel to and then approach them. When they reach their target room, they pick another room and travel there. This mimics turtles wandering around all the different places in a prison.

On their way there, each inmate will take stock of all the other inmates around them and ask themselves four questions:
   - Is it worth it to interact with this person? (dependent on turtle specific interaction rate)
   - Do I like this person? Based on closeness of turtles in network
   - Do the other inmates around us like this person?
   - Are there any guards around that can see me and could punish me if I decide to be violent with this inmate?

The inmate decides to interact based on the first question and updates its propensity for violence or kindness towards this new inmate using the second, third and fourth questions. On that basis, it acts on the probability of it being violent, kind or neutral towards this new inmate and updates the link between them, representing their relationship, appropriatley

## HOW TO USE IT

Play with the sliders:
- NUMBER-OF-GUARDS: Number of guards simulated
- PERCENT- square-johns/Right-Guys/Outlaws/Politicians: the PERCENTAGE of the number of "TOTAL-INMATES" specified that has a certain personality.
- STRANGER-INTERACTION-RATE: what fraction of the time you will interact with the potential partner identified
- ___-KINDNESS-PROPENSITY: roughly the threshold for you being kind when interacting with someone, specific slider for each personality type
- ____-PERCENT-CONFORMING: prisoners will sometimes decide to defy social norms and act on what they want to do even when it is unpopular (be violent, even when everyone else in the room likes the person they're being violent towards or neglecting the fact that there is a guard present and not updating your propensity for violence accordingly). This slider is a reflection of how often you do NOT do this and instead obey authority.

- VISION: how far away the prisoners can see other guards to be scared of or other inmates to interact with - also effectively the maximum distance at which you can be kind or violent to someone
- SPEED: how fast turtles walk across the room in one tick
- NEUTRAL-LINK-WEIGHT: effectively represents the level of granularity achievable when characterizing a relationship. If this is set to 1, then all relationships are entirley black or white. you're either a neutral relationship (link weight of 1), a horrible one (0) or a good one (2). the higher the number, the greater the level of relationship hierarchy

- PRISON-LAYOUT lets you try the different layout designs available
- SHOW-VIOLENCE-TRAIL?: when on, the turtle leave a little bit of red marking on the patches they were violent on, creates a heat map of violence.

## THINGS TO NOTICE

- note how decreasing the guard to prison ratio leads to increased violence
- note how, even at high guard to prison ratios, increasing the number of prisoners allows them to stay hidden and so the violence levels are as if there were no guards again
- which prison layouts are the safest? play around with that and notice that the tighter
- turn on the violence trail and observe that violence tends to happen in enclosed tight spaces where you are hidden from guards, usually not in doors, but near doors because you bump into people.

## THINGS TO TRY

- try different fractions of prisoner personality types to see how sensisitive a prison design is to the introduction of a more violent personality in higher quantities
- try changing the guard to prison ratios and seeing what happens in different designs

## EXTENDING THE MODEL

- modify it so that not all violent interactions are equally violent, add hierarchies
- add schedules so turtles don't just wander around but instead go to events and stuff\
- incorporate level space for more sophisticated prisoner social evaluation

## NETLOGO FEATURES

- The Bitmap extension was used to import prison layouts
- The NW extension was used to characterize the network
- The Hubnet Extension was used to develop the model into a sort of videogame

## RELATED MODELS

- Giant Cluster network model
- Small World metwork model
- Team Assembly network model

## REFERENCES

“Assessing the Relationship between Exposure to Violence and Inmate Maladjustment within and Across State Correctional Facilities,” n.d., 80.

“Can the Architecture of a Prison Contribute to the Rehabilitation of Its Inmates?” Design Indaba. Accessed June 4, 2019. https://www.designindaba.com/articles/creative-work/can-architecture-prison-contribute-rehabilitation-its-inmates.

Cason, Mike. “Alabama Prison Chief Says Violence Rising as Staffing Falls.” al.com, November 30, 2016. https://www.al.com/news/birmingham/2016/11/alabama_prison_chief_says_viol.html.

Chong, Christine, and Michael Musheno. “Inmate-to-Inmate: Socialization, Relationships, and Community Amongst Incarcerated Men,” n.d., 53.

Clemmer, Donald. “Observations on Imprisonment as a Source of Criminality.” Journal of Criminal Law and Criminology (1931-1951) 41, no. 3 (September 1950): 311. https://doi.org/10.2307/1138066.

Ekland-Olson, Sheldon. “Crowding, Social Control, and Prison Violence: Evidence from the Post-Ruiz Years in Texas.” Law & Society Review, vol. 20, no. 3, 1986, pp. 389–421. JSTOR, www.jstor.org/stable/3053581. Accessed 11 Sept. 2020.

Garabedian, Peter G. “Social Rules in a Correctional Community,” n.d., 11.

Harress, Christopher. “The Architecture of Violence in Alabama’s Prisons.” al.com, February 12, 2017. https://www.al.com/news/mobile/2017/02/the_architecture_of_violence_i.html.

Jacobs, James B. “American Prisons: The Frustration of Inching Toward Reform.” Edited by Blake McKelvey. Reviews in American History 6, no. 2 (1978): 184–89. https://doi.org/10.2307/2701295.

McGuire, Professor James. “Understanding Prison Violence: A Rapid Evidence Assessment,” n.d., 9.

McKelvey, Blake. American Prisons: A History of Good Intentions. P. Smith, 1977.

“NCJRS Abstract - National Criminal Justice Reference Service.” Accessed May 31, 2019. https://www.ncjrs.gov/App/Publications/abstract.aspx?ID=192846.

National Criminal Justice Reference Service. “Our Crowded Jails: A National Plight.” Accessed June 3, 2019. https://www.bjs.gov/content/pub/pdf/ocj-np.pdf.

"State Prison Capacity, Overcrowded Prisons Data.” Accessed June 3, 2019. https://www.governing.com/gov-data/safety-justice/state-prison-capacity-overcrowding-data.html.

Sterbenz, Christina. “Why Norway’s Prison System Is so Successful.” Business Insider. Accessed June 4, 2019. https://www.businessinsider.com/why-norways-prison-system-is-so-successful-2014-12.

“The Evolution of Prison Design and the Direct Supervision Model.” Lexipol (blog), March 17, 2017. https://www.lexipol.com/resources/blog/the-evolution-of-prison-design-and-the-rise-of-the-direct-supervision-model/.

Thomas, Charles W. “Theoretical Perspectives on Prisonization: A Comparison of the Importation and Deprivation Models.” The Journal of Criminal Law and Criminology (1973-) 68, no. 1 (March 1977): 135. https://doi.org/10.2307/1142482.

Thompson, Barbara A. "Prison Design and Prisoner Beavhior: Philosophy, Architecture, and Violence.” 1980. Accessed June 3, 2019. https://etd.ohiolink.edu/!etd.send_file?accession=oberlin1316531267&disposition=inline.

Vessella, Luigi. “Prison, Architecture and Social Growth: Prison as an Active Component of the Contemporary City.” The Plan Journal 2, no. 1 (July 2, 2017): 63–84. https://doi.org/10.15274/tpj.2017.02.01.05.

Wheeler, Stanton. “Socialization in Correctional Communities.” American Sociological Review 26, no. 5 (1961): 697–712. https://doi.org/10.2307/2090199.

ZeusesCloud. Prison Architect Basic Prison Layout. Accessed May 29, 2019. https://www.youtube.com/watch?v=PG1Pw77i-IU.

“10 Stats about Assault and Sexual Violence in America’s Prisons.” Mother Jones (blog). Accessed June 7, 2019. https://www.motherjones.com/politics/2016/06/attacks-and-assaults-behind-bars-cca-private-prisons/.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Hazboun, A. and Wilensky, U. (2020).  NetLogo Prison Architecture and Emergent Violence model.  http://ccl.northwestern.edu/netlogo/models/PrisonArchitectureandEmergentViolence.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

This model was developed as part of the Multi-agent Modeling course offerred by Dr. Uri Wilensky at Northwestern University. For more info, visit http://ccl.northwestern.edu/courses/mam/. Special thanks to Teaching Assistants Sugat Dabholkar, Can Gurkan, and Connor Bain.

## COPYRIGHT AND LICENSE

Copyright 2020 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2020 MAM2019 Cite: Hazboun, A. -->
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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="sample-experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(mean [nw:weighted-closeness-centrality weight] of inmates) * neutral-link-weight</metric>
    <metric>(mean [nw:weighted-closeness-centrality weight] of inmates with [persona = "right guy"]) * neutral-link-weight</metric>
    <metric>(mean [nw:weighted-closeness-centrality weight] of inmates with [persona = "square john"]) * neutral-link-weight</metric>
    <metric>(mean [nw:weighted-closeness-centrality weight] of inmates with [persona = "politician"]) * neutral-link-weight</metric>
    <metric>(mean [nw:weighted-closeness-centrality weight] of inmates with [persona = "outlaw"]) * neutral-link-weight</metric>
    <metric>kind-incidents</metric>
    <metric>violent-incidents</metric>
    <metric>kind-incidents / violent-incidents</metric>
    <metric>mean-distance-of-violent-area-to-door</metric>
    <metric>mean-distance-of-violent-area-to-living-quarters</metric>
    <metric>mean-distance-of-violent-area-to-guard-post</metric>
    <enumeratedValueSet variable="number-of-right-guys">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-politicians">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-links?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-guards">
      <value value="0"/>
      <value value="15"/>
      <value value="30"/>
      <value value="60"/>
      <value value="90"/>
      <value value="120"/>
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stranger-interaction-rate">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SJ-base-kindness-propensity">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-square-johns">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neutral-link-weight">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-violence-trail?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PT-base-kindness-propensity">
      <value value="41"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prison-layout">
      <value value="&quot;Campus&quot;"/>
      <value value="&quot;Radial Turtle&quot;"/>
      <value value="&quot;Courtyard&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RG-base-kindness-propensity">
      <value value="54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-outlaws">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="0.92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hide-turtles?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OL-base-kindness-propensity">
      <value value="27"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interaction-rate">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-inmates">
      <value value="15"/>
      <value value="30"/>
      <value value="60"/>
      <value value="90"/>
      <value value="120"/>
      <value value="180"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
