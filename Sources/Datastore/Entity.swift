//
//  Entity.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import Core

public protocol Entity: ValueConvertible {
	static var kind: String { get }
	var key: Key { get set }
	var excludeFromIndexes: [String] { get }
	var properties: [String: ValueConvertible] { get }
}

// MARK: - Defaults

extension Entity {
	public var excludeFromIndexes: [String] {
		return []
	}
	
	public var value: Value {
		return .entity(self)
	}
}

// MARK: - Internal

extension Entity {
	internal func asEntityMap() throws -> Map {
		var propertiesDict: [String: Map] = [:]
		for (k, v) in properties {
			var data = try v.value.asMap()
			if excludeFromIndexes.contains(k) {
				data["excludeFromIndexes"] = true
			}
			propertiesDict[k] = data
		}
		return try [
			"key": try key.asMap(),
			"properties": try propertiesDict.asMap(),
		].asMap()
	}
}

// MARK: - Public

extension Entity {
	public mutating func put() throws {
		let result = try Client.commit(.upsert(self))
		if let _key = result.keys.first, let key = _key { self.key = key }
	}
	
	public func remove() throws {
		try Client.commit(.delete(key))
	}
}
