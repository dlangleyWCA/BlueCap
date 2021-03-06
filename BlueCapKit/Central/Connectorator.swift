//
//  Connector.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class Connectorator {

    private var timeoutCount    = 0
    private var disconnectCount = 0
    
    private let promise : StreamPromise<Peripheral>

    public var timeoutRetries           = -1
    public var disconnectRetries        = -1
    public var connectionTimeout        = 10.0
    public var characteristicTimeout    = 10.0

    public init () {
        self.promise = StreamPromise<Peripheral>()
    }

    public init (capacity:Int) {
        self.promise = StreamPromise<Peripheral>(capacity:capacity)
    }
    
    convenience public init(initializer:((connectorator:Connectorator) -> Void)?) {
        self.init()
        if let initializer = initializer {
            initializer(connectorator:self)
        }
    }

    convenience public init(capacity:Int, initializer:((connectorator:Connectorator) -> Void)?) {
        self.init(capacity:capacity)
        if let initializer = initializer {
            initializer(connectorator:self)
        }
    }

    public func onConnect() -> FutureStream<Peripheral> {
        return self.promise.future
    }
    
    internal func didTimeout() {
        Logger.debug("Connectorator#didTimeout")
        if self.timeoutRetries > 0 {
            if self.timeoutCount < self.timeoutRetries {
                self.callDidTimeout()
                ++self.timeoutCount
            } else {
                self.callDidGiveUp()
                self.timeoutCount = 0
            }
        } else {
            self.callDidTimeout()
        }
    }

    internal func didDisconnect() {
        Logger.debug("Connectorator#didDisconnect")
        if self.disconnectRetries > 0 {
            if self.disconnectCount < self.disconnectRetries {
                ++self.disconnectCount
                self.callDidDisconnect()
            } else {
                self.disconnectCount = 0
                self.callDidGiveUp()
            }
        } else {
            self.callDidDisconnect()
        }
    }
    
    internal func didForceDisconnect() {
        Logger.debug("Connectorator#didForceDisconnect")
        self.promise.failure(BCError.connectoratorForcedDisconnect)
    }
    
    internal func didConnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didConnect")
        self.promise.success(peripheral)
    }
    
    internal func didFailConnect(error:NSError?) {
        Logger.debug("Connectorator#didFailConnect")
        if let error = error {
            self.promise.failure(error)
        } else {
            self.promise.failure(BCError.connectoratorFailed)
        }
    }
    
    internal func callDidTimeout() {
        self.promise.failure(BCError.connectoratorDisconnect)
    }
    
    internal func callDidDisconnect() {
        self.promise.failure(BCError.connectoratorTimeout)
    }
    
    internal func callDidGiveUp() {
        self.promise.failure(BCError.connectoratorGiveUp)
    }
}