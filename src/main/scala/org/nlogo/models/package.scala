package org.nlogo

import java.io.File
import java.util.regex.Pattern.quote

import org.apache.commons.io.FileUtils.{ listFiles, readFileToString }
import org.apache.commons.io.FilenameUtils.{ getExtension, removeExtension }

import org.nlogo.api.{ LabProtocol, PreviewCommands, XMLReader }
import org.nlogo.core.{ Button, Model, Monitor, Slider }
import org.nlogo.fileformat.FileFormat
import org.nlogo.headless.{ HeadlessWorkspace, Main }
import org.nlogo.models.InfoTabParts

import scala.Boolean
import scala.jdk.CollectionConverters.CollectionHasAsScala
import scala.util.Try

package object models {

  Main.setHeadlessProperty()

  lazy val onLocal: Boolean = Option(System.getProperty("org.nlogo.onLocal")).getOrElse("true").toBoolean

  def withWorkspace[A](model: Model)(f: HeadlessWorkspace => A) = {
    val workspace = HeadlessWorkspace.newInstance

    try {
      workspace.silent = true
      // open the model from path instead of content string so that
      // the current directory gets set (necessary for `__includes`)
      workspace.open(model.file.getCanonicalPath, true)
      f(workspace)
    } finally workspace.dispose()
  }

  implicit class RicherString(s: String) {
    def indent(spaces: Int): String =
      s.linesIterator.map((" " * spaces) + _).mkString("\n")
  }

  val modelTries: Iterable[(File, Try[Model], Try[String])] = {
    val workspace = HeadlessWorkspace.newInstance
    try {
      workspace.silent = true
      val loader = FileFormat.standardAnyLoader(true, workspace.compiler.utilities)
      val modelDir = new File(".")
      val extensions = Array("nlogox", "nlogox3d")
      listFiles(modelDir, extensions, true).asScala
        .filterNot { f => extensions.map(".tmp." + _).exists(f.getName.endsWith) || f.toString.contains("test") }
        .map { f => (f, loader.readModel(f.toURI), Try(readFileToString(f))) }
    } finally workspace.dispose()
  }

  val modelFiles: Map[Model, File] =
    (for {
      (file, modelTry, _) <- modelTries
      model <- modelTry.toOption
    } yield model -> file).toMap

  val modelContent: Map[Model, String] =
    (for {
      (file, modelTry, contentTry) <- modelTries
      model <- modelTry.toOption
      content <- contentTry.toOption
    } yield model -> content).toMap

  val allModels: Iterable[Model] = modelFiles.keys.toSeq
  val libraryModels: Iterable[Model] = allModels.filterNot(_.isTestModel)

  val allModelsNamed: Map[Model, String] = modelFiles.view.mapValues(_.getName).toMap
  val libraryModelsNamed: Map[Model, String] = modelFiles.view.mapValues(_.getName).toMap

  implicit class EnrichedModel(val model: Model) {
    def file = modelFiles(model)
    def content = modelContent(model)
    def isTestModel = file.getCanonicalPath.startsWith(new File("test/").getCanonicalPath)
    def name = file.getPath.reverse.dropWhile(_ != '.').tail.takeWhile(_ != '/').reverse.mkString
    def isHubNet = name.contains("HubNet")
    def compressedName = name.replaceAll(" ", "")
    def isIABM = file.getPath.contains("IABM")
    def baseName = if (name.endsWith(" 3D")) name.replaceFirst(" 3D$", "") else name
    def is3D = getExtension(file.getName) == "nlogox3d"
    def quotedPath = "\"" + file.getCanonicalPath + "\""
    def previewFile = new File(removeExtension(file.getPath) + ".png")
    def infoTabParts = InfoTabParts.fromContent(model.info)
    def isCompilable: Boolean = {
      val notCompilableOnTestServer = Set(
        "Beatbox", "Composer", "GasLab With Sound", "Musical Phrase Example",
        "Percussion Workbench", "Sound Workbench", "Sound Machines", "Frogger",
        "Sound Machines", "GenJam - Duple") // because MIDI is not available on Jenkins
      val neverCompilable = Set("GoGoMonitor", "GoGoMonitorSimple", "Profiler Example")
      !(neverCompilable.contains(name) || (!onLocal && notCompilableOnTestServer.contains(name)))
    }
    def protocols: Seq[LabProtocol] = model
      .optionalSectionValue("org.nlogo.modelsection.behaviorspace").map(_.asInstanceOf[Seq[LabProtocol]])
      .getOrElse(Seq())
    def previewCommands: PreviewCommands = model
      .optionalSectionValue[PreviewCommands]("org.nlogo.modelsection.previewcommands")
      .get // let it crash if preview commands are not loaded
    def widgetSources: Seq[String] =
      model.widgets.collect {
        case Button(Some(source), _, _, _, _, _, _, _, _, _, _)   => Seq(source)
        case Slider(_, _, _, _, _, _, _, min, max, _, step, _, _) => Seq(min, max, step)
        case Monitor(Some(source), _, _, _, _, _, _, _, _, _)     => Seq(source)
      }.flatten
    def plotSources: Seq[String] =
      model.plots.flatMap { plot =>
        Seq(plot.setupCode, plot.updateCode) ++
          plot.pens.flatMap { pen =>
            Seq(pen.setupCode, pen.updateCode)
          }
      }
    def allSources: Seq[String] =
      Seq(model.code, model.previewCommands.source) ++ widgetSources ++ plotSources
  }

}
