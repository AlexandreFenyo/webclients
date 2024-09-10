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

final class WebClientSession: Sendable {
    private let config: WebClientConfig
    private let verbose: Bool

    init(config: WebClientConfig, verbose: Bool = false) throws {
        self.config = config
        self.verbose = verbose
    }
    
    func doJobs(target: WebClientTarget, count: Int = 1) async throws {
        var tasks: [Task<String, Error>] = []

        let url_session_configuration = URLSessionConfiguration.ephemeral
        
        let url_session = URLSession(configuration: url_session_configuration)
        
        (1...count).forEach { step in
            if verbose {
                print("launch background task #\(step - 1)")
            }
            let task = Task {
                try await Task.sleep(nanoseconds: 1000000000)
                
                let (data, response) = try await url_session.data(from: target.getURL())
                print(response)
                
                if verbose {
                    print("running task #\(step - 1)")
                }
                return ""
            }
            tasks.append(task)
        }
        
        for task in tasks {
            let retval = try await task.value
        }

    }
 }
