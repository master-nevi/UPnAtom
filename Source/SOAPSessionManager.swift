//
//  SOAPSessionManager.swift
//  ControlPointDemo
//
//  Created by David Robles on 1/21/15.
//  Copyright (c) 2015 David Robles. All rights reserved.
//

import Foundation

class SOAPSessionManager: AFHTTPSessionManager {
    override init!(baseURL url: NSURL!) {
        super.init(baseURL: url)
    }
    
    override init!(baseURL url: NSURL!, sessionConfiguration configuration: NSURLSessionConfiguration!) {
        super.init(baseURL: url, sessionConfiguration: configuration)
        
        self.requestSerializer = SOAPRequestSerializer() as AFHTTPRequestSerializer
        self.responseSerializer = SOAPResponseSerializer()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
