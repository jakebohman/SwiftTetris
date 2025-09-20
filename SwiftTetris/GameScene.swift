import SpriteKit
import GameplayKit
import AVFoundation

// Constants
let columns = 10
let rows = 20
let blockSize: CGFloat = 32.0
let spawnRow = 21  // Spawn above visible area

// Game States
enum GameState {
    case menu
    case playing
    case paused
    case gameOver
}

// MARK: - Models

enum TileColor {
    case none
    case i, j, l, o, s, t, z

    var color: SKColor {
        switch self {
        case .none: return .clear
        case .i: return SKColor.cyan
        case .j: return SKColor.blue
        case .l: return SKColor.orange
        case .o: return SKColor.yellow
        case .s: return SKColor.green
        case .t: return SKColor.purple
        case .z: return SKColor.red
        }
    }
}

struct Point { var x: Int; var y: Int }

struct Tetromino {
    // Pre-defined rotation states: arrays of Point offsets from origin
    let kind: TileColor
    let rotations: [[Point]]  // 4 rotation states
    var rotationIndex: Int = 0
    var position: Point  // position of the tetromino origin on the board

    var blocks: [Point] {
        return rotations[rotationIndex]
    }

    mutating func rotateClockwise() { rotationIndex = (rotationIndex + 1) % rotations.count }
    mutating func rotateCounter() { rotationIndex = (rotationIndex - 1 + rotations.count) % rotations.count }
}

// MARK: - Tetromino factory (NES-like deterministic shapes)
func makeTetromino(kind: TileColor, spawnX: Int = columns/2 - 1) -> Tetromino {
    // Rotation definitions as relative coordinates (x,y). Origin chosen per shape.
    // Coordinates chosen so that positive y goes up.
    switch kind {
    case .i:
        return Tetromino(kind: .i,
            rotations: [
                [Point(x:-2,y:0),Point(x:-1,y:0),Point(x:0,y:0),Point(x:1,y:0)],
                [Point(x:0,y:-1),Point(x:0,y:0),Point(x:0,y:1),Point(x:0,y:2)],
                [Point(x:-2,y:1),Point(x:-1,y:1),Point(x:0,y:1),Point(x:1,y:1)],
                [Point(x:-1,y:-1),Point(x:-1,y:0),Point(x:-1,y:1),Point(x:-1,y:2)]
            ],
            rotationIndex: 0,
            position: Point(x: spawnX, y: spawnRow))
    case .j:
        return Tetromino(kind: .j,
            rotations: [
                [Point(x:-1,y:0),Point(x:0,y:0),Point(x:1,y:0),Point(x:-1,y:-1)],
                [Point(x:0,y:1),Point(x:0,y:0),Point(x:0,y:-1),Point(x:1,y:1)],
                [Point(x:-1,y:0),Point(x:0,y:0),Point(x:1,y:0),Point(x:1,y:1)],
                [Point(x:-1,y:-1),Point(x:0,y:1),Point(x:0,y:0),Point(x:0,y:-1)]
            ],
            rotationIndex: 0,
            position: Point(x: spawnX, y: spawnRow))
    case .l:
        return Tetromino(kind: .l,
            rotations: [
                [Point(x:-1,y:0),Point(x:0,y:0),Point(x:1,y:0),Point(x:1,y:1)],
                [Point(x:0,y:-1),Point(x:0,y:0),Point(x:0,y:1),Point(x:1,y:-1)],
                [Point(x:-1,y:-1),Point(x:-1,y:0),Point(x:0,y:0),Point(x:1,y:0)],
                [Point(x:-1,y:1),Point(x:0,y:-1),Point(x:0,y:0),Point(x:0,y:1)]
            ],
            rotationIndex: 0,
            position: Point(x: spawnX, y: spawnRow))
    case .o:
        return Tetromino(kind: .o,
            rotations: [
                [Point(x:0,y:0),Point(x:1,y:0),Point(x:0,y:1),Point(x:1,y:1)],
                [Point(x:0,y:0),Point(x:1,y:0),Point(x:0,y:1),Point(x:1,y:1)],
                [Point(x:0,y:0),Point(x:1,y:0),Point(x:0,y:1),Point(x:1,y:1)],
                [Point(x:0,y:0),Point(x:1,y:0),Point(x:0,y:1),Point(x:1,y:1)]
            ],
            rotationIndex: 0,
            position: Point(x: spawnX, y: spawnRow))
    case .s:
        return Tetromino(kind: .s,
            rotations: [
                [Point(x:0,y:0),Point(x:1,y:0),Point(x:-1,y:1),Point(x:0,y:1)],
                [Point(x:0,y:-1),Point(x:0,y:0),Point(x:1,y:0),Point(x:1,y:1)],
                [Point(x:0,y:0),Point(x:1,y:0),Point(x:-1,y:1),Point(x:0,y:1)],
                [Point(x:0,y:-1),Point(x:0,y:0),Point(x:1,y:0),Point(x:1,y:1)]
            ],
            rotationIndex: 0,
            position: Point(x: spawnX, y: spawnRow))
    case .t:
        return Tetromino(kind: .t,
            rotations: [
                [Point(x:-1,y:0),Point(x:0,y:0),Point(x:1,y:0),Point(x:0,y:1)],
                [Point(x:0,y:-1),Point(x:0,y:0),Point(x:0,y:1),Point(x:1,y:0)],
                [Point(x:-1,y:0),Point(x:0,y:0),Point(x:1,y:0),Point(x:0,y:-1)],
                [Point(x:-1,y:0),Point(x:0,y:-1),Point(x:0,y:0),Point(x:0,y:1)]
            ],
            rotationIndex: 0,
            position: Point(x: spawnX, y: spawnRow))
    case .z:
        return Tetromino(kind: .z,
            rotations: [
                [Point(x:-1,y:0),Point(x:0,y:0),Point(x:0,y:1),Point(x:1,y:1)],
                [Point(x:1,y:-1),Point(x:0,y:0),Point(x:1,y:0),Point(x:0,y:1)],
                [Point(x:-1,y:0),Point(x:0,y:0),Point(x:0,y:1),Point(x:1,y:1)],
                [Point(x:1,y:-1),Point(x:0,y:0),Point(x:1,y:0),Point(x:0,y:1)]
            ],
            rotationIndex: 0,
            position: Point(x: spawnX, y: spawnRow))
    case .none:
        fatalError("makeTetromino none")
    }
}

