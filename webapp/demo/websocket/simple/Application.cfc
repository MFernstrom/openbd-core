/**
 * Simple WebSocket Example - Application.cfc
 *
 * Shows how to initialize a WebSocket channel.
 */
component {

	// Application Settings
	this.name = "SimpleWebSocketDemo";
	this.applicationTimeout = createTimeSpan(0, 2, 0, 0);

	/**
	 * onApplicationStart - Initialize WebSocket channel
	 *
	 * This method is called once when the application first starts.
	 * It registers a single "notifications" channel for demonstration.
	 *
	 * @return boolean - true to continue application startup
	 */
	function onApplicationStart() {
		consoleoutput(true);
		console("onApplicationStart launched::");
		
		writeLog(text="[SimpleWebSocket] Application starting - registering WebSocket channel", type="information");

		// Register a simple channel named "notifications"
		try {
			var result = wsRegisterChannel(channelName="notifications");

			if (result) {
				writeLog(text="[SimpleWebSocket] Successfully registered 'notifications' channel", type="information");
				application.channelsRegistered = true;
			} else {
				writeLog(text="[SimpleWebSocket] Channel already registered", type="warning");
				application.channelsRegistered = true;
			}

		} catch (any e) {
			writeLog(text="[SimpleWebSocket] ERROR registering channel: #e.message#", type="error");
		}

		return true;
	}

	/**
	 * onRequestStart - Allow manual reinitialization via URL parameter
	 *
	 * Visit any page with ?reinit=true to restart the application
	 * and re-register the WebSocket channel.
	 *
	 * @return boolean - true to continue processing the request
	 */
	function onRequestStart(required string targetPage) {

		// Allow URL-based reinitialization
		if (structKeyExists(url, "reinit") && url.reinit == true) {
			applicationStop();
			location(url=arguments.targetPage, addtoken=false);
		}

		return true;
	}

}
