//
//  WebRTCClient.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/16.
//

import Foundation
import WebRTC
import os

protocol WebRTCClientDelegate: class {
    func webRTCClinet(_ client: WebRTCClientService, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClientService, didChangeConnecctionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClientService, didReceieveData data: Data)
}

final class WebRTCClientService: NSObject {
    
    @available(*, unavailable)
    override init() {
        fatalError()
    }
    
    required init(_ iceServers: [String]) {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: iceServers)]
        // webRTCライブラリ内の通信形式を指定するフラグ unifiedPlanが標準化されている方式らしい
        // https://webrtc.org/getting-started/unified-plan-transition-guide
        config.sdpSemantics = .unifiedPlan
        // ネットワークの変更を監視して他のクライアントに候補を送信する設定
        config.continualGatheringPolicy = .gatherContinually
        
        // DtlsSrtpKeyAgreement -> 通信を暗号化を有効化する設定値
        let constrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
            
        self.peerConnection = WebRTCClientService.connectionFactory.peerConnection(with: config,
                                                                                   constraints: constrains,
                                                                                   delegate: nil)
        super.init()
        self.createMediaSenders()
        self.configureAudioSession()
        self.peerConnection.delegate = self
    }
    
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
    
    private func createMediaSenders() {
        /** peerConnectionに通信時に扱いたいトリームを追加する */

        let streamId = "stream"
        
        // Audioの追加
        let audioTrack = self.createAudioTrack()
        self.peerConnection.add(audioTrack, streamIds: [streamId])
        
        // Videoの追加
        let videoTrack = self.createVideoTrack()
        self.peerConnection.add(videoTrack, streamIds: [streamId])
        
        // チャンネルの追加
        if let dataChannel = self.createDataChannel() {
            dataChannel.delegate = self
            self.localDataCannel = dataChannel
        }
    }
    
    private func configureAudioSession() {
        // Audioの設定を変更する場合は排他制御をライブラリ指示する必要がある
        self.rtcAudioSession.lockForConfiguration()
        defer {
            self.rtcAudioSession.unlockForConfiguration()
        }
        
        do {
            // デバイスのオーディオ設定
            let options: AVAudioSession.CategoryOptions = []
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue, with: options)
            // オーディオのユースケースをVoIPで指定する
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
            
        } catch let error {
            os_log("%s -> %s", #function, "\(error.localizedDescription)")
        }
    }
    
    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCClientService.connectionFactory.audioSource(with: audioConstrains)
        let audioTrack = WebRTCClientService.connectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }
    
    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = WebRTCClientService.connectionFactory.videoSource()
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        let videoTrack = WebRTCClientService.connectionFactory.videoTrack(with: videoSource, trackId: "video0")
        return videoTrack
    }
    
    private func createDataChannel() -> RTCDataChannel? {
        // ピア間のコネクション内で管理されるチャンネル
        // https://developer.mozilla.org/ja/docs/Web/API/RTCDataChannel
        let config = RTCDataChannelConfiguration()
        guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            return nil
        }
        
        return dataChannel
    }
    
    func sendData(_ data: Data) {
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        self.remoteDataChanel?.sendData(buffer)
    }
    
    // MARK: Signaling
    func offer(completion: @escaping(_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        self.peerConnection.offer(for: constrains) { sdp, error  in
            guard let sdpContext = sdp else {
                return
            }
            
            self.peerConnection.setLocalDescription(sdpContext) { error in
                completion(sdpContext)
            }
        }
    }
    
    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains, optionalConstraints: nil)
        self.peerConnection.answer(for: constrains) { (sdp, error) in
            guard let sdp = sdp else {
                return
            }
            
            self.peerConnection.setLocalDescription(sdp) { error in
                completion(sdp)
            }
        }
    }
    
    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    func set(remoteCandidate: RTCIceCandidate) {
        self.peerConnection.add(remoteCandidate)
    }
    
    // Media
    func startCaptureLocalVideo(render: RTCVideoRenderer) {
        guard let capture = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }
        
        guard let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
            
              let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
              }).last,
              
              let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last)
        else {
            return
        }
        
        capture.startCapture(with: frontCamera, format: format, fps: Int(fps.maxFrameRate))
        self.localVideoTrack?.add(render)
    }
    
    func renderRemoteVideo(to render: RTCVideoRenderer) {
        self.remoteVideoTrack?.add(render)
    }
    
    private func configurateAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        defer {
            self.rtcAudioSession.unlockForConfiguration()
        }
        
        do {
            let options: AVAudioSession.CategoryOptions = []
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue, with: options)
            try self.rtcAudioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        }
        catch let error {
            os_log("%s: error changing AVAudioSession catgory -> %s", #function, error.localizedDescription )
        }
    }
}

