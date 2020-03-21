//
//  DO_UpLoad.swift
//  PegaXPool
//
//  Created by thailinh on 3/12/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import RealmSwift
class RealmString: Object {
    @objc dynamic var stringValue = ""
}
class RealmInt: Object {
    @objc dynamic var intValue : Int = 0
}
open class DO_UploadDataTask : Object{
    @objc public dynamic var id = ""
    @objc public dynamic var content = Data()
    override public static func primaryKey() -> String? {
        return "id"
    }
    public func wrapToUpLoadDataTask() -> UploadDataTask{
        
        let result = self.content
        let jsonResult = try! JSONSerialization.jsonObject(with: result, options: .mutableLeaves)
        if let jsonData = jsonResult as? [String : Any]{
            return UploadDataTask(dict: jsonData)
        }
        print("wrapToUpLoadDataTask fail. deo phai json")
        return UploadDataTask()
    }
    
    //    @objc dynamic var id = ""
    //    @objc dynamic var local = ""
    //    @objc dynamic var link = ""
    //    @objc dynamic var width = 0
    //    @objc dynamic var height = 0
    //    @objc dynamic var mediaType = 0
    //
    //
    //    convenience init(id : String, local : String, link : String, width : Int, height : Int, mediaType : Int){
    //        self.init()
    //        self.id = id
    //        self.local = local
    //        self.link = link
    //        self.width = width
    //        self.height = height
    //        self.mediaType = mediaType
    //
    //    }
    //    func wrapToUpLoadDataTask() -> UploadDataTask{
    //        let model = UploadDataTask(id: self.id, local: self.local, link: self.link, width: self.width, height: self.height, mediaType: self.mediaType)
    //        return model
    //    }
    //    override static func primaryKey() -> String? {
    //        return "id"
    //    }
}
open class UploadDataTask{
    public var id = ""
    public var local = ""
    public var link = ""
    public var width = 0
    public var height = 0
    public var mediaType = 0
    
    public init() { }
    
    public convenience init(id : String, local : String, link : String, width : Int, height : Int, mediaType : Int){
        self.init()
        self.id = id
        self.local = local
        self.link = link
        self.width = width
        self.height = height
        self.mediaType = mediaType
    }
    convenience init(dict : [String : Any]) {
        self.init()
        if let temp = dict["id"] as? String{
            self.id = temp
        }
        if let temp = dict["local"] as? String{
            self.local = temp
        }
        if let temp = dict["link"] as? String{
            self.link = temp
        }
        if let temp = dict["width"] as? Int{
            self.width = temp
        }
        if let temp = dict["height"] as? Int{
            self.height = temp
        }
        if let temp = dict["mediaType"] as? Int{
            self.mediaType = temp
        }
    }
    open func wrapToDictionary() -> [String : Any] {
        var dic = [String : Any]()
        dic["id"] =  self.id
        dic["local"] =  self.local
        dic["link"] =  self.link
        dic["width"] =  self.width
        dic["height"] =  self.height
        dic["mediaType"] =  self.mediaType
        return dic
    }
    open func wrapToUpLoadDataTaskDatabaseObject() -> DO_UploadDataTask{
        let model = DO_UploadDataTask()
        model.id = self.id
        if let json = try? JSONSerialization.data(withJSONObject: self.wrapToDictionary(), options: JSONSerialization.WritingOptions.prettyPrinted){
            model.content = json
        }else{
            print("wrapToUpLoadDataTaskDatabaseObject fail. ko phai json ")
        }
        
        return model
    }
    
    //    func wrapToUpLoadDataTaskDatabaseObject() -> DO_UploadDataTask{
    //        let model = DO_UploadDataTask(id: self.id, local: self.local, link: self.link, width: self.width, height: self.height, mediaType: self.mediaType)
    //        return model
    //    }
    
}
class DO_UpLoad : Object{
    @objc dynamic var idAuto : Int = 0
    @objc dynamic var id : String = "0"
    @objc dynamic var status : Int = 0
    @objc dynamic var uploadType : Int = 0
    @objc dynamic var retryCount : Int = 0
    @objc dynamic var cardID : String = ""
    @objc dynamic var isNeedRequest = 1
    var _backingLocals = List<RealmString>()
    var _backinglistIDMedia = List<RealmString>()
    var _backingLinks = List<DO_UploadDataTask>()
    var _backingTypeMedia = List<RealmString>()
    //    var typeMedia : [Int] = [Int]()
    var typeMedia : [Int]{
        get {
            return _backingTypeMedia.map{Int($0.stringValue) ?? 0}
        }
        set {
            _backingTypeMedia.removeAll()
            _backingTypeMedia.append(objectsIn: newValue.map({RealmString(value: ["\($0)"])}))
        }
    }
    var listIDMedia : [String]{
        get {
            return _backinglistIDMedia.map{$0.stringValue}
        }
        set {
            _backinglistIDMedia.removeAll()
            _backinglistIDMedia.append(objectsIn: newValue.map({RealmString(value: [$0])}))
        }
    }
    var locals : [String]{
        get {
            return _backingLocals.map{$0.stringValue}
        }
        set {
            _backingLocals.removeAll()
            _backingLocals.append(objectsIn: newValue.map({RealmString(value: [$0])}))
        }
    }
    var links : [UploadDataTask]{
        get {
            return _backingLinks.map{$0.wrapToUpLoadDataTask()}
        }
        set{
            _backingLinks.removeAll()
            for item in newValue{
                _backingLinks.append(item.wrapToUpLoadDataTaskDatabaseObject())
            }
            
        }
    }
    
    override static func primaryKey() -> String? {
        return "idAuto"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["locals","links","typeMedia"]
    }
    
    convenience init(id: String, status: Int, uploadType: Int, retryCount: Int, cardID: String, local: [String],typeMedia : [Int], link: [UploadDataTask], idAuto : Int?,  isNeedRequest : Int?, listIDMedia : [String]){
        self.init()
        self.id = id
        if let idAuTo = idAuto{
            self.idAuto = idAuTo
        }else{
            self.idAuto = LocalDatabase.shareInstance.incrementUpLoadID()
        }
        self.isNeedRequest = isNeedRequest ?? 1
        self.status = status
        self.uploadType = uploadType
        self.retryCount = retryCount
        self.cardID = cardID
        self.locals = local
        self.links = link
        self.typeMedia = typeMedia
        self.listIDMedia = listIDMedia
    }
    
    func wrapToUpLoadModel() -> UpLoadModel{
        let model = UpLoadModel(id: self.id, status: self.status, uploadType: self.uploadType, retryCount: self.retryCount, cardID: self.cardID, local: self.locals,typeMedia : self.typeMedia, link: self.links, idAuto : self.idAuto,isNeedRequest : self.isNeedRequest, listIDMedia : self.listIDMedia)
        return model
    }
}



