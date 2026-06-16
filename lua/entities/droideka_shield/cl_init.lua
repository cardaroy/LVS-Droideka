include("shared.lua")
--[[
function ENT:Initialize()
    self:SetSolid(SOLID_NONE)
end
--]]

net.Receive( "droideka_shield_impact", function()
    local pos = net.ReadVector()
    local normal = net.ReadVector()
    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    effectdata:SetNormal( normal )
    effectdata:SetMagnitude( 2 )
    effectdata:SetScale( 10 )
	ParticleEffect("hcea_t25r_core_2", dmginfo:GetDamagePosition(), dmginfo:GetDamageForce():Angle(), self)
end )

function ENT:Draw()

    self:DrawModel()

end

