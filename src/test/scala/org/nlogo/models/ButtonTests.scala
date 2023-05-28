package org.nlogo.models

import scala.collection.parallel.ParMap
import scala.util.Try

import org.nlogo.api.SimpleJobOwner
import org.nlogo.api.Version
import org.nlogo.api.World
import org.nlogo.core.AgentKind
import org.nlogo.core.AgentKind.Observer
import org.nlogo.core.Button
import org.nlogo.core.CompilerException
import org.nlogo.core.Model

class ButtonTests extends TestModels {

  val models = libraryModels.filter { model =>
    (model.is3D == Version.is3D) &&
      (model.isCompilable) &&
      (!Set(
        "GoGoMonitor", // won't work without a GoGo board
        "GoGoMonitorSimple",
        "Arduino Example", // the arduino extension makes the tests crash when running in parallel
        "2.5d Patch View Example", "2.5d Turtle View Example", // https://github.com/NetLogo/View2.5D/issues/4
        "Python Flocking Clusters" // issues with sklearn install on GitHub Actions
      ).contains(model.name))
  }.par

  def run(model: Model, button: Button): Try[World] = Try {
    withWorkspace(model) { ws =>
      button.source.foreach { source =>
        val code = button.buttonKind match {
          // Surely I don't have to do this mapping myself? Not sure why I did
          // it this way - should be revisited at some point... - NP 2016-05-16
          case AgentKind.Turtle   => "ask turtles [" + source + "\n]"
          case AgentKind.Patch    => "ask patches [" + source + "\n]"
          case AgentKind.Link     => "ask links [" + source + "\n]"
          case AgentKind.Observer => source
        }
        val jobOwner = new SimpleJobOwner(button.display.getOrElse(source), ws.mainRNG, Observer)
        try {
          ws.evaluateCommands(jobOwner, "startup", ws.world.observers, true)
        } catch {
          case e: CompilerException => /* ignore */
        }
        ws.evaluateCommands(jobOwner, code, ws.world.observers, true)
        Option(ws.lastLogoException)
          .filterNot(_.getMessage.endsWith("You can't get user input headless."))
          .foreach(throw _)
      }
      ws.world
    }
  }

  val buttons: ParMap[Model, Iterable[Button]] =
    models.map { model =>
      model -> model.widgets.collect { case b: Button => b }
    }(collection.breakOut)

  testModels(buttons.keys, "Buttons should be disabled until ticks start if they trigger a runtime error") { model =>
    for {
      button <- buttons(model)
      source <- button.source
      if !button.disableUntilTicksStart
      exception <- run(model, button).failed.toOption
    } yield "\"" + button.display.getOrElse(source) + "\" button: " + exception.getMessage
  }

  testModels(buttons.keys,
    "If any button is disabled until ticks start, ensure at least one enabled button that resets ticks") {
      model =>
        for {
          modelButtons <- buttons.get(model)
          if modelButtons.exists(_.disableUntilTicksStart)
          enabledButtons = modelButtons.filterNot(_.disableUntilTicksStart)
          if !enabledButtons.exists(b => run(model, b).filter(_.ticks != -1).isSuccess)
        } yield ""
    }
}
