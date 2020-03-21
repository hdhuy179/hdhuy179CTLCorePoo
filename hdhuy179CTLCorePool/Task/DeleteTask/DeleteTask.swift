//
//  DeleteTask.swift
//  PegaXPool
//
//  Created by thailinh on 2/20/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class DeleteTask: BaseWokerOperationTask {
    weak var clientConfig : ClientConfig?
    init( _id : TaskID, config : ClientConfig) {        
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
        
        //do task
        let listData = LocalDatabase.shareInstance.getAllRanks()
        
        if listData.count >= PoolConstants.BackgroundConfig.Boder_Delete_Number{
            if PoolConstants.Debug.debugLog{
                print("Delete Bat Dau Xoa vi so luong data = \(listData.count)")
            }
            // nhieu hon 350 thi bat dau delete
            
            // lay ids seen
            let idsSeen = PoolCache.shareInstance.getCurrentShowIds()
            // lay cac id can phai xoa
            let listIdsForDelete = LocalDatabase.shareInstance.getIDRankForDelete(ids: idsSeen)
            if PoolConstants.Debug.debugLog{
                print("Delete List Ids delete \(listIdsForDelete)")
            }
            
            
            LocalDatabase.shareInstance.deleteOverCapacity(ids: listIdsForDelete)
            self.taskProtocol?.deleteRanks(ids: listIdsForDelete)
            
            self.clientConfig?.deleteListCardId(ids: listIdsForDelete)
//            print("Delete List seen \(idsSeen)")
            // xoa card out of date first
//            let idsOutOfData = LocalDatabase.shareInstance.deleteAllCardOutOfDate()
//            if PoolConstants.Debug.debugLog{
//                print("Delete Xoa data = \(idsOutOfData)")
//            }
            
            //xoa tiep card rank thap
//            let idsLowRank = LocalDatabase.shareInstance.deleteOverCapacityBoder(ids: idsSeen)
//            print("Delete List Low score \(idsLowRank)")
        
            
        }else{
            if PoolConstants.Debug.debugLog{
                print("Delete Chua Can Phai Xoa vi count = \(listData.count)")
            }
        }
        
        //end task
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        
        self.taskProtocol?.complete(taskID: self.id)
        
    }
}
