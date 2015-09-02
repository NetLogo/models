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

  testAllModels("Models should compile") { model =>
    for {
      m <- Option(model)
      if !excluded(m)
      error <- Try(withWorkspace(m)(_ => ())).failed.toOption
    } yield error.toString
  }

  testAllModels("Singular breed names should not be used as args/local names") {
    def findDuplicateNames(model: Model): Seq[String] =
      withWorkspace(model) { ws =>
        val singularBreedNames =
          ws.world.program.breedsSingular.keySet.asScala ++
            ws.world.program.linkBreedsSingular.keySet.asScala
        for {
          (procedureName, p) <- ws.getProcedures.asScala.toSeq
          localName <- (p.args.asScala ++ p.lets.asScala.map(_.varName))
          if singularBreedNames contains localName
        } yield s"$localName in $procedureName"
      }
    Seq(_).filterNot(excluded).flatMap(findDuplicateNames)
  }

  testAllModels("All breeds should have singular names") {
    def breedsWithNoSingular(model: Model) = withWorkspace(model) { ws =>
      def find(
        breeds: java.util.Map[String, AnyRef],
        breedsSingular: java.util.Map[String, String]) =
        breeds.asScala.keys.filterNot(breedsSingular.asScala.values.toSet.contains)
      val p = ws.world.program
      find(p.breeds, p.breedsSingular) ++ find(p.linkBreeds, p.linkBreedsSingular)
    }
    Seq(_).filterNot(excluded).flatMap(breedsWithNoSingular)
  }

  testLibraryModels("Preview commands should compile (except for test models)") {
    def compilePreviewCommands(model: Model): Unit = withWorkspace(model) { ws =>
      if (!(ws.previewCommands contains "need-to-manually-make-preview-for-this-model")) {
        val source = s"to __custom-preview-commands\n${ws.previewCommands}\nend"
        ws.compiler.compileMoreCode(source, None, ws.world.program, ws.getProcedures, ws.getExtensionManager)
      }
    }
    Seq(_).filterNot(excluded).flatMap { m =>
      Try(compilePreviewCommands(m)).failed.toOption
    }
  }

  testAllModels("All BehaviorSpace experiments should compile") {
    def compileExperiments(model: Model): Unit = withWorkspace(model) { ws =>
      val lab = HeadlessWorkspace.newLab
      lab.names.foreach(lab.newWorker(_).compile(ws))
    }
    Seq(_).filterNot(excluded).flatMap { m =>
      Try(compileExperiments(m)).failed.toOption
    }
  }

  testLibraryModels("Procedures should not use `reset-ticks` more than once") {
    Seq(_)
      .filterNot { m => m.is3d || m.code.contains("extensions") }
      .flatMap {
        withWorkspace(_) { ws =>
          // It would be better to use StructureParser output
          // directly (instead of final compilation output)
          // but it is not currently accessible in the 5.3
          // branch (and it doesn't seem worth it to mess around
          // with reflection just for this) -- NP 2015-09-01
          for {
            (procedureName, procedure) <- ws.getProcedures.asScala
            commandNames = procedure.code.flatMap(cmd => Option(cmd.token).map(_.name))
            if commandNames.count(_ == "reset-ticks") > 1
          } yield procedureName
        }
      }
  }

}
