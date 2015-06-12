package org.nlogo.models

import scala.util.Try

class BehaviorSpaceTests extends TestModels {

  testLibraryModels("BehaviorSpace experiments XML should be well formed") { models =>
    for {
      model <- models
      if model.behaviorSpace.nonEmpty
      error <- Try(model.behaviorSpaceXML).failed.toOption
      if !error.isInstanceOf[UnsupportedOperationException]
    } yield model.quotedPath + "\n  " + error
  }

  testLibraryModels("BehaviorSpace experiment names should not start with \"experiment\"") { models =>
    for {
      model <- models
      if model.behaviorSpace.nonEmpty
      xml = model.behaviorSpaceXML
      experimentNames = (xml \ "experiment" \ "@name").map(_.text)
      badExperimentNames = experimentNames.filter(_.startsWith("experiment"))
      if badExperimentNames.nonEmpty
    } yield model.quotedPath + ":\n" + badExperimentNames.map("  " + _).mkString("\n")
  }
}
