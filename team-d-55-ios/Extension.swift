//
//  Extension.swift
//  BitcoinKit-HandsOn
//
//  Created by Akifumi Fujita on 2018/09/21.
//  Copyright © 2018年 Yenom. All rights reserved.
//

import Foundation
import MapKit

struct LocationData{
    static let destinationLocation = "latitude: 35.659, longitude: 139.7"
    static let userLocation = "latitude: 35.654, longitude: 139.701"
}

struct transaction{
    static let lockingScriptHex = "a914f62ce7c41fcd4ca6f5857102563df61ca0c9d49087"
    static let txid = "7677522e5d92c0a6ae6391f1e471b87e1b3ff246fc0fda38aaeca0a4e45c19df"
}

extension Data {
    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hex.index(hex.startIndex, offsetBy: i * 2)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
    var hex: String {
        return reduce("") { $0 + String(format: "%02x", $1) }
    }
}

protocol BinaryConvertible {
    static func +(lhs: Data, rhs: Self) -> Data
    static func +=(lhs: inout Data, rhs: Self)
}

extension BinaryConvertible {
    static func +(lhs: Data, rhs: Self) -> Data {
        var value = rhs
        let data = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
        return lhs + data
    }
    
    static func +=(lhs: inout Data, rhs: Self) {
        lhs = lhs + rhs
    }
}

extension UInt8: BinaryConvertible {}


extension Data: BinaryConvertible {
    static func +(lhs: Data, rhs: Data) -> Data {
        var data = Data()
        data.append(lhs)
        data.append(rhs)
        return data
    }
}

extension CLLocationCoordinate2D {
    var areaString: String {
        return "latitude: \((latitude * 1000.0).rounded() / 1000.0), longitude: \((longitude * 1000.0).rounded() / 1000.0)"
    }
}
