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
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.naryx.tagfusion.cfm.engine.cfArgStructData;
import com.naryx.tagfusion.cfm.engine.cfArrayData;
import com.naryx.tagfusion.cfm.engine.cfBooleanData;
import com.naryx.tagfusion.cfm.engine.cfComponentData;
import com.naryx.tagfusion.cfm.engine.cfData;
import com.naryx.tagfusion.cfm.engine.cfEngine;
import com.naryx.tagfusion.cfm.engine.cfSession;
import com.naryx.tagfusion.cfm.engine.cfStringData;
import com.naryx.tagfusion.cfm.engine.cfStructData;
import com.naryx.tagfusion.cfm.engine.cfcMethodData;
import com.naryx.tagfusion.cfm.engine.cfmRunTimeException;
import com.naryx.tagfusion.expression.function.string.serializejson;
import com.naryx.tagfusion.util.dummyServletRequest;
import com.naryx.tagfusion.util.dummyServletResponse;

/**
 * Central manager for all WebSocket channels.
 *
 * This singleton class maintains the registry of channels, handles
 * subscription management, and routes messages to appropriate channels.
 *
 * Phase 2: Basic channel management and message routing
 * Phase 3: Will add Channel Listener CFC integration
 *
 * Thread-safe: All operations are safe for concurrent access.
 */
public class WebSocketChannelManager {

	private static WebSocketChannelManager instance;

	// Channel registry: channelName -> WebSocketChannel
	private final Map<String, WebSocketChannel> channels;

	/**
	 * Private constructor for singleton pattern
	 */
	private WebSocketChannelManager() {
		this.channels = new ConcurrentHashMap<>();
		cfEngine.log("[WebSocket] ChannelManager initialized");
	}

	/**
	 * Get the singleton instance
	 *
	 * @return the WebSocketChannelManager instance
	 */
	public static synchronized WebSocketChannelManager getInstance() {
		if (instance == null) {
			instance = new WebSocketChannelManager();
		}
		return instance;
	}

	/**
	 * Register a new channel
	 *
	 * Phase 2: Simple channel creation
	 * Phase 3: Will accept Channel Listener CFC path
	 *
	 * @param channelName the name of the channel to register
	 * @return true if created, false if already exists
	 */
	public boolean registerChannel(String channelName) {
		if (channelName == null || channelName.trim().isEmpty()) {
			cfEngine.log("[WebSocket] Cannot register channel: name is null or empty");
			return false;
		}

		channelName = channelName.trim();

		WebSocketChannel existingChannel = channels.get(channelName);
		if (existingChannel != null) {
			cfEngine.log("[WebSocket] Channel '" + channelName + "' already registered");
			return false;
		}

		WebSocketChannel newChannel = new WebSocketChannel(channelName);
		channels.put(channelName, newChannel);

		cfEngine.log("[WebSocket] Channel '" + channelName + "' registered successfully " +
		             "(total channels: " + channels.size() + ")");

		return true;
	}

	/**
	 * Unregister a channel
	 *
	 * This will remove the channel and disconnect all subscribers.
	 *
	 * @param channelName the channel name to unregister
	 * @return true if removed, false if not found
	 */
	public boolean unregisterChannel(String channelName) {
		if (channelName == null) {
			return false;
		}

		WebSocketChannel channel = channels.remove(channelName);

		if (channel != null) {
			int subscriberCount = channel.getSubscriberCount();
			cfEngine.log("[WebSocket] Channel '" + channelName + "' unregistered " +
			             "(had " + subscriberCount + " subscribers, " +
			             channels.size() + " channels remaining)");
			return true;
		}

		cfEngine.log("[WebSocket] Cannot unregister channel '" + channelName + "': not found");
		return false;
	}

