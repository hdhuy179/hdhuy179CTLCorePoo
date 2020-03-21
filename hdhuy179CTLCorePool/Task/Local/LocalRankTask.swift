//
//  LocalRankTask.swift
//  PegaXPool
//
//  Created by thailinh on 1/10/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class LocalRankTask: BaseWokerOperationTask {
    var listRanks = [RankingModel]()
    init(_id: TaskID, data : [RankingModel]) {
        super.init(_id: _id)
        self.listRanks = data
    }
    
    override func main() {
        let beginTime  = Timestamp.getTimeStamp()
        if PoolConstants.Debug.debugTask {print(" Task Begin id : \(String(describing: self.id)) ",beginTime)}
        if isCancelled {
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id))")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        let timestamp = Timestamp()
        if isCancelled {
            return
        }
        guard  self.listRanks.count > 0 else {
            if PoolConstants.Debug.debugLog{ print( "list rankings is nil" )}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        if isCancelled {
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        LocalDatabase.shareInstance.updateRanks(ranks: self.listRanks)
//        LocalDatabase.shareInstance.deleteOverCapacity()
        if PoolConstants.Debug.debugLog{ print( "add ranks success call ranking" )}
        self.taskProtocol?.needRanking()
        // check xem da du action de rank chua.
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        
        self.taskProtocol?.complete(taskID: self.id)
    }
}
