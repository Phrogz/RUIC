-- Copyright (c) 2013 NVIDIA, Inc.
-- Provided under the MIT License: http://opensource.org/licenses/MIT

--[[
	<Property name="component" formalName="Component"      description="The element to use the time of."                 type="ObjectRef" default="parent"   />
	<Property name="target"    formalName="Target"         description="The element to control."                         type="ObjectRef" default="parent"   />
	<Property name="attrName"  formalName="Attribute"      description="Name of the attribute on the object to control." type="String"    default="rotation.x"   />
	<Property name="isNumber"  formalName="Remap Numbers?" description="Is the value being read and set a number that needs to be transformed?" type="Boolean" default="False" />
	<Property name="minTime"   formalName="Min Time"       description="The min time on the component."                  type="Float"     default="0"><ShowIfEqual property="isNumber" value="True" /></Property>
	<Property name="maxTime"   formalName="Max Time"       description="The max time on the component."                  type="Float"     default="10"><ShowIfEqual property="isNumber" value="True" /></Property>
	<Property name="minOutput" formalName="Min Set Value"  description="The min value to set the attribute to."          type="Float"     default="0"><ShowIfEqual property="isNumber" value="True" /></Property>
	<Property name="maxOutput" formalName="Max Set Value"  description="The max value to set the attribute to."          type="Float"     default="1"><ShowIfEqual property="isNumber" value="True" /></Property>
	<Property name="clamp"     formalName="Clamp Value?"   description="Prevent the value from being set outside the min/max range?"      type="Boolean" default="True"><ShowIfEqual property="isNumber" value="True" /></Property>
	<Reference>
		[target].[attrName]
	</Reference>
--]]


function self:onInitialize()
	self.comp   = getElement( getAttribute(self.element,'component'), self.element )
	self.target = getElement( getAttribute(self.element,'target'), self.element )
	self:cacheAttributeValues( 'attrName', 'isNumber' )
	if self.isNumber then
		self:cacheAttributeValues( 'minTime', 'maxTime', 'minOutput', 'maxOutput', 'clamp' )
		self.degreesToRadians = string.find( self.attrName, 'rotation' ) and math.pi/180
		self.ratio = (self.maxOutput  - self.minOutput) / (self.maxTime - self.minTime)
	end
end

function self:onUpdate()
	local theValue = getTime( self.comp )
	if theValue ~= self.oldValue then
		self.oldValue = theValue
		if self.isNumber then
			theValue = ( ( theValue - self.minTime ) * self.ratio + self.minOutput )
			if self.clamp then
				if     theValue < self.minOutput then theValue = self.minOutput
				elseif theValue > self.maxOutput then theValue = self.maxOutput end
			end
			if self.degreesToRadians then theValue = theValue * self.degreesToRadians end
		end
		setAttribute( self.target, self.attrName, theValue )
	end
end

function self:cacheAttributeValues(...)
	for _,name in ipairs(arg) do self[name] = getAttribute( self.element, name ) end
end
