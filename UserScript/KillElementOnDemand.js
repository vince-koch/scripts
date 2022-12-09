// ==UserScript==
// @name         Kill Element On Demand
// @namespace    http://tampermonkey.net/
// @version      0.14
// @description  (CTRL+`) = toggle targeting mode; (ESC) = exit targeting mode; (`) = kill targeted element
// @author       Vince Koch
// @match        https://*/*
// @match        http://*/*
// @icon         https://raw.githubusercontent.com/vince-koch/scripts/main/UserScript/cookie.ico
// @grant        none
// @run-at       document-start
// @noframes
// ==/UserScript==

(function() {
    'use strict';

    let _isTargeting = false;
    let _lastMouseEvent = null;
    let _glowingElement = null;
    let _infoPanel = createKillInfoPanel();

    function appendKillGlowStyle() {
        const style = document.createElement("style");
        style.innerHTML = `
            .kill-glow, .kill-panel {
                border: 2px solid red;
                border-radius: 7px;
                outline: none;
                box-shadow: 0 0 10px red;
            }

            .kill-panel {
                background-color: maroon;
                color: white;
                font-family: Segoe UI, Roboto;
                font-size: 16px;
                font-weight: bold;
                opacity: 0.5;
                padding: 10px;
                position: sticky;
                text-align: center;
                top:0;
                z-index: 2147483647;
            }

            .kill-pulse {
                -webkit-animation: kill-pulse-frames 3.0s ease-out;
                -webkit-animation-iteration-count: infinite;
                opacity: 0.3;
            }

            @-webkit-keyframes kill-pulse-frames {
                0% { opacity: 0.3; }
                90% { opacity: 1.0; }
                100% { opacity: 0.3; }
            }`;

        document.head.appendChild(style);
    }

    function createKillInfoPanel() {
        const div = document.createElement("div");
        div.innerHTML = "Kill Element On Demand Activated;  CTRL+~ = Toggle Targeting;  ESC = Exit Targeting;  ~ = Kill Element";
        div.classList.add("kill-panel");
        div.classList.add("kill-pulse");

        return div;
    }

    function updateGlow() {
        function removeGlow() {
            if (_glowingElement !== null) {
                _glowingElement.classList.remove("kill-glow");
                _glowingElement = null;
                _infoPanel.remove();
            }
        }

        function addGlow(element) {
            removeGlow();
            _glowingElement = hoverElement;
            _glowingElement.classList.add("kill-glow");
            document.body.insertBefore(_infoPanel, document.body.firstChild);
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
        //console.info("event.key = ", event.key);

        if (event.key === "`") {
            if (event.ctrlKey === true) {
                _isTargeting = !_isTargeting;
                createInfoPanel();
                updateGlow();
                event.preventDefault();
            }
            else if (_isTargeting && _glowingElement !== null) {
                _glowingElement.remove();
                _glowingElement = null;
                updateGlow();
                event.preventDefault();
            }
        }
        else if (event.key === "Escape" && _isTargeting) {
            _isTargeting = !_isTargeting;
            updateGlow();
            event.preventDefault();
        }
    }

    appendKillGlowStyle();

    document.addEventListener("mousemove", e => onMouseMove(e));
    document.addEventListener("keydown", e => onKeyDown(e));
    console.info('Kill Element On Demand ==> ', { "CTRL+`": "Toggle targeting", "`": "Kill targeted element" });
})();
