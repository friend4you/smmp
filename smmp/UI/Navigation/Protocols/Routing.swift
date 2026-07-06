//
//  Routing.swift
//  smmp
//

import Combine
import SwiftUI

@MainActor
protocol Routing: AnyObject, ObservableObject {
    associatedtype Route: AppRoute

    var path: NavigationPath { get set }
    var sheet: Route? { get set }
    var fullScreenCover: Route? { get set }

    func push(_ route: Route)
    func pop()
    func popToRoot()
    func presentSheet(_ route: Route)
    func dismissSheet()
    func presentFullScreenCover(_ route: Route)
    func dismissFullScreenCover()
    func reset()
}
