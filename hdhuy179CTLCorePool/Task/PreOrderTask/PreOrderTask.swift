//
//  PreOrderTask.swift
//  PegaXPool
//
//  Created by thailinh on 1/15/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class PreOrderTask: BaseWokerOperationTask {
    var ids : [String]
    var pattern : [Int]?
    init( _id : TaskID, _pattern : [Int], ids : [String]) {
        self.ids = ids
        self.pattern = _pattern
        super.init(_id: _id)
    }
    
    override func main() {
        let beginTime  = Timestamp.getTimeStamp()
        if PoolConstants.Debug.debugTask {print(" Task Begin id : \(String(describing: self.id)) ",beginTime)}
        if isCancelled {
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id))")}
            return
        }
        guard self.ids.count > 0 else {
            if PoolConstants.Debug.debugLog{ print( "No dataRanking to preorder " )}
            self.taskProtocol?.pullData(ids: self.ids)
            return
        }
        if isCancelled {
            return
        }
        guard let pattern = self.pattern else {
            if PoolConstants.Debug.debugLog{ print( "khong co list pattern tra ve all " )}
            self.taskProtocol?.pullData(ids: self.ids)
            return
        }
        if isCancelled {
            return
        }
        if pattern.count == 0{
            if PoolConstants.Debug.debugLog{ print( "list pattern.count == 0 return all " )}
            self.taskProtocol?.pullData(ids: self.ids)
            return
        }
        if isCancelled {
            return
        }
        let data = PoolCache.shareInstance.listRanks.filter({ids.contains($0.id)})
        let listLength =  data.count
        var numberOfCheck = 0
        var indexOfPattern = 0
        var result = [String]()
        var dataRanks = data
        while (numberOfCheck < listLength){
            for index in 0..<dataRanks.count{
                if dataRanks[index].type == pattern[indexOfPattern]{
                    result.append(dataRanks[index].id)
                    dataRanks.remove(at: index)
                    break
                }
            }
            indexOfPattern = indexOfPattern >= pattern.count - 1 ? 0 : indexOfPattern + 1
            numberOfCheck += 1
        }
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        
        self.taskProtocol?.pullData(ids: result)
    }
}

