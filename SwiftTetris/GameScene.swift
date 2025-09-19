import SpriteKit
import GameplayKit
import AVFoundation

// Constants
let columns = 10
let rows = 20
let blockSize: CGFloat = 32.0
let spawnRow = 19  // Top row for spawning

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
        rotations[rotationIndex]
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
    
    // Random number generation
    private var rngSeed = 0xC0FFEE
    
    // Sound effects
    private var moveSoundAction: SKAction!
    private var rotateSoundAction: SKAction!
    private var lockSoundAction: SKAction!
    private var lineClearSoundAction: SKAction!
    private var gameOverSoundAction: SKAction!
    private var backgroundMusicPlayer: AVAudioPlayer?

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
        
        // Score UI
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: boardWidth/2 + 80, y: boardHeight/2 - 40)
        scoreLabel.horizontalAlignmentMode = .left
        uiNode.addChild(scoreLabel)
        
        levelLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        levelLabel.text = "LEVEL: 1"
        levelLabel.fontSize = 20
        levelLabel.fontColor = .white
        levelLabel.position = CGPoint(x: boardWidth/2 + 80, y: boardHeight/2 - 80)
        levelLabel.horizontalAlignmentMode = .left
        uiNode.addChild(levelLabel)
        
        linesLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        linesLabel.text = "LINES: 0"
        linesLabel.fontSize = 20
        linesLabel.fontColor = .white
        linesLabel.position = CGPoint(x: boardWidth/2 + 80, y: boardHeight/2 - 120)
        linesLabel.horizontalAlignmentMode = .left
        uiNode.addChild(linesLabel)
        
        // Next piece preview
        let nextLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        nextLabel.text = "NEXT"
        nextLabel.fontSize = 16
        nextLabel.fontColor = .white
        nextLabel.position = CGPoint(x: boardWidth/2 + 80, y: 0)
        nextLabel.horizontalAlignmentMode = .left
        uiNode.addChild(nextLabel)
        
        nextPieceNode.position = CGPoint(x: boardWidth/2 + 120, y: -40)
        
        // Add pause button
        let pauseButton = SKLabelNode(fontNamed: "Helvetica-Bold")
        pauseButton.text = "||"
        pauseButton.fontSize = 24
        pauseButton.fontColor = .white
        pauseButton.position = CGPoint(x: boardWidth/2 + 80, y: boardHeight/2 - 200)
        pauseButton.name = "pauseButton"
        uiNode.addChild(pauseButton)
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
            gameOver()
            return
        }
        
        updateNextPiece()
    }

    func canPlace(tetromino: Tetromino) -> Bool {
        for p in tetromino.blocks {
            let x = tetromino.position.x + p.x
            let y = tetromino.position.y + p.y
            if !(x >= 0 && x < columns && y >= 0 && y < rows) { return false }
            if board.grid[x][y] != .none { return false }
        }
        return true
    }

    func lockCurrent() {
        guard gameState == .playing else { return }
        
        run(lockSoundAction)
        
        for p in current.blocks {
            let x = current.position.x + p.x
            let y = current.position.y + p.y
            if x >= 0 && x < columns && y >= 0 && y < rows {
                board.set(current.kind, at: x, y: y)
            }
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
            y: CGFloat(rows - 1 - y) * blockSize - boardHeight/2 + blockSize/2
        )
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
        let highlight = SKSpriteNode(color: color.blended(withFraction: 0.3, of: .white),
                                   size: CGSize(width: blockSize-2, height: 3))
        highlight.position = CGPoint(x: 0, y: (blockSize-2)/2 - 1.5)
        block.addChild(highlight)
        
        // Add side shadow
        let shadow = SKSpriteNode(color: color.blended(withFraction: 0.3, of: .black),
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
        for p in nextTetromino.blocks {
            let tile = SKSpriteNode(color: nextKind.color, 
                                  size: CGSize(width: blockSize/2, height: blockSize/2))
            tile.position = CGPoint(x: CGFloat(p.x) * blockSize/2, y: CGFloat(-p.y) * blockSize/2)
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
            // Check if tap is on pause button
            let pauseButton = uiNode.childNode(withName: "pauseButton")
            if let button = pauseButton, button.contains(location) {
                pauseGame()
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
        
        if gameState == .playing {
            handleTouchGesture(start: touchStartLocation, end: location, duration: duration)
        }
    }
    
    func handleGameTouch(_ location: CGPoint) {
        // Quick tap for rotation
        if abs(location.x - touchStartLocation.x) < 20 && abs(location.y - touchStartLocation.y) < 20 {
            // This will be handled in touchesEnded if it's a quick tap
            return
        }
    }
    
    func handleTouchGesture(start: CGPoint, end: CGPoint, duration: TimeInterval) {
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
        
        // Lock delay - give player time to move/rotate before locking
        if lockTimer > 0 && currentTime - lockTimer >= lockDelay {
            lockCurrent()
        }
    }
}