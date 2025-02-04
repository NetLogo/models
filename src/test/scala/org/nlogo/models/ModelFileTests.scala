package org.nlogo.models

class ModelFileTests extends TestModels {

  testModels("Models should not use tab characters anywhere") {
    testLines(_.content, _ contains "\t", _ => "")
  }

  testModels("Models should not contain trailing whitespace") {
    testLines(_.content, line => line != line.replaceAll("\\s+$", ""), _ => "")
  }

}
