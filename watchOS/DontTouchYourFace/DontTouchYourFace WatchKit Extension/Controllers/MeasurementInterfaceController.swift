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
	@IBOutlet private var thresholdLabel: WKInterfaceLabel!
	@IBOutlet private var thresholdSlider: WKInterfaceSlider!
	@IBOutlet private var startStopButton: WKInterfaceButton!
	@IBOutlet var calibrateButton: WKInterfaceButton!

	private lazy var numberFormatter: NumberFormatter = {
		let numberFormatter = NumberFormatter()
		numberFormatter.numberStyle = .decimal
		numberFormatter.maximumFractionDigits = 2
		return numberFormatter
	}()

	private let detectionManager = DetectionManager(threshold: Constant.initialThreshold)
	private var crownAccumulator = 0.0

	override func awake(withContext context: Any?) {
        super.awake(withContext: context)


		setupSlider()
		calibrateButton.setBackgroundColor(Constant.Color.blue)
		dataLabel.setText("Press start")

		updateThreshold(Constant.initialThreshold)
		crownSequencer.delegate = self

		detectionManager.delegate = self
		detectionManager.sensorCallback = { [weak self] result in
			guard let _self = self else {
				return
			}

			switch result {
			case .error(let errorString):
				_self.dataLabel.setText(errorString)
			case .data(let sensorsData):

				let gravityValues = sensorsData.first { $0.type == .gravity }
				let accelerometerValues = sensorsData.first { $0.type == .userAccelerometer }

				guard
					let xGravityComponent = gravityValues?.x,
					let zAccelerationComponent = accelerometerValues?.z
				else {
					return
				}

				// Check wirst side for asin
				let theha = asin(xGravityComponent) * 180 / .pi
				let dataString = String(format: "X Θ: %.2f \nZ acc: %.2f", theha, zAccelerationComponent)

				#if !DEBUG
				// Add Magnetometer
				#endif
				_self.dataLabel.setText(dataString)
			}
		}
    }

	override func willActivate() {
		super.willActivate()
		crownSequencer.focus()
	}

	private func setupSlider() {
		let steps = (Constant.maxValue - Constant.minValue) / Constant.step
		thresholdSlider.setNumberOfSteps(Int(steps))
	}

	@IBAction func didChangeSliderValue(_ value: Float) {
		updateThreshold(value)
	}

	@IBAction func didTapStartStop() {
		detectionManager.toggleState()
	}

	@IBAction func didTapCalibrate() {
		let isRecalibration = true
		pushController(withName: CalibrationInterfaceController.identifier, context: isRecalibration)
	}

	private func updateThreshold(_ value: Float) {
		guard value <= Constant.maxValue && value >= Constant.minValue else {
			return
		}
		thresholdLabel.setText("\(value)")
		thresholdSlider.setValue(value)
		detectionManager.setThreshold(value)
	}

	private func setStopActivityUI() {
		startStopButton.setBackgroundColor(Constant.Color.green)
		startStopButton.setTitle(Constant.startButtonText)
		dataLabel.setText(Constant.notReadingDataText)
	}

	private func setRunningActivityUI() {
		startStopButton.setBackgroundColor(Constant.Color.red)
		startStopButton.setTitle(Constant.stopButtonText)
		dataLabel.setText("")
	}
}

extension MeasurementInterfaceController: WKCrownDelegate {
	func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
		crownAccumulator += rotationalDelta
		if crownAccumulator > Constant.crownSensitivity {
			updateThreshold(detectionManager.threshold + Constant.step)
		   crownAccumulator = 0.0
		} else if crownAccumulator < -Constant.crownSensitivity {
			updateThreshold(detectionManager.threshold - Constant.step)
		   crownAccumulator = 0.0
		}
	}
}

extension MeasurementInterfaceController: DetectionManagerDelegate {
	func manager(_ manager: DetectionManager, didChangeState state: DetectionManager.State) {
		switch state {
		case .running:
			setRunningActivityUI()
		case .stopped:
			setStopActivityUI()
		}
	}
}
