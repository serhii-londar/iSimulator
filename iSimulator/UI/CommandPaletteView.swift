//
//  CommandPaletteView.swift
//  iSimulator
//

import SwiftUI

@available(macOS 10.15, *)
struct CommandPaletteItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let iconName: String
    let category: String
    let isBooted: Bool?
    let action: () -> Void
}

@available(macOS 10.15, *)
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

@available(macOS 11.0, *)
struct CommandPaletteView: View {
    @State private var searchText: String = ""
    @State private var selectedIndex: Int = 0
    let onDismiss: () -> Void
    
    @State private var items: [CommandPaletteItem] = []
    
    var filteredItems: [CommandPaletteItem] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return items
        }
        let query = searchText.lowercased()
        return items.filter { item in
            item.title.lowercased().contains(query) ||
            item.subtitle.lowercased().contains(query) ||
            item.category.lowercased().contains(query)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Input Header
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search simulators, applications, or actions...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .regular))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: { onDismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close (ESC)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            Divider()
            
            // Results List
            if filteredItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "circle.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No matching simulators or apps found")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            HStack(spacing: 12) {
                                Image(systemName: item.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(item.isBooted == true ? .green : .secondary)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text(item.subtitle)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(item.category)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.secondary.opacity(0.15))
                                    .cornerRadius(6)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(index == selectedIndex ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .id(index)
                            .onTapGesture {
                                item.action()
                                onDismiss()
                            }
                        }
                    }
                    .listStyle(SidebarListStyle())
                }
            }
            
            Divider()
            
            // Keyboard hints footer
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("↑↓").bold()
                    Text("Navigate")
                }
                HStack(spacing: 4) {
                    Text("↵").bold()
                    Text("Select")
                }
                Button(action: { onDismiss() }) {
                    HStack(spacing: 4) {
                        Text("ESC").bold()
                        Text("Dismiss")
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                Text("\(filteredItems.count) items")
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .frame(width: 580, height: 380)
        .onExitCommand {
            onDismiss()
        }
        .onAppear {
            loadItems()
        }
    }
    
    private func loadItems() {
        var result: [CommandPaletteItem] = []
        TotalModel.default.update()
        
        TotalModel.default.runtimes.forEach { runtime in
            runtime.devices.forEach { device in
                let isBooted = device.state == .booted
                
                // Device Action
                result.append(CommandPaletteItem(
                    title: device.name,
                    subtitle: "\(runtime.name) • \(isBooted ? "Booted" : "Shutdown")",
                    iconName: isBooted ? "iphone" : "iphone.slash",
                    category: "Simulator",
                    isBooted: isBooted,
                    action: {
                        if isBooted {
                            try? device.shutdown()
                        } else {
                            try? device.boot()
                        }
                    }
                ))
                
                // Device Applications
                device.applications.forEach { app in
                    result.append(CommandPaletteItem(
                        title: app.bundleDisplayName,
                        subtitle: "\(app.bundleID) • \(device.name)",
                        iconName: "app.fill",
                        category: "App",
                        isBooted: isBooted,
                        action: {
                            if let url = app.linkURL {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    ))
                }
            }
        }
        
        self.items = result
    }
}
