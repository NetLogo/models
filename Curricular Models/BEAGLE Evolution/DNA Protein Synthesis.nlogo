;;;;;;;;;;;;; DNA molecules  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; keeps a list of the dna code for a given gene
breed [genes gene]

;; the pieces that are inside the dna chain
breed [nucleotides nucleotide]

;; a visualization agent (similar to a promoter protein)
;; that attaches to every start codon location in a DNA chain
breed [promoters promoter]

;; a visualization agent that attaches to every stop codon location in a DNA chain
breed [terminators terminator]

;;;;;;;;;;;;; mRNA molecules  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; the pieces that are inside the mRNA chain
breed [mRNA-nucleotides mRNA-nucleotide]

;; the tail ends of the mRNA chain
breed [mRNAs mRNA]

;;;;;;;;;;;;; tRNA molecules  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; the center piece of the tRNA complex
breed [tRNAs tRNA]

;; the pieces that are inside the tRNA complex
breed [tRNA-nucleotides tRNA-nucleotide]

;; the top part of the tRNA complex
breed [amino-acids amino-acid]

;;;;;;;;;;;;; protein molecules  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [proteins protein]                    ;; holds proteins information

;;;;;;;;;;;;; tags for supporting a fine tuned placement of labels ;;;;;;;;;;;;;
breed [tags tag]

;;;;;;;;;;;;; links ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; the link between an agent and where its label agent is.
;; This allows fine tuned placement of visualizing of labels
undirected-link-breed [taglines tagline]

;; the link between adjacent amino acids in a protein.
;; It will allows the entire protein to be folded up
;; (not currently implemented)
directed-link-breed   [backbones backbone]

;;;;;;;;;;;;;;;;;;;turtle variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
genes-own            [gene-number strand code start-position end-position]
mRNAs-own            [gene-number strand code cap-type traveling? released?]
promoters-own        [gene-number strand]
terminators-own      [gene-number strand]
tRNAs-own            [gene-number strand]
proteins-own         [gene-number strand value]
amino-acids-own      [gene-number strand value place]
nucleotides-own      [gene-number strand value place]
mRNA-nucleotides-own [gene-number strand value place]
tRNA-nucleotides-own [gene-number strand value place]
tags-own [
  value ; the value for the label of the agent it is linked to when visualized.
]



