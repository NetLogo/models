globals [
  ; These variables give the layout of the view from top to bottom
  y-view-top                 ; y-coordinate at the top of the view (0.5)
  y-mRNA-top                 ; y-coordinate at the top of the mRNA area
  y-mRNA-bottom              ; y-coordinate at the bottom of the mRNA area
  y-TF-top                   ; y-coordinate at the top of the TF area
  y-TF-bottom                ; y-coordinate at the bottom of the TF area
  y-DNA                      ; y-coordinate of the DNA turtles
  y-view-bottom              ; y-coordinate at the bottom of the view (-0.5)

  ; These variables set the width of the plots that have "rolling" views of the recent data
  signal-rolling-plot-width    ; width in ticks of rolling signal plot
  TF-rolling-plot-width        ; width in ticks of rolling TF plot
  interval-rolling-plot-width  ; number of off intervals show in rolling signal plot

  ; This variable is used to implement the plot of off interval lengths
  ; The plot is updated only when completed-signal-off-length is not 0
  completed-signal-off-length  ; 0 if we have not just transitioned from an off to an on state
                               ; length (in ticks) of off state if we have just transitioned

  ; This variable is used to implement the plot of on interval lengths
  ; The plot is updated only when completed-signal-on-length is not 0
  completed-signal-on-length   ; 0 if we have not just transitioned from an on to an off state
                               ; length (in ticks) of off state if we have just transitioned
  signal-off-length-list       ; list of the lengths of each off period
  signal-on-length-list        ; list of the lengths of each on period
]

;; set trades lput trades-in-this-tick trades

; The signal indicates the overall state of the system ON or OFF
breed [ signals signal ]
; A DNA-segment is a visual representation of part of a larger stretch of coding DNA
breed [ DNA-segments DNA-segment ]
; An mRNA is a messenger RNA
breed [ mRNAs mRNA ]
; A TF is a Transcription Factor, a type of protein
breed [ TFs TF ]
; A TF-binding-site is a stretch of DNA to which a TF can attach
breed [ TF-binding-sites TF-binding-site ]

; A banner is a size 0 turtle used to display a properly positioned label for another turtle
breed [ banners banner ]
; A gene-label shows the name of a gene, e.g. GENE 0
breed [ gene-labels gene-label ]
; A gene-off-label displays the word OFF when a gene is bound by a TF
breed [ gene-off-labels gene-off-label ]
; The signal-label shows the word SIGNAL, indicating the location of the signal
breed [ signal-labels signal-label ]

; Each patch is identified with the gene it contains
patches-own             [
  DNA-gene-id                ; ID number of the patch's gene
  DNA-inhibited-by-gene-id   ; ID number of the gene that produces the TF that inhibits the patch's gene
  gene-inhibited?            ; Is this gene inhibited? true/false
]
mRNAs-own               [
  mRNA-gene-id               ; ID number of the gene that produced this mRNA
]
TFs-own                 [
  TF-gene-id                 ; ID number of the gene/mRNA that produced this TF
  TF-inhibits-gene-id        ; ID number of the gene inhibited by this TF
  TF-age                     ; Number of ticks since this TF was created. Currently for informational use only.
  TF-bound?                  ; Is this TF bound to a gene?  true/false
  TF-bound-to-signal?        ; Is this TF bound to the signal?  true/false
]
TF-binding-sites-own    [
  TF-binding-site-gene-id    ; ID number of the TF binding site's gene
]
signals-own             [
  signal-bound?              ; Is the signal bound? true/false
  signal-on?                 ; Is the signal on? true/false
  was-signal-on?             ; Was the signal on during the last tick? true/false
                             ; equals signal-on? for tick 0
  interval-start             ; tick on which the last interval started
  my-banner                  ; banner associated with the signal
]
gene-labels-own         [
  my-banner                  ; banner associated with the gene label
]
gene-off-labels-own     [
  my-banner                  ; banner associated with the gene off label
]
signal-labels-own       [
  my-banner                  ; banner associated with the signal
]

;-----------------------------------------------------------------------------------;
to setup
  clear-all
  reset-ticks

  set-default-shape mRNAs "mRNA"
  ; TFs start out unbound, but may later change shape
  set-default-shape TFs unbound-TF-shape

  ; Create a one-dimensional world with 3 patches
  resize-world 0 num-patches - 1 0 0
  set-patch-size 250

  initialize-layout
  initialize-patches
  initialize-TFs
  initialize-signal
  set signal-off-length-list []
  set signal-on-length-list []
end

to go

  ; TFs can bind with some probability
  bind-TFs

  ; TFs can move
  ; A TF that is in an inhibiting position stays in place
  ; Other TFs relocate randomly
  move-TFs

    ; TFs can unbind with some probability
  unbind-TFs

  ; mRNAs and TFs can degrade with some probability
  degrade-TFs
  degrade-mRNAs

  ; Each patch will produce transcription factors if the gene is not inhibited

  ; TF age is just for informational purposes
  ask TFs [set TF-age TF-age + 1]
  produce-mRNAs

  produce-TFs

  ; Determine if the signal is on.
  ; Set its color and ON/OFF sign appropriately.
  update-signal

  tick
end


;;;; Initialization Functions ;;;;

; Initialize constants for the layout
; The y coordinate for each patch goes from -0.5 at the bottom of the view to
;   0.5 at the top of the view.
; From top to bottom the variables below delimit:
;   the mRNA area
;   the TF area
;   the DNA area
to initialize-layout
  ; top of the view
  set y-view-top 0.5
  set y-view-bottom -0.5
  set y-mRNA-top y-view-top - 0.5 * mRNA-size
  set y-mRNA-bottom y-mRNA-top - 0.3 * mRNA-size
  set y-TF-top y-mRNA-bottom - 0.25 * (mRNA-size + TF-size)
  set y-DNA y-view-bottom + DNA-segment-size
  set y-TF-bottom y-DNA + 0.5 * TF-size
end

; The patches need to be initialize with color, some variables, and DNA for the gene.
to initialize-patches
  ; The patches have a variable indicated which TF they are inhibited by
  ; The value is the DNA-gene-id of the patch to the left. (with wrap)
  ask patches [
    set DNA-gene-id pxcor
    set pcolor patch-color DNA-gene-id
    set DNA-inhibited-by-gene-id get-TF-DNA-is-inhibited-by DNA-gene-id
    set gene-inhibited? false
    initialize-composite-DNA   ; create the DNA
    initialize-gene-label      ; create label for the DNA
    initialize-gene-off-label  ; create label that will indicate gene is inhibited
  ]
