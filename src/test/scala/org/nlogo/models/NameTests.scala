package org.nlogo.models

import org.scalatest.FunSuite

class NameTests extends FunSuite {

  test("There should be no duplicate model names") {
    val duplicates = libraryModels.groupBy(_.name).filter(_._2.size > 1)
    if (duplicates.nonEmpty) fail(
      duplicates.map {
        case (name, models) => name + "\n" + models.map("  " + _.quotedPath).mkString("\n")
      }.mkString("\n")
    )
  }
}
