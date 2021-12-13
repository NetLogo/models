                                                        ;;;;;;;;;;;;; small molecules  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [phosphates phosphate]                            ;; the free floating phosphates that are broken off a nucleoside-tri-phosphate when a nucleotide is formed
breed [nucleosides nucleoside]                          ;; the free floating nucleoside-tri-phosphates
breed [nucleotides nucleotide]                          ;; the pieces that are inside the DNA chain

                                                        ;;;;;;;;;;;;enzymes ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [polymerases polymerase]                          ;; for gearing a hydrogen "old-stair" bond of free nucleosides to existing nucleotides
breed [helicases helicase]                              ;; for unzipping a DNA strand
breed [topoisomerases topoisomerase]                    ;; for unwinding a DNA chromosome
breed [topoisomerases-gears topoisomerase-gear]         ;; for visualizing a spin in topoisomerases when unwinding a DNA chromosome
breed [primases primase]                                ;; for attaching to the first nucleotide on the top strand.
                                                        ;;   It marks the location where the topoisomerase must be to unwind

                                                        ;;;;;;;;;;;;; label turtles  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [nucleotide-tags nucleotide-tag]                  ;; the turtle tied to the nucleotide that supports a fine tuned placement of the A, G, C, T lettering
breed [enzyme-tags enzyme-tag]                          ;; the turtle tied to the helicase and polymerase that supports a fine tuned placement of the label

                                                        ;;;;;;;;;;;;; visualization turtles ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [mouse-cursors mouse-cursor]                      ;; follows the cursor location
breed [chromosome-builders initial-chromosomes-builder] ;; initial temporary construction turtle

                                                        ;;;;;;;;;;;;; links ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
undirected-link-breed [old-stairs old-stair]            ;; links between nucleotide base pairs that made the old stairs of the "spiral staircase" in the DNA
undirected-link-breed [new-stairs new-stair]            ;; links between nucleotide base pairs that makes the new stairs of the "spiral staircase" in the replicated DNA
undirected-link-breed [taglines tagline]                ;; links between an agent and where its label agent is. This allows fine tuned placement of visualizing of labels
directed-link-breed [gearlines gearline]                ;; links between topoisomerase and its topoisomerases-gears
directed-link-breed [cursor-drags cursor-drag]          ;; links the mouse-cursor and any other agent it is dragging with it during a mouse-down? event
directed-link-breed [backbones backbone]                ;; links between adjacent nucleotides on the same side of the DNA strand -
                                                        ;;   this represents the sugar backbone of the strand it allows the entire strand to be wound or unwound

                                                        ;;;;;;;;;;;;;;;;;;;turtle variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
nucleosides-own [class value place]                     ;; class is top or bottom and copy or original / value is A, G, C, or T /  place is a # of order in sequence
nucleotides-own [                                       ;; nucleotides may be any of 4 unzipped-stages (how far the zipper is undone)
  class value
  place unwound?
  unzipped-stage
]
nucleotide-tags-own [value]                             ;; the value for their label when visualized
polymerases-own [locked-state]                          ;; locked-state can be four possible values for polymerase for when it is bound to a nucleotide and
                                                        ;;   responding to confirmation of whether a matched nucleoside is nearby or not
topoisomerases-own [locked?]                            ;; locked? is true/false for when the topoisomerase is on the site of the primase

