package org.nlogo.models

import org.nlogo.core.Button
import org.nlogo.core.Model
import org.nlogo.core.Monitor
import org.nlogo.core.Slider
import org.nlogo.core.Switch
import org.nlogo.core.Token
import org.nlogo.core.TokenType.Command
import org.nlogo.core.TokenType.Reporter
import org.nlogo.parse.Colorizer.Namer
import org.nlogo.parse.FrontEnd

class Tokens(model: Model) {

  def tokenize(source: String) = FrontEnd.tokenizer.tokenizeString(source).map(Namer).toSeq

  def widgetTokens: Seq[Token] =
    model.widgets.collect {
      case Button(Some(source), _, _, _, _, _, _, _, _, _) =>
        tokenize(source)
      case Switch(Some(variable), _, _, _, _, _, _) =>
        tokenize(variable)
      case Slider(Some(variable), _, _, _, _, _, min, max, _, step, _, _) =>
        Seq(variable, min, max, step).flatMap(tokenize)
      case Monitor(Some(source), _, _, _, _, _, _, _) =>
        tokenize(source)
    }.flatten

  def codeTokens: Seq[Token] = tokenize(model.code)

  def previewCommandsTokens: Seq[Token] = tokenize(model.previewCommands.source)

  def plotNames: Seq[String] =
    model.plots.map { plot =>
      plot.display.getOrElse("")
    }

  def plotPenNamesByPlot: Seq[(String, Seq[String])] =
    model.plots.map { plot =>
      plot.display.getOrElse("") -> plot.pens.map { pen =>
        pen.display
      }
    }

  def plotTokens: Seq[Token] =
    model.plots.flatMap { plot =>
      tokenize(plot.setupCode) ++ tokenize(plot.updateCode) ++
        plot.pens.flatMap { pen =>
          tokenize(pen.setupCode) ++ tokenize(pen.updateCode)
        }
    }

  def allTokens = widgetTokens ++ codeTokens ++ previewCommandsTokens ++ plotTokens

  // Note: this works for 3D models, but the 3D primitives don't
  // get properly typed as `Reporter` or `Command` by `Colorizer.Namer`. We'd need
  // to use a Namer that rely on `ThreeDTokenMapper` when needed. NP 2016-05-16
  def primitiveTokenNames: Seq[String] = allTokens
    .filter(t => t.tpe == Reporter || t.tpe == Command)
    .map(_.text)
}
