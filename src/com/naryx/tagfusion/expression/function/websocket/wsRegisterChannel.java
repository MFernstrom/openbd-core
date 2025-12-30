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
import com.naryx.tagfusion.cfm.engine.cfmRunTimeException;
import com.naryx.tagfusion.cfm.websocket.WebSocketChannelManager;
import com.naryx.tagfusion.expression.function.functionBase;

/**
 * wsRegisterChannel(channelName)
 *
 * Register a WebSocket channel for client subscriptions.
 *
 * Phase 2: Basic channel registration
 * Phase 3: Will accept optional listener CFC path
 *
 * Example:
 *   wsRegisterChannel("chatChannel")
 *   wsRegisterChannel("notifyChannel")
 *
 * Returns: true if channel registered, false if already exists
 */
public class wsRegisterChannel extends functionBase {
	private static final long serialVersionUID = 1L;

	public wsRegisterChannel() {
		min = 1;
		max = 2;
		setNamedParams(new String[] { "channelname", "listener" });
	}

	public String[] getParamInfo() {
		return new String[] {
			"Channel name to register",
			"Optional: Path to Channel Listener CFC (Phase 3)"
		};
	}

	public java.util.Map<String, String> getInfo() {
		return makeInfo(
			"websocket",
			"Register a WebSocket channel for client subscriptions",
			ReturnType.BOOLEAN
		);
	}

	public cfData execute(cfSession _session, cfArgStructData argStruct) throws cfmRunTimeException {
		// Get channel name
		String channelName = getNamedStringParam(argStruct, "channelname", null);
		if (channelName == null || channelName.trim().isEmpty()) {
			throwException(_session, "channelName is required");
		}

		// Get optional listener (Phase 3 - not used yet)
		String listenerPath = getNamedStringParam(argStruct, "listener", null);

		// Phase 2: listener parameter is ignored
		// Phase 3: Will load and register the CFC
		if (listenerPath != null && !listenerPath.isEmpty()) {
			// Log that this will be supported in Phase 3
			com.naryx.tagfusion.cfm.engine.cfEngine.log(
				"[WebSocket] wsRegisterChannel: listener parameter not yet supported (Phase 3 feature)"
			);
		}

		// Register the channel
		WebSocketChannelManager manager = WebSocketChannelManager.getInstance();
		boolean success = manager.registerChannel(channelName.trim());

		return cfBooleanData.getcfBooleanData(success);
	}
}
