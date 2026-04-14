//
//  AuthServiceProtocol.swift
//  smmp
//
//  Created by Vladyslav Arseniuk on 4/3/26.
//

protocol AuthServiceProtocol {
    func login(email: String, password: String, completion: @escaping ((Result<User, Error>) -> Void))
    func register(email: String, password: String, completion: @escaping ((Result<User, Error>) -> Void))
}
