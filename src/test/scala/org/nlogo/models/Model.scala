package org.nlogo.models

import java.io.File
import java.util.regex.Pattern.quote
import scala.collection.JavaConverters.collectionAsScalaIterableConverter
import org.apache.commons.io.FileUtils
import org.apache.commons.io.FileUtils.listFiles
import org.apache.commons.io.FileUtils.readFileToString
import org.apache.commons.io.FilenameUtils.getExtension
import org.apache.commons.io.FilenameUtils.removeExtension
import scala.xml.XML

object Model {
  sealed abstract trait UpdateMode
  case object Continuous extends UpdateMode
  case object OnTicks extends UpdateMode

  val modelDir = new File(".")
  val extensions = Array("nlogo", "nlogo3d")
  val sectionSeparator = "@#$#@#$#@"
  val manualPreview = "need-to-manually-make-preview-for-this-model"
  val models: Iterable[Model] = {
    val testPath = new File("test/").getCanonicalPath
    val isUnderTest = (_: File).getCanonicalPath.startsWith(testPath)
    listFiles(modelDir, extensions, true).asScala
      .filterNot(isUnderTest)
      .map(apply)
  }

  def apply(file: File): Model = {
    val content = readFileToString(file, "UTF-8")
    val sections = (content + sectionSeparator + "\n").split(quote(sectionSeparator) + "\\n")
    val Array(
      code, interface, infoString, turtleShapes, version,
      previewCommands, systemDynamics, behaviorSpace,
      hubNetClient, linkShapes, modelSettings) = sections
    val info = Info.fromContent(infoString)
    Model(file, info, code, interface, turtleShapes,
      version, previewCommands, systemDynamics, behaviorSpace,
      hubNetClient, linkShapes, modelSettings)
  }

}

case class Model(
  val file: File,
  val info: Info,
  val code: String,
  val interface: String,
  val turtleShapes: String,
  val version: String,
  val previewCommands: String,
  val systemDynamics: String,
  val behaviorSpace: String,
  val hubNetClient: String,
  val linkShapes: String,
  val modelSettings: String) {
  import Model._
  assert(extensions.contains(getExtension(file.getName)))
  val content = Seq(
    code, interface, info.content, turtleShapes, version,
    previewCommands, systemDynamics, behaviorSpace,
    hubNetClient, linkShapes, modelSettings)
    .mkString("", sectionSeparator + "\n", sectionSeparator + "\n")
  def save() = FileUtils.write(file, content, "UTF-8")
  def needsManualPreview = previewCommands.toLowerCase.contains(manualPreview)
  def is3d = getExtension(file.getName) == "nlogo3d"
  def updateMode: UpdateMode =
    if (interface.lines
      .dropWhile(_ != "GRAPHICS-WINDOW")
      .drop(if (is3d) 24 else 21).take(1).contains("1"))
      OnTicks else Continuous
  def patchSize: Double = interface.lines
    .dropWhile(_ != "GRAPHICS-WINDOW")
    .drop(7).next.toDouble
  def quotedPath = "\"" + file.getCanonicalPath + "\""
  def previewFile = new File(removeExtension(file.getPath) + ".png")
  def legalInfo = LegalInfo(this)
  val isIABM = file.getPath.contains("IABM")
  val isHubNet =
    file.getPath.startsWith("./HubNet Activities/")
  val name =
    file.getPath.reverse.dropWhile(_ != '.').tail.takeWhile(_ != '/').reverse.mkString
  val compressedName =
    (if (isHubNet) "HubNet" else "") + name.replaceAll(" ", "")
  val baseName =
    if (name.endsWith(" 3D"))
      name.replaceFirst(" 3D$", "")
    else name
    def behaviorSpaceXML = XML.loadString(behaviorSpace)
}
