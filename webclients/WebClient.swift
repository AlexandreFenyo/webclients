//
//  WebClient.swift
//  webclients
//
//  Created by Alexandre Fenyo on 26/05/2024.
//

// Saving this CLI into a binary file: Product / Archive

import Foundation

typealias CredentialsContainer = [String: (String, String)]
typealias DataAndResponse = (Data?, URLResponse?)
typealias DataRequestResponse = (Data?, URLRequest?, URLResponse?)

// Network access config
struct AccessNetworkConfig: Sendable {
    private let is_proxy_ssl: Bool
    fileprivate let is_use_proxy: Bool
    private let is_auth: Bool
    private let proxy_login: String?
    private let proxy_password: String?
    fileprivate let proxy_host: String?
    fileprivate let proxy_port: Int?
    fileprivate let is_check_ssl: Bool
    fileprivate let credentials: CredentialsContainer

    // Pre-initialized values for common cases
    static let defaultAccessNetwork = AccessNetworkConfig()
    static let unsecureDefaultAccessNetwork = AccessNetworkConfig(is_check_ssl: false)

    init(is_proxy_ssl: Bool = false, is_use_proxy: Bool = false, is_auth: Bool = false, proxy_login: String? = nil, proxy_password: String? = nil, proxy_host: String? = nil, proxy_port: Int? = nil, is_check_ssl: Bool = true, credentials: CredentialsContainer = CredentialsContainer()) {
        self.is_proxy_ssl = is_proxy_ssl
        self.is_use_proxy = is_use_proxy
        self.is_auth = is_auth
        self.proxy_login = proxy_login
        self.proxy_password = proxy_password
        self.proxy_host = proxy_host
        self.proxy_port = proxy_port
        self.is_check_ssl = is_check_ssl
        self.credentials = credentials
    }
}

struct ParsedURL {
    private let is_ssl: Bool
    private let is_auth: Bool
    private let login: String?
    private let password: String?
    private let host: String
    private let port: Int
    private let path: String

    init(_ url: String, login: String? = nil, password: String? = nil) throws {
        // format: [protocol://]host[:port][/path]
        let regex = /(?<protocol>https?:\/\/)(?<host>[^:\/]+)(?<port>:[0-9]+)?(?<path>\/.*)?/
        guard let match = try regex.wholeMatch(in: url) else {
            throw WebClientError(kind: .generalError, reason: "invalid URL")
        }

        self.login = login
        self.password = password
        if login == nil && password == nil {
            is_auth = false
        } else {
            is_auth = true
        }
        
        is_ssl = match.protocol == "https://"
        host = String(match.host)
        if let _port = match.port {
            port = Int(String(_port[_port.index(after: _port.startIndex)...]))!
        } else {
            port = is_ssl ? 443 : 80
        }
        if (1...65535).contains(port) == false {
            throw WebClientError(kind: .generalError, reason: "invalid proxy port")
        }
        if let _path = match.path {
            path = String(_path[_path.index(after: _path.startIndex)...])
        } else {
            path = "/"
        }
    }
    
    func toTarget(timeout: TimeInterval = 0) -> WebClientTarget {
        return WebClientTarget(is_ssl: is_ssl, is_auth: is_auth, login: login, password: password, host: host, port: port, path: path, timeout: timeout)
    }
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
    let timeout: TimeInterval
    
    func getURL() throws -> URL {
        let url = "http\(is_ssl ? "s" : "")://\(host):\(port ?? 80)/\(path ?? "")"
        guard let retval = URL(string: url) else {
            throw WebClientError(kind: .generalError, reason: "invalid URL")
        }
        return retval
    }
}

// https://developer.apple.com/documentation/foundation/url_loading_system/handling_an_authentication_challenge/performing_manual_server_trust_authentication
final class WebClientDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private let config: AccessNetworkConfig
    
    init(config: AccessNetworkConfig) {
        self.config = config
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
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
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
 
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodHTTPBasic:
            guard let realm = challenge.protectionSpace.realm, let username = config.credentials[realm]?.0, let password = config.credentials[realm]?.1 else {
                completionHandler(.performDefaultHandling, .none)
                break
            }
            let credential = URLCredential(user: username, password: password,
                                           persistence: .forSession)
            completionHandler(.useCredential, credential)
            
        default:
            completionHandler(.performDefaultHandling, .none)
        }
    }
}

final class WebClientSession: Sendable {
    private let config: AccessNetworkConfig
    private let verbose: Bool
    private let url_session: URLSession
    
    init(config: AccessNetworkConfig, verbose: Bool = false) throws {
        self.config = config
        self.verbose = verbose
        let url_session_configuration = URLSessionConfiguration.ephemeral

        // Deal with proxy settings
        var dict = [AnyHashable: Any]()

        if config.is_use_proxy {
            // For URL starting with http://
            dict[kCFNetworkProxiesHTTPEnable as String] = 1
            dict[kCFNetworkProxiesHTTPProxy as String] = config.proxy_host
            dict[kCFNetworkProxiesHTTPPort as String] = config.proxy_port
            
            // For URL starting with https://
            dict[kCFNetworkProxiesHTTPSEnable as String] = 1
            dict[kCFStreamPropertyHTTPSProxyHost as String] = config.proxy_host
            dict[kCFStreamPropertyHTTPSProxyPort as String] = config.proxy_port
            
            url_session_configuration.connectionProxyDictionary = dict
        }
        
        url_session = URLSession(configuration: url_session_configuration, delegate: WebClientDelegate(config: config), delegateQueue: nil)
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
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
    
    // https://developer.apple.com/documentation/swift/withcheckedthrowingcontinuation(isolation:function:_:)?changes=_8
    func fetch(target: WebClientTarget) async throws -> DataRequestResponse {
        return try await withCheckedThrowingContinuation { continuation in
            // continuation: CheckedContinuation<String, any Error>
            do {
                let url = try target.getURL()
                
                let url_request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: target.timeout != 0 ? target.timeout : 3600)

                // No need to ask for uncompressed content, URLSession will deal with the encoding
                // url_request.setValue("deflate", forHTTPHeaderField: "Accept-Encoding")

                let data_task = url_session.dataTask(with: url_request) { [url_request] data, response, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: DataRequestResponse(data, url_request, response))
                    }
                }
                data_task.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func doJobs(target: WebClientTarget, count: Int = 1) async throws {
        var tasks: [Task<DataRequestResponse, Error>] = []
        
        if count > 1 {
            for step in 1...count {
                if verbose {
                    print("launch background task #\(step - 1)")
                }
                let task = Task {
                    return try await fetch(target: target)
                }
                tasks.append(task)
            }
        } else {
            let (_, _, _) = try await fetch(target: target)
        }

        for task in tasks {
            let (_, _, response) = try await task.value
            if verbose {
                print("response from background task: \(String(describing: response))")
            }
        }
    }
}
