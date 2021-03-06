//
//  PeripheralsViewController.swift
//  BlueCapUI
//
//  Created by Troy Stribling on 6/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

class PeripheralsViewController : UITableViewController {
    
    var stopScanBarButtonItem   : UIBarButtonItem!
    var startScanBarButtonItem  : UIBarButtonItem!
    
    struct MainStoryboard {
        static let peripheralCell   = "PeripheralCell"
        static let peripheralSegue  = "Peripheral"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
        self.stopScanBarButtonItem = UIBarButtonItem(barButtonSystemItem:.Stop, target:self, action:"toggleScan:")
        self.startScanBarButtonItem = UIBarButtonItem(title:"Scan", style:UIBarButtonItemStyle.Bordered, target:self, action:"toggleScan:")
        self.styleUIBarButton(self.startScanBarButtonItem)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.setScanButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
        self.setScanButton()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralSegue {
            if let selectedIndex = self.tableView.indexPathForCell(sender as UITableViewCell) {
                let viewController = segue.destinationViewController as PeripheralViewController
                viewController.peripheral = CentralManager.sharedInstance.peripherals[selectedIndex.row]
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        var perform = false
        if let identifier = identifier {
            if identifier == MainStoryboard.peripheralSegue {
                if let selectedIndex = self.tableView.indexPathForCell(sender as UITableViewCell) {
                    let peripheral = CentralManager.sharedInstance.peripherals[selectedIndex.row]
                    perform = (peripheral.state == .Connected)
                }
            }
        }
        return perform
    }
    
    // actions
    func toggleScan(sender:AnyObject) {
        if BeaconManager.sharedInstance.isMonitoring == false {
            let central = CentralManager.sharedInstance
            if (central.isScanning) {
                if  ConfigStore.getScanTimeoutEnabled() {
                    TimedScannerator.sharedInstance.stopScanning()
                } else {
                    central.stopScanning()
                }
                central.disconnectAllPeripherals()
                central.removeAllPeripherals()
                self.setScanButton()
                self.updateWhenActive()
            } else {
                central.disconnectAllPeripherals()
                central.removeAllPeripherals()
                self.powerOn()
            }
        } else {
            self.presentViewController(UIAlertController.alertWithMessage("iBeacon monitoring is active. Cannot scan and monitor iBeacons simutaneously. Stop iBeacon monitoring to start scan"), animated:true, completion:nil)
        }
    }
    
    // utils
    func didResignActive() {
        Logger.debug("PeripheralsViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralsViewController#didBecomeActive")
        self.tableView.reloadData()
        self.setScanButton()
    }
    
    func setScanButton() {
        if CentralManager.sharedInstance.isScanning || TimedScannerator.sharedInstance.isScanning {
            self.navigationItem.setLeftBarButtonItem(self.stopScanBarButtonItem, animated:false)
        } else {
            self.navigationItem.setLeftBarButtonItem(self.startScanBarButtonItem, animated:false)
        }
    }
    
    func powerOn() {
        CentralManager.sharedInstance.powerOn().onSuccess {
            Logger.debug("PeripheralsViewController#powerOn")
            self.startScan()
            self.setScanButton()
        }
    }
    
    func connect(peripheral:Peripheral) {
        let connectorator = Connectorator(capacity:10) {config in
            config.timeoutRetries = ConfigStore.getMaximumReconnections()
            config.connectionTimeout = Double(ConfigStore.getPeripheralConnectionTimeout())
            config.characteristicTimeout = Double(ConfigStore.getCharacteristicReadWriteTimeout())
        }
        let future = connectorator.onConnect()
        future.onSuccess {_ in
            Logger.debug("Connectorator#connect")
            Notify.withMessage("Connected peripheral: '\(peripheral.name)'")
            self.updateWhenActive()
        }
        future.onFailure {error in
            if error.domain == BCError.domain {
                if let connectoratorError = ConnectoratorError(rawValue:error.code) {
                    switch connectoratorError {
                    case .Timeout:
                        Logger.debug("Connectorator#Timeout: '\(peripheral.name)'")
                        NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                        peripheral.reconnect()
                        self.updateWhenActive()
                    case .Disconnect:
                        Logger.debug("Connectorator#Disconnect")
                        Notify.withMessage("Disconnected peripheral: '\(peripheral.name)'")
                        peripheral.reconnect()
                        NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                        self.updateWhenActive()
                    case .ForceDisconnect:
                        Logger.debug("Connectorator#ForcedDisconnect")
                        Notify.withMessage("Force disconnection of: '\(peripheral.name)'")
                        NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.peripheralDisconnected, object:peripheral)
                        self.updateWhenActive()
                    case .Failed:
                        Logger.debug("Connectorator#Failed")
                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                    case .GiveUp:
                        Logger.debug("Connectorator#GiveUp: '\(peripheral.name)'")
                        peripheral.terminate()
                        self.updateWhenActive()
                    }
                } else {
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                }
            } else {
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
        }
        peripheral.connect(connectorator:connectorator)
    }
    
    func startScan() {
        let scanMode = ConfigStore.getScanMode()
        let afterPeripheralDiscovered = {(discovery:PeripheralDiscovery) -> Void in
            Notify.withMessage("Discovered peripheral '\(discovery.peripheral.name)'")
            self.connect(discovery.peripheral)
            self.updateWhenActive()
        }
        let afterTimeout = {(error:NSError) -> Void in
            if error.domain == BCError.domain && error.code == PeripheralError.DiscoveryTimeout.rawValue {
                Logger.debug("Scannerator#timeoutScan: timing out")
                TimedScannerator.sharedInstance.stopScanning()
                self.setScanButton()
            }
        }
        // Promiscuous Scan Enabled
        var future : FutureStream<PeripheralDiscovery>
        switch scanMode {
        case "Promiscuous" :
            // Promiscuous Scan with Timeout Enabled
            if ConfigStore.getScanTimeoutEnabled() {
                future = TimedScannerator.sharedInstance.startScanning(Double(ConfigStore.getScanTimeout()), capacity:10)
                
            } else {
                future = CentralManager.sharedInstance.startScanning(capacity:10)
            }
            future.onSuccess(afterPeripheralDiscovered)
            future.onFailure(afterTimeout)
        case "Service" :
            let scannedServices = ConfigStore.getScannedServiceUUIDs()
            if scannedServices.isEmpty {
                self.presentViewController(UIAlertController.alertWithMessage("No scan services configured"), animated:true, completion:nil)
            } else {
                // Service Scan with Timeout Enabled
                if ConfigStore.getScanTimeoutEnabled() {
                    future = TimedScannerator.sharedInstance.startScanningForServiceUUIDs(Double(ConfigStore.getScanTimeout()), uuids:scannedServices, capacity:10)
                } else {
                    future = CentralManager.sharedInstance.startScanningForServiceUUIDs(scannedServices, capacity:10)
                }
                future.onSuccess(afterPeripheralDiscovered)
                future.onFailure(afterTimeout)
            }
        default:
            Logger.debug("Scan Mode :'\(scanMode)' invalid")
        }
    }
        
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return CentralManager.sharedInstance.peripherals.count
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralCell, forIndexPath: indexPath) as PeripheralCell
        let peripheral = CentralManager.sharedInstance.peripherals[indexPath.row]
        cell.nameLabel.text = peripheral.name
        cell.accessoryType = .None
        if peripheral.state == .Connected {
            cell.nameLabel.textColor = UIColor.blackColor()
            cell.rssiLabel.text = "\(peripheral.rssi)"
            cell.stateLabel.text = "Connected"
            cell.stateLabel.textColor = UIColor(red:0.1, green:0.7, blue:0.1, alpha:0.5)
        } else {
            cell.nameLabel.textColor = UIColor.lightGrayColor()
            cell.rssiLabel.text = "NA"
            cell.stateLabel.text = "Disconnected"
            cell.stateLabel.textColor = UIColor.lightGrayColor()
        }
        return cell
    }
    

}