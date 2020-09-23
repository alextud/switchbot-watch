//
//  SwitchbotApp.swift
//  Switchbot WatchKit Extension
//
//  Created by Alexandru Tudose on 17.09.2020.
//

import SwiftUI
import UIKit

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
            }.onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification), perform: { _ in
                scanFor(seconds: 10)
            }).onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillResignActiveNotification), perform: { _ in
                bluetooth.stopScan()
            })
        }
    }
    
    func scanFor(seconds: TimeInterval = 10) {
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
