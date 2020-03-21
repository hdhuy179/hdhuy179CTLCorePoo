//
//  PoolManager.swift
//  PegaXPool
//
//  Created by thailinh on 1/4/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import SocketIO
//import Alamofire
// block closure
public typealias PoolCreatePostCompletion = ([String : Any]?) -> Void
public typealias PoolDeletePostCompletion = ([String : Any]?) -> Void

public class PoolManager {
    public static let shareInstance =  PoolManager(this: "")
    var isRanking = false
    var isNeedRanking = true
    var patternList = [Int]()
    var isSocketConnect = false
//    var isSocketDev = false
    weak var iPool : PoolManagerProtocol?
    weak var initPool : PoolInitProtocol?
    var isRequestLongTermMore = false
    var currentID : Int = 0 // currentPage
    var networkStatus = NetworkStatus()
    weak var clientConfig : ClientConfig?
    weak var clientPostConfig : ClientPostConfig?
    weak var clientUploadConfig : ClientUpLoadConfig?
    //    var apiExtend : ApiExtend?
    public var bearerToken = ""
    public var session_id = ""
    var firstAccess = true
    var isInitNetworkSuccess = false
    var isInitLocalUpdateSuccess = false
    
    var currentRetrySocket = 0
    
    var schedule: Timer?
    var scheduleRequets : Timer?
    var scheduleDelete : Timer?
    var scheduleCheckUpload : Timer?
    var lastTimeRequest : TimeInterval = 0
    var scheduleSendAction : Timer?
    var poolMechenicValue : PoolMechenic = PoolMechenic.sortPoolAlgorithm
//    var manager : SocketManager?
    
    var manager : SocketManager!
    var socket : SocketIOClient!
    
    let imageDownLoadManager = ImageDownLoadManager()
    
    var photos = [PhotoRecord]()
    
    public var numberOfRetry  = 0
    
    public var userID : String = ""
    
    init(this : String) {
        if PoolConstants.Debug.debugLog{ print( "==============Init Pool=============" )}
        firstAccess = true
        isInitNetworkSuccess = false
        isInitLocalUpdateSuccess = false
        ThreadManager.shareInstance.callBack = self
        
        self.poolMechenicValue = PoolMechenic.sortPoolAlgorithm
        self.initPool?.prepareInit()
        NetworkReceiver.shared.iNetworkReceiver = self
        NetworkReceiver.shared.startNetworkReachabilityObserver()
        //        apiExtend = ApiExtend()
        //        self.clientConfig = apiExtend
        self.switchID(id: self.currentID)
//        self.localUpdateCacheTask()
        
        
    }
    //MARK: -Clear Database
    public func setPoolMechenicValue(value : PoolMechenic){
        self.poolMechenicValue = value
    }
    public func getPoolMechenicValue() -> PoolMechenic{
        return self.poolMechenicValue
    }
    
