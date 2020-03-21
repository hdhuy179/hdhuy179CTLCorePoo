//
//  LocalDatabase.swift
//  PegaXPool
//
//  Created by thailinh on 1/5/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import RealmSwift

class LocalDatabase {
    static let shareInstance = LocalDatabase(first: "")
    init(first : String){
        let userID = PoolManager.shareInstance.userID
        self.DBName = "\(PoolConstants.Database.Prefix_DataBase_Pool)\(userID).realm"
        let array = PoolManager.shareInstance.getDecryptionKey(userID: userID)
        keyEnCrypt = NSMutableData()
        keyEnCrypt.append(array, length: 64)
    }
    var DBName : String = ""
    var keyEnCrypt : NSMutableData = NSMutableData()
    
    private var realmUrl : URL{
        get {
            let documentUrl = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
            let url = documentUrl.appendingPathComponent(self.DBName)
//            print("Key Debug url =",url)
            return url
        }
    }
    var config : Realm.Configuration {
        get{
//            print("keyEncrypt : \(keyEnCrypt)")
            
            return Realm.Configuration(fileURL: self.realmUrl, inMemoryIdentifier: nil, syncConfiguration: nil, encryptionKey: keyEnCrypt as Data, readOnly: false, schemaVersion: 1, migrationBlock: nil, deleteRealmIfMigrationNeeded: false, shouldCompactOnLaunch: nil, objectTypes: [DO_Action.self,DO_Rank.self, DO_UpLoad.self,RealmString.self, DO_UploadDataTask.self])
        }
    }
    func login(userID : String){
        self.DBName = "\(PoolConstants.Database.Prefix_DataBase_Pool)\(userID).realm"
//        print("Key Debug userID \(userID)")
        let array = PoolManager.shareInstance.getDecryptionKey(userID: userID)
        keyEnCrypt = NSMutableData()
        keyEnCrypt.append(array, length: 64)
    }
    //MARK: -Clear Database
    func clearDataBase(){
        let realm = try! Realm(configuration: config)
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    func clearDataBase(forUser userID : String){
        self.login(userID: userID)
        self.clearDataBase()
    }
    
    //MARK: -Action
    
    func insertClick(){
        
    }
    func getAllActions() -> [ActionModel] {
        var listStatus = [Int]()
        listStatus.append(ActionSatus.Pending.rawValue)
        listStatus.append(ActionSatus.Sending.rawValue)
        let realm = try! Realm(configuration: config)
        let list = realm.objects(DO_Action.self).filter("status in %@ AND retry < %d",listStatus,PoolConstants.Configure.ACTION_RETRY_LIMIT)
        var results = [ActionModel]()
        for item in list{
            let actionObj = item.wrapToActionModel()
            results.append(actionObj)
        }
        return results
    }
    func getActionForSend(byListStatus listStatus : [Int])->[ActionModel]{
        let realm = try! Realm(configuration: config)
        let list = realm.objects(DO_Action.self).filter("status in %@ AND retry < %d",listStatus,PoolConstants.Configure.ACTION_RETRY_LIMIT)
        var results = [ActionModel]()
        for item in list{
            let actionObj = item.wrapToActionModel()
            results.append(actionObj)
        }
        return results
    }
    func getActionForSend(byListStatus listStatus : [Int], type : [Int])->[ActionModel]{
        let realm = try! Realm(configuration: config)
        let list = realm.objects(DO_Action.self).filter("status in %@ AND type in %@ AND retry < %d",listStatus, PoolConstants.Configure.ACTION_RETRY_LIMIT)
        var results = [ActionModel]()
        for item in list{
            let actionObj = item.wrapToActionModel()
            results.append(actionObj)
        }
        return results
    }
    
    /// Use only for action which can be send
    ///
    /// - Parameters:
    ///   - action: action model
    ///   - status: status (sending or complete)
    func updateActionStatusById(action : ActionModel, status : Int){
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_Action.self).filter("rankID == %@ && type = %d",action.rankID,action.type)
        if let obj = objs.first{
            // ton tai 1 thang cu
            try! realm.write {
                obj.status = action.status
            }
        }
        // deo ton tai thang nao giong the
    }
    func updateActionRetryById(action : ActionModel, retry : Int){
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_Action.self).filter("rankID == %@ && type = %d",action.rankID,action.type)
        if let obj = objs.first{
            // ton tai 1 thang cu
            try! realm.write {
                obj.retry = action.retry
            }
        }
    }
    func updateActionRetryById(actions : [ActionModel]){
        for item in actions{
            self.updateActionRetryById(action: item, retry: item.retry + 1)
        }
    }
    func deleteActions(listAction : [String]){        
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_Action.self).filter("rankID in %@",listAction)
        //print("Clll co objs database count = \(objs.count)")
        
        try! realm.write {
            realm.delete(objs)
            print("Real Delete 1")
        }
        print("Real Delete 2")
    }
    func deleteAllActions(){
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_Action.self)
        for obj in objs.reversed(){
            try! realm.write {
                realm.delete(obj)
            }
        }
    }

