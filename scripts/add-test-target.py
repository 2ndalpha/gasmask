#!/usr/bin/env python3
"""
Adds a "Gas Mask Tests" XCTest unit-test bundle target to Gas Mask.xcodeproj/project.pbxproj
and wires it into the existing Gas Mask.xcscheme.

Fixed UUIDs used (all CC2B3C4D5E6F0001XXXXXXXX):
  00000001 – PBXNativeTarget  "Gas Mask Tests"
  00000002 – XCBuildConfiguration Debug
  00000003 – XCBuildConfiguration Release
  00000004 – XCConfigurationList
  00000005 – PBXSourcesBuildPhase
  00000006 – PBXFrameworksBuildPhase
  00000007 – PBXResourcesBuildPhase
  00000010 – PBXFileReference NodeTests.m
  00000011 – PBXFileReference HostsTests.m
  00000012 – PBXFileReference HostsGroupTests.m
  00000013 – PBXFileReference AbstractHostsControllerTests.m
  00000020 – PBXFileReference Gas Mask Tests.xctest (product)
  00000030 – PBXGroup "Tests"
  00000031 – PBXGroup "GasMaskTests"
  00000040 – PBXBuildFile NodeTests.m in Sources
  00000041 – PBXBuildFile HostsTests.m in Sources
  00000042 – PBXBuildFile HostsGroupTests.m in Sources
  00000043 – PBXBuildFile AbstractHostsControllerTests.m in Sources
"""

import sys
import os
import re

PROJECT_PATH = os.path.join(os.path.dirname(__file__), '..', 'Gas Mask.xcodeproj', 'project.pbxproj')
SCHEME_PATH  = os.path.join(os.path.dirname(__file__), '..', 'Gas Mask.xcodeproj',
                             'xcshareddata', 'xcschemes', 'Gas Mask.xcscheme')

ALL_UUIDS = [
    'CC2B3C4D5E6F000100000001',
    'CC2B3C4D5E6F000100000002',
    'CC2B3C4D5E6F000100000003',
    'CC2B3C4D5E6F000100000004',
    'CC2B3C4D5E6F000100000005',
    'CC2B3C4D5E6F000100000006',
    'CC2B3C4D5E6F000100000007',
    'CC2B3C4D5E6F000100000010',
    'CC2B3C4D5E6F000100000011',
    'CC2B3C4D5E6F000100000012',
    'CC2B3C4D5E6F000100000013',
    'CC2B3C4D5E6F000100000020',
    'CC2B3C4D5E6F000100000030',
    'CC2B3C4D5E6F000100000031',
    'CC2B3C4D5E6F000100000040',
    'CC2B3C4D5E6F000100000041',
    'CC2B3C4D5E6F000100000042',
    'CC2B3C4D5E6F000100000043',
]

def validate_no_uuid_conflicts(pbxproj):
    for uuid in ALL_UUIDS:
        if uuid in pbxproj:
            print(f'ERROR: UUID {uuid} already exists in project.pbxproj. Aborting.')
            sys.exit(1)
    print('UUID collision check passed.')

def check_already_applied(pbxproj):
    if 'Gas Mask Tests' in pbxproj:
        print('ERROR: "Gas Mask Tests" already present in project.pbxproj. Already applied?')
        sys.exit(1)

# ── PBXBuildFile section ───────────────────────────────────────────────────

BUILD_FILE_ENTRIES = """\
\t\tCC2B3C4D5E6F000100000040 /* NodeTests.m in Sources */ = {isa = PBXBuildFile; fileRef = CC2B3C4D5E6F000100000010 /* NodeTests.m */; };
\t\tCC2B3C4D5E6F000100000041 /* HostsTests.m in Sources */ = {isa = PBXBuildFile; fileRef = CC2B3C4D5E6F000100000011 /* HostsTests.m */; };
\t\tCC2B3C4D5E6F000100000042 /* HostsGroupTests.m in Sources */ = {isa = PBXBuildFile; fileRef = CC2B3C4D5E6F000100000012 /* HostsGroupTests.m */; };
\t\tCC2B3C4D5E6F000100000043 /* AbstractHostsControllerTests.m in Sources */ = {isa = PBXBuildFile; fileRef = CC2B3C4D5E6F000100000013 /* AbstractHostsControllerTests.m */; };
"""