// MARK: - Board

class Board {
    private(set) var grid: [[TileColor]] = Array(
        repeating: Array(repeating: .none, count: rows),
        count: columns)

    func isEmpty(at x: Int, y: Int) -> Bool {
        guard x >= 0 && x < columns && y >= 0 && y < rows else { return false }
        return grid[x][y] == .none
    }

    func set(_ color: TileColor, at x: Int, y: Int) {
        guard x >= 0 && x < columns && y >= 0 && y < rows else { return }
        grid[x][y] = color
    }

    func clearLine(_ y: Int) {
        for x in 0..<columns {
            grid[x][y] = .none
        }
        // drop everything above down one
        for row in (y+1)..<rows {
            for x in 0..<columns {
                grid[x][row-1] = grid[x][row]
            }
        }
        // clear top row
        for x in 0..<columns { grid[x][rows-1] = .none }
    }

    func findFullLines() -> [Int] {
        var full: [Int] = []
        for y in 0..<rows {
            var isFull = true
            for x in 0..<columns {
                if grid[x][y] == .none { isFull = false; break }
            }
            if isFull { full.append(y) }
        }
        return full
    }
}

// MARK: - GameScene

class GameScene: SKScene {
    // Game State
    private var gameState: GameState = .menu
    
    // Game Components
    private let board = Board()
    private var current: Tetromino!
    private var nextKind: TileColor = .i
    private var holdPiece: TileColor? = nil
    private var canHold = true
    
    // Timing
    private var timer: TimeInterval = 0
    private var gravityInterval: TimeInterval = 1.0
    private var lockTimer: TimeInterval = 0
    private var lockDelay: TimeInterval = 0.5
    
    // Game Stats
    private var score = 0
    private var level = 1
    private var linesCleared = 0
    
    // Rendering
    private var boardNode: SKNode!
    private var uiNode: SKNode!
    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var linesLabel: SKLabelNode!
    private var nextPieceNode: SKNode!
    
    // Input
    private var lastTouchTime: TimeInterval = 0
    private var touchStartLocation: CGPoint = .zero
    
    // Button auto-repeat functionality
    private var leftButtonPressed = false
    private var rightButtonPressed = false
    private var downButtonPressed = false
    private var lastLeftRepeat: TimeInterval = 0
    private var lastRightRepeat: TimeInterval = 0
    private var lastDownRepeat: TimeInterval = 0
    private var buttonRepeatDelay: TimeInterval = 0.3 // Initial delay before repeating
    private var leftRightRepeatRate: TimeInterval = 0.15 // Repeat every 150ms for left/right
    private var downRepeatRate: TimeInterval = 0.05 // Repeat every 50ms for down (faster)
    
    // Random number generation
    private var rngSeed = 0xC0FFEE
    
    // Sound effects
    private var moveSoundAction: SKAction!
    private var rotateSoundAction: SKAction!
    private var lockSoundAction: SKAction!
    private var lineClearSoundAction: SKAction!
    private var gameOverSoundAction: SKAction!
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    // MARK: - Helper Functions
    
