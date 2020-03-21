//
//  NetworkReceiver.swift
//  PegaXPool
//
//  Created by thailinh on 1/23/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
import Alamofire
protocol NetworkReceiverProtocol {
    func updateNetworkStatus(isConnect : Bool, isWifi : Bool)
}
class NetworkReceiver {
    //shared instance
    static let shared = NetworkReceiver()
    var iNetworkReceiver : NetworkReceiverProtocol?
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")
    func startNetworkReachabilityObserver() {
        reachabilityManager?.listener = { status in
            switch status {
            case .notReachable:
                if PoolConstants.Debug.debugLog{print(" Network Disconnect ")}
                self.iNetworkReceiver?.updateNetworkStatus(isConnect: false, isWifi: false)
            case .unknown :
                if PoolConstants.Debug.debugLog{print(" unknow Network Disconnect")}
                self.iNetworkReceiver?.updateNetworkStatus(isConnect: false, isWifi: false)
            case .reachable(.ethernetOrWiFi):
                if PoolConstants.Debug.debugLog{print(" Mang wifi ")}
                self.iNetworkReceiver?.updateNetworkStatus(isConnect: true, isWifi: true)
            case .reachable(.wwan):
                if PoolConstants.Debug.debugLog{print(" Mang 3G ")}
                self.iNetworkReceiver?.updateNetworkStatus(isConnect: true, isWifi: false)
            }
        }
        // start listening
        reachabilityManager?.startListening()
    }
    func bandWidthCheck()  {
        let sample = URL(string: "http://nspapi.aiservice.vn/")
        let request = URLRequest(url: sample!)
        let session = URLSession.shared
        let startTime = Date()
        let task =  session.dataTask(with: request) { (data, resp, error) in
            guard error == nil && data != nil else{
                if PoolConstants.Debug.debugTask{print("connection error or data is nill")}
                return
            }
            guard resp != nil else{
                if PoolConstants.Debug.debugTask{print("Connection response is nill")}
                return
            }
            //byte
            let size  = CGFloat( (resp?.expectedContentLength)!) / 1048576.0
            print(size)
            
            let time = CGFloat( Date().timeIntervalSince(startTime))*1000
            if PoolConstants.Debug.debugTask{print("elapsed: \(time) ms")}
            if PoolConstants.Debug.debugTask{print("Speed: \(size/time) Mb/s")}
        }
        task.resume()
    }
}
