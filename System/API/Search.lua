function Open()
	Log.i('Opening search')
	Current.SearchActive = true
	Current.Bedrock:GetObject('ClickCatcherView').Z = 999
	Current.Bedrock:GetObject('ClickCatcherView').Visible = true
	Current.Bedrock:GetObject('SearchTextBox').Text = ''
	Current.Bedrock:GetObject('SearchButton').Toggle = true
	Current.Bedrock:SetActiveObject(Current.Bedrock:GetObject('SearchTextBox'))
	Current.Bedrock:GetObject('SearchView'):UpdateSearch()
	AnimateOpenClose()
end

function Close()
	Log.i('Closing search')
	Current.SearchActive = false
	Current.Bedrock:GetObject('ClickCatcherView').Z = 1
	Current.Bedrock:GetObject('ClickCatcherView').Visible = false
	Current.Bedrock:GetObject('SearchButton').Toggle = false
	Current.Bedrock:SetActiveObject(Current.ProgramView)
	AnimateOpenClose()
end

function SetOffset(offset)
	for i, v in ipairs(Current.Bedrock.View.Children) do
		if v.Name ~= 'SearchView' then
			v.X = offset
		end
	end
end

function AnimateOpenClose()
	local openX = -Current.Bedrock:GetObject('SearchView').Width + 1
	if Settings:GetValues()['UseAnimations'] then
		for i = 1, 5 do
			SetOffset((Current.SearchActive and i * (openX / 5) or 1 + openX - i * (openX / 5)))
			Current.Bedrock:Draw()
			sleep(0.05)
		end
	end

	if Current.SearchActive then
		SetOffset(openX)
	else
		SetOffset(1)
	end
end