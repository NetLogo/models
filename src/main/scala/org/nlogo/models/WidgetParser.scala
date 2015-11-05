package org.nlogo.models

import scala.collection.JavaConverters.asScalaBufferConverter

import org.nlogo.api.ModelReader
import org.nlogo.plot.Plot
import org.nlogo.plot.PlotLoader

object WidgetParser {

  /*
   * The code here is mostly lifted from:
   * org.nlogo.headless.HeadlessModelOpener.WidgetParser
   *
   * I hate having to do this, but the original has unwanted
   * side-effects and requires a workspace.
   *
   * This version is also stripped down to only get what I need:
   * pieces of code and variable names, for the purpose of tokenizing.
   * It's not pretty code, but it works...
   *
   * NP 2015-10-16.
   */

  def parseWidgets(widgetsSection: Array[String]): List[String] = {

    // parsing widgets dumps all bits of code in this mutable val
    val buffer = new collection.mutable.ArrayBuffer[String]

    def parseSlider(widget: Array[String]) {
      buffer ++= List(widget(6), widget(7), widget(8), widget(10), widget(9))
    }

    def parseSwitch(widget: Array[String]) {
      buffer += widget(6)
    }

    def parseChoiceOrChooser(widget: Array[String]) {
      buffer += widget(6)
    }

    def parseInputBox(widget: Array[String]) {
      buffer += widget(5)
    }

    def parsePlot(widget: Array[String]) {
      val plot = new Plot(widget(5))
      PlotLoader.parsePlot(widget, plot, identity)
      buffer += plot.setupCode
      buffer += plot.updateCode
      for (pen <- plot.pens) {
        buffer += pen.setupCode
        buffer += pen.updateCode
      }
    }

    def parseButton(widget: Array[String]) {
      buffer += (ModelReader.restoreLines(widget(6)) match {
        case "NIL" => ""
        case s => s
      })
    }

    def parseMonitor(widget: Array[String]) {
      buffer += ModelReader.restoreLines(widget(6))
    }

    // finally parse all the widgets in the WIDGETS section
    val widgets = ModelReader.parseWidgets(widgetsSection)

    for (widget <- widgets.asScala.map(_.asScala.toArray))
      widget(0) match {
        case "SLIDER" => parseSlider(widget)
        case "SWITCH" => parseSwitch(widget)
        case "CHOICE" | "CHOOSER" => parseChoiceOrChooser(widget)
        case "INPUTBOX" => parseInputBox(widget)
        case "PLOT" => parsePlot(widget)
        case "BUTTON" => parseButton(widget)
        case "MONITOR" => parseMonitor(widget)
        case _ => // ignore
      }

    buffer.toList

  }

}
