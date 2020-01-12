# AVURLAssetReader

A subclass of NSOperation to read the raw binary data from an AVURLAsset.

Here I read the data from AVURLAsset. You can configure up the format for which you want to read.

Here I'm reading at 32 bits, 44.1kHz, 2 channels, Float point, interleaved (samples in the sequence LRLRLRLR..)

You simply add the operation to an NSOperationQueue, and away it goes..

If you want to stop the read process, you can just cancel the operation and it exits.

This is a very much reduced version, it simply loops to read all the data.
You could use this as a way to populate a circular buffer, for example, with the relevant sleep/waits.

Once the data is in the circular buffer, you simply read it off, for example, in a RemoteIO audio unit callback.

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData)
{
    AudioPlayer *player = (__bridge AudioPlayer*)inRefCon;
    Float32 *targetBuffer = (Float32*)ioData->mBuffers[0].mData;
    int totalFrames = (ioData->mBuffers[0].mDataByteSize / SIZEOF_FLOAT32) * 0.5;
        
    int32_t bytesAvailable = 0;
    Float32 *buffer_Main = (Float32*)CircularBufferTail(&player->buffer_Main, &bytesAvailable);
        
    int frames_Main = bytesAvailable / SIZEOF_FLOAT32 * 0.5;
    frames_Main = MIN(frames_Main, totalFrames);
        
    @synchronized(player)
    {
        Float32 xL = 0.0;
        Float32 xR = 0.0;
        
        int i, j;
        for (i=0, j=0; i<totalFrames; i++, j+=2)
        {
            xL = 0.0;
            xR = 0.0;
            
            if (frames_Main > i)
            {
                xL = buffer_Main[j];
                xR = buffer_Main[j+1];
            }
            
            targetBuffer[j] = xL;
            targetBuffer[j+1] = xR;
        }
    }
    
    CircularBufferConsume(&player->buffer_Main, frames_Main*TWO_SIZEOF_FLOAT32);
    
    return noErr;
}