end

; I am a patch, initialize my DNA. It is composed of two binding sites and
; three DNA coding segments.
to initialize-composite-DNA ; patch procedure
  sprout-DNA-segments 1 [
    set shape "binding site"
    set xcor (DNA-x-offset  + DNA-gene-id) + 0.5  * DNA-segment-size
    set ycor y-DNA
    set size DNA-segment-size
    set heading 0
    set color yellow
  ]
  sprout-DNA-segments 1 [
    set shape "binding site"
    set xcor (DNA-x-offset  + DNA-gene-id) + 1.5 * DNA-segment-size
    set ycor y-DNA
    set size DNA-segment-size
    set heading 0
    set color black
  ]
  sprout-DNA-segments 1 [
    set shape one-of DNA-segment-shapes
    set xcor (DNA-x-offset  + DNA-gene-id) + 2.5 * DNA-segment-size
    set ycor  y-DNA
    set size DNA-segment-size
    set heading 0
  ]
  sprout-DNA-segments 1 [
    set shape one-of DNA-segment-shapes
    set xcor (DNA-x-offset + DNA-gene-id) + 3.5 * DNA-segment-size
    set ycor y-DNA
    set size DNA-segment-size
    set heading 0
  ]
  sprout-DNA-segments 1 [
    set shape one-of DNA-segment-shapes
    set xcor (DNA-x-offset + DNA-gene-id) + 4.5 * DNA-segment-size
    set ycor y-DNA
    set size DNA-segment-size
    set heading 0
  ]
end

; Initialize me, an mRNA. I start out in the top region. My color is slightly
; darker than my patch color. My id corresponds to that of my parent patch
to initialize-mRNA  ; turtle procedure
  set heading -45 + random 90
  set mRNA-gene-id DNA-gene-id
  set size mRNA-size
  let usable-mRNA-height y-mRNA-top - y-mRNA-bottom
  set xcor (mRNA-gene-id - 0.5 + 0.5 * mRNA-size) +
  (count-other-mRNAs-same-patch * 1.6 * mRNA-size) mod (1 - mRNA-size)
  set ycor y-mRNA-bottom + random-float usable-mRNA-height
  set color darken-color pcolor
end

; By default there are no initial TFs, however the user can set their number.
to initialize-TFs
  ask patches with [ DNA-gene-id = 0 ] [ create-initial-TFs initial-TF0s ]
  ask patches with [ DNA-gene-id = 1 ] [ create-initial-TFs initial-TF1s ]
  ask patches with [ DNA-gene-id = 2 ] [ create-initial-TFs initial-TF2s ]
end

; I am a patch. Create my initial TFs.
to create-initial-TFs [ initial-TFs ] ; patch procedure
  ; Create my TFs one at a time because their position depends on
  ; how many TFs of the same kind I already have
  foreach range initial-TFs [ sprout-TFs 1 [ initialize-TF ] ]
end

; I am a TF. Set my initial position and values. I start out in my home patch,
; facing right. My color is slightly darker than the home patch color. My
; TF-gene-id corresponding to my parent patch. I know the id of the gene I inhibit.
to initialize-TF ; turtle procedure
  set heading 0
  set TF-gene-id DNA-gene-id
  set TF-inhibits-gene-id get-DNA-TF-inhibits DNA-gene-id
  set TF-bound? false
  set TF-bound-to-signal? false
  set size TF-size
  set-TF-position
  set color darken-color pcolor
end

; I am a TF in a given patch. Set my position. Place me in the correct column.
; There are three columns, corresponding to the three kinds of TF.
; My x coordinate is random within the column. My y coordinate depends on the
; number of TFs of my kind on the patch.
to set-TF-position ; turtle procedure
  let col-position-width 1 / num-patches - ( 0.5 * TF-size )
  set xcor (get-patch-column-x DNA-gene-id) +
    (random-float col-position-width) - 0.5 *  col-position-width
  set ycor y-TF-top -
    (count-other-TFs-same-color-same-patch * 0.5 * TF-size) mod (y-TF-top - y-TF-bottom)
end

; The signal is the state of the system visible to the world. In the physical
; repressilator it is on a separate circular DNA. Here it is visualized in
; the lower right corner of the right most patch. If at least one TF from the
; right most gene binds the signal, it will be off. Otherwise the signal will be on.
to initialize-signal
  create-signals 1 [
    set size signal-size
    set shape "signal"
    setxy (max-pxcor + 0.5 - .75 * size) (y-view-bottom + size + .01)

    set heading 0
    set signal-bound? false
    set signal-on? true
    set was-signal-on? true
    set interval-start 0
    set completed-signal-off-length 0
    set completed-signal-on-length 0
    set color signal-on-color
    attach-banner-below "ON"
    initialize-signal-label
  ]
end

; I am a patch, initialize my gene label. The gene labels "GENE 0", "GENE 1",
; and "GENE 2" are displayed beneath the corresponding DNA.
to initialize-gene-label ; patch procedure
  sprout-gene-labels 1  [
    set size 0
    set label-color black
    attach-banner word "GENE " DNA-gene-id
    set xcor 0.5 * DNA-segment-size + DNA-gene-id
    set ycor y-view-bottom
  ]
end

; I am a patch, initialize my "OFF" label. When my DNA is inhibited (a TF is
; attached to the binding site) a white label "OFF" will be displayed. Otherwise
; the label will be hidden.
to initialize-gene-off-label  ; patch procedure
  sprout-gene-off-labels 1  [
    set size 0
    hide-turtle
    set label-color white
    attach-banner "OFF"
    set xcor 2.5 * DNA-segment-size + DNA-gene-id - 0.5
    set ycor y-view-bottom
  ]
end

; I am the signal, initialize my label "SIGNAL".
to initialize-signal-label ; turtle procedure
  hatch-signal-labels 1  [
    set size 0
    set label-color black
    set label "SIGNAL"
    set xcor (get-signal-xcor - 0.65 * signal-size)
    set ycor y-for-label-below-me
  ]
end

; I am a turtle. Report a y-coordinate below me, suitable for a label.
to-report y-for-label-below-me ; turtle procedure
  report [ ycor ] of myself - [ size ] of myself - 0.01
end

;;;; Action Procedures ;;;;

