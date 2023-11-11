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
    @State private var backgroundStopScanTimer: Timer?
    @State var lastOpenedDate: Date?
    
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
                } else {
                    Button("Reload") {
                        scanFor(seconds: 10)
                    }.foregroundColor(.blue)
                }
                ForEach(bluetooth.bots, id: \.id) { bot in
                    SwithcbotView(bot: bot)
                }
                if !bluetooth.isLoading && bluetooth.bots.count == 0 {
                    Text("No bots found")
                }
            }.onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification), perform: { _ in
                self.backgroundStopScanTimer?.invalidate()
                self.backgroundStopScanTimer = nil
                
                // automatic scanning after a period of time,
                if let lastDate = lastOpenedDate, -lastDate.timeIntervalSinceNow > 5*60 {
                    scanFor(seconds: 10)
                }
                self.lastOpenedDate = Date()
            }).onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillResignActiveNotification), perform: { _ in
                self.backgroundStopScanTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { _ in
                    bluetooth.stopScan()
                }
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
