<h1>Stage 7: Register Premium Chat Channel</h1>

<cfscript>
try {
	writeOutput("<h2>Comprehensive Channel Listener Test</h2>");

	// Register the channel with PremiumChatListener using wsRegisterChannel()
	result = wsRegisterChannel(
		channelName: "premiumChat",
		listener: "OPENBD.websocket.PremiumChatListener"
	);

	if (result) {
		writeOutput("<p>✅ Registered 'premiumChat' with PremiumChatListener using wsRegisterChannel()</p>");

		writeOutput("<hr>");
		writeOutput("<h2 style='color: green;'>✅ Premium Chat Channel Registered Successfully!</h2>");
		writeOutput("<p>This comprehensive channel demonstrates all 5 hooks working together:</p>");
		writeOutput("<ul>");
		writeOutput("<li>✅ <strong>allowSubscribe()</strong>: Authentication, tier validation, VIP room access control</li>");
		writeOutput("<li>✅ <strong>allowPublish()</strong>: Ban checking, tier-based room restrictions, rate limiting (5s/2s/1s)</li>");
		writeOutput("<li>✅ <strong>beforePublish()</strong>: HTML sanitization, server timestamps, message length limits (100/500/2000 chars)</li>");
		writeOutput("<li>✅ <strong>canSendMessage()</strong>: Room-based filtering, premium feature filtering, block lists</li>");
		writeOutput("<li>✅ <strong>beforeSendMessage()</strong>: Privacy controls (email/phone), tier-based feature access, per-user customization</li>");
		writeOutput("</ul>");

		writeOutput("<h3>Channel Features:</h3>");
		writeOutput("<ul>");
		writeOutput("<li>🆓 <strong>Free Tier</strong>: lobby room only, 100 char limit, 5s cooldown</li>");
		writeOutput("<li>💎 <strong>Premium Tier</strong>: premium room access, 500 char limit, 2s cooldown, premium features</li>");
		writeOutput("<li>👑 <strong>VIP Tier</strong>: all rooms including VIP, 2000 char limit, 1s cooldown, see all phone numbers</li>");
		writeOutput("</ul>");

		writeOutput("<h3>Security Features:</h3>");
		writeOutput("<ul>");
		writeOutput("<li>🔒 HTML/Script sanitization on all messages</li>");
		writeOutput("<li>🔒 Email addresses hidden from non-senders</li>");
		writeOutput("<li>🔒 Phone numbers hidden from non-VIP/non-senders</li>");
		writeOutput("<li>🔒 Premium features hidden from free users</li>");
		writeOutput("<li>🔒 Rate limiting prevents spam</li>");
		writeOutput("<li>🔒 Room-based message filtering</li>");
		writeOutput("</ul>");

		writeOutput("<h3>Next: Test the comprehensive channel</h3>");
		writeOutput("<p><a href='websocket_test_stage7_simple.html' style='font-size: 18px; font-weight: bold;'>Open Stage 7 Test Page (RECOMMENDED - Multi-Tab)</a></p>");
		writeOutput("<p><a href='websocket_test_stage7.html'>Open Stage 7 Test Page (Advanced - Single Tab Demo)</a></p>");
	} else {
		writeOutput("<h2 style='color: orange;'>⚠️ Channel Already Registered</h2>");
		writeOutput("<p>The 'premiumChat' channel already exists. This is normal if you've run this page before.</p>");
		writeOutput("<p>The existing channel is still active and ready for testing.</p>");

		writeOutput("<h3>Next: Test the comprehensive channel</h3>");
		writeOutput("<p><a href='websocket_test_stage7_simple.html' style='font-size: 18px; font-weight: bold;'>Open Stage 7 Test Page (RECOMMENDED - Multi-Tab)</a></p>");
		writeOutput("<p><a href='websocket_test_stage7.html'>Open Stage 7 Test Page (Advanced - Single Tab Demo)</a></p>");
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
