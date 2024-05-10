//
//  main.swift
//  webclient
//
//  Created by Alexandre Fenyo on 10/05/2024.
//

import Foundation

enum AuthError: Error {
    case tooManyErrors
}

class MyDemo4: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    var auth_error_cnt = 0

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("XXXXX: didReceive TLS")
        let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, urlCredential)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("XXXXX: didReceive Auth")
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
            auth_error_cnt += 1
            if auth_error_cnt > 2 {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            let username = StaticCredentials.login
            let password = StaticCredentials.password
            let credential = URLCredential(user: username, password: password,
                                           persistence: .forSession)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func demo() async throws {
        let url = URL(string: "https://fenyo.net/newweb/cplus/")!
        // URLSessionConfiguration.ephemeral pour éviter la mise en cache
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self, delegateQueue: nil)
       let (data, response) = try await session.data(from: url)
        print(response)
        let data_str = String(decoding: data, as: UTF8.self)
        print(data_str)
    }
}

class MyDemo3: NSObject, URLSessionTaskDelegate {
    private var auth_error_cnt = 0
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("XXXXX: didReceive")
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
            auth_error_cnt += 1
            if auth_error_cnt > 2 {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            let username = StaticCredentials.login
            let password = StaticCredentials.password
            let credential = URLCredential(user: username, password: password,
                                           persistence: .forSession)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func demo() async throws {
        let url = URL(string: "http://fenyo.net/newweb/cplus/")!
        // URLSessionConfiguration.ephemeral pour éviter la mise en cache
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self, delegateQueue: nil)
       let (data, response) = try await session.data(from: url)
        print(response)
        let data_str = String(decoding: data, as: UTF8.self)
        print(data_str)
    }
}

// Trust the certificate even if not valid
class MyDemo2: NSObject, URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("XXXXX: didReceive")
        let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, urlCredential)
    }

    func demo() async throws {
        let url = URL(string: "https://www.fenyo.net/abc")!
        // URLSessionConfiguration.ephemeral pour éviter la mise en cache
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self, delegateQueue: nil)
       let (data, response) = try await session.data(from: url)
        print(response)
        let data_str = String(decoding: data, as: UTF8.self)
        print(data_str)
    }
}

@main
class MyApp {
    static func main() async throws {
        try await demo4()
    }

    // Auth, ignore TLS certificate
    static func demo4() async throws {
        let my_demo = MyDemo4()
        try await my_demo.demo()
    }

    // Auth, no TLS
    static func demo3() async throws {
        let my_demo = MyDemo3()
        try await my_demo.demo()
    }

    // No auth, ignore TLS certificate
    static func demo2() async throws {
        let my_demo = MyDemo2()
        try await my_demo.demo()
    }

    // No auth, no TLS
    static func demo1() async throws {
        let url = URL(string: "http://www.fenyo.net/abc")!
        let (data, response) = try await URLSession.shared.data(from: url)
        print(response)
        let data_str = String(decoding: data, as: UTF8.self)
        print(data_str)
    }
}
