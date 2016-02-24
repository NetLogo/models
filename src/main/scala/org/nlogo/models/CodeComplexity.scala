package org.nlogo.models

import java.nio.charset.StandardCharsets.UTF_8
import java.nio.file.Files
import java.nio.file.Paths

import Model.libraryModels

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
    writeFile("identifier_costs.txt", models.flatMap(_.primitiveTokenNames).toSeq.distinct.sorted.mkString("\n"))

  }

  def writeFile(fileName: String, content: String) {
    Files.write(Paths.get(fileName), content.getBytes(UTF_8))
  }
}
