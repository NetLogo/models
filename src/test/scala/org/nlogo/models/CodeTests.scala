package org.nlogo.models

import org.nlogo.core.TokenType
import org.nlogo.core.TokenType.Command

class CodeTests extends TestModels {

  type Exemption = String // the base name of an exempted model
  val forbiddenPrimitives: Seq[(String, Seq[Exemption])] = Seq(
    "__approximate-hsb-old" -> Seq.empty,
    "__bench" -> Seq.empty,
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
    "ask-concurrent" -> Seq("Ask-Concurrent Example"),
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
    "hubnet-set-client-interface" -> Seq.empty,
    "in-cone-nowrap" -> Seq.empty,
    "in-radius-nowrap" -> Seq.empty,
    "no-display" -> Seq.empty,
    "pd" -> Seq.empty,
    "ppd" -> Seq.empty,
    "ppu" -> Seq.empty,
    "print" -> Seq(
      // IABM textbook models using `print` in example code:
      "Example HubNet", "Voting Sensitivity Analysis",
      "Voting Component Verification", "Spread of Disease"
    ),
    "pu" -> Seq.empty,
    "se" -> Seq.empty,
    "show" -> Seq.empty,
    "st" -> Seq.empty,
    "towards-nowrap" -> Seq.empty,
    "towardsxy-nowrap" -> Seq.empty,
    "type" -> Seq.empty,
    "wait" -> Seq(
      "Sound Workbench", "Fish Spotters HubNet", "Bug Hunt Camouflage",
      "Bug Hunters Camouflage HubNet", "Bug Hunters Adaptations HubNet",
      "Memory HubNet", "Central Limit Theorem",
      "Gridlock HubNet", "Gridlock Alternate HubNet", "Polling Advanced HubNet",
      "Public Good HubNet", "4 Blocks", "9-Blocks", "Expected Value",
      "Expected Value Advanced", "Random Combinations and Permutations",
      "Partition Perms Distrib", "GoGoMonitorSerial", "GoGoMonitorSimpleSerial"
    ),
    "who" -> Seq(
      // Some of the following models may make justifiable use of `who`, but most
      // probably don't. They should be revisited at some point. NP 2015-10-16.
      "Disease HubNet", "Restaurants HubNet", "Prisoners Dilemma HubNet",
      "Disease Doctors HubNet", "Planarity", "Tetris", "PD N-Person Iterated",
      "Minority Game", "Osmotic Pressure", "Scattering", "N-Bodies", "Rope",
      "Speakers", "Raindrops", "GasLab Free Gas", "GasLab Moving Piston",
      "GasLab Heat Box", "GasLab Second Law", "GasLab Pressure Box",
      "GasLab Isothermal Piston", "GasLab Single Collision", "GasLab Two Gas",
      "GasLab Gravity Box", "GasLab Atmosphere", "GasLab Gas in a Box",
      "GasLab Maxwells Demon", "GasLab Adiabatic Piston", "Turing Machine 2D",
      "PageRank", "Dining Philosophers", "Team Assembly", "Ants",
      "Simple Birth Rates", "BeeSmart Hive Finding", "Sunflower Biomorphs",
      "AIDS", "Tumor", "Flocking Vee Formations", "Ant Lines", "Kaleidoscope",
      "Geometron Top-Down", "Optical Illusions", "Sound Machines", "Random Walk 360",
      "ProbLab Genetics", "Expected Value Advanced", "GasLab Free Gas", "Rope",
      "Three Loops Example", "Shapes Example", "Disease With Android Avoidance HubNet",
      "Random Network", "Ask Ordering Example", "Label Position Example", "Beatbox",
      "Composer", "GasLab With Sound", "Grouping Turtles Example", "Mouse Recording Example",
      "Line of Sight Example", "GasLab Gas in a Box (Perspective Demo)",
      "Ants (Perspective Demo)", "Intersecting Lines Example", "3D Shapes Example",
      "Urban Suite - Economic Disparity", "Urban Suite - Tijuana Bordertowns",
      "Connected Chemistry 5 Temperature and Pressure", "Connected Chemistry 6 Volume and Pressure",
      "Connected Chemistry 1 Bike Tire", "Connected Chemistry 7 Ideal Gas Law",
      "Connected Chemistry 3 Circular Particles", "Connected Chemistry 4 Number and Pressure",
      "Connected Chemistry Atmosphere", "Connected Chemistry 2 Changing Pressure",
      "Connected Chemistry 8 Gas Particle Sandbox", "DNA Protein Synthesis",
      "Hotelling's Law", "Tie System Example", "Piaget-Vygotsky Game"
    ),
    "write" -> Seq.empty
  )

  testModels("Forbidden primitives are not used") { model =>
    val tokenNames = new Tokens(model).primitiveTokenNames.toSet
    for {
      (prim, exceptions) <- forbiddenPrimitives
      if !exceptions.contains(model.baseName)
      if tokenNames.contains(prim)
    } yield "uses " + prim
  }

