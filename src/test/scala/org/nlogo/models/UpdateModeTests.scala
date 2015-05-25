package org.nlogo.models

class UpdateModeTests extends TestModels {
  val continuousUpdateModels = Set(
    "./3D/Code Examples/Shapes Example 3D.nlogo3d",
    "./3D/Sample Models/Sierpinski Simple 3D.nlogo3d",
    "./Code Examples/Ask Ordering Example.nlogo",
    "./Code Examples/Ask-Concurrent Example.nlogo",
    "./Code Examples/Box Drawing Example.nlogo",
    "./Code Examples/Breed Procedures Example.nlogo",
    "./Code Examples/Case Conversion Example.nlogo",
    "./Code Examples/Color Chart Example.nlogo",
    "./Code Examples/File Input Example.nlogo",
    "./Code Examples/GIS/GIS General Examples.nlogo",
    "./Code Examples/GoGoMonitor.nlogo",
    "./Code Examples/GoGoMonitorSerial.nlogo",
    "./Code Examples/GoGoMonitorSimple.nlogo",
    "./Code Examples/GoGoMonitorSimpleSerial.nlogo",
    "./Code Examples/HSB and RGB Example.nlogo",
    "./Code Examples/Image Import Example.nlogo",
    "./Code Examples/Info Tab Example.nlogo",
    "./Code Examples/Link Breeds Example.nlogo",
    "./Code Examples/Link Lattice Example.nlogo",
    "./Code Examples/Matrix Example.nlogo",
    "./Code Examples/Moore & Von Neumann Example.nlogo",
    "./Code Examples/Myself Example.nlogo",
    "./Code Examples/Neighborhoods Example.nlogo",
    "./Code Examples/Network Import Example.nlogo",
    "./Code Examples/One Turtle Per Patch Example.nlogo",
    "./Code Examples/Patch Clusters Example.nlogo",
    "./Code Examples/Perspective Demos/Termites (Perspective Demo).nlogo",
    "./Code Examples/Profiler Example.nlogo",
    "./Code Examples/QuickTime Extension/QuickTime Movie Example.nlogo",
    "./Code Examples/Random Seed Example.nlogo",
    "./Code Examples/Scatter Example.nlogo",
    "./Code Examples/Sound/GasLab With Sound.nlogo",
    "./Code Examples/Sound/Musical Phrase Example.nlogo",
    "./Code Examples/Sound/Percussion Workbench.nlogo",
    "./Code Examples/Sound/Sound Workbench.nlogo",
    "./Code Examples/Table Example.nlogo",
    "./Code Examples/Tie System Example.nlogo",
    "./Code Examples/Transparency Example.nlogo",
    "./Code Examples/User Interaction Example.nlogo",
    "./Curricular Models/BEAGLE Evolution/Bird Breeder.nlogo",
    "./Curricular Models/Connected Chemistry/Connected Chemistry Atmosphere.nlogo",
    "./Curricular Models/Connected Chemistry/Connected Chemistry Rusting Reaction.nlogo",
    "./Curricular Models/ProbLab/4 Block Stalagmites.nlogo",
    "./Curricular Models/ProbLab/4 Block Two Stalagmites.nlogo",
    "./HubNet Activities/Polling HubNet.nlogo",
    "./IABM Textbook/chapter 8/Example HubNet.nlogo",
    "./IABM Textbook/chapter 8/Run Result Example.nlogo",
    "./IABM Textbook/chapter 8/Simple Viral Marketing.nlogo",
    "./Sample Models/Art/Optical Illusions.nlogo",
    "./Sample Models/Art/Unverified/Geometron Top-Down.nlogo",
    "./Sample Models/Biology/BeeSmart - Hive Finding.nlogo",
    "./Sample Models/Biology/Termites.nlogo",
    "./Sample Models/Computer Science/Painted Desert Challenge.nlogo",
    "./Sample Models/Computer Science/Unverified/Merge Sort.nlogo",
    "./Sample Models/Games/Unverified/Pac-Man Level Editor.nlogo",
    "./Sample Models/Mathematics/Probability/ProbLab/Unverified/Equidistant Probability.nlogo",
    "./Sample Models/Mathematics/Probability/ProbLab/Unverified/Random Combinations and Permutations.nlogo",
    "./Sample Models/Mathematics/Voronoi.nlogo",
    "./Sample Models/Social Science/Unverified/Prisoner's Dilemma/PD Basic.nlogo"
  )
  testModels("Models should use tick-based updates unless otherwise specified") {
    for {
      model <- _
      excluded = continuousUpdateModels(model.file.getPath)
      targetMode = if (excluded) Continuous else OnTicks
      if model.updateMode != targetMode
    } yield s"update mode should be $targetMode in ${model.quotedPath}"
  }
}
