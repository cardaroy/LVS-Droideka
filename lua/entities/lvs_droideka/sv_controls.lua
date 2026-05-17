
function ENT:TransformNormal( ent, Normal )
	ent.smNormal = ent.smNormal and ent.smNormal + (Normal - ent.smNormal) * FrameTime() * 2 or Normal

	return ent.smNormal
end

function ENT:SetTargetSteer( num )
	self._TargetSteer = num
end

function ENT:SetTargetSpeed( num )
	self._TargetVel = num
end

function ENT:GetTargetSpeed()
	local TargetSpeed = (self._TargetVel or 0)

	return TargetSpeed
end

function ENT:GetTargetSteer()
	return (self._TargetSteer or 0)
end

function ENT:ApproachTargetSpeed( MoveX )
	local Cur = self:GetTargetSpeed()
	local New = Cur + (MoveX - Cur) * FrameTime() * 10
	self:SetTargetSpeed( New )
end

function ENT:CalcThrottle( ply, cmd )
	local MoveSpeed = cmd:KeyDown( IN_SPEED ) and 600 or 50
	local MoveX = (cmd:KeyDown( IN_FORWARD ) and MoveSpeed or 0) + (cmd:KeyDown( IN_BACK ) and -MoveSpeed or 0)

	self:ApproachTargetSpeed( MoveX )
end

function ENT:CalcSteer( ply, cmd )
	local KeyLeft = cmd:KeyDown( IN_MOVELEFT )
	local KeyRight = cmd:KeyDown( IN_MOVERIGHT )
	local Steer = ((KeyLeft and 1 or 0) - (KeyRight and 1 or 0)) * 0.2 * math.max( math.abs( self:GetTargetSpeed() ), 100 )
	

	local Cur = self:GetTargetSteer()
	local RotateSpeed = 5
	--local RotateSpeed = cmd:KeyDown( IN_SPEED ) and 7.5 or 5
	local New = Cur + (Steer - Cur) * FrameTime() * RotateSpeed

	self:SetTargetSteer( New )
end

function ENT:StartCommand( ply, cmd )
	if self:GetDriver() ~= ply then return end

	self:CalcThrottle( ply, cmd )
	self:CalcSteer( ply, cmd )


end

function ENT:GetHoverHeight( ent, phys )
	local Len = self.HoverHeight
	local trace = self:ClimbTrace()

	if trace.Hit then
		Len = Len + 60
	end

	return Len
end

function ENT:GetAlignment( ent, phys )
	-- Keep hover alignment stable; artificial wobble torque can cause spinouts on slope transitions.
	return ent:GetForward(), ent:GetRight()
end

function ENT:ClimbTrace()
	local tracedata = {
		start = self:LocalToWorld( self:OBBCenter() ),
		endpos = self:LocalToWorld( self:OBBCenter() + Vector(0,0,0) ),
		filter = function( ent )
			if self:GetCrosshairFilterLookup()[ ent:EntIndex() ] or ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() or self.HoverCollisionFilter[ ent:GetCollisionGroup() ] then
				return false
			end

			return true
		end,
	}

	local trace = util.TraceLine( tracedata )
	trace.InvFraction = (1 - math.max(trace.Fraction - 0.3,0) / 0.7) ^ 2
	trace.Hit = trace.Hit and not trace.HitSky

	return trace
end


function ENT:CalcMove( speed )
	self:SetMove( self:GetMove() + speed * 0.027 )

	local Move = self:GetMove()

	if Move > 360 then
		self:SetMove( Move - 360 )
	end

	if Move < -360 then
		self:SetMove( Move + 360 )
	end


end
--
function ENT:GetMoveXY( ent, phys, deltatime )
	local VelL = ent:WorldToLocal( ent:GetPos() + ent:GetVelocity() )

	local X = (self:GetTargetSpeed() - VelL.x)
	local Y = -VelL.y * 0.6



	if ent == self then self:CalcMove( VelL.x ) end

	local moveSpeed = math.abs(self:GetTargetSpeed())

		return X, Y

end

function ENT:GetSteer( ent, phys )
	local Steer = -phys:GetAngleVelocity().z * 0.5

	if not IsValid( self:GetDriver() ) and not self:GetAI() then return Steer end

	return Steer + self:GetTargetSteer()

end
