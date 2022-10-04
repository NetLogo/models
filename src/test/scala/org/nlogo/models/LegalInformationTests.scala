package org.nlogo.models

import java.io.ByteArrayInputStream

import difflib.DiffUtils

import scala.collection.JavaConverters._
import scala.io.Source
import scala.util.Try

class LegalInformationTests extends TestModels {

  testModels("The last line of the info tab should be a " +
    "well-formatted legal snippet inside an HTML comment") { model =>
    for {
      error <- Try(LegalInfo(model)).failed.toOption
      if !error.isInstanceOf[UnsupportedOperationException]
    } yield error
  }

  testModels("The notarizer should work properly on all models") { model =>
    for {
      error <- Try(Notarizer.notarize(model)).failed.toOption
      if !error.isInstanceOf[UnsupportedOperationException]
    } yield error
  }

  testModels("Model file should be identical to output of Notarizer") { model =>
    val savedLines = Source.fromFile(model.file.getPath).getLines.toSeq.asJava
    for {
      notarizedModel <- Try(Notarizer.notarize(model)).toOption
      patch = DiffUtils.diff(savedLines, notarizedModel.linesIterator.toSeq.asJava)
      if ! patch.getDeltas.isEmpty
    } yield DiffUtils.generateUnifiedDiff(model.file.getPath, model.file.getPath, savedLines, patch, 3).asScala.mkString("\n")
  }

}
