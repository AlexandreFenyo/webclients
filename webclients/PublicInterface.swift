import Foundation

public struct WebClientError: Error {
    enum ErrorKind {
        case generalError
    }
    let kind: ErrorKind
    var reason: String?
}

func example() async throws {
    let parsed_url = try ParsedURL("http://fenyo.net/tmp/enc/tst.u8")
    let credentials: CredentialsContainer = ["domotique": (StaticCredentials.login, StaticCredentials.password)]
    let session = try WebClientSession(config: AccessNetworkConfig(credentials: credentials))
    let (data, request, response) = try await session.fetch(target: parsed_url.toTarget())
    guard let data, let request, let response else {
        throw WebClientError(kind: .generalError, reason: "invalid fetch results")
    }
    print(response)
    if response.mimeType == "text/html" {
        print("HTML")
    }
        
    try getCharset(data: data, response: response)
}
