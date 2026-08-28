import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: ""
  property string sourceDir: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
  property string managerPath: sourceDir ? sourceDir + "/scripts/manage.sh" : ""
  property bool installed: false

  function qmlColor(value) {
    return String(value || "")
  }

  function themeArguments(action) {
    return [
      "bash",
      root.managerPath,
      action,
      root.sourceDir,
      root.qmlColor(Color.menu.background),
      root.qmlColor(Color.menu.text),
      root.qmlColor(Color.menu.border),
      root.qmlColor(Color.menu.selectedBackground),
      root.qmlColor(Color.menu.selectedText),
      String(Style.font.menuFamily || "sans-serif")
    ]
  }

  function ensureInstalled() {
    if (!root.managerPath || installProcess.running) return
    installProcess.command = root.themeArguments("install")
    installProcess.running = true
  }

  function syncTheme() {
    if (!root.installed || !root.managerPath || themeProcess.running) return
    themeProcess.command = root.themeArguments("theme")
    themeProcess.running = true
  }

  onManifestChanged: Qt.callLater(root.ensureInstalled)

  Process {
    id: installProcess
    running: false
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector {
      id: installError
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.installed = exitCode === 0
      if (exitCode !== 0)
        console.warn("Quick Emoji setup failed:", installError.text)
    }
  }

  Process {
    id: themeProcess
    running: false
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector {
      id: themeError
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode !== 0)
        console.warn("Quick Emoji theme sync failed:", themeError.text)
    }
  }

  Timer {
    id: themeDebounce
    interval: 150
    repeat: false
    onTriggered: root.syncTheme()
  }

  Connections {
    target: Color.menu
    function onBackgroundChanged() { themeDebounce.restart() }
    function onTextChanged() { themeDebounce.restart() }
    function onBorderChanged() { themeDebounce.restart() }
    function onSelectedBackgroundChanged() { themeDebounce.restart() }
    function onSelectedTextChanged() { themeDebounce.restart() }
  }

  Connections {
    target: Style.font
    function onMenuFamilyChanged() { themeDebounce.restart() }
  }

  Component.onDestruction: {
    if (root.managerPath)
      Quickshell.execDetached(["bash", root.managerPath, "deactivate-if-disabled"])
  }
}
