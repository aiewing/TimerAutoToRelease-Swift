//
//  AieController.swift
//  TimerAutoToRelease
//
//  Created by Aiewing on 2018/1/7.
//  Copyright © 2018年 Aiewing. All rights reserved.
//

import UIKit

class AieController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        button.center = view.center
        view.addSubview(button)
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        
        Timer.scheduledTimerAutoToRelease(timeInterval: 2, target: self, name: "aiewing1", userInfo: nil, repeats: true) { (_) in
            print("-------1")
        }
        Timer.scheduledTimerAutoToRelease(timeInterval: 2, target: self, name: "aiewing2", userInfo: nil, repeats: true) { (_) in
            print("-------2")
        }
        Timer.scheduledTimerAutoToRelease(timeInterval: 2, target: self, name: "aiewing3", userInfo: nil, repeats: true) { (_) in
            print("-------3")
        }
        Timer.scheduledTimerAutoToRelease(timeInterval: 2, target: self, name: "aiewing4", userInfo: nil, repeats: true) { (_) in
            print("-------4")
        }
    }
    
    @objc func buttonClick()
    {
        self.dismiss(animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