    public func clearDataBase(){
        LocalDatabase.shareInstance.clearDataBase()
    }
    public func clearDataBase(forUser userID : String){
        LocalDatabase.shareInstance.clearDataBase(forUser: userID)
    }
    //MARK: - socket
    func initSocket(sessionID : String){
        // init socket
        DispatchQueue.main.async {
            self.currentRetrySocket = 0
            
            if PoolConstants.Debug.debugSocket {
                print("CTLSocketLog initSocket")
                self.iPool?.socketPrepareInit()
            }
            self.isSocketConnect = false
            var socketUrl = ""
            //        if isSocketDev{
            //            socketUrl = "\(PoolConstants.API.SocketURLDev):\(PoolConstants.API.SocketPort)"
            //        }else{
            //            socketUrl = "\(PoolConstants.API.SocketURL)"
            //        }
            if PoolConstants.API.SocketPort == nil || PoolConstants.API.SocketPort == ""{
                socketUrl = "\(PoolConstants.API.SocketURL)"
            }else{
                socketUrl = "\(PoolConstants.API.SocketURL):\(PoolConstants.API.SocketPort)"
            }
            
            //"fe6b169e250275a887161431de587f530000016975387782"
                    self.socket = nil
                    self.manager = nil
            if PoolConstants.Configure.SocketVersion2 {
                self.manager = SocketManager(socketURL: URL(string: socketUrl)!, config: [.log(false), .forceNew(true)])
                self.socket = self.manager.socket(forNamespace: "/user")
            }else{
                self.manager = SocketManager(socketURL: URL(string: socketUrl)!, config: [.reconnectAttempts(3),.log(false), .extraHeaders(["session-id" : sessionID])])
                self.socket = self.manager.defaultSocket
            }
            
            if PoolConstants.Configure.SocketConnectOnce{
                self.socket.once(clientEvent: .connect) { (data, ack) in
                    self.currentRetrySocket = 0
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog once connected")
                    }
                    self.iPool?.socketConnected()
                    
                    if PoolConstants.Configure.SocketVersion2{
                        let string = "{\"sessionID\":\"\(sessionID)\"}"
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog SocketVersion2 send authen \(string)")
                        }
                        self.socket.emit("authentication", with: [string])
                    }else{
                        self.isSocketConnect = true
                    }
                }
            }else{
                do{
                    try self.socket.on(clientEvent: .connect) {data, ack in
                        self.currentRetrySocket = 0
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog connected")
                        }
                        self.iPool?.socketConnected()
                        
                        if PoolConstants.Configure.SocketVersion2{
                            let string = "{\"sessionID\":\"\(sessionID)\"}"
                            if PoolConstants.Debug.debugSocket {
                                print("CTLSocketLog SocketVersion2 send authen \(string)")
                            }
                            self.socket.emit("authentication", with: [string])
                        }else{
                            self.isSocketConnect = true
                        }
                    }
                }catch let erorr{
                    print("CTLSOCKET error connect \(erorr.localizedDescription)")
                }
                
            }
            
            
            
            self.socket.onAny { (event) in
                if PoolConstants.Debug.debugSocketAny {
                    print("CTLSocketLog Any event = \(event.event) eventItem =\(event.items)")
                }
            }
            
            self.socket.on(clientEvent: .disconnect) { (data, ack) in
                if PoolConstants.Debug.debugSocketClientEvent {
                    print("CTLSocketLog disconnect \(data) \(ack)")
                }
                self.isSocketConnect = false
                self.iPool?.socketDisconnect()
            }
            
            
            self.socket.on(clientEvent: .error) { (data, ack) in
                if PoolConstants.Debug.debugSocketClientEvent {
                    print("CTLSocketLog error \(data) \(ack)")
                }
                self.currentRetrySocket += 1
                if (self.currentRetrySocket >= PoolConstants.SocketEventCode.Socket_Max_Retry){
                    
                    if PoolConstants.Debug.debugSocketClientEvent {
                        print("CTLSocketLog qua max retry > \(PoolConstants.SocketEventCode.Socket_Max_Retry). disconnect ")
                    }
                    //                self.socket.disconnect()
                    self.socketDisconnect()
                    
                    //                self.initSocket(sessionID: self.session_id)
                }
                
                self.iPool?.socketError(data: data)
            }
            
            self.socket.on(clientEvent: .statusChange) { (data, ack) in
                if PoolConstants.Debug.debugSocketClientEvent {
                    print("CTLSocketLog statusChange \(data) \(ack)")
                }
                
            }
            self.socket.on(clientEvent: SocketClientEvent.reconnect) { (data, ack) in
                if PoolConstants.Debug.debugSocketClientEvent {
                    print("CTLSocketLog reconnect \(data) \(ack)")
                }
                self.iPool?.socketReconnect()
            }
            self.socket.on(clientEvent: .websocketUpgrade) {data, ack in
                let headers = (data as [Any])[0]
                if PoolConstants.Debug.debugSocketClientEvent {
                    print("CTLSocketLog websocketUpgrade header \(headers)")
                }
            }
            //        socket.on("authenticated") { (data, ack) in
            //            self.isSocketConnect = true
            //        }
            //        socket.on("unauthorized") { (data, ack) in
            //            self.isSocketConnect = false
            //        }
            self.socketOnAuthen()
            
            self.socketOnPost()
            
            self.socketOnComment()
            
            self.socketOnPermission()
            
            self.socketOnUser()
            
            self.socketOnSetting()
            
            self.socketOnInspection()
            
            self.socketOnLive()
            
            self.socketOnGroup()
            
            self.socket.connect()
        }
        
    }
    
    private func socketOnGroup(){
        socket.on(PoolConstants.SocketEventName.Socket_Event_Name_Group) { (data, ack) in
            if PoolConstants.Debug.debugSocket {
                print("CTLSocketLog event \(PoolConstants.SocketEventName.Socket_Event_Name_Group) withData \(data)  andAck \(ack)")
            }
            //            CoreUltilies.printJson(byObject: data)
            guard let dataString = data[0] as? String else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog event post dataResponse == nil")
                }
                return
            }
            
            if let dataJson = dataString.data(using: String.Encoding.utf8){
                do{
                    guard let dataResponse = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String : Any] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. dataResponse is not json")
                        }
                        return
                    }
                    
                    guard let status = dataResponse["status"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. status == nil")
                        }
                        return
                    }
                    let intStatus = status as? Int
                    if intStatus != 1 {
                        //fail data response
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog Status Code != 1. status code = \(intStatus)")
                        }
                        return
                    }
                    guard let code = dataResponse["code"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. code == nil")
                        }
                        return
                    }
                    
                    guard var result : [String : Any] = dataResponse["result"] as? [String : Any] else{
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. result == nil")
                        }
                        return
                    }
                    result = CoreUltilies.encodeForSocket(data: result)
                    //                    result = CoreUltilies.encodeForSocket(data: result)
                    
                    let intCode = code as? Int
                    if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Group_Join {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Group_Join")
                        }
                        self.iPool?.socketReceiveGroupNoti(data: result)
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Group_Leave {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Group_Leave")
                        }
                        self.iPool?.socketReceiveGroupNoti(data: result)
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Group_Push_Noti {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Group_Push_Noti")
                        }
                        self.iPool?.socketReceiveGroupNoti(data: result)
                    }else{
                        self.iPool?.socketReceiveAny(data: result)
                    }
                    
                }catch{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog parser Mes. data is not json")
                    }
                }
            }else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog parser Mes. not convert string to data")
                }
            }
            
            
        }
    }
    
    private func socketOnAuthen(){
        socket.on("authentication") { (data, ack) in
            if PoolConstants.Debug.debugSocket {
                print("CTLSocketLog event \(PoolConstants.SocketEventName.Socket_Event_Name_Post) withData \(data)  andAck \(ack)")
            }
            //            CoreUltilies.printJson(byObject: data)
            guard let dataString = data[0] as? String else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog event post dataResponse == nil")
                }
                return
            }
            
            if let dataJson = dataString.data(using: String.Encoding.utf8){
                do{
                    guard let dataResponse = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String : Any] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. dataResponse is not json")
                        }
                        return
                    }
                    if let code = dataResponse["code"] as? Int{
                        if code == 200 {
                            self.isSocketConnect = true
                        }else {
                            self.isSocketConnect = false
                        }
                    }else{
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog authen code = nil")
                        }
                        self.isSocketConnect = false
                    }
                    
                    if let mes = dataResponse["message"] as? String{
                        print("CTLSocketLog authen mess = \(mes)")
                    }
                    
                }catch{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog parser Mes. data is not json")
                    }
                }
            }
        }
    }
    private func socketOnPost(){
        socket.on(PoolConstants.SocketEventName.Socket_Event_Name_Post) { (data, ack) in
            if PoolConstants.Debug.debugSocket {
                print("CTLSocketLog event \(PoolConstants.SocketEventName.Socket_Event_Name_Post) withData \(data)  andAck \(ack)")
            }
            //            CoreUltilies.printJson(byObject: data)
            guard let dataString = data[0] as? String else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog event post dataResponse == nil")
                }
                return
            }
            
            if let dataJson = dataString.data(using: String.Encoding.utf8){
                do{
                    guard let dataResponse = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String : Any] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. dataResponse is not json")
                        }
                        return
                    }
                    
                    guard let status = dataResponse["status"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. status == nil")
                        }
                        return
                    }
                    let intStatus = status as? Int
                    if intStatus != 1 {
                        //fail data response
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog Status Code != 1. status code = \(intStatus)")
                        }
                        return
                    }
                    guard let code = dataResponse["code"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. code == nil")
                        }
                        return
                    }
                    
                    guard var result : [String : Any] = dataResponse["result"] as? [String : Any] else{
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. result == nil")
                        }
                        return
                    }
//                    print("CTLSocketLog result 1 = \(result)")
                    result = CoreUltilies.encodeForSocket(data: result)
                    
//                    print("CTLSocketLog result 2 = \(result)")
                    
//                    guard let result : String = dataResponse["result"] as? String else{
//                        if PoolConstants.Debug.debugSocket {
//                            print("CTLSocketLog parser Mes. result == nil")
//                        }
//                        return
//                    }
                    
