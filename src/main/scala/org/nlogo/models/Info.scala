package org.nlogo.models

import scala.collection.immutable.ListMap

import org.apache.commons.lang3.StringUtils.stripEnd

object InfoTabParts {

  sealed abstract class Section(val name: String)
  case object Acknowledgment extends Section("ACKNOWLEDGMENT")
  case object CreditsAndReferences extends Section("CREDITS AND REFERENCES")
  case object WhatIsIt extends Section("WHAT IS IT?")
  case object HowToCite extends Section("HOW TO CITE")
  case object CopyrightAndLicense extends Section("COPYRIGHT AND LICENSE")
  val sections: Map[String, Section] = Seq(
    WhatIsIt, HowToCite, CopyrightAndLicense
  ).map(s => s.name -> s).toMap

  def clean(s: String) =
    s.linesIterator.map(stripEnd(_, null)).toSeq
      .dropWhile(_.isEmpty).reverse
      .dropWhile(_.isEmpty).reverse
      .mkString("\n")

  def contentToSections(contentLines: Seq[String]): Iterable[(String, String)] = {
    val titlePattern = """^##([^#].*)""".r
    def loop(
      contentLines: Seq[String],
      result: Vector[(String, Vector[String])],
      title: Option[String],
      sectionLines: Vector[String]): Vector[(String, Vector[String])] = {
      def newResult = title.map(result :+ (_, sectionLines)).getOrElse(result)
      if (contentLines.isEmpty) newResult
      else contentLines.head match {
        case titlePattern(t) =>
          loop(contentLines.tail, newResult, Some(t.trim), Vector.empty)
        case line =>
          loop(contentLines.tail, result, title, sectionLines :+ line)
      }
    }
    loop(contentLines, Vector.empty, None, Vector.empty)
      .map { case (title, lines) => title -> clean(lines.mkString("\n")) }
  }
  def fromContent(content: String): InfoTabParts = {
    val contentLines = clean(content).linesIterator.toSeq
    fromSections(contentToSections(contentLines))
  }
  def fromSections(sections: Iterable[(String, String)]): InfoTabParts = {
    val content = sections
      .map { case (title, text) => s"## $title\n\n$text" }
      .mkString("\n\n")
    InfoTabParts(content, sections)
  }
}
case class InfoTabParts(
  val content: String,
  val sections: Iterable[(String, String)]) {
  val sectionMap: ListMap[String, String] = ListMap() ++ sections
}
