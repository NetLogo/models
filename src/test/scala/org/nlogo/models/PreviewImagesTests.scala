package org.nlogo.models

import java.io.File

import org.apache.commons.io.FileUtils.readFileToString
import org.apache.commons.io.FilenameUtils.removeExtension

class PreviewImagesTests extends TestModels {

  def needsPreviewFile(m: Model) = m.is3D || m.needsManualPreview

  val ignoredLines = readFileToString(new File(".gitignore"), "UTF-8").lines.toSeq
  val ignored = ignoredLines.toSet
  def isInGitIgnore(m: Model) = ignored.contains(m.previewFile.getPath.drop(1))

  // Some models are automatically excluded from `all-previews`
  // (http://git.io/vGb9l), but for them to be checked by other
  // tests (and also to be consistent) we need them to be
  // explicitely tagged with "need-to-manually-make-preview-for-this-model"
  val modelsThatShouldNeedManualPreviews = Model.libraryModels.filter { m =>
    val path = m.file.getPath.toUpperCase
    Set("HUBNET", "/GOGO/", "/CODE EXAMPLES/SOUND/").exists(path.contains)
  }
  testModels(modelsThatShouldNeedManualPreviews,
    "Some library models should be tagged as needing manual previews") {
      Option(_).filterNot(needsPreviewFile)
        .map(_ => "should be tagged as needing manual preview")
    }

  testModels("Models should have committed preview iif they're 3d or require manual preview") { model =>
    for {
      m <- Option(model)
      if !isInGitIgnore(m)
      if m.previewFile.isFile != needsPreviewFile(m)
    } yield {
      "\"" + m.previewFile.getPath + "\"" +
        " should" + (if (needsPreviewFile(m)) " " else " not ") +
        "be committed"
    }
  }

  testModels("Images should be in `.gitignore` iif they don't need manual previews") { model =>
    for {
      m <- Option(model)
      needsPreview = needsPreviewFile(m)
      if isInGitIgnore(m) == needsPreview
    } yield m.previewFile.getPath.drop(1) +
      " should " + (if (needsPreview) "not" else "") +
      " be added to .gitignore"
  }

  test(".gitignore should not have duplicates") {
    val duplicates =
      ignoredLines.groupBy(identity)
        .collect { case (x, ys) if ys.size > 1 => x }
    if (duplicates.nonEmpty) fail(duplicates.mkString("\n"))
  }

  test(".gitignore should not contain preview entries for non-existing models") {
    val modelNames = Model.libraryModels.map(_.name).toSet
    val unneededEntries =
      ignoredLines.filter(_.endsWith(".png"))
        .filterNot(path => modelNames.contains(removeExtension(new File(path).getName)))
    if (unneededEntries.nonEmpty) fail(unneededEntries.mkString("\n"))
  }

}