;;;;;;;;;;;;;globals ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [

  current-instruction               ;; holds counter value for which instruction is being displayed
  codon-to-amino-acid-key           ;; holds lookup table for codon triplet to amino acid
  original-dna-string               ;; holds a string of the original DNA
  duplicate-dna-string              ;; holds a string of the duplicate DNA.  This changes every time the replicate DNA button is pressed

  ;; position values for visualization
  duplicate-ribosome-ycor
  original-ribosome-ycor
  duplicate-dna-ycor
  original-dna-ycor
  nucleotide-spacing

  ;; colors for various agents and states of agents
  nucleo-tag-color
  terminator-color
  gene-color-counter

  ;; counters for the number of genes
  original-strand-gene-counter
  duplicate-strand-gene-counter
  original-display-mrna-counter
  duplicate-display-mrna-counter

  mRNAs-traveling                    ;; list of mRNAs traveling
  mRNAs-released                     ;; list of mRNAs released

  ;; for keeping track of user initiated events
  replicate-dna-event?
  show-genes-event?
  event-1-triggered?
  event-2-triggered?
  event-3-triggered?
  event-4-triggered?
  event-6-triggered?
  event-7-triggered?
  event-8-triggered?
  event-9-triggered?
  event-1-completed?
  event-2-completed?
  event-3-completed?
  event-4-completed?
  event-6-completed?
  event-7-completed?
  event-8-completed?
  event-9-completed?
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;setup procedures;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set replicate-dna-event? false
  set show-genes-event? false

  set event-1-triggered? false
  set event-2-triggered? false
  set event-3-triggered? false
  set event-4-triggered? false
  set event-6-triggered? false
  set event-7-triggered? false
  set event-8-triggered? false
  set event-9-triggered? false
  set event-1-completed? false
  set event-2-completed? false
  set event-3-completed? false
  set event-4-completed? false
  set event-6-completed? false
  set event-7-completed? false
  set event-8-completed? false
  set event-9-completed? false


  set mRNAs-traveling []
  set mRNAs-released  []
  set codon-to-amino-acid-key []
  set original-dna-string ""
  set duplicate-dna-string ""

  set duplicate-ribosome-ycor -7
  set original-ribosome-ycor 4
  set duplicate-dna-ycor -2
  set original-dna-ycor 1
  set gene-color-counter 1
  set nucleotide-spacing .45

  set original-strand-gene-counter 0
  set duplicate-strand-gene-counter 0
  set original-display-mrna-counter 0
  set duplicate-display-mrna-counter 0

  set-default-shape promoters "start"
  set-default-shape terminators "end"
  set-default-shape tags "empty"

  set terminator-color      [255 0 0 150]
  set nucleo-tag-color      [255 255 255 120]

  initialize-codon-to-amino-acid-key
  setup-starting-dna
  visualize-all-genes
  ask patches [set pcolor blue - 4]
  ask patches with [pycor > 2]  [set pcolor blue - 3.5]
  ask patches with [pycor < 0]  [set pcolor green - 4]
  ask patches with [pycor < -3] [set pcolor green - 3.5]
  show-instruction 1
  reset-ticks
end


to setup-starting-dna
  setup-dna-string
  build-genes-from-dna "original" original-dna-string
  make-a-nucleotide-chain-for-dna-string "original" original-dna-string
  place-dna "original"
  build-mrna-for-each-gene "original"
  build-protein-from-mrna  "original"
  place-trnas "original"
  hide-mrna   "original"
  hide-trna   "original"
  hide-genes  "original"
end



;; original-dna-string
to setup-dna-string
  if initial-dna-string = "from user-created-code" [set original-dna-string dna-string-with-non-nucleotide-characters-replaced user-created-code]
  if initial-dna-string = "random (short strand)" [
    let initial-length-dna 12
    repeat initial-length-dna [set original-dna-string (word original-dna-string random-base-letter-DNA)]
  ]
  if initial-dna-string = "random (long strand)"  [
    let initial-length-dna 56
    repeat initial-length-dna [set original-dna-string (word original-dna-string random-base-letter-DNA)]
  ]
  if initial-dna-string = "no genes (short strand)" [set original-dna-string "ATTATATCGTAG"]
  if initial-dna-string = "no genes (long strand)"  [set original-dna-string "GATATTTGGTAGCCCGAGAAGTGGTTTTTCAGATAACAGAGGTGGAGCAGCTTTTAG"]
  if initial-dna-string = "1 short gene"            [set original-dna-string "ATTATGTGGTAG"]
  if initial-dna-string = "1 long gene"             [set original-dna-string "GGGATGGACACCTTATCATTTGCTACTAGCGACCAGTTTGAGTAGCTTCGTCGGTGA"]
  if initial-dna-string = "2 sequential genes"      [set original-dna-string "AGTATGAAAACCCACGAGTGGTAGCCCGAGATTGAGATGTGGTTTTTCAGATAACAG"]
  if initial-dna-string = "2 nested genes"          [set original-dna-string "GTTATGAGGGGGACCCGAGATGTGGTTTTTGAAATAGACAAGTAGACCCTAATAGAC"]
  if initial-dna-string = "3 sequential genes"      [set original-dna-string "GATATGTGGTAGCCCGAGATGTGGTTTTTCAGATAACAGATGTGGAGCAGCTTTTAG"]
end


to place-dna [strand-type]
  let dna (turtle-set genes nucleotides promoters terminators)
  ask dna with [strand = strand-type][
    if strand-type = "original"  [set ycor original-dna-ycor]
    if strand-type = "duplicate" [set ycor duplicate-dna-ycor]
  ]
end


to place-trnas [strand-type]
  ask tRNAs with [strand = strand-type] [
    if strand-type = "original"   [set ycor original-ribosome-ycor + 1]
    if strand-type = "duplicate"  [set ycor duplicate-ribosome-ycor + 1]
  ]
end


to make-a-nucleotide-chain-for-dna-string [strand-type dna-string]
  let previous-nucleotide nobody
  let place-counter 0
  create-turtles 1 [
    set heading 90
    fd 1
    repeat (length dna-string) [
        hatch 1 [
          set breed nucleotides
          set strand strand-type
          set value item place-counter dna-string
          set shape (word "nucleotide-" value)
          set heading 0
          set place place-counter
          attach-tag 5 0.5 value nucleo-tag-color
          set place-counter place-counter + 1
          ]
       fd nucleotide-spacing
       ]
   die ;; remove the chromosome builder (a temporary construction turtle)
  ]
end



to build-genes-from-dna [strand-type dna-string]
  let remaining-dna dna-string
  let this-item ""
  let last-item ""
  let last-last-item ""
  let triplet ""
  let item-position 0
  let last-item-kept length dna-string
  repeat (length dna-string) [
    let first-item item 0 remaining-dna
    set remaining-dna remove-item 0 remaining-dna
    set last-last-item last-item
    set last-item this-item
    set this-item first-item
    set triplet (word last-last-item last-item this-item)
    if triplet = "ATG" [
      create-genes 1 [
        set hidden? true
        set strand strand-type
        if strand = "original"  [
          set original-strand-gene-counter original-strand-gene-counter + 1
          set gene-number original-strand-gene-counter
        ]
        if strand = "duplicate" [
          set duplicate-strand-gene-counter duplicate-strand-gene-counter + 1
          set gene-number duplicate-strand-gene-counter
        ]
        set start-position item-position
        set end-position ((length original-dna-string))
        set code (word triplet substring dna-string (item-position + 1) ((length dna-string) ) )
        ]
     ]
     set item-position item-position + 1
  ]
  ask genes [
    let end-of-gene? false
    let triplet-counter 0
    let new-code code
    repeat floor (length code / 3)  [
      let this-triplet (word  (item (0 + (triplet-counter * 3)) code)  (item (1 + (triplet-counter * 3)) code)  (item (2 + (triplet-counter * 3)) code) )
      if (this-triplet =  "TAG" or this-triplet = "TGA"  or this-triplet = "TAA") and not end-of-gene? [
        set end-position triplet-counter * 3
        set new-code substring code 0 end-position
        set end-of-gene? true
      ]
      set triplet-counter triplet-counter + 1
    ]
    set triplet-counter 0
    set end-of-gene? false
    set code new-code
  ]

end


to build-mRNA-for-each-gene [strand-type]
  ask genes with [strand = strand-type] [
    let this-code code
    let this-gene self

    set heading 90
    fd .1
    repeat start-position [fd .45] ;; move over to correct nucleotide location on dna

    let gene-color next-gene-color
    let gene-color-with-transparency (sentence (extract-rgb gene-color) 110)
    let gene-color-label (sentence (extract-rgb gene-color) 250)
    ;; make promoter for start codon
    hatch 1 [
      set breed promoters
      set color gene-color-with-transparency
      set size 3
      set hidden? false
      attach-tag 142 1.7 (word "start:" gene-number) gene-color-label
      create-backbone-from this-gene [set hidden? true set tie-mode "fixed" tie]
      ;; make terminator for end codon
      hatch 1 [
        set breed terminators
        fd ((length this-code) * 0.45)
        attach-tag 142 1.7 (word "end:" gene-number) gene-color-label
        create-backbone-from this-gene [set hidden? true set tie-mode "fixed" tie]
      ]
    ]
     ;; make start cap for mRNA molecule
    hatch 1 [
      let this-mRNA self
      set breed mRNAs
      set traveling? false
      set released? false
      set code mrna-string-from-dna-string code
      set cap-type "start"
      set shape "mrna-start"
      set hidden? false
      ;; associate the mRNA molecule with the parent gene
      create-backbone-from this-gene [set hidden? true set tie-mode "fixed" tie]
      ;; build a stop cap for the mRNA molecule
      hatch 1 [
        set cap-type "stop"
        set shape "mrna-stop"
        let nucleotide-counter 0
        ;; associate the mRNA stop cap with the start cap
        create-backbone-from this-mRNA  [set hidden? true set tie-mode "fixed" tie]
        ;; use the stop cap turtle to construct the mRNA nucleotides
        let code-to-transcribe code
        repeat length code [
          hatch 1 [
            set breed mRNA-nucleotides
            set value first code-to-transcribe
            set shape (word "mrna-" value)
            set heading 180
            attach-tag 175 0.9 value nucleo-tag-color
            create-backbone-from this-mRNA  [set hidden? true set tie-mode "fixed" tie]
          ]
          set code-to-transcribe remove-item 0 code-to-transcribe
          fd nucleotide-spacing
        ]
      ]
    ]
  ]
end


to build-protein-from-mrna [strand-type]
  ask mRNAs with [cap-type = "start" and strand = strand-type] [
    let number-of-triplets-in-list floor ((length code) / 3)
    let this-triplet ""
    let triplet-counter 0
    repeat number-of-triplets-in-list   [
      set this-triplet (word
        complementary-mRNA-base  (item (0 + (triplet-counter * 3)) code)
        complementary-mRNA-base  (item (1 + (triplet-counter * 3)) code)
        complementary-mRNA-base  (item (2 + (triplet-counter * 3)) code)
        )
      build-tRNA-for-this-triplet  this-triplet triplet-counter
      set triplet-counter triplet-counter + 1
    ]
  ]
end



to build-tRNA-for-this-triplet [this-triplet triplet-counter]
  let this-tRNA nobody
  hatch 1 [
    set breed tRNAs
    set this-tRNA self
    set shape "tRNA-core"
    set size 1.2
    set heading 0
    hatch 1 [
      set breed amino-acids
      set value  (which-protein-for-this-codon this-triplet)
      set shape (word "amino-" value)
      set heading 0
      set size 2
      fd 1
      create-backbone-from this-tRNA  [set hidden? true set tie-mode "free" tie]
      attach-tag 20 .8 value nucleo-tag-color
    ]
    hatch 1 [
      set breed tRNA-nucleotides
      set shape (word "trna-" (item 0 this-triplet))
      set heading -155
      fd 1.1
      set heading 0
      create-backbone-from this-tRNA  [set hidden? true set tie-mode "fixed" tie]
      hatch 1 [
        set breed tRNA-nucleotides
        set shape (word "trna-" (item 1 this-triplet))
        set heading 90
        fd .45
        set heading 0
        create-backbone-from this-tRNA  [set hidden? true set tie-mode "fixed" tie]
      ]
      hatch 1 [
        set breed tRNA-nucleotides
        set shape (word "trna-" (item 2 this-triplet))
        set heading 90
        fd .90
        set heading 0
        create-backbone-from this-tRNA  [set hidden? true set tie-mode "fixed" tie]
      ]
    ]
    fd 1
    set heading 90
    fd nucleotide-spacing + ( nucleotide-spacing * 3 * triplet-counter )
    set heading 0
  ]
end


;; fine tuned placement of the location of a label for a nucleoside or nucleotide
to attach-tag [direction displacement label-value color-value]
  hatch 1 [
    set heading direction
    fd displacement
    set breed tags
    set label label-value
    set size 0.1
    set label-color color-value
    create-tagline-with myself [set tie-mode "fixed" set hidden? true tie]
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; visibility procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to visualize-all-genes
   ask (turtle-set promoters terminators)[ask tagline-neighbors [set hidden? not show-genes?] set hidden? not show-genes?]
end


to hide-genes  [strand-type]
   ask (turtle-set promoters terminators)  with [strand = strand-type] [ask tagline-neighbors [set hidden? true] set hidden? true]
end


to hide-mrna  [strand-type]
   ask (turtle-set mRNAs mrna-nucleotides) with [strand = strand-type] [ask tagline-neighbors [set hidden? true] set hidden? true]
end


to hide-trna  [strand-type]
   ask (turtle-set tRNAs trna-nucleotides amino-acids) with [strand = strand-type] [ask tagline-neighbors [set hidden? true] set hidden? true]
end


to show-next-mrna  [strand-type]
  let these-genes genes with [strand = strand-type]
  if count these-genes = 0 [display-user-message-no-genes]
  if strand-type = "original" [
    set original-display-mrna-counter original-display-mrna-counter + 1
    if (original-display-mrna-counter > count these-genes) [set original-display-mrna-counter 1]
    ask mRNAs with [strand = strand-type and cap-type = "start"] [
      ifelse gene-number != original-display-mrna-counter
        [ask out-backbone-neighbors [set hidden? true ask tagline-neighbors [set hidden? true] ] set hidden? true]
        [ask out-backbone-neighbors [set hidden? false ask tagline-neighbors [set hidden? false] ] set hidden? false]
      set traveling? false set released? false set ycor original-dna-ycor
    ]
  ]
  if strand-type = "duplicate" [
    set duplicate-display-mrna-counter duplicate-display-mrna-counter + 1
    if (duplicate-display-mrna-counter > count these-genes) [set duplicate-display-mrna-counter 1]
    ask mRNAs with [strand = strand-type and cap-type = "start"] [
      ifelse gene-number != duplicate-display-mrna-counter
        [ask out-backbone-neighbors [set hidden? true ask tagline-neighbors [set hidden? true] ] set hidden? true]
        [ask out-backbone-neighbors [set hidden? false ask tagline-neighbors [set hidden? false]] set hidden? false]
      set traveling? false set released? false set ycor duplicate-dna-ycor
    ]
  ]
end


to show-next-trna  [strand-type]
  let this-gene-number gene-number-for-this-strand strand-type
  ask mRNAs with [strand = strand-type and cap-type = "start" and released? and gene-number = this-gene-number ] [
    ask tRNAs with [strand = strand-type] [
      ifelse gene-number = this-gene-number
        [ask out-backbone-neighbors [set hidden? false ask tagline-neighbors [set hidden? false] ] set hidden? false]
        [ask out-backbone-neighbors [set hidden? true ask tagline-neighbors [set hidden? true] ] set hidden? true]
      ]
  ]
end


to display-user-message-no-genes
  user-message "There are no genes in this strand of DNA. A specific sequence of 3 nucleotides is required for a gene"
end


to release-next-protein  [strand-type]
  let make-protein? false
  let this-gene-number gene-number-for-this-strand strand-type
  ask mRNAs with [strand = strand-type and cap-type = "start" and released?  and gene-number = this-gene-number ] [

    ask tRNAs with [strand = strand-type] [
      ifelse gene-number = this-gene-number
        [ask out-backbone-neighbors [
         set make-protein? true
         set hidden? true
           ifelse breed = amino-acids
             [set hidden? false ask tagline-neighbors [set hidden? false] ]
             [set hidden? true ask tagline-neighbors [set hidden? true] ]
           ]
         ]
         [ask out-backbone-neighbors [set hidden? true ask tagline-neighbors [set hidden? true] ] set hidden? true]
         set hidden? true
    ]
    if make-protein? [make-protein strand-type ]
  ]
end


to make-protein [strand-type]
  let this-gene-number gene-number-for-this-strand strand-type
  let this-protein-value ""
  let these-amino-acids amino-acids with [breed = amino-acids and strand-type = strand and gene-number = this-gene-number]
  let ordered-amino-acids sort-on [who] these-amino-acids
  foreach ordered-amino-acids [ the-amino-acid ->
    set this-protein-value (word   this-protein-value "-" ([value] of the-amino-acid))
  ]
  if not any? proteins with [strand = strand-type and value = this-protein-value] [
      hatch 1 [set breed proteins set value this-protein-value set hidden? true setxy 0 0]
  ]
end


to release-next-mRNA-from-nucleus [strand-type]
  ask mRNAs with [strand = strand-type][set traveling? true set released? false]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; runtime procedures ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  visualize-all-genes
  ;; these boolean variables keep track of button press events being cued by the user
  if event-1-triggered? [
    show-next-mrna "original"
    set event-1-triggered? false
    set event-1-completed? true
    set event-2-completed? false
    set event-3-completed? false
    set event-4-completed? false
  ]
  if event-2-triggered? and event-1-completed? [
    release-next-mRNA-from-nucleus "original"
    set event-2-triggered? false
    set event-3-completed? false
    set event-4-completed? false
  ]
  if event-3-triggered? and event-2-completed? [
    show-next-trna "original"
    set event-3-triggered? false
    set event-3-completed? true
    set event-4-completed? false
  ]
  if event-4-triggered? and event-3-completed? [
    release-next-protein "original"
    set event-4-triggered? false
    set event-4-completed? true
  ]
  if event-6-triggered? [
    show-next-mrna "duplicate"
    set event-6-triggered? false
    set event-6-completed? true
    set event-7-completed? false
    set event-8-completed? false
    set event-9-completed? false
  ]
  if event-7-triggered? and event-6-completed? [
    release-next-mRNA-from-nucleus "duplicate"
    set event-7-triggered? false
    set event-8-completed? false
    set event-9-completed? false
  ]
  if event-8-triggered? and event-7-completed? [
    show-next-trna "duplicate"
    set event-8-triggered? false
    set event-8-completed? true
    set event-9-completed? false
  ]
  if event-9-triggered? and event-8-completed? [
    release-next-protein "duplicate"
    set event-9-triggered? false
    set event-9-completed? true
  ]
  move-mRNA-molecules-out-of-nucleus
  tick
end


to move-mRNA-molecules-out-of-nucleus
  ask mRNAs with [traveling? and cap-type = "start"] [
    if strand = "original" [
      if ycor < original-ribosome-ycor [ set ycor ycor + .1 ]
      if ycor >= original-ribosome-ycor [ set traveling? false set released? true set event-2-completed? true]
    ]
    if strand = "duplicate" [
      if ycor > duplicate-ribosome-ycor [ set ycor ycor - .1]
      if ycor <= duplicate-ribosome-ycor [ set traveling? false set released? true set event-7-completed? true]
    ]
  ]
end


to show-protein-production
  clear-output
  let original-proteins proteins with [strand = "original"]
  output-print "Proteins Produced"
  output-print (word "from original DNA  = " count original-proteins)
  output-print "::::::::::::::::::"
  ask original-proteins [
    output-print (word "Orig.Gene #" gene-number " > Protein:")
    output-print value
    output-print ""
  ]
  output-print "=================="
  let duplicate-proteins  proteins with [strand = "duplicate"]
  output-print "Proteins Produced"
  output-print (word "from copy of DNA = " count duplicate-proteins)
  output-print "::::::::::::::::::"
  ask duplicate-proteins [
    output-print (word "Copy.Gene #" gene-number " > Protein:")
    output-print value
    output-print ""
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; make duplicate dna procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-duplicate-dna-string
  let position-counter 0
  set duplicate-strand-gene-counter 0
  let clean-duplicate-dna-string original-dna-string
  let mutating-copy-of-dna-string original-dna-string

    let target-loci random ((length mutating-copy-of-dna-string) - #-nucleotides-affected)
    let dna-at-target item target-loci mutating-copy-of-dna-string
    let dna-before-target substring mutating-copy-of-dna-string 0 target-loci
    let loci-counter 0
    let dna-at-and-after-target substring mutating-copy-of-dna-string target-loci length mutating-copy-of-dna-string

    if mutation-type = "deletion" [
      repeat #-nucleotides-affected [
        set  mutating-copy-of-dna-string remove-item target-loci mutating-copy-of-dna-string
      ]
    ]
    if mutation-type  = "substitution" [
      repeat #-nucleotides-affected [
        set mutating-copy-of-dna-string (replace-item (target-loci + loci-counter) mutating-copy-of-dna-string random-base-letter-DNA)
        set loci-counter loci-counter + 1
      ]
    ]
    if mutation-type  = "insertion" [
      repeat #-nucleotides-affected [
        set  dna-at-and-after-target (word random-base-letter-DNA  dna-at-and-after-target)
      ]
      set mutating-copy-of-dna-string (word dna-before-target dna-at-and-after-target)
    ]

 set duplicate-dna-string mutating-copy-of-dna-string
end


to replicate-dna
  let turtles-to-remove (turtle-set nucleotides mRNAs tRNAs genes promoters terminators amino-acids mrna-nucleotides)
  ;; (re)build the everything for the duplicate dna
  ask turtles-to-remove with [strand = "duplicate" ][ask tagline-neighbors [die] die]            ;; wipe out old nucleotides
  make-duplicate-dna-string
  build-genes-from-dna "duplicate" duplicate-dna-string
  make-a-nucleotide-chain-for-dna-string "duplicate" duplicate-dna-string
  place-dna "duplicate"
  build-mrna-for-each-gene "duplicate"
  build-protein-from-mrna "duplicate"
  place-trnas "duplicate"
  hide-mrna   "duplicate"
  hide-trna   "duplicate"
  hide-genes  "duplicate"
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; initializing lists and strings ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to initialize-codon-to-amino-acid-key
   set codon-to-amino-acid-key [
     ;;all triplets where the 2nd base is U
     ["UUU" "Phe"] ["UUC" "Phe"] ["UUA" "Leu"] ["UUG" "Leu"]
     ["CUU" "Leu"] ["CUC" "Leu"] ["CUA" "Leu"] ["CUG" "Leu"]
     ["AUU" "Ile"] ["AUC" "Ile"] ["AUA" "Ile"] ["AUG" "Met"]
     ["GUU" "Val"] ["GUC" "Val"] ["GUA" "Val"] ["GUG" "Val"]
     ;;all triplets where the 2nd base is C
     ["UCU" "Ser"] ["UCC" "Ser"] ["UCA" "Ser"] ["UCG" "Ser"]
     ["CCU" "Pro"] ["CCC" "Pro"] ["CCA" "Pro"] ["CCG" "Pro"]
     ["ACU" "Thr"] ["ACC" "Thr"] ["ACA" "Thr"] ["ACG" "Thr"]
     ["GCU" "Ala"] ["GCC" "Ala"] ["GCA" "Ala"] ["GCG" "Ala"]
     ;;all triplets where the 3rd base is A
     ["UAU" "Tyr"] ["UAC" "Tyr"] ["UAA" "Stop"] ["UAG" "Stop"]
     ["CAU" "His"] ["CAC" "His"] ["CAA" "Gln"] ["CAG" "Gln"]
     ["AAU" "Asn"] ["AAC" "Asn"] ["AAA" "Lys"] ["AAG" "Lys"]
     ["GAU" "Asp"] ["GAC" "Asp"] ["GAA" "Glu"] ["GAG" "Glu"]
     ;;all triplets where the 4th base is G
     ["UGU" "Cys"] ["UGC" "Cys"] ["UGA" "Stop"] ["UGG" "Trp"]
     ["CGU" "Arg"] ["CGC" "Arg"] ["CGA" "Arg"] ["CGG" "Arg"]
     ["AGU" "Ser"] ["AGC" "Ser"] ["AGA" "Arg"] ["AGG" "Arg"]
     ["GGU" "Gly"] ["GGC" "Gly"] ["GGA" "Gly"] ["GGG" "Gly"]
     ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; reporters ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;; returns values such as "Gly" for "GGA" or "Tyr" for "UAC" using the codon-to-amino-acid-key
to-report which-protein-for-this-codon [this-codon]
 report item 1 (item 0 filter [ pair -> first pair = this-codon] codon-to-amino-acid-key )
end

;;; reports a random base for a nucleotide in DNA
to-report random-base-letter-DNA
  let r random 4
  let letter-to-report ""
  if r = 0 [set letter-to-report "A"]
  if r = 1 [set letter-to-report "G"]
  if r = 2 [set letter-to-report "T"]
  if r = 3 [set letter-to-report "C"]
  report letter-to-report
end

;;; reports a complementary base for a base pairing given the nucleotide from DNA or mRNA
to-report complementary-mRNA-base [base]
  let base-to-report ""
  if base = "A" [set base-to-report "U"]
  if base = "T" [set base-to-report "A"]
  if base = "U" [set base-to-report "A"]
  if base = "G" [set base-to-report "C"]
  if base = "C" [set base-to-report "G"]
  report base-to-report
end


;; cycles through next color in base-color list to assign to the next gene
to-report next-gene-color
  ifelse gene-color-counter >= (length base-colors) - 1
   [set gene-color-counter 0]
   [set gene-color-counter gene-color-counter + 1 ]
  report (item gene-color-counter base-colors)
end


to-report gene-number-for-this-strand [strand-type]
  let this-gene-number 0
  if strand-type = "original"  [set this-gene-number original-display-mrna-counter]
  if strand-type = "duplicate" [set this-gene-number duplicate-display-mrna-counter]
  report this-gene-number
end


;; reports the mrna code that gets transcribed from the dna
to-report mrna-string-from-dna-string [dna-string]
  let new-string dna-string
  let next-item 0
  repeat length dna-string [
    set new-string (replace-item next-item new-string (complementary-mRNA-base (item next-item new-string))  )
    set next-item next-item + 1
  ]
  report new-string
end

;; reports a string of dna where any A, G, C, T letter is replaced with a random one of these, and any length beyond
;; characters is deprecated
to-report dna-string-with-non-nucleotide-characters-replaced [dna-string]
  let new-string dna-string
  let next-item 0
  repeat length dna-string [
    set new-string (replace-item next-item new-string (replace-non-nucleotide-character (item next-item new-string))  )
    set next-item next-item + 1
  ]
  if length dna-string > 64 [set new-string substring new-string 0 64]
  report new-string
end

;; replaces any A, G, C, T letter is replaced with a random one of these
to-report replace-non-nucleotide-character [nucleotide-character]
   let character-to-return nucleotide-character
   if nucleotide-character != "A" and nucleotide-character != "T" and nucleotide-character != "C" and nucleotide-character != "G"
     [set character-to-return random-base-letter-DNA]
   report character-to-return
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; instructions for players ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report current-instruction-label
  report ifelse-value current-instruction = 0
    [ "press setup" ]
    [ (word current-instruction " of " length instructions) ]
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
     "of protein synthesis from DNA that"
     "occurs in every cell.  And you will"
     "explore the effects of mutations"
     "on the proteins that are produced."
    ]
    [
     "When you press SETUP, a single"
     "strand of an unwound DNA molecule"
     "appears. This represents the state"
      "of DNA in the cell nucleus during"
     "transcription."
    ]
    [
     "To produce proteins, each gene in"
     "the original DNA strand must be"
     "transcribed  into an mRNA molecule."
     "Do this by pressing GO/STOP and"
     "then the 1-TRANSCRIBE button."
    ]
    [
     "For each mRNA molecule that was"
     "transcribed, press the 2-RELEASE"
     "button.  This releases the mRNA"
     "from the nucleus  into the ribosome"
     "of the cell."
    ]
    [
     "For each mRNA molecule in the"
     "ribosome, press the 3-TRANSLATE"
     "button.  This pairs up molecules"
     "of tRNA with each set of three"
     "nucleotides in the mRNA molecule."
    ]
    [
      "For each tRNA chain built, press"
      "the 4-RELEASE button.  This"
      "releases the amino acid chain"
      "from the rest of the tRNA chain,"
      "leaving behind the protein"
      "molecule that is produced."
    ]
    [
      "Each time the 1-TRANSCRIBE"
      "button is pressed, the next gene"
      "in the original strand of DNA "
      "will be transcribed.  Press the 1-,"
      "2-, 3-, 4- buttons and repeat to"
      "translate each subsequent gene."
    ]
    [
      "When you press the 5-REPLICATE"
      "THE ORIGINAL DNA button a copy"
      "of the original DNA will be "
      "generated for a new cell"
      "(as in mitosis or meiosis) and"
      "it will appear in the green."
    ]
    [
      "The replicated DNA will have a"
      "# of random mutations, set by"
      "#-NUCLEOTIDES-AFFECTED, each"
      "mutation of the type set by"
      "MUTATION-TYPE. Press button 5)"
      "again to explore possible outcomes."
    ]
    [
      "Now repeat the same transcription,"
      "release, translation, and release"
      "process for the DNA in this new"
      "cell by pressing 6-, 7-, 8-, 9-."
      "Repeat that sequence again to"
      "cycle through to the next gene."
    ]
    [
      "If you want to test the outcomes"
      "for your own DNA code, type any"
      "sequence of A, G, T, C in the"
      "USER-CREATED-CODE box and set"
      "the INITIAL-DNA-STRING to"
      "“from-user-code”.  Then press"
      "SETUP and start over again."
    ]
  ]
