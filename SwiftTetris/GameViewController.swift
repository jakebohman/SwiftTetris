import UIKit
import SpriteKit
import GameplayKit

// GameViewController sets up and presents the main game scene
class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            let scene = GameScene()
            scene.size = view.bounds.size
            scene.scaleMode = .aspectFill
            
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
