package org.nlogo.models

class MergeConflictTests extends TestModels {
  testModels("No merge conflicts appear in model files", includeTestModels = true) {
    testLines(_.content, _.contains("<<<<<<< HEAD"))
  }
}
