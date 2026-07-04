//
//  NetworkConnectivityProviding.swift
//  smmp
//

import Foundation

protocol NetworkConnectivityProviding: AnyObject {
    var isConnected: Bool { get }
}

extension NetworkMonitor: NetworkConnectivityProviding {}
