package org.nlogo.models

class ViewTests extends TestModels {

  testModels("Models should have integer patch sizes") {
    Option(_)
      .filterNot(m => m.patchSize.toInt == m.patchSize)
      .map(_.patchSize.toString)
  }

  val nonStandardFrameRateModels = Set(
    "Mouse Example", "Label Position Example", "Shape Animation Example", "3D Shapes Example",
    "Movie Example", "Connected Chemistry Atmosphere", "Connected Chemistry Rusting Reaction",
    "Particle System Basic", "Particle System Fountain", "Particle System Waterfall",
    "Particle System Flame", "Brian's Brain", "Life Turtle-Based", "Life", "Robby the Robot",
    "Sample Stalagmite", "Binomial Rabbits", "Birthdays", "Random Walk 360", "Pursuit", "Lightning",
    "Sound Machines", "Flocking Vee Formations", "BeeSmart Hive Finding", "Disease Solo", "Peppered Moths",
    "Honeycomb", "Preferential Attachment", "Sandpile", "Raindrops", "Doppler", "Ising", "MaterialSim Grain Growth",
    "Gravitation", "B-Z Reaction", "Reactor X-Section", "Lunar Lander", "El Farol Network Congestion",
    "PD N-Person Iterated", "PD Basic Evolutionary", "Sandpile Simple", "Heroes and Cowards"
  )
  testModels("Most models should have a frame rate of 30") {
    /* It can be OK to have a non-standard frame rate (though I'm
     * not sure all the exceptions listed here are justified --
     * I didn't check -- but this tests make sure that the frame
     * rate is not changed by mistake to a non-standard value.
     */
    Option(_)
      .filterNot(_.is3D)
      .filterNot(m => nonStandardFrameRateModels.contains(m.name))
      .map(_.interface.lines.dropWhile(_ != "GRAPHICS-WINDOW").drop(25).next.toDouble)
      .filterNot(_ == 30)
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
    val lines = model.content.lines.toSeq
    val version = lines.find(_.matches("""NetLogo [0-9]\..*""")).get.drop("NetLogo ".size)
    val graphics = lines.dropWhile(_ != "GRAPHICS-WINDOW").takeWhile(_ != "")
    val (x1, y1, x2, y2) = (graphics(1).toInt, graphics(2).toInt, graphics(3).toInt, graphics(4).toInt)
    val patchSize = graphics(7).toDouble
    val maxx = if (graphics.size > 18) graphics(18).toInt else graphics(5).toInt
    val maxy = if (graphics.size > 20) graphics(20).toInt else graphics(6).toInt
    val minx = if (graphics.size > 17) graphics(17).toInt else -maxx
    val miny = if (graphics.size > 19) graphics(19).toInt else -maxy
    val (worldWidth, worldHeight) = (maxx - minx + 1, maxy - miny + 1)
    // take control strip and gray border into account
    val (extraWidth, extraHeight) = (10, 31)
    val computedWidth = extraWidth + patchSize * worldWidth
    val computedHeight = extraHeight + patchSize * worldHeight
    var problems = Seq[String]()
    if (maxx < 0 || minx > 0 || maxy < 0 || miny > 0)
      problems +:= "bad world dimensions: " + (maxx, minx, maxy, miny)
    if (computedWidth != x2 - x1)
      problems +:= "computed width: " + computedWidth + ", actual width: " + (x2 - x1)
    if (computedHeight != y2 - y1)
      problems +:= "computed height: " + computedHeight + ", actual height: " + (y2 - y1)
    if (problems.nonEmpty)
      Some(model.quotedPath + " (" + version + "):\n" + problems.mkString("\n"))
    else None
  }
}
