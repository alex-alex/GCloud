//
//  Entity.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import StructuredData

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
	internal var entityStructuredData: StructuredData {
		var propertiesDict: [String: StructuredData] = [:]
		for (k, v) in properties {
			var data = v.value.structuredData
			if excludeFromIndexes.contains(k) {
				data["excludeFromIndexes"] = true
			}
			propertiesDict[k] = data
		}
		return .infer([
			"key": key.structuredData,
			"properties": .infer(propertiesDict),
		])
	}
}

// MARK: - Public

extension Entity {
	public mutating func put() throws {
		let result = try Client.commit(.upsert(self))
		if let _key = result.keys.first, key = _key { self.key = key }
	}
	
	public func remove() throws {
		try Client.commit(.delete(key))
	}
}
