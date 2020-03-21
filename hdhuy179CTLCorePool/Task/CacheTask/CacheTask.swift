//
//  CacheTask.swift
//  PegaXPool
//
//  Created by thailinh on 1/24/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class CacheTask: BaseWokerOperationTask {
    override init( _id : TaskID) {
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
        
        // check xem da du action de rank chua.
//        let listRanking = LocalDatabase.shareInstance.getAllRanks()
        let listRanking = LocalDatabase.shareInstance.getAllRanksSortByScore(ascending: false)
        if PoolConstants.Debug.debugScore {
            print("Debug cache task")
            for l in listRanking{
                print("Debug list ranking cache task \(l.id) \(l.type) \(l.publishDate) \(l.finalScore)")
            }
        }
        
        if listRanking.count > 0 {
            self.taskProtocol?.updateCache(data: listRanking)
            if PoolConstants.Debug.debugLog{ print("has \(listRanking.count) in cache.") }
        }else{
            if PoolConstants.Debug.debugLog{ print( "no data in Database." )}
        }
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        
        self.taskProtocol?.complete(taskID: self.id)
    }
}
