//
//  FaceScene.swift
//  PentoFace WatchKit Extension
//
//  Created by Nicholaos Mouzourakis on 2020-03-29.
//  Copyright © 2020 NEVUM X. All rights reserved.
//

import SpriteKit

fileprivate let anticipatedAnimationDuration = 0.5
fileprivate let animationSpeed = 5.0
fileprivate let animationScaleMultiplier = CGFloat(2.0)

fileprivate class TimeOffsetNode {
	private static let secondOffsetPerUnit = 1.0 / 300
	
	let node: SKNode
	let baseNode: SKNode
	let getDisplayNumber: (Date) -> UInt8
	let displayDigitTens: Bool
	var finishedWaitingForOpeningAnimation: Bool
	var digitToWaitFor: UInt8 = 0
	
	init(node: SKNode, baseNode: SKNode, getDisplayNumber: @escaping (Date) -> UInt8, displayDigitTens: Bool, finishedWaitingForOpeningAnimation: Bool) {
		self.node = node
		self.baseNode = baseNode
		self.getDisplayNumber = getDisplayNumber
		self.displayDigitTens = displayDigitTens
		self.finishedWaitingForOpeningAnimation = finishedWaitingForOpeningAnimation
	}
	
	func getDisplayDigit(displayNumber: UInt8) -> UInt8 {
		displayDigitTens ? (displayNumber / 10) : (displayNumber % 10)
	}

	func getNodeDate(baseDate: Date) -> Date {
		let positionDiff = baseNode.position - node.position
		return baseDate + TimeInterval(positionDiff.x - positionDiff.y) * TimeOffsetNode.secondOffsetPerUnit + anticipatedAnimationDuration
	}
	
	private func getCurrentDigit(baseDate: Date) -> UInt8 {
		let nodeDate = getNodeDate(baseDate: baseDate)
		return finishedWaitingForOpeningAnimation ? getDisplayDigit(displayNumber: getDisplayNumber(nodeDate)) : (nodeDate.seconds % 10)
	}
	
	func incrementNextNumberToWaitFor(baseDate: Date) {
		finishedWaitingForOpeningAnimation = true
		digitToWaitFor = getCurrentDigit(baseDate: baseDate)
	}
	
	func shouldAnimate(baseDate: Date) -> Bool {
		finishedWaitingForOpeningAnimation ? getCurrentDigit(baseDate: baseDate) != digitToWaitFor : getCurrentDigit(baseDate: baseDate) == digitToWaitFor
	}
}

fileprivate enum AnimationState {
	case WaitingToEnter, AnimatingEnter, WaitingToExit, AnimatingExit, Finished
}

