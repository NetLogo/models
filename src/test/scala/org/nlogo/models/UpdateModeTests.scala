package org.nlogo.models

import org.nlogo.core.UpdateMode.Continuous
import org.nlogo.core.UpdateMode.TickBased

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
      targetMode = if (continuousUpdateModels(m.name)) Continuous else TickBased
      if model.view.updateMode != targetMode
    } yield s"update mode should be $targetMode"
  }
}