; mRNAs are produced once per tick if the corresponding DNA is not inhibited.
to produce-mRNAs
  ; no mRNAs will be produced if there is an inhibiting TF on the patch
  ; create them one at a time so they will spread out
  ask patches with [ not gene-inhibited? ] [
    foreach range n-mRNAs-produced [
      sprout-mRNAs 1 [ initialize-mRNA ]
    ]
  ]
end

; mRNAs will degrade (die) with some probability.
to degrade-mRNAs
  ask mRNAs [
    if random-float 1 < mRNA-decay-prob [ die ]
  ]
end

; TFs are produced once per tick by mRNAs.
to produce-TFs
  ask mRNAs [
    hatch-TFs n-TFs-produced [ initialize-TF ]
  ]
end

; TFs will degrade (die) with some probability.
to degrade-TFs
  ask TFs [
    if random-float 1 < TF-decay-prob [
      if TF-bound? [ unbind-TF ]
      if TF-bound-to-signal? [ unbind-TF-from-signal ]
      die
    ]
  ]
  update-gene-off-labels
end

; TFs can move randomly to any patch (or stay put) unless they are inhibiting DNA
; or the signal.
to move-TFs
  ask TFs with [ not TF-bound? and not TF-bound-to-signal? ]  [
    set xcor (xcor + random num-patches) set heading -45 + random 90
  ]
end

; Bind some TFs to DNA or the signal, if they are eligible and pass a probabilistic test
to bind-TFs
  ; Potentially inhibiting TFs will bind to DNA  with some probability.
  ; There is cooperativity - more TFs (up to max-TF-synergy TFs) increase the
  ; binding probability.
  ask TFs with [ TF-can-bind-gene-here? ] [
    ; coef is used to implement co-operativity.
    let coef 1 / (max list max-TF-synergy count-other-TFs-same-color-same-patch)
    if random-float 1 < TF-bind-prob ^ coef [ bind-TF ]
  ]
  ; if any TFs are bound, the off labels must become visible
  update-gene-off-labels

  ask TFs with [ TF-can-bind-signal? ] [
    if random-float 1 < signal-TF-bind-prob [ bind-TF-to-signal ]
  ]
end

; I am a TF that is ready to bind to DNA - bind me. I should have already
; passed the probabilistic test in bind-TFs.
to bind-TF ; turtle procedure

  ; initially:
  ;   TF should be unbound
  ;   gene (patch) should not be inhibited
  ;   TF should be on patch it can inhibit
  ; action:
  ;   set TF to be bound
  ;   set gene (patch) to be inhibited

  ; note - the binding test should already have be run, test in case
  if TF-can-bind-gene-here? [
    set TF-bound? true
    ask patch-here [ set gene-inhibited? true ]
    ; bound TFs have a different shape
    update-TF-shape
    ; the TF should sit in the binding site of the DNA
    set xcor (DNA-x-offset  + DNA-gene-id) + 1.5  * DNA-segment-size
    set ycor  y-DNA
    set heading 0
  ]
end

; I am a TF that is ready to bind to the signal - bind me. I should have
; already passed the probabilistic test in bind-TFs.
to bind-TF-to-signal ; turtle procedure
  ; initially:
  ;   TF should be unbound
  ;   signal should not be inhibited
  ; action:
  ;   set TF to be bound
  ;   set signal to be inhibited
  ; note - the binding test should already have be run, but just in case
  if TF-can-bind-signal? [
    set TF-bound-to-signal? true
    ask signals [ set signal-bound? true ]
    update-TF-shape
    set xcor get-signal-xcor
    set ycor get-signal-ycor
    set heading 0
  ]
end

; Unbind some TFs from DNA or the signal, if they are eligible and pass a
; probabilistic test.
to unbind-TFs
  ask TFs with [ TF-bound? ] [
    if random-float 1 < TF-unbind-prob [ unbind-TF ]
  ]
  ; if any TFs are unbound, the off labels must become invisible
  update-gene-off-labels

  ask TFs with [ TF-bound-to-signal? ] [
    if random-float 1 < signal-TF-unbind-prob [ unbind-TF-from-signal ]
  ]
end

; I am a TF that is ready to unbind from DNA - unbind me. I should have already
; passed the probabilistic test in unbind-TFs.
to unbind-TF ; turtle procedure
  if TF-bound? [
    set TF-bound? false
    ; set the gene (patch) to not inhibited
    ask patch-here [ set gene-inhibited? false ]
    update-TF-shape ; unbound TFs have a different shape
    set-TF-position ; return me to my TF area
  ]
end

; I am a TF that is ready to unbind from the signal - unbind me. I should have
; already passed the probabilistic test in unbind-TFs.
to unbind-TF-from-signal ; turtle procedure
  ; initially I should be bound
  ;  so set me to be unbound and set signal to not inhibited
  if TF-bound-to-signal? [
    set TF-bound-to-signal? false
    ask signals [ set signal-bound? false ]
    set-TF-position
    update-TF-shape
  ]
end

;;;; Banner Procedures ;;;;

; Banners are turtles used to allow control over the positioning of labels

; I am a turtle. Attach a banner to me. The banner label is centered horizontally
; relative to me. The banner is optionally placed below me.
to attach-banner-optionally-below [ the-text below? ] ; turtle procedure
  hatch-banners 1 [
    set size 0
    set label the-text
    set xcor [ xcor ] of myself + 0.4 * [ size ] of myself
    if below? [ set ycor [ ycor ] of myself - [ size ] of myself - 0.01 ]
    let me self
    if [ hidden? ] of myself [ hide-turtle ]
    ask myself [ set my-banner me ]
    create-link-from myself [
      tie
      hide-link
    ]
  ]
end

; I am a turtle. Attach a banner to me. The banner label is centered horizontally
; relative to me.
to attach-banner [ the-text ] ; turtle procedure
  attach-banner-optionally-below the-text false
end

; I am a turtle. Attach a banner to me. The banner label is centered horizontally
; relative to me and is below me.
to attach-banner-below [ the-text ] ; turtle procedure
  attach-banner-optionally-below the-text true
end

; I am a turtle with a banner and will make my label visible.
to show-turtle-and-banner ; turtle procedure
  show-turtle
  ask my-banner [ show-turtle ]
end

; I am a turtle with a banner and will make my label invisible.
to hide-turtle-and-banner ; turtle procedure
  hide-turtle
  ask my-banner [ hide-turtle ]
end

; hide or show the gene-off-labels of all patches
to update-gene-off-labels
  ask patches [
    ifelse gene-inhibited?
      [ ask gene-off-labels-here [ show-turtle-and-banner ] ]
      [ ask gene-off-labels-here [ hide-turtle-and-banner ] ]
  ]
