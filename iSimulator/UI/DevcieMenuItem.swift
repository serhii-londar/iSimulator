//
//  DevcieMenuItem.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/11/10.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

class DeviceMenuItem: NSMenuItem {
    let device: Device
    let hasApps: Bool
    init(_ device: Device) {
        self.device = device
        hasApps = !device.applications.isEmpty
        super.init(title: device.name, action: nil, keyEquivalent: "")
        self.onStateImage = NSImage.init(named: NSImage.statusAvailableName)
        self.offStateImage = nil
        self.state = device.state == .shutdown ? .off : .on
        self.submenu = NSMenu()
        if !device.applications.isEmpty {
            self.submenu?.addItem(NSMenuItem.init(title: "Application", action: nil, keyEquivalent: ""))
            device.applications.forEach({ (app) in
                self.submenu?.addItem(AppMenuItem(app))
            })
            self.submenu?.addItem(NSMenuItem.separator())
        }
        let deviceActionItems = createDeviceActionItems(device)
        deviceActionItems.forEach({ (item) in
            self.submenu?.addItem(item)
        })
        if !device.pairs.isEmpty{
            self.submenu?.addItem(NSMenuItem.separator())
            pairActionItems(device).forEach({ (item) in
                self.submenu?.addItem(item)
            })
        }
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(cowder:) has not been implemented")
    }
    
}

