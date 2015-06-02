package org.nlogo.models

import scala.util.Try
import scala.collection.immutable.ListMap

object Notarizer {

  def notarize(model: Model): Model = {
    val legal = model.legalInfo
    val newSections = (
      ListMap() ++
      legal.acknowledgment.map(Info.Acknowledgment.name -> _) ++
      (model.info.sectionMap - Info.Acknowledgment.name) ++
      legal.creditsAndReferences.map(Info.CreditsAndReferences.name -> _)
      ++ Seq(
        Info.HowToCite.name -> legal.howToCite,
        Info.CopyrightAndLicense.name -> legal.copyrightAndLicence
      )
    ).filter(_._2.nonEmpty)
    val newInfo = Info.fromSections(newSections, model.info.legalSnippet)
    val newCode = legal.code
    model.copy(info = newInfo, code = newCode)
  }

  def main(args: Array[String]): Unit =
    for {
      model <- Model.models
      notarizedModel <- Try(notarize(model)).toOption
    } notarizedModel.save()
}
