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
    return NSImage(size: size, flipped: false) { rect in
      NSGraphicsContext.current?.imageInterpolation = .high
      let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
      path.addClip()
      self.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
      return true
    }
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
