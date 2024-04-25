//
//  CameraViewController.swift
//  GStreamerSwiftUIDemo
//


import Foundation
import UIKit
import Dispatch
import SwiftUI


@objc class CameraViewController: NSObject, GStreamerBackendProtocol, ObservableObject{
    var gstBackend:GStreamerBackend?
    var camUIView:UIView
    var cameraView:CameraView
    @Published var gStreamerInitializationStatus:Bool = false
    @Published var messageFromGstBackend:String?
//    Save Images
    @Published var imagesFromGstBackend: [UIImage] = []
//    Change Color Balance of Livestream
    @Published var brightness: Int = 50
    @Published var saturation: Int = 50
    @Published var contrast: Int = 50
    @Published var hue: Int = 50

    init(camUIView: UIView) {
        self.camUIView = camUIView
        self.cameraView = CameraView(placeholderView: camUIView)
    }
    
    func initBackend(){
        self.gstBackend = GStreamerBackend(self, videoView: self.camUIView)
        let queue = DispatchQueue(label: "run_app_q")
        queue.async{
            self.gstBackend?.run_app_pipeline_threaded()
        }
        return
    }
    
    func play(){
        if gstBackend == nil{
            self.initBackend()
        }
        self.gstBackend!.play()
    }
    
    func pause(){
        self.gstBackend!.pause()
    }
    
    func captureSnapshot() {
        if let capturedImage = self.cameraView.captureView() {
            self.imagesFromGstBackend.append(capturedImage)
        }
    }
    
    func changeColorBalance(channel: String, adjustmentMultiplier: Int) {
        self.gstBackend?.updateColorChannel(withName: channel, adjustmentMultiplier: adjustmentMultiplier)
    }

    func updateBrightness(to value: Int) {
        self.brightness = value
        changeColorBalance(channel: "BRIGHTNESS", adjustmentMultiplier: value)
    }

    func updateContrast(to value: Int) {
        self.contrast = value
        changeColorBalance(channel: "CONTRAST", adjustmentMultiplier: value)
    }

    func updateHue(to value: Int) {
        self.hue = value
        changeColorBalance(channel: "HUE", adjustmentMultiplier: value)
    }

    func updateSaturation(to value: Int) {
        self.saturation = value
        changeColorBalance(channel: "SATURATION", adjustmentMultiplier: value)
    }
    
    func indexUp() {
            print("Index increased")
        }
        
    func indexDown() {
        print("Index decreased")
    }
    
    @objc func updateColorChannelValue(channel: String, value: Int) {
        switch channel {
            case "BRIGHTNESS":
                self.brightness = value
            case "CONTRAST":
                self.contrast = value
            case "SATURATION":
                self.saturation = value
            case "HUE":
                self.hue = value
            default:
                print("Unknown color channel")
        }
    }
    
    @objc func gStreamerInitialized() {
        self.gStreamerInitializationStatus = true
    }
    
    @objc func gstreamerSetUIMessageWithMessage(message: String) {
        self.messageFromGstBackend = message
    }
    
    
}