//                    let strResult = String.init(data: result.data(using: String.Encoding.isoLatin1)!, encoding: String.Encoding.utf8)
                    
                    
                    
                    let intCode = code as? Int
                    if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Delete {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Delete Post")
                        }
                        self.iPool?.socketReceiveDeletePost(data: result)
                        
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_BreakingNews {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event BreakingNews")
                        }
                        self.iPool?.socketReceiveBreakingNews(data: result)
                        
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Widget {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Widget")
                        }
                        
                        self.iPool?.socketReceiveWidget(data: result)
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_PostFocus_Join {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_PostFocus_Join")
                        }
                        
                        self.iPool?.socketReceiveFocusPost(data: result)
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_PostFocus_Leave {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_PostFocus_Leave")
                        }
                        
                        self.iPool?.socketReceiveFocusPost(data: result)
                    }
                    else{
                        self.iPool?.socketReceiveAny(data: result)
                    }
 //
                    //                    if intCode == 601 {
                    //                        if PoolConstants.Debug.debugSocket {
                    //                            print("CTLSocketLog event Delete Post")
                    //                        }
                    //                        guard let dataResult = result["data"] as? [String : Any] else{
                    //                            if PoolConstants.Debug.debugSocket {
                    //                                print("CTLSocketLog parser Mes for code = \(intCode). dataResult == nil")
                    //                            }
                    //                            return
                    //                        }
                    //                        self.iPool?.socketReceiveDeletePost(data: dataResult)
                    //                    }else if intCode == 602 {
                    //                        if PoolConstants.Debug.debugSocket {
                    //                            print("CTLSocketLog event BreakingNews")
                    //                        }
                    //                        guard let dataResult = result["data"] as? [[String : Any]] else{
                    //                            if PoolConstants.Debug.debugSocket {
                    //                                print("CTLSocketLog parser Mes for code = \(intCode). dataResult == nil")
                    //                            }
                    //                            return
                    //                        }
                    //                        self.iPool?.socketReceiveBreakingNews(data: dataResult)
                    //                    }
                    
                    
                }catch{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog parser Mes. data is not json")
                    }
                }
            }else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog parser Mes. not convert string to data")
                }
            }
            
            
        }
    }
    
    private func socketOnComment(){
        socket.on(PoolConstants.SocketEventName.Socket_Event_Name_Comment) { (data, ack) in
            if PoolConstants.Debug.debugSocket {
                print("CTLSocketLog event \(PoolConstants.SocketEventName.Socket_Event_Name_Comment) withData \(data)  andAck \(ack)")
            }
            //            CoreUltilies.printJson(byObject: data)
            guard let dataString = data[0] as? String else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog event post dataResponse == nil")
                }
                return
            }
            
            if let dataJson = dataString.data(using: String.Encoding.utf8){
                do{
                    guard let dataResponse = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String : Any] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. dataResponse is not json")
                        }
                        return
                    }
                    
                    guard let status = dataResponse["status"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. status == nil")
                        }
                        return
                    }
                    let intStatus = status as? Int
                    if intStatus != 1 {
                        //fail data response
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog Status Code != 1. status code = \(intStatus)")
                        }
                        return
                    }
                    guard let code = dataResponse["code"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. code == nil")
                        }
                        return
                    }
                    
                    guard var result : [String : Any] = dataResponse["result"] as? [String : Any] else{
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. result == nil")
                        }
                        return
                    }
                    result = CoreUltilies.encodeForSocket(data: result)
                    
                    let intCode = code as? Int
                    if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Comment {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Comment")
                        }
                        self.iPool?.socketReceiveLivingComment(data: result)
                        
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Comment_Delete {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Comment_Delete")
                        }
                        self.iPool?.socketReceiveLivingCommentDelete(data: result)
                        
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Comment_Update {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Comment_Update")
                        }
                        self.iPool?.socketReceiveLivingCommentUpdate(data: result)
                        
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Comment_Typing {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Comment_Typing")
                        }
                        self.iPool?.socketReceiveLivingCommentTyping(data: result)
                    }else{
                        self.iPool?.socketReceiveAny(data: result)
                    }
                    
                }catch{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog parser Mes. data is not json")
                    }
                }
            }else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog parser Mes. not convert string to data")
                }
            }
        }
    }
    
    private func socketOnInspection(){
        socket.on(PoolConstants.SocketEventName.Socket_Event_Name_Inspection) { (data, ack) in
            if PoolConstants.Debug.debugSocket {
                print("CTLSocketLog event \(PoolConstants.SocketEventName.Socket_Event_Name_Inspection) withData \(data)  andAck \(ack)")
            }
            //            CoreUltilies.printJson(byObject: data)
            guard let dataString = data[0] as? String else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog event post dataResponse == nil")
                }
                return
            }
            
            if let dataJson = dataString.data(using: String.Encoding.utf8){
                do{
                    guard let dataResponse = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String : Any] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. dataResponse is not json")
                        }
                        return
                    }
                    
                    guard let status = dataResponse["status"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. status == nil")
                        }
                        return
                    }
                    let intStatus = status as? Int
                    if intStatus != 1 {
                        //fail data response
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog Status Code != 1. status code = \(intStatus)")
                        }
                        return
                    }
                    guard let code = dataResponse["code"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. code == nil")
                        }
                        return
                    }
                    
                    guard var result : [String : Any] = dataResponse["result"] as? [String : Any] else{
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. result == nil")
                        }
                        return
                    }
                    result = CoreUltilies.encodeForSocket(data: result)
                    
                    let intCode = code as? Int
                    self.iPool?.socketReceiveInspection(data: result)
                }catch{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog parser Mes. data is not json")
                    }
                }
            }else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog parser Mes. not convert string to data")
                }
            }
        }
    }
    
    private func socketOnSetting(){
        socket.on(PoolConstants.SocketEventName.Socket_Event_Name_Setting) { (data, ack) in
            if PoolConstants.Debug.debugSocket {
                print("CTLSocketLog event \(PoolConstants.SocketEventName.Socket_Event_Name_Setting) withData \(data)  andAck \(ack)")
            }
            //            CoreUltilies.printJson(byObject: data)
            guard let dataString = data[0] as? String else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog event post dataResponse == nil")
                }
                return
            }
            
            if let dataJson = dataString.data(using: String.Encoding.utf8){
                do{
                    guard let dataResponse = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String : Any] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. dataResponse is not json")
                        }
                        return
                    }
                    
                    guard let status = dataResponse["status"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. status == nil")
                        }
                        return
                    }
                    let intStatus = status as? Int
                    if intStatus != 1 {
                        //fail data response
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog Status Code != 1. status code = \(intStatus)")
                        }
                        return
                    }
                    guard let code = dataResponse["code"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. code == nil")
                        }
                        return
                    }
                    
                    guard var result : [String : Any] = dataResponse["result"] as? [String : Any] else{
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. result == nil")
                        }
                        return
                    }
                    result = CoreUltilies.encodeForSocket(data: result)

                    let intCode = code as? Int
                    self.iPool?.socketReceiveSetting(data: result)
