//
//  SensorManager.swift
//  DontTouchYourFace WatchKit Extension
//
//  Created by Annino De Petra on 06/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation
import CoreMotion


final class SensorManager {
	typealias SensorHandler = ([SensorData]?, Error?) -> Void

	enum SensorType {
		case userAccelerometer
		case magnetometer
		case gravity
	}

	struct SensorData {
		let type: SensorType
		let x: Double
		let y: Double
		let z: Double
		var average: Double? = nil // for magnetometer

		var norm: Double {
			let powNorm = pow(x, 2) + pow(y, 2) + pow(z, 2)
			return sqrt(powNorm)
		}

		var isAlertConditionVerified: Bool {
			switch type {
			case .gravity:
				let pitch = atan2(-x, sqrt(pow(y, 2) + pow(z, 2))) * (180 / .pi)
				return pitch >= 20 && pitch <= 100
			case .magnetometer:
				guard let average = average else {
					return false
				}
				return average >= 0.15
			case .userAccelerometer:
				return z >= Double(Threshold.Acceleration.accelerationThreshold)
			}
		}
	}

	private var collectMagnetometerData: Bool = false
	private var magnetometerBuffer: RingBuffer<Double>

	private let queue: OperationQueue = {
		let queue = OperationQueue()
		queue.qualityOfService = .userInteractive
		return queue
	}()

	static let shared = SensorManager()

	lazy var motionManager: CMMotionManager = {
		let motionManager = CMMotionManager()
		motionManager.deviceMotionUpdateInterval = 1/Constant.sensorDataFrequency
		return motionManager
	}()

	var isDeviceSupported: Bool {
		#if DEBUG
		return motionManager.isAccelerometerAvailable
		#else
		return motionManager.isMagnetometerAvailable
		#endif
	}

	private init() {
		magnetometerBuffer = RingBuffer(count: Int(Constant.sensorDataFrequency) * Constant.collectionDataSeconds)
	}

	func startMagnetometerCalibration() {
		collectMagnetometerData = true
		startContinousDataUpdates()
	}

	func stopMagnetometerCalibration() {
		collectMagnetometerData = false
		stopContinousDataUpdates()
	}

	func startContinousDataUpdates(withHandler: SensorHandler? = nil) {
		motionManager.startDeviceMotionUpdates(to: queue) { [weak self] (deviceMotion, error) in
			guard let _self = self else {
				return
			}

			let callHandler: SensorHandler = { deviceMotion, error in
				DispatchQueue.main.async {
					withHandler?(deviceMotion, error)
				}
			}

			// Magnetometer's outcome is an error
			if let error = error {
				callHandler(nil, error)
				return
			}

			guard let deviceMotion = deviceMotion else {
				callHandler(nil, nil)
				return
			}

			let gravity = SensorData(
				type: .gravity,
				x: deviceMotion.gravity.x,
				y: deviceMotion.gravity.y,
				z: deviceMotion.gravity.z
			)

			let accelerometer = SensorData(
				type: .userAccelerometer,
				x: deviceMotion.userAcceleration.x,
				y: deviceMotion.userAcceleration.y,
				z: deviceMotion.userAcceleration.z
			)

			var sensorsData: [SensorData] = [
				gravity,
				accelerometer
			]

			// If the x component of the gravity is not between a certain range
			// it means the user is not raising the hand
			if !gravity.isAlertConditionVerified {
				_self.collectMagnetometerData = true
			} else {
			// Otherwise stop calibrating
				_self.collectMagnetometerData = false
			}

			#if DEBUG
			var magnetometer = SensorData(
				type: .magnetometer,
				x: deviceMotion.userAcceleration.x,
				y: deviceMotion.userAcceleration.y,
				z: deviceMotion.userAcceleration.z
			)
			#else
			var magnetometer = SensorData(
				type: .magnetotemer,
				x: deviceMotion.magneticField.field.x,
				y: deviceMotion.magneticField.field.y,
				z: deviceMotion.magneticField.field.z
			)
			#endif

			// if we are still calibrating, then add the value to the buffer
			if _self.collectMagnetometerData {
				_self.magnetometerBuffer.write(magnetometer.norm)
			}

			// set up the average for the magnetometer
			magnetometer.average = _self.magnetometerBuffer.average
			sensorsData.append(magnetometer)

			callHandler(sensorsData, nil)
		}
	}

	func stopContinousDataUpdates() {
		motionManager.stopDeviceMotionUpdates()
	}
}