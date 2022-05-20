// ==UserScript==
// @name         Remove Google Search Ads
// @namespace    http://tampermonkey.net/
// @version      0.4
// @description  Remove ads from Google search results
// @author       You
// @match        https://www.google.com/*
// @icon         https://www.google.com/s2/favicons?domain=github.com
// @grant        none
// ==/UserScript==

function removeAdsById(elementId) {
    var element = document.getElementById(elementId)
    if (element) {
        //element.remove();
        const message = "GoogleRemoveAds: Removed ads (" + elementId + ")"

        const div = document.createElement("h4");
        const divContent = document.createTextNode(message)
        div.appendChild(divContent);
        div.style.color = "red";
        element.parentNode.replaceChild(div, element)

        console.warn(message)
    }
}

(function() {
    'use strict';

    console.warn("GoogleRemoveAds: looking for ads")
    removeAdsById("tads")
    removeAdsById("bottomads")
})();
