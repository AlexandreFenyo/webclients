//
//  WebClient.swift
//  webclients
//
//  Created by Alexandre Fenyo on 26/05/2024.
//

// Saving this CLI into a binary file: Product / Archive

import Foundation

// Network access config
public struct AccessNetworkConfig: Sendable {
    private let is_proxy_ssl: Bool
    private let is_use_proxy: Bool
    private let is_auth: Bool
    private let proxy_login: String?
    private let proxy_password: String?
    private let proxy_host: String?
    private let proxy_port: Int?
    fileprivate let is_check_ssl: Bool
    private let credentials: CredentialsContainer

    static let defaultAccessNetwork = AccessNetworkConfig()
    static let unsecureDefaultAccessNetwork = AccessNetworkConfig(is_check_ssl: false)

    init(is_proxy_ssl: Bool = false, is_use_proxy: Bool = false, is_auth: Bool = false, proxy_login: String? = nil, proxy_password: String? = nil, proxy_host: String? = nil, proxy_port: Int? = nil, is_check_ssl: Bool = false, credentials: CredentialsContainer = CredentialsContainer()) {
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

public struct ParsedURL {
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
    
    func toTarget() -> WebClientTarget {
        return WebClientTarget(is_ssl: is_ssl, is_auth: is_auth, login: login, password: password, host: host, port: port, path: path)
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
    
    func getURL() throws -> URL {
        let url = "http\(is_ssl ? "s" : "")://\(host):\(port ?? 80)/\(path ?? "")"
        guard let retval = URL(string: url) else {
            throw WebClientError(kind: .generalError, reason: "invalid URL")
        }
        return retval
    }
}

public class WebClientSessionDelegate: NSObject, URLSessionDelegate {
    private let config: AccessNetworkConfig

    init(config: AccessNetworkConfig) {
        self.config = config
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
}

public typealias CredentialsContainer = [String: (String, String)]

public final class WebClientSession: Sendable {
    private let config: AccessNetworkConfig
    private let verbose: Bool
    private let url_session: URLSession
    private let credentials: CredentialsContainer
    
    let del: WebClientSessionDelegate
    
    init(config: AccessNetworkConfig, credentials: CredentialsContainer = CredentialsContainer(), verbose: Bool = false) throws {
        self.config = config
        self.verbose = verbose
        self.credentials = credentials
        let url_session_configuration = URLSessionConfiguration.ephemeral
        del = WebClientSessionDelegate(config: config)
        url_session = URLSession(configuration: url_session_configuration, delegate: del, delegateQueue: nil)
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
    func fetch(target: WebClientTarget) async throws -> DataAndResponse {
        return try await withCheckedThrowingContinuation { continuation in
            // continuation: CheckedContinuation<String, any Error>
            do {
                let url = try target.getURL()
                var url_request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
                url_request.setValue("deflate", forHTTPHeaderField: "Accept-Encoding")
                print("req:\(String(describing: url_request.allHTTPHeaderFields))")
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
            let (_, response) = try await fetch(target: target)
            print("HTTP response: \(String(describing: response))")
        }

        for task in tasks {
            let (_, _) = try await task.value
        }
    }
}
