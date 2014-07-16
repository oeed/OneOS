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

function AnimateOpenClose()
	local openX = -Current.Bedrock:GetObject('SearchView').Width
	if Settings:GetValues()['UseAnimations'] then
		for i = 1, 5 do
			Current.Bedrock.View.ChildOffset = {X = (Current.SearchActive and i * (openX / 5) or openX - i * (openX / 5)), Y = 0}
			Current.Bedrock:Draw()
			sleep(0.05)
		end
	end

	if Current.SearchActive then
		Current.Bedrock.View.ChildOffset = {X = openX, Y = 0}
	else
		Current.Bedrock.View.ChildOffset = {X = 0, Y = 0}
	end
end