package org.nlogo.models

import java.awt.Font
import java.awt.image.BufferedImage

import org.nlogo.awt.Fonts
import org.nlogo.core.Output
import org.nlogo.core.TextBox

class BadInterfacesTests extends TestModels {
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
      noteWidth = note.width
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
