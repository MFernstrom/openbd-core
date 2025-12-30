# Java 17+ Compatibility Guide for OpenBD

## Overview

OpenBD has been updated to ensure full compatibility with Java 17 and newer versions. This document outlines the changes made and requirements for building and running OpenBD on Java 17+.

## Changes Made

### 1. Build Configuration Updates

The `build/build.xml` file has been updated to include explicit Java version targeting:

- Added `release="17"` attribute to the `<javac>` task
- Added `includeantruntime="false"` to suppress Ant warnings
- This ensures the compiled bytecode is Java 17 compatible (major version 61)

**Why this matters:** Without the `release="17"` flag, compiling with JDK 21+ can insert references to Java 21 features like `SequencedCollection`, which causes `NoClassDefFoundError` when running on Java 17.

### 2. SequencedCollection Compatibility

The main compatibility issue resolved is the SequencedCollection problem:

- **Problem:** When code is compiled with JDK 21's javac, the compiler can insert references to `java.util.SequencedCollection` (introduced in Java 21) even when using `release="17"`. This happens because JDK 21 changed the `List` interface to extend `SequencedCollection`, and OpenBD's `cfArrayListData` class implements `List<Object>`.
- **Impact:** This causes runtime failures with `NoClassDefFoundError: java/util/SequencedCollection` when running on Java 17
- **Root Cause:** The `release="17"` flag alone is not enough - you must use javac from JDK 17, not JDK 21
- **Solution:** The build.xml now explicitly uses Java 17's javac via `fork="true"` and `executable="/usr/lib/jvm/java-17-openjdk/bin/javac"`

## Build Requirements

### CRITICAL: Supported JDK Versions for Building

**You MUST compile with Java 17 JDK, not Java 21 or newer.**

- **Java 17** (REQUIRED for production builds)
- **Java 18-20** (NOT recommended - may have compatibility issues)
- **Java 21+** (DO NOT USE - will cause SequencedCollection errors)

### Why Java 17 JDK is Required

Even with the `release="17"` flag, using javac from JDK 21+ can leak references to Java 21 features (like `SequencedCollection` in the `List` interface). The build.xml is configured to use `/usr/lib/jvm/java-17-openjdk/bin/javac` explicitly via the `fork="true"` and `executable` attributes.

### Verifying Your Build Environment

Before building, verify your javac version:

```bash
javac -version  # Should show "javac 17.x.x", NOT "javac 21.x.x"
```

If you see javac 21 or higher, you need to either:
1. Use the build.xml as-is (it forces Java 17 javac)
2. Or set your JAVA_HOME to Java 17:
   ```bash
   export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
   export PATH=$JAVA_HOME/bin:$PATH
   ```

### Building OpenBD

```bash
ant -f build/build.xml compile  # Compile only
ant -f build/build.xml jar      # Build JAR
ant -f build/build.xml war      # Build WAR file
```

## Runtime Requirements

### Minimum Java Version

OpenBD compiled with these settings requires **Java 17 or newer** to run.

### Jetty Compatibility

When running OpenBD with Jetty:

- **Jetty 9.4.x**: Compatible with Java 17, but in End of Community Support
- **Jetty 10.x**: Recommended for Java 17 (uses `javax.*` namespace)
- **Jetty 11.x**: Recommended for Java 17+ (uses `jakarta.*` namespace)
- **Jetty 12.x**: For Java 17+ with latest features

### Running with jetty-runner

```bash
java -jar jetty-runner-10.x.x.jar path/to/openbd.war
```

## Known Issues and Considerations

### 1. Deprecated APIs

The build shows warnings about deprecated APIs marked for removal. These are from dependencies and don't affect Java 17 compatibility:

- Browser applet classes are excluded (removed in Java 9+)
- Some collection APIs show deprecation warnings but are still functional

### 2. javax.activation Package

OpenBD uses `javax.activation` which was removed from the JDK in Java 11+:

- **Current solution:** The `activation.jar` is provided in `build/lib/`
- **Status:** Working correctly with Java 17+
- **Future consideration:** Could migrate to Jakarta EE (`jakarta.activation`) if needed

### 3. Dependencies

All dependencies have been verified to work with Java 17:

- Netty 4.1.15.Final (for WebSocket support)
- MongoDB Driver 3.5.0
- AWS SDK 1.11.448
- Lettuce (Redis client)
- And all other libraries in `webapp/WEB-INF/lib/`

## Verification

To verify your build is Java 17 compatible:

```bash
# Check bytecode version (should show major version: 61)
javap -verbose build/classes/com/naryx/tagfusion/cfm/engine/cfEngine.class | grep "major version"

# Expected output: major version: 61
```

## Migration from Java 8

If you're migrating from Java 8:

1. Update to Java 17 LTS
2. Rebuild OpenBD using the updated build.xml
3. Update Jetty to version 10+ if using jetty-runner
4. Test your CFML applications thoroughly
5. Check for any deprecated API usage in your custom Java extensions

## Resources

- [Java 17 Release Notes](https://openjdk.org/projects/jdk/17/)
- [JEP 431: Sequenced Collections](https://openjdk.org/jeps/431) (Java 21 feature)
- [Jetty Version Compatibility](https://eclipse.dev/jetty/documentation/)

## Support

For issues related to Java 17 compatibility:

1. Verify you're using the correct Java version: `java -version`
2. Ensure you're building with the updated `build.xml`
3. Check Jetty version compatibility
4. Report issues at: https://github.com/OpenBD/openbd-core/issues
