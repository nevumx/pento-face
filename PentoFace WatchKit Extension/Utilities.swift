//
//  Utilities.swift
//  PentoFace WatchKit Extension
//
//  Created by Nicholaos Mouzourakis on 2020-04-03.
//  Copyright © 2020 NEVUM X. All rights reserved.
//

import SpriteKit

var is24Hour: Bool {
	get {
		return DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)!.firstIndex(of: "a") == nil
	}
}

extension SKNode {
	var globalPosition: CGPoint { get { convert(CGPoint(), to: scene!) } }
}

func interpolateTowards(current: Double, destination: Double, speed: Double, deltaTime: Double) -> Double
{
	let distance = destination - current;

	if abs(distance) < 0.001 {
		return destination;
	}

	let delta = distance * min(max(deltaTime * speed, 0), 1)

	return current + delta;
}

extension CGPoint {
	static func - (left: CGPoint, right: CGPoint) -> CGPoint {
		CGPoint(x: left.x - right.x, y: left.y - right.y)
	}
	static func -= (left: inout CGPoint, right: CGPoint) {
		left = left - right
	}
	static func + (left: CGPoint, right: CGPoint) -> CGPoint {
		CGPoint(x: left.x + right.x, y: left.y + right.y)
	}
	static func += (left: inout CGPoint, right: CGPoint) {
		left = left + right
	}
	static func * (left: CGPoint, right: CGFloat) -> CGPoint {
		CGPoint(x: left.x * right, y: left.y * right)
	}
	func distance(to other: CGPoint) -> CGFloat {
		let xDistance = x - other.x
		let yDistance = y - other.y
		return sqrt(xDistance * xDistance + yDistance * yDistance)
	}
}

extension Date {
	var hours: UInt8 {
		get {
			var hour = UInt8(Calendar.current.component(.hour, from: self))
			if (!is24Hour) {
				hour = hour % 12
				if hour == 0 {
					return 12
				}
				return hour
			}
			return hour
		}
	}
	var minutes: UInt8 {
		get {
			UInt8(Calendar.current.component(.minute, from: self))
		}
	}
	var seconds: UInt8 {
		get {
			UInt8(Calendar.current.component(.second, from: self))
		}
	}
}