//    func insertAction(action : ActionModel){
//        let realm = try! Realm(configuration: config)
//        try! realm.write {
//            realm.add(action.wrapToDO_Action())
//        }
//    }

    func insertActions(ranks : [ActionModel]){

        let realm = try! Realm(configuration: config)
        for action in ranks{
            if action.type == ActionType.Like_Aciton.rawValue || action.type == ActionType.Follow_Action.rawValue || action.type == ActionType.Subcribe_Action.rawValue{
                let objs = realm.objects(DO_Action.self).filter("rankID == %@ && type = %d",action.rankID,action.type)
                if let obj = objs.first{
                    // ton tai 1 thang cu
                    try! realm.write {
                        obj.data = action.data
                        obj.value = action.value
                    }
                }else{
                    // deo ton tai thang nao giong the
                    try! realm.write {
                        realm.add(action.wrapToDO_Action())
                    }
                }
            }else{
                try! realm.write {
                    realm.add(action.wrapToDO_Action())
                }
            }
        }
    }
    
    //MARK: -Upload
    func deleteUpload(idTemp : String){
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_UpLoad.self).filter("cardID = %@",idTemp)
        if let obj = objs.first{
            try! realm.write {
                realm.delete(obj)
            }
        } 
    }
    func getUploadByStatus(status : [Int])-> [UpLoadModel]{
        let realm = try! Realm(configuration: config)
        
        let list = realm.objects(DO_UpLoad.self).filter("status in %@ AND retryCount < %d",status, PoolConstants.Configure.UPLOAD_RETRY_LIMIT )
        var results = [UpLoadModel]()
        for item in list{
            let uploadObj = item.wrapToUpLoadModel()
            results.append(uploadObj)
        }
        return results
    }
    func updateUploadStatusById(upload : UpLoadModel, status : Int){
        let uploadTemp = upload
        uploadTemp.status = status
        let upLoad2 = uploadTemp.wrapToUpLoadObject()
        let realm = try! Realm(configuration: config)
        
        try! realm.write {
            realm.create(DO_UpLoad.self, value: ["idAuto":upLoad2.idAuto, "status" : upLoad2.status], update: Realm.UpdatePolicy.all)
        }
    }
    func updateUploadRetryById(upload : UpLoadModel, retry : Int){
        let uploadTemp = upload
        uploadTemp.retryCount = retry
        let upLoad2 = uploadTemp.wrapToUpLoadObject()
        let realm = try! Realm(configuration: config)
        try! realm.write {
            realm.create(DO_UpLoad.self, value: ["idAuto":upLoad2.idAuto, "retryCount" : upLoad2.retryCount], update: Realm.UpdatePolicy.all)
        }
    }
    func updateUploadLinkById(upload : UpLoadModel, links : [UploadDataTask]){
        let uploadTemp = upload
        uploadTemp.link = links
        let upLoad2 = uploadTemp.wrapToUpLoadObject()
        let realm = try! Realm(configuration: config)
        
        try! realm.write {
            realm.create(DO_UpLoad.self, value: ["idAuto":upLoad2.idAuto, "_backingLinks" : upLoad2._backingLinks], update: Realm.UpdatePolicy.all)
        }
        print("abc")
    }
    func insertUploads(uploads : [UpLoadModel]){
        let realm = try! Realm(configuration: config)
        var list = [DO_UpLoad]()
        for item in uploads{
            list.append(item.wrapToUpLoadObject())
        }
        try! realm.write {
            realm.add(list, update: Realm.UpdatePolicy.all)
        }
    }
    func insertUpload(upload : UpLoadModel){
        let realm = try! Realm(configuration: config)
        try! realm.write {
            realm.add(upload.wrapToUpLoadObject(), update: Realm.UpdatePolicy.all)
        }
    }
    func incrementUpLoadID() -> Int {
        let realm = try! Realm(configuration: config)
        return (realm.objects(DO_UpLoad.self).max(ofProperty: "idAuto") as Int? ?? 0) + 1
    }
    func resetRetryOfUpload(byIdTemp idTemp : String){
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_UpLoad.self).filter("cardID = %@",idTemp)
        if let obj = objs.first{
            try! realm.write {
                obj.retryCount = 0
            }
        }
    }
    //MARK: -Ranking
    func getAllRanks() -> [RankingModel] {
        let realm = try! Realm(configuration: config)
        let list = realm.objects(DO_Rank.self)
        var results = [RankingModel]()
        for item in list{
            let actionObj = item.wrapToRankingModel()
            results.append(actionObj)
        }
        return results
    }
    func getAllRanksSortByScore(ascending : Bool) -> [RankingModel]  {
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_Rank.self)
        let list =  objs.sorted(byKeyPath: "publishDate", ascending: ascending).sorted(byKeyPath: "finalScore", ascending: ascending)
        var results = [RankingModel]()
        for item in list{
            let actionObj = item.wrapToRankingModel()
            results.append(actionObj)
        }
        return results
    }
    func getAllRanksHavingIds(ids: [String]) -> [RankingModel]{
        let realm = try! Realm(configuration: config)
        var results = [RankingModel]()
        let predicate = NSPredicate(format: "id IN %@",ids)
        let cards = realm.objects(DO_Rank.self).filter(predicate)
        for card in cards{
            results.append(card.wrapToRankingModel())
        }
        return results
    }
    
    func getAllRanksOfUser(id: String) -> [RankingModel]{
        let realm = try! Realm(configuration: config)
        var results = [RankingModel]()
        let predicate = NSPredicate(format: "ownerUser == %@",id)
        let cards = realm.objects(DO_Rank.self).filter(predicate)
        for card in cards{
            results.append(card.wrapToRankingModel())
        }
        return results
    }
    
    
    func getAllRankIdsOfUser(id: String) -> [String]{
        let realm = try! Realm(configuration: config)
        var results = [String]()
        let predicate = NSPredicate(format: "ownerUser == %@",id)
        let cards = realm.objects(DO_Rank.self).filter(predicate)
        for card in cards{
            results.append(card.wrapToRankingModel().id)
        }
        return results
    }
    
    func getAllRanksNotSeen(ids : [Int])-> [RankingModel]{
        let realm = try! Realm(configuration: config)
        var results = [RankingModel]()
        let predicate = NSPredicate(format: "NOT (id IN %@)",ids)
        let cards = realm.objects(DO_Rank.self).filter(predicate).sorted(byKeyPath: "publishDate", ascending: false).sorted(byKeyPath: "finalScore", ascending: false)
        for card in cards{
            results.append(card.wrapToRankingModel())
        }
        return results
    }
    
    func getIDRankForDelete(ids : [String])->[String]{
        var listDeleted : [String] = [String]()
        let realm = try! Realm(configuration: config)
        let now  = Date().timeIntervalSince1970 //ss
        let nowInt : Int64 = Int64(now)
        let timeDecay = nowInt - PoolConstants.BackgroundConfig.Time_Limit_For_Delete
        
        let cardsForDelete = realm.objects(DO_Rank.self).filter("publishDate <= %ld", timeDecay)
        listDeleted = cardsForDelete.map{$0.id}
        
        if listDeleted.count >= PoolConstants.BackgroundConfig.Number_Card_Delete{
            return Array(listDeleted[0..<PoolConstants.BackgroundConfig.Number_Card_Delete])
        }
        
        let cardsLowScoreForDelete = realm.objects(DO_Rank.self).filter("publishDate > %ld AND (NOT (id IN %@))", timeDecay, ids).sorted(byKeyPath: "finalScore", ascending: false)
        let listLowScoreDelete = cardsLowScoreForDelete.map{$0.id}
        
        let set = Set(listDeleted)
        let listCombine = Array(set.union(listLowScoreDelete))
        
        if listCombine.count >= PoolConstants.BackgroundConfig.Number_Card_Delete{
            return Array(listCombine[0..<PoolConstants.BackgroundConfig.Number_Card_Delete])
        }
        return listCombine
    }
    
    func deleteOverCapacity(ids : [String]){
        let realm = try! Realm(configuration: config)
        let cardsForDelete = realm.objects(DO_Rank.self).filter("id IN %@", ids)
        try! realm.write {
            for item in cardsForDelete{
                realm.delete(item)
            }
        }
    }
    
    func deleteAllCardOutOfDate()->[String]{
        var listDeleted : [String] = [String]()
        let realm = try! Realm(configuration: config)
        let now  = Date().timeIntervalSince1970 //ss
        let nowInt : Int64 = Int64(now)
        let timeDecay = nowInt - PoolConstants.BackgroundConfig.Time_Limit_For_Delete
        
        let cardsForDelete = realm.objects(DO_Rank.self).filter("publishDate <= %ld", timeDecay)
        listDeleted = cardsForDelete.map{$0.id}
        try! realm.write {
            for item in cardsForDelete{
                realm.delete(item)
            }
        }
        return listDeleted
    }
    
    func deleteOverCapacityBoder(ids : [String])->[String]{
        let now  = Date().timeIntervalSince1970 //ss
        let nowInt : Int64 = Int64(now)
        let timeDecay = nowInt - PoolConstants.BackgroundConfig.Time_Limit_For_Delete
        
        var listDeleted : [String] = [String]()
        let realm = try! Realm(configuration: config)
        let cardsForDelete = realm.objects(DO_Rank.self).filter("publishDate > %ld AND (NOT (id IN %@))", timeDecay, ids).sorted(byKeyPath: "publishDate", ascending: false).sorted(byKeyPath: "finalScore", ascending: false)
        for item in cardsForDelete.reversed(){
            if listDeleted.count >= PoolConstants.BackgroundConfig.Number_Card_Delete {
                break
            }
            listDeleted.append(item.id)
            try! realm.write {
                realm.delete(item)
            }
            
        }
        return listDeleted
    }
    
    func deleteAllRanks(){
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_Rank.self)
        for obj in objs.reversed(){
            try! realm.write {
                realm.delete(obj)
            }
        }
    }
    
    func insertRanks(ranks : [RankingModel]){
        let realm = try! Realm(configuration: config)
        var list = [DO_Rank]()
        for item in ranks{
            list.append(item.wrapToDO_Rank())
        }
        try! realm.write {
            realm.add(list, update: Realm.UpdatePolicy.all)
        }
    }
    func insertRank(rank : RankingModel){
        let realm = try! Realm(configuration: config)
        try! realm.write {
            realm.add(rank.wrapToDO_Rank(),update: Realm.UpdatePolicy.all)
        }
    }
    
    func updateRank(rank : RankingModel){
        let realm = try! Realm(configuration: config)
        try! realm.write {
            realm.create(DO_Rank.self, value: ["id":rank.id, "type" : rank.type,"baseScore" : rank.baseScore, "publishDate": rank.publishDate, "personalRank":rank.personalRank, "numberOfClicks": rank.numberOfClicks,"finalScore" : rank.finalScore,"ownerUser":rank.ownerUser], update: Realm.UpdatePolicy.all)
        }
    }
    func updateRanks(ranks : [RankingModel]){
        let realm = try! Realm(configuration: config)
        for rank in ranks {
            try! realm.write {
                realm.create(DO_Rank.self, value: ["id":rank.id, "type" : rank.type, "baseScore" : rank.baseScore, "publishDate": rank.publishDate, "personalRank":rank.personalRank, "numberOfClicks": rank.numberOfClicks,"finalScore" : rank.finalScore,"ownerUser":rank.ownerUser], update: Realm.UpdatePolicy.all)
            }
        }
//        print("updateRanks DB complete")
    }
    func updateClick( rankID : String){
        let realm = try! Realm(configuration: config)
        let obj = realm.objects(DO_Rank.self).filter("id = %@",rankID).first
        if obj == nil{
            return
        }
        try! realm.write {
            obj!.numberOfClicks += 1
        }
    }
    func updateDomain(data : String){
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_Rank.self).filter("domain LIKE %@",data)
        for obj in objs{
            try! realm.write {
                obj.userReadByDomain += 1
            }
        }
    }
    func updateChannel(data : String){
        let realm = try! Realm(configuration: config)
        let objs = realm.objects(DO_Rank.self).filter("channel LIKE %@",data)
        for obj in objs{
            try! realm.write {
                obj.userReadByChannel += 1
            }
        }
    }
    
    func getConfigForUserID(userID : String) -> Realm.Configuration{
        let varDBName = "\(PoolConstants.Database.Prefix_DataBase_Pool)\(userID).realm"
        let array = PoolManager.shareInstance.getDecryptionKey(userID: userID)
        let keyEnCryptor = NSMutableData()
        keyEnCryptor.append(array, length: 64)
        let documentUrl = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
        let url = documentUrl.appendingPathComponent(varDBName)
        
        let oldConfig = Realm.Configuration(fileURL: url, inMemoryIdentifier: nil, syncConfiguration: nil, encryptionKey: keyEnCryptor as Data, readOnly: false, schemaVersion: 1, migrationBlock: nil, deleteRealmIfMigrationNeeded: false, shouldCompactOnLaunch: nil, objectTypes: [DO_Action.self,DO_Rank.self, DO_UpLoad.self,RealmString.self, DO_UploadDataTask.self])
        return oldConfig
        
    }
    func mergeDB(fromOldUser oldUser : String, toNewUser newUser : String){
        let oldConfig = self.getConfigForUserID(userID: oldUser)
        let newConfig = self.getConfigForUserID(userID: newUser)
        let oldRealm = try! Realm(configuration: oldConfig)
        let newRealm = try! Realm(configuration: newConfig)
        
        //lay het data trong oldRealm
//        DO_Action
        let newActions = newRealm.objects(DO_Action.self)
        var listIDNews = [String]()
        for item in newActions{
            listIDNews.append(item.rankID)
        }
        let oldActions = oldRealm.objects(DO_Action.self).filter("NOT (rankID in %@)",listIDNews)
        print("merge \(oldActions.count) actions" )
        for actionItem in oldActions{
            try! newRealm.write {
                newRealm.add(actionItem.wrapToActionModel().wrapToDO_Action())
            }
        }
        
        
//        DO_Rank
        let newRanks = newRealm.objects(DO_Rank.self)
        listIDNews = [String]()
        for item in newRanks{
            listIDNews.append(item.id)
        }
        let oldRanks = oldRealm.objects(DO_Rank.self).filter("NOT (id in %@)",listIDNews)
        print("merge \(oldRanks.count) Ranks" )
        
        for rankItem in oldRanks{
            try! newRealm.write {
                newRealm.add(rankItem.wrapToRankingModel().wrapToDO_Rank())
            }
        }
        
        try! oldRealm.write {
            oldRealm.deleteAll()
        }
        
        // user guest ko co may cai con lai nen ko can lam
    }

}


