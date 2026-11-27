//
//  ActionMenu.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/24.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

//  FileInfo DirectoryWatcher CancelBlocks

import Cocoa

class AppMenu: NSMenu, NSMenuDelegate {

  let app: Application
  private var isPopulated = false

  init(_ app: Application) {
    self.app = app
    super.init(title: "")
    self.delegate = self
  }

  required init(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    guard !isPopulated else { return }
    isPopulated = true
    addCustomItem()
  }

  private func addCustomItem() {
    let actionTypes: [AppActionable.Type] = [
      AppPinAction.self,
      AppShowInFinderAction.self,
      AppCopyBundleIDAction.self,
      AppCopySandboxPathAction.self,
      AppLaunchAction.self,
      AppSendPushAction.self,
      AppResetAction.self,
      AppTerminateAction.self,
      AppUninstallAction.self,
    ]
    actionTypes.forEach { (ActionType) in
      let action = ActionType.init(app)
      if !action.isAvailable {
        return
      }
      let item = NSMenuItem.init(
        title: action.title, action: #selector(AppShowInFinderAction.perform), keyEquivalent: "")
      item.target = action as AnyObject
      item.image = action.icon
      item.representedObject = action
      self.addItem(item)
    }
    self.insertItem(createOtherSimLunchAppItem(), at: 2)
    self.addItem(createSnapshotMenuItem())
    self.addItem(createPrivacyMenuItem())
    if let item = createDatabaseInspectorItem() {
      self.addItem(item)
    }
    if let item = createPreferencesInspectorItem() {
      self.addItem(item)
    }
    self.addItem(NSMenuItem.separator())
    let infoItem = NSMenuItem()
    infoItem.view = AppInfoView(application: app)
    self.addItem(infoItem)
  }

  func createOtherSimLunchAppItem() -> NSMenuItem {
    let otherSimLunchAppItem = NSMenuItem.init(
      title: "Launch From Other Simulator", action: nil, keyEquivalent: "")
    let submenu = NSMenu()
    let runtimes: [Runtime] = TotalModel.default.runtimes(osType: app.device.runtime.osType)
    var appDeviceItemDic: [String: [NSMenuItem]] = [:]
    runtimes.forEach { (r) in
      var appDeviceItems: [NSMenuItem] = []
      r.devices.forEach({ (device) in
        if device === app.device {
          return
        }
        let action = DeviceLaunchOtherAppAction.init(app: app, device: device)
        let item = NSMenuItem.init(
          title: device.name, action: #selector(action.perform), keyEquivalent: "")
        item.target = action as AnyObject
        item.representedObject = action
        appDeviceItems.append(item)
      })
      if !appDeviceItems.isEmpty {
        let titleItem = NSMenuItem(title: r.name, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        appDeviceItems.insert(titleItem, at: 0)
        appDeviceItemDic[r.name] = appDeviceItems
      }
    }
    appDeviceItemDic.forEach { (_, deviceItems) in
      deviceItems.forEach({ (item) in
        submenu.addItem(item)
      })
    }
    otherSimLunchAppItem.submenu = submenu
    return otherSimLunchAppItem
  }

  func createSnapshotMenuItem() -> NSMenuItem {
    let item = NSMenuItem(title: "Sandbox Snapshots", action: nil, keyEquivalent: "")
    let submenu = NSMenu()

    let saveAction = AppSaveSnapshotAction(app)
    let saveItem = NSMenuItem(
      title: saveAction.title, action: #selector(AppSaveSnapshotAction.perform), keyEquivalent: "")
    saveItem.target = saveAction as AnyObject
    saveItem.representedObject = saveAction
    submenu.addItem(saveItem)

    let snapshots = app.listSnapshots()
    if !snapshots.isEmpty {
      submenu.addItem(NSMenuItem.separator())

      let restoreItem = NSMenuItem(title: "Restore Snapshot", action: nil, keyEquivalent: "")
      let restoreSubmenu = NSMenu()
      snapshots.forEach { name in
        let action = AppRestoreSnapshotAction(app: app, snapshotName: name)
        let menuItem = NSMenuItem(
          title: name, action: #selector(AppRestoreSnapshotAction.perform), keyEquivalent: "")
        menuItem.target = action as AnyObject
        menuItem.representedObject = action
        restoreSubmenu.addItem(menuItem)
      }
      restoreItem.submenu = restoreSubmenu
      submenu.addItem(restoreItem)

      let deleteItem = NSMenuItem(title: "Delete Snapshot", action: nil, keyEquivalent: "")
      let deleteSubmenu = NSMenu()
      snapshots.forEach { name in
        let action = AppDeleteSnapshotAction(app: app, snapshotName: name)
        let menuItem = NSMenuItem(
          title: name, action: #selector(AppDeleteSnapshotAction.perform), keyEquivalent: "")
        menuItem.target = action as AnyObject
        menuItem.representedObject = action
        deleteSubmenu.addItem(menuItem)
      }
      deleteItem.submenu = deleteSubmenu
      submenu.addItem(deleteItem)
    }

    item.submenu = submenu
    return item
  }

  func createDatabaseInspectorItem() -> NSMenuItem? {
    let all = FileManager.default.enumerator(
      at: app.sandboxDirUrl, includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles, .skipsPackageDescendants])
    var dbFilePaths: [String] = []
    let validExtensions = ["sqlite", "db", "storedata", "realm"]
    while let fileUrl = all?.nextObject() as? URL {
      if validExtensions.contains(fileUrl.pathExtension.lowercased()) {
        dbFilePaths.append(fileUrl.path)
      }
    }
    guard !dbFilePaths.isEmpty else { return nil }

    if dbFilePaths.count == 1 {
      let path = dbFilePaths[0]
      let filename = URL(fileURLWithPath: path).lastPathComponent
      let action = AppFileOpenAction(title: "Open Database (\(filename))", path: path)
      let item = NSMenuItem(
        title: action.title, action: #selector(AppFileOpenAction.perform), keyEquivalent: "")
      item.target = action as AnyObject
      item.representedObject = action
      return item
    } else {
      let item = NSMenuItem(title: "Open Database", action: nil, keyEquivalent: "")
      let submenu = NSMenu()
      dbFilePaths.forEach { path in
        let filename = URL(fileURLWithPath: path).lastPathComponent
        let action = AppFileOpenAction(title: filename, path: path)
        let menuItem = NSMenuItem(
          title: action.title, action: #selector(AppFileOpenAction.perform), keyEquivalent: "")
        menuItem.target = action as AnyObject
        menuItem.representedObject = action
        submenu.addItem(menuItem)
      }
      item.submenu = submenu
      return item
    }
  }

  func createPreferencesInspectorItem() -> NSMenuItem? {
    let prefsDir = app.sandboxDirUrl.appendingPathComponent("Library/Preferences")
    guard
      let contents = try? FileManager.default.contentsOfDirectory(
        at: prefsDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
    else {
      return nil
    }
    let plistFiles = contents.filter { $0.pathExtension.lowercased() == "plist" }
    guard !plistFiles.isEmpty else { return nil }

    let item = NSMenuItem(title: "Preferences (.plist)", action: nil, keyEquivalent: "")
    let submenu = NSMenu()
    plistFiles.forEach { fileURL in
      let plistMenuItem = NSMenuItem(
        title: fileURL.lastPathComponent, action: nil, keyEquivalent: "")
      let plistSubmenu = NSMenu()

      let inspectAction = AppInspectPlistAction(
        title: fileURL.lastPathComponent, path: fileURL.path)
      let inspectItem = NSMenuItem(
        title: "Inspect in iSimulator", action: #selector(AppInspectPlistAction.perform),
        keyEquivalent: "")
      inspectItem.target = inspectAction as AnyObject
      inspectItem.representedObject = inspectAction
      plistSubmenu.addItem(inspectItem)

      let openAction = AppFileOpenAction(title: "Open External Editor", path: fileURL.path)
      let openItem = NSMenuItem(
        title: openAction.title, action: #selector(AppFileOpenAction.perform), keyEquivalent: "")
      openItem.target = openAction as AnyObject
      openItem.representedObject = openAction
      plistSubmenu.addItem(openItem)

      plistMenuItem.submenu = plistSubmenu
      submenu.addItem(plistMenuItem)
    }
    item.submenu = submenu
    return item
  }

  func createPrivacyMenuItem() -> NSMenuItem {
    let item = NSMenuItem(title: "Privacy & Permissions", action: nil, keyEquivalent: "")
    let submenu = NSMenu()

    let grantAllAction = AppPrivacyAction(app: app, service: .all, action: .grant)
    let grantAllItem = NSMenuItem(
      title: "Grant All Permissions", action: #selector(AppPrivacyAction.perform), keyEquivalent: ""
    )
    grantAllItem.target = grantAllAction as AnyObject
    grantAllItem.representedObject = grantAllAction
    submenu.addItem(grantAllItem)

    let denyAllAction = AppPrivacyAction(app: app, service: .all, action: .deny)
    let denyAllItem = NSMenuItem(
      title: "Deny All Permissions", action: #selector(AppPrivacyAction.perform), keyEquivalent: "")
    denyAllItem.target = denyAllAction as AnyObject
    denyAllItem.representedObject = denyAllAction
    submenu.addItem(denyAllItem)

    let resetAllAction = AppPrivacyAction(app: app, service: .all, action: .reset)
    let resetAllItem = NSMenuItem(
      title: "Reset All Permissions", action: #selector(AppPrivacyAction.perform), keyEquivalent: ""
    )
    resetAllItem.target = resetAllAction as AnyObject
    resetAllItem.representedObject = resetAllAction
    submenu.addItem(resetAllItem)

    submenu.addItem(NSMenuItem.separator())

    let services: [Application.PrivacyService] = [
      .camera, .photos, .contacts, .microphone, .location, .calendar, .reminders,
    ]
    services.forEach { service in
      let serviceItem = NSMenuItem(title: service.displayName, action: nil, keyEquivalent: "")
      let serviceSubmenu = NSMenu()

      let actions: [Application.PrivacyAction] = [.grant, .deny, .reset]
      actions.forEach { act in
        let privacyAction = AppPrivacyAction(app: app, service: service, action: act)
        let menuItem = NSMenuItem(
          title: act.displayName, action: #selector(AppPrivacyAction.perform), keyEquivalent: "")
        menuItem.target = privacyAction as AnyObject
        menuItem.representedObject = privacyAction
        serviceSubmenu.addItem(menuItem)
      }

      serviceItem.submenu = serviceSubmenu
      submenu.addItem(serviceItem)
    }

    item.submenu = submenu
    return item
  }

  func createRealmAppItem() -> NSMenuItem? {
    let all = FileManager.default.enumerator(
      at: app.sandboxDirUrl, includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles, .skipsPackageDescendants])
    var realmFilePaths: [String] = []
    while let fileUrl = all?.nextObject() as? URL {
      if fileUrl.pathExtension.lowercased() == "realm" {
        realmFilePaths.append(fileUrl.path)
      }
    }
    guard !realmFilePaths.isEmpty else {
      return nil
    }
    if realmFilePaths.count == 1 {
      let action = AppRealmAction.init("Open Realm Database", path: realmFilePaths[0])
      let item = NSMenuItem.init(
        title: action.title, action: #selector(action.perform), keyEquivalent: "")
      item.target = action as AnyObject
      item.image = action.icon
      item.representedObject = action
      return item
    } else {
      let item = NSMenuItem.init(title: "Open Realm Database", action: nil, keyEquivalent: "")
      item.image = #imageLiteral(resourceName: "realmAppActionIcon")
      let submenu = NSMenu()
      realmFilePaths.forEach { (path) in
        let action = AppRealmAction.init(
          URL.init(fileURLWithPath: path).lastPathComponent, path: path)
        let item = NSMenuItem.init(
          title: action.title, action: #selector(action.perform), keyEquivalent: "")
        item.target = action as AnyObject
        item.representedObject = action
        submenu.addItem(item)
      }
      item.submenu = submenu
      return item
    }
  }
}

protocol AppActionable {
  init(_ app: Application)
  var app: Application { set get }
  var title: String { get }
  var icon: NSImage? { get }
  var isAvailable: Bool { get }
  func perform()
}

class AppPinAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String {
    return FavoritesManager.shared.isPinned(app: app) ? "Unpin App" : "Pin App to Top"
  }
  var isAvailable: Bool = true
  var icon: NSImage? {
    if #available(macOS 11.0, *) {
      let isPinned = FavoritesManager.shared.isPinned(app: app)
      return NSImage(
        systemSymbolName: isPinned ? "star.slash" : "star.fill", accessibilityDescription: nil)
    }
    return nil
  }

  @objc func perform() {
    FavoritesManager.shared.togglePin(app: app)
  }
}

class AppShowInFinderAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String = "Show in Finder"
  @objc func perform() {
    if let url = app.linkURL {
      NSWorkspace.shared.open(url)
    }
  }
  var isAvailable: Bool = true
  var icon: NSImage?
}

class DeviceLaunchOtherAppAction: AppActionable {
  required init(_ app: Application) {
    fatalError("init(coder:) has not been implemented")
  }
  var app: Application
  var device: Device
  var title: String
  required init(app: Application, device: Device) {
    self.app = app
    self.device = device
    self.title = device.name
  }
  @objc func perform() {
    device.installApp(app)
    device.launch(appBundleId: app.bundleID)
  }
  var isAvailable: Bool = true
  var icon: NSImage?
}

class AppCopyBundleIDAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String = "Copy Bundle ID"
  var isAvailable: Bool = true
  var icon: NSImage? {
    if #available(macOS 11.0, *) {
      return NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
    }
    return nil
  }
  @objc func perform() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(app.bundleID, forType: .string)
    ToastManager.shared.showToast(
      message: "Copied Bundle ID: \(app.bundleID)", iconName: "doc.on.doc.fill")
  }
}

class AppCopySandboxPathAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String = "Copy Sandbox Path"
  var isAvailable: Bool = true
  var icon: NSImage? {
    if #available(macOS 11.0, *) {
      return NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
    }
    return nil
  }
  @objc func perform() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(app.sandboxDirUrl.path, forType: .string)
    ToastManager.shared.showToast(message: "Copied Sandbox Path", iconName: "folder.fill")
  }
}

class AppLaunchAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String = "Launch"
  @objc func perform() {
    let targetApp = app
    DispatchQueue.global(qos: .userInitiated).async {
      targetApp.launch()
      ToastManager.shared.showToast(
        message: "Launched \(targetApp.bundleDisplayName)", iconName: "play.fill")
    }
  }
  var isAvailable: Bool = true
  var icon: NSImage?
}

class AppTerminateAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String = "Terminate"
  @objc func perform() {
    let targetApp = app
    DispatchQueue.global(qos: .userInitiated).async {
      targetApp.terminate()
      ToastManager.shared.showToast(
        message: "Terminated \(targetApp.bundleDisplayName)", iconName: "stop.fill")
    }
  }
  var isAvailable: Bool {
    return app.device.state == .booted
  }
  var icon: NSImage?
}

class AppResetAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String = "Reset Content..."
  @objc func perform() {
    let alert: NSAlert = NSAlert()
    alert.messageText = String(
      format: "Are you sure you want to Reset Content %@ from %@?", app.bundleDisplayName,
      app.device.name)
    alert.informativeText = "All of sandbox data in this application will be remove."
    alert.alertStyle = .critical
    alert.addButton(withTitle: "Reset")
    alert.addButton(withTitle: "Cancel")
    NSApp.activate(ignoringOtherApps: true)
    let response = alert.runModal()
    if response == NSApplication.ModalResponse.alertFirstButtonReturn {
      app.resetContent()
    }

  }
  var isAvailable: Bool {
    return true
  }
  var icon: NSImage?
}

class AppUninstallAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String = "Delete App..."
  @objc func perform() {
    let alert: NSAlert = NSAlert()
    alert.messageText = String(
      format: "Are you sure you want to delete %@ from %@?", app.bundleDisplayName,
      app.device.name)
    alert.informativeText = "All of data (sandbox/bundle) in this application will be deleted."
    alert.alertStyle = .critical
    alert.addButton(withTitle: "Delete")
    alert.addButton(withTitle: "Cancel")
    NSApp.activate(ignoringOtherApps: true)
    let response = alert.runModal()
    if response == NSApplication.ModalResponse.alertFirstButtonReturn {
      let targetApp = app
      DispatchQueue.global(qos: .userInitiated).async {
        targetApp.uninstall()
        TotalModel.default.isForceUpdate = true
        BarManager.default.refresh(immediate: true)
        ToastManager.shared.showToast(
          message: "Deleted \(targetApp.bundleDisplayName)", iconName: "trash.fill")
      }
    }

  }
  var isAvailable: Bool = true
  var icon: NSImage? {
    if #available(macOS 11.0, *) {
      return NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
    }
    return nil
  }
}

protocol AppActionableExt: AppActionable {
  var appBundleIdentifier: String { get }
}

extension AppActionableExt {

  var appPath: String? {
    return self.path(forBundleIdentifier: appBundleIdentifier)
  }

