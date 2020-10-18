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
    var characterstic: CBCharacteristic!
    var isLoading = false
    
    func press() {
        sendData(BotData.PRESS_KEY.data(using: .hexadecimal)!)
    }
    
    func turnOn() {
        let data = BotData.ON_KEY.data(using: .hexadecimal)!
        peripheral?.writeValue(data, for: characterstic, type: .withResponse)
    }
    
    func turnOff() {
        let data = BotData.OFF_KEY.data(using: .hexadecimal)!
        peripheral?.writeValue(data, for: characterstic, type: .withResponse)
    }
    
    func sendData(_ data: Data) {
        guard let peripheral = peripheral else {
            return
        }
        
        switch peripheral.state {
        case .connected:
            peripheral.writeValue(data, for: characterstic, type: .withResponse)
        case .connecting:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sendData(data)
            }
        case .disconnected:
            break
        case .disconnecting:
            break
        @unknown default:
            fatalError()
        }
    }
}
