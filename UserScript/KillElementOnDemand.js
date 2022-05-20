// ==UserScript==
// @name         Kill Element On Demand
// @namespace    http://tampermonkey.net/
// @version      0.6
// @description  Highlights the element directly under the cursor when the CTRL is pressed, and kills it when CTRL+` is pressed!
// @author       Vince Koch
// @match        https://*/*
// @match        http://*/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=tampermonkey.net
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    function createGlowStyle() {
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
    
    let glowingElement = null;

    function addGlow(element) {
        removeGlow();
        
        glowingElement = element;
        glowingElement.classList.add("kill-glow");
    }
    
    function removeGlow() {
        if (glowingElement !== null) {
            glowingElement.classList.remove("kill-glow");
        }
    }
    
    function killGlowingElement() {
        if (glowingElement !== null) {
            glowingElement.remove();
            glowingElement = null;
        }
    }
    
    createGlowStyle();

    document.addEventListener("keydown", function onKeyDown(event) {
        if (event.ctrlKey === true && event.key === "`") {
            killGlowingElement();
        }
        else if (event.ctrlKey === true) {
            removeGlow();

            let elements = document.querySelectorAll(":hover");
            if (elements.length > 0) {
                addGlow(elements[elements.length - 1]);
            }
        }
    });
    
    document.addEventListener("keydown", function onKeyDown(event) {
        if (event.ctrlKey === true) {
            removeGlow();
        }
    }
})();
