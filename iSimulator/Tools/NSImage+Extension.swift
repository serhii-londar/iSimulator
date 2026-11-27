//
//  NSImage+Extension.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/24.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

extension NSImage {

  func appIcon(h: CGFloat = 35) -> NSImage {
    let size = NSSize(width: h, height: h)
    let cornerRadius: CGFloat = h / 5
    guard self.isValid, !self.representations.isEmpty else {
      return self
    }
    let scale = 2
    let pixelSize = Int(h) * scale
    guard
      let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
      )
    else {
      return self
    }
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
      NSGraphicsContext.current = ctx
      ctx.imageInterpolation = .high
      let rect = NSRect(origin: .zero, size: size)
      let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
      path.addClip()
      self.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    NSGraphicsContext.restoreGraphicsState()
    let result = NSImage(size: size)
    result.addRepresentation(rep)
    return result
  }
}

extension Array where Element: Equatable {
  func divideDuplicates() -> (result: [Element], duplicates: [Element]) {
    var result = [Element]()
    var duplicates = [Element]()
    for value in self {
      if result.contains(value) == false {
        result.append(value)
      } else {
        duplicates.append(value)
      }
    }

    return (result, duplicates)
  }
}
