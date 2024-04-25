//
//  ColorChannelView.swift
//  PeekaView
//
//  Created by Devon Quispe on 4/18/24.
//

import SwiftUI

struct ColorChannelView: View {
    @Binding var value: Int // Use a binding to allow two-way data flow
    let captionName: String
    let onValueChanged: (Int) -> Void

    var body: some View {
        Stepper(value: $value) {
            Text("\(captionName): \(value)%")
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .onChange(of: value) { newValue in
            onValueChanged(newValue)
        }
//        VStack {
//            HStack {
//                Text("\(value)%")
//                    .font(.caption)
//                    .fontWeight(.bold)
//                    .foregroundColor(.white)
//                .padding(.bottom, 2)
//
//                Text(captionName)
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
//
//            Stepper(value: $value, in: 0...100) {
//            }
//            .accentColor(.white)
//            .background(.blue)
//            .cornerRadius(8)
//            .labelsHidden()
//        }
//        .padding(10)
//        .background(Color.black)
//        .edgesIgnoringSafeArea(.all)
//        .onChange(of: value) { newValue in
//            onValueChanged(newValue)
//        }
    }
}
