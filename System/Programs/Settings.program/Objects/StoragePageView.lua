Inherit = 'PageView'

OnLoad = function(self)
	if fs.getFreeSpace and fs.getSize then
		self:AddStorage('Main Computer Storage', '/', 2)
		-- self:AddStorage('Left Disk', '/disk', 8)
		local y = 8
		for i, p in ipairs(Peripheral.GetPeripherals('drive')) do
			local info = Peripheral.GetInfo(p)
			if info['Disc Type'] == 'Data' then
				local name = info['Disc Label'] or self.Bedrock.Helpers.Capitalise(p.Side)
				self:AddStorage('Disc (' .. name .. ')', info['Mount Path'], y)
				y = y + 6
			end
		end

		self:GetObject('StorageWrapperView'):UpdateScroll()
	else

	end
end

local function formatBytes(bytes)
	if bytes == 0 then
		return 'Zero bytes'
	elseif bytes < 1024 then
		return "< 1kB"
	elseif bytes < 1024 * 1024 then
		return math.ceil(bytes / 1024) .. 'kB'
	elseif bytes < 1024 * 1024 * 1024 then
		local b = math.ceil((bytes / 1024 / 1024)*100)
		return b/100 .. 'MB'
	else
		return '> 1GB'
	end
end

local function folderSize(path)
	if not OneOS.FS.isDir(path) or path == '//.git' then
		return 0
	end
	local totalSize = 0
	for i, v in ipairs(OneOS.FS.list(path)) do
		if path..'/'..v ~= '//rom' and v ~= 'disk' and not string.match(v, 'disk%d') then
			if OneOS.FS.isDir(path..'/'..v) then
				totalSize = totalSize + folderSize(path..'/'..v)
			else
				totalSize = totalSize + OneOS.FS.getSize(path..'/'..v)
			end
		end
	end
	return totalSize
end

AddStorage = function(self, title, path, y)
	local systemSize = folderSize(path .. 'System/') + (OneOS.FS.exists(path .. 'startup') and OneOS.FS.getSize(path .. 'startup') or 0)
	local desktopSize = folderSize(path .. 'Desktop/')
	local programsSize = folderSize(path .. 'Programs/')
	local totalSize = folderSize(path)
	local maxSpace = OneOS.FS.getFreeSpace(path) + totalSize

	local scroll = self:GetObject('StorageWrapperView')
	scroll:AddObject({
        X = 3,
        Y = y,
        TextColour = 'grey',
        Type = 'Label',
        Text = title
    })

    scroll:AddObject({
        X = 3,
        Y = y + 1,
        TextColour = 'lightGrey',
        Type = 'Label',
        Text = formatBytes(totalSize)..' used, '..formatBytes(maxSpace - totalSize)..' available'
    })

    scroll:AddObject({
        X = 3,
        Y = y + 3,
        Width = '100%,-4',
        Type = 'ProgressBar',
        Maximum = maxSpace,
        BarColour = {16384, 2048, 8192, 16},
        Value = {systemSize, programsSize, desktopSize, totalSize-systemSize-programsSize-desktopSize}
    })
end