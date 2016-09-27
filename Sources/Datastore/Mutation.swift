//
//  Mutation.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import Core

public enum Mutation {
	case insert(Entity)
	case update(Entity)
	case upsert(Entity)
	case delete(Key)
}

// MARK: - MapFallibleRepresentable

extension Mutation: MapFallibleRepresentable {
	public func asMap() throws -> Map {
		switch self {
		case .insert(let entity):
			return ["insert": try entity.asEntityMap()]
		case .update(let entity):
			return ["update": try entity.asEntityMap()]
		case .upsert(let entity):
			return ["upsert": try entity.asEntityMap()]
		case .delete(let key):
			return ["delete": try key.asMap()]
		}
	}
}
