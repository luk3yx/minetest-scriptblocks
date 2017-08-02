minetest.register_node("rmod:crate", {
	description = "Crate",
	on_construct = function (pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local item_meta = minetest.deserialize(itemstack:get_meta():get_string("inv"))
		local node_meta = minetest.get_meta(pos)
		
		node_meta:set_string("formspec", [[size[8, 9]
list[context;main;0,0;8,4;]
list[current_player;main;0,5;8,4;]
]])
		
		local infotext = "Empty Crate"
		if item_meta and #item_meta > 0 then
			infotext = "Crate containing:"
			local i = 0
			for _,istack in pairs(item_meta) do
				node_meta:get_inventory():add_item("main", ItemStack(istack))
				
				if i < 3 then
					local stack = ItemStack(istack)
						local name = stack:get_name()
							local def = minetest.registered_items[name] or minetest.registered_nodes[name]
							local desc = def and def.description or name
						local count = stack:get_count()
				
					infotext = infotext .. "\n" .. tostring(count) .. "x " .. desc
				end
				i = i + 1
			end
			
			if i > 3 then
				infotext = infotext .. "\n" .. "...and more."
			end
		end
		
		node_meta:set_string("infotext", infotext)
		
		print(dump(item_meta))
	end,
	on_receive_fields = function(pos)
		local node_meta = minetest.get_meta(pos)
		
		local string_inventory = {}
		for _,istack in pairs(node_meta:get_inventory():get_list("main")) do
			table.insert(string_inventory, istack:to_table())
		end
		
		local infotext = "Empty Crate"
		if not node_meta:get_inventory():is_empty("main") then
			infotext = "Crate containing:"
			local i = 0
			for _,istack in pairs(string_inventory) do
				if i < 3 then
					local stack = ItemStack(istack)
						local name = stack:get_name()
							local def = minetest.registered_items[name] or minetest.registered_nodes[name]
							local desc = def and def.description or name
						local count = stack:get_count()
				
					infotext = infotext .. "\n" .. tostring(count) .. "x " .. desc
				end
				i = i + 1
			end
			
			if i > 3 then
				infotext = infotext .. "\n" .. "...and more."
			end
		end
		
		node_meta:set_string("infotext", infotext)
	end,
	on_dig = function(pos, node, player)
		local node_meta = minetest.get_meta(pos)
		
		local inv = player:get_inventory()
		local stack = ItemStack( {name="rmod:crate", count=1, wear=0} )
		
		local string_inventory = {}
		for _,istack in pairs(node_meta:get_inventory():get_list("main")) do
			table.insert(string_inventory, istack:to_table())
		end
		
		stack:get_meta():set_string("inv", minetest.serialize(string_inventory) )
		print(dump(node_meta:to_table().inventory))
			
		inv:add_item("main", stack)
		
		minetest.remove_node(pos)
	end,
	tiles = {"rmod_crate.png"},
	groups = {oddly_breakable_by_hand = 2, choppy = 2},
})
