
function ENT:RunAI()
	self._AIState = "Active"
	local Target = self:AIGetTarget( 20 )
	local TargetPosLocal = self:WorldToLocal( IsValid( Target ) and Target:GetPos() or self:GetPos() )
	local YawError = math.NormalizeAngle( TargetPosLocal:Angle().y )
	local Dir = math.Clamp( YawError / 45, -1, 1 ) * 80

	self._AIFireInput = false

	if not IsValid( Target ) then
		self:AIState_Idle()
	else
		local Dist = TargetPosLocal:Length()

		if self._HoldPosition and CurTime() < ( self._AIStateEnd or 0 ) then
			self:AIState_BeginHold( Dir )
		elseif self._HoldPosition then
			self:AIState_Engage( Target, Dist, Dir )
		elseif Dist > 750 then
			self:AIState_Approach( YawError, Dir )
		else
			self:AIState_BeginHold( Dir )
		end
	end

	local pod = self:GetDriverSeat()
	if not IsValid( pod ) then return end

	local TargetPos = IsValid( Target ) and Target:LocalToWorld( Target:OBBCenter() ) or self:LocalToWorld( Vector(2000,0,150) )
	self:SetAIAimVector( (TargetPos - pod:LocalToWorld( Vector(0,0,33) )):GetNormalized() )
end

function ENT:AIState_Idle()
	self._AIState = "Idle"
	self:SetTargetSteer( 0 )
	self:SetTargetSpeed( 0 )
end

function ENT:AIState_Approach( YawError, Dir )
	self._AIState = "Approach"
	local MoveSpeed = math.abs( YawError ) > 110 and 200 or 600
	self:SetTargetSteer( Dir )
	if CurTime() < ( self._LastCapturedCollision or 0 ) + 2 then
		self:SetTargetSpeed( 0 )
	else
		self:SetTargetSpeed( MoveSpeed )
	end
end

function ENT:AIState_BeginHold( Dir )
	self._AIState = "BeginHold"
	if not self._HoldPosition then
		self._HoldPosition = true
		self._AIStateEnd = CurTime() + 1
		timer.Simple( 5, function()
			if not IsValid( self ) then return end
			self._HoldPosition = false
		end )
	end
	self:SetTargetSteer( Dir )
	self:SetTargetSpeed( 0 )
end

function ENT:AIState_Engage( Target, Dist, Dir )
	self._AIState = "Engage"
	local CurWeapon = self:GetSelectedWeapon()
	self:AISelectWeapon(2)
	timer.Simple( 0.6, function()
		if not IsValid( self ) then return end
		self:AISelectWeapon(1)
	
	end )

	self:SetTargetSteer( Dir )
	self:SetTargetSpeed( 0 )

	if Dist < 3000 and self:AITargetInFront( Target, 120 ) then
		self._AIFireInput = true
	end
end


function ENT:AISelectWeapon( ID )
	if ID == self:GetSelectedWeapon() then return end

	local T = CurTime()

	if (self._nextAISwitchWeapon or 0) > T then return end

	self._nextAISwitchWeapon = T + math.random(3,6)

	self:SelectWeapon( ID )
end


--[[
function ENT:AIGetTarget( viewcone )
	if (self._lvsNextAICheck or 0) > CurTime() then return self._LastAITarget end

	self._lvsNextAICheck = CurTime() + 2
	
	local MyPos = self:GetPos()
	local MyTeam = self:GetAITEAM()

	if MyTeam == 0 then self._LastAITarget = NULL return NULL end

	local ClosestTarget = NULL
	local TargetDistance = 60000

	if not LVS.IgnorePlayers then
		for _, ply in pairs( player.GetAll() ) do
			if not ply:Alive() then continue end

			if ply:IsFlagSet( FL_NOTARGET ) then continue end

			local Dist = (ply:GetPos() - MyPos):Length()

			if Dist > TargetDistance then continue end

			local Veh = ply:lvsGetVehicle()

			if IsValid( Veh ) then
				if self:AICanSee( Veh ) and Veh ~= self then
					local HisTeam = Veh:GetAITEAM()

					if HisTeam == 0 then continue end

					if self.AISearchCone then
						if not self:AITargetInFront( Veh, self.AISearchCone ) then continue end
					end

					if HisTeam ~= MyTeam or HisTeam == 3 then
						ClosestTarget = Veh
						TargetDistance = Dist
					end
				end
			else
				local HisTeam = ply:lvsGetAITeam()
				if not ply:IsLineOfSightClear( self ) or HisTeam == 0 then continue end

				if self.AISearchCone then
					if not self:AITargetInFront( ply, self.AISearchCone ) then continue end
				end
				
				if HisTeam ~= MyTeam or HisTeam == 3 then
					ClosestTarget = ply
					TargetDistance = Dist
				end
			end
		end
	end

	if not LVS.IgnoreNPCs then
		for _, npc in pairs( LVS:GetNPCs() ) do
			local HisTeam = LVS:GetNPCRelationship( npc:GetClass() )

			if HisTeam == 0 or (HisTeam == MyTeam and HisTeam ~= 3) then continue end

			local Dist = (npc:GetPos() - MyPos):Length()

			if Dist > TargetDistance or not self:AICanSee( npc ) then continue end

			if self.AISearchCone then
				if not self:AITargetInFront( npc, self.AISearchCone ) then continue end
			end

			ClosestTarget = npc
			TargetDistance = Dist
		end
	end

	for _, veh in pairs( LVS:GetVehicles() ) do
		if veh:IsDestroyed() then continue end

		if veh == self then continue end

		local Dist = (veh:GetPos() - MyPos):Length()

		if Dist > TargetDistance or not self:AITargetInFront( veh, (viewcone or 100) ) then continue end

		local HisTeam = veh:GetAITEAM()

		if HisTeam == 0 then continue end

		if HisTeam == self:GetAITEAM() then
			if HisTeam ~= 3 then continue end
		end

		if self.AISearchCone then
			if not self:AITargetInFront( veh, self.AISearchCone ) then continue end
		end

		if self:AICanSee( veh ) then
			ClosestTarget = veh
			TargetDistance = Dist
		end
	end

	self._LastAITarget = ClosestTarget
	
	return ClosestTarget
end
--[[
function ENT:OnAITakeDamage( dmginfo )
	local attacker = dmginfo:GetAttacker()

	if not IsValid( attacker ) then return end

	if not self:AITargetInFront( attacker, IsValid( self:AIGetTarget() ) and 120 or 45 ) then
		self:SetHardLockTarget( attacker )
	end
end

function ENT:SetHardLockTarget( target )
	if not self:IsEnemy( target ) then return end

	self._HardLockTarget = target
	self._HardLockTime = CurTime() + 4
end

function ENT:GetHardLockTarget()
	if (self._HardLockTime or 0) < CurTime() then return NULL end

	return self._HardLockTarget
end
--]]