end

;;;; Reporter Procedures ;;;;

; the "wrap" topology is implemented by doing computations mod num-patches

; Report the gene-id of the DNA (patch x coordinate) inhibited by a TF of a
; particular gene-id. It is the patch to the right with wrapping. The patch
; to the right of the rightmost patch is the leftmost patch.
to-report get-DNA-TF-inhibits [ local-TF-gene-id ]
  report (local-TF-gene-id + 1) mod num-patches
end

; Report the gene-id of the TF that inhibits the DNA of a particular patch.
; The TF originates from  the patch to the left with wrapping.
to-report get-TF-DNA-is-inhibited-by [ local-DNA-gene-id ]
  report (local-DNA-gene-id - 1) mod num-patches
end

; Report number of mRNAs on this patch other than me
to-report count-other-mRNAs-same-patch ; turtle procedure
  report count other mRNAs-here
end

; Report number of transcription factors on this patch other than me
to-report count-other-TFs-same-color-same-patch ; turtle procedure
  report count other TFs-here with [ TF-gene-id = [TF-gene-id] of myself ]
end

; Report whether I am a TF that can bind the gene of the patch I am on
to-report TF-can-bind-gene-here? ; turtle procedure
  ; I can't already be bound, no TF can be bound to the gene,
  ; and I need to be the right kind of TF.
  report (not TF-bound? and not gene-inhibited? and TF-can-inhibit-gene-here?)
end

; Report whether I am a TF that can bind the signal
to-report TF-can-bind-signal? ; turtle procedure
  ; The signal must be unbound, I am not attached to a binding site,
  ; and I come from the right patch.
  report (not is-signal-bound?) and
    (not TF-bound?) and TF-gene-id = signal-TF-gene-id
end

; Update the status and appearance of the signal. This should be done only once per tick
; at the end of the go cycle. Determine if the signal is on. Set the signal color and
; ON/OFF label appropriately.
; Keep track of intervals during which the signal is ON or OFF
to update-signal
  ask signals [
    ; save the previous signal state
    if ticks > 0 [ set was-signal-on?  signal-on? ]

    ; because an on signal can decay, and because a bound TF can unbind
    ; need to determine whether the signal should be on
    set signal-on? should-signal-be-on?

    ; This is an edge case
    if ticks = 0 [ set was-signal-on?  signal-on? ]

    ; set appropriate color
    set color  (
      ifelse-value signal-on?
        [ signal-on-color ]
        [ signal-off-color ]
    )
    ;set appropriate label
    ask my-banner [ set label (
      ifelse-value [ signal-on? ] of myself
        [ "ON" ]
        [ "OFF" ]
      )
    ]

    ; Keep track of the start and length of intervals

    ; These should always be zero, except at the end of an interval
    ; The plot is only updated when the value is positive
    set completed-signal-off-length 0
    set completed-signal-on-length 0

    ; Signal goes from ON to OFF - ON interval is completed
    if ( was-signal-on? = TRUE and is-signal-on? = FALSE) [
      set completed-signal-on-length ticks - interval-start
      set interval-start ticks
      ; add data to list
      set signal-on-length-list lput completed-signal-on-length signal-on-length-list
    ]

    ; Signal goes from OFF to ON - OF interval is completed
    if ( was-signal-on? = FALSE and is-signal-on? = TRUE) [
      set completed-signal-off-length ticks - interval-start
      set interval-start ticks
      ; add data to array
      set signal-off-length-list lput completed-signal-off-length signal-off-length-list
    ]
  ]
  update-plots
end

; Set me (TF) to the appropriate shape depending on whether I am unbound, bound to a gene,
; or bound to the signal.
to update-TF-shape ; turtle procedure
  ifelse not TF-bound? and not TF-bound-to-signal?  [ set shape unbound-TF-shape ]
    [ set shape ifelse-value TF-bound?
      [ bound-TF-shape ]
      [ bound-to-signal-TF-shape ]
    ]
end

; Can I (TF) inhibit the gene of the patch I am on
to-report TF-can-inhibit-gene-here?  ; turtle procedure
 ; inhibits if gene-id inhibited by my-TF is the DNA-gene-id of TF's patch
  report TF-inhibits-gene-id = DNA-gene-id
end

; On average 1 mRNA will be produced per tick.
to-report n-mRNAs-produced
  report random-poisson 1
end

; On average each mRNA will produce TFs-per-mRNA per tick.
to-report n-TFs-produced
  report random-poisson ( TFs-per-mRNA )
end

; Return the signal.
to-report the-signal
  ; There is only one in the AgentSet.
  report one-of signals
end

; Report whether the signal is bound.
to-report is-signal-bound?
  report [ signal-bound? ] of the-signal
end

; Report whether the signal is on.
to-report is-signal-on?
  report [ signal-on? ] of the-signal
end

; Report the x coordinate of the signal.
to-report get-signal-xcor
  report [ xcor ] of the-signal
end

; Report the y coordinate of the signal.
to-report get-signal-ycor
  report [ ycor ] of the-signal
end

; I am a signal. Report whether I should be on. The signal will be on when no TF
; is bound to it. After a TF binds the signal there is a fixed chance that it will turn
; off per tick with TF bound.
to-report should-signal-be-on? ; turtle procedure
  ; the signal stay on rate when the signal is bound is 1 - signal-decay-prob
  report (not is-signal-bound?) or (signal-on? and random-float 1 < 1 - signal-decay-prob)
end

; Report the x coordinate of the column (0, 1 or 2)
; in my local patch (if I am a turtle) or in me (if I am a patch).
to-report get-patch-column-x [ column-num ] ; turtle or patch procedure
  ; column numbers go from 0 to num-patches - 1
  report pxcor + ((column-num - 1) / num-patches)
end

; Report the color of the patch with the given index (0, 1, or 2).
to-report patch-color [ the-gene-id ]
  report item the-gene-id patch-colors
end

; Report a color slightly darker than the given color.
; The color must not be at the black end of a color range, that is its units digit must
; must be greater than greater than 1.
to-report darken-color [ the-color ]
  ; Subtract a small amount to make a color darker.
  report the-color - 0.8
end

;;;; Reporters for Display, Layout, Etc. ;;;;

; These are used as replacements for global variables.
to-report num-patches
  report 3
end

to-report DNA-segment-size
  report 0.1
end

to-report mRNA-size
  report 0.15
end

to-report TF-size
  report 0.15
end

