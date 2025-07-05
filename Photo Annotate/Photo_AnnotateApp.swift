//
//  Photo_AnnotateApp.swift
//  Photo Annotate
//
//  Created by Brett Larson on 4/15/25.
//
//*************************************************************************************************
//* Copyright Brett Larson 2025
//*
//* This program is free software: you can redistribute it and/or modify it under the terms of the
//* GNU General Public License version 3 as published by the Free Software Foundation,
//*
//* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
//* PURPOSE. See the GNU General Public License for more details.
//*
//* You should have received a copy of the GNU General Public License along with this program. If
//* not, see <https://www.gnu.org/licenses/>.
//*************************************************************************************************

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct Photo_AnnotateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
