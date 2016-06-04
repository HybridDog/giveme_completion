local load_time_start = minetest.get_us_time()


local player_items = {}
local function find_item(name, pname)
	if minetest.registered_items[name] then
		return name
	end

	-- find from alias
	local aliased = minetest.registered_aliases[name]
	if aliased then
		while aliased
		and aliased ~= "" do
			name = aliased
			aliased = minetest.registered_aliases[aliased]
		end
		return name
	end

	-- take an item from the last ones where more were found
	local known_name = tonumber(name)
	if known_name then
		known_name = player_items[pname][known_name]
		if known_name then
			player_items[pname] = {}
			return known_name
		end
	end

	-- find possible items
	local possible_names,n = {},1
	for iname,def in pairs(minetest.registered_items) do
		if string.find(iname, name)
		or (def.description and string.find(string.lower(def.description), name)) then
			possible_names[n] = iname
			n = n+1
		end
	end
	if n == 2 then
		return possible_names[1]
	end
	if n == 1 then
		return false
	end

	-- collect information about them and put it to priority
	local maxwant = 0
	local data = {}
	for _,name in pairs(possible_names) do
		local want = 0
		if minetest.get_item_group(name, "not_in_creative_inventory") == 0
		and minetest.registered_items[name].description then
			want = want+4
		end
		if minetest.registered_nodes[name] then
			want = want+2
			if string.sub(name, 1,7) ~= "stairs:" then
				want = want+1
			end
		end
		maxwant = math.max(maxwant, want)
		if want == maxwant then
			data[name] = want
		end
	end

	-- collect possible ones
	possible_names,n = {},1
	for name,want in pairs(data) do
		if want == maxwant then
			possible_names[n] = name
			n = n+1
		end
	end
	if n == 2 then
		return possible_names[1]
	end

	return possible_names
end

local oldfunc = minetest.chatcommands.giveme.func
function minetest.chatcommands.giveme.func(name, param)
	local itemstring = string.match(param, "(.+)$")
	if not itemstring then
		return false, "ItemString required"
	end
	local rest, itemname = ""
	local fspc = string.find(itemstring, " ")
	if fspc then
		itemname = string.sub(itemstring, 1, fspc-1)
		rest = string.sub(itemstring, fspc)
	else
		itemname = itemstring
	end
	player_items[name] = player_items[name] or {}
	local items = find_item(itemname, name)
	if items == false then
		return false, "No item found."
	end
	if type(items) == "table" then
		player_items[name] = items
		local cnt = #items
		local txt = "More items found:\n"
		for i = 1,cnt-1 do
			--txt = txt..i..": "..items[i]..", \t"
			txt = txt..minetest.colorize("#fe55ff", i)..": "..items[i]..", \t"
		end
		--txt = txt..cnt..": "..items[cnt]
		txt = txt..minetest.colorize("#fe55ff", cnt)..": "..items[cnt]
		return false, txt
	end
	return oldfunc(name, items..rest)
end


local time = (minetest.get_us_time() - load_time_start) / 1000000
local msg = "[giveme_completion] loaded after ca. " .. time .. " seconds."
if time > 0.01 then
	print(msg)
else
	minetest.log("info", msg)
end
