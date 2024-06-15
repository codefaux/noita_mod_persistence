---how to use for your own mod: drop this file into files\ and call it with dofile() -- NOT dofile_once() -- in init.lua OnWorldPostUpdate()

---only run function one time, but must init variable
if actions_by_id__init_done==nil then actions_by_id__init_done=false; end
if actions_by_id__init_done==false then
	---variables and functions run/register/initialize only once
	actions_by_id__init_done = true;
	actions_bt_id__notify_when_finished = true;

	---kill file cache, force reload
	__loaded = {};

	dofile_once( "data/scripts/gun/gun.lua" );
	dofile_once( "data/scripts/lib/utilities.lua" );

	function table_equals(o1, o2, ignore_mt)
		if o1 == o2 then return true end
		local o1Type = type(o1)
		local o2Type = type(o2)
		if o1Type ~= o2Type then return false end
		if o1Type ~= 'table' then return false end

		if not ignore_mt then
				local mt1 = getmetatable(o1)
				if mt1 and mt1.__eq then
					  --compare using built in method
					  return o1 == o2
				end
		end

		local keySet = {}

		for key1, value1 in pairs(o1) do
				local value2 = o2[key1]
				if value2 == nil or table_equals(value1, value2, ignore_mt) == false then
					  return false
				end
				keySet[key1] = true
		end

		for key2, _ in pairs(o2) do
				if not keySet[key2] then return false end
		end
		return true
	end

	---init but don't overwrite public veriables
	action_count = action_count or 0;
	actions_by_id = actions_by_id or {};

	---returns nothing, directly acts on actions_by_id array
	---@param action_id string id of action to run
	function get_action_metadata(action_id)
		metadata = { c = {}, projectiles = nil, shot_effects = {} };

		---override Reflection_RegisterProjectile(xml) -in this context only-
		Reflection_RegisterProjectile = function( projectile_xml )
			if metadata.projectiles==nil then
				metadata.projectiles = {};
			end

			local skip_or_modify_hash =
			{		---list of member names we don't care about, or need to explicitly change
				config = true,
				config_explosion = true,
				damage_critical = true,
				damage_by_type = true,
				mStartingLifetime = true,
				mTriggers = true,
				do_moveto_update = true,
				angular_velocity = true,
				penetrate_world_velocity_coeff = true,
				ground_penetration_coeff = true,
				-- mInitialSpeed = true,
				on_death_emit_particle = true,
				ground_collision_fx = true,
				die_on_low_velocity = true,
				on_collision_spawn_entity = true,
				penetrate_entities = true,
				velocity_sets_scale = true,
				go_through_this_material = true,
				die_on_liquid_collision = true,
				bounce_at_any_angle = true,
				-- damage_melee = true,
				-- damage_explosion = true,
				mDamagedEntities = true,
				on_death_emit_particle_count = true,
				-- never_hit_player = true,
				camera_shake_when_shot = true,
				-- bounce_always = true,
				velocity_sets_y_flip = true,
				-- damage_physics_hit = true,
				-- collide_with_world = true,
				-- penetrate_world = true,
				physics_impulse_coeff = true,
				mShooterHerdId = true,
				lifetime_randomness = true,
				on_death_particle_check_concrete = true,
				spawn_entity_is_projectile = true,
				-- explosion_dont_damage_shooter = true,
				-- damage_ice = true,
				muzzle_flash_file = true,
				shoot_light_flash_g = true,
				-- damage_radioactive = true,
				shoot_light_flash_b = true,
				collide_with_entities = true,
				damage_scale_max_speed = true,
				ragdoll_fx_on_collision = true,
				bounces_left = true,
				lifetime = true,
				velocity_updates_animation = true,
				-- damage_curse = true,
				damage_every_x_frames = true,
				friction = true,
				on_death_duplicate_remaining = true,
				-- damage_fire = true,
				-- damage_projectile = true,
				shoot_light_flash_radius = true,
				damage_overeating = true,
				-- projectiles = true,
				die_on_low_velocity_limit = true,
				shell_casing_material = true,
				lob_min = true,
				on_collision_die = true,
				-- damage_drill = true,
				-- on_death_explode = true,
				lob_max = true,
				on_collision_remove_projectile = true,
				-- friendly_fire = true,
				-- damage_scaled_by_speed = true,
				-- damage_healing = true,
				spawn_entity = true,
				velocity_sets_rotation = true,
				on_death_item_pickable_radius = true,
				on_lifetime_out_explode = true,
				play_damage_sounds = true,
				mWhoShotEntityTypeID = true,
				-- projectile_type = true,
				-- damage_poison = true,
				damage_game_effect_entities = true,
				-- speed_min = true,
				attach_to_parent_trigger = true,
				-- speed_max = true,
				on_death_gfx_leave_sprite = true,
				ground_penetration_max_durability_to_destroy = true,
				mLastFrameDamaged = true,
				shoot_light_flash_r = true,
				shell_casing_offset = true,
				-- bounce_energy = true,
				collide_with_tag = true,
				ragdoll_force_multiplier = true,
				-- damage = true,
				collide_with_shooter_frames = true,
				-- knockback_force = true,
				velocity_sets_scale_coeff = true,
				dont_collide_with_tag = true,
				hit_particle_force_multiplier = true,
				create_shell_casing = true,
				bounce_fx_file = true,
				collect_materials_to_shooter = true,
				blood_count_multiplier = true,
				mEntityThatShot = true,
				mWhoShot = true,
				-- damage_electricity = true,
				on_death_emit_particle_type = true,
				-- damage_slice = true,
				-- damage_holy = true,
				direction_nonrandom_rad = true,
				-- direction_random_rad = true
			};

			if metadata.projectiles[projectile_xml]~=nil then ---check if projectile data already exists
				metadata.projectiles[projectile_xml].projectiles = metadata.projectiles[projectile_xml].projectiles + 1 ---data for this projectile_xml already exists, add one to count
			else ---projectile doesn't exist, create it
				local proj_entity_id = EntityLoad(projectile_xml, -20000, -20000); ---load projectile entity
				local proj_comp = EntityGetFirstComponent(proj_entity_id, "ProjectileComponent"); ---find the first projectile component
				if proj_comp~=nil and proj_comp~=0 then ---ensure projectile component loaded properly
					metadata.projectiles[projectile_xml] = metadata.projectiles[projectile_xml] or {}; ---create empty table for incoming projectile if doesn't exist
					for proj_member, _ in pairs(ComponentGetMembers(proj_comp)) do ---iterate thru component members if they exist
					  if skip_or_modify_hash[proj_member]~=true then ---only directly store members which aren't tagged
					    metadata.projectiles[projectile_xml][proj_member] = ComponentGetValue2(proj_comp, proj_member); ---store member to structure
					  elseif proj_member=="damage_by_type" then ---specific processing for "damage_by_type"
					    for dmg_type, _ in pairs(ComponentObjectGetMembers(proj_comp, proj_member)) do ---break open damage_by_type table
					      metadata.projectiles[projectile_xml]["damage_" .. dmg_type] = 25 * (ComponentObjectGetValue2(proj_comp, proj_member, dmg_type) or 0); ---store it in singles
					    end ---for dmg_type in damage_by_type
					  elseif proj_member=="config_explosion" then ---specific processing for "config_explosion"
					    metadata.projectiles[projectile_xml]["damage_explosion"] = 25 * (ComponentObjectGetValue2(proj_comp, proj_member, "damage") or 0); ---stored separately, standardise
					  elseif proj_member=="mStartingLifetime" then ---specific processing for "mStartingLifetime"
					    metadata.projectiles[projectile_xml]["lifetime"] = ComponentGetValue2(proj_comp, proj_member); ---save with more typical name
						elseif proj_member=="direction_random_rad" then ---specific processing for "direction_random_rad"
							metadata.projectiles[projectile_xml]["spread_deg"] = math.deg(ComponentGetValue2(proj_comp, proj_member));
						end ---if skip_or_modify_hash[proj_member] block
					end ---for proj_member in ComponentGetMembers(proj_comp); ---iterate thru component members if they exist
					metadata.projectiles[projectile_xml].projectiles = 1; ---start with one projectile
					EntityRemoveComponent(proj_entity_id, proj_comp); ---remove the projectile component before we kill it to avoid issues
				end --- if proj_comp~=nil|0; ---to ensure loaded
				EntityKill(proj_entity_id); ---kill the projectile entity since we're done with it
			end ---if metadata.projectiles[projectile_xml]~=nil; ---processing block for existent projectiles
		end -- function override Reflection_RegisterProjectile();

		---strip values from c which we don't care about, modify others inline, return updated c table
		---@param in_c table incoming c table
		---@return table stripped c table
		local function parse_c(in_c)
			local skip_or_modify_hash =
			{		---table of values to remove, modify here if add'l data required
				-- pattern_degrees = true,
				-- bounces = true,
				-- action_spawn_level = true,
				-- lightning_count = true,
				state_destroyed_action = true,
				-- action_ai_never_uses = true,
				-- action_name = true,
				-- recoil = true,
				-- action_max_uses = true,
				fire_rate_wait = true,
				sprite = true,
				-- explosion_damage_to_materials = true,
				physics_impulse_coeff = true,
				-- trail_material = true,
				-- child_speed_multiplier = true,
				-- action_draw_many_count = true,
				-- damage_critical_chance = true,
				gore_particles = true,
				action_sprite_filename = true,
				-- action_type = true,
				game_effect_entities = true,
				screenshake = true,
				-- material = true,
				extra_entities = true,
				-- action_never_unlimited = true,
				-- friendly_fire = true,
				sound_loop_tag = true,
				-- action_spawn_probability = true,
				reload_time = true,
				projectile_file = true,
				state_shuffled = true,
				-- explosion_radius = true,
				custom_xml_file = true,
				-- action_mana_drain = true,
				ragdoll_fx = true,
				-- light = true,
				-- action_is_dangerous_blast = true,
				-- spread_degrees = true,
				state_discarded_action = true,
				action_unidentified_sprite_filename = true,
				-- action_description = true,
				-- speed_multiplier = true,
				-- dampening = true,
				-- damage_null_all = true,
				-- knockback_force = true,
				-- action_spawn_requires_flag = true,
				-- blood_count_multiplier = true,
				-- trail_material_amount = true,
				-- damage_critical_multiplier = true,
				state_cards_drawn = true,
				action_spawn_manual_unlock = true,
				-- material_amount = true,
				-- action_id = true,
				-- gravity = true,
				-- lifetime_add = true,
				-- damage_slice_add = true,
				-- damage_ice_add = true,
				-- damage_curse_add = true,
				-- damage_healing_add = true,
				-- damage_drill_add = true,
				damage_fire_add = true,
				damage_melee_add = true,
				damage_electricity_add = true,
				damage_explosion_add = true,
				damage_projectile_add = true,
			};
			local out_c = {}; ---create out_c table
			for membername, _ in pairs(in_c) do ---iterate through members in incoming table
				if skip_or_modify_hash[membername]~=true then ---check against skip_hash to only store desired info
					out_c[membername] = in_c[membername]; ---copy member to output table
				elseif	membername=="damage_electricity_add" or
								membername=="damage_melee_add" or
								membername=="damage_explosion_add" or
								membername=="damage_projectile_add" or
								membername=="damage_fire_add" then
					out_c[membername] = in_c[membername] * 25;
				elseif 	membername=="reload_time" or
								membername=="fire_rate_wait" then
					out_c[membername] = in_c[membername] / 60;
				end ---if skip_hash[membername];
			end ---for membername in in_ic
			return out_c; ---return data table
		end ---function strip_c(in_c); ---returns stripped c structure

		-- local _draw_actions = draw_actions;
		local draws = 0; -- start at 0 additional draws
		draw_actions = function( x ) draws = draws + x; end -- another local override for action() to count draw_action calls

		local _c = c; -- capture the global c context
		c = {}; -- clear c context so we only get one action()
		shot_effects = {}; -- clear shot_effects context so we only get one action()
		current_reload_time = 0; -- clear current_reload_time so we only get one action()
		reset_modifiers( c ); -- prepare c table structure and initialize for relative operations
		ConfigGunShotEffects_Init( shot_effects ); -- prepare shot_effects table structure and initialize for relative operations
		reflecting = true; -- This is how we tell the game not to do the things, this redirects many of the action's calls to Reflection_RegisterProjectile() which allows us to extract data
		actions_by_id[action_id].action(); -- call the action() function
		reflecting = false; -- Return to normal. Likely not necessary but....
		actions_by_id[action_id] = actions_by_id[action_id] or {}; -- new table if not already present
		actions_by_id[action_id].c = parse_c(c); -- strip c before storing its data
		actions_by_id[action_id].c.draw_actions = draws; -- add a few flags
		actions_by_id[action_id].c.reload_time = current_reload_time;
		actions_by_id[action_id].c.recoil_knockback = shot_effects.recoil_knockback;
		actions_by_id[action_id].c.projectiles =  metadata.projectiles;
		c = _c; -- restore the global c context
	end -- function get_action_metadata(action_id)

	---intended to be run when new actions are found, typically by code below -- feeds information directly into actions_by_id
	---@param max_new_actions_this_pass number
	function collect_action_data(max_new_actions_this_pass)
		local target_cnt = action_count + max_new_actions_this_pass; ---track how many actions we're targeting as our max
		local player = EntityGetWithTag("player_unit")[1];

		if player then EntityRemoveTag(player, "player_unit"); end ---remove player_unit tag, this protects us from some actions
		for _,curr_action in pairs(actions) do ---iterate thru actions until finished or stopped
			if actions_by_id[curr_action.id]==nil and curr_action.id~=nil then ---only process non-nil entries
				action_count = (action_count or 0) + 1; ---add to the action count, start at zero if un-initialized
				actions_by_id[curr_action.id] = curr_action; ---store current action basic data
				get_action_metadata(curr_action.id); ---process action to add metadata
			end ---if actions_by_id[curr_action.id]==nil and curr_action.id~=nil;
			if action_count >= target_cnt then break; end
		end ---for curr_action in actions;
		if player then EntityAddTag(player, "player_unit"); end ---re-add player_unit tag to stored player entity
	end -- function collect_action_data(max_new_actions_this_pass)

	---debugging function
	function table_dump(o)
		if type(o) == 'table' then
			 local s = '{ '
			 for k,v in pairs(o) do
					if type(k) ~= 'number' then k = '"'..k..'"' end
					s = s .. '['..k..'] = ' .. table_dump(v) .. ','
			 end
			 return s .. '} '
		else
			 return tostring(o)
		end
 end ---function table_dump(0);
end -- if initialized

---intended to be run every world update w/ minimal impact
if action_count<#actions then
	print("actions_by_id: capturing new actions, group " .. action_count .. " to (at most) " .. action_count + 150);
	collect_action_data(150);
	actions_bt_id__notify_when_finished = true;
elseif actions_bt_id__notify_when_finished==true then
	actions_bt_id__notify_when_finished = false;
	print("actions_by_id: scan done, storing " .. action_count .. " actions")
	print(table_dump(actions_by_id["BOMB"]));
end
