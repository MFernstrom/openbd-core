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

import com.naryx.tagfusion.cfm.engine.cfEngine;
import com.naryx.tagfusion.cfm.engine.cfComponentData;

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
	 * Phase 3: Will add CFC listener hooks (beforePublish, canSendMessage, etc.)
	 *
	 * @param message the message to broadcast (JSON string)
	 */
	public void publish(String message) {
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

		for (WebSocketConnection conn : subscribers) {
			try {
				conn.sendMessage(message);
				successCount++;
			} catch (Exception e) {
				errorCount++;
				cfEngine.log("[WebSocket] Channel '" + channelName + "': Failed to send to " +
						conn.getConnectionId() + ": " + e.getMessage());
			}
		}

		cfEngine.log("[WebSocket] Channel '" + channelName + "': Broadcast complete - " +
				successCount + " success, " + errorCount + " errors");
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
