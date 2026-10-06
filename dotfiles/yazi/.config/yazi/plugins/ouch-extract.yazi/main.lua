--- @since 26.8.15
-- Extract archives with `ouch`, prompting for a password when one is needed.
--
-- Invoked by the `extract` opener in yazi.toml (`ya emit plugin ouch-extract`),
-- so it acts on the selection, or on the hovered file when nothing is selected.
--
-- Each archive is extracted into a hidden temp dir next to it and only moved
-- into place on success: ouch leaves a half-written output dir behind when a
-- password is missing or wrong (and with 7z, even garbage files), so that is
-- discarded instead of polluting the folder. The password reaches ouch through
-- OUCH_PASSWORD, never argv, so it does not show up in `ps`.

local TITLE = "Extract"

local selected_or_hovered = ya.sync(function()
	local tab, paths = cx.active, {}
	for _, f in pairs(tab.selected) do
		paths[#paths + 1] = tostring(f.url)
	end
	if #paths == 0 and tab.current.hovered then
		paths[1] = tostring(tab.current.hovered.url)
	end
	return paths
end)

local function notify(level, s, ...)
	ya.notify { title = TITLE, content = string.format(s, ...), level = level, timeout = 5 }
end

-- Classify a failed ouch run. Messages observed with ouch 0.8.3:
--   zip, no password: "Password required to decrypt file"
--   7z,  no password: "PasswordRequired"
--   zip, wrong:       "Invalid password" / "The provided password is incorrect"
--   7z,  wrong:       "MaybeBadPassword(...)"
local function password_problem(output)
	local text = (output.stdout .. "\n" .. output.stderr):lower()
	if not text:find("password", 1, true) then
		return nil
	elseif text:find("invalid password", 1, true) or text:find("incorrect", 1, true) or text:find("badpassword", 1, true) then
		return "wrong"
	else
		return "missing"
	end
end

local function last_error(output)
	local text = output.stderr ~= "" and output.stderr or output.stdout
	local lines = {}
	for line in text:gmatch("[^\n]+") do
		lines[#lines + 1] = line
	end
	return table.concat(lines, "\n", math.max(1, #lines - 2))
end

local function run_ouch(archive, dir, password)
	local cmd = Command("ouch")
		:arg({ "decompress", "--yes", "--", archive })
		:cwd(tostring(dir))
		:stdin(Command.NULL)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
	if password then
		cmd = cmd:env("OUCH_PASSWORD", password)
	end
	return cmd:output()
end

-- Move every entry of `tmp` into `parent`, renaming on collision ("name_1").
local function move_out(tmp, parent)
	local files, err = fs.read_dir(tmp, { resolve = true })
	if not files then
		return false, err
	end
	for _, f in ipairs(files) do
		local target = fs.unique(f.cha.is_dir and "dir" or "file", parent:join(f.url.name))
		local ok, rerr = fs.rename(f.url, target or parent:join(f.url.name))
		if not ok then
			return false, rerr
		end
	end
	return true
end

local function extract(path)
	local archive = Url(path)
	local parent, name = archive.parent, archive.name
	if not parent then
		return notify("error", "Cannot resolve the parent dir of %s", path)
	end

	local password, title = nil, string.format("Password for %s:", name)
	while true do
		-- Created per attempt and removed before prompting, so quitting Yazi
		-- while the password dialog is open leaves nothing behind.
		local tmp = fs.unique("dir", parent:join(".ouch-extract-" .. name))
		if not tmp or not fs.create("dir_all", tmp) then
			return notify("error", "Cannot create a temp dir next to %s", name)
		end

		local output, err = run_ouch(path, tmp, password)
		if not output then
			fs.remove("dir_all", tmp)
			return notify("error", "Failed to run ouch: %s", err)
		end

		if output.status.success then
			local ok, merr = move_out(tmp, parent)
			fs.remove("dir_all", tmp)
			if ok then
				return notify("info", "Extracted %s", name)
			end
			return notify("error", "Extracted, but could not move the files out: %s", merr)
		end

		-- Discard whatever the failed attempt wrote (partial dirs, garbage).
		fs.remove("dir_all", tmp)

		local problem = password_problem(output)
		if not problem then
			return notify("error", "Failed to extract %s:\n%s", name, last_error(output))
		end

		if problem == "wrong" and password then
			title = string.format("Wrong password, retry %s:", name)
		end

		local value, event = ya.input {
			title = title,
			pos = { "center", w = 60 },
			obscure = true,
		}
		if event ~= 1 then
			return notify("warn", "Extraction of %s cancelled", name)
		end
		password = value
	end
end

return {
	entry = function()
		ya.emit("escape", { visual = true })

		local paths = selected_or_hovered()
		if #paths == 0 then
			return notify("warn", "No file selected")
		end
		for _, path in ipairs(paths) do
			extract(path)
		end
	end,
}
