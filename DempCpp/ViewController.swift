//
//  ViewController.swift
//  DempCpp
//
//  Created by Suraj on 19/05/22.
//

/*
 Peripheral name Found!= iTAG
 try to discover all service
 2022-06-01 17:00:03.436405+0530 DempCpp[41675:2500497] [CoreBluetooth] API MISUSE: Discovering services for peripheral <CBPeripheral: 0x281a910e0, identifier = C0AF6300-A049-7777-69B1-575E6307702E, name = iTAG            , mtu = 23, state = connected> while delegate is either nil or does not implement peripheral:didDiscoverServices:
 service = <CBService: 0x283ed0900, isPrimary = YES, UUID = Battery>
 service = <CBService: 0x283ec0900, isPrimary = YES, UUID = 1802>
 service = <CBService: 0x283ec08c0, isPrimary = YES, UUID = FFE0>
 characteristic = <CBCharacteristic: 0x280f98840, UUID = Battery Level, properties = 0x12, value = (null), notifying = NO>
 characteristic = <CBCharacteristic: 0x280f98960, UUID = 2A06, properties = 0x1C, value = (null), notifying = NO>
 characteristic = <CBCharacteristic: 0x280f9eb20, UUID = FFE1, properties = 0x12, value = (null), notifying = NO>
 */

import UIKit
import CoreBluetooth

struct BLE: Hashable {
    var id: String
    var name:String
}
extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
class ViewController: UIViewController {
    
    @IBOutlet weak var SpinnerView: UIView! {
      didSet {
          SpinnerView.layer.cornerRadius = 6
      }
    }
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var myCentralManager: CBCentralManager?
    var myPeripheral: CBPeripheral?
    var alertLevel:CBUUID?
    var batteryLavel:CBUUID?
    var rndLevel: CBUUID?
    var BleFoundList: [BLE] = []
    var previousCount = 0
    @IBOutlet var BleLister: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.stopAnimating()
        SpinnerView.isHidden = true
        alertLevel = CBUUID(string: "0x2A06")//
        rndLevel = CBUUID(string: "0x180F")
        batteryLavel = CBUUID(string: "0x2A19")
        print("The print = \(HelloWorldWrapper().sayHello())")
        self.BleLister.register(UITableViewCell.self, forCellReuseIdentifier: "BleCellID")
    }
    
    @IBAction func startSound(_ sender: UIButton) {
        if let prf = myPeripheral{
            myCentralManager?.cancelPeripheralConnection(prf)
        }
    }
    
    @IBAction func stopSound(_ sender: UIButton) {
        if let prf = myPeripheral{
            myCentralManager?.connect(prf, options: nil)
        }
    }
    
    //MARK: start Scan --
    @IBAction func startScan(_ sender: UIButton) {
        self.BleFoundList.removeAll()
        self.previousCount = 0
        activityIndicator.startAnimating()
        SpinnerView.isHidden = false
        myCentralManager = CBCentralManager(delegate: self, queue: nil)
    }
    //MARK: stop Scan --
    @IBAction func stopScan(_ sender: UIButton) {
        self.myCentralManager?.stopScan()
    }
    
}

extension ViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.BleFoundList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BleCellID", for: indexPath)
        let name = self.BleFoundList[indexPath.row].name
        let identifier = self.BleFoundList[indexPath.row].id
        cell.textLabel?.text = name
        cell.detailTextLabel?.text = identifier
        return cell
    }
    
    
}
extension ViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45.0
    }
}

extension ViewController : CBPeripheralDelegate{
    
  
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("service = \(service)")
          peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
          print("characterristics = \(characteristic)")
          if characteristic.properties.contains(.read) {
            print("\(characteristic.uuid): properties contains .read")
            peripheral.readValue(for: characteristic)
          }
          if characteristic.properties.contains(.notify) {
            print("\(characteristic.uuid): properties contains .notify")
            peripheral.setNotifyValue(true, for: characteristic)
          }
        }
    }
    
}

extension ViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
           central.scanForPeripherals(withServices: nil, options: nil)
           print("Scanning...")
        }else if central.state == .poweredOff{
            print("Turn on your blooth ...")
        }else if central.state == .resetting{
            print("Your Blooth is resetting ...")
        }else if central.state == .unauthorized{
            print("Unauthrised access ...")
        }else if central.state == .unknown{
            print("Unauthrised access ...")
        }else if central.state == .unsupported{
            print("Unauthrised access ...")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //try to discover all service
        print("connected!! and try to discover all service")
        peripheral.discoverServices(nil)
       
    }
    
    
    
}

extension ViewController: CBPeripheralManagerDelegate{
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.name != nil else {return}
        print("Peripheral name Found!= \(peripheral.name)")
        let newBleDevice  = BLE(id: peripheral.identifier.uuidString, name: peripheral.name!)
        self.BleFoundList.append(newBleDevice)
        if previousCount != self.BleFoundList.unique().count{
            self.BleLister.delegate = self
            self.BleLister.dataSource = self
            self.BleLister.reloadData()
            previousCount = self.BleFoundList.unique().count
            activityIndicator.stopAnimating()
            SpinnerView.isHidden = true
        }
        for bles in self.BleFoundList.unique(){
            print("Peripheral in array!= \(bles.id) and \(bles.name)")
        }
        self.myPeripheral = peripheral
        self.myPeripheral?.delegate = self
        //this is to make connection with BLE device
        //myCentralManager?.connect(peripheral, options: nil)
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        //
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let characteristicData = characteristic.value,
              let byte = characteristicData.first {
                 // print("DID = \(byte)")
                 // print("value = \(characteristicData as NSData)")
              }
       
    }
    
}
