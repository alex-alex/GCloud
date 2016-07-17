//
//  Mutation.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import StructuredData

public enum Mutation {
	case insert(Entity)
	case update(Entity)
	case upsert(Entity)
	case delete(Key)
}

// MARK: - StructuredDataRepresentable

extension Mutation: StructuredDataRepresentable {
	public var structuredData: StructuredData {
		switch self {
		case .insert(let entity):
			return ["insert": entity.entityStructuredData]
		case .update(let entity):
			return ["update": entity.entityStructuredData]
		case .upsert(let entity):
			return ["upsert": entity.entityStructuredData]
		case .delete(let key):
			return ["delete": key.structuredData]
		}
	}
}
