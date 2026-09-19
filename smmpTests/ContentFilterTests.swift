//
//  ContentFilterTests.swift
//  smmpTests
//

import Testing
@testable import smmp

struct ContentFilterTests {

    private let filter = ContentFilter()

    @Test func matchesDeniedWord() {
        #expect(filter.containsDeniedContent("this is shit"))
    }

    @Test func allowsCleanText() {
        #expect(!filter.containsDeniedContent("hello friends"))
    }

    @Test func matchIsCaseInsensitive() {
        #expect(filter.containsDeniedContent("This is SHIT"))
    }

    @Test func respectsWordBoundaries() {
        #expect(!filter.containsDeniedContent("assignment"))
        #expect(filter.containsDeniedContent("Don't be an asshole"))
    }

    @Test func ignoresEmptyAndWhitespace() {
        #expect(!filter.containsDeniedContent("   "))
        #expect(!filter.containsDeniedContent(""))
    }
}
