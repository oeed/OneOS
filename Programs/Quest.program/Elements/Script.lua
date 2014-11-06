Text = nil
URL = nil

OnInitialise = function(self, node)
	local attr = self.Attributes
	self.Text = table.concat(node, '\n')

	if attr.src then
		self.URL = attr.src
		self.Text = nil
	end
end

InsertScript = function(self, webView)
	if self.Text then
		webView:LoadScript(self.Text)
	elseif self.URL then
		fetchHTTPAsync(resolveFullUrl(self.URL), function(ok, event, response)
			if ok then
				self.Text = response.readAll()
				webView:LoadScript(self.Text)
			end
		end)

	end
	return nil
end