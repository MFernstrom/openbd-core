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

import com.naryx.tagfusion.cfm.engine.cfArrayData;
import com.naryx.tagfusion.cfm.engine.cfData;
import com.naryx.tagfusion.cfm.engine.cfSession;
import com.naryx.tagfusion.cfm.engine.cfmRunTimeException;
import com.naryx.tagfusion.cfm.websocket.WebSocketChannelManager;
import com.naryx.tagfusion.expression.function.functionBase;

/**
 * wsGetAllChannels()
 *
 * Get a list of all registered WebSocket channels.
 *
 * Returns an array of channel names (strings) for all channels that have
 * been registered with wsRegisterChannel().
 *
 * Example:
 *   channels = wsGetAllChannels();
 *   writeOutput("Registered channels: " & arrayLen(channels) & "<br>");
 *
 *   for (channelName in channels) {
 *       subscribers = wsGetSubscribers(channelName);
 *       writeOutput(channelName & ": " & arrayLen(subscribers) & " subscribers<br>");
 *   }
 *
 * Returns: array of channel names (empty array if no channels registered)
 */
public class wsGetAllChannels extends functionBase {
	private static final long serialVersionUID = 1L;

	public wsGetAllChannels() {
		min = 0;
		max = 0;
	}

	public String[] getParamInfo() {
		return new String[] {};
	}

	public java.util.Map<String, String> getInfo() {
		return makeInfo(
			"websocket",
			"Get a list of all registered WebSocket channels",
			ReturnType.ARRAY
		);
	}

	public cfData execute(cfSession _session, List<cfData> parameters) throws cfmRunTimeException {
		WebSocketChannelManager manager = WebSocketChannelManager.getInstance();
		return manager.getChannels();
	}
}
