//
//  ContentView.swift
//  switchbot WatchKit Extension
//
//  Created by Alexandru Tudose on 16.09.2020.
//

import SwiftUI

struct SwithcbotView: View {
    var bot: Switchbot
    var body: some View {
        HStack {
            Button(bot.name, action: bot.press)
                .disabled(bot.peripheral?.state != .connected)
            Text(" \(bot.rssi)db")
        }
        if bot.isLoading {
            ProgressView("...")
        }
    }
}

struct SwithcbotView_Previews: PreviewProvider {
    static var previews: some View {
        SwithcbotView(bot: Switchbot(name: "Garage", mac: "", rssi: -50))
    }
}