//                    if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Setting_DisableComment {
//                        if PoolConstants.Debug.debugSocket {
//                            print("CTLSocketLog event Socket_Event_Code_Setting_DisableComment")
//                        }
//                        self.iPool?.socketReceiveSetting(data: result)
//
//                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Setting_Comment_Censorship {
//                        if PoolConstants.Debug.debugSocket {
//                            print("CTLSocketLog event Socket_Event_Code_Setting_Comment_Censorship")
//                        }
//                        self.iPool?.socketReceiveSetting(data: result)
//
//                    }else{
//
//                    }
                    
                }catch{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog parser Mes. data is not json")
                    }
                }
            }else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog parser Mes. not convert string to data")
                }
            }
        }
    }
    
    private func socketOnPermission(){
        socket.on(PoolConstants.SocketEventName.Socket_Event_Name_Permission) { (data, ack) in
            if PoolConstants.Debug.debugSocket {
                print("CTLSocketLog event \(PoolConstants.SocketEventName.Socket_Event_Name_Permission) withData \(data)  andAck \(ack)")
            }
            //            CoreUltilies.printJson(byObject: data)
            guard let dataString = data[0] as? String else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog event permission dataResponse == nil")
                }
                return
            }
            
            if let dataJson = dataString.data(using: String.Encoding.utf8){
                do{
                    guard let dataResponse = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String : Any] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. dataResponse is not json")
                        }
                        return
                    }
                    
                    guard let status = dataResponse["status"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. status == nil")
                        }
                        return
                    }
                    let intStatus = status as? Int
                    if intStatus != 1 {
                        //fail data response
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog Status Code != 1. status code = \(intStatus)")
                        }
                        return
                    }
                    guard let code = dataResponse["code"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. code == nil")
                        }
                        return
                    }
                    
                    guard var result : [String : Any] = dataResponse["result"] as? [String : Any] else{
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. result == nil")
                        }
                        return
                    }
                    result = CoreUltilies.encodeForSocket(data: result)
                    
                    
                    let intCode = code as? Int
                    /*if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Permission_All {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Permission_All")
                        }
                        self.iPool?.socketReceivePermissionAll(data: result)
                        
                    }else*/ if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Permission_Page {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Permission_Page")
                        }
                        self.iPool?.socketReceivePermissionPage(data: result)
                        
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Permission_Post {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Permission_Post")
                        }
                        self.iPool?.socketReceivePermissionPost(data: result)
                    }else if
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_UserNormal ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_UserSuppended ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_DeActive ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_Delete ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_Reader ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_Admin ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_ExpertUser ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_OfficialUser ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_InviteCode ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_InvitedPending ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_FBLoggedIn ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_DeniedLoggedIn ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_HasBeenApproved ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_KYC_Verify_Requirement ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_User_KYC_Waiting_Approve ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_GoToCountDown ||
                    intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_GoToWaiting ||
                    intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_GoToLiveStream
                            {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_Permission_Role")
                        }
                        self.iPool?.socketUpdateRoleAndPermission(role: intCode!, data: result)
                    }else{
                        self.iPool?.socketReceiveAny(data: result)
                    }
                    
//                    else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Permission_UserSuppended {
//                        if PoolConstants.Debug.debugSocket {
//                            print("CTLSocketLog event Socket_Event_Code_Permission_UserSuppended")
//                        }
//                        self.iPool?.socketReceivePermissionUserSuppend(data: result)
//
//                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Permission_User_DeActive {
//                        if PoolConstants.Debug.debugSocket {
//                            print("CTLSocketLog event Socket_Event_Code_Permission_User_DeActive")
//                        }
//                        self.iPool?.socketReceivePermissionUserDeactive(data: result)
//
//                    }
                    
                }catch{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog parser Mes. data is not json")
                    }
                }
            }else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog parser Mes. not convert string to data")
                }
            }
        }
    }
    
    private func socketOnLive(){
            socket.on(PoolConstants.SocketEventName.Socket_Event_Name_Live) { (data, ack) in
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog event \(PoolConstants.SocketEventName.Socket_Event_Name_Live) withData \(data)  andAck \(ack)")
                }
                //            CoreUltilies.printJson(byObject: data)
                guard let dataString = data[0] as? String else{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog event Socket_Event_Name_LivedataResponse == nil")
                    }
                    return
                }
                
                if let dataJson = dataString.data(using: String.Encoding.utf8){
                    do{
                        guard let dataResponse = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String : Any] else {
                            if PoolConstants.Debug.debugSocket {
                                print("CTLSocketLog parser Mes. dataResponse is not json")
                            }
                            return
                        }
                        
                        guard let status = dataResponse["status"] else {
                            if PoolConstants.Debug.debugSocket {
                                print("CTLSocketLog parser Mes. status == nil")
                            }
                            return
                        }
                        let intStatus = status as? Int
                        if intStatus != 1 {
                            //fail data response
                            if PoolConstants.Debug.debugSocket {
                                print("CTLSocketLog Status Code != 1. status code = \(intStatus)")
                            }
                            return
                        }
                        guard let code = dataResponse["code"] else {
                            if PoolConstants.Debug.debugSocket {
                                print("CTLSocketLog parser Mes. code == nil")
                            }
                            return
                        }
                        
                        guard var result : [String : Any] = dataResponse["result"] as? [String : Any] else{
                            if PoolConstants.Debug.debugSocket {
                                print("CTLSocketLog parser Mes. result == nil")
                            }
                            return
                        }
                        
                        result = CoreUltilies.encodeForSocket(data: result)
                        
                        
                        let intCode = code as? Int

                        if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_GoToCountDown ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_GoToWaiting ||
                        intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Role_GoToLiveStream ||
                            intCode == PoolConstants.SocketEventCode.Socket_Event_Code_Get_New_Role
                                {
                            if PoolConstants.Debug.debugSocket {
                                print("CTLSocketLog event Socket_Event_Name_Live")
                            }
                            self.iPool?.socketUpdateLive(role: intCode!, data: result)
                        }else{
                            self.iPool?.socketReceiveAny(data: result)
                        }

                        
                    }catch{
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. data is not json")
                        }
                    }
                }else{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog parser Mes. not convert string to data")
                    }
                }
            }
        }
    
    private func socketOnUser(){
        socket.on(PoolConstants.SocketEventName.Socket_Event_Name_User) { (data, ack) in
            if PoolConstants.Debug.debugSocket {
                print("CTLSocketLog event \(PoolConstants.SocketEventName.Socket_Event_Name_Post) withData \(data)  andAck \(ack)")
            }
            //            CoreUltilies.printJson(byObject: data)
            guard let dataString = data[0] as? String else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog event post dataResponse == nil")
                }
                return
            }
            
            if let dataJson = dataString.data(using: String.Encoding.utf8){
                do{
                    guard let dataResponse = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String : Any] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. dataResponse is not json")
                        }
                        return
                    }
                    
                    guard let status = dataResponse["status"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. status == nil")
                        }
                        return
                    }
                    let intStatus = status as? Int
                    if intStatus != 1 {
                        //fail data response
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog Status Code != 1. status code = \(intStatus)")
                        }
                        return
                    }
                    guard let code = dataResponse["code"] else {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. code == nil")
                        }
                        return
                    }
                    
                    guard var result : [String : Any] = dataResponse["result"] as? [String : Any] else{
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog parser Mes. result == nil")
                        }
                        return
                    }
                    result = CoreUltilies.encodeForSocket(data: result)
