//
//  WebRTCClient.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/16.
//

import Foundation
import WebRTC

protocol WebRTCClient: class {

}

protocol WebRTCClientDelegate: class {
    func webRTCClinet(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnecctionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didReceieveData data: Data)
}

final class WebRTCClientService: NSObject, WebRTCClient {
    private static let connectionFactory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEnconderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        return RTCPeerConnectionFactory(encoderFactory: videoEnconderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection
    private let rtcAudioSession = RTCAudioSession.sharedInstance()
    private let audionQueue = DispatchQueue(label: "audio-queue")
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio : kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo : kRTCMediaConstraintsValueTrue]
    
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var localDataCannel: RTCDataChannel?
    private var remoteDataChanel: RTCDataChannel?
}
