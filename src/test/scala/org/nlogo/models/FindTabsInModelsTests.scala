package org.nlogo.models

import org.scalatest.FunSuite

import Model.models

class FindTabsInModelsTests extends FunSuite {
  for (model <- models) test(model.file.getPath) {
    val linesWithTabs =
      model.content.lines
        .zipWithIndex
        .filter(_._1.contains("\t"))
        .map(_._2)
    if (linesWithTabs.nonEmpty) fail(
      "Found tab character(s) at line(s): " +
        linesWithTabs.mkString(", ") + "\n" +
        model.quotedPath
    )
  }
}
