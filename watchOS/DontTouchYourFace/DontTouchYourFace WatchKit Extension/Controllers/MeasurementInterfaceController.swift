//
//  InterfaceController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion

final class MeasurementInterfaceController: WKInterfaceController {
	@IBOutlet private var dataLabel: WKInterfaceLabel!

	private lazy var coreMotionManager = CMMotionManager()
	private lazy var detectionManager: DetectionManager = {
		return DetectionManager(coreMotionManager: self.coreMotionManager)
	}()

	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
		detectionManager.collectData { [weak self] result in
			guard let _self = self else {
				return
			}

			switch result {
			case .error(let errorString):
				_self.dataLabel.setText(errorString)
			case .data(let acceleration):
				_self.dataLabel.setText("Data \(acceleration.z)")
			}
		}
    }
}
