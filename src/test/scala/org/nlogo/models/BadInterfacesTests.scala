package org.nlogo.models

import java.awt.Font
import java.awt.image.BufferedImage

import org.nlogo.awt.Fonts
import org.nlogo.core.Output
import org.nlogo.core.TextBox

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

  testModels("Widget sections should have proper lengths") { model =>
    for {
      widgetDefinition <- model.sections(1).split("\n\n")
      kind = widgetDefinition.split("\n").head
      (min, max) <- allowedLengths.get(kind)
      len = widgetDefinition.split("\n").size
      if len < min || len > max
    } yield s"$kind (min: $min, max: $max) has length $len"
  }

  testModels("Output widgets should have reasonably sized font") { model =>
    for {
      output <- model.widgets.collect { case w: Output => w }
      if output.fontSize < 8 || output.fontSize > 14
    } yield s"OUTPUT has font size ${output.fontSize}"
  }

  testModels("Textboxes (i.e., notes) should be wide enough") { model =>
    val graphics = new BufferedImage(1, 1, BufferedImage.TYPE_INT_RGB).createGraphics
    val bufferPct = 3 // how much of a safety buffer do we want to keep for wider fonts?
    for {
      note <- model.widgets.collect { case w: TextBox=> w }
      text <- note.display.toSeq
      noteWidth = note.right - note.left
      font = new Font(Fonts.platformFont, Font.PLAIN, note.fontSize)
      fontMetrics = graphics.getFontMetrics(font)
      line <- text.linesIterator
      lineWidth = fontMetrics.stringWidth(line)
      desiredWidth = (lineWidth + lineWidth * (bufferPct / 100.0)).ceil.toInt
      if noteWidth < desiredWidth
    } yield s"Line width is $lineWidth px but note width is $noteWidth px. " +
      s"It should be $desiredWidth px to get a $bufferPct% buffer:\n    $line"
  }
}
