//
//  WebClient.swift
//  webclients
//
//  Created by Alexandre Fenyo on 26/05/2024.
//

import Foundation

enum WebClientError: Error {
    case generalError
}

class WebClient {
    private var url: URL
    private var ignore_ssl: Bool
    
    init(url: String, ignore_ssl: Bool = true, proxy_host: String? = nil, proxy_port: UInt16? = nil) throws {
        do {
            self.url = try URL(string: url)
        } catch {
            
        }
        self.ignore_ssl = ignore_ssl
    }

    
}
