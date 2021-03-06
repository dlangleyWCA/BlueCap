//
//  Errors.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public enum CharacteristicError : Int {
    case ReadTimeout        = 1
    case WriteTimeout       = 2
    case NotSerializable    = 3
    case ReadNotSupported   = 4
    case WriteNotSupported  = 5
}


public enum ConnectoratorError : Int {
    case Timeout            = 10
    case Disconnect         = 11
    case ForceDisconnect    = 12
    case Failed             = 13
    case GiveUp             = 14
}

public enum PeripheralError : Int {
    case DiscoveryTimeout   = 20
    case Disconnected       = 21
}

public enum PeripheralManagerError : Int {
    case IsAdvertising      = 40
}

public struct BCError {
    public static let domain = "BlueCap"
    
    internal static let characteristicReadTimeout = NSError(domain:domain, code:CharacteristicError.ReadTimeout.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic read timeout"])
    internal static let characteristicWriteTimeout = NSError(domain:domain, code:CharacteristicError.WriteTimeout.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic write timeout"])
    internal static let characteristicNotSerilaizable = NSError(domain:domain, code:CharacteristicError.NotSerializable.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic not serializable"])
    internal static let characteristicReadNotSupported = NSError(domain:domain, code:CharacteristicError.ReadNotSupported.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic read not supported"])
    internal static let characteristicWriteNotSupported = NSError(domain:domain, code:CharacteristicError.WriteNotSupported.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic write not supported"])

    internal static let connectoratorTimeout = NSError(domain:domain, code:ConnectoratorError.Timeout.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator timeout"])
    internal static let connectoratorDisconnect = NSError(domain:domain, code:ConnectoratorError.Disconnect.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator disconnect"])
    internal static let connectoratorForcedDisconnect = NSError(domain:domain, code:ConnectoratorError.ForceDisconnect.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator forced disconnected"])
    internal static let connectoratorFailed = NSError(domain:domain, code:ConnectoratorError.Failed.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator connection failed"])
    internal static let connectoratorGiveUp = NSError(domain:domain, code:ConnectoratorError.GiveUp.rawValue, userInfo:[NSLocalizedDescriptionKey:"Connectorator giving up"])

    internal static let peripheralDisconnected = NSError(domain:domain, code:PeripheralError.DiscoveryTimeout.rawValue, userInfo:[NSLocalizedDescriptionKey:"Peripheral disconnected timeout"])
    internal static let peripheralDiscoveryTimeout = NSError(domain:domain, code:PeripheralError.Disconnected.rawValue, userInfo:[NSLocalizedDescriptionKey:"Peripheral discovery Timeout"])
        
    internal static let peripheralManagerIsAdvertising = NSError(domain:domain, code:PeripheralManagerError.IsAdvertising.rawValue, userInfo:[NSLocalizedDescriptionKey:"Peripheral Manager is Advertising"])

}

