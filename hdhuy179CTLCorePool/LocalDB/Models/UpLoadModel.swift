//
//  UpLoadModel.swift
//  PegaXPool
//
//  Created by thailinh on 3/12/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
public enum UploadStatus : Int{
    case PENDING = 1
    case UPLOAD_SUCCESS = 2
    case COMPELE = 3
    case FAIL = 4
}

public class UpLoadModel{
    public var id : String = "0"
    public var status : Int = 0
    public var uploadType : Int = 0
    public var retryCount : Int = 0
    public var cardID : String = ""
    public var local : [String] = [String]()
    public var listIDMedia : [String] = [String]()
    public var typeMedia : [Int] = [Int]()
    public var link : [UploadDataTask] = [UploadDataTask]()
    public var idAuto : Int = 0
    public var isNeedRequest = 1
    public convenience init(id: String, status: Int, uploadType: Int, retryCount: Int, cardID: String, local: [String],typeMedia : [Int], link: [UploadDataTask], idAuto: Int?, isNeedRequest : Int?, listIDMedia : [String]){
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
        self.local = local
        self.link = link
        self.typeMedia = typeMedia
        self.listIDMedia = listIDMedia
        
    }
    public convenience init(uploadType: Int, cardID: String, local: [String],typeMedia : [Int], listIDMedia : [String]){
        self.init()
        
        self.idAuto = LocalDatabase.shareInstance.incrementUpLoadID()
        self.status = UploadStatus.PENDING.rawValue
        self.uploadType = uploadType
        self.retryCount = 0
        self.cardID = cardID
        self.local = local
        self.link = [UploadDataTask]()
        self.isNeedRequest = 1
        self.typeMedia = typeMedia
        self.listIDMedia = listIDMedia
        
    }
    func wrapToUpLoadObject() -> DO_UpLoad{
        let model = DO_UpLoad(id: self.id, status: self.status, uploadType: self.uploadType, retryCount: self.retryCount, cardID: self.cardID, local: self.local,typeMedia : self.typeMedia, link: self.link, idAuto : self.idAuto,isNeedRequest : self.isNeedRequest, listIDMedia : self.listIDMedia)
        return model
    }
}

