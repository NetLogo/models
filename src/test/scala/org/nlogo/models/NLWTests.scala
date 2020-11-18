package org.nlogo.models

import org.nlogo.core.TokenType
import org.nlogo.core.TokenType.Command

class NLWTests extends TestModels {

   val unsupportedPrimitives = Set(
      // This is sort of a lie as of 2020-11-18
      // but we leave it for simplicity.
      "extensions",
      // Inspect in progress
      "inspect",

      "__set-line-thickness",

      // HubNet Prims
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

      // Synchrony Plagued
      "import-pcolors",
      "import-pcolors-rgb",
      "import-world",
      "display",
      "no-display",
      "wait",
      "user-one-of",
      "export-interface",

      // Ask Concurrent (s)
      "ask-concurrent",
      "without-interruption",

      // File
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
      "set-current-directory",
      "user-directory",
      "user-file",
      "user-new-file"
      )

  if (onLocal) {
     /* This is really just a placeholder for more advanced tests that
      * determine the viability of a library model for NLW. Right now,
      * we just check for prims that have yet to be implemented in
      * NLW. On run on local since it's not a helpful failure. Update these
      * occasionally from some authoritative source. I'v been using
      * https://github.com/NetLogo/Tortoise/wiki/Unimplemented-Primitives
      *
      * CB 2020-11-17.
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
