local files = {}
local wallpaperColour = colours.cyan
local selectedFile = nil
local dragRelPos = nil
local lastClick = nil
local currentPage = 1
local offset = 0
local totalPages = 1
dragTimeout = 0
local dragLock = false

local function IconLocation(i)
	local slotHeight = 5
	local slotWidth = 11
	local x, y, maxX, maxY, maxPage = MaxIcons()
	local _i = ((i-1) % maxPage) + 1
	local rowPos = ((_i - 1) % maxX)
	local colPos = math.ceil(_i / maxX) - 1
	local page = math.ceil(i/maxPage)
	x = x + (slotWidth * rowPos) + 3 + offset + Drawing.Screen.Width * (page - 1)
	y = y + colPos * slotHeight
	return x, y
end

function MaxIcons()
	local y, x = 3, 5
	local slotHeight = 5
	local slotWidth = 11
	local maxX = math.floor((Drawing.Screen.Width - 2) / slotWidth)
	local maxY = math.floor((Drawing.Screen.Height - 2) / slotHeight)
	x = 1 + math.floor(((Drawing.Screen.Width - (maxX * slotWidth))) / 2)
	return x, y, maxX, maxY, maxX * maxY
end

function GoToPage(i)
	if i > 0 and i <= totalPages then
		selectedFile = nil
		local old = currentPage
		currentPage = i
		Desktop.dragTimeout = nil
		AnimatePageChange(old, currentPage)
	end
end

function DragTimeout()
	local relOffset = (offset + Drawing.Screen.Width * (currentPage - 1))
	local fakeOld = currentPage + 1
	if relOffset > 0 then
		fakeOld = currentPage - 1
	end
	AnimatePageChange(currentPage, currentPage)
end

function AnimatePageChange(from, to)
	dragLock = true
	dragRelPos = nil
	local max = -1*Drawing.Screen.Width * (to - 1)
	local relOffset = (offset + Drawing.Screen.Width * (to - 1))
	local direction = -1
	if relOffset < 0 then
		direction = 1
	end
	if Settings:GetValues()['UseAnimations'] then
		if relOffset < 0 then
			relOffset = relOffset * -1
		end
		local speed = math.ceil(relOffset / Drawing.Screen.Width * 6)
		while ((max < offset) and direction == -1) or ((max > offset) and direction == 1) do
			offset = offset + direction * speed
			relOffset = (offset + Drawing.Screen.Width * (to - 1))
			if speed > relOffset and relOffset > -1*speed then
				offset = max
			end
			QuickDraw()
			sleep(0.05)
		end
		os.queueEvent('timer', clockTimer)
	end
	offset = max
	QuickDraw()
	dragLock = false
end

function QuickDraw()
	if Current.CanDraw then
		Draw()
		Drawing.DrawBuffer()
	end
end

local function doIndex()
	_G.indexTimer = os.startTimer(Indexer.FSIndexRate)
end

