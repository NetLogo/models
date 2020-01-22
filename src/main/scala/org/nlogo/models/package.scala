package org.nlogo

import java.io.File
import java.util.regex.Pattern.quote

import scala.Boolean
import scala.collection.JavaConverters.collectionAsScalaIterableConverter
import scala.util.Try

import org.apache.commons.io.FileUtils.listFiles
import org.apache.commons.io.FileUtils.readFileToString
import org.apache.commons.io.FilenameUtils.getExtension
import org.apache.commons.io.FilenameUtils.removeExtension
import org.nlogo.api.LabProtocol
import org.nlogo.api.PreviewCommands
import org.nlogo.core.Button
import org.nlogo.core.LibraryStatus
import org.nlogo.core.Model
import org.nlogo.core.Monitor
import org.nlogo.core.Slider
import org.nlogo.headless.HeadlessWorkspace
import org.nlogo.models.InfoTabParts

package object models {

  org.nlogo.headless.Main.setHeadlessProperty()

  lazy val onTestServer: Boolean = sys.env.get("JENKINS_URL").forall(!_.isEmpty)

  def withWorkspace[A](model: Model)(f: HeadlessWorkspace => A) = {
    val workspace = HeadlessWorkspace.newInstance
    val libraryManager = workspace.getLibraryManager
    libraryManager.reloadMetadata(isFirstLoad = false)
    val updateableLibs = libraryManager.getExtensionInfos.filter(_.status == LibraryStatus.CanUpdate)
    updateableLibs.foreach( (libInfo) => {
      println(s"Updating extension: ${libInfo.name}")
      libraryManager.installExtension(libInfo)
    })
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
      s.lines.map((" " * spaces) + _).mkString("\n")
  }

  val modelTries: Iterable[(File, Try[Model], Try[String])] = {
    val workspace = HeadlessWorkspace.newInstance
    try {
      workspace.silent = true
      val loader = fileformat.standardLoader(workspace.compiler.utilities)
      val modelDir = new File(".")
      val extensions = Array("nlogo", "nlogo3d")
      listFiles(modelDir, extensions, true).asScala
        .filterNot { f => extensions.map(".tmp." + _).exists(f.getName.endsWith) }
        .map { f => (f, loader.readModel(f.toURI), Try(readFileToString(f))) }
    } finally workspace.dispose()
  }

  val modelFiles: Map[Model, File] =
    (for {
      (file, modelTry, _) <- modelTries
      model <- modelTry.toOption
    } yield model -> file)(collection.breakOut)

  val modelContent: Map[Model, String] =
    (for {
      (file, modelTry, contentTry) <- modelTries
      model <- modelTry.toOption
      content <- contentTry.toOption
    } yield model -> content)(collection.breakOut)

  val allModels: Iterable[Model] = modelFiles.keys.toSeq
  val libraryModels: Iterable[Model] = allModels.filterNot(_.isTestModel)

  implicit class EnrichedModel(val model: Model) {
    def file = modelFiles(model)
    def content = modelContent(model)
    def isTestModel = file.getCanonicalPath.startsWith(new File("test/").getCanonicalPath)
    def isHubNet = file.getPath.startsWith("./HubNet Activities/")
    def name = file.getPath.reverse.dropWhile(_ != '.').tail.takeWhile(_ != '/').reverse.mkString
    def compressedName = (if (isHubNet) "HubNet" else "") + name.replaceAll(" ", "")
    def isIABM = file.getPath.contains("IABM")
    def baseName = if (name.endsWith(" 3D")) name.replaceFirst(" 3D$", "") else name
    def is3D = getExtension(file.getName) == "nlogo3d"
    def quotedPath = "\"" + file.getCanonicalPath + "\""
    def previewFile = new File(removeExtension(file.getPath) + ".png")
    def infoTabParts = InfoTabParts.fromContent(model.info)
    def isCompilable: Boolean = {
      val notCompilableOnTestServer = Set(
        "Beatbox", "Composer", "GasLab With Sound", "Musical Phrase Example",
        "Percussion Workbench", "Sound Workbench", "Sound Machines", "Frogger",
        "Sound Machines", "GenJam - Duple") // because MIDI is not available on Jenkins
      val neverCompilable = Set("GoGoMonitor", "GoGoMonitorSimple", "Profiler Example")
      !(neverCompilable.contains(name) || (onTestServer && notCompilableOnTestServer.contains(name)))
    }
    def protocols: Seq[LabProtocol] = model
      .optionalSectionValue("org.nlogo.modelsection.behaviorspace")
      .getOrElse(Seq.empty)
    def previewCommands: PreviewCommands = model
      .optionalSectionValue[PreviewCommands]("org.nlogo.modelsection.previewcommands")
      .get // let it crash if preview commands are not loaded
    def sections = {
      val sectionSeparator = "@#$#@#$#@"
      (content + sectionSeparator + "\n").split(quote(sectionSeparator) + "\\n")
    }
    def widgetSources: Seq[String] =
      model.widgets.collect {
        case Button(Some(source), _, _, _, _, _, _, _, _, _)   => Seq(source)
        case Slider(_, _, _, _, _, _, min, max, _, step, _, _) => Seq(min, max, step)
        case Monitor(Some(source), _, _, _, _, _, _, _)        => Seq(source)
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
