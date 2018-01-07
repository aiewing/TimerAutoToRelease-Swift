//
//  TimerAutoToRelease.swift
//  TimerAutoToRelease
//
//  Created by Aiewing on 2018/1/6.
//  Copyright © 2018年 Aiewing. All rights reserved.
//

import Foundation

extension Timer
{
    /// 创建可以自动释放的定时器
    ///
    /// - Parameters:
    ///   - ti: 定时器时间间隔
    ///   - aTarget: <#aTarget description#>
    ///   - aName: 定时器名字
    ///   - aUserInfo: <#aUserInfo description#>
    ///   - yesOrNo: 是否循环
    ///   - aBlock: <#aBlock description#>
    /// - Returns: <#return value description#>
    class func scheduledTimerAutoToRelease(timeInterval ti: TimeInterval, target aTarget: AnyObject, name aName: String, userInfo aUserInfo: Any?, repeats yesOrNo: Bool, block aBlock: @escaping TimerBlock) -> Timer
    {
        let timerTarget: TimerTarget = TimerTarget(target: aTarget, name: aName, block: aBlock)
        let timer: Timer = Timer.scheduledTimer(timeInterval: ti, target: timerTarget, selector: #selector(timerTarget.aiewing), userInfo: aUserInfo, repeats: yesOrNo)
        timerTarget.timer = timer
        return timer
    }
    
    
    /// 暂停定时器
    public func pauseTimer()
    {
        guard self.isValid else {
            return
        }
        self.fireDate = Date.distantFuture
    }
    
    /// 开始定时器
    public func resumeTimer()
    {
        guard self.isValid else {
            return
        }
        self.fireDate = Date()
    }
    
    
    /// 定时开始定时器
    ///
    /// - Parameter intercal: 经过多少秒之后开始
    public func resumeTimerAfterInterval(intercal: TimeInterval)
    {
        guard self.isValid else {
            return
        }
        self.fireDate = Date(timeIntervalSinceNow: intercal)
    }
}

typealias TimerBlock = (Timer) -> Swift.Void

class TimerTarget: NSObject {
    
    weak var timer: Timer?
    weak var target: AnyObject?
    
    var name: String?
    var block: TimerBlock?
    
    /// 初始化
    ///
    /// - Parameters:
    ///   - aTarget: 定时器的持有者
    ///   - aName: 定时器名字
    ///   - aBlock: <#aBlock description#>
    init(target aTarget: AnyObject?, name aName: String?, block aBlock: TimerBlock?)
    {
        target = aTarget as AnyObject
        name = aName
        block = aBlock
    }
    
    convenience override init() {
        self.init(target: nil, name: nil, block: nil)
    }
    
    @objc func aiewing()
    {
        guard let _ = self.target,
        let block = self.block,
        let timer = self.timer else {
            self.timer?.invalidate()
            self.timer = nil
            guard let name = self.name else {
                return
            }
            print("Timer called \(name) has been invalidated")
            return
        }
        
        // 执行block
        block(timer)
    }
}
