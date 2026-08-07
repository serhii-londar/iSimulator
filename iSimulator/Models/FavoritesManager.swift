//
//  FavoritesManager.swift
//  iSimulator
//

import Foundation

class FavoritesManager {
    static let shared = FavoritesManager()
    
    private let pinnedDevicesKey = "iSimulator.pinnedDevices"
    private let pinnedAppsKey = "iSimulator.pinnedApps"
    
    private init() {}
    
    // MARK: - Devices
    var pinnedDeviceUDIDs: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: pinnedDevicesKey) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: pinnedDevicesKey)
        }
    }
    
    func isPinned(device: Device) -> Bool {
        return pinnedDeviceUDIDs.contains(device.udid)
    }
    
    func togglePin(device: Device) {
        if isPinned(device: device) {
            pinnedDeviceUDIDs.removeAll { $0 == device.udid }
        } else {
            pinnedDeviceUDIDs.append(device.udid)
        }
        BarManager.default.refresh()
    }
    
    // MARK: - Applications
    var pinnedAppKeys: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: pinnedAppsKey) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: pinnedAppsKey)
        }
    }
    
    private func appKey(for app: Application) -> String {
        return "\(app.device.udid)::\(app.bundleID)"
    }
    
    func isPinned(app: Application) -> Bool {
        return pinnedAppKeys.contains(appKey(for: app))
    }
    
    func togglePin(app: Application) {
        let key = appKey(for: app)
        if isPinned(app: app) {
            pinnedAppKeys.removeAll { $0 == key }
        } else {
            pinnedAppKeys.append(key)
        }
        BarManager.default.refresh()
    }
    
    func clearAll() {
        pinnedDeviceUDIDs.removeAll()
        pinnedAppKeys.removeAll()
        BarManager.default.refresh()
    }
}
