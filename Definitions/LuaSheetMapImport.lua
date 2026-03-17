--- @class LuaSheetMapImport:Panel 
--- @field errorMessage any 
--- @field path any 
--- @field paths any 
--- @field pathIndex any 
--- @field instructionsText any 
--- @field haveConfirm any 
--- @field haveNext any 
--- @field havePrevious any 
--- @field tileDim any 
--- @field error any 
--- @field zoom any 
--- @field tileType any 
--- @field lockDimensions boolean 
--- @field tileScaling number
--- @field imageDim vec2|nil
--- @field imageWidth number The width of the imported image in pixels (0 if not loaded).
--- @field imageHeight number The height of the imported image in pixels (0 if not loaded).
--- @field imageFromId string (write-only) Set the image to display from a cloud image ID (asset ID or md5:hash).
LuaSheetMapImport = {}

--- Next
--- @return nil
function LuaSheetMapImport:Next()
	-- dummy implementation for documentation purposes only
end

--- Previous
--- @return nil
function LuaSheetMapImport:Previous()
	-- dummy implementation for documentation purposes only
end

--- Confirm
--- @param callback any
--- @return nil
function LuaSheetMapImport:Confirm(callback)
	-- dummy implementation for documentation purposes only
end

--- SetWidth
--- @param w any
--- @return nil
function LuaSheetMapImport:SetWidth(w)
	-- dummy implementation for documentation purposes only
end

--- SetHeight
--- @param h any
--- @return nil
function LuaSheetMapImport:SetHeight(h)
	-- dummy implementation for documentation purposes only
end

--- SetMapDimensions
--- @param tilesW number
--- @param tilesH number
--- @return nil
function LuaSheetMapImport:SetMapDimensions(tilesW, tilesH)
	-- dummy implementation for documentation purposes only
end

--- GetCalibrationData: Returns the current calibration data without creating assets.
--- @return {controlPoints: {x: number, y: number}[], scaling: number, tileType: string, width: number, height: number}|nil
function LuaSheetMapImport:GetCalibrationData()
	-- dummy implementation for documentation purposes only
end

--- ApplyCalibrationTo: Apply the current calibration (control points, scaling, tileType) directly to an existing object's Map component.
--- @param targetObj LuaObjectInstance
--- @return nil
function LuaSheetMapImport:ApplyCalibrationTo(targetObj)
	-- dummy implementation for documentation purposes only
end

--- CreateGridless
--- @return nil
function LuaSheetMapImport:CreateGridless()
	-- dummy implementation for documentation purposes only
end

--- ClearMarkers
--- @return nil
function LuaSheetMapImport:ClearMarkers()
	-- dummy implementation for documentation purposes only
end