end



to reset-completed-events

  if event-1-triggered? or  event-2-triggered? or event-3-triggered? or event-4-triggered? [
    set event-4-completed? false
    if event-1-triggered? or  event-2-triggered? or event-3-triggered? [
      set event-3-completed? false
      if event-1-triggered? or  event-2-triggered?  [
        set event-2-completed? false
        if event-1-triggered?  [ set event-1-completed? false ]
      ]
    ]
  ]
  if event-6-triggered? or event-7-triggered? or event-8-triggered? or event-9-triggered? [
    set event-9-completed? false
    if event-6-triggered? or  event-7-triggered? or event-8-triggered? [
      set event-8-completed? false
      if event-6-triggered? or  event-7-triggered?  [
        set event-7-completed? false
        if event-6-triggered?  [ set event-6-completed? false ]
      ]
    ]

  ]


end


; Copyright 2012 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
465
10
1217
403
-1
-1
24.0
1
9
1
1
1
0
1
1
1
0
30
-8
7
1
1
1
ticks
30.0

BUTTON
5
10
75
50
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
75
10
165
50
go / stop
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

CHOOSER
5
285
255
330
initial-dna-string
initial-dna-string
"from user-created-code" "no genes (short strand)" "no genes (long strand)" "1 short gene" "1 long gene" "2 sequential genes" "2 nested genes" "3 sequential genes" "random (short strand)" "random (long strand)"
4

