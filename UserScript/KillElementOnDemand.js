// ==UserScript==
// @name         Kill Element On Demand
// @namespace    http://tampermonkey.net/
// @version      0.9
// @description  (CTRL+`) = enter/exit targeting mode; (`) = kill targeted element
// @author       Vince Koch
// @match        https://*/*
// @match        http://*/*
// @icon         https://raw.githubusercontent.com/vince-koch/scripts/main/UserScript/cookie.ico
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    let _isTargeting = false;
	let _lastMouseEvent = null;
    let _glowingElement = null;

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

    function updateGlow() {
        function removeGlow() {
            if (_glowingElement !== null) {
                _glowingElement.classList.remove("kill-glow");
                _glowingElement = null;
            }
        }

        function addGlow(element) {
            removeGlow();
            _glowingElement = hoverElement;
            _glowingElement.classList.add("kill-glow");
        }

        let hoverElement = document.elementFromPoint(_lastMouseEvent.clientX, _lastMouseEvent.clientY);

        if (!_isTargeting) {
            removeGlow();
        }
        else if (_glowingElement !== hoverElement) {
            removeGlow();

            if (hoverElement !== null) {
                addGlow(hoverElement);
            }
        }
    }

    function onMouseMove(event) {
		_lastMouseEvent = event;
        updateGlow();
	}

    function onKeyDown(event) {
        console.info("onKeyDown ::: ", event);

        if (event.key === "`") {
            event.preventDefault();

            if (event.ctrlKey === true) {
                _isTargeting = !_isTargeting;
                updateGlow();
            }
            else if (_isTargeting && _glowingElement !== null) {
                _glowingElement.remove();
                _glowingElement = null;
                updateGlow();
            }
        }
    }

    createGlowStyle();
	document.addEventListener("mousemove", e => onMouseMove(e));
    document.addEventListener("keydown", e => onKeyDown(e));
})();
