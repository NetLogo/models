package org.nlogo.models

class CodeTests extends TestModels {

  testAllModels("Deprecated primitives are not used") { models =>

    type Exemption = String // the base name of an exempted model

    val forbiddenPrimitives: Seq[(String, Seq[Exemption])] = Seq(
      "__set-line-thickness" -> Seq("Optical Illusions", "Halo Example"),
      "__clear-all-and-reset-ticks" -> Seq.empty,
      "__approximate-hsb-old" -> Seq.empty
    )

    for {
      (prim, exceptions) <- forbiddenPrimitives
      model <- models
      if !exceptions.contains(model.baseName)
      if model.content.contains(prim)
    } yield model.quotedPath + "\n  uses " + prim
  }

}
