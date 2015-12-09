package org.nlogo.models

import java.awt.Font
import java.awt.image.BufferedImage

import org.nlogo.api.ModelReader
import org.nlogo.awt.Fonts

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

  testLibraryModels("Widget sections should have proper lengths") { model =>
    for {
      widget <- model.interface.split("\n\n")
      kind = widget.split("\n").head
      (min, max) <- allowedLengths.get(kind)
      len = widget.split("\n").size
      if len < min || len > max
    } yield s"$kind (min: $min, max: $max) has length $len"
  }

  testLibraryModels("Output widgets should have reasonably sized font") { model =>
    for {
      widget <- model.interface.split("\n\n")
      lines = widget.split("\n")
      if lines.head == "OUTPUT"
      fontSize <- lines.lift(5).map(_.toInt)
      if fontSize < 8 || fontSize > 14
    } yield s"OUTPUT has font size $fontSize"
  }

  testLibraryModels("Textboxes (i.e., notes) should be wide enough") { model =>
    val graphics = new BufferedImage(1, 1, BufferedImage.TYPE_INT_RGB).createGraphics
    val bufferPct = 3 // how much of a safety buffer do we want to keep for wider fonts?
    for {
      widget <- model.interface.split("\n\n")
      lines = widget.split("\n")
      if lines.head == "TEXTBOX"
      noteWidth = lines(3).toInt - lines(1).toInt
      fontSize = lines(6).toInt
      font = new Font(Fonts.platformFont, Font.PLAIN, fontSize)
      fontMetrics = graphics.getFontMetrics(font)
      string <- ModelReader.restoreLines(lines(5)).lines
      stringWidth = fontMetrics.stringWidth(string)
      desiredWidth = (stringWidth + stringWidth * (bufferPct / 100.0)).ceil.toInt
      if noteWidth < desiredWidth
    } yield s"Line width is $stringWidth px but note width is $noteWidth px. " +
      s"It should be $desiredWidth px to get a $bufferPct% buffer:\n    $string"
  }
}
