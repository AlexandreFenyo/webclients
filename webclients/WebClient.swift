//
//  WebClient.swift
//  webclients
//
//  Created by Alexandre Fenyo on 26/05/2024.
//

// Saving this CLI into a binary file: Product / Archive

import Foundation

enum WebClientError: Error {
    case generalError
}

// La configuration pour accéder au réseau
struct WebClientConfig {
    
}

// Le serveur cible
struct WebClientTarget {
    
}



class WebClientSession {
    private var url: URL
    private var ignore_ssl: Bool
    
    init(url: String, ignore_ssl: Bool = true, proxy_host: String? = nil, proxy_port: UInt16? = nil) throws {
   
        guard let _url = URL(string: url) else {
            throw WebClientError.generalError
        }
        self.url = _url
        self.ignore_ssl = ignore_ssl
    }

    // CONTINUER ici pour sauvegarder proxy_host et proxy_port ou les traiter directement dans init
}
