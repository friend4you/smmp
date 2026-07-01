//
//  Coordinating.swift
//  smmp
//

import Combine

@MainActor
protocol Coordinating: AnyObject, ObservableObject {
    associatedtype Route: AppRoute

    var router: Router<Route> { get }
}
