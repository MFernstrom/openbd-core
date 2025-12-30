<h1>Stage 3: Register Channel with allowSubscribe() Hook</h1>

<cfscript>
try {
	writeOutput("<h2>Test: Create Authenticated Channel</h2>");

	// Register the channel with AuthChannelListener using the new wsRegisterChannel() API
	result = wsRegisterChannel(
		channelName: "authChannel",
		listener: "OPENBD.websocket.AuthChannelListener"
	);

	if (result) {
		writeOutput("<p>✅ Registered 'authChannel' with AuthChannelListener using wsRegisterChannel()</p>");

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
	} else {
		writeOutput("<h2 style='color: orange;'>⚠️ Channel Already Registered</h2>");
		writeOutput("<p>The 'authChannel' already exists. This is normal if you've run this page before.</p>");
		writeOutput("<p>The existing channel is still active and ready for testing.</p>");

		writeOutput("<h3>Next: Test the channel</h3>");
		writeOutput("<p><a href='websocket_test_stage3.html'>Open Stage 3 Test Page</a></p>");
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
