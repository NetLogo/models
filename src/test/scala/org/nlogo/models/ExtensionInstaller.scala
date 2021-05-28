package org.nlogo.models

import org.nlogo.api.{ ExtensionManager, LibraryManager }
import org.nlogo.core.{ LibraryInfo, LibraryStatus, Model }

object ExtensionInstaller {

  private var hasRun: Boolean = false

  def apply(forceRun: Boolean = false): Unit = {
    if (hasRun && !forceRun) {
      return
    }
    hasRun = true

    val libraryManager = new LibraryManager(ExtensionManager.userExtensionsPath, () => {})
    libraryManager.reloadMetadata(isFirstLoad = false, useBundled = false)
    val extensionInfos = libraryManager.getExtensionInfos
    // We even install the extensions we can't or won't test just to avoid compile errors with them.
    // -Jeremy B May 2021
    val neededExtensionNames = Set("arduino", "array", "bitmap", "csv", "gis", "gogo", "ls", "matrix", "nw", "palette", "profiler", "py", "r", "rnd", "sound", "table", "time", "vid", "view2.5d")
    def isNeededExtension(extInfo: LibraryInfo): Boolean = {
      println(s"checking ${extInfo.codeName}")
      val isContained   = neededExtensionNames.contains(extInfo.codeName)
      val isInstallable = (extInfo.status == LibraryStatus.CanInstall || extInfo.status == LibraryStatus.CanUpdate)
      return isContained && isInstallable
    }

    val neededInfos = extensionInfos.filter(isNeededExtension)
    println(s"Found ${extensionInfos.size} extensions in the library, with ${neededInfos.size} of them needing updates.")
    neededInfos.foreach( (extInfo) => {
      val action = if (extInfo.status == LibraryStatus.CanInstall) { "Installing" } else { "Updating" }
      println(s"$action extension: ${extInfo.name} (${extInfo.codeName})")
      libraryManager.installExtension(extInfo)
      println(s"${extInfo.name} done.")
      Thread.sleep(2500)
    })
  }


  def main(args: Array[String]): Unit = {
    ExtensionInstaller(true)
    println("Complete")
  }

}
