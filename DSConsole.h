#import <UIKit/UIKit.h>

#define NSLog(...) customLogger(__VA_ARGS__)

@interface DSConsole : UIViewController

@property (strong, nonatomic) NSMutableArray *logsContainer;

+ (void)showViewer;
+ (void)hideViewer;
+ (void)registerTwoFingerDoubleTapGesture;
- (NSString*)textFromDate:(NSDate*)date;
void customLogger(NSString *format, ...);

@end
