-- ============================================================
-- OBS Auto Away Image
-- Version: 1.0.0
--
-- Automatically hides a selected OBS source after a set time.
-- Useful for AFK / BRB / away images during streams.
--
-- Requirements:
--   - OBS Studio with Lua scripting support
--
-- License: MIT
-- ============================================================

obs = obslua

-- ------------------------------------------------------------
-- 設定
-- ------------------------------------------------------------

source_name = ""
timeout_minutes = 15

-- 監視間隔（ミリ秒）
check_interval_ms = 500

-- ------------------------------------------------------------
-- 内部状態
-- ------------------------------------------------------------

was_visible = false
timer_running = false
elapsed_ms = 0


-- ------------------------------------------------------------
-- ログ
-- ------------------------------------------------------------

function log_info(message)
    obs.script_log(obs.LOG_INFO, "[AutoAwayImage] " .. message)
end


-- ------------------------------------------------------------
-- 指定ソースの SceneItem を探す
-- ------------------------------------------------------------

function find_scene_item_recursive(scene, target_name)

    if scene == nil then
        return nil
    end

    local items = obs.obs_scene_enum_items(scene)

    if items == nil then
        return nil
    end

    local found = nil

    for _, item in ipairs(items) do

        local source = obs.obs_sceneitem_get_source(item)

        if source ~= nil then

            local name = obs.obs_source_get_name(source)

            if name == target_name then
                found = item
                break
            end

            -- グループ内も検索
            if obs.obs_sceneitem_is_group(item) then

                local group_scene = obs.obs_sceneitem_group_get_scene(item)

                if group_scene ~= nil then
                    found = find_scene_item_recursive(
                        group_scene,
                        target_name
                    )

                    if found ~= nil then
                        break
                    end
                end
            end
        end
    end

    obs.sceneitem_list_release(items)

    return found
end


-- ------------------------------------------------------------
-- 全シーンから対象ソースを探す
-- ------------------------------------------------------------

function find_target_item()

    if source_name == nil or source_name == "" then
        return nil
    end

    local scenes = obs.obs_frontend_get_scenes()

    if scenes == nil then
        return nil
    end

    local found = nil

    for _, scene_source in ipairs(scenes) do

        local scene = obs.obs_scene_from_source(scene_source)

        if scene ~= nil then

            found = find_scene_item_recursive(
                scene,
                source_name
            )

            if found ~= nil then
                break
            end
        end
    end

    obs.source_list_release(scenes)

    return found
end


-- ------------------------------------------------------------
-- 対象が表示中か確認
-- ------------------------------------------------------------

function is_target_visible()

    local item = find_target_item()

    if item == nil then
        return false
    end

    return obs.obs_sceneitem_visible(item)
end


-- ------------------------------------------------------------
-- 対象を非表示にする
-- ------------------------------------------------------------

function hide_target()

    if source_name == nil or source_name == "" then
        return
    end

    local scenes = obs.obs_frontend_get_scenes()

    if scenes == nil then
        return
    end

    local hidden_count = 0

    for _, scene_source in ipairs(scenes) do

        local scene = obs.obs_scene_from_source(scene_source)

        if scene ~= nil then

            local item = find_scene_item_recursive(
                scene,
                source_name
            )

            if item ~= nil then

                if obs.obs_sceneitem_visible(item) then
                    obs.obs_sceneitem_set_visible(
                        item,
                        false
                    )

                    hidden_count = hidden_count + 1
                end
            end
        end
    end

    obs.source_list_release(scenes)

    if hidden_count > 0 then
        log_info(
            "時間になったため「"
            .. source_name
            .. "」を自動で非表示にしました。"
        )
    end
end


-- ------------------------------------------------------------
-- メイン監視
-- ------------------------------------------------------------

