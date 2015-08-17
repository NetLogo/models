package org.nlogo.models

class ModelFileTests extends TestModels {

  testAllModels("Models should not use tab characters anywhere") {
    testLines(_.content, _ contains "\t", _ => "")
  }

  testAllModels("Models should not countain trailing whitespace") {
    testLines(_.content, line => line != line.replaceAll("\\s+$", ""), _ => "")
  }

}
