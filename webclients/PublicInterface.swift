import Foundation

public struct WebClientError: Error {
    enum ErrorKind {
        case generalError
    }
    let kind: ErrorKind
    var reason: String?
}

func example() async throws {
    let parsed_url = try ParsedURL("http://www.google.com")
    let session = try WebClientSession(config: .unsecureDefaultAccessNetwork)
    
}