  // Some of these exceptions are debatable and should
  // be revisited at some point -- NP 2015-08-30
  val nonLowercaseExceptions = Map[String, Set[String]](
    "CA 1D Elementary" -> Set(
      "OIO", "IOI", "OII", "III", "OOI", "IOO", "IIO", "OOO"
    ),
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
      "Io", "Km", "Ki", "Kr"
    ),
    "Simple Kinetics 1" -> Set(
      "Kb", "Ku"
    ),
    "Ising" -> Set(
      "Ediff"
    ),
    "Prisoners Dilemma HubNet" -> Set(
      "D-C", "C-C", "D-D", "C-D", "COOPERATE", "DEFECT"
    ),
    "Ethnocentrism" -> Set(
      "initial-PTR"
    ),
    "Ethnocentrism - Alternative Visualization" -> Set(
      "initial-PTR"
    ),
    "Wolf Sheep Predation (Docked Hybrid)" -> Set(
      "sheepStock", "wolfStock", "predationRate", "predatorEfficiency"
    ),
    "Piaget-Vygotsky Game" -> Set(
      "ZPD"
    )
  )

  val typesToCheck = Set[TokenType](
    TokenType.Ident, TokenType.Command, TokenType.Reporter, TokenType.Keyword
  )

  testModels("All identifiers should be lowercase") { model =>
    val allowed = nonLowercaseExceptions.getOrElse(model.baseName, Set.empty)
    (for {
      token <- new Tokens(model).allTokens
      if typesToCheck.contains(token.tpe)
      if !allowed.contains(token.text)
      if token.text != token.text.toLowerCase
    } yield token.text).toSet
  }

  val plotInCodeExceptions = Set(
    // Some of the following models probably could (carefully) be
    // converted to have all their plotting code in the plots:
    "4 Block Two Stalagmites",
    "4 Blocks",
    "Artificial Neural Net - Perceptron",
    "BeeSmart Hive Finding",
    "Bug Hunt Predators and Invasive Species - Two Regions",
    "Bug Hunt Environmental Changes",
    "Bug Hunt Disruptions",
    "Bug Hunt Coevolution",
    "Central Limit Theorem",
    "Connected Chemistry 3 Circular Particles",
    "Connected Chemistry 5 Temperature and Pressure",
    "Connected Chemistry 6 Volume and Pressure",
    "Connected Chemistry 8 Gas Particle Sandbox",
    "Decay",
    "Diprotic Acid",
    "Doppler",
    "Enzyme Kinetics",
    "Equidistant Probability",
    "Expected Value Advanced",
    "Expected Value",
    "GasLab Atmosphere",
    "GasLab Circular Particles",
    "GasLab Free Gas",
    "GasLab Free Gas 3D",
    "GasLab Gas in a Box",
    "GasLab Gravity Box",
    "GasLab Heat Box",
    "GasLab Isothermal Piston",
    "GasLab Moving Piston",
    "GasLab Second Law",
    "Histo Blocks",
    "Minority Game",
    "Prob Graphs Basic",
    "ProbLab Genetics",
    "Robby the Robot",
    "Sample Stalagmite",
    "Sampler Solo",
    "Sandpile 3D",
    "Solid Diffusion",
    "Strong Acid",
    "Tabonuco Yagrumo Hybrid",
    "Tabonuco Yagrumo",
    "Urban Suite - Cells",
    "Weak Acid",
    // The "Wolf Sheep Simple" models from the IABM textbook
    // demonstrate in-code plotting for pedagogical reasons.
    // They should *not* be converted, ever.
    "Wolf Sheep Simple 2",
    "Wolf Sheep Simple 3",
    "Wolf Sheep Simple 4",
    "Wolf Sheep Simple 5"
  )

  testModels("Plotting commands should not be in the main code") { model =>
    if (plotInCodeExceptions.contains(model.name) ||
      model.name.contains("HubNet")) // give a pass to HubNet models for now
      Seq.empty
    else (for {
      token <- new Tokens(model).codeTokens
      if token.tpe == Command
      if Set("plot", "plotxy") contains token.text.toLowerCase
    } yield token.text).toSet
  }

  /* Currently commented out because it generates far too much noise
   * in the test reports. Will enable officially once the test passes.
   * NP 2015-08-20
   */
  val lineLengthLimit = 170
  testModels(s"Lines should not be longer than $lineLengthLimit characters", false, false,
    _.name != "Continental Divide") {
      // 85 is the limit in the IABM textbook, so ideally, we'd aim for that everywhere
      // For now, though, we'll tolerate a bit more and just catch the worst offenders
      testLines(_.code, _.length > lineLengthLimit, l => "%4d for ".format(l.length))
    }

}
