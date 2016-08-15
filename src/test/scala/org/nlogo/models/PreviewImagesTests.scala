package org.nlogo.models

import java.io.File

import org.apache.commons.io.FileUtils.readFileToString
import org.apache.commons.io.FilenameUtils.removeExtension
import org.nlogo.api.PreviewCommands.Manual
import org.nlogo.core.Model

class PreviewImagesTests extends TestModels {

  /*
   * A note about the 3D models: all 3D models should have a manual preview committed in
   * the repository, but some of them still have "custom preview commands" saved in the
   * model file: those are not used for generating the model previews but they *are* used
   * for generating the model checksums and should *not* be removed from the model files.
   * NP 2016-05-19
   */
  def needsPreviewFile(m: Model) = m.is3D || m.previewCommands == Manual

  val ignoredLines = readFileToString(new File(".gitignore"), "UTF-8").lines.toSeq
  val ignored = ignoredLines.toSet
  def isInGitIgnore(m: Model) = ignored.contains(m.previewFile.getPath.drop(1))

  val manualPreviewNeeded = Set(
    "HubNet", "/sound/", "GoGo", "Arduino"
  )
  val manualPreviewPermitted = Set(
    "Table Example",
    "Info Tab Example",
    "Profiler Example",
    "Mouse Example",
    "Plotting Example",
    "Termites (Perspective Demo)",
    "Flocking (Perspective Demo)",
    "Ants (Perspective Demo)",
    "3D Shapes Example",
    "File Input Example",
    "User Interaction Example",
    "Matrix Example",
    "Mouse Recording Example",
    "Plot Smoothing Example",
    "Case Conversion Example",
    "Perspective Example",
    "Rolling Plot Example",
    "Plot Axis Example",
    "Electrostatics",
    "Series Circuit", // because https://github.com/NetLogo/models/issues/48
    "Current in a Wire", // idem
    "Parallel Circuit", // idem
    "Electron Sink", // idem
    "Simple Genetic Algorithm",
    "Exponential Growth",
    "Tabonuco Yagrumo",
    "Wolf Sheep Predation (System Dynamics)",
    "Logistic Growth",
    "Prob Graphs Basic",
    "Equidistant Probability",
    "Partition Perms Distrib",
    "Video Camera Example",
    "Movie Playing Example",
    "Model Loader Example",
    "Model Visualizer and Plotte Exampler",
    "Model Interactions Example"
  )
  testModels("Models should have manual previews only if needed or permitted") { m =>
    if (manualPreviewNeeded.exists(m.file.getPath.contains))
      if (m.previewCommands != Manual)
        Some("should need manual preview")
      else
        None
    else if (m.previewCommands == Manual && !manualPreviewPermitted.contains(m.name))
      Some("should NOT need manual preview")
    else
      None
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
    val modelNames = libraryModels.map(_.name).toSet
    val unneededEntries =
      ignoredLines.filter(_.endsWith(".png"))
        .filterNot(path => modelNames.contains(removeExtension(new File(path).getName)))
    if (unneededEntries.nonEmpty) fail(unneededEntries.mkString("\n"))
  }

}
