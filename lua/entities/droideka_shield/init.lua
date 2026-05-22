AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    
    self:SetModel("models/ptejack/starwars/droidekas/shield.mdl")
    --self:SetMaterial("ace/sw/holoproj")
    self:SetMaterial("niksacokica/medical/medical_republic_koltotank_fluid")
    --self:PhysicsInit(SOLID_NONE)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
    --self:SetColor(Color(100, 162, 255, 1))

    local phys = self:GetPhysicsObject()

    if phys:IsValid() then

        phys:Wake()
    end
    self:SetMaxHealth(500)
    self:SetHealth(500)

end

function ENT:OnTakeDamage( dmginfo )
    self:SetHealth( self:Health() - dmginfo:GetDamage() )
    if self:Health() <= 0 then
        local effectdata = EffectData()
        effectdata:SetOrigin( self:GetPos() )
        util.Effect( "lvs_explosion_nodebris", effectdata )
        self:Remove()
    end
end

function ENT:OnRemove()
    local owner = self:GetOwner()
    if IsValid( owner ) then
        owner._ShieldActive = false
        owner._Shield = nil
    end
end
