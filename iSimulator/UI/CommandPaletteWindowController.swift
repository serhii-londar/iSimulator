//
//  CommandPaletteWindowController.swift
//  iSimulator
//

import Cocoa
import SwiftUI

class CommandPalettePanel: NSPanel {
  override var canBecomeKey: Bool {
    return true
  }

  override var canBecomeMain: Bool {
    return true
  }

  override func cancelOperation(_ sender: Any?) {
    CommandPaletteWindowController.shared.close()
  }
}

class CommandPaletteWindowController: NSWindowController {
  static let shared = CommandPaletteWindowController()
  private var localEventMonitor: Any?
  private var _viewModel: Any?

  @available(macOS 11.0, *)
  private var viewModel: CommandPaletteViewModel? {
    get { _viewModel as? CommandPaletteViewModel }
    set { _viewModel = newValue }
  }

  private convenience init() {
    let window = CommandPalettePanel(
      contentRect: NSRect(x: 0, y: 0, width: 580, height: 380),
      styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    window.isMovableByWindowBackground = true
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.level = .floating
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    window.hidesOnDeactivate = true

    self.init(window: window)
    setupContentView()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidResignKey),
      name: NSWindow.didResignKeyNotification,
      object: window
    )
  }

  @objc private func windowDidResignKey() {
    close()
  }

  private func setupContentView() {
    guard #available(macOS 11.0, *), let window = self.window else { return }

    let vm = CommandPaletteViewModel()
    self.viewModel = vm
    let paletteView = CommandPaletteView(
      viewModel: vm,
      onDismiss: { [weak self] in
        self?.close()
      })
    let hostingController = NSHostingController(rootView: paletteView)
    window.contentViewController = hostingController
  }

  func toggle() {
    if window?.isVisible == true {
      close()
    } else {
      show()
    }
  }

  func show() {
    guard let window = self.window, let screen = NSScreen.main else { return }
    let screenFrame = screen.visibleFrame
    let windowSize = window.frame.size
    let origin = CGPoint(
      x: screenFrame.midX - (windowSize.width / 2),
      y: screenFrame.midY + (screenFrame.height / 6) - (windowSize.height / 2)
    )
    window.setFrameOrigin(origin)

    setupContentView()
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)

    if localEventMonitor == nil {
      localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
        [weak self] event in
        switch event.keyCode {
        case 53:  // ESC
          self?.close()
          return nil
        case 126:  // Up Arrow
          if #available(macOS 11.0, *) {
            self?.viewModel?.moveSelectionUp()
          }
          return nil
        case 125:  // Down Arrow
          if #available(macOS 11.0, *) {
            self?.viewModel?.moveSelectionDown()
          }
          return nil
        case 36, 76:  // Return / Keypad Enter
          if #available(macOS 11.0, *) {
            self?.viewModel?.executeSelected()
          }
          return nil
        default:
          return event
        }
      }
    }
  }

  override func close() {
    if let monitor = localEventMonitor {
      NSEvent.removeMonitor(monitor)
      localEventMonitor = nil
    }
    super.close()
  }
}