  var icon: NSImage? {
    if let path = appPath {
      let image = NSWorkspace.shared.icon(forFile: path)
      image.size = NSSize(width: 16, height: 16)
      return image
    }
    return nil
  }

  var isAvailable: Bool {
    return appPath != nil
  }

  func path(forBundleIdentifier bundleIdentifier: String) -> String? {
    return NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: bundleIdentifier)
  }

}

class AppRealmAction {

  var icon: NSImage? {
    return #imageLiteral(resourceName: "realmAppActionIcon")
  }
  let title: String
  let realmPath: String

  init(_ title: String, path: String) {
    self.title = title
    self.realmPath = path
  }

  @objc func perform() {
    NSWorkspace.shared.openFile(realmPath)
  }
}

class AppFileOpenAction {
  let title: String
  let path: String

  init(title: String, path: String) {
    self.title = title
    self.path = path
  }

  @objc func perform() {
    NSWorkspace.shared.openFile(path)
  }
}

class AppInspectPlistAction {
  let title: String
  let path: String

  init(title: String, path: String) {
    self.title = title
    self.path = path
  }

  @objc func perform() {
    if #available(macOS 10.15, *) {
      PlistInspectorWindowController.show(title: title, plistPath: path)
    } else {
      NSWorkspace.shared.openFile(path)
    }
  }
}

class AppSendPushAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String = "Send Push Notification (.apns)..."
  var isAvailable: Bool = true
  var icon: NSImage?

  @objc func perform() {
    let openPanel = NSOpenPanel()
    openPanel.title = "Select APNS or JSON Payload File"
    openPanel.allowedFileTypes = ["apns", "json"]
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = false

    NSApp.activate(ignoringOtherApps: true)
    openPanel.begin { response in
      if response == .OK, let url = openPanel.url {
        let targetApp = self.app
        DispatchQueue.global(qos: .userInitiated).async {
          targetApp.sendPushNotification(payloadURL: url)
          ToastManager.shared.showToast(
            message: "Sent push to \(targetApp.bundleDisplayName)", iconName: "bell.fill")
        }
      }
    }
  }
}

class AppSaveSnapshotAction: AppActionable {
  var app: Application
  required init(_ app: Application) {
    self.app = app
  }
  var title: String = "Save Sandbox Snapshot..."
  var isAvailable: Bool = true
  var icon: NSImage?

  @objc func perform() {
    let alert = NSAlert()
    alert.messageText = "Save Sandbox Snapshot"
    alert.informativeText = "Enter a name for this snapshot of '\(app.bundleDisplayName)':"

    let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
    inputTextField.placeholderString = "e.g. Logged In State"
    alert.accessoryView = inputTextField
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Cancel")

    NSApp.activate(ignoringOtherApps: true)
    DispatchQueue.main.async {
      alert.window.makeFirstResponder(inputTextField)
    }
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
      let name = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
      if !name.isEmpty {
        let targetApp = app
        DispatchQueue.global(qos: .userInitiated).async {
          targetApp.saveSnapshot(named: name)
          ToastManager.shared.showToast(
            message: "Saved snapshot '\(name)'", iconName: "archivebox.fill")
        }
      }
    }
  }
}

