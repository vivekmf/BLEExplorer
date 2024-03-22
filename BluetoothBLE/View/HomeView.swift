//
//  HomeView.swift
//  BluetoothBLE
//
//  Created by Vivek Singh on 21/03/24.
//

import Foundation
import SwiftUI

struct HomeView: View {
    @State private var isAddDeviceViewActive = false
    
    var body: some View {
        GeometryReader { geometry in
            Image("headphones_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.6)
                .overlay(
                    VStack {
                        Image("bluetooth_white")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color(red: 0.51, green: 0.59, blue: 0.42).opacity(1.5))
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 6, y: 6)
                                    .shadow(color: Color.white.opacity(0.7), radius: 5, x: -5, y: -5)
                            )
                            .padding(.top, 80)
                        
                        Spacer()
                        
                        Button(action: {
                            isAddDeviceViewActive = true
                        }) {
                            Text("ADD DEVICE")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 180)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(red: 0.51, green: 0.59, blue: 0.42).opacity(0.6))
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 5, y: 5)
                                        .shadow(color: Color.white.opacity(0.6), radius: 5, x: -4, y: -4)
                                )
                        }
                        .padding(80)
                        .padding(.top)
                    }
                )
                .sheet(isPresented: $isAddDeviceViewActive) {
                    AddDeviceView()
                }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    HomeView()
}
