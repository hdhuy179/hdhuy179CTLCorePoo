//
//  PoolManagerProtocol.swift
//  PegaXPool
//
//  Created by thailinh on 1/10/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
public protocol PoolManagerProtocol : class{
    func noMoreData(typeOfRequest: Int)
    func getFeedFail(typeOfRequest: Int)
    func receiveData(idTab : Int ,ids : [String])
    func requestNotReceiveAfter(second : TimeInterval)
    func deleteListCard(ids: [String])
    
    func socketPrepareInit()
    func socketConnecting()
    func socketConnected()
    func socketReconnect()
    func socketDisconnect()
    func socketError(data : [Any])
//    func socketReceiveBreakingNews(data : [[String : Any]])
    func socketReceiveBreakingNews(data : [String : Any])
    func socketReceiveDeletePost(data : [String : Any])
    func socketReceiveLivingComment(data : [String : Any])
    func socketReceiveLivingCommentDelete(data : [String : Any])
    func socketReceiveLivingCommentUpdate(data : [String : Any])
    func socketReceiveLivingCommentTyping(data : [String : Any])
    func socketReceiveWidget(data : [String : Any])
    func socketReceiveFocusPost(data : [String : Any])    
    func socketUpdateRoleAndPermission(role : Int , data : [String : Any])
    func socketUpdateLive(role : Int , data : [String : Any])
    func socketReceivePermissionAll(data : [String : Any])
    func socketReceivePermissionPost(data : [String : Any])
    func socketReceivePermissionPage(data : [String : Any])
    func socketReceivePermissionUserSuppend(data : [String : Any])
    func socketReceivePermissionUserDeactive(data : [String : Any])
    func socketReceiveAny(data : [String : Any])
    func socketReceiveUserSessionExpire(data : [String : Any])
    func socketReceiveUserNotify(data : [String : Any])
    func socketReceiveGroupNoti(data : [String : Any])
    
    func socketReceiveSetting(data : [String : Any])
    func socketReceiveInspection(data : [String : Any])
}
public protocol PoolInitProtocol : class{
    func prepareInit()
    func initFail()
    func initSuccess()
}
class Timestamp {
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS "
        return formatter
    }()
    
    func printTimestamp() {
        print(dateFormatter.string(from: Date()))
    }
    func getTime() -> String {
        return dateFormatter.string(from: Date())
    }
    class func getTimeStamp()->String{
        let now  = Date().timeIntervalSince1970 * 1000
        return "\(now)"
    }
}
public struct PoolConstants {
    
    public struct Debug {
        public static var debugLog : Bool                                               = false
        public static var debugNetWork : Bool                                           = false
        public static var debugRanking : Bool                                           = false
        public static var debugTask : Bool                                              = false
        public static var debugTaskProtocol : Bool                                      = false
        public static var debugScore : Bool                                             = false
        public static var debugKeyDB : Bool                                             = false
        public static var debugSocket : Bool                                            = false
        public static var debugSocketClientEvent : Bool                                 = false
        public static var debugSocketAny : Bool                                         = false
        static let usingThreadManager : Bool                                            = true
    }
    
    public struct Configure {
        public static var DATA_MAX_IN_CACHE : Int                                       = 1000
        public static var DATA_COUNT_PER_GET : Int                                      = 20
        public static var MIN_ITEM_CACHE : Int                                          = Int( Double (DATA_COUNT_PER_GET)  *  1.75)
        public static var Pattern_Any : Int                                             = -1
        public static var UPLOAD_RETRY_LIMIT : Int                                      = 3
        public static var ACTION_RETRY_LIMIT : Int                                      = 3
        public static var InitSocket : Bool                                             = true
        public static var TwentyNewsFirst : Bool                                        = true
        public static var SocketConnectOnce : Bool                                      = false
        public static var SocketVersion2     : Bool                                     = false
        
    }
    public struct SocketEventCode {
        public static var Socket_Event_Code_Delete : Int                                     = 601
        public static var Socket_Event_Code_BreakingNews : Int                               = 602
        public static var Socket_Event_Code_Widget : Int                                     = 603
        public static var Socket_Event_Code_Role_UserNormal : Int                            = 620
        public static var Socket_Event_Code_Permission_Page : Int                            = 621
        public static var Socket_Event_Code_PostFocus_Join : Int                             = 605
        public static var Socket_Event_Code_PostFocus_Leave : Int                            = 606
        
        public static var Socket_Event_Code_Permission_Full : Int                            = 800
        public static var Socket_Event_Code_Permission_ReadPost : Int                        = 801
        public static var Socket_Event_Code_Permission_CreatePost : Int                      = 802
        public static var Socket_Event_Code_Permission_DeletePost : Int                      = 803
        public static var Socket_Event_Code_Permission_ReadComment : Int                     = 804
        public static var Socket_Event_Code_Permission_CreateComment : Int                   = 805
        public static var Socket_Event_Code_Permission_DeleteComment : Int                   = 806
        public static var Socket_Event_Code_Permission_AllowReact : Int                      = 807
        public static var Socket_Event_Code_Permission_NotAllowReact : Int                   = 808
        public static var Socket_Event_Code_Permission_AllowFollow : Int                     = 809
        public static var Socket_Event_Code_Permission_NotAllowFollow : Int                  = 810
        
