// ==UserScript==
// @name         Cookie Monster
// @namespace    http://tampermonkey.net/
// @version      0.4
// @description  Lots of sites are asking about cookies these days.  I just want to read something real quick.
// @author       You
// @match        https://*.askubuntu.com/*
// @match        https://*.stackexchange.com/*
// @match        https://*.stackoverflow.com/*
// @match        https://*.superuser.com/*
// @match        https://*.superuser.com/*
// @match        https://*.wowhead.com/*
// @icon         https://raw.githubusercontent.com/vince-koch/scripts/main/UserScript/cookie.ico
// @grant        none
// ==/UserScript==

'use strict';

(function() {
    function isIterable(obj) {
        if (obj == null) {
            return false;
        }

        return typeof obj[Symbol.iterator] === 'function';
    }

    function removeElements(elements) {
        if (elements === null) {
            return;
        }

        if (!isIterable(elements)) {
            console.info("Cookie Monster is removing element", elements);
            elements.remove();
        }

        // remove elements in reverse order
        for (let i = elements.length - 1; i >= 0; --i) {
            console.info("Cookie Monster is removing element", elements[i]);
            elements[i].remove();
        }
    }

    function scan(callback, interval, remainingAttempts) {
        callback();
        if (remainingAttempts > 0) {
            setTimeout(scan, interval, callback, interval, remainingAttempts - 1);
        }
    }

    function wowhead() {
        // no privacy / cookie notifications
        removeElements(document.getElementById("onetrust-consent-sdk"));

        // no desktop notifications
        removeElements(document.getElementsByClassName("notifications-dialog"));

        // block video
        removeElements(document.getElementsByClassName("blocks"));
    }

    console.info("Cookie Monster is scanning for annoyances");
    removeElements(document.querySelectorAll('div.js-consent-banner'));

    if (window.location.host === "www.wowhead.com") {
        scan(wowhead, 500, 10);
    }
})();
