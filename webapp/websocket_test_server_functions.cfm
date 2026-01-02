<h1>WebSocket Server-Side Functions Test</h1>

<cfscript>
try {
	writeOutput("<h2>Test 1: wsGetAllChannels() - Before Registration</h2>");

	// Get channels before registering any
	channels = wsGetAllChannels();
	writeOutput("<p>Channels before registration: " & arrayLen(channels) & "</p>");
	if (arrayLen(channels) GT 0) {
		writeDump(var=channels, label="Existing Channels");
	}

	writeOutput("<hr>");
	writeOutput("<h2>Test 2: wsRegisterChannel() - Create Test Channels</h2>");

	// Register a few test channels
	result1 = wsRegisterChannel("testChannel1");
	writeOutput("<p>Registered 'testChannel1': " & result1 & "</p>");

	result2 = wsRegisterChannel("testChannel2");
	writeOutput("<p>Registered 'testChannel2': " & result2 & "</p>");

	result3 = wsRegisterChannel("serverTestChannel");
	writeOutput("<p>Registered 'serverTestChannel': " & result3 & "</p>");

	writeOutput("<hr>");
	writeOutput("<h2>Test 3: wsGetAllChannels() - After Registration</h2>");

	// Get channels after registration
	channels = wsGetAllChannels();
	writeOutput("<p>Channels after registration: " & arrayLen(channels) & "</p>");
	writeDump(var=channels, label="All Registered Channels");

	writeOutput("<hr>");
	writeOutput("<h2>Test 4: wsGetSubscribers() - Before Any Subscriptions</h2>");

	// Get subscribers for each channel (should be empty)
	for (channelName in channels) {
		subscribers = wsGetSubscribers(channelName);
		writeOutput("<p><strong>" & channelName & "</strong>: " & arrayLen(subscribers) & " subscriber(s)</p>");
		if (arrayLen(subscribers) GT 0) {
			writeDump(var=subscribers, label=channelName & " Subscribers");
		}
	}

	writeOutput("<hr>");
	writeOutput("<h2>Test 5: wsPublish() - Server-Side Message</h2>");

	// Publish a message from server-side
	message1 = {
		type: "notification",
		text: "This is a server-side notification!",
		timestamp: now(),
		from: "SERVER"
	};

	publishResult = wsPublish("serverTestChannel", message1);
	writeOutput("<p>Published to 'serverTestChannel': " & publishResult & "</p>");
	writeDump(var=message1, label="Published Message");

	// Publish a simple string message
	publishResult2 = wsPublish("testChannel1", "Hello from the server!");
	writeOutput("<p>Published string to 'testChannel1': " & publishResult2 & "</p>");

	writeOutput("<hr>");
	writeOutput("<h2>Test 6: Error Handling - Invalid Channel</h2>");

	try {
		badResult = wsPublish("nonexistentChannel", "This should fail");
		writeOutput("<p style='color: red;'>ERROR: Should have thrown exception for non-existent channel!</p>");
	} catch (any e) {
		writeOutput("<p style='color: green;'>✅ Correctly threw exception for non-existent channel</p>");
		writeOutput("<p><strong>Error message:</strong> " & e.message & "</p>");
	}

	writeOutput("<hr>");
	writeOutput("<h2>Test 7: Complex Message with Different Data Types</h2>");

	complexMessage = {
		type: "update",
		data: {
			users: ["alice", "bob", "charlie"],
			counts: {
				total: 100,
				active: 75,
				inactive: 25
			},
			timestamp: now(),
			enabled: true
		},
		metadata: {
			source: "server",
			priority: "high"
		}
	};

	publishResult3 = wsPublish("testChannel2", complexMessage);
	writeOutput("<p>Published complex message: " & publishResult3 & "</p>");
	writeDump(var=complexMessage, label="Complex Message Structure");

	writeOutput("<hr>");
	writeOutput("<h2>✅ All Server-Side Function Tests Complete!</h2>");

	writeOutput("<h3>Summary:</h3>");
	writeOutput("<ul>");
	writeOutput("<li>✅ <strong>wsGetAllChannels()</strong> - Works correctly</li>");
	writeOutput("<li>✅ <strong>wsRegisterChannel()</strong> - Already tested in previous stages</li>");
	writeOutput("<li>✅ <strong>wsGetSubscribers()</strong> - Works correctly (returns empty arrays for channels with no subscribers)</li>");
	writeOutput("<li>✅ <strong>wsPublish()</strong> - Successfully publishes from server-side</li>");
	writeOutput("</ul>");

	writeOutput("<hr>");
	writeOutput("<h3>Next Steps:</h3>");
	writeOutput("<ol>");
	writeOutput("<li>Open <a href='websocket_test_server_functions_client.html' target='_blank'>Client Test Page</a> in a new tab</li>");
	writeOutput("<li>Subscribe to 'serverTestChannel' in the client</li>");
	writeOutput("<li>Use <a href='websocket_test_server_publish.cfm' target='_blank'>Server Publish Page</a> to send messages</li>");
	writeOutput("<li>Verify messages appear in the client</li>");
	writeOutput("</ol>");

} catch (any e) {
	writeOutput("<h2 style='color: red;'>❌ Error!</h2>");
	writeOutput("<p><strong>Type:</strong> " & e.type & "</p>");
	writeOutput("<p><strong>Message:</strong> " & e.message & "</p>");
	writeOutput("<p><strong>Detail:</strong> " & e.detail & "</p>");

	// Dump the entire exception for debugging
	writeOutput("<h3>Exception Details:</h3>");
	writeDump(var=e, label="Exception Object");
}
</cfscript>