# ── PBXFileReference section ───────────────────────────────────────────────

FILE_REF_ENTRIES = """\
\t\tCC2B3C4D5E6F000100000010 /* NodeTests.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = NodeTests.m; sourceTree = "<group>"; };
\t\tCC2B3C4D5E6F000100000011 /* HostsTests.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = HostsTests.m; sourceTree = "<group>"; };
\t\tCC2B3C4D5E6F000100000012 /* HostsGroupTests.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = HostsGroupTests.m; sourceTree = "<group>"; };
\t\tCC2B3C4D5E6F000100000013 /* AbstractHostsControllerTests.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = AbstractHostsControllerTests.m; sourceTree = "<group>"; };
\t\tCC2B3C4D5E6F000100000020 /* Gas Mask Tests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = "Gas Mask Tests.xctest"; sourceTree = BUILT_PRODUCTS_DIR; };
"""

# ── PBXFrameworksBuildPhase ────────────────────────────────────────────────

FRAMEWORKS_PHASE = """\
\t\tCC2B3C4D5E6F000100000006 /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
"""

# ── PBXGroup entries ───────────────────────────────────────────────────────

GASMASK_TESTS_GROUP = """\
\t\tCC2B3C4D5E6F000100000031 /* GasMaskTests */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\tCC2B3C4D5E6F000100000010 /* NodeTests.m */,
\t\t\t\tCC2B3C4D5E6F000100000011 /* HostsTests.m */,
\t\t\t\tCC2B3C4D5E6F000100000012 /* HostsGroupTests.m */,
\t\t\t\tCC2B3C4D5E6F000100000013 /* AbstractHostsControllerTests.m */,
\t\t\t);
\t\t\tname = GasMaskTests;
\t\t\tpath = Tests/GasMaskTests;
\t\t\tsourceTree = "<group>";
\t\t};
\t\tCC2B3C4D5E6F000100000030 /* Tests */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\tCC2B3C4D5E6F000100000031 /* GasMaskTests */,
\t\t\t);
\t\t\tname = Tests;
\t\t\tpath = Tests;
\t\t\tsourceTree = "<group>";
\t\t};
"""

# ── PBXNativeTarget ────────────────────────────────────────────────────────

NATIVE_TARGET = """\
\t\tCC2B3C4D5E6F000100000001 /* Gas Mask Tests */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = CC2B3C4D5E6F000100000004 /* Build configuration list for PBXNativeTarget "Gas Mask Tests" */;
\t\t\tbuildPhases = (
\t\t\t\tCC2B3C4D5E6F000100000005 /* Sources */,
\t\t\t\tCC2B3C4D5E6F000100000006 /* Frameworks */,
\t\t\t\tCC2B3C4D5E6F000100000007 /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = "Gas Mask Tests";
\t\t\tproductName = "Gas Mask Tests";
\t\t\tproductReference = CC2B3C4D5E6F000100000020 /* Gas Mask Tests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t};
"""

# ── PBXResourcesBuildPhase ─────────────────────────────────────────────────

RESOURCES_PHASE = """\
\t\tCC2B3C4D5E6F000100000007 /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
"""

# ── PBXSourcesBuildPhase ───────────────────────────────────────────────────

SOURCES_PHASE = """\
\t\tCC2B3C4D5E6F000100000005 /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\tCC2B3C4D5E6F000100000040 /* NodeTests.m in Sources */,
\t\t\t\tCC2B3C4D5E6F000100000041 /* HostsTests.m in Sources */,
\t\t\t\tCC2B3C4D5E6F000100000042 /* HostsGroupTests.m in Sources */,
\t\t\t\tCC2B3C4D5E6F000100000043 /* AbstractHostsControllerTests.m in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
"""

