package org.nlogo.models

import java.io.ByteArrayInputStream

import scala.sys.process.stringSeqToProcess
import scala.util.Try

class LegalInformationTests extends TestModels {

  testModels("The last line of the info tab should be a " +
    "well-formatted legal snippet inside an HTML comment") {
    for {
      model <- _
      error <- Try(model.legalInfo).failed.toOption
      if !error.isInstanceOf[UnsupportedOperationException]
    } yield model.quotedPath + "\n  " + error
  }

  testModels("The notarizer should work properly on all models") { models =>
    for {
      model <- models
      error <- Try(Notarizer.notarize(model)).failed.toOption
      if !error.isInstanceOf[UnsupportedOperationException]
    } yield model.quotedPath + "\n  " + error
  }

  testModels("Model file should be identical to output of Notarizer") { models =>
    for {
      model <- models
      notarizedModel <- Try(Notarizer.notarize(model)).toOption
      inputStream = new ByteArrayInputStream(notarizedModel.content.getBytes("UTF-8"))
      diffCommand = Seq("diff", "-u", "-", model.file.getPath)
      diffs = (diffCommand #< inputStream).lineStream_!.mkString("\n")
      if diffs.nonEmpty
    } yield diffs
  }

}