INPUTBOX
5
330
255
390
user-created-code
AAAAA
1
0
String

BUTTON
265
210
455
246
5. replicate the original DNA
replicate-dna\nvisualize-all-genes
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
5
205
255
238
#-nucleotides-affected
#-nucleotides-affected
1
6
1.0
1
1
NIL
HORIZONTAL

CHOOSER
5
240
125
285
mutation-type
mutation-type
"deletion" "insertion" "substitution"
2

BUTTON
280
145
370
179
3. translate
if event-2-completed? [\n  set event-3-triggered? true\n  reset-completed-events\n]
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
280
92
370
127
1. transcribe
set event-1-triggered? true\nreset-completed-events
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
370
145
446
179
4. release
if event-3-completed? [\n  set event-4-triggered? true\n  reset-completed-events\n]
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
295
30
352
71
genes
original-strand-gene-counter
17
1
10

MONITOR
340
280
440
321
proteins made
count proteins with [strand = \"duplicate\"]
17
1
10

TEXTBOX
306
263
462
281
Replicated DNA in new cell
11
54.0
1

BUTTON
370
92
445
127
2. release
if event-1-completed? [\n  set event-2-triggered? true\n  reset-completed-events\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

OUTPUT
5
85
255
205
12

MONITOR
291
280
341
321
genes
duplicate-strand-gene-counter
17
1
10

BUTTON
280
340
370
373
6. transcribe
set event-6-triggered? true\nreset-completed-events
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
370
340
445
373
7. release
if event-6-completed? [\n  set event-7-triggered? true\n  reset-completed-events\n]
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
280
395
365
428
8. translate
if event-7-completed? [\n  set event-8-triggered? true\n  reset-completed-events\n]
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
365
395
445
428
9. release
if event-8-completed? [\n  set event-9-triggered? true\n  reset-completed-events\n]
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
336
79
426
97
DNA-->mRNA
9
103.0
1

TEXTBOX
329
382
419
400
mRNA-->protein
9
54.0
1

TEXTBOX
331
131
424
149
mRNA-->protein
9
103.0
1

MONITOR
346
30
441
71
proteins made
count proteins with [strand = \"original\"]
17
1
10

TEXTBOX
334
325
421
343
DNA-->mRNA
9
54.0
1

TEXTBOX
312
12
446
40
Original DNA in old cell
11
103.0
1

TEXTBOX
272
8
322
42
<--
16
14.0
1

SWITCH
130
245
260
278
show-genes?
show-genes?
0
1
-1000

BUTTON
5
395
255
428
10.  show protein production summary
show-protein-production
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
262
195
282
216
 V
16
14.0
1

TEXTBOX
270
18
285
204
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|
14
14.0
1

TEXTBOX
274
261
317
281
-->
16
14.0
1

TEXTBOX
270
243
285
274
|\n
14
14.0
1

TEXTBOX
267
256
282
276
V
16
14.0
1

BUTTON
145
50
255
83
next instruction
next-instruction
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
50
145
83
previous instruction
previous-instruction
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
165
10
255
51
instruction #
current-instruction-label
17
1
10

@#$#@#$#@
## WHAT IS IT?

This model allows you to explore the effects of deletion, substitution, and insertion mutations on a single strand of DNA and the subsequent outcomes in related protein synthesis in cells.  The model represents effects from mutations that include 1) the number of genes that are encoded in the DNA, 2) the mRNA molecules that are transcribed, and 3) the tRNA molecules that are used to transcribe the mRNA into an amino acid chain, as wells as 4) the subsequent protein that is synthesized.

