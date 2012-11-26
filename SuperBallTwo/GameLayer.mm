//
//  GameLayer.m
//  SuperBallTwo
//
//  Created by Darrell Payne on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// #define JUMP_IMPULSE 12.5f
#define JUMP_IMPULSE 12.0f
#define WIDTH 320
#define HEIGHT 480

#import "GameLayer.h"
#import "GB2DebugDrawLayer.h"
#import "GB2Sprite.h"
#import "Ball.h"
#import "Launcher.h"
#import "Piston.h"

@implementation GameLayer

-(id) init
{
    if( (self=[super init]))
    {
        // Load all Sprites
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"sprites.plist"];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"Background.plist"];
        
        // Load Box2d Shapes
        [[GB2ShapeCache sharedShapeCache] addShapesWithFile:@"shapes.plist"];
        
        world = [[GB2Engine sharedInstance]world];
        
        // Setup game background layer
        background = [CCSprite spriteWithSpriteFrameName:@"Background.png"];
        [self addChild:background z:0];
        background.anchorPoint = ccp(0,0);
        background.position = ccp(0,0);
        
        // add walls to the left
        GB2Node *leftWall = [[GB2Node alloc] initWithStaticBody:nil node:nil];
        [leftWall addEdgeFrom:b2Vec2FromCC(0, 0) to:b2Vec2FromCC(0, 20000)];
        
        // add walls to the right
        GB2Node *rightWall = [[GB2Node alloc] initWithStaticBody:nil node:nil];
        [rightWall addEdgeFrom:b2Vec2FromCC(320, 0) to:b2Vec2FromCC(320, 20000)];
        
        // Load physics object Launcher
        launcher = [[[Launcher alloc] initWithGameLayer:self] autorelease];
        [self addChild:[launcher ccNode] z:25];
        [launcher setPhysicsPosition:b2Vec2FromCC(60, 0)];
        
        pistonAnimation = [[[Piston alloc] initWithGameLayer:self] autorelease];
        [self addChild:[pistonAnimation ccNode] z:25];
        [pistonAnimation setPhysicsPosition:b2Vec2FromCC(0, 700)];
        [pistonAnimation setActive:NO];
        
        rightPiston = [[[StaticObject alloc]initWithGameLayer:self andObjName:@"PistonRight" andSpriteName:@"PistonRight.png"]autorelease];
        [self addChild:[rightPiston ccNode] z:25];
        [rightPiston setPhysicsPosition:b2Vec2FromCC(187, 700)];
        
        // Setup for the bridge
        bridge = [CCSprite spriteWithSpriteFrameName:@"Bridge.png"];
        [self addChild:bridge];
        bridge.position = ccp(160,250);
        
        // Setup for emitter
        emmitterDevice = [CCSprite spriteWithSpriteFrameName:@"newEmitter01.png"];
        [self addChild:emmitterDevice z:24];
        emmitterDevice.position = ccp(160,400);
        
        //Setup for numbers
        numbers[0] = [CCSprite spriteWithSpriteFrameName:@"NumberThree.png"];
        numbers[0].opacity = 0;
        numbers[0].position = ccp(160,150);
        [self addChild:numbers[0] z:255];
        
        numbers[1] = [CCSprite spriteWithSpriteFrameName:@"NumberTwo.png"];
        numbers[1].opacity = 0;
        numbers[1].position = ccp(160,150);
        [self addChild:numbers[1] z:255];
        
        numbers[2] = [CCSprite spriteWithSpriteFrameName:@"NumberOne.png"];
        numbers[2].opacity = 0;
        numbers[2].position = ccp(160,150);
        [self addChild:numbers[2] z:255];
        
        // Set off particles
        particles = [CCParticleSystemQuad particleWithFile:@"ParticleTest.plist"];
        [self addChild:particles z:22];
        particles.scale = .6;
        particles.position = ccp(160,100);
        
        //particles from pods
        podParticles = [CCParticleSystemQuad particleWithFile:@"ParticleEmitter.plist"];
        podParticles.scale = .75;
        // podParticles.position = ccp(160,375); // Not necessary
        
        // Setup Ball
        ball = [[[Ball alloc] initWithGameLayer:self] autorelease];
        [self addChild:[ball ccNode] z:20];
        [ball setPhysicsPosition:b2Vec2FromCC(160,120)];
        [ball setActive:NO];
        [ball setVisible:NO];
        
        // Tell app to check update function
        [self scheduleUpdate];
        
        // Enable screen touches
        [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
        
        runOnce = false;
        doCountDown = true;
        currNumber = 0; // Start countdown with numberThree;
        
        modeLevel = 0; // current level
        
     }
    return self;
}

