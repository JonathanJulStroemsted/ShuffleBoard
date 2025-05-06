//
//  GameScene.swift
//  ShuffleBoard Shared
//
//  Created by Jonathan Strømsted on 05/05/2025.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game elements
    private var ball: SKShapeNode!
    private var paddle1: SKShapeNode!
    private var paddle2: SKShapeNode!
    private var scoreLabel1: SKLabelNode!
    private var scoreLabel2: SKLabelNode!
    private var pauseButton: SKSpriteNode!
    private var obstacles = [SKNode]()
    
    // Game state
    private var score1 = 0
    private var score2 = 0
    private var isPausedNow = false
    private var activeTouches: [UITouch: SKShapeNode] = [:]
    private var gameStarted = false
    private var targetScore = 10
    private var gameEnded = false
    
    // UI elements
    private var menuNode: SKNode?
    private var winnerNode: SKNode?
    
    // Physics categories
    private let ballCategory: UInt32 = 0x1 << 0
    private let wallCategory: UInt32 = 0x1 << 1
    private let paddleCategory: UInt32 = 0x1 << 2
    
    class func newGameScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        scene.scaleMode = .aspectFill
        return scene
    }
    
    override func didMove(to view: SKView) {
        // Set up physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        // Set up game elements
        setupBoundaries()
        setupBall()
        setupPaddles()
        setupScoreLabels()
        
        // Show score selection menu instead of starting game immediately
        showScoreSelectionMenu()
    }
    
    private func setupBoundaries() {
        // Create only side boundaries (no top/bottom)
        let sideWalls = SKNode()
        
        // Left boundary
        let leftWall = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: 0), 
                                   to: CGPoint(x: 0, y: size.height))
        leftWall.friction = 0
        leftWall.restitution = 1.0
        leftWall.isDynamic = false
        leftWall.categoryBitMask = wallCategory
        
        // Right boundary
        let rightWall = SKPhysicsBody(edgeFrom: CGPoint(x: size.width, y: 0), 
                                    to: CGPoint(x: size.width, y: size.height))
        rightWall.friction = 0
        rightWall.restitution = 1.0
        rightWall.isDynamic = false
        rightWall.categoryBitMask = wallCategory
        
        // Create visual boundaries to help see where the edges are
        let leftEdge = SKSpriteNode(color: .white, size: CGSize(width: 4, height: size.height))
        leftEdge.position = CGPoint(x: 2, y: size.height/2)
        addChild(leftEdge)
        
        let rightEdge = SKSpriteNode(color: .white, size: CGSize(width: 4, height: size.height))
        rightEdge.position = CGPoint(x: size.width-2, y: size.height/2)
        addChild(rightEdge)
        
        // Add physics bodies to a container node
        let leftNode = SKNode()
        leftNode.physicsBody = leftWall
        sideWalls.addChild(leftNode)
        
        let rightNode = SKNode()
        rightNode.physicsBody = rightWall
        sideWalls.addChild(rightNode)
        
        addChild(sideWalls)
        
        // Remove debug visualization of the boundaries
    }
    
    private func setupBall() {
        // Create the ball
        let ballRadius: CGFloat = 15
        ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.fillColor = .white
        ball.strokeColor = .clear
        ball.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Add physics to the ball
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.friction = 0
        ball.physicsBody?.linearDamping = 0.0
        
        // Set up physics categories
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.contactTestBitMask = wallCategory | paddleCategory
        ball.physicsBody?.collisionBitMask = wallCategory | paddleCategory
        
        addChild(ball)
    }
    
    private func setupPaddles() {
        // Create paddles
        let paddleWidth: CGFloat = 100
        let paddleHeight: CGFloat = 10
        
        // Paddle 1 (bottom)
        paddle1 = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight), cornerRadius: 5)
        paddle1.fillColor = .red
        paddle1.strokeColor = .clear
        paddle1.position = CGPoint(x: size.width / 2, y: paddleHeight + 40)
        
        // Paddle 2 (top)
        paddle2 = SKShapeNode(rectOf: CGSize(width: paddleWidth, height: paddleHeight), cornerRadius: 5)
        paddle2.fillColor = .blue
        paddle2.strokeColor = .clear
        paddle2.position = CGPoint(x: size.width / 2, y: size.height - paddleHeight - 40)
        
        // Add physics to paddles - fix: use non-optional references
        for paddle in [paddle1!, paddle2!] {
            paddle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: paddleWidth, height: paddleHeight), center: .zero)
            paddle.physicsBody?.isDynamic = false
            paddle.physicsBody?.restitution = 1.0
            paddle.physicsBody?.friction = 0
            paddle.physicsBody?.categoryBitMask = paddleCategory
            paddle.physicsBody?.contactTestBitMask = ballCategory
            paddle.physicsBody?.collisionBitMask = ballCategory
            
            addChild(paddle)
        }
    }
    
    private func setupScoreLabels() {
        // Score labels
        scoreLabel1 = SKLabelNode(fontNamed: "Helvetica Neue Bold")
        scoreLabel1.fontSize = 36
        scoreLabel1.fontColor = .red
        scoreLabel1.position = CGPoint(x: size.width / 2 - 50, y: size.height / 2)
        scoreLabel1.horizontalAlignmentMode = .center
        scoreLabel1.text = "0"
        
        scoreLabel2 = SKLabelNode(fontNamed: "Helvetica Neue Bold")
        scoreLabel2.fontSize = 36
        scoreLabel2.fontColor = .blue
        scoreLabel2.position = CGPoint(x: size.width / 2 + 50, y: size.height / 2)
        scoreLabel2.horizontalAlignmentMode = .center
        scoreLabel2.text = "0"
        
        addChild(scoreLabel1)
        addChild(scoreLabel2)
        
        // Add pause button
        let pauseButtonSize: CGFloat = 40
        pauseButton = SKSpriteNode(color: .darkGray, size: CGSize(width: pauseButtonSize, height: pauseButtonSize))
        pauseButton.position = CGPoint(x: size.width - 30, y: size.height - 30)
        pauseButton.zPosition = 100
        
        // Add pause icon
        let pauseSymbol = SKShapeNode(rectOf: CGSize(width: 5, height: 15))
        pauseSymbol.fillColor = .white
        pauseSymbol.strokeColor = .clear
        pauseSymbol.position = CGPoint(x: -5, y: 0)
        
        let pauseSymbol2 = SKShapeNode(rectOf: CGSize(width: 5, height: 15))
        pauseSymbol2.fillColor = .white
        pauseSymbol2.strokeColor = .clear
        pauseSymbol2.position = CGPoint(x: 5, y: 0)
        
        pauseButton.addChild(pauseSymbol)
        pauseButton.addChild(pauseSymbol2)
        
        addChild(pauseButton)
    }
    
    private func showScoreSelectionMenu() {
        // Create menu container
        menuNode = SKNode()
        
        // Create semi-transparent background
        let menuBackground = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), 
                                        size: CGSize(width: size.width, height: size.height))
        menuBackground.position = CGPoint(x: size.width/2, y: size.height/2)
        menuNode?.addChild(menuBackground)
        
        // Title
        let titleLabel = SKLabelNode(fontNamed: "Helvetica Neue Bold")
        titleLabel.text = "SHUFFLEBOARD"
        titleLabel.fontSize = 44
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.7)
        menuNode?.addChild(titleLabel)
        
        // Subtitle
        let subtitleLabel = SKLabelNode(fontNamed: "Helvetica Neue")
        subtitleLabel.text = "Select winning score"
        subtitleLabel.fontSize = 26
        subtitleLabel.fontColor = .white
        subtitleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.6)
        menuNode?.addChild(subtitleLabel)
        
        // Create score option buttons
        let buttonScores = [3, 5, 10]
        let buttonWidth: CGFloat = 120
        let buttonHeight: CGFloat = 60
        let buttonSpacing: CGFloat = 20
        let totalButtonsWidth = CGFloat(buttonScores.count) * buttonWidth + CGFloat(buttonScores.count - 1) * buttonSpacing
        var currentX = (size.width - totalButtonsWidth) / 2 + buttonWidth / 2
        
        for score in buttonScores {
            let button = SKSpriteNode(color: .white, size: CGSize(width: buttonWidth, height: buttonHeight))
            button.position = CGPoint(x: currentX, y: size.height * 0.45)
            button.name = "score_\(score)"
            
            let buttonLabel = SKLabelNode(fontNamed: "Helvetica Neue Bold")
            buttonLabel.text = "\(score)"
            buttonLabel.fontSize = 32
            buttonLabel.fontColor = .black
            buttonLabel.verticalAlignmentMode = .center
            button.addChild(buttonLabel)
            
            menuNode?.addChild(button)
            currentX += buttonWidth + buttonSpacing
        }
        
        addChild(menuNode!)
        
        // Hide ball and paddles until game starts
        ball.isHidden = true
        paddle1.isHidden = true
        paddle2.isHidden = true
        scoreLabel1.isHidden = true
        scoreLabel2.isHidden = true
        pauseButton.isHidden = true
    }
    
    private func startGameWithScore(_ score: Int) {
        // Set target score
        targetScore = score
        
        // Reset game state
        gameEnded = false
        isPausedNow = false
        
        // Clear obstacles when starting a new game
        for obstacle in obstacles {
            obstacle.removeFromParent()
        }
        obstacles.removeAll()
        
        // Remove menu
        menuNode?.removeFromParent()
        
        // Show game elements
        ball.isHidden = false
        paddle1.isHidden = false
        paddle2.isHidden = false
        scoreLabel1.isHidden = false
        scoreLabel2.isHidden = false
        pauseButton.isHidden = false
        
        // Reset scores
        score1 = 0
        score2 = 0
        scoreLabel1.text = "0"
        scoreLabel2.text = "0"
        
        // Start game
        gameStarted = true
        startGame()
    }
    
    private func showWinner(player: Int) {
        // First remove any existing winner node to avoid conflicts
        winnerNode?.removeFromParent()
        
        // Set game as ended
        gameEnded = true
        isPausedNow = true
        
        // Pause the ball
        ball.physicsBody?.velocity = CGVector.zero
        ball.physicsBody?.isDynamic = false
        
        // Create a completely new winner overlay
        winnerNode = SKNode()
        
        // Background
        let winBackground = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.7), 
                                       size: CGSize(width: size.width, height: size.height))
        winBackground.position = CGPoint(x: size.width/2, y: size.height/2)
        winnerNode?.addChild(winBackground)
        
        // Winner text
        let winnerText = SKLabelNode(fontNamed: "Helvetica Neue Bold")
        winnerText.text = player == 1 ? "RED WINS!" : "BLUE WINS!"
        winnerText.fontSize = 48
        winnerText.fontColor = player == 1 ? .red : .blue
        winnerText.position = CGPoint(x: size.width/2, y: size.height * 0.6)
        winnerNode?.addChild(winnerText)
        
        // Play again button
        let playAgainButton = SKSpriteNode(color: .white, size: CGSize(width: 200, height: 60))
        playAgainButton.position = CGPoint(x: size.width/2, y: size.height * 0.35)
        playAgainButton.name = "playAgain"
        
        let playAgainLabel = SKLabelNode(fontNamed: "Helvetica Neue Bold")
        playAgainLabel.text = "PLAY AGAIN"
        playAgainLabel.fontSize = 24
        playAgainLabel.fontColor = .black
        playAgainLabel.verticalAlignmentMode = .center
        playAgainButton.addChild(playAgainLabel)
        
        winnerNode?.addChild(playAgainButton)
        
        // New game button
        let newGameButton = SKSpriteNode(color: .white, size: CGSize(width: 200, height: 60))
        newGameButton.position = CGPoint(x: size.width/2, y: size.height * 0.25)
        newGameButton.name = "newGame"
        
        let newGameLabel = SKLabelNode(fontNamed: "Helvetica Neue Bold")
        newGameLabel.text = "NEW GAME"
        newGameLabel.fontSize = 24
        newGameLabel.fontColor = .black
        newGameLabel.verticalAlignmentMode = .center
        newGameButton.addChild(newGameLabel)
        
        winnerNode?.addChild(newGameButton)
        
        // Add the winner node to the scene
        addChild(winnerNode!)
    }
    
    private func startGame() {
        // Reset ball position
        ball.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Choose a random direction that's more direct toward either paddle
        let steepAngleRange = CGFloat.pi/6...CGFloat.pi/3  // Steeper angle range (30-60 degrees)
        let randomAngle = CGFloat.random(in: steepAngleRange)
        
        // Randomly choose between top and bottom paddle
        let targetBottom = Bool.random()
        
        // If targeting bottom paddle, angle should be in 3rd or 4th quadrant (downward)
        // If targeting top paddle, angle should be in 1st or 2nd quadrant (upward)
        let angle: CGFloat
        if targetBottom {
            // Target bottom paddle (randomize between going left or right)
            angle = Bool.random() ? CGFloat.pi + randomAngle : CGFloat.pi * 2 - randomAngle
        } else {
            // Target top paddle (randomize between going left or right)
            angle = Bool.random() ? randomAngle : CGFloat.pi - randomAngle
        }
        
        // Set initial speed - slightly faster than before for more action
        let initialSpeed: CGFloat = 12.0
        let impulseVector = CGVector(dx: initialSpeed * cos(angle), dy: initialSpeed * sin(angle))
        
        ball.physicsBody?.velocity = CGVector.zero // Reset any existing velocity
        ball.physicsBody?.applyImpulse(impulseVector)
    }
    
    private func updateScore(player: Int) {
        if player == 1 {
            score1 += 1
            scoreLabel1.text = "\(score1)"
            
            // Check if player 1 has won
            if score1 >= targetScore {
                showWinner(player: 1)
                return
            }
            
            // Increase paddle width of the losing player (player 2)
            increasePlayerPaddleWidth(player: 2)
            
            // Add an obstacle
            addRandomObstacle()
        } else {
            score2 += 1
            scoreLabel2.text = "\(score2)"
            
            // Check if player 2 has won
            if score2 >= targetScore {
                showWinner(player: 2)
                return
            }
            
            // Increase paddle width of the losing player (player 1)
            increasePlayerPaddleWidth(player: 1)
            
            // Add an obstacle
            addRandomObstacle()
        }
        
        // Reset game for next round
        startGame()
    }
    
    private func increasePlayerPaddleWidth(player: Int) {
        // Get the paddle to increase
        let paddle = player == 1 ? paddle1 : paddle2
        
        // Calculate new width (40 more than current)
        let currentSize = paddle!.frame.size
        let newWidth = currentSize.width + 30
        let maxWidth = size.width * 0.6 // Set maximum width to 80% of screen width
        
        // Cap the width to maximum
        let clampedWidth = min(newWidth, maxWidth)
        
        // Remove the old paddle
        paddle!.removeFromParent()
        
        // Create a new paddle with the new width
        let newPaddle = SKShapeNode(rectOf: CGSize(width: clampedWidth, height: currentSize.height), cornerRadius: 5)
        newPaddle.fillColor = player == 1 ? .red : .blue
        newPaddle.strokeColor = .clear
        newPaddle.position = paddle!.position
        
        // Set up the physics body
        newPaddle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: clampedWidth, height: currentSize.height))
        newPaddle.physicsBody?.isDynamic = false
        newPaddle.physicsBody?.restitution = 1.0
        newPaddle.physicsBody?.friction = 0
        newPaddle.physicsBody?.categoryBitMask = paddleCategory
        newPaddle.physicsBody?.contactTestBitMask = ballCategory
        newPaddle.physicsBody?.collisionBitMask = ballCategory
        
        // Add to scene
        addChild(newPaddle)
        
        // Update the reference
        if player == 1 {
            paddle1 = newPaddle
        } else {
            paddle2 = newPaddle
        }
    }
    
    private func addRandomObstacle() {
        // Define the play area (middle section of the screen)
        let playAreaMinY = size.height * 0.3
        let playAreaMaxY = size.height * 0.7
        let playAreaWidth = size.width * 0.8
        let playAreaMinX = (size.width - playAreaWidth) / 2
        
        // Limit the maximum number of obstacles
        let maxObstacles = 5
        if obstacles.count >= maxObstacles {
            return // Already at maximum number of obstacles
        }
        
        // Choose obstacle size first
        let obstacleSize = CGFloat.random(in: 20...40)
        let radius = obstacleSize / 2
        
        // Try to find a non-overlapping position (max 20 attempts)
        var validPosition = false
        var randomX: CGFloat = 0
        var randomY: CGFloat = 0
        var attemptCount = 0
        let maxAttempts = 20
        
        while !validPosition && attemptCount < maxAttempts {
            // Random position within the play area
            randomX = CGFloat.random(in: (playAreaMinX + radius)...(playAreaMinX + playAreaWidth - radius))
            randomY = CGFloat.random(in: (playAreaMinY + radius)...(playAreaMaxY - radius))
            
            // Check if this position would overlap with any existing obstacle
            validPosition = true // Assume valid until proven otherwise
            
            for existingObstacle in obstacles {
                let existingPos = existingObstacle.position
                let existingRadius = max(existingObstacle.frame.width, existingObstacle.frame.height) / 2
                
                // Calculate distance between centers
                let distance = hypot(randomX - existingPos.x, randomY - existingPos.y)
                let minDistance = radius + existingRadius + 10 // Add 10 points of padding
                
                if distance < minDistance {
                    validPosition = false
                    break
                }
            }
            
            attemptCount += 1
        }
        
        // If we couldn't find a valid position after max attempts, don't add an obstacle
        if !validPosition {
            print("Could not find non-overlapping position for obstacle after \(maxAttempts) attempts")
            return
        }
        
        // Random shape type - updated to include hexagon (case 3)
        let shapeType = Int.random(in: 0...1)
        
        // Create the obstacle based on shape type
        let obstacle: SKNode
        
        switch shapeType {
 
        default:
            let path = CGMutablePath()
            
            // Create a proper hexagon with 6 sides
            let numberOfSides = 6
            let theta = 2.0 * CGFloat.pi / CGFloat(numberOfSides) // central angle
            
            // Start at the rightmost point (0 degrees)
            let firstPoint = CGPoint(x: radius, y: 0)
            path.move(to: firstPoint)
            
            // Add the other 5 points
            for i in 1..<numberOfSides {
                let angle = CGFloat(i) * theta
                let x = radius * cos(angle)
                let y = radius * sin(angle)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.closeSubpath()
            
            let hexagonObstacle = SKShapeNode(path: path)
            hexagonObstacle.fillColor = .cyan
            hexagonObstacle.strokeColor = .white
            hexagonObstacle.lineWidth = 2
            hexagonObstacle.position = CGPoint(x: randomX, y: randomY)
            
            // Physics body matches the polygon shape
            hexagonObstacle.physicsBody = SKPhysicsBody(polygonFrom: path)
            obstacle = hexagonObstacle
        }
        
        // Configure physics body properties
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.restitution = 1.0
        obstacle.physicsBody?.friction = 0
        obstacle.physicsBody?.categoryBitMask = wallCategory
        obstacle.physicsBody?.contactTestBitMask = ballCategory
        obstacle.physicsBody?.collisionBitMask = ballCategory
        
        // Add to scene and track in array
        addChild(obstacle)
        obstacles.append(obstacle)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Determine which bodies are the ball and the paddle
        let ballBody: SKPhysicsBody
        let paddleBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask == ballCategory {
            ballBody = contact.bodyA
            paddleBody = contact.bodyB
        } else if contact.bodyB.categoryBitMask == ballCategory {
            ballBody = contact.bodyB
            paddleBody = contact.bodyA
        } else {
            // Neither body is the ball
            return
        }
        
        // Only apply angle change if hitting a paddle
        if paddleBody.categoryBitMask == paddleCategory {
            guard let ball = ballBody.node as? SKShapeNode else { return }
            
            // Get current velocity
            let velocity = ballBody.velocity
            var dx = velocity.dx
            var dy = velocity.dy
            
            // Calculate current speed (magnitude of velocity)
            let currentSpeed = hypot(dx, dy)
            
            // Determine which paddle was hit
            let isPaddle1 = paddleBody.node == paddle1 || paddleBody.node?.parent == paddle1
            
            // Calculate distance from center of paddle for angle effect
            let paddle = isPaddle1 ? paddle1 : paddle2
            let hitPoint = contact.contactPoint
            let paddleWidth = paddle!.frame.width
            let paddleCenter = paddle!.position.x
            
            // Calculate offset from center (-1.0 to 1.0)
            let offset = (hitPoint.x - paddleCenter) / (paddleWidth * 0.5)
            
            // Apply angle based on hit position (the further from center, the steeper the angle)
            let angleInfluence: CGFloat = 5.0 // Adjust for more/less angle
            dx = velocity.dx + (offset * angleInfluence)
            
            // Ensure we're moving in the right vertical direction after hit
            if isPaddle1 {
                // Bottom paddle - ensure ball goes up
                dy = abs(dy)
            } else {
                // Top paddle - ensure ball goes down
                dy = -abs(dy)
            }
            
            // Calculate new direction as a normalized vector
            let magnitude = hypot(dx, dy)
            let normalizedDx = dx / magnitude
            let normalizedDy = dy / magnitude
            
            // Calculate new speed with 1.2x multiplier
            let newSpeed = currentSpeed * 1.2
            
            // Limit maximum speed to prevent the ball from moving too fast
            let maxSpeed: CGFloat = 2000.0
            let speedToApply = min(newSpeed, maxSpeed)
            
            // Apply the new velocity with increased speed
            let newVelocity = CGVector(
                dx: speedToApply * normalizedDx,
                dy: speedToApply * normalizedDy
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                ballBody.velocity = newVelocity
            }
            
      
            
            
            let removeAction = SKAction.sequence([
                SKAction.wait(forDuration: 0.2),
                SKAction.removeFromParent()
            ])
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Don't update if game is paused or ended
        if isPausedNow || gameEnded || !gameStarted {
            return
        }
        
        // Make sure ball stays within playable area
        if let ballPhysicsBody = ball.physicsBody {
            // Enforce minimum velocity to keep the game moving
            let minSpeed: CGFloat = 5.0
            let currentSpeed = hypot(ballPhysicsBody.velocity.dx, ballPhysicsBody.velocity.dy)
            
            if currentSpeed < minSpeed {
                let multiplier = minSpeed / currentSpeed
                ballPhysicsBody.velocity.dx *= multiplier
                ballPhysicsBody.velocity.dy *= multiplier
            }
            
            // Limit maximum velocity to keep game playable
            let maxSpeed: CGFloat = 10000.0
            if currentSpeed > maxSpeed {
                let multiplier = maxSpeed / currentSpeed
                ballPhysicsBody.velocity.dx *= multiplier
                ballPhysicsBody.velocity.dy *= multiplier
            }
        }
        
        // Check for scoring conditions - only if game is active
        if ball.position.y < 0 {
            updateScore(player: 2)
        } else if ball.position.y > size.height {
            updateScore(player: 1)
        }
    }
    
    // Helper function to find the paddle touched
    private func getPaddleForTouch(touch: UITouch) -> SKShapeNode? {
        let touchLocation = touch.location(in: self)
        let touchedNode = atPoint(touchLocation)
        
        if touchedNode == paddle1 || touchedNode.parent == paddle1 {
            return paddle1
        } else if touchedNode == paddle2 || touchedNode.parent == paddle2 {
            return paddle2
        }
        
        return nil
    }
    
    private func togglePause() {
        isPausedNow = !isPausedNow
        
        if isPausedNow {
            // Store current velocity
            ball.userData = NSMutableDictionary()
            if let velocity = ball.physicsBody?.velocity {
                ball.userData?.setValue(NSValue(cgVector: velocity), forKey: "velocity")
            }
            
            // Pause ball
            ball.physicsBody?.velocity = CGVector.zero
            ball.physicsBody?.isDynamic = false
            
            // Show pause overlay
            let pauseOverlay = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.5), 
                                          size: CGSize(width: size.width, height: size.height))
            pauseOverlay.position = CGPoint(x: size.width/2, y: size.height/2)
            pauseOverlay.zPosition = 90
            pauseOverlay.name = "pauseOverlay"
            
            let pauseText = SKLabelNode(fontNamed: "Helvetica Neue Bold")
            pauseText.text = "PAUSED"
            pauseText.fontSize = 48
            pauseText.fontColor = .white
            pauseText.verticalAlignmentMode = .center
            pauseOverlay.addChild(pauseText)
            
            addChild(pauseOverlay)
        } else {
            // Resume game
            ball.physicsBody?.isDynamic = true
            
            // Restore velocity
            if let storedVelocity = ball.userData?.value(forKey: "velocity") as? NSValue {
                ball.physicsBody?.velocity = storedVelocity.cgVectorValue
            }
            
            // Remove pause overlay
            childNode(withName: "pauseOverlay")?.removeFromParent()
        }
    }
}