to-report bound-TF-size
  report 0.1
end

to-report signal-size
  report 0.1
end

to-report gene-off-label-size
  report 0.1
end

; Reports a list of different DNA segment shapes that can be incorporated
; into a composite piece of DNA
to-report DNA-segment-shapes
  report (list "DNA 1" "DNA 2" "DNA 3" "DNA 4")
end

to-report bound-TF-shape
  report "Transcription Factor bound"
end

to-report unbound-TF-shape
  report "Transcription Factor"
end

to-report bound-to-signal-TF-shape
  report "Transcription Factor bound"
end

to-report signal-on-color
  report lime
end

to-report patch-colors
  report (list 24.4 115.6 75)
end

to-report signal-off-color
  report black
end

to-report DNA-x-offset
  report -0.5 + 0.5 * DNA-segment-size
end

to-report signal-TF-gene-id
  report 2
end

; functions to evaluate the on-off characteristics of a model run
; could easily add: max median standard-deviation modes

to-report mean-on-duration
  report ifelse-value length signal-on-length-list > 0
  [ mean signal-on-length-list ] [ 0 ]
end

to-report mean-off-duration
  report ifelse-value length signal-off-length-list > 0
  [ mean signal-off-length-list ] [ 0 ]
end

to-report harmonic-mean [ val1 val2 ]
  let the-sum val1 + val2
    report ifelse-value the-sum  > 0
  [ (2 * val1 * val2) / the-sum ] [ 0 ]
end

to-report on-off-harmonic-mean
    report harmonic-mean mean-on-duration mean-off-duration
end

; The harmonic mean is not an adequate objective function
; Each mean is at least 1.0, so a result in which the signal is on for
; very long periods, and off for one tick would score well.
; Therefore both means need to hit a minimum value.
; Also the mean can be misleading if there are only a few items on the list,
; and one is much larger than the others
to-report on-off-optim-fcn22
  if length signal-off-length-list < 20 [ report 0 ]
  let v-on mean-on-duration
  let v-off mean-off-duration
  ; require each value be at least 2.0
  if (v-on < 2.0 or v-off < 2.0) [ report min list v-off v-on ]
  ; don't count values beyond 50
  set v-on min list v-on 50
  set v-off min list v-off 50
  report harmonic-mean mean-on-duration mean-off-duration
end


to-report on-off-optim-fcn1
  let v-on mean-on-duration
  let v-off mean-off-duration
  ; require each value be at least 2.0
  if (v-on < 2.0 or v-off < 2.0) [ report 0.0 ]
  ; don't count values beyond 50
  set v-on min list v-on 50
  set v-off min list v-off 50
  report harmonic-mean mean-on-duration mean-off-duration
end


; Copyright 2020 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
420
10
1178
269
-1
-1
250.0
1
10
1
1
1
0
1
1
1
0
2
0
0
1
1
1
ticks
30.0

BUTTON
10
70
82
103
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
105
70
180
103
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
10
200
195
233
TF-decay-prob
TF-decay-prob
0
1
0.1
.005
1
NIL
HORIZONTAL

SLIDER
10
160
195
193
TF-unbind-prob
TF-unbind-prob
0
1
0.355
.005
1
NIL
HORIZONTAL

PLOT
540
285
1160
485
Recent Signal Pattern
Time
On = 1, 0 = Off
0.0
500.0
0.0
1.0
false
false
"set signal-rolling-plot-width 500\nset-plot-x-range  0 signal-rolling-plot-width\n" "if ticks > signal-rolling-plot-width [\n  ; scroll the range of the plot so only\n  ; the last signal-rolling-plot-width ticks are visible\n  set-plot-x-range (ticks - signal-rolling-plot-width) ticks\n]"
PENS
"default" 1.0 0 -16777216 true "" "if ticks > 0 [\nifelse is-signal-on? [ plotxy ticks 1 ] [ plotxy ticks 0 ]\n]\n"

SLIDER
10
120
195
153
TF-bind-prob
TF-bind-prob
0
1
0.975
.005
1
NIL
HORIZONTAL

MONITOR
75
310
160
355
Num mRNA 0
count mRNAs with [ mRNA-gene-id = 0 ]
17
1
11

MONITOR
180
310
263
355
Num mRNA 1
count mRNAs with [ mRNA-gene-id = 1 ]
17
1
11

MONITOR
280
310
363
355
Num mRNA 2
count mRNAs with [ mRNA-gene-id = 2 ]
17
1
11

SLIDER
210
120
410
153
signal-TF-bind-prob
signal-TF-bind-prob
0
1
0.75
.005
1
NIL
HORIZONTAL

SLIDER
210
160
410
193
signal-TF-unbind-prob
signal-TF-unbind-prob
0
1
0.1
.005
1
NIL
HORIZONTAL

SLIDER
210
200
410
233
signal-decay-prob
signal-decay-prob
0
1
0.2
.005
1
NIL
HORIZONTAL

SLIDER
10
240
160
273
mRNA-decay-prob
mRNA-decay-prob
0
1
0.25
.005
1
NIL
HORIZONTAL

PLOT
540
505
1160
710
Recent TF Counts
Time
TF Count
0.0
100.0
0.0
20.0
true
true
"set tf-rolling-plot-width 100\nset-plot-x-range  0 tf-rolling-plot-width" "\nif ticks > tf-rolling-plot-width [\n  ; scroll the range of the plot so only\n  ; the last tf-rolling-plot-width ticks are visible\\n\n  set-plot-x-range (ticks - tf-rolling-plot-width) ticks\n]"
PENS
"TF Gene 0" 1.0 0 -2269166 true "" "plotxy ticks (count TFs with [ TF-gene-id = 0 ]) "
"TF Gene 1" 1.0 0 -7773779 true "" "plotxy ticks (count TFs with [ TF-gene-id = 1 ])"
"TF Gene 2" 1.0 0 -14835848 true "" "plotxy ticks (count TFs with [ TF-gene-id = 2 ])"

TEXTBOX
180
290
270
308
mRNA Counts
12
0.0
1

BUTTON
205
70
310
103
go-once
go
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
20
115
53
initial-TF0s
initial-TF0s
0
200
0.0
10
1
NIL
HORIZONTAL

SLIDER
135
20
240
53
initial-TF1s
initial-TF1s
0
200
0.0
10
1
NIL
HORIZONTAL

SLIDER
255
20
360
53
initial-TF2s
initial-TF2s
0
200
0.0
10
1
NIL
HORIZONTAL

