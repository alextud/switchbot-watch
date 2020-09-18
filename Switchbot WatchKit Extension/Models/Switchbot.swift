//
//  Switchbot.swift
//  switchbot WatchKit Extension
//
//  Created by Alexandru Tudose on 16.09.2020.
//

import Foundation
import SwiftUI
import CoreBluetooth

struct Switchbot: Hashable {
    let name: String
    let id =  UUID().uuidString
    let mac: String
    let rssi: Int
    
    
    var peripheral: CBPeripheral?
    var service: CBService!
    var charcterstic: CBCharacteristic!
    var isLoading = false
    
    func press() {
        let data = BotData.PRESS_KEY.data(using: .hexadecimal)!
        peripheral?.writeValue(data, for: charcterstic, type: .withResponse)
    }
    
    func turnOn() {
        let data = BotData.ON_KEY.data(using: .hexadecimal)!
        peripheral?.writeValue(data, for: charcterstic, type: .withResponse)
    }
    
    func turnOff() {
        let data = BotData.OFF_KEY.data(using: .hexadecimal)!
        peripheral?.writeValue(data, for: charcterstic, type: .withResponse)
    }
}
