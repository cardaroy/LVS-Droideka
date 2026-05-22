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