        public static var Socket_Event_Code_Permission_Post : Int                            = 622
        public static var Socket_Event_Code_Role_UserSuppended : Int                         = 623
        public static var Socket_Event_Code_Role_User_DeActive : Int                         = 624
        public static var Socket_Event_Code_Role_User_Delete : Int                           = 625
        public static var Socket_Event_Code_Role_User_Admin : Int                            = 626
        public static var Socket_Event_Code_Role_User_Reader : Int                           = 627
        public static var Socket_Event_Code_Role_User_InviteCode : Int                       = 630
        public static var Socket_Event_Code_Role_User_OfficialUser : Int                     = 628
        public static var Socket_Event_Code_Role_User_ExpertUser : Int                       = 629
        public static var Socket_Event_Code_Role_User_InvitedPending : Int                   = 640
        public static var Socket_Event_Code_Role_User_FBLoggedIn : Int                       = 641
        public static var Socket_Event_Code_Role_User_DeniedLoggedIn : Int                   = 642
        public static var Socket_Event_Code_Role_User_HasBeenApproved : Int                  = 643
        public static var Socket_Event_Code_Role_User_KYC_Verify_Requirement : Int           = 644
        public static var Socket_Event_Code_Role_User_KYC_Waiting_Approve : Int              = 645
        public static var Socket_Event_Code_Role_GoToCountDown : Int                         = 900
        public static var Socket_Event_Code_Role_GoToWaiting : Int                           = 901
        public static var Socket_Event_Code_Role_GoToLiveStream : Int                        = 902
        public static var Socket_Event_Code_Get_New_Role : Int                               = 643
        
        public static var Socket_Event_Code_Group_Join : Int                                 = 802
        public static var Socket_Event_Code_Group_Leave : Int                                = 803
        public static var Socket_Event_Code_Group_Push_Noti : Int                            = 801
        
        public static var Socket_Event_Code_Other : Int                                      = 609
        public static var Socket_Event_Code_Comment : Int                                    = 703
        public static var Socket_Event_Code_Comment_Delete : Int                             = 704	
        public static var Socket_Event_Code_Comment_Update : Int                             = 705
        public static var Socket_Event_Code_Comment_Join : Int                               = 706
        public static var Socket_Event_Code_Comment_Leave : Int                              = 707
        public static var Socket_Event_Code_Comment_Join_Action : Int                        = 708
        public static var Socket_Event_Code_Comment_Leave_Action : Int                       = 709
        public static var Socket_Event_Code_Comment_Typing : Int                             = 710
        public static var Socket_Event_Code_FocusPost : Int                                  = 701
        public static var Socket_Event_Code_OutPost : Int                                    = 702
        public static var Socket_Max_Retry : Int                                             = 3
        
        
        public static var Socket_Event_Code_User_SessionExpire : Int                         = 101
        public static var Socket_Event_Code_User_Notify : Int                                = 104
        
        public static var Socket_Event_Code_Setting_DisableComment : Int                     = 365
        public static var Socket_Event_Code_Setting_Comment_Censorship : Int                 = 367
        