function RefreshFiles()
	files = {}

	if not fs.exists('Desktop/') then
		fs.makeDir('Desktop/')
		doIndex()
	elseif not fs.isDir('Desktop/') then
		fs.delete('Destop/')
		fs.makeDir('Desktop/')
		doIndex()
	end

	for i, file in ipairs(fs.list('Desktop/')) do
		if string.sub( file, 1, 1 ) ~= '.' then
			table.insert(files, file)
		end
	end
	local x, y, maxX, maxY, maxPage = MaxIcons()
	totalPages = math.ceil(#files/maxPage)

	wallpaperColour = Settings:GetValues()['DesktopColour']
end

function Draw()
	Drawing.DrawBlankArea(1, 2, Drawing.Screen.Width, Drawing.Screen.Height - 1, wallpaperColour)

	for i, file in ipairs(files) do
		DrawFile(file, i)
	end
	local indicatorWidth = (totalPages * 2) - 2
	local indicatorPos = math.ceil((Drawing.Screen.Width/2)) - totalPages - 1

	for i = 1, totalPages do
		local col = colours.grey
		if currentPage == i then
			col = colours.white
		end
		Drawing.WriteToBuffer(indicatorPos + i * 2, Drawing.Screen.Height - 1, ' ', colours.white, col)
	end

end

function FileHitTest(file, i, x, y)
	local shortenedName = Helpers.RemoveExtension(fs.getName(file))
	local posX, posY = IconLocation(i)
	return (y >= posY and y <= posY + 2 and x >= posX and x <= posX + 3) or (y == posY + 3 and x >= math.floor(posX+2-(#shortenedName/2)) and x <= math.floor(posX+(#shortenedName/2)))
end

function Click(event, side, x, y)
	local found = false
	if (event == 'mouse_drag' and dragRelPos) or (event == 'mouse_scroll' and not dragLock) then
		if event == 'mouse_drag' then
			offset =  (x - dragRelPos) - Drawing.Screen.Width * (currentPage - 1)
		else
			offset = offset + side
		end
		if not dragLock then
			Desktop.dragTimeout = os.startTimer(1)
			local relOffset = (offset + Drawing.Screen.Width * (currentPage - 1))
			if relOffset < 0 and relOffset < -1*Drawing.Screen.Width/4 then
				GoToPage(currentPage + 1)
			elseif relOffset > 0 and relOffset > Drawing.Screen.Width/4 then
				GoToPage(currentPage - 1)
			else
				QuickDraw()
			end
		end
		return
	end
	for i, file in ipairs(files) do
		local name = fs.getName(file)
		if event == 'mouse_click' and FileHitTest(file, i, x, y) then
			if selectedFile == name and lastClick and (os.clock() - lastClick) < 0.5 then
				Helpers.OpenFile('Desktop/'..name)
			end
			lastClick = os.clock()
			selectedFile = name
			found = true

			if side == 2 then
				Menu:Initialise(x, y, nil, nil, self,{ 
					{
						Title = 'Open',
						Click = function()
							Helpers.OpenFile('Desktop/'..name)
						end
					},
					{
						Separator = true
					},
					{
						Title = 'Rename...',
						Click = function()
							if name == 'Documents' then
								ButtonDialogueWindow:Initialise("Unable to rename!", 'You can not rename the Documents folder.', 'Ok', nil, function()end):Show()
							else
								TextDialogueWindow:Initialise("Rename '"..Helpers.TruncateString(name, 17).."'", function(success, value)
									if success and #value ~= 0 then
										local _, err = pcall(function()fs.move('Desktop/'..name, 'Desktop/'..value)doIndex() end)
										if err then
											ButtonDialogueWindow:Initialise("Rename Failed!", 'Error: '..errr, 'Ok', nil, function()end):Show()
										end
										RefreshFiles()
									end
								end):Show()
							end
						end
					},
					{
						Title = 'Delete...',
						Click = function()
							if name == 'Documents' then
								ButtonDialogueWindow:Initialise("Unable to delete!", 'You can not delete the Documents folder.', 'Ok', nil, function()end):Show()
								MainDraw()
							else
								ButtonDialogueWindow:Initialise("Delete '"..Helpers.TruncateString(Helpers.RemoveExtension(name), 16).."'?", "Are you sure you want to delete '"..name.."'?", 'Yes', 'Cancel', function(success)
									if success then
										fs.delete('Desktop/'..name)
										doIndex()
										RefreshFiles()
									end
								end):Show()
							end
						end
					},
					{
						Separator = true
					},
					{
						Title = 'New Folder...',
						Click = function()
							TextDialogueWindow:Initialise("Create a Folder", function(success, value)
								if success then
									if fs.exists('Desktop/'..value) then
										ButtonDialogueWindow:Initialise("File/Folder Exists!", 'A file/folder with that name already exists!', 'Ok', nil, function()end):Show()
									else
										fs.makeDir('Desktop/'..value)
										doIndex()
										RefreshFiles()
									end
								end
							end):Show()
						end
					},
					{
						Title = 'New File...',
						Click = function()
						TextDialogueWindow:Initialise("Create a File", function(success, value)
							if success then
								if fs.exists('Desktop/'..value) then
									ButtonDialogueWindow:Initialise("File/Folder Exists!", 'A file/folder with that name already exists!', 'Ok', nil, function()end):Show()
								else
									local h = fs.open('Desktop/'..value, 'w')
									h.close()
									doIndex()
									RefreshFiles()
								end
							end
						end):Show()
						end
					},
					{
						Separator = true
					},
					{
						Title = 'Refresh',
						Click = function()
							RefreshFiles()
						end
					}
				}):Show()
			end
			MainDraw()
			return
		end
	end

	if not found and selectedFile then
		selectedFile = nil
		MainDraw()
	elseif not found then
		if event == 'mouse_click' and side ~= 2 then
			dragRelPos = x
		elseif event == 'mouse_click' and side == 2 then
			Menu:Initialise(x, y, nil, nil, self,{ 
				{
					Title = 'New Folder...',
					Click = function()
						TextDialogueWindow:Initialise("Create a Folder", function(success, value)
							if success then
								if fs.exists('Desktop/'..value) then
									ButtonDialogueWindow:Initialise("File/Folder Exists!", 'A file/folder with that name already exists!', 'Ok', nil, function()end):Show()
								else
									fs.makeDir('Desktop/'..value)
									doIndex()
									RefreshFiles()
								end
							end
						end):Show()
					end
				},
				{
					Title = 'New File...',
					Click = function()
					TextDialogueWindow:Initialise("Create a File", function(success, value)
						if success then
							if fs.exists('Desktop/'..value) then
								ButtonDialogueWindow:Initialise("File/Folder Exists!", 'A file/folder with that name already exists!', 'Ok', nil, function()end):Show()
							else
								local h = fs.open('Desktop/'..value, 'w')
								h.close()
								doIndex()
								RefreshFiles()
							end
						end
					end):Show()
					end
				},
				{
					Separator = true
				},
				{
					Title = 'Refresh',
					Click = function()
						RefreshFiles()
					end
				}
			}):Show()
		end
		
		MainDraw()
	end
end

function HandleKey(key)
	if key == keys.enter then
		Desktop.OpenSelected()
	elseif key == keys.delete or key == keys.backspace then
		Desktop.DeleteSelected()
	elseif key == keys.right then
		GoToPage(currentPage + 1)
	elseif key == keys.left then
		GoToPage(currentPage - 1)
	end
end

function DrawFile(fileName, i)
	local x, y = IconLocation(i)
	if x + 4 < 0 or x - 2 > Drawing.Screen.Width then
		return
	end
	local backgroundColour = wallpaperColour
	local textColour = colours.black

	if selectedFile and selectedFile == fileName then
		backgroundColour = colours.blue
		textColour = colours.white
	end

	--Drawing.DrawArea(x - 3, y, 9, 5, " ", colours.black, colours.grey)
	local shortenedName = Helpers.RemoveExtension(fileName)
	shortenedName = Helpers.TruncateString(shortenedName, 10)
	Drawing.DrawImage(x, y, Helpers.IconForFile('Desktop/'..fileName), 4, 3)

	if Helpers.Extension(fileName) == 'shortcut' then
		Drawing.WriteToBuffer(x+3, y+2, '>', colours.black, colours.white)
	end

	Drawing.DrawCharacters(math.floor(x+2-(#shortenedName/2)), y+3, shortenedName, textColour, backgroundColour)
end

function OpenSelected()
	if selectedFile then
		Helpers.OpenFile('Desktop/'..selectedFile)
		return true
	else
		return false
	end
end

function DeleteSelected()
	if selectedFile and selectedFile == 'Documents' then
		ButtonDialogueWindow:Initialise("Unable to delete!", 'You can not delete the Documents folder.', 'Ok', nil, function()end):Show()
		MainDraw()
		return true
	elseif selectedFile then
		ButtonDialogueWindow:Initialise("Delete '"..Helpers.TruncateString(Helpers.RemoveExtension(selectedFile), 16).."'?", "Are you sure you want to delete '"..selectedFile.."'?", 'Yes', 'Cancel', function(success)
			if success then
				fs.delete('Desktop/'..selectedFile)
				doIndex()
				RefreshFiles()
			end
		end):Show()
		MainDraw()
		return true
	else
		return false
	end
end