package org.nlogo.models

import Model._
import org.nlogo.api.TokenType
import org.nlogo.api.TokenType._

object CodeComplexity {

  val models = libraryModels.filterNot(_.file.getPath.contains("Code Examples"))

  val usageCosts =
    models.flatMap(_.primitiveTokenNames)
      .groupBy(identity)
      .mapValues(1.0 / _.size)

  def main(args: Array[String]): Unit = {
    println(
      models
        .map(m => m.name -> m.primitiveTokenNames.map(usageCosts).sum)
        .toSeq.sortBy(_._2)
        .map { case (m, w) => s"$m, $w" }
        .mkString("\n")
    )
  }
}
