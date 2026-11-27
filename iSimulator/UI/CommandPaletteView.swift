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
class CommandPaletteViewModel: ObservableObject {
  @Published var searchText: String = "" {
    didSet {
      selectedIndex = 0
    }
  }
  @Published var selectedIndex: Int = 0
  @Published var items: [CommandPaletteItem] = []

  var onDismiss: (() -> Void)?

  var filteredItems: [CommandPaletteItem] {
    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
      return items
    }
    let query = searchText.lowercased()
    return items.filter { item in
      item.title.lowercased().contains(query) || item.subtitle.lowercased().contains(query)
        || item.category.lowercased().contains(query)
    }
  }

  func moveSelectionUp() {
    let count = filteredItems.count
    guard count > 0 else { return }
    selectedIndex = max(0, selectedIndex - 1)
  }

  func moveSelectionDown() {
    let count = filteredItems.count
    guard count > 0 else { return }
    selectedIndex = min(count - 1, selectedIndex + 1)
  }

  func executeSelected() {
    let current = filteredItems
    guard selectedIndex >= 0, selectedIndex < current.count else { return }
    let item = current[selectedIndex]
    onDismiss?()
    item.action()
  }

  func loadItems() {
    var result: [CommandPaletteItem] = []
    TotalModel.default.update()

    TotalModel.default.runtimes.forEach { runtime in
      runtime.devices.forEach { device in
        let isBooted = device.state == .booted

        // Device Action
        result.append(
          CommandPaletteItem(
            title: device.name,
            subtitle:
              "\(isBooted ? "Shutdown" : "Boot") • \(runtime.name) • \(device.formattedTotalSize)",
            iconName: isBooted ? "iphone" : "iphone.slash",
            category: "Simulator",
            isBooted: isBooted,
            action: {
              DispatchQueue.global(qos: .userInitiated).async {
                if isBooted {
                  try? device.shutdown()
                  ToastManager.shared.showToast(
                    message: "Shutdown \(device.name)", iconName: "power")
                } else {
                  try? device.boot()
                  ToastManager.shared.showToast(
                    message: "Booted \(device.name)", iconName: "iphone")
                }
              }
            }
          ))

        // Device Applications
        device.applications.forEach { app in
          result.append(
            CommandPaletteItem(
              title: app.bundleDisplayName,
              subtitle: "Launch • \(app.bundleID) • \(device.name)",
              iconName: "app.fill",
              category: "App",
              isBooted: isBooted,
              action: {
                DispatchQueue.global(qos: .userInitiated).async {
                  app.launch()
                  ToastManager.shared.showToast(
                    message: "Launched \(app.bundleDisplayName)", iconName: "play.fill")
                }
              }
            ))
        }
      }
    }

    result.append(
      CommandPaletteItem(
        title: "Delete Unavailable Simulators",
        subtitle: "Free disk space by removing unavailable CoreSimulator devices",
        iconName: "trash",
        category: "Action",
        isBooted: nil,
        action: {
          DispatchQueue.global(qos: .userInitiated).async {
            shell("/usr/bin/xcrun", arguments: "simctl", "delete", "unavailable")
            BarManager.default.refresh()
            ToastManager.shared.showToast(
              message: "Deleted unavailable simulators", iconName: "trash.fill")
          }
        }
      ))

    result.append(
      CommandPaletteItem(
        title: "Preferences...",
        subtitle: "Configure iSimulator data directory, shortcuts, and pinned items",
        iconName: "gearshape",
        category: "Action",
        isBooted: nil,
        action: {
          DispatchQueue.main.async {
            BarManager.default.openPreferences()
          }
        }
      ))

    self.items = result
    self.selectedIndex = 0
  }
}

@available(macOS 11.0, *)
struct CommandPaletteView: View {
  @ObservedObject var viewModel: CommandPaletteViewModel
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      // Search Input Header
      HStack(spacing: 12) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(.secondary)

        TextField("Search simulators, applications, or actions...", text: $viewModel.searchText)
          .textFieldStyle(PlainTextFieldStyle())
          .font(.system(size: 16, weight: .regular))

        if !viewModel.searchText.isEmpty {
          Button(action: { viewModel.searchText = "" }) {
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
      let filtered = viewModel.filteredItems
      if filtered.isEmpty {
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
            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
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
              .background(
                index == viewModel.selectedIndex ? Color.accentColor.opacity(0.2) : Color.clear
              )
              .cornerRadius(8)
              .contentShape(Rectangle())
              .id(index)
              .onTapGesture {
                onDismiss()
                item.action()
              }
            }
          }
          .listStyle(SidebarListStyle())
          .onChange(of: viewModel.selectedIndex) { newIndex in
            proxy.scrollTo(newIndex, anchor: .center)
          }
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
        Text("\(filtered.count) items")
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
      viewModel.onDismiss = onDismiss
      viewModel.loadItems()
    }
  }
}
