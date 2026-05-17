function ENT:Shoot(ent)
	local boneID = self._LeftWeapon and self:LookupBone("bip_weapon_L") or self:LookupBone("bip_weapon_r")
	local Pos = boneID and self:GetBonePosition( boneID ) or self:GetPos()

	local _AimAngles, AimPos, _InRange = ent:GetMainAimAngles()
	local Dir = (AimPos - Pos):GetNormalized()

	local bullet = {}
	bullet.Src 	= Pos
	bullet.Dir 	= Dir
	bullet.Spread 	= Vector( 0.01,  0.01, 0 )
	bullet.TracerName = "lvs_tracer_red"
	bullet.Force	= 10
	bullet.HullSize 	= 30
	bullet.Damage	= 100
	bullet.SplashDamage = 100
	bullet.SplashDamageRadius = 10
	bullet.Velocity = 16000
	bullet.Attacker 	= ent:GetDriver()
	bullet.Callback = function(att, tr, dmginfo)
		local effectdata = EffectData()
			effectdata:SetStart( Vector(255,50,50) )
			effectdata:SetOrigin( tr.HitPos )
		--util.Effect( "lvs_laser_impact", effectdata )
	end
	ent:LVSFireBullet( bullet )
	self._LeftWeapon = not self._LeftWeapon

	local effectdata = EffectData()
	effectdata:SetStart( Vector(255,50,50) )
	effectdata:SetOrigin( bullet.Src )
	effectdata:SetNormal( Dir )
	effectdata:SetEntity( ent )
	util.Effect( "lvs_muzzle_colorable", effectdata )

	ent:TakeAmmo()

	-- self:GetTurretEnt():PlayAnimation( "idle" )

	if not IsValid( ent.SNDPrimary ) then return end

	ent.SNDPrimary:PlayOnce( 100 + math.cos( CurTime() + ent:EntIndex() * 1337 ) * 5 + math.Rand(-1,1), 1 )

end

function ENT:InitWeapons()
	local weapon = {}
	weapon.Icon = Material("lvs/weapons/hmg.png")
	weapon.Ammo = 9999
	weapon.Delay = 0.2
	weapon.HeatRateUp = 0
	weapon.HeatRateDown = 0.2
	self._LeftWeapon = true
	weapon.Attack = function( ent )
		if ent:GetIsCarried() then ent:SetHeat( 0 ) return true end

		-- if (self:GetDriverGunAngles() == 1) then return end
		-- 	ent:GetDriver():PrintMessage( HUD_PRINTCENTER, "NAJPIERW WYŁĄCZ TRYB STACJONARNY ABY STRZELAĆ Z TEJ BRONI" )
		-- return end

		return self:Shoot(ent)

	end
	weapon.OnThink = function( ent, active )
		local base = ent:GetVehicle()

		if IsValid( base ) and base:GetIsCarried() then return end

		-- if (self:GetDriverGunAngles() == 1) then return end

		local AimAngles = ent:GetMainAimAngles()

		local _p = math.Clamp(AimAngles.p, -25, 35)
		-- local y = math.Clamp(AimAngles.y, -78, 78)

		-- bone aiming disabled
		--ent:ManipulateBoneAngles(2,Angle(AimAngles.y,0,0))
		--ent:ManipulateBoneAngles(3,Angle(0,0,p))

	end

	weapon.OnOverheat = function( ent ) ent:EmitSound("lvs/overheat.wav") end
	self:AddWeapon( weapon )

	-- self.LegRotate = 0
	-- self.KnockbackAnim = 0

end

