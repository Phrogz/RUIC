--[[

--]]

--[==========================================================================================================================================[
	Copy and customize items from below to the comment block above to expose properties/events/actions to your artists

	<Property name="foo" formalName="Foo" description="Unbounded Float"                                       default="42.6"              />
	<Property name="bar" formalName="Bar" description="Bounded Float Slider"   min="0" max="100"              default="100"               />
	<Property name="jim" formalName="Jim" description="Unbounded Integer"      type="Long" animatable="False" default="17"                />
	<Property name="jam" formalName="Jam" description="Bounded Integer Slider" type="Long"  min="0" max="100" default="17"                />
	<Property name="biz" formalName="Biz" description="Checkbox"               type="Boolean"                 default="True"              />
	<Property name="baz" formalName="Baz" description="List of strings"        list="First:Second Item:Third" default="Second Item"       />
	<Property name="meh" formalName="Meh" description="Single-line Text"       type="String"                  default="Hello World"       />
	<Property name="heh" formalName="Heh" description="Multi-line Text"        type="MultiLineString"         default="Line 1&#10;Line 2" />

	<Property name="ooh" formalName="Ooh" description="Object Picker"          type="ObjectRef"               default="parent.items"      />

	<Property name="cuz" formalName="Cuz" description="RGB color"              type="Color"                   default="1 0.5 0.5"         />
	<Property name="vee" formalName="Vee" description="XYZ Vector"             type="Vector"                  default="13 127.5 1000"     />
	<Property name="ree" formalName="Ree" description="XYZ Rotation"           type="Rotation"                default="13 127.5 1000"     />
	!! Rotation attributes are intepreted as degrees in the Studio interface, but received as radians from script

	<Property name="yee" formalName="Yee" description="Mesh picker"            type="Mesh"                                                />
	<Property name="zee" formalName="Zee" description="Image picker"           type="Image"                                               />

	<Property name="con" formalName="Con" description="This property will be shown in the Studio UI if and only if meh equals 'Yes Sir'">
		<ShowIfEqual property="meh" value="Yes Sir" />
	</Property>


	<Event name="onSelected" category="Custom Name to Group Events in the UI" />


	<Handler name="explode" category="Dynamics" description="Invoke self:explode() on this behavior"/>
	<Handler name="implode" category="Dynamics" description="Invoke self:implode(amount) on this behavior">
	 <Argument name="amount" description="Help text for this argument" type="Long" default="10" />
	</Handler>


	<Reference>
		Scene.Layer.Cube.opacity
		parent.opacity
		Scene.Layer.Group.children.position
		[targetGroup].children.position
		parent.descendants.opacity
		parent.[targetProp]
		parent.children.all
	</Reference>

  ]==========================================================================================================================================]

-- Runs once, when the behavior is active for the first time
function self:onInitialize()
	self:cacheElements( )
	-- Note: Caching values during onInitialize is simple but not artist-friendly,
	-- as it prevents animations and per-slide values. You may wish to do this
	-- inside onActivate or onUpdate for some attributes.
	-- self:cacheAttributes('foo','bar','jim')

	-- Registering for events is common in the initialization
	-- registerForEvent( "onEvent", self.scene, self.handleEvent )

	-- Use getAttribute directly when animations or per-slide values are accepted instead
	-- local foo = getAttribute(self.element, 'foo')
end

-- Runs each time the behavior becomes active (including the first time)
function self:onActivate()
	-- fireEvent( "onSelected", self.parent, "optional event parameter" )
end

-- Runs each frame that the behavior is active
function self:onUpdate()
	-- Remove this function if you don't need it for a performance gain
end

-- Runs right before the behavior becomes inactive
function self:onDeactivate()
end


-- ========================================================================
-- The following utility functions are for convenience only.
-- They take a value from an exposed property name  (e.g. "speed")
-- and save the current value to the behavior's "self" (e.g. "self.speed")
-- ========================================================================

-- Copy the current value of numbers, text (including lists), and booleans
function self:cacheAttributes(...)
	for _,name in ipairs(arg) do
		self[name] = getAttribute( self.element, name )
	end
end

-- Save element references specified by an ObjectRef picker
function self:cacheElements(...)
	self.scene = getElement( "Scene" )
	self.parent = getElement( "parent", self.element )

	for _,name in ipairs(arg) do
		self[name] = getElement( getAttribute( self.element, name ), self.element )
	end
end

--[[ Copy the current value of vectors and rotations as an XYZ table
function self:cacheVectors(...)
	for _,name in ipairs(arg) do
		self[name] = {
			x=getAttribute( self.element, name..".x" ),
			y=getAttribute( self.element, name..".y" ),
			z=getAttribute( self.element, name..".z" )
		}
	end
end --]]

--[[ Copy the current value of colors as an RGB table
function self:cacheColors(...)
	for _,name in ipairs(arg) do
		self[name] = {
			r=getAttribute( self.element, name..".r" ),
			g=getAttribute( self.element, name..".g" ),
			b=getAttribute( self.element, name..".b" )
		}
	end
end --]]