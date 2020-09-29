

#import <Foundation/Foundation.h>
#import "LocalStreamManager.h"

//可能的两种分隔符
static const uint8_t KStartCode[4]={0,0,0,1};
//流的分辨率
#define streamW 1920
#define streamH 1080

static int bufferCap = streamH*streamW;
static int bufferSize = 0;
static uint8_t *buffer;     //存放一帧的数据
static BOOL isStop = NO;
static NSInputStream *fileStream = nil;
@interface LocalStreamManager()
{
    
}
@end

@implementation LocalStreamManager

+ (instancetype)shared{
    static LocalStreamManager *localManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localManager = [[LocalStreamManager alloc] init];
    });
    return localManager;
}

+ (void)readStreamFromFile:(NSString *)filePath callBack:(void(^)(NSData *streamData, NSInteger width, NSInteger height))callBack{
    if(!callBack){
        return;
    }
    buffer = malloc(bufferCap);
    fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    if(!fileStream){
        callBack(nil,0,0);
        return;
    }
    [fileStream open];
    isStop = NO;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @autoreleasepool {
            NSData *vp = nil;
            while(!isStop){
                [NSThread sleepForTimeInterval:0.02];
                vp = [self nextPacket];
                if(vp==nil){
                    if(callBack)
                        callBack(nil,0,0);
                    [self destroy];
                    break;
                }
                if(callBack)
                    callBack(vp, streamW, streamH);
            }
        }
        
        [self destroy];
    });

}

+ (void)destroy{
    dispatch_async(dispatch_get_main_queue(), ^{

        isStop = YES;
        if(fileStream){
            [fileStream close];
            fileStream = nil;
        }
        bufferSize = 0;
        if(buffer){
            free(buffer);
            buffer = NULL;
        }
//        memset(buffer, 0, bufferCap);
        
    });
}

+ (NSData *)nextPacket{
    if(bufferSize<bufferCap && fileStream.hasBytesAvailable){
        //读取一帧的数据
        NSInteger readBytes=[fileStream read:buffer+bufferSize maxLength:bufferCap-bufferSize];
        bufferSize+=readBytes;
    }

    if(buffer==NULL)
        return nil;
    //判断是否有公共头
    if(memcmp(buffer, KStartCode, 4)!=0){
        //首位不是头部，就找到头部为止
        int s = [self gainStartIndex:buffer size:bufferSize];
        if(s>0){
            bufferSize = bufferSize-s;
            //把取出的内容从_buffer移除掉
            memmove(buffer, buffer + s, bufferSize);
        }else{
            memset(buffer, 0, bufferCap);
            bufferSize = 0;
        }
    }
    if(bufferSize>=5){
        uint8_t *bufferBegin = buffer + 4;
        uint8_t *bufferEnd = buffer + bufferSize;
        while(bufferBegin!=bufferEnd)
        {
            if(*bufferBegin==0x01){
                //下一个kstartCode开始，取出前面的nalu，每个nalu以KStartCode分割
                if((memcmp(bufferBegin-3,KStartCode,4)==0)){
                    NSInteger packetSize = bufferBegin-buffer-3;

                    NSData *tmpData = [NSData dataWithBytes:buffer length:packetSize];
                    //把取出的内容从_buffer移除掉
                    memmove(buffer, buffer+packetSize, bufferSize-packetSize);
                    bufferSize -= packetSize;
                    return tmpData;
                }
            }
            ++bufferBegin;
        }
    }

    if(bufferSize==0){
        memset(buffer, 0, bufferCap);
        return nil;
    }

    NSData *tmpData = [NSData dataWithBytes:buffer length:bufferSize];
    bufferSize = 0;
    memset(buffer, 0, bufferCap);
    return tmpData;
}

+ (int)gainStartIndex:(uint8_t *)buf size:(int)size{
    int s = -1;
    int headLen = 4;
    for(int i=0;i<size;i++){
        if(i<headLen){
            continue;
        }
        uint8_t *tp = buf + i - headLen;
        if(memcmp(tp, KStartCode, headLen)==0){
            s = i-headLen;
            break;
        }
    }
    return s;
}
@end
