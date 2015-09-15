package org.nlogo

import org.nlogo.headless.HeadlessWorkspace

package object models {
  def withWorkspace[A](model: Model)(f: HeadlessWorkspace => A) = {
    val workspace = HeadlessWorkspace.newInstance
    try {
      workspace.compilerTestingMode = true
      workspace.silent = true
      // open the model from path instead of content string so that
      // the current directory gets set (necessary for `__includes`)
      workspace.open(model.file.getCanonicalPath)
      f(workspace)
    } finally workspace.dispose()
  }

  implicit class RicherString(s: String) {
    def indent(spaces: Int): String =
      s.lines.map((" " * spaces) + _).mkString("\n")
  }
}
