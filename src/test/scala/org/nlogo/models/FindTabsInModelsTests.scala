package org.nlogo.models

class FindTabsInModelsTests extends TestModels {
  testModels("Models should not use tab characters anywhere") {
    for {
      model <- _
      (line, lineNumber) <- model.content.lines.zipWithIndex
      if line contains "\t"
    } yield s"line $lineNumber in ${model.quotedPath}"
  }
}
