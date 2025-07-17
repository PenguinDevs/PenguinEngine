--[=[
    Assign objects to annotate to attachments when debugging is enabled.

	@class DebugAnnotation
]=]

local require = require(script.Parent.loader).load(script)

local DebugAnnotationConstants = require("DebugAnnotationConstants")
local DebugAnnotationParent = require("DebugAnnotationParent")

export type AnnotationObject = {
	instance: Instance,
	useConstraint: boolean,
}

local DebugAnnotations = {}

--[=[
    Assigns a debug annotation to an instance and optionally a constraint for it to connect to.
    @param annotationConfig AnnotationObject -- The configuration for the annotation
    @param parent Instance -- The parent instance to which the annotation will be added
]=]
function DebugAnnotations:AssignDebuggingInstance(annotationConfig: AnnotationObject, parent: Instance)
	assert(annotationConfig, "No annotationConfig provided")
	assert(parent, "No parent provided")

	local folder = parent:FindFirstChild(DebugAnnotationConstants.Names.Folder)
	if not folder then
		folder = Instance.new("Configuration")
		folder.Name = DebugAnnotationConstants.Names.Folder
		folder.Parent = parent
	end

	local instanceValue = folder:FindFirstChild(DebugAnnotationConstants.Names.Instance)
	if not instanceValue then
		instanceValue = Instance.new("ObjectValue")
		instanceValue.Name = DebugAnnotationConstants.Names.Instance
		instanceValue.Parent = folder
	end
	instanceValue.Value = annotationConfig.instance

	local constraintValue = folder:FindFirstChild(DebugAnnotationConstants.Names.UseConstraint)
	if not constraintValue then
		constraintValue = Instance.new("BoolValue")
		constraintValue.Name = DebugAnnotationConstants.Names.UseConstraint
		constraintValue.Parent = folder
	end
	constraintValue.Value = annotationConfig.useConstraint

	DebugAnnotationParent:Tag(parent)
end

return DebugAnnotations
