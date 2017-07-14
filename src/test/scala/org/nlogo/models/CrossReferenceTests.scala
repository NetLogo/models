package org.nlogo.models

import java.io.File
import java.nio.file.{ Files, Paths }

import com.typesafe.config.{ Config, ConfigFactory }

import org.scalatest.FunSuite

import scala.collection.JavaConverters._

class CrossReferenceTests extends FunSuite {

  val crossReference = ConfigFactory.parseFile(new File("crossReference.conf"))

  test("all cross-referenced single models exist") {
    val modelRefs = crossReference.getConfigList("org.nlogo.models.crossReference.singleModels").asScala
    modelRefs.foreach { ref =>
      val source = ref.getString("source")
      assert(Files.isRegularFile(Paths.get(source)), s"expected to find a nlogo file at $source, but couldn't find it!")
    }
  }

  test("all cross-referenced directories exist and are directories") {
    val directoryRefs = crossReference.getConfigList("org.nlogo.models.crossReference.directories").asScala
    directoryRefs.foreach { ref =>
      val source = ref.getString("sourceDir")
      assert(Files.isDirectory(Paths.get(source)), s"expected find a directory at $source, but couldn't find it!")
    }
  }
}
