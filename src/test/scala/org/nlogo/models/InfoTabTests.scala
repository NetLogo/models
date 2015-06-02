package org.nlogo.models

class InfoTabsTests extends TestModels {

  val whatIsIt = Info.WhatIsIt.name

  testModels("All models' info tabs should have WHAT IS IT? section") { models =>
    for {
      model <- models
      if !model.info.sectionMap.keySet.contains(whatIsIt)
    } yield s"${model.quotedPath} doesn't have WHAT IS IT? section"
  }

  testModels("Most info tabs should start with WHAT IS IT? section") { models =>
    for {
      model <- models
      if model.info.sections.head._1 != whatIsIt
      if !Set("Alternative Visualizations", "IABM Textbook")
        .exists(model.file.getPath.contains)
    } yield s"${model.quotedPath} starts with:\n" +
      model.info.content.lines.dropWhile(_.isEmpty).take(1).mkString
  }

  testModels("Length of first paragraph of WHAT IS IT should be > 42 and <= 540") { models =>
    for {
      model <- models
      paragraph <- model.info.sectionMap.get(whatIsIt).map(_.lines.next)
      length = paragraph.length
      if length < 42 || length > 540
    } yield s"Length is $length in ${model.quotedPath}"
  }

  testModels("Info tabs should not have empty sections") { models =>
    for {
      model <- models
      emptySections = model.info.sections.filter(_._2.isEmpty).map(_._1)
      if emptySections.nonEmpty
    } yield model.quotedPath + "\n" + emptySections.map("  " + _).mkString("\n")
  }

  testModels("Info tabs should not have repeated sections") { models =>
    for {
      model <- models
      sectionTitles = model.info.sections.map(_._1).toSeq
      duplicateSections = sectionTitles diff sectionTitles.distinct
      if duplicateSections.nonEmpty
    } yield model.quotedPath + "\n" + duplicateSections.map("  " + _).mkString("\n")
  }

}
