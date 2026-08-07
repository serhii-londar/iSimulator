//
//  Runtime.swift
//  iSimulator
//
//  Created by 靳朋 on 2017/8/23.
//  Copyright © 2017年 niels.jin. All rights reserved.
//

import Foundation

enum Availability: String, Decodable {
    case available = "(available)"
    case unavailable = "(unavailable, runtime profile not found)"
}

class Runtime: Decodable {
    
    enum OSType: String {
        case iOS, tvOS, watchOS, None
    }
    
    var buildversion = ""
    var availability = Availability.unavailable
    var name = ""
    var identifier = ""
    var version = ""
    var devices: [Device] = []
    var devicetypes: [DeviceType] = []
    var osType: OSType {
        if name.contains("iOS") {
            return .iOS
        } else if name.contains("tvOS") {
            return .tvOS
        } else if name.contains("watchOS") {
            return .watchOS
        } else {
            return .None
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case buildversion
        case availability
        case isAvailable
        case name
        case identifier
        case version
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        buildversion = try container.decodeIfPresent(String.self, forKey: .buildversion) ?? ""
        if let avail = try container.decodeIfPresent(Availability.self, forKey: .availability) {
            availability = avail
        } else if let isAvail = try container.decodeIfPresent(Bool.self, forKey: .isAvailable) {
            availability = isAvail ? .available : .unavailable
        } else {
            availability = .unavailable
        }
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        identifier = try container.decodeIfPresent(String.self, forKey: .identifier) ?? ""
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? ""
    }
    
    var dataReportDic: [String: String] {
        return ["n": name, "b": buildversion, "v": version, "id": identifier]
    }
}

