<h1>WebSocket Function Diagnostic</h1>

<cfscript>
writeOutput("<h2>Test 1: Check if function exists via GetFunctionList()</h2>");

try {
	// Get all available functions
	allFunctions = GetFunctionList();

	writeOutput("<p>Total functions available: " & structCount(allFunctions) & "</p>");

	// Check for our WebSocket functions
	wsfunctions = [];
	wsfunctions[1] = "wsRegisterChannel";
	wsfunctions[2] = "wsGetAllChannels";
	wsfunctions[3] = "wsPublish";
	wsfunctions[4] = "wsGetSubscribers";

	writeOutput("<h3>Checking for WebSocket functions:</h3>");
	writeOutput("<table border='1' cellpadding='5'>");
	writeOutput("<tr><th>Function Name</th><th>Exists?</th></tr>");

	for (fname in wsfunctions) {
		exists = structKeyExists(allFunctions, fname);
		writeOutput("<tr>");
		writeOutput("<td>" & fname & "</td>");
		writeOutput("<td style='color: " & (exists ? "green" : "red") & ";'>" & (exists ? "YES ✓" : "NO ✗") & "</td>");
		writeOutput("</tr>");
	}

	writeOutput("</table>");

} catch (any e) {
	writeOutput("<p style='color: red;'>Error getting function list: " & e.message & "</p>");
}

writeOutput("<hr>");
writeOutput("<h2>Test 2: Try calling each function</h2>");

// Test wsRegisterChannel (should work - we know this one works)
writeOutput("<h3>1. wsRegisterChannel()</h3>");
try {
	result = wsRegisterChannel("diagnosticChannel");
	writeOutput("<p style='color: green;'>✓ SUCCESS: " & result & "</p>");
} catch (any e) {
	writeOutput("<p style='color: red;'>✗ FAILED: " & e.message & "</p>");
}

// Test wsGetAllChannels
writeOutput("<h3>2. wsGetAllChannels()</h3>");
try {
	result = wsGetAllChannels();
	writeOutput("<p style='color: green;'>✓ SUCCESS: Returned " & arrayLen(result) & " channels</p>");
	if (arrayLen(result) GT 0) {
		writeDump(var=result, label="Channels");
	}
} catch (any e) {
	writeOutput("<p style='color: red;'>✗ FAILED: " & e.message & "</p>");
	writeOutput("<pre>");
	writeDump(var=e);
	writeOutput("</pre>");
}

// Test wsGetSubscribers
writeOutput("<h3>3. wsGetSubscribers()</h3>");
try {
	result = wsGetSubscribers("diagnosticChannel");
	writeOutput("<p style='color: green;'>✓ SUCCESS: Returned " & arrayLen(result) & " subscribers</p>");
} catch (any e) {
	writeOutput("<p style='color: red;'>✗ FAILED: " & e.message & "</p>");
	writeOutput("<pre>");
	writeDump(var=e);
	writeOutput("</pre>");
}

// Test wsPublish
writeOutput("<h3>4. wsPublish()</h3>");
try {
	result = wsPublish("diagnosticChannel", "Test message");
	writeOutput("<p style='color: green;'>✓ SUCCESS: " & result & "</p>");
} catch (any e) {
	writeOutput("<p style='color: red;'>✗ FAILED: " & e.message & "</p>");
	writeOutput("<pre>");
	writeDump(var=e);
	writeOutput("</pre>");
}
</cfscript>

<hr>
<h2>Debug Information</h2>
<p>Check the server log at: <code>webapp/WEB-INF/bluedragon/work/bluedragon.log</code></p>
<p>Look for lines containing: <code>[WebSocket]</code></p>
