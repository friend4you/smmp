//
//  AppRoute.swift
//  smmp
//

import Foundation

protocol AppRoute: Hashable, Identifiable {}

extension AppRoute {
    var id: Self { self }
}
