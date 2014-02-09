	local defaultTimeout = 1
	local state = "Idle"



	RelativePosition = {
		X = 0,
		Y = 0,
		Z = 0,
		Rotation = 0
	}

	function SetHome()
		Turtle.RelativePosition = {
			X = 0,
			Y = 0,
			Z = 0,
			Rotation = 0
		}
	end

	function GoHome(x, y, z)
		if x == nil and Turtle.RelativePosition.X ~= 0 then
			if Turtle.RelativePosition.X < 0 then
				Turtle.DigMoveForward(-1*Turtle.RelativePosition.X)
			elseif Turtle.RelativePosition.X > 0 then
				RotateTo(2)
				Turtle.DigMoveForward(Turtle.RelativePosition.X)
			end
		end

		if z == nil and Turtle.RelativePosition.Z ~= 0 then
			if Turtle.RelativePosition.Z < 0 then
				RotateTo(1)
				Turtle.DigMoveForward(-1*Turtle.RelativePosition.Z)
			elseif Turtle.RelativePosition.Z > 0 then
				RotateTo(3)
				Turtle.DigMoveForward(Turtle.RelativePosition.Z)
			end
		end
		
		if y == nil and Turtle.RelativePosition.Y ~= 0 then
			if Turtle.RelativePosition.Y < 0 then
				Turtle.DigMoveUp(-1*Turtle.RelativePosition.Y)
			elseif Turtle.RelativePosition.Y > 0 then
				Turtle.DigMoveDown(Turtle.RelativePosition.Y)
			end
		end

		RotateTo(0)
	end

	function RotateTo(rotation)
		print(Turtle.RelativePosition.Rotation..' i')
		if Turtle.RelativePosition.Rotation ~= rotation then
			if Turtle.RelativePosition.Rotation < rotation + 1 then
				print('one')
				print(rotation - Turtle.RelativePosition.Rotation)
				Turtle.TurnLeft(rotation - Turtle.RelativePosition.Rotation)
			else
				print('two')
				print(rotation-Turtle.RelativePosition.Rotation)
				Turtle.TurnLeft(-1*(rotation-Turtle.RelativePosition.Rotation))
			end				
		end
		print(Turtle.RelativePosition.Rotation..' b')		
	end

	function UpdateRelativePosition(deltaX, deltaY, deltaRotation)
		if deltaRotation then
			Turtle.RelativePosition.Rotation = Turtle.RelativePosition.Rotation + deltaRotation
			Turtle.RelativePosition.Rotation = ((Turtle.RelativePosition.Rotation%4) +4)%4
		end

		if deltaY then
			Turtle.RelativePosition.Y = Turtle.RelativePosition.Y + deltaY
		end

		if deltaX then
			if Turtle.RelativePosition.Rotation == 0 then
				Turtle.RelativePosition.X = Turtle.RelativePosition.X + deltaX
			elseif Turtle.RelativePosition.Rotation == 2 then
				Turtle.RelativePosition.X = Turtle.RelativePosition.X - deltaX
			elseif Turtle.RelativePosition.Rotation == 1 then
				Turtle.RelativePosition.Z = Turtle.RelativePosition.Z - deltaX
			elseif Turtle.RelativePosition.Rotation == 3 then
				Turtle.RelativePosition.Z = Turtle.RelativePosition.Z + deltaX
			else
			end
		end
	end

	function SendMessage(message, getReply, timeout)
		local _m = Wireless.SendMessage(Wireless.Channels.TurtleRemote, message, Wireless.Channels.TurtleRemoteReply)
		if getReply then
			return Wireless.RecieveMessage(Wireless.Channels.TurtleRemoteReply, _m.messageID, timeout)
		end
	end

	function Ping()
		SendMessage('Ping!', true)
	end

	function Forward(distance)
		return Move('forward', distance)
	end

	function Back(distance)
		return Move('back', distance)
	end

	function Up(distance)
		return Move('up', distance)
	end

	function Down(distance)
		return Move('down', distance)
	end

	function Move(direction, distance)
		distance = distance or 1
		if not turtle then
			local timeout = (distance * 0.5) + defaultTimeout
			local _,_,_,_, message = SendMessage({
				action = 'move',
				direction = direction,
				distance = distance
			}, true, timeout)
			if message then
				return message.content.success, message.content.distance, message.reason
			else
				return nil
			end
		else
			local func = turtle.forward
			if direction == 'back' then
				func = turtle.back
			elseif direction == 'forward' then
				func = turtle.forward
			elseif direction == 'up' then
				func = turtle.up
			elseif direction == 'down' then
				func = turtle.down
			end
			local moved = 0
			for i = 1, distance do
				if func() then
					moved = moved + 1
				end
			end

			if direction == 'back' then
				UpdateRelativePosition(-moved)
			elseif direction == 'forward' then
				UpdateRelativePosition(moved)
			elseif direction == 'up' then
				UpdateRelativePosition(nil, moved)
			elseif direction == 'down' then
				UpdateRelativePosition(nil, -moved)
			end

			local reason = nil
			if moved ~= distance then
				_, reason = func()
			end

			return moved == distance, moved, reason
		end
	end

	function TurnLeft(turns)
		turns = turns or 1
		return Turn(true, turns)
	end

	function TurnRight(turns)
		turns = turns or 1
		return Turn(false, turns)
	end

	function Turn(left, turns)
		if not turtle then
			local timeout = (turns * 0.5) + defaultTimeout
			local _,_,_,_, message = SendMessage({
				action = 'turn',
				left = left,
				turns = turns
			}, true, timeout)
			if message then
				return message.content.success, message.content.turns
			else
				return nil
			end
		else
			local func = turtle.turnRight
			if left then
				func = turtle.turnLeft
			end

			local moved = 0
			for i = 1, turns do
				if func() then
					moved = moved + 1
				end
			end

			if left then
				UpdateRelativePosition(nil, nil, -turns)
			else
				UpdateRelativePosition(nil, nil, turns)
			end

			return moved == turns, moved
		end
	end

	function DigUp()
		return Dig('up')
	end

	function DigDown()
		return Dig('down')
	end

	function Dig(direction)
		direction = direction or 'forward'

		if not turtle then

			local _,_,_,_, message = SendMessage({
				action = 'dig',
				direction = direction
			}, true, defaultTimeout + 0.4)
			if message then
				return message.content.success
			else
				return nil
			end
		else
			local func = turtle.dig
			if direction == 'up' then
				func = turtle.digUp
			elseif direction == 'down' then
				func = turtle.digDown
			end

			return func()
		end
	end

	function DigMoveForward(distance)
		distance = distance or 1
		local remaining = distance
		local lastSuccess = true
		while remaining > 0 do
			local success, moved = Forward(remaining)
			sleep(0.05)
			moved = moved or 0
			remaining = remaining - moved
			if not success then
				local digSuccess = Dig()
				if not digSuccess and not lastSuccess then
					return
				end

				lastSuccess = digSuccess
			end
		end
	end

	function DigMoveDown(distance)
		distance = distance or 1
		local remaining = distance
		local lastSuccess = true
		while remaining > 0 do
			local success, moved = Down(remaining)
			moved = moved or 0
			remaining = remaining - moved
			if not success then
				local digSuccess = DigDown()
				if not digSuccess and not lastSuccess then
					return
				end
				
				lastSuccess = digSuccess
			end
		end
	end

	function DigMoveUp(distance)
		distance = distance or 1
		local remaining = distance
		local lastSuccess = true
		while remaining > 0 do
			local success, moved = Up(remaining)
			moved = moved or 0
			remaining = remaining - moved
			if not success then
				local digSuccess = DigUp()
				if not digSuccess and not lastSuccess then
					return
				end
				
				lastSuccess = digSuccess
			end
		end
	end

	function FuelLevel()
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'fuelLevel'
			}, true)
			if message then
				return message.content.value
			else
				return nil
			end
		else
			return turtle.getFuelLevel()
		end
	end

	function ItemCount(slot)
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'itemCount',
				slot = slot
			}, true)
			if message then
				return message.content.value
			else
				return nil
			end
		else
			return turtle.getItemCount(slot)
		end		
	end

	function ItemSpace(slot)
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'itemSpace',
				slot = slot
			}, true)
			if message then
				return message.content.value
			else
				return nil
			end
		else
			return turtle.getItemSpace(slot)
		end		
	end

	function Refuel(amount)
		amount = amount or 64
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'refuel',
				amount = amount
			}, true, defaultTimeout + (0.05*16))
			if message then
				return message.content.success, message.content.slot
			else
				return nil
			end
		else
			local success = false
			local slot = nil
			for i = 1, 16 do
				if ItemCount(i) > 0 then
					turtle.select(i)
					if turtle.refuel(amount) then
						success = true
						slot = i
						break
					end
				end
			end

			return success, slot
		end
	end

	function PlaceUp(slot)
		return Place(slot, 'up')
	end

	function PlaceDown(slot)
		return Place(slot, 'down')
	end

	function Place(slot, direction)
		direction = direction or 'forward'
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'place',
				slot = slot,
				direction = direction
			}, true, defaultTimeout + 0.4)
			if message then
				return message.content.success
			else
				return nil
			end
		else
			if slot then
				turtle.select(slot)
			end
			
			local func = turtle.place
			if direction == 'up' then
				func = turtle.placeUp
			elseif direction == 'down' then
				func = turtle.placeDown
			end

			return func()
		end
	end

	function AttackUp(times)
		times = times or 0
		return Place(times, 'up')
	end

	function AttackDown(times)
		times = times or 0
		return Attack(times, 'down')
	end

	function Attack(times, direction)
		times = times or 0
		direction = direction or 'forward'
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'attack',
				direction = direction,
				times = times
			}, true, defaultTimeout + 8)
			if message then
				return message.content.success
			else
				return nil
			end
		else
			
			local func = turtle.attack
			if direction == 'up' then
				func = turtle.attackUp
			elseif direction == 'down' then
				func = turtle.attackDown
			end
			local success = false
			if times ~= 0 then
				success = func()
				for i = 1, times-1 do
					success = func()
				end
			else
				success = func()
				local present = success
				while present do
					sleep(0.4)
					present = func()
				end
			end

			return success
		end
	end

	function DetectUp()
		return Detect('up')
	end

	function DetectDown()
		return Detect('down')
	end

	function Detect(direction)
		direction = direction or 'forward'
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'detect',
				direction = direction
			}, true, defaultTimeout + 0.05)
			if message then
				return message.content.success
			else
				return nil
			end
		else
			
			local func = turtle.detect
			if direction == 'up' then
				func = turtle.detectUp
			elseif direction == 'down' then
				func = turtle.detectDown
			end

			return func()
		end
	end

	function CompareUp(slot)
		return Detect(slot, 'up')
	end

	function CompareDown(slot)
		return Detect(slot, 'down')
	end

	function Compare(slot, direction)
		direction = direction or 'forward'
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'compare',
				direction = direction,
				slot = slot
			}, true, defaultTimeout + 0.05)
			if message then
				return message.content.success
			else
				return nil
			end
		else
			
			local func = turtle.compare
			if direction == 'up' then
				func = turtle.compareUp
			elseif direction == 'down' then
				func = turtle.compareDown
			end

			if slot then
				turtle.select(slot)
			end

			return func()
		end
	end

	function DropUp(amount, slot)
		return Detect(amount, slot, 'up')
	end

	function DropDown(amount, slot)
		return Detect(amount, slot, 'down')
	end

	function Drop(amount, slot, direction)
		amount = amount or 64
		direction = direction or 'forward'
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'drop',
				direction = direction,
				amount = amount,
				slot = slot
			}, true, defaultTimeout + 0.05)
			if message then
				return message.content.success
			else
				return nil
			end
		else
			
			local func = turtle.drop
			if direction == 'up' then
				func = turtle.dropUp
			elseif direction == 'down' then
				func = turtle.dropDown
			end

			if slot then
				turtle.select(slot)
			end
			local success = func(amount)

			return 
		end
	end

	function DropAll(direction)
		direction = direction or 'forward'
		for i = 1, 16 do
			if Turtle.ItemCount(i) ~= 0 then
				Drop(64, i, direction)
			end
		end
	end

	function SuckUp(slot)
		return Detect(slot, 'up')
	end

	function SuckDown(slot)
		return Detect(slot, 'down')
	end

	function Suck(slot, direction)
		direction = direction or 'forward'
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'suck',
				direction = direction,
				amount = amount,
				slot = slot
			}, true, defaultTimeout + 0.05)
			if message then
				return message.content.success
			else
				return nil
			end
		else
			
			local func = turtle.suck
			if direction == 'up' then
				func = turtle.suckUp
			elseif direction == 'down' then
				func = turtle.suckDown
			end

			if slot then
				turtle.select(slot)
			end
			local success = func()

			return 
		end
	end

	function CompareTo(slot, otherSlot)
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'compareTo',
				slot = slot,
				otherSlot = otherSlot
			}, true, defaultTimeout + 0.05)
			if message then
				return message.content.success
			else
				return nil
			end
		else
			
			if otherSlot then
				turtle.select(slot)
			end
			
			local success = turtle.compareTo(slot)
			return 
		end		
	end

	function GetState()
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'getState'
			}, true, defaultTimeout + 0.05)
			if message then
				return message.content.value
			else
				return nil
			end
		else
			return state
		end	
	end

	function SetState(value)
		if not turtle then
			local _,_,_,_, message = SendMessage({
				action = 'setState',
				value = value
			}, true, defaultTimeout + 0.05)
			if message then
				return message.content.success
			else
				return nil
			end
		else
			state = value
			return state == _state
		end	
	end

	function HandleMessage(m)
		local reponse = nil
		if m.action == 'move' then
			response = 'Pong!'
		elseif m.action == 'move' then
			local success, distance, reason = Move(m.direction, m.distance)
			response = {
				success = success,
				distance = distance,
				reason = reason
			}
		elseif m.action == 'turn' then
			local success, distance = Turn(m.left, m.turns)
			response = {
				success = success,
				turns = turns
			}
		elseif m.action == 'dig' then
			local success = Dig(m.direction)
			response = {
				success = success
			}
		elseif m.action == 'fuelLevel' then
			local value = FuelLevel()
			response = {
				value = value
			}
		elseif m.action == 'refuel' then
			local success, slot = Refuel(m.amount)
			response = {
				success = success,
				slot = slot
			}
		elseif m.action == 'itemCount' then
			local value = ItemCount(m.slot)
			response = {
				value = value
			}
		elseif m.action == 'itemSpace' then
			local value = ItemSpace(m.slot)
			response = {
				value = value
			}
		elseif m.action == 'place' then
			local success = Place(m.direction, m.slot)
			response = {
				success = success
			}
		elseif m.action == 'attack' then
			local success = Attack(m.times, m.direction)
			response = {
				success = success
			}
		elseif m.action == 'detect' then
			local success = Detect(m.direction)
			response = {
				success = success
			}
		elseif m.action == 'compare' then
			local success = Compare(m.slot, m.direction)
			response = {
				success = success
			}		
		elseif m.action == 'drop' then
			local success = Drop(m.amount, m.slot, m.direction)
			response = {
				success = success
			}
		elseif m.action == 'suck' then
			local success = Suck(m.slot, m.direction)
			response = {
				success = success
			}		
		elseif m.action == 'compareTo' then
			local success = CompareTo(m.slot, m.otherSlot)
			response = {
				success = success
			}		
		elseif m.action == 'getState' then
			local value = GetState()
			response = {
				value = value
			}
		elseif m.action == 'setState' then
			local success = SetState(m.value)
			response = {
				success = success
			}
		end
		return response
	end

	function Reply(m, id)
		Wireless.SendMessage(Wireless.Channels.TurtleRemoteReply, m, Wireless.Channels.TurtleRemote, id)
	end