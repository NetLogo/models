package org.nlogo.models

class ViewTests extends TestModels {

  testLibraryModels("Models should have integer patch sizes") {
    Option(_)
      .filterNot(m => m.patchSize.toInt == m.patchSize)
      .map(_.patchSize.toString)
  }

  testLibraryModels("Saved view size must match size computed from the saved patch size and screen-edge-x/y") {
    // finds models whose graphics windows' saved sizes don't match the size you should get if you
    // compute from the saved patch size and screen-edge-x/y
    // I think that this:
    // https://github.com/NetLogo/NetLogo/blob/09198dc87a4c509a5ca86811ef4123e09ba282bb/src/main/org/nlogo/window/ViewWidget.java#L200
    // ...explains most the cases where there is a discrepancy. The trick to keep the test
    // happy seems to simply make sure that the view is at least 245 pixels wide.
    // Non-integer patch sizes can also cause problems, but those should be caught
    // by the previous test. -- NP 2015-05-25.
    Option(_).filterNot(_.is3d).flatMap(checkModel)
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
    val (extraWidth, extraHeight) =
      // take control strip and gray border into account
      if (List("1.3", "2.", "3.", "4.", "5.").exists(version.startsWith(_))) (10, 31) else (0, 0)
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
