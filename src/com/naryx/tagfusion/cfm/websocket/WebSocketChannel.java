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
package com.naryx.tagfusion.cfm.websocket;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import com.naryx.tagfusion.cfm.engine.cfArgStructData;
import com.naryx.tagfusion.cfm.engine.cfBooleanData;
import com.naryx.tagfusion.cfm.engine.cfComponentData;
import com.naryx.tagfusion.cfm.engine.cfData;
import com.naryx.tagfusion.cfm.engine.cfEngine;
import com.naryx.tagfusion.cfm.engine.cfSession;
import com.naryx.tagfusion.cfm.engine.cfStructData;
import com.naryx.tagfusion.cfm.engine.cfcMethodData;
import com.naryx.tagfusion.expression.function.string.serializejson;
import com.naryx.tagfusion.util.dummyServletRequest;
import com.naryx.tagfusion.util.dummyServletResponse;

/**
 * Represents a single WebSocket channel that manages its subscribers.
 *
 * Phase 2: Basic subscriber management and message broadcasting
 * Phase 3: Channel Listener CFC integration (in progress)
 *
 * Thread-safe implementation using ConcurrentHashMap.
 */
public class WebSocketChannel {

	private final String channelName;
	private final Set<WebSocketConnection> subscribers;
	private final cfComponentData listenerCFC;

	/**
	 * Create a new channel without a listener CFC
	 *
	 * @param channelName the name of this channel
	 */
	public WebSocketChannel(String channelName) {
		this(channelName, null);
	}

	/**
	 * Create a new channel with an optional listener CFC
	 *
	 * @param channelName the name of this channel
	 * @param listenerCFC the Channel Listener CFC (can be null)
	 */
	public WebSocketChannel(String channelName, cfComponentData listenerCFC) {
		this.channelName = channelName;
		this.listenerCFC = listenerCFC;
		// ConcurrentHashMap.newKeySet() provides thread-safe Set
		this.subscribers = ConcurrentHashMap.newKeySet();

		if (listenerCFC != null) {
			cfEngine.log("[WebSocket] Channel created: " + channelName +
			             " (with listener CFC)");
		} else {
			cfEngine.log("[WebSocket] Channel created: " + channelName +
			             " (no listener)");
		}
	}

	/**
	 * Add a subscriber to this channel
	 *
	 * @param conn the connection to add
	 * @return true if added, false if already subscribed
	 */
	public boolean addSubscriber(WebSocketConnection conn) {
		boolean added = subscribers.add(conn);

		if (added) {
			cfEngine.log("[WebSocket] Channel '" + channelName + "': Added subscriber " +
					conn.getConnectionId() + " (total: " + subscribers.size() + ")");
		} else {
			cfEngine.log("[WebSocket] Channel '" + channelName + "': Subscriber " +
					conn.getConnectionId() + " already subscribed");
		}

		return added;
	}

	/**
	 * Remove a subscriber from this channel
	 *
	 * @param conn the connection to remove
	 * @return true if removed, false if not subscribed
	 */
	public boolean removeSubscriber(WebSocketConnection conn) {
		boolean removed = subscribers.remove(conn);

		if (removed) {
			cfEngine.log("[WebSocket] Channel '" + channelName + "': Removed subscriber " +
					conn.getConnectionId() + " (total: " + subscribers.size() + ")");
		} else {
			cfEngine.log("[WebSocket] Channel '" + channelName + "': Subscriber " +
					conn.getConnectionId() + " was not subscribed");
		}

		return removed;
	}

