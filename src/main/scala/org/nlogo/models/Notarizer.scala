package org.nlogo.models

import java.io.StringWriter
import java.util.regex.Pattern.quote

import org.apache.commons.io.FileUtils

import org.nlogo.core.{ Femto, LiteralParser, Model }
import org.nlogo.fileformat.FileFormat

import scala.collection.immutable.ListMap

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
    val newInfo = InfoTabParts.fromSections(newSections, infoTabParts.legalSnippet).content
    val newCode = legal.code

    val writer = new StringWriter

    val loader =
      FileFormat.standardXMLLoader(false, Femto.scalaSingleton[LiteralParser]("org.nlogo.parse.CompilerUtilities"))

    loader.saveToWriter(model.copy(info = newInfo, code = newCode), writer)

    val str = writer.toString

    writer.close()

    str
  }

  def main(args: Array[String]): Unit =
    for {
      model <- libraryModels
      newContent = notarize(model)
    } FileUtils.write(model.file, newContent, "UTF-8")
}
