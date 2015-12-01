package org.nlogo.models

import scala.collection.JavaConverters.asScalaBufferConverter
import scala.util.Try

import org.nlogo.api.CompilerException
import org.nlogo.api.ModelReader
import org.nlogo.api.Observer
import org.nlogo.api.SimpleJobOwner

class ButtonTests extends TestModels {

  // 3D models and models using extensions are excluded because our
  // current setup makes it non-trivial to headlessly compile them
  def excluded(model: Model) =
    model.is3d || model.code.lines.exists(_.startsWith("extensions"))

  testModels(Model.libraryModels.par,
    "Buttons should be disabled until ticks start if they trigger a runtime error") { model =>
      if (excluded(model)) Seq.empty else for {
        widget <- ModelReader.parseWidgets(model.interface.lines.toArray).asScala
        lines = widget.asScala
        if lines(0) == "BUTTON"
        disabledUntilTicksStart = (lines(15) == "0")
        if !disabledUntilTicksStart
        source = ModelReader.restoreLines(lines(6)).stripLineEnd
        displayName = Option(lines(5)).filterNot(_ == "NIL").getOrElse(source)
        exception <- withWorkspace(model) { ws =>
          val code = lines(10) match {
            case "TURTLE"   => "ask turtles [" + source + "\n]"
            case "PATCH"    => "ask patches [" + source + "\n]"
            case "OBSERVER" => source
          }
          val jobOwner = new SimpleJobOwner(displayName, ws.mainRNG, classOf[Observer])
          Try(ws.evaluateCommands(jobOwner, code, ws.world.observers, true)) // catch regular exceptions
            .failed.toOption.orElse(Option(ws.lastLogoException)) // and Logo exceptions
        }
        if exception.getMessage != "You can't get user input headless."
      } yield "\"" + displayName + "\" button: " + exception.getMessage
    }

}
