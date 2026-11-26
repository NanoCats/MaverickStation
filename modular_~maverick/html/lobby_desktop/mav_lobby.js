/* MaverickStation lobby desktop.
 *
 * The server writes a `window.MAV` settings object into the page before this
 * script loads. Clicks talk back to the server through byond:// links, and the
 * server calls the global hook functions near the bottom (toggle_ready etc).
 */
(function () {
	"use strict";

	var C = window.MAV || {};
	C.music = C.music || { enabled: false, tracks: [] };
	C.boot = C.boot || {};
	var started = false;

	// ------------------------------------------------------------- helpers

	// Links to the server wait until the page has finished loading. Following a link
	// while the page still loads can stop the rest of it from loading.
	var byond_queue = [];
	// Every link to the server goes through one queue, one at a time with a short gap.
	// Two links sent close together cancel each other in the browser, and only the last
	// one arrives. That was eating the desktop click sounds.
	var LINK_GAP_MS = 60;
	var link_busy = false;

	function byond(query) {
		byond_queue.push(query);
		pump_links();
	}

	function pump_links() {
		if (link_busy || !byond_queue.length || document.readyState === "loading") {
			return;
		}
		link_busy = true;
		var query = byond_queue.shift();
		if (C.preview) {
			C.preview(query);
		} else {
			location.href = "byond://?src=" + C.ref + ";" + query;
		}
		setTimeout(function () {
			link_busy = false;
			pump_links();
		}, LINK_GAP_MS);
	}
	document.addEventListener("DOMContentLoaded", pump_links);

	// ------------------------------------------------------------- desktop sounds

	// Like an old OS: a click when something opens, a chime on error boxes, a startup
	// sound once per round and a shutdown sound. The server checks the player's setting
	// too; checking here just saves sending links for nothing.
	var SFX_MODES = ["All", "Clicks only", "Off"];
	var sfx_mode = C.sfx || "All";
	var STARTUP_MS = 4300;

	// The page plays its own sounds, so a click sounds the moment it happens and the
	// boot screen can wait until they are loaded. The server sends the files with the
	// other lobby files. A sound that never loads is played by the server instead.
	// The startup sound is not here: it plays before the player has clicked anything, and
	// a page may not be allowed to play sound until then. The server always plays it.
	var SFX_FILES = {
		click: "desktop_click.ogg",
		error: "desktop_error.ogg",
		shutdown: "desktop_shutdown.ogg",
	};
	var SFX_RETRIES = 10;
	var sfx_audio = {};
	var sfx_loaded = {};
	var sfx_vol = +C.sfx_vol || 0;

	function load_sfx(kind, tries) {
		if (sfx_loaded[kind]) {
			return;
		}
		var a = new Audio();
		a.preload = "auto";
		a.addEventListener("canplaythrough", function () {
			sfx_loaded[kind] = true;
		});
		a.addEventListener("error", function () {
			if (tries < SFX_RETRIES) {
				after(400 * (tries + 1), function () { load_sfx(kind, tries + 1); });
			}
		});
		a.src = SFX_FILES[kind];
		a.load();
		sfx_audio[kind] = a;
	}
	Object.keys(SFX_FILES).forEach(function (kind) { load_sfx(kind, 0); });

	// The sounds this player's setting lets through
	function sfx_kinds() {
		if (sfx_mode === "Off") {
			return [];
		}
		if (sfx_mode !== "All") {
			return ["click", "error"];
		}
		return Object.keys(SFX_FILES);
	}

	function sfx_ready() {
		return sfx_kinds().every(function (kind) { return sfx_loaded[kind]; });
	}

	// Plays a sound here. Returns false if this page could not play it.
	function play_local(kind) {
		if (!sfx_loaded[kind]) {
			return false;
		}
		if (sfx_vol <= 0) {
			return true;
		}
		var a = sfx_audio[kind].cloneNode();
		a.volume = Math.min(1, sfx_vol / 100);
		var started = a.play();
		if (started && started.catch) {
			// the page wasn't allowed to play it, so the server plays it instead
			started.catch(function () {
				if (kind !== "shutdown") {
					byond("lobby_sfx=" + kind);
				}
			});
		}
		return true;
	}

	function sfx(kind) {
		if (sfx_kinds().indexOf(kind) < 0) {
			return;
		}
		if (!play_local(kind)) {
			byond("lobby_sfx=" + kind);
		}
	}

	function cycle_sfx_mode() {
		sfx_mode = SFX_MODES[(SFX_MODES.indexOf(sfx_mode) + 1) % SFX_MODES.length];
		byond("lobby_sfx_mode=1");
		return sfx_mode;
	}

	// The desktop is up. The first desktop of the round always tells the server, which
	// plays the startup sound and uses it up even when sounds are off, so it can't turn up
	// later in the round. If it is heard, the music waits for it.
	function desktop_ready() {
		// the welcome window (privacy policy and age check) waits for this, so it never covers the boot screen
		byond("lobby_desktop_up=1");
		if (C.startup_due) {
			C.startup_due = false;
			byond("lobby_sfx=startup");
			if (sfx_mode === "All" && sfx_vol > 0) {
				after(STARTUP_MS, music_hello);
				return;
			}
		}
		music_hello();
	}

	// Buttons click too: dialog buttons, title bar buttons, the taskbar, SpaceAmp
	var CLICKY = ".btn, .tbtn, .mbtn, #startbtn, .task, .amp_btn, .amp_tog, .amp_list div, .filelist div";
	document.addEventListener("mousedown", function (e) {
		if (e.button === 0 && e.target.closest && e.target.closest(CLICKY)) {
			sfx("click");
		}
	}, true);

	function el(tag, cls, parent, text) {
		var e = document.createElement(tag);
		if (cls) {
			e.className = cls;
		}
		if (text !== undefined) {
			e.textContent = text;
		}
		if (parent) {
			parent.appendChild(e);
		}
		return e;
	}

	// Pictures the page carries itself, as data URIs (see maverick_inline_images)
	var INLINE = C.inline || {};

	function img(src, cls, parent) {
		var e = el("img", cls, parent);
		src = INLINE[src] || src;
		e.dataset.src = src;
		e.src = src;
		e.draggable = false;
		return e;
	}

	// ------------------------------------------------------------- late files

	// The server sends the pictures in the background, so a picture can be asked for
	// before it has arrived and show as a broken image. Broken pictures try again a few
	// times, and again whenever the server says it has sent everything.
	var IMG_RETRIES = 8;
	var broken_imgs = [];

	function retry_img(e) {
		var name = e.dataset.src;
		if (!name) {
			return;
		}
		e.removeAttribute("src");
		e.src = name;
	}

	document.addEventListener("error", function (ev) {
		var e = ev.target;
		if (!e || e.tagName !== "IMG" || !e.dataset.src) {
			return;
		}
		var tries = +(e.dataset.tries || 0);
		if (broken_imgs.indexOf(e) < 0) {
			broken_imgs.push(e);
		}
		if (tries >= IMG_RETRIES) {
			return;
		}
		e.dataset.tries = tries + 1;
		after(300 * (tries + 1), function () { retry_img(e); });
	}, true);

	document.addEventListener("load", function (ev) {
		var i = broken_imgs.indexOf(ev.target);
		if (i >= 0) {
			broken_imgs.splice(i, 1);
		}
	}, true);

	// Pictures the stylesheet uses can't report an error, so each one is fetched on the
	// side. The browser remembers a stylesheet picture that failed and won't look again
	// at the same address, so one that turns up late goes back in with a new address.
	var CSS_IMAGES = ["mav_id_parts.png", "mav_tray_sound.png", "mav_sky_glyphs.png", "mav_starfield.png", "mav_paint_tools.png", "mav_amp_glyphs.png"];
	var css_missing = {};
	var css_fixed = {};

	function probe_css_image(name, tries) {
		var url = css_missing[name] ? name + "?v=" + (tries + 1) : name;
		var probe = new Image();
		probe.onload = function () {
			if (css_missing[name]) {
				delete css_missing[name];
				css_fixed[name] = url;
				reload_styles();
			}
		};
		probe.onerror = function () {
			css_missing[name] = true;
			if (tries < IMG_RETRIES) {
				after(300 * (tries + 1), function () { probe_css_image(name, tries + 1); });
			}
		};
		probe.src = url;
	}

	function reload_styles() {
		var old = document.querySelector("head style");
		if (!old) {
			return;
		}
		var text = old.textContent;
		Object.keys(css_fixed).forEach(function (name) {
			text = text.split('url("' + name + '")').join('url("' + css_fixed[name] + '")');
		});
		if (text !== old.textContent) {
			old.textContent = text;
		}
	}

	CSS_IMAGES.forEach(function (name) { probe_css_image(name, 0); });

	// The title bar buttons show on the boot screens, so their picture comes with the page too
	if (INLINE["mav_tbtn_glyphs.png"]) {
		el("style", null, document.head, '.tbtn { background-image: url("' + INLINE["mav_tbtn_glyphs.png"] + '"), none; }');
	}

	// The server calls this once every lobby file is on its way.
	window.lobby_files_sent = function () {
		broken_imgs.slice().forEach(function (e) {
			e.dataset.tries = 0;
			retry_img(e);
		});
		Object.keys(css_missing).forEach(function (name) { probe_css_image(name, 0); });
		Object.keys(SFX_FILES).forEach(function (kind) { load_sfx(kind, 0); });
	};

	function pick(list) {
		return list[Math.floor(Math.random() * list.length)];
	}

	function after(ms, fn) {
		return setTimeout(fn, ms);
	}

	var stage = document.getElementById("stage");
	// The desktop is designed for at least 480 x 270 art pixels. Wider windows get more
	// width; narrower (taller) windows get more sky above the wallpaper instead of cropping.
	var MIN_W = 480;
	var WALL_H = 270;
	var stage_w = MIN_W;
	var stage_h = WALL_H;
	var wall_y = 0;
	var scale = 1;

	function layout() {
		var vw = window.innerWidth;
		var vh = window.innerHeight;
		if (vw / vh >= MIN_W / WALL_H) {
			scale = vh / WALL_H;
			stage_w = Math.round(vw / scale);
			stage_h = WALL_H;
		} else {
			scale = vw / MIN_W;
			stage_w = MIN_W;
			stage_h = Math.round(vh / scale);
		}
		wall_y = stage_h - WALL_H;
		stage.style.width = stage_w + "px";
		stage.style.height = stage_h + "px";
		stage.style.transform = "scale(" + scale + ")";
		document.documentElement.style.setProperty("--art_px", scale + "px");
		var wall = document.getElementById("wall");
		if (wall) {
			wall.style.left = Math.round((stage_w - 640) / 2) + "px";
			wall.style.top = wall_y + "px";
		}
		place_icons();
		clamp_windows();
		layout_hooks.forEach(function (fn) { fn(); });
	}

	// things glued to the wallpaper re-place themselves after every layout
	var layout_hooks = [];

	// ------------------------------------------------------------- time of day

	// The player's own clock decides the sky.
	function time_slot(hour) {
		if (hour >= 22 || hour < 5) {
			return "night";
		}
		if (hour < 9) {
			return "dawn";
		}
		if (hour < 17) {
			return "day";
		}
		return "dusk";
	}

	var wall_imgs = [];
	var wall_front = 0;
	var current_slot = null;

	var SKY_TOP = { night: "#03041a", dawn: "#1a2a8a", day: "#0612a8", dusk: "#120c3a" };

	function build_wall(parent) {
		var wall = el("div", null, parent);
		wall.id = "wall";
		wall_imgs = [img("", null, wall), img("", null, wall)];
		wall_imgs[1].style.opacity = 0;
		update_sky(true);
		setInterval(update_sky, 15000);
		return wall;
	}

	function update_sky(instant) {
		var slot = time_slot(new Date().getHours());
		if (slot === current_slot) {
			return;
		}
		current_slot = slot;
		var src = "mav_wall_" + slot + ".png";
		// the sky above a tall window's wallpaper matches the wallpaper's top row
		stage.style.background = SKY_TOP[slot];
		if (instant === true) {
			wall_imgs[0].dataset.src = src;
			wall_imgs[0].src = src;
			return;
		}
		var back = 1 - wall_front;
		wall_imgs[back].dataset.src = src;
		wall_imgs[back].src = src;
		wall_imgs[back].style.opacity = 1;
		wall_imgs[wall_front].style.opacity = 0;
		wall_front = back;
	}

	// ------------------------------------------------------------- sky shapes

	// [x, w, h, twinkles] for each shape in mav_sky_glyphs.png
	var SKY_FRAMES = [[0, 32, 26, 0], [33, 32, 30, 0], [66, 16, 15, 0], [83, 15, 13, 0], [99, 11, 11, 1], [111, 11, 11, 1],
		[123, 11, 11, 1], [135, 11, 11, 1], [147, 12, 13, 0], [160, 11, 11, 1], [172, 16, 15, 0]];
	// Wallpaper art the shapes slip behind (wall coordinates): the wordmark, then the CRT.
	var SKY_COVERS = [[96, 14, 166, 52], C.crt_hotspot || [100, 105, 92, 96]];
	var sky_shapes = [];

	// A tall window shows sky above the wallpaper. Fill it with stars like the wallpaper's,
	// a few of them twinkling, so the sky doesn't just stop.
	function build_stars(sky) {
		var field = el("div", null, sky);
		field.id = "stars";
		function fill() {
			field.innerHTML = "";
			var count = Math.round(stage_w * wall_y / 110);
			for (var i = 0; i < count; i++) {
				var big = Math.random() < 0.12;
				var st = el("i", big ? "star big" : "star", field);
				st.style.left = Math.floor(Math.random() * stage_w) + "px";
				st.style.top = Math.floor(Math.random() * wall_y) + "px";
				var col = pick(["#ffffff", "#cfd8ff", "#8a96d8"]);
				st.style.background = col;
				if (big) {
					st.style.boxShadow = "1px 0 " + col + ", -1px 0 " + col + ", 0 1px " + col + ", 0 -1px " + col;
				}
				if (big || Math.random() < 0.15) {
					st.style.animationDelay = (-Math.random() * 4).toFixed(2) + "s";
					st.style.animationDuration = (2 + Math.random() * 3).toFixed(2) + "s";
					st.classList.add("twinkle");
				}
			}
		}
		var last_key = "";
		layout_hooks.push(function () {
			var key = stage_w + "x" + wall_y;
			if (key !== last_key) {
				last_key = key;
				fill();
			}
		});
	}

	// Now and then a tiny clown tumbles across a sky, far away. size is the sprite's size in px.
	function fly_clown(sky, size, seconds) {
		var w = sky.clientWidth;
		var h = sky.clientHeight;
		if (!w || !h) {
			return;
		}
		var c = img("mav_clown_S.png", "clown_fly", sky);
		c.style.width = size + "px";
		c.style.height = size + "px";
		var ltr = Math.random() < 0.5;
		var y0 = Math.random() * h * 0.6;
		var y1 = y0 + (Math.random() - 0.3) * h * 0.4;
		c.style.left = (ltr ? -size : w) + "px";
		c.style.top = Math.round(y0) + "px";
		c.style.animationDirection = ltr ? "normal" : "reverse";
		c.style.transition = "left " + seconds + "s linear, top " + seconds + "s linear";
		after(30, function () {
			c.style.left = (ltr ? w : -size) + "px";
			c.style.top = Math.round(y1) + "px";
		});
		after(seconds * 1000 + 200, function () { c.remove(); });
	}

	// Rolls for a flying clown every so often, while the sky is still on the page.
	function clown_sky_rolls(sky, size, seconds, chance, min_wait, max_wait) {
		(function roll() {
			after(min_wait + Math.random() * (max_wait - min_wait), function () {
				if (!sky.isConnected) {
					return;
				}
				if (!document.hidden && Math.random() < chance) {
					fly_clown(sky, size, seconds);
				}
				roll();
			});
		})();
	}

	// The neon shapes drift slowly across the sky, behind the windows, so some always peek out.
	function build_sky(parent) {
		var sky = el("div", null, parent);
		sky.id = "sky";
		build_stars(sky);
		// a distant clown, about one roll in eight, every half minute or so
		clown_sky_rolls(sky, 10, 5, 0.12, 20000, 40000);
		var order = [0, 1, 2, 3, 8, 10, 4, 5, 6, 7, 9, 4, 6, 9];
		for (var i = 0; i < order.length; i++) {
			var f = SKY_FRAMES[order[i]];
			var e = el("div", "sky_shape", sky);
			e.style.width = f[1] + "px";
			e.style.height = f[2] + "px";
			e.style.backgroundPosition = -f[0] + "px 0";
			sky_shapes.push({
				e: e, w: f[1], h: f[2], twinkle: f[3],
				x: Math.random() * stage_w,
				// 0 is the top of the window, 1 is just above the hills
				lane: Math.random(),
				speed: (1.5 + Math.random() * 3) * (Math.random() < 0.5 ? -1 : 1),
				bob: 1 + Math.random() * 3,
				period: 5 + Math.random() * 6,
				phase: Math.random() * 6.28,
				fade: 1,
			});
		}
		var last = null;
		function frame(now) {
			var dt = last === null ? 0 : Math.min(0.25, (now - last) / 1000);
			last = now;
			var t = now / 1000;
			var wall_x = Math.round((stage_w - 640) / 2);
			for (var j = 0; j < sky_shapes.length; j++) {
				var s = sky_shapes[j];
				s.x += s.speed * dt;
				if (s.x > stage_w + 4) {
					s.x = -s.w - 4;
				} else if (s.x < -s.w - 4) {
					s.x = stage_w + 4;
				}
				var x = Math.round(s.x);
				var y = Math.round(6 + s.lane * (wall_y + 172 - s.h - 6) + Math.sin(t * 6.28 / s.period + s.phase) * s.bob);
				// fade out while crossing the wordmark or the CRT, so they read as passing behind
				var hidden = false;
				for (var k = 0; k < SKY_COVERS.length; k++) {
					var c = SKY_COVERS[k];
					var cx = c[0] + wall_x;
					var cy = c[1] + wall_y;
					if (x < cx + c[2] && x + s.w > cx && y < cy + c[3] && y + s.h > cy) {
						hidden = true;
					}
				}
				s.fade = Math.max(0, Math.min(1, s.fade + (hidden ? -3 : 3) * dt));
				var glow = s.twinkle ? 0.55 + 0.45 * Math.abs(Math.sin(t * 1.7 + s.phase)) : 1;
				s.e.style.transform = "translate(" + x + "px," + y + "px)";
				s.e.style.opacity = (s.fade * glow).toFixed(2);
			}
			window.requestAnimationFrame(frame);
		}
		window.requestAnimationFrame(frame);
		return sky;
	}

	// ------------------------------------------------------------- lobby actions

	var ready = false;
	var antag = false;

	var ACTIONS = {
		ready: function () {
			byond(C.playing ? "late_join=1" : "toggle_ready=1");
		},
		observe: function () { byond("observe=1"); },
		manifest: function () { byond("view_manifest=1"); },
		directory: function () { byond("character_directory=1"); },
		setup: function () { byond("character_setup=1"); },
		options: function () { byond("game_options=1"); },
		antag: function () { byond("toggle_antag=1"); },
		servers: function () { byond("server_swap=1"); },
		traits: function () { byond("job_traits=1"); },
		polls: function () { byond("polls_menu=1"); },
	};

	function ready_label() {
		if (C.playing) {
			return "Join Game";
		}
		return ready ? "Ready: YES" : "Ready: NO";
	}

	// ------------------------------------------------------------- windows

	var wins = {};
	var z_top = 10;
	var save_timer = null;

	var WINDOWS = {
		station: {
			title: "station.exe", icon: "station", w: 190, h: 172,
			x: function () { return Math.round(stage_w / 2 - 120); }, y: 12,
			build: build_station,
		},
		paint: {
			title: "MSpacePaint.exe - Honk.bmp", icon: "paint", w: 168, h: 152,
			x: function () { return 6; }, y: 104,
			build: build_paint,
		},
		amp: {
			title: "SpaceAmp", icon: "music", w: 184, h: 112,
			x: function () { return 8; }, y: 6,
			build: build_amp,
		},
		readme: {
			title: "readme.txt - Notepad", icon: "readme", w: 170, h: 120,
			x: function () { return Math.round(stage_w / 2 - 40); }, y: 40,
			build: build_readme,
		},
		recycle: {
			title: "Recycle Bin", icon: "recycle", w: 150, h: 112,
			x: function () { return Math.round(stage_w / 2 - 20); }, y: 70,
			build: build_recycle,
		},
	};

	function make_window(id, spec, opts) {
		opts = opts || {};
		var w = el("div", "win" + (opts.cls ? " " + opts.cls : ""), document.getElementById("windows"));
		w.style.width = spec.w + "px";
		if (spec.h) {
			w.style.height = spec.h + "px";
		}
		w.style.left = (typeof spec.x === "function" ? spec.x() : spec.x) + "px";
		w.style.top = spec.y + "px";
		var bar = el("div", "titlebar", w);
		if (spec.icon) {
			img("mav_icon_" + spec.icon + ".png", null, bar);
		}
		el("span", "ttl", bar, spec.title);
		var buttons = opts.buttons || ["min", "max", "close"];
		buttons.forEach(function (b) {
			var t = el("div", "tbtn tbtn_" + b, bar);
			t.addEventListener("mousedown", function (e) { e.stopPropagation(); });
			t.addEventListener("click", function (e) {
				e.stopPropagation();
				if (opts.on_button) {
					opts.on_button(b);
					return;
				}
				if (b === "min") { minimize(id); }
				if (b === "max") { toggle_max(id); }
				if (b === "close") { close_window(id); }
			});
		});
		drag(w, bar, id);
		w.addEventListener("mousedown", function () { focus(id); });
		return w;
	}

	function open_window(id) {
		if (wins[id]) {
			wins[id].el.classList.remove("min");
			focus(id);
			queue_save();
			return wins[id];
		}
		var spec = WINDOWS[id];
		var w = make_window(id, spec);
		var body = el("div", "body", w);
		wins[id] = { el: w, spec: spec, body: body };
		spec.build(body, wins[id]);
		focus(id);
		update_taskbar();
		queue_save();
		return wins[id];
	}

	function close_window(id) {
		var win = wins[id];
		if (!win) {
			return;
		}
		if (win.on_close) {
			win.on_close();
		}
		win.el.remove();
		delete wins[id];
		update_taskbar();
		queue_save();
	}

	function minimize(id) {
		wins[id].el.classList.add("min");
		update_taskbar();
		queue_save();
	}

	function toggle_max(id) {
		wins[id].el.classList.toggle("max");
		queue_save();
	}

	function focus(id) {
		var win = wins[id] || dialogs[id];
		if (!win) {
			return;
		}
		win.el.style.zIndex = ++z_top;
		Object.keys(wins).forEach(function (k) {
			wins[k].el.classList.toggle("inactive", k !== id);
		});
		update_taskbar(id);
	}

	function drag(w, handle, id) {
		handle.addEventListener("mousedown", function (e) {
			if (w.classList.contains("max") || w.dataset.locked) {
				return;
			}
			var sx = e.clientX;
			var sy = e.clientY;
			var ox = w.offsetLeft;
			var oy = w.offsetTop;
			function move(ev) {
				w.style.left = Math.round(ox + (ev.clientX - sx) / scale) + "px";
				w.style.top = Math.round(oy + (ev.clientY - sy) / scale) + "px";
			}
			function up() {
				document.removeEventListener("mousemove", move);
				document.removeEventListener("mouseup", up);
				clamp_one(w);
				queue_save();
			}
			document.addEventListener("mousemove", move);
			document.addEventListener("mouseup", up);
		});
	}

	function clamp_one(w) {
		var x = Math.min(Math.max(w.offsetLeft, -w.offsetWidth + 30), stage_w - 30);
		var y = Math.min(Math.max(w.offsetTop, 0), stage_h - 30);
		w.style.left = x + "px";
		w.style.top = y + "px";
	}

	function clamp_windows() {
		Object.keys(wins).forEach(function (k) { clamp_one(wins[k].el); });
	}

	// Window layout survives page reloads: the server keeps it for the session.
	function queue_save() {
		if (C.classic || C.mode !== "lobby") {
			return;
		}
		clearTimeout(save_timer);
		save_timer = after(700, function () {
			var order = Object.keys(wins).sort(function (a, b) {
				return (+wins[a].el.style.zIndex) - (+wins[b].el.style.zIndex);
			});
			var state = order.map(function (k) {
				var w = wins[k].el;
				return {
					id: k, x: w.offsetLeft, y: w.offsetTop,
					min: w.classList.contains("min") ? 1 : 0, max: w.classList.contains("max") ? 1 : 0,
				};
			});
			byond("desktop_state=" + encodeURIComponent(JSON.stringify(state)));
		});
	}

	function restore_windows() {
		var saved = null;
		try {
			saved = C.desktop ? (typeof C.desktop === "string" ? JSON.parse(C.desktop) : C.desktop) : null;
		} catch (e) {
			saved = null;
		}
		if (!saved || !saved.length) {
			saved = [{ id: "amp" }];
		}
		saved.forEach(function (s) {
			if (!WINDOWS[s.id]) {
				return;
			}
			var win = open_window(s.id);
			if (s.x !== undefined) {
				win.el.style.left = s.x + "px";
				win.el.style.top = s.y + "px";
			}
			if (s.max) {
				win.el.classList.add("max");
			}
			if (s.min) {
				win.el.classList.add("min");
			}
		});
		clamp_windows();
		update_taskbar();
	}

	// ------------------------------------------------------------- dialogs

	var dialogs = {};
	var dialog_seq = 0;

	// opts: title, text, icon ("err" | image name), buttons [{label, fn}], x, y, w, big, on_x, cls
	function dialog(opts) {
		var id = "dlg" + (++dialog_seq);
		var spec = {
			title: opts.title, icon: opts.title_icon, w: opts.w || 170, h: null,
			x: opts.x !== undefined ? opts.x : Math.round(stage_w / 2 - (opts.w || 170) / 2),
			y: opts.y !== undefined ? opts.y : 80,
		};
		var close = function () {
			if (dialogs[id]) {
				dialogs[id].el.remove();
				delete dialogs[id];
			}
		};
		var w = make_window(id, spec, {
			cls: "dlg" + (opts.big ? " big_dlg" : "") + (opts.cls ? " " + opts.cls : ""),
			buttons: ["close"],
			on_button: function () {
				if (opts.on_x) {
					opts.on_x(close);
				} else {
					close();
				}
			},
		});
		var body = el("div", "body", w);
		if (opts.icon === "err") {
			img("mav_icon_err.png", "err_x", body);
			if (!opts.silent) {
				sfx("error");
			}
		} else if (opts.icon) {
			img(opts.icon, "dicon", body);
		}
		var text = el("div", "dtext", body);
		if (opts.html) {
			text.innerHTML = opts.html;
		} else {
			text.textContent = opts.text;
		}
		var btns = el("div", "dbtns", w);
		(opts.buttons || [{ label: "OK" }]).forEach(function (b) {
			var bt = el("div", "btn", btns, b.label);
			bt.addEventListener("click", function () {
				if (b.fn) {
					b.fn(close);
				} else {
					close();
				}
			});
		});
		dialogs[id] = { el: w, close: close };
		w.style.zIndex = ++z_top;
		w.addEventListener("mousedown", function () { w.style.zIndex = ++z_top; });
		return dialogs[id];
	}

	// ------------------------------------------------------------- station.exe

	var station_refs = {};

	function station_menu(body) {
		body.classList.add("station_body");
		var head = el("div", "station_head", body);
		img("mav_wordmark.png", "wm", head);
		var menu = el("div", null, body);
		function item(label, action, cls) {
			var b = el("a", "mbtn" + (cls ? " " + cls : ""), menu);
			b.innerHTML = label;
			b.addEventListener("click", function () { ACTIONS[action](); });
			return b;
		}
		if (C.playing) {
			station_refs.ready = item("JOIN GAME", "ready");
			item("CREW MANIFEST", "manifest");
		} else {
			station_refs.ready = item("", "ready");
		}
		item("CHARACTER DIRECTORY", "directory");
		item("OBSERVE", "observe");
		el("hr", null, menu);
		station_refs.setup = item("", "setup");
		item("GAME OPTIONS", "options");
		station_refs.antag = item("", "antag");
		if (C.servers || C.traits || C.polls) {
			el("hr", null, menu);
		}
		if (C.servers) {
			item("SWAP SERVERS", "servers");
		}
		if (C.traits) {
			item("JOB TRAITS", "traits");
		}
		if (C.polls) {
			item(C.polls === "new" ? "POLLS (NEW)" : "POLLS", "polls", C.polls === "new" ? "newpoll" : "");
		}
		refresh_station();
	}

	// station.exe: the station drifts slowly across its starfield, with a few glowing shapes.
	function build_station(body) {
		var bg = el("div", "station_sky", body);
		for (var n = 0; n < 26; n++) {
			var st = el("i", "twinkle_star", bg);
			st.style.left = Math.floor(Math.random() * 180) + "px";
			st.style.top = Math.floor(Math.random() * 160) + "px";
			st.style.animationDelay = (-Math.random() * 4).toFixed(2) + "s";
			st.style.animationDuration = (1.8 + Math.random() * 2.6).toFixed(2) + "s";
			if (Math.random() < 0.3) {
				st.classList.add("big");
			}
		}
		var drift = img("mav_station.png", "station_drift", bg);
		// start partway along its path so it is already on screen when the window opens
		drift.style.animationDelay = "-" + (19 + Math.random() * 31).toFixed(1) + "s, 0s";
		clown_sky_rolls(bg, 12, 3.5, 0.15, 10000, 20000);
		[[9, 18, 70], [4, 150, 96], [6, 40, 150], [10, 128, 40], [5, 88, 128]].forEach(function (g, i) {
			var f = SKY_FRAMES[g[0]];
			var e = el("div", "station_glint", bg);
			e.style.width = f[1] + "px";
			e.style.height = f[2] + "px";
			e.style.backgroundPosition = -f[0] + "px 0";
			e.style.left = g[1] + "px";
			e.style.top = g[2] + "px";
			e.style.animationDelay = (-i * 1.3) + "s";
		});
		station_menu(body);
	}

	function refresh_station() {
		if (station_refs.ready && !C.playing) {
			station_refs.ready.innerHTML = ready
				? "<span class='checked'>☑</span> READY"
				: "<span class='unchecked'>☒</span> READY";
		}
		if (station_refs.setup) {
			station_refs.setup.innerHTML = "SETUP CHARACTER (<span></span>)";
			station_refs.setup.querySelector("span").textContent = (C.name || "").toUpperCase();
		}
		if (station_refs.antag) {
			station_refs.antag.innerHTML = antag
				? "<span class='checked'>☑</span> BE ANTAGONIST"
				: "<span class='unchecked'>☒</span> BE ANTAGONIST";
		}
		var icon = icon_refs.ready;
		if (icon) {
			icon.querySelector(".label").textContent = ready_label();
		}
	}

	// ------------------------------------------------------------- notepad, recycle bin

	var README = [
		"NANOTRASEN STANDARD CREW TERMINAL",
		"AeriOS 4.0 (build 2566.11), crew edition",
		"",
		"This terminal is Nanotrasen property. Your use of it is logged, reviewed and occasionally laughed at.",
		"",
		"KNOWN ISSUES",
		"",
		"* Clown.exe is not authorized Nanotrasen software. Do not run it. Do not attempt to remove it either. I have no fucking idea who put this here, but when I deleted it the computer wouldn't start. We tried downloading an antivirus and it just screamed and deleted itself(?) Words cannot describe my fucking confusion.",
		"* SpaceAmp music is provided by a third party. We have no control over the playlist or its apparent ability to predict station events. Please stop asking.",
		"* The clock shows your local time, not station time.",
		"* The presence of games and recreational software does not constitute permission to use them during working hours.",
		"",
		"SUPPORT",
		"",
		"For technical assistance, contact your Head of Personnel. If your Head of Personnel is the problem, contact the Captain. If the Captain is the problem, please submit form 690-L (Formal deathsquad request) and associates will arrive shortly to \"solve\" the problem.",
		"If your issue concerns clown.exe, we already know god damn it.",
		"",
		"(C) 2566 Aeri Consultations and Services, under license to Nanotrasen. All rights reserved.",
	].join("\n");

	function build_readme(body) {
		var box = el("div", "sunken notepad", body);
		box.style.height = "100%";
		box.textContent = README;
	}

	// The Shotgun Manifesto: an old ban appeal the community never let die. Not endorsed
	// conduct, which is why it lives in the recycle bin. Kept word for word.
	var MANIFESTO = "I used the shotgun. You know why? Cause the shot gun doesn\u2019t miss: and unlike the shitty hybrid taser it stops a criminal in their tracks in two hits. Bang: bang: and they\u2019re fucking done. I use four shots just to make damn sure. Because: once again: I\u2019m not there to coddle a buncha criminal scum sucking *******: I\u2019m there to 1) Survive the fucking round. 2) Guard the armory. So you can absolutely get fucked. If I get unbanned: which I won\u2019t: you can guarantee I will continue to use the shotgun to apprehend criminals. Because it\u2019s quick: clean and effective as fuck. Why in the seven hells would I fuck around with the disabler shots: which take half a clip just to bring someone down: or with the tazer bolts which are slow as balls: impossible to aim and do about next to jack shit: fuck all. The shotgun is the superior law enforcement weapon. Because it stops crime. And it stops crime by reducing the number of criminals roaming the fucking halls.";

	var BIN = [
		["Shotgun_manifesto.txt", "4 KB", MANIFESTO],
		["my_will_to_live.txt", "0 KB"],
		["nuke_disk (2).lnk", "1 KB"],
		["clown_permission_slip.pdf", "12 KB"],
		["atmos_was_fine_actually.doc", "3 KB"],
		["captains_spare_id.jpg", "88 KB"],
		["supermatter_manual.txt", "0 KB"],
		["NOT_A_VIRUS.exe", "666 KB"],
	];

	// Why a deleted file can't come back. Each file gets its own reason.
	var BIN_REFUSALS = [
		"Restore failed: this file was deleted under Nanotrasen Records Retention Policy 7.2 (Plausible Deniability). It never existed.",
		"Restore failed: this file has been reassigned to Lavaland.",
		"Restore failed: a Nanotrasen representative is already reading this file. Please wait your turn.",
		"Restore failed: this file went down the disposals chute and is now somewhere in Cargo.",
	];

	function build_recycle(body) {
		var tb = el("div", "toolbar", body);
		var empty = el("div", "btn", tb, "Empty Recycle Bin");
		empty.addEventListener("click", function () {
			dialog({
				title: "Recycle Bin", icon: "mav_icon_clown.png",
				text: "Cannot empty the Recycle Bin. Someone is living in it.",
			});
		});
		var list = el("div", "sunken filelist", body);
		list.style.height = "calc(100% - 14px)";
		list.style.overflowY = "auto";
		BIN.forEach(function (f, i) {
			var row = el("div", null, list);
			el("span", null, row, f[0]);
			el("span", "sz", row, f[1]);
			row.addEventListener("dblclick", function () {
				// the manifesto keeps finding its way back, so it still opens
				if (f[2]) {
					var d = dialog({ title: f[0] + " - Notepad", w: 210, y: 24, html: "<div class='sunken notepad manifesto'></div>", buttons: [{ label: "Close" }] });
					d.el.querySelector(".manifesto").textContent = f[2];
					return;
				}
				dialog({ title: f[0], icon: "err", text: BIN_REFUSALS[(i - 1) % BIN_REFUSALS.length] });
			});
		});
	}

	// ------------------------------------------------------------- MSpacePaint

	var PAINT_COLORS = [
		"#000000", "#808080", "#800000", "#808000", "#008000", "#008080", "#000080", "#800080", "#808040", "#004040", "#0080ff", "#004080", "#8000ff", "#804000",
		"#ffffff", "#c0c0c0", "#ff0000", "#ffff00", "#00ff00", "#00ffff", "#0000ff", "#ff00ff", "#ffff80", "#00ff80", "#80ffff", "#8080ff", "#ff0080", "#ff8040",
	];

	// The crude clown, as pencil strokes on a 120x84 canvas.
	function clown_strokes() {
		var s = [];
		function circle(cx, cy, r, color, n, wob) {
			var pts = [];
			for (var i = 0; i <= n; i++) {
				var a = i / n * Math.PI * 2 - 0.4;
				var rr = r + (wob ? Math.sin(i * 1.7) * wob : 0);
				pts.push([cx + Math.cos(a) * rr, cy + Math.sin(a) * rr * 0.95]);
			}
			s.push({ c: color, w: 1, p: pts });
		}
		// hair tufts, scribbled
		[[30, 30], [90, 30]].forEach(function (h) {
			var pts = [];
			for (var i = 0; i < 26; i++) {
				var a = i * 0.9;
				pts.push([h[0] + Math.cos(a) * (6 + i * 0.25), h[1] + Math.sin(a) * (5 + i * 0.2) + i * 0.4]);
			}
			s.push({ c: "#ff8040", w: 2, p: pts });
		});
		circle(60, 42, 21, "#000000", 28, 1.2);                       // head
		circle(51, 37, 3, "#0000ff", 8, 0);                           // eyes
		circle(69, 37, 3, "#0000ff", 8, 0);
		s.push({ c: "#000000", w: 1, p: [[49, 31], [54, 32]] });      // brows
		s.push({ c: "#000000", w: 1, p: [[66, 32], [71, 31]] });
		for (var r = 5; r >= 1; r -= 1) {                             // nose, coloured in
			circle(60, 45, r, "#ff0000", 10, 0);
		}
		s.push({ c: "#ff0000", w: 2, p: [[46, 51], [50, 56], [56, 59], [64, 59], [70, 56], [74, 51]] });
		s.push({ c: "#ff0000", w: 1, p: [[50, 55], [60, 58], [70, 55]] });
		// HONK, badly
		var letters = [
			[[90, 62], [90, 74]], [[90, 68], [95, 68]], [[95, 62], [95, 74]],
			[[98, 62], [102, 62], [102, 74], [98, 74], [98, 62]],
			[[105, 74], [105, 62], [110, 74], [110, 62]],
			[[113, 62], [113, 74]], [[118, 62], [113, 68], [118, 74]],
		];
		letters.forEach(function (l) { s.push({ c: "#ff00ff", w: 1, p: l }); });
		s.push({ c: "#000000", w: 1, p: [[60, 63], [58, 70], [62, 76], [60, 82]] }); // neck squiggle
		return s;
	}

	function build_paint(body, win) {
		var wrap = el("div", "paint_wrap", body);
		var menu = el("div", "menubar", body.parentNode);
		["File", "Edit", "View", "Image", "Options", "Help"].forEach(function (m) { el("span", null, menu, m); });
		body.parentNode.insertBefore(menu, body);
		var main = el("div", "paint_main", wrap);
		var tools = el("div", "paint_tools", main);
		var tool_els = [];
		for (var i = 0; i < 16; i++) {
			var t = el("div", "tool", tools);
			t.style.backgroundPosition = (-(i % 2) * 12) + "px " + (-Math.floor(i / 2) * 12) + "px";
			tool_els.push(t);
		}
		var cw = el("div", "paint_canvas_wrap", main);
		var canvas = el("canvas", null, cw);
		canvas.width = 120;
		canvas.height = 84;
		canvas.style.width = "120px";
		canvas.style.height = "84px";
		var cursor = el("div", "paint_cursor", cw);
		cursor.style.background = "url(mav_paint_tools.png) -12px -48px";
		var pal = el("div", "paint_palette", wrap);
		var cur = el("div", "cur", pal);
		var fg = el("i", null, cur);
		fg.style.left = "2px";
		fg.style.top = "2px";
		var bg = el("i", null, cur);
		bg.style.left = "6px";
		bg.style.top = "6px";
		bg.style.background = "#fff";
		var cols = el("div", "col", pal);
		PAINT_COLORS.forEach(function (c) {
			el("div", "sw", cols).style.background = c;
		});
		var status = el("div", "paint_status", wrap, "For Help, click Help Topics on the Help Menu.");

		var ctx = canvas.getContext("2d");
		var strokes = clown_strokes();
		var si = 0;
		var pi = 0;
		var t = 0;
		var last = null;
		var timer = null;

		function dot(x, y, c, w) {
			ctx.fillStyle = c;
			ctx.fillRect(Math.round(x), Math.round(y), w, w);
		}

		function reset() {
			ctx.fillStyle = "#fff";
			ctx.fillRect(0, 0, 120, 84);
			si = 0;
			pi = 0;
			t = 0;
			last = null;
		}

		function step() {
			if (si >= strokes.length) {
				clearInterval(timer);
				status.textContent = "Honk.bmp saved. Masterpiece.";
				timer = null;
				after(5000, function () {
					if (!wins.paint) {
						return;
					}
					status.textContent = "For Help, click Help Topics on the Help Menu.";
					reset();
					timer = setInterval(step, 30);
				});
				return;
			}
			var st = strokes[si];
			fg.style.background = st.c;
			tool_els.forEach(function (te, k) { te.classList.toggle("on", k === (st.w > 1 ? 13 : 9)); });
			var a = st.p[pi];
			var b = st.p[pi + 1];
			if (!b) {
				si++;
				pi = 0;
				t = 0;
				last = null;
				return;
			}
			var len = Math.max(1, Math.hypot(b[0] - a[0], b[1] - a[1]));
			for (var k = 0; k < 2; k++) {
				t += 1 / len;
				if (t >= 1) {
					t = 0;
					pi++;
					break;
				}
				var x = a[0] + (b[0] - a[0]) * t;
				var y = a[1] + (b[1] - a[1]) * t;
				dot(x, y, st.c, st.w);
				cursor.style.left = (3 + Math.round(x)) + "px";
				cursor.style.top = (3 + Math.round(y) - 11) + "px";
			}
		}

		reset();
		timer = setInterval(step, 30);
		win.on_close = function () { clearInterval(timer); };
	}

	// ------------------------------------------------------------- SpaceAmp

	var amp = null;

	// The track clock and the repeat mode live outside the SpaceAmp window, so the
	// playlist keeps going and repeat keeps its setting while the window is closed.
	var amp_clock = { elapsed: C.music.elapsed || 0, last: Date.now(), ended_sent: false };
	var amp_repeat = "all";
	var REPEAT_LABEL = { all: "RPT ALL", one: "RPT ONE", off: "RPT OFF" };
	var REPEAT_TIP = {
		all: "Repeat: the whole playlist. Click to repeat this song.",
		one: "Repeat: this song. Click to turn repeat off.",
		off: "Repeat: off, music stops after this song. Click to repeat the playlist.",
	};

	function music_clock_tick() {
		var M = C.music;
		var now = Date.now();
		// the clock waits for the desktop, since the music does too
		if (music_live && M.playing && !M.paused) {
			amp_clock.elapsed += (now - amp_clock.last) / 1000;
		}
		amp_clock.last = now;
		if (music_live && M.playing && !M.paused && M.len && amp_clock.elapsed >= M.len && !amp_clock.ended_sent) {
			amp_clock.ended_sent = true;
			byond("music=ended;repeat=" + amp_repeat);
		}
	}
	if (C.music.enabled) {
		setInterval(music_clock_tick, 100);
	}

	function fmt_time(s) {
		s = Math.max(0, Math.floor(s));
		var m = Math.floor(s / 60);
		var r = s % 60;
		return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r;
	}

	function build_amp(body, win) {
		body.classList.add("amp_body");
		var M = C.music;
		if (!M.enabled) {
			el("div", "amp_off", body, "Lobby music is switched off in this server's config. SpaceAmp is sad.");
			return;
		}
		var lcd = el("div", "amp_lcd", body);
		var time = el("div", "amp_time", lcd, "00:00");
		var marquee = el("div", "amp_marquee", lcd);
		var marquee_text = el("span", null, marquee);
		el("div", "amp_info", lcd, "128kbps");
		var spec = el("canvas", null, lcd);
		spec.width = 38;
		spec.height = 14;
		spec.style.width = "38px";
		spec.style.height = "14px";
		var seek = el("div", "amp_seek", body);
		var seek_fill = el("i", null, seek);
		var row = el("div", "amp_row", body);
		var glyph = { prev: 0, play: 1, pause: 2, stop: 3, next: 4 };
		var btns = {};
		["prev", "play", "pause", "stop", "next"].forEach(function (b) {
			var e = el("div", "amp_btn", row);
			e.style.backgroundPosition = (-glyph[b] * 12) + "px 0";
			e.title = b;
			e.addEventListener("click", function () { amp_cmd(b); });
			btns[b] = e;
		});
		var vol = el("div", "amp_vol", row);
		var vol_fill = el("i", null, vol);
		var vol_knob = el("b", null, vol);
		var rpt = el("div", "amp_tog", row, REPEAT_LABEL[amp_repeat]);
		rpt.title = REPEAT_TIP[amp_repeat];
		// Shuffle lives on the server, since the server picks the next track. This only asks it to flip.
		var shuf = el("div", "amp_tog", row, "SHUF");
		shuf.title = "Shuffle: play the playlist in random order. Click to toggle.";
		shuf.addEventListener("click", function () { byond("music=shuffle"); });
		var list = el("div", "amp_list", body);

		amp = {
			time: time, marquee_text: marquee_text, seek_fill: seek_fill, vol_fill: vol_fill, vol_knob: vol_knob,
			btns: btns, list: list, rpt: rpt, shuf: shuf, spec: spec,
		};

		rpt.classList.toggle("on", amp_repeat !== "off");
		rpt.addEventListener("click", function () {
			amp_repeat = { all: "one", one: "off", off: "all" }[amp_repeat];
			rpt.textContent = REPEAT_LABEL[amp_repeat];
			rpt.title = REPEAT_TIP[amp_repeat];
			rpt.classList.toggle("on", amp_repeat !== "off");
		});
		seek.addEventListener("click", function (e) {
			if (!M.len) {
				return;
			}
			var r = e.offsetX / seek.offsetWidth;
			byond("music=seek;pos=" + Math.floor(r * M.len));
		});
		var vol_timer = null;
		function set_vol_from(e) {
			var r = Math.min(1, Math.max(0, (e.clientX - vol.getBoundingClientRect().left) / (vol.offsetWidth * scale)));
			M.vol = Math.round(r * 100);
			amp.vol_label = "VOLUME: " + M.vol + "%";
			draw_amp();
			clearTimeout(vol_timer);
			vol_timer = after(250, function () { byond("music=vol;vol=" + M.vol); });
		}
		vol.addEventListener("mousedown", function (e) {
			set_vol_from(e);
			function mv(ev) { set_vol_from(ev); }
			function up() {
				document.removeEventListener("mousemove", mv);
				document.removeEventListener("mouseup", up);
				if (amp) {
					amp.vol_label = null;
					draw_amp();
				}
			}
			document.addEventListener("mousemove", mv);
			document.addEventListener("mouseup", up);
		});

		draw_amp(true);
		var tick = setInterval(amp_tick, 100);
		win.on_close = function () {
			clearInterval(tick);
			amp = null;
		};
	}

	function amp_cmd(b) {
		var M = C.music;
		// Pressing SpaceAmp during the startup sound asks for this player's track first.
		// Waiting let the play start the default track, which then switched by itself.
		if (!music_live) {
			music_hello();
			// the hello starts a track by itself unless the music is off
			if (b === "play" && C.music.playing) {
				return;
			}
		}
		if (b === "play") {
			byond(M.paused ? "music=resume" : "music=play");
		} else if (b === "pause") {
			byond(M.paused ? "music=resume" : "music=pause");
		} else {
			byond("music=" + b);
		}
	}

	function draw_amp(rebuild_list) {
		if (!amp) {
			return;
		}
		var M = C.music;
		var t = M.tracks[M.index] || { title: "Nothing" };
		var label = (M.index + 1) + ". " + t.title + "  ***  " + (M.playing ? (M.paused ? "PAUSED" : "It really whips the clown's ass.") : "STOPPED");
		// while the volume slider is held, the display shows the volume instead, held still
		amp.marquee_text.parentNode.classList.toggle("held", !!amp.vol_label);
		if (amp.vol_label) {
			label = amp.vol_label;
		}
		if (amp.marquee_text.textContent !== label) {
			amp.marquee_text.textContent = label;
		}
		amp.time.classList.toggle("paused", !!M.paused);
		amp.btns.play.classList.toggle("on", M.playing && !M.paused);
		amp.btns.pause.classList.toggle("on", !!M.paused);
		amp.shuf.classList.toggle("on", !!M.shuffle);
		amp.vol_fill.style.width = M.vol + "%";
		amp.vol_knob.style.left = M.vol + "%";
		if (rebuild_list) {
			amp.list.innerHTML = "";
			M.tracks.forEach(function (tr, i) {
				var row = el("div", i === M.index ? "cur" : "", amp.list, (i + 1) + ". " + tr.title);
				row.addEventListener("dblclick", function () { byond("music=track;track=" + (i + 1)); });
			});
		}
		// Like Winamp: when the track changes, scroll the playlist so the new one sits in the middle.
		// Only on a change, so it does not fight someone scrolling the list by hand.
		// clientHeight is 0 until the window is laid out; try again on the next draw instead of giving up.
		if (M.index !== amp.shown_index && amp.list.clientHeight) {
			amp.shown_index = M.index;
			var cur = amp.list.children[M.index];
			if (cur) {
				var list_box = amp.list.getBoundingClientRect();
				var row_box = cur.getBoundingClientRect();
				amp.list.scrollTop += (row_box.top - list_box.top) - (amp.list.clientHeight - row_box.height) / 2;
			}
		}
	}

	var spec_levels = [];
	function amp_tick() {
		if (!amp) {
			return;
		}
		var M = C.music;
		var now = Date.now();
		var shown = M.len ? Math.min(amp_clock.elapsed, M.len) : amp_clock.elapsed;
		amp.time.textContent = M.playing ? fmt_time(shown) : "00:00";
		amp.seek_fill.style.width = M.len && M.playing ? (100 * shown / M.len) + "%" : "0%";
		// fake spectrum, it just needs to look busy
		var ctx = amp.spec.getContext("2d");
		ctx.clearRect(0, 0, 38, 14);
		for (var i = 0; i < 12; i++) {
			var target = (M.playing && !M.paused) ? Math.random() * (14 - i * 0.6) * (0.5 + 0.5 * Math.sin(now / 240 + i)) : 0;
			spec_levels[i] = Math.max(target, (spec_levels[i] || 0) - 1.5);
			var h = Math.round(spec_levels[i]);
			for (var y = 0; y < h; y++) {
				ctx.fillStyle = y > 10 ? "#e03a3a" : (y > 7 ? "#ffe066" : "#5fff5f");
				ctx.fillRect(i * 3 + 1, 13 - y, 2, 1);
			}
		}
	}

	// ------------------------------------------------------------- desktop icons

	var icon_refs = {};
	var icon_list = [];

	function icon_defs() {
		var list = [
			{ id: "station", label: "station.exe", icon: "station", open: function () { open_window("station"); } },
			{ id: "ready", label: ready_label(), icon: "join", open: ACTIONS.ready },
			{ id: "observe", label: "Observe", icon: "observe", open: ACTIONS.observe },
			{ id: "setup", label: "Setup Character", icon: "setup", open: ACTIONS.setup },
			{ id: "options", label: "Game Options", icon: "options", open: ACTIONS.options },
			{ id: "directory", label: "Personnel Files", icon: "directory", open: ACTIONS.directory },
			{ id: "amp", label: "SpaceAmp", icon: "music", open: function () { open_window("amp"); } },
			{ id: "paint", label: "MSpacePaint", icon: "paint", open: function () { open_window("paint"); } },
			{ id: "readme", label: "readme.txt", icon: "readme", open: function () { open_window("readme"); } },
			{ id: "clown", label: "Clown.exe (NEVER OPEN)", icon: "clown", open: clown_exe },
			{ id: "recycle", label: "Recycle Bin", icon: "recycle", open: function () { open_window("recycle"); } },
		];
		if (C.playing) {
			list.splice(2, 0, { id: "manifest", label: "Crew Manifest", icon: "manifest", open: ACTIONS.manifest });
		}
		if (C.servers) {
			list.push({ id: "servers", label: "Swap Servers", icon: "servers", open: ACTIONS.servers });
		}
		if (C.traits) {
			list.push({ id: "traits", label: "Job Traits", icon: "traits", open: ACTIONS.traits });
		}
		if (C.cheats) {
			list.push({ id: "cheats", label: "Cheat Engine", icon: "cheats", open: function () { byond("open_cheats=1"); } });
		}
		if (C.polls) {
			list.push({ id: "polls", label: C.polls === "new" ? "Polls (NEW)" : "Polls", icon: "polls", open: ACTIONS.polls });
		}
		return list;
	}

	function build_icons(parent) {
		var box = el("div", null, parent);
		box.id = "icons";
		icon_defs().forEach(function (d) {
			var ic = el("div", "icon", box);
			img("mav_icon_" + d.icon + ".png", null, ic);
			el("span", "label", ic, d.label);
			ic.addEventListener("mousedown", function (e) {
				e.stopPropagation();
				select_icon(d.id);
			});
			if (d.id === "setup") {
				chameleon_id(ic);
			}
			ic.addEventListener("dblclick", function () {
				if (d.id === "clown") {
					clown_icon_honk();
				} else {
					sfx("click");
				}
				d.open();
			});
			icon_refs[d.id] = ic;
			icon_list.push(ic);
		});
		parent.addEventListener("mousedown", function (e) {
			if (e.target === parent || e.target.id === "wall" || e.target.parentNode.id === "wall") {
				select_icon(null);
			}
		});
	}

	// Setup Character is a chameleon ID card. Every ten seconds or so it glitches for a
	// moment, then settles on a new random station card back and job trim.
	// mav_id_parts.png, 32px cells. Row 0: the card backs. Row 1: the job icons.
	// Row 2: the department box, the head of staff box and the stripe, all white.
	// Backs: every advanced card with the standard station shape. Basic cards like the
	// retro one can't hold a trim in game, so they stay out. Trims: every job, CentCom,
	// Syndicate and prisoner trim. Prisoner number trims only go on the prisoner card back.
	var ID_BACKS = 10;
	var ID_PRISONER_BACK = 6;
	var ID_PRISONER_TRIMS = [33, 34, 35, 36, 37, 38, 39];
	var ID_MASK_DEPT = 0;
	var ID_MASK_HEAD = 1;
	var ID_MASK_STRIPE = 2;

	// Every trim the game draws with these icons: [icon, box color, stripe color, head of staff]
	var ID_LOOKS = [
		[0, "#FF3300", "#FF3300"],
		[1, "#6E6E6E", "#828163"],
		[1, "#1B67A5", "#1B67A5"],
		[2, "#58C800", "#58C800"],
		[3, "#B18644", "#B18644"],
		[4, "#58C800", "#58C800"],
		[5, "#58C800", "#CB0000"],
		[6, "#58C800", "#58C800"],
		[7, "#58C800", "#58C800"],
		[8, "#58C800", "#58C800"],
		[9, "#58C800", "#58C800"],
		[10, "#FF00FF", "#FF00FF"],
		[11, "#C0C0C0", "#FFFFFF"],
		[12, "#B18644", "#B18644"],
		[12, "#1B67A5", "#B18644", true],
		[13, "#B18644", "#C96DBF"],
		[14, "#FFA62B", "#FFA62B"],
		[15, "#FFA62B", "#FFA62B"],
		[15, "#1B67A5", "#FFA62B", true],
		[16, "#5B97BC", "#5B97BC"],
		[17, "#5B97BC", "#5B97BC"],
		[18, "#58C800", "#5B97BC"],
		[19, "#5B97BC", "#5B97BC"],
		[19, "#1B67A5", "#5B97BC", true],
		[20, "#5B97BC", "#58C800"],
		[21, "#C96DBF", "#C96DBF"],
		[22, "#C96DBF", "#C96DBF"],
		[22, "#1B67A5", "#C96DBF", true],
		[23, "#C96DBF", "#C96DBF"],
		[24, "#CB0000", "#CB0000"],
		[25, "#CB0000", "#CB0000"],
		[26, "#CB0000", "#CB0000"],
		[26, "#1B67A5", "#CB0000", true],
		[27, "#CB0000", "#1B67A5"],
		[28, "#1B67A5", "#58C800", true],
		[29, "#1B67A5", "#1B67A5", true],
		[30, "#134975", "#134975"],
		[31, "#134975", "#134975"],
		[32, "#134975", "#134975"],
		[33, "#292929", "#292929"],
		[34, "#292929", "#292929"],
		[35, "#292929", "#292929"],
		[36, "#292929", "#292929"],
		[37, "#292929", "#292929"],
		[38, "#292929", "#292929"],
		[39, "#292929", "#292929"],
		[40, "#F10303", "#F10303"],
		[41, "#000000", "#008000"],
		[42, "#75A2BB", "#555CC2"],
		[43, "#58C800", "#58C800"],
	];

	// It is a chameleon card, so about half the time it gets the colors wrong on purpose.
	function random_id_color() {
		return "hsl(" + Math.floor(Math.random() * 360) + ", " + (45 + Math.floor(Math.random() * 45)) + "%, " + (35 + Math.floor(Math.random() * 30)) + "%)";
	}

	function id_face(parent) {
		var face = el("div", "idface", parent);
		var back = el("i", "idback", face);
		var box = el("i", "idtint", face);
		var stripe = el("i", "idtint", face);
		var trim = el("i", "idtrim", face);
		function cell(part, col, row) {
			var pos = (-col * 32) + "px " + (-row * 32) + "px";
			part.style.backgroundPosition = pos;
			part.style.webkitMaskPosition = pos;
			part.style.maskPosition = pos;
		}
		return {
			el: face,
			set: function (look) {
				cell(back, look.back, 0);
				cell(trim, look.icon, 1);
				cell(box, look.head ? ID_MASK_HEAD : ID_MASK_DEPT, 2);
				cell(stripe, ID_MASK_STRIPE, 2);
				box.style.backgroundColor = look.box;
				stripe.style.backgroundColor = look.stripe;
			},
		};
	}

	function chameleon_id(ic) {
		ic.classList.add("idcard");
		var box = el("div", "cham", ic);
		var faces = [id_face(box), id_face(box)];
		var shown = 0;
		var cur = null;
		function random_look() {
			var next;
			do {
				var b = Math.floor(Math.random() * ID_BACKS);
				var looks = ID_LOOKS.filter(function (l) {
					return (b === ID_PRISONER_BACK) === (ID_PRISONER_TRIMS.indexOf(l[0]) >= 0);
				});
				var l = pick(looks);
				next = { back: b, icon: l[0], box: l[1], stripe: l[2], head: !!l[3] };
				if (Math.random() < 0.5) {
					next.box = random_id_color();
					next.stripe = Math.random() < 0.5 ? next.box : random_id_color();
				}
			} while (cur && next.back === cur.back && next.icon === cur.icon);
			return next;
		}
		cur = random_look();
		faces[0].set(cur);
		faces[1].el.style.opacity = 0;
		function change() {
			var next = random_look();
			var glitch = faces[shown];
			// two quick frames of the current card jittering a pixel...
			var g = 0;
			var timer = setInterval(function () {
				if (g < 2) {
					box.style.left = (10 + (g % 2 ? 1 : -1)) + "px";
					g++;
					return;
				}
				clearInterval(timer);
				box.style.left = "10px";
				// ...then fade over to the new card
				var other = faces[1 - shown];
				other.set(next);
				other.el.style.opacity = 1;
				glitch.el.style.opacity = 0;
				shown = 1 - shown;
				cur = next;
			}, 90);
		}
		(function idle() {
			after(8000 + Math.random() * 4000, function () {
				change();
				idle();
			});
		})();
	}

	function select_icon(id) {
		Object.keys(icon_refs).forEach(function (k) {
			icon_refs[k].classList.toggle("selected", k === id);
		});
	}

	var ICON_W = 54;
	var ICON_H = 46;

	function place_icons() {
		var rows = Math.floor((stage_h - 16 - 4) / ICON_H);
		icon_list.forEach(function (ic, i) {
			var col = Math.floor(i / rows);
			var row = i % rows;
			ic.style.left = (stage_w - 4 - ICON_W * (col + 1)) + "px";
			ic.style.top = (4 + row * ICON_H) + "px";
		});
	}

	// ------------------------------------------------------------- taskbar, start menu, clock

	function build_taskbar(parent) {
		var tb = el("div", null, parent);
		tb.id = "taskbar";
		var start = el("div", "btn", tb);
		start.id = "startbtn";
		img("mav_chevron.png", null, start);
		el("span", null, start, "Start");
		var tasks = el("div", null, tb);
		tasks.id = "tasks";
		var tray = el("div", null, tb);
		tray.id = "tray";
		var horn = img("mav_tray_horn.png", null, tray);
		horn.title = "Honk";
		horn.addEventListener("click", function () { honk(); });
		var snd = el("span", "snd", tray);
		var show_snd = function () {
			snd.className = "snd snd_" + ["all", "clicks", "off"][SFX_MODES.indexOf(sfx_mode)];
			snd.title = "Sounds: " + sfx_mode;
		};
		show_snd();
		snd.addEventListener("click", function () {
			cycle_sfx_mode();
			show_snd();
		});
		var clock = el("span", null, tray);
		clock.id = "clock";
		function tick() {
			var d = new Date();
			clock.textContent = d.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
			clock.title = d.toLocaleDateString([], { weekday: "long", year: "numeric", month: "long", day: "numeric" });
		}
		tick();
		setInterval(tick, 1000);

		var menu = el("div", null, parent);
		menu.id = "startmenu";
		var side = el("div", "side", menu);
		side.innerHTML = "Aeri<b>OS</b>";
		function item(icon, label, fn) {
			var it = el("div", "item", menu);
			img("mav_icon_" + icon + ".png", null, it);
			el("span", null, it, label);
			it.addEventListener("click", function () {
				menu.style.display = "none";
				start.classList.remove("on");
				if (fn !== shut_down) {
					sfx("click");
				}
				fn();
			});
			return it;
		}
		item("station", "station.exe", function () { open_window("station"); });
		item("music", "SpaceAmp", function () { open_window("amp"); });
		item("paint", "MSpacePaint", function () { open_window("paint"); });
		item("readme", "readme.txt", function () { open_window("readme"); });
		el("div", "sep", menu);
		item("join", C.playing ? "Join Game" : "Toggle Ready", ACTIONS.ready);
		item("observe", "Observe", ACTIONS.observe);
		item("setup", "Setup Character", ACTIONS.setup);
		item("options", "Game Options", ACTIONS.options);
		if (C.servers) {
			item("servers", "Swap Servers", ACTIONS.servers);
		}
		el("div", "sep", menu);
		item("power", "Shut Down...", shut_down);
		start.addEventListener("click", function (e) {
			e.stopPropagation();
			var open = menu.style.display === "block";
			menu.style.display = open ? "none" : "block";
			start.classList.toggle("on", !open);
		});
		document.addEventListener("mousedown", function (e) {
			if (!menu.contains(e.target) && !start.contains(e.target)) {
				menu.style.display = "none";
				start.classList.remove("on");
			}
		});
	}

	function update_taskbar(active) {
		var tasks = document.getElementById("tasks");
		if (!tasks) {
			return;
		}
		tasks.innerHTML = "";
		Object.keys(wins).forEach(function (k) {
			var w = wins[k];
			var minimized = w.el.classList.contains("min");
			var on = !minimized && !w.el.classList.contains("inactive");
			var t = el("div", "task" + (on ? " on" : ""), tasks);
			img("mav_icon_" + w.spec.icon + ".png", null, t);
			el("span", null, t, w.spec.title);
			t.addEventListener("click", function () {
				if (on) {
					minimize(k);
				} else {
					open_window(k);
				}
			});
		});
	}

	// It really shuts down: the server disconnects you a moment later. Rejoining is one click.
	function shut_down() {
		var s = document.getElementById("shutdown");
		s.style.display = "block";
		s.textContent = "AeriOS is shutting down...";
		// with the shutdown sound on, the server lets the sound finish before it lets go of you
		after(sfx_mode === "All" ? 3200 : 1200, function () { s.textContent = "It's now safe to turn off your station."; });
		// "local" tells the server this page played the shutdown sound itself
		if (sfx_mode === "All" && play_local("shutdown")) {
			byond("lobby_shutdown=1;local=1");
		} else {
			byond("lobby_shutdown=1");
		}
	}

	// ------------------------------------------------------------- clown.exe

	var clown_busy = false;
	var last_honk = 0;

	var last_icon_honk = 0;

	// Opening the Clown.exe icon plays the clown rift honks. No shake: it's not asking for attention.
	function clown_icon_honk() {
		var now = Date.now();
		if (now - last_icon_honk < 1200) {
			return;
		}
		last_icon_honk = now;
		byond("lobby_honk=rift");
	}

	function honk() {
		var now = Date.now();
		if (now - last_honk < 500) {
			return;
		}
		last_honk = now;
		byond("lobby_honk=1");
		var r = document.getElementById("root");
		r.classList.remove("shake");
		void r.offsetWidth;
		r.classList.add("shake");
	}

	function clown_exe() {
		if (clown_busy) {
			return;
		}
		clown_chain();
	}

	var CLOWN_NOISES = ["bikehorn", "squeak1", "slip", "squeak2", "partyhorn", "clownstep", "carhorn", "squeak3", "trombone"];

	function clown_chain() {
		clown_busy = true;
		var spam = [];
		for (var i = 0; i < 9; i++) {
			(function (i) {
				after(i * 110, function () {
					byond("lobby_honk=" + CLOWN_NOISES[i]);
					spam.push(dialog({
						title: "clown.exe", icon: "err", w: 120, big: true, silent: true,
						x: 40 + i * 12, y: 20 + i * 11,
						text: "HONK!",
						buttons: [{ label: "HONK", fn: function (close) { close(); last_honk = 0; honk(); } }],
						on_x: function (close) { close(); last_honk = 0; honk(); },
					}));
				});
			})(i);
		}
		after(1300, honk);
		after(1700, function () { clown_run(spam); });
	}

	function clown_run(spam) {
		var c = document.getElementById("clown");
		var W = stage_w;
		var path = [
			[-32, 196], [Math.round(W * 0.45 / 16) * 16, 196], [Math.round(W * 0.45 / 16) * 16, 112],
			[W - 112, 112], [W - 112, 32], [W + 40, 32],
		];
		var pts = [];
		for (var p = 0; p < path.length - 1; p++) {
			var a = path[p];
			var b = path[p + 1];
			var steps = Math.max(1, Math.round(Math.hypot(b[0] - a[0], b[1] - a[1]) / 16));
			for (var s = 0; s < steps; s++) {
				pts.push([a[0] + (b[0] - a[0]) * s / steps, a[1] + (b[1] - a[1]) * s / steps]);
			}
		}
		pts.push(path[path.length - 1]);
		c.style.display = "block";
		c.style.transition = "left " + CLOWN_STEP_MS + "ms linear, top " + CLOWN_STEP_MS + "ms linear";
		var i = 0;
		var honked_again = false;
		var mover = setInterval(function () {
			if (i >= pts.length) {
				clearInterval(mover);
				c.style.display = "none";
				// the ones it knocked flying are gone; the rest stay for the player to close
				spam.forEach(function (d) {
					if (d.el.classList.contains("flung")) {
						d.close();
					}
				});
				open_window("paint");
				after(3000, function () {
					icon_list.forEach(function (ic) { ic.classList.remove("knocked", "knocked2"); });
					clown_busy = false;
				});
				return;
			}
			var pt = pts[i];
			var prev = pts[Math.max(0, i - 1)];
			var dir = pt[0] > prev[0] ? "E" : (pt[0] < prev[0] ? "W" : "S");
			c.dataset.src = "mav_clown_" + dir + ".png";
			c.src = c.dataset.src;
			c.style.left = pt[0] + "px";
			c.style.top = pt[1] + "px";
			clown_waddle(c);
			// real clown shoes squeak every other step; this one is in a hurry
			byond("lobby_honk=step");
			// knock over icons and fling error boxes we run through
			icon_list.forEach(function (ic, k) {
				if (Math.abs(ic.offsetLeft + 6 - pt[0]) < 26 && Math.abs(ic.offsetTop - pt[1]) < 26) {
					ic.classList.add(k % 2 ? "knocked" : "knocked2");
				}
			});
			spam.forEach(function (d) {
				var e = d.el;
				if (e.classList.contains("flung")) {
					return;
				}
				var cx = e.offsetLeft + e.offsetWidth / 2;
				var cy = e.offsetTop + e.offsetHeight / 2;
				if (Math.abs(cx - pt[0]) < e.offsetWidth / 2 + 10 && Math.abs(cy - pt[1]) < e.offsetHeight / 2 + 10) {
					e.classList.add("flung");
					e.style.transform = "translate(" + (pt[0] < cx ? 160 : -160) + "px, 220px) rotate(" + (pt[0] < cx ? 160 : -160) + "deg)";
				}
			});
			if (!honked_again && i > pts.length * 0.6) {
				honked_again = true;
				last_honk = 0;
				honk();
			}
			i++;
		}, CLOWN_STEP_MS);
	}

	// How long the clown takes per tile, about a clown's walking pace in game
	var CLOWN_STEP_MS = 180;

	// The same waddle the game gives clowns: hop up 4 pixels, then settle back down
	// with a random tilt left, right or none, then snap upright for the next step.
	function clown_waddle(c) {
		c.style.animation = "none";
		void c.offsetWidth;
		c.style.animation = "waddle_" + pick(["l", "n", "r"]) + " " + Math.round(CLOWN_STEP_MS * 0.9) + "ms linear";
	}

	// ------------------------------------------------------------- CRT

	function add_crt() {
		if (C.classic) {
			return;
		}
		// the power-on only plays on a connection's first page, not on every reload
		if (C.intro) {
			document.body.classList.add("crt_on");
		}
		["crt_scan", "crt_grille", "crt_flicker", "crt_roll", "crt_glass"].forEach(function (c) {
			el("div", "crt_layer " + c, document.body);
		});
	}

	// ------------------------------------------------------------- startup splashes

	var progress = { cur: 0, total: 1, last: Date.now() };
	var latest_line = "";
	var splash_refs = {};

	// Text only. DOMParser builds an inert document: no scripts run and no images load.
	function strip(html) {
		var doc = new DOMParser().parseFromString(String(html), "text/html");
		return (doc.body.textContent || "").trim();
	}

	var splash_live = false;

	// The boot screen only gives way to the desktop once the desktop can work: its sounds
	// have loaded. If they never do, it gives up waiting after READY_TIMEOUT_MS.
	var READY_TIMEOUT_MS = 20000;
	var page_start = Date.now();

	function lobby_ready() {
		return sfx_ready() || Date.now() - page_start > READY_TIMEOUT_MS;
	}

	// done: set for the quick boot screen a player sees on connecting to a running server.
	// Without it, the splash shows the server's real startup until the server reloads the page.
	// quick: start the bar near the end, for a page that already sat through a boot screen.
	function build_splash(root, done, quick) {
		var B = C.boot || {};
		splash_live = true;
		if (done) {
			progress.total = 75;
			progress.cur = quick ? 65 : 0;
		} else {
			progress.cur = +B.progress_time || 0;
			progress.total = +B.progress_total || 1500;
		}
		(B.messages || []).forEach(function (m) { latest_line = strip(m) || latest_line; });
		var kind = C.splash || pick(["bios", "setup", "bsod"]);
		if (kind === "bios") {
			build_bios(root, B);
		} else if (kind === "setup") {
			build_setup(root);
		} else {
			build_bsod(root, B);
		}
		var ticker = setInterval(function () {
			progress_tick();
			if (done && progress_ratio() >= 1 && lobby_ready()) {
				clearInterval(ticker);
				splash_live = false;
				after(450, done);
			}
		}, 100);
		progress_tick();
	}

	/// Width of one progress bar block with its gap, in pixels
	var BAR_BLOCK = 8;
	/// How long a status line stays up before the next one replaces it
	var STATUS_MIN_MS = 600;
	var status_shown_at = 0;

	function progress_ratio() {
		return progress.cur / Math.max(1, progress.total);
	}

	function progress_tick() {
		var now = Date.now();
		if (progress.cur < progress.total * 3) {
			progress.cur += (now - progress.last) / 100;
		}
		progress.last = now;
		var r = progress_ratio();
		// the bar holds just short of the end until the desktop is ready
		if (!lobby_ready()) {
			r = Math.min(r, 0.99);
		}
		if (splash_refs.bar) {
			// whole blocks only: a block is 6px plus a 2px gap, so a part block never shows
			var holder = splash_refs.bar.parentNode;
			var pad = getComputedStyle(holder);
			var track = holder.clientWidth - parseFloat(pad.paddingLeft) - parseFloat(pad.paddingRight);
			var blocks = Math.floor(Math.min(1, r) * (track + 2) / BAR_BLOCK);
			splash_refs.bar.style.width = Math.max(0, blocks * BAR_BLOCK - 2) + "px";
		}
		if (splash_refs.pct) {
			splash_refs.pct.textContent = Math.floor(r * 100) + "% complete";
		}
		// a new status line waits until the last one was up long enough to read
		if (splash_refs.status && now - status_shown_at >= STATUS_MIN_MS) {
			var shown = latest_line ? latest_line : "Waking up the hamsters...";
			if (splash_refs.status.textContent !== shown) {
				splash_refs.status.textContent = shown;
				status_shown_at = now;
			}
		}
		if (splash_refs.humans) {
			splash_refs.humans.textContent = String(C.boot.humans || 0);
		}
	}

	function line(parent, text, cls) {
		var d = el("div", cls, parent);
		d.textContent = text === "" ? " " : text;
		return d;
	}

	function build_bios(root, B) {
		var s = el("div", "splash bios", root);
		img("mav_chevron.png", "logo", s);
		line(s, "MAVERICK-OS BIOS v1.13", "hi");
		line(s, "(C) Aeri Consultations and Services. No refunds.");
		line(s, "");
		line(s, "Memory test ............. 640K OK (it's enough)");
		line(s, "BYOND engine ............ " + (B.byond || "???"));
		line(s, "Tick rate ............... " + (B.fps || "?") + " FPS");
		line(s, "Scanning crew manifest ...");
		var h = line(s, "  Humans detected ....... ");
		splash_refs.humans = el("span", null, h);
		line(s, "  Automatons ............ 0 (on strike)");
		line(s, "Loading blackjack ....... OK");
		line(s, "Loading hookers ......... OK");
		line(s, "Mounting STATION ........ " + (B.map || "Unknown Station"));
		line(s, "  OK (Not really, but let's pretend)");
		var st = line(s, "");
		splash_refs.status = st;
		var bar = el("div", "bar", s);
		splash_refs.bar = el("i", null, bar);
		var boom = line(s, B.explode_line || "TOUCH ANY BUTTON TO EXPLODE", "hi blink");
		boom.style.marginTop = "6px";
		var drills = ["...relax. that was a drill.", "ok that one was a joke. stop touching things.", "good thing the station is insured.", "BOOM. (it didn't explode. we lied.)"];
		function kaboom() {
			if (!splash_live) {
				return;
			}
			var r = document.getElementById("root");
			r.classList.remove("shake", "flash");
			void r.offsetWidth;
			r.classList.add("shake", "flash");
			boom.classList.remove("blink");
			boom.textContent = pick(drills);
			byond("lobby_kaboom=1");
		}
		document.addEventListener("keydown", kaboom);
		s.addEventListener("mousedown", kaboom);
	}

	function build_setup(root) {
		var s = el("div", "splash setup_bg", root);
		var w = 384;
		var holder = el("div", null, s);
		holder.id = "windows";
		var spec = { title: "MaverickStation Setup", icon: "station", w: w, h: 168, x: Math.round(stage_w / 2 - w / 2), y: 46 };
		function no_escape() {
			dialog({ title: "Setup", icon: "err", w: 140, text: "THERE IS NO ESCAPE", big: false, y: 110 });
		}
		var win = make_window("setup", spec, { buttons: ["close"], on_button: no_escape });
		win.dataset.locked = "1";
		var body = el("div", "body", win);
		body.style.display = "flex";
		body.style.padding = "4px";
		var panel = el("div", "setup_panel", body);
		img("mav_icon_join.png", null, panel);
		var col = el("div", null, body);
		col.style.flex = "1";
		var head = el("div", null, col, "Preparing your shift");
		head.style.fontFamily = "Pixellari";
		head.style.fontSize = "16px";
		head.style.marginBottom = "6px";
		// one line at a time, like a certain life simulator
		var sims = line(col, "");
		var SIMS_LINES = [
			"Reticulating splines...",
			"Lubing the hallways...",
			"Teaching the AI a fourth law...",
			"Counting the monkeys...",
			"Recounting the monkeys...",
			"Polishing the captain's spare ID...",
			"Untangling the disposals loop...",
			"Charging the SMES...",
			"Feeding the slimes...",
			"Bribing the quartermaster...",
			"Hiding the toolboxes from the assistants...",
			"Calibrating the gravity generator...",
			"Inflating the clown's balloons...",
			"Locating the nuke disk...",
		];
		var sims_i = Math.floor(Math.random() * SIMS_LINES.length);
		sims.textContent = SIMS_LINES[sims_i];
		setInterval(function () {
			sims_i = (sims_i + 1 + Math.floor(Math.random() * 3)) % SIMS_LINES.length;
			sims.textContent = SIMS_LINES[sims_i];
		}, 1400);
		var disk = el("div", null, col);
		disk.style.display = "flex";
		disk.style.alignItems = "center";
		disk.style.whiteSpace = "nowrap";
		el("span", null, disk, "Hiding the nuke disk (selected location:\u00a0");
		var where = el("span", null, disk, "Clown's ass");
		where.style.color = "#c01010";
		el("span", null, disk, ")");
		var cl = img("mav_clown_small.png", null, disk);
		cl.style.marginLeft = "3px";
		splash_refs.status = line(col, "");
		splash_refs.status.style.color = "#404040";
		splash_refs.status.style.marginTop = "6px";
		splash_refs.status.style.whiteSpace = "nowrap";
		splash_refs.status.style.overflow = "hidden";
		var pb = el("div", "pbar", col);
		splash_refs.bar = el("i", null, pb);
		var btns = el("div", null, col);
		btns.style.textAlign = "right";
		btns.style.marginTop = "8px";
		var cancel = el("div", "btn", btns, "Cancel");
		cancel.addEventListener("click", no_escape);
	}

	var STOP_CODES = ["SHIT_FUCK", "HELP_ME", "OH_NO"];

	function build_bsod(root, B) {
		var s = el("div", "splash bsod", root);
		el("div", "face", s, ";)");
		var msg = el("div", "msg", s);
		msg.innerHTML = "Your FRIEND ran into a problem and needs to restart.<br>We're just collecting some <span class='redact'>████</span> and then<br>we'll be right back!";
		splash_refs.pct = el("div", "pct", s, "0% complete");
		var small = el("div", "small", s);
		el("div", null, small, "If you call a clown, give them this info. They won't be able to help, but it might be funny.");
		el("div", null, small, "Stop code: " + (B.stop_code || pick(STOP_CODES)));
		img("mav_blinds.png", "blinds", s);
		el("div", "gl1", s);
		el("div", "gl2", s);
		el("div", "gl3", s);
	}

	// ------------------------------------------------------------- page build

	function build_lobby(root) {
		build_wall(root);
		build_sky(root);
		var hot = el("div", null, root);
		hot.id = "crt_hot";
		hot.title = "station.exe";
		var hs = C.crt_hotspot || [100, 105, 92, 96];
		hot.addEventListener("dblclick", function () { open_window("station"); });
		build_crt_power(root);
		var holder = el("div", null, root);
		holder.id = "windows";
		if (C.classic) {
			var spec = { title: "MaverickStation", icon: "station", w: 190, h: 172, x: function () { return Math.round(stage_w / 2 - 95); }, y: 24, build: station_menu };
			var w = make_window("classic", spec, { buttons: [] });
			w.dataset.locked = "1";
			var body = el("div", "body", w);
			station_menu(body);
			wins.classic = { el: w, spec: spec, body: body };
			if (C.notice) {
				show_notice();
			}
			return;
		}
		build_icons(root);
		var clown = img("mav_clown_E.png", null, root);
		clown.id = "clown";
		build_taskbar(root);
		var sd = el("div", null, root);
		sd.id = "shutdown";
		restore_windows();
		if (C.assigned) {
			dialog({
				title: "Message", icon: "mav_chevron.png", big: true, w: 220, y: 70,
				text: "You have been assigned a STATION.",
				buttons: [
					{ label: "Awesome", fn: function (close) { close(); byond("assigned_seen=1;late_join=1"); } },
					{ label: "Wowsome", fn: function (close) { close(); byond("assigned_seen=1;late_join=1"); } },
				],
				on_x: function (close) { close(); byond("assigned_seen=1"); },
			});
		}
		if (C.notice) {
			show_notice();
		}
		// keep the hotspot glued to the CRT in the wallpaper
		layout_hooks.push(function () {
			var left = Math.round((stage_w - 640) / 2);
			hot.style.left = (left + hs[0]) + "px";
			hot.style.top = (wall_y + hs[1]) + "px";
			hot.style.width = hs[2] + "px";
			hot.style.height = hs[3] + "px";
		});
	}

	// The CRT on the wallpaper has a working power button on its base unit.
	// Wallpaper coordinates: the screen, the button, and the power light on the button.
	var CRT_SCREEN = [112, 113, 69, 45];
	var CRT_BUTTON = [104, 183, 13, 12];
	var CRT_LIGHT = [110, 187, 1, 2];

	function build_crt_power(root) {
		var screen_off = el("div", "crt_off", root);
		var light_off = el("div", "crt_light_off", root);
		var button = el("div", "crt_button", root);
		button.title = "Power";
		var on = true;
		button.addEventListener("mousedown", function (e) { e.stopPropagation(); });
		button.addEventListener("dblclick", function (e) { e.stopPropagation(); });
		button.addEventListener("click", function (e) {
			e.stopPropagation();
			on = !on;
			screen_off.classList.toggle("shown", !on);
			light_off.style.display = on ? "none" : "block";
			if (on) {
				screen_off.classList.remove("shown");
				screen_off.classList.add("warming");
				after(600, function () { screen_off.classList.remove("warming"); });
			}
		});
		function place(e, box) {
			var left = Math.round((stage_w - 640) / 2);
			e.style.left = (left + box[0]) + "px";
			e.style.top = (wall_y + box[1]) + "px";
			e.style.width = box[2] + "px";
			e.style.height = box[3] + "px";
		}
		layout_hooks.push(function () {
			place(screen_off, CRT_SCREEN);
			place(button, CRT_BUTTON);
			place(light_off, CRT_LIGHT);
		});
	}

	function show_notice() {
		dialog({
			title: "IMPORTANT.txt - Notepad", icon: "err", w: 200, y: 30, silent: true,
			html: "<div class='notice_text'></div>",
		});
		var boxes = document.querySelectorAll(".notice_text");
		boxes[boxes.length - 1].textContent = C.notice;
	}

	// Once per session, tell the server the player's clock so it can pick
	// time- or date-limited lobby tracks (see config/title_music/names.txt).
	var music_live = false;

	function clock_args() {
		var d = new Date();
		return "hour=" + d.getHours() + ";minute=" + d.getMinutes() + ";month=" + (d.getMonth() + 1) + ";day=" + d.getDate();
	}

	// The server picks the first track as soon as the page loads, so SpaceAmp already
	// shows the right one when the desktop appears instead of switching to it.
	function music_clock() {
		if (C.mode !== "startup" && C.music.enabled && C.music.needs_hello) {
			byond("music=clock;" + clock_args());
		}
	}

	function music_hello() {
		if (music_live) {
			return;
		}
		music_live = true;
		if (!C.music.enabled || !C.music.needs_hello) {
			return;
		}
		byond("music=hello;" + clock_args());
	}

	function init() {
		try {
			init_desktop();
		} catch (e) {
			if (window.MAV_FAIL) {
				window.MAV_FAIL(e && e.message ? e.message : String(e));
			}
			throw e;
		}
	}

	function init_desktop() {
		if (started) {
			return;
		}
		started = true;
		var root = el("div", null, stage);
		root.id = "root";
		root.style.position = "absolute";
		root.style.inset = "0";
		ready = !!C.ready;
		antag = !!C.antag;
		music_clock();
		if (C.mode === "startup") {
			build_splash(root);
		} else if ((C.intro || (C.startup_due && !lobby_ready())) && !C.classic) {
			// a quick boot screen on the first page of a connection, then the desktop.
			// The first desktop of the round waits behind one too, so its startup sound and
			// clicks are loaded when it shows. The music waits for the desktop too.
			build_splash(root, function () {
				root.innerHTML = "";
				splash_refs = {};
				build_lobby(root);
				layout();
				desktop_ready();
			}, !C.intro);
		} else {
			build_lobby(root);
			desktop_ready();
		}
		add_crt();
		if (C.intro) {
			byond("lobby_intro_seen=1");
		}
		if (C.ready_ping) {
			byond("title_is_ready=1");
		}
		byond("lobby_alive=1");
		// the server's plain fallback menu stays hidden as long as this flag gets set
		window.MAV_OK = true;
		window.addEventListener("resize", layout);
		layout();
	}

	// ------------------------------------------------------------- hooks the server calls

	window.toggle_ready = function (value) {
		ready = String(value) === String(C.ready_value);
		refresh_station();
	};
	window.toggle_antag = function (value) {
		if (value !== undefined && value !== "") {
			antag = !!(+value);
		} else {
			antag = !antag;
		}
		refresh_station();
	};
	window.update_current_character = function (name) {
		C.name = name;
		refresh_station();
	};
	window.append_terminal_text = function (html) {
		var t = strip(html || "");
		if (t) {
			latest_line = t;
		}
	};
	window.update_loading_progress = function (current, total) {
		progress.cur = parseFloat(current) || progress.cur;
		progress.total = parseFloat(total) || progress.total;
	};
	window.update_humans = function (count) {
		if (C.boot) {
			C.boot.humans = +count;
		}
	};
	window.music_state = function (json) {
		var s;
		try {
			s = JSON.parse(json);
		} catch (e) {
			return;
		}
		var track_changed = s.index !== C.music.index || s.started;
		Object.keys(s).forEach(function (k) { C.music[k] = s[k]; });
		if (s.vol !== undefined) {
			sfx_vol = +s.vol || 0;
		}
		if (track_changed) {
			amp_clock.elapsed = s.offset || 0;
			amp_clock.ended_sent = false;
		}
		if (s.offset !== undefined) {
			amp_clock.elapsed = s.offset;
			amp_clock.ended_sent = false;
		}
		amp_clock.last = Date.now();
		if (amp) {
			draw_amp(true);
		}
	};

	// The script sits after everything it builds on, so it starts right away instead of
	// waiting for the page's load event, which a stray link can stop from ever firing.
	init();
})();
