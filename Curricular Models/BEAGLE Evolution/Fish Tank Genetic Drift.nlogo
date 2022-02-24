breed [fish a-fish]

;; fish parts include fins, tails, and spots - all of
;; which are tied and attached to the main fish body
breed [fish-parts a-fish-part]

;; fish are tied to somatic-cells.  Fish are what
;; wander about (the body of the organism),
;; while the somatic cell contains all the
;; genetic information of the organism
breed [somatic-cells somatic-cell]

;; sex cells that are hatched from somatic cells
;; through a simplified form of meiosis
breed [gamete-cells gamete-cell]

;; alleles are tied to somatic cells or gamete
;; cells - 1 allele is assigned to one chromosome
breed [alleles allele]

breed [fish-bones a-fish-bones]     ;; used for visualization of fish death
breed [fish-zygotes a-fish-zygote]  ;; used for visualization of a fish mating event

;; used for visualization of different types of mouse actions the user can do in the
;; fish tank - namely removing fish and adding/subtracting dividers
breed [mouse-cursors mouse-cursor]

fish-own          [sex bearing]
somatic-cells-own [sex]
gamete-cells-own  [sex]
fish-bones-own    [countdown]
alleles-own       [gene value owned-by-fish? side]

patches-own [type-of-patch divider-here?]

