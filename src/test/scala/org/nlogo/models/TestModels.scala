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

}
