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

func getCharset(data: Data, response: URLResponse) throws -> String.Encoding? {
    print("XXXXX: getCharset()")

    var encoding: String.Encoding?

    if let encoding = response.textEncodingName {
        switch encoding {
        case "utf-8":
            return String.Encoding.utf8
        default:
            break
        }
    }



    let x = String(bytes: data, encoding: .utf8)
//    let x = String(bytes: data, encoding: .isoLatin1)
//    let x = String(bytes: data, encoding: .ascii)

    print("chaine: \(x)")
    
    print("encoding: \(response.textEncodingName)")

    return encoding
}
