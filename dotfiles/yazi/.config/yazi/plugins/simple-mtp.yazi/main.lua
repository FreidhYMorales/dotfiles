--- @since 25.5.31
-- ─────────────────────────────────────────────────────────────
--  simple-mtp.yazi — Montaje de dispositivos MTP via simple-mtpfs (FUSE)
--  Alternativa a gvfs para transferencias de archivos grandes.
--
--  Acciones:
--    plugin simple-mtp -- mount    → selecciona dispositivo y monta
--    plugin simple-mtp -- unmount  → selecciona montaje activo y desmonta
--
--  Mountpoint base: /run/user/{UID}/mtp/device{N}/
-- ─────────────────────────────────────────────────────────────

local M = {}

local UID        = tostring(ya.uid and ya.uid() or 1000)
local MTP_BASE   = "/run/user/" .. UID .. "/mtp"
local KEYS       = "1234567890qwertyuiopasdfghjklzxcvbnm"

-- ── Helpers ───────────────────────────────────────────────────

local function notify(msg, level)
	ya.notify({ title = "simple-mtp", content = msg, timeout = 3, level = level or "info" })
end

--- Ejecuta un comando y devuelve (stdout+stderr combinados, success).
local function run(cmd, args)
	local child, err = Command(cmd)
		:args(args)
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then return "", false, tostring(err) end
	local out = child:wait_with_output()
	local text = (out.stdout or "") .. (out.stderr or "")
	return text, out.status and out.status.success, nil
end

--- Lista los dispositivos MTP disponibles.
--- Devuelve una tabla: { { num = 1, name = "Samsung Galaxy" }, ... }
local function list_devices()
	local text = run("simple-mtpfs", { "--list-devices" })
	local devices = {}
	for line in text:gmatch("[^\n]+") do
		local num, name = line:match("^%s*(%d+):%s*(.+)$")
		if num then
			table.insert(devices, { num = tonumber(num), name = name:gsub("%s+$", "") })
		end
	end
	return devices
end

--- Lista los subdirectorios bajo MTP_BASE (montajes activos).
local function list_mounts()
	local text = run("ls", { MTP_BASE })
	local mounts = {}
	for name in text:gmatch("[^\n]+") do
		if name ~= "" then
			table.insert(mounts, name)
		end
	end
	return mounts
end

--- Muestra un picker tipo which-key y devuelve el índice elegido (1-based) o nil.
local function pick(items, label_fn)
	if #items == 0 then return nil end
	if #items == 1 then return 1 end

	local cands = {}
	for i, item in ipairs(items) do
		local key = KEYS:sub(i, i)
		if key == "" then break end
		table.insert(cands, { on = key, run = "", desc = label_fn(item) })
	end
	return ya.which({ cands = cands, silent = false })
end

-- ── Acciones ──────────────────────────────────────────────────

local function action_mount()
	local devices = list_devices()
	if #devices == 0 then
		notify("No se encontraron dispositivos MTP", "warn")
		return
	end

	local idx = pick(devices, function(d) return d.name end)
	if not idx then return end

	local dev        = devices[idx]
	local mountpoint = MTP_BASE .. "/device" .. dev.num

	-- Crear directorio de montaje si no existe
	run("mkdir", { "-p", mountpoint })

	-- Montar con simple-mtpfs
	local _, ok, err = run("simple-mtpfs", { "--device", tostring(dev.num), mountpoint })
	if ok then
		notify('Montado "' .. dev.name .. '" en ' .. mountpoint)
		ya.mgr_emit("cd", { Url(mountpoint) })
	else
		-- Limpiar directorio vacío si el montaje falló
		run("rmdir", { mountpoint })
		notify('Error montando "' .. dev.name .. '": ' .. (err or "fallo desconocido"), "error")
	end
end

local function action_unmount()
	local mounts = list_mounts()
	if #mounts == 0 then
		notify("No hay dispositivos MTP montados", "warn")
		return
	end

	local idx = pick(mounts, function(m) return m end)
	if not idx then return end

	local name       = mounts[idx]
	local mountpoint = MTP_BASE .. "/" .. name

	local _, ok = run("fusermount", { "-u", mountpoint })
	if ok then
		-- Eliminar el directorio vacío tras desmontar
		run("rmdir", { mountpoint })
		notify("Desmontado: " .. name)
	else
		notify("Error desmontando: " .. name, "error")
	end
end

-- ── Entry point ───────────────────────────────────────────────

function M:entry(_, args)
	local action = args[1]
	if action == "mount" then
		action_mount()
	elseif action == "unmount" then
		action_unmount()
	else
		notify('Acción desconocida: "' .. tostring(action) .. '". Usa mount o unmount.', "warn")
	end
end

return M
