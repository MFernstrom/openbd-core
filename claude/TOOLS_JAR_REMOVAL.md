# Removal of tools.jar Dependency

## Summary

The OpenBD codebase has been updated to remove the dependency on `tools.jar`, which was removed in Java 9+. The code now uses the modern `javax.tools` API that works with Java 8+ and doesn't require tools.jar in Java 9+.

## Changes Made

### 1. JavaPlatform.java
**File:** `src/com/bluedragon/platform/java/JavaPlatform.java`

**What was changed:**
- Replaced deprecated `sun.tools.javac.Main` class with modern `javax.tools.JavaCompiler` API
- Updated the `compileOutput()` method to use the same compiler API that `CharSequenceCompiler.java` already uses
- Added proper null checking for `sun.boot.class.path` (which is null in Java 9+)
- Added diagnostic output for better error reporting when compilation fails

**Why it was needed:**
- The old code used `sun.tools.javac.Main` from tools.jar (deprecated since JDK 1.3)
- This class is not available in Java 9+ and required tools.jar in Java 8
- The modern `javax.tools` API is part of the standard JDK and doesn't require tools.jar

### 2. CharSequenceCompiler.java
**File:** `src/org/alanwilliamson/lang/java/CharSequenceCompiler.java`

**What was changed:**
- Updated error message to be more accurate for Java 9+
- Changed from: "Check that your class path includes tools.jar"
- Changed to: "Ensure you are running on a JDK (not JRE). For Java 8, tools.jar must be on the classpath."

**Why it was needed:**
- The old error message was misleading for Java 9+ users
- This code already used the modern `javax.tools` API, so it only needed a message update

## Technical Details

### How the Modern API Works

Both files now use the `javax.tools.JavaCompiler` API:

```java
javax.tools.JavaCompiler javac = javax.tools.ToolProvider.getSystemJavaCompiler();
```

This API:
- Is available in Java 8 with tools.jar on the classpath
- Is available in Java 9+ without requiring any additional JARs
- Provides better error diagnostics
- Is the officially supported way to compile Java code programmatically

### Java Version Compatibility

- **Java 8**: Requires JDK (not JRE). For some configurations, tools.jar may need to be explicitly added to classpath
- **Java 9+**: Works out of the box with JDK (tools.jar no longer exists or is needed)

## Known Issues

The full build currently has unrelated compilation errors in browser applet code:
- `SliderApplet.java` - JSObject.getWindow() not found
- `TextInput.java` - JSObject.getWindow() not found
- `TreeApplet.java` - JSObject.getWindow() not found

These errors are **NOT** related to the tools.jar removal. They are due to missing Java browser plugin API classes (plugin.jar), which were also removed in newer Java versions. These applet classes may need to be excluded from compilation or updated if applet functionality is still needed.

## Testing

The modified files have been verified to compile successfully:
- `JavaPlatform.java` - ✓ Compiles
- `CharSequenceCompiler.java` - ✓ Compiles

## Benefits

1. **Java 9+ Compatibility**: Code now works with Java 9+ without requiring tools.jar
2. **Better Error Messages**: Updated error messages guide users to the correct solution
3. **Modern API Usage**: Uses officially supported javax.tools API throughout
4. **Improved Diagnostics**: Better error reporting when compilation fails
5. **Future-Proof**: No longer depends on deprecated internal APIs

## Migration Notes

If you're upgrading to Java 9+ or newer:
1. Remove any manual tools.jar references from your classpath
2. Ensure you're using a JDK (not JRE)
3. The compiler API will be automatically available

If you're still on Java 8:
1. Ensure you're using a JDK
2. In some servlet containers, you may need tools.jar on the classpath
3. The code will continue to work as before