SLIDER
290
240
410
273
max-TF-synergy
max-TF-synergy
0
4
4.0
1
1
NIL
HORIZONTAL

SLIDER
165
240
285
273
TFs-per-mRNA
TFs-per-mRNA
0
10
2.0
1
1
NIL
HORIZONTAL

PLOT
15
370
455
535
Time Between On Signals
NIL
NIL
0.0
100.0
0.0
3.0
true
false
"set interval-rolling-plot-width 200\nset-plot-x-range  0 interval-rolling-plot-width\nset-plot-pen-mode 2" "if FALSE and ticks > interval-rolling-plot-width [\n  ; scroll the range of the plot so only\n  ; the last interval-rolling-plot-width ticks are visible\\n\n  set-plot-x-range (ticks - interval-rolling-plot-width) ticks\n]"
PENS
"default" 1.0 0 -16777216 true "" "if completed-signal-off-length > 0 [ \n   plot completed-signal-off-length\n]"

PLOT
10
550
450
715
Duration of On Signals
NIL
NIL
0.0
100.0
0.0
3.0
true
false
"set interval-rolling-plot-width 200\nset-plot-x-range  0 interval-rolling-plot-width\nset-plot-pen-mode 2" "if FALSE and ticks > interval-rolling-plot-width [\n  ; scroll the range of the plot so only\n  ; the last interval-rolling-plot-width ticks are visible\\n\n  set-plot-x-range (ticks - interval-rolling-plot-width) ticks\n]"
PENS
"default" 1.0 0 -16777216 true "" "if completed-signal-on-length > 0 [ \n   plot completed-signal-on-length\n]"

@#$#@#$#@
## WHAT IS IT?

This is a NetLogo model of one of the first notable constructs in synthetic biology: an oscillatory network of transcriptional regulators called a **repressilator**. Three sets of components (DNA, mRNA and proteins called transcription factors) each follow a simple set of rules, resulting in a signal being turned on and off.

