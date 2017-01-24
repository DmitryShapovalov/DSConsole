#import "DSConsole.h"
#import "MessageLog.h"

@interface DSConsole () {

    NSRange currentRangeInSearch;
}

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *reloadButton;
@property (strong, nonatomic) IBOutlet UITextField *searchField;
@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic) BOOL loadingLogs;

@end

@implementation DSConsole

#pragma mark - public

+ (void)showViewer {
    
    [[self sharedInstance] showInOwnWindow];
}

+ (void)hideViewer {

    [[self sharedInstance] hideOwnWindow];
}

void customLogger(NSString *format, ...) {

    va_list argumentList;
    va_start(argumentList, format);
    NSMutableString * message = [[NSMutableString alloc] initWithFormat:format arguments:argumentList];

    MessageLog *log = [[MessageLog alloc] init];
    log.message = message;
    log.dateInString = [NSString stringWithFormat:@"%@", [[DSConsole sharedInstance] textFromDate:[NSDate date]]];

    [[DSConsole sharedInstance].logsContainer addObject:log];

    NSLogv(message, argumentList);
    va_end(argumentList);
}

+ (void)registerTwoFingerDoubleTapGesture {

    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showViewer)];
    [recognizer setNumberOfTouchesRequired:2];
    [recognizer setNumberOfTapsRequired:2];
    
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
    if (!mainWindow)
        mainWindow = [[[UIApplication sharedApplication] delegate] window];
    [mainWindow addGestureRecognizer:recognizer];
}

- (NSString*)textFromDate:(NSDate*)date {

    NSDate *currentDate = date;
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YY-MM-dd HH:mm:ss"];

    return [dateFormat stringFromDate:currentDate];
}

#pragma mark - private

+ (instancetype)sharedInstance {

    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {

    self = [super init];
    if (self) {

        self.logsContainer = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)showInOwnWindow {

    if(!self.window) {

        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.window.windowLevel = UIWindowLevelAlert;
        self.window.rootViewController = self;
    }

    [self.window makeKeyAndVisible];
    [self refreshLogs];
}

- (void)hideOwnWindow {

    self.textView.selectedTextRange = nil;
    self.window.hidden = YES;
}

#pragma mark - view controller

- (void)viewDidLoad {

    [super viewDidLoad];

    self.textView.text = @"LOADING...";
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"SEARCH"
                                                                             attributes:@{ NSForegroundColorAttributeName: [UIColor lightGrayColor] }];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tapGesture];
    
    [self refreshLogs];
}

- (void)hideKeyboard {

    [self.view endEditing:YES];
}

- (void)refreshLogs {

    if (self.loadingLogs)
        return;
    
    self.loadingLogs = YES;
    self.reloadButton.enabled = NO;
    [self asyncReadDeviceLogsWithCompletionBlock:^(NSString *logs) {
        self.textView.text = logs;
        self.reloadButton.enabled = YES;
        self.loadingLogs = NO;
        [self scrollToBottom];
    }];
}

- (void)scrollToBottom {

    if (self.textView.text.length > 0) {

        NSRange range = NSMakeRange(self.textView.text.length - 1, 1);
        [self.textView scrollRangeToVisible:range];
    }
}

- (IBAction)searchAction:(id)sender {

    NSString *search = self.searchField.text;
    NSString *text = self.textView.text;
    
    NSRange currentRange = currentRangeInSearch;
    NSRange range = [text rangeOfString:search options:NSCaseInsensitiveSearch];
    
    if (currentRange.location != NSNotFound && currentRange.location + 1 <= [text length]) {

        range = [text rangeOfString:search options:NSCaseInsensitiveSearch range:NSMakeRange(currentRange.location + 1, [text length] - currentRange.location - 1)];
    }
    
    if (range.location == NSNotFound) {

        range = [text rangeOfString:search options:NSCaseInsensitiveSearch];
    }
    
    if (range.location != NSNotFound) {

        currentRangeInSearch = range;
        NSMutableAttributedString *mutableAttString = [[NSMutableAttributedString alloc] initWithString:self.textView.text];
        [mutableAttString addAttribute:NSBackgroundColorAttributeName value:[UIColor clearColor] range:NSMakeRange(0, self.textView.text.length)];
        [mutableAttString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, self.textView.text.length)];
        [mutableAttString addAttribute:NSBackgroundColorAttributeName value:[UIColor yellowColor] range:range];
        [mutableAttString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range];
        self.textView.attributedText = mutableAttString;
        [self.textView scrollRangeToVisible:range];
    }
}

- (IBAction)searchBackwardAction:(id)sender {

    NSString *search = self.searchField.text;
    NSString *text = self.textView.text;
    
    NSRange currentRange = currentRangeInSearch;
    NSRange range = [text rangeOfString:search options:NSCaseInsensitiveSearch | NSBackwardsSearch];
    
    if (currentRange.location != NSNotFound && (NSInteger)currentRange.location - 1 >= 0) {

        range = [text rangeOfString:search options:NSCaseInsensitiveSearch | NSBackwardsSearch range:NSMakeRange(0, currentRange.location - 1)];
    }
    
    if (range.location == NSNotFound) {

        range = [text rangeOfString:search options:NSCaseInsensitiveSearch | NSBackwardsSearch];
    }
    
    if (range.location != NSNotFound) {

        currentRangeInSearch = range;
        NSMutableAttributedString *mutableAttString = [[NSMutableAttributedString alloc] initWithString:self.textView.text];
        [mutableAttString addAttribute:NSBackgroundColorAttributeName value:[UIColor clearColor] range:NSMakeRange(0, self.textView.text.length)];
        [mutableAttString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, self.textView.text.length)];
        [mutableAttString addAttribute:NSBackgroundColorAttributeName value:[UIColor yellowColor] range:range];
        [mutableAttString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range];
        self.textView.attributedText = mutableAttString;
        [self.textView scrollRangeToVisible:range];
    }
}

- (IBAction)cleanHistoryAction:(id)sender {

    [self.logsContainer removeAllObjects];
    [self refreshLogs];
}

- (IBAction)refreshAction:(id)sender {

    currentRangeInSearch = NSMakeRange(0, 0);
    [self refreshLogs];
}

- (IBAction)closeAction:(id)sender {

    [self hideOwnWindow];
}

- (IBAction)searchEditingDidBegin:(id)sender {

    currentRangeInSearch = NSMakeRange(0, 0);
    self.searchField.attributedPlaceholder = nil;
}

- (IBAction)searchEditingDidEnd:(id)sender {

    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"SEARCH" attributes:@{ NSForegroundColorAttributeName: [UIColor lightGrayColor] }];
}

#pragma mark - logs reading

- (void)asyncReadDeviceLogsWithCompletionBlock:(void (^)(NSString *logs))completionBlock {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSString *logs = [self readDeviceLogs];

        dispatch_async(dispatch_get_main_queue(), ^{

            if (completionBlock)

                completionBlock(logs);

        });
    });
}

- (NSString *)readDeviceLogs {

    NSMutableString *logs = [NSMutableString stringWithString:@""];

    for (MessageLog *log in self.logsContainer) {

        [logs appendString:[NSString stringWithFormat:@"[%@] %@\n", log.dateInString, log.message]];
    }

    return logs;
}

@end
