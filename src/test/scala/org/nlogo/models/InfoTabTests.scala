package org.nlogo.models

class InfoTabsTests extends TestModels {

  val whatIsIt = Info.WhatIsIt.name

  testLibraryModels("All models' info tabs should have WHAT IS IT? section") { models =>
    for {
      model <- models
      if !model.info.sectionMap.keySet.contains(whatIsIt)
    } yield s"${model.quotedPath} doesn't have WHAT IS IT? section"
  }

  testLibraryModels("Most info tabs should start with WHAT IS IT? section") { models =>
    for {
      model <- models
      if model.info.sections.head._1 != whatIsIt
      if !Set("Alternative Visualizations", "IABM Textbook")
        .exists(model.file.getPath.contains)
    } yield s"${model.quotedPath} starts with:\n" +
      model.info.content.lines.dropWhile(_.isEmpty).take(1).mkString
  }

  val minLen = 40
  val maxLen = 700
  testLibraryModels(s"Length of first paragraph of WHAT IS IT should be >= $minLen and <= $maxLen") { models =>
    for {
      model <- models
      paragraph <- model.info.sectionMap.get(whatIsIt).map(_.lines.next)
      length = paragraph.length
      if length <= minLen || length > maxLen
    } yield s"Length is $length in ${model.quotedPath}"
  }

  testLibraryModels("First paragraph of WHAT IS IT should be unique") { models =>
    for {
      (optWhatItIs, groupedModels) <- models.groupBy(_.info.sectionMap.get(whatIsIt).map(_.lines.next))
      whatItIs <- optWhatItIs
      if groupedModels.size > 1
    } yield whatItIs + "\n  " + groupedModels.map(_.quotedPath).mkString("\n  ")
  }

  testLibraryModels("Info tabs should not have empty sections") { models =>
    for {
      model <- models
      emptySections = model.info.sections.filter(_._2.isEmpty).map(_._1)
      if emptySections.nonEmpty
    } yield model.quotedPath + "\n" + emptySections.map("  " + _).mkString("\n")
  }

  testLibraryModels("Info tabs should not have repeated sections") { models =>
    for {
      model <- models
      sectionTitles = model.info.sections.map(_._1).toSeq
      duplicateSections = sectionTitles diff sectionTitles.distinct
      if duplicateSections.nonEmpty
    } yield model.quotedPath + "\n" + duplicateSections.map("  " + _).mkString("\n")
  }

  testLibraryModels("Bullet list using dashes should have space after dash") {
    val pattern = """^-\w.+""".r.pattern
    testLines(_.info.content, pattern.matcher(_).matches)
  }

}