For more information see [Wikipedia Repressilator](https://en.wikipedia.org/wiki/Repressilator)

The repressilator was a proof of concept that artificial biological constructs could behave reliably enough to mimic the behavior of electrical circuits. Although the repressilator did not have a practical application it helped lead the way toward more practical goals, such as biological circuits that could count and turn on or off after a fixed period of time. The hope is that such components can contribute to drug delivery, nano-construction, and other fields.

The repressilator has three genes, each of which produces a messenger RNA (mRNA) that produces a protein called a transcription factor (TF). What makes the system interesting is that the proteins can inhibit one of the other genes, and that they do so in a non-transitive way, analogous to the outcomes in the game Rock, Paper, Scissors - none of the actors dominates the other two.

## HOW IT WORKS

Call the three genes Gene 0, Gene 1 and Gene 2. The genes are DNA that includes a binding site to which an appropriate transcription factor can attach, and a coding section that gives the sequence of the mRNA. The corresponding mRNAs are mRNA 0, mRNA 1 and mRNA 2. The mRNAs produce corresponding transcription factors (TFs): TF 0, TF 1 and TF 2. The TFs inhibit genes from producing mRNA as follows:

* TF 0 inhibits Gene 1
* TF 1 inhibits Gene 2
* TF 2 inhibits Gene 0.

The inhibition can happen only if the TF is in the patch of the gene it inhibits, and even then binding has only a certain probability of succeeding. Biologically this corresponds to a transcription factor being near enough to the binding site of a gene's DNA to bind to it. Other events, such as whether an mRNA or a TF will decay (become non-functional and be broken down for "parts") or which gene a TF will move to are also governed by random factors.

From the perspective of the different types of agents, the rules for one tick are as follows (the process is cyclical):

* I am a TF,
    - If I am bound, I become unbound with some probability
    - I decay with some probability
* I am an mRNA, I decay with some probability
* I am coding DNA (a gene), is a TF bound to me?
    - If yes, do nothing
    - If no, I produce TFs-per-mRNA mRNAs (on average)
* I am an mRNA, I produce a set number of TFs (on average)
* I am a TF,
    - If I am on the patch of an unbound gene I can inhibit, I bind to the gene with some probability
        - If synergy is enabled and I am accompanied by TFs of my kind my probability of binding can increase.
    - If I am not bound, I move with equal probability to one of the patches (including my current patch)

### The Signal
The description above left out one element of the system - the signal. The signal represents the state of the system visible to the outside world.

The biological repressilator consists of tiny loops of DNA inside of _E. coli_ bacteria, which are themselves invisible to the naked eye. The bacteria are visible through a microscope, but the DNA is not. The visible output of the system is the glow of a fluorescent green protein as filmed through a microscope. The DNA encoding this protein is on a separate loop of DNA, although, in this NetLogo model, it is visualized in the lower right corner of the view.

A few rule updates are needed to add the behavior of the signal to the system:

* I am the signal, is a TF bound to me?
    - If yes, I become invisible with some probability
    - If no, I am visible

* I am an unbound TF 0 and the signal is unbound
    - I bind to the signal with some probability

## HOW TO USE IT

This model is visually complex, but easy to start using. Push the SETUP button to create three patches, each of which contains a gene. The rightmost patch also contains the signal. Push the GO button, and the action starts.

### The View
The model world consists of three patches along the x axis, with wrapping. It represents a system consisting of a piece of circular DNA with three genes, as well as associated  mRNA and TFs plus the signal. The model is one dimensional. The layout within each patch uses the vertical dimension for visualization of important agents in the model.

#### The mRNA
mRNAs are shown at the top of the view. The model does not represent the physical processes by which mRNAs are created by transcription from DNA, or translated into proteins such as TFs. See the _DNA Protein Synthesis_ and _GenEvo 1 Genetic Switch_ models for an illustration of these processes.

#### The Genes
The DNA for each gene appears near the bottom of the view. It has two binding sites, one of which can become occupied by a TF. The DNA also has a visual indicator of the coding sequence. The gene number is visible below the DNA. When the binding site is occupied, a label "OFF" become visible.

#### The Transcription Factors (TFs)
The TF area is located below the mRNA area. Each TF has a color that is a bit darker than the color of the patch containing the gene that coded for it. Each TF is located in the patch of the gene it is near, and with which it can potentially interact. Orientation and position are used to visually distinguish individual TFs of each type, but this does not reflect differences in access to the binding site.

#### The DNA
Each patch shows a portion of the DNA associated with it. The DNA appears near the bottom of the view. It has two binding sites, one of which can become occupied by a TF. When the binding site is occupied, the gene cannot produce mRNA and an "OFF" label becomes visible. The DNA also has a visual representation of the sequence of bases A, C, G and T coding for the mRNA. The gene number is visible below the DNA.

#### The Signal
The signal is the state of the system visible to the world. It is visualized in the lower right corner of the right-most patch. Conceptually it is physically separate from the rest of the DNA. The signal is on by default. It has a TF binding site. When a TF is bound, the signal will decay and become "OFF".

### Monitors
The three mRNA COUNTS Monitors beneath the view show the number of mRNAs of each type.

### Plots

The _Recent TF Counts_ Plot shows the number of TFs of each type over the last 500 ticks.
This can help give insight into the relationship between the TFs. When the number of one type of TF decreases, what happens to the other ones? How regular are the maxima and the minima of each colored line. The patterns are an emergent behavior of the TF populations, they are not build directly into a TF agent's rules.

The _Recent Signal Pattern_ Plot indicates whether the signal was on or off during each of the last 100 ticks.

The _Time_Between_On_Signals_ Plot shows the length of each time stretch during which the signal is off.

The _Duration_Of_On_Signals_ Plot shows the length of each time stretch during which the signal is on.

### The Sliders
The sliders represent physical characteristics of the biological components in the model.

#### Decay Sliders
Each decay slider gives the probability per tick that the corresponding entity will decay. A decay rate of 0 means the entity will exist forever. A decay rate of 1 means the entity will live for only one tick. Experiment with the extremes, as well as rates in between. Note that the performance of the system will degrade if the total number of TFs and mRNAs becomes too large.

**MRNA-DECAY-PROB**: The probability per tick that an individual mRNA will die.
**TF-DECAY-PROB**: The probability per tick that an individual TF will die.
**SIGNAL-DECAY-PROB**: The probability per tick that the an unbound ON signal will turn off.

#### Binding Sliders
Each binding slider gives the probability per tick that a TF will will bind to an accessible target (DNA binding-site or the signal). A binding rate of 0 means the entity will never bind. A binding rate of 1 means the entity will always bind an accessible target.

**TF-BIND-PROB**: The probability per tick that an individual TF will attach to the DNA binding site if it is in the patch of a gene it inhibits.
**SIGNAL-TF-BIND-PROB**: The probability per tick that an individual signal-inhibiting TF (TF 2) will bind to the signal if it is in the signal's patch.

#### Unbinding Sliders
Each unbinding slider gives the probability per tick that a bound TF will will unbind from its target. A unbinding rate of 0 means the entity will never unbind. A unbinding rate of 1 means the entity will always unbind from its target after one tick.

**TF-UNBIND-PROB**: The probability per tick that an individual DNA-bound TF will unbind.
**SIGNAL-TF-UNBIND-PROB**: The probability per tick that an individual signal-bound TF will unbind.

#### Input Widgets

**INITIAL-TF0**, **INITIAL-TF1**, **INITIAL-TF2**: These control the initial number of TFs for each of the three types.
**N-TFs-PER-mRNA**: The number of TFs that an mRNA will produce per tick on average.
**MAX-TF-SYNERGY**: In biology TFs competing for a target can cooperate, increasing the probability that one of them will bind, a phenomenon called synergy. This variable sets a limit beyond which additional TFs do not affect binding probability. If MAX-TF-SYNERGY is 1 there is no synergy. The result of synergy depends on the binding probability  TF-BIND-PROB or SIGNAL-TF-BIND-PROB.

## THINGS TO NOTICE

You might begin by getting an overall impression of the action in the view. The most prominent agents are the transcription factors (TFs). With each tick some are born and some die. Some stay in the same patch, and others relocate. Some may bind to a gene or the signal, and some may unbind. Each TF's behavior is guided by the rules given in HOW IT WORKS, but its specific action at any moment depends on probabilistic outcomes - it is stochastic.

Do you notice any patterns in the overall numbers of the TFs of each color? For example what happens when there is a build-up of turquoise TFs? Does a particular color of TF decrease in numbers next?

What connection can you observe between the number of mRNAs of each type and the number of corresponding TFs?

## THINGS TO TRY

By default, the simulation starts with no TFs. What happens if you start with TFs of one kind only? Do the other TFs eventually reach comparable levels?

BehaviorSpace can be used to systematically explore the effect of the variables. Which variables change the behavior most dramatically? Which variables increase or decrease the the interval between times the signal is on? Which variables increase the number of mRNAs or TFs? Can you find any states in which the signal is always on or always off?

## WHY ONE DIMENSIONAL?

There are advantages and disadvantages to having a one-dimensional model.

The main idea behind making the model one dimensional is to place the emphasis on how parameters such as binding and unbinding rates, synergy between TFs, and rate of mRNA production affect the rise and fall of different TF populations, and the intervals during which the signal is on and off. A potential disadvantage is that a two-dimensional model could be more realistic in a way that makes a difference.

The goal of a two-dimensional model would be that one could simulate the diffusion of TFs throughout the space. Synergy and binding could then be based on distance of TFs from the binding site. A potential problem with this type of modeling is that the time scale of the nano-movements is incredibly smaller than time scale of degradation of TFs and mRNAs. For example, TFs could wind up largely degrading before ever binding to a target.

## EXTENDING THE MODEL

  * Allow each of the three types of TF to have its own decay, binding and unbinding properties.
  * Allow each of the three types of mRNA to have its own decay and TF production properties.
  * Make the model two-dimensional - with patches in the y direction as well. The locations of the mRNA and TFs would then be physically meaningful. How would you handle the signal?
  * Display the age distribution of the TFs (collectively or by type.) Each TF has a TF-age property which equals the number of ticks for which it has existed. What is the shape of this distribution?
  * Instead of using a decay rate - a fixed probability of decay occurring in a fixed time period, one can characterize decay in terms of a half life - the time it takes for half of the items to die or transform. For example, Plutonium-239 has a half-life of 24,110 years. Convert decay rates to half-lives. Does this help you think about the effect of changing decay rates? What about other rates? The action of medicinal drugs is typically characterized by a half-life.

## NETLOGO FEATURES

An unusual feature of this model is that there is only one dimension of patches. The two-dimensional layout of each patch is computed using the patch's coordinate range , as well as information about the size of each breed of turtle. The x coordinates of `patch i 0` range from `i - 0.5` to `i + 0.5`  and y coordinates range from -0.5 to 0.5. The circularity of the topology is maintained through the use of the mod function. Since there are three patches, the patch to the right of `patch i 0` is `patch ((i + 1) mod 3) 0`. For example, the right-most patch is `patch 2 0`. The patch to its right is `patch (3 mod 3) 0`, which is `patch 0 0`, the left-most patch.

To control the placement of labels, this model makes use extra turtles called banners. ( See the Label Position Example model) NetLogo right justifies the position of a label in the lower right corner of the turtle’s bounding box. A banner is a turtle of size zero that carries the desired label. The x and y coordinates of the banner must be appropriately calculated relative to the size and position of the turtle that is actually being labeled.

## RELATED MODELS

* DNA Protein Synthesis
* GenEvo 1 - Genetic Switch
* Label Position Example
* Rock Paper Scissors

## CREDITS AND REFERENCES

Elowitz, M. B., & Leibler, S. (2000). A synthetic oscillatory network of transcriptional regulators. Nature, 403(6767), 335–338. 10.1038/35002125.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Brandes, A. and Wilensky, U. (2020).  NetLogo Repressilator 1D model.  http://ccl.northwestern.edu/netlogo/models/Repressilator1D.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2020 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2020 Cite: Brandes, A. -->
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

binding site
true
6
Rectangle -13840069 true true 0 150 75 180
Rectangle -13840069 true true 120 150 180 180
Rectangle -13840069 true true 225 150 300 180
Rectangle -13840069 true true 0 180 300 195

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

dna 1
false
15
Rectangle -10899396 true false 0 150 60 173
Rectangle -13345367 true false 60 196 0 176
Rectangle -13345367 true false 238 150 298 173
Rectangle -11221820 true false 0 172 60 195
Rectangle -14835848 true false 61 150 121 173
Rectangle -13345367 true false 61 172 121 195
Rectangle -13345367 true false 122 150 182 173
Rectangle -14835848 true false 122 172 182 195
Rectangle -10899396 true false 181 172 241 195
Rectangle -14835848 true false 242 172 302 195
Rectangle -11221820 true false 180 150 240 173

dna 2
false
15
Rectangle -11221820 true false 0 150 60 173
Rectangle -13345367 true false 60 196 0 176
Rectangle -13345367 true false 238 150 298 173
Rectangle -10899396 true false 0 172 60 195
Rectangle -11221820 true false 61 150 121 173
Rectangle -10899396 true false 61 172 121 195
Rectangle -10899396 true false 122 150 182 173
Rectangle -13345367 true false 122 172 182 195
Rectangle -10899396 true false 181 172 241 195
Rectangle -14835848 true false 242 172 302 195
Rectangle -11221820 true false 180 150 240 173

dna 3
false
15
Rectangle -11221820 true false 240 150 300 173
Rectangle -13345367 true false 300 196 240 176
Rectangle -13345367 true false -1 150 59 173
Rectangle -10899396 true false 240 172 300 195
Rectangle -11221820 true false 179 150 239 173
Rectangle -10899396 true false 179 172 239 195
Rectangle -10899396 true false 118 150 178 173
Rectangle -13345367 true false 118 172 178 195
Rectangle -10899396 true false 59 172 119 195
Rectangle -14835848 true false -2 172 58 195
Rectangle -11221820 true false 60 150 120 173

dna 4
false
15
Rectangle -10899396 true false 240 150 300 173
Rectangle -13345367 true false 300 196 240 176
Rectangle -13345367 true false -1 150 59 173
Rectangle -11221820 true false 240 172 300 195
Rectangle -14835848 true false 179 150 239 173
Rectangle -13345367 true false 179 172 239 195
Rectangle -13345367 true false 118 150 178 173
Rectangle -14835848 true false 118 172 178 195
Rectangle -10899396 true false 59 172 119 195
Rectangle -14835848 true false -2 172 58 195
Rectangle -11221820 true false 60 150 120 173

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

mrna
true
2
Circle -955883 true true 219 114 42
Circle -955883 true true 189 129 42
Circle -955883 true true 159 114 42
Circle -955883 true true 39 114 42
Circle -955883 true true 69 129 42
Circle -955883 true true 98 144 42
Circle -955883 true true 129 129 42
Circle -16777216 false false 99 145 40
Circle -16777216 false false 220 115 40
Circle -16777216 false false 189 132 40
Circle -16777216 false false 160 114 40
Circle -16777216 false false 129 131 40
Circle -16777216 false false 70 131 40
Circle -16777216 false false 39 114 40

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

signal
false
6
Circle -13840069 true true 30 60 240
Rectangle -13840069 true true 120 150 180 180
Rectangle -14835848 true false 30 45 270 150
Rectangle -14835848 true false 75 150 120 180
Rectangle -14835848 true false 180 150 225 180

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

transcription factor
true
8
Rectangle -11221820 true true 75 150 120 180
Rectangle -11221820 true true 180 150 225 180
Rectangle -11221820 true true 75 105 225 150
Circle -11221820 true true 88 13 124
Rectangle -16777216 true false 75 165 120 180
Rectangle -16777216 true false 180 165 225 180

transcription factor bound
true
8
Rectangle -16777216 true false 75 150 120 180
Rectangle -16777216 true false 180 150 225 180
Circle -11221820 true true 105 60 90
Rectangle -11221820 true true 75 120 225 150

transcription factor signal bound
false
8
Rectangle -16777216 true false 75 150 120 180
Rectangle -16777216 true false 180 150 225 180
Rectangle -11221820 true true 90 105 210 150
Circle -11221820 true true 129 84 42

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
<experiments>
  <experiment name="repr 1" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>on-off-harmonic-mean</metric>
    <metric>mean-off-duration</metric>
    <metric>mean-on-duration</metric>
    <steppedValueSet variable="signal-decay-prob" first="0.05" step="0.1" last="0.95"/>
    <steppedValueSet variable="signal-TF-bind-prob" first="0.05" step="0.1" last="0.95"/>
  </experiment>
  <experiment name="TF-mRNA-experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>on-off-harmonic-mean</metric>
    <metric>mean-off-duration</metric>
    <metric>mean-on-duration</metric>
    <steppedValueSet variable="TF-bind-prob" first="0.05" step="0.1" last="0.95"/>
    <steppedValueSet variable="mRNA-decay-prob" first="0.05" step="0.1" last="0.95"/>
    <steppedValueSet variable="TF-decay-prob" first="0.05" step="0.1" last="0.95"/>
    <steppedValueSet variable="TF-unbind-prob" first="0.05" step="0.1" last="0.95"/>
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
