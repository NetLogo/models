package org.nlogo.models

import org.scalatest.FunSuite

trait TestModels extends FunSuite {
  def testModels(testName: String)(testFun: Iterable[Model] => Iterable[String]): Unit =
    test(testName) {
      val failures = testFun(Model.models)
      if (failures.nonEmpty) fail(failures.mkString("", "\n", "\n  -- "))
    }
}
