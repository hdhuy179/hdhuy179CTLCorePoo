//
//  HiddenDeleteTask.swift
//  PegaXPool
//
//  Created by thailinh on 5/20/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class HiddenDeleteTask: BaseWokerOperationTask {
    weak var clientConfig : ClientConfig?
    var idForHiddenDelete : String
    var typeForHiddenDelete :  TypeHiddenDelete
    init( _id : TaskID, config : ClientConfig,idForHiddenDelete : String,typeForHiddenDelete : TypeHiddenDelete  ) {
        self.clientConfig = config
        self.idForHiddenDelete = idForHiddenDelete
        self.typeForHiddenDelete = typeForHiddenDelete
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
        var listData = [String]()
        
        if typeForHiddenDelete == TypeHiddenDelete.HiddenPost{
            listData = [self.idForHiddenDelete]
        }else if typeForHiddenDelete == TypeHiddenDelete.HiddenUser{
            listData = LocalDatabase.shareInstance.getAllRankIdsOfUser(id: self.idForHiddenDelete)
        }
        
        if listData.count > 0{
            if PoolConstants.Debug.debugLog{
                print("Hidden = \(listData.count) bai viet")
            }
            //xoa data o DB Pool
            LocalDatabase.shareInstance.deleteOverCapacity(ids: listData)
            //xoa cache
            PoolCache.shareInstance.deleteCardIsSeen(byID: listData)
            //xoa data o DB Extend
//            self.taskProtocol?.deleteRanks(ids: listData)
            // noti ra api extend
            self.clientConfig?.deleteListCardId(ids: listData)
            
        }else{
            if PoolConstants.Debug.debugLog{
                print("Error.There are no posts for being hidden.")
            }
        }
        
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        
        //end task
        self.taskProtocol?.complete(taskID: self.id)
    }
}

