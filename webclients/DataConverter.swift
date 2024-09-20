//
//  DataConverter.swift
//  webclients
//
//  Created by Alexandre Fenyo on 20/09/2024.
//

import Foundation

// Determining the charset used to encode data: https://html.spec.whatwg.org/multipage/parsing.html#determining-the-character-encoding

func getCharset(data: Data, response: URLResponse) throws -> String.Encoding? {
    print("XXXXX: getCharset()")

    var encoding: String.Encoding?
    CONTINUER ICI
    if let encoding = response.textEncodingName {
        switch encoding {
        case "utf-8":
            return String.Encoding.utf8
        default:
            return String.Encoding.ascii
        }
    }
    print(response.textEncodingName)
    

    return nil
}
