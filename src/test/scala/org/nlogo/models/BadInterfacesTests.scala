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
}