## HOW IT WORKS

In this model nucleotides are molecules, that when joined together, make up the structural units of DNA.  Visually this appears as single nitrogen base (represented as a colored polygon) and 1 phosphate group (represented as a yellow circle).  Only a single strand of the double stranded DNA molecule is show in this model, as the protein synthesis process starts with the doubled stranded DNA being unwound into two single strands to permit mRNA production.

The nitrogen bases for DNA come in four variations: ([A]denine, [G]uanine, [T]hymine, [C]ytosine) bound to a ribose or deoxyribose backbone.

The same nitrogen bases are used for mRNA and tRNA, as for DNA, except no [T]hymine is used.  Instead it is replaced with [U]racil.

Genes start locations in DNA in this model don't use promoters to initiate transcription of a particular gene, like they do in reality.  Rather, the start codon (encoded by a three letter sequence of nucleotides [ATG], when read from a particular direction),  signals the start of transcription for mRNA.  In reality, ATG start condons are the first codon in mRNA that is translated by ribosome.  Therefore, in reality mRNA often contains additional non-translated nucleotides, before the start codon in mRNA and additional non-translated nucleotides after the stop codons in mRNA.

In this model, however, that complexity of additional "dangling" non-transcribed mRNA has been eliminated by setting the start codon as the site for transcription of DNA to mRNA and the stop codon as the site for ending transcription of DNA to mRNA as well.

