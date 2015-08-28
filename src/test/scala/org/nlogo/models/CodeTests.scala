package org.nlogo.models

class CodeTests extends TestModels {

  testAllModels("Forbidden primitives are not used") { models =>

    type Exemption = String // the base name of an exempted model

    val forbiddenPrimitives: Seq[(String, Seq[Exemption])] = Seq(
      "__approximate-hsb-old" -> Seq.empty,
      "__bench gui" -> Seq.empty,
      "__change-language" -> Seq.empty,
      "__change-topology" -> Seq.empty,
      "__clear-all-and-reset-ticks" -> Seq.empty,
      "__delete-log-files" -> Seq.empty,
      "__done" -> Seq.empty,
      "__edit" -> Seq.empty,
      "__english" -> Seq.empty,
      "__experimentstepend" -> Seq.empty,
      "__export-drawing" -> Seq.empty,
      "__fire" -> Seq.empty,
      "__foreverbuttonend" -> Seq.empty,
      "__git" -> Seq.empty,
      "__hubnet-broadcast-user-message" -> Seq("Memory HubNet"),
      "__hubnet-clear-plot" -> Seq("Oil Cartel HubNet"),
      "__hubnet-create-client" -> Seq.empty,
      "__hubnet-make-plot-narrowcast" -> Seq("Oil Cartel HubNet"),
      "__hubnet-plot" -> Seq("Oil Cartel HubNet"),
      "__hubnet-plot-pen-down" -> Seq.empty,
      "__hubnet-plot-pen-up" -> Seq.empty,
      "__hubnet-plot-point" -> Seq.empty,
      "__hubnet-plotxy" -> Seq.empty,
      "__hubnet-robo-client" -> Seq.empty,
      "__hubnet-send-from-local-client" -> Seq.empty,
      "__hubnet-send-user-message" -> Seq.empty,
      "__hubnet-set-histogram-num-bars" -> Seq.empty,
      "__hubnet-set-plot-mirroring" -> Seq.empty,
      "__hubnet-set-plot-pen-interval" -> Seq.empty,
      "__hubnet-set-plot-pen-mode" -> Seq.empty,
      "__hubnet-set-view-mirroring" -> Seq.empty,
      "__hubnet-wait-for-clients" -> Seq.empty,
      "__hubnet-wait-for-messages" -> Seq.empty,
      "__ignore" -> Seq("List Benchmark", "One-Of Turtles Benchmark"),
      "__inspect-with-radius" -> Seq.empty,
      "__let" -> Seq.empty,
      "__life" -> Seq.empty,
      "__linkcode" -> Seq.empty,
      "__magic-open" -> Seq.empty,
      "__make-preview" -> Seq.empty,
      "__mkdir" -> Seq.empty,
      "__observercode" -> Seq.empty,
      "__patchcode" -> Seq.empty,
      "__plot-pen-hide" -> Seq("Gridlock HubNet"),
      "__plot-pen-show" -> Seq("Gridlock HubNet"),
      "__pwd" -> Seq.empty,
      "__reload" -> Seq.empty,
      "__reload-extensions" -> Seq.empty,
      "__set-error-locale" -> Seq.empty,
      "__set-line-thickness" -> Seq("Optical Illusions", "Halo Example"),
      "__spanish" -> Seq.empty,
      "__stderr" -> Seq.empty,
      "__stdout" -> Seq.empty,
      "__thunk-did-finish" -> Seq.empty,
      "__turtlecode" -> Seq.empty,
      "__updatemonitor" -> Seq.empty,
      "__zip-log-files" -> Seq.empty,
      "bf" -> Seq.empty,
      "bl" -> Seq.empty,
      "ca" -> Seq.empty,
      "cd" -> Seq.empty,
      "cp" -> Seq.empty,
      "cro" -> Seq.empty,
      "crt" -> Seq.empty,
      "ct" -> Seq.empty,
      "distance-nowrap" -> Seq.empty,
      "distancexy-nowrap" -> Seq.empty,
      "face-nowrap" -> Seq.empty,
      "facexy-nowrap" -> Seq.empty,
      "ht" -> Seq.empty,
      "in-cone-nowrap" -> Seq.empty,
      "in-radius-nowrap" -> Seq.empty,
      "pd" -> Seq.empty,
      "ppd" -> Seq.empty,
      "ppu" -> Seq.empty,
      "pu" -> Seq.empty,
      "se" -> Seq.empty,
      "st" -> Seq.empty,
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
