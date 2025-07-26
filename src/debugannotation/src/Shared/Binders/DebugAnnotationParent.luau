--[=[
    Binds debug annotations to specific instances for easier debugging.
    Annotations must be set beforehand using [DebugAnnotation:AssignDebuggingInstance].

    Should be initialised using [ServiceBag].

    @class DebugAnnotationParent
]=]

local require = require(script.Parent.loader).load(script)

local AttributeValue = require("AttributeValue")
local BaseObject = require("BaseObject")
local Binder = require("Binder")
local Brio = require("Brio")
local DebugAnnotationConstants = require("DebugAnnotationConstants")
local ObservableMap = require("ObservableMap")
local RxBrioUtils = require("RxBrioUtils")
local RxInstanceUtils = require("RxInstanceUtils")
local RxValueBaseUtils = require("RxValueBaseUtils")
local ServiceBag = require("ServiceBag")

local DebugAnnotationParent = setmetatable({}, BaseObject)
DebugAnnotationParent.ClassName = "DebugAnnotationParent"
DebugAnnotationParent.__index = DebugAnnotationParent

export type DebugAnnotationParent = typeof(setmetatable(
	{} :: {
		_parent: BasePart | Attachment,
		_configFolder: Configuration?,
		_instance: Instance?,
		_useConstraint: boolean?,
	},
	{} :: typeof({ __index = DebugAnnotationParent })
)) & BaseObject.BaseObject

--[=[
	Constructs a new DebugAnnotationParent.
	@param parent BasePart | Attachment -- The parent instance to bind annotations to.
	@param serviceBag ServiceBag -- The service bag for dependencies.
	@return DebugAnnotationParent
]=]
function DebugAnnotationParent.new(
	parent: BasePart | Attachment,
	serviceBag: ServiceBag.ServiceBag
): DebugAnnotationParent
	assert(parent, "Parent must be provided")
	assert(parent:IsA("BasePart") or parent:IsA("Attachment"), "Parent must be a BasePart or Attachment")

	local self = setmetatable(BaseObject.new(parent), DebugAnnotationParent)

	self._parent = parent

	self._enableAnnotationsAttribute =
		AttributeValue.new(self._parent, DebugAnnotationConstants.Names.EnableAnnotations, false)

	self._enableAnnotationsAttribute:Observe():Subscribe(function(enabled: boolean)
		if enabled then
			self:_enableAnnotations()
		else
			self:_disableAnnotations()
		end
	end)

	return self
end

function DebugAnnotationParent._enableAnnotations(self: DebugAnnotationParent)
	self._maid.observableMap = ObservableMap.new()
	self._maid.observableMap
		:ObserveAtKey(DebugAnnotationConstants.Names.Instance)
		:Subscribe(function(instance: Instance)
			self:_createAnnotationInstance(instance)
		end)
	self._maid.observableMap
		:ObserveAtKey(DebugAnnotationConstants.Names.UseConstraint)
		:Subscribe(function(useConstraint: boolean)
			self:_useAnnotationConstraint(useConstraint)
		end)

	self._maid.observe = RxInstanceUtils.observeLastNamedChildBrio(
		self._parent,
		"Configuration",
		DebugAnnotationConstants.Names.Folder
	)
		:Pipe({
			RxBrioUtils.switchMapBrio(function(container: Instance)
				return RxInstanceUtils.observeChildrenBrio(container, function(child: Instance)
					for _, name in pairs(DebugAnnotationConstants.Names) do
						if child.Name == name then
							return true
						end
					end
					return false
				end)
			end),
		})
		:Subscribe(function(brio: Brio.Brio<Instance>)
			local maid, obj = brio:ToMaidAndValue()
			maid:GiveTask(RxValueBaseUtils.observeValue(obj):Subscribe(function(value)
				self._maid.observableMap:Set(obj.Name, value)
			end))
			maid:GiveTask(function()
				self._maid.observableMap:Remove(obj.Name)
			end)
		end)
end

function DebugAnnotationParent._disableAnnotations(self: DebugAnnotationParent)
	self._maid.observe = nil
	self._maid.observableMap = nil
	self._maid.instance = nil
end

function DebugAnnotationParent._createAnnotationInstance(self: DebugAnnotationParent, instance: Instance)
	if not instance then
		return
	end

	local annotationInstance = instance:Clone()
	self._maid.instance = annotationInstance

	local parentCFrame = nil
	if self._parent.ClassName == "BasePart" or self._parent.ClassName == "Part" then
		parentCFrame = self._parent.CFrame
	elseif self._parent.ClassName == "Attachment" then
		parentCFrame = (self._parent :: Attachment).WorldCFrame
	else
		warn("[DebugAnnotationParent] - Parent is not a BasePart or Attachment. Cannot find CFrame.")
		return
	end

	if annotationInstance.ClassName == "Part" then
		annotationInstance.CFrame = parentCFrame
	elseif annotationInstance.ClassName == "Attachment" then
		annotationInstance.WorldCFrame = parentCFrame
	elseif annotationInstance.ClassName == "BillboardGui" then
		annotationInstance.Adornee = self._parent
	else
		warn("[DebugAnnotationParent] - Unsupported annotation instance type: " .. typeof(annotationInstance))
		return
	end

	annotationInstance.Parent = self._parent

	self:_useAnnotationConstraint(self._maid.observableMap:Get(DebugAnnotationConstants.Names.UseConstraint))
end

function DebugAnnotationParent._useAnnotationConstraint(self: DebugAnnotationParent, useConstraint: boolean)
	if not useConstraint then
		return
	end

	if not self._maid.instance then
		return
	end

	-- It seems as though this doesn't work :/
	-- self._constraint = self._maid.instance:FindFirstChildOfClass("Constraint")

	for _, child in ipairs(self._maid.instance:GetChildren()) do
		if child:IsA("Constraint") then
			self._constraint = child
			break
		end
	end

	if not self._constraint then
		warn("[DebugAnnotationParent] - No constraint found in annotation instance. Cannot bind to parent.")
		return
	end

	if not self._constraint.Attachment0 then
		self._constraint.Attachment0 = self._parent
	elseif not self._constraint.Attachment1 then
		self._constraint.Attachment1 = self._parent
	else
		warn("[DebugAnnotationParent] - Constraint already has both attachments set. Cannot bind to parent.")
		return
	end
end

return Binder.new("DebugAnnotationParent", DebugAnnotationParent)