private func createDeviceActionItems(_ device: Device) -> [NSMenuItem] {
    let actionTypes: [DeviceActionable.Type] = [DeviceStateAction.self,
                                                DeviceUnpairAction.self,
                                                DeviceEraseAction.self,
                                                DeviceDeleteAction.self]
    let actions = actionTypes.map { $0.init(device) }.filter { $0.isAvailable  }
    var items = actions.map { (action) -> NSMenuItem in
        let item = NSMenuItem.init(title: action.title, action: #selector(DeviceStateAction.perform), keyEquivalent: "")
        item.indentationLevel = 1
        item.target = action as AnyObject
        item.image = action.icon
        item.representedObject = action
        return item
    }
    
    let openUrlAction = DeviceOpenURLAction(device)
    let openUrlItem = NSMenuItem(title: openUrlAction.title, action: #selector(DeviceOpenURLAction.perform), keyEquivalent: "")
    openUrlItem.indentationLevel = 1
    openUrlItem.target = openUrlAction as AnyObject
    openUrlItem.representedObject = openUrlAction
    items.insert(openUrlItem, at: 1)

    if device.state == .booted {
        let appearanceItem = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        appearanceItem.indentationLevel = 1
        let appearanceSubmenu = NSMenu()
        
        let lightAction = DeviceAppearanceAction(device: device, appearance: .light)
        let lightItem = NSMenuItem(title: lightAction.title, action: #selector(DeviceAppearanceAction.perform), keyEquivalent: "")
        lightItem.target = lightAction as AnyObject
        lightItem.representedObject = lightAction
        appearanceSubmenu.addItem(lightItem)
        
        let darkAction = DeviceAppearanceAction(device: device, appearance: .dark)
        let darkItem = NSMenuItem(title: darkAction.title, action: #selector(DeviceAppearanceAction.perform), keyEquivalent: "")
        darkItem.target = darkAction as AnyObject
        darkItem.representedObject = darkAction
        appearanceSubmenu.addItem(darkItem)
        
        appearanceItem.submenu = appearanceSubmenu
        items.insert(appearanceItem, at: 2)

        let statusBarItem = NSMenuItem(title: "Status Bar", action: nil, keyEquivalent: "")
        statusBarItem.indentationLevel = 1
        let statusBarSubmenu = NSMenu()

        let setStatusAction = DeviceStatusBarAction(device: device, isOverride: true)
        let setStatusItem = NSMenuItem(title: setStatusAction.title, action: #selector(DeviceStatusBarAction.perform), keyEquivalent: "")
        setStatusItem.target = setStatusAction as AnyObject
        setStatusItem.representedObject = setStatusAction
        statusBarSubmenu.addItem(setStatusItem)

        let clearStatusAction = DeviceStatusBarAction(device: device, isOverride: false)
        let clearStatusItem = NSMenuItem(title: clearStatusAction.title, action: #selector(DeviceStatusBarAction.perform), keyEquivalent: "")
        clearStatusItem.target = clearStatusAction as AnyObject
        clearStatusItem.representedObject = clearStatusAction
        statusBarSubmenu.addItem(clearStatusItem)

        statusBarItem.submenu = statusBarSubmenu
        items.insert(statusBarItem, at: 3)
    }

    if device.runtime.osType == .iOS {
        let pairItem = NSMenuItem.init(title: "Pair", action: nil, keyEquivalent: "")
        pairItem.indentationLevel = 1
        items.insert(pairItem, at: 1)
        let submenu = NSMenu.init()
        let runtimes: [Runtime] = TotalModel.default.runtimes(osType: .watchOS)
        var pairItemDic: [String: [NSMenuItem]] = [:]
        runtimes.forEach { (r) in
            var pairItems: [NSMenuItem] = []
            r.devices.forEach({ (watchDevice) in
                if watchDevice.pairUDID != nil {
                    return
                }
                if device.pairs.contains(where: { $0.udid == device.udid }){
                    return
                }
                let action = DevicePairAction.init(device: device, watchDevice: watchDevice)
                let item = NSMenuItem.init(title: watchDevice.name, action: #selector(DeviceStateAction.perform), keyEquivalent: "")
                item.target = action as AnyObject
                item.representedObject = action
                pairItems.append(item)
            })
            if !pairItems.isEmpty {
                let titleItem = NSMenuItem(title: r.name, action: nil, keyEquivalent: "")
                titleItem.isEnabled = false
                pairItems.insert(titleItem, at: 0)
                pairItemDic[r.name] = pairItems
            }
        }
        pairItemDic.forEach { (_, pairItems) in
            pairItems.forEach({ (item) in
                submenu.addItem(item)
            })
        }
        pairItem.submenu = submenu
    }
    items.insert(NSMenuItem.init(title: "Simulator Action", action: nil, keyEquivalent: ""), at: 0)
    return items
}

private func pairActionItems(_ device: Device) -> [NSMenuItem] {
    var items: [NSMenuItem] = []
    let item = NSMenuItem.init(title: "Paired Watches", action: nil, keyEquivalent: "")
    item.isEnabled = false
    items.append(item)
    device.pairs.forEach {
        let item = DeviceMenuItem.init($0)
        item.indentationLevel = 1
        items.append(item)
    }
    return items
}

protocol DeviceActionable {
    init(_ device: Device)
    var device: Device { get }
    var title: String { get }
    var icon: NSImage? { get }
    var isAvailable: Bool { get }
    func perform()
}

class DevicePairAction: DeviceActionable {
    required init(_ device: Device) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let device: Device
    let watchDevice: Device
    let title: String
    var isAvailable: Bool = true
    var icon: NSImage?
    required init(device: Device, watchDevice: Device) {
        self.device = device
        self.watchDevice = watchDevice
        self.title = device.name
    }

    @objc func perform() {
        watchDevice.pair(to: device)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            BarManager.default.refresh()
        }
    }
}

class DeviceUnpairAction: DeviceActionable {
    let device: Device
    let title: String
    var isAvailable: Bool {
        return device.pairUDID != nil
    }
    var icon: NSImage?
    
    required init(_ device: Device) {
        self.device = device
        self.title = "Unpair"
    }
    
    @objc func perform() {
        device.unpair()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            BarManager.default.refresh()
        }
    }
    
}

class DeviceStateAction: DeviceActionable {
    let device: Device
    let title: String
    var isAvailable: Bool = true
    var icon: NSImage?
    
    required init(_ device: Device) {
        self.device = device
        switch device.state {
        case .booted:
            self.title = "Shutdown"
        case .shutdown:
            self.title = "Boot"
        }
    }
    
    @objc func perform() {
        switch device.state {
        case .booted:
            try? device.shutdown()
        case .shutdown:
            try? device.boot()
        }
    }
    
}

class DeviceEraseAction: DeviceActionable {
    let device: Device
    let title: String
    var isAvailable: Bool = true
    var icon: NSImage?
    
    required init(_ device: Device) {
        self.device = device
        self.title = "Erase All content and setting..."
    }
    
    @objc func perform() {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to Erase '%@'?", device.name)
        let textView = NSTextView.init(frame: NSRect(x: 0, y: 0, width: 300, height: 45))
        textView.isEditable = false
        textView.drawsBackground = false
        let prefixStr = "This action will make device reset to its initial state.\n The device udid:\n"
        let udidStr = device.udid
        let att = NSMutableAttributedString(string: prefixStr + udidStr, attributes: [.foregroundColor : NSColor.textColor])
        att.addAttributes([NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 11)], range: NSRange(location: prefixStr.count, length: udidStr.count))
        textView.textStorage?.append(att)
        alert.accessoryView = textView
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Erase")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        let deviceState = device.state
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            try? device.erase()
            switch deviceState{
            case .booted:
                try? device.boot()
            case .shutdown:
                try? device.shutdown()
            }
        }
    }
}

class DeviceDeleteAction: DeviceActionable {
    let device: Device
    let title: String
    var isAvailable: Bool = true
    var icon: NSImage?
    
    required init(_ device: Device) {
        self.device = device
        self.title = "Delete..."
    }
    
    @objc func perform() {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to delete '%@'?", device.name)
        let textView = NSTextView.init(frame: NSRect(x: 0, y: 0, width: 300, height: 60))
        textView.isEditable = false
        textView.drawsBackground = false
        let prefixStr = "All of the installed content and settings in this simulator will also be deleted.\n The device udid:\n"
        let udidStr = device.udid
        let att = NSMutableAttributedString(string: prefixStr + udidStr)
        att.addAttributes([NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 11)], range: NSRange(location: prefixStr.count, length: udidStr.count))
        textView.textStorage?.append(att)
        alert.accessoryView = textView
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            try? device.delete()
        }
    }
}

class DeviceAppearanceAction: DeviceActionable {
    let device: Device
    let appearance: Device.Appearance
    let title: String
    var isAvailable: Bool {
        return device.state == .booted
    }
    var icon: NSImage?
    
    required init(_ device: Device) {
        self.device = device
        self.appearance = .light
        self.title = "Light Mode"
    }

    init(device: Device, appearance: Device.Appearance) {
        self.device = device
        self.appearance = appearance
        switch appearance {
        case .light:
            self.title = "Light Mode"
        case .dark:
            self.title = "Dark Mode"
        }
    }

    @objc func perform() {
        device.setAppearance(appearance)
    }
}

class DeviceStatusBarAction: DeviceActionable {
    let device: Device
    let isOverride: Bool
    let title: String
    var isAvailable: Bool {
        return device.state == .booted
    }
    var icon: NSImage?

    required init(_ device: Device) {
        self.device = device
        self.isOverride = true
        self.title = "Clean Status Bar (9:41 AM, 100% Battery)"
    }

    init(device: Device, isOverride: Bool) {
        self.device = device
        self.isOverride = isOverride
        self.title = isOverride ? "Clean Status Bar (9:41 AM, 100% Battery)" : "Clear Status Bar Overrides"
    }

    @objc func perform() {
        if isOverride {
            device.overrideStatusBar()
        } else {
            device.clearStatusBar()
        }
    }
}

class DeviceOpenURLAction: DeviceActionable {
    let device: Device
    let title: String = "Open URL / Deep Link..."
    var isAvailable: Bool = true
    var icon: NSImage?

    required init(_ device: Device) {
        self.device = device
    }

    @objc func perform() {
        let alert = NSAlert()
        alert.messageText = "Open URL / Deep Link"
        alert.informativeText = "Enter a URL scheme or web address to open on '\(device.name)':"
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        inputTextField.placeholderString = "e.g. myapp://path or https://apple.com"
        
        if let lastURL = UserDefaults.standard.string(forKey: "iSimulator.lastOpenedURL") {
            inputTextField.stringValue = lastURL
        }
        
        alert.accessoryView = inputTextField
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")
        
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let urlString = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !urlString.isEmpty {
                UserDefaults.standard.set(urlString, forKey: "iSimulator.lastOpenedURL")
                device.openURL(urlString)
            }
        }
    }
}

