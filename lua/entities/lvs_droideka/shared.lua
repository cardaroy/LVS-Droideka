
ENT.Base = "lvs_walker_atte_hoverscript"

ENT.PrintName = "Droideka"
ENT.Author = "Cards"
ENT.Information = "Destroyers are quick rolling droids with powerful twin blasters and a deflector shield"
ENT.Category = "[LVS] - Star Wars"

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

--ENT.MDL = "models/macieg/starwars/spider.mdl"
ENT.MDL = "models/ptejack/starwars/droidekas/droideka.mdl"
ENT.GibModels = {
}

ENT.AITEAM = 3

ENT.MaxHealth = 1000

ENT.ForceLinearMultiplier = 1

ENT.ForceAngleMultiplier = 1
ENT.ForceAngleDampingMultiplier = 1

ENT.HoverHeight = 60
ENT.HoverTraceLength = 220
ENT.HoverHullRadius = 8

ENT.TurretTurnRate = 100

ENT.LAATC_PICKUPABLE = false
ENT.LAATC_DROP_IN_AIR = true
ENT.LAATC_PICKUP_POS = Vector(-220,0,-145)
ENT.LAATC_PICKUP_Angle = Angle(0,180,0)

ENT.CanMoveOn = {
	["func_door"] = true,
	["func_movelinear"] = true,
	["prop_physics"] = true,
}

ENT.lvsShowInSpawner = true

function ENT:OnSetupDataTables()
	self:AddDT( "Entity", "TurretEnt" )
	self:AddDT( "Entity", "TurretSeat" )
	self:AddDT( "Entity", "GunnerSeat" )

	self:AddDT( "Float", "Move" )
	self:AddDT( "Bool", "IsMoving" )
	self:AddDT( "Bool", "IsCarried" )
	self:AddDT( "Bool", "IsRagdoll" )
	self:AddDT( "Vector", "AIAimVector" )

	self:AddDT( "Float", "TurretPitch" )
	self:AddDT( "Float", "TurretYaw" )

	if SERVER then
		self:NetworkVarNotify( "IsCarried", self.OnIsCarried )
	end
end

function ENT:GetContraption()
	return {self}
end

function ENT:GetEyeTrace()
	local startpos = self:GetPos()

	local pod = self:GetDriverSeat()

	if IsValid( pod ) then
		startpos = pod:LocalToWorld( Vector(0,0,33) )
	end

	local trace = util.TraceLine( {
		start = startpos,
		endpos = (startpos + self:GetAimVector() * 50000),
		filter = self:GetCrosshairFilterEnts()
	} )

	return trace
end

function ENT:GetAimVector()
	if self:GetAI() then
		return self:GetAIAimVector()
	end

	local Driver = self:GetDriver()

	if IsValid( Driver ) then
		return Driver:GetAimVector()
	else
		return self:GetForward()
	end
end

function ENT:GetMainAimAngles()
	local trace = self:GetEyeTrace()

	local AimAngles = self:WorldToLocalAngles( (trace.HitPos - self:LocalToWorld( Vector(0,0,100)) ):GetNormalized():Angle() )

	local ID = self:LookupAttachment( "barrel" )
	local Muzzle = self:GetAttachment( ID )

	if not Muzzle then return AimAngles, trace.HitPos, false end

	local DirAng = self:WorldToLocalAngles( (trace.HitPos - self:GetDriverSeat():LocalToWorld( Vector(0,0,33) ) ):Angle() )

	-- print(DirAng.p)

	return AimAngles, trace.HitPos, (math.abs( DirAng.p ) < 30)-- and math.abs( DirAng.y ) < 80)
end

-- function ENT:GetAimAngles( ent, base, RearEnt )
-- 	local trace = self:GetEyeTrace()

-- 	local Pos = self:LocalToWorld( Vector(208,0,170) )
-- 	local wAng = (trace.HitPos - Pos):GetNormalized():Angle()

-- 	local _, Ang = WorldToLocal( Pos, wAng, Pos, self:LocalToWorldAngles( Angle(0,0,0) ) )

-- 	return Ang, trace.HitPos, (Ang.p < 30 and Ang.p > -10 and math.abs( Ang.y ) < 60)
-- end

function ENT:CalcHeadAim()
	local bodyBone = self:LookupBone("bip_bodyLift")
	if not bodyBone then return end

	local aimDir = self:GetAimVector()
	local aimAng = self:WorldToLocalAngles( aimDir:Angle() )

	local targetAng = Angle(aimAng.y, 0, 0)

	self._HeadAng = self._HeadAng or Angle(0,0,0)
	self._HeadAng = targetAng
	--self._HeadAng = LerpAngle( RealFrameTime() * 4, self._HeadAng, targetAng )

	self:ManipulateBoneAngles( bodyBone, self._HeadAng)

end
