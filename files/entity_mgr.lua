if entity_mgr_loaded==nil then entity_mgr_loaded=false; end
if entity_mgr_loaded==false then
-- one time init
	known_workshops = {};
	lobby_e_id = 0;

	---close out frame by disabling triggers
	function OnEndFrame()
		if GlobalsGetValue("lobby_collider_triggered", "x")=="1" then GlobalsSetValue("lobby_collider_triggered", "0"); end	---disable trigger every frame; re-enabled by collider entity
		if GlobalsGetValue("workshop_collider_triggered", "x")=="1" then GlobalsSetValue("workshop_collider_triggered", "0"); end	---disable trigger every frame; re-enabled by collider entity
	end
end


-- TODO : Remove Move lobby to spawn mod setting?


-- every frame
if GameGetFrameNum()%5==0 then -- every five frames, for performance
	if lobby_e_id==0 and player_e_id~=0 then
		lobby_e_id=EntityGetWithName("persistence_lobby");
		if lobby_e_id==0 then
			local x_loc = GlobalsGetValue("first_spawn_x", "x");
			local y_loc = GlobalsGetValue("first_spawn_y", "x");
			lobby_e_id = EntityLoad(mod_dir .. "files/entity/lobby.xml", x_loc, y_loc);
		end
	end

	local workshop_pool = EntityGetWithTag("workshop");
	for _, workshop_e_id in ipairs(workshop_pool) do
		if not EntityHasTag(workshop_e_id, "persistence_cloned") then
			local workshop_hitbox_comp = EntityGetComponent(workshop_e_id, "HitboxComponent")[1];
			if workshop_hitbox_comp~=nil then
				local workshop_hitbox = ComponentGetMembers(workshop_hitbox_comp);
				if workshop_hitbox~=nil then
					print("persistence: entity_mgr.lua: cloend workshop " .. workshop_e_id);
					local _width = workshop_hitbox["aabb_max_x"] - workshop_hitbox["aabb_min_x"];
					local _height = workshop_hitbox["aabb_max_y"] - workshop_hitbox["aabb_min_y"];
					local _xloc, _yloc = EntityGetFirstHitboxCenter(workshop_e_id);
					local new_workshop_id = EntityLoad(mod_dir .. "files/entity/workshop.xml", _xloc, _yloc);
					EntityAddComponent2(new_workshop_id, "CollisionTriggerComponent", {width=_width, height=_height, radius=1000, destroy_this_entity_when_triggered=false, required_tag="player_unit", _enabled=true});
					EntityAddTag(workshop_e_id, "persistence_cloned");
					if ModSettingGet("persistence.reusable_holy_mountain")~=true then
						EntityAddChild(workshop_e_id, new_workshop_id);
					end
				end
			end
		end
	end
end