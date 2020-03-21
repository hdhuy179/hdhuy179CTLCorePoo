//
//  LocalActionTask.swift
//  PegaXPool
//
//  Created by thailinh on 1/10/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class LocalActionTask: BaseWokerOperationTask {
    override init(_id: TaskID) {
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
        let data = PoolCache.shareInstance.listActions
        if data.count < 1{
            if PoolConstants.Debug.debugLog{ print( "action is nil? add roi null cc" )}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        // check xem da du action de rank chua. de goi need ranking
        LocalDatabase.shareInstance.insertActions(ranks: data)
        
        // TODO : update ranking table with action
        for action in data{
            if action != nil{
                switch action.type {
                case ActionType.Click.rawValue :
                    LocalDatabase.shareInstance.updateClick(rankID: action.rankID)
                    break
                case ActionType.Read_By_Domain.rawValue :
                    LocalDatabase.shareInstance.updateDomain(data: action.data)
                    break
                case ActionType.Read_By_Channel.rawValue :
                    LocalDatabase.shareInstance.updateChannel(data: action.data)
                    break
                case ActionType.Follow_Action.rawValue:
                    
                    break
                case ActionType.Like_Aciton.rawValue:
                    
                    break
                case ActionType.Subcribe_Action.rawValue:
                    
                    break
                default:
                    if PoolConstants.Debug.debugLog{ print( "Action ko co hoac ko dc dinh nghia type = \(action.type)" )}
                }
            }
        }
        if PoolConstants.Debug.debugLog{ print( "add action sucess" )}
        self.taskProtocol?.needRanking()
        
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        self.taskProtocol?.complete(taskID: self.id)
    }    
}
