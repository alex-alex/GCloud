//
//  LatLng.swift
//  GCloud
//
//  Created by Alex Studnicka on 7/17/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

import StructuredData

public struct LatLng {
	public var latitude: Double
	public var longitude: Double
	
	public init(latitude: Double, longitude: Double) {
		self.latitude = latitude
		self.longitude = longitude
	}
}

// MARK: - StructuredDataRepresentable

extension LatLng: StructuredDataRepresentable {
	public var structuredData: StructuredData {
		return ["latitude": .infer(latitude), "longitude": .infer(longitude)]
	}
}

// MARK: - ValueConvertible

extension LatLng: ValueConvertible {
	public var value: Value {
		return .geoPoint(self)
	}
}
