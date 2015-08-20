package org.nlogo.models

import org.scalatest.FunSuite

trait TestModels extends FunSuite {

  def testLibraryModels(testName: String)(testFun: Iterable[Model] => Iterable[String]): Unit =
    testModels(Model.libraryModels, testName, testFun)

  def testAllModels(testName: String)(testFun: Iterable[Model] => Iterable[String]): Unit =
    testModels(Model.allModels, testName, testFun)

  def testModels(models: Iterable[Model], testName: String, testFun: Iterable[Model] => Iterable[String]): Unit =
    test(testName) {
      val failures = testFun(models)
      if (failures.nonEmpty) fail(failures.mkString("", "\n", "\n  -- "))
    }

  def testLines(section: Model => String, p: String => Boolean,
    msg: String => String = _ => "")(models: Iterable[Model]): Iterable[String] = {

    def linesWhere(str: String, p: String => Boolean, msg: String => String): Iterator[String] =
      for {
        (line, lineNumber) <- str.lines.zipWithIndex
        if p(line)
      } yield "  " + msg(line) + "line %4d |".format(lineNumber) + line

    for {
      model <- models
      errors = linesWhere(section(model), p, msg)
      if errors.nonEmpty
    } yield model.quotedPath + "\n" + errors.mkString("\n")

  }
}
