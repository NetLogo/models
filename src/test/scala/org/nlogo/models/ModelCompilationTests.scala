package org.nlogo.models

import scala.collection.JavaConverters.asScalaBufferConverter
import scala.collection.JavaConverters.asScalaSetConverter
import scala.collection.JavaConverters.mapAsScalaMapConverter
import scala.util.Try

import org.nlogo.headless.HeadlessWorkspace

class ModelCompilationTests extends TestModels {

  // 3D models and models using extensions are excluded because our
  // current setup makes it non-trivial to headlessly compile them
  def excluded(model: Model) =
    model.is3d || model.code.lines.exists(_.startsWith("extensions"))

  def withWorkspace[A](model: Model)(f: HeadlessWorkspace => A) = {
    val workspace = HeadlessWorkspace.newInstance
    try {
      workspace.compilerTestingMode = true
      workspace.silent = true
      // open the model from path instead of content string so that
      // the current directory gets set (necessary for `__includes`)
      workspace.open(model.file.getCanonicalPath)
      f(workspace)
    } finally workspace.dispose()
  }

  testAllModels("Models should compile") { models =>
    for {
      model <- models
      if !excluded(model)
      error <- Try(withWorkspace(model)(_ => ())).failed.toOption
    } yield s"${model.quotedPath}: " + error
  }

  testAllModels("Singular breed names should not be used as args/local names") { models =>
    def findDuplicateNames(model: Model) = withWorkspace(model) { ws =>
      val singularBreedNames =
        ws.world.program.breedsSingular.keySet.asScala ++
          ws.world.program.linkBreedsSingular.keySet.asScala
      for {
        (procedureName, p) <- ws.getProcedures.asScala.toSeq
        localName <- (p.args.asScala ++ p.lets.asScala.map(_.varName))
        if singularBreedNames contains localName
      } yield (localName, procedureName)
    }
    for {
      model <- models
      if !excluded(model)
      duplicateNames = findDuplicateNames(model)
      if duplicateNames.nonEmpty
    } yield s"${model.quotedPath}:\n" + duplicateNames.map {
      case (n, p) => s"  $n in $p"
    }.mkString("\n")
  }

  testAllModels("All breeds should have singular names") { models =>
    def breedsWithNoSingular(model: Model) = withWorkspace(model) { ws =>
      def find(
        breeds: java.util.Map[String, AnyRef],
        breedsSingular: java.util.Map[String, String]) =
        breeds.asScala.keys.filterNot(breedsSingular.asScala.values.toSet.contains)
      val p = ws.world.program
      find(p.breeds, p.breedsSingular) ++ find(p.linkBreeds, p.linkBreedsSingular)
    }
    for {
      model <- models
      if !excluded(model)
      breeds = breedsWithNoSingular(model)
      if breeds.nonEmpty
    } yield s"${model.quotedPath}:" + breeds.mkString("  \n", "  \n", "")
  }

  testLibraryModels("Preview commands should compile (except for test models)") { models =>
    def compilePreviewCommands(model: Model): Unit = withWorkspace(model) { ws =>
      if (!(ws.previewCommands contains "need-to-manually-make-preview-for-this-model")) {
        val source = s"to __custom-preview-commands\n${ws.previewCommands}\nend"
        ws.compiler.compileMoreCode(source, None, ws.world.program, ws.getProcedures, ws.getExtensionManager)
      }
    }
    for {
      model <- models
      if !excluded(model)
      error <- Try(compilePreviewCommands(model)).failed.toOption
    } yield s"${model.quotedPath}: " + error
  }

  testAllModels("All BehaviorSpace experiments should compile") { models =>
    def compileExperiments(model: Model): Unit = withWorkspace(model) { ws =>
      val lab = HeadlessWorkspace.newLab
      lab.names.foreach(lab.newWorker(_).compile(ws))
    }
    for {
      model <- models
      if !excluded(model)
      error <- Try(compileExperiments(model)).failed.toOption
    } yield s"${model.quotedPath}: " + error
  }
}