//                    result = CoreUltilies.encodeForSocket(data: result)
                    
                    let intCode = code as? Int
                    if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_User_SessionExpire {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_User_SessionExpire")
                        }
                        self.iPool?.socketReceiveUserSessionExpire(data: result)
                    }else if intCode == PoolConstants.SocketEventCode.Socket_Event_Code_User_Notify {
                        if PoolConstants.Debug.debugSocket {
                            print("CTLSocketLog event Socket_Event_Code_User_Notify")
                        }
                        self.iPool?.socketReceiveUserNotify(data: result)
                    }else{
                        self.iPool?.socketReceiveAny(data: result)
                    }
                    
                }catch{
                    if PoolConstants.Debug.debugSocket {
                        print("CTLSocketLog parser Mes. data is not json")
                    }
                }
            }else{
                if PoolConstants.Debug.debugSocket {
                    print("CTLSocketLog parser Mes. not convert string to data")
                }
            }
            
            
        }
    }
    public func socketDisconnect(){
        self.isSocketConnect = false
        if self.socket != nil{
            self.socket.disconnect()
            self.socket = nil
            self.manager = nil
        }
    }
    func verifySocket() ->Bool{
        if (self.socket != nil) && self.isSocketConnect {
            return true
        }
        return false
    }
    public func socketEmit(event : String, listItems : [Any]){
        if self.verifySocket(){
            let time = Timestamp.getTimeStamp()
            if PoolConstants.Debug.debugSocket{print("time start socketEmit = \(time) content \(listItems.first)")}
            self.socket.emit(event, with: listItems)
            return
        }
        if PoolConstants.Debug.debugSocket{
            print("Exception : Socket nil or not connect.")
        }
        
    }
    
    public func setInitProtocol(delegate : PoolInitProtocol){
        self.initPool = delegate
    }
    public func setProtocol(delegate : PoolManagerProtocol){
        self.iPool = delegate
    }
    public func setClientConfigProtocol(delegate : ClientConfig?){
        self.clientConfig = delegate
    }
    public func setClientUploadConfigProtocol(delegate : ClientUpLoadConfig?){
        self.clientUploadConfig = delegate
    }
    public func setPostClientConfigProtocol(_protocol : ClientPostConfig?){
        self.clientPostConfig = _protocol
    }
    public func verifyContent(textContent text : String)->[Range<String.Index>]{
        return VerifyPost.verifyPost(forTextContent: text)
    }
    
    public func switchID (id : Int){
        self.currentID = id
        PoolCache.shareInstance.updateID(id: id)
    }
    public func setPattern( id : Int, pattern : [[Int]]){
        PoolCache.shareInstance.setPattern(id: id, pattern: pattern)
    }
    public func getAllRanksHavingIds(ids: [String]) -> [RankingModel]{
        return LocalDatabase.shareInstance.getAllRanksHavingIds(ids:ids)
    }
    func pullDataToClient(idTab : Int, ids : [String]){
        self.iPool?.receiveData(idTab: idTab, ids: ids)
    }
    public func resetRetryOfUpload(byIdTemp idTemp : String){
        LocalDatabase.shareInstance.resetRetryOfUpload(byIdTemp: idTemp)
    }
    func checkIsLogin() ->Bool{
        if self.userID == "" || self.session_id == ""{
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return false
        }
        return true
    }
    //MARK: -Schedule
    @objc func doSchedule(){
        return;
        if PoolConstants.Debug.debugLog{ print( "**************doSchedule**************" )}
        if !checkIsLogin(){
            return
        }
        var isNeedRun = false
        let now  = Date().timeIntervalSince1970
        if PoolConstants.Configure.DATA_MAX_IN_CACHE <= 0{
            // ko can chan tren nua
            isNeedRun = true
        }else{
            // can chan tren
            if PoolCache.shareInstance.getAvailableCount(id: self.currentID, limit: PoolConstants.Configure.DATA_MAX_IN_CACHE) < PoolConstants.Configure.DATA_MAX_IN_CACHE{
                if now - PoolConstants.BackgroundConfig.scheduleBetweenRequest > lastTimeRequest{
                    isNeedRun = true
                }else{
                    if PoolConstants.Debug.debugLog{ print( "last request and now too close" )}
                }
            }else{
                if PoolConstants.Debug.debugLog{ print( "too many unseen item, not need get data from server" )}
            }
        }
        if (isNeedRun){
            self.remoteRestTask(taskId: TaskID.Remote_Long_Term, type: RemoteType.Long_Term)
        }
    }
    
    @objc func scheudleRequestGetData(){
        if PoolConstants.Debug.debugLog{
            print("scheudleRequestGetData when response not receive after ", PoolConstants.BackgroundConfig.Get_Data_Time_Limit , "s")
        }
        if !checkIsLogin(){
            return
        }
        self.iPool?.requestNotReceiveAfter(second: PoolConstants.BackgroundConfig.Get_Data_Time_Limit)
        self.getDataTask()
        scheduleRequets?.invalidate()
        scheduleRequets = nil
    }
    @objc func scheduleCheckUploadRun(){
        if PoolConstants.Debug.debugLog{
            print("=================================scheduleCheckUpload==================================")
        }
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        var status = [Int]()
        status.append(UploadStatus.PENDING.rawValue)
        status.append(UploadStatus.UPLOAD_SUCCESS.rawValue)
        var uploads = LocalDatabase.shareInstance.getUploadByStatus(status: status)
        if uploads.count > 0{
            self.uploadTask()
        }else{
            if PoolConstants.Debug.debugLog{
                print("no data for upload")
            }
        }
    }
    @objc func scheduleSendActionRun(){
        if PoolConstants.Debug.debugLog{
            print("=================================scheduleSendActionRun==================================")
        }
        if !checkIsLogin(){
            return
        }
        var actions = LocalDatabase.shareInstance.getAllActions()
        if actions.count > 0{
            self.actionRemoteTask()
        }else{
            if PoolConstants.Debug.debugLog{
                print("no action for send")
            }
        }
    }
    
    @objc func scheduleDeleteData(){
        if PoolConstants.Debug.debugLog{
            print("scheudle Delete after ", PoolConstants.BackgroundConfig.Time_Limit_For_Delete , "s")
        }
        if !checkIsLogin(){
            return
        }
        self.deleteTask()
    }
    
    //MARK: -Login LogOut
    public func logIn(idUser : String,sessionID : String){
        //updatePreCache
        //Getdata true
        if idUser != nil && idUser != ""{
            // goi logout roi moi dc login
            if PoolConstants.Debug.debugLog{print("DEO logout ma login ak?")}
            self.logOut()
        }
        //session
        //userid  =
        self.session_id = sessionID
        if PoolConstants.Configure.InitSocket{
            self.initSocket(sessionID: sessionID)
        }
        print("CTLSocketLog sessionID \(sessionID)")
        userID = idUser
        LocalDatabase.shareInstance.login(userID: userID)
        self.localUpdateCacheTask()
//        self.getDataTask(isRefresh: true)
//        let headers: [String : String
//            ] = [
//            "Accept": "application/json",
//            "OVP-APP-KEY" : PoolConstants.API.OVP_APP_KEY,
//            "OVP-SECRET-KEY" : PoolConstants.API.OVP_SECRET_KEY
//        ]
        let headers: [String : String ] =
            ["session-id" : session_id]
        let params : [String : Any] = [String : Any]()
//        let params : [String : Any] = [
////            "userId" : "1476885440500675"
//            "userId" : userID
//        ]
        CoreAPIService.sharedInstance.ctlRequestAPI(url: PoolConstants.API.ovpSohaTV, params: params, meThod: MethodApi.PostApi, header: headers, completionHandler: { (responseData) in
            if PoolConstants.Debug.debugTask{print("ovpSohaTV after login \(responseData)")}
            print("")
            guard let data = responseData as? [String : Any] else{
                if PoolConstants.Debug.debugLog{print("k lay dc data token Bearer")}
                return
            }
            if let token = data["token"] as? String{
                let newToken = "Bearer \(token)"
                self.bearerToken = newToken
                if PoolConstants.Debug.debugLog{print(newToken)}
            }else{
                if PoolConstants.Debug.debugLog{print("k lay dc token Bearer")}
            }
            
            /*
             linh ["success": 1, "data": {
             token = "11ce5319-0984-4f71-b26d-94a0aee3ef9d";
             userInfo =     {
             id = 1000360;
             name = "user_8838762";
             status = active;
             };
             }]
             */
        }) { (error) in
            if PoolConstants.Debug.debugLog{print("get token Bearer fail"   )}
            if PoolConstants.Debug.debugTask{print(error.localizedDescription)}
        }
        
    }
    public func logOut(){
        self.isSocketConnect = false
        userID = ""
        session_id = ""
        LocalDatabase.shareInstance.login(userID: "")
        PoolCache.shareInstance.clearWhenLogOut()
        self.socketDisconnect()
        
//        self.manager.di
//        manager.disconnect()
    }
    
    public func getDecryptionKey(userID : String) ->[UInt8]{
        let stringName = "\(PoolConstants.Database.Prefix_DataBase_Encrypt)\(userID)\(PoolConstants.Database.Suffix_DataBase_Encrypt))"
        let data = Data(stringName.utf8)
        let hexString = data.map{ String(format:"%02x", $0) }.joined()
        if PoolConstants.Debug.debugKeyDB{
            print("Key Debug DB 1f2dee\(hexString)")
        }
        let array: [UInt8] = self.stringToBytes(hexString) ?? [UInt8]()
        return array
    }
    func stringToBytes(_ string: String) -> [UInt8]? {
        let length = string.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }
    
    public func getAllActions()->[ActionModel]{
        return LocalDatabase.shareInstance.getAllActions()
    }
    
    public func deletePostFromClient(idTemp: String){
        LocalDatabase.shareInstance.deleteUpload(idTemp: idTemp)
    }
    func createTaskByTaskID (taskId: TaskID , data : Any){
        switch taskId {
        case TaskID.Get_Data:
            self.getDataTask()
            break
        case TaskID.Action_Add:
            
            break
        case TaskID.Ranking:
            self.rankingTask()
            break
        case TaskID.Remote_Short_Term:
            self.remoteRestTask(taskId: TaskID.Remote_Short_Term, type: RemoteType.Short_Term)
            break
        case TaskID.Remote_Long_Term:
            self.remoteRestTask(taskId: TaskID.Remote_Long_Term, type: RemoteType.Long_Term)
            break
        case TaskID.Local_Insert_Rank:
            if let pData : Array<RankingModel> = (data) as? Array<RankingModel>{
                self.localInsertRankTask(data: pData)
            }
            break
        case TaskID.Local_Cache_Update:
            self.localUpdateCacheTask()
            break
        case TaskID.Pre_Order:
            if let pData : Array<String> = (data) as? Array<String>{
                self.preOrderTask(ids: pData)
            }
            break
        default:
            if PoolConstants.Debug.debugLog{ print( "no TaskId for create" )}
        }
    }
    
}
//MARK: -Up Load
extension PoolManager{
//    public func upLoadImage(data : RemoteTaskData, completion : @escaping ([String : Any])->(),failure : @escaping ()->() ){
//        if PoolConstants.Debug.debugTask{print("upLoadImage CoreAPIService")}
//        CoreAPIService.sharedInstance.ctlUpLoadApi(path: data.url, params: data.params, image: data.image, videoData: nil, header: data.header, completionHandler: { (response) in
//            if PoolConstants.Debug.debugTask{print("upLoadImage success \(response)")}
//            completion(response)
//        }) { (error) in
//            if PoolConstants.Debug.debugTask{print("upLoadImage fail \(error)")}
//            failure()
//
//        }
//
//    }
}
//MARK: -Post
extension PoolManager{
    
