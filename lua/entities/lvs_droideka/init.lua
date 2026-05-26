AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
-- AddCSLuaFile( "cl_ikfunctions.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "sh_weapons.lua" )
-- AddCSLuaFile( "cl_legs.lua" )
AddCSLuaFile( "cl_prediction.lua" )
--AddCSLuaFile( "sh_turret.lua" )
--AddCSLuaFile( "sh_gunner.lua")
include("shared.lua")
include("sv_ragdoll.lua")
include("sv_controls.lua")
include("sv_contraption.lua")
include("sv_ai.lua")
include("sh_weapons.lua")


ENT.SpawnNormalOffset = 0
ENT.SpawnNormalOffsetSpawner = 0
//ENT.MassCenterOverride = Vector(0, 0, 0)

function ENT:OnSpawn( PObj )
	PObj:SetMass( 10000 )

	-- self:SetCannonMode(0)
	-- self:SetDriverGunAngles(0)

	local DriverSeat = self:AddDriverSeat( Vector(-5,0,33), Angle(0,-90,0) )
	DriverSeat.HidePlayer = true
	DriverSeat:SetCameraDistance( 0.05 )
	
	-- DriverSeat.PlaceBehindVelocity = 1000

	--self:PlayAnimation( "idle" )
	--self.NextFootstep = CurTime() + 1

	-- local ID = self:LookupAttachment( "driver" )
	-- local Attachment = self:GetAttachment( ID )

	-- if Attachment then
	-- 	local Pos,Ang = LocalToWorld( Vector(0,-5,-10), Angle(0,0,5), Attachment.Pos, Attachment.Ang )

	-- 	DriverSeat:SetParent( NULL )
	-- 	DriverSeat:SetPos( Pos )
	-- 	DriverSeat:SetAngles( Ang )
	-- 	DriverSeat:SetParent( self, ID )
	-- 	DriverSeat.ExitPos =  Vector(-10,50,93)

	-- end


	self.SNDPrimary = self:AddSoundEmitter( Vector(50,0,93), "kingpommes/starwars/hailfire/laser.wav", "kingpommes/starwars/hailfire/laser.wav" )
	self.SNDPrimary:SetSoundLevel( 110 )

	-- self.SNDPrimaryTurret = self:AddSoundEmitter( Vector(150,0,248), "lvs/vehicles/atte/fire_turret.mp3", "lvs/vehicles/atte/fire_turret.mp3" )
	-- self.SNDPrimaryTurret:SetSoundLevel( 110 )

	-- self.SNDTurret = self:AddSoundEmitter( Vector(45,0,300), "lvs/vehicles/atte/fire_turret.mp3", "lvs/vehicles/atte/fire_turret.mp3" )
	-- self.SNDTurret:SetSoundLevel( 110 )

    -- self:CreateFlashlight()
	-- armor protecting the weakspot
	-- self:AddDSArmor( {
	-- 	pos = Vector(20,0,100),
	-- 	ang = Angle(0,0,0),
	-- 	mins = Vector(-10,-15,-30),
	-- 	maxs =  Vector(15,15,10),
	-- 	Callback = function( tbl, ent, dmginfo )
	-- 		-- dont do anything, just prevent it from hitting the critical spot
	-- 	end
	-- } )

	-- -- -- weak spots
	-- self:AddDS( {
	-- 	pos = Vector(-20,0,90),
	-- 	ang = Angle(0,0,0),
	-- 	mins = Vector(-10,-10,-5),
	-- 	maxs =  Vector(10,10,5),
	-- 	Callback = function( tbl, ent, dmginfo )
	-- 		if dmginfo:GetDamage() <= 0 then return end

	-- 		dmginfo:ScaleDamage( 2 )

	-- 		if ent:GetHP() > 200 then return end

	-- 		-- ent:BecomeRagdoll()

	-- 		local effectdata = EffectData()
	-- 			effectdata:SetOrigin( ent:LocalToWorld( Vector(0,0,80) ) )
	-- 		util.Effect( "lvs_explosion_nodebris", effectdata )
	-- 	end
	-- } )
	self._AIState = "None"
	self._CollisionCheck = false
	self._LastCapturedCollision = CurTime() - 2
	self._HoldPosition = false
	self._shootDelay = 0

	--self._ShieldActive = false
	
end


function ENT:OnTick()
	-- self:InitRear() -- this fixes a gmod bug
	self:ContraptionThink()
	self:CalcHeadAim()
	--self:Animate()

end

function ENT:FootStep() --lvs/vehicles/hsd/footstep01.wav
	--self:EmitSound("lvs/vehicles/hsd/footstep0"..math.random(1,3)..".wav", 70, math.random(100,130))
end

function ENT:OnMaintenance()
	self:UnRagdoll()
end


function ENT:AlignView( ply, SetZero )
	if not IsValid( ply ) then return end

	timer.Simple( 0, function()
		if not IsValid( ply ) or not IsValid( self ) then return end

		ply:SetEyeAngles( Angle(0,90,0) )
	end)
end

function ENT:PhysicsCollide( data, physobj )
	-- Wall hit (normal is mostly horizontal): stop immediately to prevent wall climbing
	if data.HitNormal.z < 0.5 then
		self._LastCapturedCollision = CurTime()
		self._CollisionCheck = false
		return
	end

	-- Floor/ramp collision: use a short delay to avoid stopping on every tiny bump
	if not self._CollisionCheck then
		self._CollisionTimerStart = CurTime()
		self._CollisionCheck = true
		return
	end

	if CurTime() < self._CollisionTimerStart + 2 then return end

	self._LastCapturedCollision = CurTime()
	self._CollisionTimerStart = CurTime()
end

util.AddNetworkString( "droideka_impact" )

function ENT:OnTakeDamage( dmginfo )
	local attackerPos = dmginfo:GetDamagePosition()
	local toSelf = ( self:GetPos() - attackerPos ):GetNormalized()
	net.Start( "droideka_impact" )
		net.WriteVector( self:NearestPoint( attackerPos ) )
		net.WriteVector( -toSelf )
	net.SendPVS( self:GetPos() )
end

