//
//  RemoteTaskProtocol.swift
//  PegaXPool
//
//  Created by thailinh on 1/5/19.
//  Copyright © 2019 thailinh. All rights reserved.
//

import Foundation
protocol RemoteTaskProtocol {
    func prepareRequest()
    func successRequest(response : [String : Any])
    func failureRequest(error : Error)
    func cancelRequest()
}
