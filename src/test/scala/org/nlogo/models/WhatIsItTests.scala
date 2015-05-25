package org.nlogo.models

class WhatIsItTests extends TestModels {

  val whatIsIt = "## WHAT IS IT?"

  testModels("All models' info tabs should have WHAT IS IT section") {
    for {
      model <- _
      if !model.info.contains(whatIsIt + "\n\n")
    } yield s"${model.quotedPath} doesn't have WHAT IS IT section"
  }

  testModels("Most info tabs should start with WHAT IS IT section") {
    for {
      model <- _
      if !model.info.startsWith(whatIsIt + "\n\n")
      if !Set("Alternative Visualizations", "IABM Textbook")
        .exists(model.file.getPath.contains)
    } yield s"${model.quotedPath} starts with:\n" +
      model.info.lines.dropWhile(_.isEmpty).take(1).mkString
  }

  testModels("Length of first paragraph of WHAT IS IT should be > 42 and <= 540") {
    for {
      model <- _
      paragraph <- model.info.lines.dropWhile(_ != whatIsIt).drop(2).take(1)
      length = paragraph.length
      if length < 42 || length > 540
    } yield s"Length is $length in ${model.quotedPath}"
  }

}
