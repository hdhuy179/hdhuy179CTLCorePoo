//
//  LocalUploadTask.swift
//  PegaXPool
//
//  Created by thailinh on 3/12/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class LocalUploadTask: BaseWokerOperationTask{
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
        //do task
        if let uploads = self.taskProtocol?.getUploads(){
            if uploads.count > 0{
                LocalDatabase.shareInstance.insertUploads(uploads: uploads)
            }else{
                if PoolConstants.Debug.debugTask {print(" LocalUploadTask uploads count == 0")}
            }
        }else{
            if PoolConstants.Debug.debugTask {print(" LocalUploadTask uploads == nil")}
        }
        //end task
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        
        self.taskProtocol?.complete(taskID: self.id)
        
    }
}
