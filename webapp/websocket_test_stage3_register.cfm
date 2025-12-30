<h1>Stage 3: Register Channel with allowSubscribe() Hook</h1>

<cfscript>
try {
	writeOutput("<h2>Test: Create Authenticated Channel</h2>");

	// Create the AuthChannelListener CFC
	listener = CreateObject("component", "OPENBD.websocket.AuthChannelListener");
	writeOutput("<p>✅ AuthChannelListener CFC loaded</p>");

	// Get channel manager
	channelManagerClass = CreateObject("java", "com.naryx.tagfusion.cfm.websocket.WebSocketChannelManager");
	manager = channelManagerClass.getInstance();

	// Create a channel directly with the CFC
	channelClass = CreateObject("java", "com.naryx.tagfusion.cfm.websocket.WebSocketChannel");
	authChannel = channelClass.init("authChannel", listener);
	writeOutput("<p>✅ Created channel 'authChannel' with AuthChannelListener</p>");

	// Manually register the channel with the manager
	// Note: In Stage 6 we'll update wsRegisterChannel() to accept a listener parameter
	manager.getChannels(); // Force manager initialization if needed

	// Access private channels map via reflection (temporary workaround for Stage 3)
	// In Stage 6, we'll add a proper registerChannel(name, listener) method
	channelsField = manager.getClass().getDeclaredField("channels");
	channelsField.setAccessible(true);
	channelsMap = channelsField.get(manager);
	channelsMap.put("authChannel", authChannel);

	writeOutput("<p>✅ Registered 'authChannel' with manager</p>");

	writeOutput("<hr>");
	writeOutput("<h2 style='color: green;'>✅ Channel Registered Successfully!</h2>");
	writeOutput("<p>The 'authChannel' is now active with authentication enabled.</p>");
	writeOutput("<ul>");
	writeOutput("<li>✅ allowSubscribe() hook will be invoked on subscription attempts</li>");
	writeOutput("<li>✅ Valid authToken: <strong>SECRET123</strong></li>");
	writeOutput("<li>✅ Invalid tokens will be rejected</li>");
	writeOutput("</ul>");

	writeOutput("<h3>Next: Test the channel</h3>");
	writeOutput("<p><a href='websocket_test_stage3.html'>Open Stage 3 Test Page</a></p>");

} catch (any e) {
	writeOutput("<h2 style='color: red;'>❌ Error!</h2>");
	writeOutput("<p><strong>Type:</strong> " & e.type & "</p>");
	writeOutput("<p><strong>Message:</strong> " & e.message & "</p>");
	writeOutput("<p><strong>Detail:</strong> " & e.detail & "</p>");
	writeOutput("<h3>Stack Trace:</h3>");
	writeOutput("<pre>" & e.stacktrace & "</pre>");
}
</cfscript>
