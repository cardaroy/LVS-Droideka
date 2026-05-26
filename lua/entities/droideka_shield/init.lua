AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString( "droideka_shield_impact" )

function ENT:Initialize()
    
    self:SetModel("models/ptejack/starwars/droidekas/shield.mdl")
    --self:SetMaterial("ace/sw/holoproj")
    --self:SetMaterial("niksacokica/medical/medical_republic_koltotank_fluid")
    self:SetMaterial("repcom/droids/droideka/dshield_shader")
    --self:PhysicsInit(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    --self:SetColor(Color(100, 162, 255, 1))
    self:SetMaxHealth(500)
    self:SetHealth(500)

end

function ENT:OnTakeDamage( dmginfo )
    self:SetHealth( self:Health() - dmginfo:GetDamage() )

    local attackerPos = dmginfo:GetDamagePosition()
    local toShield = ( self:GetPos() - attackerPos ):GetNormalized()
    net.Start( "droideka_shield_impact" )
        net.WriteVector( self:NearestPoint( attackerPos ) )
        net.WriteVector( -toShield )
    net.SendPVS( self:GetPos() )

    if self:Health() <= 0 then
        local effectdata = EffectData()
        effectdata:SetOrigin( self:GetPos() )
        --util.Effect( "lvs_explosion_nodebris", effectdata )
        ParticleEffectAttach("hcea_shield_disperse",PATTACH_POINT_FOLLOW,self:GetOwner(),self:GetOwner():LookupAttachment("bip_weapon_r"))
        self:Remove()
    end
end

function ENT:OnRemove()
    local owner = self:GetOwner()
    if IsValid( owner ) then
        owner._ShieldCoolDown = CurTime() + 15
        owner._ShieldActive = false
        owner._Shield = nil
    end
end
