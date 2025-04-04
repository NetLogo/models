package org.nlogo.models

import org.nlogo.core.Model

class ViewTests extends TestModels {

  testModels("Models should have integer patch sizes") {
    Option(_)
      .filterNot(m => m.view.patchSize.toInt == m.view.patchSize)
      .map(_.view.patchSize.toString)
  }

  val nonStandardFrameRateModels = Set(
    "Mouse Example", "Label Position Example", "Shape Animation Example", "3D Shapes Example",
    "Movie Recording Example", "Connected Chemistry Atmosphere", "Connected Chemistry Rusting Reaction",
    "Particle System Basic", "Particle System Fountain", "Particle System Waterfall",
    "Particle System Flame", "Brian's Brain", "Life Turtle-Based", "Life", "Robby the Robot",
    "Sample Stalagmite", "Binomial Rabbits", "Birthdays", "Random Walk 360", "Pursuit", "Lightning",
    "Sound Machines", "Flocking Vee Formations", "BeeSmart Hive Finding", "Disease Solo", "Peppered Moths",
    "Honeycomb", "Preferential Attachment", "Sandpile", "Raindrops", "Doppler", "Ising", "MaterialSim Grain Growth",
    "Gravitation", "B-Z Reaction", "Reactor X-Section", "Lunar Lander",
    "PD N-Person Iterated", "PD Basic Evolutionary", "Sandpile Simple", "Heroes and Cowards",
    // Exception for MTG models that control tick-rate in case of no HubNet activity (CB 05-15-2018)
    "MTG 1 Equal Opportunities HubNet", "MTG 2 Random Assignment HubNet", "MTG 3 Feedback Loop HubNet"
  )
  testModels("Most models should have a frame rate of 30") {
    /* It can be OK to have a non-standard frame rate (though I'm
     * not sure all the exceptions listed here are justified --
     * I didn't check -- but this tests make sure that the frame
     * rate is not changed by mistake to a non-standard value.
     */
    Option(_)
      .filterNot(m => nonStandardFrameRateModels.contains(m.name))
      .filterNot(_.view.frameRate == 30)
  }

  testModels("Saved view size must match size computed from the saved patch size and screen-edge-x/y") {
    // finds models whose graphics windows' saved sizes don't match the size you should get if you
    // compute from the saved patch size and screen-edge-x/y
    // I think that this:
    // https://github.com/NetLogo/NetLogo/blob/09198dc87a4c509a5ca86811ef4123e09ba282bb/src/main/org/nlogo/window/ViewWidget.java#L200
    // ...explains most the cases where there is a discrepancy. The trick to keep the test
    // happy seems to simply make sure that the view is at least 245 pixels wide.
    // Non-integer patch sizes can also cause problems, but those should be caught
    // by the previous test. -- NP 2015-05-25.
    Option(_).filterNot(_.is3D).flatMap(checkModel)
  }

  def checkModel(model: Model): Option[String] = {
    // Note: I'm converting this to scalatest with as little fiddling as possible,
    // since I don't fully understand how this calculation is made. NP 2015-05-25.
    val maxx = model.view.maxPxcor
    val maxy = model.view.maxPycor
    val minx = model.view.minPxcor
    val miny = model.view.minPycor
    val (worldWidth, worldHeight) = (maxx - minx + 1, maxy - miny + 1)
    val (extraWidth, extraHeight) = (4, 4)
    var problems = Seq[String]()
    if (maxx < 0 || minx > 0 || maxy < 0 || miny > 0)
      problems +:= "bad world dimensions: " + (maxx, minx, maxy, miny)
    val computedWidth = extraWidth + model.view.patchSize * worldWidth
    val actualWidth = model.view.width
    if (computedWidth != actualWidth)
      problems +:= "computed width: " + computedWidth + ", actual width: " + actualWidth
    val computedHeight = extraHeight + model.view.patchSize * worldHeight
    val actualHeight = model.view.height
    if (computedHeight != actualHeight)
      problems +:= "computed height: " + computedHeight + ", actual height: " + actualHeight
    if (problems.nonEmpty)
      Some(model.quotedPath+ ":\n" + problems.mkString("\n"))
    else None
  }
}