globals [

  ;; for keeping track of the # of alleles of each type
  #-big-B-alleles  #-small-b-alleles
  #-big-T-alleles  #-small-t-alleles
  #-big-F-alleles  #-small-f-alleles
  #-big-G-alleles  #-small-g-alleles
  #-y-chromosomes  #-x-chromosomes

  ;; globals for keeping track of default values for
  ;; shapes and colors used for phenotypes
  water-color
  green-dorsal-fin-color  no-green-dorsal-fin-color
  yellow-tail-fin-color   no-yellow-tail-fin-color
  male-color              female-color
  spots-shape             no-spots-shape
  forked-tail-shape       no-forked-tail-shape

  ;;  globals for keeping track of phenotypes
  #-of-green-dorsal-fins  #-of-no-green-dorsal-fins
  #-of-yellow-tail-fins   #-of-no-yellow-tail-fins
  #-of-spots              #-of-no-spots
  #-of-forked-tails       #-of-no-forked-tails
  #-of-males              #-of-females

  ;; keeps track of whether the mouse button was down on last tick
  mouse-continuous-down?

  num-fish-removed
  num-fish-born
  num-fish-in-tank
  fish-forward-step      ;; size of movement steps each tick
  gamete-forward-step    ;; size of movement steps each tick

  ;; used for spacing the chromosomes out in the
  ;; karyotypes of the somatic cells and gametes
  intra-chromosome-pair-spacing
  inter-chromosome-pair-spacing

  size-of-karyotype-background-for-cells

  initial-#-females
  initial-#-males
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;; setup procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set mouse-continuous-down? false
  set intra-chromosome-pair-spacing 0.20
  set inter-chromosome-pair-spacing 0.55
  set fish-forward-step 0.04
  set num-fish-removed 0
  set num-fish-born 0
  set num-fish-in-tank 0

  ;; the size of the large pink rectangle used as the
  ;; background for the cell or karyotype of the cell
  set size-of-karyotype-background-for-cells 5.2

  set initial-#-females (floor ((initial-females / 100) * carrying-capacity))
  set initial-#-males carrying-capacity - initial-#-females

  set green-dorsal-fin-color    [90 255 90 255]
  set no-green-dorsal-fin-color [176 196 222 255]
  set yellow-tail-fin-color     [255 255 0 255]
  set no-yellow-tail-fin-color  [176 196 255 255]
  set female-color              [255 150 150 255]
  set male-color                [150 150 255 255]
  set water-color               blue - 1.5

  set spots-shape                 "fish-spots"
  set no-spots-shape              "none"
  set forked-tail-shape           "fish-forked-tail"
  set no-forked-tail-shape        "fish-no-forked-tail"
  set-default-shape fish          "fish-body"
  set-default-shape somatic-cells "cell-somatic"
  set-default-shape fish-bones    "fish-bones"

  create-mouse-cursors 1 [
    set shape "x"
    set hidden? true
    set color red
    set heading 0
  ]

  set-tank-regions
  create-initial-gene-pool
  create-initial-fish
  visualize-tank
  visualize-fish-and-alleles
  reset-ticks
end


to set-tank-regions
  let min-pycor-edge min-pycor  let max-pycor-edge max-pycor
  let water-patches nobody
  ask patches [
    set divider-here? false
    set type-of-patch "water"
    ;; water edge are the patches right up against the tank wall on the inside of the
    ;; tank - they are used to determine whether to turn the fish around as they are
    ;; moving about the tank
    if pycor =  (max-pycor-edge - 2) or
      pycor = (min-pycor-edge + 2) or
      pxcor = left-side-of-water-in-tank or
      pxcor = right-side-of-water-in-tank [
      set type-of-patch "water-edge"
    ]
    if pycor >= (max-pycor-edge - 1) [
      set type-of-patch "air"
    ]
    if pxcor <= (left-side-of-water-in-tank - 1) or
      pxcor >= (right-side-of-water-in-tank + 1) or
      pycor <= (min-pycor-edge + 1) [
      set type-of-patch "tank-wall"
    ]
    if pycor = (max-pycor-edge) or
      pycor = (min-pycor-edge) or
      pxcor = (left-side-of-water-in-tank - 2) or
      pxcor >= (right-side-of-water-in-tank + 2) [
      set type-of-patch "air"
    ]
  ]
  set water-patches  patches with [type-of-patch = "water"]
end


to create-initial-gene-pool
  let num-big-alleles 0
  let initial-number-fish (carrying-capacity)

  set num-big-alleles  round ((initial-alleles-big-b * 2 *  initial-number-fish) / 100)
  make-initial-alleles-for-gene 1 "B" "b" num-big-alleles
  set num-big-alleles  round ((initial-alleles-big-t * 2 *  initial-number-fish) / 100)
  make-initial-alleles-for-gene 2 "T" "t" num-big-alleles
  set num-big-alleles  round ((initial-alleles-big-f * 2 *  initial-number-fish) / 100)
  make-initial-alleles-for-gene 3 "F" "f" num-big-alleles
  set num-big-alleles  round ((initial-alleles-big-g * 2 *  initial-number-fish) / 100)
  make-initial-alleles-for-gene 4 "G" "g" num-big-alleles

  make-initial-alleles-for-gene 5 "Y" "X" initial-#-males
end


to create-initial-fish
  ;; makes the cells for the initial fish
  create-somatic-cells initial-#-males [set sex "male"]
  create-somatic-cells initial-#-females [set sex "female"]
  ask somatic-cells [setup-new-somatic-cell-attributes]
  ;; randomly sorts out the gene pool to each somatic cell
  distribute-gene-pool-to-somatic-cells
  ;; grows the body parts from the resulting genotype, and distributes the fish
  ask somatic-cells [grow-fish-parts-from-somatic-cell]
  distribute-fish-in-tank
end


to setup-new-somatic-cell-attributes
  ;; somatic cells are the same as body cells - they are the rectangle shape that is
  ;; tied to the fish and chromosomes that looks like a karyotype
  set heading 0
  set breed somatic-cells
  set color [100 100 100 100]
  set size size-of-karyotype-background-for-cells
  set hidden? true
end


to distribute-fish-in-tank
   let water-patches patches with [type-of-patch = "water"]
   let water-patch nobody
   ask fish [
     move-to one-of water-patches
   ]
end


to make-initial-alleles-for-gene [gene-number allele-1 allele-2 num-big-alleles ]
  let initial-number-fish initial-#-males + initial-#-females
  create-alleles 2 * (initial-number-fish) [
    set gene gene-number
    set shape (word "gene-" gene-number)
    set heading 0
    set owned-by-fish? false
    set value allele-2
    set color  [0 0 0 255]
    set label-color color
    set label (word value "     " )
  ]
  ;; after coloring all the alleles with black band on chromosomes with the
  ;; dominant allele label, now go back and select the correct proportion of
  ;; these to recolor code as recessive alleles with white bands on chromosomes
  ;; and add recessive letter label
  ask n-of num-big-alleles  alleles with [gene = gene-number] [
    set value allele-1
    set color [220 220 220 255]
    set label (word value "     " )
    set label-color color
    ]
end



to distribute-gene-pool-to-somatic-cells
  ;; randomly selects some chromosomes for this cell
  let this-somatic-cell nobody
  let last-sex-allele ""

  ask somatic-cells [
    set this-somatic-cell self
    foreach [ 1 2 3 4 ] [ n ->
      ;; assign one of the alleles to appear on the left side of the chromosome pair
      position-and-link-alleles self n "left"
      ;; assign the other allele to appear on the right side
      position-and-link-alleles self n "right"
    ]

    ;; now assign the sex chromosome pair, putting one of the Xs on the left,
    ;; and the other chromosome (whether it is an X or } on the right
    ask one-of alleles with [not owned-by-fish? and gene = 5 and value = "X"] [
       set owned-by-fish? true
       set size 1.2
       set xcor ((inter-chromosome-pair-spacing * 4) + .1)
       set ycor -0.4
       set side "left"
       create-link-from this-somatic-cell  [
         set hidden? true
         set tie-mode "fixed"
         tie
       ]
    ]
    ifelse sex = "male" [ set last-sex-allele "Y" ] [ set last-sex-allele "X" ]
    ask one-of alleles with [
      not owned-by-fish? and gene = 5 and value = last-sex-allele
    ] [
      set owned-by-fish? true
      set size 1.2
      set xcor ((inter-chromosome-pair-spacing * 4) + intra-chromosome-pair-spacing + .1)
      set ycor -0.4
      set side "right"
      create-link-from this-somatic-cell [
        set hidden? true
        set tie-mode "fixed"
        tie
      ]
    ]
  ]
end


to position-and-link-alleles [this-somatic-cell gene-number which-side]
  let pair-shift-right 0
  let side-shift 0

  ;; adjusts the spacing between chromosome pairs (1-4( so that one of each pair
  ;; is moved to the left and one of each pair is moved to the right
  ifelse which-side = "right"
    [ set side-shift intra-chromosome-pair-spacing ]
    [ set side-shift 0 ]
  set pair-shift-right ((inter-chromosome-pair-spacing * gene-number) - .45)

  ask one-of alleles with [not owned-by-fish? and gene = gene-number] [
    set owned-by-fish? true
    set side which-side
    set size 1.2
    set xcor ([xcor] of this-somatic-cell + (pair-shift-right + side-shift))
    set ycor ([ycor] of this-somatic-cell - 0.4)
    create-link-from this-somatic-cell [
      set hidden? true
      set tie-mode "fixed"
      tie
    ]
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; runtime-procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to go
   wander
   update-statistics
   detect-fish-outside-the-water
   detect-and-move-fish-at-inside-tank-boundary
   auto-selection
   clean-up-fish-bones
   if auto-replace? [find-potential-mates]
   move-gametes-together
   convert-zygote-into-somatic-cell
   detect-mouse-selection-event
   visualize-fish-and-alleles

   visualize-tank
   tick
end


to auto-selection
  if auto-replace? [
    ;; use EVERY to limit the rate of selection
    ;; to slow things down for visualization purposes
    every 0.25 [
      ;;let under-carrying-capacity carrying-capacity -  num-fish-in-tank
      if any? fish [
        ask one-of fish [
          if both-sexes-in-this-fishs-tank-region? [
            remove-this-fish
          ]
        ]
      ]
    ]
  ]
end



to move-gametes-together
  ;; moves the male sex cell (gamete) toward its target
  ;; female sex cell it will fertilize (zygote).
  let my-zygote nobody
  let distance-to-zygote 0
  ;; if the user as the see-sex-cells? switch on then slow down their motion
  ifelse see-sex-cells? [ set gamete-forward-step 0.08] [ set gamete-forward-step 1.0]

   ask gamete-cells [
     set my-zygote one-of fish-zygotes with [in-link-neighbor? myself]
     set distance-to-zygote distance my-zygote
     if distance-to-zygote > 0
      [ face my-zygote
        ifelse distance-to-zygote > gamete-forward-step [fd gamete-forward-step ] [fd distance-to-zygote]
        set heading 0
      ]
   ]
end


to convert-zygote-into-somatic-cell
  ;; upon arriving at the female sex cell the male sex cell will fertilize
  ;; it and disappear the zygote (shown as a heart) will convert into a
  ;; somatic cell and a fish will immediately appear (skipping the time
  ;; it takes for the embryo to form)
  let female-sex-cell-alleles nobody
  let male-sex-cell-alleles nobody
  let male-gamete nobody
  let female-gamete nobody
  let this-somatic-cell nobody

  ask fish-zygotes [
   set male-gamete gamete-cells with [out-link-neighbor? myself and sex = "male"]
   set female-gamete gamete-cells with [out-link-neighbor? myself and sex = "female"]
   if any? male-gamete and any? female-gamete [
     if distance one-of male-gamete <= .01 and distance one-of female-gamete <= .01  [
       ;; close enough for fertilization to be complete
       setup-new-somatic-cell-attributes
       set this-somatic-cell self
       ask male-gamete [
         set male-sex-cell-alleles alleles-that-belong-to-this-gamete
         die
       ]
       ask female-gamete [
         set female-sex-cell-alleles alleles-that-belong-to-this-gamete
         die
       ]
       ask male-sex-cell-alleles [
         create-link-from this-somatic-cell [
           set hidden? true
           set tie-mode "fixed"
           tie
         ]
       ]
       ask female-sex-cell-alleles [
         create-link-from this-somatic-cell [
           set hidden? true
           set tie-mode "fixed"
           tie
         ]
       ]
       align-alleles-for-this-somatic-cell this-somatic-cell
       set sex sex-phenotype
       grow-fish-parts-from-somatic-cell
       set num-fish-born num-fish-born + 1
     ]
   ]
 ]
end


to align-alleles-for-this-somatic-cell [this-zygote]
  ;; when gametes merge they may both have chromosomes on the right
  ;; (for each matching pair) or both on the left
  ;; this procedure moves one of them over if that is the case
  let all-alleles alleles with [in-link-neighbor? this-zygote]
  foreach [1 2 3 4 5] [ this-gene ->
    if count all-alleles with [gene = this-gene and side = "left"]  > 1 [
      ask one-of all-alleles with [gene = this-gene] [
        set heading 90
        forward intra-chromosome-pair-spacing
        set side "right"
      ]
    ]
    if count all-alleles with [gene = this-gene and side = "right"] > 1 [
      ask one-of all-alleles with [gene = this-gene] [
        set heading 90
        back
        intra-chromosome-pair-spacing
        set side "left"
      ]
    ]
  ]
end


to find-potential-mates
  let mom nobody
  let dad nobody
  let xcor-dad 0
  let turtles-in-this-region nobody
  let potential-mates nobody
  let all-fish-and-fish-zygotes nobody

  if any? somatic-cells with [sex = "male"] [
    ask one-of somatic-cells with [ sex = "male" ] [
      set dad self
      set xcor-dad xcor
    ]
    ask dad [
      ;; if  parent genetic information for sexual reproduction
      ;; still exists in the gene pool in this region
      set turtles-in-this-region other-turtles-in-this-turtles-tank-region
    ]
    set all-fish-and-fish-zygotes turtles-in-this-region with [
      breed = fish or breed = fish-zygotes
    ]
    set potential-mates turtles-in-this-region with [
      breed = somatic-cells and sex = "female"
    ]
    if any? potential-mates [
       ask one-of potential-mates  [ set mom self ]
       ;;; only reproduce up to the carrying capacity in this region allowed
       let this-carrying-capacity  carrying-capacity-in-this-region xcor-dad
       if count all-fish-and-fish-zygotes < this-carrying-capacity [
         reproduce-offspring-from-these-two-parents mom dad
       ]
    ]
  ]
end


to reproduce-offspring-from-these-two-parents [mom dad]
  let child nobody
    ask mom [
      hatch 1 [
       set heading 0
       set breed fish-zygotes
       set size 1
       set shape "heart"
       set color red
       set child self
      ]

    ]
    ask mom [ link-alleles-to-gametes-and-gametes-to-zygote child ]
    ask dad [ link-alleles-to-gametes-and-gametes-to-zygote child ]
end


to link-alleles-to-gametes-and-gametes-to-zygote [child]
  let this-new-gamete-cell nobody
  hatch 1 [
    set breed gamete-cells
    set heading 0
    create-link-to child [set hidden? false] ;; link these gametes to the child
    ifelse sex = "male"
      [set shape "cell-gamete-male"]
      [set shape "cell-gamete-female"]

       set this-new-gamete-cell self
    ]

  foreach [1 2 3 4 5] [ this-gene ->
    ask n-of 1 alleles with [in-link-neighbor? myself and  gene = this-gene]
    [hatch 1 [set owned-by-fish? false
       create-link-from this-new-gamete-cell  [set hidden? true  set tie-mode "fixed" tie]
      ]
    ]
  ]

end


to wander
  ask fish [
    set heading bearing
    rt random-float 70 lt random-float 70
    set bearing heading
    fd fish-forward-step
    set heading 0
    ]
  ask somatic-cells [set heading 0]
end



to detect-fish-outside-the-water
     ask fish with [type-of-patch != "water" and type-of-patch != "water-edge"] [  remove-this-fish  ]
end


to detect-and-move-fish-at-inside-tank-boundary
   let nearest-water-patch nobody
   let water-patches patches with [type-of-patch = "water" and not divider-here?]
   ask fish [
    set nearest-water-patch  min-one-of water-patches [distance myself]
    if type-of-patch = "tank-wall" or type-of-patch = "water-edge"   [
      set heading towards nearest-water-patch
      fd fish-forward-step * 2
      set heading 0
      set bearing  random-float 360
    ]
    if divider-here? [move-to nearest-water-patch]
   ]
end


to clean-up-fish-bones
  let bone-transparency 0
  let color-list []
   ask fish-bones [  ;;; fade away progressively the fish bone shape until the countdown in complete
     set countdown countdown - 1
     set bone-transparency (countdown * 255 / 50)
     set color-list lput bone-transparency [255 255 255]
     set color color-list
     if countdown <= 0 [die]
   ]
end


to remove-this-fish
 set num-fish-removed num-fish-removed + 1
 hatch 1 [
   ;; make the fish bones for visualization of this fishes death
   set breed fish-bones
   set color white
   set countdown 25
 ]
 ask out-link-neighbors [
   ;; ask the somatic cells and the fish-parts and the alleles attached to this fish to die first
   ask out-link-neighbors [ die ]
   die
 ]
 die
end


to detect-mouse-selection-event

  let p-mouse-xcor mouse-xcor
  let p-mouse-ycor mouse-ycor
  let p-type-of-patch [type-of-patch] of patch p-mouse-xcor p-mouse-ycor
  let mouse-was-just-down? mouse-down?

  ask mouse-cursors [
    setxy p-mouse-xcor p-mouse-ycor
    ;;;;;;  cursor visualization ;;;;;;;;;;;;
    if (p-type-of-patch = "water") [
      set hidden? false
      set shape "x"
      set label-color white
      set label "remove fish"
    ]
    if divider-here? and p-type-of-patch = "tank-wall" [
      set hidden? false
      set shape "subtract divider"
      set label-color white
      set label "remove divider"
    ]
    if not divider-here? and p-type-of-patch = "tank-wall" [
      set hidden? false
      set shape "add divider"
      set label-color white
      set label "add divider"
    ]
    if (p-type-of-patch != "water" and p-type-of-patch != "tank-wall") [
      set hidden? true
      set shape "x"
      set label ""
    ]
    ;;;;; cursor actions ;;;;;;;;;;;;;;;
    if mouse-was-just-down? [
      ask fish-here [remove-this-fish]
    ]
    if (mouse-was-just-down? and
      not mouse-continuous-down? and
      p-type-of-patch = "tank-wall" and
      pycor = (min-pycor + 1) and
      pxcor > (min-pxcor + 1) and
      pxcor < (max-pxcor - 1)) [
      set divider-here? not divider-here?
      let divider-xcor pxcor
      ask patches with [
        (type-of-patch = "water" or type-of-patch = "water-edge") and
        pxcor = divider-xcor
      ] [
        set divider-here? not divider-here?
      ]
    ]
    ifelse not mouse-inside? [set hidden? true][set hidden? false]
  ]

  ifelse mouse-was-just-down?
    [ set mouse-continuous-down? true ]
    [ set mouse-continuous-down? false ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; calculate statistics procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to update-statistics
  set num-fish-in-tank (count fish )

  set #-big-B-alleles   count alleles with [value = "B"]
  set #-small-b-alleles count alleles with [value = "b"]
  set #-big-T-alleles   count alleles with [value = "T"]
  set #-small-t-alleles count alleles with [value = "t"]
  set #-big-F-alleles   count alleles with [value = "F"]
  set #-small-f-alleles count alleles with [value = "f"]
  set #-big-G-alleles   count alleles with [value = "G"]
  set #-small-g-alleles count alleles with [value = "g"]
  set #-y-chromosomes   count alleles with [value = "Y"]
  set #-x-chromosomes   count alleles with [value = "X"]

  set #-of-green-dorsal-fins     count fish-parts with [color = green-dorsal-fin-color]
  set #-of-no-green-dorsal-fins  count fish-parts with [color = no-green-dorsal-fin-color]
  set #-of-yellow-tail-fins      count fish-parts with [color = yellow-tail-fin-color]
  set #-of-no-yellow-tail-fins   count fish-parts with [color = no-yellow-tail-fin-color]
  set #-of-spots               count fish-parts with [shape = spots-shape and hidden? = false]
  set #-of-no-spots            count fish-parts with [shape = spots-shape and hidden? = true]
  set #-of-forked-tails        count fish-parts with [shape = forked-tail-shape]
  set #-of-no-forked-tails     count fish-parts with [shape = no-forked-tail-shape]
  set #-of-males               count fish with [sex = "male"]
  set #-of-females             count fish with [sex = "female"]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; visualization-procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to visualize-tank
   ask patches with [(type-of-patch = "water" or type-of-patch = "water-edge")] [
     ifelse not divider-here?
       [ set pcolor water-color ]
       [ set pcolor gray - 3.5 ]
   ]
   ask patches with [type-of-patch = "tank-wall" ] [
     ifelse not divider-here?
       [ set pcolor gray - 3 ]
       [ set pcolor gray - 4 ]
     ]
   ask patches with [type-of-patch = "air" ] [
     set pcolor gray + 3
   ]
end


to visualize-fish-and-alleles
  ifelse see-body-cells? [
    ask somatic-cells [
      set hidden? false
      ask alleles with [ in-link-neighbor? myself ] [
        set hidden? false
      ]
    ]
  ] [
    ask somatic-cells [
      set hidden? true
      ask alleles with [ in-link-neighbor? myself ] [
        set hidden? true
      ]
    ]
  ]
  ifelse see-sex-cells? [
    ask gamete-cells [
      set hidden? false
      ask alleles with [ in-link-neighbor? myself ] [
        set hidden? false
      ]
    ]
    ask fish-zygotes [
      set hidden? false
    ]
  ] [
    ask gamete-cells [
      set hidden? true
      ask alleles with [ in-link-neighbor? myself ] [
        set hidden? true
      ]
    ]
    ask fish-zygotes [
      set hidden? true
    ]
  ]
  ifelse see-fish? [
    ask fish [
      set hidden? false
    ]
    ask fish-parts [
      set hidden? false
    ]
  ] [
    ask fish [
      set hidden? true
    ]
    ask fish-parts [
      set hidden? true
    ]
  ]
end


to grow-fish-parts-from-somatic-cell
  let this-fish-body nobody

  hatch 1 [
    set breed fish
    set bearing  random-float 360
    set heading 0
    set size 1
    set this-fish-body self
    if sex = "male" [set color male-color]
    if sex = "female" [set color female-color]
  ]
  create-link-from  this-fish-body  [
    ;; somatic cell will link to the fish body -
    ;; thus following the fish body around as it moves
    set hidden? true
    set tie-mode "fixed"
    tie
  ]

  hatch 1 [
    set breed fish-parts  ;;;make tail
    set breed fish-parts
    set size 1
    set shape tail-shape-phenotype
    set color tail-color-phenotype
    set heading -90 fd .4
    create-link-from this-fish-body [
      ;; fish-parts will link to the fish body -
      ;; thus following the fish body around as it moves
      set hidden? true
      set tie-mode "fixed"
      tie
    ]
  ]
  hatch 1 [                      ;;;make fins
    set breed fish-parts
    set size 1
    set shape "fish-fins"
    set color dorsal-fin-color-phenotype
    create-link-from this-fish-body  [
      ;; fish-parts will link to the fish body -
      ;; thus following the fish body around as it moves
      set hidden? true
      set tie-mode "fixed"
      tie
    ]
  ]

  hatch 1 [                      ;;;make spots
    set breed fish-parts
    set size 1
    set shape rear-spots-phenotype
    set color [ 0 0 0 255]
    create-link-from this-fish-body [
      ;; fish-parts will link to the fish body -
      ;; thus following the fish body around as it moves
      set hidden? true
      set tie-mode "fixed"
      tie
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;; phenotype reporters ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report has-at-least-one-dominant-set-of-instructions-for [dominant-allele]
  let this-somatic-cell self
  let #-of-dominant-alleles count alleles with [in-link-neighbor? this-somatic-cell  and value = dominant-allele]
  ifelse #-of-dominant-alleles > 0  [report true][report false]   ;; if it has at least one set of instructions (DNA) on how to build the protein reports true
end


to-report tail-shape-phenotype
  let this-shape ""
  let this-fish  myself
  ask myself ;; the somatic-cell
  [
    ifelse  has-at-least-one-dominant-set-of-instructions-for "F"
       [set this-shape forked-tail-shape]      ;; tail fin forking results if protein is produced
       [set this-shape no-forked-tail-shape]   ;; no tail fin forking results if protein is not produced (underlying tissue is continuous triangle shape)
  ]
  report this-shape
end


to-report rear-spots-phenotype
  let this-spots-shape ""
  ask myself
  [
    ifelse has-at-least-one-dominant-set-of-instructions-for "B"
       [set this-spots-shape spots-shape]    ;; spots on the rear of the fish result if protein is produced
       [set this-spots-shape no-spots-shape]     ;; no spots on the rear of the fish result if protein is not produced
  ]
  report this-spots-shape
end


to-report dorsal-fin-color-phenotype
  let this-color []
  ask myself
  [
    ifelse  has-at-least-one-dominant-set-of-instructions-for "G"
      [set this-color green-dorsal-fin-color  ]      ;; green color results in dorsal fins if protein is produced
      [set this-color no-green-dorsal-fin-color ]    ;; no green color results in dorsal fins if protein is not produced (underlying tissue color is grayish)
  ]
  report this-color
end


to-report tail-color-phenotype
  let this-color []
  let this-fish  myself
  ask myself
  [
    ifelse  has-at-least-one-dominant-set-of-instructions-for "T"
       [set this-color yellow-tail-fin-color ]     ;; yellow color results in tail fins results if protein is produced
       [set this-color no-yellow-tail-fin-color ]  ;; yellow color results in tail fins if protein is not produced (underlying tissue is continuous triangle shape)
  ]
  report this-color
end


to-report sex-phenotype
  let this-sex ""
  let this-cell self
  ifelse  has-at-least-one-dominant-set-of-instructions-for "Y"
     [set this-sex "male"]
     [set this-sex "female"]
   report this-sex
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; other reporters ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report alleles-that-belong-to-this-gamete
  report alleles with [in-link-neighbor? myself]
end


to-report left-side-of-water-in-tank
  report (min-pxcor) + 2
end


to-report right-side-of-water-in-tank
  report  (max-pxcor) - 2
end



to-report other-turtles-in-this-turtles-tank-region
  ;; when dividers are up, it reports how many turtles are in this region for this turtle
  let turtles-in-this-region nobody
  let xcor-of-this-turtle xcor
  let this-region-left-side left-side-of-water-in-tank
  let this-region-right-side right-side-of-water-in-tank
  let dividers-to-the-right patches with [divider-here? and pxcor > xcor-of-this-turtle]
  let dividers-to-the-left  patches with [divider-here? and pxcor < xcor-of-this-turtle]

  if any? dividers-to-the-right [set this-region-right-side min [pxcor] of dividers-to-the-right ]
  if any? dividers-to-the-left  [set this-region-left-side max [pxcor] of dividers-to-the-left   ]

  set turtles-in-this-region turtles with [xcor >= this-region-left-side and xcor <= this-region-right-side]
  report turtles-in-this-region
end


to-report both-sexes-in-this-fishs-tank-region?
  let fish-in-this-region other-turtles-in-this-turtles-tank-region with [breed = fish]
  let male-fish-in-this-region fish-in-this-region with [sex = "male"]
  let female-fish-in-this-region fish-in-this-region with [sex = "female"]
  ifelse (any? male-fish-in-this-region and any? female-fish-in-this-region ) [report true] [report false]
end



to-report carrying-capacity-in-this-region [this-xcor]
  let this-region-left-side left-side-of-water-in-tank
  let this-region-right-side right-side-of-water-in-tank
  let dividers-to-the-right patches with [divider-here? and pxcor > this-xcor]
  let dividers-to-the-left  patches with [divider-here? and pxcor < this-xcor]

  if any? dividers-to-the-right [ set this-region-right-side min [pxcor] of dividers-to-the-right ]
  if any? dividers-to-the-left  [ set this-region-left-side max [pxcor] of dividers-to-the-left   ]
  let tank-capacity-of-this-region (this-region-right-side - this-region-left-side) * carrying-capacity / 25
  report tank-capacity-of-this-region
end


; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
610
10
1458
467
-1
-1
28.0
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
29
0
15
1
1
1
ticks
30.0

SLIDER
185
150
365
183
initial-alleles-big-b
initial-alleles-big-b
0
100
50.0
1
1
%
HORIZONTAL

BUTTON
15
10
93
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

SWITCH
15
135
175
168
see-body-cells?
see-body-cells?
1
1
-1000

BUTTON
95
10
175
44
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

SLIDER
185
505
365
538
initial-alleles-big-t
initial-alleles-big-t
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
185
270
365
303
initial-alleles-big-g
initial-alleles-big-g
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
185
390
365
423
initial-alleles-big-f
initial-alleles-big-f
0
100
50.0
1
1
%
HORIZONTAL

PLOT
370
370
605
490
Tail Shape Alleles
time
# of
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"big-F" 1.0 0 -16777216 true "" "plotxy ticks #-big-f-alleles"
"small-f" 1.0 0 -4539718 true "" "plotxy ticks #-small-f-alleles"

PLOT
370
490
605
610
Tail Color Alleles
time
# of
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"big-T" 1.0 0 -16777216 true "" "plotxy ticks #-big-t-alleles"
"small-t" 1.0 0 -4539718 true "" "plotxy ticks #-small-t-alleles"

PLOT
370
250
605
370
Dorsal Fin Color Alleles
time
# of
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"big-G" 1.0 0 -16777216 true "" "plotxy ticks #-big-g-alleles"
"small-g" 1.0 0 -4539718 true "" "plotxy ticks #-small-g-alleles"

PLOT
370
10
605
130
Sex Chromosomes
time
# of
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"X" 1.0 0 -16777216 true "" "plotxy ticks #-x-chromosomes"
"Y" 1.0 0 -4539718 true "" "plotxy ticks #-y-chromosomes"

SLIDER
15
50
175
83
carrying-capacity
carrying-capacity
2
60
30.0
1
1
NIL
HORIZONTAL

TEXTBOX
201
561
357
593
TT / Tt / tT --> yellow tail\n              tt --> no yellow
10
0.0
1

TEXTBOX
200
543
365
573
Genotype -->  Phenotype
12
37.0
1

TEXTBOX
200
65
366
84
Genotype ---> Phenotype
12
37.0
1

TEXTBOX
194
186
356
205
Genotype --> Phenotype
12
37.0
1

TEXTBOX
204
303
375
321
Genotype --> Phenotype\n
12
37.0
1

TEXTBOX
200
423
364
442
Genotype --> Phenotype
12
37.0
1

PLOT
611
490
909
610
dorsal fin & spotting variations
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"spots" 1.0 0 -16777216 true "" "plotxy ticks #-of-spots"
"no spots" 1.0 0 -5987164 true "" "plotxy ticks #-of-no-spots"
"green dorsal" 1.0 0 -8330359 true "" "plotxy ticks #-of-green-dorsal-fins"
"no green" 1.0 0 -11033397 true "" "plotxy ticks #-of-no-green-dorsal-fins"

TEXTBOX
207
444
369
478
FF / Ff / fF --> forked tail\n             ff --> no fork
10
0.0
1

TEXTBOX
195
320
365
348
GG / Gg / gG --> green dorsal fin\n                gg --> no green fin
10
0.0
1

PLOT
370
130
605
250
Body Spot Alleles
time
# alleles
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"big-B" 1.0 0 -16777216 true "" "plotxy ticks #-big-b-alleles"
"small-b" 1.0 0 -4539718 true "" "plotxy ticks #-small-b-alleles"

TEXTBOX
241
85
355
118
XX  --> female\nXY  --> male
10
0.0
1

TEXTBOX
200
205
382
246
BB / Bb / bB  -->  black spots\n              bb  --> no black spots
10
0.0
1

SWITCH
15
100
175
133
see-fish?
see-fish?
0
1
-1000

SWITCH
15
170
175
203
see-sex-cells?
see-sex-cells?
1
1
-1000

PLOT
911
490
1183
610
tail fin variations
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"forked tail" 1.0 0 -16777216 true "" "plotxy ticks #-of-forked-tails"
"no fork" 1.0 0 -4539718 true "" "plotxy ticks #-of-no-forked-tails"
"yellow tail" 1.0 0 -4079321 true "" "plotxy ticks #-of-yellow-tail-fins"
"no yellow" 1.0 0 -13791810 true "" "plotxy ticks #-of-no-yellow-tail-fins"

PLOT
1186
490
1458
610
# of males & females
time
# of
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"females" 1.0 0 -4757638 true "" "plotxy ticks #-of-females"
"males" 1.0 0 -11033397 true "" "plotxy ticks #-of-males"

MONITOR
45
365
145
410
fish removed
num-fish-removed
0
1
11

SWITCH
14
268
174
301
auto-replace?
auto-replace?
0
1
-1000

BUTTON
15
230
175
264
Randomly replace a fish
ask one-of fish [ remove-this-fish]\nfind-potential-mates
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
45
320
145
365
fish in tank
num-fish-in-tank
0
1
11

SLIDER
185
30
365
63
initial-females
initial-females
0
100
50.0
1
1
%
HORIZONTAL

MONITOR
45
410
145
455
fish born
num-fish-born
0
1
11

@#$#@#$#@
## WHAT IS IT?

This is a genetic drift model that shows how gene frequencies change in a population due to purely random events.  The effect of random selection of certain individuals in a population (either through death or through reproduction) and/or the effect of random selection as to which chromosome (from every chromosome pair) end up being sorted into each gamete (sex cells), results in the loss or gains of alleles in the population.

Over multiple generations this shift in gene distribution leads to alleles becoming progressively more rare or more common (or disappearing completely) in a population. This effect is called genetic drift.

The underlying mechanism of random selection generates different outcomes than in  natural selection (where individual traits and genes are selected for the advantages they confer on the survival and reproduction of individuals).  In addition to natural selection, however, this random selection and resulting effects of genetic drift is one of the primary mechanisms, which drive evolution.  It is also believed to be one of the mechanisms, which contributes to speciation.

## HOW IT WORKS

The fish have a simple genetic representation for five traits: sex (and corresponding body color), spotting, dorsal fin color, tail shape, and tail color.

These traits are represented with genes that have one of two possible alleles each (X or Y, B or b, G or g, F or f, and T or f, for the traits listed above). Upper case letters represent dominant alleles and lower case represent recessive alleles.  Therefore the three combinations BB, Bb, and bB result in expression of the trait for B (e.g. black spots), and only bb results in the expression of the trait for b (e.g. no black spots). Males and Females are determined by whether the bird has XY (male) or XX (female).  Body color is trait determined by what sex the fish is.  Females are salmon colored and males are blue colored.

Here is the genotype to phenotype mapping:
Spotting: (BB, Bb, bB) yes or (bb) no
Dorsal Fin Color: (GG, Gg, gG) green or (bb) non-green (gray)
Tail Fin Shape: (FF, Ff, fF) forked or (ff) no fork
Tail color: (TT, Tt, tT) yellow or (tt) non-yellow (gray)

A male fish can interbreed with a female fish in the same region of the tank.  By default the tank is all one large region.  But dividers can be added to the tank to split the tank up into separate regions.

The genotype for each fish is represented as a karyotype of a body cell.  A visualization of the chromosome pairs (one pair for each gene) and the corresponding band showing the location of the gene on the chromosome can be seen in the model.

The arrows and hearts in the model represent the movement and recombination of alleles through sexual reproduction.  Arrows represent the movement of the male sex cell to the female sex cell.  The heart represents a fertilization event that will occur when that male sex cell reaches the randomly selected female sex cell.  A karyotype of the alleles in both the body cells (somatic cells) and/or the sex cells (gametes) for all the fish involved in reproduction can also be visualized as this process is occurring.

The model has two random selection mechanisms used for driving the effects of genetic drift.  One of these is the AUTO-REPLACE switch.  It is used to continually remove a randomly selected individual from the population and replace it with an offspring from a randomly selected pair of parents.

## HOW TO USE IT

Press SETUP and you will see the resulting phenotypes in the fish based on the random distribution of the % of each type of allele you have set initially.  Make sure the SEE-FISH? switch is set to "on".

When you run the model the fish in the fish tank begin to move around.  If you click on a fish, that fish will die and be removed.  If AUTO-REPLACE is set to the "On", then one male fish and one female fish will be randomly chosen from the remaining population to reproduce a replacement offspring.  This process will be visible by an arrow from the male, moving toward a heart on the female (if the SEE-SEX-CELLS? is set to "on").  When the arrow collapses down into the heart, the heart will turn into a new fish.


CARRYING-CAPACITY: of the population sets the carrying capacity of the tank. Whatever this is set to, the population will automatically reproduce (if AUTO-REPLACE? is "on") or die off to reach this level.

INITIAL-FEMALES: sets the % of initial females put in the tank.  The initial number of females is the % of the carrying-capacity.

INITIAL-ALLELES-BIG-B: sets the % of alleles related to the gene for black spots in the population that will have the recessive "b" allele.  The % of alleles that will have the dominant "B" (large B) allele will be = (100% - INITIAL-ALLELES-BIG-B).

INITIAL-ALLELES-BIG-G: sets the % of alleles related to the gene for green dorsal fin in the population that will have the "G" allele.  The % of alleles that will have the "G" (large G) allele will be = (100% - INITIAL-ALLELES-BIG-G).

INITIAL-ALLELES-BIG-F: sets the % of alleles related to the gene for forked tail in the population that will have the "f" allele.  The % of alleles that will have the "F" (large F) allele will be = (100% - INITIAL-ALLELES-BIG-F).

INITIAL-ALLELES-BIG-T: sets the % of alleles related to the gene for yellow tail in the population that will have the "t" allele.  The % of alleles that will have the "T" (large T) allele will be = (100% - INITIAL-ALLELES-BIG-T).

SEE-FISH?: when turned "on" allows you to see the fish and their phenotypes.  It may be useful to turn it "off" though when looking at the genotypes (SEE-BODY-CELLS? or SEE-SEX-CELLS) as there may be too much visual information with everything on.

SEE-BODY-CELLS?: when it is set to "on" a karyotype of all the chromosomes in the body cells for this fish will be shown.  Each chromosome has a band on it that is either black or light gray.  If it is black it represents the dominant version of the allele for a given gene and if it is light gray it represents the recessive version.  Letters (Capital for dominant and lower case for recessive) are also shown below the chromosome.  Chromosome pairs for each gene have matching lengths.  And, all but the chromosomes for sex also have matching colors.

SEE-SEX-CELLS?: when it is set to "on", a karyotype of all the chromosomes in each sex cell will be shown.  When reproduction occurs, a sex cell from the male (sperm) must travel to the sex cell from the female (egg).  Sex cells contain half the genetic information of a body cell, and 1 allele for each gene (which is shown as 1 chromosome from each chromosome pair).  The male sex cell is shown as a triangle whose upper left corner makes a right angle.  The female sex cell is shown as a triangle whose lower right corner makes a right angle.  When both triangles meet, they form a whole rectangle and a whole karyotype for a fish.  At this point the heart disappears, the sex cells disappears, and a new body cells of a new fish (and the corresponding new fish) appears.  This entire process is shown as occurring outside the fish, to allow the user to watch the flow of alleles from somatic cells into gametes and back into the new offspring's somatic cells.  This process of "gene flow" is referred to in other mechanisms and phenomena related to evolution.  Here that flow can actually be visualized.  In the model the reproductive process is visualized outside the fish.  In reality, insemination occurs when a sperm cell and an egg cell merge inside a female fish.

RANDOMLY-REPLACE-A-FISH: is a button that when pressed will have the computer select a fish at random to remove and replace it with a new one through reproduction between two randomly selected fish remaining in the population (a male and female). If there are no males or females in the tank, then no fish can be born to replace the fish (there aren't two parents available), and only a fish will be removed but not replaced when that is the case.

You can add dividers to break the tank up into smaller regions, by clicking on the bottom of the tank using your mouse cursor.  The mouse cursor will turn to an up arrow when you are able to do this.  To remove the divider that you put up, hover your mouse cursor over the same spot on the bottom of the tank and the it will turn to a down arrow.  Click the mouse button when you see this down arrow to remove the divider.  When dividers are added, the carrying capacity of each region of the tank is calculated to be the fraction of the water in that portion of the tank out of the whole tank's water times the CARRYING-CAPACITY slider value.

AUTO-REPLACE?: when turned "on" will cause the computer select a fish at random to remove and replace it with a new one every .25 seconds.  The new fish will be an offspring of two randomly selected fish remaining in the population (one male and one female parent).  This can only occur if there is at least one male and at least one female available in that section of the fish tank.  For example, if a tank is divided into two regions, and the right region has only males, and the left region has both males and females, auto-replace will replace fish on the right side only.   If no region has both males and females, then no fish will be replaced in any part of the tank, even when AUTO-REPLACE? is set to "On".

## THINGS TO NOTICE

When fish are randomly replaced fluctuation in the proportion of each allele in the population will occur  This is because only 1 of every two alleles for a gene is passed on to an offspring, and the process of separating out which allele is passed on through a gamete (via. meiosis) is fundamentally a random outcome.  When fluctuations bring the number of alleles down to zero, that allele is gone from the fish population and can't return.

Randomly selecting individuals out of the population and/or randomly producing new offspring will eventually result in this loss of diversity in the gene pool of the population, eventually leading to a single gene or trait in the population.  This process and resulting outcome is referred to as genetic drift.

Larger populations take longer to lose diversity than smaller ones.

Likewise, alleles that are less frequent in a population are more likely to disappear from the population more quickly than those that are more frequent.

Bottle neck affects can be simulated by sweeping the population size down to very low levels and then allowing it to return to higher population sizes.  This can be done by reducing the size of the fish tank and the allowing it to become big again.  Each time the population is reduced to only a few fish, that even increases the chances that one or more alleles have removed from the population and that the remaining population now has less diversity in its traits than its ancestors.

Bottle necks can also be created by adding dividers in the fish tank to separate the main population into smaller sub populations.

One limiting bottleneck factor to notice is related to the proportion of males and females.  A population can be very large overall, but if it only has one or two males than the males end up being a potential bottle neck for what type of genes can be passed on. This is also true if the population has only one or two females.

When pressing SETUP for the same initial conditions for the % of each allele observer will notice that fluctuations occur in the phenotypes of the fish, even as no fluctuations have occurred in frequency of each allele in the gene pool of the population.  This is because of the rules of Mendelian genetics.  Imagine that we have two fish in a population that contains 50% of the alleles as "g" (no instructions for producing the protein for making the green pigmentation of the tail) and 50% of the alleles as "G" (instructions for producing the protein for making the green pigmentation of the tail.  A population where one fish has a GG genotype and the other has a gg genotype would have phenotypes of one fish with a green tail and one without.  But a population where one fish has a Gg genotype and the other has a Gg genotype would have both fish with green tails.  In both populations, however, the number of each type of allele in the gene pool is the same.  This type of fluctuation occurs from generation to generation in the fish.

## THINGS TO TRY

You can watch random selection occur by "random selection" by turning on an auto replace process (which will steadily remove four fish from the population and replace them with new offspring fish from the population every second).

You can set the % of each type of allele you wish to start off with in the gene pool of the population, as well as the % of males and females. If you don't include at least 1 male and 1 female the population will not be able to reproduce.

Try intentionally selecting a particular phenotype to remove from the fish and keep selecting to see how many selections it takes to remove all that variants from the population.  If the trait variation you are trying to remove is apparent only when two recessive alleles are present, you may see the trait resurface in future generations (due to the recombination of the recessive alleles in offspring). Watch the graphs to see if you have removed the corresponding alleles completely.

Try predicting the resulting phenotype of an offspring fish, by turning SEE-FISH? and SEE-BODY-CELLS to "off" and SEE-SEX-CELLS? "on".  As the sex cells are moving toward each other, pause the model (by pressing GO/STOP).  Look at the rules for genotype ---> phenotype mapping and write your prediction down for the phenotype of the offspring.  Switch the SEE-FISH? back to "on" and resume the model, to see if your prediction was correct.

Vary the size of the initial fish tank to explore how fast genetic drift occurs in different population sizes.

Simulate the reduction the effects of a disease, temporary loss of habitat, temporary loss of food, etc.. by reducing the carrying capacity of the ecosystem for a brief time.  Do this by reducing the size of the fish tank to sweep away some portion of the fish (e.g. over half of them).  Then simulate the ecosystem returning to it previous stable state, by increasing the fish tank size to it previous level.

Try adding barriers in the fish tank (by clicking on the black bottom of the fish tank) to geographically isolate portions of the population from one another.  You can cause the isolated sub population to lose diversity of traits and alleles, but the overall population to keep the allele diversity needed for any variation.

## NETLOGO FEATURES

Transparency is used to visualize the death of fish.  When a fish dies, the fish shape is removed and a bone shape appears and then gradually fades to transparent when a fish is removed from the population.

Directional links are used to visualize the transmission of a gamete to a "fertilization event" (shown as a heart)

Tie is used to build hierarchies of shapes that belong to parent shapes.  For example, sex cells and body cells have parent shapes (karyotypes) thank have other shapes linked to them (chromosomes - which represent the alleles).  And the fish shape has fish parts that are linked to it, each part a phenotype determined by the genetic information of the body cell of the parent.

## EXTENDING THE MODEL

It might be useful to add the code that allows you to drag agents (fish) around using a mouse cursor.  That way you could move a fish from one region to another to explore what happens when a pioneer brings in new genes into a gene pool from a previously isolated population.

## RELATED MODELS

GenDrift models in the Genetic Drift folder, under Biology
Bug Hunt Drift, under BEAGLE Evolution folder, under Curricular Resources

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2011).  NetLogo Fish Tank Genetic Drift model.  http://ccl.northwestern.edu/netlogo/models/FishTankGeneticDrift.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Novak, M. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

add divider
true
0
Polygon -7500403 true true 0 180 45 225 150 135 255 240 300 195 150 60

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

cell-gamete-female
false
0
Polygon -2064490 true false 150 210 300 210 300 150
Rectangle -1 false false 150 150 300 210

cell-gamete-male
false
13
Polygon -11221820 true false 150 150 150 210 300 150
Rectangle -1 false false 150 150 300 210

cell-somatic
false
0
Rectangle -2064490 true false 150 150 300 210

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

fish-body
false
11
Polygon -8630108 true true 15 135 151 92 226 96 280 134 292 161 292 175 287 185 270 210 195 225 151 227 15 165
Circle -16777216 true false 236 125 34
Line -1 false 256 143 264 132

fish-bones
false
15
Rectangle -1 true true 45 150 210 165
Polygon -1 true true 210 180 210 210 270 195 240 180 285 165 285 150 270 120 225 90 195 135 210 165
Circle -16777216 true false 236 110 34
Line -1 true 180 90 195 210
Line -1 true 150 90 180 210
Line -1 true 120 105 150 210
Line -1 true 90 120 120 195
Line -1 true 60 135 75 180

fish-fins
false
2
Polygon -955883 true true 45 0 75 45 71 103 75 120 165 105 120 30
Polygon -955883 true true 75 180 45 240 90 225 105 270 135 210

fish-forked-tail
false
5
Polygon -10899396 true true 150 135 105 75 45 0 75 90 105 150 75 195 45 300 105 225 150 165

fish-no-forked-tail
false
1
Polygon -2674135 true true 150 135 120 60 75 0 60 75 60 150 60 210 75 300 120 240 150 165

fish-spots
false
15
Circle -1 true true 84 129 12
Circle -1 true true 66 161 12
Circle -1 true true 92 162 22
Circle -1 true true 114 99 24
Circle -1 true true 39 129 24
Circle -1 true true 129 144 12

fish-ventral-fin
false
11
Polygon -7500403 true false 60 180 15 240 75 225 90 270 150 210

gene-1
false
15
Rectangle -11221820 true false 135 60 150 165
Rectangle -1 true true 135 105 150 135

gene-2
false
15
Rectangle -1184463 true false 135 75 150 150
Rectangle -1 true true 135 90 150 135

gene-3
false
15
Rectangle -2064490 true false 135 75 150 135
Rectangle -1 true true 135 75 150 105

gene-4
false
15
Rectangle -13840069 true false 135 75 150 135
Rectangle -1 true true 135 105 150 135

gene-5
false
15
Rectangle -1 true true 135 60 150 150

gene-y
false
15
Rectangle -1 true true 135 60 150 105

heart
false
0
Polygon -7500403 true true 60 105 60 135 90 180 120 210 150 225 165 105
Circle -7500403 true true 60 60 90
Circle -7500403 true true 150 60 90
Polygon -7500403 true true 240 105 240 135 210 180 180 210 150 225 150 105

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

none
true
0

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
Rectangle -7500403 true true 15 15 285 285
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

subtract divider
true
0
Polygon -7500403 true true 0 120 45 75 150 165 255 60 300 105 150 240

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
