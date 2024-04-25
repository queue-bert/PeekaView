//
//  ContentView.swift
//  GStreamerSwiftUIDemo
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var camViewController: CameraViewController
    @State private var selectedImage: UIImage?
    @State private var isShowingZoomableView = false
    var networkListener: NetworkListener?
    
    init() {
        self.camViewController = CameraViewController(camUIView: UIView())
        self.networkListener = NetworkListener(cameraViewController: camViewController)
    }
    
    func playStream() {
        self.camViewController.play()
    }
    
    func pauseStream() {
        self.camViewController.pause()
    }
    
    func captureSnapshot() {
        self.camViewController.captureSnapshot()
    }
    
    func startListening() {
        networkListener?.start()
    }
    
    var body: some View {
        VStack {
            
            HStack {
                Text("PeekaView")
                    .font(.largeTitle)
                    .padding()
                    .foregroundColor(.white)
                Spacer()
            }
            Divider()
                .overlay(.white)
            CameraContainerView(camContainerViewController: self.camViewController)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
            Divider()
                .overlay(.white)
            
            HStack(spacing: 10) {
                Button("Play") {
                    playStream()
                }
                Button("Pause") {
                    pauseStream()
                }
                Button("Capture") {
                    captureSnapshot()
                }
                
            }
            .padding()
            .background(Color.black)
            .cornerRadius(10)
            .foregroundColor(.white)
            
            ScrollView {
                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(camViewController.imagesFromGstBackend, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                    }
                }
                .padding()
            }
            
            Divider().overlay(.white)
            
            Spacer()
            VStack {
                ColorChannelView(
                    value: $camViewController.brightness,
                    captionName: "Brightness",
                    onValueChanged: camViewController.updateBrightness
                )
                
                ColorChannelView(
                    value: $camViewController.contrast,
                    captionName: "Contrast",
                    onValueChanged: camViewController.updateContrast
                )
                
                ColorChannelView(
                    value: $camViewController.hue,
                    captionName: "Hue",
                    onValueChanged: camViewController.updateHue
                )
                
                ColorChannelView(
                    value: $camViewController.saturation,
                    captionName: "Saturation",
                    onValueChanged: camViewController.updateSaturation
                )
            }
//            HStack {
//                ColorChannelView(
//                    value: $camViewController.brightness,
//                    captionName: "Brightness",
//                    onValueChanged: camViewController.updateBrightness
//                )
//
//                ColorChannelView(
//                    value: $camViewController.contrast,
//                    captionName: "Contrast",
//                    onValueChanged: camViewController.updateContrast
//                )
//            }
//            HStack {
//                ColorChannelView(
//                    value: $camViewController.hue,
//                    captionName: "Hue",
//                    onValueChanged: camViewController.updateHue
//                )
//
//                ColorChannelView(
//                    value: $camViewController.saturation,
//                    captionName: "Saturation",
//                    onValueChanged: camViewController.updateSaturation
//                )
//            }
            

            


        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

struct CameraContainerView: View {
    @ObservedObject var camContainerViewController: CameraViewController
    
    var body: some View {
        Group {
            if camContainerViewController.gstBackend != nil {
                camContainerViewController.cameraView
            } else {
                let _ = camContainerViewController.initBackend()
                Text("Initializing GStreamer, please wait...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.white)
            }
        }
    }
}
