package org.nlogo.models

import scala.collection.GenIterable

import org.scalatest.FunSuite

trait TestModels extends FunSuite {

  def testLibraryModels(testName: String)(testFun: Model => GenIterable[Any]): Unit =
    testModels(Model.libraryModels, testName)(testFun)

  def testAllModels(testName: String)(testFun: Model => GenIterable[Any]): Unit =
    testModels(Model.allModels, testName)(testFun)

  def testModels(models: GenIterable[Model], testName: String)(testFun: Model => GenIterable[Any]): Unit =
    test(testName) {
      val allFailures: GenIterable[String] = models
        .map(model => (model, testFun(model)))
        .filter(_._2.nonEmpty)
        .map {
          case (model, failures) =>
            model.quotedPath + "\n" + failures.map("  " + _).mkString("\n")
        }
      if (allFailures.nonEmpty)
        fail(allFailures.mkString("\n") + "\n(" + allFailures.size + " failing models)")
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
