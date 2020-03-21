//
//  ActionRemoteTask.swift
//  PegaXPool
//
//  Created by thailinh on 3/21/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class ActionRemoteTask: BaseWokerOperationTask {
    weak var clientConfig : ClientConfig?
    init(_id: TaskID, config : ClientConfig?) {
        self.clientConfig = config
        super.init(_id: _id)
    }
    
    override func main() {
        let beginTime  = Timestamp.getTimeStamp()
        if PoolConstants.Debug.debugTask {print(" Task Begin id : \(String(describing: self.id)) ",beginTime)}
        if isCancelled {
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id))")}
            self.taskProtocol?.fail(task: self, isValid: true)
            return
        }
        // get all action pending
        var statusAction = [Int]()
        statusAction.append(ActionSatus.Pending.rawValue)
        let actions = LocalDatabase.shareInstance.getActionForSend(byListStatus: statusAction)
        //print("Clll first actions.count = \(actions.count)")
        if actions.count == 0{
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id) ) actions count == 0. no action for send")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        
        guard let status = self.taskProtocol?.getNetworkState() else{
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id) ) status connect = null")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        if !status.isConnected{
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id) ) isconnect = false. tuc deo co mang")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        
        let requestData : RemoteTaskData?
        
        requestData = clientConfig?.getActionRequest(actions: actions)
        
        if isCancelled {
            if PoolConstants.Debug.debugLog {print("ActionRemoteTask cancel")}
            self.taskProtocol?.fail(task: self, isValid: true)
            return
        }        
        guard let data = requestData else {
            if PoolConstants.Debug.debugLog {print("request Data = null. CLient config at ApiExtend, functions : getData, scheduleGetDataWifi,scheduleGetDataMobile,...")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        
        let dpgAll = DispatchGroup()
        dpgAll.enter()
        CoreAPIService.sharedInstance.ctlRequestAPIAll(url: data.url, params: data.params, meThod: data.methodApi, header: data.header, isRaw: false, completionHandler: { (response) in
            let isSuccess = self.clientConfig?.parserActionResponse(response: response) ?? false
            if isSuccess{
                if PoolConstants.Debug.debugTask {print(" send action to success ")}
                var listActionIDs = [String]()
                for item in actions{
                    listActionIDs.append(item.rankID)
                }
                //print("Clll delete action \(actions.count)")
                //print("Clll \(listActionIDs)")
                LocalDatabase.shareInstance.deleteActions(listAction: listActionIDs)
                PoolCache.shareInstance.listActions.removeAll()
            }else{
                if PoolConstants.Debug.debugTask {print(" send action to server fail. parser response return false ")}
                //print("Clll updateActionRetryById \(actions.count)")
                LocalDatabase.shareInstance.updateActionRetryById(actions: actions)
            }
            dpgAll.leave()
        }) { (error) in
            if PoolConstants.Debug.debugTask {print(" send action to server fail ")}
            self.clientConfig?.actionFail(error: error)
            dpgAll.leave()
        }
        dpgAll.wait()
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        self.taskProtocol?.complete(taskID: self.id)
    }
}
