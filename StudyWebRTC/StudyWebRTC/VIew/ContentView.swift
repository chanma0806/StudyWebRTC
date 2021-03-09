//
//  ContentView.swift
//  StudyWebRTC
//
//  Created by 丸山大幸 on 2021/02/16.
//

import SwiftUI

enum SignalingState: String {
    case notConnect
    case connect
}

enum SDPState: String {
    case none = "❌"
    case exist = "⭕️"
}

enum WebRTCStatus: String {
    case New
}

enum SpeakerState: String {
    case on
    case off
    
    mutating func toggle() {
        switch self {
        case .on:
            self = .off
        case .off:
            self = .on
        }
    }
}

enum MuteState: String {
    case on
    case off
    
    mutating func toggle() {
        switch self {
        case .on:
            self = .off
        case .off:
            self = .on
        }
    }
}

struct ContentView: View {
    @ObservedObject var model = ContentViewModel()
    @State var isShowingTextFiled = false
    @State var message: String = ""
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(alignment: .leading, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
                    Text("WebRTC Demo")
                        .font(.system(size: 40))
                        .bold()
                    Group {
                        HStack {
                            Text("Singanling State: \(model.signalingState.rawValue)")
                        }
                        HStack {
                            Text("Local SDP: \(model.remoteSdpState.rawValue)")
                        }
                        HStack {
                            Text("LocalCandidate: \(model.localCandidateCount)")
                        }
                        HStack {
                            Text("Remote SDP: \(model.remoteSdpState.rawValue)")
                        }
                        HStack {
                            Text("RemoteCandidate: \(model.remoteCandidateCount)")
                        }
                    }
                    .padding(10)
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/) {
                        Text("WebRTC Status: ")
                            .font(.system(size: 20))
                        Text("\(model.webRTCState)")
                    }
                    .frame(width: geo.size.width, height: 200)
                    
                    Spacer()
                    
                    Group {
                        HStack{
                            // Mute Button
                            Button("Mute: \(model.muteState.rawValue)", action: {
                                model.muteState.toggle()
                            })
                            
                            Spacer()
                            
                            // Send Data Button
                            Button("Send Data", action: {
                                tappedSendButton()
                            })
                        }
                        .frame(width: geo.size.width)
                        
                        Spacer()
                            .frame(height: 10)
                        
                        HStack {
                            // Speaker Button
                            Button("Speaker: \(model.speakerState.rawValue)", action: {
                                model.speakerState.toggle()
                            })
                            
                            Spacer()
                            
                            // Video Button
                            Button("Video", action: {
                                
                            })
                        }
                        .frame(width: geo.size.width)
                    }
                    
                    Spacer().frame(height: 15)
                            
                    VStack(alignment: .leading) {
                        Group {
                            Button("Send Offer", action: {
                                tappedOffer()
                            })
                            .padding(.bottom, 10)
                            
                            Button("Send Answer", action: {
                                tappedAnswer()
                            })
                        }
                        .frame(width: geo.size.width, height: 40)
                        .background(Color.blue)
                        .foregroundColor(.white)
                    }.frame(width: geo.size.width, alignment: .bottom)
                })
                
                if isShowingTextFiled {
                    Color.black.opacity(0.5)
                        .frame(width: .infinity, height: .infinity)
                        .padding(-10)
                    GeometryReader { localGeo in
                        VStack(alignment: .center) {
                            TextField("input message", text:$message,
                                      onEditingChanged: { _ in },
                                      onCommit: {
                                        sendMessage(message)
                                        isShowingTextFiled = false
                                      })
                                .padding(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 2))
                                .frame(height: localGeo.size.height * 0.4)
                            
                            HStack {
                                Group {
                                    Button("Cancel", action: {
                                        isShowingTextFiled = false
                                    })
                                    Button("Send!", action: {
                                        sendMessage(message)
                                        isShowingTextFiled = false
                                    })
                                }
                                .frame(width: localGeo.size.width * 0.45, height: localGeo.size.height * 0.2)
                                .background(Color.blue.opacity(0.5))
                            }
                            .frame(width: localGeo.size.width, height: localGeo.size.height * 0.5, alignment: .bottom)
                        }
                        .frame(width: localGeo.size.width - 20, height: localGeo.size.height - 10)
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
                    }
                    .zIndex(2.0)
                    .frame(width: geo.size.width * 0.8, height: UIScreen.main.bounds.height * 0.3)
                    .background(Color.white)
                    .cornerRadius(25.0)
                    .shadow(radius: 10)
                }
            }
        }
        .frame(width: .infinity, height:.infinity, alignment: .topLeading)
        .padding(10)
        .onAppear {
            self.model.connect()
        }
    }
    
    func tappedOffer() {
        model.offer()
    }
    
    func tappedAnswer() {
        model.answer()
    }
    
    func tappedSendButton() {
        isShowingTextFiled = true
    }
    
    func sendMessage(_ message: String) {
        model.sendMessage(message: message)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
