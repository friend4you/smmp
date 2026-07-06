//
//  NetworkMonitorProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 7/4/26.
//

import Combine
import Foundation

enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
    var connectionType: ConnectionType { get }
    var connectivityPublisher: AnyPublisher<Bool, Never> { get }
}
