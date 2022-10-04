package org.nlogo.models

import java.util.{ ArrayList => JArrayList }

import scala.collection.JavaConverters._
import scala.language.postfixOps
import scala.util.{ Failure, Try }

import com.vladsch.flexmark.ast.{ FencedCodeBlock, Node, IndentedCodeBlock }
import com.vladsch.flexmark.parser.{ Parser, ParserEmulationProfile }
import com.vladsch.flexmark.util.options.MutableDataSet

import org.nlogo.app.infotab.InfoFormatter
import org.nlogo.core.{ CompilerException, TokenType }

class InfoTabsTests extends TestModels {

  val whatIsIt = InfoTabParts.WhatIsIt.name

  testModels("All models' info tabs should have WHAT IS IT? section") {
    Option(_)
      .filterNot(_.infoTabParts.sectionMap.keySet.contains(whatIsIt))
      .map(_ => "doesn't have WHAT IS IT? section")
  }

  testModels("Most info tabs should start with WHAT IS IT? section") {
    Option(_)
      .filter(_.infoTabParts.sections.head._1 != whatIsIt)
      .filterNot { m =>
        Set("Alternative Visualizations", "IABM Textbook")
          .exists(m.file.getPath.contains)
      }
      .map {
        "starts with " + _.info.linesIterator.dropWhile(_.isEmpty).take(1).mkString
      }
  }

  val minLen = 40
  val maxLen = 700
  testModels(s"Length of first paragraph of WHAT IS IT should be >= $minLen and <= $maxLen") { model =>
    for {
      paragraph <- model.infoTabParts.sectionMap.get(whatIsIt).map(_.linesIterator.next)
      length = paragraph.length
      if length <= minLen || length > maxLen
    } yield s"Length is $length in ${model.quotedPath}"
  }

  test("First paragraph of WHAT IS IT should be unique") {
    val failures = for {
      (optWhatItIs, groupedModels) <- libraryModels.groupBy(_.infoTabParts.sectionMap.get(whatIsIt).map(_.linesIterator.next))
      whatItIs <- optWhatItIs
      if groupedModels.size > 1
    } yield whatItIs + "\n  " + groupedModels.map(_.quotedPath).mkString("\n  ")
    if (failures.nonEmpty) fail(failures.mkString("\n"))
  }

  testModels("Info tabs should not have empty sections") {
    Seq(_).flatMap(_.infoTabParts.sections.filter(_._2.isEmpty).map(_._1))
  }

  testModels("Info tabs should not have repeated sections") {
    Seq(_).flatMap { m =>
      val sectionTitles = m.infoTabParts.sections.map(_._1).toSeq
      sectionTitles diff sectionTitles.distinct
    }
  }

  testModels("Bullet list using dashes should have space after dash") {
    val pattern = """^-\w.+""".r.pattern
    testLines(_.info, pattern.matcher(_).matches)
  }

  testModels("Info tabs should not contain reviewer comments (e.g. `{{{` or `}}}`)") {
    val pattern = """\{\{\{|\}\}\}""".r.pattern
    testLines(_.info, pattern.matcher(_).find)
  }

  testModels("Info tabs should not contain HTML tags (other than <sup> and <sub>)") {
    val pattern = """(?i)<(?!sub|sup)([A-Z][A-Z0-9]*)\b[^>]*>(.*?)<\/\1>""".r.pattern
    testLines(_.info, pattern.matcher(_).find)
  }

  val codeTestsExceptions = Set(
    "Example HubNet" // because the code block in it uses procedure names that don't exist
  )
  testModels("Code blocks should only include NetLogo code") { model =>
    val parser = {
      val options = new MutableDataSet()

      options.setFrom(ParserEmulationProfile.PEGDOWN)
      options.set(Parser.MATCH_CLOSING_FENCE_CHARACTERS, Boolean.box(false))

      Parser.builder(options).build()
    }

    if (!model.isCompilable || codeTestsExceptions.contains(model.name))
      Seq.empty
    else
      withWorkspace(model) { ws =>
        val program = ws.world.program
        val alreadyDefined =
          program.globals ++ program.turtlesOwn ++ program.patchesOwn ++ program.linksOwn ++
            ws.procedures.keySet ++ program.breeds.keys ++ program.linkBreeds.keys ++
            program.breeds.values.flatMap(_.owns) ++ program.linkBreeds.values.flatMap(_.owns)

        def getErrors(node: Node): Seq[(String, String)] =
          node match {
            case f: FencedCodeBlock if f.getInfo.trim.isEmpty =>
              check(f.getContentChars.toString)
            case i: IndentedCodeBlock => check(i.getContentChars.toString)
            case other => other.getChildren.asScala.flatMap(s => getErrors(s)).toSeq
          }

        def check(code: String) = {
          def compileProc(header: String, body: String) =
            Try(ws.compiler.compileMoreCode(s"$header $body end", None, ws.world.program,
              ws.procedures, ws.getExtensionManager, ws.getLibraryManager, ws.getCompilationEnvironment))

          val blocks = code.split("""\n\s*\n""")
          val errors = blocks map { block =>
            val idents = ws
              .tokenizeForColorization(block)
              .filter(_.tpe == TokenType.Ident)
              .map(_.text.toUpperCase)
              .distinct
            val unknownIdents = idents.diff(alreadyDefined.map(_.toUpperCase) :+ "->")

            val body = block
              .replaceAll(""";[^\n]*""", "").trim
              .replaceFirst("""^to(-report)?\s+[-A-Za-z]+""", "")
              .replaceFirst("""^\s*\[\s*[-A-Za-z]+(\s+[-A-Za-z]+)*\s*\]""", "")
              .stripSuffix("end")
              .replaceAll("""\blet\b""", "set")

            compileProc(s"to __proc [${unknownIdents.mkString(" ")}]", body) recoverWith {
              case ex: CompilerException if ex.getMessage == "Expected command." =>
                compileProc(s"to-report __proc [${unknownIdents.mkString(" ")}] report", body)
              case ex: CompilerException if ex.getMessage == "REPORT can only be used inside TO-REPORT." =>
                compileProc(s"to-report __proc [${unknownIdents.mkString(" ")}]", body)
              case ex: CompilerException if ex.getMessage.startsWith("There is already a local variable here called ") =>
                val id = ex.getMessage.stripPrefix("There is already a local variable here called ")
                compileProc(s"to __proc [${unknownIdents.diff(Seq(id)).mkString(" ")}]", body)
            }
          } collect { case Failure(ex) => ex.getMessage }

          blocks zip errors
        }

        val doc = parser.parse(model.info)

        getErrors(doc) map { case (code, error) => s"$error\n$code" }
      }
  }

}
