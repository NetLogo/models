package org.nlogo.models

import scala.Left
import scala.Right
import scala.collection.JavaConverters.asScalaBufferConverter
import scala.collection.parallel.ParMap
import scala.util.Try

import org.nlogo.core.CompilerException
import org.nlogo.core.AgentKind.Observer
import org.nlogo.api.ModelReader
import org.nlogo.api.SimpleJobOwner
import org.nlogo.api.Version
import org.nlogo.api.World

class ButtonTests extends TestModels {

  val models = Model.libraryModels.filter { model =>
    (model.is3D == Version.is3D) &&
      (model.isCompilable) &&
      (!Set("GoGoMonitor", "GoGoMonitorSimple").contains(model.name)) // won't work without a GoGo board
  }.par

  case class Button(
    val model: Model,
    val displayName: String,
    val code: String,
    val disabledUntilTicksStart: Boolean) {
    def run(): Try[World] = Try {
      withWorkspace(model) { ws =>
        val jobOwner = new SimpleJobOwner(displayName, ws.mainRNG, Observer)
        try
          ws.evaluateCommands(jobOwner, "startup", ws.world.observers, true)
        catch {
          case e: CompilerException => /* ignore */
        }
        ws.evaluateCommands(jobOwner, code, ws.world.observers, true)
        Option(ws.lastLogoException)
          .filterNot(_.getMessage.endsWith("You can't get user input headless."))
          .foreach(throw _)
        ws.world
      }
    }
  }

  val buttons: ParMap[Model, Iterable[Button]] =
    models.map { model =>
      model -> (for {
        widget <- ModelReader.parseWidgets(model.interface.lines.toArray).asScala
        lines = widget.asScala
        if lines(0) == "BUTTON"
        disabledUntilTicksStart = (lines(15) == "0")
        source = ModelReader.restoreLines(lines(6)).stripLineEnd
        displayName = Option(lines(5)).filterNot(_ == "NIL").getOrElse(source)
        code = lines(10) match {
          case "TURTLE"   => "ask turtles [" + source + "\n]"
          case "PATCH"    => "ask patches [" + source + "\n]"
          case "OBSERVER" => source
        }
      } yield Button(model, displayName, code, disabledUntilTicksStart))
    }(collection.breakOut)

  testModels(buttons.keys, "Buttons should be disabled until ticks start if they trigger a runtime error") { model =>
    for {
      button <- buttons(model)
      if !button.disabledUntilTicksStart
      exception <- button.run().failed.toOption
    } yield "\"" + button.displayName + "\" button: " + exception.getMessage
  }

  testModels(buttons.keys,
    "If any button is disabled until ticks start, ensure at least one enabled button that resets ticks") {
      model =>
        for {
          modelButtons <- buttons.get(model)
          if modelButtons.exists(_.disabledUntilTicksStart)
          enabledButtons = modelButtons.filterNot(_.disabledUntilTicksStart)
          if !enabledButtons.exists(_.run().filter(_.ticks != -1).isSuccess)
        } yield ""
    }
}
