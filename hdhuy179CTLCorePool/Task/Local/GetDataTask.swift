//
//  GetDataTask.swift
//  PegaXPool
//
//  Created by thailinh on 1/10/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
class GetDataTask: BaseWokerOperationTask {
    var idTab : Int
    init(_id: TaskID, idTab : Int) {
        self.idTab = idTab
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
        guard var showIds = PoolCache.shareInstance.showIdsMap[idTab] else {
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        
        if PoolCache.shareInstance.listRanks.count > 0{
            var ids = [String]()
            let patterns = PoolCache.shareInstance.patternMap[idTab]
//            print("Check patterns ",patterns )
            if patterns != nil && patterns!.count > 0{
                if PoolConstants.Debug.debugLog {print(" Get Data with pattern ")}
                var specificCount = 0
                var anyCount = 0
//                print("Check tao map so luong pattern theo newFeed type")
                // tao map so luong pattern theo newFeed type
                var patternCount = [Int : Int]()
                for pattern in patterns!{
                    for value in pattern{
                        if patternCount[value] != nil{
                            let count = patternCount[value]!
                            patternCount[value] = count + 1
                        }else{
                            patternCount[value] = 1
                        }
                        if (value != PoolConstants.Configure.Pattern_Any){
                            specificCount += 1
                        }else{
                            anyCount += 1
                        }
                    }
                }
//                print("Check anyCount = \(anyCount) va specificCount = \(specificCount) patternCount = ",patternCount)
//                print("Check Lấy dữ liệu theo theo số liệu map được tạo theo pattern")
                // Lấy dữ liệu theo theo số liệu map được tạo theo pattern
                var temp = [Int : [String]]()
                var mapIds = [String : Bool]()
                for item in PoolCache.shareInstance.listRanks{
                    let type = item.type
                    let id = item.id
                    let isShow = showIds.contains(item.id)
                    if !isShow && patternCount[type] != nil && patternCount[type]! > 0{
                        self.addMap(temp: &temp, patternCount: &patternCount, type: type, id: id)
                        mapIds[id] = true
                        specificCount -= 1
                    }
                    if specificCount <= 0{
                        break
                    }
                }
//                print("Check mapIds = ",mapIds)
//
//                print("Check temp = ",temp)
                
//                print("Check Lấy dữ liệu cho map -1 ( thay thế bằng bất kì card nào )")
                // Lấy dữ liệu cho map -1 ( thay thế bằng bất kì card nào )
                if patternCount[PoolConstants.Configure.Pattern_Any] != nil && patternCount[PoolConstants.Configure.Pattern_Any]! > 0{
                    for item in PoolCache.shareInstance.listRanks{
                        let id = item.id
                        let isShow = showIds.contains(id) || mapIds[id] ?? false
                        if !isShow{
                            addMap(temp: &temp, patternCount: &patternCount, type: PoolConstants.Configure.Pattern_Any, id: id)
                            anyCount -= 1
                        }
                        if anyCount <= 0{
                            break
                        }
                    }
                }
//                print("Check temp2 = ",temp)
//                print("Check fill data")
                // fill data
                for pattern in patterns!{
                    for value in pattern{
                        if temp[value] != nil && temp[value]!.count > 0{
                            ids.append(temp[value]!.remove(at: 0))
                            break
                        }
                    }
                }
//                print("Check ids= ",ids)
            }else{
                if PoolConstants.Debug.debugLog {print(" Get Data with NO pattern => get all ")}
                // lay tin chua seen. isseen = false.
                // hien tai coi nhu nhung thang lon y nem ra cho client se tinhh luon la seen nen set value = true
                for item in PoolCache.shareInstance.listRanks{
                    if !showIds.contains(item.id){
                        ids.append(item.id)
                        if ids.count >= PoolConstants.Configure.DATA_COUNT_PER_GET{
                            break
                        }
                    }
                }
            }
            
//            print("Check showIds= ",showIds)
            // add may thang lin y vao cachhe
            showIds.append(contentsOf: ids)
//            print("Check showIds after add = ",showIds)
            
            PoolCache.shareInstance.showIdsMap[idTab] = showIds
            // tinh xem co phai lay them data ko? list card chua seen con lai < 25% cua 1page.
            let availableCountUnSeen = PoolCache.shareInstance.getAvailableCount(id:idTab , limit: PoolConstants.Configure.MIN_ITEM_CACHE)
            
            if availableCountUnSeen < PoolConstants.Configure.MIN_ITEM_CACHE{
                if PoolConstants.Debug.debugLog{ print( "has \(availableCountUnSeen) item. Need more data, call remote" )}
                self.taskProtocol?.needMoreData()
            }else{
                if PoolConstants.Debug.debugLog{ print( "has over %d item", PoolConstants.Configure.MIN_ITEM_CACHE )}
            }
            
            self.taskProtocol?.pullData(idTab: idTab, ids: ids)
            PoolCache.shareInstance.clientWaitData = false
        }else{
            if PoolConstants.Debug.debugLog{ print( "NullPointException : ranking in cache null or empty" )}
            
            self.taskProtocol?.needMoreData()
            PoolCache.shareInstance.clientWaitData = true
//            self.taskProtocol?.complete(taskID: self.id)
            self.taskProtocol?.fail(task: self, isValid: false)
            return
        }
        
        let endTime  = Timestamp.getTimeStamp()
        let duration = TimeInterval(endTime)! - TimeInterval(beginTime)!
        if PoolConstants.Debug.debugTask {print(" Task Complete id : \(String(describing: self.id)) : ",endTime ,"\t DURATION =  \(duration) ms")}
        self.taskProtocol?.complete(taskID: self.id)
    }
    func addMap( temp : inout [Int : [String]] , patternCount : inout [Int : Int], type : Int, id : String){
        if temp[type] != nil{
            temp[type]!.append(id)
        }else{
            temp[type] = [String]()
            temp[type]!.append(id)
        }
        patternCount[type] = patternCount[type]! - 1
    }
}
