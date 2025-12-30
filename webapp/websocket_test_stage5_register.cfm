<h1>Stage 5: Register Channel with canSendMessage() and beforeSendMessage() Hooks</h1>

<cfscript>
try {
	writeOutput("<h2>Test: Create Room-Based Channel</h2>");

	// Create the RoomChannelListener CFC
	listener = CreateObject("component", "OPENBD.websocket.RoomChannelListener");
	writeOutput("<p>✅ RoomChannelListener CFC loaded</p>");

	// Get channel manager
	channelManagerClass = CreateObject("java", "com.naryx.tagfusion.cfm.websocket.WebSocketChannelManager");
	manager = channelManagerClass.getInstance();

	// Create a channel directly with the CFC
	channelClass = CreateObject("java", "com.naryx.tagfusion.cfm.websocket.WebSocketChannel");
	roomChannel = channelClass.init("roomChannel", listener);
	writeOutput("<p>✅ Created channel 'roomChannel' with RoomChannelListener</p>");

	// Manually register the channel with the manager (using reflection)
	channelsField = manager.getClass().getDeclaredField("channels");
	channelsField.setAccessible(true);
	channelsMap = channelsField.get(manager);
	channelsMap.put("roomChannel", roomChannel);

	writeOutput("<p>✅ Registered 'roomChannel' with manager</p>");

	writeOutput("<hr>");
	writeOutput("<h2 style='color: green;'>✅ Channel Registered Successfully!</h2>");
	writeOutput("<p>The 'roomChannel' is now active with per-subscriber filtering and customization.</p>");
	writeOutput("<ul>");
	writeOutput("<li>✅ canSendMessage() hook will filter messages by room</li>");
	writeOutput("<li>✅ beforeSendMessage() hook will customize each message per subscriber</li>");
	writeOutput("<li>✅ Email addresses hidden from non-senders</li>");
	writeOutput("<li>✅ Phone numbers hidden from non-admins</li>");
	writeOutput("<li>✅ 'isYou' flag added for sender's own messages</li>");
	writeOutput("</ul>");

	writeOutput("<h3>Next: Test the channel</h3>");
	writeOutput("<p><a href='websocket_test_stage5.html'>Open Stage 5 Test Page</a></p>");

} catch (any e) {
	writeOutput("<h2 style='color: red;'>❌ Error!</h2>");
	writeOutput("<p><strong>Type:</strong> " & e.type & "</p>");
	writeOutput("<p><strong>Message:</strong> " & e.message & "</p>");
	writeOutput("<p><strong>Detail:</strong> " & e.detail & "</p>");
	writeOutput("<h3>Stack Trace:</h3>");
	writeOutput("<pre>" & e.stacktrace & "</pre>");
}
</cfscript>
