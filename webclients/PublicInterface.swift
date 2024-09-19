import Foundation

public struct WebClientError: Error {
    enum ErrorKind {
        case generalError
    }
    let kind: ErrorKind
    var reason: String?
}

func example() async throws {
    let parsed_url = try ParsedURL("http://fenyo.net/newweb/cplus/")
    let credentials: CredentialsContainer = ["domotique": (StaticCredentials.login, StaticCredentials.password)]
    
    let session = try WebClientSession(config: .unsecureDefaultAccessNetwork, credentials: credentials)
    let (data, response) = try await session.fetch(target: parsed_url.toTarget())
    print(response)
}
