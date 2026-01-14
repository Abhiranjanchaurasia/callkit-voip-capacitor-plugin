//
//  CallSessionState.swift
//  Pods
//
//  Created by Abhiranjan Chaurasiya on 18/12/25.
//

import Foundation

final class CallSessionState {
    static let shared: CallSessionState = CallSessionState()
    private init() {}

    // Set to true only on the device that answered
    var hasAnsweredCall: Bool = false

    func reset() {
        hasAnsweredCall = false
    }
}
