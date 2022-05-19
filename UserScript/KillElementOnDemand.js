// ==UserScript==
// @name         Kill Element On Demand
// @namespace    http://tampermonkey.net/
// @version      0.4
// @description  Removes the element directly under the cursor when the backtick (`) key is pressed!
// @author       Vince Koch
// @match        https://*/*
// @match        http://*/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=tampermonkey.net
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    document.addEventListener("keydown", function onKeyDown(event) {
        if (event.ctrlKey === true && event.key === "`") {
            var elements = document.querySelectorAll(":hover");
            if (elements.length > 0) {
                var element = elements[elements.length - 1];
                element.remove();
            }
        }
    });

})();