    func blendColor(_ color: SKColor, with blendColor: SKColor, fraction: CGFloat) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        blendColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return SKColor(
            red: r1 + (r2 - r1) * fraction,
            green: g1 + (g2 - g1) * fraction,
            blue: b1 + (b2 - b1) * fraction,
            alpha: a1
        )
    }

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor.black
        
        setupGameNodes()
        setupUI()
        setupSounds()
        showMainMenu()
    }

    // MARK: - Setup Methods
    
    func setupGameNodes() {
        boardNode = SKNode()
        boardNode.name = "board"
        addChild(boardNode)
        
        uiNode = SKNode()
        uiNode.name = "ui"
        addChild(uiNode)
        
        nextPieceNode = SKNode()
        nextPieceNode.name = "nextPiece"
        uiNode.addChild(nextPieceNode)
    }
    
    func setupUI() {
        // Board border
        let boardWidth = CGFloat(columns) * blockSize
        let boardHeight = CGFloat(rows) * blockSize
        let border = SKShapeNode(rect: CGRect(x: -boardWidth/2 - 2, y: -boardHeight/2 - 2, 
                                             width: boardWidth + 4, height: boardHeight + 4))
        border.strokeColor = .white
        border.lineWidth = 2
        border.fillColor = .clear
        boardNode.addChild(border)
        
        // Position UI elements with proper spacing
        let screenWidth = self.size.width
        let screenHeight = self.size.height
        
        // Score, Level, Lines UI - aligned with game area's left edge, moved down slightly
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: -boardWidth/2, y: boardHeight/2 + 60)
        scoreLabel.horizontalAlignmentMode = .left
        uiNode.addChild(scoreLabel)
        
        levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel.text = "LEVEL: 1"
        levelLabel.fontSize = 16
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: -boardWidth/2, y: boardHeight/2 + 35)
        levelLabel.horizontalAlignmentMode = .left
        uiNode.addChild(levelLabel)
        
        linesLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        linesLabel.text = "LINES: 0"
        linesLabel.fontSize = 16
        linesLabel.fontColor = .white
        linesLabel.position = CGPoint(x: -boardWidth/2, y: boardHeight/2 + 10)
        linesLabel.horizontalAlignmentMode = .left
        uiNode.addChild(linesLabel)
        
        // Larger Next piece container to include label and fit 4-wide tetromino
        // Position so right edge of box aligns with right edge of game area
        let nextContainer = SKNode()
        nextContainer.position = CGPoint(x: boardWidth/2 - 50, y: boardHeight/2 + 40)
        
        // "Next" label at the top of the box
        let nextLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nextLabel.text = "NEXT"
        nextLabel.fontSize = 14
        nextLabel.fontColor = .white
        nextLabel.verticalAlignmentMode = .center
        nextLabel.horizontalAlignmentMode = .center
        nextLabel.position = CGPoint(x: 0, y: 30)
        nextContainer.addChild(nextLabel)
        
        // Larger box to contain both label and 4-wide tetromino (I-piece)
        // Expand height to fully contain the label (fontSize 14 needs about 20px total)
        let nextBox = SKShapeNode(rect: CGRect(x: -50, y: -35, width: 100, height: 80))
        nextBox.strokeColor = .white
        nextBox.lineWidth = 2
        nextBox.fillColor = .clear
        nextContainer.addChild(nextBox)
        
        uiNode.addChild(nextContainer)
        
        // Position nextPieceNode inside the box area (below the label)
        nextPieceNode.position = CGPoint(x: boardWidth/2 - 50, y: boardHeight/2 + 25)
        
        // Add pause button - positioned at very top right, above Next box
        let pauseButton = SKLabelNode(fontNamed: "Helvetica-Bold")
        pauseButton.text = "PAUSE"
        pauseButton.fontSize = 16
        pauseButton.fontColor = .yellow
        pauseButton.position = CGPoint(x: screenWidth/2 - 30, y: boardHeight/2 + 100)
        pauseButton.horizontalAlignmentMode = .center
        pauseButton.name = "pauseButton"
        uiNode.addChild(pauseButton)
        
        // Add game controls
        setupGameControls()
    }
    
    func setupGameControls() {
        let screenWidth = self.size.width
        let screenHeight = self.size.height
        let boardHeight = CGFloat(rows) * blockSize
        
        // D-pad below the game area - moved higher so bottom button is visible
        let dpadSize: CGFloat = 60
        let dpadCenter = CGPoint(x: -screenWidth/4, y: -boardHeight/2 - 30)
        
        // Down button
        let downButton = createDpadButton(direction: "down")
        downButton.position = CGPoint(x: dpadCenter.x, y: dpadCenter.y - dpadSize)
        downButton.name = "downButton"
        uiNode.addChild(downButton)
        
        // Left and right buttons positioned so their bottom corners meet top corners of down button
        // Button size is 50, so top of down button is at downButton.position.y + 25
        // We want left/right bottoms at that level, so left/right centers should be 25 higher
        let leftRightY = downButton.position.y + 50 // Position so bottom corners touch top corners
        
        // Left button
        let leftButton = createDpadButton(direction: "left")
        leftButton.position = CGPoint(x: dpadCenter.x - dpadSize, y: leftRightY)
        leftButton.name = "leftButton"
        uiNode.addChild(leftButton)
        
        // Right button  
        let rightButton = createDpadButton(direction: "right")
        rightButton.position = CGPoint(x: dpadCenter.x + dpadSize, y: leftRightY)
        rightButton.name = "rightButton"
        uiNode.addChild(rightButton)
        
        // A and B buttons centered between game area bottom and screen bottom
        let gameAreaBottom = -boardHeight/2
        let screenBottom = -screenHeight/2
        let buttonCenter = CGPoint(x: screenWidth/4, y: (gameAreaBottom + screenBottom) / 2)
        
        // A button (rotate clockwise) - moderate spacing between original and current
        let aButton = createActionButton(letter: "A")
        aButton.position = CGPoint(x: buttonCenter.x + 50, y: buttonCenter.y)
        aButton.name = "aButton"
        uiNode.addChild(aButton)
        
        // B button (rotate counter-clockwise) - moderate spacing
        let bButton = createActionButton(letter: "B")
        bButton.position = CGPoint(x: buttonCenter.x - 50, y: buttonCenter.y)
        bButton.name = "bButton"
        uiNode.addChild(bButton)
    }
    
    func createDpadButton(direction: String) -> SKNode {
        let buttonNode = SKNode()
        
        // Black square with white outline - bigger size
        let size: CGFloat = 50
        let button = SKShapeNode(rect: CGRect(x: -size/2, y: -size/2, width: size, height: size))
        button.fillColor = .black
        button.strokeColor = .white
        button.lineWidth = 2
        buttonNode.addChild(button)
        
        // Create equilateral triangle arrows
        let triangleSize: CGFloat = 12
        let triangle: SKShapeNode
        
        switch direction {
        case "left":
            // Left-pointing equilateral triangle
            let leftPath = CGMutablePath()
            leftPath.move(to: CGPoint(x: -triangleSize, y: 0))
            leftPath.addLine(to: CGPoint(x: triangleSize/2, y: triangleSize * 0.866)) // sqrt(3)/2 for equilateral
            leftPath.addLine(to: CGPoint(x: triangleSize/2, y: -triangleSize * 0.866))
            leftPath.closeSubpath()
            triangle = SKShapeNode(path: leftPath)
            
        case "right":
            // Right-pointing equilateral triangle  
            let rightPath = CGMutablePath()
            rightPath.move(to: CGPoint(x: triangleSize, y: 0))
            rightPath.addLine(to: CGPoint(x: -triangleSize/2, y: triangleSize * 0.866))
            rightPath.addLine(to: CGPoint(x: -triangleSize/2, y: -triangleSize * 0.866))
            rightPath.closeSubpath()
            triangle = SKShapeNode(path: rightPath)
            
        case "down":
            // Down-pointing equilateral triangle
            let downPath = CGMutablePath()
            downPath.move(to: CGPoint(x: 0, y: -triangleSize))
            downPath.addLine(to: CGPoint(x: triangleSize * 0.866, y: triangleSize/2))
            downPath.addLine(to: CGPoint(x: -triangleSize * 0.866, y: triangleSize/2))
            downPath.closeSubpath()
            triangle = SKShapeNode(path: downPath)
            
        default:
            // Default case (shouldn't happen)
            triangle = SKShapeNode(circleOfRadius: triangleSize)
        }
        
        triangle.fillColor = .white
        triangle.strokeColor = .clear
        buttonNode.addChild(triangle)
        return buttonNode
    }
    
    func createActionButton(letter: String) -> SKNode {
        let buttonNode = SKNode()
        
        // White square background - bigger
        let squareSize: CGFloat = 70
        let square = SKShapeNode(rect: CGRect(x: -squareSize/2, y: -squareSize/2, width: squareSize, height: squareSize))
        square.fillColor = .white
        square.strokeColor = .white
        square.lineWidth = 1
        buttonNode.addChild(square)
        
        // Red circular button - bigger
        let circleRadius: CGFloat = 25
        let circle = SKShapeNode(circleOfRadius: circleRadius)
        circle.fillColor = .red
        circle.strokeColor = SKColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
        circle.lineWidth = 2
        buttonNode.addChild(circle)
        
        // White letter - bigger
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = letter
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        buttonNode.addChild(label)
        
        return buttonNode
    }
    
    func setupSounds() {
        // Create simple sound effects using system sounds
        // Note: In a real app, you'd want to add actual sound files
        moveSoundAction = SKAction.playSoundFileNamed("move.wav", waitForCompletion: false)
        rotateSoundAction = SKAction.playSoundFileNamed("rotate.wav", waitForCompletion: false)
        lockSoundAction = SKAction.playSoundFileNamed("lock.wav", waitForCompletion: false)
        lineClearSoundAction = SKAction.playSoundFileNamed("lineclear.wav", waitForCompletion: false)
        gameOverSoundAction = SKAction.playSoundFileNamed("gameover.wav", waitForCompletion: false)
        
        // For now, we'll use placeholder actions that don't crash if files don't exist
        moveSoundAction = SKAction.run { }
        rotateSoundAction = SKAction.run { }
        lockSoundAction = SKAction.run { }
        lineClearSoundAction = SKAction.run { }
        gameOverSoundAction = SKAction.run { }
    }
    
    func showMainMenu() {
        gameState = .menu
        
        let titleLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        titleLabel.text = "TETRIS"
        titleLabel.fontSize = 48
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 100)
        titleLabel.name = "title"
        addChild(titleLabel)
        
        let startLabel = SKLabelNode(fontNamed: "Helvetica")
        startLabel.text = "TAP TO START"
        startLabel.fontSize = 24
        startLabel.fontColor = .yellow
        startLabel.position = CGPoint(x: 0, y: 0)
        startLabel.name = "startLabel"
        addChild(startLabel)
        
        // Blinking animation
        let blink = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.5)
        ])
        startLabel.run(SKAction.repeatForever(blink))
    }
    
    func startGame() {
        gameState = .playing
        
        // Remove menu elements
        childNode(withName: "title")?.removeFromParent()
        childNode(withName: "startLabel")?.removeFromParent()
        
        // Initialize game
        score = 0
        level = 1
        linesCleared = 0
        gravityInterval = 1.0
        
        nextKind = pickKind()
        spawnRandomTetromino()
        drawBoard()
        updateUI()
        updateNextPiece()
    }
    
    // MARK: - Random Generation
    
    func nextRandom() -> Int {
        rngSeed = (1103515245 &* rngSeed &+ 12345) & 0x7fffffff
        return rngSeed
    }
    
    func pickKind() -> TileColor {
        let r = nextRandom() % 7
        switch r {
        case 0: return .i
        case 1: return .j
        case 2: return .l
        case 3: return .o
        case 4: return .s
        case 5: return .t
        default: return .z
        }
    }

    // MARK: - Game Logic
    
    func spawnRandomTetromino() {
        let kind = nextKind
        current = makeTetromino(kind: kind)
        nextKind = pickKind()
        canHold = true
        lockTimer = 0
        
        if !canPlace(tetromino: current) {
            // Check if there are blocks in the top rows (game over condition)
            if isGameOverCondition() {
                gameOver()
                return
            } else {
                // Try spawning higher up
                current.position.y += 2
                if !canPlace(tetromino: current) {
                    gameOver()
                    return
                }
            }
        }
        
        updateNextPiece()
    }
    
    func isGameOverCondition() -> Bool {
        // Game over if there are blocks in the top 2 rows of the visible area
        for x in 0..<columns {
            for y in (rows-2)..<rows {
                if board.grid[x][y] != .none {
                    return true
                }
            }
        }
        return false
    }

    func canPlace(tetromino: Tetromino) -> Bool {
        for p in tetromino.blocks {
            let x = tetromino.position.x + p.x
            let y = tetromino.position.y + p.y
            
            // Check horizontal bounds
            if x < 0 || x >= columns { return false }
            
            // Check bottom bound (can't go below y = 0)
            if y < 0 { return false }
            
            // Allow pieces to extend above the visible area (y >= rows)
            // Only check for collisions within the visible game board
            if y < rows && board.grid[x][y] != .none { return false }
        }
        return true
    }

    func lockCurrent() {
        guard gameState == .playing else { return }
        
        run(lockSoundAction)
        
        // Lock the piece and check if any blocks are above the game area
        var hasBlocksAboveBoard = false
        for p in current.blocks {
            let x = current.position.x + p.x
            let y = current.position.y + p.y
            
            // Check if this block is above the visible game area
            if y >= rows {
                hasBlocksAboveBoard = true
            }
            
            if x >= 0 && x < columns && y >= 0 && y < rows {
                board.set(current.kind, at: x, y: y)
            }
        }
        
        // Game over if a resting tetromino has any square above the game area
        if hasBlocksAboveBoard {
            gameOver()
            return
        }
        
        let clearedLines = handleLineClears()
        if clearedLines > 0 {
            run(lineClearSoundAction)
            
            // Special effect for Tetris (4 lines)
            if clearedLines == 4 {
                addTetrisEffect()
            }
            
            updateLevel()
        }
        
        spawnRandomTetromino()
        drawBoard()
        updateUI()
    }
    
    func updateLevel() {
        let newLevel = (linesCleared / 10) + 1
        if newLevel != level {
            level = newLevel
            // NES Tetris gravity frames: Level 0: 48, Level 1: 43, etc.
            gravityInterval = max(0.1, 1.0 - (Double(level - 1) * 0.1))
        }
    }

    func handleLineClears() -> Int {
        let full = board.findFullLines()
        guard !full.isEmpty else { return 0 }
        
        let count = full.count
        // NES scoring system
        switch count {
        case 1: score += 40 * level
        case 2: score += 100 * level
        case 3: score += 300 * level
        case 4: score += 1200 * level
        default: break
        }
        
        linesCleared += count
        
        // Animate line clearing
        animateLineClears(lines: full) {
            // Clear lines from bottom to top after animation
            for y in full.sorted() {
                self.board.clearLine(y)
            }
            self.drawBoard()
        }
        
        return count
    }
    
    func animateLineClears(lines: [Int], completion: @escaping () -> Void) {
        var flashNodes: [SKSpriteNode] = []
        
        // Create flash overlay for cleared lines
        for y in lines {
            for x in 0..<columns {
                let flash = SKSpriteNode(color: .white, size: CGSize(width: blockSize, height: blockSize))
                flash.position = pointFor(x: x, y: y)
                flash.alpha = 0.8
                boardNode.addChild(flash)
                flashNodes.append(flash)
            }
        }
        
        // Flash animation
        let flashAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ])
        
        for node in flashNodes {
            node.run(flashAction)
        }
        
        // Complete after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion()
        }
    }
    
    func addTetrisEffect() {
        // Create "TETRIS!" text effect
        let tetrisLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        tetrisLabel.text = "TETRIS!"
        tetrisLabel.fontSize = 32
        tetrisLabel.fontColor = .yellow
        tetrisLabel.position = CGPoint(x: 0, y: 0)
        addChild(tetrisLabel)
        
        // Animate the text
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.7)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([scaleUp, fadeOut, remove])
        
        tetrisLabel.run(sequence)
        
        // Add particle effect
        if let particles = SKEmitterNode(fileNamed: "TetrisParticles") {
            particles.position = CGPoint(x: 0, y: 0)
            addChild(particles)
            
            // Remove particles after animation
            let wait = SKAction.wait(forDuration: 2.0)
            let removeParticles = SKAction.removeFromParent()
            particles.run(SKAction.sequence([wait, removeParticles]))
        }
    }

    func gameOver() {
        gameState = .gameOver
        run(gameOverSoundAction)
        
        // Clear all tetrominos from the game area
        clearBoard()
        drawBoard()
        
        let gameOverLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 100)
        gameOverLabel.name = "gameOver"
        addChild(gameOverLabel)
        
        let finalScoreLabel = SKLabelNode(fontNamed: "Helvetica")
        finalScoreLabel.text = "FINAL SCORE: \(score)"
        finalScoreLabel.fontSize = 24
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: 0, y: 50)
        finalScoreLabel.name = "finalScore"
        addChild(finalScoreLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "Helvetica")
        restartLabel.text = "TAP TO RESTART"
        restartLabel.fontSize = 20
        restartLabel.fontColor = .yellow
        restartLabel.position = CGPoint(x: 0, y: -50)
        restartLabel.name = "restart"
        addChild(restartLabel)
        
        let blink = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.5)
        ])
        restartLabel.run(SKAction.repeatForever(blink))
    }
    
    func restartGame() {
        // Remove game over labels
        childNode(withName: "gameOver")?.removeFromParent()
        childNode(withName: "finalScore")?.removeFromParent()
        childNode(withName: "restart")?.removeFromParent()
        
        // Clear board
        for x in 0..<columns {
            for y in 0..<rows {
                board.set(.none, at: x, y: y)
            }
        }
        
        startGame()
    }
    
    func pauseGame() {
        gameState = .paused
        
        let pauseLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        pauseLabel.text = "PAUSED"
        pauseLabel.fontSize = 36
        pauseLabel.fontColor = .yellow
        pauseLabel.position = CGPoint(x: 0, y: 50)
        pauseLabel.name = "pauseLabel"
        addChild(pauseLabel)
        
        let resumeLabel = SKLabelNode(fontNamed: "Helvetica")
        resumeLabel.text = "TAP TO RESUME"
        resumeLabel.fontSize = 20
        resumeLabel.fontColor = .white
        resumeLabel.position = CGPoint(x: 0, y: 0)
        resumeLabel.name = "resumeLabel"
        addChild(resumeLabel)
        
        let blink = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.5)
        ])
        resumeLabel.run(SKAction.repeatForever(blink))
    }
    
    func resumeGame() {
        gameState = .playing
        
        childNode(withName: "pauseLabel")?.removeFromParent()
        childNode(withName: "resumeLabel")?.removeFromParent()
    }

    // MARK: - Rendering
    
    func pointFor(x: Int, y: Int) -> CGPoint {
        let boardWidth = CGFloat(columns) * blockSize
        let boardHeight = CGFloat(rows) * blockSize
        return CGPoint(
            x: CGFloat(x) * blockSize - boardWidth/2 + blockSize/2,
            y: CGFloat(y) * blockSize - boardHeight/2 + blockSize/2
        )
    }
    
    func clearBoard() {
        // Clear all pieces from the board grid
        for x in 0..<columns {
            for y in 0..<rows {
                board.set(.none, at: x, y: y)
            }
        }
    }
    
    func drawBoard() {
        // Only redraw what's necessary for better performance
        boardNode.enumerateChildNodes(withName: "tile") { node, _ in
            node.removeFromParent()
        }
        
        // Draw border (only once during setup)
        if boardNode.childNode(withName: "border") == nil {
            let boardWidth = CGFloat(columns) * blockSize
            let boardHeight = CGFloat(rows) * blockSize
            let border = SKShapeNode(rect: CGRect(x: -boardWidth/2 - 2, y: -boardHeight/2 - 2,
                                                 width: boardWidth + 4, height: boardHeight + 4))
            border.strokeColor = .white
            border.lineWidth = 2
            border.fillColor = .clear
            border.name = "border"
            boardNode.addChild(border)
            
            // Draw grid background (only once)
            for x in 0..<columns {
                for y in 0..<rows {
                    let gridTile = SKSpriteNode(color: SKColor.darkGray.withAlphaComponent(0.2),
                                              size: CGSize(width: blockSize-1, height: blockSize-1))
                    gridTile.position = pointFor(x: x, y: y)
                    gridTile.name = "grid"
                    boardNode.addChild(gridTile)
                }
            }
        }
        
        // Draw locked pieces
        for x in 0..<columns {
            for y in 0..<rows {
                let color = board.grid[x][y]
                if color != .none {
                    let tile = createBlock(color: color.color)
                    tile.position = pointFor(x: x, y: y)
                    tile.name = "tile"
                    boardNode.addChild(tile)
                }
            }
        }
        
        // Draw current piece
        if current != nil {
            drawCurrentPiece()
        }
    }
    
    func drawCurrentPiece() {
        boardNode.enumerateChildNodes(withName: "currentPiece") { node, _ in
            node.removeFromParent()
        }
        
        for p in current.blocks {
            let x = current.position.x + p.x
            let y = current.position.y + p.y
            guard x >= 0 && x < columns && y >= 0 && y < rows else { continue }
            
            let tile = createBlock(color: current.kind.color)
            tile.position = pointFor(x: x, y: y)
            tile.name = "currentPiece"
            boardNode.addChild(tile)
        }
    }
    
    func createBlock(color: SKColor) -> SKSpriteNode {
        let block = SKSpriteNode(color: color, size: CGSize(width: blockSize-2, height: blockSize-2))
        
        // Add top highlight for 3D effect
        let highlight = SKSpriteNode(color: blendColor(color, with: .white, fraction: 0.3),
                                   size: CGSize(width: blockSize-2, height: 3))
        highlight.position = CGPoint(x: 0, y: (blockSize-2)/2 - 1.5)
        block.addChild(highlight)
        
        // Add side shadow
        let shadow = SKSpriteNode(color: blendColor(color, with: .black, fraction: 0.3),
                                size: CGSize(width: 3, height: blockSize-2))
        shadow.position = CGPoint(x: (blockSize-2)/2 - 1.5, y: 0)
        block.addChild(shadow)
        
        // Add border
        let border = SKShapeNode(rect: CGRect(x: -blockSize/2 + 1, y: -blockSize/2 + 1,
                                            width: blockSize-2, height: blockSize-2))
        border.strokeColor = .white
        border.lineWidth = 0.5
        border.fillColor = .clear
        block.addChild(border)
        
        return block
    }
    
    func updateNextPiece() {
        nextPieceNode.removeAllChildren()
        
        let nextTetromino = makeTetromino(kind: nextKind)
        
        // Scale to fit box: 100px wide box should fit 4-wide I-piece perfectly
        // Leave some padding, so use 80px for 4 blocks = 20px per block
        let nextBlockSize: CGFloat = 20
        
        // Calculate bounds to center the piece horizontally
        let minX = nextTetromino.blocks.map { $0.x }.min() ?? 0
        let maxX = nextTetromino.blocks.map { $0.x }.max() ?? 0
        let pieceWidth = maxX - minX + 1
        let offsetX = -CGFloat(pieceWidth) * nextBlockSize / 2 + nextBlockSize / 2
        
        for p in nextTetromino.blocks {
            let tile = SKSpriteNode(color: nextKind.color, 
                                  size: CGSize(width: nextBlockSize, height: nextBlockSize))
            tile.position = CGPoint(x: CGFloat(p.x) * nextBlockSize + offsetX, 
                                  y: CGFloat(p.y) * nextBlockSize)
            nextPieceNode.addChild(tile)
        }
    }
    
    func updateUI() {
        scoreLabel.text = "SCORE: \(score)"
        levelLabel.text = "LEVEL: \(level)"
        linesLabel.text = "LINES: \(linesCleared)"
    }

    // MARK: - Movement and Controls
    
    func attemptMove(dx: Int, dy: Int) -> Bool {
        guard gameState == .playing else { return false }
        
        var moved = current!
        moved.position.x += dx
        moved.position.y += dy
        
        if canPlace(tetromino: moved) {
            current = moved
            drawCurrentPiece()
            
            // Play move sound for horizontal movement
            if dx != 0 {
                run(moveSoundAction)
            }
            
            // Reset lock timer if moving down succeeded
            if dy != 0 {
                lockTimer = 0
            }
            return true
        }
        
        // If moving down failed, start lock timer
        if dy < 0 {
            lockTimer = CACurrentMediaTime()
        }
        
        return false
    }
    
    func attemptRotate() -> Bool {
        guard gameState == .playing else { return false }
        
        var rotated = current!
        rotated.rotateClockwise()
        
        // Basic wall kick attempts
        let kickTests = [
            Point(x: 0, y: 0),   // No kick
            Point(x: -1, y: 0),  // Left kick
            Point(x: 1, y: 0),   // Right kick
            Point(x: 0, y: 1),   // Up kick
            Point(x: -1, y: 1),  // Left-up kick
            Point(x: 1, y: 1)    // Right-up kick
        ]
        
        for kick in kickTests {
            rotated.position.x = current.position.x + kick.x
            rotated.position.y = current.position.y + kick.y
            
            if canPlace(tetromino: rotated) {
                current = rotated
                drawCurrentPiece()
                run(rotateSoundAction)
                return true
            }
        }
        
        return false
    }
    
    func attemptRotateCounterClockwise() -> Bool {
        guard gameState == .playing else { return false }
        
        var rotated = current!
        rotated.rotateCounter()
        
        // Basic wall kick attempts
        let kickTests = [
            Point(x: 0, y: 0),   // No kick
            Point(x: -1, y: 0),  // Left kick
            Point(x: 1, y: 0),   // Right kick
            Point(x: 0, y: 1),   // Up kick
            Point(x: -1, y: 1),  // Left-up kick
            Point(x: 1, y: 1)    // Right-up kick
        ]
        
        for kick in kickTests {
            rotated.position.x = current.position.x + kick.x
            rotated.position.y = current.position.y + kick.y
            
            if canPlace(tetromino: rotated) {
                current = rotated
                drawCurrentPiece()
                run(rotateSoundAction)
                return true
            }
        }
        
        return false
    }
    
    func hardDrop() {
        guard gameState == .playing else { return }
        
        var dropDistance = 0
        while attemptMove(dx: 0, dy: -1) {
            dropDistance += 1
        }
        
        // Add points for hard drop
        score += dropDistance * 2
        
        lockCurrent()
    }

    // MARK: - Touch Input
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchStartLocation = location
        lastTouchTime = CACurrentMediaTime()
        
        switch gameState {
        case .menu:
            startGame()
        case .gameOver:
            restartGame()
        case .playing:
            // Check if tap is on any control button
            if handleControlInput(location) {
                return
            } else {
                handleGameTouch(location)
            }
        case .paused:
            resumeGame()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let duration = CACurrentMediaTime() - lastTouchTime
        
        // Reset button states when touch ends
        resetButtonStates()
        
        if gameState == .playing {
            handleTouchGesture(start: touchStartLocation, end: location, duration: duration)
        }
    }
    
    func resetButtonStates() {
        leftButtonPressed = false
        rightButtonPressed = false
        downButtonPressed = false
    }
    
    func handleButtonAutoRepeat(currentTime: TimeInterval) {
        // Left button auto-repeat
        if leftButtonPressed && (currentTime - lastLeftRepeat) > buttonRepeatDelay {
            if (currentTime - lastLeftRepeat) > (buttonRepeatDelay + leftRightRepeatRate) {
                let success = attemptMove(dx: -1, dy: 0)
                if success {
                    lastLeftRepeat = currentTime - buttonRepeatDelay // Adjust for consistent timing
                } else {
                    // If move failed (piece is blocked), stop auto-repeat for left
                    leftButtonPressed = false
                }
            }
        }
        
        // Right button auto-repeat
        if rightButtonPressed && (currentTime - lastRightRepeat) > buttonRepeatDelay {
            if (currentTime - lastRightRepeat) > (buttonRepeatDelay + leftRightRepeatRate) {
                let success = attemptMove(dx: 1, dy: 0)
                if success {
                    lastRightRepeat = currentTime - buttonRepeatDelay
                } else {
                    // If move failed (piece is blocked), stop auto-repeat for right
                    rightButtonPressed = false
                }
            }
        }
        
        // Down button auto-repeat (faster)
        if downButtonPressed && (currentTime - lastDownRepeat) > buttonRepeatDelay {
            if (currentTime - lastDownRepeat) > (buttonRepeatDelay + downRepeatRate) {
                let success = attemptMove(dx: 0, dy: -1)
                if success {
                    lastDownRepeat = currentTime - buttonRepeatDelay
                } else {
                    // If move failed (piece is blocked), stop auto-repeat for down
                    downButtonPressed = false
                }
            }
        }
    }
    
    func handleControlInput(_ location: CGPoint) -> Bool {
        // Check pause button
        let pauseButton = uiNode.childNode(withName: "pauseButton")
        if let button = pauseButton, button.contains(location) {
            pauseGame()
            return true
        }
        
        // Check D-pad buttons with auto-repeat tracking
        if let leftButton = uiNode.childNode(withName: "leftButton"), leftButton.contains(location) {
            if !leftButtonPressed {
                leftButtonPressed = true
                lastLeftRepeat = CACurrentMediaTime()
                _ = attemptMove(dx: -1, dy: 0)
            }
            return true
        }
        if let rightButton = uiNode.childNode(withName: "rightButton"), rightButton.contains(location) {
            if !rightButtonPressed {
                rightButtonPressed = true
                lastRightRepeat = CACurrentMediaTime()
                _ = attemptMove(dx: 1, dy: 0)
            }
            return true
        }
        if let downButton = uiNode.childNode(withName: "downButton"), downButton.contains(location) {
            if !downButtonPressed {
                downButtonPressed = true
                lastDownRepeat = CACurrentMediaTime()
                _ = attemptMove(dx: 0, dy: -1)
            }
            return true
        }
        
        // Check action buttons
        if let aButton = uiNode.childNode(withName: "aButton"), aButton.contains(location) {
            _ = attemptRotate()
            return true
        }
        if let bButton = uiNode.childNode(withName: "bButton"), bButton.contains(location) {
            _ = attemptRotateCounterClockwise()
            return true
        }
        
        return false
    }
    
    func handleGameTouch(_ location: CGPoint) {
        // Only handle game touches if they're inside the game area
        if !isLocationInGameArea(location) {
            return
        }
        
        // Quick tap for rotation (fallback if not using buttons)
        if abs(location.x - touchStartLocation.x) < 20 && abs(location.y - touchStartLocation.y) < 20 {
            // This will be handled in touchesEnded if it's a quick tap
            return
        }
    }
    
    func isLocationInGameArea(_ location: CGPoint) -> Bool {
        let boardWidth = CGFloat(columns) * blockSize
        let boardHeight = CGFloat(rows) * blockSize
        let gameAreaLeft = -boardWidth/2
        let gameAreaRight = boardWidth/2
        let gameAreaTop = boardHeight/2
        let gameAreaBottom = -boardHeight/2
        
        return location.x >= gameAreaLeft && location.x <= gameAreaRight &&
               location.y >= gameAreaBottom && location.y <= gameAreaTop
    }
    
    func handleTouchGesture(start: CGPoint, end: CGPoint, duration: TimeInterval) {
        // Only handle gesture if it started in the game area
        if !isLocationInGameArea(start) {
            return
        }
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = sqrt(dx*dx + dy*dy)
        
        // Quick tap = rotate
        if duration < 0.3 && distance < 30 {
            _ = attemptRotate()
            return
        }
        
        // Swipe gestures
        if distance > 50 {
            if abs(dx) > abs(dy) {
                // Horizontal swipe
                if dx > 0 {
                    _ = attemptMove(dx: 1, dy: 0)
                } else {
                    _ = attemptMove(dx: -1, dy: 0)
                }
            } else {
                // Vertical swipe
                if dy < 0 {
                    // Swipe down = hard drop
                    hardDrop()
                } else {
                    // Swipe up = rotate (alternative)
                    _ = attemptRotate()
                }
            }
        }
        
        // Long press = soft drop
        if duration > 0.5 {
            _ = attemptMove(dx: 0, dy: -1)
        }
    }

    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing else { return }
        
        // Initialize timer
        if timer == 0 { 
            timer = currentTime 
        }
        
        // Gravity - piece falls automatically
        let dt = currentTime - timer
        if dt >= gravityInterval {
            timer = currentTime
            
            if !attemptMove(dx: 0, dy: -1) {
                // Piece can't fall, start lock delay
                if lockTimer == 0 {
                    lockTimer = currentTime
                }
            }
        }
        
        // Handle button auto-repeat
        handleButtonAutoRepeat(currentTime: currentTime)
        
        // Lock delay - give player time to move/rotate before locking
        if lockTimer > 0 && currentTime - lockTimer >= lockDelay {
            lockCurrent()
        }
    }
}