/* which-key strip for vscode-neovim.
 *
 * be5invis.vscode-custom-css inlines this as a <script> into the workbench
 * (extension.js:252), so it runs in the renderer with DOM access.
 *
 * lua/config/vscode_whichkey.lua drives it. That module calls nvim_echo, which
 * vscode-neovim turns into msg_show and writes into its "vscode-neovim-status"
 * status bar item. This watches that item for a "WK1:" payload, hides the raw
 * text, and paints the grid above the status bar. Nothing here reads keys; the
 * Lua side owns the getcharstr loop and this only ever draws.
 */
(function () {
    "use strict";

    var MARK = "WK1:";
    var panel = null;
    var lastPayload = null;

    // ------------------------------------------------------------------ dom

    function build() {
        var el = document.createElement("div");
        el.className = "whichkey-strip";
        el.innerHTML =
            '<div class="whichkey-grid"></div><div class="whichkey-prefix"></div>';
        document.body.appendChild(el);
        return el;
    }

    function ensure() {
        if (!panel || !panel.isConnected) panel = build();
        return panel;
    }

    function hide() {
        if (panel) panel.classList.remove("visible");
        lastPayload = null;
    }

    function render(data) {
        var el = ensure();
        var grid = el.querySelector(".whichkey-grid");
        var rows = data.r || [];

        grid.textContent = "";
        for (var i = 0; i < rows.length; i++) {
            var cell = document.createElement("div");
            cell.className = "whichkey-cell";

            var k = document.createElement("span");
            k.className = "whichkey-key";
            k.textContent = rows[i].k;

            var arrow = document.createElement("span");
            arrow.className = "whichkey-arrow";
            arrow.textContent = "→";

            var d = document.createElement("span");
            d.className = rows[i].g ? "whichkey-group" : "whichkey-desc";
            d.textContent = rows[i].d;

            cell.appendChild(k);
            cell.appendChild(arrow);
            cell.appendChild(d);
            grid.appendChild(cell);
        }

        el.querySelector(".whichkey-prefix").textContent = data.p || "";
        el.classList.add("visible");
    }

    // -------------------------------------------------------------- channel

    /* Nvim and the Lua side share one status bar item, so this both reads the
     * payload and manages that item's visibility. Hiding it permanently would
     * swallow every later nvim message (-- INSERT --, :w output), and leaving a
     * stale marker on screen would show raw "WK1:" text. */
    var hidden = [];

    function restore(el) {
        var i = hidden.indexOf(el);
        if (i !== -1) {
            el.style.display = "";
            hidden.splice(i, 1);
        }
    }

    function readStatus() {
        var items = document.querySelectorAll(".statusbar-item");
        var payload = null;
        for (var i = 0; i < items.length; i++) {
            var el = items[i];
            if ((el.textContent || "").indexOf(MARK) === 0) {
                // keep the transport out of the status bar itself
                el.style.display = "none";
                if (hidden.indexOf(el) === -1) hidden.push(el);
                payload = el.textContent.slice(MARK.length);
            } else {
                restore(el);
            }
        }
        return payload;
    }

    function scan() {
        var payload = readStatus();

        /* payload === null means the marker is gone, which happens whenever
         * nvim writes anything else to that item. Feeding a mode-changing key
         * used to overwrite the marker with "-- VREPLACE --" and strand the
         * panel on screen forever, so treat a missing marker as "close". */
        if (payload === null || payload === "") {
            hide();
            return;
        }
        if (payload === lastPayload) return;
        lastPayload = payload;

        try {
            render(JSON.parse(decodeURIComponent(escape(atob(payload)))));
        } catch (e) {
            hide();
        }
    }

    function start() {
        var bar = document.querySelector(".statusbar") || document.body;
        new MutationObserver(scan).observe(bar, {
            childList: true,
            subtree: true,
            characterData: true,
        });
        scan();
    }

    if (document.querySelector(".statusbar")) {
        start();
    } else {
        var boot = new MutationObserver(function () {
            if (document.querySelector(".statusbar")) {
                boot.disconnect();
                start();
            }
        });
        boot.observe(document.documentElement, { childList: true, subtree: true });
    }
})();
