package org.nlogo.models

import java.io.File

import org.apache.commons.io.FileUtils.readFileToString

class PreviewImagesTests extends TestModels {

  testLibraryModels("3D models should have committed images, regardless of what the preview commands say") {
    for {
      model <- _
      if model.is3d && !model.previewFile.isFile
    } yield "\"" + model.previewFile.getPath + "\" should be committed"
  }

  testLibraryModels("Models requiring manual previews should have committed images") {
    for {
      model <- _
      if !model.is3d && model.needsManualPreview && !model.previewFile.isFile
    } yield "\"" + model.previewFile.getPath + "\" should be committed"
  }

  testLibraryModels("Only models requiring manual previews should have committed images") {
    for {
      model <- _
      if !model.is3d && !model.needsManualPreview && model.previewFile.isFile
    } yield "\"" + model.previewFile.getPath + "\" should not be committed"
  }

  testLibraryModels("Non-manual preview images should be in `.gitignore`") {
    val ignored = readFileToString(new File(".gitignore"), "UTF-8").lines.toSet
    for {
      model <- _
      if !model.is3d && !model.needsManualPreview
      imagePath = model.previewFile.getPath.drop(1)
      if !ignored.contains(imagePath)
    } yield imagePath + " should be added to .gitignore"
  }

}
