//
//  ViewController.swift
//  pingpong
//
//  Created by peter on 2021/7/27.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var leftPointsButton: UIButton!
    @IBOutlet weak var rightPointsButton: UIButton!
    @IBOutlet weak var leftRoundsButton: UIButton!
    @IBOutlet weak var rightRoundsButton: UIButton!
    @IBOutlet weak var leftServeLabel: UILabel!
    @IBOutlet weak var rightServeLabel: UILabel!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var changeSideButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    // Create a speech synthesizer.
    var synthesizer = AVSpeechSynthesizer()
    let voice = AVSpeechSynthesisVoice(language: "zh-TW")
    let volume: Float = 0.8
    
    func roundEndVoice(saySomething: String?) {
        let roundEndUtterance: AVSpeechUtterance
        if saySomething == nil {
            roundEndUtterance = AVSpeechUtterance(string: "此局結束")
            roundEndUtterance.rate = 0.4
            roundEndUtterance.pitchMultiplier = 0.8
            roundEndUtterance.postUtteranceDelay = 0.2
        } else {
            roundEndUtterance = AVSpeechUtterance(string: saySomething!)
            roundEndUtterance.rate = 0.6
            roundEndUtterance.pitchMultiplier = 1.2
            roundEndUtterance.postUtteranceDelay = 0.3
        }
        
        roundEndUtterance.volume = volume
        roundEndUtterance.voice = voice
        
        if synthesizer.isSpeaking {
            print(synthesizer.stopSpeaking(at: .immediate))
        }
        synthesizer.speak(roundEndUtterance)
    }
    
    func pointVoice(_ person: String) {
        let roundEndUtterance = AVSpeechUtterance(string: "\(person)得分")
        roundEndUtterance.rate = 0.55
        roundEndUtterance.pitchMultiplier = 1.0
        roundEndUtterance.postUtteranceDelay = 0.2
        roundEndUtterance.volume = volume
        roundEndUtterance.voice = voice

        synthesizer.speak(roundEndUtterance)
    }
    
    func changeSideVoice() {
        let roundEndUtterance = AVSpeechUtterance(string: "換邊")
        roundEndUtterance.rate = 0.50
        roundEndUtterance.pitchMultiplier = 0.90
        roundEndUtterance.postUtteranceDelay = 0.2
        roundEndUtterance.volume = volume
        roundEndUtterance.voice = voice

        synthesizer.speak(roundEndUtterance)
    }
    
    struct PushDropStack<T> {
        var elements: [T] = []
        var capacity: Int
        var last: T? {
            elements.last
        }
        
        init(capacity: Int) {
            self.capacity = capacity
        }
        
        mutating func push(_ element: T) {
            if elements.count >= capacity {
                elements.removeFirst()
            }
            elements.append(element)
        }
        
        mutating func pop() -> T {
            if elements.count <= 1 {
                return elements[0]
            }
            return elements.removeLast()
        }
    }
    
    enum ServeSide {
        case left
        case right
        
        func change() -> ServeSide {
            switch self {
            case .left:
                return .right
            case .right:
                return .left
            }
        }
    }
    
    struct Frame {
        var roundServe = ServeSide.left
        var serve = ServeSide.left
        var servesCounts = 0
        
        var deuce = false
        var leftRounds = 0
        var rightRounds = 0
        var leftPoints = 0
        var rightPoints = 0
        
        func checkDeuce() -> Bool {
            deuce ? true : ((leftPoints == 10) && (rightPoints == 10))
        }
        
        func checkRoundEnd() -> Bool {
            if deuce && (leftPoints >= (rightPoints + 2)) {
                return true
            }
            
            if deuce && (rightPoints >= (leftPoints + 2)) {
                return true
            }
            
            if !deuce && (leftPoints == 11) {
                return true
            }
            
            if !deuce && (rightPoints == 11) {
                return true
            }
 
            return false
        }
        
        mutating func changeSide() {
            self.serve = self.serve.change()
            self.roundServe = self.roundServe.change()
            
            let round = self.leftRounds
            self.leftRounds = self.rightRounds
            self.rightRounds = round
            
            let points = self.leftPoints
            self.leftPoints = self.rightPoints
            self.rightPoints = points
        }
        
        mutating func resetPoints() {
            self.leftPoints = 0
            self.rightPoints = 0
        }
        
        mutating func addLeftRounds() {
            leftRounds += 1
        }
        
        mutating func addRightRounds() {
            rightRounds += 1
        }
        
        mutating func addServesCounts() {
            servesCounts += 1
            
            if deuce {
                serve = serve.change()
                servesCounts = 0
                return
            }
            
            if (servesCounts % 2) != 0 {
                return
            }

            serve = serve.change()
            servesCounts = 0
        }
        
        mutating func addLeftPoints() -> Frame? {
            self.leftPoints += 1
            let alertFrame = self
            
            addServesCounts()
            self.deuce = checkDeuce()
            if checkRoundEnd() {
                resetPoints()
                addLeftRounds()
                self.roundServe = self.roundServe.change()
                self.serve = self.roundServe
                self.deuce = false
                return alertFrame
            }
            
            return nil
        }
        
        mutating func addRightPoints() -> Frame? {
            self.rightPoints += 1
            let alertFrame = self
            
            self.deuce = checkDeuce()
            addServesCounts()
            if checkRoundEnd() {
                resetPoints()
                addRightRounds()
                self.roundServe = self.roundServe.change()
                self.serve = self.roundServe
                self.deuce = false
                return alertFrame
            }
            
            return nil
        }
    }
    
    var game = PushDropStack<Frame>.init(capacity: 16)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let firstFrame = Frame()
        game.push(firstFrame)
        updateScreen(show: firstFrame)
        
    }

    func updateScreen(show frame: Frame) {
        var attribute = AttributedString("\(frame.leftPoints)")
        attribute.font = UIFont.systemFont(ofSize:  150)
        leftPointsButton.configuration?.attributedTitle = attribute
        leftPointsButton.tintColor = .white
        
        attribute = AttributedString("\(frame.rightPoints)")
        attribute.font = UIFont.systemFont(ofSize: 150)
        rightPointsButton.configuration?.attributedTitle = attribute
        rightPointsButton.tintColor = .white
        
        attribute = AttributedString("\(frame.leftRounds)")
        attribute.font = UIFont.systemFont(ofSize: 80)
        leftRoundsButton.configuration?.attributedTitle = attribute
        leftRoundsButton.tintColor = .white
        
        attribute = AttributedString("\(frame.rightRounds)")
        attribute.font = UIFont.systemFont(ofSize: 80)
        rightRoundsButton.configuration?.attributedTitle = attribute
        rightRoundsButton.tintColor = .white
        
        leftServeLabel.isHidden = (frame.serve != .left)
        leftServeLabel.textColor = .blue
        
        rightServeLabel.isHidden = (frame.serve != .right)
        rightServeLabel.textColor = .blue
        
        attribute = AttributedString("上一步")
        attribute.font = UIFont.systemFont(ofSize: 17)
        rewindButton.configuration?.attributedTitle = attribute
        rewindButton.tintColor = .white
        
        attribute = AttributedString("換邊")
        attribute.font = UIFont.systemFont(ofSize: 17)
        changeSideButton.configuration?.attributedTitle = attribute
        changeSideButton.tintColor = .white
        
        attribute = AttributedString("重置")
        attribute.font = UIFont.systemFont(ofSize: 17)
        resetButton.configuration?.attributedTitle = attribute
        resetButton.tintColor = .red
    }
    
    func alertRoundEndMessage(checkedHandler: @escaping () -> Void) {
        let controller = UIAlertController(title: "", message: "此局結束", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            checkedHandler()
        }
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func rewindButtonTouchUpInside(_ sender: UIButton) {
        _ = game.pop()
        guard let currentFrame = game.last else {
            return
        }
        updateScreen(show: currentFrame)
    }
    
    @IBAction func changeSideButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }
        changeSideVoice()
        
        currentFrame.changeSide()
        game.push(currentFrame)
        updateScreen(show: currentFrame)
    }
    
    @IBAction func resetButtonTouchUpInside(_ sender: UIButton) {
        let resetFrame = Frame()
        game.push(resetFrame)
        updateScreen(show: resetFrame)
    }
    
    @IBAction func leftPointsButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }
        pointVoice("左邊")
        guard let alertFrame = currentFrame.addLeftPoints() else {
            game.push(currentFrame)
            updateScreen(show: currentFrame)
            return
        }
        
        game.push(currentFrame)
        updateScreen(show: alertFrame)
        alertRoundEndMessage{ self.updateScreen(show: currentFrame) }
        roundEndVoice(saySomething: "右邊，你阿庫雅嗎？")
    }
    
    @IBAction func rightPointsButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }
        
        pointVoice("右邊")
        guard let alertFrame = currentFrame.addRightPoints() else {
            game.push(currentFrame)
            updateScreen(show: currentFrame)
            return
        }
        
        game.push(currentFrame)
        updateScreen(show: alertFrame)
        alertRoundEndMessage{ self.updateScreen(show: currentFrame) }
        
        if currentFrame.rightRounds >= (currentFrame.leftRounds + 2) {
            roundEndVoice(saySomething: "愛麗絲女神在我這邊拉！")
        } else {
            roundEndVoice(saySomething: nil)
        }
    }
    
    @IBAction func leftRoundsButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }
        currentFrame.addLeftRounds()
        game.push(currentFrame)
        updateScreen(show: currentFrame)
    }
    
    @IBAction func rightRoundsButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }
        currentFrame.addRightRounds()
        game.push(currentFrame)
        updateScreen(show: currentFrame)
    }
}

