package org.nlogo.models

class UpdateModeTests extends TestModels {
  val continuousUpdateModels = Set(
    "Shapes Example 3D",
    "Ask-Concurrent Example",
    "GIS General Examples",
    "GoGoMonitor",
    "GoGoMonitorSerial",
    "GoGoMonitorSimple",
    "GoGoMonitorSimpleSerial",
    "Image Import Example",
    "Termites (Perspective Demo)",
    "QuickTime Movie Example",
    "Tie System Example",
    "Bird Breeder",
    "Polling HubNet",
    "Example HubNet",
    "Geometron Top-Down",
    "Termites",
    "Painted Desert Challenge",
    "Pac-Man Level Editor",
    "Piaget-Vygotsky Game",
    "Equidistant Probability",
    "Random Combinations and Permutations",
    "Voronoi"
  )

  testModels("Models should use tick-based updates unless otherwise specified") { model =>
    for {
      m <- Option(model)
      excluded = continuousUpdateModels(m.name)
      targetMode = if (excluded) Model.Continuous else Model.OnTicks
      if model.updateMode != targetMode
    } yield s"update mode should be $targetMode"
  }
}
