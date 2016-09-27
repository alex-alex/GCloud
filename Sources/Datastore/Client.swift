//
//  Datastore.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import Foundation
import Core
import HTTPClient
import JSONWebToken

internal let clientContentNegotiaton = ContentNegotiationMiddleware(mediaTypes: [JSON.self, URLEncodedForm.self], mode: .client)

public final class Client {
	internal var projectId: String
	internal var keyUrl: URL
	internal var token: String? = nil
	
	fileprivate init(projectId: String, keyUrl: URL) {
		self.projectId = projectId
		self.keyUrl = keyUrl
	}
}

// MARK: - Instance

extension Client {
	internal static var instance: Client? = nil
	
	public static func setup(projectId: String, keyUrl: URL) {
		Client.instance = Client(projectId: projectId, keyUrl: keyUrl)
	}
}

// MARK: - Error

public enum ClientError: Error {
	case notInitialized
	case invalidKeyFile
}

// MARK: - Token

extension Client {
	internal func getToken() throws -> String {
		if let token = token {
			return token
		} else {
			return try requestToken()
		}
	}
	
	private func requestToken() throws -> String {
		let json: Map
		let key: OpenSSL.Key
		do {
			let data = try Data(contentsOf: keyUrl)
			json = try JSONMapParser().parse(data)
			let keyStr = try json["private_key"].asString()
			key = try OpenSSL.Key(pemString: keyStr)
		} catch {
			throw ClientError.invalidKeyFile
		}
		
		let algorithm = JSONWebToken.Algorithm.rs256(key: key)
		
		var payload = JSONWebToken.Payload()
		payload.map["iss"] = json["client_email"]
		payload.map["scope"] = "https://www.googleapis.com/auth/datastore"
		payload.map["aud"] = "https://www.googleapis.com/oauth2/v4/token"
		payload.expire(after: Int(1.hour))
		let token = try JSONWebToken.encode(payload: payload, algorithm: algorithm)
		
		let client = try HTTPClient.Client(url: "https://www.googleapis.com:443")
		let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=" + token
		let response = try client.post("/oauth2/v4/token", headers: ["Content-Type": "application/x-www-form-urlencoded"], body: body, middleware: [clientContentNegotiaton])
		
		guard let content = response.content else { throw HTTPError.internalServerError }
		let accessToken = try content["access_token"].asString()
		let newToken = "Bearer \(accessToken)"
		
		self.token = newToken
		return newToken
	}
}

// MARK: - Request

extension Client {
	internal static func request(method: String, body: Map? = nil) throws -> (response: Response, content: Map) {
		guard let datastore = Client.instance else { throw ClientError.notInitialized }
		let uri = "/v1/projects/\(datastore.projectId):\(method)"
		let bodyData: Data
		if let body = body {
			bodyData = try JSONMapSerializer().serialize(body)
		} else {
			bodyData = Data()
		}
		let client = try HTTPClient.Client(url: "https://datastore.googleapis.com:443")
		let response = try client.post(uri, headers: ["Authorization": datastore.getToken()], body: bodyData, middleware: [clientContentNegotiaton])
		if response.status == .unauthorized {
			datastore.token = nil
			return try request(method: method, body: body)
		} else if let content = response.content {
			return (response, content)
		} else {
			throw HTTPError.internalServerError
		}
	}
}

// MARK: - Allocate IDs

extension Client {
	public static func allocateIds(_ keys: Key...) throws -> [Key] {
		return try allocateIds(keys: keys)
	}
	
	public static func allocateIds(keys: [Key]) throws -> [Key] {
		let body: Map = ["keys": try keys.map({ try $0.asMap() }).asMap()]
		let (_, content) = try request(method: "allocateIds", body: body)
		let keys: [Map] = try content.get("keys")
		return try keys.map({ try Key(map: $0) })
	}
}

// MARK: - Begin Transaction

extension Client {
	public static func beginTransaction() throws -> String {
		return try request(method: "beginTransaction").content.get("transaction")
	}
}

// MARK: - Commit

extension Client {
	@discardableResult
	public static func commit(transaction: String? = nil, _ mutations: Mutation...) throws -> (indexUpdates: Int, keys: [Key?]) {
		return try commit(transaction: transaction, mutations: mutations)
	}
	
	@discardableResult
	public static func commit(transaction: String? = nil, mutations: [Mutation]) throws -> (indexUpdates: Int, keys: [Key?]) {
		var body: Map = [
			"mutations": try mutations.map({ try $0.asMap() }).asMap()
		]
		
		if let transaction = transaction {
			body["mode"] = "TRANSACTIONAL"
			body["transaction"] = try transaction.asMap()
		} else {
			body["mode"] = "NON_TRANSACTIONAL"
		}
		
		let (_, content) = try request(method: "commit", body: body)
		let indexUpdates: Double = try content.get("indexUpdates")
		
		let mutationResults: [Map] = try content.get("mutationResults")
		let keys: [Key?] = try mutationResults.map { result in
			let keyDict = result["key"]
			return try Key(map: keyDict)
		}
		
		return (Int(indexUpdates), keys)
	}
}

// MARK: - Begin Transaction

extension Client {
	public static func rollback(transaction: String) throws {
		let response = try request(method: "rollback", body: ["transaction": try transaction.asMap()])
		guard response.response.status == .ok else { throw HTTPError.internalServerError }
	}
}
