//
//  MessageInterfaceController.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import WatchKit

final class MessageInterfaceController: WKInterfaceController {
	@IBOutlet private var centredLabel: WKInterfaceLabel!

	override func awake(withContext context: Any?) {
		super.awake(withContext: context)

		if let text = context as? String {
			centredLabel.setText(text)
		}
	}
}