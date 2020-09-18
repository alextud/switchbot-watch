//
//  SwitchbotApp.swift
//  Switchbot WatchKit Extension
//
//  Created by Alexandru Tudose on 17.09.2020.
//

import SwiftUI

@main
struct SwitchbotApp: App {
    @ObservedObject var bluetooth = BluetoothController()
    
    init() {
        scanFor(seconds: 10)
    }
    
    var body: some Scene {
        WindowGroup {
            List {
                if bluetooth.isLoading {
                    HStack(spacing:0) {
                        ProgressView().frame(maxWidth: 40, maxHeight: 10)
                        Text("Scanning...")
                    }
                }
                ForEach(bluetooth.bots, id: \.id) { bot in
                    SwithcbotView(bot: bot)
                }
                if !bluetooth.isLoading {
                    if (bluetooth.bots.count == 0) {
                        Text("No bots found")
                    }
                    Button("Reload") {
                        scanFor(seconds: 10)
                    }.foregroundColor(.blue)
                }
            }
        }
    }
    
    func scanFor(seconds: TimeInterval) {
        bluetooth.scan()
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            bluetooth.stopScan()
        }
    }
}

struct SwitchbotApp_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing:0) {
            ProgressView().frame(maxWidth: 40, maxHeight: 10)
            Text("Scanning...")
        }
    }
}
