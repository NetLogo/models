package org.nlogo.models

import scala.util.Try

class BehaviorSpaceTests extends TestModels {

  testModels("BehaviorSpace experiments XML should be well formed") {
    Option(_)
      .filter(_.behaviorSpace.nonEmpty)
      .flatMap(m => Try(m.behaviorSpaceXML).failed.toOption)
      .filterNot(_.isInstanceOf[UnsupportedOperationException])
  }

  testModels("BehaviorSpace experiment names should not start with \"experiment\"") {
    Seq(_).filter(_.behaviorSpace.nonEmpty).flatMap { m =>
      (m.behaviorSpaceXML \ "experiment" \ "@name")
        .map(_.text)
        .filter(_.startsWith("experiment"))
    }
  }
}
