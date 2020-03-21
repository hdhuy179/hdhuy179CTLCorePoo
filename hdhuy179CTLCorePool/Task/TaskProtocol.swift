//
//  TaskProtocol.swift
//  PegaXPool
//
//  Created by thailinh on 1/23/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
protocol TaskProtocol{    
    func localAddRank (taskID : TaskID, data : [RankingModel])
    
    func needMoreData()
    
    func needRanking()
    
    func needUpdateCache()
    
    func updateCache(data : [RankingModel] )
    
    func pullData(ids : [String])
    
    func pullData(idTab: Int, ids : [String])
    
    func preOrder(ids : [String])
    
    func getActions() -> [ActionModel]
    
    func getNetworkState() ->NetworkStatus
    
    func complete(taskID : TaskID )
    
    func fail(task : BaseWokerOperationTask , isValid : Bool )
    
    func noMoreData(typeOfRequest : Int)
    
    func remoteFail(typeOfRequest : Int)
    
    func deleteRanks(ids : [String])
    
    func getUploads()->[UpLoadModel]
    
    func uploadSuccess(id : String, path : String, link : String)
    
    func uploadFileFail(id : String, path : String)
    
    func checkIsLogin() -> Bool
    
    func getPoolMechenic() -> PoolMechenic
//    func 
    
}
