//
//  ConnectivityBinding.swift
//  smmp
//

import Combine
import Foundation

enum ConnectivityBinding {
    /// Binds `connectivityPublisher` and invokes `onChange` with `(isConnected, wasConnected)`.
    static func bind(
        monitor: NetworkMonitorProtocol,
        cancellables: inout Set<AnyCancellable>,
        onChange: @escaping (_ isConnected: Bool, _ wasConnected: Bool) -> Void
    ) {
        var previous = monitor.isConnected

        monitor.connectivityPublisher
            .receive(on: DispatchQueue.main)
            .sink { isConnected in
                let wasConnected = previous
                previous = isConnected
                onChange(isConnected, wasConnected)
            }
            .store(in: &cancellables)
    }
}
