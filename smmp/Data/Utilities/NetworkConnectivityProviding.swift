//
//  NetworkConnectivityProviding.swift
//  smmp
//

import Combine
import Foundation

protocol NetworkConnectivityProviding: AnyObject {
    var isConnected: Bool { get }
    var connectivityPublisher: AnyPublisher<Bool, Never> { get }
}

extension NetworkMonitor: NetworkConnectivityProviding {}
