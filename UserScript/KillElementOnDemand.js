// ==UserScript==
// @name         Kill Element On Demand
// @namespace    http://tampermonkey.net/
// @version      0.5
// @description  Highlights the element directly under the cursor when the CTRL is pressed, and kills it when CTRL+` is pressed!
// @author       Vince Koch
// @match        https://*/*
// @match        http://*/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=tampermonkey.net
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    function addGlowStyle() {
        const style = document.createElement("style");
        style.innerHTML = `
            .kill-glow {
                border: 2px solid red;
                border-radius: 7px;
                outline: none;
                box-shadow: 0 0 10px red;
            }`;

        document.head.appendChild(style);
    }

    addGlowStyle();

    let glowingElement = null;

    document.addEventListener("keydown", function onKeyDown(event) {
        if (event.ctrlKey === true && event.key === "`") {
            if (glowingElement !== null) {
                glowingElement.remove();
                glowingElement = null;
            }
        }
        else if (event.ctrlKey === true) {
            // remove glow from prior element
            if (glowingElement !== null) {
                glowingElement.classList.remove("kill-glow");
            }

            // find the current element and give it a glow
            let elements = document.querySelectorAll(":hover");
            if (elements.length > 0) {
                glowingElement = elements[elements.length - 1];
                glowingElement.classList.add("kill-glow");
            }
        }
    });
})();
