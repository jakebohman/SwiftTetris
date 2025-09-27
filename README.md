# SwiftTetris

A (somewhat) faithful recreation of classic NES Tetris built in Swift using SpriteKit. I also created an [Android version of this app](https://github.com/jakebohman/KotlinTetris) using Kotlin.

## Features

The game recreates the authentic NES Tetris experience with accurate scoring, level progression, and gameplay mechanics. Players can control pieces using touch controls that mimic the original NES controller, complete with a realistic D-pad and A/B buttons.

<img width="327" height="655" alt="Capture" src="https://github.com/user-attachments/assets/5080bb1c-4f11-442e-bd71-09191a35617d" />

**Authentic NES Mechanics:**
- Original scoring system (40/100/300/1200 points for 1/2/3/4 lines)
- Exact speed progression matching NES levels 00-29+
- Level increases every 10 lines cleared
- Classic piece rotation and movement physics

**Visual Design:**
- NES controller-inspired interface
- Retro color palette with cream and red accents
- Nintendo branding and authentic controller styling
- Game area with proper proportions

## Controls

**NES-style**
- **D-pad:** Move pieces left/right/down
- **A Button:** Rotate clockwise  
- **B Button:** Rotate counter-clockwise
- **Pause Button:** Pause/resume game

**Touchscreen**
- **Tap anywhere on game area:** Rotate piece clockwise
- **Swipe left/right:** Move piece horizontally
- **Swipe down:** Soft drop (accelerated fall)
- **Swipe up:** Rotate piece (alternative method)
- **Long press on game area:** Continuous soft drop


## Technical Details

Built with Swift 4.2 and SpriteKit for iOS. The game implements the original NES Tetris gravity table, converting the 60 FPS frame timings to modern time intervals for smooth gameplay on contemporary devices.

Tested with XCode's iPhone XR simulator - iOS 12.1.
