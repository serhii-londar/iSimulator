//
//  PreferencesViewController.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/11/16.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa
import SwiftUI

class PreferencesViewController: NSViewController {

    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var pathTextField: NSTextField!
    
    @IBOutlet weak var aboutName: NSTextField!
    @IBOutlet weak var aboutVersion: NSTextField!
    @IBOutlet weak var aboutCopyright: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let pathTF = self.pathTextField {
            pathTF.stringValue = RootLink.url.path
        }
        let infoDic = Bundle.main.infoDictionary ?? [:]
        if let nameTF = aboutName {
            nameTF.stringValue = infoDic["CFBundleDisplayName"] as? String ?? "iSimulator"
        }
        let shortVersion = infoDic["CFBundleShortVersionString"] as? String ?? ""
        let version = infoDic["CFBundleVersion"] as? String ?? ""
        if let versionTF = aboutVersion {
            versionTF.stringValue = "Version \(shortVersion) (\(version))"
        }
        if let copyrightTF = aboutCopyright {
            copyrightTF.stringValue = infoDic["NSHumanReadableCopyright"] as? String ?? ""
        }
    }
}

// MARK: - Change iSimulator folder
extension PreferencesViewController {
    @IBAction func changePath(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { (resp) in
            if resp.rawValue == NSFileHandlingPanelCancelButton{
                return
            }
            if let url = panel.url {
                self.changePathAlert(path: url.path)
            }
        }
    }
    
    @IBAction func openPath(_ sender: Any) {
        NSWorkspace.shared.open(RootLink.url)
    }
    
    func changePathAlert(path: String) {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Are you sure you want to change data path?")
        alert.informativeText = "The iSimulator folder will be moved to the new location."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Done")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!) { (response) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                RootLink.update(with: path, finish: { (errorStr) in
                    if let error = errorStr {
                        self.changePathErrorAlert(error: error)
                        return
                    }
                    self.pathTextField?.stringValue = RootLink.url.path
                })
            }
        }
    }
    
    func changePathErrorAlert(error: String) {
        let alert: NSAlert = NSAlert()
        alert.messageText = String(format: "Change data path failed!")
        alert.informativeText = error
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Done")
        NSApp.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
}

extension PreferencesViewController {
    @IBAction func checkForUpdate(_ sender: Any) {
        let url = "https://github.com/wigl/iSimulator/releases"
        NSWorkspace.shared.open(URL(string: url)!)
    }
}

// MARK: - SwiftUI Preferences View
@available(macOS 10.15, *)
struct PreferencesSwiftUIView: View {
    @State private var currentPath: String = RootLink.url.path
    
    var body: some View {
        TabView {
            VStack(alignment: .leading, spacing: 16) {
                Text("iSimulator Data Directory")
                    .font(.headline)
                
                HStack {
                    TextField("Path", text: $currentPath)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(true)
                    
                    Button("Open Folder") {
                        NSWorkspace.shared.open(RootLink.url)
                    }
                }
                
                Button("Change Location...") {
                    selectNewPath()
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Text("General")
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("UI & Shortcuts")
                    .font(.headline)
                
                Button("Open Command Palette (⌘K)") {
                    CommandPaletteWindowController.shared.show()
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pinned Favorites")
                        .font(.subheadline)
                        .bold()
                    
                    Text("Reset all pinned simulators and applications from top menu bar section.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Clear All Pinned Items") {
                        FavoritesManager.shared.clearAll()
                    }
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Text("UI & Shortcuts")
            }
            
            VStack(spacing: 12) {
                Text(Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "iSimulator")
                    .font(.title)
                    .bold()
                
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Check for Updates...") {
                    if let url = URL(string: "https://github.com/wigl/iSimulator/releases") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
            .tabItem {
                Text("About")
            }
        }
        .frame(minWidth: 450, minHeight: 250)
    }
    
    private func selectNewPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                RootLink.update(with: url.path) { errorStr in
                    if let error = errorStr {
                        let alert = NSAlert()
                        alert.messageText = "Change data path failed!"
                        alert.informativeText = error
                        alert.alertStyle = .critical
                        alert.runModal()
                    } else {
                        self.currentPath = RootLink.url.path
                    }
                }
            }
        }
    }
}
