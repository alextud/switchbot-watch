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
            // Scan without service filter — newer firmware no longer advertises the 128-bit UUID
            bluetootManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }

    }

    func stopScan() {
        if isLoading {
            isLoading = false
            bluetootManager.stopScan()
        }
    }

    /// Check if advertisement data belongs to a SwitchBot device
    private func isSwitchBotDevice(advertisementData: [String: Any]) -> Bool {
        // Check for new 16-bit service data UUID (firmware V6.4+)
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            if serviceData.keys.contains(CBUUID(string: BotData.advertisementServiceUUID)) {
                return true
            }
            // Also check old 16-bit UUID for older firmware
            if serviceData.keys.contains(CBUUID(string: "000D")) {
                return true
            }
        }

        // Check for SwitchBot manufacturer ID
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           manufacturerData.count >= 2 {
            let companyID = UInt16(manufacturerData[0]) | (UInt16(manufacturerData[1]) << 8)
            if companyID == BotData.manufacturerID || companyID == 0x0059 /* old Nordic ID */ {
                return true
            }
        }

        // Check for old 128-bit service UUID (pre V6.4 firmware)
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            if serviceUUIDs.contains(CBUUID(string: BotData.serviceUUID)) {
                return true
            }
        }

        return false
    }
}

extension BluetoothController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state change:", central.state.rawValue)
        if central.state == .unauthorized {
            print("BT authorization:", CBCentralManager.authorization.rawValue)
            print("Bluetooth unauthorized - check Settings > Privacy & Security > Bluetooth")
        }
        if [.unauthorized, .unsupported, .poweredOff].contains(central.state) {
            print("could not start, state:", central.state.rawValue)
        }

        if central.state == .poweredOn {
            bluetootManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else {
            isLoading = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard isSwitchBotDevice(advertisementData: advertisementData) else {
            return
        }

        // Skip if already discovered
        guard !bots.contains(where: { $0.mac == peripheral.identifier.uuidString }) else {
            return
        }

        print("discover SwitchBot:", peripheral.name ?? "", "data:", advertisementData, "rssi:", RSSI)

        var bot = Switchbot(name: peripheral.name ?? "N/A", mac: peripheral.identifier.uuidString, rssi: RSSI.intValue)
        bot.peripheral = peripheral
        bots.append(bot)

        peripheral.delegate = self
        bluetootManager.connect(peripheral, options: .none)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        peripheral.discoverServices([CBUUID(string: BotData.serviceUUID)])
    }
}


extension BluetoothController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print(#function)

        for service in peripheral.services ?? [] {
            print(service)
            peripheral.discoverCharacteristics([
                CBUUID(string: BotData.HANDLE),
                CBUUID(string: BotData.notifyCharacteristic)
            ], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for item in service.characteristics ?? [] {
            print("characteristic:", item.uuid.uuidString)

            let uuidString = item.uuid.uuidString.uppercased()

            if uuidString == BotData.notifyCharacteristic.uppercased() {
                // Subscribe to notifications — required on newer hardware before writing commands
                print("subscribing to notify characteristic", item)
                peripheral.setNotifyValue(true, for: item)
            }

            if uuidString == BotData.HANDLE.uppercased() {
                print("found RX characteristic", item)
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
        if let error = error {
            print("notify error for \(characteristic.uuid):", error)
        } else {
            print("notify enabled for \(characteristic.uuid)")
        }
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
