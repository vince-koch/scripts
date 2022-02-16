// ==UserScript==
// @name         Cookie Monster
// @namespace    http://tampermonkey.net/
// @version      0.2
// @description  Lots of sites are asking about cookies these days.  I just want to read something real quick.
// @author       You
// @match        https://*.askubuntu.com/*
// @match        https://*.stackexchange.com/*
// @match        https://*.stackoverflow.com/*
// @match        https://*.superuser.com/*
// @icon         https://www.google.com/s2/favicons?domain=superuser.com
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    console.info("Scanning for annoying consent requests");
    var divs = document.querySelectorAll('div.js-consent-banner');
    for (var i = 0; i < divs.length; i++)
    {
        divs[i].remove();
    }

    if (divs.length > 0)
    {
        console.info("Removed " + divs.length + " annoyances");
    }
})();
