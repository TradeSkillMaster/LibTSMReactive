local Plugin = {}

local function DefineStateTypeHelper(fieldType, fieldName, extraArg, stateTypeHelperFunc)
	fieldType = fieldType:lower():gsub("^optional(.+)", "%1?")
	extraArg = extraArg:gsub("^%s*", "")
	local isOptional = fieldType:sub(-1) == "?"
	local nonOptionalFieldType = isOptional and fieldType:sub(1, -2) or fieldType
	if nonOptionalFieldType == "enum" then
		fieldType = isOptional and "EnumValue?" or "EnumValue"
	elseif nonOptionalFieldType == "class" then
		extraArg = stateTypeHelperFunc and stateTypeHelperFunc("class", extraArg) or extraArg
		fieldType = extraArg..(isOptional and "?" or "")
	else
		fieldType = stateTypeHelperFunc and stateTypeHelperFunc(nonOptionalFieldType, extraArg) or nonOptionalFieldType
		fieldType = fieldType..(isOptional and "?" or "")
	end
	return "---@field "..fieldName.." "..fieldType
end

function Plugin.DefineStateType(typeName, code, parentTypeName, stateTypeHelperFunc)
	-- Define class for state types defined with ReactiveStateSchema
	parentTypeName = parentTypeName or "ReactiveState"
	local resultLines = {}
	table.insert(resultLines, "---@class "..typeName..": "..parentTypeName)
	if type(code) == "table" then
		for _, line in ipairs(code) do
			local fieldType, fieldName, extraArg = line:match(":Add([A-Za-z]+)Field%(\"([A-Za-z0-9_]+)\",?(.-)%)$")
			local resultLine = fieldType and DefineStateTypeHelper(fieldType, fieldName, extraArg, stateTypeHelperFunc) or nil
			if resultLine then
				table.insert(resultLines, resultLine)
			end
		end
	else
		for fieldType, fieldName, extraArg in code:gmatch(":Add([A-Za-z]+)Field%(\"([A-Za-z0-9_]+)\",?(.-)%)\r?\n") do
			local resultLine = DefineStateTypeHelper(fieldType, fieldName, extraArg, stateTypeHelperFunc)
			if resultLine then
				table.insert(resultLines, resultLine)
			end
		end
	end
	return table.concat(resultLines, "\n").."\n"
end

local function ProcessStateType(context, varName, expression, stateTypeHelperFunc)
	-- Define reactive state types
	local typeName = expression:match("Reactive%.CreateStateSchema%(\"(.-)\"%)")
	if not typeName then
		return
	end
	typeName = typeName:lower():gsub("_ui_", "_UI_"):gsub("^([a-z])", string.upper):gsub("_(.)", string.upper)
	local codeLines = {}
	for i = context.currentLine.index + 1, #context.lines do
		local line = context.lines[i]
		if line:match("^%s*:Commit%(%)$") then
			break
		else
			table.insert(codeLines, line)
		end
	end
	local result = Plugin.DefineStateType(typeName, codeLines, nil, stateTypeHelperFunc)
	-- Insert an extra empty line so this type isn't assigned to the schema
	context:AddPrefixDiff(result.."\n")
	for i = context.currentLine.index + 1, #context.lines do
		local line = context.lines[i]
		if line:match("= "..varName..":CreateState%(%)") then
			context:AddPrefixDiff("--[[@as "..typeName.."]]", context.lineStartPos[i] + #line)
		end
	end
end

function Plugin.ProcessContext(context, stateClassTypeHelperFunc)
	for _, varName, expression in context:VariableAssignmentIterator() do
		ProcessStateType(context, varName, expression, stateClassTypeHelperFunc)
	end
end

return Plugin
