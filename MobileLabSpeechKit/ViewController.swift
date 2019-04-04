//
//  ViewController.swift
//  MobileLabSpeechKit
//
//  Created by Nien Lam on 12/31/17.
//  Copyright © 2017 Mobile Lab. All rights reserved.
//
//  Description:
//  View controller for speech recognition demo.

import UIKit
import Speech
import SwiftSiriWaveformView

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioRecorderDelegate {

    var timer: Timer?
    var change: CGFloat = 0.01

    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var recorder: AVAudioRecorder!

    
    // View for audio wave form feedback.
    @IBOutlet weak var audioWaveView: SwiftSiriWaveformView!
    @IBOutlet weak var detectedTextLabel: UILabel!
    
    var mostRecentlyProcessedSegmentDuration: TimeInterval = 0
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        self.requestSpeechAuthorization()
        
        self.audioWaveView.density = 1.0
        self.audioWaveView.waveColor = UIColor.green
        //timer = Timer.scheduledTimer(timeInterval: 0.009, target: self, selector: #selector(refreshAudioView(_:)), userInfo: nil, repeats: true)

    
        if self.recorder != nil {
            //if here it means that the record button was double clicked
            return
        }

        
        let url: NSURL = NSURL(fileURLWithPath: "/dev/null")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            self.recorder = try AVAudioRecorder(url: url as URL, settings: settings )
            self.recorder.delegate = self
            self.recorder.isMeteringEnabled = true
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.record)))
            
            self.recorder.record()
            
            timer = Timer.scheduledTimer(timeInterval: 0.009, target: self, selector: #selector(refreshAudioView(_:)), userInfo: nil, repeats: true)
            
            print("RECORDING!!!")
            
        } catch {
            //failed to record!
        }
        
    }

    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    print("authorized")
                    self.recordAndRecognizeSpeech()

                //                    self.startButton.isEnabled = true
                case .denied:
                    print("denied")
//                    self.startButton.isEnabled = false
//                    self.detectedTextLabel.text = "User denied access to speech recognition"
                case .restricted:
                    print("restricted")
//                    self.startButton.isEnabled = false
//                    self.detectedTextLabel.text = "Speech recognition restricted on this device"
                case .notDetermined:
                    print("notDetermined")
//                    self.startButton.isEnabled = false
//                    self.detectedTextLabel.text = "Speech recognition not yet authorized"
                }
            }
        }
    }
    
    
    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode

        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                self.detectedTextLabel.text = bestString
                
                print(bestString)
                
                if let lastSegment = result.bestTranscription.segments.last,
                    lastSegment.duration > self.mostRecentlyProcessedSegmentDuration {
                    self.mostRecentlyProcessedSegmentDuration = lastSegment.duration
                    
//                    self.detectedTextLabel.text = lastSegment.substring
                }
                
                
                /*
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = bestString.substring(from: indexTo)
                }*/

                
                //              self.checkForColorsSaid(resultString: lastString)
            } else if let error = error {
                self.sendAlert(message: "There has been a speech recognition error.")
                print(error)
            }

        })
    }
    
    func sendAlert(message: String) {
        let alert = UIAlertController(title: "Speech Recognizer Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc internal func refreshAudioView(_: Timer) {
//        if self.recorder == nil {
//            self.endTimer()
//
//            return
//        }
        
        //        if self.audioView.amplitude <= self.audioView.idleAmplitude || self.audioView.amplitude > 1.0 {
        //            self.change *= -1.0
        //        }
        
        // Simply set the amplitude to whatever you need and the view will update itself.
        self.audioWaveView.amplitude = 0.5

        recorder.updateMeters()
  //      print("Average Power: \(CGFloat(self.recorder.averagePower(forChannel: 0)))")
        
        let normalizedValue:CGFloat = pow(10, CGFloat(recorder.averagePower(forChannel: 0))/20)
        self.audioWaveView.amplitude = normalizedValue
//        print(normalizedValue)
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
