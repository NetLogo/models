package org.nlogo.models

import java.io.File

import org.apache.commons.io.FileUtils.readFileToString

class PreviewImagesTests extends TestModels {

  def needsPreviewFile(m: Model) = m.is3d || m.needsManualPreview

  testLibraryModels("Models should have committed preview iif they're 3d or require manual preview") { model =>
    for {
      m <- Option(model)
      if m.previewFile.isFile != needsPreviewFile(m)
    } yield {
      "\"" + m.previewFile.getPath + "\"" +
        " should " + (if (needsPreviewFile(m)) "" else "not") +
        " be committed"
    }
  }

  testLibraryModels("Non-manual preview images should be in `.gitignore`") { model =>
    val ignored = readFileToString(new File(".gitignore"), "UTF-8").lines.toSet
    for {
      m <- Option(model)
      if !needsPreviewFile(m)
      imagePath = m.previewFile.getPath.drop(1)
      if !ignored.contains(imagePath)
    } yield imagePath + " should be added to .gitignore"
  }

}
