//
//  GameScene.swift
//  FlappyBird
//
//  Created by 里舘 徹 on 2016/09/15.
//  Copyright © 2016年 tooru.satodate. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var bird: SKSpriteNode!
    var scoreNode: SKNode!
    var enemyNode: SKNode!
    var action: SKAction = SKAction.playSoundFileNamed("se9.wav", waitForCompletion: true)
    var player = AVAudioPlayer()

    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0      // 0...00001
    let groundCategory: UInt32 = 1 << 1   // 0...00010
    let wallCategory: UInt32 = 1 << 2     // 0...00100
    let scoreCategory: UInt32 = 1 << 3    // 0...01000
    let enemyCategory: UInt32 = 1 << 4
    
    // スコア
    var score = 0
    var enemyScore = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabeleNode:SKLabelNode!
    var enemyScoreLabekNode:SKLabelNode!
    var userDefaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: - Life Cycle　SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMoveToView(view: SKView) {
        
        // 重量を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.5)
        physicsWorld.contactDelegate = self
        
        //　背景色を設定
        backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // BGM
        let bgm_url = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("n5", ofType: "mp3")!)
        player = try! AVAudioPlayer(contentsOfURL: bgm_url, fileTypeHint: "mp3")
        player.play()
        
        
        // ゲームオーバーになったときにスクロールを一括で止めることができるように親のノードを作成
        // スクロールするスプライト（画像を表示）の親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のスプライト（画像を表示）の親ノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
    
        // Enemyのスプライト（画像を表示）の親ノード
        enemyNode = SKNode()
        scrollNode.addChild(enemyNode)
        
        setupWall()
        setupGround()
        setupCloud()
        setupBird()
        setupEnemy()
        setupScoreLabel()
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if scrollNode.speed > 0 {
        
        // 鳥の速度をゼロにする
        bird.physicsBody?.velocity = CGVector.zero
        
        // 鳥に縦方向の力を与える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            
        } else if bird.speed == 0 {
            
            restart()
        }
    }
    
     // MARK: - 敵の作成
    func setupEnemy() {
        
        // 敵の画像を読み込む
        let enemyTexture = SKTexture(imageNamed: "enemy")
        enemyTexture.filteringMode = SKTextureFilteringMode.Linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + enemyTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let monvEnemy = SKAction.moveByX(-movingDistance, y: 0, duration: 5.0)
        
        // 自身を取りのぞくアクションを作成
        let removeEnemy = SKAction.removeFromParent()
        
        // 二つのアニメーションを順に実行するアクションを作成
        let enemyAnimation = SKAction.sequence([monvEnemy, removeEnemy])
        
        // enemyを生成するアクションを作成
        let createEnemyAnimation = SKAction.runBlock({
            
            let enemy = SKNode()
            
            enemy.position = CGPoint(x: self.frame.size.width + enemyTexture.size().width / 2, y: 0.0)
            enemy.zPosition = -60.0 // 雲より手前、地面より奥
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            
            // enemyを作成
            let enemyTextu = SKSpriteNode(texture: enemyTexture)
            enemyTextu.position = CGPoint(x: 1.0, y: center_y)
            enemy.addChild(enemyTextu)
            
            // enemyに物理演算を設定する
            enemyTextu.physicsBody = SKPhysicsBody(rectangleOfSize: enemyTexture.size())
            // enemyにカテゴリー設定し、スコア用の物体を追加
            enemyTextu.physicsBody?.categoryBitMask = self.enemyCategory
            
            // 衝突の際に動かないように設定する
            enemyTextu.physicsBody?.dynamic = false
            
            enemy.runAction(enemyAnimation)
            
            self.enemyNode.addChild(enemy)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.waitForDuration(5)
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatActionForever(SKAction.sequence([createEnemyAnimation, waitAnimation]))
        
        runAction(repeatForeverAnimation)
    }
    
    // MARK:　- 壁の作成
    func setupWall() {
    
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = SKTextureFilteringMode.Linear
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveByX(-movingDistance, y: 0, duration:4.0)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.runBlock({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0 // 雲より手前、地面より奥
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            // 壁のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4
            // 下の壁のY軸の下限
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 4
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            
            // スプライトに物理演算を設定する
            under.physicsBody = SKPhysicsBody(rectangleOfSize: wallTexture.size())
            // 壁にカテゴリー設定し、スコア用の物体を追加
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            under.physicsBody?.dynamic = false
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            // スプライトに物理演算を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOfSize: wallTexture.size())
            // 壁にカテゴリー設定し、スコア用の物体を追加
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定する
            upper.physicsBody?.dynamic = false
     
            wall.addChild(upper)
            
            // スコアアップ用のノード　　ーーーここからーーー
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width  + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.dynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            // 衝突することを判定する相手のカテゴリーを設定
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            // ---ここまで---
            
            wall.runAction(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.waitForDuration(2)
        
        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatActionForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        runAction(repeatForeverAnimation)
    }
    
    // MARK: - 鳥の作成
    func setupBird(){
        
        // 鳥の画像を２種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .Linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .Linear
        
        // ２種類のテクスチャを交互に変更するアニメーションを作成
        let texuresAnimation = SKAction.animateWithTextures([birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatActionForever(texuresAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | enemyCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | enemyCategory
        
        // アニメーションを設定
        bird.runAction(flap)
        
        // スプライトを追加する
        addChild(bird)
    }

    // MARK: - 地面の作成
    func setupGround() {
        
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        // 必要な枚数を計算
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveByX(-groundTexture.size().width , y: 0, duration: 5.0)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveByX(groundTexture.size().width , y: 0, duration: 0.0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
        let repeatScrollGround = SKAction.repeatActionForever(SKAction.sequence([moveGround,resetGround]))
        
        // groundのスプライトを配置する
        CGFloat(0).stride(to: needNumber, by: 1.0).forEach { i in
            
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height / 2)
            
            //　スプライトにアクションを設定する
            sprite.runAction(repeatScrollGround)
            
            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOfSize: groundTexture.size())
            
            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突の時に動かないように設定する
            sprite.physicsBody?.dynamic = false
        
            //　スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
     // MARK: - 雲の作成
    func setupCloud()  {
        
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        // 必要な枚数を計算
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveByX(-cloudTexture.size().width, y: 0, duration: 20.0)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveByX(cloudTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
        let repeatScrollClond = SKAction.repeatActionForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        CGFloat(0).stride(to: needCloudNumber, by: 1.0).forEach{ i in
            
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100  // 一番後ろになるようにする
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2 )
            
            // スプライトにアニメーションを設定する
            sprite.runAction(repeatScrollClond)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
            
            }
    }
    
     // MARK: - SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBeginContact(contact: SKPhysicsContact) {
        
        // ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return  player.stop()
        }
        if (contact.bodyA.categoryBitMask & enemyCategory) == enemyCategory || (contact.bodyB.categoryBitMask & enemyCategory) == enemyCategory{
            
            bird.physicsBody?.allowsRotation = false
            
            let action : SKAction = SKAction.playSoundFileNamed("se9.wav", waitForCompletion: true)
            self.runAction(action)
            
            contact.bodyA.node?.removeFromParent()
            
            enemyScore += 1
            enemyScoreLabekNode.text = "赤玉撃破:\(enemyScore)"
            
        } else if  (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory{
            
            // スコア用の物体と衝突した
            print("Scoreup")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            // ベストスコア更新か確認する ---　ここから　---
            var bestScore = userDefaults.integerForKey("BEST")
            
            if score > bestScore {
                
                bestScore = score
                
                bestScoreLabeleNode.text = "Best Score:\(bestScore)"
                
                userDefaults.setInteger(bestScore, forKey: "BEST")
                
                userDefaults.synchronize()
            } // ここまで

        } else {
            // 壁か地面と衝突した
            print("GameOver")
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotateByAngle(CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration: 1)
            
            bird.runAction(roll, completion: {
            self.bird.speed = 0
            })
        }
    }
    
    // MARK: - スコアの作成
    func setupScoreLabel() {
    
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.blackColor()
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabeleNode = SKLabelNode()
        bestScoreLabeleNode.fontColor = UIColor.blackColor()
        bestScoreLabeleNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreLabeleNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabeleNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        
        enemyScore = 0
        enemyScoreLabekNode = SKLabelNode()
        enemyScoreLabekNode.fontColor = UIColor.blackColor()
        enemyScoreLabekNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        enemyScoreLabekNode.zPosition = 100 // 一番手前に表示
        enemyScoreLabekNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        enemyScoreLabekNode.text = "赤玉撃破:\(enemyScore)"
        self.addChild(enemyScoreLabekNode)
        
        let bestScore = userDefaults.integerForKey("BEST")
        bestScoreLabeleNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabeleNode)
        
    }
    
    // MARK: -  リスタート
    func restart() {
        score = 0
        enemyScore = 0
        scoreLabelNode.text = String("Score:\(score)")
        enemyScoreLabekNode.text = String("赤玉撃破:\(enemyScore)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory | enemyCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        enemyNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
        player.play()
    }
}
        
