//
//  AppMenuItem.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/24.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Cocoa

class AppMenuItem: NSMenuItem {
    
    let app: Application
    
    init(_ app: Application) {
        self.app = app
        super.init(title: "", action: nil, keyEquivalent: "")
        self.image = app.image
        self.attributedTitle = app.attributeStr
        self.indentationLevel = 1
        self.submenu = AppMenu(app)
    }

    func refreshSizeAsync() {
        app.size { [weak self] sandboxSize, bundleSize in
            guard let self = self else { return }
            self.attributedTitle = self.app.attributedTitle(totalSize: sandboxSize + bundleSize)
        }
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(cowder:) has not been implemented")
    }
    
}
