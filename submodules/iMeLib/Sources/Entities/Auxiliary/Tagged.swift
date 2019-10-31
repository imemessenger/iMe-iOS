//
//  Tagged.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 28/06/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

public struct Tagged<Tag, RawValue> {
    public var rawValue: RawValue

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    public func map<B>(_ f: (RawValue) -> B) -> Tagged<Tag, B> {
        return .init(rawValue: f(self.rawValue))
    }
}

extension Tagged: CustomStringConvertible {
    public var description: String {
        return String(describing: self.rawValue)
    }
}

extension Tagged: RawRepresentable {
}

extension Tagged: CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        return self.rawValue
    }
}

// MARK: - Conditional Conformances

extension Tagged: Hashable where RawValue: Hashable { }

extension Tagged: Comparable where RawValue: Comparable {
    public static func < (lhs: Tagged, rhs: Tagged) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension Tagged: Decodable where RawValue: Decodable {
    public init(from decoder: Decoder) throws {
        do {
            self.init(rawValue: try decoder.singleValueContainer().decode(RawValue.self))
        } catch {
            self.init(rawValue: try .init(from: decoder))
        }
    }
}

extension Tagged: Encodable where RawValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

extension Tagged: Equatable where RawValue: Equatable {
    public static func == (lhs: Tagged, rhs: Tagged) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension Tagged: Error where RawValue: Error {
}

extension Tagged: ExpressibleByBooleanLiteral where RawValue: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = RawValue.BooleanLiteralType

    public init(booleanLiteral value: RawValue.BooleanLiteralType) {
        self.init(rawValue: RawValue(booleanLiteral: value))
    }
}

extension Tagged: ExpressibleByExtendedGraphemeClusterLiteral where RawValue: ExpressibleByExtendedGraphemeClusterLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = RawValue.ExtendedGraphemeClusterLiteralType

    public init(extendedGraphemeClusterLiteral: ExtendedGraphemeClusterLiteralType) {
        self.init(rawValue: RawValue(extendedGraphemeClusterLiteral: extendedGraphemeClusterLiteral))
    }
}

extension Tagged: ExpressibleByFloatLiteral where RawValue: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = RawValue.FloatLiteralType

    public init(floatLiteral: FloatLiteralType) {
        self.init(rawValue: RawValue(floatLiteral: floatLiteral))
    }
}

extension Tagged: ExpressibleByIntegerLiteral where RawValue: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = RawValue.IntegerLiteralType

    public init(integerLiteral: IntegerLiteralType) {
        self.init(rawValue: RawValue(integerLiteral: integerLiteral))
    }
}

extension Tagged: ExpressibleByStringLiteral where RawValue: ExpressibleByStringLiteral {
    public typealias StringLiteralType = RawValue.StringLiteralType

    public init(stringLiteral: StringLiteralType) {
        self.init(rawValue: RawValue(stringLiteral: stringLiteral))
    }
}

extension Tagged: ExpressibleByUnicodeScalarLiteral where RawValue: ExpressibleByUnicodeScalarLiteral {
    public typealias UnicodeScalarLiteralType = RawValue.UnicodeScalarLiteralType

    public init(unicodeScalarLiteral: UnicodeScalarLiteralType) {
        self.init(rawValue: RawValue(unicodeScalarLiteral: unicodeScalarLiteral))
    }
}

extension Tagged: LosslessStringConvertible where RawValue: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let rawValue = RawValue(description) else { return nil }
        self.init(rawValue: rawValue)
    }
}
