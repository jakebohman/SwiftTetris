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

// Tetromino factory
func makeTetromino(kind: TileColor, spawnX: Int = columns/2 - 1) -> Tetromino {
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
        for row in (y+1)..<rows {
            for x in 0..<columns {
                grid[x][row-1] = grid[x][row]
            }
        }
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
    private var level = 0
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
    
    // Button auto-repeat
    private var leftButtonPressed = false
    private var rightButtonPressed = false
    private var downButtonPressed = false
    private var lastLeftRepeat: TimeInterval = 0
    private var lastRightRepeat: TimeInterval = 0
    private var lastDownRepeat: TimeInterval = 0
    private var buttonRepeatDelay: TimeInterval = 0.3
    private var leftRightRepeatRate: TimeInterval = 0.15
    private var downRepeatRate: TimeInterval = 0.05
    
    // Random number generation
    private var rngSeed = 0xC0FFEE
    
    // Sound effects - Not impelemented
    private var moveSoundAction: SKAction!
    private var rotateSoundAction: SKAction!
    private var lockSoundAction: SKAction!
    private var lineClearSoundAction: SKAction!
    private var gameOverSoundAction: SKAction!
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    // Blend colors for shading of blocks
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

    // Set up the scene
    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor.black
        
        setupRetroBackground()
        setupGameNodes()
        setupUI()
        setupSounds()
        showMainMenu()
    }

    // Sets up the main game nodes
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
    
    // Sets up the retro-style background with grid and decorative tetromino shapes
    func setupRetroBackground() {
        let screenWidth = self.size.width
        let screenHeight = self.size.height
        
        // Create background node
        let retroBackgroundNode = SKNode()
        retroBackgroundNode.name = "retroBackground"
        retroBackgroundNode.zPosition = -20
        addChild(retroBackgroundNode)
        
        // Dark background
        let darkBackground = SKShapeNode(rect: CGRect(x: -screenWidth/2, y: -screenHeight/2, width: screenWidth, height: screenHeight))
        darkBackground.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1.0) // #1A1A2E
        darkBackground.strokeColor = .clear
        darkBackground.zPosition = -20
        retroBackgroundNode.addChild(darkBackground)
        
        // Add grid pattern
        createRetroGrid(in: retroBackgroundNode, width: screenWidth, height: screenHeight)
        
        // Add decorative tetromino shapes
        createDecorativeTetrominoes(in: retroBackgroundNode, width: screenWidth, height: screenHeight)
    }
    
    // Creates the grid pattern for the retro background
    func createRetroGrid(in parent: SKNode, width: CGFloat, height: CGFloat) {
        let gridColor = SKColor(red: 0.086, green: 0.129, blue: 0.243, alpha: 0.3) // #16213E with alpha
        let cellSize: CGFloat = 40.0
        
        // Vertical lines
        var x: CGFloat = -width/2
        while x <= width/2 {
            let verticalLine = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: -height/2))
            path.addLine(to: CGPoint(x: x, y: height/2))
            verticalLine.path = path
            verticalLine.strokeColor = gridColor
            verticalLine.lineWidth = 1.0
            verticalLine.zPosition = -19
            parent.addChild(verticalLine)
            x += cellSize
        }
        
        // Horizontal lines
        var y: CGFloat = -height/2
        while y <= height/2 {
            let horizontalLine = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -width/2, y: y))
            path.addLine(to: CGPoint(x: width/2, y: y))
            horizontalLine.path = path
            horizontalLine.strokeColor = gridColor
            horizontalLine.lineWidth = 1.0
            horizontalLine.zPosition = -19
            parent.addChild(horizontalLine)
            y += cellSize
        }
    }
    
    // Creates decorative tetromino shapes scattered on the background
    func createDecorativeTetrominoes(in parent: SKNode, width: CGFloat, height: CGFloat) {
        let blockSize: CGFloat = 20.0
        let alpha: CGFloat = 0.15
        
        // Tetromino colors with low alpha
        let tetrominoColors = [
            SKColor.cyan.withAlphaComponent(alpha),     // I piece
            SKColor.yellow.withAlphaComponent(alpha),   // O piece  
            SKColor.purple.withAlphaComponent(alpha),   // T piece
            SKColor.green.withAlphaComponent(alpha),    // S piece
            SKColor.red.withAlphaComponent(alpha),      // Z piece
            SKColor.blue.withAlphaComponent(alpha),     // J piece
            SKColor.orange.withAlphaComponent(alpha)    // L piece
        ]
        
        // Calculate edge zones
        let edgeMargin = width * 0.15 // 15% from each edge
        
        // Left edge positions - defining tetromino shapes
        let leftPositions = [
            // I piece on left edge (horizontal)
            [CGPoint(x: -width/2 + 20, y: height * 0.1), 
             CGPoint(x: -width/2 + 40, y: height * 0.1), 
             CGPoint(x: -width/2 + 60, y: height * 0.1), 
             CGPoint(x: -width/2 + 80, y: height * 0.1)],
            
            // O piece on left edge
            [CGPoint(x: -width/2 + 30, y: height * 0.25), 
             CGPoint(x: -width/2 + 50, y: height * 0.25),
             CGPoint(x: -width/2 + 30, y: height * 0.25 + 20), 
             CGPoint(x: -width/2 + 50, y: height * 0.25 + 20)],
            
            // T piece on left edge
            [CGPoint(x: -width/2 + 60, y: height * 0.4),
             CGPoint(x: -width/2 + 40, y: height * 0.4 + 20), 
             CGPoint(x: -width/2 + 60, y: height * 0.4 + 20), 
             CGPoint(x: -width/2 + 80, y: height * 0.4 + 20)],
            
            // S piece on left edge
            [CGPoint(x: -width/2 + 20, y: height * 0.6), 
             CGPoint(x: -width/2 + 40, y: height * 0.6),
             CGPoint(x: -width/2 + 40, y: height * 0.6 + 20), 
             CGPoint(x: -width/2 + 60, y: height * 0.6 + 20)],
            
            // L piece on left edge
            [CGPoint(x: -width/2 + 30, y: height * 0.8), 
             CGPoint(x: -width/2 + 30, y: height * 0.8 + 20),
             CGPoint(x: -width/2 + 30, y: height * 0.8 + 40), 
             CGPoint(x: -width/2 + 50, y: height * 0.8 + 40)]
        ]
        
        // Right edge positions
        let rightPositions = [
            // I piece on right edge (horizontal)
            [CGPoint(x: width/2 - 100, y: height * 0.15), 
             CGPoint(x: width/2 - 80, y: height * 0.15),
             CGPoint(x: width/2 - 60, y: height * 0.15), 
             CGPoint(x: width/2 - 40, y: height * 0.15)],
            
            // O piece on right edge
            [CGPoint(x: width/2 - 70, y: height * 0.3), 
             CGPoint(x: width/2 - 50, y: height * 0.3),
             CGPoint(x: width/2 - 70, y: height * 0.3 + 20), 
             CGPoint(x: width/2 - 50, y: height * 0.3 + 20)],
            
            // T piece on right edge
            [CGPoint(x: width/2 - 60, y: height * 0.45),
             CGPoint(x: width/2 - 80, y: height * 0.45 + 20), 
             CGPoint(x: width/2 - 60, y: height * 0.45 + 20), 
             CGPoint(x: width/2 - 40, y: height * 0.45 + 20)],
            
            // Z piece on right edge
            [CGPoint(x: width/2 - 80, y: height * 0.65), 
             CGPoint(x: width/2 - 60, y: height * 0.65),
             CGPoint(x: width/2 - 60, y: height * 0.65 + 20), 
             CGPoint(x: width/2 - 40, y: height * 0.65 + 20)],
            
            // J piece on right edge
            [CGPoint(x: width/2 - 50, y: height * 0.85), 
             CGPoint(x: width/2 - 70, y: height * 0.85 + 20),
             CGPoint(x: width/2 - 50, y: height * 0.85 + 20), 
             CGPoint(x: width/2 - 30, y: height * 0.85 + 20)]
        ]
        
        let allPositions = leftPositions + rightPositions
        
        // Draw the tetromino shapes
        for (shapeIndex, positions) in allPositions.enumerated() {
            let color = tetrominoColors[shapeIndex % tetrominoColors.count]
            
            for position in positions {
                // Check bounds
                if position.x >= -width/2 && position.y >= -height/2 && 
                   position.x < width/2 - blockSize && position.y < height/2 - blockSize {
                    
                    let block = SKShapeNode(rect: CGRect(x: 0, y: 0, width: blockSize, height: blockSize))
                    block.fillColor = color
                    block.strokeColor = .clear
                    block.position = position
                    block.zPosition = -18
                    parent.addChild(block)
                }
            }
        }
    }
    
    // Sets up the UI elements and NES controller background
    func setupUI() {
        let screenWidth = self.size.width
        let screenHeight = self.size.height
        let boardWidth = CGFloat(columns) * blockSize
        let boardHeight = CGFloat(rows) * blockSize
        
        // Add NES controller-style background covering entire bottom area
        let controllerTop = -boardHeight/2 - 10
        let originalHeight = controllerTop - (-screenHeight/2)
        let controllerHeight = originalHeight * 2
        
        // Main controller body
        let controllerBackground = SKShapeNode(rect: CGRect(x: -screenWidth/2, y: -screenHeight/2, width: screenWidth, height: controllerHeight))
        controllerBackground.fillColor = SKColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1.0)
        controllerBackground.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        controllerBackground.lineWidth = 3
        controllerBackground.zPosition = -15
        addChild(controllerBackground)
        
        // Add highlight on top edge of controller
        let actualControllerTop = -screenHeight/2 + controllerHeight
        let controllerHighlight = SKShapeNode(rect: CGRect(x: -screenWidth/2, y: actualControllerTop - 4, width: screenWidth, height: 4))
        controllerHighlight.fillColor = SKColor(red: 0.85, green: 0.85, blue: 0.9, alpha: 1.0)
        controllerHighlight.strokeColor = .clear
        controllerHighlight.zPosition = -14
        addChild(controllerHighlight)
        
        // Add subtle shadow on bottom edge
        let controllerShadow = SKShapeNode(rect: CGRect(x: -screenWidth/2, y: -screenHeight/2, width: screenWidth, height: 4))
        controllerShadow.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0)
        controllerShadow.strokeColor = .clear
        controllerShadow.zPosition = -14
        addChild(controllerShadow)
        
        // Add Nintendo branding on controller
        let nintendoLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nintendoLabel.text = "Nintendo"
        nintendoLabel.fontSize = 18
        nintendoLabel.fontColor = .red
        nintendoLabel.position = CGPoint(x: screenWidth/2 - 10, y: actualControllerTop - 25) // Moved slightly right to show "endo"
        nintendoLabel.horizontalAlignmentMode = .right
        nintendoLabel.zPosition = -13
        addChild(nintendoLabel)
        
        // Game area background - semi-transparent dark overlay
        let gameAreaBackground = SKShapeNode(rect: CGRect(x: -boardWidth/2 - 2, y: -boardHeight/2 - 2, width: boardWidth + 4, height: boardHeight + 4))
        gameAreaBackground.strokeColor = .clear
        gameAreaBackground.fillColor = SKColor.black.withAlphaComponent(0.7) // Semi-transparent to show retro background
        gameAreaBackground.zPosition = -1
        boardNode.addChild(gameAreaBackground)
        
        // Board border
        let border = SKShapeNode(rect: CGRect(x: -boardWidth/2 - 2, y: -boardHeight/2 - 2, width: boardWidth + 4, height: boardHeight + 4))
        border.strokeColor = .white
        border.lineWidth = 2
        border.fillColor = .clear
        border.zPosition = 0
        boardNode.addChild(border)
        
        // Ensure game area nodes are above controller
        boardNode.zPosition = 0
        uiNode.zPosition = 1
        
        // Score, Level, Lines UI
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: -boardWidth/2, y: boardHeight/2 + 55)
        scoreLabel.horizontalAlignmentMode = .left
        uiNode.addChild(scoreLabel)
        
        levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel.text = "LEVEL: 00"
        levelLabel.fontSize = 16
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: -boardWidth/2, y: boardHeight/2 + 30)
        levelLabel.horizontalAlignmentMode = .left
        uiNode.addChild(levelLabel)
        
        linesLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        linesLabel.text = "LINES: 0"
        linesLabel.fontSize = 16
        linesLabel.fontColor = .white
        linesLabel.position = CGPoint(x: -boardWidth/2, y: boardHeight/2 + 5)
        linesLabel.horizontalAlignmentMode = .left
        uiNode.addChild(linesLabel)
        
        // Score area box
        let scoreBoxLeft = -boardWidth/2 - 2
        let scoreBoxRight = boardWidth/2 - 49 - 50
        let scoreBoxWidth = scoreBoxRight - scoreBoxLeft
        let scoreBox = SKShapeNode(rect: CGRect(x: scoreBoxLeft, y: -35, width: scoreBoxWidth, height: 80))
        scoreBox.strokeColor = .white
        scoreBox.lineWidth = 2
        scoreBox.fillColor = .clear
        scoreBox.position = CGPoint(x: 0, y: boardHeight/2 + 35)
        uiNode.addChild(scoreBox)
        
        // Next piece container
        let nextContainer = SKNode()
        nextContainer.position = CGPoint(x: boardWidth/2 - 49, y: boardHeight/2 + 35)
        
        // "Next" label
        let nextLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nextLabel.text = "NEXT"
        nextLabel.fontSize = 14
        nextLabel.fontColor = .white
        nextLabel.verticalAlignmentMode = .center
        nextLabel.horizontalAlignmentMode = .center
        nextLabel.position = CGPoint(x: 0, y: 30)
        nextContainer.addChild(nextLabel)
        
        // Next piece box
        let nextBox = SKShapeNode(rect: CGRect(x: -50, y: -35, width: 100, height: 80))
        nextBox.strokeColor = .white
        nextBox.lineWidth = 2
        nextBox.fillColor = .clear
        nextContainer.addChild(nextBox)
        
        uiNode.addChild(nextContainer)
        
        // Position nextPieceNode inside the box area
        nextPieceNode.position = CGPoint(x: boardWidth/2 - 49, y: boardHeight/2 + 20)
        
        // Add pause button
        let pauseButton = createPauseButton()
        pauseButton.position = CGPoint(x: screenWidth/2 - 50, y: boardHeight/2 + 100)
        pauseButton.name = "pauseButton"
        uiNode.addChild(pauseButton)
        
        setupGameControls()
    }
    
    // Game controls- supports both buttons and swipe gestures
    func setupGameControls() {
        let screenWidth = self.size.width
        let screenHeight = self.size.height
        let boardHeight = CGFloat(rows) * blockSize
        
        // Create NES-style D-pad with cross shape and white border
        let dpadCenter = CGPoint(x: -screenWidth/4, y: -(boardHeight + screenHeight) / 4 + 25)
        let dpadCrossBackground = createDpadCross()
        dpadCrossBackground.position = dpadCenter
        dpadCrossBackground.zPosition = -10
        uiNode.addChild(dpadCrossBackground)
        let dpadOffset: CGFloat = 50
        
        // Up button
        let upButton = createDpadButton(direction: "up")
        upButton.position = CGPoint(x: dpadCenter.x, y: dpadCenter.y + dpadOffset)
        upButton.name = "upButton"
        upButton.zPosition = -9
        uiNode.addChild(upButton)
        
        // Down button
        let downButton = createDpadButton(direction: "down")
        downButton.position = CGPoint(x: dpadCenter.x, y: dpadCenter.y - dpadOffset)
        downButton.name = "downButton"
        uiNode.addChild(downButton)
        
        // Left button
        let leftButton = createDpadButton(direction: "left")
        leftButton.position = CGPoint(x: dpadCenter.x - dpadOffset, y: dpadCenter.y)
        leftButton.name = "leftButton"
        uiNode.addChild(leftButton)
        
        // Right button
        let rightButton = createDpadButton(direction: "right")
        rightButton.position = CGPoint(x: dpadCenter.x + dpadOffset, y: dpadCenter.y)
        rightButton.name = "rightButton"
        uiNode.addChild(rightButton)
        
        // Align buttons
        let leftRightY = dpadCenter.y
        let buttonCenter = CGPoint(x: screenWidth/4, y: leftRightY - 10)
        
        // A button
        let aButton = createActionButton(letter: "A")
        aButton.position = CGPoint(x: buttonCenter.x + 50, y: buttonCenter.y)
        aButton.name = "aButton"
        uiNode.addChild(aButton)
        
        // B button
        let bButton = createActionButton(letter: "B")
        bButton.position = CGPoint(x: buttonCenter.x - 50, y: buttonCenter.y)
        bButton.name = "bButton"
        uiNode.addChild(bButton)
    }
    
    func createDpadButton(direction: String) -> SKNode {
        let buttonNode = SKNode()
        let triangleSize: CGFloat = 18
        let triangle: SKShapeNode
        
        switch direction {
        case "up":
            let upPath = CGMutablePath()
            upPath.move(to: CGPoint(x: 0, y: triangleSize))
            upPath.addLine(to: CGPoint(x: triangleSize * 0.866, y: -triangleSize/2))
            upPath.addLine(to: CGPoint(x: -triangleSize * 0.866, y: -triangleSize/2))
            upPath.closeSubpath()
            triangle = SKShapeNode(path: upPath)
            
        case "left":
            let leftPath = CGMutablePath()
            leftPath.move(to: CGPoint(x: -triangleSize, y: 0))
            leftPath.addLine(to: CGPoint(x: triangleSize/2, y: triangleSize * 0.866)) // sqrt(3)/2 for equilateral
            leftPath.addLine(to: CGPoint(x: triangleSize/2, y: -triangleSize * 0.866))
            leftPath.closeSubpath()
            triangle = SKShapeNode(path: leftPath)
            
        case "right":
            let rightPath = CGMutablePath()
            rightPath.move(to: CGPoint(x: triangleSize, y: 0))
            rightPath.addLine(to: CGPoint(x: -triangleSize/2, y: triangleSize * 0.866))
            rightPath.addLine(to: CGPoint(x: -triangleSize/2, y: -triangleSize * 0.866))
            rightPath.closeSubpath()
            triangle = SKShapeNode(path: rightPath)
            
        case "down":
            let downPath = CGMutablePath()
            downPath.move(to: CGPoint(x: 0, y: -triangleSize))
            downPath.addLine(to: CGPoint(x: triangleSize * 0.866, y: triangleSize/2))
            downPath.addLine(to: CGPoint(x: -triangleSize * 0.866, y: triangleSize/2))
            downPath.closeSubpath()
            triangle = SKShapeNode(path: downPath)
            
        default:
            triangle = SKShapeNode(circleOfRadius: triangleSize)
        }
        
        triangle.fillColor = SKColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0)
        triangle.strokeColor = .clear
        buttonNode.addChild(triangle)
        return buttonNode
    }
    
    // Creates A/B buttons
    func createActionButton(letter: String) -> SKNode {
        let buttonNode = SKNode()
        
        // Cream square background
        let squareSize: CGFloat = 70
        let cornerRadius: CGFloat = 5
        let square = SKShapeNode(rect: CGRect(x: -squareSize/2, y: -squareSize/2, width: squareSize, height: squareSize), cornerRadius: cornerRadius)
        let creamColor = SKColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0)
        square.fillColor = creamColor
        square.strokeColor = creamColor
        square.lineWidth = 1
        buttonNode.addChild(square)
        
        // Red circle
        let circleRadius: CGFloat = 25
        let circle = SKShapeNode(circleOfRadius: circleRadius)
        circle.fillColor = .red
        circle.strokeColor = SKColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0)
        circle.lineWidth = 2
        buttonNode.addChild(circle)
        
        // Red letter positioned below button
        let label = SKLabelNode(fontNamed: "Courier-Bold")
        label.text = letter
        label.fontSize = 24
        label.fontColor = .red
        label.verticalAlignmentMode = .top
        label.horizontalAlignmentMode = .right
        label.position = CGPoint(x: squareSize/2, y: -squareSize/2 - 5)
        buttonNode.addChild(label)
        
        return buttonNode
    }
    
    func createDpadCross() -> SKNode {
        let crossNode = SKNode()

        // Dimensions
        let armSize: CGFloat = 150
        let armThickness: CGFloat = 50
        let centerSize: CGFloat = 50
        
        // Horizontal arm of the cross
        let horizontalArm = SKShapeNode(rect: CGRect(x: -armSize/2, y: -armThickness/2, width: armSize, height: armThickness))
        horizontalArm.fillColor = .black
        horizontalArm.strokeColor = .clear
        horizontalArm.zPosition = -2
        crossNode.addChild(horizontalArm)
        
        // Vertical arm of the cross
        let verticalArm = SKShapeNode(rect: CGRect(x: -armThickness/2, y: -armSize/2, width: armThickness, height: armSize))
        verticalArm.fillColor = .black
        verticalArm.strokeColor = .clear
        verticalArm.zPosition = -2
        crossNode.addChild(verticalArm)
        
        // Center of the cross
        let center = SKShapeNode(circleOfRadius: centerSize/2)
        center.fillColor = .black
        center.strokeColor = .clear
        center.zPosition = -1
        crossNode.addChild(center)
        
        // Outer border
        let outerBorder = SKShapeNode()
        let borderPath = CGMutablePath()
        let halfArm = armSize/2
        let halfWidth = armThickness/2
        
        // Start from top-left of vertical arm
        borderPath.move(to: CGPoint(x: -halfWidth, y: halfArm))
        borderPath.addLine(to: CGPoint(x: -halfWidth, y: halfWidth))
        borderPath.addLine(to: CGPoint(x: -halfArm, y: halfWidth))
        borderPath.addLine(to: CGPoint(x: -halfArm, y: -halfWidth))
        borderPath.addLine(to: CGPoint(x: -halfWidth, y: -halfWidth))
        borderPath.addLine(to: CGPoint(x: -halfWidth, y: -halfArm))
        borderPath.addLine(to: CGPoint(x: halfWidth, y: -halfArm))
        borderPath.addLine(to: CGPoint(x: halfWidth, y: -halfWidth))
        borderPath.addLine(to: CGPoint(x: halfArm, y: -halfWidth))
        borderPath.addLine(to: CGPoint(x: halfArm, y: halfWidth))
        borderPath.addLine(to: CGPoint(x: halfWidth, y: halfWidth))
        borderPath.addLine(to: CGPoint(x: halfWidth, y: halfArm))
        borderPath.closeSubpath()
        
        outerBorder.path = borderPath
        outerBorder.fillColor = .clear
        outerBorder.strokeColor = SKColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0)
        outerBorder.lineWidth = 2
        outerBorder.zPosition = 0
        crossNode.addChild(outerBorder)
        
        return crossNode
    }
    
    // Creates pause button with two vertical yellow bars
    func createPauseButton() -> SKNode {
        let buttonNode = SKNode()
        
        let leftBar = SKShapeNode(rect: CGRect(x: -8, y: -10, width: 4, height: 20))
        leftBar.fillColor = .yellow
        leftBar.strokeColor = .clear
        leftBar.name = "leftBar"
        
        let rightBar = SKShapeNode(rect: CGRect(x: 4, y: -10, width: 4, height: 20))
        rightBar.fillColor = .yellow
        rightBar.strokeColor = .clear
        rightBar.name = "rightBar"
        
        buttonNode.addChild(leftBar)
        buttonNode.addChild(rightBar)
        
        return buttonNode
    }
    
    // Creates play button
    func createPlayTriangle() -> SKShapeNode {
        let triangleSize: CGFloat = 12
        let trianglePath = CGMutablePath()
        trianglePath.move(to: CGPoint(x: triangleSize, y: 0))
        trianglePath.addLine(to: CGPoint(x: -triangleSize/2, y: triangleSize * 0.866))
        trianglePath.addLine(to: CGPoint(x: -triangleSize/2, y: -triangleSize * 0.866))
        trianglePath.closeSubpath()
        
        let triangle = SKShapeNode(path: trianglePath)
        triangle.fillColor = .yellow
        triangle.strokeColor = .clear
        triangle.name = "playTriangle"
        
        return triangle
    }
    
    // Sets up sound actions (TODO: Add actual sound files to project)
    func setupSounds() {
        moveSoundAction = SKAction.playSoundFileNamed("move.wav", waitForCompletion: false)
        rotateSoundAction = SKAction.playSoundFileNamed("rotate.wav", waitForCompletion: false)
        lockSoundAction = SKAction.playSoundFileNamed("lock.wav", waitForCompletion: false)
        lineClearSoundAction = SKAction.playSoundFileNamed("lineclear.wav", waitForCompletion: false)
        gameOverSoundAction = SKAction.playSoundFileNamed("gameover.wav", waitForCompletion: false)
        
        // Placeholder empty actions if sound files are not available
        moveSoundAction = SKAction.run { }
        rotateSoundAction = SKAction.run { }
        lockSoundAction = SKAction.run { }
        lineClearSoundAction = SKAction.run { }
        gameOverSoundAction = SKAction.run { }
    }
    
    // Show main menu (Title and Tap to Start)
    func showMainMenu() {
        gameState = .menu
        
        // TETRIS title
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
    
    // Start a new game
    func startGame() {
        gameState = .playing
        
        // Remove menu elements
        childNode(withName: "title")?.removeFromParent()
        childNode(withName: "startLabel")?.removeFromParent()
        
        // Initialize game with NES Tetris starting values
        score = 0
        level = 0
        linesCleared = 0
        updateGravitySpeed()
        
        nextKind = pickKind()
        spawnRandomTetromino()
        drawBoard()
        updateUI()
        updateNextPiece()
    }
    
    // Pseudo-random number generation
    func nextRandom() -> Int {
        rngSeed = (1103515245 &* rngSeed &+ 12345) & 0x7fffffff
        return rngSeed
    }
    
    // Picks a random tetromino kind
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
    
    // Spawns a new random tetromino
    func spawnRandomTetromino() {
        let kind = nextKind
        current = makeTetromino(kind: kind)
        nextKind = pickKind()
        canHold = true
        lockTimer = 0
        
        if !canPlace(tetromino: current) {
            if isGameOverCondition() {
                gameOver()
                return
            } else {
                current.position.y += 2
                if !canPlace(tetromino: current) {
                    gameOver()
                    return
                }
            }
        }
        
        updateNextPiece()
    }

    // Checks if the game is over - any blocks in the top 2 rows
    func isGameOverCondition() -> Bool {
        for x in 0..<columns {
            for y in (rows-2)..<rows {
                if board.grid[x][y] != .none {
                    return true
                }
            }
        }
        return false
    }

    // Checks if a tetromino can be placed at its current position
    func canPlace(tetromino: Tetromino) -> Bool {
        for p in tetromino.blocks {
            let x = tetromino.position.x + p.x
            let y = tetromino.position.y + p.y
            
            if x < 0 || x >= columns { return false }
            if y < 0 { return false }
            if y < rows && board.grid[x][y] != .none { return false }
        }
        return true
    }

    // Locks the current piece in place and handles line clears
    func lockCurrent() {
        guard gameState == .playing else { return }
        
        run(lockSoundAction)
        
        // Lock the piece and check if any blocks are above the game area
        var hasBlocksAboveBoard = false
        for p in current.blocks {
            let x = current.position.x + p.x
            let y = current.position.y + p.y
            
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
    
    // Updates score, level, and lines labels
    func updateLevel() {
        let newLevel = linesCleared / 10
        if newLevel != level {
            level = newLevel
            updateGravitySpeed()
        }
    }
    
    // Updates gravity speed based on current level
    func updateGravitySpeed() {
        let framesPerGridcell: Int
        switch level {
        case 0: framesPerGridcell = 48
        case 1: framesPerGridcell = 43
        case 2: framesPerGridcell = 38
        case 3: framesPerGridcell = 33
        case 4: framesPerGridcell = 28
        case 5: framesPerGridcell = 23
        case 6: framesPerGridcell = 18
        case 7: framesPerGridcell = 13
        case 8: framesPerGridcell = 8
        case 9: framesPerGridcell = 6
        case 10...12: framesPerGridcell = 5
        case 13...15: framesPerGridcell = 4
        case 16...18: framesPerGridcell = 3
        case 19...28: framesPerGridcell = 2
        default: framesPerGridcell = 1 // Level 29+
        }
        
        gravityInterval = Double(framesPerGridcell) / 60.0
    }

    // Handles line clears, scoring, and animations
    func handleLineClears() -> Int {
        let full = board.findFullLines()
        guard !full.isEmpty else { return 0 }
        
        let count = full.count
        // NES scoring system (use level + 1 for scoring multiplier)
        let scoringLevel = level + 1
        switch count {
        case 1: score += 40 * scoringLevel
        case 2: score += 100 * scoringLevel
        case 3: score += 300 * scoringLevel
        case 4: score += 1200 * scoringLevel
        default: break
        }
        
        linesCleared += count
        
        // Animate line clearing
        animateLineClears(lines: full) {
            // Clear lines from top to bottom after animation to maintain proper indexing
            for y in full.sorted(by: >) {
                self.board.clearLine(y)
            }
            self.drawBoard()
        }
        
        return count
    }
    
    // Animates line clears with a flash effect
    func animateLineClears(lines: [Int], completion: @escaping () -> Void) {
        var flashNodes: [SKSpriteNode] = []
        
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
    
    // Create "TETRIS!" text effect
    func addTetrisEffect() {
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

    // Game State Management
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
    
    // Restart the game from game over state
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
    
    // Pause and Resume
    func pauseGame() {
        gameState = .paused
        
        if let pauseButton = uiNode.childNode(withName: "pauseButton") {
            // Remove pause bars
            pauseButton.childNode(withName: "leftBar")?.removeFromParent()
            pauseButton.childNode(withName: "rightBar")?.removeFromParent()
            
            // Add play triangle
            let playTriangle = createPlayTriangle()
            pauseButton.addChild(playTriangle)
        }
        
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
        
        if let pauseButton = uiNode.childNode(withName: "pauseButton") {
            // Remove play triangle
            pauseButton.childNode(withName: "playTriangle")?.removeFromParent()
            
            // Add pause bars back
            let leftBar = SKShapeNode(rect: CGRect(x: -8, y: -10, width: 4, height: 20))
            leftBar.fillColor = .yellow
            leftBar.strokeColor = .clear
            leftBar.name = "leftBar"
            
            let rightBar = SKShapeNode(rect: CGRect(x: 4, y: -10, width: 4, height: 20))
            rightBar.fillColor = .yellow
            rightBar.strokeColor = .clear
            rightBar.name = "rightBar"
            
            pauseButton.addChild(leftBar)
            pauseButton.addChild(rightBar)
        }
        
        childNode(withName: "pauseLabel")?.removeFromParent()
        childNode(withName: "resumeLabel")?.removeFromParent()
    }

    // Renders a grid position (x,y) to a CGPoint in the scene
    func pointFor(x: Int, y: Int) -> CGPoint {
        let boardWidth = CGFloat(columns) * blockSize
        let boardHeight = CGFloat(rows) * blockSize
        return CGPoint(
            x: CGFloat(x) * blockSize - boardWidth/2 + blockSize/2,
            y: CGFloat(y) * blockSize - boardHeight/2 + blockSize/2
        )
    }
    
    // Clear all pieces from the board grid
    func clearBoard() {
        for x in 0..<columns {
            for y in 0..<rows {
                board.set(.none, at: x, y: y)
            }
        }
    }
    
    // Draws the entire board, including locked pieces and current piece
    func drawBoard() {
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
    
    // Draws the current falling tetromino
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
    
    // Creates a block with 3D effect
    func createBlock(color: SKColor) -> SKSpriteNode {
        let block = SKSpriteNode(color: color, size: CGSize(width: blockSize-2, height: blockSize-2))
        
        // Add top highlight for 3D effect
        let highlight = SKSpriteNode(color: blendColor(color, with: .white, fraction: 0.3), size: CGSize(width: blockSize-2, height: 3))
        highlight.position = CGPoint(x: 0, y: (blockSize-2)/2 - 1.5)
        block.addChild(highlight)
        
        // Add side shadow
        let shadow = SKSpriteNode(color: blendColor(color, with: .black, fraction: 0.3), size: CGSize(width: 3, height: blockSize-2))
        shadow.position = CGPoint(x: (blockSize-2)/2 - 1.5, y: 0)
        block.addChild(shadow)
        
        // Add border
        let border = SKShapeNode(rect: CGRect(x: -blockSize/2 + 1, y: -blockSize/2 + 1, width: blockSize-2, height: blockSize-2))
        border.strokeColor = .white
        border.lineWidth = 0.5
        border.fillColor = .clear
        block.addChild(border)
        
        return block
    }
    
    // Draws the next piece in the preview box
    func updateNextPiece() {
        nextPieceNode.removeAllChildren()
        
        let nextTetromino = makeTetromino(kind: nextKind)
        let nextBlockSize: CGFloat = 20
        
        for p in nextTetromino.blocks {
            let tile = SKSpriteNode(color: nextKind.color, size: CGSize(width: nextBlockSize, height: nextBlockSize))

            switch nextKind {
                case .i:
                    tile.position = CGPoint(x: CGFloat(p.x) * nextBlockSize + nextBlockSize/2, y: CGFloat(p.y) * nextBlockSize + nextBlockSize/2)
                case .j:
                    tile.position = CGPoint(x: CGFloat(p.x) * nextBlockSize, y: CGFloat(p.y) * nextBlockSize + nextBlockSize)
                case .o:
                    tile.position = CGPoint(x: CGFloat(p.x) * nextBlockSize - nextBlockSize/2, y: CGFloat(p.y) * nextBlockSize)
                default:
                    tile.position = CGPoint(x: CGFloat(p.x) * nextBlockSize, y: CGFloat(p.y) * nextBlockSize)
            }
            nextPieceNode.addChild(tile)
        }
    }
    
    // Updates score, level, and lines labels
    func updateUI() {
        scoreLabel.text = "SCORE: \(score)"
        levelLabel.text = String(format: "LEVEL: %02d", level) // Two-digit format like NES
        linesLabel.text = "LINES: \(linesCleared)"
    }

    // Movement and Rotation Attempts
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
    
    // Attempts to rotate the current piece clockwise
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
    
    // Attempts to rotate the current piece counter-clockwise
    func attemptRotateCounterClockwise() -> Bool {
        guard gameState == .playing else { return false }
        
        var rotated = current!
        rotated.rotateCounter()
        
        // Basic wall kick attempts
        let kickTests = [
            Point(x: 0, y: 0),
            Point(x: -1, y: 0),
            Point(x: 1, y: 0),
            Point(x: 0, y: 1),
            Point(x: -1, y: 1),
            Point(x: 1, y: 1)
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
    
    // Performs a hard drop of the current piece
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
    
    // Touch Handling
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
    
    // Track button press states for auto-repeat
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
    
    // Resets button press states
    func resetButtonStates() {
        leftButtonPressed = false
        rightButtonPressed = false
        downButtonPressed = false
    }
    
    // Handles auto-repeat for D-pad buttons
    func handleButtonAutoRepeat(currentTime: TimeInterval) {
        // Left button auto-repeat
        if leftButtonPressed && (currentTime - lastLeftRepeat) > buttonRepeatDelay {
            if (currentTime - lastLeftRepeat) > (buttonRepeatDelay + leftRightRepeatRate) {
                let success = attemptMove(dx: -1, dy: 0)
                if success {
                    lastLeftRepeat = currentTime - buttonRepeatDelay
                } else {
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
                    downButtonPressed = false
                }
            }
        }
    }
    
    // Handles input on control buttons
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
    
    // Handles touches in the game area (not on buttons)
    func handleGameTouch(_ location: CGPoint) {
        if !isLocationInGameArea(location) {
            return
        }
        
        // Quick tap for rotation
        if abs(location.x - touchStartLocation.x) < 20 && abs(location.y - touchStartLocation.y) < 20 {
            // This will be handled in touchesEnded if it's a quick tap
            return
        }
    }
    
    // Checks if a touch location is within the game area
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
    
    // Handles touch gestures like swipes and long presses
    func handleTouchGesture(start: CGPoint, end: CGPoint, duration: TimeInterval) {
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
    
    // Game Loop
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
