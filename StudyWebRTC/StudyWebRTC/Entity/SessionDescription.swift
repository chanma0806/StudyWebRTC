//
//  SessionDescription.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/16.
//

import Foundation
import WebRTC

// RTCSdpTypeのWrapper
enum SdyType: String, Codable {
    case offer, prAnswer, answer
    
    var rtcSdpType: RTCSdpType {
        switch self {
        case .offer:    return .offer
        case .prAnswer: return .prAnswer
        case .answer:   return .answer
        }
    }
}
// RTCSessionDescriptionのWrapper
struct SessionDescription: Codable {
    let sdp: String
    let type: SdyType
    
    init(from rtcSessionDescription: RTCSessionDescription) {
        self.sdp = rtcSessionDescription.sdp
        
        switch rtcSessionDescription.type {
        case .offer:
            self.type = .offer
        case .prAnswer:
            self.type = .prAnswer
        case .answer:
            self.type = .answer
        @unknown default:
            fatalError("unknown RTCSdpType -> \(rtcSessionDescription.type.rawValue)")
        }
    }
    
    var rtcSessionDescription: RTCSessionDescription {
        get {
            RTCSessionDescription(type: self.type.rtcSdpType, sdp: self.sdp)
        }
    }
}
