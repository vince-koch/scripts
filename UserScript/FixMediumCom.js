// ==UserScript==
// @name         Fix medium.com
// @namespace    http://tampermonkey.net/
// @version      0.2
// @description  fix annoying things about medium.com
// @author       You
// @match        http*://medium.com/*
// @match        https://medium.com/@*
// @match        https://*.medium.com/*
// @icon         https://raw.githubusercontent.com/vince-koch/scripts/main/UserScript/cookie.ico
// @grant        none
// @run-at       document-idle
// ==/UserScript==

(function() {
    'use strict';

    const maxRetryCount = 10;
    const retryIntervalMs = 1000;
    let removeGoogleSignInRetryCount = 0;
    let removeMediumSignUpRetryCount = 0;

    function removeGoogleSignIn() {
        removeGoogleSignInRetryCount++;

        const div = document.getElementById("credential_picker_container");
        if (div) {
            div.remove();
            console.info("Removed Google Sign In Panel");
        }
        else if (removeGoogleSignInRetryCount < maxRetryCount) {
            setTimeout(() => removeGoogleSignIn(), retryIntervalMs);
        }
        else {
            console.warn("Unable to remove Google Sign In Panel");
        }
    }

    function removeMediumSignUp() {
        removeMediumSignUpRetryCount++;

        const collection = document.getElementsByTagName('DIV');
        const array = Array.from(collection);
        const filtered = array.filter(div => div.style.bottom === "0px");

        if (filtered.length > 0) {
            filtered.forEach(div => div.remove());
            console.info("Removed Medium Sign Up Panel");
        }
        else if (removeMediumSignUpRetryCount < maxRetryCount) {
            setTimeout(() => removeMediumSignUp(), retryIntervalMs);
        }
        else {
            console.info("Unable to remove Medium Sign Up Panel");
        }
    }

    function resetSidCookie() {
        const storiesLeftCookie = "sid";
        document.cookie = storiesLeftCookie + "=";
        console.info(`[${GM_info.script.name}] cookie [${storiesLeftCookie}] was reset to enable unlimited reading`);
    }

    function clearLocalStorage() {
        // Erase tracking ID of medium.com from localStorage. For cookie, use extensions like EditThisCookie.
        localStorage.clear();
        const iframe = document.querySelector('iframe[src^="https://smartlock.google.com"]');
        if (iframe) {
            iframe.remove();
        }
    }

    removeGoogleSignIn();
    removeMediumSignUp();
    resetSidCookie();
    clearLocalStorage();
})();
