package org.nlogo.models

import org.nlogo.core.{ LibraryInfo, LibraryStatus, Model }
import org.nlogo.headless.HeadlessWorkspace

object ExtensionInstaller {

  private var hasRun: Boolean = false

  def apply(forceRun: Boolean = false): Unit = {
    if (hasRun && !forceRun) {
      return
    }
    hasRun = true

    val workspace      = HeadlessWorkspace.newInstance
    val libraryManager = workspace.getLibraryManager
    libraryManager.reloadMetadata(isFirstLoad = false, useBundled = false)

    val extensionInfos       = libraryManager.getExtensionInfos
    val neededExtensionNames = Set("bitmap", "csv", "gis", "ls", "matrix", "nw", "palette", "py", "rnd", "table", "time", "vid")
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
      Thread.sleep(2500)
    })
  }


  def main(args: Array[String]): Unit = {
    ExtensionInstaller(true)
    println("Complete")
    System.exit(0)
  }

}