	/**
	 * Publish a message to all subscribers of this channel
	 *
	 * Phase 2: Simple broadcast to all subscribers
	 * Phase 3: Per-subscriber hooks (canSendMessage, beforeSendMessage)
	 *
	 * @param message the message to broadcast (JSON string, already formatted)
	 * @param messageData the raw message data (for per-subscriber transformation)
	 */
	public void publish(String message, cfData messageData) {
		int subscriberCount = subscribers.size();

		cfEngine.log("[WebSocket] Channel '" + channelName + "': Publishing message to " +
				subscriberCount + " subscriber(s)");

		if (subscriberCount == 0) {
			cfEngine.log("[WebSocket] Channel '" + channelName + "': No subscribers, message not sent");
			return;
		}

		// Broadcast to all subscribers
		int successCount = 0;
		int errorCount = 0;
		int filteredCount = 0;

		// Phase 3: Invoke per-subscriber hooks if listener is attached
		boolean hasListener = (listenerCFC != null);

		for (WebSocketConnection conn : subscribers) {
			try {
				String finalMessage = message;

				if (hasListener) {
					// Create temporary session for CFC invocation
					cfSession session = new cfSession(
						new dummyServletRequest("/"),
						new dummyServletResponse(),
						cfEngine.thisServletContext
					);

					// Get subscriber info
					cfStructData subscriberInfo = conn.getSubscriberInfo();
					if (subscriberInfo == null) {
						subscriberInfo = new cfStructData();
					}

					// Hook 1: canSendMessage(subscriberInfo, message) - Filter check
					cfEngine.log("[WebSocket] Channel '" + channelName + "': Invoking canSendMessage() for " +
							conn.getConnectionId());

					cfArgStructData canSendArgs = new cfArgStructData();
					canSendArgs.setData("subscriberInfo", subscriberInfo);
					canSendArgs.setData("message", messageData);

					cfcMethodData canSendMethod = new cfcMethodData(session, "canSendMessage", canSendArgs);
					cfData canSendResult = listenerCFC.invokeComponentFunction(session, canSendMethod);

					boolean allowed = true;
					if (canSendResult instanceof cfBooleanData) {
						allowed = ((cfBooleanData) canSendResult).getBoolean();
					} else if (canSendResult != null) {
						String resultStr = canSendResult.getString().toLowerCase();
						allowed = resultStr.equals("true") || resultStr.equals("yes");
					}

					if (!allowed) {
						cfEngine.log("[WebSocket] Channel '" + channelName + "': Message filtered for " +
								conn.getConnectionId() + " by canSendMessage() hook");
						filteredCount++;
						continue; // Skip this subscriber
					}

					// Hook 2: beforeSendMessage(subscriberInfo, message) - Per-subscriber transformation
					cfEngine.log("[WebSocket] Channel '" + channelName + "': Invoking beforeSendMessage() for " +
							conn.getConnectionId());

					cfArgStructData beforeSendArgs = new cfArgStructData();
					beforeSendArgs.setData("subscriberInfo", subscriberInfo);
					beforeSendArgs.setData("message", messageData);

					cfcMethodData beforeSendMethod = new cfcMethodData(session, "beforeSendMessage", beforeSendArgs);
					cfData customizedMessage = listenerCFC.invokeComponentFunction(session, beforeSendMethod);

					if (customizedMessage != null) {
						// Build customized JSON message for this subscriber
						finalMessage = "{\"type\":\"message\",\"channelName\":\"" +
								escapeJSON(channelName) + "\",\"message\":" +
								serializeJSON(customizedMessage) + "}";

						cfEngine.log("[WebSocket] Channel '" + channelName + "': Message customized for " +
								conn.getConnectionId());
					}
				}

				// Send the message (either original or customized)
				conn.sendMessage(finalMessage);
				successCount++;

			} catch (Exception e) {
				errorCount++;
				cfEngine.log("[WebSocket] Channel '" + channelName + "': Failed to send to " +
						conn.getConnectionId() + ": " + e.getMessage());
				e.printStackTrace();
			}
		}

		cfEngine.log("[WebSocket] Channel '" + channelName + "': Broadcast complete - " +
				successCount + " sent, " + filteredCount + " filtered, " + errorCount + " errors");
	}

	/**
	 * Escape special characters for JSON strings
	 */
	private String escapeJSON(String str) {
		if (str == null) {
			return "";
		}
		return str.replace("\\", "\\\\")
				.replace("\"", "\\\"")
				.replace("\n", "\\n")
				.replace("\r", "\\r")
				.replace("\t", "\\t");
	}

	/**
	 * Serialize an object to JSON string
	 */
	private String serializeJSON(cfData obj) {
		try {
			if (obj == null) {
				return "null";
			}

			StringBuilder buffer = new StringBuilder();
			serializejson serializer = new serializejson();
			serializer.encodeJSON(buffer, obj, false,
					serializejson.CaseType.MAINTAIN,
					serializejson.DateType.LONG);
			return buffer.toString();
		} catch (Exception e) {
			cfEngine.log("[WebSocket] JSON serialization error: " + e.getMessage());
			return "\"\"";
		}
	}

	/**
	 * Get the number of subscribers to this channel
	 *
	 * @return subscriber count
	 */
	public int getSubscriberCount() {
		return subscribers.size();
	}

	/**
	 * Get a list of all subscribers (defensive copy)
	 *
	 * @return immutable list of subscribers
	 */
	public List<WebSocketConnection> getSubscribers() {
		return Collections.unmodifiableList(new ArrayList<>(subscribers));
	}

	/**
	 * Get the channel name
	 *
	 * @return channel name
	 */
	public String getChannelName() {
		return channelName;
	}

	/**
	 * Check if a connection is subscribed to this channel
	 *
	 * @param conn the connection to check
	 * @return true if subscribed
	 */
	public boolean isSubscribed(WebSocketConnection conn) {
		return subscribers.contains(conn);
	}

	/**
	 * Get the Channel Listener CFC
	 *
	 * @return the listener CFC, or null if no listener attached
	 */
	public cfComponentData getListenerCFC() {
		return listenerCFC;
	}

	/**
	 * Check if this channel has a listener CFC
	 *
	 * @return true if a listener is attached, false otherwise
	 */
	public boolean hasListener() {
		return listenerCFC != null;
	}
}
