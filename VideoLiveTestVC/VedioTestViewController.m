

#import "VedioTestViewController.h"

#import "LocalStreamManager.h"
#import <sys/utsname.h>
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface VedioTestViewController ()
{
    BOOL _isFirst;
}

@property(nonatomic) UIButton *startBtn;
@property(nonatomic) IJKFFMoviePlayerController *videoPlayer;
@end

@implementation VedioTestViewController

- (void)dealloc{
    NSLog(@">>>dealloc");

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)setupUI{
    self.title=@"Test view";
    self.view.backgroundColor = [UIColor whiteColor];
    
//    [self showCpu];
//    [self testOther];
    [self testHardDecode];
}

- (void)didMoveToParentViewController:(UIViewController *)parent{
    if(parent==nil){
        [LocalStreamManager destroy];
        [self.videoPlayer stop];
    }
}

- (NSString *)getDocumentWithFile:(NSString *)filename{
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    char ss = [documentsDirectory characterAtIndex:0];
    if(ss=='/')
    {
        documentsDirectory = [documentsDirectory substringFromIndex:1];
    }
    
    return [NSString stringWithFormat:@"%@/%@",documentsDirectory,filename];
}

- (void)testHardDecode{

    _isFirst = YES;
    __weak VedioTestViewController *weakSelf = self;
    
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"movieH264" ofType:@"ts"];
//    NSString *videoPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"Video_Test_File"];
//    NSString *videoPath = [self getDocumentWithFile:@"movieH264.ts"];
//    NSString *videoPath = [self getDocumentWithFile:@"afei.mp4"];
//    NSString *videoPath = @"https://eufy-security-pr.s3-us-west-2.amazonaws.com/overall/eufy.doorbell.v3.en.mp4";
    if(![[NSFileManager defaultManager] fileExistsAtPath:videoPath]){
        NSLog(@"videoFile is not Exist!!!!");
        return;
    }
    
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    self.videoPlayer = [[IJKFFMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:videoPath] withOptions:options];
//    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.videoPlayer.view.frame = CGRectMake(10, 100, self.view.bounds.size.width-20, 280);
//    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.videoPlayer.shouldAutoplay = YES;

//    self.view.autoresizesSubviews = YES;
    [self.view addSubview:self.videoPlayer.view];
    
    [self.videoPlayer prepareToPlay];
    [self.videoPlayer play];
    
    [LocalStreamManager readStreamFromFile:videoPath callBack:^(NSData * _Nonnull streamData, NSInteger width, NSInteger height) {
//        NSLog(@">>>>>%@",[streamData subdataWithRange:NSMakeRange(0, streamData.length>128?128:streamData.length)]);
        [weakSelf decodeDatas:streamData width:width height:height];
    }];
    
    [self.view addSubview:self.startBtn];
}
- (void)decodeDatas:(NSData *)data width:(NSInteger)width height:(NSInteger)height{
    
    [self.videoPlayer inputFrameData:data];
    
//    if(_isFirst&&data.length>0){
//        _isFirst = NO;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.videoPlayer prepareToPlay];
//        });
//    }
}


- (void)btnAction:(UIButton *)sender{
//    [self.tcpClient startConnect:@"192.168.50.41"];
//    [self testHardDecode];
    [self.videoPlayer prepareToPlay];
    [self.videoPlayer play];
}



- (UIButton *)startBtn{
    if(!_startBtn){
        _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _startBtn.frame = CGRectMake(0, CGRectGetMaxY(self.videoPlayer.view.frame)+50, 100, 32);
        _startBtn.center = CGPointMake(self.view.center.x, _startBtn.center.y);
        [_startBtn setTitle:@"start" forState:UIControlStateNormal];
        [_startBtn setBackgroundColor:[UIColor yellowColor]];
        [_startBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBtn;
}

@end
