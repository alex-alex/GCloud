//
//  Value.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import Core

public enum Value {
	case null
	case bool(Bool)
	case int(Int64)
	case double(Double)
	case timestamp(String)
	case key(Key)
	case string(String)
	case blob(String)
	case geoPoint(LatLng)
	case entity(Entity)
	case array([Value])
}

// MARK: - Error

public enum ValueError: Error {
	case incompatibleType
}

// MARK: - StructuredDataRepresentable

extension Value: MapFallibleRepresentable {
	public func asMap() throws -> Map {
		switch self {
		case .null:
			return ["nullValue": .null]
		case .bool(let bool):
			return ["booleanValue": .bool(bool)]
		case .int(let string):
			return ["integerValue": .string(String(string))]
		case .double(let double):
			return ["doubleValue": .double(double)]
		case .timestamp(let string):
			return ["timestampValue": .string(string)]
		case .key(let key):
			return ["keyValue": try key.asMap()]
		case .string(let string):
			return ["stringValue": .string(string)]
		case .blob(let string):
			return ["blobValue": .string(string)]
		case .geoPoint(let latLng):
			return ["geoPointValue": try latLng.asMap()]
		case .entity(let entity):
			return ["entityValue": try entity.asEntityMap()]
		case .array(let values):
			return ["arrayValue": ["values": try values.map({ try $0.asMap() }).asMap()]]
		}
	}
}

// MARK: - Getters

extension Value {
	public func get<T>() throws -> T {
		switch self {
		case .bool(let value as T):
			return value
		case .int(let value as T):
			return value
		case .double(let value as T):
			return value
		case .timestamp(let value as T):
			return value
		case .key(let value as T):
			return value
		case .string(let value as T):
			return value
		case .blob(let value as T):
			return value
		case .geoPoint(let value as T):
			return value
		case .entity(let value as T):
			return value
		case .array(let value as T):
			return value
		default: break
		}
		throw ValueError.incompatibleType
	}
	
	public func get<T>() -> T? {
		return try? get()
	}
}

// MARK: - LiteralConvertibles

extension Value: ExpressibleByNilLiteral {
	public init(nilLiteral value: Void) {
		self = .null
	}
}

extension Value: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Value...) {
		self = .array(elements)
	}
}

//// MARK: - Equatable
//
//extension Value: Equatable {}
//
//public func ==(lhs: Value, rhs: Value) -> Bool {
//	switch (lhs, rhs) {
//	case (.null, .null):
//		return true
//	case (.bool(let l), .bool(let r)) where l == r:
//		return true
//	case (.int(let l), .int(let r)) where l == r:
//		return true
//	case (.double(let l), .double(let r)) where l == r:
//		return true
//	case (.timestamp(let l), .timestamp(let r)) where l == r:
//		return true
//	case (.key(let l), .key(let r)) where l == r:
//		return true
//	case (.string(let l), .string(let r)) where l == r:
//		return true
//	case (.blob(let l), .blob(let r)) where l == r:
//		return true
//	case (.geoPoint(let l), .geoPoint(let r)) where l == r:
//		return true
////	case (.entity(let l), .entity(let r)) where l == r:
////		return true
//	case (.array(let l), .array(let r)) where l == r:
//		return true
//	default:
//		return false
//	}
//}

// MARK: - ValueConvertible

public protocol ValueConvertible {
	var value: Value { get }
}

extension Value: ValueConvertible {
	public var value: Value { return self }
}

extension Bool: ValueConvertible {
	public var value: Value { return .bool(self) }
}

extension Int: ValueConvertible {
	public var value: Value { return .int(Int64(self)) }
}

extension Int32: ValueConvertible {
	public var value: Value { return .int(Int64(self)) }
}

extension Int64: ValueConvertible {
	public var value: Value { return .int(self) }
}

extension Float: ValueConvertible {
	public var value: Value { return .double(Double(self)) }
}

extension Double: ValueConvertible {
	public var value: Value { return .double(self) }
}

extension String: ValueConvertible {
	public var value: Value { return .string(self) }
}
