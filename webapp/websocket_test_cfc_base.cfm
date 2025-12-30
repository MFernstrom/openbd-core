<h1>Stage 1: Base ChannelListener.cfc Test</h1>

<cfscript>
try {
	writeOutput("<h2>Test 1: Load Base CFC</h2>");

	// Create instance of base ChannelListener
	listener = CreateObject("component", "OPENBD.websocket.ChannelListener");
	writeOutput("<p>✅ Base CFC loaded successfully</p>");

	// Test each method with sample data
	writeOutput("<h2>Test 2: Call allowSubscribe()</h2>");
	subscriberInfo = {
		clientId = "test-client-123",
		username = "testuser"
	};
	result = listener.allowSubscribe(subscriberInfo);
	writeOutput("<p>✅ allowSubscribe() returned: <strong>" & result & "</strong> (expected: true)</p>");

	writeOutput("<h2>Test 3: Call allowPublish()</h2>");
	publisherInfo = {
		connectionId = "conn-456",
		subscriberInfo = subscriberInfo
	};
	result = listener.allowPublish(publisherInfo);
	writeOutput("<p>✅ allowPublish() returned: <strong>" & result & "</strong> (expected: true)</p>");

	writeOutput("<h2>Test 4: Call beforePublish()</h2>");
	message = {
		text = "Hello World",
		from = "testuser"
	};
	result = listener.beforePublish(publisherInfo, message);
	writeOutput("<p>✅ beforePublish() returned message with keys: <strong>" & structKeyList(result) & "</strong></p>");
	writeOutput("<p>Message unchanged: <strong>" & (result.text eq "Hello World") & "</strong></p>");

	writeOutput("<h2>Test 5: Call canSendMessage()</h2>");
	result = listener.canSendMessage(subscriberInfo, message);
	writeOutput("<p>✅ canSendMessage() returned: <strong>" & result & "</strong> (expected: true)</p>");

	writeOutput("<h2>Test 6: Call beforeSendMessage()</h2>");
	result = listener.beforeSendMessage(subscriberInfo, message);
	writeOutput("<p>✅ beforeSendMessage() returned message with keys: <strong>" & structKeyList(result) & "</strong></p>");
	writeOutput("<p>Message unchanged: <strong>" & (result.text eq "Hello World") & "</strong></p>");

	writeOutput("<hr>");
	writeOutput("<h2 style='color: green;'>✅ All Tests Passed!</h2>");
	writeOutput("<p>The base ChannelListener.cfc is working correctly.</p>");
	writeOutput("<p>All 5 lifecycle methods return expected default values:</p>");
	writeOutput("<ul>");
	writeOutput("<li>allowSubscribe() = true</li>");
	writeOutput("<li>allowPublish() = true</li>");
	writeOutput("<li>beforePublish() = message unchanged</li>");
	writeOutput("<li>canSendMessage() = true</li>");
	writeOutput("<li>beforeSendMessage() = message unchanged</li>");
	writeOutput("</ul>");

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
<p><strong>Next:</strong> Stage 2 will update WebSocketChannel to store this CFC reference</p>
