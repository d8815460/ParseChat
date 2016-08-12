//
//  ToneViewController.swift
//  app
//
//  Created by 駿逸 陳 on 2016/8/12.
//  Copyright © 2016年 KZ. All rights reserved.
//

import UIKit
import ToneAnalyzerV3

//@objc protocol SpeakerToneDelegate {
////    func SpeakTone(tone:ToneScore?)
//    optional func TellChatView(tone:AnyObject?)
//}

class ToneViewController: UIViewController {

//    let chatView:ChatView! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func toneAnalayiz(text:String, chatView:ChatView) {
        // Do any additional setup after loading the view.
        
        let toneAnalyzer: ToneAnalyzer
        
        // identify credentials file
        let bundle = NSBundle(forClass: self.dynamicType)
        guard let credentialsURL = bundle.pathForResource("Credentials", ofType: "plist") else {
            failure("Loading Credentials", message: "Unable to locate credentials file.")
            return 
        }
        
        // load credentials file
        let dict = NSDictionary(contentsOfFile: credentialsURL)
        guard let credentials = dict as? Dictionary<String, String> else {
            failure("Loading Credentials", message: "Unable to read credentials file.")
            return
        }
        
        // read SpeechToText username
        guard let toneUser = credentials["ToneAnalyzerUsername"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text username.")
            return
        }
        
        // read SpeechToText password
        guard let tonePassword = credentials["ToneAnalyzerPassword"] else {
            failure("Loading Credentials", message: "Unable to read Speech to Text password.")
            return
        }
        
        
        let version = "2016-08-12" // use today's date for the most recent version
        
        toneAnalyzer = ToneAnalyzer(username: toneUser, password: tonePassword, version: version)
        
        
//        let text = "我現在超級生氣"
        let failure2 = { (error: NSError) in print(error) }
        toneAnalyzer.getTone(text, failure: failure2) { tones in
            
            for tone in tones.documentTone[0].tones {
                print("\(tone.name) = \(tone.score)")
            }
            
            
            let anger:ToneScore = tones.documentTone[0].tones[0]
            let disgust:ToneScore = tones.documentTone[0].tones[1]
            let fear:ToneScore = tones.documentTone[0].tones[2]
            let joy:ToneScore = tones.documentTone[0].tones[3]
            let sad:ToneScore = tones.documentTone[0].tones[4]
            
            if anger.score > fear.score && anger.score > joy.score && anger.score > sad.score && anger.score > disgust.score {
                //生氣
//                print("生氣=", anger.score)
                chatView.refrashBackground(anger.score, andName: anger.name)
            }
            else if fear.score > anger.score && fear.score > joy.score && fear.score > sad.score && fear.score > disgust.score {
                //害怕
//                print("害怕=", fear.score)
                chatView.refrashBackground(fear.score, andName: fear.name)
            }
            else if joy.score > anger.score && joy.score > fear.score && joy.score > sad.score && joy.score > disgust.score {
                //開心
//                print("開心=", joy.score)
                chatView.refrashBackground(joy.score, andName: joy.name)
            }
            else if sad.score > anger.score && sad.score > fear.score && sad.score > joy.score && sad.score > disgust.score {
                //難過
//                print("難過=", sad.score)
                chatView.refrashBackground(sad.score, andName: sad.name)
            } else {
                chatView.refrashBackground(disgust.score, andName: disgust.name)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func failure(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in }
        alert.addAction(ok)
        presentViewController(alert, animated: true) { }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
