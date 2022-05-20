// ==UserScript==
// @name Gitlab Wide Screen
// @description Adapt gitlab layout to wide screens. Please add your own domain if you use on-premise server
// @author V1rgul (https://github.com/V1rgul)
// @license CC BY-NC - Creative Commons Attribution-NonCommercial
// @version 0.0.1.20200814213543
// @namespace https://greasyfork.org/users/676264
// @grant GM_addStyle
// @run-at document-start
// @match http://gitlab.com/*
// @match https://gitlab.com/*
// @match http://*.gitlab.com/*
// @match https://*.gitlab.com/*
// ==/UserScript==

(function() {
let css = `
  .container-limited
  {
    max-width: none !important;
  }

  .commit
  {
    position: relative;
  }

  .commit .avatar-cell
  {
    position: absolute;
    left: 240px;
  }

  .commit .commit-detail .commit-content
  {
    position: absolute;
    left: 286px;
  }

  .commit .commit-detail .commit-actions
  {
    position: relative;
    padding-left: 36px;
  }

  .commit .commit-detail .commit-actions .ci-status-link
  {
    position: absolute;
    left: 0;
  }

  .commit .commit-detail .commit-actions .ci-status-link .svg
  {
    width: 24px;
    min-width: 24px;
  }

  .commit.gl-responsive-table-row
  {
    position: relative;
  }

  .commit.gl-responsive-table-row > *
  {
    /*flex-grow: 0;*/
    width: auto;
    max-width: none;
    flex-basis: auto;
  }

  .commit.gl-responsive-table-row .commit-link
  {
    margin-right: 16px;
  }

  .commit.gl-responsive-table-row > *:nth-child(4)
  {
    flex-grow: 1;
  }

  .commit.gl-responsive-table-row .stage-cell
  {
    width: 160px;
  }

  .commit.gl-responsive-table-row .pipelines-time-ago
  {
    margin-right: 200px;
    width: 140px;
  }

  .commit.gl-responsive-table-row .pipeline-actions
  {
    position: absolute;
    right: 0;
  }

  .issuable-info-container
  {
    flex-direction: row-reverse;
    /*justify-content: flex-start;*/;
  }

  .issuable-info-container .issuable-meta
  {
    flex-grow: 0 !important;
    margin-right: 32px;
  }
`;
if (typeof GM_addStyle !== "undefined") {
  GM_addStyle(css);
} else {
  let styleNode = document.createElement("style");
  styleNode.appendChild(document.createTextNode(css));
  (document.querySelector("head") || document.documentElement).appendChild(styleNode);
}
})();
