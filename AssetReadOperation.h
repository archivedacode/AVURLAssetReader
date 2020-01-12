//
//  AssetReadOperation.h
//
//
//  Created by David Ross on 04/01/2013.
//  Copyright © 2013 David Ross. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AssetReadOperationDelegate;

@interface AssetReadOperation : NSOperation
{
    BOOL _Finished;
    BOOL _Executing;
}

- (id)initWithDelegate:(id)delegate_ asset:(AVURLAsset*)asset_;

@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, assign) id <AssetReadOperationDelegate> delegate;

- (void)start;

@end

#pragma mark - Delegate

@protocol AssetReadOperationDelegate <NSObject>
- (void)readingAssetError;
- (void)readingAssetStatus:(AVAssetReaderStatus)status;
@end
