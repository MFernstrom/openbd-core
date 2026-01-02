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
package com.naryx.tagfusion.cfm.tag.ext;

import java.io.Serializable;

import com.naryx.tagfusion.cfm.engine.cfEngine;
import com.naryx.tagfusion.cfm.engine.cfSession;
import com.naryx.tagfusion.cfm.engine.cfStructData;
import com.naryx.tagfusion.cfm.engine.cfmBadFileException;
import com.naryx.tagfusion.cfm.engine.cfmRunTimeException;
import com.naryx.tagfusion.cfm.tag.cfTag;
import com.naryx.tagfusion.cfm.tag.cfTagReturnType;

/**
 * CFWEBSOCKET Tag
 *
 * Generates JavaScript code for a WebSocket client that connects to OpenBD's WebSocket server.
 *
 * Example:
 * <cfwebsocket
 *     name="chatClient"
 *     onMessage="handleMessage"
 *     onOpen="handleOpen"
 *     onClose="handleClose"
 *     onError="handleError"
 *     subscribeTo="chatChannel">
 */
public class cfWEBSOCKET extends cfTag implements Serializable {
	private static final long serialVersionUID = 1L;

	public java.util.Map<String, String> getInfo() {
		return createInfo(
			"output",
			"Generates JavaScript code for a WebSocket client that connects to OpenBD's WebSocket server. " +
			"Creates a JavaScript object with methods to connect, subscribe, publish, and manage WebSocket channels."
		);
	}

	public java.util.Map[] getAttInfo() {
		return new java.util.Map[] {
			createAttInfo("ATTRIBUTECOLLECTION", "A structure containing the tag attributes", "", false),
			createAttInfo("NAME", "JavaScript variable name for the WebSocket client object (required)", "", true),
			createAttInfo("ONMESSAGE", "JavaScript function name to call when a message is received", "", false),
			createAttInfo("ONOPEN", "JavaScript function name to call when connection opens", "", false),
			createAttInfo("ONCLOSE", "JavaScript function name to call when connection closes", "", false),
			createAttInfo("ONERROR", "JavaScript function name to call when an error occurs", "", false),
			createAttInfo("SUBSCRIBETO", "Channel name to auto-subscribe to after connection", "", false),
			createAttInfo("USECFAUTH", "Whether to include CF session authentication (not yet implemented)", "false", false),
			createAttInfo("PORT", "WebSocket server port (overrides config)", "", false)
		};
	}

	protected void defaultParameters(String _tag) throws cfmBadFileException {
		parseTagHeader(_tag);
		setFlushable(false);

		// Validate required attribute
		if (!containsAttribute("NAME")) {
			throw newBadFileException("Missing NAME attribute", "The NAME attribute is required");
		}
	}

	public cfTagReturnType render(cfSession _Session) throws cfmRunTimeException {
		cfStructData attributes = setAttributeCollection(_Session);

		// Get required attribute
		String name = getDynamic(attributes, _Session, "NAME").getString();

		// Get optional attributes
		String onMessage = containsAttribute(attributes, "ONMESSAGE") ?
			getDynamic(attributes, _Session, "ONMESSAGE").getString() : null;
		String onOpen = containsAttribute(attributes, "ONOPEN") ?
			getDynamic(attributes, _Session, "ONOPEN").getString() : null;
		String onClose = containsAttribute(attributes, "ONCLOSE") ?
			getDynamic(attributes, _Session, "ONCLOSE").getString() : null;
		String onError = containsAttribute(attributes, "ONERROR") ?
			getDynamic(attributes, _Session, "ONERROR").getString() : null;
		String subscribeTo = containsAttribute(attributes, "SUBSCRIBETO") ?
			getDynamic(attributes, _Session, "SUBSCRIBETO").getString() : null;

		// Get WebSocket configuration
		boolean wsEnabled = cfEngine.thisInstance.getSystemParameters().getBoolean("server.system.websocket.enabled", false);
		int wsPort = 8580; // Default port

		if (!wsEnabled) {
			throw newRunTimeException("WebSocket server is not enabled. Enable it in bluedragon.xml");
		}

		// Allow port override via attribute
		if (containsAttribute(attributes, "PORT")) {
			wsPort = getDynamic(attributes, _Session, "PORT").getInt();
		} else {
			wsPort = cfEngine.thisInstance.getSystemParameters().getInt("server.system.websocket.port", 8580);
		}

		// Build WebSocket URL
		String wsProtocol = "ws";
		String wsHost = _Session.REQ.getServerName();
		String wsUrl = wsProtocol + "://" + wsHost + ":" + wsPort + "/openbd/ws";

		// Generate JavaScript
		String javascript = generateJavaScriptClient(name, wsUrl, onMessage, onOpen, onClose, onError, subscribeTo);

		// Output the script tag
		_Session.write("<script type=\"text/javascript\">\n");
		_Session.write(javascript);
		_Session.write("\n</script>\n");

		return cfTagReturnType.NORMAL;
	}

