//
//  GameScene.swift
//  ScrollerGame
//
//  Created by Vadim on 5/23/16.
//  Copyright (c) 2016 Vadim. All rights reserved.
//

import SpriteKit
import AVFoundation
import Firebase
import FirebaseAuth
import FirebaseDatabase


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Physics
    let GroundCategory: UInt32 = 0x1 << 0
    let BallCategory: UInt32 = 0x1 << 1
    let LavaCategory: UInt32 = 0x1 << 2
    let IceCategory: UInt32 = 0x1 << 3
    
    // Sprites
    var Ball = SKSpriteNode()
    var Ground = SKSpriteNode()
    var Ground2 = SKSpriteNode()
    var BlockLow = SKShapeNode()
    var CloudLow1 = SKSpriteNode()
    var CloudMid1 = SKSpriteNode()
    var CloudHigh1 = SKSpriteNode()
    var Explosion = SKEmitterNode(fileNamed: "SparkParticle")
    var LogoAtlas = SKTextureAtlas(named: "logo")
    var LogoArray = [SKTexture]()
    var Logo = SKSpriteNode()
    var GameOverMenu = SKSpriteNode(imageNamed: "GameOverMenu")
    var PlayAgainButton = SKSpriteNode(imageNamed: "PlayAgainButton")
    var MainMenuButton = SKSpriteNode(imageNamed: "MainMenuButton")
    var HowToPlay = SKSpriteNode(imageNamed: "HowToPlay")
    var MusicIcon = SKSpriteNode()
    var LevelPick = SKSpriteNode(imageNamed: "levelPick")
    var EasyDiff = SKSpriteNode(imageNamed: "easyDiff")
    var MedDiff = SKSpriteNode(imageNamed: "medDiff")
    var HardDiff = SKSpriteNode(imageNamed: "hardDiff")
    var DemoButton = SKSpriteNode(imageNamed: "demoButton")
    var DemoMode = SKSpriteNode(imageNamed: "DemoMode")
    
    // Player
    var jumped = false
    var doubleJumped = true
    var landed = true
    var currentBall = "fire"
    var currentPos = CGPoint()
    
    // Blocks
    var lavaCount = 1
    var iceCount = 1
    var blockLowCount = 1
    var blockMidCount = 1
    var blockHighCount = 1
    
    // Gameworld vars
    var currentEnd: CGFloat = 0
    var gameOver = false
    var gameStart = false
    var showingTutorial = false
    var greenAmount: CGFloat = 188
    var redAmount: CGFloat = 62
    var blueAmount: CGFloat = 23
    var levelPicked = false
    var score = 0
    var HighScore = 0
    
    // Audio/visual
    var audioPlayer = AVAudioPlayer()
    var ScoreLabel = SKLabelNode()
    var HighScoreLabel = SKLabelNode()
    let defaults = NSUserDefaults.standardUserDefaults()
    var muteMusic = false
    var soundToPlay = NSURL()
    
    // Logic vars
    var lastBlock: String = ""
    var lastGround: String = ""
    var consecLava: Int = 0
    var consecIce: Int = 0
    var consecBlock: Int = 0
    
    // Difficulty vars
    var gameSpeed: CGFloat = 18
    var jumpForce: CGFloat = 100
    var gameDiff: Int = 0
    var gameMode: String?
    var blockSpaceNear: CGFloat = 110
    var blockSpaceMid: CGFloat = 175
    var blockSpaceFar: CGFloat = 230
    var difficultyMod: CGFloat = 0
    var blockDiffMult: CGFloat = 1.8
    
    // Choi
    var Sun = SKSpriteNode(imageNamed: "sun")
    var Choi = SKSpriteNode(imageNamed: "choi")
    var ChoiBubble = SKSpriteNode(imageNamed: "choiBubble")
    var ChoiTextLabel = SKLabelNode()
    var ChoiTalked = false
    var ChoiTalking = false
    var ChoiTextArr = ["Wow great jump!", "You're doing great!", "Keep it up!", "Fear is the mind killer", "Hmmm......"]
    
    // Login
    var UserIcon = SKSpriteNode()
    var LoginMenu = SKSpriteNode(imageNamed: "LoginMenu")
    var EmailField = UITextField()
    var PassField = UITextField()
    var LoginButton = SKSpriteNode(imageNamed: "LoginButton")
    var LoggedIn = false
    var ShowLogin = false
    var Database = FIRDatabase.database().reference()
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////123LoadView////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    override func didMoveToView(view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        
        
        for i in 1...LogoAtlas.textureNames.count{
            let Name = "logo\(i)"
            LogoArray.append(SKTexture(imageNamed: Name))
        }
        
        Logo = SKSpriteNode(imageNamed: LogoAtlas.textureNames[0])
        Logo.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(LogoArray, timePerFrame: 0.2)))
        
        
        
        drawWorld()
        playMusic()
        
    }

    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////123UPDATE//////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    override func update(currentTime: CFTimeInterval) {
        
        if(gameMode == "procedural" || gameMode == "impossible"){
        
            if(score > 750 && gameDiff == 0){
                gameDiff = 1
            }
        }
        
        if(ChoiTalking == true){
            
            let ChoiAdvice = arc4random_uniform(500)
            if(ChoiAdvice < 5 && ChoiTalked == false){
                drawChoiText()
                ChoiTalked = true
            }
            
        }
        
        
        if(Ball.position.y < 0 && gameOver == false){
            endGame()
        }
        
        if(gameStart == false && ShowLogin == false){
            StartMenu()
        }
        
        if(gameOver == false && gameStart == true){
            
            if(gameMode == "procedural" || gameMode == "impossible"){
                score += 1
                displayScore(score)
            }
            
            runGame(gameSpeed + (difficultyMod / 10))
            Logo.hidden = true
        }
        
        
        //Keep ball in place
        if(Ball.position.x != self.frame.width / 4){
            Ball.position.x = self.frame.width / 4
        }
        
    }
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////123CONTACT/////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == GroundCategory && secondBody.categoryBitMask == BallCategory {
            jumped = false
            doubleJumped = true
            landed = true
        }
        
        if secondBody.categoryBitMask == LavaCategory && firstBody.categoryBitMask == BallCategory {
            
            if(currentBall == "water"){
                endGame()
            }
            else{
                jumped = false
                doubleJumped = true
                landed = true
            }
        }
        if secondBody.categoryBitMask == IceCategory && firstBody.categoryBitMask == BallCategory {
            
            if(currentBall == "fire"){
                endGame()
            }
            else{
                jumped = false
                doubleJumped = true
                landed = true
            }
        }
        
        
    }
    

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////123TOUCHES///////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let touch = touches.first!
        let touchLocation = touch.locationInNode(self)
        
        if(ShowLogin == true){  // Login
            
            if(CGRectContainsPoint(LoginButton.frame, touchLocation)){
                
                FIRAuth.auth()?.createUserWithEmail(EmailField.text!, password: PassField.text!, completion: {
                    user, error in
                    
                    if error != nil{
                        self.Login()
                    }
                    else{
                        print("User Created")
                        self.Login()
                    }
                })
                ShowLogin = false
                resetWorld()
            }
            
        }
        
        if(gameMode != "demo"){
        
            //Double jump check
            if(jumped == true && doubleJumped == false && landed == false && gameOver == false){
                doubleJump()
            }
            
            //Ball bounce on click
            if(jumped == false && doubleJumped == true && landed == true && gameOver == false){
                jump()
            }
            
        }
        else{
            
            if(CGRectContainsPoint(DemoMode.frame, touchLocation)){
                endGame()
            }
            
        }
        
        // Music mute
        if(CGRectContainsPoint(MusicIcon.frame, touchLocation)){
            if(muteMusic == false){
                muteMusic = true
                audioPlayer.stop()
                drawMusic()
            }
            else{
                muteMusic = false
                drawMusic()
                playMusic()
            }
        }
        
        
        // Start Menu
        if(gameStart == false){
            
            if(showingTutorial == false){ // Login menu
                
                if(ShowLogin == false){
                    if(CGRectContainsPoint(UserIcon.frame, touchLocation)){
                        hideLogin()
                        drawLogin()
                        ShowLogin = true
                    }
                }
                else{
                    if(CGRectContainsPoint(UserIcon.frame, touchLocation)){
                        hideLogin()
                        ShowLogin = false
                        resetWorld()
                    }
                }
                
            }
            
            if(CGRectContainsPoint(Choi.frame, touchLocation)){
                if(showingTutorial == false){
                    HowToPlay.hidden = false
                    drawDemo()
                    DemoButton.hidden = false
                    showingTutorial = true
                    if(levelPicked == false){
                        Logo.hidden = true
                    }
                }
                else{
                    HowToPlay.hidden = true
                    DemoButton.removeFromParent()
                    showingTutorial = false
                    if(levelPicked == false){
                        Logo.hidden = false
                    }
                }
            }

            
            if(CGRectContainsPoint(DemoButton.frame, touchLocation) && showingTutorial == true){
                gameMode = "demo"
                gameStart = true
                playMusic()
                resetWorld()
                drawDemoMode()
                ScoreLabel.hidden = true
                HowToPlay.hidden = true
                showingTutorial = false
            }
            
            if(levelPicked == false){
                if(CGRectContainsPoint(Ball.frame, touchLocation)){
                    Logo.removeFromParent()
                    drawLevelPick()
                    LevelPick.hidden = false
                    EasyDiff.hidden = false
                    MedDiff.hidden = false
                    HardDiff.hidden = false
                    levelPicked = true
                }
            }
                    // Level select
            else{
                if(CGRectContainsPoint(EasyDiff.frame, touchLocation)){
                    gameMode = "practice"
                    ChoiTalking = true
                    gameStart = true
                    resetWorld()
                    playMusic()
                    ScoreLabel.hidden = true
                }
                if(CGRectContainsPoint(MedDiff.frame, touchLocation)){
                    gameMode = "procedural"
                    gameStart = true
                    resetWorld()
                    playMusic()
                    ScoreLabel.hidden = false
                }
                if(CGRectContainsPoint(HardDiff.frame, touchLocation)){
                    gameMode = "impossible"
                    gameStart = true
                    resetWorld()
                    playMusic()
                    ScoreLabel.hidden = false
                }
            }
            
        }
        
        
        // Game Over Menu
        if(gameOver == true){
            
            if(CGRectContainsPoint(PlayAgainButton.frame, touchLocation)){
                gameStart = true
                playMusic()
                resetWorld()
                ScoreLabel.hidden = false
                if(gameMode == "demo"){
                    drawDemoMode()
                }
            }
            if(CGRectContainsPoint(MainMenuButton.frame, touchLocation)){
                resetWorld()
                gameStart = false
                playMusic()
            }
        }
        
        
    }
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////123MAKE GAME RUN GOOD///////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func runGame(speed: CGFloat){
        
        if(gameMode == "demo"){
            
            let demoSpeed: CGFloat = 20
            
            Ground.position.x = Ground.position.x - demoSpeed
            Ground2.position.x = Ground2.position.x - demoSpeed
            
            moveChildren(demoSpeed)
            moveClouds(demoSpeed)
            
            currentEnd -= demoSpeed
            
            blockParty()
            
        }
        
        
        if(gameMode == "practice"){
            
            Ground.position.x = Ground.position.x - speed
            Ground2.position.x = Ground2.position.x - speed
            
            moveChildren(speed)
            moveClouds(speed)
            
            currentEnd -= speed
            
            blockParty()
            
        }
        
        
        if(gameMode == "procedural" || gameMode == "impossible"){
        
            if(score < 1000){
                difficultyMod += 0.07
            }
            else{
                blockDiffMult = 3.1
            }
            if(score > 300 && score < 500){
                blockDiffMult = 2.3
            }
            if(score > 500 && score < 750){
                blockDiffMult = 2.5
            }
            if(score > 750 && score < 1100){
                blockDiffMult = 2.8
            }
            
            
            self.backgroundColor = UIColor(red: (redAmount / 255), green: (greenAmount / 255), blue: (blueAmount / 255), alpha: 1)
            if(greenAmount > 0){
                greenAmount -= 0.3
            }
            else{
                redAmount += 0.3
                blueAmount -= 0.3
            }
            
            Sun.position.y = Sun.position.y - 0.3
            Choi.position.y = Choi.position.y - 0.3
            
            Ground.position.x = Ground.position.x - speed
            Ground2.position.x = Ground2.position.x - speed
            
            moveChildren(speed)
            moveClouds(speed)
            
            currentEnd -= speed
            
            blockParty()
            
        }
        
    }
    
    
    
    
    func StartMenu(){
        
        Logo.hidden = false
        
        Ground.position.x = Ground.position.x - 4
        Ground2.position.x = Ground2.position.x - 4
        
        CloudLow1.position.x = CloudLow1.position.x - (gameSpeed / 4.5)
        CloudMid1.position.x = CloudMid1.position.x - (gameSpeed / 6)
        CloudHigh1.position.x = CloudHigh1.position.x - (gameSpeed / 9)
        
        // Clouds
        if(CloudLow1.position.x < -500){
            CloudLow1.position.x = CGFloat(currentEnd) + CGFloat(arc4random_uniform(200))
        }
        if(CloudMid1.position.x < -400){
            CloudMid1.position.x = CGFloat(currentEnd) + CGFloat(arc4random_uniform(200))
        }
        if(CloudHigh1.position.x < -500){
            CloudHigh1.position.x = CGFloat(currentEnd) + CGFloat(arc4random_uniform(200))
        }
        
        
        // Infinite ground
        if(Ground.position.x < -500 ){
            Ground.position = CGPointMake(Ground2.position.x + Ground2.size.width, Ground.frame.height)
        }
        if(Ground2.position.x < -500 ){
            Ground2.position = CGPointMake(Ground.position.x + Ground.size.width, Ground2.frame.height)
        }

        
    }
    
    
    
    
    func drawWorld(){
        
        self.backgroundColor = UIColor(red: (62 / 255), green: (188 / 255), blue: (230 / 255), alpha: 1)
        
        Logo.position = CGPoint(x: self.frame.width / 2, y: 340)
        Logo.zPosition = -1
        Logo.hidden = true
        self.addChild(Logo)
        
        HowToPlay.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        HowToPlay.size = CGSize(width: 650, height: 500)
        HowToPlay.zPosition = 50
        HowToPlay.hidden = true
        self.addChild(HowToPlay)
        
        
        Ground = drawGround(CGPoint( x: 0, y: 101))
        Ground2 = drawGround(CGPoint(x: Ground.size.width , y: 101))
        
        currentEnd = Ground.size.width + Ground2.size.width - 380
        
        drawClouds("low1")
        drawClouds("mid1")
        drawClouds("high1")
        
        for i in 1 ... 6{
            drawLava(i)
            drawIce(i)
        }
        
        for i in 1 ... 3{
            drawBlock("low", name: "\(i)")
            drawBlock("mid", name: "\(i)")
            drawBlock("high", name: "\(i)")
        }
        
        currentPos = CGPoint(x: self.frame.width / 4, y: self.frame.height / 2)
        Ball = drawBall(currentPos, ballSprite: currentBall)
        
        drawLabels()
        drawChoi()
        drawGameOver()
        drawMusic()
        drawUserIcon()
        
    }
    
    
    
    
    func endGame(){
        
        gameSpeed = 0
        gameOver = true
        lastBlock = ""
        lastGround = ""
        ChoiTalking = false
        
        GameOverMenu.hidden = false
        PlayAgainButton.hidden = false
        MainMenuButton.hidden = false
        DemoMode.hidden = true
        
        //Sound
        if(muteMusic == false){
            audioPlayer.stop()
            runAction(SKAction.playSoundFileNamed("explode.wav", waitForCompletion: true))
        }
        
        killBall()
        
        // Set high score
        if(score > HighScore){
            if( gameMode == "procedural" || gameMode == "impossible"){
                HighScore = score
                if(LoggedIn == true){
                    Database.child("HighScore").setValue(score)
                }
            }
        }
        
    }
    
    
    
    
    func resetWorld(){
        
        greenAmount = 188
        redAmount = 62
        blueAmount = 230
        gameSpeed = 18
        jumpForce = 100
        gameOver = false
        score = 0
        difficultyMod = 0
        GameOverMenu.hidden = true
        PlayAgainButton.hidden = true
        MainMenuButton.hidden = true
        levelPicked = false
        
        self.removeAllChildren()
        
        hideLogin()
        drawWorld()
    }
    
    
    
    
    func displayScore(score: Int){
        ScoreLabel.text = "Score: \(score)"
    }
    
    
    
    
    func playMusic(){
        
        if(muteMusic == false){
            
            if(gameStart == false){
                soundToPlay = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("fezMenu", ofType: "mp3")!)
            }
            
            if(gameMode == "demo" && gameStart == true){
                soundToPlay = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("topGear", ofType: "mp3")!)
            }else if(gameMode == "practice" && gameStart == true){
                soundToPlay = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("rainbowRoad", ofType: "mp3")!)
            }else if(gameMode == "procedural" && gameStart == true){
                soundToPlay = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("bgmusic", ofType: "mp3")!)
            }else if(gameMode == "impossible" && gameStart == true){
                soundToPlay = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("braveheart", ofType: "mp3")!)
            }
            
            do{
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                try audioPlayer = AVAudioPlayer(contentsOfURL: soundToPlay)
                audioPlayer.numberOfLoops = -1
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            } catch {print("error in sound:\n\n \(error)")}
        }
        
    }
    
    
    
    
    func killBall(){
        
        if(Ball.position.y > 0){
            //Particle explosion
            Explosion?.position = Ball.position
            Explosion?.hidden = false
            Explosion?.particleColorBlendFactor = 0
            self.addChild(Explosion!)
            let wait = SKAction.waitForDuration(0.8)
            let run = SKAction.runBlock{
                self.Explosion?.removeFromParent()
            }
            runAction(SKAction.sequence([wait, run]))
        }
        
        Ball.removeFromParent()
        
    }
    
    
    
    
    func moveChildren(speed: CGFloat){ //presmove
        
        childNodeWithName("blockLow1")?.position.x = (childNodeWithName("blockLow1")?.position.x)! - speed
        childNodeWithName("blockLow2")?.position.x = (childNodeWithName("blockLow2")?.position.x)! - speed
        childNodeWithName("blockLow3")?.position.x = (childNodeWithName("blockLow3")?.position.x)! - speed
        
        childNodeWithName("blockMid1")?.position.x = (childNodeWithName("blockMid1")?.position.x)! - speed
        childNodeWithName("blockMid2")?.position.x = (childNodeWithName("blockMid2")?.position.x)! - speed
        childNodeWithName("blockMid3")?.position.x = (childNodeWithName("blockMid3")?.position.x)! - speed
        
        childNodeWithName("blockHigh1")?.position.x = (childNodeWithName("blockHigh1")?.position.x)! - speed
        childNodeWithName("blockHigh2")?.position.x = (childNodeWithName("blockHigh2")?.position.x)! - speed
        childNodeWithName("blockHigh3")?.position.x = (childNodeWithName("blockHigh3")?.position.x)! - speed
        
        childNodeWithName("lavaBlock1")?.position.x = (childNodeWithName("lavaBlock1")?.position.x)! - speed
        childNodeWithName("lavaBlock2")?.position.x = (childNodeWithName("lavaBlock2")?.position.x)! - speed
        childNodeWithName("lavaBlock3")?.position.x = (childNodeWithName("lavaBlock3")?.position.x)! - speed
        childNodeWithName("lavaBlock4")?.position.x = (childNodeWithName("lavaBlock4")?.position.x)! - speed
        childNodeWithName("lavaBlock5")?.position.x = (childNodeWithName("lavaBlock5")?.position.x)! - speed
        childNodeWithName("lavaBlock6")?.position.x = (childNodeWithName("lavaBlock6")?.position.x)! - speed
        
        childNodeWithName("iceBlock1")?.position.x = (childNodeWithName("iceBlock1")?.position.x)! - speed
        childNodeWithName("iceBlock2")?.position.x = (childNodeWithName("iceBlock2")?.position.x)! - speed
        childNodeWithName("iceBlock3")?.position.x = (childNodeWithName("iceBlock3")?.position.x)! - speed
        childNodeWithName("iceBlock4")?.position.x = (childNodeWithName("iceBlock4")?.position.x)! - speed
        childNodeWithName("iceBlock5")?.position.x = (childNodeWithName("iceBlock5")?.position.x)! - speed
        childNodeWithName("iceBlock6")?.position.x = (childNodeWithName("iceBlock6")?.position.x)! - speed
        
    }
    
    
    
    
    func moveClouds(speed: CGFloat){
        
        CloudLow1.position.x = CloudLow1.position.x - (speed / 4.5)
        CloudMid1.position.x = CloudMid1.position.x - (speed / 6)
        CloudHigh1.position.x = CloudHigh1.position.x - (speed / 9)
        
        if(CloudLow1.position.x < -500){
            CloudLow1.position.x = CGFloat(currentEnd) + CGFloat(arc4random_uniform(200))
        }
        if(CloudMid1.position.x < -400){
            CloudMid1.position.x = CGFloat(currentEnd) + CGFloat(arc4random_uniform(200))
        }
        if(CloudHigh1.position.x < -500){
            CloudHigh1.position.x = CGFloat(currentEnd) + CGFloat(arc4random_uniform(200))
        }
        
    }
    
    
    
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////Start of BlockParty///////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func blockParty(){
        
        var choice = arc4random_uniform(100)
        
        if(currentEnd < 1150){
            
            if(gameMode == "demo"){
                
                if(lastBlock == "lavablock"){
                    placeIce()
                    placeIce()
                }
                else{
                    placeLava()
                    placeLava()
                }
            }
            
            
            if(gameMode == "practice"){
                
                if(choice <= 50){
                    if(consecLava < 4){
                        placeLava()
                        placeLava()
                    }
                    else{
                        consecLava = 0
                        placeIce()
                        placeIce()
                    }
                }
                else{
                    if(consecIce < 4){
                        placeIce()
                        placeIce()
                    }
                    else{
                        consecIce = 0
                        placeLava()
                        placeLava()
                    }
                }
                
            }
            
        
            if(gameMode == "procedural"){
            
                if(lastBlock == "lavablock" || lastBlock == "iceblock" || lastBlock == ""){    //-------------------- Spawn any ground
                    
                    if(choice >= 0 && choice <= 45){
                        if(consecLava < 2){
                            placeLava()
                            if(gameDiff == 1){
                                placeLava()
                            }
                        }
                        else{
                            consecLava = 0  // If 3 consecutive lava, spawn ice
                            if(choice <= 35){
                                placeIce()
                                if(gameDiff == 1){
                                    placeIce()
                                }
                            }
                            else{
                                placeBlockLow()
                            }
                        }
                    }
                    else if(choice > 45 && choice <= 90){
                        if(consecIce < 2){
                            placeIce()
                            if(gameDiff == 1){
                                placeIce()
                            }
                        }
                        else{
                            consecIce = 0   // If 3 consecutive ice, spawn lava
                            if(choice <= 75){
                                placeLava()
                                if(gameDiff == 1){
                                    placeLava()
                                }
                            }
                            else{
                                placeBlockLow()
                            }
                        }
                    }
                    else if(choice > 90 && choice <= 100){
                        placeBlockLow()
                    }
                }
                
                if(lastBlock == "lowblock"){                                                    //-------------------- Spawn mid/low/ground
                    
                    if(consecBlock == 6){   // If 6 consec blocks, spawn lava/ice
                        consecBlock = 0
                        if(choice <= 50){
                            placeLava()
                            placeLava()
                            if(gameDiff == 1){
                                placeLava()
                            }
                            choice = 500
                        }
                        else{
                            placeIce()
                            placeIce()
                            if(gameDiff == 1){
                                placeIce()
                            }
                            choice = 500
                        }
                    }
                    
                    if(choice >= 0 && choice <= 10){
                        placeBlockLow()
                    }
                    else if(choice > 10 && choice <= 70){
                        placeBlockMid()
                    }
                    else if(choice > 70 && choice <= 100){
                        if(lastGround == "lavablock"){
                            placeLava()
                            placeLava()
                            if(gameDiff == 1){
                                placeLava()
                            }
                        }
                        if(lastGround == "iceblock"){
                            placeIce()
                            placeIce()
                            if(gameDiff == 1){
                                placeLava()
                            }
                        }
                    }
                    
                }
                
                if(lastBlock == "midblock"){                                                    //-------------------- Spawn high/mid/low
                    
                    if(consecBlock == 6){   // Ramp down if at max blocks
                        placeBlockLow()
                        consecBlock = 0
                        if(choice <= 50){
                            placeLava()
                            placeLava()
                            if(gameDiff == 1){
                                placeLava()
                            }
                            choice = 500
                        }
                        else{
                            placeIce()
                            placeIce()
                            if(gameDiff == 1){
                                placeIce()
                            }
                            choice = 500
                        }
                    }
                    
                    if(choice >= 0 && choice <= 33){
                        placeBlockHigh()
                    }
                    
                    if(choice > 33 && choice <= 66){
                        placeBlockMid()
                    }
                    
                    if(choice > 66 && choice <= 100){
                        placeBlockLow()
                    }
                    
                }
                
                if(lastBlock == "highblock"){                                                   //-------------------- Spawn high/mid
                    
                    if(consecBlock == 6){   // Ramp down if at max blocks
                        placeBlockMid()
                        placeBlockLow()
                        consecBlock = 0
                        if(choice <= 50){
                            placeLava()
                            placeLava()
                            if(gameDiff == 1){
                                placeLava()
                            }
                            choice = 500
                        }
                        else{
                            placeIce()
                            placeIce()
                            if(gameDiff == 1){
                                placeIce()
                            }
                            choice = 500
                        }
                    }
                    
                    if(choice <= 50){
                        placeBlockHigh()
                    }
                    else if(choice > 50 && choice <= 100){
                        placeBlockMid()
                    }
                    
                }
            }   // ------ End of procedural
            
            
            if(gameMode == "impossible"){
                
                if(choice <= 50){
                    placeIce()
                }
                else{
                    placeLava()
                }
                
                
                if(choice <= 33){
                    if(blockLowCount > 3){
                        blockLowCount = 1
                    }
                    self.childNodeWithName("blockLow\(blockLowCount)")!.position.x = currentEnd
                    self.childNodeWithName("blockLow\(blockLowCount)")!.hidden = false
                    blockLowCount += 1
                }
                else if(choice > 33 && choice <= 66){
                    if(blockMidCount > 3){
                        blockMidCount = 1
                    }
                    self.childNodeWithName("blockMid\(blockMidCount)")!.position.x = currentEnd
                    self.childNodeWithName("blockMid\(blockMidCount)")!.hidden = false
                    blockMidCount += 1
                }
                else if(choice > 66 && choice <= 100){
                    if(blockHighCount > 3){
                        blockHighCount = 1
                    }
                    self.childNodeWithName("blockHigh\(blockHighCount)")!.position.x = currentEnd
                    self.childNodeWithName("blockHigh\(blockHighCount)")!.hidden = false
                    blockHighCount += 1
                }
                
            }   // ------ End of impossible
            
            
            if(gameMode == "demo"){     //presdemo
                
                if(currentBall == "water"){
                    for i in 1...6{
                        if( self.childNodeWithName("lavaBlock\(i)")!.position.x < 650 &&
                            self.childNodeWithName("lavaBlock\(i)")!.position.x > 0 ){
                            
                            if(jumped == false){
                                let wait = SKAction.waitForDuration(0.3)
                                let run = SKAction.runBlock{
                                    self.jump()
                                }
                                runAction(SKAction.sequence([wait, run]))
                            }
                        }
                    }
                }
                else{
                    for i in 1...6{
                        if( self.childNodeWithName("iceBlock\(i)")!.position.x < 650 &&
                            self.childNodeWithName("iceBlock\(i)")!.position.x > 0 ){
                            
                            if(jumped == false){
                                let wait = SKAction.waitForDuration(0.3)
                                let run = SKAction.runBlock{
                                    self.jump()
                                }
                                runAction(SKAction.sequence([wait, run]))
                            }
                        }
                    }
                }
                
            }   // ------ End of demomode
            
            
        }
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////End of BlockParty///////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    
    func placeLava(){           //presplace
        if(lavaCount > 6){
            lavaCount = 1
        }
        if(lastBlock == "lowblock"){
            childNodeWithName("lavaBlock\(lavaCount)")!.position.x = currentEnd + 150 + difficultyMod*blockDiffMult
            currentEnd += 400 + difficultyMod*blockDiffMult
        }
        else{
            childNodeWithName("lavaBlock\(lavaCount)")!.position.x = currentEnd
            currentEnd += 250
        }
        
        childNodeWithName("lavaBlock\(lavaCount)")!.hidden = false
        
        lavaCount += 1
        lastGround = "lavablock"
        lastBlock = "lavablock"
        consecLava += 1
        consecIce = 0
        consecBlock = 0
    }
    
    
    func placeIce(){
        if(iceCount > 6){
            iceCount = 1
        }
        if(lastBlock == "lowblock"){
            childNodeWithName("iceBlock\(iceCount)")!.position.x = currentEnd + 150 + difficultyMod*blockDiffMult
            currentEnd += 400 + difficultyMod*blockDiffMult
        }
        else{
            childNodeWithName("iceBlock\(iceCount)")!.position.x = currentEnd
            currentEnd += 250
        }
        
        childNodeWithName("iceBlock\(iceCount)")!.hidden = false
        
        iceCount += 1
        lastGround = "iceblock"
        lastBlock = "iceblock"
        consecLava = 0
        consecIce += 1
        consecBlock = 0
    }
    
    
    func placeBlockLow(){
        if(blockLowCount > 3){
            blockLowCount = 1
        }
        if(consecBlock > 0){
            lastGround = ""
        }
        
        if(lastBlock == "lowblock"){
            childNodeWithName("blockLow\(blockLowCount)")!.position.x = currentEnd + blockSpaceFar + difficultyMod*blockDiffMult
            currentEnd += 555 + difficultyMod*blockDiffMult
        }
        else if(lastBlock == "midblock"){
            childNodeWithName("blockLow\(blockLowCount)")!.position.x = currentEnd + blockSpaceNear + difficultyMod*blockDiffMult
            currentEnd += 435 + difficultyMod*blockDiffMult
        }
        else{
            childNodeWithName("blockLow\(blockLowCount)")!.position.x = currentEnd + blockSpaceMid + difficultyMod*blockDiffMult
            currentEnd += 500 + difficultyMod*blockDiffMult
        }
        
        childNodeWithName("blockLow\(blockLowCount)")!.hidden = false
        
        blockLowCount += 1
        lastBlock = "lowblock"
        consecLava = 0
        consecIce = 0
        consecBlock += 1
        
    }
    
    func placeBlockMid(){
        if(blockMidCount > 3){
            blockMidCount = 1
        }
        if(lastBlock == "midblock"){
            childNodeWithName("blockMid\(blockMidCount)")!.position.x = currentEnd + blockSpaceFar + difficultyMod*blockDiffMult
            currentEnd += 555 + difficultyMod*blockDiffMult
        }
        else if(lastBlock == "highblock"){
            childNodeWithName("blockMid\(blockMidCount)")!.position.x = currentEnd + blockSpaceNear + difficultyMod*blockDiffMult
            currentEnd += 435 + difficultyMod*blockDiffMult
        }
        else{
            childNodeWithName("blockMid\(blockMidCount)")!.position.x = currentEnd + blockSpaceMid + difficultyMod*blockDiffMult
            currentEnd += 500 + difficultyMod*blockDiffMult
        }
        
        childNodeWithName("blockMid\(blockMidCount)")!.hidden = false
        
        blockMidCount += 1
        lastBlock = "midblock"
        consecLava = 0
        consecIce = 0
        consecBlock += 1
    }

    func placeBlockHigh(){
        if(blockHighCount > 3){
            blockHighCount = 1
        }
        if(lastBlock == "highblock"){
            childNodeWithName("blockHigh\(blockHighCount)")!.position.x = currentEnd + blockSpaceFar + difficultyMod*blockDiffMult
            currentEnd += 555 + difficultyMod*blockDiffMult
        }
        else{
            childNodeWithName("blockHigh\(blockHighCount)")!.position.x = currentEnd + blockSpaceMid + difficultyMod*blockDiffMult
            currentEnd += 500 + difficultyMod*blockDiffMult
        }
        
        childNodeWithName("blockHigh\(blockHighCount)")!.hidden = false
        
        blockHighCount += 1
        lastBlock = "highblock"
        consecLava = 0
        consecIce = 0
        consecBlock += 1
    }

    
    
    
    func jump(){            //presjump
        
        if(gameOver == false){
            
            let tempPos = Ball.position
            Ball.removeFromParent()
            
            if(currentBall == "fire"){
                currentBall = "water"
            }else if(currentBall == "water"){
                currentBall = "fire"
            }
            
            Ball = drawBall(tempPos, ballSprite: currentBall)
            
            Ball.physicsBody?.velocity = CGVectorMake(0, 0)
            Ball.physicsBody?.applyImpulse(CGVectorMake(0, jumpForce))
            
            jumped = true
            doubleJumped = false
            landed = false
            
        }
    }
    
    
    
    
    func doubleJump(){
        
        let tempPos = Ball.position
        Ball.removeFromParent()
        
        if(currentBall == "fire"){
            currentBall = "water"
        }
        else if(currentBall == "water"){
            currentBall = "fire"
        }
        
        Ball = drawBall(tempPos, ballSprite: currentBall)
        
        Ball.physicsBody?.velocity = CGVectorMake(0, 0)
        Ball.physicsBody?.applyImpulse(CGVectorMake(0, jumpForce - 10))
        
        jumped = false
        doubleJumped = true
        
    }
    
    
    
    
    func Login(){   //presfirebase
        
        FIRAuth.auth()?.signInWithEmail(EmailField.text!, password: PassField.text!, completion: {
            
            user, error in
            if error != nil {
                print("Login failed")
            }
            else{
                print("Login worked")
                
                self.Database.child("HighScore").observeEventType(.Value, withBlock: { (snapshot) in
                    
                    let DBScore = snapshot.value! as! Int
                    if(DBScore > self.HighScore){
                        self.HighScore = DBScore
                        self.HighScoreLabel.text = "High Score: \(self.HighScore)"
                    }
                    
                    self.LoggedIn = true
                    self.drawUserIcon()
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
        })
        
    }
    
    
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////123SPRITES/////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func drawBall(currentPos: CGPoint, ballSprite: String) -> SKSpriteNode{     //presball
        
        let Ball = SKSpriteNode(imageNamed: "\(ballSprite)_sprite")
        
        Ball.name = "Ball"
        Ball.size = CGSize(width: 80, height: 80)
        Ball.position = CGPoint(x: currentPos.x, y: currentPos.y + 2)
        
        Ball.physicsBody = SKPhysicsBody(circleOfRadius: 40)
        Ball.physicsBody?.affectedByGravity = true
        Ball.physicsBody?.dynamic = true
        Ball.physicsBody?.allowsRotation = true
        Ball.physicsBody?.categoryBitMask = BallCategory
        Ball.physicsBody?.collisionBitMask = GroundCategory | LavaCategory | IceCategory
        Ball.physicsBody?.contactTestBitMask = LavaCategory | IceCategory
        Ball.physicsBody?.restitution = 0
        Ball.physicsBody?.linearDamping = 1
        Ball.physicsBody?.angularDamping = 1
        Ball.physicsBody?.friction = 0
        Ball.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(Ball)
        
        let rotate = SKAction.rotateByAngle(-7, duration: 1)
        let repeatAction = SKAction.repeatActionForever(rotate)
        Ball.runAction(repeatAction, withKey: "rotate")
        
        return Ball
        
    }
    
    
    func drawGround(posPoint : CGPoint) -> SKSpriteNode{
        
        let Ground = SKSpriteNode(imageNamed: "Ground")
        Ground.size = CGSize(width: 1000, height: 100)
        Ground.position = posPoint
        
        Ground.physicsBody = SKPhysicsBody(rectangleOfSize: Ground.size)
        Ground.physicsBody?.affectedByGravity = false
        Ground.physicsBody?.dynamic = false
        Ground.physicsBody?.categoryBitMask = GroundCategory
        Ground.physicsBody?.collisionBitMask = BallCategory
        Ground.physicsBody?.contactTestBitMask = BallCategory
        Ground.physicsBody?.restitution = 0
        Ground.physicsBody?.linearDamping = 1
        Ground.physicsBody?.angularDamping = 1
        Ground.physicsBody?.friction = 0
        
        self.addChild(Ground)
        
        return Ground
    }
    
    
    func drawBlock(position: String, name: String){
        
        let Block = SKShapeNode(rectOfSize: CGSize(width: 50, height: 50))
        Block.fillColor = SKColor.blackColor()
        Block.hidden = true
        
        if(position == "low"){
            Block.name = "blockLow\(name)"
            Block.position = CGPoint(x: -500, y: 170)
        }
        if(position == "mid"){
            Block.name = "blockMid\(name)"
            Block.position = CGPoint(x: -500, y: 240)
        }
        if(position == "high"){
            Block.name = "blockHigh\(name)"
            Block.position = CGPoint(x: -500, y: 310)
        }
        
        Block.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 50, height: 50))
        Block.physicsBody?.affectedByGravity = false
        Block.physicsBody?.dynamic = false
        Block.physicsBody?.allowsRotation = false
        Block.physicsBody?.categoryBitMask = GroundCategory
        Block.physicsBody?.collisionBitMask = BallCategory
        Block.physicsBody?.contactTestBitMask = BallCategory
        Block.physicsBody?.restitution = 0
        Block.physicsBody?.linearDamping = 1
        Block.physicsBody?.angularDamping = 1
        Block.physicsBody?.friction = 0
        
        self.addChild(Block)
        
    }
    
    
    func drawLava(count: Int){
        
        let lavaBlock = SKSpriteNode(imageNamed: "lava_sprite")
        lavaBlock.size = CGSize(width: 250, height: 100)
        lavaBlock.position = CGPoint(x: -500, y: 120)
        lavaBlock.name = "lavaBlock\(count)"
        lavaBlock.hidden = true
        
        lavaBlock.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 250, height: 60))
        lavaBlock.physicsBody?.affectedByGravity = false
        lavaBlock.physicsBody?.dynamic = false
        lavaBlock.physicsBody?.allowsRotation = false
        lavaBlock.physicsBody?.categoryBitMask = LavaCategory
        lavaBlock.physicsBody?.collisionBitMask = BallCategory
        lavaBlock.physicsBody?.contactTestBitMask = BallCategory
        lavaBlock.physicsBody?.restitution = 0
        lavaBlock.physicsBody?.linearDamping = 1
        lavaBlock.physicsBody?.angularDamping = 1
        lavaBlock.physicsBody?.friction = 0
        
        self.addChild(lavaBlock)
        
    }
    
    
    func drawIce(count: Int){
        
        let iceBlock = SKSpriteNode(imageNamed: "ice_sprite")
        iceBlock.size = CGSize(width: 250, height: 100)
        iceBlock.position = CGPoint(x: -500, y: 100)
        iceBlock.name = "iceBlock\(count)"
        iceBlock.hidden = true
        
        iceBlock.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 250, height: 100))
        iceBlock.physicsBody?.affectedByGravity = false
        iceBlock.physicsBody?.dynamic = false
        iceBlock.physicsBody?.allowsRotation = false
        iceBlock.physicsBody?.categoryBitMask = IceCategory
        iceBlock.physicsBody?.collisionBitMask = BallCategory
        iceBlock.physicsBody?.contactTestBitMask = BallCategory
        iceBlock.physicsBody?.restitution = 0
        iceBlock.physicsBody?.linearDamping = 1
        iceBlock.physicsBody?.angularDamping = 1
        iceBlock.physicsBody?.friction = 0
        
        self.addChild(iceBlock)
        
    }
    
    
    func drawClouds(level: String){
        
        if(level == "low1"){
            CloudLow1 = SKSpriteNode(imageNamed: "cloud_sprite")
            CloudLow1.size = CGSize(width: 450, height: 62)
            CloudLow1.position = CGPoint(x: Int(self.frame.width) + Int(arc4random_uniform(400)), y: 250)
            CloudLow1.zPosition = -2
            
            self.addChild(CloudLow1)
        }
        else if(level == "mid1"){
            CloudMid1 = SKSpriteNode(imageNamed: "cloud_sprite")
            CloudMid1.size = CGSize(width: 338, height: 47)
            CloudMid1.position = CGPoint(x: Int(self.frame.width) + Int(arc4random_uniform(400)), y: 400)
            CloudMid1.zPosition = -2
            
            self.addChild(CloudMid1)
        }
        else if(level == "high1"){
            CloudHigh1 = SKSpriteNode(imageNamed: "cloud_sprite")
            CloudHigh1.size = CGSize(width: 562, height: 78)
            CloudHigh1.position = CGPoint(x: Int(self.frame.width) + Int(arc4random_uniform(400)), y: 550)
            CloudHigh1.zPosition = -2
            
            self.addChild(CloudHigh1)
        }
        
    }
    
    
    func drawLabels(){
        
        ScoreLabel.position = CGPoint(x: self.frame.width / 2, y: self.frame.height - 150)
        ScoreLabel.zPosition = 10
        ScoreLabel.fontSize = 40
        ScoreLabel.fontName = "Helvetica Neue Thin"
        ScoreLabel.hidden = true
        self.addChild(ScoreLabel)
        
        HighScoreLabel.position = CGPoint(x: 10, y: self.frame.height - 150)
        HighScoreLabel.zPosition = 10
        HighScoreLabel.fontSize = 26
        HighScoreLabel.fontName = "Helvetica Neue"
        HighScoreLabel.hidden = false
        HighScoreLabel.text = "High Score: \(HighScore)"
        HighScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode(rawValue: 1)!
        self.addChild(HighScoreLabel)
        
    }
    
    
    func drawChoi(){
        
        Sun.position = CGPoint( x: self.frame.width - 100, y: self.frame.height - 200)
        Sun.size = CGSize(width: 100, height: 100)
        Sun.zPosition = -10
        Sun.hidden = false
        
        let rotate = SKAction.rotateByAngle(1, duration: 1)
        let repeatAction = SKAction.repeatActionForever(rotate)
        Sun.runAction(repeatAction, withKey: "rotate")
        
        self.addChild(Sun)
        
        
        Choi.position = Sun.position
        Choi.size = CGSize(width: 80, height: 80)
        Choi.zPosition = -9
        Choi.hidden = false
        
        self.addChild(Choi)
        
    }
    
    
    func drawGameOver(){
        
        GameOverMenu.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        GameOverMenu.zPosition = 20
        GameOverMenu.hidden = true
        self.addChild(GameOverMenu)
        
        PlayAgainButton.position = CGPoint(x: self.frame.width / 2, y: (self.frame.height / 2) + 10)
        PlayAgainButton.size = CGSize(width: 180, height: 90)
        PlayAgainButton.zPosition = 21
        PlayAgainButton.hidden = true
        self.addChild(PlayAgainButton)
        
        MainMenuButton.position = CGPoint(x: self.frame.width / 2, y: (self.frame.height / 2) - 90)
        MainMenuButton.size = CGSize(width: 180, height: 90)
        MainMenuButton.zPosition = 21
        MainMenuButton.hidden = true
        self.addChild(MainMenuButton)
        
    }
    
    
    func drawMusic(){
        
        if let _ : SKSpriteNode = MusicIcon {
            MusicIcon.removeFromParent()
        }
        
        if(muteMusic == false){
            MusicIcon = SKSpriteNode(imageNamed: "greenMusic")
        }
        else{
            MusicIcon = SKSpriteNode(imageNamed: "redMusic")
        }
        MusicIcon.position = CGPoint(x: 40, y: self.frame.height - 200)
        MusicIcon.hidden = false
        MusicIcon.size = CGSize(width: 40, height: 40)
        self.addChild(MusicIcon)
        
    }
    
    
    func drawLevelPick(){
        
        LevelPick.position = CGPoint(x: self.frame.width / 2, y: 340)
        LevelPick.size = CGSize(width: 450, height: 433)
        LevelPick.zPosition = -1
        LevelPick.hidden = true
        self.addChild(LevelPick)
        
        EasyDiff.position = CGPoint(x: self.frame.width / 2, y: 495)
        EasyDiff.zPosition = 1
        EasyDiff.hidden = true
        self.addChild(EasyDiff)
        
        MedDiff.position = CGPoint(x: self.frame.width / 2, y: 388)
        MedDiff.zPosition = 1
        MedDiff.hidden = true
        self.addChild(MedDiff)
        
        HardDiff.position = CGPoint(x: self.frame.width / 2, y: 280)
        HardDiff.zPosition = 1
        HardDiff.hidden = true
        self.addChild(HardDiff)
        
    }
    
    
    func drawDemo(){
        
        DemoButton.position = CGPoint( x: self.frame.width - 88, y: self.frame.height - 350)
        DemoButton.size = CGSize(width: 160, height: 90)
        DemoButton.zPosition = 250
        DemoButton.hidden = false
        self.addChild(DemoButton)
        
    }
    
    
    func drawDemoMode(){
        
        DemoMode.position = CGPoint(x: self.frame.width / 2, y: self.frame.height - 250)
        DemoMode.zPosition = 100
        DemoMode.hidden = false
        self.addChild(DemoMode)
        
    }
    
    
    func drawChoiText(){
        
        self.ChoiBubble.removeFromParent()
        self.ChoiTextLabel.removeFromParent()
        
        ChoiBubble.position = CGPoint( x: self.frame.width - 280, y: self.frame.height - 370)
        ChoiBubble.zPosition = 5
        ChoiBubble.size = CGSize(width: 450, height: 250)
        ChoiBubble.hidden = false
        self.addChild(ChoiBubble)
        
        ChoiTextLabel.position = CGPoint(x: ChoiBubble.position.x, y: ChoiBubble.position.y - 40)
        ChoiTextLabel.zPosition = 6
        ChoiTextLabel.hidden = false
        ChoiTextLabel.text = ChoiTextArr[Int(arc4random_uniform(5))]
        ChoiTextLabel.fontName = "Helvetica Neue Bold"
        ChoiTextLabel.fontSize = 40
        self.addChild(ChoiTextLabel)
    
        let wait = SKAction.waitForDuration(2.0)
        let run = SKAction.runBlock{
            self.ChoiBubble.removeFromParent()
            self.ChoiTextLabel.removeFromParent()
            self.ChoiTalked = false
        }
        runAction(SKAction.sequence([wait, run]))
    
    }
    
    
    func hideLogin(){
        
        LoginMenu.removeFromParent()
        self.view?.willRemoveSubview(EmailField)
        self.EmailField.removeFromSuperview()
        self.view?.willRemoveSubview(PassField)
        self.PassField.removeFromSuperview()
        LoginButton.removeFromParent()
        
    }
    
    
    func drawLogin(){   //preslogin
        
        LoginMenu.position = CGPoint(x: self.frame.width / 2, y: self.frame.height - 250)
        LoginMenu.zPosition = 1
        LoginMenu.hidden = false
        addChild(LoginMenu)
        
        EmailField = UITextField(frame: CGRectMake(self.frame.width / 2, self.frame.height / 2, 180, 45))
        EmailField.hidden = false
        EmailField.textAlignment = NSTextAlignment.Center
        EmailField.keyboardType = UIKeyboardType.Alphabet
        EmailField.keyboardAppearance = UIKeyboardAppearance.Alert
        EmailField.background = UIImage(named: "LoginInput")
        EmailField.textColor = SKColor.whiteColor()
        EmailField.center = CGPoint(x: self.frame.width / 2 - 130, y: 120 )
        EmailField.placeholder = "EMAIL"
        self.view?.addSubview(EmailField)
        
        PassField = UITextField(frame: CGRectMake(self.frame.width / 2, self.frame.height / 2, 180, 45))
        PassField.hidden = false
        PassField.textAlignment = NSTextAlignment.Center
        PassField.keyboardAppearance = UIKeyboardAppearance.Alert
        PassField.background = UIImage(named: "LoginInput")
        PassField.textColor = SKColor.whiteColor()
        PassField.center = CGPoint(x: self.frame.width / 2 - 130, y: 170 )
        PassField.placeholder = "PASSWORD"
        PassField.secureTextEntry = true
        self.view?.addSubview(PassField)
        
        LoginButton.position = CGPoint(x: self.frame.width / 2, y: 350)
        LoginButton.zPosition = 2
        LoginButton.hidden = false
        self.addChild(LoginButton)
        
        Logo.hidden = true
        LevelPick.hidden = true
        EasyDiff.hidden = true
        MedDiff.hidden = true
        HardDiff.hidden = true
        
    }
 
    
    func drawUserIcon(){
    
        UserIcon.removeFromParent()
        
        if(LoggedIn == true){
            UserIcon = SKSpriteNode(imageNamed: "UserIcon2")
        }
        else{
            UserIcon = SKSpriteNode(imageNamed: "UserIcon")
        }
        UserIcon.position = CGPoint(x: MusicIcon.position.x, y: MusicIcon.position.y - 75)
        UserIcon.zPosition = 100
        UserIcon.size = CGSize(width: 50, height: 50)
        self.addChild(UserIcon)
        
    }
    
    
}


