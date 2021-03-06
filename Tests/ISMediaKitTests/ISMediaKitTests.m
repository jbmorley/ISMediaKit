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

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <ISMediaKit/ISMediaKit.h>

NSInteger ISYearFromDate(NSDate *date)
{
    if (date == nil) {
        return ISMediaKitUnknown;
    }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:date];
    return [components year];
}

@interface ISMediaKitTests : XCTestCase

@property (nonatomic, readwrite, strong) ISMKDatabaseClient *client;

@end

@implementation ISMediaKitTests

- (void)setUp
{
    [super setUp];
    
    self.client = [ISMKDatabaseClient sharedInstance];
    XCTAssertNotNil(self.client, @"Unable to get the shared client instance");
    
    // These keys are for testing purposes only. Please do not use them in your own applications.
    [self.client setTVDBAPIKey:@"C798710FFA249698"
                     mdbAPIKey:@"c39bbdd3113e0716a66d0f64534d2ff6"];
}

- (void)tearDown
{
    [super tearDown];
}

- (NSDictionary *)searchForFilename:(NSString *)filename
{
    __block NSDictionary *result = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [self.client searchWithFilename:filename completionBlock:^(NSDictionary *media) {
        result = media;
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return result;
}

- (void)checkShowWithFilename:(NSString *)filename
                         show:(NSString *)show
                        title:(NSString *)title
                       season:(NSNumber *)season
                      episode:(NSNumber *)episode
{
    NSDictionary *media = [self searchForFilename:filename];
    XCTAssertNotNil(media);
    XCTAssertEqualObjects(media[ISMKKeyType], @(ISMKTypeShow));
    XCTAssertEqualObjects(media[ISMKKeyShowTitle], show);
    XCTAssertEqualObjects(media[ISMKKeyEpisodeTitle], title);
    XCTAssertEqualObjects(media[ISMKKeyEpisodeSeason], season);
    XCTAssertEqualObjects(media[ISMKKeyEpisodeNumber], episode);
}

- (void)testFailedSearchReturnsNil
{
    NSDictionary *media = [self searchForFilename:@"a.show.that.should.never.exist.s03e01.m4v"];
    XCTAssertNil(media);
}

- (void)testArrowS01E01
{
    [self checkShowWithFilename:@"arrow.s01e01.m4v"
                           show:@"Arrow"
                          title:@"Pilot"
                         season:@1
                        episode:@1];
}

- (void)testJeevesAndWooster
{
    [self checkShowWithFilename:@"jeeves.&.wooster.s01e03.m4v"
                           show:@"Jeeves and Wooster"
                          title:@"The Purity of the Turf"
                         season:@1
                        episode:@3];
    
    [self checkShowWithFilename:@"jeeves.and.wooster.s01e03.m4v"
                           show:@"Jeeves and Wooster"
                          title:@"The Purity of the Turf"
                         season:@1
                        episode:@3];
}

- (void)testMarvelsAgentsOfSHIELD
{
    [self checkShowWithFilename:@"marvels.agents.of.s.h.i.e.l.d.s02e09.mp4"
                           show:@"Marvel's Agents of S.H.I.E.L.D."
                          title:@"...Ye Who Enter Here"
                         season:@2
                        episode:@9];
}

- (void)testElementaryConciseFormat
{
    [self checkShowWithFilename:@"elementary.315.noise.mp4"
                           show:@"Elementary"
                          title:@"When Your Number's Up"
                         season:@3
                        episode:@15];
}

- (void)testElementaryConciseFormatShort
{
    [self checkShowWithFilename:@"elementary.315.mp4"
                           show:@"Elementary"
                          title:@"When Your Number's Up"
                         season:@3
                        episode:@15];
}

- (void)testNCISConciseFormat
{
    [self checkShowWithFilename:@"ncis.1215.random.mp4"
                           show:@"NCIS"
                          title:@"Cabin Fever"
                         season:@12
                        episode:@15];
}

- (void)testNCISConciseFormatShort
{
    [self checkShowWithFilename:@"ncis.1215.mp4"
                           show:@"NCIS"
                          title:@"Cabin Fever"
                         season:@12
                        episode:@15];
}

- (void)testBackToTheFuture
{
    NSDictionary *media = [self searchForFilename:@"Back to the Future.m4v"];
    XCTAssertNotNil(media);
    XCTAssertEqualObjects(media[ISMKKeyType], @(ISMKTypeMovie));
    XCTAssertEqualObjects(media[ISMKKeyMovieTitle], @"Back to the Future");
}

- (void)testLadyHawkeNotFound
{
    NSDictionary *media = [self searchForFilename:@"Lady Hawke.m4v"];
    XCTAssertNil(media);
}

- (void)testLadyHawke
{
    NSDictionary *media = [self searchForFilename:@"Ladyhawke.m4v"];
    XCTAssertNotNil(media);
    XCTAssertEqualObjects(media[ISMKKeyType], @(ISMKTypeMovie));
    XCTAssertEqualObjects(media[ISMKKeyMovieTitle], @"Ladyhawke");
}

- (void)testNewRoboCop
{
    NSDictionary *media = [self searchForFilename:@"Robocop.m4v"];
    XCTAssertNotNil(media);
    XCTAssertEqualObjects(media[ISMKKeyType], @(ISMKTypeMovie));
    XCTAssertEqualObjects(media[ISMKKeyMovieTitle], @"RoboCop");
    XCTAssertEqual(ISYearFromDate(media[ISMKKeyMovieDate]), 2014);
}

- (void)testOriginalRoboCop
{
    NSDictionary *media = [self searchForFilename:@"Robocop 1987.m4v"];
    XCTAssertNotNil(media);
    XCTAssertEqualObjects(media[ISMKKeyType], @(ISMKTypeMovie));
    XCTAssertEqualObjects(media[ISMKKeyMovieTitle], @"RoboCop");
    XCTAssertEqual(ISYearFromDate(media[ISMKKeyMovieDate]), 1987);
}

- (void)testOriginalRoboCopParentheses
{
    NSDictionary *media = [self searchForFilename:@"Robocop (1987).m4v"];
    XCTAssertNotNil(media);
    XCTAssertEqualObjects(media[ISMKKeyType], @(ISMKTypeMovie));
    XCTAssertEqualObjects(media[ISMKKeyMovieTitle], @"RoboCop");
    XCTAssertEqual(ISYearFromDate(media[ISMKKeyMovieDate]), 1987);
}

@end
