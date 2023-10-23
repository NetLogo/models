package org.nlogo.models

import org.nlogo.core.TokenType
import org.nlogo.core.TokenType.Command
import org.nlogo.core.Model

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
    "__plot-pen-hide" -> Seq.empty,
    "__plot-pen-show" -> Seq.empty,
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
      // Exclusion for MTG models to print an error-message in rare case
      // the sugar map isn't available for some reason (CB 05-18-2018)
      "MTG 1 Equal Opportunities HubNet", "MTG 2 Random Assignment HubNet",
      "MTG 3 Feedback Loop HubNet",
      // IABM textbook models using `print` in example code:
      "Example HubNet", "Voting Sensitivity Analysis",
      "Voting Component Verification", "Spread of Disease",
      "Logotimes Example", // prints out logo times
      "Distribution Center Discrete Event Simulator"
    ),
    "pu" -> Seq.empty,
    "se" -> Seq.empty,
    "show" -> Seq("GIS General Examples"),
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
      "Partition Permutation Distribution", "GenJam - Duple",
      "PNoM 5 Virtual Syringe Temperature Graph",
      "2.5d Turtle View Example", "2.5d Patch View Example",
      "Pendulum"
    ),
    "who" -> Seq(
      // Some of the following models may make justifiable use of `who`, but most
      // probably don't. They should be revisited at some point. NP 2015-10-16.
      "Bidding Market", "Disease HubNet", "Restaurants HubNet", "Prisoners Dilemma HubNet",
      "Disease Doctors HubNet", "Planarity", "Tetris", "Prisoner's Dilemma N-Person Iterated",
      "Minority Game", "Osmotic Pressure", "Scattering", "N-Bodies", "Rope",
      "Speakers", "Raindrops", "GasLab Free Gas", "GasLab Moving Piston",
      "GasLab Heat Box", "GasLab Second Law", "GasLab Pressure Box",
      "GasLab Isothermal Piston", "GasLab Single Collision", "GasLab Two Gas",
      "GasLab Gravity Box", "GasLab Atmosphere", "GasLab Gas in a Box",
      "GasLab Maxwells Demon", "GasLab Adiabatic Piston", "Turing Machine 2D",
      "PageRank", "Dining Philosophers", "Team Assembly", "Ants",
      "Simple Birth Rates", "BeeSmart Hive Finding", "Sunflower Biomorphs",
      "HIV", "Tumor", "Flocking Vee Formations", "Ant Lines", "Kaleidoscope",
      "Geometron Top-Down", "Optical Illusions", "Sound Machines", "Random Walk 360",
      "Expected Value Advanced", "GasLab Free Gas", "Rope",
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
      "Hotelling's Law", "Tie System Example", "Piaget-Vygotsky Game", "GenJam - Duple",
      "Lattice Land - Triangles Dissection", "Lattice Land - Triangles Explore", "Lattice Land - Explore",
      "PNoM 1 Diffusion Sandbox", "PNoM 2 Diffusion Sensor Sandbox", "PNoM 3 Virtual Syringe",
      "PNoM 4 Virtual Syringe Force Graph", "PNoM 5 Virtual Syringe Temperature Graph",
      "PNoM 6 Particle Sandbox Gravity", "PNoM 7 Particle Sandbox Intermolecular Forces",
      "Prison Architecture and Emergent Violence", "Robotic Factory", "Limited Order Book",
      "Distribution Center Discrete Event Simulator", "Volume Temperature", "Hydrogen Gas Production"
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
    "Chloroplasts and Food" -> Set(
      "ADP-ATPs", "ADP-ATP", "ADP-ATPs-own", "update-ADP-ATPs"
    ),
    "Ant Adaptation" -> Set(
      "create-HUD-display-of-ants"
   ),
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
    "Current in a Semiconductor" -> Set(
      "Vx", "Vy"
    ),
    "CRISPR Bacterium LevelSpace" -> Set(
      "RNAPs-own",
      "hatch-guide-RNAs",
      "guide-RNA",
      "guide-RNAs-own",
      "go-guide-RNAs",
      "CRISPR-function",
      "guide-RNAs",
      "go-RNAPs",
      "CRISPR",
      "RNAPs",
      "create-RNAPs",
      "transcripts-per-RNAP",
      "CRISPR-function-%",
      "RNAP",
      "CRISPR-array",
      "guide-RNAs-here"
    ),
    "CRISPR Bacterium" -> Set(
      "RNAPs-own",
      "hatch-guide-RNAs",
      "guide-RNA",
      "guide-RNAs-own",
      "go-guide-RNAs",
      "guide-RNAs",
      "go-RNAPs",
      "CRISPR",
      "RNAPs",
      "create-RNAPs",
      "transcripts-per-RNAP",
      "RNAP",
      "guide-RNAs-here"
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
    "Small Worlds" -> Set(
      "node-A", "node-B"
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
   ),
   "GenEvo 1 Genetic Switch" -> Set(
     "go-LacYs", "LacI", "LacZs", "LacIs-own", "create-RNAPs", "RNAP", "on-DNA?",
     "LacZ-production-num", "LacYs", "LacZ-production-cost",
     "LevelSpace?", "LacY-degradation-chance", "LacI-number",
     "create-LacIs", "RNAPs-own", "LacZ", "lacZs", "go-LacI",
     "LacI-bond-leakage", "go-LacZ", "LacI-lactose-binding-chance",
     "RNAP-number", "LacI-lactose-binding-chance", "LacY-production-num",
     "LacI-bond-leakage", "hatch-LacYs", "LacY", "LacIs",
     "LacI-lactose-separation-chance", "hatch-lacZs", "RNAPs", "go-RNAP",
     "LacY-production-cost", "LacZ-degradation-chance", "LacI-lactose-separation-chance",
     "create-LacZs", "create-LacYs", "go-LacZs", "LacZs", "LacI-number", "LacY-degradation-chance",
     "go-LacIs", "go-RNAPs", "hatch-LacZs"
   ),
   "GenEvo 4 Competition" -> Set(
     "LevelSpace?", "lacZ-inside", "lacI-lactose-complex", "lacY-inserted", "lacY-inside"
   ),
   "Synthetic Biology - Genetic Switch" -> Set(
      "go-LacIs", "set-DNA-patches", "create-LacIs", "LacZ-gene", "RNAPs-own", "create-ONPGs",
      "degrade-LacZ", "LacZ", "ONPG-degradation-count", "LacI", "ONPGs-own", "update-ONPG",
      "RNAP-number", "go-LacIs", "create-LacZs", "LacZs", "LacZ-production-num-list", "ONPGs-here",
      "LacI-bond-leakage", "ONPG", "go-RNAPs", "LacIs", "go-LacZs", "ONPG-degradation-chance",
      "LacI-ONPG-separation-chance", "RNAPs", "create-RNAPs", "RNAPS", "go-LacZs", "LacI-ONPG-binding-chance",
      "LacZ-degradation-chance", "add-ONPG", "ONPGs", "go-ONPG", "LacIs-own", "ONPG?", "ONPG-quantity",
      "ONPG-number", "RNAP", "LacZ-degradation-chance", "LacI-ONPG-binding-chance", "LacZs", "LacZ-production-num",
      "degrade-LacZ", "go-ONPGs", "LacI-number"
   ),
   "Repressilator 1D" -> Set(
      "count-other-mRNAs-same-patch", "set-TF-position", "y-DNA","mRNA-gene-id",
      "bound-to-signal-TF-shape", "bound-TF-shape", "y-mRNA-top", "y-TF-top",
      "initial-TF1s","local-TF-gene-id","DNA-segment-shapes","mRNA-decay-prob",
      "TF-gene-id","TFs","TF-unbind-prob","signal-TF-unbind-prob","DNA-x-offset",
      "TF-age","initial-TF2s","sprout-TFs", "get-TF-DNA-is-inhibited-by",
      "TF","TF-decay-prob","initial-TFs","move-TFs","mRNAs-here","hatch-TFs",
      "mRNAs","initialize-TFs","TF-binding-site-gene-id","mRNAs-own","TF-can-bind-signal?",
      "DNA-segment-size","TF-bound-to-signal?","signal-TF-bind-prob","signal-TF-gene-id",
      "bind-TF","TF-binding-site","degrade-mRNAs","local-DNA-gene-id","TFs-here",
      "initialize-composite-DNA","n-TFs-produced","bind-TF-to-signal","DNA-gene-id",
      "get-DNA-TF-inhibits","sprout-DNA-segments","y-TF-bottom","produce-mRNAs",
      "TFs-per-mRNA","n-mRNAs-produced","count-other-TFs-same-color-same-patch",
      "unbound-TF-shape","initialize-TF","usable-mRNA-height","DNA-segments",
      "unbind-TF","TF-inhibits-gene-id","TF-binding-sites-own","DNA-segment",
      "unbind-TFs","TF-can-bind-gene-here?","y-mRNA-bottom","update-TF-shape",
      "create-initial-TFs","TF-can-inhibit-gene-here?","TF-binding-sites","produce-TFs",
      "bind-TFs","max-TF-synergy","TF-size","DNA-inhibited-by-gene-id","TF-bound?",
      "mRNA-size","TFs-own","TF-bind-prob","initial-TF0s","mRNA","degrade-TFs",
      "unbind-TF-from-signal","TF-rolling-plot-width","bound-TF-size","sprout-mRNAs",
      "initialize-mRNA"
   ),
   "Prison Architecture and Emergent Violence" -> Set(
      "PT-base-kindness-propensity", "SJ-percent-conforming", "RG-percent-conforming",
      "RG-base-kindness-propensity", "SJ-base-kindness-propensity", "PT-percent-conforming",
      "OL-base-kindness-propensity", "OL-percent-conforming"
   ),
   "Mendelian Inheritance" -> Set(
      "make-F1-generation", "clear-F1-generation"
   ),
   "Dislocation Motion and Deformation" -> Set(
      "total-PE", "indiv-PE-and-force", "equalizing-LJ-force", "min-A",
      "LJ-potential-and-force"
   ),
   "Hardy Weinberg Equilibrium" -> Set(
      "frequency-of-dominant-A"
   ),
   "Calorimetry" -> Set(
      "Ca-to-add",
      "add-Ca",
      "add-CA",
      "add-KI",
      "KI-to-add"
   ),
   "Taxi Cabs" -> Set(
       "prob-res-res-EVE", "prob-com-com-PM", "prob-cbd-res-PM", "prob-cbd-cbd-AM",
       "prob-com-res-AM", "prob-res-res-EM", "prob-res-res-PM", "prob-cbd-com-PM",
       "prob-com-res-MD", "prob-res-cbd-EM", "prob-cbd-cbd-EVE", "prob-com-com-EVE",
       "prob-cbd-res-AM", "prob-com-cbd-EVE", "prob-res-com-AM", "prob-res-com-EM",
       "prob-com-cbd-PM", "prob-res-cbd-PM", "prob-cbd-res-MD", "prob-cbd-com-EM",
       "prob-cbd-com-AM", "prob-cbd-cbd-EM", "prob-res-cbd-AM", "prob-com-com-EM",
       "prob-com-res-EVE", "prob-res-res-MD", "prob-res-cbd-MD", "prob-res-com-MD",
       "prob-res-cbd-EVE", "prob-res-com-EVE", "prob-com-cbd-AM", "prob-cbd-res-EVE",
       "prob-com-com-MD", "prob-res-res-AM", "prob-com-cbd-MD", "prob-com-cbd-EM",
       "prob-cbd-com-MD", "prob-com-res-PM", "prob-com-res-EM", "prob-com-com-AM",
       "prob-cbd-com-EVE", "prob-res-com-PM", "prob-cbd-cbd-MD", "prob-cbd-res-EM",
       "prob-cbd-cbd-PM",
   ),
   "Hydrogen Gas Production" -> Set(
     "num-Zn", "num-HCl", "Zn-increment", "Zns", "Zn", "Zn-ions", "Zn-ion",
     "Zn-ions-own","make-Zn", "make-HCl", "Zns-here", "sprout-Zns",
   ),
   "Molecular Dynamics Lennard-Jones" -> Set(
     "Kb",
   )
  )

  val typesToCheck = Set[TokenType](
    TokenType.Ident, TokenType.Command, TokenType.Reporter, TokenType.Keyword
  )

  testModels("Plot names should be case insensitive") { model =>
    (for {
      m <- Option(Model)
      duplicates = new Tokens(model).plotNames.map(_.toLowerCase)
        .groupBy(identity)
        .collect { case (x, ys) if ys.size > 1 => x }
      if (duplicates.nonEmpty)
    } yield(duplicates.mkString("\n"))).toSet
  }

  testModels("Plot-pen names should be case insensitive") { model =>
    (for {
      plot <- new Tokens(model).plotPenNamesByPlot
      title = plot._1
      duplicates = plot._2.map(_.toLowerCase).filter(_.nonEmpty)
        .groupBy(identity)
        .collect { case (x, ys) if ys.size > 1 => x }
      if (duplicates.nonEmpty)
    } yield(title + " plot: " + duplicates.mkString(", "))).toSet
  }

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
    "CRISPR Ecosystem",
    "CRISPR Ecosystem LevelSpace",
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
    "Robby the Robot",
    "Sample Stalagmite",
    "Sampler Solo",
    "Sandpile 3D",
    "SmoothLife",
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
    "Wolf Sheep Simple 5",
    "Discrete Event Mousetrap"
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

  val lineLengthLimit = 170
  testModels(s"Lines should not be longer than $lineLengthLimit characters", false, false,
    _.name != "Continental Divide") {
      // 85 is the limit in the IABM textbook, so ideally, we'd aim for that everywhere
      // For now, though, we'll tolerate a bit more and just catch the worst offenders
      testLines(_.code, _.length > lineLengthLimit, l => "%4d for ".format(l.length))
    }

  val pattern = """\[\s*[^\s]*\s*\]\s*->""".r
  testModels("Anonymous procedures with zero or one argument should not use brackets") {
    testLines(_.allSources.mkString("\n"), l => pattern.findFirstIn(l).isDefined)
  }

  testModels("Code should not contain reviewer comments (e.g. `{{{` or `}}}`)") {
    testLines(_.allSources.mkString("\n"), l => """\{\{\{|\}\}\}""".r.findFirstIn(l).isDefined)
  }
}
