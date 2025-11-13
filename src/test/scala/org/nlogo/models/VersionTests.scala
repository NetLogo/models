package org.nlogo.models

import java.io.File

import scala.util.Try

import org.nlogo.api.Version

class VersionTests extends TestModels {

  // Turn both failures from reading the model into a case class
  // and the failures from reading the model file content into
  // a single sequence of pairs. Not the most elegant, but eh...
  // NP 2016-05-16
  def allModelFailures: Iterable[(File, Throwable)] =
    modelTries.flatMap {
      case (file, modelTry, contentTry) =>
        def failureSeq = (_: Try[?]).failed.toOption.toSeq.map(file -> _)
        failureSeq(modelTry) ++ failureSeq(contentTry)
    }

  test("All models are readable") {
    if (allModelFailures.nonEmpty) fail(
      "The following models failed:" +
        allModelFailures.map { case (f, e) => "  \"" + f.getCanonicalPath + "\"" }.mkString("\n") +
        "Details:\n" +
        allModelFailures.map {
          case (f, e) =>
            "\"" + f.getCanonicalPath + "\"\n" +
              e + "\n" +
              e.getStackTrace.mkString("\n")
        }.mkString("\n\n")
    )
  }

  testModels(s"Version should be ${Version.version}") { model =>
    Option(model.version.trim).filter(_ != Version.version)
  }
}
