package org.nlogo.models

import org.scalatest.FunSuite

import Model.models

class FindNonIntegerPatchSizesTests extends FunSuite {
  for (model <- models) test(model.file.getPath) {
    if (model.patchSize.toInt != model.patchSize) fail(
      "Found non-integer patch size in\n" + model.quotedPath
    )
  }
}
