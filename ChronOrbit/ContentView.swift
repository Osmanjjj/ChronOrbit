//
//  ContentView.swift
//  ChronOrbit
//
//  Created by 黒本誉隆 on 2025/06/15.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                ScheduleInputView()
            }
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }

            NavigationView {
                Text("設定画面")
            }
            .tabItem {
                Label("設定", systemImage: "gear")
            }
        }
    }
}
