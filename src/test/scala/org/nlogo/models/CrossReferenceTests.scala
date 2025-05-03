package org.nlogo.models

import java.io.File
import java.nio.file.{ Files, Paths }

import com.typesafe.config.{ Config, ConfigFactory }

import org.scalatest.funsuite.AnyFunSuite

import scala.jdk.CollectionConverters.ListHasAsScala

class CrossReferenceTests extends AnyFunSuite {

  val crossReference = ConfigFactory.parseFile(new File("crossReference.conf"))

  test("all cross-referenced single models exist") {
    val modelRefs = crossReference.getConfigList("org.nlogo.models.crossReference.singleModels").asScala
    modelRefs.foreach { ref =>
      val source = ref.getString("source")
      val path = Paths.get(source)
      val realPath = path.toRealPath()
      val realSubpath =
        realPath.subpath(realPath.getNameCount - path.getNameCount, realPath.getNameCount)
      assert(
        Files.exists(path) && Files.isRegularFile(path) &&
        realSubpath.toString == path.toString,
        s"expected to find a nlogo file at $source, but couldn't find it!")
    }
  }

  test("all cross-referenced directories exist and are directories") {
    val directoryRefs = crossReference.getConfigList("org.nlogo.models.crossReference.directories").asScala
    directoryRefs.foreach { ref =>
      val source = ref.getString("sourceDir")
      val path = Paths.get(source)
      val realPath = path.toRealPath()
      val realSubpath =
        realPath.subpath(realPath.getNameCount - path.getNameCount, realPath.getNameCount)
      assert(
        Files.exists(path) && Files.isDirectory(path) &&
        realSubpath.toString == path.toString,
        s"expected find a directory at $source, but couldn't find it!")
    }
  }
}
