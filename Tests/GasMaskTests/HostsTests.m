#import <XCTest/XCTest.h>
#import "Hosts.h"

@interface HostsTests : XCTestCase
@property (nonatomic, strong) NSString *tempFilePath;
@end

@implementation HostsTests

- (void)setUp
{
    [super setUp];
    // Create a temporary .hosts file for tests that read from disk
    NSString *tempDir = NSTemporaryDirectory();
    self.tempFilePath = [tempDir stringByAppendingPathComponent:@"TestHosts.hst"];
    [@"127.0.0.1 localhost" writeToFile:self.tempFilePath
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:NULL];
}

- (void)tearDown
{
    [[NSFileManager defaultManager] removeItemAtPath:self.tempFilePath error:NULL];
    [super tearDown];
}

- (void)testInitWithPath
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    XCTAssertNotNil(hosts);
    XCTAssertEqualObjects(hosts.path, self.tempFilePath);
}

- (void)testDefaultState
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    XCTAssertFalse([hosts active]);
    XCTAssertTrue([hosts saved]);
    XCTAssertTrue([hosts enabled]);
    XCTAssertTrue(hosts.editable);
    XCTAssertTrue(hosts.exists);
    XCTAssertNil([hosts error]);
}

- (void)testName
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    // name is last path component without extension
    XCTAssertEqualObjects([hosts name], @"TestHosts");
}

- (void)testFileName
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    XCTAssertEqualObjects([hosts fileName], @"TestHosts.hst");
}

- (void)testContentsReadFromDisk
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    NSString *contents = [hosts contents];
    XCTAssertEqualObjects(contents, @"127.0.0.1 localhost");
}

- (void)testSetContentsMarksDirty
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    XCTAssertTrue([hosts saved]);
    [hosts setContents:@"# modified"];
    XCTAssertFalse([hosts saved]);
    XCTAssertEqualObjects([hosts contents], @"# modified");
}

- (void)testSetContentsNilBecomesEmpty
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    [hosts setContents:nil];
    XCTAssertEqualObjects([hosts contents], @"");
}

- (void)testSaveWritesToDisk
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    [hosts setContents:@"# saved content"];
    [hosts save];
    XCTAssertTrue([hosts saved]);

    NSString *onDisk = [NSString stringWithContentsOfFile:self.tempFilePath
                                                 encoding:NSUTF8StringEncoding
                                                    error:NULL];
    XCTAssertEqualObjects(onDisk, @"# saved content");
}

- (void)testSetActiveTogglesState
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    XCTAssertFalse([hosts active]);
    [hosts setActive:YES];
    XCTAssertTrue([hosts active]);
    [hosts setActive:NO];
    XCTAssertFalse([hosts active]);
}

- (void)testSetEnabledTogglesState
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    XCTAssertTrue([hosts enabled]);
    [hosts setEnabled:NO];
    XCTAssertFalse([hosts enabled]);
}

- (void)testSelectableRespectedByEnabled
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    XCTAssertTrue([hosts selectable]);
    [hosts setEnabled:NO];
    XCTAssertFalse([hosts selectable]);
}

- (void)testTypeIsLocal
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    XCTAssertEqualObjects([hosts type], @"Local");
}

- (void)testContentsOnDiskReturnsCurrentFileContent
{
    Hosts *hosts = [[Hosts alloc] initWithPath:self.tempFilePath];
    NSString *onDisk = [hosts contentsOnDisk];
    XCTAssertEqualObjects(onDisk, @"127.0.0.1 localhost");
}

@end
