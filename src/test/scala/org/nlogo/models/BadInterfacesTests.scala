package org.nlogo.models

import java.awt.Font
import java.awt.image.BufferedImage
import javax.swing.JLabel

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

  testModels("Textboxes (i.e., notes) should be tall enough to fit their content") { model =>
    for {
      note <- model.widgets.collect { case w: TextBox=> w }
      text <- note.display.toSeq
      noteHeight = note.height
      dummyLabel = new JLabel(s"<html>$text</html>") {
        setFont(getFont.deriveFont(note.fontSize.toFloat))
      }
      desiredHeight = dummyLabel.getPreferredSize.height
      if noteHeight < desiredHeight
    } yield s"Content height is $desiredHeight px but note height is $noteHeight px. " +
            s"It should be $desiredHeight px to properly fit the content:\n$text"
  }
}