function check_visibility()

    if source_name == nil or source_name == "" then
        return
    end

    local visible = is_target_visible()

    -- ----------------------------------------
    -- OFF → ON を検知
    -- ----------------------------------------

    if visible and not was_visible then

        elapsed_ms = 0
        timer_running = true

        log_info(
            "「"
            .. source_name
            .. "」を検知。"
            .. tostring(timeout_minutes)
            .. "分タイマーを開始します。"
        )
    end


    -- ----------------------------------------
    -- 手動でOFFにした
    -- ----------------------------------------

    if not visible and was_visible then

        if timer_running then
            log_info(
                "「"
                .. source_name
                .. "」が手動で非表示になりました。"
                .. "タイマーをリセットします。"
            )
        end

        timer_running = false
        elapsed_ms = 0
    end


    -- ----------------------------------------
    -- カウント
    -- ----------------------------------------

    if visible and timer_running then

        elapsed_ms = elapsed_ms + check_interval_ms

        local timeout_ms =
            timeout_minutes * 60 * 1000

        if elapsed_ms >= timeout_ms then

            timer_running = false
            elapsed_ms = 0

            hide_target()

            visible = false
        end
    end

    was_visible = visible
end


-- ------------------------------------------------------------
-- OBS設定画面
-- ------------------------------------------------------------

function script_properties()

    local props = obs.obs_properties_create()

    local source_list = obs.obs_properties_add_list(
        props,
        "source_name",
        "離席画像のソース",
        obs.OBS_COMBO_TYPE_LIST,
        obs.OBS_COMBO_FORMAT_STRING
    )

    -- OBS内のソース一覧
    local sources = obs.obs_enum_sources()

    if sources ~= nil then

        for _, source in ipairs(sources) do

            local name = obs.obs_source_get_name(source)

            if name ~= nil and name ~= "" then
                obs.obs_property_list_add_string(
                    source_list,
                    name,
                    name
                )
            end
        end

        obs.source_list_release(sources)
    end


    -- 自動OFF時間
    local time_list = obs.obs_properties_add_list(
        props,
        "timeout_minutes",
        "自動OFFまでの時間",
        obs.OBS_COMBO_TYPE_LIST,
        obs.OBS_COMBO_FORMAT_INT
    )

    obs.obs_property_list_add_int(
        time_list,
        "5分",
        5
    )

    obs.obs_property_list_add_int(
        time_list,
        "10分",
        10
    )

    obs.obs_property_list_add_int(
        time_list,
        "15分",
        15
    )

    obs.obs_property_list_add_int(
        time_list,
        "20分",
        20
    )

    obs.obs_property_list_add_int(
        time_list,
        "30分",
        30
    )

    obs.obs_property_list_add_int(
        time_list,
        "45分",
        45
    )

    obs.obs_property_list_add_int(
        time_list,
        "60分",
        60
    )

    return props
end


-- ------------------------------------------------------------
-- デフォルト設定
-- ------------------------------------------------------------

function script_defaults(settings)

    obs.obs_data_set_default_int(
        settings,
        "timeout_minutes",
        15
    )
end


-- ------------------------------------------------------------
-- 設定変更
-- ------------------------------------------------------------

function script_update(settings)

    source_name =
        obs.obs_data_get_string(
            settings,
            "source_name"
        )

    timeout_minutes =
        obs.obs_data_get_int(
            settings,
            "timeout_minutes"
        )

    -- 安全対策
    if timeout_minutes <= 0 then
        timeout_minutes = 15
    end

    -- 状態リセット
    timer_running = false
    elapsed_ms = 0
    was_visible = is_target_visible()

    log_info(
        "設定更新：対象="
        .. tostring(source_name)
        .. " / 自動OFF="
        .. tostring(timeout_minutes)
        .. "分"
    )
end


-- ------------------------------------------------------------
-- スクリプト説明
-- ------------------------------------------------------------

function script_description()

    return [[
<h2>Auto Away Image</h2>

OBSの離席画像を自動で非表示にするスクリプトです。<br><br>

<b>使い方</b><br>
1. 「離席画像のソース」を選択<br>
2. 自動OFFまでの時間を選択<br>
3. OBSで普段通り目アイコンを押して画像を表示<br><br>

画像が表示されると自動的にタイマーが開始され、
設定時間が経過すると画像を自動で非表示にします。<br><br>

途中で自分で画像を非表示にした場合は
タイマーも自動的にリセットされます。
]]
end


-- ------------------------------------------------------------
-- 読み込み
-- ------------------------------------------------------------

function script_load(settings)

    obs.timer_add(
        check_visibility,
        check_interval_ms
    )

    log_info("スクリプトを読み込みました。")
end


-- ------------------------------------------------------------
-- 終了
-- ------------------------------------------------------------

function script_unload()

    obs.timer_remove(
        check_visibility
    )

    log_info("スクリプトを終了しました。")
end