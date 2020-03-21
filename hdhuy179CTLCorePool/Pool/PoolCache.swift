//
//  PoolCache.swift
//  PegaXPool
//
//  Created by thailinh on 1/11/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class PoolCache {
    static let shareInstance =  PoolCache()
    var listRanks = [RankingModel]()
    var listActions = [ActionModel]()
//    var listShowIds = [Int]()
    var showIdsMap : [Int : [String]] = [Int : [String]]()
    var patternMap : [Int : [[Int]]] = [Int : [[Int]]]()
    var clientWaitData : Bool = false
    var uploads = [UpLoadModel]()
//    var uniqueIDUser : String?
    
    func clear(){
        if self.showIdsMap.keys.count > 0{
            self.showIdsMap.removeAll()
        }
        if self.patternMap.keys.count > 0{
            self.patternMap.removeAll()
        }
        self.clearWhenLogOut()
    }
    func clearWhenLogOut(){
        if listRanks.count > 0{
            listRanks.removeAll()
        }
        if listActions.count > 0{
            listActions.removeAll()
        }
        clientWaitData = false
    }
    func deleteCardIsSeen(byID listID : [String]){
        let listKey = Array(self.showIdsMap.keys)
        
        if listKey.count > 0{
            for key in listKey{
                if var arrayIds = self.showIdsMap[key]{
                    
                    let listR = arrayIds.filter{ !listID.contains($0)}
                    self.showIdsMap[key] = listR
                }
            }
        }
        // kiem tra
        let listAll = self.getCurrentShowIds()
        if listAll.contains(listID[0]){
            print("CTLSocketLog Delete Cache Fail")
        }else{
            print("CTLSocketLog Delete Cache Success")
        }
        
    }
    //MARK: - upload
    func pushUpload(upload : UpLoadModel){
        uploads.append(upload)
    }
    func pullUpload() -> [UpLoadModel]{
        var result = [UpLoadModel]()
        result.append(contentsOf: uploads)
        uploads.removeAll()
        return result
    }
    func getAvailableCount(id : Int, limit : Int) -> Int{
        if showIdsMap[id] != nil{
            let showIds = showIdsMap[id]
            if showIds != nil && showIds!.count>0{
                var availableCount = 0
                for item in self.listRanks{
                    if !showIds!.contains(item.id){
                        availableCount += 1
                    }
                    if limit > 0 && availableCount >= limit{
                        break
                    }

                }
                if PoolConstants.Debug.debugLog{ print( "availableCount = \(availableCount)" )}
                return availableCount
            }else{
                if PoolConstants.Debug.debugLog{ print( "NullPointException : list showids null with id = \(id)" )}
            }
        }else{
            if PoolConstants.Debug.debugLog{ print( "Map ids not found id = \(id)" )}
        }
        return 0
    }
    
    func getRankCount(isSeen : Bool) -> Int{
        var count = 0
        if listRanks.count > 0{
            for i in 0..<listRanks.count{
                let item = listRanks[i]
                if item.isSeen == isSeen{
                    count += 1;
                }
            }
        }
        return count
    }
    
    func clearListShow(id :Int){
        if showIdsMap[id] != nil{
            showIdsMap[id]?.removeAll()
        }else{
            if PoolConstants.Debug.debugLog{ print( "Map not found id = \(id)" )}
        }
    }
    func updateID (id : Int){
        if (self.showIdsMap[id] == nil){
            showIdsMap[id] = [String]()
        }
    }
    func setPattern( id : Int , pattern : [[Int]]){
        patternMap[id] = pattern
    }
    func getCurrentShowIds()-> [String]{
        let listKey = Array(self.showIdsMap.keys)
        if listKey.count > 0{
            var results : Set<String> = Set<String>()
            for key in listKey{
                if let arrayIds = self.showIdsMap[key]{
                    results = results.union(arrayIds)
                }
            }
            return Array(results)
        }
        return [String]()
    }
}