globals [                                               ;;;;;;;;;;;;;;;;;;;;globals ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  initial-length-dna
  mouse-continuous-down?

  instruction ;; counter which keeps track of which instruction is being displayed in the output

  ;; colors for various agents and states of agents
  cursor-detect-color
  cursor-drag-color
  wound-dna-color
  unwound-dna-color
  nucleo-tag-color
  enzyme-tag-color
  nucleoside-color

  ;; colors for the four different states the polymerase enzyme can be in
  polymerase-color-0
  polymerase-color-1
  polymerase-color-2
  polymerase-color-3

  ;; colors for the two different states the helicase enzyme can be in
  helicase-color-0
  helicase-color-1

  ;; colors for the two different states the topoisomerase enzyme can be in
  topoisomerase-color-0
  topoisomerase-color-1

  ;; colors for the two different states the primase enzyme can be in
  primase-color-0
  primase-color-1

  final-time

  ;; for keeping track of the total number of mutations
  total-deletion-mutations-top-strand
  total-substitution-mutations-top-strand
  total-correct-duplications-top-strand
  total-deletion-mutations-bottom-strand
  total-substitution-mutations-bottom-strand
  total-correct-duplications-bottom-strand

  lock-radius           ;; how far away an enzyme must be from a target interaction (with another molecule )
                        ;;   for it to lock those molecules (or itself) into a confirmation state/site
  mouse-drag-radius     ;; how far away a molecule must be in order for the mouse-cursor to link to it and the user to be able to drag it (with mouse-down?
  molecule-step         ;; how far each molecules moves each tick
  wind-angle            ;; angle of winding used for twisting up the DNA

  length-of-simulation  ;; number of seconds for this simulation
  time-remaining        ;; time-remaining in the simulation
  current-instruction   ;; counter for keeping track of which instruction is displayed in output window
  using-time-limit      ;; boolean for keeping track of whether this is a timed model run
  simulation-started?   ;; boolean for keeping track of whether the simulation started
  cell-divided?         ;; boolean for keeping track of whether the end of the simulation was cued
  simulation-ended?     ;; boolean for keeping track of whether the end of the simulation ended
  cell-message-shown?   ;; boolean for keep track of whether the cell message was shown
  timer-message-shown?  ;; boolean for keeping track of whether the timer message was shown

]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;setup procedures;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all

  set polymerase-color-0    [150 150 150 150]
  set polymerase-color-1    [75  200  75 200]
  set polymerase-color-2    [0   255   0 220]
  set polymerase-color-3    [255   0   0 220]
  set nucleo-tag-color      [255 255 255 200]
  set enzyme-tag-color      [255 255 255 200]
  set primase-color-0       [255 255 255 150]
  set primase-color-1       [255 255 255 200]
  set helicase-color-1      [255 255 210 200]
  set helicase-color-0      [255 255 210 150]
  set topoisomerase-color-0 [210 255 255 150]
  set topoisomerase-color-1 [180 255 180 220]
  set nucleoside-color      [255 255 255 150]
  set wound-dna-color       [255 255 255 150]
  set unwound-dna-color     [255 255 255 255]
  set cursor-detect-color   [255 255 255 150]
  set cursor-drag-color     [255 255 255 200]
  set instruction 0
  set wind-angle 25
  set lock-radius 0.3
  set mouse-drag-radius 0.4
  set molecule-step 0.025
  set final-time 0
  set current-instruction 0

  set total-deletion-mutations-top-strand "N/A"
  set total-substitution-mutations-top-strand  "N/A"
  set total-correct-duplications-top-strand  "N/A"
  set total-deletion-mutations-bottom-strand  "N/A"
  set total-substitution-mutations-bottom-strand  "N/A"
  set total-correct-duplications-bottom-strand  "N/A"

  set-default-shape chromosome-builders "empty"
  set-default-shape nucleotide-tags "empty"

  set mouse-continuous-down? false
  set simulation-started? false
  set length-of-simulation 0
  set using-time-limit false
  set cell-divided? false
  set simulation-ended? false
  set cell-message-shown? false
  set timer-message-shown? false
  set initial-length-dna dna-strand-length

  create-mouse-cursors 1 [set shape "target" set color [255 255 255 100] set hidden? true] ;; make turtle for mouse cursor
  repeat free-nucleosides [make-a-nucleoside ] ;;make initial nucleosides
  make-initial-dna-strip
  make-polymerases
  make-a-helicase
  make-a-topoisomerase
  wind-initial-dna-into-bundle
  visualize-agents

  initialize-length-of-time
  show-instruction 1
  reset-ticks
end

to initialize-length-of-time
  set using-time-limit (time-limit != "none") ;*** replaces: ifelse time-limit = "none"  [set using-time-limit false] [set using-time-limit true]
  if time-limit = "2 minutes" [set length-of-simulation 120 set time-remaining 120]
  if time-limit = "5 minutes" [set length-of-simulation 300 set time-remaining 300]
end

to make-a-nucleoside
  create-nucleosides 1 [
    set value random-base-letter
    set shape (word "nucleoside-tri-" value)
    set color nucleoside-color
    attach-nucleo-tag 0 0
    setxy random-pxcor random-pycor ;*** replaces: setxy random 100 random 100 (see log for explanation)
                                    ;*** removed: set heading random 360 (the heading is already random when the turtle is created)
  ]
end

;; make two polymerases
to make-polymerases
  create-polymerases 1 [
    set heading random (180 - random 20 + random 20)
    setxy (((max-pxcor - min-pxcor) / 2) + 3) (max-pycor - 1)
  ]
  create-polymerases 1 [
    set heading (90 - random 20 + random 20)
    setxy (((max-pxcor - min-pxcor) / 2) - 5) (max-pycor - 1)
  ]
  ask polymerases [
    attach-enzyme-tag 150 .85 "polymerase"
    set locked-state 0
    set shape "polymerase-0"
    set color polymerase-color-0
  ]
end

to make-a-helicase
  create-helicases 1 [
    set shape "helicase"
    set color helicase-color-0
    set size 3.2
    set heading 90
    attach-enzyme-tag 150 .85 "helicase"
    setxy (((max-pxcor - min-pxcor) / 2)) (max-pycor - 1)
  ]
end

to make-a-topoisomerase
  create-topoisomerases 1 [
    set shape "topoisomerase"
    set locked? false
    set color topoisomerase-color-0
    set size 1.5
    set heading -90 + random-float 10 - random-float 10
    hatch 1 [set breed topoisomerases-gears set shape "topoisomerase-gears" create-gearline-from myself [set tie-mode "fixed" set hidden? true tie]]
    attach-enzyme-tag 150 .85 "topoisomerase"
    setxy (((max-pxcor - min-pxcor) / 2) - 3) (max-pycor - 1)
  ]
end

;; primase is attached to the very first nucleotide in the initial DNA strand
to make-and-attach-a-primase
  hatch 1 [
    set breed primases
    set shape "primase"
    set color primase-color-0
    set size 1.7
    set heading -13
    fd 1.1
    create-gearline-from myself [set tie-mode "fixed" set hidden? true tie]
    attach-enzyme-tag 100 0 "primase"
  ]
end

to make-initial-dna-strip
  let last-nucleotide-top-strand nobody
  let last-nucleotide-bottom-strand nobody
  let place-counter 0
  let first-base-pair-value ""
  let is-this-the-first-base? true
  create-turtles 1 [set breed chromosome-builders set heading 90 fd 1 ]

  ask chromosome-builders [
    repeat initial-length-dna [
      set place-counter place-counter + 1
      hatch 1 [
        set breed nucleotides
        set value random-base-letter
        set first-base-pair-value value
        set shape (word "nucleotide-" value)
        set heading 0
        set class "original-dna-top"
        set unwound? true
        set color unwound-dna-color
        set place place-counter
        set unzipped-stage 0
        attach-nucleo-tag 5 0.5
        if last-nucleotide-top-strand != nobody [create-backbone-to last-nucleotide-top-strand [set hidden? true tie]]
        set last-nucleotide-top-strand self
        if is-this-the-first-base? [make-and-attach-a-primase]
        set is-this-the-first-base? false

        ;; make complementary base side
        hatch 1 [     ;*** removed "if true", which was probably a left over from some experimentation...
          rt 180
          set value complementary-base first-base-pair-value  ;; this second base pair value is based on the first base pair value
          set shape (word "nucleotide-" value)
          set class "original-dna-bottom"
          create-old-stair-with last-nucleotide-top-strand [set hidden? false]
          attach-nucleo-tag 175 0.7
          if last-nucleotide-bottom-strand != nobody [create-backbone-to last-nucleotide-bottom-strand [set hidden? true tie]]
          set last-nucleotide-bottom-strand self
        ]
      ]
      fd .45
    ]
    die ;; remove the chromosome builder (a temporary construction turtle)
  ]
end

;; fine tuned placement of the location of a label for a nucleoside or nucleotide
to attach-nucleo-tag [direction displacement]
  hatch 1 [
    set heading direction
    fd displacement
    set breed nucleotide-tags
    set label value
    set size 0.1
    set color nucleo-tag-color
    create-tagline-with myself [set tie-mode "fixed" set hidden? true tie]
  ]
end

;; fine tuned placement of the location of a label for any enzyme
to attach-enzyme-tag [direction displacement label-value]
  hatch 1 [
    set heading direction
    fd displacement
    set breed enzyme-tags
    set shape "empty"
    set label label-value
    set color enzyme-tag-color
    set size 0.1
    create-tagline-with myself [set tie-mode "fixed" set hidden? true tie]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; runtime procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; run if the timer is being used and time remains, or if the timer is not being used and the cell division has not been cued by the user
  if ((using-time-limit and time-remaining > 0) or (not using-time-limit and not cell-divided?)) [
    check-timer
    move-free-molecules
    clean-up-free-phosphates
    refill-or-remove-nucleosides
    unzip-nucleotides
    detect-mouse-selection-event
    lock-polymerase-to-one-nucleotide
    lock-topoisomerase-to-wound-primase
    if all-base-pairs-unwound? [separate-base-pairs] ;; only check base pair separation once all base pairs are unwound
    visualize-agents
    tick
  ]
  if (cell-divided? and not cell-message-shown?) [
    if final-time = 0 [ set final-time timer ]  ;; record final time
    calculate-mutations
    user-message (word "You have cued the cell division.  Let's see how you did in replicating "
      "an exact copy of the DNA.")
    user-message user-message-string-for-mutations
    set cell-message-shown? true
  ]
  if ((using-time-limit and time-remaining <= 0) and not timer-message-shown?) [
    if final-time = 0 [ set final-time length-of-simulation ]  ;; record final time
    calculate-mutations
    user-message (word "The timer has expired.  Let's see how you did in replicating "
      "an exact copy of it.")
    user-message  user-message-string-for-mutations
    set timer-message-shown? true
  ]
end

to check-timer
  if not simulation-started? [
    set simulation-started? true
    reset-timer
  ]
  if using-time-limit [set time-remaining (length-of-simulation - timer)]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; visualization procedures ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to visualize-agents
  ask enzyme-tags      [ set hidden? not enzyme-labels?]
  ask nucleotide-tags  [ set hidden? not nucleo-labels?]
  ask topoisomerases [
    ;; spin at different speeds depending if you are locked into the primase location
    ifelse locked?
      [ask topoisomerases-gears [lt 10 set color topoisomerase-color-1]]
      [ask topoisomerases-gears [lt 3  set color topoisomerase-color-0]]
  ]
  ask polymerases [
    if locked-state = 0 [set shape "polymerase-0" set color polymerase-color-0]   ;; free floating polymerases not locked into a nucleotide
    if locked-state = 1 [set shape "polymerase-1" set color polymerase-color-1]   ;; polymerase ready to lock onto nearest open nucleotide (or locked on)
    if locked-state = 2 [set shape "polymerase-2" set color polymerase-color-2]   ;; polymerase ready to gear two nucleotides together
    if locked-state = 3 [set shape "polymerase-3" set color polymerase-color-3]   ;; polymerase will reject the nucleoside you are trying to the nucleotide
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; winding and unwinding chromosome procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to wind-initial-dna-into-bundle
  repeat (initial-length-dna ) [ wind-dna ]
end

to unwind-dna
  let wound-nucleotides nucleotides with [not unwound?]
  if any? wound-nucleotides [
    let max-wound-place max [place] of wound-nucleotides
    ask wound-nucleotides with [place = max-wound-place] [
      lt wind-angle  ;; left turn unwinds, right turn winds
      set unwound? true
      set color unwound-dna-color
      display
    ]
  ]
end

to wind-dna
  let unwound-nucleotides nucleotides with [unwound? and class != "copy-of-dna-bottom" and class != "copy-of-dna-top"]
  if any? unwound-nucleotides [
    let min-unwound-place min [place] of unwound-nucleotides
    ask unwound-nucleotides with [place = min-unwound-place  ] [
      rt wind-angle  ;; right turn winds, left turn unwinds
      set unwound? false
      set color wound-dna-color
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; procedures for zipping & unzipping DNA strand ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to unzip-nucleotides
  let were-any-nucleotides-unzipped-further? false

  ask nucleotides with [next-nucleotide-unzipped-the-same? and unzipped-stage > 0] [
    let fractional-separation (unzipped-stage / 2)  ;; every unzipped stage will increment the fractional separation by 1/2 of a patch width
    if unzipped-stage = 3 [ask my-old-stairs [die] ask my-out-backbones [die] ]  ;; break the linking between the nucleotide bases (the stairs of the staircase)
    if unzipped-stage = 1 [ask my-out-backbones [untie]]                         ;; break the sugar backbone of the DNA strand
    if unzipped-stage > 0 and unzipped-stage < 4 [
      set unzipped-stage unzipped-stage + 1
      set were-any-nucleotides-unzipped-further? true                            ;; if any nucleotide was unzipped partially this stage
      if class = "original-dna-top"      [set ycor fractional-separation  ]      ;; move upward
      if class = "original-dna-bottom"   [set ycor -1 * fractional-separation ]  ;; move downward
    ]
  ]
  ask helicases [
    ifelse were-any-nucleotides-unzipped-further? [set shape "helicase-expanded" ][set shape "helicase" ]  ;; show shape change in this enzyme
  ]
end

to separate-base-pairs
  let lowest-place 0
  ask helicases  [
    let this-helicase self
    let unzipped-nucleotides nucleotides with [unzipped-stage = 0]
    if any? unzipped-nucleotides [ set lowest-place min-one-of unzipped-nucleotides [place] ]  ;; any unzipped nucleotides
    let available-nucleotides unzipped-nucleotides  with [distance this-helicase < 1  and are-previous-nucleotides-unzipped?]
    if any? available-nucleotides [
      let lowest-value-nucleotide min-one-of available-nucleotides [place]
      ask lowest-value-nucleotide [
        let base self
        let base-place place
        let other-base other nucleotides with [place = base-place]
        if any? other-base  [
          set unzipped-stage 1
          ask other-base [set unzipped-stage 1]
        ]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; procedures for adding and removing nucleosides and free phosphates and moving everything around ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-free-molecules
  let all-molecules (turtle-set nucleosides phosphates polymerases helicases topoisomerases)
  ask all-molecules [
    if not being-dragged-by-cursor? [
      ;; only move the molecules that aren't being dragged by the users mouse cursor (during mouse-down?)
      fd molecule-step
    ]
  ]
end

to clean-up-free-phosphates
  ask phosphates [ if pxcor = min-pxcor or pxcor = max-pxcor or pycor = min-pycor or pycor = max-pycor [die]]  ;; get rid of phosphates at the edge of the screen
end

to refill-or-remove-nucleosides
  if count nucleosides < free-nucleosides [make-a-nucleoside]
  if count nucleosides > free-nucleosides [ask one-of nucleosides [ask tagline-neighbors [die] die]]  ;; get rid of label tags too
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; procedures for setting polymerase states, aligning nucleosides to nucleotides & linking them  ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to lock-polymerase-to-one-nucleotide
  let target-xcor 0
  let target-ycor 0
  let target-class ""

  ask polymerases  [
    let nucleosides-ready-to-gear-to-polymerase nobody
    let potential-nucleoside-ready-to-gear-to-polymerase nobody
    let target-nucleotide-ready-to-gear-to-polymerase nobody
    set nucleosides-ready-to-gear-to-polymerase nucleosides with [distance myself < lock-radius]  ;; find  nucleosides floating nearby
    if count nucleosides-ready-to-gear-to-polymerase > 1 [
      set potential-nucleoside-ready-to-gear-to-polymerase min-one-of nucleosides-ready-to-gear-to-polymerase [distance myself]
    ]
    if count nucleosides-ready-to-gear-to-polymerase = 1 [
      set potential-nucleoside-ready-to-gear-to-polymerase nucleosides-ready-to-gear-to-polymerase
    ]
    let nucleotides-ready-to-gear-to-polymerase nucleotides with [
      ;; nearby nucleotides (different than nucleosides) that are not stair lined to any other nucleotides
      not any? my-old-stairs and not any? my-new-stairs and (class = "original-dna-bottom" or class = "original-dna-top") and distance myself < lock-radius
    ]

    if any? nucleotides-ready-to-gear-to-polymerase and all-base-pairs-unwound? and not being-dragged-by-cursor? [
      set target-nucleotide-ready-to-gear-to-polymerase min-one-of nucleotides-ready-to-gear-to-polymerase [distance myself]
      set target-xcor   [xcor] of target-nucleotide-ready-to-gear-to-polymerase
      set target-ycor   [ycor] of target-nucleotide-ready-to-gear-to-polymerase
      set target-class [class] of target-nucleotide-ready-to-gear-to-polymerase
      setxy target-xcor target-ycor
    ]

    if not any? nucleotides-ready-to-gear-to-polymerase or any? other polymerases-here [set locked-state 0]   ;; if no open nucleotide are present then no gearing
    if any? nucleotides-ready-to-gear-to-polymerase and
      all-base-pairs-unwound? and
      potential-nucleoside-ready-to-gear-to-polymerase = nobody and
      not any? other polymerases-here [
      ;; if an open nucleotide is present but no nucleosides
      set locked-state 1
    ]
    if target-nucleotide-ready-to-gear-to-polymerase != nobody and
      all-base-pairs-unwound?
      and potential-nucleoside-ready-to-gear-to-polymerase != nobody
      and not any? other polymerases-here [
      set locked-state 2   ;; if an open nucleotide is present and a nucleosides is present

      ifelse (
        (would-these-nucleotides-pair-correctly? target-nucleotide-ready-to-gear-to-polymerase potential-nucleoside-ready-to-gear-to-polymerase) or
        (substitutions?)
      ) [
        ask potential-nucleoside-ready-to-gear-to-polymerase  [
          ask my-in-cursor-drags  [die]
          ask tagline-neighbors [die]
          set breed nucleotides
          set shape (word "nucleotide-"  value)
          set unwound? true
          if target-class = "original-dna-top"     [ set heading 180 set class "copy-of-dna-bottom" attach-nucleo-tag 175 0.7]
          if target-class = "original-dna-bottom"  [ set heading 0 set class "copy-of-dna-top" attach-nucleo-tag 5 0.5]
          setxy target-xcor target-ycor
          break-off-phosphates-from-nucleoside
          create-new-stair-with target-nucleotide-ready-to-gear-to-polymerase [set hidden? false tie]
        ]
      ]
      [ ;; if an open nucleotide is present, and a nucleoside is present, but it is not the correct nucleosides to pair
        set locked-state 3
      ]
    ]
  ]
end

to break-off-phosphates-from-nucleoside
  hatch 1 [
    set breed phosphates
    set shape "phosphate-pair"
    set heading random 360
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; setting locking topoisomerases onto primase ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to lock-topoisomerase-to-wound-primase
  let target-xcor 0
  let target-ycor 0
  let target-class ""
  let wound-nucleotides  nucleotides with [not unwound?]
  ask topoisomerases  [
    ifelse any? wound-nucleotides [
      let target-primases-ready-to-gear-to-topoisomerase primases  with [distance myself < lock-radius ]
      ifelse any? target-primases-ready-to-gear-to-topoisomerase [
        let target-primase-ready-to-gear-to-topoisomerase one-of target-primases-ready-to-gear-to-topoisomerase
        set locked? true
        if not mouse-down? [
          unwind-dna
          ask my-in-cursor-drags  [die]
          set target-xcor   [xcor] of target-primase-ready-to-gear-to-topoisomerase
          set target-ycor   [ycor] of target-primase-ready-to-gear-to-topoisomerase
          setxy target-xcor target-ycor
        ]
      ]
      [
        set locked? false
      ]
    ]
    [
      set locked? false
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; statistics ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-mutations
  set total-deletion-mutations-top-strand 0
  set total-substitution-mutations-top-strand 0
  set total-correct-duplications-top-strand 0
  set total-deletion-mutations-bottom-strand 0
  set total-substitution-mutations-bottom-strand 0
  set total-correct-duplications-bottom-strand 0

  let original-nucleotides nucleotides with [class = "original-dna-top" ]
  ask original-nucleotides [
    if not any? my-new-stairs [set total-deletion-mutations-top-strand total-deletion-mutations-top-strand + 1]
    if count my-new-stairs >= 1 [
      ifelse is-this-nucleotide-paired-correctly?
        [set total-correct-duplications-top-strand total-correct-duplications-top-strand + 1]
        [set total-substitution-mutations-top-strand total-substitution-mutations-top-strand + 1]
    ]
  ]

  set original-nucleotides nucleotides with [class = "original-dna-bottom" ]
  ask original-nucleotides [
    if not any? my-new-stairs [set total-deletion-mutations-bottom-strand total-deletion-mutations-bottom-strand + 1]
    if count my-new-stairs >= 1 [
      ifelse is-this-nucleotide-paired-correctly?
        [set total-correct-duplications-bottom-strand total-correct-duplications-bottom-strand + 1]
        [set total-substitution-mutations-bottom-strand total-substitution-mutations-bottom-strand + 1]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;mouse cursor detection ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to detect-mouse-selection-event
  let p-mouse-xcor mouse-xcor
  let p-mouse-ycor mouse-ycor
  let current-mouse-down? mouse-down?
  let target-turtle nobody
  let current-mouse-inside? mouse-inside?
  ask mouse-cursors [
    setxy p-mouse-xcor p-mouse-ycor
    ;;;;;;  cursor visualization ;;;;;;;;;;;;
    set hidden? true
    let all-moveable-molecules (turtle-set nucleosides polymerases helicases topoisomerases)
    let draggable-molecules all-moveable-molecules with [not being-dragged-by-cursor? and distance myself <= mouse-drag-radius]

    ;; when mouse button has not been down and you are hovering over a draggable molecules - then the mouse cursor appears and is rotating
    if not current-mouse-down? and mouse-inside? and (any? draggable-molecules) [ set color cursor-detect-color  set hidden? false rt 4 ]
    ;; when things are being dragged the mouse cursor is a different color and it is not rotating
    if is-this-cursor-dragging-anything? and mouse-inside? [ set color cursor-drag-color set hidden? false]

    if not mouse-continuous-down? and current-mouse-down? and not is-this-cursor-dragging-anything? and any? draggable-molecules [
      set target-turtle min-one-of draggable-molecules  [distance myself]
      ask target-turtle [setxy p-mouse-xcor p-mouse-ycor]
      create-cursor-drag-to target-turtle [ set hidden? false tie ]
    ] ;; create-link from cursor to one of the target turtles.  These links are called cursor-drags
    if (not current-mouse-down? ) [ask my-out-cursor-drags  [die] ] ;; remove all drag links
  ]
  ifelse current-mouse-down? and mouse-down? [set mouse-continuous-down? true][set mouse-continuous-down? false]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; reporters ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report random-base-letter
  let r random 4
  let letter-to-report ""
  if r = 0 [set letter-to-report "A"]
  if r = 1 [set letter-to-report "G"]
  if r = 2 [set letter-to-report "T"]
  if r = 3 [set letter-to-report "C"]
  report letter-to-report
end

to-report complementary-base [base]
  let base-to-report ""
  if base = "A" [set base-to-report "T"]
  if base = "T" [set base-to-report "A"]
  if base = "G" [set base-to-report "C"]
  if base = "C" [set base-to-report "G"]
  report base-to-report
end

to-report time-remaining-to-display
  ifelse using-time-limit [report time-remaining][report ""]
end

to-report is-this-cursor-dragging-anything?
  ifelse (any? out-cursor-drag-neighbors) [report true][report false]
end

to-report being-dragged-by-cursor?
  ifelse any? my-in-cursor-drags [report true][report false]
end

to-report all-base-pairs-unwound?
  ifelse any? nucleotides with [not unwound?] [report false][report true]
end

to-report would-these-nucleotides-pair-correctly? [nucleotide-1 nucleotide-2]
  ifelse ( (complementary-base [value] of nucleotide-1) = item 0 [value] of nucleotide-2) [report true][report false ]
end

to-report is-this-nucleotide-paired-correctly?
  let original-nucleotide self
  let this-stair one-of my-new-stairs
  let this-paired-nucleotide nobody
  let overwrite? false
  ask this-stair [set this-paired-nucleotide other-end
    if this-paired-nucleotide != nobody [
      if [class] of this-paired-nucleotide != "copy-of-dna-bottom" and [class] of this-paired-nucleotide  != "copy-of-dna-top" [set overwrite? true];; [set
    ]
  ]
  ifelse (value = (complementary-base [value] of this-paired-nucleotide) and not overwrite?) [report true] [report false ]
end

to-report next-nucleotide-unzipped-the-same?
  let my-unzipped-stage unzipped-stage
  let my-place place
  let my-class class
  let next-nucleotides-available nucleotides with [class = my-class and place = (my-place + 1) and unzipped-stage = my-unzipped-stage]
  let can-continue-to-unzip? false
  ifelse my-place < dna-strand-length [
    ifelse any? next-nucleotides-available and are-previous-nucleotides-unzipped?;;; is another nucleotides in the next sequence in the strand
    [set can-continue-to-unzip? true] [set can-continue-to-unzip? false]
  ]
  [set can-continue-to-unzip? true]  ;; there is no other nucleotides in the next sequence in the strand so no nucleotides will prevent the zipper from opening
  report can-continue-to-unzip?
end


to-report are-previous-nucleotides-unzipped?
  let my-place place
  let previous-nucleotides nucleotides with [place = (my-place - 1)]
  let value-to-return false
  ifelse not any? previous-nucleotides
  [set value-to-return true]
  [
    let previous-nucleotides-are-unzipped previous-nucleotides  with [unzipped-stage > 0]
    ifelse any? previous-nucleotides-are-unzipped [set value-to-return true] [set value-to-return false]
  ]
  report value-to-return
end

to-report user-message-string-for-mutations
  let duplication-rate  precision ( (total-correct-duplications-top-strand + total-correct-duplications-bottom-strand)  / final-time) 4
  report (word "You had " (total-correct-duplications-top-strand + total-correct-duplications-bottom-strand)
    " correct replications and " (total-substitution-mutations-top-strand + total-substitution-mutations-bottom-strand)
    " substitutions and "  (total-deletion-mutations-top-strand + total-deletion-mutations-bottom-strand)  "  deletions."
    " That replication process took you " final-time " seconds.  This was a rate of " duplication-rate
    " correct nucleotides duplicated per second." )
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; instructions for players ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report current-instruction-label
  report ifelse-value current-instruction = 0
    [ "press setup" ]
    [ (word current-instruction " / " length instructions) ]
end

to next-instruction
  show-instruction current-instruction + 1
end

to previous-instruction
  show-instruction current-instruction - 1
end

to show-instruction [ i ]
  if i >= 1 and i <= length instructions [
    set current-instruction i
    clear-output
    foreach item (current-instruction - 1) instructions output-print
  ]
end

to-report instructions
  report [
    [
      "You will be simulating the process"
      "of DNA replication that occurs in"
      "every cell in every living creature"
      "as part of mitosis or meiosis."
    ]
    [
      "To do this you will need to complete"
      "4 tasks in the shortest time you"
      "can. Each of these tasks requires"
      "you to drag a molecule using your"
      "mouse, from one location to another."
    ]
    [
      "The 1st task will be to unwind a "
      "twisted bundle of DNA by using your"
      "mouse to place a topoisomerase "
      "enzyme on top of the primase enzyme."
    ]
    [
      "The 2nd task will be to unzip the"
      "DNA ladder structure by dragging"
      "a helicase enzyme from the 1st "
      "base pair to the last base pair."
    ]
    [
      "The 3rd task will be to first drag"
      "a polymerase enzyme to an open"
      "nucleotide and then drag a floating"
      "nucleoside to the same location."
    ]
    [
      "The last task is to simply repeat"
      "the previous task of connecting"
      "nucleosides to open nucleotides" ;
      "until as much of the DNA as"
      "possible has been replicated."
    ]
    [
      "The simulation ends either when"
      "the timer runs out (if the timer?"
      "chooser is set to YES) or when you"
      "press the DIVIDE THE CELL button"
    ]
  ]
end


; Copyright 2012 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
330
10
1188
519
-1
-1
50.0
1
14
1
1
1
0
1
1
1
0
16
-5
4
1
1
1
ticks
30.0

BUTTON
4
10
74
44
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

SLIDER
4
46
152
79
dna-strand-length
dna-strand-length
1
30
30.0
1
1
NIL
HORIZONTAL

SWITCH
5
116
151
149
nucleo-labels?
nucleo-labels?
0
1
-1000

BUTTON
75
10
152
43
go/stop
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

SWITCH
5
81
151
114
enzyme-labels?
enzyme-labels?
0
1
-1000

MONITOR
15
255
147
300
# deletions
total-deletion-mutations-top-strand
17
1
11

MONITOR
15
298
146
343
# substitutions
total-substitution-mutations-top-strand
17
1
11

TEXTBOX
38
192
147
210
Top Strand
13
0.0
1

MONITOR
15
211
147
256
# correct duplications
total-correct-duplications-top-strand
17
1
11

SWITCH
170
10
305
43
substitutions?
substitutions?
1
1
-1000

SLIDER
171
47
305
80
free-nucleosides
free-nucleosides
0
200
50.0
1
1
NIL
HORIZONTAL

MONITOR
170
210
305
255
# correct duplications
total-correct-duplications-bottom-strand
17
1
11

MONITOR
170
254
305
299
# deletions
total-deletion-mutations-bottom-strand
17
1
11

MONITOR
170
297
305
342
# substitutions
total-substitution-mutations-bottom-strand
17
1
11

TEXTBOX
192
191
297
209
Bottom Strand
13
0.0
1

OUTPUT
5
345
325
492
12

CHOOSER
169
85
304
130
time-limit
time-limit
"none" "2 minutes" "5 minutes"
0

MONITOR
169
134
304
179
time remaining
time-remaining-to-display
0
1
11

BUTTON
5
150
150
184
divide the cell
set cell-divided? true\nset cell-message-shown? false
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
130
495
220
540
instruction
current-instruction-label
17
1
11

BUTTON
220
495
325
540
NIL
next-instruction
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
495
130
540
NIL
previous-instruction
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

@#$#@#$#@
## WHAT IS IT?

In this model you can orchestrate the DNA replication fork process that occurs in the cells of all living creatures before cells divide.  Both mitosis and meiosis rely on this process to make copies of existing DNA before making new cells.

In a real cell, the DNA replication begins by unwinding and unzipping of the twisted double helix structure of DNA at specific location in the genome.  It is then followed by construction of a new DNA strand to match the template strand.  This entire process is aided by many proteins which initiate, facilitate, and terminate the DNA replication process.  It is this process that the model replicates.

As the model runs you will can facilitate the placement and assembly of some of the molecules involved this process by dragging and dropping relevant proteins and nucleosides to help catalyze various reactions at different steps of the process

Alternatively, you can let the model run on its own without interacting with any of the proteins and nucleosides in the model.  As these molecules float freely about the cell nucleus they will eventually make a copy of the DNA strand autonomously, as the eventually wander into the correct locations and configurations that permit them to interact for DNA replication.

By attempting to speed up this process using the mouse cursor you may find that the replication process incurs errors in the duplication.  These errors, though relatively rare in the cell duplication in living organisms do occur, are the basis for some types of mutations.  These mutations will in turn lead to the emergence of new proteins in daughter cells when the DNA is translated.

## HOW IT WORKS

This model is based on simplified representations shown for how DNA polymerase facilitates DNA replication summarized at https://en.wikipedia.org/wiki/DNA_polymerase.

In this model nucleotides are molecules that when joined together make up the structural units of DNA.  Visually this appears as a nitrogen base (represented as a colored polygon) and 1 phosphate group (represented as a yellow circle), and  white line that links these two representing the five-carbon sugar that forms the backbone of DNA.

A nucleoside is represented in this model as an unjoined nucleotide, a five-carbon sugar link and three phosphate groups  (the little yellow circles) attached to it (a nucleoside triphosphate).  A di-phosphate is released through a chemical reaction when a nucleoside (a reactant) bind to the template DNA nucleotides to form a new nucleotide sub-unit (a product) in the new DNA strand copy.

The nitrogen bases for nucleotides and nucleotide come in four variations: ([A]dine, [G]uanine, [T]hymine, [C]ytosine) bound to a ribose or deoxyribose backbone

Four enzymes are included in this model of the DNA replication fork process:

* The entire DNA polymerase enzyme is be modeled as a single agent
* The entire Helicase enzyme will is modeled as a single agent
* The entire Topoisomerase enzyme is modeled as a two agents. That includes a base agent (topoisomares) that maintains a specific heading and a rotating set of "gear shaped" proteins that is attached to it (topoisomare-gears)
* The primase enzyme is used both for showing where Helicase and Topoisomerase should start their work. In reality, primase is used for showing the starting location for where the polymerase enzyme begins duplication, but in this model polymerase can duplicate at any nucleotide that is unwound and unzipped.

When the substitution switch is turned "on", then the polymerase protein does not catch any mismatches between which nitrogen bases are to be paired together in the new DNA strand based on the template DNA strand.  In reality, polymerase can auto-correct many errors and will check and confirm that the correct bases are paired up (e.g. A goes with T and G goes with C).  But in a real cell this is not an error free process.  Other molecules in the cell can interfere with the double checking chemical processes that polymerase can perform.  UV light and other forms of radiation can cause unwanted chemical changes that interfere with correct base pair matching.

When this interference results in a incorrect pairing of bases (e.g. an A with an A, or an A with a G), this is a type of substitution mutation.

When a base is not paired up, or a section of DNA is not replicated, this is known as a deletion mutation.

## HOW TO USE IT

Your goal is to speed up the DNA replication process that occurs in every cell in every living creature as part of mitosis or meiosis.

To do this you will need to complete 4 tasks in the shortest time you can (with the greatest fidelity possible). Each of these tasks requires you to drag a molecule using your mouse, from one location to another.  The 1st task will be to unwind a twisted bundle of DNA by using your mouse to place a topoisomerase enzyme on top of the primase enzyme. The 2nd task will be to unzip the DNA ladder structure by dragging a helicase enzyme from the 1st base pair to the last base pair.  The 3rd task will be to first drag a polymerase enzyme to an open nucleotide and then drag a floating nucleoside to the same location.  The last task is to simply repeat the previous task of connecting nucleosides to open nucleotides until as much of the DNA as possible has been replicated.

To increase the chances that DNA replication coordinated by the user will unintentionally lead to the emergence of two types of mutations (deletions and substitutions), make sure the TIME-LIMIT chooser is set to something other than "none" and make sure the SUBSTITUTIONS? is set to "on".  This last setting allows substitution mutations to occur when incorrect bases are paired up at a polymerase facilitated location.  When set to "off" SUBSTITUTIONS? will ensure no substitution errors can occur (the polymerase will automatically reject any nucleosides that do not pair correctly when it is synthesizing a complementary strand of DNA).

The model will automatically duplicate the entire DNA strand correctly on its own when the TIME-LIMIT is set to "none" and SUBSTITUTIONS? are set to "off".  It just will take a lot more time for the process to be completed than it would if the user were to help it along.

DNA-STRAND-LENGTH sets the length of the initial DNA strand you are going to copy.

SUBSTITUTIONS? when set to "on" it will allow substitution mutations to occur when bases are paired up at a polymerase facilitated location.  When set to "off" it will ensure no substitution errors can occur.

FREE-NUCLEOSIDES sets the number of free floating nucleosides inside this part of the cell.  If you have none, you won't be able to replicate the DNA.  If you have too many, they can tend to interfere (visually) with the sorting and aggregation you are trying to do in the replication process.

ENZYME-LABELS? shows which enzymes are which, using labels.

NUCLEO-LABELS? shows a A,T,G,C label for each nucleotide (including the free floating ones and the ones connected into the sugar backbone of the DNA).

TIME-LIMIT has 3 settings.  "None" Lets you run the model until either forever or until you press the DIVIDE-THE-CELL button.  The other two settings give you a time limit to see how much of the DNA you were able to duplicate correctly.

TIME-REMAINING shows the time left before the model will stop and display how accurate your duplication process was in that time.

NEXT-INSTRUCTION displays the next direction for the user to follow to interact with the model using the mouse (what is necessary to unwind and unzip the DNA strand and then replicate it).

PREVIOUS-INSTRUCTION displays the previous direction.

INSTRUCTION displays which direction out of the total number of directions is currently being displayed.

DIVIDE-THE-CELL marks that you are done with the duplication process and you want the model to calculate the mutations you have accumulated (if any) in the DNA duplication process.  It will report these values:

CORRECT DUPLICATIONS (both for the top and bottom strands).  This is a count of every A that is paired with a T and every G that is paired with a C.

DELETIONS (both for the top and bottom strands).  This is a count of every base pair that was skipped and not paired with any other nucleotide.

SUBSTITUTIONS (both for the top and bottom strands).  This is a count of every A that is paired but not with a T and every G that is paired but not with a C.

## THINGS TO NOTICE

Mutations can be incurred both in the top and bottom strands of DNA.  Since the mutation that affects one strand of DNA is not the same that necessarily affects another strand, different replication mutations may affect different daughter cells in mitosis or meiosis.

## THINGS TO TRY

Compete against another user who also is running their own version of the model at the same time with the SUBSTITUTIONS? setting set to "on".  This element of competition will encourage the emergence of unintentional mutations as each player is tries to increase their rate of duplications, but end up decreasing their fidelity of duplication in the process.

## EXTENDING THE MODEL

Another important type of mutation that could be added to the model is an insertion mutation.  That could be added by allowing more than one base to be paired up at an original nucleotide location.

## NETLOGO FEATURES

The model makes use of transparency features in the color channel for the shape to help see through the many different agents.  This aids the user in being able to keep track of things in the molecular assembly processes.

Shape and color changes of the polymerase molecule simulate the confirmation shape shape changes that the molecule undergoes as it catalyzes various parts of the reaction.

## RELATED MODELS

The DNA Protein Synthesis in BEAGLE is the follow-up model for this one.  It shows how different mutations then lead to different types of proteins produced in cells. It is still under development and will be included in a future release.

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2012).  NetLogo DNA Replication Fork model.  http://ccl.northwestern.edu/netlogo/models/DNAReplicationFork.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2012 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2012 Cite: Novak, M. -->
@#$#@#$#@
default
true
0
Circle -7500403 false true 120 120 60
Polygon -7500403 true true 150 150 165 165 165 195 180 195 180 225 195 225 195 255 210 255 210 285 165 285 165 255 150 255
Polygon -7500403 true true 150 150 135 165 135 195 120 195 120 225 105 225 105 255 90 255 90 285 135 285 135 255 150 255

empty
false
0

helicase
false
0
Polygon -7500403 true true 195 150 180 165 165 165 150 180 135 180 120 195 105 195 90 210 75 210 75 165 105 165 105 150
Polygon -7500403 true true 195 150 180 135 165 135 150 120 135 120 120 105 105 105 90 90 75 90 75 135 105 135 105 150
Circle -1184463 false false 117 117 66

helicase-expanded
false
0
Polygon -7500403 true true 210 150 195 135 180 135 165 120 150 120 135 105 120 105 105 90 75 90 90 135 120 135 135 150
Polygon -7500403 true true 210 150 195 165 180 165 165 180 150 180 135 195 120 195 105 210 75 210 90 165 120 165 135 150
Circle -1184463 false false 117 117 66

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

nucleoside-tri-a
true
0
Line -1 false 75 30 90 75
Polygon -10899396 true false 180 180 150 120 120 180 120 60 180 60
Line -1 false 120 60 90 30
Line -1 false 45 60 75 75
Circle -1184463 true false 69 15 30
Circle -1184463 true false 69 60 30
Circle -1184463 true false 24 45 30

nucleoside-tri-c
true
0
Line -1 false 75 30 90 75
Line -1 false 120 60 90 30
Line -1 false 45 60 75 75
Circle -1184463 true false 69 15 30
Circle -1184463 true false 69 60 30
Circle -1184463 true false 24 45 30
Polygon -11221820 true false 120 60 120 135 135 165 165 165 180 135 180 60

nucleoside-tri-g
true
0
Line -1 false 75 30 90 75
Line -1 false 120 60 90 30
Line -1 false 45 60 75 75
Circle -1184463 true false 69 15 30
Circle -1184463 true false 69 60 30
Circle -1184463 true false 24 45 30
Polygon -8630108 true false 120 60 120 165 135 135 165 135 180 165 180 60

nucleoside-tri-t
true
0
Line -1 false 75 30 90 75
Line -1 false 120 60 90 30
Line -1 false 45 60 75 75
Circle -1184463 true false 69 15 30
Circle -1184463 true false 69 60 30
Circle -1184463 true false 24 45 30
Polygon -955883 true false 120 60 120 120 150 180 180 120 180 60

nucleotide-a
true
0
Line -1 false 75 30 45 60
Line -1 false 120 60 90 30
Circle -1184463 true false 69 15 30
Polygon -10899396 true false 180 180 150 120 120 180 120 60 180 60

nucleotide-c
true
0
Line -1 false 45 60 75 30
Line -1 false 120 61 90 31
Circle -1184463 true false 67 15 30
Polygon -11221820 true false 180 135 180 60 120 60 120 135 135 165 165 165

nucleotide-g
true
0
Polygon -8630108 true false 120 60 120 165 135 135 165 135 180 165 180 60
Line -1 false 120 60 90 30
Line -1 false 45 60 75 30
Circle -1184463 true false 67 15 30

nucleotide-t
true
0
Polygon -955883 true false 120 60 120 120 150 180 180 120 180 60
Line -1 false 120 60 90 30
Line -1 false 45 60 75 30
Circle -1184463 true false 67 17 30

phosphate
true
0
Circle -1184463 true false 129 135 30

phosphate-pair
true
0
Line -1 false 120 135 150 150
Circle -1184463 true false 144 135 30
Circle -1184463 true false 99 120 30

polymerase-0
false
1
Polygon -2674135 true true 120 150 120 60 90 60 75 60 30 60 0 120 0 180 30 240 75 240 90 240 120 240
Rectangle -2674135 true true 90 0 120 60
Rectangle -2674135 true true 90 240 120 300
Rectangle -2674135 false true 120 60 180 240

polymerase-1
false
1
Polygon -2674135 true true 120 150 120 30 90 45 75 60 30 60 0 120 0 180 30 240 75 240 90 240 120 240
Rectangle -2674135 true true 120 30 180 60
Rectangle -2674135 true true 90 240 120 300
Rectangle -2674135 false true 120 60 180 240

polymerase-2
false
1
Polygon -2674135 true true 120 150 120 30 90 45 75 60 30 60 0 120 0 180 30 240 75 240 90 255 120 270
Rectangle -2674135 true true 120 30 180 60
Rectangle -2674135 true true 120 240 180 270
Line -2674135 true 180 60 180 240

polymerase-3
false
1
Polygon -2674135 true true 120 150 120 30 90 45 75 60 30 60 0 120 0 180 30 240 75 240 90 255 120 270
Rectangle -2674135 true true 120 30 180 60
Rectangle -2674135 true true 120 240 180 270

primase
true
1
Polygon -11221820 true false 90 195 75 240 90 270 120 255 150 270 150 300 180 300 180 270 225 255 285 195 285 180 270 165 240 150 210 165 195 165 195 135 180 90 150 90 105 90 75 120 60 150 60 165
Circle -16777216 true false 135 135 30

target
true
0
Circle -7500403 false true 76 76 146
Line -7500403 true 150 60 150 105
Line -7500403 true 150 195 150 240

topoisomerase
true
0
Circle -7500403 true true 45 45 210
Circle -16777216 true false 130 129 44

topoisomerase-gears
true
0
Rectangle -7500403 true true 135 15 165 60
Rectangle -7500403 true true 240 135 285 165
Rectangle -7500403 true true 135 240 165 285
Rectangle -7500403 true true 15 135 60 165
Polygon -7500403 true true 60 255 105 225 75 195 45 240
Polygon -7500403 true true 45 60 75 105 105 75 60 45
Polygon -7500403 true true 240 45 195 75 225 105 255 60
Polygon -7500403 true true 255 240 225 195 195 225 240 255

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
