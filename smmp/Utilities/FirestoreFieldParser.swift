//
//  FirestoreFieldParser.swift
//  smmp
//

import FirebaseFirestore
import Foundation

enum FirestoreFieldParser {

    static func optionalString(_ value: Any?) -> String? {
        guard let value, !(value is NSNull) else { return nil }
        return value as? String
    }

    static func intValue(_ value: Any?, default defaultValue: Int = 0) -> Int {
        if let int = value as? Int { return int }
        if let int64 = value as? Int64 { return Int(int64) }
        if let number = value as? NSNumber { return number.intValue }
        return defaultValue
    }

    static func date(from value: Any?) -> Date? {
        guard let value, !(value is NSNull) else { return nil }
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        return nil
    }
}
