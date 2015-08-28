package org.nlogo.models

class CodeTests extends TestModels {

  testAllModels("Deprecated primitives are not used") { models =>

    type Exemption = String // the base name of an exempted model

    val forbiddenPrimitives: Seq[(String, Seq[Exemption])] = Seq(
      "__set-line-thickness" -> Seq("Optical Illusions", "Halo Example"),
      "__clear-all-and-reset-ticks" -> Seq.empty,
      "__approximate-hsb-old" -> Seq.empty,
      "face-nowrap" -> Seq.empty,
      "facexy-nowrap" -> Seq.empty,
      "distance-nowrap" -> Seq.empty,
      "distancexy-nowrap" -> Seq.empty,
      "in-cone-nowrap" -> Seq.empty,
      "in-radius-nowrap" -> Seq.empty,
      "towards-nowrap" -> Seq.empty,
      "towardsxy-nowrap" -> Seq.empty
    )

    for {
      (prim, exceptions) <- forbiddenPrimitives
      model <- models
      if !exceptions.contains(model.baseName)
      if model.primitiveTokenNames.contains(prim)
    } yield model.quotedPath + "\n  uses " + prim
  }

  /* Currently commented out because it generates far too much noise
   * in the test reports. Will enable officially once the test passes.
   * NP 2015-08-20
   */
//  testLibraryModels("Lines should not be longer than 85 characters") {
//    // 85 is the limit in the IABM textbook, so let's aim for that everywhere
//    testLines(_.code, _.length > 85, l => "%4d for ".format(l.length))
//  }

}
