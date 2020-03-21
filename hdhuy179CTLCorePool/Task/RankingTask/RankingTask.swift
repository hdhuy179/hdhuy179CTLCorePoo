//
//  RankingTask.swift
//  PegaXPool
//
//  Created by thailinh on 1/10/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import RealmSwift
class  RankingTask : BaseWokerOperationTask {
    override init( _id : TaskID) {
        super.init(_id: _id)
        self.queuePriority = .high
    }
    
    override func main() {
        let beginTime  = Timestamp.getTimeStamp()
        var endTime  = Timestamp.getTimeStamp()
        var duration : TimeInterval = 0
        if PoolConstants.Debug.debugTask {print(" Task Begin id : \(String(describing: self.id)) ",beginTime)}
        if isCancelled {
            if PoolConstants.Debug.debugTask {print(" Task Cancel id : \(String(describing: self.id))")}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        let listDataRanking = LocalDatabase.shareInstance.getAllRanks()
//        let listDataRanking = LocalDatabase.shareInstance.getAllRanksSortByScore(ascending: false)

        guard listDataRanking.count > 0 else {
            if PoolConstants.Debug.debugLog{ print( "Ranking No data in database ? WTF" )}
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        if isCancelled {
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        for item in listDataRanking{
            if let poolMechenicVal = self.taskProtocol?.getPoolMechenic(){
                if poolMechenicVal == PoolMechenic.sortTiming{
                    item.finalScore = Double(item.publishDate)
                }else if poolMechenicVal == PoolMechenic.sortData{
                    item.finalScore = item.baseScore
                }else if poolMechenicVal == PoolMechenic.sortPoolAlgorithm{
                    item.finalScore = self.caculateScore(dataRanking: item)
                }
            }else{
                //ko the lay gia tri. mac dinh la getPoolMechenic
                item.finalScore = self.caculateScore(dataRanking: item)
            }
            
        }
        if PoolConstants.Debug.debugScore {
            print("list data ranking")
            for item in listDataRanking{
                print("Debug item \(item.id) \(item.type) \(item.publishDate) \(item.finalScore)")
            }
        }
        // update vao DB. cai nay thuc su hien tai la ko can thiet
        // vi luu tren cache hop li hon. luu them vao DB vi Tu Fat bao nho sau nay can dung.
        LocalDatabase.shareInstance.insertRanks(ranks: listDataRanking)

        self.taskProtocol?.needUpdateCache()
        endTime  = Timestamp.getTimeStamp()
        duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        self.taskProtocol?.complete(taskID: self.id)
    }
    func caculateScore( dataRanking : RankingModel)-> Double{
        
        let now : Int64 = Int64(Date().timeIntervalSince1970)
        let valueTime = Double( (now - dataRanking.publishDate) / 60 )
        let finalScore =    log2(Double(dataRanking.numberOfClicks + 2)) * log2(Double(dataRanking.userReadByDomain + 2)) * log2(Double(dataRanking.userReadByChannel + 2))
            * exp( -valueTime ) * dataRanking.baseScore * dataRanking.personalRank
        //        print("score \(finalScore)")
        if PoolConstants.Debug.debugScore {
            print("linhdeptrai \(dataRanking.id) \(dataRanking.baseScore) \(dataRanking.publishDate) \(dataRanking.userReadByDomain) \(dataRanking.userReadByChannel) \(dataRanking.numberOfClicks) \(valueTime) \(now)  \(finalScore) ")
        }
        //        print("linhdeptrai \(valueTime) \(exp( -valueTime )) \(dataRanking.personalRank)")
        //        print("linhdeptrai \(now)")
        return finalScore
        
    }
    
}
