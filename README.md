# NetLogo Models Library

## Bundling

The NetLogo Models Library is bundled with NetLogo.  You can download NetLogo and the Models Library from http://ccl.northwestern.edu/netlogo/.

## NetLogo Version Changes

When the NetLogo version is bumped, a few changes are required:

- Update the version in `build.sbt`
- Update the expected version in `VersionTests.scala`
- Resave the models using the `runMain org.nlogo.models.ModelsResaver` sbt command.

## Licenses

The models in this repository are provided under a variety of licenses.

Some models are public domain, some models are open source, some models are [CC BY-NC-SA](http://creativecommons.org/licenses/by-nc-sa/3.0/) (free for noncommercial distribution and use).

See each model's Info tab for details.
