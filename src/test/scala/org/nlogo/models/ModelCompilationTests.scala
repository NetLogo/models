package org.nlogo.models

import scala.annotation.migration
import scala.jdk.CollectionConverters.MapHasAsScala
import scala.util.Failure
import scala.util.Success
import scala.util.Try

import org.nlogo.core.Breed
import org.nlogo.core.Model
import org.nlogo.headless.BehaviorSpaceCoordinator
import org.nlogo.headless.HeadlessWorkspace

class ModelCompilationTests extends TestModels {

  def compilationTests(model: Model)(ws: HeadlessWorkspace): Iterable[String] =
    breedsWithNoSingularName(ws) ++
      uncompilableExperiments(model, ws) ++
      (if (model.isTestModel) Nil else {
        uncompilablePreviewCommands(ws) ++
          proceduresUsingResetTicksMoreThanOnce(ws)
      })

  testModels("Compilation output should satisfy various properties", includeTestModels = true) { model =>
    if (model.isCompilable) {
      Try(withWorkspace(model)(compilationTests(model))) match {
        case Failure(error)  => Seq(error.toString)
        case Success(errors) => errors
      }
    } else Seq.empty
  }

  def breedsWithNoSingularName(ws: HeadlessWorkspace): Iterable[String] =
    for {
      breed <- ws.world.program.breeds.values ++ ws.world.program.linkBreeds.values
      if breed.singular == null
    } yield breed.name

  def uncompilablePreviewCommands(ws: HeadlessWorkspace): Iterable[String] = {
    def compile(source: String) =
      ws.compiler.compileMoreCode(source, None, ws.world.program,
        ws.procedures, ws.getExtensionManager, ws.getLibraryManager, ws.getCompilationEnvironment)
    for {
      commands <- Seq(ws.previewCommands)
      source = s"to __custom-preview-commands\n${commands.source}\nend"
      if !source.contains("need-to-manually-make-preview-for-this-model")
      error <- Try(compile(source)).failed.toOption
    } yield s"Preview commands do not compile:\n$error\n$source"
  }

  def uncompilableExperiments(model: Model, ws: HeadlessWorkspace): Iterable[String] = {
    val lab = HeadlessWorkspace.newLab
    for {
      experiment <- BehaviorSpaceCoordinator.protocolsFromModel(model.file.getPath, ws)
      error <- Try(lab.newWorker(experiment).compile(ws)).failed.toOption
    } yield s"BehaviorSpace experiment '$experiment' does not compile: $error"
  }

  def proceduresUsingResetTicksMoreThanOnce(ws: HeadlessWorkspace): Iterable[String] = {
    // It would be better to use StructureParser output
    // directly (instead of final compilation output)
    // but it is not currently accessible in the 5.3
    // branch (and it doesn't seem worth it to mess around
    // with reflection just for this) -- NP 2015-09-01
    for {
      (procedureName, procedure) <- ws.procedures
      commandNames = procedure.code.flatMap(cmd => Option(cmd.token).map(_.text))
      if commandNames.count(_ == "reset-ticks") > 1
    } yield s"Procedure $procedureName uses `reset-ticks` more than once"
  }
}
