#import "PlayerViewController.h"
#import "InfoViewController.h"
#import "AudioStreamer.h"
#import <CFNetwork/CFNetwork.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Reachability.h"

@implementation PlayerViewController

@synthesize volumeSlider;
@synthesize playbackButton;

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (void)viewDidAppear:(BOOL)animated {
  [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
  [self becomeFirstResponder];
}


- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
  switch (event.subtype) {
    case UIEventSubtypeRemoteControlTogglePlayPause:
      if ([streamer isPlaying])
      {
        [streamer pause];
      } else {
        [streamer start];
      }
      break;
    default:
      break;
  }
}


- (void)destroyStreamer
{
  if (streamer)
  {
    [streamer stop];
    [streamer release];
    streamer = nil;
  }
}

- (void)createStreamer
{
  if (streamer)
  {
    return;
  }
  [self destroyStreamer];
  
  NSURL *url = [NSURL URLWithString:@"http://www.live365.com/play/chirpradio"];
  streamer = [[AudioStreamer alloc] initWithURL:url];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playbackStateChanged:)
                                               name:ASStatusChangedNotification
                                             object:streamer];  
}

- (IBAction)playbackButtonPressed:(id)sender
{
  if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable){
    [self alertNoConnection];
    return;
  }

  if ([streamer isPlaying])
  {
    [streamer pause];
  } else {
    [streamer start];
  }
}

- (void)playbackStateChanged:(NSNotification *)aNotification
{
  UIApplication *app = [UIApplication sharedApplication];
  if ([streamer isWaiting])
  {
    app.networkActivityIndicatorVisible = YES;
  }
  else if ([streamer isPlaying])
  {
    [playbackButton setImage:[UIImage imageNamed:@"pauseButton.png"] forState:UIControlStateNormal];
    app.networkActivityIndicatorVisible = NO;
  }
  else if ([streamer isPaused])
  {
    [playbackButton setImage:[UIImage imageNamed:@"playButton.png"] forState:UIControlStateNormal];
    app.networkActivityIndicatorVisible = NO;
  }
  else if ([streamer isIdle])
  {
    // streamer goes idle when Internet connectivity is lost
    [self destroyStreamer];
    [self createStreamer];
    [playbackButton setImage:[UIImage imageNamed:@"playButton.png"] forState:UIControlStateNormal];
    app.networkActivityIndicatorVisible = NO;
  }
}

- (void)alertNoConnection
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Streaming Error" message:@"No Internet Connection"
												   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];   
    [alert release];
}

- (void)reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:curReach
{
  NetworkStatus netStatus = [curReach currentReachabilityStatus];
  if (netStatus == NotReachable) {
    [self alertNoConnection];
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
  [volumeSlider release];
  [playbackButton release];
  [hostReach release];
  [super dealloc];
}

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
  // method "reachabilityChanged" will be called. 
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	
	hostReach = [[Reachability reachabilityWithHostName: @"www.live365.com"] retain];
	[hostReach startNotifer];

  MPVolumeView *volumeView = [[[MPVolumeView alloc] initWithFrame:volumeSlider.bounds] autorelease];
  [volumeSlider addSubview:volumeView];
  [volumeView sizeToFit];
  
  [self createStreamer];
  [streamer start];
}

- (IBAction)showInfoView:(id)sender {
  InfoViewController *infoController = [[InfoViewController alloc] initWithNibName:@"InfoViewController" bundle:nil];
  infoController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentModalViewController:infoController animated:YES];
  [infoController release];
}

@end