        public static var Socket_Event_Code_Inspection_16Plus : Int                          = 650
        public static var Socket_Event_Code_Inspection_18Plus : Int                          = 651
        public static var Socket_Event_Code_Inspection_PhanDong : Int                        = 652
        
    }
    public struct SocketEventName {
        public static var Socket_Event_Name_Post : String                                    = "post"
        public static var Socket_Event_Name_Group : String                                    = "group"
        public static var Socket_Event_Name_Comment : String                                 = "comment"
        public static var Socket_Event_Name_FocusPost : String                               = "focus"
        public static var Socket_Event_Name_Permission : String                              = "permission"
        public static var Socket_Event_Name_User : String                                    = "user"
        public static var Socket_Event_Name_Live : String                                    = "live"
        public static var Socket_Event_Name_Setting : String                                 = "setting"
        public static var Socket_Event_Name_Inspection : String                              = "inspection"// cai ten vai lol nay do Minh server gui. Deo co chu c. neu sau nay loi thi nho  la bao lai. chat o tele group sockettest 17h30 ngay 1/8/2019. thoi t doi lai dung la inspection cho chay dung.
    }
    public struct API{
//        public static var ovpSohaTV : String                                            = "https://ovp.sohatv.vn/api/app/kinghub/user/access-token"
        public static var ovpSohaTV : String                                            = "https://api.bigdata.kinghub.vn/api/v2/kinghub/video/access-token"
        public static var OVP_APP_KEY : String                                          = "g63hfzwu6heogfzxrop2z3v3hgii88im"
        public static var OVP_SECRET_KEY : String                                       = "dxjs9tppt24892rrotvz2easphjfd0vvzfhlo18efp5t2abe61u7mizmlhgpua6k"
        static var Debug_clientId : String                                              = "6fd5f82ef58685520af99ee1"
        static var Debug_secretKey : String                                             = "ae272c163d7e1bd408b27006898b2d3f"
        public static var SocketURL                                                     = "http://14.225.10.11"
        public static var SocketPort                                                    = "2511"
//        public static var SocketURL                                                     = "https://dev.v2.aio.lotus.vn"
//        public static var SocketPort                                                    = ""
        static var policyUrl                                                            = "https://api.bigdata.kinghub.vn/api/v2/kinghub/policy"
//        public static var SocketURLDev                                                     = "http://14.225.10.11"
//        public static var SocketPortDev                                                    = "2511"
    }
    public struct BackgroundConfig{
        static let nameOfQueues : String                                                = "ChuTieuThreadTask"
        static let maxConcurrentOperationCount : NSInteger                              = 4
        public static var scheduleDelay : TimeInterval                                  = 5
        public static var scheduleBetweenRequest : TimeInterval                         = 2
        public static var scheduleUploadTime : TimeInterval                             = 10
        public static var scheduleSendActionTime : TimeInterval                         = 8
        public static var Get_Data_Time_Limit   : TimeInterval                          = 1
        public static var schedule_Delete : TimeInterval                                = 7
        
        /// delete card when cardcount > Boder_Delete_Number 
        public static var Boder_Delete_Number : Int                                     = 350
        
        /// Time_Limit_For_Delete (second) 60*60*24*1 = 1 day
        public static var Time_Limit_For_Delete : Int64                                 = 60*60*24*1
        public static var Number_Card_Delete : Int                                      = 150
    }
    
    public struct Database {
        public static var Max_Card_Local : Int                                          = 1000
        public static var Prefix_DataBase_Pool : String                                 = "CTLPegaXLocalDatabasePool_"
        public static var Prefix_DataBase_Module : String                               = "CTLPegaXLocalDatabase"
        static let Prefix_DataBase_Encrypt : String                                     = "CanThaiLinhDepTrai"
        static let Suffix_DataBase_Encrypt : String                                     = "maimaivimotcongviectothonlamviechetminhvicongvaconghientatcatrituecuaminhvietchonodaithoicungchangcogica"
    }

}
public enum TaskID{
    case None
    case Get_Data
    case Action_Add
    case Ranking
    case Remote_Short_Term
    case Remote_Long_Term
    case Local_Insert_Rank
    case Local_Cache_Update
    case Pre_Order
    case Delete_Task
    case Hidden_Delete_Task
    case Upload_Task
    case Upload_Add_Task
    case Action_Remote_Task
}

public enum RemoteType : Int{
    case Short_Term = 2
    case Long_Term = 3
    case Short_Refresh = 1
}
public enum ActionType : Int{
    case Click  = 1
    case Read_By_Domain = 2
    case Read_By_Channel = 3
    case Like_Aciton = 4
    case Follow_Action = 5
    case Subcribe_Action = 6
    case Like_Comment_Action = 7
}
public enum MethodApi
{
    case PostApi
    case GetApi
    case PutApi
}
public enum ActionSatus : Int{
    case Pending = 0
    case Sending = 1
    case Complete = 2
}
public enum CreatePostCommentReasonFail : Int{
    case Network = 0
    case UploadMedia = 1
    case CreatePostComment = 2
}
public enum UpLoadMediaType : Int{
    case Image = 2
    case Video = 1
    case Gif = 3
    case Pdf = 4
    case File = 5
    case Other = 6
}
public enum PermissionCode : Int{
    case Socket_Event_Code_Permission_Full                              = 800
    case Socket_Event_Code_Permission_ReadPost                          = 801
    case Socket_Event_Code_Permission_CreatePost                        = 802
    case Socket_Event_Code_Permission_DeletePost                        = 803
    case Socket_Event_Code_Permission_ReadComment                       = 804
    case Socket_Event_Code_Permission_CreateComment                     = 805
    case Socket_Event_Code_Permission_DeleteComment                     = 806
    case Socket_Event_Code_Permission_AllowReact                        = 807
    case Socket_Event_Code_Permission_NotAllowReact                     = 808
    case Socket_Event_Code_Permission_AllowFollow                       = 809
    case Socket_Event_Code_Permission_NotAllowFollow                    = 810
}
public enum TypeHiddenDelete{
    case HiddenPost
    case HiddenUser
}
public enum PoolMechenic : Int{
    case sortTiming = 1
    case sortData = 2
    case sortPoolAlgorithm = 3
}


