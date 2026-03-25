//
//  BotData.swift
//  Switchbot WatchKit Extension
//
//  Created by Alexandru Tudose on 18.09.2020.
//

import Foundation

struct BotData {
    /// GATT service UUID (still used after connection, but no longer advertised in firmware V6.4+)
    static let serviceUUID = "cba20d00-224d-11e6-9fb8-0002a5d5c51b"
    /// RX characteristic - write commands here
    static let HANDLE = "cba20002-224d-11e6-9fb8-0002a5d5c51b"
    /// TX characteristic - subscribe for notifications before writing commands (required on newer hardware)
    static let notifyCharacteristic = "cba20003-224d-11e6-9fb8-0002a5d5c51b"

    /// New 16-bit service data UUID used in advertisements (firmware V6.4+)
    static let advertisementServiceUUID = "FD3D"
    /// SwitchBot manufacturer company ID (firmware V6.4+)
    static let manufacturerID: UInt16 = 0x0969

    static let KEY_PASSWORD_PREFIX = "5711"

    static let PRESS_KEY = "570100"
    static let ON_KEY = "570101"
    static let OFF_KEY = "570102"

    static let ON_KEY_SUFFIX = "01"
    static let OFF_KEY_SUFFIX = "02"
    static let PRESS_KEY_SUFFIX = "00"
}
