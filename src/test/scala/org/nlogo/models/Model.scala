package org.nlogo.models

import java.io.File
import java.util.regex.Pattern.quote

import scala.collection.JavaConverters.collectionAsScalaIterableConverter

import org.apache.commons.io.FileUtils.listFiles
import org.apache.commons.io.FileUtils.readFileToString
import org.apache.commons.io.FilenameUtils.getExtension
import org.apache.commons.io.FilenameUtils.removeExtension
import org.scalatest.FunSuite

object Model {
  val modelDir = new File(".")
  val extensions = Array("nlogo", "nlogo3d")
  val models: Iterable[Model] = {
    val testPath = new File("test/").getCanonicalPath
    val isUnderTest = (_: File).getCanonicalPath.startsWith(testPath)
    listFiles(modelDir, extensions, true).asScala
      .filterNot(isUnderTest) // at least until https://github.com/NetLogo/models/issues/56 is fixed
      .map(new Model(_))
  }
  val sectionSeparator = "@#$#@#$#@"
  val manualPreview = "need-to-manually-make-preview-for-this-model"
}

trait TestModels extends FunSuite {
  def testModels(testName: String)(testFun: Iterable[Model] => Iterable[String]): Unit =
    test(testName) {
      val failures = testFun(Model.models)
      if (failures.nonEmpty) fail(failures.mkString("", "\n", "\n  -- "))
    }
}

sealed abstract trait UpdateMode
case object Continuous extends UpdateMode
case object OnTicks extends UpdateMode

class Model(val file: File) {
  import Model._
  assert(extensions.contains(getExtension(file.getName)))
  def content = readFileToString(file, "UTF-8")
  lazy val sections = (content + sectionSeparator).split(quote(sectionSeparator) + "\\n")
  lazy val Array(
    code, interface, info, turtleShapes, version,
    previewCommands, systemDynamics, behaviorSpace,
    hubNetClient, linkShapes, modelSettings, deltaTick) = sections
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
}
