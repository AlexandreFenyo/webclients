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
struct Webclients: AsyncParsableCommand {
    // -x, --proxy [protocol://]host[:port]
    @Option(name: [.customShort("x"), .customLong("proxy")], help: "Use the specified proxy ([protocol://]host[:port]).")
    var opt_proxy: String? = nil
    
    // -k, --insecure
    //By default, every secure connection curl makes is verified to be secure before the transfer takes place. This option makes curl skip the verification step and proceed without checking
    @Flag(name: [.customShort("k"), .customLong("insecure")], help: "By default, every secure connection curl makes is verified to be secure before the transfer takes place. This option makes curl skip the verification step and proceed without checking.")
    var opt_insecure: Bool = false
    
    // -u, --user <name:password>
    @Option(name: [.customShort("u"), .customLong("user")], help: "Specify the user name and password to use for server authentication (user:password).")
    var opt_cred: String? = nil
    
    // -U, --proxy-user <user:password>
    @Option(name: [.customShort("U"), .customLong("proxy-user")], help: "Specify the user name and password to use for proxy authentication (user:password).")
    var opt_proxy_cred: String? = nil
    
    // -v, --verbose
    @Flag(name: .shortAndLong, help: "Print debugging informations.")
    var verbose = false
  
    // -l, --loop <count>
    @Option(name: [.customShort("l"), .customLong("loop")], help: "Make the request <loop> times.")
    var opt_loop: Int = 1

    @Argument(help: "Target url to retrieve ([protocol://]host[:port][/path]).")
    // non debug inside Xcode:
//    var url: String
    // debug inside Xcode:
    var url: String = "debug"

    mutating func run() async throws {
        // We run here only if the command line parameters are correct according to the package swift-argument-parser
  
//        try await example()
//        return;

//        try await MyApp.demo4()
//        return ;
        
        if url == "debug" {
            url = "http://fenyo.net/newweb/cplus/"
            opt_insecure = true
            verbose = true
//            opt_loop = 1
        }
        
        if verbose {
            print("output mode: verbose")
        }
        
        var is_proxy_ssl = false
        var is_use_proxy = false
        var proxy_login: String?
        var proxy_password: String?
        var proxy_host: String?
        var proxy_port = 3128
        
        if opt_loop <= 0 {
            return
        }
        
        if let opt_proxy {
            is_use_proxy = true
            // format: [protocol://]host[:port]
            let regex = /(?<protocol>https?:\/\/)?(?<host>[^:\/]+)(?<port>:[0-9]+)?/
            guard let match = try regex.wholeMatch(in: opt_proxy) else {
                throw WebClientError(kind: .generalError, reason: "invalid proxy")
            }
            
            is_proxy_ssl = match.protocol == "https://"
            
            proxy_host = String(match.host)
            
            if let port = match.port {
                proxy_port = Int(String(port[port.index(after: port.startIndex)...]))!
            }

            if (1...65535).contains(proxy_port) == false {
                throw WebClientError(kind: .generalError, reason: "invalid proxy port")
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
 
        // format: username:password
        if let opt_proxy_cred {
            if is_use_proxy == false {
                Self.exit(withError: WebClientError(kind: .generalError, reason: "proxy credentials without proxy"))
            }
            
            let regex_auth = /(?<username>[^:]*)?:(?<password>[^:]*)?/
            guard let match = try regex_auth.wholeMatch(in: opt_proxy_cred) else {
                Self.exit(withError: WebClientError(kind: .generalError, reason: "invalid proxy credentials"))
            }
            proxy_login = String(match.username ?? "")
            proxy_password = String(match.password ?? "")
            if verbose {
                print("proxy login: \(proxy_login ?? "")")
                print("proxy password: \(proxy_password ?? "")")
            }
        }

        let credentials: CredentialsContainer = ["domotique": (StaticCredentials.login, StaticCredentials.password)]
        let client_config = AccessNetworkConfig(is_proxy_ssl: is_proxy_ssl, is_use_proxy: is_use_proxy, is_auth: opt_proxy_cred != nil, proxy_login: proxy_login, proxy_password: proxy_password, proxy_host: proxy_host, proxy_port: proxy_port, is_check_ssl: !opt_insecure, credentials: credentials)
        
        var is_ssl = false
        var login: String?
        var password: String?
        var host: String
        var port = 80
        var path: String?
        
        // format: [protocol://]host[:port][/path]
        let regex = /(?<protocol>https?:\/\/)(?<host>[^:\/]+)(?<port>:[0-9]+)?(?<path>\/.*)?/
        guard let match = try regex.wholeMatch(in: url) else {
            throw WebClientError(kind: .generalError, reason: "invalid URL")
        }
        
        is_ssl = match.protocol == "https://"
        if verbose {
            print(is_ssl ? "connect to TLS server" : "connect to unencrytped server")
        }

        host = String(match.host)
        if verbose {
            print("remote host: \(host)")
        }

        if let _port = match.port {
            port = Int(String(_port[_port.index(after: _port.startIndex)...]))!
        } else {
            port = is_ssl ? 443 : 80
        }
        if (1...65535).contains(proxy_port) == false {
            throw WebClientError(kind: .generalError, reason: "invalid proxy port")
        }
        if verbose {
            print("remote port: \(port)")
        }

        if let _path = match.path {
            path = String(_path[_path.index(after: _path.startIndex)...])
        }
        if verbose {
            print("remote path: /\(path ?? "")")
        }

        // format: username:password
        if let opt_cred {
            let regex_auth = /(?<username>[^:]*)?:(?<password>[^:]*)?/
            guard let match = try regex_auth.wholeMatch(in: opt_cred) else {
                    throw WebClientError(kind: .generalError, reason: "invalid server credentials")
            }
            login = String(match.username ?? "")
            password = String(match.password ?? "")
            if verbose {
                print("login: \(login ?? "")")
                print("password: \(password ?? "")")
            }
        }
        
        let client_target = WebClientTarget(is_ssl: is_ssl, is_auth: opt_cred != nil, login: login, password: password, host: host, port: port, path: path)
        let session = try WebClientSession(config: client_config, verbose: verbose)
        try await session.doJobs(target: client_target, count: opt_loop)
    }
}
