//
//  GameViewController.swift
//  ShuffleBoard iOS
//
//  Created by Jonathan Strømsted on 05/05/2025.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and configure the scene
        let scene = GameScene.newGameScene()
        
        // Configure the view
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        // Set up view properties
        skView.ignoresSiblingOrder = true
        
        // Debug options - can be removed for release
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = false // Set to true to visualize physics bodies
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait // Lock to portrait for phone
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
