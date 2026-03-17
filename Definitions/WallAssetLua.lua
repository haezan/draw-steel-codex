--- @class WallAssetLua:AssetImageBaseLua 
--- @field scale any 
--- @field cornerSize any 
--- @field shadowMask any 
--- @field previewRect any 
--- @field tint any 
--- @field hueshift any 
--- @field saturation any 
--- @field brightness any 
--- @field contrast any 
--- @field invisible any 
--- @field visionOneWay any 
--- @field movementOneWay any 
--- @field occludesVision any 
--- @field occludesLight any 
--- @field renderParallax any 
--- @field blocksMovement any 
--- @field blocksForcedMovement any 
--- @field blocksFlying any 
--- @field cover any 
--- @field soundOcclusion any 
--- @field wallHeight any 
--- @field shadowDistortion any 
--- @field taper any 
--- @field parallax any 
--- @field shadowGlowThickness any
--- @field solidity string "Unbreakable", "Thin", or "Solid"
--- @field breakStamina number stamina cost to break through this wall (0 = unbreakable)
--- @field rubbleKeyword string|nil keyword to search for rubble objects to spawn when broken
--- @field rubbleTerrainId string|nil terrain tile asset id to draw as rubble when broken
--- @field breakSound string|nil destruction sound type id to play when broken (from AudioObjectDestructionTypes)
WallAssetLua = {}

--- Upload
--- @return nil
function WallAssetLua:Upload()
	-- dummy implementation for documentation purposes only
end

--- Delete
--- @return nil
function WallAssetLua:Delete()
	-- dummy implementation for documentation purposes only
end
