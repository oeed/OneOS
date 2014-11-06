Inherit = 'ScrollView'
URL = nil
FakeURL = nil
LoadingURL = nil
Tree = nil
BackgroundColour = colours.white
ScriptEnvironment = nil
Timers = nil
Download = nil

-- TODO: strip this down to remove positioning stuff
UpdateLayout = function(self)
	self:RemoveAllObjects()
	self.BackgroundColour = colours.white
	local body = self.Tree:GetElement('body')

	--TODO: check that body exists, if not redirect to an error page

	if body.BackgroundColour then
		self.BackgroundColour = body.BackgroundColour
	end

	local node = true
	node = function(children, parentObject)
		local currentY = 1
		for i, v in ipairs(children) do
			local object = v:CreateObject(parentObject, currentY)
			if object then
				v.Object = object
				if v.Children and #v.Children > 0 and object.Children then
					local usedY = node(v.Children, object)
					if not v.Attributes.height then
						object.Height = usedY
					end
					object:OnUpdate('Children')
				end
				-- if not object.Height then
				-- 	for k, v in pairs(object) do
				-- 		error(v)
				-- 	end	
				-- 	error('Nope')
				-- end
				currentY = currentY + object.Height
			end
		end
		return currentY - 1
	end
	node(body.Children, self)
	
	self:RepositionLayout()

	local head = self.Tree:GetElement('head')
	if head then
		for i, child in ipairs(head.Children) do
			if child.Tag == 'script' then
				child:InsertScript(self)
			end
		end
	end
end

RepositionLayout = function(self)
	local node = true
	node = function(children, isFloat, parent)
		if parent.OnRecalculateStart then
			parent:OnRecalculateStart()
		end

		local currentY = 1
		local currentX = 1
		local tallestChild = 1
		for i, child in ipairs(children) do
			if child.Type ~= 'ScrollBar' then
				if isFloat then
					if currentX ~= 1 and parent.Width - currentX + 1 < child.Width then
						currentX = 1
						currentY = currentY + tallestChild
						tallestChild = 1
					end

					if parent.Align == "Left" then
						child.X = currentX
					elseif parent.Align == "Right" then
						child.X = parent.Width - currentX - child.Width + 2
					end
				end
				child.Y = currentY

				if child.Children and #child.Children > 0 then
					local usedY = node(child.Children, child.IsFloat, child)
					child:OnUpdate('Children')
					if not child.Element.Attributes.height then
						child.Height = usedY
					end
				end

				if child.Height > tallestChild then
					tallestChild = child.Height
				end

				if isFloat then
					currentX = currentX + child.Width
				else
					currentY = currentY + child.Height
				end
			end
		end
		if isFloat then
			currentY = currentY + tallestChild
		end
		if parent.OnRecalculateEnd then
			currentY = parent:OnRecalculateEnd(currentY)
		end
		return currentY - 1
	end
	node(self.Children, self.IsFloat, self)

	self:UpdateScroll()
end

