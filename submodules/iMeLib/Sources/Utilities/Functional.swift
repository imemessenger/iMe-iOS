//
//  Functional.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 03/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

@inlinable
@discardableResult
public func with<T: AnyObject>(_ obj: T, _ closure: (T) -> Void) -> T {
    closure(obj)
    return obj
}

@inlinable
@discardableResult
public func with<T: AnyObject>(_ obj: T?, _ closure: (T?) -> Void) -> T? {
    closure(obj)
    return obj
}

@inlinable
@discardableResult
public func with<T>(struct: T, _ closure: (inout T) -> Void) -> T {
    var copy = `struct`
    closure(&copy)
    return `struct`
}

@inlinable
public func with<T: AnyObject, U: AnyObject>(_ obj0: T, _ obj1: U, _ closure: (T, U) -> Void) {
    closure(obj0, obj1)
}

@inlinable
public func with<T: AnyObject, U: AnyObject, V: AnyObject>(_ obj0: T, _ obj1: U, _ obj2: V, _ closure: (T, U, V) -> Void) {
    closure(obj0, obj1, obj2)
}

@inlinable
public func with<T: AnyObject, U: AnyObject, V: AnyObject, W: AnyObject>(
    _ obj0: T,
    _ obj1: U,
    _ obj2: V,
    _ obj3: W,
    _ closure: (T, U, V, W) -> Void
    ) {
    closure(obj0, obj1, obj2, obj3)
}

@discardableResult
public func wrap<A: AnyObject, B: AnyObject, C: AnyObject, D: AnyObject, R>(
    _ a: A,
    _ b: B,
    _ c: C,
    _ d: D,
    _ f: (A, B, C, D) -> R
    ) -> R {
    return f(a, b, c, d)
}

@discardableResult
public func wrap<A: AnyObject, B: AnyObject, C: AnyObject, R>(
    _ a: A,
    _ b: B,
    _ c: C,
    _ f: (A, B, C) -> R
    ) -> R {
    return f(a, b, c)
}

@discardableResult
public func wrap<A: AnyObject, B: AnyObject, R>(
    _ a: A,
    _ b: B,
    _ f: (A, B) -> R
    ) -> R {
    return f(a, b)
}

@discardableResult
public func wrap<A: AnyObject, R>(
    _ a: A,
    _ f: (A) -> R
    ) -> R {
    return f(a)
}

@discardableResult
public func wrapFlat<A: AnyObject, B: AnyObject, C: AnyObject, R>(
    _ a: A,
    _ b: B,
    _ c: C,
    _ f: (A, B, C) -> [[R]]
    ) -> [R] {
    return f(a, b, c).flatMap { $0 }
}

@discardableResult
public func wrapFlat<A: AnyObject, B: AnyObject, R>(
    _ a: A,
    _ b: B,
    _ f: (A, B) -> [[R]]
    ) -> [R] {
    return f(a, b).flatMap { $0 }
}

@discardableResult
public func wrapFlat<A: AnyObject, R>(
    _ a: A,
    _ f: (A) -> [[R]]
    ) -> [R] {
    return f(a).flatMap { $0 }
}

public func carry<T, R>(_ val: T, _ f: @escaping (T) -> R) -> () -> R {
    return { f(val) }
}

