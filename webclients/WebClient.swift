//
//  WebClient.swift
//  webclients
//
//  Created by Alexandre Fenyo on 26/05/2024.
//

// Saving this CLI into a binary file: Product / Archive

import Foundation

struct WebClientError: Error {
    enum ErrorKind {
        case generalError
    }
    let kind: ErrorKind
    var reason: String?
}

// Network access config
struct WebClientConfig {
    let is_proxy_ssl: Bool
    let is_use_proxy: Bool
    let is_auth: Bool
    let proxy_login: String?
    let proxy_password: String?
    let proxy_host: String?
    let proxy_port: Int?
    let is_check_ssl: Bool
}

// Target web server
struct WebClientTarget {
    let is_ssl: Bool
    let is_auth: Bool
    let login: String?
    let password: String?
    let host: String
    let port: Int?
    let path: String?
    
    func getURL() throws -> URL {
        let url = "http\(is_ssl ? "s" : "")://\(host):\(port ?? 80)/\(path ?? "")"
        guard let retval = URL(string: url) else {
            throw WebClientError(kind: .generalError, reason: "invalid URL")
        }
        return retval
    }
}

final class WebClientSession: NSObject, URLSessionDelegate, Sendable {
    private let config: WebClientConfig
    private let verbose: Bool
    
    init(config: WebClientConfig, verbose: Bool = false) throws {
        self.config = config
        self.verbose = verbose
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // https://developer.apple.com/documentation/foundation/url_loading_system/handling_an_authentication_challenge/performing_manual_server_trust_authentication
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodHTTPBasic:
            let username = StaticCredentials.login
            let password = StaticCredentials.password
            let credential = URLCredential(user: username, password: password,
                                           persistence: .forSession)
            completionHandler(.useCredential, credential)
            
        case NSURLAuthenticationMethodServerTrust:
            if config.is_check_ssl == false {
                let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential, urlCredential)
            } else {
                completionHandler(.performDefaultHandling, .none)
            }
            
        default:
            completionHandler(.performDefaultHandling, .none)
        }
    }
    
    typealias DataAndResponse = (Data?, URLResponse?)
    
    // Utiliser URLRequest ou analogue plutôt que URL
    // https://developer.apple.com/documentation/swift/withcheckedthrowingcontinuation(isolation:function:_:)?changes=_8
    func fetch(target: WebClientTarget, url_session: URLSession) async throws -> DataAndResponse {
        return try await withCheckedThrowingContinuation { continuation in
            // continuation: CheckedContinuation<String, any Error>
            do {
                let url = try target.getURL()
                var url_request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
                url_request.setValue("deflate", forHTTPHeaderField: "Accept-Encoding")
                print("req:\(url_request.allHTTPHeaderFields)")
                let data_task = url_session.dataTask(with: url_request) { data, response, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: DataAndResponse(data, response))
                    }
                }
                data_task.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func doJobs(target: WebClientTarget, count: Int = 1) async throws {
        var tasks: [Task<DataAndResponse, Error>] = []
        
        let url_session_configuration = URLSessionConfiguration.ephemeral
        
        let url_session = URLSession(configuration: url_session_configuration, delegate: self, delegateQueue: nil)
        
        if count > 1 {
            for step in 1...count {
                if verbose {
                    print("launch background task #\(step - 1)")
                }
                let task = Task {
                    return try await fetch(target: target, url_session: url_session)
                }
                tasks.append(task)
            }
        } else {
            let (data, response) = try await fetch(target: target, url_session: url_session)
            print("HTTP response: \(response)")
        }

        for task in tasks {
            let (data, response) = try await task.value
        }
    }
}
