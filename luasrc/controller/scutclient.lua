module("luci.controller.scutclient", package.seeall)

function index()
	local fs = require "nixio.fs"
	if not fs.access("/etc/config/scutclient") then
		return
	end
	local uci = require "luci.model.uci".cursor()
	local mainorder = uci:get_first("scutclient", "luci", "mainorder", 10)

	entry({"admin", "services", "scutclient"},
		alias("admin", "services", "scutclient", "status"),
		_("华南理工大学客户端"),
		mainorder
	)

	entry({"admin", "services", "scutclient", "status"},
		call("action_status"),
		_("状态"),
		10
	).leaf = true

	entry({"admin", "services", "scutclient", "logs"}, template("scutclient/logs"), _("日志"), 20).leaf = true
	entry({"admin", "services", "scutclient", "about"}, call("action_about"), _("关于"), 30).leaf = true
	entry({"admin", "services", "scutclient", "get_log"}, call("get_log"))
	entry({"admin", "services", "scutclient", "netstat"}, call("get_netstat"))
	entry({"admin", "services", "scutclient", "scutclient-log.tar"}, call("get_dbgtar"))
end


function get_log()
	local http = require "luci.http"
	local fs = require "nixio.fs"
	local sys = require "luci.sys"
	local log_file = "/tmp/scutclient.log"
	local send_log_lines = 75
	local client_log

	if fs.access(log_file) then
		client_log = sys.exec("tail -n " .. send_log_lines .. " " .. log_file)
	else
		client_log = "Unable to access the log file!"
	end

	http.prepare_content("text/plain; charset=utf-8")
	http.write(client_log)
	http.close()
end

function action_about()
	local template = require "luci.template"
	template.render("scutclient/about")
end


function action_status()
	local template = require "luci.template"
	local http = require "luci.http"
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()

	-- Handle actions before rendering (so page shows updated data)
	if http.formvalue("logoff") == "1" then
		sys.call("/etc/init.d/scutclient stop > /dev/null")
	end
	if http.formvalue("redial") == "1" then
		sys.call("/etc/init.d/scutclient stop > /dev/null")
		sys.call("/etc/init.d/scutclient start > /dev/null")
	end
	if http.formvalue("enable") == "1" then
		sys.call("/etc/init.d/scutclient enable > /dev/null")
		uci:set("scutclient", uci:get_first("scutclient", "option"), "enable", "1")
		uci:commit("scutclient")
	end
	if http.formvalue("disable") == "1" then
		sys.call("/etc/init.d/scutclient disable > /dev/null")
		uci:set("scutclient", uci:get_first("scutclient", "option"), "enable", "0")
		uci:commit("scutclient")
	end
	if http.formvalue("move_tag") == "1" then
		sys.call("uci set scutclient.@luci[-1].mainorder=90")
		sys.call("uci commit")
		sys.call("rm -rf /tmp/luci-*cache")
	end

	-- Handle config save / save & apply
	local save_action = http.formvalue("save") or http.formvalue("save_apply")
	if save_action then
		local fields = {
			{ section = "scutclient", key = "username", param = "cfg_username" },
			{ section = "scutclient", key = "password", param = "cfg_password" },
			{ section = "drcom",      key = "hostname", param = "cfg_hostname" },
			{ section = "drcom",      key = "server_auth_ip", param = "cfg_server" },
			{ section = "drcom",      key = "version", param = "cfg_version" },
			{ section = "drcom",      key = "hash", param = "cfg_hash" },
			{ section = "drcom",      key = "nettime", param = "cfg_nettime" },
		}
		for _, f in ipairs(fields) do
			local val = http.formvalue(f.param)
			if val and val ~= "" then
				local sid = uci:get_first("scutclient", f.section)
				if sid then
					uci:set("scutclient", sid, f.key, val)
				end
			end
		end
		uci:commit("scutclient")

		-- If save & apply, restart service to apply changes
		if http.formvalue("save_apply") then
			sys.call("/etc/init.d/scutclient stop > /dev/null")
			sys.call("/etc/init.d/scutclient start > /dev/null")
		end
	end

	template.render("scutclient/status")
end

function get_netstat()
	local http = require "luci.http"
	local sys  = require "luci.sys"
	local fs   = require "nixio.fs"

	-- generate_204 probes: real internet → HTTP 204 + empty body
	--                       captive portal → HTTP 200 + login-page body
	--                       network failure → wget exit non-zero
	-- Domestic CDN endpoints tried first for lower latency on Chinese campuses.
	local probe_urls = {
		"http://connect.rom.miui.com/generate_204",
		"http://connectivitycheck.platform.hicloud.com/generate_204",
		"http://wifi.vivo.com.cn/generate_204",
	}

	local tmpfile = "/tmp/.scutnetck_" .. tostring(os.time())
	local nstat   = { stat = "no_internet" }

	for _, url in ipairs(probe_urls) do
		-- wget exit 0 = HTTP response received; non-zero = timeout / DNS failure
		local ret = sys.call(
			"wget -T 4 -q -O " .. tmpfile .. " '" .. url .. "' 2>/dev/null"
		)
		if ret == 0 then
			local body = fs.readfile(tmpfile) or ""
			fs.unlink(tmpfile)
			if body == "" then
				-- Empty body: server returned 204 — real internet
				nstat.stat = "internet"
			else
				-- Non-empty body: captive portal returned a login page
				nstat.stat = "no_login"
			end
			break
		end
		-- Network error on this probe — clean up and try the next one
		fs.unlink(tmpfile)
	end

	http.prepare_content("application/json")
	http.write_json(nstat)
	http.close()
end

function get_dbgtar()
	local http = require "luci.http"
	local fs = require "nixio.fs"
	local sys = require "luci.sys"
	local log_file = "/tmp/scutclient.log"
	local log_file_backup = "/tmp/scutclient.log.backup.log"

	local tar_dir = "/tmp/scutclient-log"
	local tar_files = {
		"/etc/config/wireless",
		"/etc/config/network",
		"/etc/config/system",
		"/etc/config/scutclient",
		"/etc/openwrt_release",
		"/etc/crontabs/root",
		"/etc/config/dhcp",
		"/tmp/dhcp.leases",
		"/etc/rc.local",
	}

	fs.mkdirr(tar_dir)
	for i, v in ipairs(tar_files) do
		sys.call("cp " .. v .. " " .. tar_dir .. " 2>/dev/null")
	end

	if fs.access(log_file_backup) then
		sys.call("cat " .. log_file_backup .. " >> " .. tar_dir .. "/scutclient.log")
	end
	if fs.access(log_file) then
		sys.call("cat " .. log_file .. " >> " .. tar_dir .. "/scutclient.log")
	end
	http.prepare_content("application/octet-stream")
	http.write(sys.exec("tar -C " .. tar_dir .. " -cf - ."))
	sys.call("rm -rf " .. tar_dir)
	http.close()
end
