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

enum AuthError: Error {
    case tooManyErrors
}

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

    
    @Flag(name: .shortAndLong, help: "Print debugging informations.")
    var verbose = false

    @Argument(help: "Target url to retrieve ([protocol://]host[:port][/path]).")
    var url: String

    mutating func run() throws {
        if CommandLine.arguments.count == 1 {
            let exec_name = CommandLine.arguments[0]
            print("""
            XXXUsage: \(exec_name) [options...] <url>
            \(exec_name): try '\(exec_name) --help' or '\(exec_name) -h' for more information
            """)
            return
        }
    }
}