    public func createPost(params : [String : Any] , completion : @escaping PoolCreatePostCompletion){
        let requestData = self.clientPostConfig?.createPost(params: params)
        guard let data = requestData else {
            if PoolConstants.Debug.debugLog {print("ClientPostProtocol = nil")}
            completion([String:Any]())
            return
        }
        self.doARequest(withRemoteData: data,completion: completion)
    }
    
    private func doARequest(withRemoteData data: RemoteTaskData, completion : @escaping PoolCreatePostCompletion){
        let status = self.getNetworkState()
        if status.isConnected{
            CoreAPIService.sharedInstance.httpRequestAPI(url: data.url, params: data.params, meThod: data.methodApi, completionHandler: { (dataResponse) in
                if PoolConstants.Debug.debugLog{
                    print("createPost success ")
                }
                completion(dataResponse)
            }) { (error) in
                if PoolConstants.Debug.debugLog {print("Create a Post fail ",error.localizedDescription)}
            }
        }else{
            if PoolConstants.Debug.debugLog {print("No Network")}
            return
        }
    }
}
//MARK: -Task
extension PoolManager{
    
    public func getDataTask(){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        let task = GetDataTask(_id: TaskID.Get_Data, idTab: currentID)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    public func getDataTask(isRefresh : Bool, isOpen : Bool){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        if (isRefresh ){
//            isRequestLongTermMore = true
            PoolCache.shareInstance.clearListShow(id: self.currentID)
            PoolCache.shareInstance.clientWaitData = true
            if isOpen{
                self.remoteRestTask(taskId: TaskID.Remote_Short_Term, type: RemoteType.Short_Refresh)
            }else{
                self.remoteRestTask(taskId: TaskID.Remote_Short_Term, type: RemoteType.Short_Term)
            }            
            let now  = Date().timeIntervalSince1970 * 1000
            if PoolConstants.Debug.debugLog{ print("Start GetDataTask \(now)")}
            scheduleRequets = Timer.scheduledTimer(timeInterval: PoolConstants.BackgroundConfig.Get_Data_Time_Limit, target: self, selector: #selector(scheudleRequestGetData), userInfo: nil, repeats: false)
        }else{
            self.getDataTask()
        }
    }
    
    public func upload(upload : UpLoadModel){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        PoolCache.shareInstance.pushUpload(upload: upload)
        let task = LocalUploadTask(_id: TaskID.Upload_Add_Task)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    public func remoteRestTask(taskId : TaskID, type : RemoteType){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        if !networkStatus.isConnected{
            if PoolConstants.Debug.debugLog {print("Network not connect. remoteTask fail")}
            return
        }
        if self.clientConfig == nil{
            if PoolConstants.Debug.debugLog {print("CLient config = nil. set up at ApiExtend, functions : getData, scheduleGetDataWifi,scheduleGetDataMobile,...")}
            return
        }
        let task = RemoteTaskOperation(_id: taskId, remoteType: type, config: self.clientConfig!)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    public func localInsertRankTask(data : [RankingModel]){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        // neu chua valid thi return
        //        let task = l
        let task = LocalRankTask(_id: TaskID.Local_Insert_Rank, data: data)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    public func uploadTask(){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        if self.clientUploadConfig == nil{
            if PoolConstants.Debug.debugLog {print("clientUploadConfig = nil. set up at ApiExtend, functions : UPLOAD,...")}
            return
        }
        let task = UpLoadTask(_id: TaskID.Upload_Task, config: self.clientUploadConfig!, postConfig: self.clientPostConfig)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    public func rankingTask(){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        let task = RankingTask(_id: TaskID.Ranking)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    
    public func localUpdateCacheTask(){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        let task = CacheTask(_id: TaskID.Local_Cache_Update)
        task.taskProtocol = self
        if firstAccess{
            task.completionBlock = {
                self.isInitLocalUpdateSuccess = true
                if self.firstAccess{
                    DispatchQueue.main.async {
                        self.doInitPoolSuccess()
                    }
                    
                }
            }
        }
        ThreadManager.shareInstance.addTaskOperation(task: task)
        
    }
    public func preOrderTask(ids : [String]){
        let task = PreOrderTask(_id: TaskID.Pre_Order, _pattern: self.patternList, ids: ids)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    
    public func addActionTask (action : ActionModel){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        PoolCache.shareInstance.listActions.append(action)
        let task = LocalActionTask(_id: TaskID.Action_Add)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    public func actionRemoteTask(){
        if !checkIsLogin(){
            if PoolConstants.Debug.debugLog{ print( "Chua Login. Not Run" )}
            return
        }
        let task = ActionRemoteTask(_id: TaskID.Action_Remote_Task, config: self.clientConfig)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    public func getImage(){
        for (index,photo) in photos.enumerated(){
            switch (photo.state){
            case .new,.failed:
                self.startDownloadForRecord(photoDetails: photo, index: index)
                break
            case .downloaded:
                break
            }
        }
    }
    public func mergeDB(fromOldUser oldUser : String, toNewUser newUser : String){
        LocalDatabase.shareInstance.mergeDB(fromOldUser: oldUser, toNewUser: newUser)
    }
    public func deleteTask(){
        let task = DeleteTask(_id: TaskID.Delete_Task, config: self.clientConfig!)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    public func hiddenDeleteTask(idForHiddenDelete: String, typeForHiddenDelete: TypeHiddenDelete){
        let task = HiddenDeleteTask(_id: TaskID.Hidden_Delete_Task, config: self.clientConfig!, idForHiddenDelete: idForHiddenDelete, typeForHiddenDelete: typeForHiddenDelete)
        task.taskProtocol = self
        ThreadManager.shareInstance.addTaskOperation(task: task)
    }
    func startDownloadForRecord(photoDetails: PhotoRecord, index: Int){
        if imageDownLoadManager.downloadsInProgress[index] != nil {
            return
        }
        let downloader = ImageDownloader(photoDetails)
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            DispatchQueue.main.async(execute: {
                self.imageDownLoadManager.downloadsInProgress.removeValue(forKey: index)
                // tra callback
            })
        }
        imageDownLoadManager.downloadsInProgress[index] = downloader
        imageDownLoadManager.downloadQueue.addOperation(downloader)
    }
}
//MARK: - InitPool Complete
extension PoolManager : NetworkReceiverProtocol{
    func updateNetworkStatus(isConnect: Bool, isWifi: Bool) {
        if PoolConstants.Debug.debugLog{ print( "updateNetworkStatus ", isConnect ? "connect" : "disconnect"  )}
        self.networkStatus.isConnected = isConnect
        self.networkStatus.isWifi = isWifi
        isInitNetworkSuccess = true
        if firstAccess{
            self.doInitPoolSuccess()
        }
        
        if networkStatus.isConnected {
            if PoolConstants.Debug.usingThreadManager{
                ThreadManager.shareInstance.runTask()
            }
            if self.socket == nil || !self.isSocketConnect{
                if self.session_id != nil && self.session_id != ""{
                    PoolManager.shareInstance.initSocket(sessionID: self.session_id)
                }
//                PoolManager.shareInstance.initSocket(sessionID: self.session_id)
            }
            
        }
    }
    func doInitPoolSuccess(){
//        if firstAccess  && isInitNetworkSuccess && isInitLocalUpdateSuccess{
        if firstAccess  && isInitNetworkSuccess {
            firstAccess = false
            schedule =  Timer.scheduledTimer(timeInterval: PoolConstants.BackgroundConfig.scheduleDelay, target: self, selector: #selector(doSchedule), userInfo: nil, repeats: true)
            scheduleDelete = Timer.scheduledTimer(timeInterval: PoolConstants.BackgroundConfig.schedule_Delete, target: self, selector: #selector(scheduleDeleteData), userInfo: nil, repeats: true)
            scheduleCheckUpload = Timer.scheduledTimer(timeInterval: PoolConstants.BackgroundConfig.scheduleUploadTime, target: self, selector: #selector(scheduleCheckUploadRun), userInfo: nil, repeats: true)
            scheduleSendAction = Timer.scheduledTimer(timeInterval: PoolConstants.BackgroundConfig.scheduleUploadTime, target: self, selector: #selector(scheduleSendActionRun), userInfo: nil, repeats: true)
            if PoolConstants.Debug.debugLog{ print( "==============Init Pool Complete =============" )}
            
            self.initPool?.initSuccess()
        }
    }
}
//MARK: -Task Protocol
extension PoolManager : TaskProtocol{
    
    func uploadFileFail(id: String, path: String) {
        
        
    }
    
    func uploadSuccess(id: String, path: String, link: String) {
//        self.clientUploadConfig?.uploadFileSuccess(id: id, path: path, link: link)
    }

    func getUploads() -> [UpLoadModel] {
        return PoolCache.shareInstance.pullUpload()
    }
    
    
    func deleteRanks(ids: [String]) {
        self.iPool?.deleteListCard(ids: ids)
    }
    public func deleteRanksFromDBAndCache(ids :[String]){
        LocalDatabase.shareInstance.deleteOverCapacity(ids: ids)
        PoolCache.shareInstance.deleteCardIsSeen(byID: ids)
    }
    
    func localAddRank(taskID : TaskID,data: [RankingModel]) {
        
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol localAddRank" )}
        let now  = Date().timeIntervalSince1970 * 1000
        
        if PoolConstants.Debug.debugLog{ print("Ket thuc remote \(now)")}
        if taskID == TaskID.Remote_Long_Term{
            lastTimeRequest = Date().timeIntervalSince1970
        }else if taskID == TaskID.Remote_Short_Term{
            scheduleRequets?.invalidate()
            scheduleRequets = nil
            // co goi longterm ko?
            if isRequestLongTermMore{
                if PoolConstants.Debug.debugLog{ print("Request Long term after short term")}
                isRequestLongTermMore = false
                self.remoteRestTask(taskId: TaskID.Remote_Long_Term, type: RemoteType.Long_Term)
            }
        }
        self.localInsertRankTask(data: data)
    }
    
    func needMoreData() {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol needMoreData" )}
//        self.remoteRestTask(taskId: TaskID.Remote_Short_Term, type: RemoteType.Short_Term)
    }
    
    func needRanking() {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol needRanking" )}
        self.rankingTask()
    }
    
    func needUpdateCache() {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol needUpdateCache" )}
        self.localUpdateCacheTask()
    }
    
    func updateCache(data: [RankingModel]) {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol updateCache" )}
//        PoolCache.shareInstance.listRanks = data
        PoolCache.shareInstance.listRanks.append(contentsOf: data)
//        if PoolCache.shareInstance.clientWaitData{
//            self.getDataTask()
//        }
    }
    
    func preOrder(ids: [String]) {
        self.preOrderTask(ids: ids)
    }
    
    func pullData(idTab : Int, ids: [String]) {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol pullData for idTab = \(idTab)" )}
        // cai nay la ban ve cho client show data
        self.pullDataToClient(idTab: idTab, ids: ids)
    }
    
    func pullData(ids: [String]) {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol pullData current tab" )}
        self.pullDataToClient(idTab: self.currentID, ids: ids)
    }
    
    func getActions() -> [ActionModel] {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol getActions" )}
        var action = [ActionModel]()
        action.append(contentsOf: PoolCache.shareInstance.listActions)
        return action
    }
    
    func getNetworkState() -> NetworkStatus {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol getNetworkState" )}
        return networkStatus
    }
    
    func complete(taskID: TaskID) {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol complete" )}
        ThreadManager.shareInstance.completeTask(id: taskID)
        switch taskID {
        case .Remote_Long_Term:
            //            lastTimeRequest = Date().timeIntervalSince1970
            //call at localAddRank
            break
        case .Remote_Short_Term:
            // call longterm
            //call at localAddRank
            
            break
        case .Local_Cache_Update :
            break
        default:
            print("")
        }
    }
    
    func fail(task: BaseWokerOperationTask, isValid: Bool) {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol fail" )}
        ThreadManager.shareInstance.completeTask(id: task.id)
        
        if isValid {
            task.completionBlock = {
                self.createTaskByTaskID(taskId: task.id, data: "")
            }
        }
    }
    
    func noMoreData(typeOfRequest: Int) {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol noMoreData" )}
        self.iPool?.noMoreData(typeOfRequest: typeOfRequest)
    }
    
    func remoteFail(typeOfRequest: Int) {
        if PoolConstants.Debug.debugTaskProtocol{ print( "TaskProtocol remoteFail" )}
        self.iPool?.getFeedFail(typeOfRequest: typeOfRequest)
        if PoolCache.shareInstance.clientWaitData /*&& numberOfRetry < 3*/{
            //            numberOfRetry = numberOfRetry + 1
            if typeOfRequest == 1{
                self.remoteRestTask(taskId: TaskID.Remote_Short_Term, type: RemoteType.Short_Refresh)
            }
            if typeOfRequest == 2{
                self.remoteRestTask(taskId: TaskID.Remote_Short_Term, type: RemoteType.Short_Term)
            }
            
        }
        
    }
    func getPoolMechenic() -> PoolMechenic{
        return self.getPoolMechenicValue()
    }
}

