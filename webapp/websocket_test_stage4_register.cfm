<h1>Stage 4: Register Channel with allowPublish() and beforePublish() Hooks</h1>

<cfscript>
try {
	writeOutput("<h2>Test: Create Moderated Channel</h2>");

	// Create the ModeratedChannelListener CFC
	listener = CreateObject("component", "OPENBD.websocket.ModeratedChannelListener");
	writeOutput("<p>✅ ModeratedChannelListener CFC loaded</p>");

	// Get channel manager
	channelManagerClass = CreateObject("java", "com.naryx.tagfusion.cfm.websocket.WebSocketChannelManager");
	manager = channelManagerClass.getInstance();

	// Create a channel directly with the CFC
	channelClass = CreateObject("java", "com.naryx.tagfusion.cfm.websocket.WebSocketChannel");
	moderatedChannel = channelClass.init("moderatedChannel", listener);
	writeOutput("<p>✅ Created channel 'moderatedChannel' with ModeratedChannelListener</p>");

	// Manually register the channel with the manager (using reflection)
	channelsField = manager.getClass().getDeclaredField("channels");
	channelsField.setAccessible(true);
	channelsMap = channelsField.get(manager);
	channelsMap.put("moderatedChannel", moderatedChannel);

	writeOutput("<p>✅ Registered 'moderatedChannel' with manager</p>");

	writeOutput("<hr>");
	writeOutput("<h2 style='color: green;'>✅ Channel Registered Successfully!</h2>");
	writeOutput("<p>The 'moderatedChannel' is now active with publish moderation enabled.</p>");
	writeOutput("<ul>");
	writeOutput("<li>✅ allowPublish() hook will check if user has 'moderator' role</li>");
	writeOutput("<li>✅ beforePublish() hook will add timestamps and sanitize content</li>");
	writeOutput("<li>✅ Non-moderators will not be able to publish messages</li>");
	writeOutput("</ul>");

	writeOutput("<h3>Next: Test the channel</h3>");
	writeOutput("<p><a href='websocket_test_stage4.html'>Open Stage 4 Test Page</a></p>");

} catch (any e) {
	writeOutput("<h2 style='color: red;'>❌ Error!</h2>");
	writeOutput("<p><strong>Type:</strong> " & e.type & "</p>");
	writeOutput("<p><strong>Message:</strong> " & e.message & "</p>");
	writeOutput("<p><strong>Detail:</strong> " & e.detail & "</p>");
	writeOutput("<h3>Stack Trace:</h3>");
	writeOutput("<pre>" & e.stacktrace & "</pre>");
}
</cfscript>
