package org.nlogo.models

class ModelFileTests extends TestModels {

  testModels("Models should not use tab characters anywhere", includeTestModels = true) {
    testLines(_.content, _ contains "\t", _ => "")
  }

  testModels("Models should not countain trailing whitespace", includeTestModels = true) {
    testLines(_.content, line => line != line.replaceAll("\\s+$", ""), _ => "")
  }

}
