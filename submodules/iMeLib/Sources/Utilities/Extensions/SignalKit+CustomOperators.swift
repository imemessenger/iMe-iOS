//
//  SignalKit+CustomOperators.swift
//  iMeLib
//
//  Created by Valeriy Mikholapov on 11/09/2019.
//  Copyright © 2019 Valeriy Mikholapov. All rights reserved.
//

import SwiftSignalKit

extension Signal {
    public static func just(_ value: T) -> Signal<T, E> {
        return Signal<T, E> { subscriber in
            subscriber.putNext(value)
            
            return EmptyDisposable
        }
    }
}

public func ignoreErrors<T, E>(_ signal: Signal<T, E>) -> Signal<T, NoError> {
    return Signal<T, NoError> { subscriber in
        signal.start(
            next: subscriber.putNext,
            error: { _ in },
            completed: subscriber.putCompletion
        )
    }
}

public func compactMap<T, E, R>(_ f: @escaping(T) -> R?) -> (Signal<T, E>) -> Signal<R, E> {
    return { signal in
        return Signal<R, E> { subscriber in
            return signal.start(next: { next in
                guard let next = f(next) else { return }
                subscriber.putNext(next)
            }, error: { error in
                subscriber.putError(error)
            }, completed: {
                subscriber.putCompletion()
            })
        }
    }
}
