
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
	self:SetTargetSteer( Dir )
	self:SetTargetSpeed( 0 )

	if Dist < 3000 and self:AITargetInFront( Target, 120 ) then
		self._AIFireInput = true
	end
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