class AppRestoreSnapshotAction {
  let app: Application
  let snapshotName: String

  init(app: Application, snapshotName: String) {
    self.app = app
    self.snapshotName = snapshotName
  }

  @objc func perform() {
    let alert = NSAlert()
    alert.messageText = "Restore Sandbox Snapshot"
    alert.informativeText =
      "Are you sure you want to restore '\(snapshotName)'? Current sandbox data will be replaced."
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Restore")
    alert.addButton(withTitle: "Cancel")

    NSApp.activate(ignoringOtherApps: true)
    if alert.runModal() == .alertFirstButtonReturn {
      let targetApp = app
      let name = snapshotName
      DispatchQueue.global(qos: .userInitiated).async {
        targetApp.restoreSnapshot(named: name)
        ToastManager.shared.showToast(
          message: "Restored snapshot '\(name)'", iconName: "arrow.counterclockwise")
      }
    }
  }
}

class AppDeleteSnapshotAction {
  let app: Application
  let snapshotName: String

  init(app: Application, snapshotName: String) {
    self.app = app
    self.snapshotName = snapshotName
  }

  @objc func perform() {
    let alert = NSAlert()
    alert.messageText = "Delete Snapshot"
    alert.informativeText = "Are you sure you want to delete snapshot '\(snapshotName)'?"
    alert.alertStyle = .critical
    alert.addButton(withTitle: "Delete")
    alert.addButton(withTitle: "Cancel")

    NSApp.activate(ignoringOtherApps: true)
    if alert.runModal() == .alertFirstButtonReturn {
      app.deleteSnapshot(named: snapshotName)
    }
  }
}

