//
//  NativeWebSocket.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/20.
//

import Foundation

class NativeWebSocket: NSObject, WebSocketProvider {
    var delegate: WebSocketProviderDelegate?
    private let url: URL
    private var socket: URLSessionWebSocketTask?
    private lazy var urlSession: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    func connect() {
        let socket = urlSession.webSocketTask(with: url)
        socket.resume()
        self.socket = socket
        self.readMeassage()
    }
    
    func send(data: Data) {
        self.socket?.send(.data(data), completionHandler: { error in
            
        })
    }
    
    private func readMeassage() {
        self.socket?.receive { [weak self] message in
            guard let self = self else {
                return
            }
            
            switch message {
            case .success(.data(let data)):
                self.delegate?.webSocket(self, didRecieveData: data)
                self.readMeassage()
            case .success:
                self.readMeassage()
            case .failure:
                 self.disConnect()
            }
        }
    }
    
    private func disConnect() {
        self.socket?.cancel()
        self.socket = nil
        self.delegate?.webSocketProviderDidDisConnect(self)
    }
}

extension NativeWebSocket: URLSessionWebSocketDelegate, URLSessionDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.delegate?.webSocketProviderDidConnect(self)
    }
    
    func urlSeesion(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.disConnect()
    }
}
