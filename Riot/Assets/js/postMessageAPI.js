/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

window.riotIOS = {};

// Generic JS -> ObjC bridge
window.riotIOS.sendObjectMessageToObjC = function(parameters) {
    var iframe = document.createElement('iframe');
    iframe.setAttribute('src', 'js:' + JSON.stringify(parameters));

    document.documentElement.appendChild(iframe);
    iframe.parentNode.removeChild(iframe);
    iframe = null;
};

window.riotIOS.events = {};

// Listen to messages posted by the widget
window.riotIOS.onMessage = function(event) {

    // Use an internal "_id" field for matching onMessage events and requests
    // _id was originally used by the Modular API. Keep it
    if (!event.data._id) {
        // The Matrix Widget API v2 spec says:
        // "The requestId field should be unique and included in all requests"
        event.data._id = event.data.requestId;
    }

    // Make sure to have one id
    if (!event.data._id) {
        event.data._id = Date.now() + "-" + Math.random().toString(36);
    }
    
    // Do not SPAM ObjC with event already managed
    if (riotIOS.events[event.data._id]) {
        return;
    }

    if (!event.origin) { // stupid chrome
        event.origin = event.originalEvent.origin;
    }

    // Keep this event for future usage
    riotIOS.events[event.data._id] = event;

    riotIOS.sendObjectMessageToObjC({
                                    'event.data': event.data,
                                    });
};
window.addEventListener('message', riotIOS.onMessage, false);


// ObjC -> Widget JS bridge
window.riotIOS.sendResponse = function(eventId, res) {

    // Retrieve the correspong JS event
    var event = riotIOS.events[eventId];

    console.log("sendResponse to " + event.data.action + " for "+ eventId + ": " + JSON.stringify(res));

    var data = JSON.parse(JSON.stringify(event.data));
    data.response = res;
    event.source.postMessage(data, event.origin);

    // Mark this event as handled
    riotIOS.events[eventId] = true;
}
