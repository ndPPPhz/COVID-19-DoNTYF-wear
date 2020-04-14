//
//  CircleBuffer.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 08/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

struct RingBuffer<T> {
	private(set) var array: [T?]
	private var writeIndex = 0

	init(count: Int) {
		array = [T?](repeating: nil, count: count)
	}

	mutating func write(_ element: T) {
	  array[writeIndex % array.count] = element
	  writeIndex += 1
	}
}

extension RingBuffer where T == Double {
	var average: Double {
		return array.compactMap { $0 }.reduce(0, +) / Double(array.count)
	}
}