	/**
	 * Generate the JavaScript client code
	 */
	private String generateJavaScriptClient(String name, String wsUrl,
	                                       String onMessage, String onOpen, String onClose,
	                                       String onError, String subscribeTo) {
		StringBuilder js = new StringBuilder();

		js.append("// OpenBD WebSocket Client - Generated by <cfwebsocket>\n");
		js.append("window.").append(name).append(" = (function() {\n");
		js.append("    var wsClient = {\n");
		js.append("        ws: null,\n");
		js.append("        url: '").append(escapeJavaScript(wsUrl)).append("',\n");
		js.append("        subscribedChannels: {},\n");
		js.append("        \n");

		// openConnection method
		js.append("        openConnection: function(options) {\n");
		js.append("            if (this.ws && this.ws.readyState === WebSocket.OPEN) {\n");
		js.append("                console.warn('WebSocket already connected');\n");
		js.append("                return;\n");
		js.append("            }\n");
		js.append("            \n");
		js.append("            var self = this;\n");
		js.append("            this.ws = new WebSocket(this.url);\n");
		js.append("            \n");
		js.append("            this.ws.onopen = function(evt) {\n");
		js.append("                if (typeof self.onOpen === 'function') {\n");
		js.append("                    self.onOpen(evt);\n");
		js.append("                }\n");

		// Auto-subscribe if specified
		if (subscribeTo != null && !subscribeTo.trim().isEmpty()) {
			js.append("                // Auto-subscribe to channel\n");
			js.append("                self.subscribe('").append(escapeJavaScript(subscribeTo)).append("');\n");
		}

		js.append("            };\n");
		js.append("            \n");
		js.append("            this.ws.onmessage = function(evt) {\n");
		js.append("                self._handleMessage(evt);\n");
		js.append("            };\n");
		js.append("            \n");
		js.append("            this.ws.onerror = function(evt) {\n");
		js.append("                if (typeof self.onError === 'function') {\n");
		js.append("                    self.onError(evt);\n");
		js.append("                }\n");
		js.append("            };\n");
		js.append("            \n");
		js.append("            this.ws.onclose = function(evt) {\n");
		js.append("                if (typeof self.onClose === 'function') {\n");
		js.append("                    self.onClose(evt);\n");
		js.append("                }\n");
		js.append("                self.subscribedChannels = {};\n");
		js.append("            };\n");
		js.append("        },\n");
		js.append("        \n");

		// closeConnection method
		js.append("        closeConnection: function() {\n");
		js.append("            if (this.ws) {\n");
		js.append("                this.ws.close();\n");
		js.append("                this.ws = null;\n");
		js.append("            }\n");
		js.append("        },\n");
		js.append("        \n");

		// subscribe method
		js.append("        subscribe: function(channelName, subscriberInfo, callback) {\n");
		js.append("            if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {\n");
		js.append("                throw new Error('WebSocket not connected');\n");
		js.append("            }\n");
		js.append("            \n");
		js.append("            var msg = {\n");
		js.append("                type: 'subscribe',\n");
		js.append("                channelName: channelName,\n");
		js.append("                subscriberInfo: subscriberInfo || {}\n");
		js.append("            };\n");
		js.append("            \n");
		js.append("            this.subscribedChannels[channelName] = {\n");
		js.append("                subscriberInfo: subscriberInfo,\n");
		js.append("                callback: callback\n");
		js.append("            };\n");
		js.append("            \n");
		js.append("            this._send(msg);\n");
		js.append("        },\n");
		js.append("        \n");

		// unsubscribe method
		js.append("        unsubscribe: function(channelName, callback) {\n");
		js.append("            if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {\n");
		js.append("                return;\n");
		js.append("            }\n");
		js.append("            \n");
		js.append("            var msg = {\n");
		js.append("                type: 'unsubscribe',\n");
		js.append("                channelName: channelName\n");
		js.append("            };\n");
		js.append("            \n");
		js.append("            delete this.subscribedChannels[channelName];\n");
		js.append("            this._send(msg);\n");
		js.append("            \n");
		js.append("            if (callback) callback();\n");
		js.append("        },\n");
		js.append("        \n");

		// publish method
		js.append("        publish: function(channelName, message, callback) {\n");
		js.append("            if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {\n");
		js.append("                throw new Error('WebSocket not connected');\n");
		js.append("            }\n");
		js.append("            \n");
		js.append("            var msg = {\n");
		js.append("                type: 'publish',\n");
		js.append("                channelName: channelName,\n");
		js.append("                message: message\n");
		js.append("            };\n");
		js.append("            \n");
		js.append("            this._send(msg);\n");
		js.append("            \n");
		js.append("            if (callback) callback();\n");
		js.append("        },\n");
		js.append("        \n");

		// isConnectionOpen method
		js.append("        isConnectionOpen: function() {\n");
		js.append("            return this.ws && this.ws.readyState === WebSocket.OPEN;\n");
		js.append("        },\n");
		js.append("        \n");

		// getSubscriptions method
		js.append("        getSubscriptions: function() {\n");
		js.append("            return Object.keys(this.subscribedChannels);\n");
		js.append("        },\n");
		js.append("        \n");

		// _handleMessage internal method
		js.append("        _handleMessage: function(evt) {\n");
		js.append("            try {\n");
		js.append("                var msg = JSON.parse(evt.data);\n");
		js.append("                \n");
		js.append("                switch(msg.type) {\n");
		js.append("                    case 'subscribed':\n");
		js.append("                        var ch = this.subscribedChannels[msg.channelName];\n");
		js.append("                        if (ch && ch.callback) {\n");
		js.append("                            ch.callback(null, msg);\n");
		js.append("                        }\n");
		js.append("                        break;\n");
		js.append("                        \n");
		js.append("                    case 'message':\n");
		js.append("                        if (typeof this.onMessage === 'function') {\n");
		js.append("                            this.onMessage(msg.channelName, msg.message);\n");
		js.append("                        }\n");
		js.append("                        break;\n");
		js.append("                        \n");
		js.append("                    case 'error':\n");
		js.append("                        if (typeof this.onError === 'function') {\n");
		js.append("                            this.onError(new Error(msg.message));\n");
		js.append("                        }\n");
		js.append("                        break;\n");
		js.append("                }\n");
		js.append("            } catch(e) {\n");
		js.append("                console.error('WebSocket message parse error:', e);\n");
		js.append("            }\n");
		js.append("        },\n");
		js.append("        \n");

		// _send internal method
		js.append("        _send: function(msg) {\n");
		js.append("            if (this.ws && this.ws.readyState === WebSocket.OPEN) {\n");
		js.append("                this.ws.send(JSON.stringify(msg));\n");
		js.append("            }\n");
		js.append("        },\n");
		js.append("        \n");

		// Event handlers
		js.append("        // Event handlers (can be overridden or set via tag attributes)\n");
		js.append("        onOpen: ");
		if (onOpen != null && !onOpen.trim().isEmpty()) {
			js.append(onOpen);
		} else {
			js.append("null");
		}
		js.append(",\n");

		js.append("        onClose: ");
		if (onClose != null && !onClose.trim().isEmpty()) {
			js.append(onClose);
		} else {
			js.append("null");
		}
		js.append(",\n");

		js.append("        onError: ");
		if (onError != null && !onError.trim().isEmpty()) {
			js.append(onError);
		} else {
			js.append("null");
		}
		js.append(",\n");

		js.append("        onMessage: ");
		if (onMessage != null && !onMessage.trim().isEmpty()) {
			js.append(onMessage);
		} else {
			js.append("null");
		}
		js.append("\n");

		js.append("    };\n");
		js.append("    \n");
		js.append("    return wsClient;\n");
		js.append("})();\n");

		return js.toString();
	}

	/**
	 * Escape special characters for JavaScript strings
	 */
	private String escapeJavaScript(String str) {
		if (str == null) {
			return "";
		}
		return str.replace("\\", "\\\\")
			.replace("'", "\\'")
			.replace("\"", "\\\"")
			.replace("\n", "\\n")
			.replace("\r", "\\r")
			.replace("\t", "\\t");
	}
}
