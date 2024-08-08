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
// ./webclients --help

@main
struct MyCommand: ParsableCommand {
    @Argument(help: "The phrase to repeat.")
    var phrase: String = "toto"
    
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int? = nil
    
    mutating func run() throws {
        let repeatCount = count ?? 2
        for _ in 0..<repeatCount {
            print(phrase)
        }
    }
}

