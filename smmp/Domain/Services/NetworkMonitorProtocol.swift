//
//  NetworkMonitorProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

import Foundation

enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

protocol NetworkMonitorProtocol: ObservableObject {
    var isConnected: Bool { get }
    var connectionType: ConnectionType { get }
}
