//
//  Coordinating.swift
//  smmp
//

import Combine

@MainActor
protocol Coordinating: ObservableObject {
    associatedtype Route: AppRoute

    var router: Router<Route> { get }
}
