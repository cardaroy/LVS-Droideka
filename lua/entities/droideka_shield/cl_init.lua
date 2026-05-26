include("shared.lua")

net.Receive( "droideka_shield_impact", function()
    local pos = net.ReadVector()
    local normal = net.ReadVector()
    local effectdata = EffectData()
    effectdata:SetOrigin( pos )
    effectdata:SetNormal( normal )
    effectdata:SetMagnitude( 2 )
    effectdata:SetScale( 10 )
    util.Effect( "ElectricSpark", effectdata )
end )

function ENT:Draw()

    self:DrawModel()

end

