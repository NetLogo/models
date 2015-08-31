package org.nlogo.models

import org.nlogo.api.TokenType
import org.nlogo.api.TokenType.COMMAND
import org.nlogo.api.TokenType.IDENT
import org.nlogo.api.TokenType.KEYWORD
import org.nlogo.api.TokenType.REPORTER
import org.nlogo.api.TokenType.VARIABLE

class CodeTests extends TestModels {

  testLibraryModels("Forbidden primitives are not used") { models =>

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
      "__ignore" -> Seq.empty,
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
      model <- models
      tokenNames = model.primitiveTokenNames.toSet
      (prim, exceptions) <- forbiddenPrimitives
      if !exceptions.contains(model.baseName)
      if tokenNames.contains(prim)
    } yield model.quotedPath + "\n  uses " + prim
  }

  testLibraryModels("All identifiers should be lowercase") { models =>
    val typesToCheck = Set[TokenType](
      IDENT, COMMAND, REPORTER, KEYWORD, VARIABLE
    )

    // Some of these exceptions are debatable and should
    // be revisited at some point -- NP 2015-08-30
    val exceptions = Map[String, Set[String]](
      "CA Stochastic" -> Set(
        "OIO", "IOI", "OII", "III", "OOI", "IOO", "IIO", "OOO"
      ),
      "Fish Tank Genetic Drift" -> Set(
        "#-big-B-alleles", "#-big-T-alleles", "#-big-F-alleles", "#-big-G-alleles"
      ),
      "DNA Protein Synthesis" -> Set(
        "mRNAs-released", "move-mRNA-molecules-out-of-nucleus", "mRNA-nucleotide",
        "tRNAs", "build-tRNA-for-this-triplet", "tRNA", "tRNA-nucleotides", "mRNAs",
        "tRNAs-own", "this-tRNA", "build-mRNA-for-each-gene", "mRNA-nucleotides-own",
        "mRNA", "mRNAs-traveling", "complementary-mRNA-base", "tRNA-nucleotides-own",
        "tRNA-nucleotide", "mRNA-nucleotides", "mRNAs-own",
        "release-next-mRNA-from-nucleus", "random-base-letter-DNA", "this-mRNA"
      ),
      "Bird Breeders HubNet" -> Set(
        "check-for-DNA-test", "setup-DNA-sequencers", "DNA-sequencers",
        "DNA-sequencers-here", "max-#-of-DNA-tests", "DNA-sequencer"
      ),
      "Connected Chemistry Solid Combustion" -> Set(
        "initial-O2-molecules", "initial-N2-molecules"
      ),
      "Connected Chemistry Reversible Reaction" -> Set(
        "#-H2", "#-N2", "#-NH3"
      ),
      "Matrix Example" -> Set(
        "A", "mCopy", "B", "mRef", "conR2", "comR2", "linR2"
      ),
      "Climate Change" -> Set(
        "add-CO2", "CO2", "CO2s-here", "IRs", "IR", "create-CO2s",
        "run-IR", "remove-CO2", "run-CO2", "CO2s"
      ),
      "Weak Acid" -> Set(
        "calculate-pH", "plot-pH", "concOH", "record-pH", "pOH", "Ka", "pH", "concH"
      ),
      "Strong Acid" -> Set(
        "calculate-pH", "concOH", "record-pH", "pOH", "pH", "concH"
      ),
      "Buffer" -> Set(
        "calculate-pH", "concOH", "pOH", "pH", "concH"
      ),
      "Diprotic Acid" -> Set(
        "A2conc", "Aconc", "calculate-pH", "Hconc", "plot-pH", "mmolA", "concOH",
        "record-pH", "HAconc", "pOH", "mmolHA", "mmolA2", "Ka2", "pH", "concH",
        "mmolOH", "mmolH", "Ka1", "OHconc"
      ),
      "Enzyme Kinetics" -> Set(
        "Kc", "Kr", "Kd"
      ),
      "Simple Kinetics 2" -> Set(
        "Kf", "Keq", "Kb", "Ku", "Kr"
      ),
      "Radical Polymerization" -> Set(
        "Io", "Km", "Ki"
      ),
      "Simple Kinetics 1" -> Set(
        "Kb", "Ku"
      ),
      "Ising" -> Set(
        "Ediff"
      ),
      "Prisoners Dilemma HubNet" -> Set(
        "D-C", "C-C", "D-D", "C-D", "COOPERATE", "DEFECT"
      )
    )

    for {
      model <- models
      allowed = exceptions.getOrElse(model.baseName, Set.empty)
      nonLowerCaseTokens = (for {
        token <- model.tokens
        if typesToCheck.contains(token.tyype)
        if !allowed.contains(token.name)
        if token.name != token.name.toLowerCase
      } yield token.name).toSet
      if nonLowerCaseTokens.nonEmpty
    } yield model.quotedPath + "\n  " + nonLowerCaseTokens.mkString("\"", "\", \"", "\"")
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