# ── XCBuildConfiguration ───────────────────────────────────────────────────

BUILD_CONFIG_DEBUG = """\
\t\tCC2B3C4D5E6F000100000002 /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tFRAMEWORK_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"$(PLATFORM_DIR)/Developer/Library/Frameworks",
\t\t\t\t);
\t\t\t\tGCC_PRECOMPILE_PREFIX_HEADER = YES;
\t\t\t\tGCC_PREFIX_HEADER = Gas_Mask_Prefix.pch;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 13.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "ee.clockwise.gmask.tests";
\t\t\t\tPRODUCT_NAME = "Gas Mask Tests";
\t\t\t\tSDKROOT = macosx;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Gas Mask.app/Contents/MacOS/Gas Mask";
\t\t\t};
\t\t\tname = Debug;
\t\t};
"""

BUILD_CONFIG_RELEASE = """\
\t\tCC2B3C4D5E6F000100000003 /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tFRAMEWORK_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"$(PLATFORM_DIR)/Developer/Library/Frameworks",
\t\t\t\t);
\t\t\t\tGCC_PRECOMPILE_PREFIX_HEADER = YES;
\t\t\t\tGCC_PREFIX_HEADER = Gas_Mask_Prefix.pch;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 13.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "ee.clockwise.gmask.tests";
\t\t\t\tPRODUCT_NAME = "Gas Mask Tests";
\t\t\t\tSDKROOT = macosx;
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Gas Mask.app/Contents/MacOS/Gas Mask";
\t\t\t};
\t\t\tname = Release;
\t\t};
"""

# ── XCConfigurationList ────────────────────────────────────────────────────

CONFIG_LIST = """\
\t\tCC2B3C4D5E6F000100000004 /* Build configuration list for PBXNativeTarget "Gas Mask Tests" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\tCC2B3C4D5E6F000100000002 /* Debug */,
\t\t\t\tCC2B3C4D5E6F000100000003 /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
"""

# ── Scheme XML additions ───────────────────────────────────────────────────

SCHEME_BUILD_ENTRY = """\
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "CC2B3C4D5E6F000100000001"
               BuildableName = "Gas Mask Tests.xctest"
               BlueprintName = "Gas Mask Tests"
               ReferencedContainer = "container:Gas Mask.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>"""

SCHEME_TESTABLE = """\
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "CC2B3C4D5E6F000100000001"
               BuildableName = "Gas Mask Tests.xctest"
               BlueprintName = "Gas Mask Tests"
               ReferencedContainer = "container:Gas Mask.xcodeproj">
            </BuildableReference>
         </TestableReference>"""