-(void) update: (ccTime) dt
{
    curTime += dt;
    
    if (curTime> 5.0f && runOnce == false) {
        
        runOnce = true;
        if (particles != NULL) {
            [self removeChild:particles cleanup:YES];
        }
        [ball setVisible:YES];
        [ball setActive:YES];
    }
    
    
    // Do the countdown here
    
    if (doCountDown && ball.active == YES) {
        ++currCountdown;
        numbers[currNumber].scale += 0.001f;
        if (currCountdown<32) {
            numberOpacity += 4;
            if (numberOpacity>255) {
                numberOpacity = 255;
            }
        }else if (currCountdown>40){
            numberOpacity -= 4;
            if (numberOpacity<0) {
                numberOpacity = 0;
                currCountdown = 0;
                currNumber += 1;
                if (currNumber > 2) {
                    doCountDown = false;
                    currNumber = 2;
                    [launcher setToOpen];
                    [ball applyLinearImpulse:b2Vec2(0,[ball mass]*JUMP_IMPULSE) point:[ball worldCenter]];

                }
            }
        }
        numbers[currNumber].opacity = numberOpacity;
    }
    
    
    // Adjust camera
    float mY = [ball physicsPosition].y * PTM_RATIO;
    const float ballHeight = 50.0f;
    const float screenHeight = 480.0f;
    float cY = mY - ballHeight - screenHeight/2.0f; 
    if(cY < 0)
    {
        cY = 0;
    }
    
    // Lock the bridge into position and start emitter
    if (cY > 300.0f && modeLevel == 0)
    {
        cY = 300.0f;
        modeLevel = 1;
        [self addChild:podParticles z:22];
    }
    
    if (cY < 300.0f && modeLevel == 1) {
        cY = 300.0f;
     }
    
    if(cY > 600.0f && modeLevel == 1){
        modeLevel = 2;
        cY = 600.0f;
    }
    
    if (modeLevel == 2) {
        cY = 600.0f;
    }
    
    
    // Do some parallax scrolling
    [launcher setPhysicsPosition:b2Vec2FromCC(60, -cY)];
    [bridge setPosition:ccp(160, 250-cY)];
    [emmitterDevice setPosition:ccp(160,400-cY)];
    [podParticles setPosition:ccp(160,415-cY)];
    
    [pistonAnimation setPhysicsPosition:b2Vec2FromCC(0, 600-cY)];
    [pistonAnimation updateCCFromPhysics];
    
    [rightPiston setPhysicsPosition:b2Vec2FromCC(227, 600-cY)];
    
    [background setPosition:ccp(0,-cY*0.6)];      // move main background even slower
    
    
    // Attempt to stop the ball at a point above the ejector
    
    float base = 100.0f;
    float targetHeight = 110.0f;
    float distanceAboveGround = mY - base;
    b2Vec2 ballVel = [ball linearVelocity];
    float   springConstant = 0.25f;
    
    //dont do anything if too far above ground
    if ( distanceAboveGround < targetHeight && modeLevel == 1) {
        
        //replace distanceAboveGround with the 'look ahead' distance
        //this will look ahead 0.25 seconds - longer gives more 'damping'
        // Higher numbers reduce 'bounce' of ball
        distanceAboveGround += 2.5f * ballVel.y;
        
        float distanceAwayFromTargetHeight = targetHeight - distanceAboveGround;
        [ball applyForce:b2Vec2(0,springConstant * distanceAwayFromTargetHeight) point:[ball worldCenter]];
        
        //negate gravity
        [ball applyForce:[ball mass] * -world->GetGravity() point:[ball worldCenter]];
 
    }
}

// This method called whenever screen is touched
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {    

    // [launcher setToOpen];
    CGPoint touchLocation = [touch locationInView:[touch view]];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    // b2Vec2 locationWorld = b2Vec2(touchLocation.x/PTM_RATIO, touchLocation.y/PTM_RATIO);
    
    [self selectSpriteForTouch:touchLocation];
    
    
   // [ball applyLinearImpulse:b2Vec2(0,[ball mass]*JUMP_IMPULSE) point:[ball worldCenter]];
    // [piston01 setActive:YES];
    // NSLog(@"Touch made");
            
   //  [self selectSpriteForTouch:touchLocation];
    return TRUE;    
}

- (void)selectSpriteForTouch:(CGPoint)touchLocation {

        if (CGRectContainsPoint(pistonAnimation.ccNode.boundingBoxInPixels, touchLocation))
        {
            if (![pistonAnimation isOpen]) {
                [pistonAnimation openPiston];
                [pistonAnimation setActive:YES];
            }else{
                [pistonAnimation closePiston];
                [pistonAnimation setActive:NO];
            }
            
        }
        if(CGRectContainsPoint(ball.ccNode.boundingBoxInPixels,
                               touchLocation))
        {
            [ball applyLinearImpulse:b2Vec2(0,[ball mass]*JUMP_IMPULSE) point:[ball worldCenter]];
        }
}

+(CCScene *) scene
{
    // 'scene' is an autorelease object.
    CCScene *scene = [CCScene node];
    
    // 'layer' is an autorelease object.
    GameLayer *layer = [GameLayer node];
    
    // add layer as a child to scene
    [scene addChild: layer];
    
    // return the scene
    return scene;
}

@end
