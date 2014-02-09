--[[
tArgs = {...}

Settings = {
	InstallPath = '/', --Where the program's installed, don't always asume root (if it's run under something like OneOS)
	Hidden = true, --Whether or not the update is hidden (doesn't write to the screen), useful for background updates
	GitHubUsername = 'oeed', --Your GitHub username as it appears in the URL
	GitHubRepoName = 'OneOS', --The repo name as it appears in the URL
	DownloadReleases = true, --If true it will download the latest release, otherwise it will download the files as they currently appear
	UpdateFunction = nil, --Sent when something happens (file downloaded etc.)
	TotalBytes = 20, --Do not change this value (especially programatically)!
	DownloadedBytes = 0, --Do not change this value (especially programatically)!
	Status = 'Finding latest version',
}

if tArgs[1] and type(tArgs[1]) == 'function' then
	Settings.UpdateFunction = tArgs[1]
end


for i = 1, 20 do
	sleep(0.1)
	Settings.DownloadedBytes = Settings.DownloadedBytes + 1
	Settings.UpdateFunction()
end	
]]--

tArgs = {...}

Settings = {
	InstallPath = '/', --Where the program's installed, don't always asume root (if it's run under something like OneOS)
	Hidden = true, --Whether or not the update is hidden (doesn't write to the screen), useful for background updates
	GitHubUsername = 'oeed', --Your GitHub username as it appears in the URL
	GitHubRepoName = 'OneOS', --The repo name as it appears in the URL
	DownloadReleases = true, --If true it will download the latest release, otherwise it will download the files as they currently appear
	UpdateFunction = nil, --Sent when something happens (file downloaded etc.)
	TotalBytes = 0, --Do not change this value (especially programatically)!
	DownloadedBytes = 0, --Do not change this value (especially programatically)!
	Status = '',
	SecondaryStatus = '',
}

if tArgs[1] and type(tArgs[1]) == 'function' then
	Settings.UpdateFunction = tArgs[1]
end

os.loadAPI('/System/JSON')

local oldPrint = print

function print(...)
	local str = {...}
	if not Settings.Hidden then
		oldPrint(str[1])
	end
	Settings.Status = str[1]
	Settings.SecondaryStatus = str[2]
	Settings.UpdateFunction()
end

function downloadJSON(path)
	local _json = http.get(path)
	if not _json then
		error('Could not download, check your connection.')
	end
	return JSON.decode(_json.readAll())
end

if http then
	print('HTTP enabled, attempting update...')
else
	error('HTTP is required to update.')
end

print('Downloading releases list...', 'Determining Latest Version')
local releases = downloadJSON('https://api.github.com/repos/'..Settings.GitHubUsername..'/'..Settings.GitHubRepoName..'/releases')
local latestReleaseTag = releases[1].tag_name
print('Latest release: '..latestReleaseTag)
print('Downloading refs...', 'Optaining Latest Version URL')
local refs = downloadJSON('https://api.github.com/repos/'..Settings.GitHubUsername..'/'..Settings.GitHubRepoName..'/git/refs')
local latestReleaseSha = ''
for i, v in ipairs(refs) do
	if v.ref == 'refs/tags/'..latestReleaseTag then
		latestReleaseSha = v.object.sha
	end
end

print('Downloading tree for SHA: '..latestReleaseSha, 'Downloading File Listing')
local tree = downloadJSON('https://api.github.com/repos/'..Settings.GitHubUsername..'/'..Settings.GitHubRepoName..'/git/trees/'..latestReleaseSha..'?recursive=1').tree

local blacklist = {
	'/.gitignore',
	'/README.md',
	'/TODO',
	'/Desktop/.Desktop.settings',
	'/System/.OneOS.settings',
	'/.version'
}

function isBlacklisted(path)
	for i, item in ipairs(blacklist) do
		if item == path then
			return true
		end
	end
	return false
end

Settings.TotalFiles = 0
Settings.TotalBytes = 0
for i, v in ipairs(tree) do
	if not isBlacklisted(Settings.InstallPath..v.path) and v.size then
		Settings.TotalBytes = Settings.TotalBytes + v.size
		Settings.TotalFiles = Settings.TotalFiles + 1
	end
end

Settings.DownloadedBytes = 0
Settings.DownloadedFiles = 0
function downloadBlob(v)
	if isBlacklisted(Settings.InstallPath..v.path) then
		return
	end
	if v.type == 'tree' then
		print('Making folder: '..'/.update/'..Settings.InstallPath..v.path, 'Making folder: '..'/.update/'..Settings.InstallPath..v.path)
		fs.makeDir('/.update/'..Settings.InstallPath..v.path)
	else
		print('(' .. Settings.DownloadedBytes .. 'B/' .. Settings.TotalBytes .. 'B) Downloading file: '..Settings.InstallPath..v.path, Settings.InstallPath..v.path, 'Downloading files...')
		local f = http.get(('https://raw.github.com/'..Settings.GitHubUsername..'/'..Settings.GitHubRepoName..'/'..latestReleaseTag..Settings.InstallPath..v.path):gsub(' ','%%20'))
		if not f then
			error('Downloading failed, try again. '..('https://raw.github.com/'..Settings.GitHubUsername..'/'..Settings.GitHubRepoName..'/'..latestReleaseTag..Settings.InstallPath..v.path):gsub(' ','%%20'))
		end
		local h = fs.open('/.update/'..Settings.InstallPath..v.path, 'w')
		h.write(f.readAll())
		h.close()

		if v.size then
			Settings.DownloadedBytes = Settings.DownloadedBytes + v.size
		end
		Settings.DownloadedFiles = Settings.DownloadedFiles + 1
		Settings.UpdateFunction()
	end
end

local downloads = {}
fs.makeDir('/.update/')
for i, v in ipairs(tree) do
	--parallel.waitForAny(function() sleep(0) end, function()downloadBlob(v)end)
	--downloadBlob(v)
	table.insert(downloads, function()downloadBlob(v)end)
end


Settings.UpdateFunction()
parallel.waitForAll(unpack(downloads))

local h = fs.open('/.update/.version', 'w')
h.write(latestReleaseTag)
h.close()