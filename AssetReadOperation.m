//
//  AssetReadOperation.m
//
//
//  Created by David Ross on 04/01/2013.
//  Copyright © 2013 David Ross. All rights reserved.
//

#import "AssetReadOperation.h"

@interface AssetReadOperation ()

@end

@implementation AssetReadOperation

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _Finished = NO;
        _Executing = NO;
    }
    return self;
}

- (id)initWithDelegate:(id)delegate_ asset:(AVURLAsset*)asset_
{
    self = [super init];
    
    if (self)
    {
        self.delegate = delegate_;
        self.asset = asset_;
        
        _Finished = NO;
        _Executing = NO;
    }
    return self;
}

- (void)start
{
    if (_asset == nil || _delegate == nil)
    {
        [self setExecuting:NO finished:YES];
        return;
    }
    
    [self setExecuting:YES finished:NO];
    
    NSError *error = nil;
    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:&error];
    
    if (error != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self delegate] readingAssetError];
        });
        
        [self setExecuting:NO finished:YES];
        return;
    }
    
    AudioChannelLayout acl;
    bzero(&acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                              [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                              [NSNumber numberWithInt:32], AVLinearPCMBitDepthKey,
                              [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                              [NSNumber numberWithBool:YES], AVLinearPCMIsFloatKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                              [NSData dataWithBytes:&acl length:sizeof(AudioChannelLayout)], AVChannelLayoutKey, nil];
    
    AVAssetReaderAudioMixOutput *assetReaderOut =
    [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:[self.asset tracksWithMediaType:AVMediaTypeAudio] audioSettings:settings];
    
    if (![assetReader canAddOutput:(AVAssetReaderOutput*)assetReaderOut])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self delegate] readingAssetError];
        });
        
        [self setExecuting:NO finished:YES];
        return;
    }
    [assetReader addOutput:(AVAssetReaderOutput *)assetReaderOut];
    
    bool bDidStart = [assetReader startReading];
    if (!bDidStart)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self delegate] readingAssetError];
        });
        
        [self setExecuting:NO finished:YES];
        return;
    }
    
    NSLog(@"Start...");
    
    int32_t totalBytes = 0;
        
    while (!self.isCancelled && assetReader.status == AVAssetReaderStatusReading)
    {
        CMBlockBufferRef blockRef = nil;
        CMSampleBufferRef sampleRef = [assetReaderOut copyNextSampleBuffer];
        
        AudioBufferList abl;
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleRef, 0, &abl, sizeof(abl), 0, 0, 0, &blockRef);
        
        if (self.isCancelled)
        {
            if (sampleRef)
            {
                CMSampleBufferInvalidate(sampleRef);
                CFRelease(sampleRef);
                sampleRef = nil;
            }
            
            if (blockRef)
            {
                CFRelease(blockRef);
                blockRef = nil;
            }
            
            break;
        }
        else
        {
            int32_t receivedBytes = abl.mBuffers[0].mDataByteSize;
            
            totalBytes += receivedBytes;
        }
    }
    
    NSLog(@"totalBytes: %d", totalBytes);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self delegate] readingAssetStatus:assetReader.status];
    });
        
    [self setExecuting:NO finished:YES];
}

- (void)setExecuting:(BOOL)executing finished:(BOOL)finished
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _Executing = executing;
    _Finished = finished;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - Overrides

- (BOOL)isExecuting
{
    return _Executing;
}

- (BOOL)isFinished
{
    return _Finished;
}

@end

