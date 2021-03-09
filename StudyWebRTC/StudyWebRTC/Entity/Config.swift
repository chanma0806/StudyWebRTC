//
//  Config.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/21.
//

import Foundation

// シグナリングサーバー
fileprivate let defaultSingnalingServerUrl = URL(string: "ws://192.168.11.6:8080")

// STUNサーバー
fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",
                                     "stun:stun3.l.google.com:19302",
                                     "stun:stun4.l.google.com:19302"]

struct Config {
    let singnalingServer: URL
    let webRTCIceServers: [String]
    
    static let `default` = Config(singnalingServer: defaultSingnalingServerUrl!, webRTCIceServers: defaultIceServers)
}
