//
//  Pair.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/11/15.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

class Pair: Decodable {
    
    var watch: Device?
    var phone: Device?
    var state = ""
    
    enum CodingKeys: String, CodingKey {
        case watch
        case phone
        case state
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        watch = try container.decodeIfPresent(Device.self, forKey: .watch)
        phone = try container.decodeIfPresent(Device.self, forKey: .phone)
        state = try container.decodeIfPresent(String.self, forKey: .state) ?? ""
    }
    
    var dataReportDic: [String: String] {
        if watch == nil, phone == nil {
            return [:]
        } else {
            return ["w": watch?.udid ?? "", "p": phone?.udid ?? ""]
        }
    }
    
}
