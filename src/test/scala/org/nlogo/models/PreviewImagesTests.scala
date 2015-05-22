package org.nlogo.models

import java.io.File

import org.apache.commons.io.FileUtils.readFileToString
import org.apache.commons.io.FilenameUtils.removeExtension
import org.scalactic.Snapshots
import org.scalatest.BeforeAndAfterAll
import org.scalatest.FunSuite

import Model.models

class PreviewImagesTests extends FunSuite with Snapshots with BeforeAndAfterAll {
  val ignored = readFileToString(new File(".gitignore"), "UTF-8").lines.toSet
  val toRemove = Seq.newBuilder[String]
  val toIgnore = Seq.newBuilder[String]
  for (model <- models) {
    val previewFile = new File(removeExtension(model.file.getPath) + ".png")
    val previewFileExists = previewFile.isFile
    val isInGitIgnore = ignored contains previewFile.getPath.drop(1)
    test(previewFile.getPath) {
      val clue = ", " + snap(model.previewCommands)
      if (model.needsManualPreview) {
        assert(previewFileExists, clue)
        assert(!isInGitIgnore, clue)
      } else {
        if (previewFileExists) toRemove += "rm " + "\"" + previewFile.getPath + "\""
        if (!isInGitIgnore) toIgnore += previewFile.getPath.drop(1)
        assert(!previewFileExists, clue)
        assert(isInGitIgnore, clue)
      }
    }
  }

  override def afterAll(): Unit = {
    val _toRemove = toRemove.result()
    if (_toRemove.nonEmpty)
      alert("Remove these files:\n" + _toRemove.mkString("\n"))
    val _toIgnore = toIgnore.result()
    if (_toIgnore.nonEmpty)
      alert("Add these files to .gitignore:\n" + _toIgnore.mkString("\n"))
  }
}
