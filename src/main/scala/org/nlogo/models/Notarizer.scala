package org.nlogo.models

import java.util.regex.Pattern.quote

import scala.collection.immutable.ListMap

import org.apache.commons.io.FileUtils
import org.nlogo.core.Model

object Notarizer {

  def notarize(model: Model): String = {
    val legal = LegalInfo(model)
    val infoTabParts = model.infoTabParts
    val newSections = (
      ListMap() ++
      legal.acknowledgment.map(InfoTabParts.Acknowledgment.name -> _) ++
      (infoTabParts.sectionMap - InfoTabParts.Acknowledgment.name) ++
      legal.creditsAndReferences.map(InfoTabParts.CreditsAndReferences.name -> _)
      ++ Seq(
        InfoTabParts.HowToCite.name -> legal.howToCite,
        InfoTabParts.CopyrightAndLicense.name -> legal.copyrightAndLicence
      )
    ).filter(_._2.nonEmpty)
    val newInfo = InfoTabParts.fromSections(newSections, infoTabParts.legalSnippet)
    val newCode = legal.code
    val sectionSeparator = "@#$#@#$#@"
    val originalContent = FileUtils.readFileToString(model.file, "UTF-8")
    val sections = (originalContent + sectionSeparator + "\n").split(quote(sectionSeparator) + "\\n")
    val Array(
      code, interface, infoString, turtleShapes, version,
      previewCommands, systemDynamics, behaviorSpace,
      hubNetClient, linkShapes, modelSettings) = sections
    Seq(
      newCode, interface, newInfo.content, turtleShapes, version,
      previewCommands, systemDynamics, behaviorSpace,
      hubNetClient, linkShapes, modelSettings)
      .mkString("", sectionSeparator + "\n", sectionSeparator + "\n")
  }

  def main(args: Array[String]): Unit =
    for {
      model <- libraryModels
      newContent = notarize(model)
    } FileUtils.write(model.file, newContent, "UTF-8")
}
