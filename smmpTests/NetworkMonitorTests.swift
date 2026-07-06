//
//  NetworkMonitorTests.swift
//  smmpTests
//

import Combine
import Testing
@testable import smmp

@MainActor
struct NetworkMonitorTests {

    @Test func testInitializerSeedsOfflineState() {
        let monitor = NetworkMonitor(testConnection: false)
        #expect(monitor.isConnected == false)
    }

    @Test func testInitializerSeedsOnlineState() {
        let monitor = NetworkMonitor(testConnection: true)
        #expect(monitor.isConnected == true)
    }

    @Test func connectivityPublisherEmitsInitialOfflineValue() {
        let monitor = NetworkMonitor(testConnection: false)
        var received: [Bool] = []
        let cancellable = monitor.connectivityPublisher.sink { received.append($0) }
        #expect(received == [false])
        cancellable.cancel()
    }

    @Test func connectivityPublisherEmitsTransitions() {
        let mock = MockNetworkMonitor(isConnected: true)
        var received: [Bool] = []
        let cancellable = mock.connectivityPublisher.sink { received.append($0) }

        mock.setConnected(false)
        mock.setConnected(true)

        #expect(received == [true, false, true])
        cancellable.cancel()
    }
}
