//
//  ContentViewModel.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/21.
//

import Foundation
import WebRTC

class ContentViewModel: ObservableObject {
    
    private var webClient: WebRTCClientService
    private var signalingClient: SignalClientService
    
    @Published var localSdpState: SDPState = .none
    @Published var remoteSdpState: SDPState = .none
    @Published var speakerState: SpeakerState = .off {
        didSet {
            self.changeSpeakerState()
        }
    }
    @Published var muteState: MuteState = .off {
        didSet {
            self.changeMuteState()
        }
    }
    @Published var localCandidateCount:Int = 0
    @Published var remoteCandidateCount: Int = 0
    @Published var signalingState: SignalingState = .notConnect
    var webRTCState: String {
        get {
            self.iceConnectionState.description.capitalized
        }
    }
    @Published private var iceConnectionState: RTCIceConnectionState = .new
    
    init() {
        webClient = WebRTCClientService(Config.default.webRTCIceServers)
        let provider = NativeWebSocket(url: Config.default.singnalingServer)
        signalingClient = SignalClientService(webSocket: provider)
        webClient.delegate = self
        signalingClient.delegate = self
    }
    
    func connect() {
        self.signalingClient.connect()
    }
    
    func offer() {
        self.webClient.offer { sdp in
            self.localSdpState = .exist
            self.signalingClient.send(sdp: sdp)
        }
    }
    
    func answer() {
        self.webClient.answer { localSdp in
            self.localSdpState = .exist
            self.signalingClient.send(sdp: localSdp)
        }
    }
    
    private func changeSpeakerState() {
        switch self.speakerState {
        case .on:
            webClient.spekerOn()
        case .off:
            webClient.speakerOff()
        }
    }
    
    private func changeMuteState() {
        switch self.muteState {
        case .on:
            webClient.muteAudio()
        case .off:
            webClient.unmuteAudio()
        }
    }
    
    func sendMessage(message: String) {
        guard let data = message.data(using: .utf8) else {
            return
        }
        self.webClient.sendData(data)
    }
}

extension ContentViewModel: WebRTCClientDelegate {
    func webRTCClinet(_ client: WebRTCClientService, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        self.localCandidateCount += 1
        self.signalingClient.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClientService, didChangeConnecctionState state: RTCIceConnectionState) {
        self.iceConnectionState = state
    }
    
    func webRTCClient(_ client: WebRTCClientService, didReceieveData data: Data) {
        guard let message = String(data: data, encoding: .utf8) else {
            return
        }
        print(message)
    }
}

extension ContentViewModel: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalClientService) {
        DispatchQueue.main.async {
            self.signalingState = .connect
        }
    }
    
    func signalClientDidDisConnect(_ signalClinet: SignalClientService) {
        DispatchQueue.main.async {
            self.signalingState = .notConnect
        }
    }
    
    func signalClient(_ signalCilent: SignalClientService, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        self.webClient.set(remoteSdp: sdp, completion: { error in
            DispatchQueue.main.async {
                self.remoteSdpState = .exist
            }
        })
    }
    
    func signalClient(_ signalCilent: SignalClientService, didReceiveCandinate candinate: RTCIceCandidate) {
        self.webClient.set(remoteCandidate: candinate)
        DispatchQueue.main.async {
            self.remoteCandidateCount += 1
        }
    }
}