GoToURL = function(self, url, nonVerbose, noHistory, post)
	self.BackgroundColour = colours.white
	self:RemoveAllObjects()
	if self.OnPageLoadStart and not nonVerbose then
		self:OnPageLoadStart(url, noHistory)
	end
	self.LoadingURL = url
	if not nonVerbose then
		self.FakeURL = url
	end
	self:InitialiseScriptEnvironment()

	if not http and url:find('http://') then
		if self.OnPageLoadFailed then
			self:OnPageLoadFailed(url, 4, noHistory)
		end
		return
	end

	-- error(fs.getName(url))
	local parts = urlComponents(url)
	-- if url:sub(#url) ~= '/' and url:find('?') then
	-- 	fileName = fs.getName(url:sub(1, url:find('?') - 1))
	-- else
	-- 	fileName = fs.getName(url)
	-- end

	local fileName = parts.filename
	local extension
	if fileName == '' or url:sub(#url) == '/' then
		extension = true
	else
		extension = fileName:match('%.[0-9a-z%?%%]+$')
		if extension then
			extension = extension:sub(2)
		end
	end

	-- local nonDownloadExtensions = {}
	-- local shouldDownload =  not extension or (extension ~= true and extension ~= '' and extension ~= 'ccml' and extension ~= 'html' and extension ~= 'php' and extension ~= 'asp' and extension ~= 'aspx' and extension ~= 'jsp' and extension ~= 'qst' and extension ~= 'com' and extension ~= 'me' and extension ~= 'net' and extension ~= 'info' and extension ~= 'au' and extension ~= 'nz' and extension ~= 'de') 

	if not url:find('quest://download.ccml') and not url:find('quest://downloaded.ccml') then
		self.Download = nil
	end

	fetchHTTPAsync(url, function(ok, event, response)
		self.LoadingURL = nil
		if ok then
			if response.getResponseCode then
				local code = response.getResponseCode()
				if code ~= 200 then
					if self.OnPageLoadFailed then
						self:OnPageLoadFailed(url, code, noHistory)
					end
					response.close()
					return
				end
			end

			local html = response.readAll()
			response.close()
			if html:sub(1,9):lower() == '<!doctype' then
				--web page
				self.Tree, err = ElementTree:Initialise(html)
				if not err then
					self.URL = url
					self:UpdateLayout()
					if self.OnPageLoadEnd and not nonVerbose then
						self:OnPageLoadEnd(url, noHistory)
					end
				else
					if self.OnPageLoadFailed then
						self:OnPageLoadFailed(url, err, noHistory)
					end
				end
			else
				--download
				local downloadsFolder = '/Downloads/'
				local _fs = fs
				if OneOS then
					downloadsFolder = '/Desktop/Documents/Downloads/'
					_fs = OneOS.FS
				end
				if not _fs.exists(downloadsFolder) then
					_fs.makeDir(downloadsFolder)
				end

				local downloadPath = downloadsFolder..fileName
				local i = 1
				local name = Bedrock.Helpers.RemoveExtension(fileName)
				local ext = Bedrock.Helpers.Extension(fileName, true)
				while _fs.exists(downloadPath) do
					i = i + 1
					downloadPath = downloadsFolder..name .. ' (' .. i .. ')' .. ext
				end
				local f = _fs.open(downloadPath, 'w')
				if f then
					f.write(html)
					f.close()
					self:GoToURL('quest://downloaded.ccml?path='..textutils.urlEncode(downloadPath), true, true)
					self:OnPageLoadEnd(url, noHistory)
				else
					self:OnPageLoadFailed(url, 6, noHistory)
				end
			end
		elseif self.OnPageLoadFailed and not nonVerbose then
			self:OnPageLoadFailed(url, event, noHistory)
		end
	end, post)
end

Stop = function(self)
	cancelHTTPAsync(self.LoadingURL)
	if self.OnPageLoadFailed then
		self:OnPageLoadFailed(url, Errors.TimeoutStop)
	end
end

ResolveElements = function(self, selector)
	local elements = {}
	local node = true
	local isClass = false
	if selector:sub(1,1) == '.' then
		isClass = true
	end

	node = function(tbl)
		for i,v in ipairs(tbl) do
			if type(v) == 'table' and v.Tag then
				if not isClass and v.Tag:lower() == selector:lower() then
					table.insert(elements, v.Object)
				elseif isClass and v.Attributes.class and v.Attributes.class:lower() == selector:lower():sub(2) then
					table.insert(elements, v.Object)
				end
				if v.Children then
					local r = node(v.Children)
				end
			end
		end
	end
	node(self.Tree.Tree)
	return elements
end

InitialiseScriptEnvironment = function(self)
	lQuery.webView = self
	if self.Timers then
		for i, timer in ipairs(self.Timers) do
			-- error('clear '..timer)
			self.Bedrock.Timers[timer] = nil
		end
	end
	self.Timers = {}

	local getValues = urlComponents(self.LoadingURL).get

	self.ScriptEnvironment = {
		keys = keys,
		printError = printError, -- maybe don't have this
		assert = assert,
		getfenv = getfenv,
		bit = bit,
		rawset = rawset,
		tonumber = tonumber,
		loadstring = loadstring,
		error = error, -- maybe don't have this
		tostring = tostring,
		type = type,
		coroutine = coroutine,
		next = next,
		unpack = unpack,
		colours = colours,
		pcall = pcall,
		math = math,
		pairs = pairs,
		rawget = rawget,
		_G = _G,
		__inext = __inext,
		read = read,
		ipairs = ipairs,
		xpcall = xpcall,
		rawequal = rawequal,
		setfenv = setfenv,
		http = http, --create an ajax thing to replace this
		string = string,
		setmetatable = setmetatable,
		getmetatable = getmetatable,
		table = table,
		parallel = parallel, -- this mightn't work properly
		textutils = textutils,
		colors = colors,
		vector = vector,
		select = select,
		os = {
			version = os.version,
			getComputerID = os.getComputerID,
			getComputerLabel = os.getComputerLabel,
			clock = os.clock,
			time = os.time,
			day = os.day,
		},
		lQuery = lQuery.fn,
		l = lQuery.fn,
		setTimeout = function(func, delay)
			if type(func) == 'function' and type(delay) == 'number' then
				local t = self.Bedrock:StartTimer(func, delay)
				table.insert(self.Timers, t)
				return t
			end
		end,
		setInterval = function(func, interval)
			if type(func) == 'function' and type(interval) == 'number' then
				local t = self.Bedrock:StartRepeatingTimer(function(timer)
					table.insert(self.Timers, timer)
					func()
				end, interval)
				table.insert(self.Timers, t)
				return t
			end
		end,
		clearTimeout = function(timer)
			self.Bedrock.Timers[timer] = nil
		end,
		clearInterval = function(timer)
			self.Bedrock.Timers[timer] = nil
		end,
		window = {
			location = self.URL,
			realLocation = self.LoadingURL,
			get = getValues,
			version = QuestVersion
		}
	}
end

LoadScript = function(self, script)
	local fn, err = loadstring(script, 'Script Tag Error: '..self.URL)
	if fn then
		setfenv(fn, self.ScriptEnvironment)
		fn()
	else
		local start = err:find(': ')
		self:OnPageLoadFailed(url, err:sub(start + 2), noHistory)
	end
end

RemoveElement = function(self, elem)
	local elements = {}
	local node = true
	node = function(tbl)
		for i,v in ipairs(tbl) do
			if type(v) == 'table' then
				if v == elem.Element then
					elem.Parent:RemoveObject(elem)
					v = nil
					return
				end
				if v.Children then
					local r = node(v.Children)
				end
			end
		end
	end
	node(self.Tree.Tree)
end