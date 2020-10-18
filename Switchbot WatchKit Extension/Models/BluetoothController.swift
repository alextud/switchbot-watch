//
//  BluetoothController.swift
//  switchbot
//
//  Created by Alexandru Tudose on 16.09.2020.
//

import Foundation
import CoreBluetooth
import SwiftUI


class BluetoothController: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var bots: [Switchbot] = []
    
    var bluetootManager:CBCentralManager!
    
    override init() {
        super.init()
        
        isLoading = true
        bluetootManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scan() {
        if !isLoading {
            isLoading = true
            bots = []
            bluetootManager.scanForPeripherals(withServices: [CBUUID(string: BotData.UUID)], options: .none)
        }
        
    }
    
    func stopScan() {
        if isLoading {
            isLoading = false
            bluetootManager.stopScan()
        }
    }
}

extension BluetoothController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state change:", central.state.rawValue)
        if [.unauthorized, .unsupported, .poweredOff].contains(central.state) {
            print("could not start")
        }
        
        if central.state == .poweredOn {
            bluetootManager.scanForPeripherals(withServices: [CBUUID(string: BotData.UUID)], options: .none)
        } else {
            isLoading = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("discover: ", peripheral.name ?? "", "data:", advertisementData, "rssi:", RSSI)

        
        var bot = Switchbot(name: peripheral.name ?? "N/A", mac: peripheral.identifier.uuidString, rssi: RSSI.intValue)
        bot.peripheral = peripheral
        bots.append(bot)
        
        peripheral.delegate = self
        bluetootManager.connect(peripheral, options: .none)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        peripheral.discoverServices(nil)
    }
}


extension BluetoothController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(#function)
        
        for service in peripheral.services ?? [] {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for item in service.characteristics ?? [] {
           print(item)
            
            print(item.uuid.uuidString.uppercased())
            if (item.uuid.uuidString.uppercased() == BotData.HANDLE.uppercased()) {
                print("found charactestic", item)
                if let index = bots.firstIndex(where: {$0.peripheral == peripheral}) {
                    var bot = bots[index]
                    bot.characterstic = item
                    bots[index] = bot
                }
            }
         }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print(#function)
        for descriptor in characteristic.descriptors ?? [] {
            print(descriptor)
            peripheral.readValue(for: descriptor)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print(#function)

        print("Unhandled Characteristic UUID: \(characteristic.uuid)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
          switch characteristic.uuid {
          default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//        print(#function, characteristic, "error: ", error);
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print(#function,  descriptor);
    }
}
