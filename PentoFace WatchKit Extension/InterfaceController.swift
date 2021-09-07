//
//  InterfaceController.swift
//  PentoFace WatchKit Extension
//
//  Created by Nicholaos Mouzourakis on 2020-03-29.
//  Copyright © 2020 NEVUM X. All rights reserved.
//

import WatchKit
import SpriteKit

class InterfaceController: WKInterfaceController {
	@IBOutlet weak var scene: WKInterfaceSKScene!
	weak var watchFaceScene: FaceScene!
	
	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		
		let faceScene = FaceScene(fileNamed: "WatchFace")
		faceScene!.camera!.setScale(min(184.0 / WKInterfaceDevice.current().screenBounds.size.width, 224.0 / WKInterfaceDevice.current().screenBounds.size.height))
		scene.presentScene(faceScene)
		watchFaceScene = faceScene
    }
	
	override func didAppear() {
		super.didAppear()
		hideTime()
	}
	
	override func didDeactivate() {
		super.didDeactivate()
		watchFaceScene.pause()
	}
	
	override func willActivate() {
		super.willActivate()
		watchFaceScene.resume()
	}
}
