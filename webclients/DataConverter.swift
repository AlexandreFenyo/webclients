//
//  DataConverter.swift
//  webclients
//
//  Created by Alexandre Fenyo on 20/09/2024.
//

import Foundation

// Determining the charset used to encode data: https://html.spec.whatwg.org/multipage/parsing.html#determining-the-character-encoding

// é is in those files with different encoding:
// http://fenyo.net/tmp/enc/tst.lat1
// http://fenyo.net/tmp/enc/tst.u8
// Building a string from those encodings with String(bytes:encoding:):
// String : data en iso, encod vers utf8 => nil
// String : data en iso, encod vers iso => ok
// String : data en iso, encod vers ascii => ok
// String : data en iso, encod vers nonLossyASCII => nil
// String : data en utf8, encod vers utf8 => ok
// String : data en utf8, encod vers iso => pas nil mais contenu faux
// String : data en utf8, encod vers ascii => pas nil mais contenu faux
// String : data en utf8, encod vers nonLossyASCII => nil
// Solution : passer par ascii sur les 1024 premiers octets (cf. https://html.spec.whatwg.org/multipage/parsing.html#determining-the-character-encoding)

// La norme HTTP 1.1 indique que le codage par défaut est ISO-8859-1 (https://www.w3.org/International/articles/http-charset/index.fr)
// The HTML5 specification encourages web developers to use the UTF-8 character set. (https://www.w3schools.com/Html/html_charset.asp))

// <%@ page contentType="text/html; charset=UTF-8" %>
// HTML4: <meta http-equiv="Content-Type" content="text/html;charset=ISO-8859-1">
// HTML5: <meta charset="Windows-1252">

struct HTML {
    let content: String

    static let charsetNameToCharset: [String: String.Encoding] = ["utf-8": String.Encoding.utf8, "ansi": String.Encoding.ascii, "windows-1252": String.Encoding.ascii, "iso-8859-1": String.Encoding.isoLatin1, "iso-8859-2": String.Encoding.isoLatin2]
    
    init(data: Data, response: URLResponse) throws {
        if response.mimeType != "text/html" {
            throw WebClientError(kind: .generalError, reason: "invalid mime type: \(String(describing: response.mimeType))")
        }
        let charset = try Self.getCharset(data: data, response: response)
        guard let content = String(bytes: data, encoding: charset) else {
            throw WebClientError(kind: .generalError, reason: "can not convert data to string with encoding \(charset)")
        }
        self.content = content
    }

    // Use only when mime-type is text/html
    private static func getCharset(data: Data, response: URLResponse) throws -> String.Encoding {
        // default encoding (from HTML spec)
        var encoding: String.Encoding = .isoLatin1
        
        // use HTTP header if no encoding in the HTML content
        if let enc_header = response.textEncodingName?.lowercased(), let enc_header_charset = Self.charsetNameToCharset[enc_header] {
            encoding = enc_header_charset
            // do not look in HTML content if we have a content-type header (on 2024/09/21, http://google.com returns a header saying Latin1 but the content has a meta tag saying UTF-8, and String(bytes:encoding:) does not work with UTF-8 encoding on the returned content)
            return encoding
        }
        
        // look for encoding in the HTML content
        guard let head = String(bytes: data[0..<min(1024, data.indices.last!)], encoding: .ascii) else {
            return encoding
        }
        let regex = /charset=(?<charset>[a-zA-Z0-9-]+)/
        guard let match = try regex.firstMatch(in: head) else {
            return encoding
        }
        if let encoding = Self.charsetNameToCharset[match.charset.lowercased()] {
            return encoding
        }
        
        return encoding
    }
}
