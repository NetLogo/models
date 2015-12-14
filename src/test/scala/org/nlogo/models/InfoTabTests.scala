package org.nlogo.models

class InfoTabsTests extends TestModels {

  val whatIsIt = Info.WhatIsIt.name

  testModels("All models' info tabs should have WHAT IS IT? section") {
    Option(_)
      .filterNot(_.info.sectionMap.keySet.contains(whatIsIt))
      .map(_ => "doesn't have WHAT IS IT? section")
  }

  testModels("Most info tabs should start with WHAT IS IT? section") {
    Option(_)
      .filter(_.info.sections.head._1 != whatIsIt)
      .filterNot { m =>
        Set("Alternative Visualizations", "IABM Textbook")
          .exists(m.file.getPath.contains)
      }
      .map {
        "starts with " + _.info.content.lines.dropWhile(_.isEmpty).take(1).mkString
      }
  }

  val minLen = 40
  val maxLen = 700
  testModels(s"Length of first paragraph of WHAT IS IT should be >= $minLen and <= $maxLen") { model =>
    for {
      paragraph <- model.info.sectionMap.get(whatIsIt).map(_.lines.next)
      length = paragraph.length
      if length <= minLen || length > maxLen
    } yield s"Length is $length in ${model.quotedPath}"
  }

  test("First paragraph of WHAT IS IT should be unique") {
    val failures = for {
      (optWhatItIs, groupedModels) <- Model.libraryModels.groupBy(_.info.sectionMap.get(whatIsIt).map(_.lines.next))
      whatItIs <- optWhatItIs
      if groupedModels.size > 1
    } yield whatItIs + "\n  " + groupedModels.map(_.quotedPath).mkString("\n  ")
    if (failures.nonEmpty) fail(failures.mkString("\n"))
  }

  testModels("Info tabs should not have empty sections") {
    Seq(_).flatMap(_.info.sections.filter(_._2.isEmpty).map(_._1))
  }

  testModels("Info tabs should not have repeated sections") {
    Seq(_).flatMap { m =>
      val sectionTitles = m.info.sections.map(_._1).toSeq
      sectionTitles diff sectionTitles.distinct
    }
  }

  testModels("Bullet list using dashes should have space after dash") {
    val pattern = """^-\w.+""".r.pattern
    testLines(_.info.content, pattern.matcher(_).matches)
  }

}
