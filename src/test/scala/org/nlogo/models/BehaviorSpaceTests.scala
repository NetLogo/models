package org.nlogo.models

class BehaviorSpaceTests extends TestModels {
  testModels("BehaviorSpace experiment names should not start with \"experiment\"") {
    _.protocols.map(_.name).filter(_.startsWith("experiment"))
  }
}
