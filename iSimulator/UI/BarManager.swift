//
//  BarManager.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/17.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa
import SwiftUI

class BarManager {
  static let `default` = BarManager.init()
  private let queue = DispatchQueue(label: "iSimulator.update.queue")
  private let statusItem: NSStatusItem
  private let menu = NSMenu()
  private var watch: SKQueue?
  private var deviceInfoWatch: FileWatch?
  private var refreshTask: DispatchWorkItem?

  private init() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.image = #imageLiteral(resourceName: "statusItem_icon")
    statusItem.image?.isTemplate = true
    statusItem.menu = menu
    addWatch()
    refresh(immediate: true)
    self.commonItems.forEach({ (item) in
      self.menu.addItem(item)
    })
  }

  private func addWatch() {
    watch = SKQueue({ [weak self] (noti, _) in
      if noti.contains(.Write) && noti.contains(.SizeIncrease) {
        self?.refresh()
      }
    })
  }

  func refresh(immediate: Bool = false) {
    refreshTask?.cancel()
    let task = DispatchWorkItem { [weak self] in
      guard let `self` = self else { return }
      let deviceItems = self.deviceItems()
      DispatchQueue.main.async {
        self.menu.removeAllItems()
        deviceItems.forEach({ (item) in
          self.menu.addItem(item)
        })
        if deviceItems.isEmpty {
          let xcodeSelectItem = NSMenuItem(
            title: "Xcode Select...", action: #selector(self.preference(_:)), keyEquivalent: "")
          xcodeSelectItem.target = self
          self.menu.addItem(xcodeSelectItem)
        }
        self.menu.addItem(NSMenuItem.separator())
        self.commonItems.forEach({ (item) in
          self.menu.addItem(item)
        })
      }
    }
    self.refreshTask = task
    if immediate {
      self.queue.async(execute: task)
    } else {
      self.queue.asyncAfter(deadline: .now() + 0.75, execute: task)
    }
  }

  private func deviceItems() -> [NSMenuItem] {
    watch?.removeAllPaths()
    watch?.addPath(Device.url.path)  // 模拟器数量监控
    var deviceInfoURLPath: [String] = []  // 模拟器开关状态监控
    var items: [NSMenuItem] = []
    var hasAppDeviceItemDic: [String: [NSMenuItem]] = [:]
    var emptyAppDeviceItemDic: [String: [NSMenuItem]] = [:]
    TotalModel.default.update()

    TotalModel.default.runtimes.forEach { (r) in
      var hasAppDeviceItems: [NSMenuItem] = []
      var emptyAppDeviceItems: [NSMenuItem] = []
      let devices = r.devices
      devices.forEach({ (device) in
        deviceInfoURLPath.append(device.infoURL.path)
        self.watch?.addPath(device.dataURL.path)  // 模拟器App数量监控
        if FileManager.default.fileExists(atPath: device.bundleURL.path) {
          self.watch?.addPath(device.bundleURL.path)
        }
        let deviceItem = DeviceMenuItem(device)
        if deviceItem.hasApps {
          hasAppDeviceItems.append(deviceItem)
        } else {
          emptyAppDeviceItems.append(deviceItem)
        }
      })
      if !hasAppDeviceItems.isEmpty {
        let titleItem = NSMenuItem(title: r.name, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        hasAppDeviceItems.insert(titleItem, at: 0)
        hasAppDeviceItemDic[r.name] = hasAppDeviceItems
      }
      if !emptyAppDeviceItems.isEmpty {
        let titleItem = NSMenuItem(title: r.name, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        emptyAppDeviceItems.insert(titleItem, at: 0)
        emptyAppDeviceItemDic[r.name] = emptyAppDeviceItems
      }
    }
    DispatchQueue.main.async {
      self.deviceInfoWatch = try? FileWatch(
        paths: deviceInfoURLPath, createFlag: [.UseCFTypes, .FileEvents], runLoop: .current,
        latency: 1,
        eventHandler: { [weak self] (event) in
          if event.flag.contains(.ItemIsFile) && event.flag.contains(.ItemRenamed) {
            self?.refresh()
          }
        })
    }
    let sortKeys = hasAppDeviceItemDic.keys.sorted()
    var pinnedItems: [NSMenuItem] = []
    var pinnedAppItems: [NSMenuItem] = []

    TotalModel.default.runtimes.forEach { r in
      r.devices.forEach { device in
        if FavoritesManager.shared.isPinned(device: device) {
          let item = DeviceMenuItem(device)
          pinnedItems.append(item)
        }
        device.applications.forEach { app in
          if FavoritesManager.shared.isPinned(app: app) {
            let appItem = AppMenuItem(app)
            appItem.indentationLevel = 0
            appItem.refreshSizeAsync()
            pinnedAppItems.append(appItem)
          }
        }
      }
    }

    if !pinnedItems.isEmpty {
      let pinnedHeader = NSMenuItem(title: "⭐️ Pinned Simulators", action: nil, keyEquivalent: "")
      pinnedHeader.isEnabled = false
      items.append(pinnedHeader)
      items.append(contentsOf: pinnedItems)
      items.append(NSMenuItem.separator())
    }

    if !pinnedAppItems.isEmpty {
      let pinnedAppsHeader = NSMenuItem(title: "⭐️ Pinned Apps", action: nil, keyEquivalent: "")
      pinnedAppsHeader.isEnabled = false
      items.append(pinnedAppsHeader)
      items.append(contentsOf: pinnedAppItems)
      items.append(NSMenuItem.separator())
    }

    for key in sortKeys {
      items.append(contentsOf: hasAppDeviceItemDic[key]!)
    }
    let deviceTypeItem = DeviceTypeCreateItem()
    if !emptyAppDeviceItemDic.isEmpty && !deviceTypeItem.submenu!.items.isEmpty {
      items.append(NSMenuItem.separator())
    }
    if !emptyAppDeviceItemDic.isEmpty {
      let otherDeviceItem = NSMenuItem(title: "Other Simulators", action: nil, keyEquivalent: "")
      let submenu = NSMenu()
      otherDeviceItem.submenu = submenu
      let sortKeys = emptyAppDeviceItemDic.keys.sorted()
      for key in sortKeys {
        emptyAppDeviceItemDic[key]?.forEach({ (item) in
          submenu.addItem(item)
        })
      }
      items.append(otherDeviceItem)
    }

    if !deviceTypeItem.submenu!.items.isEmpty {
      items.append(deviceTypeItem)
    }
    return items
  }

  //MARK: - Common Items and Actions
  private lazy var commonItems: [NSMenuItem] = {
    var items: [NSMenuItem] = []
    let paletteMenu = NSMenuItem(
      title: "Command Palette...", action: #selector(openCommandPalette(_:)), keyEquivalent: "k")
    paletteMenu.target = self
    if #available(macOS 11.0, *) {
      paletteMenu.image = NSImage(
        systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
    }
    items.append(paletteMenu)
    items.append(NSMenuItem.separator())

    let preMenu = NSMenuItem(
      title: "Preferences...", action: #selector(preference(_:)), keyEquivalent: ",")
    preMenu.target = self
    items.append(preMenu)
    let cleanUnavailableMenu = NSMenuItem(
      title: "Delete Unavailable Simulators...", action: #selector(deleteUnavailableSimulators(_:)),
      keyEquivalent: "")
    cleanUnavailableMenu.target = self
    items.append(cleanUnavailableMenu)
    let refreshMenu = NSMenuItem(
      title: "Refresh", action: #selector(refresh(_:)), keyEquivalent: "r")
    refreshMenu.target = self
    items.append(refreshMenu)
    let quitMenu = NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q")
    quitMenu.target = self
    items.append(quitMenu)
    return items
  }()

  @objc private func openCommandPalette(_ sender: Any) {
    CommandPaletteWindowController.shared.show()
  }

  @objc private func refresh(_ sender: Any) {
    TotalModel.default.isForceUpdate = true
    self.refresh()
  }

  @objc private func deleteUnavailableSimulators(_ sender: Any) {
    let alert = NSAlert()
    alert.messageText = "Delete Unavailable Simulators?"
    alert.informativeText =
      "This will run 'xcrun simctl delete unavailable' to remove simulators whose runtimes are no longer installed."
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Delete")
    alert.addButton(withTitle: "Cancel")
    NSApp.activate(ignoringOtherApps: true)
    if alert.runModal() == .alertFirstButtonReturn {
      DispatchQueue.global(qos: .userInitiated).async {
        _ = shell("/usr/bin/xcrun", arguments: "simctl", "delete", "unavailable")
        TotalModel.default.isForceUpdate = true
        self.refresh()
        ToastManager.shared.showToast(
          message: "Deleted unavailable simulators", iconName: "trash.fill")
      }
    }
  }

  @objc private func quitApp(_ sender: Any) {
    NSApp.terminate(nil)
  }

  private var preferenceWindowController: NSWindowController?
  @objc private func preference(_ sender: NSMenuItem) {
    openPreferences(selectTab: sender.title == "Xcode Select..." ? "Xcode Select" : "General")
  }

  func openPreferences(selectTab: String = "General") {
    if let controller = preferenceWindowController {
      controller.close()
      preferenceWindowController = nil
    }
    if selectTab == "Xcode Select" {
      PreferencesWindowController.firstTabSelectIdentifier = "Xcode Select"
      preferenceWindowController =
        NSStoryboard.init(name: "Main", bundle: nil).instantiateController(
          withIdentifier: "Preferences") as? NSWindowController
    } else if #available(macOS 10.15, *) {
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 480, height: 280),
        styleMask: [.titled, .closable, .miniaturizable],
        backing: .buffered,
        defer: false
      )
      window.title = "Preferences"
      window.center()
      window.contentViewController = NSHostingController(rootView: PreferencesSwiftUIView())
      preferenceWindowController = NSWindowController(window: window)
    } else {
      PreferencesWindowController.firstTabSelectIdentifier = "General"
      preferenceWindowController =
        NSStoryboard.init(name: "Main", bundle: nil).instantiateController(
          withIdentifier: "Preferences") as? NSWindowController
    }
    NSApp.activate(ignoringOtherApps: true)
    preferenceWindowController?.window?.makeKeyAndOrderFront(NSApplication.shared)
  }
}
