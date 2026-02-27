#import <XCTest/XCTest.h>
#import "AbstractHostsController.h"
#import "Hosts.h"
#import "HostsGroup.h"

// Concrete subclass for testing (groupName would be nil on the abstract base)
@interface TestHostsController : AbstractHostsController
@end

@implementation TestHostsController
- (NSString *)groupName { return @"TestGroup"; }
@end

@interface AbstractHostsControllerTests : XCTestCase
@property (nonatomic, strong) TestHostsController *controller;
@property (nonatomic, strong) NSString *tempDir;
@end

@implementation AbstractHostsControllerTests

- (void)setUp
{
    [super setUp];
    self.controller = [[TestHostsController alloc] init];
    self.tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"GasMaskTests"];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.tempDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
}

- (void)tearDown
{
    [[NSFileManager defaultManager] removeItemAtPath:self.tempDir error:NULL];
    [super tearDown];
}

// Helper: add a Hosts file with the given name to the controller
- (Hosts *)addHostsWithName:(NSString *)name
{
    NSString *path = [self.tempDir stringByAppendingPathComponent:
                      [name stringByAppendingPathExtension:HostsFileExtension]];
    [@"" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    Hosts *hosts = [[Hosts alloc] initWithPath:path];
    [self.controller.hostsFiles addObject:hosts];
    return hosts;
}

#pragma mark - hostsGroup

- (void)testHostsGroupCreatedWithGroupName
{
    XCTAssertNotNil([self.controller hostsGroup]);
    XCTAssertEqualObjects([[self.controller hostsGroup] name], @"TestGroup");
}

#pragma mark - hostsExists:

- (void)testHostsExistsReturnsFalseWhenEmpty
{
    XCTAssertFalse([self.controller hostsExists:@"Anything"]);
}

- (void)testHostsExistsReturnsTrueForExistingName
{
    [self addHostsWithName:@"MyFile"];
    XCTAssertTrue([self.controller hostsExists:@"MyFile"]);
}

- (void)testHostsExistsReturnsFalseForDifferentName
{
    [self addHostsWithName:@"MyFile"];
    XCTAssertFalse([self.controller hostsExists:@"OtherFile"]);
}

#pragma mark - generateName:

- (void)testGenerateNameReturnsPrefixWhenUnique
{
    NSString *name = [self.controller generateName:@"New File"];
    XCTAssertEqualObjects(name, @"New File");
}

- (void)testGenerateNameAppendsNumberWhenNameExists
{
    [self addHostsWithName:@"New File"];
    NSString *name = [self.controller generateName:@"New File"];
    XCTAssertEqualObjects(name, @"New File 2");
}

- (void)testGenerateNameIncrementsUntilUnique
{
    [self addHostsWithName:@"New File"];
    [self addHostsWithName:@"New File 2"];
    NSString *name = [self.controller generateName:@"New File"];
    XCTAssertEqualObjects(name, @"New File 3");
}

#pragma mark - constructPath:withName:

- (void)testConstructPath
{
    NSString *path = [self.controller constructPath:@"/tmp/" withName:@"myfile"];
    XCTAssertEqualObjects(path, @"/tmp/myfile.hst");
}

#pragma mark - hostsFileByFileName:

- (void)testHostsFileByFileNameFound
{
    Hosts *hosts = [self addHostsWithName:@"Target"];
    Hosts *found = [self.controller hostsFileByFileName:@"Target.hst"];
    XCTAssertEqualObjects(found, hosts);
}

- (void)testHostsFileByFileNameNotFound
{
    [self addHostsWithName:@"Target"];
    Hosts *found = [self.controller hostsFileByFileName:@"Missing.hst"];
    XCTAssertNil(found);
}

#pragma mark - activeHostsFile

- (void)testActiveHostsFileReturnsNilWhenNoneActive
{
    [self addHostsWithName:@"A"];
    [self addHostsWithName:@"B"];
    XCTAssertNil([self.controller activeHostsFile]);
}

- (void)testActiveHostsFileReturnsActiveOne
{
    [self addHostsWithName:@"A"];
    Hosts *b = [self addHostsWithName:@"B"];
    [b setActive:YES];
    XCTAssertEqualObjects([self.controller activeHostsFile], b);
}

@end
