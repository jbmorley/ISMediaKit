//
// Copyright (c) 2013-2014 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "ISMKShowParser.h"

@interface ISMKShowParser ()

@property (nonatomic, readwrite, copy) NSString *show;
@property (nonatomic, readwrite, copy) NSNumber *season;
@property (nonatomic, readwrite, copy) NSNumber *episode;

@property (nonatomic, strong) NSRegularExpression *regex;
@property (nonatomic, strong) NSRegularExpression *regexConcise;

@end

static NSString *ShowPattern = @"^(.+)\\.s(\\d{2})e(\\d{2})";
static NSString *ShowPatternConcise = @"^(.+)\\.(\\d{1,2}?)(\\d{1,2})(\\..+)?$";

@implementation ISMKShowParser

- (id)init
{
    self = [super init];
    if (self) {
        self.regex = [NSRegularExpression regularExpressionWithPattern:ShowPattern
                                                               options:NSRegularExpressionCaseInsensitive
                                                                 error:nil];
        self.regexConcise = [NSRegularExpression regularExpressionWithPattern:ShowPatternConcise
                                                                      options:NSRegularExpressionCaseInsensitive
                                                                        error:nil];
    }
    return self;
}


- (BOOL)parse:(NSString *)string
{
    NSRange range = NSMakeRange(0, string.length);
    if ([self.regex numberOfMatchesInString:string options:0 range:range] > 0) {
        
        NSTextCheckingResult *textCheckingResult = [self.regex firstMatchInString:string options:0 range:range];
        NSRange matchRange;
        NSString *match;
        
        // Show.
        matchRange = [textCheckingResult rangeAtIndex:1];
        self.show = [string substringWithRange:matchRange];
        
        // Season.
        matchRange = [textCheckingResult rangeAtIndex:2];
        match = [string substringWithRange:matchRange];
        self.season = [NSNumber numberWithInteger:[match integerValue]];
        
        // Episode.
        matchRange = [textCheckingResult rangeAtIndex:3];
        match = [string substringWithRange:matchRange];
        self.episode = [NSNumber numberWithInteger:[match integerValue]];
        
        return YES;
        
    } else if ([self.regexConcise numberOfMatchesInString:string options:0 range:range] > 0) {
        
        NSTextCheckingResult *textCheckingResult = [self.regexConcise firstMatchInString:string options:0 range:range];
        NSRange matchRange;
        NSString *match;
        
        // Show.
        matchRange = [textCheckingResult rangeAtIndex:1];
        self.show = [string substringWithRange:matchRange];
        
        // Season.
        matchRange = [textCheckingResult rangeAtIndex:2];
        match = [string substringWithRange:matchRange];
        self.season = [NSNumber numberWithInteger:[match integerValue]];
        
        // Episode.
        matchRange = [textCheckingResult rangeAtIndex:3];
        match = [string substringWithRange:matchRange];
        self.episode = [NSNumber numberWithInteger:[match integerValue]];
        
        return YES;
        
    }
    
    return NO;
}

@end
