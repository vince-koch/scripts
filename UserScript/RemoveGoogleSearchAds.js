// ==UserScript==
// @name         Remove Google Search Ads
// @namespace    http://tampermonkey.net/
// @version      1.01
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

    const options = {
        style: {
            main: {
                background: "red",
                color: "white",
            },
        },
        settings: {
            duration: 2000,
        },
    };

    function removeAdsById(elementId) {
        var element = document.getElementById(elementId)
        if (element) {
            //element.remove();
            const message = "Remove Google Search Ads ==> Removed ads (" + elementId + ")";

            const div = document.createElement("h4");
            const divContent = document.createTextNode(message);
            div.appendChild(divContent);
            div.style.color = "red";
            element.parentNode.replaceChild(div, element);

            console.info(message);
            //iqwerty.toast.toast(message, options);
        }
    }

    console.info("Remove Google Search Ads ==> loaded");

    // @require      https://raw.githubusercontent.com/mlcheng/js-toast/master/toast.min.js
    //iqwerty.toast.toast("RemoveGoogleSearchAds.js loaded!", options);

    removeAdsById("tads");
    removeAdsById("bottomads");
})();
