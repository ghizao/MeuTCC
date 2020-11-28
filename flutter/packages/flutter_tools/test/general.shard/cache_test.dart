// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart' show InternetAddress, SocketException;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

void main() {
  group('$Cache.checkLockAcquired', () {
    MockFileSystem mockFileSystem;
    MemoryFileSystem memoryFileSystem;
    MockFile mockFile;
    MockRandomAccessFile mockRandomAccessFile;

    setUp(() {
      mockFileSystem = MockFileSystem();
      memoryFileSystem = MemoryFileSystem.test();
      mockFile = MockFile();
      mockRandomAccessFile = MockRandomAccessFile();
      when(mockFileSystem.path).thenReturn(memoryFileSystem.path);

      Cache.enableLocking();
    });

    tearDown(() {
      // Restore locking to prevent potential side-effects in
      // tests outside this group (this option is globally shared).
      Cache.enableLocking();
      Cache.releaseLock();
    });

    test('should throw when locking is not acquired', () {
      expect(Cache.checkLockAcquired, throwsStateError);
    });

    test('should not throw when locking is disabled', () {
      Cache.disableLocking();
      Cache.checkLockAcquired();
    });

    testUsingContext('should not throw when lock is acquired', () async {
      when(mockFileSystem.file(argThat(endsWith('lockfile')))).thenReturn(mockFile);
      when(mockFile.openSync(mode: anyNamed('mode'))).thenReturn(mockRandomAccessFile);
      await Cache.lock();
      Cache.checkLockAcquired();
      Cache.releaseLock();
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('throws tool exit when lockfile open fails', () async {
      when(mockFileSystem.file(argThat(endsWith('lockfile')))).thenReturn(mockFile);
      when(mockFile.openSync(mode: anyNamed('mode'))).thenThrow(const FileSystemException());
      expect(() async => await Cache.lock(), throwsToolExit());
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('should not throw when FLUTTER_ALREADY_LOCKED is set', () async {
      Cache.checkLockAcquired();
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform()..environment = <String, String>{'FLUTTER_ALREADY_LOCKED': 'true'},
    });
  });

  group('Cache', () {
    MockCache mockCache;
    Cache cache;
    MemoryFileSystem memoryFileSystem;
    ProcessManager fakeProcessManager;

    setUp(() {
      fakeProcessManager = FakeProcessManager.any();
      mockCache = MockCache();
      cache = Cache.test(
        fileSystem: memoryFileSystem,
        processManager: fakeProcessManager,
      );
      memoryFileSystem = MemoryFileSystem.test();
    });

    testUsingContext('Continues on failed stamp file update', () async {
      final Directory artifactDir = globals.fs.systemTempDirectory.createTempSync('flutter_cache_test_artifact.');
      final Directory downloadDir = globals.fs.systemTempDirectory.createTempSync('flutter_cache_test_download.');
      when(mockCache.getArtifactDirectory(any)).thenReturn(artifactDir);
      when(mockCache.getDownloadDir()).thenReturn(downloadDir);
      when(mockCache.setStampFor(any, any)).thenAnswer((_) {
        throw const FileSystemException('stamp write failed');
      });
      final FakeSimpleArtifact artifact = FakeSimpleArtifact(mockCache);
      await artifact.update(MockArtifactUpdater());
      expect(testLogger.errorText, contains('stamp write failed'));
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Gradle wrapper should not be up to date, if some cached artifact is not available', () {
      final GradleWrapper gradleWrapper = GradleWrapper(cache);
      final Directory directory = cache.getCacheDir(globals.fs.path.join('artifacts', 'gradle_wrapper'));
      globals.fs.file(globals.fs.path.join(directory.path, 'gradle', 'wrapper', 'gradle-wrapper.jar')).createSync(recursive: true);

      expect(gradleWrapper.isUpToDateInner(), false);
    }, overrides: <Type, Generator>{
      Cache: () => cache,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Gradle wrapper should be up to date, only if all cached artifact are available', () {
      final GradleWrapper gradleWrapper = GradleWrapper(cache);
      final Directory directory = cache.getCacheDir(globals.fs.path.join('artifacts', 'gradle_wrapper'));
      globals.fs.file(globals.fs.path.join(directory.path, 'gradle', 'wrapper', 'gradle-wrapper.jar')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join(directory.path, 'gradlew')).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join(directory.path, 'gradlew.bat')).createSync(recursive: true);

      expect(gradleWrapper.isUpToDateInner(), true);
    }, overrides: <Type, Generator>{
      Cache: () => cache,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('should not be up to date, if some cached artifact is not', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenAnswer((Invocation _) => Future<bool>.value(true));
      when(artifact2.isUpToDate()).thenAnswer((Invocation _) => Future<bool>.value(false));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(await cache.isUpToDate(), isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext('should be up to date, if all cached artifacts are', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenAnswer((Invocation _) => Future<bool>.value(true));
      when(artifact2.isUpToDate()).thenAnswer((Invocation _) => Future<bool>.value(true));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      expect(await cache.isUpToDate(), isTrue);
    }, overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext('should update cached artifacts which are not up to date', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenAnswer((Invocation _) => Future<bool>.value(true));
      when(artifact2.isUpToDate()).thenAnswer((Invocation _) => Future<bool>.value(false));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      await cache.updateAll(<DevelopmentArtifact>{
        null,
      });
      verifyNever(artifact1.update(any));
      verify(artifact2.update(any));
    }, overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext("getter dyLdLibEntry concatenates the output of each artifact's dyLdLibEntry getter", () async {
      final IosUsbArtifacts artifact1 = MockIosUsbArtifacts();
      final IosUsbArtifacts artifact2 = MockIosUsbArtifacts();
      final IosUsbArtifacts artifact3 = MockIosUsbArtifacts();
      when(artifact1.environment)
          .thenReturn(<String, String>{
            'DYLD_LIBRARY_PATH': '/path/to/alpha:/path/to/beta',
          });
      when(artifact2.environment)
          .thenReturn(<String, String>{
            'DYLD_LIBRARY_PATH': '/path/to/gamma:/path/to/delta:/path/to/epsilon',
          });
      when(artifact3.environment)
          .thenReturn(<String, String>{
            'DYLD_LIBRARY_PATH': '',
          });
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2, artifact3]);

      expect(cache.dyLdLibEntry.key, 'DYLD_LIBRARY_PATH');
      expect(
        cache.dyLdLibEntry.value,
        '/path/to/alpha:/path/to/beta:/path/to/gamma:/path/to/delta:/path/to/epsilon',
      );
    });

    testUsingContext('failed storage.googleapis.com download shows China warning', () async {
      final CachedArtifact artifact1 = MockCachedArtifact();
      final CachedArtifact artifact2 = MockCachedArtifact();
      when(artifact1.isUpToDate()).thenAnswer((Invocation _) => Future<bool>.value(false));
      when(artifact2.isUpToDate()).thenAnswer((Invocation _) => Future<bool>.value(false));
      final MockInternetAddress address = MockInternetAddress();
      when(address.host).thenReturn('storage.googleapis.com');
      when(artifact1.update(any)).thenThrow(SocketException(
        'Connection reset by peer',
        address: address,
      ));
      final Cache cache = Cache(artifacts: <CachedArtifact>[artifact1, artifact2]);
      try {
        await cache.updateAll(<DevelopmentArtifact>{
          null,
        });
        fail('Mock thrown exception expected');
      } on Exception {
        verify(artifact1.update(any));
        // Don't continue when retrieval fails.
        verifyNever(artifact2.update(any));
        expect(
          testLogger.errorText,
          contains('https://flutter.dev/community/china'),
        );
      }
    }, overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.any(),
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext('Invalid URI for FLUTTER_STORAGE_BASE_URL throws ToolExit', () async {
      final Cache cache = Cache();

      expect(() => cache.storageBaseUrl, throwsToolExit());
    }, overrides: <Type, Generator>{
      Platform: () => FakePlatform(environment: <String, String>{
        'FLUTTER_STORAGE_BASE_URL': ' http://foo',
      }),
    });
  });

  testWithoutContext('flattenNameSubdirs', () {
    expect(flattenNameSubdirs(Uri.parse('http://flutter.dev/foo/bar'), MemoryFileSystem.test()), 'flutter.dev/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('http://docs.flutter.io/foo/bar'), MemoryFileSystem.test()), 'docs.flutter.io/foo/bar');
    expect(flattenNameSubdirs(Uri.parse('https://www.flutter.dev'), MemoryFileSystem.test()), 'www.flutter.dev');
  });

  group('EngineCachedArtifact', () {
    FakePlatform fakePlatform;
    MemoryFileSystem fileSystem;
    MockCache mockCache;
    MockOperatingSystemUtils mockOperatingSystemUtils;

    setUp(() {
      fakePlatform = FakePlatform(environment: const <String, String>{}, operatingSystem: 'linux');
      mockCache = MockCache();
      mockOperatingSystemUtils = MockOperatingSystemUtils();
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext('makes binary dirs readable and executable by all', () async {
      final Directory artifactDir = fileSystem.systemTempDirectory.createTempSync('flutter_cache_test_artifact.');
      final Directory downloadDir = fileSystem.systemTempDirectory.createTempSync('flutter_cache_test_download.');
      when(mockCache.getArtifactDirectory(any)).thenReturn(artifactDir);
      when(mockCache.getDownloadDir()).thenReturn(downloadDir);
      artifactDir.childDirectory('bin_dir').createSync();
      artifactDir.childFile('unused_url_path').createSync();

      final FakeCachedArtifact artifact = FakeCachedArtifact(
        cache: mockCache,
        binaryDirs: <List<String>>[
          <String>['bin_dir', 'unused_url_path'],
        ],
        requiredArtifacts: DevelopmentArtifact.universal,
      );
      await artifact.updateInner(MockArtifactUpdater());
      final Directory dir = fileSystem.systemTempDirectory
          .listSync(recursive: true)
          .whereType<Directory>()
          .singleWhere((Directory directory) => directory.basename == 'bin_dir', orElse: () => null);
      expect(dir, isNotNull);
      expect(dir.path, artifactDir.childDirectory('bin_dir').path);
      verify(mockOperatingSystemUtils.chmod(argThat(hasPath(dir.path)), 'a+r,a+x'));
    }, overrides: <Type, Generator>{
      Cache: () => mockCache,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      OperatingSystemUtils: () => mockOperatingSystemUtils,
      Platform: () => fakePlatform,
    });
  });

  group('AndroidMavenArtifacts', () {
    MemoryFileSystem memoryFileSystem;
    MockProcessManager processManager;
    Cache cache;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      processManager = MockProcessManager();
      cache = Cache.test(
        fileSystem: memoryFileSystem,
        processManager: FakeProcessManager.any(),
      );
    });

    test('development artifact', () async {
      final AndroidMavenArtifacts mavenArtifacts = AndroidMavenArtifacts(cache);
      expect(mavenArtifacts.developmentArtifact, DevelopmentArtifact.androidMaven);
    });

    testUsingContext('update', () async {
      final AndroidMavenArtifacts mavenArtifacts = AndroidMavenArtifacts(cache);
      expect(await mavenArtifacts.isUpToDate(), isFalse);

      final Directory gradleWrapperDir = cache.getArtifactDirectory('gradle_wrapper')..createSync(recursive: true);
      gradleWrapperDir.childFile('gradlew').writeAsStringSync('irrelevant');
      gradleWrapperDir.childFile('gradlew.bat').writeAsStringSync('irrelevant');

      when(globals.processManager.run(any, environment: captureAnyNamed('environment')))
        .thenAnswer((Invocation invocation) {
          final List<String> args = invocation.positionalArguments[0] as List<String>;
          expect(args.length, 6);
          expect(args[1], '-b');
          expect(args[2].endsWith('resolve_dependencies.gradle'), isTrue);
          expect(args[5], 'resolveDependencies');
          expect(invocation.namedArguments[#environment], gradleEnvironment);
          return Future<ProcessResult>.value(ProcessResult(0, 0, '', ''));
        });

      await mavenArtifacts.update(MockArtifactUpdater());

      expect(await mavenArtifacts.isUpToDate(), isFalse);
    }, overrides: <Type, Generator>{
      Cache: () => cache,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => processManager,
    });
  });

  group('macOS artifacts', () {
    Cache cache;

    setUp(() {
      cache = Cache.test(
        processManager: FakeProcessManager.any(),
      );
    });

    testUsingContext('verifies executables for libimobiledevice in isUpToDateInner', () async {
      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('libimobiledevice', cache);
      iosUsbArtifacts.location.createSync();
      final File ideviceScreenshotFile = iosUsbArtifacts.location.childFile('idevicescreenshot')
        ..createSync();
      iosUsbArtifacts.location.childFile('idevicesyslog')
        .createSync();

      expect(iosUsbArtifacts.isUpToDateInner(), true);

      ideviceScreenshotFile.deleteSync();

      expect(iosUsbArtifacts.isUpToDateInner(), false);
    }, overrides: <Type, Generator>{
      Cache: () => cache,
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('verifies iproxy for usbmuxd in isUpToDateInner', () async {
      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('usbmuxd', cache);
      iosUsbArtifacts.location.createSync();
      final File iproxy = iosUsbArtifacts.location.childFile('iproxy')
        ..createSync();

      expect(iosUsbArtifacts.isUpToDateInner(), true);

      iproxy.deleteSync();

      expect(iosUsbArtifacts.isUpToDateInner(), false);
    }, overrides: <Type, Generator>{
      Cache: () => cache,
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Does not verify executables for openssl in isUpToDateInner', () async {
      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('openssl', cache);
      iosUsbArtifacts.location.createSync();

      expect(iosUsbArtifacts.isUpToDateInner(), true);
    }, overrides: <Type, Generator>{
      Cache: () => cache,
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('use unsigned when specified', () async {
      cache.useUnsignedMacBinaries = true;

      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('name', cache);
      expect(iosUsbArtifacts.archiveUri.toString(), contains('/unsigned/'));
    }, overrides: <Type, Generator>{
      Cache: () => cache,
    });

    testUsingContext('not use unsigned when not specified', () async {
      cache.useUnsignedMacBinaries = false;

      final IosUsbArtifacts iosUsbArtifacts = IosUsbArtifacts('name', cache);
      expect(iosUsbArtifacts.archiveUri.toString(), isNot(contains('/unsigned/')));
    }, overrides: <Type, Generator>{
      Cache: () => cache,
    });
  });

  testWithoutContext('Downloads Flutter runner debug symbols', () async {
    final Cache cache = Cache.test(
      processManager: FakeProcessManager.any(),
    );
    final MockVersionedPackageResolver mockPackageResolver = MockVersionedPackageResolver();
    final FlutterRunnerDebugSymbols flutterRunnerDebugSymbols = FlutterRunnerDebugSymbols(
      cache,
      packageResolver: mockPackageResolver,
      platform: FakePlatform(operatingSystem: 'linux'),
    );
    when(mockPackageResolver.resolveUrl(any, any)).thenReturn('');

    await flutterRunnerDebugSymbols.updateInner(MockArtifactUpdater());

    verifyInOrder(<void>[
      mockPackageResolver.resolveUrl('fuchsia-debug-symbols-x64', any),
      mockPackageResolver.resolveUrl('fuchsia-debug-symbols-arm64', any),
    ]);
  });

  testUsingContext('FontSubset in univeral artifacts', () {
    final Cache cache = Cache.test();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(cache);
    expect(artifacts.developmentArtifact, DevelopmentArtifact.universal);
  });

  testUsingContext('FontSubset artifacts on linux', () {
    final Cache cache = Cache.test();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(cache);
    cache.includeAllPlatforms = false;
    expect(artifacts.getBinaryDirs(), <List<String>>[<String>['linux-x64', 'linux-x64/font-subset.zip']]);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'linux'),
  });

  testUsingContext('FontSubset artifacts on windows', () {
    final Cache cache = Cache.test();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(cache);
    cache.includeAllPlatforms = false;
    expect(artifacts.getBinaryDirs(), <List<String>>[<String>['windows-x64', 'windows-x64/font-subset.zip']]);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'windows'),
  });

  testUsingContext('FontSubset artifacts on macos', () {
    final Cache cache = Cache.test();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(cache);
    cache.includeAllPlatforms = false;
    expect(artifacts.getBinaryDirs(), <List<String>>[<String>['darwin-x64', 'darwin-x64/font-subset.zip']]);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'macos'),
  });

  testUsingContext('FontSubset artifacts on fuchsia', () {
    final Cache cache = Cache.test();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(cache);
    cache.includeAllPlatforms = false;
    expect(artifacts.getBinaryDirs, throwsToolExit(message: 'Unsupported operating system: ${globals.platform.operatingSystem}'));
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'fuchsia'),
  });

  testUsingContext('FontSubset artifacts for all platforms', () {
    final Cache cache = Cache.test();
    final FontSubsetArtifacts artifacts = FontSubsetArtifacts(cache);
    cache.includeAllPlatforms = true;
    expect(artifacts.getBinaryDirs(), <List<String>>[
        <String>['darwin-x64', 'darwin-x64/font-subset.zip'],
        <String>['linux-x64', 'linux-x64/font-subset.zip'],
        <String>['windows-x64', 'windows-x64/font-subset.zip'],
    ]);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'fuchsia'),
  });

  testUsingContext('macOS desktop artifacts ignore filtering when requested', () {
    final Cache cache = Cache.test();
    final MacOSEngineArtifacts artifacts = MacOSEngineArtifacts(cache);
    cache.includeAllPlatforms = false;
    cache.platformOverrideArtifacts = <String>{'macos'};

    expect(artifacts.getBinaryDirs(), isNotEmpty);
  }, overrides: <Type, Generator> {
    Platform: () => FakePlatform(operatingSystem: 'linux'),
  });

  testWithoutContext('Windows desktop artifacts ignore filtering when requested', () {
    final Cache cache = Cache.test();
    final WindowsEngineArtifacts artifacts = WindowsEngineArtifacts(
      cache,
      platform: FakePlatform(operatingSystem: 'linux'),
    );
    cache.includeAllPlatforms = false;
    cache.platformOverrideArtifacts = <String>{'windows'};

    expect(artifacts.getBinaryDirs(), isNotEmpty);
  });

  testWithoutContext('Windows desktop artifacts include profile and release artifacts', () {
    final Cache cache = Cache.test();
    final WindowsEngineArtifacts artifacts = WindowsEngineArtifacts(
      cache,
      platform: FakePlatform(operatingSystem: 'windows'),
    );

    expect(artifacts.getBinaryDirs(), containsAll(<Matcher>[
      contains(contains('profile')),
      contains(contains('release')),
    ]));
  });

  testWithoutContext('Linux desktop artifacts ignore filtering when requested', () {
    final Cache cache = Cache.test();
    final LinuxEngineArtifacts artifacts = LinuxEngineArtifacts(
      cache,
      platform: FakePlatform(operatingSystem: 'macos'),
    );
    cache.includeAllPlatforms = false;
    cache.platformOverrideArtifacts = <String>{'linux'};

    expect(artifacts.getBinaryDirs(), isNotEmpty);
  });

  testWithoutContext('Linux desktop artifacts include profile and release artifacts', () {
    final Cache cache = Cache.test();
    final LinuxEngineArtifacts artifacts = LinuxEngineArtifacts(
      cache,
      platform: FakePlatform(operatingSystem: 'linux'),
    );

    expect(artifacts.getBinaryDirs(), containsAll(<Matcher>[
      contains(contains('profile')),
      contains(contains('release')),
    ]));
  });

  testWithoutContext('Cache can delete stampfiles of artifacts', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ArtifactSet artifactSet = MockIosUsbArtifacts();
    final BufferLogger logger = BufferLogger.test();

    when(artifactSet.stampName).thenReturn('STAMP');
    final Cache cache = Cache(
      artifacts: <ArtifactSet>[
        artifactSet,
      ],
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(),
      osUtils: MockOperatingSystemUtils(),
      rootOverride: fileSystem.currentDirectory,
    );
    final File toolStampFile = fileSystem.file('bin/cache/flutter_tools.stamp');
    final File stampFile = cache.getStampFileFor(artifactSet.stampName);
    stampFile.createSync(recursive: true);
    toolStampFile.createSync(recursive: true);

    cache.clearStampFiles();

    expect(logger.errorText, isEmpty);
    expect(stampFile, isNot(exists));
    expect(toolStampFile, isNot(exists));
  });

   testWithoutContext('Cache does not attempt to delete already missing stamp files', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ArtifactSet artifactSet = MockIosUsbArtifacts();
    final BufferLogger logger = BufferLogger.test();

    when(artifactSet.stampName).thenReturn('STAMP');
    final Cache cache = Cache(
      artifacts: <ArtifactSet>[
        artifactSet,
      ],
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(),
      osUtils: MockOperatingSystemUtils(),
      rootOverride: fileSystem.currentDirectory,
    );
    final File toolStampFile = fileSystem.file('bin/cache/flutter_tools.stamp');
    final File stampFile = cache.getStampFileFor(artifactSet.stampName);
    toolStampFile.createSync(recursive: true);

    cache.clearStampFiles();

    expect(logger.errorText, isEmpty);
    expect(stampFile, isNot(exists));
    expect(toolStampFile, isNot(exists));
  });

  testWithoutContext('Cache catches file system exception from missing tool stamp file', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final ArtifactSet artifactSet = MockIosUsbArtifacts();
    final BufferLogger logger = BufferLogger.test();

    when(artifactSet.stampName).thenReturn('STAMP');
    final Cache cache = Cache(
      artifacts: <ArtifactSet>[
        artifactSet,
      ],
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(),
      osUtils: MockOperatingSystemUtils(),
      rootOverride: fileSystem.currentDirectory,
    );

    cache.clearStampFiles();

    expect(logger.errorText, contains('Failed to delete some stamp files'));
  });

  testWithoutContext('FlutterWebSdk deletes previous directory contents', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final Directory webStuff = fileSystem.directory('web-stuff');
    final MockCache cache = MockCache();
    final MockArtifactUpdater artifactUpdater = MockArtifactUpdater();
    final FlutterWebSdk webSdk = FlutterWebSdk(cache, platform: FakePlatform(operatingSystem: 'linux'));

    when(cache.getWebSdkDirectory()).thenReturn(webStuff);
    when(artifactUpdater.downloadZipArchive('Downloading Web SDK...', any, any))
      .thenAnswer((Invocation invocation) async {
        final Directory location = invocation.positionalArguments[2] as Directory;
        location.createSync(recursive: true);
        location.childFile('foo').createSync();
      });
    webStuff.childFile('bar').createSync(recursive: true);

    webSdk.updateInner(artifactUpdater);

    expect(webStuff.childFile('foo'), exists);
    expect(webStuff.childFile('bar'), isNot(exists));
  });

  testWithoutContext('Cache handles exception thrown if stamp file cannot be parsed', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final Logger logger = BufferLogger.test();
    final FakeCache cache = FakeCache(
      fileSystem: fileSystem,
      logger: logger,
      platform: FakePlatform(),
      osUtils: MockOperatingSystemUtils()
    );
    final MockFile file = MockFile();
    cache.stampFile = file;
    when(file.existsSync()).thenReturn(false);

    expect(cache.getStampFor('foo'), null);

    when(file.existsSync()).thenReturn(true);
    when(file.readAsStringSync()).thenThrow(const FileSystemException());

    expect(cache.getStampFor('foo'), null);

    when(file.existsSync()).thenReturn(true);
    when(file.readAsStringSync()).thenReturn('ABC ');

    expect(cache.getStampFor('foo'), 'ABC');
  });

  testWithoutContext('PubDependencies needs to be updated if the package config'
    ' file or the source directories are missing', () async {
    final BufferLogger logger = BufferLogger.test();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final PubDependencies pubDependencies = PubDependencies(
      flutterRoot: () => '',
      fileSystem: fileSystem,
      logger: logger,
      pub: () => MockPub(),
    );

    expect(await pubDependencies.isUpToDate(), false); // no package config

    fileSystem.file('packages/flutter_tools/.packages')
      ..createSync(recursive: true)
      ..writeAsStringSync('\n');
    fileSystem.file('packages/flutter_tools/.dart_tool/package_config.json')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "example",
      "rootUri": "file:///.pub-cache/hosted/pub.dartlang.org/example-7.0.0",
      "packageUri": "lib/",
      "languageVersion": "2.7"
    }
  ],
  "generated": "2020-09-15T20:29:20.691147Z",
  "generator": "pub",
  "generatorVersion": "2.10.0-121.0.dev"
}
''');

    expect(await pubDependencies.isUpToDate(), false); // dependencies are missing.

    fileSystem.file('.pub-cache/hosted/pub.dartlang.org/example-7.0.0/lib/foo.dart')
      .createSync(recursive: true);

    expect(await pubDependencies.isUpToDate(), true);
  });

  testWithoutContext('PubDependencies updates via pub get', () async {
    final BufferLogger logger = BufferLogger.test();
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final MockPub pub = MockPub();
    final PubDependencies pubDependencies = PubDependencies(
      flutterRoot: () => '',
      fileSystem: fileSystem,
      logger: logger,
      pub: () => pub,
    );

    await pubDependencies.update(MockArtifactUpdater());

    verify(pub.get(
      context: PubContext.pubGet,
      directory: 'packages/flutter_tools',
      generateSyntheticPackage: false,
      skipPubspecYamlCheck: true,
      checkLastModified: false,
    )).called(1);
  });
}

class FakeCachedArtifact extends EngineCachedArtifact {
  FakeCachedArtifact({
    String stampName = 'STAMP',
    @required Cache cache,
    DevelopmentArtifact requiredArtifacts,
    this.binaryDirs = const <List<String>>[],
    this.licenseDirs = const <String>[],
    this.packageDirs = const <String>[],
  }) : super(stampName, cache, requiredArtifacts);

  final List<List<String>> binaryDirs;
  final List<String> licenseDirs;
  final List<String> packageDirs;

  @override
  List<List<String>> getBinaryDirs() => binaryDirs;

  @override
  List<String> getLicenseDirs() => licenseDirs;

  @override
  List<String> getPackageDirs() => packageDirs;
}

class FakeSimpleArtifact extends CachedArtifact {
  FakeSimpleArtifact(Cache cache) : super(
    'fake',
    cache,
    DevelopmentArtifact.universal,
  );

  @override
  Future<void> updateInner(ArtifactUpdater artifactUpdater) async {
    // nop.
  }
}

class FakeDownloadedArtifact extends CachedArtifact {
  FakeDownloadedArtifact(this.downloadedFile, Cache cache) : super(
    'fake',
    cache,
    DevelopmentArtifact.universal,
  );

  final File downloadedFile;

  @override
  Future<void> updateInner(ArtifactUpdater artifactUpdater) async {}
}

class MockArtifactUpdater extends Mock implements ArtifactUpdater {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockFileSystem extends Mock implements FileSystem {}
class MockFile extends Mock implements File {}
class MockDirectory extends Mock implements Directory {}
class MockRandomAccessFile extends Mock implements RandomAccessFile {}
class MockCachedArtifact extends Mock implements CachedArtifact {}
class MockIosUsbArtifacts extends Mock implements IosUsbArtifacts {}
class MockInternetAddress extends Mock implements InternetAddress {}
class MockCache extends Mock implements Cache {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
class MockVersionedPackageResolver extends Mock implements VersionedPackageResolver {}
class MockPub extends Mock implements Pub {}
class FakeCache extends Cache {
  FakeCache({
    @required Logger logger,
    @required FileSystem fileSystem,
    @required Platform platform,
    @required OperatingSystemUtils osUtils,
  }) : super(
    logger: logger,
    fileSystem: fileSystem,
    platform: platform,
    osUtils: osUtils,
    artifacts: <ArtifactSet>[],
  );

  File stampFile;

  @override
  File getStampFileFor(String artifactName) {
    return stampFile;
  }
}
