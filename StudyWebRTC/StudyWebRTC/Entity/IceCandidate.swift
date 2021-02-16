//
//  IceCandidate.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/16.
//

import Foundation
import WebRTC

// RTCIceCandidateのWrapper
struct IceCandidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
    
    init(from iceCandidate: RTCIceCandidate) {
        self.sdp = iceCandidate.sdp
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
    }
    
    var rtcIceCandidate: RTCIceCandidate {
        get {
            RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: self.sdpMid)
        }
    }
}
