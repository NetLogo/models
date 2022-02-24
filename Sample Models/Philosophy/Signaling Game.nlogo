globals [
  sender      ; the player perceiving a world state and sending a signal
  receiver    ; the player perceiving a signal and guessing the state
  world-state ; the currently active world state
]

; There are two players: a sender and a receiver.
breed [ players player ]

; States represent the possible states that the world can be in.
; Only one of them is active on each tick.
breed [ states state ]

; Signals represent possible signals that the sender can use
; to try to communicate the observed world state to the receiver.
breed [ signals signal ]

; Observations link a world state to the sender that's perceiving it
; or a signal to the receiver that's perceiving it.
directed-link-breed [ observations observation ]

; Choices link the sender to the world state that the sender thinks
; the receiver meant by the chosen signal.
directed-link-breed [ choices choice ]

; Urns are used to represent the associations between states and signals in the
; minds of the players:
;
; - The sender has an urn for each possible world state, and each ball in the urn
;   is a signal that the sender can use to represent that state. When the sender
;   observes a state, the sender picks a "signal ball" in the corresponding "state
;   urn" and sends that signal to the receiver.
; - The receiver has an urn for each possible signal. When the receiver sees a
;   signal, the receiver picks a ball in the corresponding "signal urn": each
;   ball is a state that the receiver can interpret the signal to mean.
;
; When communication is successful, the sender puts another copy of the "signal ball"
; in the "state urn" and the receiver puts another copy of the "state ball" in the
; "signal urn", increasing the probability that this state is associated with this
; signal in the future.
undirected-link-breed [ urns urn ]
urns-own [ balls ]

to setup
  clear-all
  ask patches [ set pcolor black + 1 ]
  setup-states
  setup-signals
  setup-players
  reset-ticks
end

to go
  if probability-of-success > 0.99 [ stop ]
  ; prepare the world for this round
  ask choices [ die ]
  ask observations [ die ]
  ask states [ look-inactive ]
  ask signals [ look-inactive ]
  ask players [ set shape "face neutral" ]
  set world-state one-of states
  ask world-state [ look-active ]

  ; the sender chooses a signal in response to the world state
  ask sender [
    observe world-state
    pick-from urn-with world-state
  ]
  ask chosen-signal [ look-active ]

  ; the receiver chooses the world state to act on, in response to the signal
  ask receiver [
    observe chosen-signal
    pick-from urn-with chosen-signal
  ]

  ifelse (guessed-state = world-state) [
    ; when the choice is correct, both players are happy
    ask [ my-out-choices ] of receiver [ set color lime ]
    ask players [ set shape "face happy" ]
    ; and the probability of choosing the same signal and actions
    ; is increased by adding the successful choices as balls in the players urns:
    ask [ urn-with world-state ] of sender [ set balls lput chosen-signal balls ]
    ask [ urn-with chosen-signal ] of receiver [ set balls lput guessed-state balls ]
  ]
  [ ; when the choice is wrong, both players are sad
    ask [ my-out-choices ] of receiver [ set color red ]
    ask players [ set shape "face sad" ]
  ]

  if print-probabilities? [ print-probabilities ]
  tick
end

to setup-states
  set-default-shape states "circle 2"
  foreach state-labels number-of-states [ the-label ->
    create-states 1 [
      set label the-label
      set color sky
      look-inactive
    ]
  ]
  spread-x (max-pycor - (world-height / 6)) states
  create-turtles 1 [ setxy 4.75 max-pycor - 2 set label "world states" set size 0 set label-color grey ]
end

to setup-signals
  set-default-shape signals "square 2"
  foreach signal-labels number-of-signals [ the-label ->
    create-signals 1 [
      set label the-label
      set color magenta
      look-inactive
    ]
  ]
  spread-x (min-pycor + (world-height / 6)) signals
  create-turtles 1 [
    setxy 2.75 min-pycor + 1
    set label "signals"
    set size 0
    set label-color grey
  ]
end

