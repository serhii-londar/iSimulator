//
//  DeviceTypes.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

class DeviceType: Decodable {
    var name = ""
    var identifier = ""
    
    enum CodingKeys: String, CodingKey {
        case name
        case identifier
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        identifier = try container.decodeIfPresent(String.self, forKey: .identifier) ?? ""
    }
    
    var dataReportDic: [String: String] {
        return ["n": name, "id": identifier]
    }
}
