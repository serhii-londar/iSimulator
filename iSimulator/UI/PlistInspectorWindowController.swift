//
//  PlistInspectorWindowController.swift
//  iSimulator
//

import Cocoa
import SwiftUI

@available(macOS 10.15, *)
struct PlistItem: Identifiable {
  let id = UUID()
  let key: String
  let value: String
  let type: String
  let detailValue: String?
}

@available(macOS 11.0, *)
struct PlistInspectorView: View {
  let title: String
  let plistPath: String
  @State private var items: [PlistItem] = []
  @State private var searchText: String = ""
  @State private var expandedKeys: Set<String> = []

  var filteredItems: [PlistItem] {
    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
      return items
    }
    let query = searchText.lowercased()
    return items.filter {
      $0.key.lowercased().contains(query)
        || $0.value.lowercased().contains(query)
        || ($0.detailValue?.lowercased().contains(query) ?? false)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Image(systemName: "doc.text.fill")
          .foregroundColor(.accentColor)
          .font(.system(size: 20))

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.headline)
          Text(plistPath)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
        }

        Spacer()

        Button("Refresh") {
          loadPlist()
          ToastManager.shared.showToast(message: "Reloaded \(title)", iconName: "arrow.clockwise")
        }

        Button("Show in Finder") {
          NSWorkspace.shared.selectFile(plistPath, inFileViewerRootedAtPath: "")
        }
      }
      .padding(14)
      .background(Color.secondary.opacity(0.08))

      Divider()

      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.secondary)
        TextField("Search keys or values...", text: $searchText)
          .textFieldStyle(PlainTextFieldStyle())
        if !searchText.isEmpty {
          Button(action: { searchText = "" }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)

      Divider()

      List {
        HStack {
          Text("Key").bold().frame(width: 180, alignment: .leading)
          Text("Type").bold().frame(width: 80, alignment: .leading)
          Text("Value").bold()
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.vertical, 4)

        Divider()

        ForEach(filteredItems) { item in
          VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
              HStack(spacing: 4) {
                if item.detailValue != nil {
                  Image(
                    systemName: expandedKeys.contains(item.key) ? "chevron.down" : "chevron.right"
                  )
                  .font(.system(size: 10, weight: .semibold))
                  .foregroundColor(.secondary)
                }
                Text(item.key)
                  .font(.system(.body, design: .monospaced))
              }
              .frame(width: 180, alignment: .leading)

              Text(item.type)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

              Text(item.value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
            }
            .contentShape(Rectangle())
            .onTapGesture {
              if item.detailValue != nil {
                if expandedKeys.contains(item.key) {
                  expandedKeys.remove(item.key)
                } else {
                  expandedKeys.insert(item.key)
                }
              }
            }
            .contextMenu {
              Button("Copy Key") {
                copyToPasteboard(item.key, label: "Key")
              }
              Button("Copy Value") {
                copyToPasteboard(item.detailValue ?? item.value, label: "Value")
              }
              Button("Copy Key & Value") {
                copyToPasteboard("\(item.key): \(item.detailValue ?? item.value)", label: "Entry")
              }
            }

            if let detail = item.detailValue, expandedKeys.contains(item.key) {
              Text(detail)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(6)
                .textSelection(.enabled)
            }
          }
          .padding(.vertical, 3)
        }
      }
    }
    .frame(minWidth: 620, minHeight: 400)
    .onAppear {
      loadPlist()
    }
  }

  private func copyToPasteboard(_ text: String, label: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    ToastManager.shared.showToast(message: "Copied \(label)", iconName: "doc.on.doc.fill")
  }

  private func loadPlist() {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
      let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        as? [String: Any]
    else {
      return
    }

    var result: [PlistItem] = []
    for (key, val) in plist.sorted(by: { $0.key < $1.key }) {
      let typeStr: String
      let valStr: String
      var detailStr: String? = nil

      switch val {
      case let str as String:
        typeStr = "String"
        valStr = str
      case let bool as Bool:
        typeStr = "Boolean"
        valStr = bool ? "true" : "false"
      case let num as NSNumber:
        typeStr = "Number"
        valStr = num.stringValue
      case let dict as [String: Any]:
        typeStr = "Dictionary"
        valStr = "{\(dict.count) items}"
        detailStr = prettyPrint(dict)
      case let arr as [Any]:
        typeStr = "Array"
        valStr = "[\(arr.count) items]"
        detailStr = prettyPrint(arr)
      default:
        typeStr = "Data"
        valStr = String(describing: val)
      }

      result.append(PlistItem(key: key, value: valStr, type: typeStr, detailValue: detailStr))
    }
    self.items = result
  }

  private func prettyPrint(_ object: Any) -> String {
    if JSONSerialization.isValidJSONObject(object),
      let data = try? JSONSerialization.data(
        withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
      let str = String(data: data, encoding: .utf8)
    {
      return str
    }
    return String(describing: object)
  }
}

class PlistInspectorWindowController: NSWindowController {
  static func show(title: String, plistPath: String) {
    guard #available(macOS 11.0, *) else {
      NSWorkspace.shared.openFile(plistPath)
      return
    }

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 640, height: 440),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Plist Inspector - \(title)"
    window.center()

    let view = PlistInspectorView(title: title, plistPath: plistPath)
    let hostingController = NSHostingController(rootView: view)
    window.contentViewController = hostingController

    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
  }
}
