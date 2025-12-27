# Eclipse Refresh Guide

If you're seeing errors in Eclipse but Ant builds successfully, Eclipse hasn't reloaded the `.classpath` changes.

## Quick Fix (Try These In Order)

### 1. Refresh + Clean (30 seconds)
```
1. Select project in Project Explorer
2. Right-click → Refresh (or press F5)
3. Project → Clean... → Select openbd → Clean
4. Wait for rebuild to complete
```

### 2. Force Classpath Reload (1 minute)
```
1. Right-click project → Properties
2. Java Build Path → Libraries tab
3. Verify all JARs are present (no red X marks)
4. Click Apply and Close
5. Project → Clean
```

### 3. Close/Reopen Project (1 minute)
```
1. Right-click project → Close Project
2. Wait 5 seconds
3. Right-click project → Open Project
4. Wait for rebuild
```

### 4. Restart Eclipse (2 minutes)
```
1. File → Exit
2. Reopen Eclipse
3. Refresh project (F5)
4. Project → Clean
```

## Verification

After refreshing, check:

✅ **Problems view shows 0 errors** (or very few)
✅ **Libraries visible:** Right-click project → Properties → Java Build Path → Libraries
✅ **xml-apis.jar present** in the Libraries list
✅ **No red X marks** on any JARs

## Still Seeing Errors?

If errors persist after refreshing:

1. Note the **first error** in the Problems view
2. Check if it's still "Attr cannot be resolved"
3. Verify xml-apis.jar exists: `ls -l build/lib/xml-apis.jar`
4. Check Eclipse is using a JDK (not JRE):
   - Window → Preferences → Java → Installed JREs
   - Should show JDK path (e.g., `/usr/lib/jvm/java-11-openjdk`)

## Common Issues

**"Still 799 errors after refresh"**
- Eclipse didn't reload .classpath
- Try restarting Eclipse (Option 4)

**"xml-apis.jar has red X"**
- File doesn't exist or wrong path
- Verify: `ls -l build/lib/xml-apis.jar`
- Should show 194205 bytes

**"Some JARs missing from Libraries"**
- .classpath file might be corrupted
- Let me know and I'll regenerate it

**"Eclipse is using JRE not JDK"**
- Window → Preferences → Java → Installed JREs
- Add JDK if not present
- Right-click project → Properties → Java Build Path → Libraries
- Edit JRE System Library to use JDK

## Expected State After Refresh

- **Errors:** 0 (or only a few in browser applet files if not excluded)
- **Libraries:** 98 JARs visible in Build Path
- **Build:** Both Ant and Eclipse compile successfully
- **First file check:** Open `cfXmlDataAttributeStruct.java` - line 36 `import org.w3c.dom.Attr;` should have no errors