to setup-players
  set-default-shape players "face neutral"
  set-default-shape urns "empty"
  create-players 1 [
    set label "sender       "
    set sender self
    create-urns-with states [
      ; each possible world state is associated with an urn from which
      ; the sender picks signals, with equal probability at first
      set balls sort signals
    ]
  ]
  create-players 1 [
    set label "receiver       "
    set receiver self
    create-urns-with signals [
      ; each possible signal is associated with an urn from which
      ; the receiver picks states, with equal probability at first
      set balls sort states
    ]
  ]
  ask players [
    set size 3
    set color yellow
  ]
  spread-x 0 players
end

to observe [ thing ] ; player procedure
  create-observation-from thing [
    set color black + 2
  ]
  display
end

to pick-from [ this-urn ] ; player procedure
  create-choice-to [ one-of balls ] of this-urn [
    set thickness 0.3
    set color white
  ]
  display
end

to look-active ; states and signals procedure
  set color color + 3
  set label-color white
  set size size + 1
  set shape remove " 2" shape
end

to look-inactive ; states and signals procedure
  set size 2
  set color (base-shade-of color) - 3
  set label-color (base-shade-of color) + 3
  set shape word (remove " 2" shape) (" 2")
end

to spread-x [ y agents ] ; observer procedure
  let d world-width / (count agents + 1)
  let xs n-values count agents [ n -> (min-pxcor - 0.5) + d + (d * n) ]
  (foreach sort agents xs [ [a x] -> ask a [ setxy x y ] ])
end

to-report state-labels [ n ]
  report sublist ["A" "B" "C" "D" "E" "F" "G" "H"] 0 n
end

to-report signal-labels [ n ]
  report n-values n [ the-label -> the-label ]
end

to-report base-shade-of [ some-color ]
  report some-color - (some-color mod 10) + 5
end

to-report chosen-signal
  report [ one-of out-choice-neighbors ] of sender
end

to-report guessed-state
  report [ one-of out-choice-neighbors ] of receiver
end

to-report times-correct
  report [ sum [ length balls - count signals ] of my-urns ] of sender
end

to-report times-wrong
  report ticks - times-correct
end

to print-probabilities
  clear-output
  output-print "Sender probabilities:"
  output-print probability-table states signals sender
  output-print ""
  output-print "Receiver probabilities:"
  output-print probability-table signals states receiver
end

to-report probability-table [ ys xs this-player ]
  let columns-labels fput "" map [ x -> [ label ] of x ] sort xs
  let separators fput "" n-values count xs [ "---" ]
  let rows map [ y -> [ make-row urn-with y ] of this-player ] sort ys
  let formatted-rows map format-list (fput columns-labels fput separators rows)
  report reduce [ [a b] -> (word a "\n" b) ] formatted-rows
end

to-report make-row [ this-urn ]
  let header-column word ([ label ] of [ end1 ] of this-urn) " :"
  let other-columns map [ p -> p * 100 ] probabilities this-urn
  report fput header-column other-columns
end

to-report format-list [ this-list ]
  let formatted-values map [ value -> format-value value 4 ] this-list
  report reduce [ [a b] -> (word a "  " b) ] formatted-values
end

to-report format-value [ x width ]
  let str (word ifelse-value is-number? x [ precision x 0 ] [ x ])
  let padding ifelse-value length str < width
    [ reduce word (n-values (width - length str) [ " " ]) ]
    [ "" ]
  report word padding str
end

to-report probabilities [ this-urn ]
  let this-breed [ breed ] of first [ balls ] of this-urn
  report normalize map [ a -> instances a [ balls ] of this-urn ] sort this-breed
end

to-report instances [ x this-list ]
  ; report the number of instances of x in this-list
  report reduce [ [a b] -> a + ifelse-value b = x [ 1 ] [ 0 ] ] fput 0 this-list
end

to-report normalize [ this-list ]
  let total sum this-list
  report map [ n -> n / total ] this-list
end

to-report probability-of-success
  report (sum [ probability-of-state-success ] of states) / count states
end

to-report probability-of-state-success ; state reporter
  let target-state self
  let this-urn [ urn-with target-state ] of sender
  report sum [
    [ probability-of-choosing myself ] of this-urn * probability-of-signal-success target-state
  ] of signals