In this model, transcription reading of DNA occurs from left to right.   Gene stop locations are encoded either by the first three letter sequence (either [] or [] or []) that is encountered, which is the same reading frame as the ATG sequence at the start of the gene.  Reading frames may be shifted by 0, 1, or 2 nucleotides from the start of the gene.  Stop signals have three possible three nucleotides sequences ([TAG], [TGA], or [TAA])

If the first letter of the three letter sequence for stop has any multiple of 3 nucleotides between it and the last letter of the ATG marking the start, then it is in the same frame of reference and will apply as a stop signal for this gene.  If not, the stop signal is ignored.  If no stop signal is found in the DNA, the gene end will continue until end of the entire DNA strand (the far right side of the DNA in this model).


In order for DNA to produce proteins for each gene, the following four steps must be followed by the user, after GO/STOP is pressed to start running the model.

1.  For each gene an mRNA molecule must be transcribed.  This is done by pressing the  1-TRANSCRIBE for genes in the original strand of DNA or 6-TRANSCRIBE for the genes in the duplicated strand of DNA.  Each time this button is pressed, the next gene in the strand of DNA will be transcribed.  When the last gene is reached, then the next gene chosen to transcribe will be the first gene (reading from left to right).

2.  For each mRNA molecule that was transcribed in the original DNA, the 2-RELEASE button must be pressed.  For each mRNA molecule that was transcribed in the duplicated DNA, the 7-RELEASE button must be pressed.  This simulates the release of the mRNA from the nucleus into the ribosome of the cell.

3.  Once the mRNA has finished moving in to the ribosome, the 3-TRANSLATE button must be pressed to translate the mRNA in the original cell and the 8-TRANSLATE button must be pressed to translate the mRNA in the replicated cell.  This pairs a tRNA molecule with each set of three nucleotides in the mRNA molecule.

4.  Once the entire mRNA molecule has been paired with tRNA, the 4-RELEASE button must be pressed to release the amino acid chain from that attached to the tRNA chain in the original cell.  And the 9-RELEASE button must be pressed to release it in the replicated cell.  This amino-acid chain is the protein molecule before it folds up to take on its tertiary structure.

## HOW TO USE IT

NEXT-INSTRUCTION button moves the text in the instruction window forward one "page".

PREVIOUS-INSTRUCTION button moves the text in the instruction window back one "page".

INSTRUCTION # reports the "page" of text in the instruction window being displayed.  These are each of the pages of instructions that the user can page through as they run the model:

Instruction 1: You will be simulating the process of protein synthesis from DNA that occurs in every cell and the effects of mutations on the proteins that are produced.

Instruction 2: When you press SETUP, a single strand of an unwound DNA molecule appears. This represents the state of DNA in the cell nucleus during transcription.

Instruction 3: To produce proteins, each gene in the original DNA strand must be transcribed  into an mRNA molecule.  Do this by pressing  the 1-TRANSCRIBE button.

Instruction 4: For each mRNA molecule that was transcribed, press the 2-RELEASE button.  This releases the mRNA from the nucleus  into the ribosome of the cell.

Instruction 5: For each mRNA molecule in the ribosome, press the 3-TRANSLATE button.  This pairs up tRNA molecules with each set of three nucleotides  in the mRNA molecule.

Instruction 6: For each tRNA chain built, press the 4-RELEASE button.  This releases the amino acid chain from the rest of the tRNA chain, leaving behind the protein molecule that is produced.

Instruction 7: Each time the 1-TRANSCRIBE button is pressed, the next gene in the original strand of DNA will be transcribed.  Press the 1-, 2-, 3-, 4-, buttons and repeat to translate each subsequent gene into a protein.

Instruction 8: When you press the 5-REPLICATE THE ORIGINAL DNA button a copy of the original DNA will be generated for a new cell (as in mitosis or meiosis) and appear in the green.

Instruction 9: The replicated DNA will have a number of random mutations, set by #-NUCLEOTIDES-AFFECTED, each mutation of the type set by MUTATION-TYPE. Press button 5-REPLICATE THE ORIGINAL DNA  again to explore possible outcomes.

Instruction 10: Now repeat the same transcription, release, translation, and release process for the DNA in this new cell.  To do that, press 6-, 7-, 8-, 9- buttons.  Again repeat that sequence to cycle through each gene in this mutated DNA.

Instruction 11: If you want to test the outcomes for your own DNA code, type any sequence of A, G, T, C in the USER-CREATED-CODE  box and set the INITIAL-DNA-STRING
to “from-user-code”.  The default is set to "AAAAA", but any sequence of letters can be processed.  Strings longer than 64 letters will be trimmed to the first 64 letters and letters that are not A, G, T, or C, will be randomly replaced by one of these letters.


Other Setting Information:

SHOW-GENES? controls whether the start and end codons for each gene are visibly tagged in the DNA.

INITIAL-DNA-STRING can be set to "from user-created-code" (see above), or to any of the following: "no genes (short strand)", "no genes (long strand)", "1 short gene", "1 long gene", "2 sequential genes", "2 nested genes", "3 sequential genes", "random (short strand)", "random (long strand)".  Both random settings are fixed length, but random code in that length of DNA.

Buttons 1-4 affect the original cell's DNA.
Button 5 affects the duplicated DNA that ends up in the new cell
Buttons 6-9 affect the duplicated cell's DNA

The 10-SHOW PRODUCTION SUMMARY button reports all the proteins that produced in both the original cell and in the duplicated cell.

MUTATION-TYPE can be set to deletion, insertion or substitution.  The number of nucleotides affected is set by #-NUCLEOTIDES-AFFECTED.  So 6 substitutions will place 6 random nucleotides in place of back to back sequence of 6 original nucleotides at a random location in the DNA.  And 4 insertions will add 4 random nucleotides in sequence at a random location in the DNA.  And 3 deletions will delete 3 random nucleotides in sequence at a random location in the DNA.

## THINGS TO NOTICE

Sometimes the end location for 1 gene is the same as for another gene.  This may make it hard to distinguish the numbering of each of the tags for these end locations, since when they are stacked on top of each other at the same location, their text and colors overlap.

Some mutations introduce brand new genes into a strand of DNA.  Some mutations remove an entire gene in a strand of DNA.  Some only affect a few of the amino acids that used in protein synthesis.  Others affect many.  And some mutation affect the non-coding regions of DNA, resulting in no effects in the proteins produced by the cell.

## THINGS TO TRY

Start with a section of DNA with no genes.  How often does a mutation result in the emergence of new gene?

Start with a section of DNA with one or more genes.  How often does a mutation result in the disappearance of an old gene?

