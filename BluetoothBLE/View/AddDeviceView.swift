//
//  ContentView.swift
//  BluetoothBLE
//
//  Created by Vivek Singh on 21/03/24.
//
import Foundation
import SwiftUI
import CoreBluetooth

// BluetoothManager: Updated to include disconnecting logic
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // State variable to store discovered Bluetooth devices
    @Published var devices: [CBPeripheral] = []
    
    // Instance of CBCentralManager to manage Bluetooth operations
    private var centralManager: CBCentralManager!
    
    // The currently connecting peripheral
    @Published var connectingPeripheral: CBPeripheral?
    
    // Constructor to initialize the central manager
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Function to initiate scanning for nearby Bluetooth devices
    func scanForDevices() {
        // Check if the central manager is powered on before scanning
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    // CBCentralManagerDelegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle Bluetooth state changes here
        if central.state == .poweredOn {
            scanForDevices()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Add discovered peripheral to the devices array
        if !devices.contains(peripheral) {
            devices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Successfully connected to the peripheral
        connectingPeripheral = nil
        // Now you can discover services and characteristics
        peripheral.delegate = self // Set delegate to handle service/characteristic discovery
        peripheral.discoverServices(nil) // Discover all services
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        // Failed to connect to the peripheral
        connectingPeripheral = nil // Reset the connecting peripheral
        print("Failed to connect to peripheral: \(error?.localizedDescription ?? "Unknown error")")
    }
    
    // Disconnect from a peripheral
    func disconnect(from peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // Connect to or disconnect from a peripheral based on its current state
    func toggleConnection(to peripheral: CBPeripheral) {
        if peripheral.state == .connected {
            disconnect(from: peripheral)
        } else {
            connect(to: peripheral)
        }
    }
    
    // Connect to a peripheral
    private func connect(to peripheral: CBPeripheral) {
        connectingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // Handle service discovery
        if let services = peripheral.services {
            for service in services {
                // Discover characteristics for each service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Handle characteristic discovery
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                // Process discovered characteristics
                print("Discovered characteristic: \(characteristic)")
                
                // Example: Read the value of the characteristic
                peripheral.readValue(for: characteristic)
                
                // Example: Write data to the characteristic
                let data = "Hello".data(using: .utf8)
                peripheral.writeValue(data!, for: characteristic, type: .withResponse)
                
                // Example: Subscribe to notifications for the characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic value: \(error.localizedDescription)")
            return
        }
        
        // Check if the characteristic value is available
        if let value = characteristic.value {
            // Process the characteristic value here
            print("Characteristic value: \(value)")
        } else {
            print("Characteristic value is nil.")
        }
    }


    // Method to determine if a device is currently being connected
    func isConnecting(to peripheral: CBPeripheral) -> Bool {
        return connectingPeripheral == peripheral
    }
}

// DeviceRow: Updated to handle connection and disconnection
struct DeviceRow: View {
    let device: CBPeripheral
    let isConnecting: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            if let deviceName = device.name {
                Text(deviceName)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isConnecting {
                    ProgressView()
                } else {
                    if device.state == .connected {
                        Text("Connected")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.clear)
                    }
                }
            }
        }
        .padding()
        .onTapGesture {
            onTap()
        }
    }
}

// ContentView: SwiftUI view to display discovered Bluetooth devices
struct AddDeviceView: View {
    // Instance of BluetoothManager to handle Bluetooth operations
    @StateObject var bluetoothManager = BluetoothManager()
    @State private var discoveryMessage = ""
    
    var body: some View {
        ZStack {
            Color(red: 0.67, green: 0.75, blue: 0.58).opacity(0.4)
                .ignoresSafeArea()
            
            VStack {
                List {
                    ForEach(bluetoothManager.devices, id: \.self) { device in
                        if device.name != nil {
                            DeviceRow(device: device, isConnecting: bluetoothManager.isConnecting(to: device)) {
                                bluetoothManager.toggleConnection(to: device)
                            }
                        }
                    }
                }
                .padding()
                
                Button(action: {
                    bluetoothManager.scanForDevices()
                }) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(Color(red: 0.51, green: 0.59, blue: 0.42).opacity(0.6))
                        .background(
                            Circle()
                                .fill(.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 3, y: 3)
                                .shadow(color: Color.white.opacity(0.7), radius: 5, x: -6, y: -6)
                        )
                        .padding(.top, 80)
                }
                .padding()
                
                Text(discoveryMessage)
                    .foregroundColor(.white)
                    .padding()
                
            }
        }
        .onReceive(bluetoothManager.$devices) { _ in
            // Check if any device has a name
            if !bluetoothManager.devices.isEmpty && bluetoothManager.devices.contains(where: { $0.name != nil }) {
                // Count only the devices with names
                let deviceCount = bluetoothManager.devices.filter { $0.name != nil }.count
                discoveryMessage = "\(deviceCount) device(s) found."
            } else {
                discoveryMessage = "No devices found."
            }
        }
    }
}

#Preview {
    AddDeviceView()
}
