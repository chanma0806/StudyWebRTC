//
//  SignalClient.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/16.
//

import Foundation
import WebRTC
import os

protocol WebSocketProviderDelegate: class {
    // webSocketの接続コールバック
    func webSocketProviderDidConnect(_ webSocket: WebSocketProvider)
    // webSocketの切断コールバック
    func webSocketProviderDidDisConnect(_ webSocket: WebSocketProvider)
    // webSocketからのデータ受信コールバック
    func webSocket(_ webSocket: WebSocketProvider, didRecieveData data: Data)
}

protocol WebSocketProvider: class {
    var delegate: WebSocketProviderDelegate? { get set }
    func connect()
    func send(data: Data)
}

protocol SignalClientDelegate: class {
    // シグナルサーバー接続時のコールバック
    func signalClientDidConnect(_ signalClient: SignalClientService)
    // シグナルサーバー切断時のコールバック
    func signalClientDidDisConnect(_ signalClinet: SignalClientService)
    // sdp受信コールバック
    func signalClient(_ signalCilent: SignalClientService, didReceiveRemoteSdp sdp: RTCSessionDescription)
    // candidate受信コールバック
    func signalClient(_ signalCilent: SignalClientService, didReceiveCandinate candinate: RTCIceCandidate)
}

class SignalClientService {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let webSocket: WebSocketProvider
    weak var delegate: SignalClientDelegate?
    
    init (webSocket: WebSocketProvider) {
        self.webSocket = webSocket
    }
    
    func connect() {
        self.webSocket.delegate = self
        self.webSocket.connect()
    }
    
    func send(sdp rtcSdp: RTCSessionDescription) {
        let message = Message.sdp(.init(from: rtcSdp))
        guard let encodedMessage = try? encoder.encode(message) else {
            os_log("could not encode sessionDescription -> %s", rtcSdp)
            return
        }
        
        self.webSocket.send(data: encodedMessage)
    }
    
    func send(candidate rtcCandidate: RTCIceCandidate) {
        let message = Message.candinate(.init(from: rtcCandidate))
        guard let encodedMessage = try? encoder.encode(message) else {
            os_log("could not encode candidate -> %s", rtcCandidate)
            return
        }
        
        self.webSocket.send(data: encodedMessage)
    }
}

// webSocketとの通信結果をSigalCilentの呼び先に通知
extension SignalClientService: WebSocketProviderDelegate {
    func webSocketProviderDidConnect(_ webSocket: WebSocketProvider) {
        self.delegate?.signalClientDidConnect(self)
    }
    
    func webSocketProviderDidDisConnect(_ webSocket: WebSocketProvider) {
        self.delegate?.signalClientDidDisConnect(self)
    }
    
    func webSocket(_ webSocket: WebSocketProvider, didRecieveData data: Data) {
        guard let message = try? self.decoder.decode(Message.self, from: data) else {
            os_log("could not decode message")
            return
        }
        
        switch message {
        case .sdp(let sdp):
            self.delegate?.signalClient(self, didReceiveRemoteSdp: sdp.rtcSessionDescription)
        case .candinate(let candidate):
            self.delegate?.signalClient(self, didReceiveCandinate: candidate.rtcIceCandidate)
        }
    }
    
    
}
