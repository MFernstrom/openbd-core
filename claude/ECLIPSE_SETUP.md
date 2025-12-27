# Eclipse Setup Guide for OpenBD

This guide will help you resolve the common Eclipse errors when importing the OpenBD project.

## Main Issues Fixed

### 1. Missing xml-apis.jar (CRITICAL)
**Symptom:** Hundreds of errors like "Attr cannot be resolved to a type", "Node cannot be resolved", etc.

**Root Cause:** The `build/lib/xml-apis.jar` was not in the Eclipse classpath. This JAR contains the W3C DOM APIs (`org.w3c.dom.*`) that are used extensively throughout the codebase.

**Status:** ✅ FIXED - Added to `.classpath`

### 2. Module Mode Issues
**Symptom:** Eclipse not properly exposing JDK classes, mysterious "type not found" errors

**Root Cause:** The `.classpath` had `module="true"` set, which treats this as a Java 9+ modular project. OpenBD predates Java modules and is not a modular project.

**Status:** ✅ FIXED - Removed `module="true"` attribute

### 3. Missing Build Library JARs
**Symptom:** Various compilation errors for classes that should be available

**Root Cause:** Several JARs from `build/lib/` were not in the Eclipse classpath

**Status:** ✅ FIXED - Added:
- `build/lib/xml-apis.jar`
- `build/lib/commons-dbcp-1.1.jar`
- `build/lib/jaws.jar`
- `build/lib/mail.jar`

## Steps to Apply the Fix

### Option 1: Automatic (Recommended)
The `.classpath` file has been updated. Simply:

1. **Close Eclipse** completely (if it's open)
2. **Delete the Eclipse workspace metadata** for this project:
   ```bash
   rm -rf .metadata
   ```
   Or just delete `.project` and `.classpath` cache in your workspace

3. **Reopen Eclipse** and refresh the project:
   - Right-click on the project → **Refresh** (or press F5)
   - If errors persist: Right-click → **Maven** → **Update Project** (if using Maven)
   - Or: Right-click → **Properties** → **Java Build Path** → verify all JARs are present

4. **Clean and rebuild**:
   - **Project** → **Clean...** → Select openbd → **Clean**
   - **Project** → **Build All**

### Option 2: Manual Verification
If you still see errors after the automatic fix:

1. Right-click on project → **Properties** → **Java Build Path**
2. Click on the **Libraries** tab
3. Verify these JARs are present:
   - `build/lib/xml-apis.jar` ← **Most important**
   - `build/lib/commons-dbcp-1.1.jar`
   - `build/lib/jaws.jar`
   - `build/lib/mail.jar`
   - All JARs from `webapp/WEB-INF/lib/`

4. If missing, click **Add JARs...** and add them
5. Click **Apply and Close**
6. Clean and rebuild the project

## Known Remaining Issues

### 1. Jackson Core Source Code (NOT AN ISSUE)
**Status:** ✅ RESOLVED

The `build/build.xml` referenced `jackson-core-2.6.7.jar`, but this is not needed because **Jackson Core is embedded in the source code** at `src/com/fasterxml/jackson/core/`. The project vendors the entire Jackson Core library as source files (47+ Java files).

**Impact:** None - this is intentional

**Fixed:** Removed the incorrect JAR references from build.xml

### 2. Browser Applet Classes
**Status:** ⚠️ Known Issue (unrelated to classpath)

These files fail to compile on Java 9+ due to removal of the browser plugin API:
- `src/com/bluedragon/browser/SliderApplet.java`
- `src/com/bluedragon/browser/TextInput.java`
- `src/com/bluedragon/browser/TreeApplet.java`

**Solution:** Exclude from build by adding to source exclusions:
1. Right-click project → **Properties** → **Java Build Path** → **Source** tab
2. Expand `src` folder
3. Select **Excluded**
4. Click **Edit**
5. Add: `com/bluedragon/browser/**`

## Expected Error Count After Fixes

- **Before fixes:** ~802 errors
- **After xml-apis.jar added:** Should drop to ~10-50 errors (mostly applets and missing jackson-core)
- **After applets excluded:** Should drop to ~0-5 errors

## Troubleshooting

### "Still seeing 802 errors"
1. Make sure Eclipse has fully refreshed the project (F5)
2. Clean the project (**Project** → **Clean**)
3. Close and reopen Eclipse
4. Verify the `.classpath` file contains the xml-apis.jar entry
5. Check that `build/lib/xml-apis.jar` physically exists

### "xml-apis.jar is shown with an error icon in Eclipse"
1. Verify the JAR file exists: `ls -l build/lib/xml-apis.jar`
2. If missing, the repository may be incomplete - you may need to download it
3. Check file permissions

### "JRE System Library shows errors"
1. Right-click project → **Properties** → **Java Build Path**
2. Click **Libraries** tab
3. Select **JRE System Library**
4. Click **Edit**
5. Select **Workspace default JRE** or a specific JDK
6. Ensure you're using a **JDK** (not JRE)
7. Click **Finish**

### "Errors in packages I'm not using"
Eclipse compiles everything by default. You can exclude packages:
1. Right-click project → **Properties** → **Java Build Path** → **Source**
2. Expand the source folder
3. Add exclusion patterns for packages you don't need

## Verifying the Fix

After applying the fixes, check one of the problematic files:

1. Open `src/com/naryx/tagfusion/cfm/xml/cfXmlDataAttributeStruct.java`
2. Line 36 should show: `import org.w3c.dom.Attr;`
3. Hover over `Attr` - you should see it resolves to `org.w3c.dom.Attr` from `xml-apis.jar`
4. No red underlines should appear

## Additional Notes

- The project was originally created for JDK 1.3/1.4 but has been updated to support Java 8+
- Some compiler warnings are expected (deprecated API usage, unchecked operations)
- The project uses Ant for building - Eclipse is just for development/IDE support
- If you only need to build (not develop), use `ant -buildfile build/build.xml compile` instead

## Quick Reference: What's in Each JAR

- **xml-apis.jar** - W3C DOM APIs (Node, Attr, Element, Document, etc.)
- **commons-dbcp-1.1.jar** - Database connection pooling
- **jaws.jar** - Amazon JAWS (likely legacy, pre-AWS SDK)
- **mail.jar** - JavaMail API for email functionality
- **servlet-api-2.4.jar** - Servlet API for web container integration

## Getting Help

If you continue to have issues:
1. Check the error count - should be much lower after adding xml-apis.jar
2. Look at the **first** error in Eclipse's Problems view
3. Verify it's not one of the known issues (applets, jackson-core)
4. Check that all JAR files physically exist on disk
