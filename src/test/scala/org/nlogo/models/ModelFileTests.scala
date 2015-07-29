package org.nlogo.models

class ModelFileTests extends TestModels {

  def linesWhere(p: String => Boolean)(model: Model): Iterator[String] =
    for {
      (line, lineNumber) <- model.content.lines.zipWithIndex
      if p(line)
    } yield s"  $lineNumber: $line"

  def testLines(p: String => Boolean)(models: Iterable[Model]): Iterable[String] =
    for {
      model <- models
      errors = linesWhere(p)(model)
      if errors.nonEmpty
    } yield model.quotedPath + "\n" + errors.mkString("\n")

  testAllModels("Models should not use tab characters anywhere") {
    testLines { line => line contains "\t" }
  }

  testAllModels("Models should not countain trailing whitespace") {
    testLines { line => line != line.replaceAll("\\s+$", "") }
  }

}
