package org.nlogo.models

import org.nlogo.api.Version
import org.nlogo.core.Model

import org.scalatest.{ Args, FunSuite, Status, SucceededStatus }

import scala.collection.{ GenIterable, GenMap, GenSeq }
import scala.util.Try

abstract class TestModels extends FunSuite {

  private var nameFilter: Option[String] = None

  override def runTest(name: String, args: Args): Status = {
    nameFilter = args.configMap.get("model").map(_.toString.toLowerCase)

    super.runTest(name, args)
  }

  def testModels(
    testName: String,
    includeTestModels: Boolean = false,
    includeOtherDimension: Boolean = false,
    filter: Model => Boolean = _ => true)(testFun: Model => GenIterable[Any]): Unit = {
    val models =
      (if (includeTestModels) allModelsNamed else libraryModelsNamed)
        .filterKeys(includeOtherDimension || _.is3D == Version.is3D)
        .filterKeys(filter)
    testModels(models, testName)(testFun)
  }

  def testModels(models: GenMap[Model, String], testName: String)(testFun: Model => GenIterable[Any]): Unit =
    test(testName) {
      val allFailures: GenSeq[String] =
        (for {
          model <- models.filterKeys(model => nameFilter.map(models(model).toLowerCase.contains).getOrElse(true)).keys
          failures <- Try(testFun(model))
            .recover { case e => Seq(e.toString + "\n" + e.getStackTrace.mkString("\n")) }
            .toOption
          if failures.nonEmpty
          descriptions = failures.map(_.toString).filterNot(_.isEmpty).map("  " + _)
        } yield (model.quotedPath +: descriptions.toSeq).mkString("\n"))(collection.breakOut)

      if (allFailures.nonEmpty)
        fail(allFailures.toArray.sorted.mkString("", "\n", s"\n(${allFailures.size} failing models)"))
    }

  def testLines(
    section: Model => String, p: String => Boolean,
    msg: String => String = _ => "")(model: Model): Iterable[String] = {
    (for {
      (line, lineNumber) <- section(model).linesIterator.zipWithIndex
      if p(line)
    } yield "  " + msg(line) + "line %4d |".format(lineNumber) + line).toIterable
  }

}
