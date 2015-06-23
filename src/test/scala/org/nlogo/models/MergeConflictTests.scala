package org.nlogo.models

class MergeConflictTests extends TestModels {
  testAllModels("No merge conflicts appear in model files") {
    _.filter(_.content.contains("<<<<<<< HEAD")).map(_.quotedPath)
  }
}
