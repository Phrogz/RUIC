-- Copyright (c) 2013 NVIDIA, Inc.
-- Provided under the MIT License: http://opensource.org/licenses/MIT

--[[
	<Property name="machineid" formalName="State Machine"     description="The id of the statemachine asset to query."  type="String"    default="logic" />
	<Property name="location"  formalName="Data Name"         description="Name of the data model attribute."           type="String"    default="vehicleSpeed" />
	<Property name="minValue"  formalName="Min Value"         description="The min value of the data model value."      type="Float"     default="0" />
	<Property name="maxValue"  formalName="Max Value"         description="The max value of the data model value."      type="Float"     default="100" />
	<Property name="target"    formalName="Target Component"  description="The scene/component to control the time of." type="ObjectRef" default="parent" />
	<Property name="minTime"   formalName="Min Time"          description="The time at which the min value is shown."   type="Float"     default="0" />
	<Property name="maxTime"   formalName="Max Time"          description="The time at which the max value is shown."   type="Float"     default="10" />
	<Property name="clampFlag" formalName="Clamp Values?"     description="Prevent times outside the min/max?"          type="Boolean"   default="True" />
	<Property name="smoothing" formalName="Enable Smoothing?" description="Smooth out abrupt changes in the data?"      type="Boolean"   default="False" />
--]]

function self:onInitialize( )
	self:cacheAttributeValues('machineid','location','minValue','maxValue','minTime','maxTime','smoothing','clampFlag')
	self.target  = getElement( getAttribute( self.element, 'target' ), self.element )
	self.machine = getStateMachine( self.machineid )
	assert(self.machine,"Could not locate a State Machine with an id of '"..self.machineid.."'")

	self.ratio = (self.maxTime  - self.minTime) / (self.maxValue - self.minValue)
	self.weighting = 0.3
	self.newTime = 0
end

function self:onActivate()
	pause(self.target) -- In case the artist forgot to pause the context
end

function self:onUpdate( )
	local theNewValue = self.machine:get(self.location)
	if theNewValue ~= self.oldValue then
		self.oldValue = theNewValue
		self.newTime = ( theNewValue - self.minValue ) * self.ratio + self.minTime
		
		if self.clampFlag then
			if self.newTime > self.maxTime then
				self.newTime = self.maxTime 
			elseif self.newTime < self.minTime then
				self.newTime = self.minTime 
			end
		end
	end

	if self.smoothing then
		local theCurrentTime = getTime( self.target )
		if theCurrentTime ~= self.newTime then
			goToTime( self.target, self.newTime*self.weighting + theCurrentTime*(1-self.weighting) )
		end
	else
		goToTime( self.target, self.newTime )
	end
end

function self:cacheAttributeValues(...)
	for _,name in ipairs(arg) do self[name] = getAttribute( self.element, name ) end
end
