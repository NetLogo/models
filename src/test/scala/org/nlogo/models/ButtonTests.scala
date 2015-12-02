package org.nlogo.models

import scala.Left
import scala.Right
import scala.collection.JavaConverters.asScalaBufferConverter
import scala.collection.parallel.ParMap
import scala.util.Try

import org.nlogo.api.CompilerException
import org.nlogo.api.ModelReader
import org.nlogo.api.Observer
import org.nlogo.api.SimpleJobOwner
import org.nlogo.api.World

class ButtonTests extends TestModels {

  // 3D models and models using extensions are excluded because our
  // current setup makes it non-trivial to headlessly compile them
  def excluded(model: Model) =
    model.is3d || model.code.lines.exists(_.startsWith("extensions"))

  case class Button(
    val model: Model,
    val displayName: String,
    val code: String,
    val disabledUntilTicksStart: Boolean) {
    def run(): Either[Throwable, World] = withWorkspace(model) { ws =>
      val jobOwner = new SimpleJobOwner(displayName, ws.mainRNG, classOf[Observer])
      try ws.evaluateCommands(jobOwner, "startup", ws.world.observers, true)
      catch { case e: CompilerException => /* ignore */ }
      val exception =
        Try(ws.evaluateCommands(jobOwner, code, ws.world.observers, true)) // catch regular exceptions
          .failed.toOption.orElse(Option(ws.lastLogoException)) // and Logo exceptions
          .filterNot(_.getMessage == "You can't get user input headless.")
      exception match {
        case Some(e) => Left(e)
        case None    => Right(ws.world)
      }
    }
  }

  val buttons: ParMap[Model, Iterable[Button]] =
    Model.libraryModels.par.filterNot(excluded).map { model =>
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
      exception <- button.run().left.toOption
    } yield "\"" + button.displayName + "\" button: " + exception.getMessage
  }

  testModels(buttons.keys,
    "If any button is disabled until ticks start, ensure at least one enabled button that resets ticks") {
      model =>
        for {
          modelButtons <- buttons.get(model)
          if modelButtons.exists(_.disabledUntilTicksStart)
          enabledButtons = modelButtons.filterNot(_.disabledUntilTicksStart)
          if !enabledButtons.exists(_.run().right.exists(_.ticks != -1))
        } yield "Has buttons disabled until ticks start but no buttons that resets ticks."
    }
}