def patch_pbxproj(pbxproj):
    # 1. PBXBuildFile section – insert before "/* End PBXBuildFile section */"
    pbxproj = pbxproj.replace(
        '/* End PBXBuildFile section */',
        BUILD_FILE_ENTRIES + '/* End PBXBuildFile section */'
    )

    # 2. PBXFileReference section – insert before "/* End PBXFileReference section */"
    pbxproj = pbxproj.replace(
        '/* End PBXFileReference section */',
        FILE_REF_ENTRIES + '/* End PBXFileReference section */'
    )

    # 3. PBXFrameworksBuildPhase section – insert before "/* End PBXFrameworksBuildPhase section */"
    pbxproj = pbxproj.replace(
        '/* End PBXFrameworksBuildPhase section */',
        FRAMEWORKS_PHASE + '/* End PBXFrameworksBuildPhase section */'
    )

    # 4. PBXGroup section – insert GasMaskTests and Tests groups before "/* End PBXGroup section */"
    pbxproj = pbxproj.replace(
        '/* End PBXGroup section */',
        GASMASK_TESTS_GROUP + '/* End PBXGroup section */'
    )

    # 5. Add Tests group to main "Gas Mask" group children list
    pbxproj = pbxproj.replace(
        '\t\t\t\t19C28FACFE9D520D11CA2CBB /* Products */,',
        '\t\t\t\tCC2B3C4D5E6F000100000030 /* Tests */,\n\t\t\t\t19C28FACFE9D520D11CA2CBB /* Products */,'
    )

    # 6. Add product to Products group
    #    Find the Products group children list and add the xctest product
    pbxproj = pbxproj.replace(
        '\t\t19C28FACFE9D520D11CA2CBB /* Products */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n',
        '\t\t19C28FACFE9D520D11CA2CBB /* Products */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n'
        '\t\t\t\tCC2B3C4D5E6F000100000020 /* Gas Mask Tests.xctest */,\n'
    )

    # 7. PBXNativeTarget section – insert before "/* End PBXNativeTarget section */"
    pbxproj = pbxproj.replace(
        '/* End PBXNativeTarget section */',
        NATIVE_TARGET + '/* End PBXNativeTarget section */'
    )

    # 8. Add test target to project targets array
    pbxproj = pbxproj.replace(
        '\t\t\ttargets = (\n\t\t\t\t8D1107260486CEB800E47090 /* Gas Mask */,',
        '\t\t\ttargets = (\n\t\t\t\t8D1107260486CEB800E47090 /* Gas Mask */,\n'
        '\t\t\t\tCC2B3C4D5E6F000100000001 /* Gas Mask Tests */,'
    )

    # 9. PBXResourcesBuildPhase section
    pbxproj = pbxproj.replace(
        '/* End PBXResourcesBuildPhase section */',
        RESOURCES_PHASE + '/* End PBXResourcesBuildPhase section */'
    )

    # 10. PBXSourcesBuildPhase section
    pbxproj = pbxproj.replace(
        '/* End PBXSourcesBuildPhase section */',
        SOURCES_PHASE + '/* End PBXSourcesBuildPhase section */'
    )

    # 11. XCBuildConfiguration section
    pbxproj = pbxproj.replace(
        '/* End XCBuildConfiguration section */',
        BUILD_CONFIG_DEBUG + BUILD_CONFIG_RELEASE + '/* End XCBuildConfiguration section */'
    )

    # 12. XCConfigurationList section
    pbxproj = pbxproj.replace(
        '/* End XCConfigurationList section */',
        CONFIG_LIST + '/* End XCConfigurationList section */'
    )

    return pbxproj


def patch_scheme(scheme):
    # Add test target to BuildActionEntries (before closing </BuildActionEntries>)
    scheme = scheme.replace(
        '      </BuildActionEntries>',
        SCHEME_BUILD_ENTRY + '\n      </BuildActionEntries>'
    )

    # Add testable reference (inside <Testables>...</Testables>)
    scheme = scheme.replace(
        '      <Testables>\n      </Testables>',
        '      <Testables>\n' + SCHEME_TESTABLE + '\n      </Testables>'
    )

    return scheme


def main():
    print(f'Reading {PROJECT_PATH}')
    with open(PROJECT_PATH, 'r', encoding='utf-8') as f:
        pbxproj = f.read()

    check_already_applied(pbxproj)
    validate_no_uuid_conflicts(pbxproj)

    patched = patch_pbxproj(pbxproj)

    if patched == pbxproj:
        print('ERROR: No changes made to project.pbxproj — pattern matching may have failed.')
        sys.exit(1)

    with open(PROJECT_PATH, 'w', encoding='utf-8') as f:
        f.write(patched)
    print(f'project.pbxproj updated successfully.')

    print(f'Reading {SCHEME_PATH}')
    with open(SCHEME_PATH, 'r', encoding='utf-8') as f:
        scheme = f.read()

    patched_scheme = patch_scheme(scheme)
    if patched_scheme == scheme:
        print('ERROR: No changes made to Gas Mask.xcscheme — pattern matching may have failed.')
        sys.exit(1)

    with open(SCHEME_PATH, 'w', encoding='utf-8') as f:
        f.write(patched_scheme)
    print(f'Gas Mask.xcscheme updated successfully.')

    print('Done.')


if __name__ == '__main__':
    main()