	/**
	 * Subscribe a connection to a channel
	 *
	 * Phase 2: Simple subscription
	 * Phase 3: Invokes CFC allowSubscribe() hook if listener attached
	 *
	 * @param channelName the channel to subscribe to
	 * @param conn the connection to subscribe
	 * @param subscriberInfo custom metadata from client (can be null)
	 * @return true if subscribed, false if channel doesn't exist or already subscribed
	 */
	public boolean subscribe(String channelName, WebSocketConnection conn, cfStructData subscriberInfo) {
		if (channelName == null || conn == null) {
			cfEngine.log("[WebSocket] Cannot subscribe: channel or connection is null");
			return false;
		}

		WebSocketChannel channel = channels.get(channelName);
		if (channel == null) {
			cfEngine.log("[WebSocket] Cannot subscribe to '" + channelName + "': channel not registered");
			return false;
		}

		// Store subscriber info on connection
		if (subscriberInfo != null) {
			conn.setSubscriberInfo(subscriberInfo);
		}

		// Phase 3: Invoke allowSubscribe() hook if listener CFC is attached
		if (channel.hasListener()) {
			cfEngine.log("[WebSocket] Channel '" + channelName + "': Invoking allowSubscribe() hook");

			try {
				cfComponentData listenerCFC = channel.getListenerCFC();

				// Create a temporary session for CFC invocation
				// WebSocket connections don't have an HTTP session, so we create a minimal one
				cfSession session = new cfSession(
					new dummyServletRequest("/"),
					new dummyServletResponse(),
					cfEngine.thisServletContext
				);

				// Prepare named arguments for allowSubscribe(subscriberInfo)
				cfArgStructData args = new cfArgStructData();
				args.setData("subscriberInfo", subscriberInfo != null ? subscriberInfo : new cfStructData());

				// Create method invocation data
				cfcMethodData methodData = new cfcMethodData(session, "allowSubscribe", args);

				// Invoke the allowSubscribe method
				cfData result = listenerCFC.invokeComponentFunction(session, methodData);

				// Check the result - should be boolean
				boolean allowed = true;
				if (result instanceof cfBooleanData) {
					allowed = ((cfBooleanData) result).getBoolean();
				} else if (result != null) {
					// Convert to boolean
					String resultStr = result.getString().toLowerCase();
					allowed = resultStr.equals("true") || resultStr.equals("yes");
				}

				if (!allowed) {
					cfEngine.log("[WebSocket] Channel '" + channelName + "': Subscription denied by allowSubscribe() hook");
					return false;
				}

				cfEngine.log("[WebSocket] Channel '" + channelName + "': Subscription allowed by allowSubscribe() hook");

			} catch (Exception e) {
				cfEngine.log("[WebSocket] ERROR invoking allowSubscribe() hook: " + e.getMessage());
				e.printStackTrace();
				// On error, deny subscription for safety
				return false;
			}
		}

		// Add to channel's subscriber list
		boolean added = channel.addSubscriber(conn);

		if (added) {
			// Track on connection side as well
			conn.subscribeToChannel(channelName);
		}

		return added;
	}

	/**
	 * Unsubscribe a connection from a channel
	 *
	 * @param channelName the channel to unsubscribe from
	 * @param conn the connection to unsubscribe
	 * @return true if unsubscribed, false if not subscribed or channel doesn't exist
	 */
	public boolean unsubscribe(String channelName, WebSocketConnection conn) {
		if (channelName == null || conn == null) {
			return false;
		}

		WebSocketChannel channel = channels.get(channelName);
		if (channel == null) {
			cfEngine.log("[WebSocket] Cannot unsubscribe from '" + channelName + "': channel not found");
			return false;
		}

		boolean removed = channel.removeSubscriber(conn);

		if (removed) {
			// Remove from connection's tracking as well
			conn.unsubscribeFromChannel(channelName);
		}

		return removed;
	}

	/**
	 * Unsubscribe a connection from all channels
	 *
	 * Called when connection closes.
	 *
	 * @param conn the connection to unsubscribe
	 */
	public void unsubscribeAll(WebSocketConnection conn) {
		if (conn == null) {
			return;
		}

		int unsubscribedCount = 0;

		// Iterate through connection's subscribed channels
		for (String channelName : conn.getSubscribedChannels()) {
			if (unsubscribe(channelName, conn)) {
				unsubscribedCount++;
			}
		}

		if (unsubscribedCount > 0) {
			cfEngine.log("[WebSocket] Connection " + conn.getConnectionId() +
			             " unsubscribed from " + unsubscribedCount + " channel(s)");
		}
	}

