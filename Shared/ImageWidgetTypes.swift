//
//  ImageWidgetTypes.swift
//  smpl-widgets
//
//  Created by Nitish on 03/22/26.
//

import Foundation

struct ImageSlotMetadata: Codable, Identifiable, Hashable {
	let id: String
	let displayName: String
	let fileName: String
	let createdAt: Date
}
