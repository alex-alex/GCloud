//
//  Datastore.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import Zewo
import HTTPSClient
import JSONWebToken

internal let clientContentNegotiaton = ContentNegotiationMiddleware(types: JSONMediaType(), URLEncodedFormMediaType(), mode: .client)

public final class Datastore {
	internal var projectId: String
	internal var keyFilename: String
	internal var token: Header? = nil
	
	private init(projectId: String, keyFilename: String) {
		self.projectId = projectId
		self.keyFilename = keyFilename
	}
}

// MARK: - Instance

extension Datastore {
	internal static var instance: Datastore? = nil
	
	public static func setup(projectId: String, keyFilename: String) {
		Datastore.instance = Datastore(projectId: projectId, keyFilename: keyFilename)
	}
}

// MARK: - Error

extension Datastore {
	public enum Error: ErrorProtocol {
		case notInitialized
		case invalidKeyFile
	}
}

// MARK: - Token

extension Datastore {
	internal func getToken() throws -> Header {
		if let token = token {
			return token
		} else {
			return try requestToken()
		}
	}
	
	private func requestToken() throws -> Header {
		let file = try File(path: keyFilename)
		let data = try file.readAllBytes()
		let json = try JSONStructuredDataParser().parse(data)
		
		guard let keyStr = json["private_key"]?.stringValue else { throw Datastore.Error.invalidKeyFile }
		let key = try SSLKey(string: keyStr)
		let algorithm = JSONWebToken.Algorithm.RS256(key: key)
		
		var payload = JSONWebToken.Payload()
		payload.structuredData["iss"] = json["client_email"]
		payload.structuredData["scope"] = "https://www.googleapis.com/auth/datastore"
		payload.structuredData["aud"] = "https://www.googleapis.com/oauth2/v4/token"
		payload.expire(after: Int(1.hour))
		let token = try JSONWebToken.encode(payload: payload, algorithm: algorithm)
		
		let client = try HTTPSClient.Client(uri: "https://www.googleapis.com:443")
		let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=" + token
		let response = try client.post("/oauth2/v4/token", headers: ["Content-Type": "application/x-www-form-urlencoded"], body: body, middleware: clientContentNegotiaton)
		
		guard let accessToken = response.content?["access_token"]?.stringValue else { throw ServerError.internalServerError }
		let newToken = Header("Bearer \(accessToken)")
		
		self.token = newToken
		return newToken
	}
}

// MARK: - Request

extension Datastore {
	internal static func request(method: String, body: StructuredData) throws -> (response: Response, content: StructuredData) {
		guard let datastore = Datastore.instance else { throw Error.notInitialized }
		let uri = "/v1beta3/projects/\(datastore.projectId):\(method)"
		let bodyData = try JSONStructuredDataSerializer().serialize(body)
		let client = try HTTPSClient.Client(uri: "https://datastore.googleapis.com:443")
		let response = try client.post(uri, headers: ["Authorization": datastore.getToken()], body: bodyData, middleware: clientContentNegotiaton)
		if response.status == .unauthorized {
			datastore.token = nil
			return try request(method: method, body: body)
		} else if let content = response.content {
			return (response, content)
		} else {
			throw ServerError.internalServerError
		}
	}
}

// MARK: - Allocate IDs

extension Datastore {
	public static func allocateIds(_ keys: Key...) throws -> [Key] {
		return try allocateIds(keys: keys)
	}
	
	public static func allocateIds(keys: [Key]) throws -> [Key] {
		let body: StructuredData = ["keys": .infer(keys.map({ $0.structuredData }))]
		let (_, content) = try request(method: "allocateIds", body: body)
		let keys: [StructuredData] = try content.get("keys")
		return try keys.map({ try Key(structuredData: $0) })
	}
}

// MARK: - Commit

extension Datastore {
	public static func commit(transaction: String? = nil, _ mutations: Mutation...) throws -> (indexUpdates: Int, keys: [Key?]) {
		return try commit(transaction: transaction, mutations: mutations)
	}
	
	public static func commit(transaction: String? = nil, mutations: [Mutation]) throws -> (indexUpdates: Int, keys: [Key?]) {
		var body: StructuredData = [
			"mutations": .infer(mutations.map({ $0.structuredData }))
		]
		
		if let transaction = transaction {
			body["mode"] = "TRANSACTIONAL"
			body["transaction"] = .infer(transaction)
		} else {
			body["mode"] = "NON_TRANSACTIONAL"
		}
		
		let (_, content) = try request(method: "commit", body: body)
		let indexUpdates: Int = try content.get("indexUpdates")
		
		let mutationResults: [StructuredData] = try content.get("mutationResults")
		let keys: [Key?] = try mutationResults.map { result in
			if let keyDict = result["key"] {
				return try Key(structuredData: keyDict)
			} else {
				return nil
			}
		}
		
		return (indexUpdates, keys)
	}
}
