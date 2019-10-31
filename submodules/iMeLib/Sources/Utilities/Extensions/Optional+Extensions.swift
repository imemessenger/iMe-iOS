//
//  Optional+Extensions.swift
//  iMeLib
//
//  Created by Valeriy Mikholapov on 11/09/2019.
//  Copyright © 2019 Valeriy Mikholapov. All rights reserved.
//

public extension Optional {
    
    @discardableResult
    func apply(_ action: ((Wrapped) -> Void)?) -> Wrapped? {
        self.map { action?($0) }
        return self
    }

    func and<T>(_ other: T?) -> (Wrapped, T)? {
        guard let self = self, let other = other else {
            return nil
        }
        
        return (self, other)
    }

    func and<T, K, M>(_ other: T?) -> (K, M, T)? where Wrapped == (K, M) {
        guard let other = other, let self = self else {
            return nil
        }
        
        return (self.0, self.1, other)
    }

    func or(_ other: Wrapped) -> Wrapped {
        return self ?? other
    }
    
    func or(_ other: Wrapped?) -> Wrapped? {
        return self ?? other
    }
    
    func or(_ f: () -> Wrapped) -> Wrapped {
        return self ?? f()
    }
    
    func assertNonNil(_ message: @autoclosure () -> String = "Non-nil assertion failed.") -> Wrapped? {
        assert(self != nil, message())
        return self
    }
    
}