	/**
	 * Publish a message to a channel
	 *
	 * Phase 2: Simple broadcast to all subscribers
	 * Phase 3: Invokes CFC hooks (allowPublish, beforePublish, canSendMessage)
	 *
	 * @param channelName the channel to publish to
	 * @param publisher the connection publishing the message
	 * @param messageData the raw message data (before JSON formatting)
	 * @return true if published, false if channel doesn't exist or publish denied
	 */
	public boolean publish(String channelName, WebSocketConnection publisher, Object messageData) {
		if (channelName == null || publisher == null || messageData == null) {
			cfEngine.log("[WebSocket] Cannot publish: channel, publisher, or message is null");
			return false;
		}

		WebSocketChannel channel = channels.get(channelName);
		if (channel == null) {
			cfEngine.log("[WebSocket] Cannot publish to '" + channelName + "': channel not registered");
			return false;
		}

		// Phase 3: Invoke CFC hooks if listener is attached
		Object finalMessageData = messageData;

		if (channel.hasListener()) {
			try {
				cfComponentData listenerCFC = channel.getListenerCFC();

				// Create temporary session for CFC invocation
				cfSession session = new cfSession(
					new dummyServletRequest("/"),
					new dummyServletResponse(),
					cfEngine.thisServletContext
				);

				// Build publisherInfo struct
				cfStructData publisherInfo = new cfStructData();
				publisherInfo.setData("connectionId", publisher.getConnectionId());
				publisherInfo.setData("subscriberInfo",
					publisher.getSubscriberInfo() != null ? publisher.getSubscriberInfo() : new cfStructData());

				// Hook 1: allowPublish(publisherInfo) - Authorization check
				cfEngine.log("[WebSocket] Channel '" + channelName + "': Invoking allowPublish() hook");

				cfArgStructData allowArgs = new cfArgStructData();
				allowArgs.setData("publisherInfo", publisherInfo);

				cfcMethodData allowMethod = new cfcMethodData(session, "allowPublish", allowArgs);
				cfData allowResult = listenerCFC.invokeComponentFunction(session, allowMethod);

				boolean allowed = true;
				if (allowResult instanceof cfBooleanData) {
					allowed = ((cfBooleanData) allowResult).getBoolean();
				} else if (allowResult != null) {
					String resultStr = allowResult.getString().toLowerCase();
					allowed = resultStr.equals("true") || resultStr.equals("yes");
				}

				if (!allowed) {
					cfEngine.log("[WebSocket] Channel '" + channelName + "': Publish denied by allowPublish() hook");
					return false;
				}

				cfEngine.log("[WebSocket] Channel '" + channelName + "': Publish allowed by allowPublish() hook");

				// Hook 2: beforePublish(publisherInfo, message) - Transform message
				cfEngine.log("[WebSocket] Channel '" + channelName + "': Invoking beforePublish() hook");

				cfArgStructData beforeArgs = new cfArgStructData();
				beforeArgs.setData("publisherInfo", publisherInfo);
				// Cast messageData to cfData (it should be cfStructData from the parsed JSON)
				if (messageData instanceof cfData) {
					beforeArgs.setData("message", (cfData) messageData);
				} else {
					// Fallback: wrap in cfStringData
					beforeArgs.setData("message", new cfStringData(messageData.toString()));
				}

				cfcMethodData beforeMethod = new cfcMethodData(session, "beforePublish", beforeArgs);
				cfData transformedMessage = listenerCFC.invokeComponentFunction(session, beforeMethod);

				if (transformedMessage != null) {
					finalMessageData = transformedMessage;
					cfEngine.log("[WebSocket] Channel '" + channelName + "': Message transformed by beforePublish() hook");
				}

			} catch (Exception e) {
				cfEngine.log("[WebSocket] ERROR invoking publish hooks: " + e.getMessage());
				e.printStackTrace();
				// On error, deny publish for safety
				return false;
			}
		}

		// Build final broadcast message with transformed data
		String broadcastMessage = "{\"type\":\"message\",\"channelName\":\"" +
		                         escapeJSON(channelName) + "\",\"message\":" +
		                         serializeJSON(finalMessageData) + "}";

		channel.publish(broadcastMessage);
		return true;
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
	private String serializeJSON(Object obj) {
		try {
			if (obj == null) {
				return "null";
			}

			// If it's already a cfData type, serialize it properly
			if (obj instanceof cfData) {
				StringBuilder buffer = new StringBuilder();
				serializejson serializer = new serializejson();
				serializer.encodeJSON(buffer, (cfData)obj, false,
				                     serializejson.CaseType.MAINTAIN,
				                     serializejson.DateType.LONG);
				return buffer.toString();
			}

			// Fallback for non-cfData types
			return "\"" + escapeJSON(obj.toString()) + "\"";
		} catch (Exception e) {
			cfEngine.log("[WebSocket] JSON serialization error: " + e.getMessage());
			return "\"\"";
		}
	}

	/**
	 * Get a list of all registered channel names
	 *
	 * @return cfArrayData of channel names
	 */
	public cfArrayData getChannels() {
		cfArrayData result = cfArrayData.createArray(1);

		try {
			for (String channelName : channels.keySet()) {
				result.addElement(new cfStringData(channelName));
			}
		} catch (cfmRunTimeException e) {
			cfEngine.log("[WebSocket] Error building channel list: " + e.getMessage());
		}

		cfEngine.log("[WebSocket] getChannels() returning " + result.size() + " channel(s)");

		return result;
	}

	/**
	 * Get the number of subscribers for a channel
	 *
	 * @param channelName the channel name
	 * @return subscriber count, or -1 if channel doesn't exist
	 */
	public int getSubscriberCount(String channelName) {
		WebSocketChannel channel = channels.get(channelName);
		return (channel != null) ? channel.getSubscriberCount() : -1;
	}

	/**
	 * Get all subscribers for a channel
	 *
	 * @param channelName the channel name
	 * @return list of connections, or empty list if channel doesn't exist
	 */
	public List<WebSocketConnection> getSubscribers(String channelName) {
		WebSocketChannel channel = channels.get(channelName);
		return (channel != null) ? channel.getSubscribers() : new ArrayList<>();
	}

	/**
	 * Check if a channel is registered
	 *
	 * @param channelName the channel name
	 * @return true if registered, false otherwise
	 */
	public boolean isChannelRegistered(String channelName) {
		return channels.containsKey(channelName);
	}

	/**
	 * Get the total number of registered channels
	 *
	 * @return channel count
	 */
	public int getChannelCount() {
		return channels.size();
	}

	/**
	 * Get statistics about the channel manager
	 *
	 * Useful for debugging and monitoring.
	 *
	 * @return struct with statistics
	 */
	public cfStructData getStatistics() {
		cfStructData stats = new cfStructData();

		int totalSubscribers = 0;
		for (WebSocketChannel channel : channels.values()) {
			totalSubscribers += channel.getSubscriberCount();
		}

		stats.setData("channelCount", channels.size());
		stats.setData("totalSubscribers", totalSubscribers);

		return stats;
	}
}
