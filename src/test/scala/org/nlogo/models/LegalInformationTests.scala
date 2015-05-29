package org.nlogo.models

import java.util.regex.Pattern.matches
import scala.util.Try
import scala.util.Failure
import java.util.Calendar

class LegalInformationTests extends TestModels {

  val format = """<!-- (\d\d\d\d)( \d\d\d\d)?(( \w+)*)( Cite: .*)? -->""".r

  case class LegalInfo(line: String) {
    val (year: Int, year2: Option[Int], keywords: List[String], cite: String) = {
      val format(y1, y2, keys, _, cite) = line
      (y1.toInt,
        if (y2 == null) None else Some(y2.trim.toInt),
        if (keys == null) List() else keys.split("""\s""").map(_.trim).filter(!_.isEmpty).toList,
        if (cite == null) "" else cite.drop(" Cite: ".size).toString)
    }
    private val currentYear = Calendar.getInstance().get(Calendar.YEAR)
    for (y <- year +: year2.toSeq)
      require(y >= 1996 && y <= currentYear, "invalid year: " + y)
  }

  testModels("The last line of the info tab should be a " +
    "well-formatted legal snippet inside an HTML comment") { models =>
    for {
      model <- models.take(2)
      lastInfoLine = model.info.lines.toSeq.last
      error <- Try(LegalInfo(lastInfoLine)).failed.toOption
      if !error.isInstanceOf[UnsupportedOperationException]
    } yield {
      model.quotedPath +
        "\n  " + error +
        "\n  Last info tab line was:\n  " + lastInfoLine
    }
  }

}

/*

(What follow is taken from `legal.txt`. It should probably be turned
into a wiki page at some point, but I'm storing it here while I'm
still working on the new way of doing things... -- NP 2015-05-28)

###
### HOW TO SPECIFY COPYRIGHTS
###
# Models that were included in 3.0 are being handled an old way;
# there's a newer way for models that are new for 3.1 and future
# releases.
#
# OLD (3.0 AND PRIOR) MODELS:
# The copyright year is just copied from whatever the model already
# said (unless it was obviously grossly wrong).  The idea is not
# to rock the boat, since the existing copyright years may already
# have been cited in various places.
#
# NEW (3.1 AND FUTURE) MODELS:
# At the time you add the model here, attach the current year.
#
# SPECIAL HANDLING FOR CONVERTED STARLOGOT MODELS:
# Models converted from StarLogoT need two years specified: the
# original's copyright year (which becomes the NetLogo version's
# copyright year as well) and the year of conversion.  To determine
# the year of conversion, follow the same rules given above for
# 3.0-and-before versus 3.1-and-after.
#
# OTHER OPTIONS:
# You can add one of the following keywords to cause a model to be
# handled specially:
#  - specialCE      in Code Examples directory, but gets normal copyright
#  - MIT            created at MIT, Resnick ref
#  - Steiner        Creative Commons license, includes code by James Steiner
#  - MAC            credit the MAC grant
#  - NIELS          copyright & cite info both include Pratim
#  - ConChem        include how-to-cite info for the curriculum
#  - Stroup         copyright & cite info both include Walter
#  - Wilensky       created at MIT, Wilensky ref
#  - Cite           should always appear last and be followed by a colon and the
#                   names of the collaborators <lastname>, <firstinitial>.
#                   It is ok to add multiple names in a single line; see Erosion
#                   for example.  Uri need not be included; he will be added
#                   automatically at the end.
#  - 3D             3D models that were directly converted from existing 2D models
#                   They should already have the same name as the 2D model with 3D
#                   attached to the end.
#
######################################################################
#
# CODE EXAMPLES
#
# notarize.scala automatically handles stuff in this directory
# differently (unless it has the specialCE keyword)
#
# HUBNET ACTIVITIES
#
# notarize.scala automatically handles HubNet specially
#
# Curricular models
#
# Most models in "Curricular models" are copied at release time
# from other directories.  These copyrights only affect the models
# that are directly committed to "Curricular models".
*/
