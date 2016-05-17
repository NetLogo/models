package org.nlogo.models

import java.io.ByteArrayInputStream

import scala.sys.process.stringSeqToProcess
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
    for {
      notarizedModel <- Try(Notarizer.notarize(model)).toOption
      inputStream = new ByteArrayInputStream(notarizedModel.getBytes("UTF-8"))
      diffCommand = Seq("diff", "-u", "-", model.file.getPath)
      diffs = (diffCommand #< inputStream).lineStream_!.mkString("\n")
      if diffs.nonEmpty
    } yield diffs
  }

}
