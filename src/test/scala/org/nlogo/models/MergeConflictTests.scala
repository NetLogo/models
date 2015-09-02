package org.nlogo.models

class MergeConflictTests extends TestModels {
  testAllModels("No merge conflicts appear in model files") {
    testLines(_.content, _.contains("<<<<<<< HEAD"))
  }
}
