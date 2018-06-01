/*
 Copyright 2017 Vector Creations Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
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
