//
//  RequestManager.swift
//  AiGramLib
//
//  Created by Valeriy Mikholapov on 02/07/2019.
//  Copyright © 2019 Ol Corporation. All rights reserved.
//

import Foundation
import SwiftSignalKit

// MARK: - Types

enum NetworkError: Error {
    case emptyResponse
    case errorStatusCode
}

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
}

final class RequestManager: NSObject {

    typealias DownloadTaskHandler = (completion: (Result<URL>) -> Void, progressClosure: (Float) -> Void)

    static let shared: RequestManager = .init()

    // MARK: - Components

    private let fileManager: FileManager = .shared
    private lazy var urlSession: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: nil
    )
    
    private let decoder: JSONDecoder = .init()
    private let lock: NSLock = .init()

    private var downloadTasks: [URLSessionDownloadTask: DownloadTaskHandler] = [:]

    // MARK: - Lifecycle

    private override init() { }

    // MARK: - Requests

    func request<T: Decodable>(
        withMethod: HttpMethod = .get,
        url: URL,
        parameters: Parameters? = nil,
        parameterEncoding: ParameterEncoding = JSONEncoding.default
    ) -> Signal<T, Error> {
        return request(
            withMethod: withMethod,
            url: url,
            parameters: parameters,
            parameterEncoding: parameterEncoding
        ) { [decoder] in
            try decoder.decode(T.self, from: $0 ?? Data())
        }
    }

    func request(
        withMethod: HttpMethod = .get,
        url: URL,
        parameters: Parameters? = nil,
        parameterEncoding: ParameterEncoding = JSONEncoding.default
    ) -> Signal<Void, Error> {
        return request(
            withMethod: withMethod,
            url: url,
            parameters: parameters,
            parameterEncoding: parameterEncoding
        ) { _ in () }
    }

    func request<T>(
        withMethod method: HttpMethod,
        url: URL,
        parameters: Parameters?,
        parameterEncoding: ParameterEncoding,
        desirialisationClosure: @escaping (Data?) throws -> T
    ) -> Signal<T, Error> {
        var request: URLRequest
        do {
            request = try parameterEncoding.encode(URLRequest(url: url), with: parameters)
        } catch {
            return .fail(error)
        }

        request.httpMethod = method.rawValue

        return Signal { [urlSession] subscriber in
            let task = urlSession.dataTask(with: request) { data, response, error in
                if let error = error {
                    return subscriber.putError(error)
                }

                guard let response = response, let httpResponse = response as? HTTPURLResponse else {
                    return subscriber.putError(NetworkError.emptyResponse)
                }

                guard (200 ... 399).contains(httpResponse.statusCode) else {
                    return subscriber.putError(NetworkError.errorStatusCode)
                }

                let decodedData: T
                do {
                    decodedData = try desirialisationClosure(data)
                    subscriber.putNext(decodedData)
                    subscriber.putCompletion()
                } catch {
                    subscriber.putError(error)
                }
            }

            task.resume()
            return ActionDisposable {
                task.cancel()
            }
        }
    }

    func download(
        from url: URL,
        downloadProgressCallback: @escaping (Float) -> Void = { _ in }
    ) -> Signal<URL, Error> {
        return Signal { [weak self, urlSession, lock] subscriber in
            let task = urlSession.downloadTask(with: url)

            let completion = { (res: Result<URL>) -> Void in
                switch res {
                    case let .success(fileUrl):
                        subscriber.putNext(fileUrl)
                        subscriber.putCompletion()
                    case let .fail(error):
                        subscriber.putError(error)
                }
            }

            lock.lock()
            self?.downloadTasks[task] = (
                completion: completion,
                progressClosure: downloadProgressCallback
            )
            lock.unlock()

            task.resume()
            return ActionDisposable { [weak self] in
                task.cancel(byProducingResumeData: { _ in
                    // TODO: Cache resume data
                })

                lock.lock()
                self?.downloadTasks.removeValue(forKey: task)
                lock.unlock()
            }
        }
    }

}

// MARK: - Session delegate

extension RequestManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let handlers = getHandlersSafely(for: downloadTask)

        let tempUrl: URL
        do {
            tempUrl = try fileManager.moveFileToTempDir(from: location)
        } catch {
            handlers?.completion(.fail(error))
            return
        }

        handlers?.completion(.success(tempUrl))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error, let downloadTask = task as? URLSessionDownloadTask else { return }

        let handlers = getHandlersSafely(for: downloadTask)
        handlers?.completion(.fail(error))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let current = Float(totalBytesWritten)
        let total = Float(totalBytesExpectedToWrite)

        var currentProgress = totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown && totalBytesExpectedToWrite != 0
            ? current / total
            : 0.0

        if currentProgress > 1 {
            currentProgress = 1.0
        } else if currentProgress < 0 {
            currentProgress = 0.0
        }

        let handlers = getHandlersSafely(for: downloadTask)
        handlers?.progressClosure(currentProgress)
    }

    private func getHandlersSafely(for task: URLSessionDownloadTask) -> DownloadTaskHandler? {
        lock.lock()
        defer { lock.unlock() }

        return downloadTasks[task]
    }

}
