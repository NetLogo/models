package org.nlogo.models

import java.io.ByteArrayInputStream
import java.io.File
import java.lang.{ ProcessBuilder => JProcessBuilder }
import java.nio.file.{ Files, Path, Paths }

import scala.collection.JavaConverters._
import scala.sys.process.ProcessBuilder
import scala.sys.process.ProcessLogger
import scala.sys.process.stringSeqToProcess

import org.scalatest.BeforeAndAfterAll

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
class SpellCheckTests extends TestModels with BeforeAndAfterAll {

  override def beforeAll() =
    if (Seq("which", "aspell").!(ProcessLogger(_ => ())) != 0)
      throw new Exception("aspell not installed!")

  val dictPath = new File(getClass.getResource("/modelwords.txt").toURI).getPath
  def aspell(inPath: Path): (JProcessBuilder, Path) = {
    val tmpPath = Files.createTempFile("out", ".txt")
    (new JProcessBuilder("aspell",
      "--encoding=UTF-8",
      "--lang=en_US",
      "--mode=html",
      "--ignore-case",
      "--personal", dictPath,
      "list")
        .redirectInput(inPath.toFile)
        .redirectOutput(tmpPath.toFile), tmpPath)
  }
  val escapes = Set("\\n", "\\t")

  // using tmpPath and java's ProcessBuilder as a workaround for
  // https://issues.scala-lang.org/browse/SI-10055
  testModels("Models must not contain typos") { model =>
    val tmpPath = Files.createTempFile(model.file.getName, ".txt")
    val contentWithoutEscapes = escapes.foldLeft(model.content)(_.replace(_, " "))
    Files.write(tmpPath, contentWithoutEscapes.getBytes("UTF-8"))
    val lines = model.content.lines.zipWithIndex.toStream
    val (runCheck, outFile) = aspell(tmpPath)
    runCheck.start().waitFor()
    Files.readAllLines(outFile)
      .asScala
      .distinct
      .map(typo => typo -> lines.filter(_._1 contains typo).map(_._2 + 1))
      .sortBy(_._2.head) // sort by line number of first occurrence
      .map { case (t, ns) => s"  $t (${ns.mkString(", ")})" }
  }
}
