package org.nlogo.models

import scala.collection.JavaConverters.asScalaBufferConverter
import scala.collection.JavaConverters.asScalaSetConverter
import scala.collection.JavaConverters.mapAsScalaMapConverter
import scala.util.Failure
import scala.util.Success
import scala.util.Try

import org.nlogo.headless.HeadlessWorkspace

class ModelCompilationTests extends TestModels {

  // 3D models and models using extensions are excluded because our
  // current setup makes it non-trivial to headlessly compile them
  def excluded(model: Model) =
    model.is3d || model.code.lines.exists(_.startsWith("extensions"))

  def compilationTests(model: Model)(ws: HeadlessWorkspace): Iterable[String] =
    breedNamesUsedAsArgsOrVars(ws) ++
      breedsWithNoSingularName(ws) ++
      uncompilableExperiments(ws) ++
      (if (model.isTestModel) Nil else {
        uncompilablePreviewCommands(ws) ++
          proceduresUsingResetTicksMoreThanOnce(ws)
      })

  testAllModels("Compilation output should satisfy various properties") { model =>
    if (excluded(model)) Seq.empty else {
      Try(withWorkspace(model)(compilationTests(model))) match {
        case Failure(error) => Seq(error.toString)
        case Success(errors) => errors
      }
    }
  }

  def breedNamesUsedAsArgsOrVars(ws: HeadlessWorkspace): Iterable[String] = {
    val singularBreedNames =
      ws.world.program.breedsSingular.keySet.asScala ++
        ws.world.program.linkBreedsSingular.keySet.asScala
    for {
      (procedureName, p) <- ws.getProcedures.asScala.toSeq
      localName <- (p.args.asScala ++ p.lets.asScala.map(_.varName))
      if singularBreedNames contains localName
    } yield s"Singular breed name $localName if used as variable or argument name in $procedureName"
  }

  def breedsWithNoSingularName(ws: HeadlessWorkspace): Iterable[String] = {
    def find(
      breeds: java.util.Map[String, AnyRef],
      breedsSingular: java.util.Map[String, String]) =
      breeds.asScala.keys.filterNot(breedsSingular.asScala.values.toSet.contains)
    val p = ws.world.program
    find(p.breeds, p.breedsSingular) ++ find(p.linkBreeds, p.linkBreedsSingular)
  }

  def uncompilablePreviewCommands(ws: HeadlessWorkspace): Iterable[String] = {
    def compile(source: String) =
      ws.compiler.compileMoreCode(source, None, ws.world.program,
        ws.getProcedures, ws.getExtensionManager)
    for {
      commands <- Seq(ws.previewCommands)
      source = s"to __custom-preview-commands\n${commands}\nend"
      if !source.contains("need-to-manually-make-preview-for-this-model")
      error <- Try(compile(source)).failed.toOption
    } yield s"Preview commands do not compile:\n$error\n$source"
  }

  def uncompilableExperiments(ws: HeadlessWorkspace): Iterable[String] = {
    val lab = HeadlessWorkspace.newLab
    for {
      experiment <- lab.names
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
      (procedureName, procedure) <- ws.getProcedures.asScala
      commandNames = procedure.code.flatMap(cmd => Option(cmd.token).map(_.name))
      if commandNames.count(_ == "reset-ticks") > 1
    } yield s"Procedure $procedureName uses `reset-ticks` more than once"
  }
}
