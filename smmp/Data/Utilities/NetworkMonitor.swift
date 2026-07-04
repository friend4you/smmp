//
//  NetworkMonitor.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.smmp.networkmonitor")

    init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            Task { @MainActor in
                self.isConnected = path.status == .satisfied
                self.connectionType = self.type(from: path)
            }
        }

        monitor.start(queue: queue)
    }

    private func type(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        return .unknown
    }
}