Are there certain types of mutations (deletion, insertion, or substitution) that seem to affect the structure of the resulting protein more than others?

Why do certain numbers of nucleotides affected (e.g. 3 and 6) seem to affect some aspects of the genes more frequently and not others?

## EXTENDING THE MODEL

A representation of protein folding could be added to the model (where each neighboring amino acid affects the amount of relative change in orientation to the previous amino acid).

## NETLOGO FEATURES

The model makes use of transparency features in the color channel for the shapes of the start and stop codons in order to allow the user to see the DNA structure beneath them.

The model makes use of "tag" turtles.  These breeds of turtles have no visible shape, but do have text labels displayed.  They are placed at a fine tuned position near the visible turtle it is helping provide a label for and is linked to it.

## RELATED MODELS

DNA Replication Fork is the precursor model to this one.  It shows how two types of mutations (deletion and substitution) cam emerge when DNA is duplicated in mitosis or meiosis through simple unintentional copying errors.

## CREDITS AND REFERENCES

This model is a part of the BEAGLE curriculum (http://ccl.northwestern.edu/rp/beagle/index.shtml)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Novak, M. and Wilensky, U. (2012).  NetLogo DNA Protein Synthesis model.  http://ccl.northwestern.edu/netlogo/models/DNAProteinSynthesis.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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

amino acid
true
0
Polygon -7500403 false true 105 135 150 165 195 135 195 90 150 60 105 90 105 135
Line -7500403 true 150 210 150 180
Line -7500403 true 120 255 195 255
Line -7500403 true 150 240 150 210
Circle -7500403 true true 135 240 30
Polygon -1184463 true false 255 255 240 270 195 270 180 255 195 240 240 240
Polygon -13345367 true false 45 255 60 270 105 270 120 255 105 240 60 240
Circle -2674135 true false 135 195 30
Circle -2674135 true false 135 150 30
Circle -2674135 true false 90 120 30
Circle -2674135 true false 90 75 30
Circle -2674135 true false 135 45 30
Circle -2674135 true false 180 75 30
Circle -2674135 true false 180 120 30

amino-ala
true
0
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 225
Polygon -1184463 true false 248 259 233 274 188 274 173 259 188 244 233 244
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24

amino-arg
true
0
Line -7500403 true 120 75 150 75
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 45
Polygon -1184463 true false 247 259 232 274 187 274 172 259 187 244 232 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 137 176 24
Circle -1184463 true false 138 102 24
Circle -2674135 true false 138 139 24
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -7500403 true true 138 64 24
Circle -1184463 true false 108 64 24
Circle -1184463 true false 138 27 24

amino-asn
true
0
Line -7500403 true 120 187 150 187
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 150
Polygon -1184463 true false 247 259 232 274 187 274 172 259 187 244 232 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 137 176 24
Circle -1184463 true false 138 139 24
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -13791810 true false 106 175 24

amino-asp
true
0
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 120
Polygon -1184463 true false 247 259 232 274 187 274 172 259 187 244 232 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -7500403 true true 137 176 24
Circle -13791810 true false 138 102 24
Circle -13791810 true false 138 139 24
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244

amino-cys
true
0
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 180
Polygon -1184463 true false 247 259 232 274 187 274 172 259 187 244 232 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -13840069 true false 137 176 24
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244

amino-gln
true
0
Line -7500403 true 120 150 150 150
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 120
Polygon -1184463 true false 247 259 232 274 187 274 172 259 187 244 232 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 137 176 24
Circle -1184463 true false 138 102 24
Circle -7500403 true true 138 139 24
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -13791810 true false 108 139 24

amino-glu
true
0
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 75
Polygon -1184463 true false 247 259 232 274 187 274 172 259 187 244 232 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 137 176 24
Circle -13791810 true false 138 102 24
Circle -7500403 true true 138 139 24
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -13791810 true false 138 64 24

amino-gly
true
0
Line -7500403 true 119 259 194 259
Polygon -1184463 true false 248 259 233 274 188 274 173 259 188 244 233 244
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -7500403 true true 138 248 24

amino-his
true
0
Polygon -7500403 false true 195 225 240 225 255 180 217 154 180 180
Line -7500403 true 150 225 195 225
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 225
Polygon -1184463 true false 248 259 233 274 188 274 173 259 188 244 233 244
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 183 214 24
Circle -2674135 true false 228 214 24
Circle -1184463 true false 243 169 24
Circle -1184463 true false 168 169 24
Circle -2674135 true false 206 143 24

amino-ile
true
0
Line -7500403 true 121 226 151 226
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 150
Polygon -1184463 true false 247 259 232 274 187 274 172 259 187 244 232 244
Circle -7500403 true true 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 137 176 24
Circle -1184463 true false 138 139 24
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -2674135 true false 106 214 24

amino-leu
true
0
Line -7500403 true 105 135 150 165
Line -7500403 true 150 165 195 135
Line -7500403 true 150 210 150 180
Line -7500403 true 120 255 195 255
Line -7500403 true 150 240 150 210
Circle -7500403 true true 135 240 30
Polygon -1184463 true false 255 255 240 270 195 270 180 255 195 240 240 240
Polygon -13345367 true false 45 255 60 270 105 270 120 255 105 240 60 240
Circle -2674135 true false 135 195 30
Circle -2674135 true false 135 150 30
Circle -2674135 true false 90 120 30
Circle -2674135 true false 180 120 30

amino-lys
true
0
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 90
Polygon -1184463 true false 248 259 233 274 188 274 173 259 188 244 233 244
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 137 176 24
Circle -1184463 true false 138 64 24
Circle -2674135 true false 138 102 24
Circle -2674135 true false 138 139 24

amino-met
true
0
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 105
Polygon -1184463 true false 247 259 232 274 187 274 172 259 187 244 232 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 137 176 24
Circle -2674135 true false 138 102 24
Circle -13840069 true false 138 139 24
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244

amino-phe
true
0
Polygon -7500403 false true 119 147 120 180 150 195 180 179 179 146 150 131 119 148
Line -7500403 true 149 224 149 194
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 149 223
Polygon -1184463 true false 248 259 233 274 188 274 173 259 188 244 233 244
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 138 183 24
Circle -2674135 true false 139 120 24
Circle -2674135 true false 109 135 24
Circle -2674135 true false 109 168 24
Circle -2674135 true false 167 135 24
Circle -2674135 true false 167 168 24

amino-pro
true
0
Line -7500403 true 210 210 195 255
Line -7500403 true 135 210 180 180
Line -7500403 true 165 180 210 210
Line -7500403 true 120 255 195 255
Line -7500403 true 135 210 150 255
Circle -7500403 true true 135 240 30
Polygon -1184463 true false 255 255 240 270 195 270 180 255 195 240 240 240
Polygon -13345367 true false 45 255 60 270 105 270 120 255 105 240 60 240
Circle -2674135 true false 160 166 30
Circle -2674135 true false 120 195 30
Circle -2674135 true false 195 195 30

amino-ser
true
0
Line -7500403 true 150 210 150 180
Line -7500403 true 120 255 195 255
Line -7500403 true 150 240 150 210
Circle -7500403 true true 135 240 30
Polygon -1184463 true false 255 255 240 270 195 270 180 255 195 240 240 240
Polygon -13345367 true false 45 255 60 270 105 270 120 255 105 240 60 240
Circle -2674135 true false 135 195 30
Circle -2064490 true false 135 150 30

amino-thr
true
0
Line -7500403 true 118 190 148 190
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 150 150
Polygon -1184463 true false 247 259 232 274 187 274 172 259 187 244 232 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -7500403 true true 137 176 24
Circle -2674135 true false 138 139 24
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -13791810 true false 105 177 24

amino-trp
true
0
Polygon -7500403 false true 204 137 181 163 181 194 225 195 226 161
Polygon -7500403 false true 224 162 225 195 255 210 285 195 284 161 255 146 224 163
Line -7500403 true 149 224 180 197
Line -7500403 true 119 259 194 259
Line -7500403 true 149 253 149 223
Polygon -1184463 true false 248 259 233 274 188 274 173 259 188 244 233 244
Polygon -13345367 true false 53 259 68 274 113 274 128 259 113 244 68 244
Circle -2674135 true false 138 214 24
Circle -7500403 true true 138 248 24
Circle -2674135 true false 243 198 24
Circle -2674135 true false 244 135 24
Circle -2674135 true false 214 150 24
Circle -2674135 true false 214 183 24
Circle -2674135 true false 272 150 24
Circle -2674135 true false 272 183 24
Circle -2674135 true false 169 183 24
Circle -11221820 true false 192 125 24
Circle -2674135 true false 169 150 24

amino-tyr
true
0
Line -7500403 true 150 60 150 30
Polygon -7500403 false true 105 135 150 165 195 135 195 90 150 60 105 90 105 135
Line -7500403 true 150 210 150 180
Line -7500403 true 120 255 195 255
Line -7500403 true 150 240 150 210
Circle -7500403 true true 135 240 30
Polygon -1184463 true false 255 255 240 270 195 270 180 255 195 240 240 240
Polygon -13345367 true false 45 255 60 270 105 270 120 255 105 240 60 240
Circle -2674135 true false 135 195 30
Circle -2674135 true false 135 150 30
Circle -2674135 true false 90 120 30
Circle -2674135 true false 90 75 30
Circle -2064490 true false 135 0 30
Circle -2674135 true false 180 75 30
Circle -2674135 true false 180 120 30
Circle -2674135 true false 135 45 30

amino-val
true
0
Line -7500403 true 105 180 150 210
Line -7500403 true 150 210 195 180
Line -7500403 true 150 240 150 210
Line -7500403 true 120 255 195 255
Line -7500403 true 150 240 150 210
Circle -7500403 true true 135 240 30
Polygon -1184463 true false 255 255 240 270 195 270 180 255 195 240 240 240
Polygon -13345367 true false 45 255 60 270 105 270 120 255 105 240 60 240
Circle -7500403 true true 135 195 30
Circle -2674135 true false 90 165 30
Circle -2674135 true false 180 165 30

empty
false
0

end
false
2
Polygon -955883 true true 130 61 145 46 160 46 175 61 220 61 235 46 250 46 265 61 265 226 250 241 235 241 220 226 175 226 160 241 145 241 130 226
Polygon -1 false false 130 61 145 46 160 46 175 61 220 61 235 46 250 46 265 61 265 226 250 241 235 241 220 226 175 226 160 241 145 241 130 226

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

mrna-a
true
0
Line -2064490 false 75 30 45 60
Line -2064490 false 120 60 90 30
Circle -2064490 true false 69 15 30
Polygon -10899396 true false 180 180 150 120 120 180 120 60 180 60

mrna-c
true
0
Line -2064490 false 45 60 75 30
Line -2064490 false 120 61 90 31
Circle -2064490 true false 67 15 30
Polygon -11221820 true false 180 135 180 60 120 60 120 135 135 165 165 165

mrna-g
true
0
Polygon -8630108 true false 120 60 120 165 135 135 165 135 180 165 180 60
Line -2064490 false 120 60 90 30
Line -2064490 false 45 60 75 30
Circle -2064490 true false 67 15 30

mrna-start
false
0
Polygon -2064490 true false 150 240 0 240 15 270 30 270 30 300 60 300 60 270 150 270

mrna-stop
false
0
Polygon -2064490 true false 180 240 30 240 30 270 105 270 105 300 135 300 135 270 165 270

mrna-u
true
0
Polygon -2674135 true false 120 60 120 120 150 180 180 120 180 60
Line -2064490 false 120 60 90 30
Line -2064490 false 45 60 75 30
Circle -2064490 true false 67 17 30

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

nucleoside-tri-u
true
0
Line -1 false 75 30 90 75
Line -1 false 120 60 90 30
Line -1 false 45 60 75 75
Circle -1184463 true false 69 15 30
Circle -1184463 true false 69 60 30
Circle -1184463 true false 24 45 30
Polygon -2674135 true false 120 60 120 120 150 180 180 120 180 60

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

nucleotide-u
true
0
Polygon -2674135 true false 120 60 120 120 150 180 180 120 180 60
Line -1 false 120 60 90 30
Line -1 false 45 60 75 30
Circle -1184463 true false 67 17 30

nucleotide-x
true
0
Line -1 false 75 30 45 60
Line -1 false 120 60 90 30
Circle -1184463 true false 69 15 30
Polygon -7500403 false true 120 60 120 180 150 120 180 180 180 60

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
Rectangle -2674135 true true 120 135 300 165

polymerase-1
false
1
Polygon -2674135 true true 120 150 120 30 90 45 75 60 30 60 0 120 0 180 30 240 75 240 90 240 120 240
Rectangle -2674135 true true 120 30 180 60
Rectangle -2674135 true true 90 240 120 300
Rectangle -2674135 false true 120 60 180 240
Rectangle -2674135 true true 105 135 300 165

polymerase-2
false
1
Polygon -2674135 true true 120 150 120 30 90 45 75 60 30 60 0 120 0 180 30 240 75 240 90 255 120 270
Rectangle -2674135 true true 120 30 180 60
Rectangle -2674135 true true 120 240 180 270
Line -2674135 true 180 60 180 240
Rectangle -2674135 true true 120 135 300 165

polymerase-3
false
1
Polygon -2674135 true true 120 150 120 30 90 45 75 60 30 60 0 120 0 180 30 240 75 240 90 255 120 270
Rectangle -2674135 true true 120 30 180 60
Rectangle -2674135 true true 120 240 180 270
Rectangle -2674135 true true 90 135 315 165

promoter-expanded
false
0
Polygon -7500403 true true 150 150 135 135 120 135 105 120 90 120 75 105 60 105 45 90 15 90 30 135 60 135 75 150
Polygon -7500403 true true 150 150 135 165 120 165 105 180 90 180 75 195 60 195 45 210 15 210 30 165 60 165 75 150
Circle -1184463 false false 117 117 66

start
false
0
Rectangle -1 false false 125 46 260 240
Rectangle -7500403 true true 126 47 260 239

target
true
0
Circle -7500403 false true 76 76 146
Line -7500403 true 150 60 150 105
Line -7500403 true 150 195 150 240

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

trna-a
true
0
Line -2064490 false 150 60 150 30
Polygon -10899396 true false 180 180 150 120 120 180 120 60 180 60

trna-c
true
0
Line -2064490 false 150 61 150 30
Polygon -11221820 true false 180 135 180 60 120 60 120 135 135 165 165 165

trna-core
true
0
Polygon -7500403 true true 15 300 285 300 300 270 300 240 195 210 195 150 210 165 225 165 240 150 240 135 225 120 210 120 195 135 195 75 180 75 180 225 285 255 285 270 270 285 30 285 15 270 15 255 105 225 105 135 90 135 90 165 75 150 60 150 45 165 45 180 60 195 75 195 90 180 90 210 0 240 0 270

trna-g
true
0
Polygon -8630108 true false 120 60 120 165 135 135 165 135 180 165 180 60
Line -2064490 false 150 60 150 30

trna-u
true
0
Polygon -2674135 true false 120 60 120 120 150 180 180 120 180 60
Line -2064490 false 150 60 150 30

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
