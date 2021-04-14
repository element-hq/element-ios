 (function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.crossplatform = f()}})(function(){var define,module,exports;return (function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
 "use strict";

 Object.defineProperty(exports, "__esModule", {
   value: true
 });
 exports.formatCommaSeparatedList = formatCommaSeparatedList;
 exports.isValid3pidInvite = isValid3pidInvite;

 var _languageHandler = require("../languageHandler");

 /*
 Copyright 2019 The Matrix.org Foundation C.I.C.

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

 /**
  * Constructs a written English string representing `items`, with an optional
  * limit on the number of items included in the result. If specified and if the
  * length of `items` is greater than the limit, the string "and n others" will
  * be appended onto the result. If `items` is empty, returns the empty string.
  * If there is only one item, return it.
  * @param {string[]} items the items to construct a string from.
  * @param {number?} itemLimit the number by which to limit the list.
  * @returns {string} a string constructed by joining `items` with a comma
  * between each item, but with the last item appended as " and [lastItem]".
  */
 function formatCommaSeparatedList(items
 /*: string[]*/
 , itemLimit
 /*: number*/
 )
 /*: string*/
 {
   const remaining = itemLimit === undefined ? 0 : Math.max(items.length - itemLimit, 0);

   if (items.length === 0) {
     return "";
   } else if (items.length === 1) {
     return items[0];
   } else if (remaining > 0) {
     items = items.slice(0, itemLimit);
     return (0, _languageHandler._t)("%(items)s and %(count)s others", {
       items: items.join(', '),
       count: remaining
     });
   } else {
     const lastItem = items.pop();
     return (0, _languageHandler._t)("%(items)s and %(lastItem)s", {
       items: items.join(', '),
       lastItem: lastItem
     });
   }
 }
 /**
  * Checks if the given MatrixEvent is a valid 3rd party user invite.
  * @param {MatrixEvent} event The event to check
  * @returns {boolean} True if valid, false otherwise
  */


 function isValid3pidInvite(event) {
   if (!event || event.getType() !== "m.room.third_party_invite") return false; // any events without these keys are not valid 3pid invites, so we ignore them

   const requiredKeys = ['key_validity_url', 'public_key', 'display_name'];

   for (let i = 0; i < requiredKeys.length; ++i) {
     if (!event.getContent()[requiredKeys[i]]) return false;
   } // Valid enough by our standards


   return true;
 }


 },{"../languageHandler":3}],2:[function(require,module,exports){
 "use strict";

 Object.defineProperty(exports, "__esModule", {
   value: true
 });
 exports.aggregateAndGenerateSummary = aggregateAndGenerateSummary;

 var _languageHandler = require("../languageHandler");

 var _common = require("./common");

 /*
 Copyright 2019 The Matrix.org Foundation C.I.C.

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
 var TransitionType;

 (function (TransitionType) {
   TransitionType["Joined"] = "joined";
   TransitionType["Left"] = "left";
   TransitionType["JoinedAndLeft"] = "joined_and_left";
   TransitionType["LeftAndJoined"] = "left_and_joined";
   TransitionType["InviteReject"] = "invite_reject";
   TransitionType["InviteWithdrawal"] = "invite_withdrawal";
   TransitionType["Invited"] = "invited";
   TransitionType["Banned"] = "banned";
   TransitionType["Unbanned"] = "unbanned";
   TransitionType["Kicked"] = "kicked";
   TransitionType["ChangedName"] = "changed_name";
   TransitionType["ChangedAvatar"] = "changed_avatar";
   TransitionType["NoChange"] = "no_change";
 })(TransitionType || (TransitionType = {}));

 const SEP = ",";

 function aggregateAndGenerateSummary(userEvents
 /*: Record<string, IUserEvents[]>*/
 , itemLimit
 /*: number*/
 )
 /*: string*/
 {
   const aggregate = getAggregate(userEvents); // Sort types by order of lowest event index within sequence

   const orderedTransitionSequences = Object.keys(aggregate.names).sort((seq1, seq2) => aggregate.indices[seq1] - aggregate.indices[seq2]);
   return generateSummary(aggregate.names, orderedTransitionSequences, itemLimit);
 }
 /**
  * Generate the text for users aggregated by their transition sequences (`eventAggregates`) where
  * the sequences are ordered by `orderedTransitionSequences`.
  * @param {object} eventAggregates a map of transition sequence to array of user display names
  * or user IDs.
  * @param {string[]} orderedTransitionSequences an array which is some ordering of
  * `Object.keys(eventAggregates)`.
  * @param {number} itemLimit the number by which to limit the list.
  * @returns {string} the textual summary of the aggregated events that occurred.
  */


 function generateSummary(eventAggregates
 /*: Record<string, string[]>*/
 , orderedTransitionSequences
 /*: string[]*/
 , itemLimit
 /*: number*/
 ) {
   const summaries = orderedTransitionSequences.map(transitions => {
     const userNames = eventAggregates[transitions];
     const nameList = renderNameList(userNames, itemLimit);
     const splitTransitions = transitions.split(SEP); // Some neighbouring transitions are common, so canonicalise some into "pair"
     // transitions

     const canonicalTransitions = getCanonicalTransitions(splitTransitions); // Transform into consecutive repetitions of the same transition (like 5
     // consecutive 'joined_and_left's)

     const coalescedTransitions = coalesceRepeatedTransitions(canonicalTransitions);
     const descs = coalescedTransitions.map(t => {
       return getDescriptionForTransition(t.transitionType, userNames.length, t.repeats);
     });
     const desc = (0, _common.formatCommaSeparatedList)(descs);
     return (0, _languageHandler._t)('%(nameList)s %(transitionList)s', {
       nameList: nameList,
       transitionList: desc
     });
   });

   if (!summaries) {
     return null;
   }

   return summaries.join(", ");
 }
 /**
  * @param {string[]} users an array of user display names or user IDs.
  * @param {number} itemLimit the number by which to limit the list.
  * @returns {string} a comma-separated list that ends with "and [n] others" if there are
  * more items in `users` than `itemLimit`, which is the number of names
  * included before "and [n] others".
  */


 function renderNameList(users
 /*: string[]*/
 , itemLimit
 /*: number*/
 ) {
   return (0, _common.formatCommaSeparatedList)(users, itemLimit);
 }
 /**
  * Canonicalise an array of transitions such that some pairs of transitions become
  * single transitions. For example an input ['joined','left'] would result in an output
  * ['joined_and_left'].
  * @param {string[]} transitions an array of transitions.
  * @returns {string[]} an array of transitions.
  */


 function getCanonicalTransitions(transitions
 /*: TransitionType[]*/
 )
 /*: TransitionType[]*/
 {
   const modMap = {
     [TransitionType.Joined]: {
       after: TransitionType.Left,
       newTransition: TransitionType.JoinedAndLeft
     },
     [TransitionType.Left]: {
       after: TransitionType.Joined,
       newTransition: TransitionType.LeftAndJoined
     } // $currentTransition : {
     //     'after' : $nextTransition,
     //     'newTransition' : 'new_transition_type',
     // },

   };
   const res
   /*: TransitionType[]*/
   = [];

   for (let i = 0; i < transitions.length; i++) {
     const t = transitions[i];
     const t2 = transitions[i + 1];
     let transition = t;

     if (i < transitions.length - 1 && modMap[t] && modMap[t].after === t2) {
       transition = modMap[t].newTransition;
       i++;
     }

     res.push(transition);
   }

   return res;
 }
 /**
  * Transform an array of transitions into an array of transitions and how many times
  * they are repeated consecutively.
  *
  * An array of 123 "joined_and_left" transitions, would result in:
  * ```
  * [{
  *   transitionType: "joined_and_left"
  *   repeats: 123
  * }]
  * ```
  * @param {string[]} transitions the array of transitions to transform.
  * @returns {object[]} an array of coalesced transitions.
  */


 function coalesceRepeatedTransitions(transitions
 /*: TransitionType[]*/
 ) {
   const res
   /*: {
           transitionType: TransitionType;
           repeats: number;
       }[]*/
   = [];

   for (let i = 0; i < transitions.length; i++) {
     if (res.length > 0 && res[res.length - 1].transitionType === transitions[i]) {
       res[res.length - 1].repeats += 1;
     } else {
       res.push({
         transitionType: transitions[i],
         repeats: 1
       });
     }
   }

   return res;
 }
 /**
  * For a certain transition, t, describe what happened to the users that
  * underwent the transition.
  * @param {string} t the transition type.
  * @param {number} userCount number of usernames
  * @param {number} repeats the number of times the transition was repeated in a row.
  * @returns {string} the written Human Readable equivalent of the transition.
  */


 function getDescriptionForTransition(t
 /*: TransitionType*/
 , userCount
 /*: number*/
 , repeats
 /*: number*/
 ) {
   // The empty interpolations 'severalUsers' and 'oneUser'
   // are there only to show translators to non-English languages
   // that the verb is conjugated to plural or singular Subject.
   let res = null;

   switch (t) {
     case "joined":
       res = userCount > 1 ? (0, _languageHandler._t)("%(severalUsers)sjoined %(count)s times", {
         severalUsers: "",
         count: repeats
       }) : (0, _languageHandler._t)("%(oneUser)sjoined %(count)s times", {
         oneUser: "",
         count: repeats
       });
       break;

     case "left":
       res = userCount > 1 ? (0, _languageHandler._t)("%(severalUsers)sleft %(count)s times", {
         severalUsers: "",
         count: repeats
       }) : (0, _languageHandler._t)("%(oneUser)sleft %(count)s times", {
         oneUser: "",
         count: repeats
       });
       break;

     case "joined_and_left":
       res = userCount > 1 ? (0, _languageHandler._t)("%(severalUsers)sjoined and left %(count)s times", {
         severalUsers: "",
         count: repeats
       }) : (0, _languageHandler._t)("%(oneUser)sjoined and left %(count)s times", {
         oneUser: "",
         count: repeats
       });
       break;

     case "left_and_joined":
       res = userCount > 1 ? (0, _languageHandler._t)("%(severalUsers)sleft and rejoined %(count)s times", {
         severalUsers: "",
         count: repeats
       }) : (0, _languageHandler._t)("%(oneUser)sleft and rejoined %(count)s times", {
         oneUser: "",
         count: repeats
       });
       break;

     case "invite_reject":
       res = userCount > 1 ? (0, _languageHandler._t)("%(severalUsers)srejected their invitations %(count)s times", {
         severalUsers: "",
         count: repeats
       }) : (0, _languageHandler._t)("%(oneUser)srejected their invitation %(count)s times", {
         oneUser: "",
         count: repeats
       });
       break;

     case "invite_withdrawal":
       res = userCount > 1 ? (0, _languageHandler._t)("%(severalUsers)shad their invitations withdrawn %(count)s times", {
         severalUsers: "",
         count: repeats
       }) : (0, _languageHandler._t)("%(oneUser)shad their invitation withdrawn %(count)s times", {
         oneUser: "",
         count: repeats
       });
       break;

     case "invited":
       res = userCount > 1 ? (0, _languageHandler._t)("were invited %(count)s times", {
         count: repeats
       }) : (0, _languageHandler._t)("was invited %(count)s times", {
         count: repeats
       });
       break;

     case "banned":
       res = userCount > 1 ? (0, _languageHandler._t)("were banned %(count)s times", {
         count: repeats
       }) : (0, _languageHandler._t)("was banned %(count)s times", {
         count: repeats
       });
       break;

     case "unbanned":
       res = userCount > 1 ? (0, _languageHandler._t)("were unbanned %(count)s times", {
         count: repeats
       }) : (0, _languageHandler._t)("was unbanned %(count)s times", {
         count: repeats
       });
       break;

     case "kicked":
       res = userCount > 1 ? (0, _languageHandler._t)("were kicked %(count)s times", {
         count: repeats
       }) : (0, _languageHandler._t)("was kicked %(count)s times", {
         count: repeats
       });
       break;

     case "changed_name":
       res = userCount > 1 ? (0, _languageHandler._t)("%(severalUsers)schanged their name %(count)s times", {
         severalUsers: "",
         count: repeats
       }) : (0, _languageHandler._t)("%(oneUser)schanged their name %(count)s times", {
         oneUser: "",
         count: repeats
       });
       break;

     case "changed_avatar":
       res = userCount > 1 ? (0, _languageHandler._t)("%(severalUsers)schanged their avatar %(count)s times", {
         severalUsers: "",
         count: repeats
       }) : (0, _languageHandler._t)("%(oneUser)schanged their avatar %(count)s times", {
         oneUser: "",
         count: repeats
       });
       break;

     case "no_change":
       res = userCount > 1 ? (0, _languageHandler._t)("%(severalUsers)smade no changes %(count)s times", {
         severalUsers: "",
         count: repeats
       }) : (0, _languageHandler._t)("%(oneUser)smade no changes %(count)s times", {
         oneUser: "",
         count: repeats
       });
       break;
   }

   return res;
 }

 function getTransitionSequence(events
 /*: MatrixEvent[]*/
 ) {
   return events.map(getTransition);
 }
 /**
  * Label a given membership event, `e`, where `getContent().membership` has
  * changed for each transition allowed by the Matrix protocol. This attempts to
  * label the membership changes that occur in `../../../TextForEvent.js`.
  * @param {MatrixEvent} e the membership change event to label.
  * @returns {string?} the transition type given to this event. This defaults to `null`
  * if a transition is not recognised.
  */


 function getTransition(e
 /*: MatrixEvent*/
 )
 /*: TransitionType*/
 {
   if (e.mxEvent.getType() === 'm.room.third_party_invite') {
     // Handle 3pid invites the same as invites so they get bundled together
     if (!(0, _common.isValid3pidInvite)(e.mxEvent)) {
       return TransitionType.InviteWithdrawal;
     }

     return TransitionType.Invited;
   }

   switch (e.mxEvent.getContent().membership) {
     case 'invite':
       return TransitionType.Invited;

     case 'ban':
       return TransitionType.Banned;

     case 'join':
       if (e.mxEvent.getPrevContent().membership === 'join') {
         if (e.mxEvent.getContent().displayname !== e.mxEvent.getPrevContent().displayname) {
           return TransitionType.ChangedName;
         } else if (e.mxEvent.getContent().avatar_url !== e.mxEvent.getPrevContent().avatar_url) {
           return TransitionType.ChangedAvatar;
         } // console.log("MELS ignoring duplicate membership join event");


         return TransitionType.NoChange;
       } else {
         return TransitionType.Joined;
       }

     case 'leave':
       if (e.mxEvent.getSender() === e.mxEvent.getStateKey()) {
         switch (e.mxEvent.getPrevContent().membership) {
           case 'invite':
             return TransitionType.InviteReject;

           default:
             return TransitionType.Left;
         }
       }

       switch (e.mxEvent.getPrevContent().membership) {
         case 'invite':
           return TransitionType.InviteWithdrawal;

         case 'ban':
           return TransitionType.Unbanned;
         // sender is not target and made the target leave, if not from invite/ban then this is a kick

         default:
           return TransitionType.Kicked;
       }

     default:
       return null;
   }
 }

 function getAggregate(userEvents
 /*: Record<string, IUserEvents[]>*/
 ) {
   // A map of aggregate type to arrays of display names. Each aggregate type
   // is a comma-delimited string of transitions, e.g. "joined,left,kicked".
   // The array of display names is the array of users who went through that
   // sequence during eventsToRender.
   const aggregate
   /*: Record<string, string[]>*/
   = {// $aggregateType : []:string
   }; // A map of aggregate types to the indices that order them (the index of
   // the first event for a given transition sequence)

   const aggregateIndices
   /*: Record<string, number>*/
   = {// $aggregateType : int
   };
   const users = Object.keys(userEvents);
   users.forEach(userId => {
     const firstEvent = userEvents[userId][0];
     const displayName = firstEvent.displayName;
     const seq = getTransitionSequence(userEvents[userId]).join(SEP);

     if (!aggregate[seq]) {
       aggregate[seq] = [];
       aggregateIndices[seq] = -1;
     }

     aggregate[seq].push(displayName);

     if (aggregateIndices[seq] === -1 || firstEvent.index < aggregateIndices[seq]) {
       aggregateIndices[seq] = firstEvent.index;
     }
   });
   return {
     names: aggregate,
     indices: aggregateIndices
   };
 }


 },{"../languageHandler":3,"./common":1}],3:[function(require,module,exports){
 "use strict";

 Object.defineProperty(exports, "__esModule", {
   value: true
 });
 exports._t = function(text, variables) { return text; };

 },{}],4:[function(require,module,exports){
 module.exports.languageHandler = require('./languageHandler');
 module.exports.common = require('./crossplatform/common');
 module.exports.memberEvents = require('./crossplatform/memberEvents');

 },{"./crossplatform/common":1,"./crossplatform/memberEvents":2,"./languageHandler":3}]},{},[3,1,2,4])(4)
 });
