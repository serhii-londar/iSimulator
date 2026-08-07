//
//  ToastManager.swift
//  iSimulator
//

import Cocoa

class ToastManager {
    static let shared = ToastManager()
    private var activeToastWindow: NSWindow?
    
    private init() {}
    
    func showToast(message: String, iconName: String = "info.circle.fill") {
        DispatchQueue.main.async {
            self.activeToastWindow?.close()
            
            let padding: CGFloat = 16
            let iconSize: CGFloat = 20
            
            let container = NSView()
            container.wantsLayer = true
            container.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95).cgColor
            container.layer?.cornerRadius = 12
            container.layer?.shadowColor = NSColor.black.cgColor
            container.layer?.shadowOpacity = 0.25
            container.layer?.shadowOffset = CGSize(width: 0, height: -4)
            container.layer?.shadowRadius = 8
            
            let label = NSTextField(labelWithString: message)
            label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            label.textColor = NSColor.labelColor
            label.sizeToFit()
            
            var imageView: NSImageView?
            if #available(macOS 11.0, *), let symbolImage = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                let imgView = NSImageView(image: symbolImage)
                imgView.contentTintColor = NSColor.controlAccentColor
                imgView.frame = NSRect(x: padding, y: padding, width: iconSize, height: iconSize)
                container.addSubview(imgView)
                imageView = imgView
                label.frame.origin = CGPoint(x: padding + iconSize + 10, y: padding + 1)
            } else {
                label.frame.origin = CGPoint(x: padding, y: padding)
            }
            
            let totalWidth = (imageView != nil ? padding + iconSize + 10 : padding) + label.frame.width + padding
            let totalHeight = label.frame.height + (padding * 2)
            
            container.frame = NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
            container.addSubview(label)
            
            guard let mainScreen = NSScreen.main else { return }
            let screenFrame = mainScreen.visibleFrame
            let windowRect = NSRect(
                x: screenFrame.midX - (totalWidth / 2),
                y: screenFrame.minY + 60,
                width: totalWidth,
                height: totalHeight
            )
            
            let window = NSWindow(
                contentRect: windowRect,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating
            window.ignoresMouseEvents = true
            window.contentView = container
            window.alphaValue = 0.0
            
            window.makeKeyAndOrderFront(nil)
            self.activeToastWindow = window
            
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                window.animator().alphaValue = 1.0
            }, completionHandler: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.3
                        window.animator().alphaValue = 0.0
                    }, completionHandler: {
                        window.close()
                        if self.activeToastWindow === window {
                            self.activeToastWindow = nil
                        }
                    })
                }
            })
        }
    }
}
