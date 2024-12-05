//
//  MotionManager.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 12/4/24.
//

import Foundation
import CoreMotion
import SwiftUI

final class MotionManager:NSObject, ObservableObject {
    @Published var x = 0.0
    @Published var y = 0.0
    @Published var z = 0.0
    
    let motionManager = CMMotionManager()
    
    func startGyroMotionSensor(){
        if motionManager.isGyroAvailable{
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self]gyroMotion, error in
                guard let gyroMotion = gyroMotion else{
                    return
                }
                self?.updateMotionData(gyroMotion: gyroMotion)
            }
        }
    }
    
    private func updateMotionData(gyroMotion: CMDeviceMotion){
        withAnimation(.bouncy(duration:0.5)){
            x = gyroMotion.rotationRate.x
            y = gyroMotion.rotationRate.y
            z = gyroMotion.rotationRate.z
        }
    }
    
    func stopGeyroMotionSensor(){
        motionManager.stopDeviceMotionUpdates()
    }
}