final class AppInfoView: NSView {

  var application: Application
  var textField: NSTextField!

  static let width: CGFloat = 250
  static let edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 5, right: 0)
  static let leftMargin: CGFloat = 20

  init(application: Application) {
    self.application = application
    super.init(frame: NSRect.zero)

    setupViews()
    update(sandboxSize: 0, bundleSize: 0)

    let size = textField.sizeThatFits(NSSize(width: CGFloat.infinity, height: CGFloat.infinity))
    textField.frame = NSRect(
      x: AppInfoView.leftMargin, y: AppInfoView.edgeInsets.bottom,
      width: AppInfoView.width - AppInfoView.edgeInsets.left, height: size.height)
    frame = NSRect(
      x: 0, y: 0, width: AppInfoView.width, height: size.height + AppInfoView.edgeInsets.bottom)

    application.size { (sandboxSize, bundleSize) in
      self.update(sandboxSize: sandboxSize, bundleSize: bundleSize)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    textField = NSTextField(frame: NSRect(x: 20, y: 0, width: 230, height: 100))
    textField.isBezeled = false
    textField.drawsBackground = false
    textField.isEditable = false
    textField.isSelectable = false
    textField.cell?.wraps = false
    textField.textColor = NSColor.disabledControlTextColor
    addSubview(textField)
  }

  private func update(sandboxSize: UInt64, bundleSize: UInt64) {
    var sandboxSizeDes = "---"
    var bundleSizeDes = "---"
    if sandboxSize != 0 {
      sandboxSizeDes = ByteCountFormatter.string(
        fromByteCount: Int64(sandboxSize), countStyle: .file)
    }
    if bundleSize != 0 {
      bundleSizeDes = ByteCountFormatter.string(fromByteCount: Int64(bundleSize), countStyle: .file)
    }
    let string =
      "\(application.bundleID)\n"
      + "Version: \(application.bundleVersion) (\(application.bundleShortVersion))\n"
      + "SandboxSize: \(sandboxSizeDes)\n" + "BundleSize: \(bundleSizeDes)"

    textField.stringValue = string
  }

}

class AppPrivacyAction {
  let app: Application
  let service: Application.PrivacyService
  let action: Application.PrivacyAction

  init(app: Application, service: Application.PrivacyService, action: Application.PrivacyAction) {
    self.app = app
    self.service = service
    self.action = action
  }

  @objc func perform() {
    let targetApp = app
    let targetService = service
    let targetAction = action
    DispatchQueue.global(qos: .userInitiated).async {
      targetApp.setPrivacy(service: targetService, action: targetAction)
      ToastManager.shared.showToast(
        message:
          "\(targetAction.displayName) \(targetService.displayName) for \(targetApp.bundleDisplayName)",
        iconName: "hand.raised.fill"
      )
    }
  }
}
