<h1>Stage 5: Register Channel with canSendMessage() and beforeSendMessage() Hooks</h1>

<cfscript>
try {
	writeOutput("<h2>Test: Create Room-Based Channel</h2>");

	// Register the channel with RoomChannelListener using the new wsRegisterChannel() API
	result = wsRegisterChannel(
		channelName: "roomChannel",
		listener: "OPENBD.websocket.RoomChannelListener"
	);

	if (result) {
		writeOutput("<p>✅ Registered 'roomChannel' with RoomChannelListener using wsRegisterChannel()</p>");

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
		writeOutput("<p><a href='websocket_test_stage5_simple.html'>Open Stage 5 Test Page (Simple - Multi-Tab)</a></p>");
		writeOutput("<p><a href='websocket_test_stage5.html'>Open Stage 5 Test Page (Advanced - Multi-Panel)</a></p>");
	} else {
		writeOutput("<h2 style='color: orange;'>⚠️ Channel Already Registered</h2>");
		writeOutput("<p>The 'roomChannel' already exists. This is normal if you've run this page before.</p>");
		writeOutput("<p>The existing channel is still active and ready for testing.</p>");

		writeOutput("<h3>Next: Test the channel</h3>");
		writeOutput("<p><a href='websocket_test_stage5_simple.html'>Open Stage 5 Test Page (Simple - Multi-Tab)</a></p>");
		writeOutput("<p><a href='websocket_test_stage5.html'>Open Stage 5 Test Page (Advanced - Multi-Panel)</a></p>");
	}

} catch (any e) {
	writeOutput("<h2 style='color: red;'>❌ Error!</h2>");
	writeOutput("<p><strong>Type:</strong> " & e.type & "</p>");
	writeOutput("<p><strong>Message:</strong> " & e.message & "</p>");
	writeOutput("<p><strong>Detail:</strong> " & e.detail & "</p>");
	writeOutput("<h3>Stack Trace:</h3>");
	writeOutput("<pre>" & e.stacktrace & "</pre>");
}
</cfscript>
