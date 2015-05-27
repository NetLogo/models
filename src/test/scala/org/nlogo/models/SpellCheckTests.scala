package org.nlogo.models

import java.io.ByteArrayInputStream
import java.io.File

import scala.sys.process.ProcessBuilder
import scala.sys.process.stringSeqToProcess

/**
 * This test is not very sophisticated, but enough to catch the most egregious typos.
 * False positives are common, so feel free to add liberally to
 *
 *     src/test/resources/modelwords.txt
 *
 * Note that the code is spell checked too. NetLogo keywords and common
 * variable names are already white listed, but you may need to add some.
 *
 * -- NP 2015-05-26
 */
class SpellCheckTests extends TestModels {

  val dictPath = new File(getClass.getResource("/modelwords.txt").toURI).getPath
  val aspell: ProcessBuilder = Seq(
    "aspell",
    "--encoding=UTF-8",
    "--lang=en_US",
    "--mode=html",
    "--ignore-case",
    "--personal", dictPath,
    "list")
  val escapes = Set("\\n", "\\t")

  testModels("Models must not contain typos") {
    for {
      model <- _
      content = escapes.foldLeft(model.content)(_.replace(_, " "))
      inputStream = new ByteArrayInputStream(content.getBytes("UTF-8"))
      typos = (aspell #< inputStream).lineStream
      if typos.nonEmpty
      lines = model.content.lines.zipWithIndex.toStream
      typosDesc = typos.distinct.sorted.map { typo =>
        val lineNos = lines.filter(_._1 contains typo).map(_._2 + 1)
        "  " + typo + " (" + lineNos.mkString(", ") + ")"
      }
    } yield model.quotedPath + "\n" + typosDesc.mkString("\n")
  }
}
