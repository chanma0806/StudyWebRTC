//
//  Message.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/16.
//

import Foundation

enum Message {
    case sdp(SessionDescription)
    case candinate(IceCandidate)
}

enum DecodeError: Error {
    case unknownError
}

extension Message: Codable {
    enum CodingKeys: String, CodingKey {
        case type, payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case String(describing: SessionDescription.self):
            self = .sdp(try container.decode(SessionDescription.self, forKey: .payload))
        case String(describing: IceCandidate.self):
            self = .candinate(try container.decode(IceCandidate.self, forKey: .payload))
        default:
            throw DecodeError.unknownError
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sdp(let sessionDescription):
            try container.encode(sessionDescription, forKey: .payload)
            try container.encode(String(describing: SessionDescription.self), forKey: .type)
        case .candinate(let candidate):
            try container.encode(candidate, forKey: .payload)
            try container.encode(String(describing: IceCandidate.self), forKey: .type)
        }
    }
}