end

to-report probability-of-signal-success [ target-state ] ; signal reporter
  let this-urn [ urn-with myself ] of receiver
  report [ probability-of-choosing target-state ] of this-urn
end

to-report probability-of-choosing [ target ] ; urn reporter
  report (instances target balls) / (length balls)
end


; Copyright 2016 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
290
15
831
401
-1
-1
13.0
1
20
1
1
1
0
0
0
1
-20
20
-14
14
1
1
1
ticks
30.0

SLIDER
15
15
280
48
number-of-states
number-of-states
2
8
2.0
1
1
NIL
HORIZONTAL

BUTTON
15
95
95
128
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
100
95
190
128
go once
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

BUTTON
195
95
280
128
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

MONITOR
15
380
100
425
times wrong
times-wrong
17
1
11

MONITOR
105
380
190
425
times correct
times-correct
17
1
11

PLOT
15
135
280
325
probability of success
ticks
%
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot probability-of-success * 100"

OUTPUT
850
10
1310
385
12

SWITCH
980
390
1167
423
print-probabilities?
print-probabilities?
0
1
-1000

SLIDER
15
55
280
88
number-of-signals
number-of-signals
2
8
2.0
1
1
NIL
HORIZONTAL

MONITOR
15
330
280
375
probability-of-success
word (precision (probability-of-success * 100) 2) \" %\"
2
1
11

MONITOR
195
380
280
425
success rate
word precision ((times-correct / ticks) * 100) 2 \" %\"
2
1
11

@#$#@#$#@
## WHAT IS IT?

This is a model of a "signaling game", in which players try to use different signals to communicate about the current state of the world.

Signaling games were discussed by the philosopher David Lewis in his book _Convention_. Lewis uses the example of Paul Revere, who during the American Revolution, asked the custodian of the Old North church to use the following signals to warn the American patriots about the movements of the British army:

- If the British troops are coming by sea, hang two lanterns in the church steeple;
- If the British troops are coming by land, hang one lantern in the church steeple;
- If the British troop are not coming, don't hang any lantern.

This is just one example. Signals are everywhere. Airport marshallers use hand signals to direct planes on a runway. Boats use flags to warn the crew of other boats about certain situations ("there has been a mutiny on board", "we're carrying explosives", etc.)

Communication systems work even if the signals used to represent world states have nothing in common with the state they represent. You don't need something that looks like a boat to represent the fact that the British troops are coming by boat. All that is needed is for everyone involved to agree that a particular signal represents a particular state of the world: when that happens, we say that everyone shares the same "convention".

David Lewis' signaling game assumes that agents already have an agreed upon convention and that they are rational enough to follow it. Another philosopher, Brian Skyrms showed that it was possible for a convention to emerge even if agents have not agreed in advance about which signal to use for which state.

Skyrms used a very simple version of the signaling game, with only two states and two signals. The players start by using random signals to represent different world states. Sometimes communication fails: the "receiver" interprets the signal to mean a different state than what the "sender" meant. But sometimes communication succeeds, and when it succeeds, the association between the state and the signal is reinforced. With time, it is possible for both players to converge on a convention.

Our version of the signaling game allows you to experiment with up to eight possible states and eight signals.

## HOW IT WORKS

Blue circles at the top of the view represent different possible world states. They are labeled with letters.

Pink squares at the bottom represent possible signals. They are labeled with numbers. (You can think of those as the number of lanterns to hang if you want to.)

In the middle of the view, there is a "sender" and a "receiver".

The sender perceives the active world state and is trying to communicate it to the receiver (who cannot perceive the world state directly) using one of the possible signals.

If the communication is successful, then both players are happy and the connection between that state and that signal is reinforced for the both the sender and the receiver.

Here is the detailed sequence of actions happening in the model at each tick:

1. First, a random world state is selected. The corresponding circle becomes highlighted.

2. The sender perceives that world state. That’s represented by the thin gray arrow between the highlighted world state and the sender.

