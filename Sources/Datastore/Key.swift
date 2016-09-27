//
//  Key.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import Core

public indirect enum Key {
	case empty(kind: String, namespace: String?, parent: Key?)
	case id(id: Int64, kind: String, namespace: String?, parent: Key?)
	case name(name: String, kind: String, namespace: String?, parent: Key?)
}

// MARK: - Error

public enum KeyError: Error {
	case noPath
}

// MARK: - Init

extension Key {
	public init(namespace: String? = nil, kind: String, id: Int64? = nil, name: String? = nil, parent: Key? = nil) {
		if let id = id {
			self = .id(id: id, kind: kind, namespace: namespace, parent: parent)
		} else if let name = name {
			self = .name(name: name, kind: kind, namespace: namespace, parent: parent)
		} else {
			self = .empty(kind: kind, namespace: namespace, parent: parent)
		}
	}
}

// MARK: - Properties

extension Key {
	public var kind: String {
		switch self {
		case .empty(let key):
			return key.kind
		case .id(let key):
			return key.kind
		case .name(let key):
			return key.kind
		}
	}
	
	public var id: Int64? {
		switch self {
		case .id(let key):
			return key.id
		default:
			return nil
		}
	}
	
	public var name: String? {
		switch self {
		case .name(let key):
			return key.name
		default:
			return nil
		}
	}
	
	public var namespace: String? {
		switch self {
		case .empty(let key):
			return key.namespace
		case .id(let key):
			return key.namespace
		case .name(let key):
			return key.namespace
		}
	}
	
	public var parent: Key? {
		switch self {
		case .empty(let key):
			return key.parent
		case .id(let key):
			return key.parent
		case .name(let key):
			return key.parent
		}
	}
}

// MARK: - Private

extension Key {
	fileprivate func makePath(array: inout [Map]) throws {
		if let parent = parent {
			try parent.makePath(array: &array)
		}
		var path: Map = ["kind": try kind.asMap()]
		switch self {
		case .id(let key):
			path["id"] = try String(key.id).asMap()
		case .name(let key):
			path["name"] = try key.name.asMap()
		case .empty:
			break
		}
		array.append(path)
	}
}

// MARK: - MapConvertible

extension Key: MapConvertible {
	public init(map: Map) throws {
		var path = try map["path"].asArray()
		
		guard path.count > 0 else { throw KeyError.noPath }
		
		let namespace = try map["partitionId"]["namespaceId"].asString()
		
		let pathEl = path.removeLast()
		let kind = try pathEl["kind"].asString()
		
		let parent: Key?
		do {
			var map = map
			map["path"] = try path.asMap()
			parent = try Key(map: map)
		} catch let error as KeyError where error == .noPath {
			parent = nil
		}
		
		if let idStr = try? pathEl["id"].asString(), let id = Int64(idStr) {
			self = .id(id: id, kind: kind, namespace: namespace, parent: parent)
		} else if let name = try? pathEl["name"].asString() {
			self = .name(name: name, kind: kind, namespace: namespace, parent: parent)
		} else {
			self = .empty(kind: kind, namespace: namespace, parent: parent)
		}
	}
	
	public func asMap() throws -> Map {
		var path: [Map] = []
		try makePath(array: &path)
		
		var data: Map = [
			"path": try path.asMap()
		]
		
		if let namespace = namespace {
			data["partitionId"] = [
				"namespaceId": try namespace.asMap()
			]
		}
		
		return data
	}
}

// MARK: - ValueConvertible

extension Key: ValueConvertible {
	public var value: Value { return .key(self) }
}

// MARK: - Equatable

extension Key: Equatable {}

public func ==(lhs: Key, rhs: Key) -> Bool {
	switch (lhs, rhs) {
	case (.empty(let l), .empty(let r)) where l.kind == r.kind && l.namespace == r.namespace && l.parent == r.parent:
		return true
	case (.id(let l), .id(let r)) where l.id == r.id && l.kind == r.kind && l.namespace == r.namespace && l.parent == r.parent:
		return true
	case (.name(let l), .name(let r)) where l.name == r.name && l.kind == r.kind && l.namespace == r.namespace && l.parent == r.parent:
		return true
	default:
		return false
	}
}
