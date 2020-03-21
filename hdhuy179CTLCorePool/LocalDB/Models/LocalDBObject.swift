//
//  LocalDBObject.swift
//  PegaXPool
//
//  Created by thailinh on 1/10/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import RealmSwift
//class DAOCard: Object {
//    var id = RealmOptional<Int>()
//    @objc dynamic var picture: Data? = nil
//    @objc dynamic var title : String?
//    @objc dynamic var sapo : String?
//    @objc dynamic var content : String?
//    @objc dynamic var url : String?
//    @objc dynamic var source : String?
//}
class DO_Action : Object {
    @objc dynamic var id : String = "0"
    @objc dynamic var type : Int = 0
    @objc dynamic var rankID : String = "0"
    @objc dynamic var data = ""
    @objc dynamic var retry : Int = 0
    @objc dynamic var status : Int = ActionSatus.Pending.rawValue
    @objc dynamic var value : String = ""
//    @objc dynamic var value = false
//    override static func primaryKey() -> String? {
//        return "id"
//    }
    convenience init(_id : String, type : Int, rankID : String, data : String,value : String, retry : Int, status : Int) {
        self.init()
        self.id = _id
        self.type = type
        self.rankID = rankID
        self.data = data
        self.status = status
        self.retry = retry
        self.value = value
    }
    convenience init(_id : String, type : Int, rankID : String, data : String) {
        self.init()
        self.id = _id
        self.type = type
        self.rankID = rankID
        self.data = data
        self.status = ActionSatus.Pending.rawValue
        self.retry = 0
    }
    
    func wrapToActionModel() -> ActionModel{
        let model = ActionModel(_id: self.id, type: self.type, rankID: self.rankID, data: self.data, value: self.value, retry: self.retry, status: self.status)
        return model
    }
}
public class ActionModel{
    public var id : String = "0"
    public var type : Int
    public var rankID : String
    public var data : String = ""
    public var retry : Int = 0
    public var value : String = ""
    public var status : Int = ActionSatus.Pending.rawValue
    
    public init(_id : String, type : Int, rankID : String, data : String,value : String, retry : Int, status : Int) {
        self.id = _id
        self.type = type
        self.rankID = rankID
        self.data = data
        self.status = status
        self.retry = retry
        self.value = value
    }
    
    func wrapToDO_Action() -> DO_Action{
        let model = DO_Action(_id: self.id, type: self.type, rankID: self.rankID, data: self.data, value: self.value, retry: self.retry, status: self.status)
        return model
    }
}
public class RankingModel  {
    public var id : String = "0"
    public var type : Int = 0
    var numberOfClicks : Int64 = 0
    var userReadByDomain : Int64 = 0
    var userReadByChannel : Int64 = 0
    var publishDate : Int64 = 0
    var baseScore : Double = 1.0
    var personalRank : Double = 1.0
    public var finalScore : Double = 1.0
    var domain : String = ""
    var channel : String = ""
    var isSeen : Bool = false
    var ownerUser : String = ""
    
    func wrapToDO_Rank() -> DO_Rank{
        let model = DO_Rank(id: self.id, type: self.type, numberOfClicks: self.numberOfClicks, userReadByDomain: self.userReadByDomain, userReadByChannel: self.userReadByChannel, publishDate: self.publishDate, baseScore: self.baseScore, PPRofUser: self.personalRank ,domain : self.domain,channel : self.channel,finalScore : self.finalScore, ownerUser : self.ownerUser)
        return model
    }
    
    public convenience init(id : String,type: Int, numberOfClicks: Int64?, userReadByDomain: Int64?, userReadByChannel: Int64?, publishDate: Int64?, baseScore: Double?, PPRofUser: Double?,domain : String,channel : String, finalScore : Double, ownerUser : String) {
        self.init()
        self.id = id
        self.type = type
        self.numberOfClicks = numberOfClicks ?? 0
        self.userReadByDomain = userReadByDomain ?? 0
        self.userReadByChannel = userReadByChannel ?? 0
        self.publishDate = publishDate ?? 0
        self.baseScore = baseScore ?? 1.0
        self.personalRank = PPRofUser ?? 1.0
        self.finalScore = finalScore
        self.domain = domain
        self.channel = channel
        self.ownerUser = ownerUser
    }
    
    convenience init(dict : [String : Any]) {
        self.init()
        guard let _id = dict["id"] else { return  }
        self.id = _id as! String
        if let _type = dict["type"] as? Int{
            self.type = _type
        }
        if let _numberOfClicks = dict["numberOfClicks"] as? Int64{
            self.numberOfClicks = _numberOfClicks
        }
        if let _userReadByDomain = dict["userReadByDomain"] as? Int64{
            self.userReadByDomain = _userReadByDomain
        }
        if let _userReadByChannel = dict["userReadByChannel"] as? Int64{
            self.userReadByChannel = _userReadByChannel
        }
        if let _publishDate = dict["publishDate"] as? Int64{
            self.publishDate = _publishDate
        }
        if let _baseScore = dict["baseScore"] as? Double{
            self.baseScore = _baseScore
        }
        if let _personalRank = dict["personalRank"] as? Double{
            self.personalRank = _personalRank
        }
    }

}

class DO_Rank : Object {
    @objc dynamic var id : String = "0"
    @objc dynamic var type : Int = 0
    @objc dynamic var numberOfClicks : Int64 = 0
    @objc dynamic var userReadByDomain : Int64 = 0
    @objc dynamic var userReadByChannel : Int64 = 0
    @objc dynamic var publishDate : Int64 = 0
    @objc dynamic var baseScore : Double = 1.0
    @objc dynamic var personalRank : Double = 1.0
    @objc dynamic var finalScore : Double = 1.0
    @objc dynamic var domain : String = ""
    @objc dynamic var channel : String = ""
    @objc dynamic var ownerUser : String = ""
//    @objc dynamic var isSeen : Bool = false
    convenience init(id : String,type: Int, numberOfClicks: Int64?, userReadByDomain: Int64?, userReadByChannel: Int64?, publishDate: Int64?, baseScore: Double?, PPRofUser: Double?,domain : String,channel : String , finalScore : Double, ownerUser : String) {
        self.init()
        self.id = id
        self.type = type
        self.numberOfClicks = numberOfClicks ?? 0
        self.userReadByDomain = userReadByDomain ?? 0
        self.userReadByChannel = userReadByChannel ?? 0
        self.publishDate = publishDate ?? 0
        self.baseScore = baseScore ?? 1.0
        self.personalRank = PPRofUser ?? 1.0
        self.finalScore = finalScore 
        self.domain = domain
        self.channel = channel
        self.ownerUser = ownerUser
    }
    func wrapToRankingModel() -> RankingModel{
        let model = RankingModel(id: self.id, type: self.type, numberOfClicks: self.numberOfClicks, userReadByDomain: self.userReadByDomain, userReadByChannel: self.userReadByChannel, publishDate: self.publishDate, baseScore: self.baseScore, PPRofUser: self.personalRank,domain : self.domain,channel : self.channel,finalScore : self.finalScore, ownerUser : self.ownerUser)
        return model
    }
    
    
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
