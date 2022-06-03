// ==UserScript==
// @name         Remove Google Search Ads
// @namespace    http://tampermonkey.net/
// @version      0.8
// @description  Remove ads from Google search results
// @author       vince-koch
// @match        https://www.google.com/*
// @icon         https://raw.githubusercontent.com/vince-koch/scripts/main/UserScript/cookie.ico
// @grant        none
// @run-at       document-end
// @license      MIT
// ==/UserScript==

(function() {
    'use strict';

    function removeAdsById(elementId) {
        var element = document.getElementById(elementId)
        if (element) {
            //element.remove();
            const message = "RemoveGoogleSearchAds.js: Removed ads (" + elementId + ")";

            const div = document.createElement("h4");
            const divContent = document.createTextNode(message);
            div.appendChild(divContent);
            div.style.color = "red";
            element.parentNode.replaceChild(div, element);

            console.warn(message);
        }
    }
    
    console.warn("RemoveGoogleSearchAds.js");
    removeAdsById("tads");
    removeAdsById("bottomads");
})();
