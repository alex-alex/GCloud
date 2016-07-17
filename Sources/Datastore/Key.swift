//
//  Key.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import StructuredData

public indirect enum Key {
	case empty(kind: String, namespace: String?, parent: Key?)
	case id(id: Int64, kind: String, namespace: String?, parent: Key?)
	case name(name: String, kind: String, namespace: String?, parent: Key?)
}

// MARK: - Error

extension Key {
	public enum Error: ErrorProtocol {
		case noPath
		case noKind
	}
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
	private func makePath(array: inout [StructuredData]) {
		if let parent = parent {
			parent.makePath(array: &array)
		}
		var path: StructuredData = ["kind": .infer(kind)]
		switch self {
		case .id(let key):
			path["id"] = .infer(String(key.id))
		case .name(let key):
			path["name"] = .infer(key.name)
		case .empty:
			break
		}
		array.append(path)
	}
}

// MARK: - StructuredDataConvertible

extension Key: StructuredDataConvertible {
	public init(structuredData: StructuredData) throws {
		guard var path = structuredData["path"]?.arrayValue where path.count > 0 else { throw Error.noPath }
		
		let namespace = structuredData["partitionId"]?["namespaceId"]?.stringValue
		
		let pathEl = path.removeLast()
		guard let kind = pathEl["kind"]?.stringValue else { throw Error.noKind }
		
		let parent: Key?
		do {
			var structuredData = structuredData
			structuredData["path"] = .infer(path)
			parent = try Key(structuredData: structuredData)
		} catch let error as Error where error == .noPath {
			parent = nil
		}
		
		if let idStr = pathEl["id"]?.stringValue, id = Int64(idStr) {
			self = .id(id: id, kind: kind, namespace: namespace, parent: parent)
		} else if let name = pathEl["name"]?.stringValue {
			self = .name(name: name, kind: kind, namespace: namespace, parent: parent)
		} else {
			self = .empty(kind: kind, namespace: namespace, parent: parent)
		}
	}
	
	public var structuredData: StructuredData {
		var path: [StructuredData] = []
		makePath(array: &path)
		
		var data: StructuredData = [
		                           	"path": .infer(path)
		]
		
		if let namespace = namespace {
			data["partitionId"] = [
			                      	"namespaceId": .infer(namespace)
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