fileprivate class PentomiNode : TimeOffsetNode {
	private let nodePool: PentominoPool
	private let digitNode: DigitNode
	
	private(set) var animationState: AnimationState = .WaitingToEnter
	
	init(nodePool: PentominoPool, digitNode: DigitNode, baseNode: SKNode, pentominoInstance: PentominoInstance, getDisplayNumber: @escaping (Date) -> UInt8, displayDigitTens: Bool, digitToWaitFor: UInt8, finishedWaitingForOpeningAnimation: Bool) {
		self.nodePool = nodePool
		self.digitNode = digitNode
		
		super.init(node: nodePool.getPentomino(
			newPosition: self.digitNode.node.position
				+ CGPoint(x: CGFloat(pentominoInstance.columnOffset) * self.digitNode.node.xScale, y: -CGFloat(pentominoInstance.rowOffset) * self.digitNode.node.yScale),
			newScale: CGPoint(x: self.digitNode.node.xScale * (pentominoInstance.flipped ? -1 : 1),
							  y: self.digitNode.node.yScale),
			newRotation: -CGFloat(pentominoInstance.rotations) * 90.0,
			newAlpha: 0, newZPosition: 1), baseNode: baseNode, getDisplayNumber: getDisplayNumber, displayDigitTens: displayDigitTens, finishedWaitingForOpeningAnimation: finishedWaitingForOpeningAnimation)
		
		var upperLeftPoint = self.node.position
		for child in self.node.children {
			upperLeftPoint.x = min(upperLeftPoint.x, child.globalPosition.x)
			upperLeftPoint.y = max(upperLeftPoint.y, child.globalPosition.y)
		}
		self.node.position += self.node.position - upperLeftPoint
		
		self.node.xScale *= animationScaleMultiplier
		self.node.yScale *= animationScaleMultiplier
		
		self.digitToWaitFor = digitToWaitFor
	}
	
	deinit {
		nodePool.returnPentomino(pentomino: node)
	}
	
	func update(withDate now: Date, deltaTime: Double) {
		if shouldAnimate(baseDate: now) {
			switch animationState {
			case .WaitingToEnter:
				animationState = .AnimatingEnter
				incrementNextNumberToWaitFor(baseDate: now)
				FaceScene.showSeparator = true
			case .AnimatingEnter, .WaitingToExit:
				animationState = .AnimatingExit
			default:
				break
			}
		}

		if [.AnimatingEnter, .AnimatingExit].contains(animationState) {
			node.yScale = CGFloat(interpolateTowards(current: Double(node.yScale), destination: Double(digitNode.node.yScale), speed: animationSpeed, deltaTime: deltaTime))
			node.xScale = node.xScale < 0 ? -node.yScale : node.yScale
			node.alpha = CGFloat(interpolateTowards(current: Double(node.alpha), destination: animationState == .AnimatingExit ? 0 : 1, speed: animationSpeed, deltaTime: deltaTime))
			node.zPosition = CGFloat(interpolateTowards(current: Double(node.zPosition), destination: animationState == .AnimatingExit ? -1 : 0, speed: animationSpeed, deltaTime: deltaTime))
			
			switch animationState {
			case .AnimatingEnter:
				if node.alpha == 1 {
					animationState = .WaitingToExit
				}
			case .AnimatingExit:
				if node.alpha == 0 {
					animationState = .Finished
				}
			default:
				break
			}
		}
	}
	
	func exit() {
		animationState = .AnimatingExit
	}
}

fileprivate class DigitNode : TimeOffsetNode {
	private var pentomiNodes = [PentomiNode]()
	
	init(node: SKNode, baseNode: SKNode, getDisplayNumber: @escaping (Date) -> UInt8, displayDigitTens: Bool, digitToWaitFor: UInt8?) {
		super.init(node: node, baseNode: baseNode, getDisplayNumber: getDisplayNumber, displayDigitTens: displayDigitTens, finishedWaitingForOpeningAnimation: false)
		
		self.digitToWaitFor = digitToWaitFor ?? ((getNodeDate(baseDate: Date()).seconds + 1) % 10)
	}
	
	func update(withDate now: Date, pentominoPools: [Pentomino:PentominoPool], deltaTime: Double) {
		if shouldAnimate(baseDate: now) {
			let newSolution = solutions[Int(getDisplayDigit(displayNumber: getDisplayNumber(getNodeDate(baseDate: now))))].randomElement()
			for pentominoInstance in newSolution! {
				pentomiNodes.append(PentomiNode(nodePool: pentominoPools[pentominoInstance.pentomino]!, digitNode: self, baseNode: baseNode, pentominoInstance: pentominoInstance, getDisplayNumber: getDisplayNumber, displayDigitTens: displayDigitTens, digitToWaitFor: digitToWaitFor, finishedWaitingForOpeningAnimation: finishedWaitingForOpeningAnimation))
			}
			incrementNextNumberToWaitFor(baseDate: now)
		}
		for i in (0..<pentomiNodes.count).reversed() {
			pentomiNodes[i].update(withDate: now, deltaTime: deltaTime)
			if pentomiNodes[i].animationState == .Finished {
				pentomiNodes.remove(at: i)
			}
		}
	}
	
	func reset(digitToWaitFor: UInt8) {
		for pentomiNode in pentomiNodes {
			pentomiNode.exit()
		}
		finishedWaitingForOpeningAnimation = false
		self.digitToWaitFor = digitToWaitFor
	}
}

