package org.nlogo.models

class BadInterfacesTests extends TestModels {

  val allowedLengths = Map(
    "BUTTON" -> (11, 16),
    "SLIDER" -> (12, 14),
    "SWITCH" -> (10, 10),
    "MONITOR" -> (9, 10),
    "GRAPHICS-WINDOW" -> (10, 28),
    "TEXTBOX" -> (6, 9),
    "CHOICE" -> (9, 9),
    "CHOOSER" -> (9, 9),
    "OUTPUT" -> (5, 6),
    "INPUTBOX" -> (8, 10),
    "PLOT" -> (14, 999999)) // any number of pens

  testModels("Widget sections should have proper lengths") {
    for {
      model <- _
      widget <- model.interface.split("\n\n")
      kind = widget.split("\n").head
      (min, max) <- allowedLengths.get(kind)
      len = widget.split("\n").size
      if len < min || len > max
    } yield s"$kind (min: $min, max: $max) has length $len in ${model.quotedPath}"
  }
}
