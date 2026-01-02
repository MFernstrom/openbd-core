<h1>Server-Side WebSocket Publisher</h1>

<cfscript>
// Handle form submission
if (structKeyExists(form, "action") AND form.action EQ "publish") {
	try {
		channelName = form.channelName;
		messageType = form.messageType;

		// Build message based on type
		if (messageType EQ "simple") {
			message = form.messageText;
		} else if (messageType EQ "notification") {
			message = {
				type: "notification",
				text: form.messageText,
				from: "SERVER",
				timestamp: now(),
				priority: form.priority
			};
		} else if (messageType EQ "data") {
			message = {
				type: "data-update",
				from: "SERVER",
				timestamp: now(),
				data: {
					metric: form.metricName,
					value: val(form.metricValue),
					unit: form.metricUnit
				}
			};
		}

		// Publish the message
		result = wsPublish(channelName, message);

		if (result) {
			writeOutput("<div style='background-color: #d4edda; color: #155724; padding: 15px; margin: 10px 0; border-radius: 4px;'>");
			writeOutput("<strong>✅ Message Published Successfully!</strong><br>");
			writeOutput("Channel: <strong>" & channelName & "</strong><br>");
			writeOutput("Type: " & messageType & "<br>");
			writeOutput("</div>");

			writeOutput("<h3>Published Message:</h3>");
			writeDump(var=message, label="Message Content");
		} else {
			writeOutput("<div style='background-color: #f8d7da; color: #721c24; padding: 15px; margin: 10px 0; border-radius: 4px;'>");
			writeOutput("<strong>❌ Publish Failed</strong><br>");
			writeOutput("Channel: " & channelName & "<br>");
			writeOutput("</div>");
		}

	} catch (any e) {
		writeOutput("<div style='background-color: #f8d7da; color: #721c24; padding: 15px; margin: 10px 0; border-radius: 4px;'>");
		writeOutput("<strong>❌ Error!</strong><br>");
		writeOutput("Message: " & e.message & "<br>");
		writeOutput("Detail: " & e.detail & "<br>");
		writeOutput("</div>");
	}

	writeOutput("<hr>");
}

// Get current channel information
try {
	allChannels = wsGetAllChannels();

	writeOutput("<h2>📊 Current Channel Status</h2>");
	writeOutput("<table border='1' cellpadding='5' cellspacing='0' style='border-collapse: collapse;'>");
	writeOutput("<tr>");
	writeOutput("<th>Channel Name</th>");
	writeOutput("<th>Subscribers</th>");
	writeOutput("<th>Subscriber Details</th>");
	writeOutput("</tr>");

	for (channelName in allChannels) {
		subscribers = wsGetSubscribers(channelName);
		writeOutput("<tr>");
		writeOutput("<td><strong>" & channelName & "</strong></td>");
		writeOutput("<td align='center'>" & arrayLen(subscribers) & "</td>");
		writeOutput("<td>");

		if (arrayLen(subscribers) GT 0) {
			writeOutput("<ul style='margin: 0; padding-left: 20px;'>");
			for (sub in subscribers) {
				writeOutput("<li>");
				writeOutput("ID: " & sub.connectionId);
				if (structKeyExists(sub, "subscriberInfo") AND structKeyExists(sub.subscriberInfo, "userId")) {
					writeOutput(" (User: " & sub.subscriberInfo.userId & ")");
				}
				writeOutput("</li>");
			}
			writeOutput("</ul>");
		} else {
			writeOutput("<em>No subscribers</em>");
		}

		writeOutput("</td>");
		writeOutput("</tr>");
	}

	writeOutput("</table>");

	writeOutput("<hr>");

} catch (any e) {
	writeOutput("<p style='color: red;'>Error getting channel info: " & e.message & "</p>");
}
</cfscript>

<h2>📤 Publish Message to Channel</h2>

<form method="post" style="max-width: 600px;">
	<input type="hidden" name="action" value="publish">

	<div style="margin: 10px 0;">
		<label><strong>Channel:</strong></label><br>
		<select name="channelName" style="padding: 5px; width: 100%;">
			<cfoutput>
			<cfloop array="#allChannels#" index="ch">
				<option value="#ch#">#ch#</option>
			</cfloop>
			</cfoutput>
		</select>
	</div>

	<div style="margin: 10px 0;">
		<label><strong>Message Type:</strong></label><br>
		<select name="messageType" id="messageType" onchange="updateFormFields()" style="padding: 5px; width: 100%;">
			<option value="simple">Simple Text</option>
			<option value="notification">Notification (with metadata)</option>
			<option value="data">Data Update (with metrics)</option>
		</select>
	</div>

	<div style="margin: 10px 0;">
		<label><strong>Message Text:</strong></label><br>
		<textarea name="messageText" rows="3" style="padding: 5px; width: 100%;">Hello from the server! This is a test message.</textarea>
	</div>

	<div id="notificationFields" style="margin: 10px 0; display: none;">
		<label><strong>Priority:</strong></label><br>
		<select name="priority" style="padding: 5px; width: 100%;">
			<option value="low">Low</option>
			<option value="normal" selected>Normal</option>
			<option value="high">High</option>
			<option value="urgent">Urgent</option>
		</select>
	</div>

	<div id="dataFields" style="margin: 10px 0; display: none;">
		<label><strong>Metric Name:</strong></label><br>
		<input type="text" name="metricName" value="cpu_usage" style="padding: 5px; width: 100%;">

		<label style="margin-top: 5px;"><strong>Value:</strong></label><br>
		<input type="text" name="metricValue" value="75.5" style="padding: 5px; width: 100%;">

		<label style="margin-top: 5px;"><strong>Unit:</strong></label><br>
		<input type="text" name="metricUnit" value="percent" style="padding: 5px; width: 100%;">
	</div>

	<div style="margin: 15px 0;">
		<button type="submit" style="padding: 10px 20px; background-color: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 14px;">
			📤 Publish Message
		</button>
	</div>
</form>

<script>
function updateFormFields() {
	var messageType = document.getElementById('messageType').value;
	var notificationFields = document.getElementById('notificationFields');
	var dataFields = document.getElementById('dataFields');

	notificationFields.style.display = 'none';
	dataFields.style.display = 'none';

	if (messageType === 'notification') {
		notificationFields.style.display = 'block';
	} else if (messageType === 'data') {
		dataFields.style.display = 'block';
	}
}
</script>

<hr>
<h3>📖 Instructions:</h3>
<ol>
	<li>Open <a href="websocket_test_server_functions_client.html" target="_blank">Client Test Page</a> in another tab/window</li>
	<li>Connect and subscribe to a channel in the client</li>
	<li>Use the form above to publish messages from the server</li>
	<li>Messages should appear in the client in real-time!</li>
	<li>Refresh this page to see updated subscriber counts</li>
</ol>

<hr>
<p><a href="websocket_test_server_functions.cfm">← Back to Server Functions Test</a></p>
