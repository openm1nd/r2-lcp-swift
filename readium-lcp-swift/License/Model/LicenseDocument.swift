//
//  LicenseDocument.swift
//  readium-lcp-swift
//
//  Created by Alexandre Camilleri on 9/6/17.
//
//  Copyright 2018 Readium Foundation. All rights reserved.
//  Use of this source code is governed by a BSD-style license which is detailed
//  in the LICENSE file present in the project repository where this source code is maintained.
//

import Foundation
import R2Shared

/// Document that contains references to the various keys, links to related external resources, rights and restrictions that are applied to the Protected Publication, and user information.
public struct LicenseDocument {

    // The possible rel of Links.
    public enum Rel: String {
        // Location where a Reading System can redirect a User looking for additional information about the User Passphrase.
        case hint
        // Location where the Publication associated with the License Document can be downloaded
        case publication
        // As defined in the IANA registry of link relations: "Conveys an identifier for the link's context."
        case `self`
        // Support resources for the user (either a website, an email or a telephone number).
        case support
        // Location to the Status Document for this license.
        case status
    }
    
    /// Unique identifier for the Provider (URI).
    public let provider: String
    /// Unique identifier for the License.
    public let id: String
    /// Date when the license was first issued.
    public let issued: Date
    /// Date when the license was last updated.
    public let updated: Date
    // Encryption object.
    public let encryption: Encryption
    /// Used to associate the License Document with resources that are not locally available.
    public let links: Links
    /// The user owning the License.
    public let user: User
    /// Rights informations associated with the License Document
    public let rights: Rights
    /// Used to validate the license integrity.
    public let signature: Signature

    /// JSON representation used to parse the License Document.
    let json: String
    let data: Data

    init(data: Data) throws {
        guard let jsonString = String(data: data, encoding: .utf8),
            let deserializedJSON = try? JSONSerialization.jsonObject(with: data) else
        {
            throw ParsingError.malformedJSON
        }

        guard let json = deserializedJSON as? [String: Any],
            let provider = json["provider"] as? String,
            let id = json["id"] as? String,
            let issued = (json["issued"] as? String)?.dateFromISO8601,
            let encryption = json["encryption"] as? [String: Any],
            let links = json["links"] as? [[String : Any]],
            let user = json["user"] as? [String: Any],
            let rights = json["rights"] as? [String: Any],
            let signature = json["signature"] as? [String: Any] else
        {
            throw ParsingError.licenseDocument
        }
        
        self.provider = provider
        self.id = id
        self.issued = issued
        self.updated = (json["updated"] as? String)?.dateFromISO8601 ?? issued
        self.encryption = try Encryption(json: encryption)
        self.links = try Links(json: links)
        self.user = try User(json: user)
        self.rights = try Rights(json: rights)
        self.signature = try Signature(json: signature)
        self.json = jsonString
        self.data = data

        /// Check that links contain rel for Hint and Publication.
        guard link(for: .hint) != nil, link(for: .publication) != nil else {
            throw ParsingError.licenseDocument
        }
    }

    /// Returns the first link containing the given rel.
    public func link(for rel: Rel) -> Link? {
        return links[rel.rawValue]
    }

    /// Gets and expands the URL for the given rel, if it exits.
    /// - Throws: `LCPError.invalidLink` if the URL can't be built.
    func url(for rel: Rel, with parameters: [String: CustomStringConvertible] = [:]) throws -> URL {
        guard let url = link(for: rel)?.url(with: parameters) else {
            throw ParsingError.url(rel: rel.rawValue)
        }
        
        return url
    }

}

extension LicenseDocument: CustomStringConvertible {
    
    public var description: String {
        return "License(\(id))"
    }
    
}
