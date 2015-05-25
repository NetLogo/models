package org.nlogo.models

import org.scalatest.FunSuite

import Model.models

class FindNonIntegerPatchSizesTests extends TestModels {
  testModels("Models should have integer patch sizes") {
    for {
      model <- _
      if model.patchSize.toInt != model.patchSize
    } yield s"${model.patchSize} in ${model.quotedPath}"
  }
}
