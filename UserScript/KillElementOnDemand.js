// ==UserScript==
// @name         Kill Element On Demand
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  Removes the element directly under the cursor when the hotkey CTRL + ~ is detected!
// @author       Vince Koch
// @match        https://*/*
// @match        http://*/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=tampermonkey.net
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    document.addEventListener("keypress", function onPress(event) {
        if (event.key === "`") {
            var elements = document.querySelectorAll(":hover");
            var element = elements[elements.length - 1]
            element.remove()
        }
    });

})();