// Touch handling for iOS
#if os(iOS) || os(tvOS)
extension GameScene {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let touchedNode = atPoint(touchLocation)
            
            // Handle menu button touches
            if let nodeName = touchedNode.name {
                if nodeName.starts(with: "score_"), let score = Int(nodeName.dropFirst(6)) {
                    startGameWithScore(score)
                    return
                } else if nodeName == "playAgain" {
                    // Show score selection screen again
                    winnerNode?.removeFromParent()
                    score1 = 0
                    score2 = 0
                    scoreLabel1.text = "0"
                    scoreLabel2.text = "0"
                    gameEnded = false
                    isPausedNow = false
                    ball.physicsBody?.isDynamic = true
                    gameStarted = false
                    showScoreSelectionMenu()
                    return
                } else if nodeName == "newGame" {
                    // Start a completely new game
                    winnerNode?.removeFromParent()
                    score1 = 0
                    score2 = 0
                    scoreLabel1.text = "0"
                    scoreLabel2.text = "0"
                    gameEnded = false
                    isPausedNow = false
                    ball.physicsBody?.isDynamic = true
                    gameStarted = false
                    showScoreSelectionMenu()
                    return
                }
            }
            
            // Check if pause button was tapped
            if touchedNode == pauseButton || touchedNode.parent == pauseButton {
                togglePause()
                return
            }
            
            // Don't process gameplay touches if game is paused or not started
            if isPausedNow || !gameStarted {
                return
            }
            
            // Determine which paddle to control based on screen position
            if touchLocation.y < size.height / 2 {
                activeTouches[touch] = paddle1
            } else {
                activeTouches[touch] = paddle2
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Don't process touches if game is paused
        if isPausedNow {
            return
        }
        
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            if let paddle = activeTouches[touch] {
                // Move the paddle horizontally
                paddle.position.x = touchLocation.x
                
                // Keep paddle within screen bounds
                paddle.position.x = max(paddle.frame.width / 2, min(size.width - paddle.frame.width / 2, paddle.position.x))
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            activeTouches.removeValue(forKey: touch)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        self.makeSpinny(at: event.location(in: self), color: SKColor.green)
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.blue)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.red)
    }

}
#endif

