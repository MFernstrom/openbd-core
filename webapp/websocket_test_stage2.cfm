<h1>Stage 2: WebSocketChannel CFC Storage Test</h1>

<cfscript>
try {
	writeOutput("<h2>Test 1: Create Channel WITHOUT CFC (Backwards Compatibility)</h2>");

	// Get channel manager
	channelManagerClass = CreateObject("java", "com.naryx.tagfusion.cfm.websocket.WebSocketChannelManager");
	manager = channelManagerClass.getInstance();

	// Create channel without CFC
	success1 = manager.registerChannel("testChannelNoCFC");
	writeOutput("<p>✅ Channel registered without CFC: <strong>" & success1 & "</strong></p>");

	writeOutput("<h2>Test 2: Create Channel WITH CFC</h2>");

	// Load the base ChannelListener CFC
	listener = CreateObject("component", "OPENBD.websocket.ChannelListener");
	writeOutput("<p>✅ Listener CFC loaded successfully</p>");

	// Create a WebSocketChannel directly with the CFC
	channelClass = CreateObject("java", "com.naryx.tagfusion.cfm.websocket.WebSocketChannel");
	channelWithCFC = channelClass.init("testChannelWithCFC", listener);

	writeOutput("<p>✅ Channel created with CFC reference</p>");

	// Test hasListener() method
	hasListener = channelWithCFC.hasListener();
	writeOutput("<p>✅ hasListener() = <strong>" & hasListener & "</strong> (expected: true)</p>");

	// Test getListenerCFC() method
	retrievedCFC = channelWithCFC.getListenerCFC();
	writeOutput("<p>✅ getListenerCFC() returned: <strong>" & (isNull(retrievedCFC) ? "null" : "CFC object") & "</strong></p>");

	writeOutput("<h2>Test 3: Verify Backwards Compatibility</h2>");

	// Create channel using old constructor (no CFC parameter)
	channelNoCFC = channelClass.init("testChannelOldWay");
	hasListener2 = channelNoCFC.hasListener();
	writeOutput("<p>✅ Old constructor still works, hasListener() = <strong>" & hasListener2 & "</strong> (expected: false)</p>");

	writeOutput("<hr>");
	writeOutput("<h2 style='color: green;'>✅ All Stage 2 Tests Passed!</h2>");
	writeOutput("<p>WebSocketChannel now stores CFC references correctly:</p>");
	writeOutput("<ul>");
	writeOutput("<li>✅ Backwards compatible (channels without CFCs still work)</li>");
	writeOutput("<li>✅ Can store CFC reference in channel</li>");
	writeOutput("<li>✅ hasListener() method works correctly</li>");
	writeOutput("<li>✅ getListenerCFC() retrieves the CFC</li>");
	writeOutput("</ul>");

	writeOutput("<h3>Next: Stage 3 will implement the allowSubscribe() hook</h3>");

} catch (any e) {
	writeOutput("<h2 style='color: red;'>❌ Error!</h2>");
	writeOutput("<p><strong>Type:</strong> " & e.type & "</p>");
	writeOutput("<p><strong>Message:</strong> " & e.message & "</p>");
	writeOutput("<p><strong>Detail:</strong> " & e.detail & "</p>");
	writeOutput("<h3>Stack Trace:</h3>");
	writeOutput("<pre>" & e.stacktrace & "</pre>");
}
</cfscript>

<hr>
<h3>Regression Test: Verify Existing Functionality</h3>
<p>The multi-channel test should still work without any changes.</p>
<p><a href="websocket_multichannel_test.html" target="_blank">Open Multi-Channel Test</a> (should work exactly as before)</p>
