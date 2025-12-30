<h1>WebSocket Channel Registration Test</h1>

<h2>Using wsRegisterChannel() Function</h2>

<cfscript>
// Test the new wsRegisterChannel() CFML function

try {
	// Register test channel
	result1 = wsRegisterChannel("testChannel");
	writeOutput("<p>✓ wsRegisterChannel('testChannel') = " & result1 & "</p>");

	// Try registering same channel again (should return false)
	result2 = wsRegisterChannel("testChannel");
	writeOutput("<p>✓ wsRegisterChannel('testChannel') again = " & result2 & " (expected: false)</p>");

	// Register another channel
	result3 = wsRegisterChannel("chatChannel");
	writeOutput("<p>✓ wsRegisterChannel('chatChannel') = " & result3 & "</p>");

	// Register one more
	result4 = wsRegisterChannel("notifyChannel");
	writeOutput("<p>✓ wsRegisterChannel('notifyChannel') = " & result4 & "</p>");

	writeOutput("<h3>Success! All channels registered.</h3>");

} catch (any e) {
	writeOutput("<h3 style='color: red;'>Error!</h3>");
	writeOutput("<p>" & e.message & "</p>");
	writeOutput("<pre>" & e.detail & "</pre>");
}
</cfscript>

<hr>
<h3>Test Pages</h3>
<ul>
	<li><a href="websocket_test.html">Single Channel Test (testChannel only)</a></li>
	<li><a href="websocket_multichannel_test.html">Multi-Channel Test (testChannel, chatChannel, notifyChannel)</a></li>
</ul>
