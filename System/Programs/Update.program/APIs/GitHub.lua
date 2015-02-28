RequestURLs = nil
Username = nil
Repository = nil
QueueCallbacks = nil
CompletedRequests = nil

Initialise = function(self, username, repository, bedrock)
	local new = {}    -- the new instance
	setmetatable(new, {__index = self} )

	new.QueueCallbacks = {}
	new.CompletedRequests = {}
	new.RequestURLs = {}
	new.Bedrock = bedrock
	new.Username = username
	new.Repository = repository

	bedrock:RegisterEvent('http_success', function(self, event, url, h)
		if new:IsValidURL(url) then
			for i, v in ipairs(new.RequestURLs) do
				if v[1] == url then
					v[2](h.readAll())
					new.RequestURLs[i] = nil
				end
			end
			h.close()
		end
	end)

	bedrock:RegisterEvent('http_failure', function(self, event, url)
		if new:IsValidURL(url) then
			new:OnDataFailed('Unknown error')
		end
	end)

	return new
end

IsValidURL = function(self, url)
	for i, v in ipairs(self.RequestURLs) do
		if v[1] == url then
			return true
		end
	end
	return false
end

RemoveCompleted = function(self, url)
	for i, v in ipairs(self.RequestURLs) do
		if v[1] == url then
			self.RequestURLs[i] = nil
		end
	end
end

APIURL = function(self)
	return 'https://api.github.com/repos/' .. self.Username .. '/' .. self.Repository .. '/'
end

RawURL = function(self)
	return 'https://raw.github.com/' .. self.Username .. '/' .. self.Repository .. '/'
end

StartRequest = function(self, url, callback)
	table.insert(self.RequestURLs, {url, callback})
	local reason

	if not http then
		reason = 'Please enabled HTTP'
	elseif http.checkURL and not http.checkURL(url) then
		reason = 'Please set HTTP whitelist to "*"'
	end

	if not reason then
		local ok, err = http.request(url)
		if ok == false then -- on earlier versions ok will be nil regardless
			if err then
				reason = err
			else
				reason = 'HTTP request error'
			end
		end
	end

	if reason then
		self.Failed = true
		self:OnDataFailed(url, reason)
	end
end

StartJSONRequest = function(self, url, callback)
	self:StartRequest(self:APIURL() .. url, function(data)
		local decoded = JSON.decode(data)
		callback(decoded)
	end)
end

OnDataFailed = function(self, reason)
end

LatestRelease = function(self, allowPreRelease, callback)
	self:StartJSONRequest('releases', function(releases)
		for i, v in ipairs(releases) do
			if allowPreRelease or not v.prerelease then
				callback(v.tag_name)
				break
			end
		end
	end)
end

FileTree = function(self, sha, callback)
	self:StartJSONRequest('git/trees/' .. sha .. '?recursive=1', function(tree)
		callback(tree.tree)
	end)
end

local blacklist = {
	'.gitignore',
	'README.md',
	'TODO',
	'.Desktop.settings',
	'.version'
}

IsBlacklisted = function(self, path)
	for i, item in ipairs(blacklist) do
		if item == path then
			return true
		end
	end
	return false
end

DownloadFiles = function(self, release, callback)
	self:StartRequest('http://cc.olivercooper.me/oneos/update.php?v=' .. release, function(data)
		callback(data)
	end)
end

InstallFiles = function(self, data, callback)
	local decoded = JSON.decode(data)

	local function saveFolder(path, tbl)
		fs.makeDir(path)
		for k, v in pairs(tbl) do
			if self:IsBlacklisted(k) then
			elseif type(v) == 'table' then
				saveFolder(path .. k .. '/', v)
			else
				local h = fs.open(path .. k, 'w')
				h.write(k:gsub('\/', '/'))
				h.close()
			end
		end
	end

	-- TODO: make this just /
	saveFolder('/update/', decoded)

	if fs.exists('/System/.onupdate') then
		dofile('/System/.onupdate')
		fs.delete('/System/.onupdate')
	end

	callback()
end

SaveVersion = function(self, version)
	local h = fs.open('/System/.version', 'w')
	h.write(version)
	h.close()
end