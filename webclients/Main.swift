//
//  main.swift
//  webclient
//
//  Created by Alexandre Fenyo on 10/05/2024.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
var is_apple_env = false
#else
var is_apple_env = true
#endif

import ArgumentParser

// TDL :
// proxy
// fonctionnement async sur Windows/Linux

// Usage:
// ./webclients --help

@main
// The struct name is used to create the help by ArgumentParser. With WebClient as the struct name, we would get "USAGE: web-client ..."
struct Webclients: ParsableCommand {
    // -x, --proxy [protocol://]host[:port]
    @Option(name: [.customShort("x"), .customLong("proxy")], help: "Use the specified proxy ([protocol://]host[:port]).")
    var opt_proxy: String? = nil
    
    // -k, --insecure
    //By default, every secure connection curl makes is verified to be secure before the transfer takes place. This option makes curl skip the verification step and proceed without checking
    @Flag(name: [.customShort("k"), .customLong("insecure")], help: "By default, every secure connection curl makes is verified to be secure before the transfer takes place. This option makes curl skip the verification step and proceed without checking.")
    var opt_insecure: Bool = false
    
    // -u, --user name:password
    @Option(name: [.customShort("u"), .customLong("user")], help: "Specify the user name and password to use for server authentication (user:password).")
    var opt_cred: String? = nil
    
    // -U, --proxy-user <user:password>
    @Option(name: [.customShort("U"), .customLong("proxy-user")], help: "Specify the user name and password to use for proxy authentication (user:password).")
    var opt_proxy_cred: String? = nil
    
    // -v, --verbose
    @Flag(name: .shortAndLong, help: "Print debugging informations.")
    var verbose = false
    
    @Argument(help: "Target url to retrieve ([protocol://]host[:port][/path]).")
    var url: String
    
    mutating func run() throws {
        // We run here only if the command line parameters are correct according to the package swift-argument-parser
        
        if verbose {
            print("output mode: verbose")
        }
        
        var is_proxy_ssl = false
        var is_use_proxy = false
        var proxy_host: String?
        var proxy_port: Int = 80
        
        if let opt_proxy {
            is_use_proxy = true
            // format: [protocol://]host[:port]
            let regex = /(?<protocol>https?:\/\/)?(?<host>[^:\/]+)(?<port>:[0-9]+)?/
            guard let match = try regex.wholeMatch(in: opt_proxy) else {
                Self.exit(withError: WebClientError(kind: .generalError, reason: "invalid proxy"))
            }
            
            is_proxy_ssl = match.protocol == "https://"
            
            proxy_host = String(match.host)
            
            if let port = match.port {
                proxy_port = Int(String(port[port.index(after: port.startIndex)...]))!
            }
            
            if verbose {
                print("proxy host: \(proxy_host ?? "")")
                print("proxy port: \(proxy_port)")
            }
        } else {
            if verbose {
                print("direct connection (no proxy)")
            }
        }
        
        if proxy_port != 80 {
            Self.exit(withError: WebClientError(kind: .generalError, reason: "invalid proxy port"))
        }
        
        let client_config = WebClientConfig(is_proxy_ssl: is_proxy_ssl, is_use_proxy: is_use_proxy, proxy_host: proxy_host, proxy_port: proxy_port, is_check_ssl: !opt_insecure)
        
        var is_ssl = false
        var is_check_cert = false
        var is_auth = false
        var login: String?
        var password: String?
        var host: String
        var port: Int = 80
        var path: String?
        
        // format: [protocol://]host[:port][/path]
        let regex = /(?<protocol>https?:\/\/)(?<host>[^:\/]+)(?<port>:[0-9]+)?(?<path>\/.*)?/
        guard let match = try regex.wholeMatch(in: url) else {
            Self.exit(withError: WebClientError(kind: .generalError, reason: "invalid URL"))
        }
        
        is_ssl = match.protocol == "https://"
        
        host = String(match.host)
        
        if let _port = match.port {
            port = Int(String(_port[_port.index(after: _port.startIndex)...]))!
        }
        
        if let _path = match.path {
            path = String(_path[_path.index(after: _path.startIndex)...])
        }
        
        let client_target = WebClientTarget(is_ssl: is_ssl, is_auth: opt_cred != nil, login: login, password: password, host: host, port: port, path: path)
    }

    
}
