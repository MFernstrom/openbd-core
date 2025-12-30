<cfscript>
// Manually register a test channel
// (In Phase 2, we don't have wsRegisterChannel() function yet,
//  so we'll call the Java class directly)

try {
	channelManager = CreateObject("java", "com.naryx.tagfusion.cfm.websocket.WebSocketChannelManager");
	instance = channelManager.getInstance();

	// Register the test channel
	success = instance.registerChannel("testChannel");

	if (success) {
		writeOutput("<h2>Success!</h2>");
		writeOutput("<p>Channel 'testChannel' registered successfully</p>");
	} else {
		writeOutput("<h2>Info</h2>");
		writeOutput("<p>Channel 'testChannel' already registered</p>");
	}

	// Show channel count
	channelCount = instance.getChannelCount();
	writeOutput("<p>Total registered channels: " & channelCount & "</p>");

} catch (any e) {
	writeOutput("<h2>Error</h2>");
	writeOutput("<p>" & e.message & "</p>");
	writeOutput("<pre>" & e.detail & "</pre>");
}
</cfscript>

<hr>
<p><a href="websocket_test.html">Go to WebSocket Test Page</a></p>
