//
//  LatLng.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import Core

public struct LatLng {
	public var latitude: Double
	public var longitude: Double
	
	public init(latitude: Double, longitude: Double) {
		self.latitude = latitude
		self.longitude = longitude
	}
}

// MARK: - MapFallibleRepresentable

extension LatLng: MapFallibleRepresentable {
	public func asMap() throws -> Map {
		return try ["latitude": latitude.asMap(), "longitude": longitude.asMap()]
	}
}

// MARK: - ValueConvertible

extension LatLng: ValueConvertible {
	public var value: Value {
		return .geoPoint(self)
	}
}
