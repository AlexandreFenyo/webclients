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
}

class WebClientSession {
    private var url: URL
    private var ignore_ssl: Bool
    
    init(url: String, ignore_ssl: Bool = true, proxy_host: String? = nil, proxy_port: UInt16? = nil) throws {
        guard let _url = URL(string: url) else {
            throw WebClientError(kind: .generalError)
        }
        self.url = _url
        self.ignore_ssl = ignore_ssl
    }
    
    // CONTINUER ici pour sauvegarder proxy_host et proxy_port ou les traiter directement dans init
}
