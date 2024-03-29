// ==UserScript==
// @name         MarkdownStyle
// @version      0.3
// @description  Renders raw markdown files as HTML.
// @match        file:///**/*.md
// @require      https://cdn.jsdelivr.net/npm/showdown@2.1.0/dist/showdown.min.js
// @resource     CSS_GITHUB https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main/github-markdown.css
// @icon         https://raw.githubusercontent.com/vince-koch/scripts/main/UserScript/cookie.ico
// @grant        GM_addStyle
// @grant        GM_getResourceText
// ==/UserScript==

(function() {
    'use strict';

    console.info("MarkdownStyle.js");
    
    GM_addStyle(GM_getResourceText("CSS_GITHUB"));
    GM_addStyle(`body {
        padding: 10px 20px;
    }`);

    let body = document.getElementsByTagName("body")[0];
    let markdownText = body.innerText;

    let converter = new showdown.Converter({
        tables: true
    });

    let markdownHtml = converter.makeHtml(markdownText);

    body.innerHTML = markdownHtml;
    body.classList.add("markdown-body");
})();