fileprivate class PentominoPool {
	private let prototype: SKNode
	private var inactives = Set<SKNode>()
	
	init(prototype: SKNode) {
		self.prototype = prototype
	}
	
	func getPentomino(newPosition: CGPoint, newScale: CGPoint, newRotation: CGFloat, newAlpha: CGFloat, newZPosition: CGFloat) -> SKNode {
		if inactives.count <= 0 {
			let newChild = prototype.copy() as! SKNode
			prototype.scene!.addChild(newChild)
			inactives.insert(newChild)
		}
		let selectedChild = inactives.randomElement()!
		inactives.remove(selectedChild)
		selectedChild.position = newPosition
		selectedChild.xScale = newScale.x
		selectedChild.yScale = newScale.y
		selectedChild.zRotation = newRotation * .pi / 180
		selectedChild.alpha = newAlpha
		selectedChild.zPosition = newZPosition
		selectedChild.isHidden = false
		return selectedChild
	}
	
	func returnPentomino(pentomino: SKNode) {
		pentomino.isHidden = true
		inactives.insert(pentomino)
	}
}

class FaceScene : SKScene {
	private var pentominoPools = [Pentomino:PentominoPool]()
	private var digitNodes = [DigitNode]()
	private var hourMinuteSeparator: SKNode!
	private var previousTime: TimeInterval?
	private var preventUpdate = false
	fileprivate static var showSeparator = false
	
	override func sceneDidLoad() {
		super.sceneDidLoad()
		
		for pentomino in Pentomino.allCases {
			pentominoPools[pentomino] = PentominoPool(prototype: childNode(withName: pentomino.rawValue)!)
		}
		hourMinuteSeparator = childNode(withName: "HMSeparator")
	}
	
	override func update(_ currentTime: TimeInterval) {
		super.update(currentTime)
		
		if preventUpdate {
			return
		}
		
		if digitNodes.count <= 0 {
			let baseAnimationNode = childNode(withName: "DigitS1")!
			digitNodes.append(DigitNode(node: childNode(withName: "DigitH10")!, baseNode: baseAnimationNode, getDisplayNumber:
				{ $0.hours }, displayDigitTens: true, digitToWaitFor: nil))
			digitNodes.append(DigitNode(node: childNode(withName: "DigitH1")!, baseNode: baseAnimationNode, getDisplayNumber:
				{ $0.hours }, displayDigitTens: false, digitToWaitFor: digitNodes[0].digitToWaitFor))
			digitNodes.append(DigitNode(node: childNode(withName: "DigitM10")!, baseNode: baseAnimationNode, getDisplayNumber:
				{ $0.minutes }, displayDigitTens: true, digitToWaitFor: digitNodes[0].digitToWaitFor))
			digitNodes.append(DigitNode(node: childNode(withName: "DigitM1")!, baseNode: baseAnimationNode, getDisplayNumber:
				{ $0.minutes }, displayDigitTens: false, digitToWaitFor: digitNodes[0].digitToWaitFor))
			digitNodes.append(DigitNode(node: childNode(withName: "DigitS10")!, baseNode: baseAnimationNode, getDisplayNumber:
				{ $0.seconds }, displayDigitTens: true, digitToWaitFor: digitNodes[0].digitToWaitFor))
			digitNodes.append(DigitNode(node: baseAnimationNode, baseNode: baseAnimationNode, getDisplayNumber: { $0.seconds }, displayDigitTens: false, digitToWaitFor: digitNodes[0].digitToWaitFor))
		}
		
		if previousTime == nil {
			previousTime = currentTime
			return
		}
		
		let deltaTime = currentTime - previousTime!
		previousTime = currentTime
		
		hourMinuteSeparator.alpha = CGFloat(interpolateTowards(current: Double(hourMinuteSeparator.alpha), destination: FaceScene.showSeparator ? 1 : 0, speed: animationSpeed, deltaTime: deltaTime))
		
		let now = Date()
		for digitNode in digitNodes {
			digitNode.update(withDate: now, pentominoPools: pentominoPools, deltaTime: deltaTime)
		}
	}
	
	func pause() {
		preventUpdate = true
	}
	
	func resume() {
		if preventUpdate {
			let now = Date()
			for digitNode in digitNodes {
				digitNode.reset(digitToWaitFor: (digitNodes[0].getNodeDate(baseDate: now).seconds + 1) % 10)
			}
			FaceScene.showSeparator = false
			previousTime = nil
			preventUpdate = false
		}
	}
}
