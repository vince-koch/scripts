// ==UserScript==
// @name         Kill Element On Demand
// @namespace    http://tampermonkey.net/
// @version      0.8
// @description  Highlights the element directly under the cursor when the CTRL is pressed, and kills it when CTRL+` is pressed!
// @author       Vince Koch
// @match        https://*/*
// @match        http://*/*
// @icon         https://raw.githubusercontent.com/vince-koch/scripts/main/UserScript/cookie.ico
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

	let lastMouseEvent = null;
    let glowingElement = null;

    function addGlow(element) {
		if (glowingElement !== null && glowingElement !== element) {
			removeGlow();
		}
		
		if (glowingElement !== element) {
			glowingElement = element;
			glowingElement.classList.add("kill-glow");
		}
    }

    function removeGlow() {
        if (glowingElement !== null) {
            glowingElement.classList.remove("kill-glow");
			glowingElement = null;
        }
    }

    function killGlowingElement() {
        if (glowingElement !== null) {
			console.warn("killing ", glowingElement);

            glowingElement.remove();
            glowingElement = null;
        }
    }

	function onMouseMove(event) {
		lastMouseEvent = event;
	}
	
    function onKeyDown(event) {	
		if (event.key === "Control") {
			let hoverElement = document.elementFromPoint(lastMouseEvent.clientX, lastMouseEvent.clientY);
			
			if (hoverElement !== null) {
				addGlow(hoverElement);
			}
			else {
				removeGlow();
			}
        }
		else if (event.key === "`" && event.ctrlKey === true) {
			event.preventDefault();
			killGlowingElement();
        }
    }

    function onKeyUp(event) {
        if (event.key === "Control") {
            removeGlow();
        }
    }

    createGlowStyle();
	document.addEventListener("mousemove", e => onMouseMove(e));
    document.addEventListener("keydown", e => onKeyDown(e));
    document.addEventListener("keyup", e => onKeyUp(e));
})();
