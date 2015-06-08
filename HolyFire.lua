
local function Cooldown(spell)
	local CD,Dur = GetSpellCooldown(spell)
	if CD and CD > 0 then return CD + Dur - GetTime() end
	return 0
end


local function CreateAutoButton(numStates, actionStates, stateFunc, ButtonName)
	
	local function CreateButtons(prefix, n, nState, actionState)
		local i
		for i=1,n do
			local buttonName = prefix .. nState .. "x" .. i
			local buttonFrame = CreateFrame("Button",buttonName ,UIParent,"SecureActionButtonTemplate")
			buttonFrame:SetAttribute("type","macro")
			buttonFrame:SetAttribute("macrotext", actionState .. "\n/cleartarget")
		end
	end

	local function RandString(length)
		local dict = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		local r = ""
		local l = #dict
		local p
		for i = 1, length do
		  p = math.random(l)
		  r = r.. string.sub(dict, p, p)
		end
		return r
	end


	local n = 2000
	local buttonToClick = {}
	local str = ""
	local i,index, j

	local prefix = RandString(3)
	for i=0,numStates-1 do
		CreateButtons(prefix, n, i, actionStates[i])
	end

	index = 0
	for i=1,n do
		for j=0,numStates-1 do
			index = index + 1
			buttonToClick[index] = prefix .. j .. "x" .. i
		end
	end

	local generation = 0
	while #buttonToClick > 1 do
		local newButtons = {}
		local parent, parentName
		index = 1
		for i=1,#buttonToClick do
			if not parent then
				parentName = prefix .. generation .. index
				parent = CreateFrame("Button", parentName ,UIParent,"SecureActionButtonTemplate")
				newButtons[index] = parentName
				index = index + 1
				str = ""
			end

			str = str .. "/click [exists]" .. buttonToClick[i] .. "\n"
			_G[buttonToClick[i]].parent = parent
			parent.num = parent.num and parent.num + 1 or 1

			if str:len() > 500 or i == #buttonToClick then 
				parent:SetAttribute("type","macro")
				parent:SetAttribute("macrotext",str)
				parent = nil
			end
		end
		generation = generation + 1
		buttonToClick = newButtons
	end

	local autoButton = CreateFrame("Button", ButtonName ,UIParent,"SecureActionButtonTemplate")
	autoButton:SetAttribute("type","macro")
	autoButton:SetAttribute("macrotext","/run _" .. prefix .. "()" .. "\n/stopmacro[noexists]\n/click " .. buttonToClick[1] .. "\n/targetlasttarget")

	local function getStateUpdater(prefix)
		local state = 0
		local curr = 1

		local function disable(button)
			button:SetScript("OnClick", nil)
			if button.parent then
				button.parent.num = button.parent.num - 1
				if button.parent.num <= 0 then
					disable(button.parent)
				end
			end
		end

		local function flipState(newState)
			local i
			if state == newState then return end
			if newState >= numStates then return end
			if state < newState then
				for i=state,newState-1 do
					disable(_G[prefix .. i .. "x" .. curr])
				end
				state = newState
			else
				for i=state, numStates-1 do
					disable(_G[prefix .. i .. "x" .. curr])
					state = 0
					curr = curr + 1
					flipState(newState)
				end
			end
		end

		return function(newState)
			if state ~= newState then
				flipState(newState)
			end
		end
	end

	local stateUpdater =  getStateUpdater(prefix)
	_G["_"..prefix] = function()
		stateUpdater(stateFunc())
	end
	
end

------------------------------------------------------------------------------

local numStates = 3
local holyFire = GetSpellInfo(14914)
local penance = GetSpellInfo(47540)
local smite = GetSpellInfo(585)
actionStates = {}
actionStates[0] = "/cast " .. holyFire
actionStates[1] = "/cast " .. penance
actionStates[2] = "/cast " .. smite

local function getState()
	if Cooldown(holyFire) <= Cooldown(smite) then return 0 end
	if Cooldown(penance) <= Cooldown(smite) then return 1 end
	return 2
end

CreateAutoButton(numStates, actionStates, getState, "HolyFire")