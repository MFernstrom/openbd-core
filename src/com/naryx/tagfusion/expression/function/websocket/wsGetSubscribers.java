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

import java.util.List;

import com.naryx.tagfusion.cfm.engine.cfArgStructData;
import com.naryx.tagfusion.cfm.engine.cfArrayData;
import com.naryx.tagfusion.cfm.engine.cfBooleanData;
import com.naryx.tagfusion.cfm.engine.cfData;
import com.naryx.tagfusion.cfm.engine.cfNumberData;
import com.naryx.tagfusion.cfm.engine.cfSession;
import com.naryx.tagfusion.cfm.engine.cfStringData;
import com.naryx.tagfusion.cfm.engine.cfStructData;
import com.naryx.tagfusion.cfm.engine.cfmRunTimeException;
import com.naryx.tagfusion.cfm.websocket.WebSocketChannelManager;
import com.naryx.tagfusion.cfm.websocket.WebSocketConnection;
import com.naryx.tagfusion.expression.function.functionBase;

/**
 * wsGetSubscribers(channelName)
 *
 * Get a list of all subscribers currently subscribed to a WebSocket channel.
 *
 * Returns an array of structs, where each struct contains information about
 * a subscriber:
 *   - connectionId: the unique connection ID
 *   - subscriberInfo: custom data provided during subscription (if any)
 *   - subscribedChannelCount: number of channels this connection is subscribed to
 *
 * Example:
 *   subscribers = wsGetSubscribers("chatChannel");
 *   writeOutput("Channel has " & arrayLen(subscribers) & " subscribers<br>");
 *
 *   for (sub in subscribers) {
 *       writeOutput("Connection: " & sub.connectionId & "<br>");
 *       if (structKeyExists(sub, "subscriberInfo")) {
 *           writeDump(sub.subscriberInfo);
 *       }
 *   }
 *
 * Returns: array of subscriber structs (empty array if channel not found)
 */
public class wsGetSubscribers extends functionBase {
	private static final long serialVersionUID = 1L;

	public wsGetSubscribers() {
		min = 1;
		max = 1;
		setNamedParams(new String[] { "channelname" });
	}

	public String[] getParamInfo() {
		return new String[] {
			"Channel name to get subscribers for"
		};
	}

	public java.util.Map<String, String> getInfo() {
		return makeInfo(
			"websocket",
			"Get a list of all subscribers for a WebSocket channel",
			ReturnType.ARRAY
		);
	}

	public cfData execute(cfSession _session, cfArgStructData argStruct) throws cfmRunTimeException {
		// Get channel name
		String channelName = getNamedStringParam(argStruct, "channelname", null);
		if (channelName == null || channelName.trim().isEmpty()) {
			throwException(_session, "channelName is required");
		}

		WebSocketChannelManager manager = WebSocketChannelManager.getInstance();

		// Get subscribers from manager
		List<WebSocketConnection> subscribers = manager.getSubscribers(channelName.trim());

		// Build array of subscriber info structs
		cfArrayData result = cfArrayData.createArray(1);

		try {
			for (WebSocketConnection conn : subscribers) {
				cfStructData subscriberStruct = new cfStructData();

				// Add connection ID
				subscriberStruct.setData("connectionId", new cfStringData(conn.getConnectionId()));

				// Add subscriber info if available
				cfStructData subInfo = conn.getSubscriberInfo();
				if (subInfo != null) {
					subscriberStruct.setData("subscriberInfo", subInfo);
				}

				// Add channel count
				subscriberStruct.setData("subscribedChannelCount",
					new cfNumberData(conn.getSubscribedChannelCount()));

				// Add connection status
				subscriberStruct.setData("connected",
					cfBooleanData.getcfBooleanData(conn.isConnected()));

				result.addElement(subscriberStruct);
			}

		} catch (cfmRunTimeException e) {
			throwException(_session, "Error building subscriber list: " + e.getMessage());
		}

		return result;
	}
}