// MARK: RTCPeerConnectionDelegate

extension WebRTCClientService: RTCPeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        os_log("%s", #function)
    }
    
    // https://www.w3.org/TR/webrtc/#dom-rtcsignalingstate
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        os_log("%s: stateChanged %s", #function, "\(stateChanged)")
    }
    
    // https://www.w3.org/TR/mediacapture-streams/#mediastream
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        os_log("$s: didAdd stream %s", #function, "\(stream)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        os_log("%s: didRemove stream %d", #function, "\(stream)")
    }
    
    // https://www.w3.org/TR/webrtc/#dfn-ice-connection-state
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        os_log("%s: newState %d", #function, "\(newState)")
    }
    
    // https://www.w3.org/TR/webrtc/#rtcicegatheringstate-enum
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        os_log("%s: newState %s", #function, "\(newState)")
    }
    
    // https://www.w3.org/TR/webrtc/#dom-rtcicecandidate
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        os_log("%s: didGenerate %s", #function, "\(candidate)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        os_log("%s: didRemove %s", #function, "\(candidates)")
    }
    
    // https://www.w3.org/TR/webrtc/#dom-rtcdatachannel
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        os_log("%s: didOpen %s", #function, "\(dataChannel)")
    }
    
    
}

// MARK: RTCDataChannelDelegate

extension WebRTCClientService: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        // readyState -> https://developer.mozilla.org/en-US/docs/Web/API/RTCDataChannel/readyState
        os_log("%s: state -> %d", #function, dataChannel.readyState.rawValue)
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        // 通信先から受信したデータ
        self.delegate?.webRTCClient(self, didReceieveData: buffer.data)
    }
}

// MARK: track control utility
extension WebRTCClientService {
    // https://www.w3.org/TR/webrtc/#dom-rtcrtpsender
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        self.peerConnection.transceivers
            .compactMap { return $0.sender.track as? T }
            .forEach { $0.isEnabled = isEnabled }
    }
}

// MARK: video Control
extension WebRTCClientService {
    func hideVido() {
        self.setVideoEnabled(false)
    }
    
    func showVideo() {
        self.setVideoEnabled(true)
    }
    
    func setVideoEnabled(_ enabled: Bool) {
        self.setTrackEnabled(RTCVideoTrack.self, isEnabled: enabled)
    }
}

// MARK: Audio Control
extension WebRTCClientService {
    func muteAudio() {
        self.setAudioEnabled(false)
    }
    
    func unmuteAudio() {
        self.setAudioEnabled(true)
    }
    
    func speakerOff() {
        self.audionQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            defer {
                self.rtcAudioSession.unlockForConfiguration()
            }
            do {
                let options: AVAudioSession.CategoryOptions = []
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue, with: options)
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
                
            } catch let error {
                os_log("could not force audio to speaker %s", "\(error)")
            }
        }
    }
    
    func spekerOn() {
        self.audionQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            
            self.rtcAudioSession.lockForConfiguration()
            defer {
                self.rtcAudioSession.unlockForConfiguration()
            }
            do {
                let options: AVAudioSession.CategoryOptions = []
                try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue, with: options)
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
                
            } catch let error {
                os_log("could not force audio to speaker %s", "\(error)")
            }
        }
    }
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        self.setTrackEnabled(RTCAudioTrack.self, isEnabled: isEnabled)
    }
}