3. The sender chooses a signal to communicate that world state to the receiver. That’s represented by the thick white arrow between the sender and the signal.

4. The receiver perceives the chosen signal. That’s the thin gray arrow between signal and receiver.

5. The receiver chooses an action appropriate for the world state that he thinks the signal represents. That’s the thick arrow between receiver and world state. If the receiver selected the correct state, that arrow turns green and the players are happy. When the choice is not correct, the arrow turns red and the players are sad.

## HOW TO USE IT

There are only two parameters for this models: the NUMBER-OF-STATES and the NUMBER-OF-SIGNALS. Once you have chosen the values that you want for these two sliders, click SETUP to initialize the model and then GO (or GO ONCE) to run it.

The PROBABILITY OF SUCCESS plot (and the monitor by the same name) show how likely it is that a round of communication will be successful.

The TIMES WRONG, TIMES CORRECT and SUCCESS RATE monitors show what happened so far in the simulation.

The OUTPUT WINDOW to the right of the view displays two probability tables: one for the sender and one for the receiver. For the sender, those are the probabilities of using a particular signal when observing a given state. For the receiver, those are the probabilities of interpreting a given signal to mean a particular state. Those probabilities are rounded to the nearest integer, so it's possible that a column or a row doesn't add up to exactly 100.

The display of probabilities in the OUTPUT WINDOW can be switched on and off using the PRINT-PROBABILITIES? slider.

## THINGS TO NOTICE

Slow down the model using the speed slider: this will make the sequence of actions more explicit.

When there are two possible world states, the probability of successful communication starts at 50%. If there are four possible states, it starts at 25%. Changing the number of possible signals does not affect the initial probability of success. Can you explain why?

As time go by, the SUCCESS RATE should get closer to the PROBABILITY OF SUCCESS, but it may not ever reach 100%. Can you explain why?

When more than one state map to the same signal, we call this a "bottleneck". When more than one signal map to the same world state, we call those signals "synonyms". Bottlenecks happen when there are more possible states than signals. Synonyms can happen when there are more signals than states. Can you use the probability tables displayed in the OUTPUT WINDOW to identify bottlenecks and synonyms?

## THINGS TO TRY

In the paper that inspired this model, Brian Skyrms (2006) asks: "Suppose there are too many signals. Do synonyms persist, or do some signals fall out of use until only the number required to identify the states remain in use?"

Another question is: "Suppose there are too few signals. Then there is, of necessity, an information bottleneck. Does efficient signaling evolve; do the players learn to do as well as possible?"

Can you use the model to answer these two questions?

## EXTENDING THE MODEL

What if both players could take turns acting as senders and receivers? Would it converge faster?

Can you change the model to accommodate more than two players? Each player could be paired with another at each tick and send a signal to that partner. If that was the case, do you think that a consensual signaling system would emerge in the community?

## NETLOGO FEATURES

The model makes an extensive use of links to represent associations between the entities in the model. Urns, for example, play a very important role in the model even if they don't appear in the view.

The various reporters called by the `print-probabilities` procedure use higher-order list functions ([`map`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#map) and [`reduce`](http://ccl.northwestern.edu/netlogo/docs/dictionary.html#map)) to nicely format probability tables of varying height and width. This is advanced NetLogo code, but it shows that NetLogo can be very flexible in the way it displays information.

## CREDITS AND REFERENCES

- Skyrms, B. (2006). [Signals](www.socsci.uci.edu/~bskyrms/bio/other/Presidential%20Address.pdf). Presidential Address, Philosophy of Science Association, for PSA 2006.

- Lewis, D. (1969). Convention. Cambridge, MA: Harvard University Press.

- https://en.wikipedia.org/wiki/Signaling_game

Thanks to Ryan Muldoon for his help with this model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2016).  NetLogo Signaling Game model.  http://ccl.northwestern.edu/netlogo/models/SignalingGame.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2016 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2016 -->
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
resize-world -14 14 -14 14
setup repeat 75 [ go ]
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

empty
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
@#$#@#$#@
1
@#$#@#$#@
