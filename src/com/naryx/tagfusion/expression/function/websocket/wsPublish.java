/*
 *  Copyright (C) 2000 - 2025 TagServlet Ltd
 *
 *  This file is part of Open BlueDragon (OpenBD) CFML Server Engine.
 *
 *  OpenBD is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  Free Software Foundation,version 3.
 *
 *  OpenBD is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with OpenBD.  If not, see http://www.gnu.org/licenses/
 *
 *  Additional permission under GNU GPL version 3 section 7
 *
 *  If you modify this Program, or any covered work, by linking or combining
 *  it with any of the JARS listed in the README.txt (or a modified version of
 *  (that library), containing parts covered by the terms of that JAR, the
 *  licensors of this Program grant you additional permission to convey the
 *  resulting work.
 *  README.txt @ http://www.openbluedragon.org/license/README.txt
 *
 *  http://openbd.org/
 */
package com.naryx.tagfusion.expression.function.websocket;

import com.naryx.tagfusion.cfm.engine.cfArgStructData;
import com.naryx.tagfusion.cfm.engine.cfBooleanData;
import com.naryx.tagfusion.cfm.engine.cfData;
import com.naryx.tagfusion.cfm.engine.cfSession;
import com.naryx.tagfusion.cfm.engine.cfStructData;
import com.naryx.tagfusion.cfm.engine.cfmRunTimeException;
import com.naryx.tagfusion.cfm.websocket.WebSocketChannelManager;
import com.naryx.tagfusion.cfm.websocket.WebSocketConnection;
import com.naryx.tagfusion.expression.function.functionBase;

/**
 * wsPublish(channelName, message)
 *
 * Publish a message to a WebSocket channel from server-side CFML code.
 *
 * This allows server-side code to push messages to WebSocket subscribers
 * without requiring a client to publish the message.
 *
 * Example:
 *   wsPublish("chatChannel", "Server announcement: maintenance in 5 minutes")
 *
 *   wsPublish("notificationChannel", {
 *       type: "alert",
 *       message: "New order received",
 *       timestamp: now()
 *   })
 *
 * Returns: true if message published successfully, false otherwise
 */
public class wsPublish extends functionBase {
	private static final long serialVersionUID = 1L;

	public wsPublish() {
		min = 2;
		max = 2;
		setNamedParams(new String[] { "channelname", "message" });
	}

	public String[] getParamInfo() {
		return new String[] {
			"Channel name to publish to",
			"Message to publish (string, struct, array, or any CFML data type)"
		};
	}

	public java.util.Map<String, String> getInfo() {
		return makeInfo(
			"websocket",
			"Publish a message to a WebSocket channel from server-side code",
			ReturnType.BOOLEAN
		);
	}

	public cfData execute(cfSession _session, cfArgStructData argStruct) throws cfmRunTimeException {
		// Get channel name
		String channelName = getNamedStringParam(argStruct, "channelname", null);
		if (channelName == null || channelName.trim().isEmpty()) {
			throwException(_session, "channelName is required");
		}

		// Get message (can be any cfData type)
		cfData message = getNamedParam(argStruct, "message");
		if (message == null) {
			throwException(_session, "message is required");
		}

		WebSocketChannelManager manager = WebSocketChannelManager.getInstance();

		// Check if channel exists
		if (!manager.isChannelRegistered(channelName.trim())) {
			throwException(_session, "Channel '" + channelName.trim() + "' is not registered. Use wsRegisterChannel() first.");
		}

		// Create a server-side "publisher" connection
		// This is a synthetic connection representing the server
		WebSocketConnection serverPublisher = WebSocketConnection.createServerPublisher();

		// Publish the message
		boolean success = manager.publish(channelName.trim(), serverPublisher, message);

		return cfBooleanData.getcfBooleanData(success);
	}
}
