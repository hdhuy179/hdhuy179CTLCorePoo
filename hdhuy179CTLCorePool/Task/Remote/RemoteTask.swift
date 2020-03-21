//
//  RemoteTask.swift
//  PegaXPool
//
//  Created by thailinh on 1/5/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class RemoteTaskOperation: BaseWokerOperationTask {
//    var remoteTaskData : RemoteTaskData?
    var remoteType : RemoteType
    weak var clientConfig : ClientConfig?
    init(_id: TaskID, remoteType : RemoteType, config : ClientConfig) {
        self.remoteType = remoteType
        self.clientConfig = config
        super.init(_id: _id)
    }
    
    override func main() {
        let beginTime  = Timestamp.getTimeStamp()
        if PoolConstants.Debug.debugTask {print(" Task Begin id : \(String(describing: self.id)) ",beginTime)}
        if isCancelled {
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id))")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        let requestData : RemoteTaskData?
        let status = self.taskProtocol?.getNetworkState()
        switch remoteType {
        case .Short_Term:
            requestData = self.clientConfig?.getData(isOpen: false)
            break
        case .Long_Term:
            if status?.isWifi ?? false{
                requestData = self.clientConfig?.scheduleGetDataWifi()
            }else{
                requestData = self.clientConfig?.scheduleGetDataMobile()
            }
            break
        case .Short_Refresh:
            requestData = self.clientConfig?.getData(isOpen: true)
            break
        default:
            if PoolConstants.Debug.debugLog {print("Remote Task Type unknown")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return;
        }
        if isCancelled {
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        guard let data = requestData else {
            if PoolConstants.Debug.debugLog {print("request Data = null. CLient config at ApiExtend, functions : getData, scheduleGetDataWifi,scheduleGetDataMobile,...")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        let dpg = DispatchGroup()
        if status != nil && status!.isConnected{
            // do task
            dpg.enter()
//            CoreAPIService.sharedInstance.httpRequestAPI(url:data.url, params: data.params, meThod: data.methodApi, completionHandler: { (dataResponse) in
//                if PoolConstants.Debug.debugLog {
//                print("request success")}
//                let rankings = self.clientConfig?.receiveData(response: dataResponse)
//                if rankings != nil && rankings!.count > 0{
//                    self.taskProtocol?.localAddRank(taskID: self.id, data: rankings!)
////                    self.taskProtocol?.localAddRank(data: rankings!)self.taskProtocol?.localAddRank(data: rankings!)
//                }else{
//                    self.taskProtocol?.noMoreData()
//                }
//            }) { (error) in
//                if PoolConstants.Debug.debugLog {print("request fail ",error.localizedDescription)}
//                self.taskProtocol?.remoteFail()t
//            }
            CoreAPIService.sharedInstance.ctlRequestAPIAll(url: data.url, params: data.params, meThod: data.methodApi, header: data.header, isRaw: false, completionHandler: { (dataResponse) in
                if PoolConstants.Debug.debugLog {
                    print("request success")}
                let rankings = self.clientConfig?.receiveData(response: dataResponse)
                if rankings != nil && rankings!.count > 0{
                    if PoolConstants.Configure.TwentyNewsFirst{
                            var ids = [String]()
                            for rank in rankings!{
                                ids.append(rank.id)
                            }
                        
                            PoolCache.shareInstance.showIdsMap[0] = ids
                        PoolCache.shareInstance.listRanks = rankings!
                        self.taskProtocol?.pullData(idTab: 0, ids: ids)
                    }
                    self.taskProtocol?.localAddRank(taskID: self.id, data: rankings!)
                }else{
                    self.taskProtocol?.noMoreData(typeOfRequest: self.remoteType.rawValue)
                }
                dpg.leave()
            }) { (error) in
                if PoolConstants.Debug.debugLog {print("request fail ",error.localizedDescription)}
                self.taskProtocol?.remoteFail(typeOfRequest: self.remoteType.rawValue)
                dpg.leave()
            }
            dpg.wait()
            
            
        }else{
            if PoolConstants.Debug.debugLog {print("No Network")}
            self.taskProtocol?.fail(task: self, isValid: true)
            return
        }
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        
        self.taskProtocol?.complete(taskID: self.id)
    }
}

