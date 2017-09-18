package org.nlogo.models

import org.nlogo.core.TokenType
import org.nlogo.core.TokenType.Command

class NLWTests extends TestModels {

   val unsupportedPrimitives = Set(
      "extensions",
      "diffuse4",
      "export-all-plots",
      "export-plot",
      "export-view",
      "inspect",
      "read-from-string",
      "run",
      "runresult",
      "display",
      "export-interface",
      "export-world",
      "import-drawing",
      "import-pcolors",
      "import-pcolors-rgb",
      "import-world",
      "no-display",
      "user-one-of",
      "wait",
      "without-interruption",
      "ask-concurrent",
      "beep",
      "file-at-end?",
      "file-close",
      "file-close-all",
      "file-delete",
      "file-exists?",
      "file-flush",
      "file-open",
      "file-print",
      "file-read",
      "file-read-characters",
      "file-read-line",
      "file-show",
      "file-type",
      "file-write",
      "hubnet-broadcast",
      "hubnet-broadcast-clear-output",
      "hubnet-broadcast-message",
      "hubnet-clear-override",
      "hubnet-clear-overrides",
      "hubnet-clients-list",
      "hubnet-enter-message?",
      "hubnet-exit-message?",
      "hubnet-fetch-message",
      "hubnet-kick-all-clients",
      "hubnet-kick-client",
      "hubnet-message",
      "hubnet-message-source",
      "hubnet-message-tag",
      "hubnet-message-waiting?",
      "hubnet-reset",
      "hubnet-reset-perspective",
      "hubnet-send",
      "hubnet-send-clear-output",
      "hubnet-send-follow",
      "hubnet-send-message",
      "hubnet-send-override",
      "hubnet-send-watch",
      "set-current-directory",
      "__set-line-thickness",
      "user-directory",
      "user-file",
      "user-new-file")

  if (!onTravis) {
     /* This is really just a placeholder for more advanced tests that
      * determine the viability of a library model for NLW. Right now,
      * we just check for prims that have yet to be implemented in
      * NLW.
      * CB 2017-09-01.
      */
     testModels("All primitives are supported by NLW") { model =>
       val tokenNames = new Tokens(model).primitiveTokenNames.toSet
       for {
         prim <- unsupportedPrimitives
         if tokenNames.contains(prim)
       } yield "uses " + prim
     }
  }
}
