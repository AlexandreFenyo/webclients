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
    
    func doJobs(target: WebClientTarget, count: Int = 1) async throws {
        var tasks: [Task<(Data, URLResponse), Error>] = []

        let url_session_configuration = URLSessionConfiguration.ephemeral
        
        let url_session = URLSession(configuration: url_session_configuration, delegate: self, delegateQueue: nil)
        
//        (1...count).forEach { step in
//            if verbose {
//                print("launch background task #\(step - 1)")
//           }

//            let task = Task {
//                try await Task.sleep(nanoseconds: 1000000000)

//                let (data, response) = try await url_session.data(from: target.getURL())
                // Utiliser URLRequest ou analogue plutôt que URL

        // https://developer.apple.com/documentation/swift/withcheckedthrowingcontinuation(isolation:function:_:)?changes=_8
        let foo: DataAndResponse = try await withCheckedThrowingContinuation { continuation in
            // continuation: CheckedContinuation<String, any Error>
            do {
                let url = try target.getURL()
                
                let data_task = url_session.dataTask(with: url) { data, response, error in
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

        /*
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
        
            let data_task = try url_session.dataTask(with: target.getURL()) { data, response, error in
                print("COMPLETED")
            }

        }*/
        
//                data_task.resume()
                
                
//                if verbose {
//                    print("running task #\(step - 1)")
//                }
//                return ""
//            }
//            tasks.append(task)
    }

//        for task in tasks {
//            let retval = try await task.value
//        }

//    }
}
