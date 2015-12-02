package org.nlogo.models

import scala.collection.GenIterable
import org.scalatest.FunSuite
import scala.collection.GenSeq

trait TestModels extends FunSuite {

  def testLibraryModels(testName: String)(testFun: Model => GenIterable[Any]): Unit =
    testModels(Model.libraryModels, testName)(testFun)

  def testAllModels(testName: String)(testFun: Model => GenIterable[Any]): Unit =
    testModels(Model.allModels, testName)(testFun)

  def testModels(models: GenIterable[Model], testName: String)(testFun: Model => GenIterable[Any]): Unit =
    test(testName) {
      val allFailures: GenSeq[String] = models
        .map(model => (model, testFun(model)))
        .filter(_._2.nonEmpty)
        .map {
          case (model, failures) =>
            val descriptions = failures.map(_.toString).filterNot(_.isEmpty).map("  " + _)
            (model.quotedPath +: descriptions.toSeq).mkString("\n")
        }(collection.breakOut)
      if (allFailures.nonEmpty)
        fail((allFailures :+ s"(${allFailures.size} failing models)").mkString("\n"))
    }

  def testLines(
    section: Model => String, p: String => Boolean,
    msg: String => String = _ => "")(model: Model): Iterable[String] = {
    (for {
      (line, lineNumber) <- section(model).lines.zipWithIndex
      if p(line)
    } yield "  " + msg(line) + "line %4d |".format(lineNumber) + line).toIterable
  }

}
