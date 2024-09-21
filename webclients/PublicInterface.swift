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
    let session = try WebClientSession(config: AccessNetworkConfig(credentials: credentials))
    let (data, request, response) = try await session.fetch(target: parsed_url.toTarget())
    guard let data, let request, let response else {
        throw WebClientError(kind: .generalError, reason: "invalid fetch results")
    }
    let html = try HTML(data: data, response: response)
    print(html.content)
}
