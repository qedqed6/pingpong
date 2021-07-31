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
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var changeSideButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var scenesModeButton: UIButton!
    // Layout of balls, order is left to right
    @IBOutlet var ballsImageView: [UIImageView]!
    
    // An animation of end of round
    func animationRoundEnd() -> CATransition {
        let animation: CATransition = CATransition()
        animation.type = CATransitionType(rawValue: "cube")
        animation.duration = 0.8
        return animation
    }
    
    // An animation of getting points on left
    func animationAddLeftPoints() -> CATransition {
        let animation: CATransition = CATransition()
        animation.type = CATransitionType(rawValue: "pageCurl")
        animation.subtype = .fromBottom
        animation.duration = 0.8
        return animation
    }
    
    // An animation of getting points on right
    func animationAddRightPoints() -> CATransition {
        let animation: CATransition = CATransition()
        animation.type = CATransitionType(rawValue: "pageCurl")
        animation.subtype = .fromBottom
        animation.duration = 0.8
        return animation
    }
    
    // An animation while left side winning this round
    func animationAddLeftRounds() -> CATransition {
        let animation: CATransition = CATransition()
        animation.type = CATransitionType(rawValue: "pageCurl")
        animation.subtype = .fromBottom
        animation.duration = 0.8
        return animation
    }
    
    // An animation while right side winning this round
    func animationAddRightRounds() -> CATransition {
        let animation: CATransition = CATransition()
        animation.type = CATransitionType(rawValue: "pageCurl")
        animation.subtype = .fromBottom
        animation.duration = 0.8
        return animation
    }
    
    // An animation to hidden the ball
    func animationHiddeBall() -> CABasicAnimation {
        let basicAnimation = CABasicAnimation(keyPath: "transform.rotation.y")
        basicAnimation.duration = 0.5
        basicAnimation.repeatCount = 1
        basicAnimation.fromValue = 0
        basicAnimation.toValue = Double.pi
        
        return basicAnimation
    }
    
    // An animation to visible the ball
    func animationVisibleBall() -> CABasicAnimation {
        let basicAnimation = CABasicAnimation(keyPath: "transform.rotation.y")
        basicAnimation.duration = 0.5
        basicAnimation.repeatCount = 2
        basicAnimation.fromValue = 0
        basicAnimation.toValue = 2 * Double.pi
        
        return basicAnimation
    }
    
    // Capacity limit stack
    // While capacity is full, push a data into stack will drop the first one.
    // Pop a data will take out the last one of data which be pushed.
    struct CirclyStack<T> {
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
    
    enum Side {
        case left
        case right
        
        func change() -> Side {
            switch self {
            case .left:
                return .right
            case .right:
                return .left
            }
        }
        
        func toString() -> String {
            switch self {
            case .left:
                return "left"
            case .right:
                return "right"
            }
        }
    }
    
    enum BallState {
        case hidden
        case visible
        
        func isHidden() -> Bool {
            switch self {
            case .hidden:
                return true
            case .visible:
                return false
            }
        }
        
        func isVisible() -> Bool {
            switch self {
            case .hidden:
                return false
            case .visible:
                return true
            }
        }
        
        func toSting() -> String {
            switch self {
            case .hidden:
                return "hidden"
            case .visible:
                return "visible"
            }
        }
    }
    
    enum ScenesMode {
        case dark
        case light
        
        func change() -> ScenesMode {
            switch self {
            case .dark:
                return .light
            case .light:
                return .dark
            }
        }
    }
    
    struct GameFrame {
        var homePlayer = Side.left
        var roundServe = Side.left
        var serve = Side.left
        var servesCounts = 0
        var scenesMode = ScenesMode.dark
        
        var deuce = false
        var leftRounds = 0
        var rightRounds = 0
        var leftPoints = 0
        var rightPoints = 0
        
        func ballsStateLeftToRightLayout() -> [BallState] {
            var layout = Array<BallState>.init(repeating: .hidden, count: 4)
            let reminingBalls: Int
            
            if self.deuce && (self.servesCounts >= 0) && (self.servesCounts <= 1) {
                reminingBalls = (1 - self.servesCounts)
            } else if !self.deuce && (self.servesCounts >= 0) && (self.servesCounts <= 2) {
                reminingBalls = (2 - self.servesCounts)
            } else {
                return layout
            }
            
            switch self.serve {
            case .left:
                if reminingBalls == 2 {
                    layout[0] = .visible
                    layout[1] = .visible
                    break
                }
                if reminingBalls == 1 {
                    layout[0] = .visible
                    break
                }
            case .right:
                if reminingBalls == 2 {
                    layout[2] = .visible
                    layout[3] = .visible
                    break
                }
                if reminingBalls == 1 {
                    layout[3] = .visible
                    break
                }
            }
            
            return layout
        }
        
        func checkDeuce() -> Bool {
            deuce ? true : ((leftPoints == 10) && (rightPoints == 10))
        }
        
        func getRemainingServeCounts() -> Int? {
            if self.deuce && (self.servesCounts >= 0) && (self.servesCounts <= 1) {
                return (1 - self.servesCounts)
            }
            
            if !self.deuce && (self.servesCounts >= 0) && (self.servesCounts <= 2) {
                return (2 - self.servesCounts)
            }
            
            return nil
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
            self.homePlayer = self.homePlayer.change()
            
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
        
        mutating func addLeftPoints() -> GameFrame? {
            self.leftPoints += 1
            let alertFrame = self
            
            addServesCounts()
            self.deuce = checkDeuce()
            if checkRoundEnd() {
                resetPoints()
                addLeftRounds()
                self.roundServe = self.roundServe.change()
                self.serve = self.roundServe
                self.servesCounts = 0
                self.deuce = false
                return alertFrame
            }
            
            return nil
        }
        
        mutating func addRightPoints() -> GameFrame? {
            self.rightPoints += 1
            let alertFrame = self
            
            self.deuce = checkDeuce()
            addServesCounts()
            if checkRoundEnd() {
                resetPoints()
                addRightRounds()
                self.roundServe = self.roundServe.change()
                self.serve = self.roundServe
                self.servesCounts = 0
                self.deuce = false
                return alertFrame
            }
            
            return nil
        }
    }
    
    var game = CirclyStack<GameFrame>.init(capacity: 16)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let firstFrame = GameFrame()
        game.push(firstFrame)
        updateScreen(show: firstFrame, ballsUpdate: true)
        
        print(MemoryLayout<ScenesMode>.size)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    func updateScreen(show frame: GameFrame, ballsUpdate: Bool) {
        let boardBackgroundColor: UIColor
        let pointsTintColor: UIColor
        let pointsBackgroundColor: UIColor
        let roundsTintColor: UIColor
        let roundsBackgroundColor: UIColor
        let controlColor: UIColor
        
        switch frame.scenesMode {
        case .dark:
            boardBackgroundColor = .systemGray3
            pointsBackgroundColor = .systemGray
            roundsBackgroundColor = .systemGray
            pointsTintColor = .white
            roundsTintColor = .white
            controlColor = .white
            
        case .light:
            boardBackgroundColor = .black
            pointsBackgroundColor = .white
            roundsBackgroundColor = .white
            pointsTintColor = .systemBlue
            roundsTintColor = .systemBlue
            controlColor = .systemBlue
        }
        
        self.view.backgroundColor = boardBackgroundColor
        
        var attribute = AttributedString("\(frame.leftPoints)")
        attribute.font = UIFont.systemFont(ofSize:  150)
        leftPointsButton.configuration?.attributedTitle = attribute
        leftPointsButton.tintColor = pointsTintColor
        leftPointsButton.backgroundColor = pointsBackgroundColor
        
        attribute = AttributedString("\(frame.rightPoints)")
        attribute.font = UIFont.systemFont(ofSize: 150)
        rightPointsButton.configuration?.attributedTitle = attribute
        rightPointsButton.tintColor = pointsTintColor
        rightPointsButton.backgroundColor = pointsBackgroundColor
        
        attribute = AttributedString("\(frame.leftRounds)")
        attribute.font = UIFont.systemFont(ofSize: 80)
        leftRoundsButton.configuration?.attributedTitle = attribute
        leftRoundsButton.tintColor = roundsTintColor
        leftRoundsButton.backgroundColor = roundsBackgroundColor
        
        attribute = AttributedString("\(frame.rightRounds)")
        attribute.font = UIFont.systemFont(ofSize: 80)
        rightRoundsButton.configuration?.attributedTitle = attribute
        rightRoundsButton.tintColor = roundsTintColor
        rightRoundsButton.backgroundColor = roundsBackgroundColor
        
        attribute = AttributedString("")
        attribute.font = UIFont.systemFont(ofSize: 17)
        rewindButton.configuration?.attributedTitle = attribute
        rewindButton.tintColor = controlColor
        
        attribute = AttributedString("")
        attribute.font = UIFont.systemFont(ofSize: 17)
        changeSideButton.configuration?.attributedTitle = attribute
        changeSideButton.tintColor = controlColor
        
        attribute = AttributedString("")
        attribute.font = UIFont.systemFont(ofSize: 17)
        resetButton.configuration?.attributedTitle = attribute
        resetButton.tintColor = .red
        
        let scenesButtonImageName: String
        switch frame.scenesMode {
        case .light:
            scenesButtonImageName = "moon"
        case .dark:
            scenesButtonImageName = "moon.fill"
        }
        scenesModeButton.tintColor = controlColor
        scenesModeButton.setImage(UIImage(systemName: scenesButtonImageName), for: .highlighted)

        if !ballsUpdate {
            return
        }
        
        for (index, ballState) in frame.ballsStateLeftToRightLayout().enumerated() {
            ballsImageView[index].tintColor = ballState.isVisible() ? UIColor.systemOrange : UIColor.clear
        }
    }
    
    func updateScreenAnimation(show preFrame: GameFrame, to nextFrame: GameFrame) {
        if preFrame.leftPoints != nextFrame.leftPoints {
            leftPointsButton.layer.add(self.animationAddLeftPoints(), forKey: nil)
        }
        
        if preFrame.rightPoints != nextFrame.rightPoints {
            rightPointsButton.layer.add(self.animationAddRightPoints(), forKey: nil)
        }
        
        if preFrame.leftRounds != nextFrame.leftRounds {
            leftRoundsButton.layer.add(self.animationAddLeftRounds(), forKey: nil)
        }
        
        if preFrame.rightRounds != nextFrame.rightRounds {
            rightRoundsButton.layer.add(self.animationAddRightRounds(), forKey: nil)
        }
        
        let preBallState = preFrame.ballsStateLeftToRightLayout()
        let nextBallState = nextFrame.ballsStateLeftToRightLayout()
        
        for (index, ballState) in nextBallState.enumerated() {
            if preBallState[index] != nextBallState[index] {
                let animation: CABasicAnimation
                if ballState.isHidden() {
                    animation = self.animationHiddeBall()
                    animation.animationComplete {
                        self.ballsImageView[index].tintColor = UIColor.clear
                    }
                } else {
                    animation = self.animationVisibleBall()
                    ballsImageView[index].tintColor = UIColor.systemOrange
                }
                
                ballsImageView[index].layer.add(animation, forKey: ballState.toSting())
            }
        }
        
        self.updateScreen(show: nextFrame, ballsUpdate: false)
    }

    func alertRoundEndMessage(checkedHandler: @escaping () -> Void) {
        let controller = UIAlertController(title: "", message: "此局結束", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.view.layer.add(self.animationRoundEnd(), forKey: nil)
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
        updateScreen(show: currentFrame, ballsUpdate: true)
    }
    
    @IBAction func changeSideButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }

        currentFrame.changeSide()
        game.push(currentFrame)
        updateScreen(show: currentFrame, ballsUpdate: true)
    }
    
    @IBAction func resetButtonTouchUpInside(_ sender: UIButton) {
        guard let currentFrame = game.last else {
            return
        }
        var resetFrame = GameFrame()
        resetFrame.scenesMode = currentFrame.scenesMode
        
        game.push(resetFrame)
        updateScreen(show: resetFrame, ballsUpdate: true)
    }
    
    @IBAction func leftPointsButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }
        let previousFrame = currentFrame

        guard let alertFrame = currentFrame.addLeftPoints() else {
            game.push(currentFrame)
            updateScreenAnimation(show: previousFrame, to: currentFrame)
            return
        }
        
        game.push(currentFrame)
        updateScreen(show: alertFrame, ballsUpdate: true)
        alertRoundEndMessage{ self.updateScreen(show: currentFrame, ballsUpdate: true) }
    }
    
    @IBAction func rightPointsButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }
        let previousFrame = currentFrame
        
        guard let alertFrame = currentFrame.addRightPoints() else {
            game.push(currentFrame)
            updateScreenAnimation(show: previousFrame, to: currentFrame)
            return
        }
        
        game.push(currentFrame)
        updateScreen(show: alertFrame, ballsUpdate: true)
        alertRoundEndMessage{ self.updateScreen(show: currentFrame, ballsUpdate: true) }
    }
    
    @IBAction func leftRoundsButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }
        let previousFrame = currentFrame
        
        currentFrame.addLeftRounds()
        game.push(currentFrame)
        updateScreenAnimation(show: previousFrame, to: currentFrame)
    }
    
    @IBAction func rightRoundsButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }
        let previousFrame = currentFrame
        
        currentFrame.addRightRounds()
        game.push(currentFrame)
        updateScreenAnimation(show: previousFrame, to: currentFrame)
    }
    
    @IBAction func scenesModeButtonTouchUpInside(_ sender: UIButton) {
        guard var currentFrame = game.last else {
            return
        }

        currentFrame.scenesMode = currentFrame.scenesMode.change()
        
        game.push(currentFrame)
        updateScreen(show: currentFrame, ballsUpdate: true)
    }
}

public typealias CAAnimationCallbackType = () -> ();

public class CAAnimationCallback: NSObject, CAAnimationDelegate {
    var stopCallBack: CAAnimationCallbackType?
    var startCallBack: CAAnimationCallbackType?
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let callBack = stopCallBack {
            callBack()
        }
    }
    
    public func animationDidStart(_ anim: CAAnimation, finished flag: Bool) {
        if let callBack = startCallBack {
            callBack()
        }
    }
}

extension CAAnimation {
    func animationComplete(callback: @escaping CAAnimationCallbackType) {
        if let delegate = self.delegate as? CAAnimationCallback {
            delegate.stopCallBack = callback
            return
        }
        
        let newDelegate = CAAnimationCallback()
        newDelegate.stopCallBack = callback
        self.delegate = newDelegate
    }
    
    func animationStart(callback: @escaping CAAnimationCallbackType) {
        if let delegate = self.delegate as? CAAnimationCallback {
            delegate.startCallBack = callback
            return
        }
        
        let newDelegate = CAAnimationCallback()
        newDelegate.startCallBack = callback
        self.delegate = newDelegate
    }
}
