<h1>Stage 4: Register Channel with allowPublish() and beforePublish() Hooks</h1>

<cfscript>
try {
	writeOutput("<h2>Test: Create Moderated Channel</h2>");

	// Register the channel with ModeratedChannelListener using the new wsRegisterChannel() API
	result = wsRegisterChannel(
		channelName: "moderatedChannel",
		listener: "OPENBD.websocket.ModeratedChannelListener"
	);

	if (result) {
		writeOutput("<p>✅ Registered 'moderatedChannel' with ModeratedChannelListener using wsRegisterChannel()</p>");

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
	} else {
		writeOutput("<h2 style='color: orange;'>⚠️ Channel Already Registered</h2>");
		writeOutput("<p>The 'moderatedChannel' already exists. This is normal if you've run this page before.</p>");
		writeOutput("<p>The existing channel is still active and ready for testing.</p>");

		writeOutput("<h3>Next: Test the channel</h3>");
		writeOutput("<p><a href='websocket_test_stage4.html'>Open Stage 4 Test Page</a></p>");
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
