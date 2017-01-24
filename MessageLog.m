#import "MessageLog.h"

@implementation MessageLog

- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.message = @"";
        self.dateInString = @"";
    }
    return self;
}

@end
