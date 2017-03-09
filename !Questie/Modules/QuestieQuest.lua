---------------------------------------------------------------------------------------------------
--Name: QuestieQuest
--Description: Handles all the quest related functions
---------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////--
---------------------------------------------------------------------------------------------------
--Local Vars
---------------------------------------------------------------------------------------------------
local QuestieHashCache = {};
local LastNrOfEntries = 0;
local CachedIds = {};
local QuestieQuestHashCache = {};
local QGet_TitleText = GetTitleText;
local QGet_QuestLogTitle = GetQuestLogTitle;
local QGet_NumQuestLeaderBoards = GetNumQuestLeaderBoards;
local QGet_QuestLogLeaderBoard = GetQuestLogLeaderBoard;
local QGet_QuestLogQuestText = GetQuestLogQuestText;
local QGet_NumQuestLogEntries = GetNumQuestLogEntries;
local QGet_QuestLogSelection = GetQuestLogSelection;
local QSelect_QuestLogEntry = SelectQuestLogEntry;
---------------------------------------------------------------------------------------------------
--Global Vars
---------------------------------------------------------------------------------------------------
LastQuestLogHashes = nil;
LastQuestLogCount = 0;
lastObjectives = nil;
QuestAbandonOnAccept = nil;
QuestAbandonWithItemsOnAccept = nil;
QuestRewardCompleteButton = nil;
QuestProgressCompleteButton = nil;
QuestDetailAcceptButton = nil;
Questie.lastCollapsedCount = 0;
Questie.collapsedThisRun = false;
QUESTIE_LAST_UPDATECACHE = GetTime();
---------------------------------------------------------------------------------------------------
--Blizzard Hook: Quest Abandon On Accept
---------------------------------------------------------------------------------------------------
QuestAbandonOnAccept = StaticPopupDialogs["ABANDON_QUEST"].OnAccept;
StaticPopupDialogs["ABANDON_QUEST"].OnAccept = function()
    local prevQuestLogSelection = QGet_QuestLogSelection();
    local id = 1;
    local qc = 0;
    local qName = GetAbandonQuestName();
    local nEntry, nQuests = QGet_NumQuestLogEntries();
    while qc < nQuests do
        local questName, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(id);
        if not isHeader and not isCollapsed then
            if qName == questName then
                QSelect_QuestLogEntry(id);
                local questText, objectiveText = QGet_QuestLogQuestText();
                local hash = Questie:getQuestHash(questName, level, objectiveText);
                QuestieSeenQuests[hash] = -1;
                QuestieCachedQuests[hash] = nil;
                QuestieHandledQuests[hash] = nil;
                --Questie:debug_Print("Quest:QuestAbandonOnAccept: [questTitle: "..questName.."] | [Hash: "..hash.."]");
                RemoveCrazyArrow(hash);
                QuestAbandonOnAccept();
            end
        end
        if not isHeader then
            qc = qc + 1;
        end
        id = id + 1;
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
end
---------------------------------------------------------------------------------------------------
--Blizzard Hook: Quest Abandon With Items On Accept
---------------------------------------------------------------------------------------------------
QuestAbandonWithItemsOnAccept = StaticPopupDialogs["ABANDON_QUEST_WITH_ITEMS"].OnAccept;
StaticPopupDialogs["ABANDON_QUEST_WITH_ITEMS"].OnAccept = function()
    local prevQuestLogSelection = QGet_QuestLogSelection();
    local id = 1;
    local qc = 0;
    local qName = GetAbandonQuestName();
    local nEntry, nQuests = QGet_NumQuestLogEntries();
    while qc < nQuests do
        local questName, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(id);
        if not isHeader and not isCollapsed then
            if qName == questName then
                QSelect_QuestLogEntry(id);
                local questText, objectiveText = QGet_QuestLogQuestText();
                local hash = Questie:getQuestHash(questName, level, objectiveText);
                QuestieSeenQuests[hash] = -1;
                QuestieCachedQuests[hash] = nil;
                QuestieHandledQuests[hash] = nil;
                --Questie:debug_Print("Quest:QuestAbandonWithItemsOnAccept: [questTitle: "..questName.."] | [Hash: "..hash.."]");
                RemoveCrazyArrow(hash);
                QuestAbandonWithItemsOnAccept();
            end
        end
        if not isHeader then
            qc = qc + 1;
        end
        id = id + 1;
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
end
---------------------------------------------------------------------------------------------------
--Blizzard Hook: Quest Reward Complete Button
---------------------------------------------------------------------------------------------------
QuestRewardCompleteButton = QuestRewardCompleteButton_OnClick;
QuestRewardCompleteButton_OnClick = function()
    if Questie:CheckPlayerInventory() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF2222 Quest:QuestRewardCompleteButton: Unable to auto complete quest. Player inventory is full!");
        PlaySound("igQuestLogAbandonQuest");
        DeclineQuest();
        HideUIPanel(QuestFrame);
        return
    end
    local questTitle = QGet_TitleText();
    local _, _, qlevel, qName = string.find(questTitle, "%[(.+)%] (.+)");
    if qName == nil then
        qName = QGet_TitleText();
    else
        qName = qName;
    end
    local id = 1;
    local qc = 0;
    local prevQuestLogSelection = QGet_QuestLogSelection();
    local nEntry, nQuests = QGet_NumQuestLogEntries();
    while qc < nQuests do
        local questName, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(id);
        if not isHeader and not isCollapsed then
            if qName == questName then
                QSelect_QuestLogEntry(id);
                local questText, objectiveText = QGet_QuestLogQuestText();
                local hash = Questie:getQuestHash(questName, level, objectiveText);
                QuestieSeenQuests[hash] = 1;
                QuestieCompletedQuestMessages[qName] = 1;
                QuestieCachedQuests[hash] = nil;
                QuestieHandledQuests[hash] = nil;
                --Questie:debug_Print("Quest:QuestRewardCompleteButton: [questTitle: "..questName.."] | [Hash: "..hash.."]");
                RemoveCrazyArrow(hash);
                QuestRewardCompleteButton();
            end
        end
        if not isHeader then
            qc = qc + 1;
        end
        id = id + 1;
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
end
---------------------------------------------------------------------------------------------------
--Blizzard Hook: Quest Progress Complete Button
---------------------------------------------------------------------------------------------------
QuestProgressCompleteButton = QuestProgressCompleteButton_OnClick;
QuestProgressCompleteButton_OnClick = function()
    if IsQuestCompletable() then
        if Questie:CheckPlayerInventory() == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF2222 Quest:QuestProgressCompleteButton: Unable to auto complete quest. Player inventory is full!");
            PlaySound("igQuestLogAbandonQuest");
            DeclineQuest();
            HideUIPanel(QuestFrame);
            return
        end
        local questTitle = QGet_TitleText();
        local _, _, qlevel, qName = string.find(questTitle, "%[(.+)%] (.+)");
        if qName == nil then
            qName = QGet_TitleText();
        else
            qName = qName;
        end
        local id = 1;
        local qc = 0;
        local prevQuestLogSelection = QGet_QuestLogSelection();
        local nEntry, nQuests = QGet_NumQuestLogEntries();
        while qc < nQuests do
            local questName, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(id);
            if not isHeader and not isCollapsed then
                if qName == questName then
                    QSelect_QuestLogEntry(id);
                    local questText, objectiveText = QGet_QuestLogQuestText();
                    local hash = Questie:getQuestHash(questName, level, objectiveText);
                    QuestieSeenQuests[hash] = 1;
                    QuestieCompletedQuestMessages[qName] = 1;
                    QuestieCachedQuests[hash] = nil;
                    QuestieHandledQuests[hash] = nil;
                    --Questie:debug_Print("Quest:QuestProgressCompleteButton: [questTitle: "..questName.."] | [Hash: "..hash.."]");
                    RemoveCrazyArrow(hash);
                    QuestProgressCompleteButton();
                end
            end
            if not isHeader then
                qc = qc + 1;
            end
            id = id + 1;
        end
        QSelect_QuestLogEntry(prevQuestLogSelection);
    end
end
---------------------------------------------------------------------------------------------------
--Blizzard Hook: Quest Progress Accept Button
---------------------------------------------------------------------------------------------------
QuestDetailAcceptButton = QuestDetailAcceptButton_OnClick;
function QuestDetailAcceptButton_OnClick()
    Questie:UpdateGameClientCache();
    QuestDetailAcceptButton();
end
---------------------------------------------------------------------------------------------------
--EQL3 is auto finishing Quests too quickly for normal events to detect. Questie calls this
--function at the sametime to make sure our quest is flagged and updated accordingly.
---------------------------------------------------------------------------------------------------
function Questie:CompleteQuest()
    if IsAddOnLoaded("EQL3") or IsAddOnLoaded("ShaguQuest") then
        if (QuestlogOptions[EQL3_Player].AutoCompleteQuests == 1) then
            if (IsQuestCompletable()) then
                local Questie_EQL3ToggleSave = nil;
                if Questie:CheckPlayerInventory() == 0 then
                    Questie_EQL3ToggleSave = QuestlogOptions[EQL3_Player].AutoCompleteQuests
                    if QuestlogOptions[EQL3_Player].AutoCompleteQuests == 1 then
                        QuestlogOptions[EQL3_Player].AutoCompleteQuests = 0;
                    end
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF2222 Quest:CompleteQuest: Unable to auto complete quest. Player inventory is full!");
                    PlaySound("igQuestLogAbandonQuest");
                    DeclineQuest();
                    HideUIPanel(QuestFrame);
                    return
                elseif Questie_EQL3ToggleSave ~= nil then
                    QuestlogOptions[EQL3_Player].AutoCompleteQuests = Questie_EQL3ToggleSave;
                end
                local questTitle = QGet_TitleText();
                local _, _, qlevel, qName = string.find(questTitle, "%[(.+)%] (.+)");
                if qName == nil then
                    qName = QGet_TitleText();
                else
                    qName = qName;
                end
                local id = 1;
                local qc = 0;
                local prevQuestLogSelection = QGet_QuestLogSelection();
                local nEntry, nQuests = QGet_NumQuestLogEntries();
                while qc < nQuests do
                    local questName, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(id);
                    if not isHeader and not isCollapsed then
                        if qName == questName then
                            QSelect_QuestLogEntry(id);
                            local questText, objectiveText = QGet_QuestLogQuestText();
                            local hash = Questie:getQuestHash(questName, level, objectiveText);
                            if (not QuestieSeenQuests[hash]) or (QuestieSeenQuests[hash] == 0) or (QuestieSeenQuests[hash] == -1) then
                                QuestieSeenQuests[hash] = 1;
                                QuestieCompletedQuestMessages[qName] = 1;
                                QuestieCachedQuests[hash] = nil;
                                QuestieHandledQuests[hash] = nil;
                                Questie:debug_Print("Quest:CompleteQuest: [questTitle: "..questName.."] | [Hash: "..hash.."]");
                                Questie:finishAndRecurse(hash);
                                RemoveCrazyArrow(hash);
                            end
                        end
                    end
                    if not isHeader then
                        qc = qc + 1;
                    end
                    id = id + 1;
                end
                QSelect_QuestLogEntry(prevQuestLogSelection);
            end
        end
    end
end
---------------------------------------------------------------------------------------------------
--EQL3 is auto finishing Quests too quickly for normal events to detect. Questie calls this
--function at the sametime to make sure our quest is flagged and updated accordingly.
---------------------------------------------------------------------------------------------------
function Questie:GetQuestReward()
    if IsAddOnLoaded("EQL3") or IsAddOnLoaded("ShaguQuest") then
        if (QuestlogOptions[EQL3_Player].AutoCompleteQuests == 1) and (GetNumQuestChoices() == 0) then
            if Questie:CheckPlayerInventory() == 0 then
                local Questie_EQL3ToggleSave = nil;
                Questie_EQL3ToggleSave = QuestlogOptions[EQL3_Player].AutoCompleteQuests
                if QuestlogOptions[EQL3_Player].AutoCompleteQuests == 1 then
                    QuestlogOptions[EQL3_Player].AutoCompleteQuests = 0;
                end
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF2222 Quest:GetQuestReward: Unable to auto complete quest. Player inventory is full!");
                PlaySound("igQuestLogAbandonQuest");
                DeclineQuest();
                HideUIPanel(QuestFrame);
                return
            elseif Questie_EQL3ToggleSave ~= nil then
                QuestlogOptions[EQL3_Player].AutoCompleteQuests = Questie_EQL3ToggleSave;
            end
            local questTitle = QGet_TitleText();
            local _, _, qlevel, qName = string.find(questTitle, "%[(.+)%] (.+)");
            if qName == nil then
                qName = QGet_TitleText();
            else
                qName = qName;
            end
            local id = 1;
            local qc = 0;
            local prevQuestLogSelection = QGet_QuestLogSelection();
            local nEntry, nQuests = QGet_NumQuestLogEntries();
            while qc < nQuests do
                local questName, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(id);
                if not isHeader and not isCollapsed then
                    if qName == questName then
                        QSelect_QuestLogEntry(id);
                        local questText, objectiveText = QGet_QuestLogQuestText();
                        local hash = Questie:getQuestHash(questName, level, objectiveText);
                        if (not QuestieSeenQuests[hash]) or (QuestieSeenQuests[hash] == 0) or (QuestieSeenQuests[hash] == -1) then
                            QuestieSeenQuests[hash] = 1;
                            QuestieCompletedQuestMessages[qName] = 1;
                            QuestieCachedQuests[hash] = nil;
                            QuestieHandledQuests[hash] = nil;
                            Questie:debug_Print("Quest:GetQuestReward: [questTitle: "..questName.."] | [Hash: "..hash.."]");
                            Questie:finishAndRecurse(hash);
                            RemoveCrazyArrow(hash);
                        end
                    end
                end
                if not isHeader then
                    qc = qc + 1;
                end
                id = id + 1;
            end
            QSelect_QuestLogEntry(prevQuestLogSelection);
        end
    end
end
---------------------------------------------------------------------------------------------------
--Matches a looted item to quest items that are contained in the QuestieCachedQuests table
---------------------------------------------------------------------------------------------------
function Questie:DetectQuestItem(itemName)
    for k, v in pairs(QuestieCachedQuests) do
        local num = v["leaderboards"]
        for i=1,num do
            desc = v["objective"..i]["desc"]
            if (desc) then
                local  _, _, questItem, itemHave, itemNeed = string.find(desc, "(.+)%: (%d+)/(%d+)");
                if itemName == questItem and itemHave ~= itemNeed then
                    --Questie:debug_Print("Quest:DetectQuestItem: [questItem: "..questItem.."] | [itemHave: "..itemHave.."] | [itemNeed: "..itemNeed.."]");
                    --Questie:debug_Print("Quest:DetectQuestItem: TRUE");
                    return true
                end
            end
        end
    end
    --Questie:debug_Print("Quest:DetectQuestItem: FALSE");
    return false
end
---------------------------------------------------------------------------------------------------
--Used to make sure the players inventory isn't full before auto-completing quest.
---------------------------------------------------------------------------------------------------
function Questie:CheckPlayerInventory()
    local totalSlots, usedSlosts, availableSlots;
    local totalSlots = 0;
    local usedSlots = 0;
    for bag = 0, 4 do
        local size = GetContainerNumSlots(bag);
        if (size and size > 0) then
		    totalSlots = totalSlots + size;
            for slot = 1, size do
                if (GetContainerItemInfo(bag, slot)) then
                    usedSlots = usedSlots + 1;
                end
            end
        end
    end
    availableSlots = totalSlots - usedSlots;
    return availableSlots
end
---------------------------------------------------------------------------------------------------
--Finishes a quest and performs a recrusive check to make sure all the required quests that come
--before it are also finsihed and recorded in the players QuestieSeenQuests. It will also clear
--any redundant quest tracking data and make sure a quest that is in a players log isn't
--accidently marked finished. When ever this function is run it will also remove invalid tracker
--data when it doesn't find a matching hash in the QuestieSeenQuests table. This sometimes
--happens when a player starts a quest chain.
---------------------------------------------------------------------------------------------------
function Questie:finishAndRecurse(questhash)
    local QSQ = QuestieSeenQuests;
    local QCQ = QuestieCachedQuests;
    local QHM = QuestieHashMap;
    --If it finds a completed quest with left over cached data, then the cached
    --data gets cleared.
    if (QSQ[questhash] == 1) then
        if (QCQ[questhash]) then
            QCQ[questhash] = nil;
        end
    end
    --This loop checks to make sure a quest is finished before marking it complete. It then
    --recursively checks all required quests before it and marks those as complete as well. It
    --also checks each one to make sure we aren't marking a seen quest finished.
    if (QSQ[questhash] == 0) and (QCQ[questhash]) then
        if ((QCQ[questhash]["leaderboards"] == 0 or QCQ[questhash]["leaderboards"] == 1) or (QCQ[questhash]["isComplete"] == 1)) then
            QSQ[questhash] = 1;
            QCQ[questhash] = nil;
            RemoveCrazyArrow(questhash);
        else
            local req = nil;
            if QHM[questhash] then
                req = QHM[questhash]['rq'];
            end
            if req and QSQ[req] ~= 1 then
                Questie:finishAndRecurse(req);
            end
            return;
        end
    --This loop allows a player to recursively finish a quest and all required quests that comes
    --before it by shift+clicking an icon from one of the maps. It also checks each one to make
    --sure we aren't marking a seen quest finished.
    elseif ((QSQ[questhash] == nil) and (QCQ[questhash] == nil)) then
        QSQ[questhash] = 1;
        local req = nil;
        if QHM[questhash] then
            req = QHM[questhash]['rq'];
        end
        if req and QSQ[req] ~= 1 then
            Questie:finishAndRecurse(req);
        else
            return;
        end
    end
    --This trolls through all cached data to make sure it stays cleaned up.
    local index = 0;
    for i,v in pairs(QCQ) do
        if QSQ[i] == 1 then
            QCQ[i] = nil;
            index = index + 1;
        end
    end
end
---------------------------------------------------------------------------------------------------
--Checks the players quest log upon login or ReloadUI to make sure QuestieMapNotes and
--QuestieCachedQuests get pre-populated with cache data before normal CheckLog functions are run.
--This is especially important if this data isn't already in the WoW game clients local cache.
---------------------------------------------------------------------------------------------------
function Questie:UpdateGameClientCache()
    if (GetTime() - QUESTIE_LAST_UPDATECACHE > 0.1) then
        --Questie:debug_Print();
        --Questie:debug_Print("************************| Beginning Game Client Cache Pull |************************");
        local prevQuestLogSelection = QGet_QuestLogSelection();
        local id = 1;
        local qc = 0;
        local nEntry, nQuests = QGet_NumQuestLogEntries();
        while qc < nQuests do
            local questName, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(id);
            if not isHeader and not isCollapsed then
                QSelect_QuestLogEntry(id);
                local questText, objectiveText = QGet_QuestLogQuestText();
                local hash = Questie:getQuestHash(questName, level, objectiveText);
                Questie:AddQuestToMap(hash);
                QuestieTracker:addQuestToTrackerCache(hash);
                Questie:AddQuestToMap(hash);
            end
            if not isHeader then
                qc = qc + 1;
            end
            id = id + 1;
        end
        QSelect_QuestLogEntry(prevQuestLogSelection);
        --Questie:debug_Print("************************| Game Client Cache Pull Complete |************************");
        --Questie:debug_Print();
        QUESTIE_LAST_UPDATECACHE = GetTime();
    else
        QUESTIE_LAST_UPDATECACHE = GetTime();
    end
end
---------------------------------------------------------------------------------------------------
--Checks the players quest log
---------------------------------------------------------------------------------------------------
function Questie:CheckQuestLog()
    --LastQuestLogHashes should always be nil upon Login or a ReloadUI - do these checks
    if (not LastQuestLogHashes) then
        --Questie:debug_Print();
        --Questie:debug_Print("************************| [PRE] Beginning CheckLog |************************ ");
        --Clears abandoned quests
        for k, v in pairs(QuestieSeenQuests) do
            if (QuestieSeenQuests[k] == -1) then
                Questie:RemoveQuestFromMap(k);
                QuestieCachedQuests[k] = nil;
                QuestieSeenQuests[k] = nil;
                QUEST_WATCH_LIST[k] = nil;
                --Questie:debug_Print("Quest:CheckQuestLog: Cleared abandoned quest: [Hash: "..k.."]");
            end
        end
        --Clears cached data
        for k, v in pairs(QuestieCachedQuests) do
            if QuestieSeenQuests[k] == 1 then
                Questie:RemoveQuestFromMap(k);
                QuestieCachedQuests[k] = nil;
                --Questie:debug_Print("Quest:CheckQuestLog: Cleaned Quest Cache: [Hash: "..k.."]");
            end
        end
        LastQuestLogHashes = Questie:AstroGetAllCurrentQuestHashesAsMeta();
        for k, v in pairs(LastQuestLogHashes) do
            --If a quest is found in the log and for some reason it's set as finished (1), or
            --missing all together (nill), reset its status back to active (0).
            if QuestieSeenQuests[k] == 1 or QuestieSeenQuests[k] == nil then
                QuestieSeenQuests[k] = 0;
            end
            --This "double-tap" ensures quest data is inserted into the cache
            --Questie:debug_Print("Quest:CheckQuestLog: --> Tracker:addQuestToTrackerCache() [Hash: "..v["hash"].."]");
            QuestieTracker:addQuestToTrackerCache(v["hash"]);
            Questie:AddQuestToMap(v["hash"]);
        end
        Questie:OnLoad_QuestEvents();
        QuestieTracker:initWOWQuestLog();
        --Questie:debug_Print("Quest:CheckQuestLog: QuestLog Changed --> RefreshQuestStatus()");
        Questie:AddEvent("UPDATE", 0.1);
        Questie:AddEvent("UPDATE", 1.2);
        Questie:AddEvent("SYNCLOG", 1.4);
        Questie:AddEvent("DRAWNOTES", 1.6);
        Questie:AddEvent("TRACKER", 1.6);
        _, LastQuestLogCount = QGet_NumQuestLogEntries();
        QUESTIE_LAST_UPDATE_FINISHED = GetTime();
        --Questie:debug_Print("************************| [PRE] CheckLog Complete |************************ ");
        --Questie:debug_Print();
        GameLoadingComplete = true;
        return;
    end
    local Quests, QuestsCount = Questie:AstroGetAllCurrentQuestHashesAsMeta();
    MapChanged = false;
    delta = {};
    if (QuestsCount > LastQuestLogCount) then
        for k, v in pairs(Quests) do
            if (Quests[k] and LastQuestLogHashes[k]) then
            else
                if (Quests[k]) then
                    v["deltaType"] = 1;
                    table.insert(delta, v);
                else
                    v["deltaType"] = 0;
                    table.insert(delta, v);
                end
            end
        end
    else
        for k, v in pairs(LastQuestLogHashes) do
            if (Quests[k] and LastQuestLogHashes[k]) then
            else
                if (Quests[k]) then
                    v["deltaType"] = 1;
                    table.insert(delta, v);
                else
                    v["deltaType"] = 0;
                    table.insert(delta, v);
                end
            end
        end
    end
    for k, v in pairs(delta) do
        Questie:debug_Print();
        Questie:debug_Print("************************| [POST] Beginning CheckLog |************************ ");
        Questie:debug_Print("Quest:CheckQuestLog: UPON ENTER: [QuestsCount: "..QuestsCount.."] | [LastCount: "..LastQuestLogCount.."]");
        if (v["deltaType"] == 1) then
            Questie:AddQuestToMap(v["hash"]);
            --This adds a quest to the cache
            if (QuestieSeenQuests[v["hash"]] == nil) then
                QuestieSeenQuests[v["hash"]] = 0;
                Questie:debug_Print("Quest:CheckQuestLog: --> Quest:addQuestToTrackerCache() [Hash: "..v["hash"].."]");
                QuestieTracker:addQuestToTrackerCache(v["hash"]);
                QuestieTracker:syncWOWQuestLog();
            end
            MapChanged = true;
        elseif not Questie.collapsedThisRun then
            Questie:RemoveQuestFromMap(v["hash"]);
            --This clears cache of finished quests
            if (QuestieSeenQuests[v["hash"]] == 1) then
                QuestieTracker:removeQuestFromTracker(v["hash"]);
                Questie:finishAndRecurse(v["hash"]);
                Questie:debug_Print("Quest:CheckQuestLog: --> Quest:finishAndRecurse() [Hash: "..v["hash"].."]");
                if (not QuestieCompletedQuestMessages[v["name"]]) then
                    QuestieCompletedQuestMessages[v["name"]] = 0;
                end
            --This clears cache of abandoned quests
            elseif (QuestieSeenQuests[v["hash"]] == -1) then
                QuestieTracker:removeQuestFromTracker(v["hash"]);
                QuestieCachedQuests[v["hash"]] = nil;
                QuestieSeenQuests[v["hash"]] = nil;
                QUEST_WATCH_LIST[v["hash"]] = nil;
                Questie:debug_Print("Quest:CheckQuestLog: clear abandoned quest: [Hash: "..v["hash"].."]");
            end
            --Cleans cached data
            for k, v in pairs(QuestieCachedQuests) do
                if QuestieSeenQuests[k] == 1 then
                    QuestieCachedQuests[k] = nil;
                    Questie:debug_Print("Quest:CheckQuestLog: Cleaned Quest Cache: [Hash: "..k.."]");
                end
            end
            if lastObjectives and lastObjectives[v["hash"]] then
                Questie:debug_Print("Quest:CheckQuestLog: lastObjectives update [Hash: "..v["hash"].."]");
                lastObjectives = {};
            end
            MapChanged = true;
        end
    end
    delta = nil;
    LastQuestLogHashes = Quests;
    LastQuestLogCount = QuestsCount;
    if (MapChanged == true) then
        Questie:debug_Print("Quest:CheckQuestLog: QuestLog Changed --> [AddEvent:DRAWNOTES]");
        Questie:CheckQuestLog();
        Questie:RefreshQuestStatus();
        QUESTIE_LAST_UPDATE_FINISHED = GetTime();
        Questie:debug_Print("Quest:CheckQuestLog: UPON EXIT: [QuestsCount: "..QuestsCount.."] | [LastCount: "..LastQuestLogCount.."]");
        Questie:debug_Print("************************| [POST] CheckLog Complete |************************ ");
        Questie:debug_Print();
        return true;
    else
        QUESTIE_LAST_UPDATE_FINISHED = GetTime();
        return nil;
    end
end
---------------------------------------------------------------------------------------------------
--Adds or updates all active objectives in the questlog to the lastObjectives table
---------------------------------------------------------------------------------------------------
function Questie:UpdateQuests(force)
    if (not lastObjectives) then
        lastObjectives = {};
        Questie:UpdateQuestsInit();
        return;
    end
    local ZonesChecked = 0;
    local CurrentZone = GetZoneText();
    local numEntries, numQuests = QGet_NumQuestLogEntries();
    local change = Questie:UpdateQuestInZone(CurrentZone);
    local i = 1;
    local qc = 0;
    ZonesChecked = ZonesChecked + 1;
    if (not change) then
        change = Questie:UpdateQuestInZone(GetMinimapZoneText());
        ZonesChecked = ZonesChecked + 1;
    end
    if (not change or force) then
        while qc < numQuests do
            local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(i);
            if (isHeader and q ~= CurrentZone) then
                local c = Questie:UpdateQuestInZone(q, force);
                ZonesChecked = ZonesChecked + 1;
                change = c;
                if (c and not force)then
                    break;
                end
            end
            if not isHeader then
                qc = qc + 1;
            end
            i = i + 1;
        end
    else
    end
    return change;
end
---------------------------------------------------------------------------------------------------
--Updates all active objectives in a zone then updates the lastObjectives table
---------------------------------------------------------------------------------------------------
function Questie:UpdateQuestInZone(Zone, force)
    local numEntries, numQuests = QGet_NumQuestLogEntries();
    local foundChange = nil;
    local ZoneFound = nil;
    local QuestsChecked = 0;
    local i = 1;
    local qc = 0;
    local prevQuestLogSelection = QGet_QuestLogSelection();
    while qc < numQuests do
        local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(i);
        if (ZoneFound and isHeader) then
            break;
        end
        if (isHeader and q == Zone) then
            ZoneFound = true;
        end
        if not isHeader and ZoneFound then
            QuestsChecked = QuestsChecked + 1;
            QSelect_QuestLogEntry(i);
            local count =  QGet_NumQuestLeaderBoards();
            local questText, objectiveText = QGet_QuestLogQuestText();
            local hash = Questie:getQuestHash(q, level, objectiveText);
            if QuestieHashCache[q] == nil then QuestieHashCache[q] = {}; end
            QuestieHashCache[q][hash] = GetTime();
            if not lastObjectives[hash] then
                lastObjectives[hash] = {};
            end
            local Refresh = nil;
            for obj = 1, count do
                if (not lastObjectives[hash][obj]) then
                    lastObjectives[hash][obj] = {};
                end
                local desc, typ, done = QGet_QuestLogLeaderBoard(obj);
                if(lastObjectives[hash][obj].desc == desc and lastObjectives[hash][obj].typ == typ and lastObjectives[hash][obj].done == done) then
                elseif(lastObjectives[hash][obj].done ~= done) then
                    Refresh = true;
                    foundChange = true;
                else
                    foundChange = true;
                end
                lastObjectives[hash][obj].desc = desc;
                lastObjectives[hash][obj].typ = typ;
                lastObjectives[hash][obj].done = done;
            end
            if (Refresh) then
                Questie:AddQuestToMap(hash, true);
                if (QuestieCachedQuests[hash]) then
                    QuestieTracker:updateTrackerCache(hash, i, level);
                end
            elseif foundChange and QuestieConfig.trackerEnabled == true then
                if (QuestieCachedQuests[hash]) then
                    QuestieTracker:updateTrackerCache(hash, i, level);
                end
            end
            QuestieTracker:FillTrackingFrame();
        end
        if (foundChange and not force) then
            break;
        end
        if not isHeader then
            qc = qc + 1;
        end
        i = i + 1;
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
    return foundChange;
end
---------------------------------------------------------------------------------------------------
--Adds all active objectives from all quests in the questlog to the lastObjectives table
---------------------------------------------------------------------------------------------------
function Questie:UpdateQuestsInit()
    local numEntries, numQuests = QGet_NumQuestLogEntries();
    local i = 1;
    local qc = 0;
    local prevQuestLogSelection = QGet_QuestLogSelection();
    while qc < numQuests do
        local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(i);
        if not isHeader then
            QSelect_QuestLogEntry(i);
            local count =  QGet_NumQuestLeaderBoards();
            local questText, objectiveText = QGet_QuestLogQuestText();
            local hash = Questie:getQuestHash(q, level, objectiveText);
            if not lastObjectives[hash] then
                lastObjectives[hash] = {};
            end
            for obj = 1, count do
                if (not lastObjectives[hash][obj]) then
                    lastObjectives[hash][obj] = {};
                end
                lastObjectives[hash][obj].desc = desc;
                lastObjectives[hash][obj].typ = typ;
                lastObjectives[hash][obj].done = done;
            end
            qc = qc + 1;
        end
        i = i + 1;
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
end
---------------------------------------------------------------------------------------------------
--Astrolabe functions
---------------------------------------------------------------------------------------------------
function Questie:AstroGetAllCurrentQuestHashes(print)
    local hashes = {};
    local numEntries, numQuests = QGet_NumQuestLogEntries();
    local i = 1;
    local qc = 0;
    if (print) then
        --Questie:debug_Print("Quest:AstroGetAllCurrentQuestHashes: Listing all current quests");
    end
    local prevQuestLogSelection = QGet_QuestLogSelection();
    while qc < numQuests do
        local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(i);
        if not isHeader then
            QSelect_QuestLogEntry(i);
            local count =  QGet_NumQuestLeaderBoards();
            local questText, objectiveText = QGet_QuestLogQuestText();
            local quest = {};
            quest["name"] = q;
            quest["level"] = level;
            local hash = Questie:getQuestHash(q, level, objectiveText);
            quest["hash"] = hash;
            if(IsAddOnLoaded("URLCopy") and print) then
                Questie:debug_Print("        "..q,URLCopy_Link(quest["hash"]));
            elseif(print) then
                Questie:debug_Print("        "..q,quest["hash"]);
            end
            table.insert(hashes, quest);
            qc = qc + 1;
        else
            if (print) then
                Questie:debug_Print("    Zone:", q);
            end
        end
        i = i + 1;
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
    if (print) then
        --Questie:debug_Print("Quest:AstroGetAllCurrentQuestHashes: End of all current quests");
    end
    return hashes;
end
---------------------------------------------------------------------------------------------------
function Questie:AstroGetAllCurrentQuestHashesAsMeta(print)
    local agacqhamtime = GetTime();
    local hashes = {};
    local Count = 0;
    local numEntries, numQuests = QGet_NumQuestLogEntries();
    local collapsedCount = 0;
    local i = 1;
    local qc = 0;
    Questie.collapsedThisRun = false;
    local prevQuestLogSelection = QGet_QuestLogSelection();
    while qc < numQuests do
        local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(i);
        if isCollapsed then collapsedCount = collapsedCount + 1; end
        if not isHeader then
            QSelect_QuestLogEntry(i);
            local count =  QGet_NumQuestLeaderBoards();
            local questText, objectiveText = QGet_QuestLogQuestText();
            local hash = Questie:getQuestHash(q, level, objectiveText);
            hashes[hash] = {};
            hashes[hash]["hash"] = hash;
            hashes[hash]["name"] = q;
            hashes[hash]["level"] = level;
            if(IsAddOnLoaded("URLCopy") and print)then
                Questie:debug_Print("        "..q,URLCopy_Link(quest["hash"]));
            elseif(print) then
                Questie:debug_Print("        "..q,quest["hash"]);
            end
            qc = qc + 1;
        else
            if (print) then
                Questie:debug_Print("    Zone:", q);
            end
        end
        i=i+1
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
    if (print) then
        --Questie:debug_Print("Quest:AstroGetAllCurrentQuestHashesAsMeta: End of all current quests");
    end
    if not (collapsedCount == Questie.lastCollapsedCount) then
        Questie.lastCollapsedCount = collapsedCount;
        Questie.collapsedThisRun = true;
    end
    --Questie:debug_Print("Quest:AstroGetAllCurrentQuestHashesAsMeta --> Getting all hashes took: ["..tostring((GetTime()- agacqhamtime)*1000).."ms]");
    return hashes, numQuests;
end
---------------------------------------------------------------------------------------------------
function Questie:AstroGetFinishedQuests()
    numEntries, numQuests = QGet_NumQuestLogEntries();
    local FinishedQuests = {};
    local i = 1;
    local qc = 0;
    local prevQuestLogSelection = QGet_QuestLogSelection();
    while qc < numQuests do
        local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(i);
        if not isHeader then
            QSelect_QuestLogEntry(i);
            local count =  QGet_NumQuestLeaderBoards();
            local questText, objectiveText = QGet_QuestLogQuestText();
            Done = true;
            for obj = 1, count do
                local desc, typ, done = QGet_QuestLogLeaderBoard(obj);
                if not done then
                    Done = nil;
                end
            end
            if(Done) then
                local hash = Questie:getQuestHash(q, level, objectiveText);
                --Questie:debug_Print("AstroGetFinishedQuests: [Hash: "..hash.."] | [Quest: "..q.."] | [Level: "..level.."]");
                table.insert(FinishedQuests, hash);
            end
            qc = qc + 1;
        end
        i = i + 1;
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
    return FinishedQuests;
end
---------------------------------------------------------------------------------------------------
function Questie:GetQuestObjectivePaths(questHash)
    local prevQuestLogSelection = QGet_QuestLogSelection();
    local questLogID = Questie:GetQuestIdFromHash(questHash);
    QSelect_QuestLogEntry(questLogID);
    local count = QGet_NumQuestLeaderBoards();
    local objectivePaths = {};
    for i = 1, count do
        local desc, type, done = QGet_QuestLogLeaderBoard(i);
        local typeFunctions = {
            ['item'] = GetItemLocations,
            ['event'] = GetEventLocations,
            ['monster'] = GetMonsterLocations,
            ['object'] = GetObjectLocations
        };
        local typeFunction = typeFunctions[type];
        if typeFunction ~= nil then
            local objectiveName = desc;
            local splitIndex = findLast(objectiveName, ":");
            if splitIndex ~= nil then
                objectiveName = string.sub(objectiveName, 1, splitIndex-1);
                if (string.find(objectiveName, " slain")) then
                    objectiveName = string.sub(objectiveName, 1, string.len(objectiveName)-6);
                end
            end
            locations = typeFunction(objectiveName);
            objectivePaths[i] = {};
            objectivePaths[i]['path'] = locations;
            objectivePaths[i]['done'] = done;
            objectivePaths[i]['type'] = type;
            objectivePaths[i]['name'] = objectiveName;
        end
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
    return objectivePaths;
end
---------------------------------------------------------------------------------------------------
--Perhaps we should consider removing this function from Questie
---------------------------------------------------------------------------------------------------
function Questie:AstroGetQuestObjectives(questHash)
    local prevQuestLogSelection = QGet_QuestLogSelection();
    local QuestLogID = Questie:GetQuestIdFromHash(questHash);
    local mapid = GetCurrentMapID();
    local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(QuestLogID);
    QSelect_QuestLogEntry(QuestLogID);
    local count =  QGet_NumQuestLeaderBoards();
    local questText, objectiveText = QGet_QuestLogQuestText();
    local AllObjectives = {};
    AllObjectives["QuestName"] = q;
    AllObjectives["objectives"] = {};
    for i = 1, count do
        local desc, typ, done = QGet_QuestLogLeaderBoard(i);
        local typeFunction = AstroobjectiveProcessors[typ];
        if typ == "item" or typ == "monster" or not (typeFunction == nil) then
            local indx = findLast(desc, ":");
            local countless = indx == nil;
            local countstr = "";
            local namestr = desc;
            if not countless then
                countstr = string.sub(desc, indx + 2);
                namestr = string.sub(desc, 1, indx - 1);
            end
            local objectives = typeFunction(q, namestr, countstr, selected, mapid);
            Objective = {};
            local hash = Questie:getQuestHash(q, level, objectiveText);
            for k, v in pairs(objectives) do
                if (AllObjectives["objectives"][v["name"]] == nil) then
                    AllObjectives["objectives"][v["name"]] = {};
                end
                if (not QuestieCachedMonstersAndObjects[hash]) then
                    QuestieCachedMonstersAndObjects[hash] = {};
                end
                if (not QuestieCachedMonstersAndObjects[hash][v["name"]]) then
                    QuestieCachedMonstersAndObjects[hash][v["name"]] = {};
                end
                QuestieCachedMonstersAndObjects[hash][v["name"]].name = v["name"];
                for monster, info in pairs(v['locations']) do
                    local obj = {};
                    obj["mapid"] = info[1];
                    obj["x"] = info[2];
                    obj["y"] = info[3];
                    obj["lootname"] = v["lootname"];
                    obj["type"] = v["type"];
                    obj["done"] = done;
                    obj['objectiveid'] = i;
                    table.insert(AllObjectives["objectives"][v["name"]], obj);
                end
            end
        else
        end
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
    return AllObjectives;
end
---------------------------------------------------------------------------------------------------
AstroobjectiveProcessors = {
    ['item'] = function(quest, name, amount, selected, mapid)
        local list = {};
        local itemdata = QuestieItems[name];
        --Questie:debug_Print(name);
        if itemdata == nil then
            Questie:debug_Print("Quest:AstroobjectiveProcessors --> ERROR1 PROCESSING: [Quest: "..quest.."] | [Objective: "..name.."] | No [itemdata] found | ID:0");
            itemdata = QuestieItems[name];
        end
        if itemdata then
            for k,v in pairs(itemdata) do
                if k == "locationCount" then
                    local monster = {};
                    monster["name"] = name;
                    monster["locations"] = {};
                    monster["type"] = "loot";
                    for b=1,itemdata['locationCount'] do
                        local loc = itemdata['locations'][b];
                        table.insert(monster["locations"], loc);
                    end
                    table.insert(list, monster);
                elseif k == "drop" then
                    for e,r in pairs(v) do
                        local monster = {};
                        monster["name"] = name;
                        monster["lootname"] = e;
                        monster["locations"] = {};
                        monster["type"] = "loot";
                        for k, pos in pairs(QuestieMonsters[e]['locations']) do
                            table.insert(monster["locations"], pos);
                        end
                        table.insert(list, monster);
                    end
                elseif k == "contained" then
                    for objectName, someNumber in pairs(v) do
                        local monster = {};
                        monster["name"] = name;
                        monster["lootname"] = objectName;
                        monster["locations"] = {};
                        monster["type"] = "object";
                        if QuestieObjects[objectName] then
                            --TODO: handle objects that appear when a mob is killed
                            for k, pos in pairs(QuestieObjects[objectName]['locations']) do
                                table.insert(monster["locations"], pos);
                            end
                            table.insert(list, monster);
                        end
                    end
                elseif k =="locations" then
                else
                    Questie:debug_Print("Quest:AstroobjectiveProcessors --> ERROR2: [Quest: "..quest.."] | [Objective: "..name.."] | ID:1");
                    for s, r in pairs(itemdata) do
                        Questie:debug_Print(s,tostring(r));
                    end
                end
            end
        end
        return list;
    end,
    ['event'] = function(quest, name, amount, selected, mapid)
        local evtdata = QuestieEvents[name];
        local list = {};
        if evtdata == nil then
            Questie:debug_Print("Quest:AstroobjectiveProcessors --> ERROR3 UNKNOWN EVENT: [Quest: "..quest.."] | [Objective: "..name.."] | ID:2");
        else
            for b=1,evtdata['locationCount'] do
                local monster = {};
                monster["name"] = name;
                monster["locations"] = {};
                monster["type"] = "event";
                for b=1,evtdata['locationCount'] do
                    local loc = evtdata['locations'][b];
                    table.insert(monster["locations"], loc);
                end
                table.insert(list, monster);
            end
        end
        return list;
    end,
    ['monster'] = function(quest, name, amount, selected, mapid)
        local list = {};
        local monster = {};
        if (string.find(name, " slain")) then
            name = string.sub(name, 1, string.len(name)-6);
        end
        monster["name"] = name;
        monster["type"] = "slay";
        monster["locations"] = {};
        if (QuestieMonsters[name] and QuestieMonsters[name]['locations']) then
            for k, pos in pairs(QuestieMonsters[name]['locations']) do
                table.insert(monster["locations"], pos);
            end
        end
        table.insert(list, monster);
        return list;
    end,
    ['object'] = function(quest, name, amount, selected, mapid)
        local list = {};
        local objdata = QuestieObjects[name];
        if objdata == nil then
            Questie:debug_Print("Quest:AstroobjectiveProcessors: ERROR4 UNKNOWN OBJECT: [Quest: "..quest.."] | [Objective: "..name.."]");
        else
            for b=1,objdata['locationCount'] do
                local monster = {};
                monster["name"] = name;
                monster["locations"] = {};
                monster["type"] = "object";
                for b=1,objdata['locationCount'] do
                    local loc = objdata['locations'][b];
                    table.insert(monster["locations"], loc);
                end
                table.insert(list, monster);
            end
        end
        return list;
    end
}
---------------------------------------------------------------------------------------------------
--End of Astrolabe functions
---------------------------------------------------------------------------------------------------
--///////////////////////////////////////////////////////////////////////////////////////////////--
---------------------------------------------------------------------------------------------------
--Get quest ID from quest hash
---------------------------------------------------------------------------------------------------
function Questie:GetQuestIdFromHash(questHash)
    local prevQuestLogSelection = QGet_QuestLogSelection();
    local numEntries, numQuests = QGet_NumQuestLogEntries();
    if (QUESTIE_UPDATE_EVENT or numEntries ~= LastNrOfEntries or not CachedIds[questHash]) then
        CachedIds[questHash] = {};
        QUESTIE_UPDATE_EVENT = 0;
        LastNrOfEntries = numEntries;
        Questie:UpdateQuestIds();
        if CachedIds[questHash] then
            return CachedIds[questHash];
        end
    else
        local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(CachedIds[questHash]);
        QSelect_QuestLogEntry(CachedIds[questHash]);
        local questText, objectiveText = QGet_QuestLogQuestText();
        if (q and level and objectiveText) then
            if(Questie:getQuestHash(q, level, objectiveText) == questHash) then
                return CachedIds[questHash];
            else
                Questie:debug_Print("Quest:GetQuestIdFromHash --> Error: [Hash: "..tostring(CachedIds[questHash]).."]1");
            end
        else
            Questie:debug_Print("Quest:GetQuestIdFromHash --> Error2: [Hash: "..tostring(CachedIds[questHash]).."] | [Quest: "..tostring(q).."] | [Level: "..tostring(level).."]");
        end
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
end
---------------------------------------------------------------------------------------------------
--Update quest ID's
---------------------------------------------------------------------------------------------------
function Questie:UpdateQuestIds()
    local uqidtime = GetTime()
    local numEntries, numQuests = QGet_NumQuestLogEntries();
    local i = 1;
    local qc = 0;
    local prevQuestLogSelection = QGet_QuestLogSelection()
    while qc < numQuests do
        local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(i);
        if not isHeader then
            QSelect_QuestLogEntry(i);
            local questText, objectiveText = QGet_QuestLogQuestText();
            local hash = Questie:getQuestHash(q, level, objectiveText);
            if (not q or not level or not objective) then
                --commented out the error because it was really annoying. -ZoeyZolotova
                --Questie:debug_Print("Quest:UpdateQuestIds --> Error1: [Name: "..tostring(name).."] | [Level: "..tostring(level).."] | [Id: "..tostring(i).."] | [Hash: "..tostring(hash).."]")
            end
            CachedIds[hash] = i;
            qc = qc + 1;
        end
        i = i + 1;
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
    --Questie:debug_Print("Quest:UpdateQuestID: --> Updating QuestIds took: ["..tostring((GetTime()- uqidtime)*1000).."ms]")
end
---------------------------------------------------------------------------------------------------
--Get quest hash from quest name
---------------------------------------------------------------------------------------------------
function Questie:GetHashFromName(name)
    if QuestieHashCache[name] then
        local hashtable = QuestieHashCache[name];
        local bestValue = 0;
        local bestHash = -1;
        for k,v in pairs(hashtable) do
            if v > bestValue then
                bestValue = v;
                bestHash = k;
            end
        end
        if not (bestHash == -1) then return bestHash; end
    end
    return Questie:getQuestHash(name, nil, nil);
end
---------------------------------------------------------------------------------------------------
--Lookup quest hash from name, level or objective text
---------------------------------------------------------------------------------------------------
function Questie:getQuestHash(name, level, objectiveText)
    local hashLevel = level or "hashLevel";
    local hashText = objectiveText or "hashText";
    if QuestieQuestHashCache[name..hashLevel..hashText] then
        return QuestieQuestHashCache[name..hashLevel..hashText];
    end
    local questLookup = QuestieLevLookup[name];
    local hasOthers = false;
    if questLookup then
        local count = 0;
        local retval = 0;
        local bestDistance = 4294967295; --some high number (0xFFFFFFFF)
        local race = UnitRace("Player");
        for k,v in pairs(questLookup) do
            local rr = v[1];
            local adjustedDescription = k;
            local strlen = string.len(k);
            if string.sub(k, -1) == "]" then
                adjustedDescription = string.sub(k, 1, strlen-4);
            end
            if checkRequirements(null, race, null, rr) or true then
                if count == 1 then
                    hasOthers = true;
                end
                if adjustedDescription == objectiveText and tonumber(QuestieHashMap[v[2]]['questLevel']) == hashLevel then
                    QuestieQuestHashCache[name..hashLevel..hashText] = v[2];
                    return v[2],hasOthers; --exact match
                end
                local dist = 4294967294;
                if not (objectiveText == nil) then
                    dist = Questie:Levenshtein(objectiveText, adjustedDescription);
                end
                if dist < bestDistance then
                    bestDistance = dist;
                    retval = v[2];
                end
            else
            end
            count = count + 1;
        end
        if not (retval == 0) then
            QuestieQuestHashCache[name..hashLevel..hashText] = retval;
            return retval, hasOthers; --nearest match
        end
    end
    if name == nil then
        return -1;
    end
    local hash = Questie:MixString(0, name);
    if not (level == nil) then
        hash = Questie:MixInt(hash, level);
        QuestieQuestHashCache[name..hashLevel..hashText] = hash;
    end
    if not (objectiveText == nil) then
        hash = Questie:MixString(hash, objectiveText);
        QuestieQuestHashCache[name..hashLevel..hashText] = hash;
    end
    QuestieQuestHashCache[name..hashLevel..hashText] = hash;
    return hash, false;
end
---------------------------------------------------------------------------------------------------
--Checks to see if a quest is finished by quest hash
---------------------------------------------------------------------------------------------------
function Questie:IsQuestFinished(questHash)
    local id = Questie:GetQuestIdFromHash(questHash);
    if (not id) then
        return false;
    end
    local prevQuestLogSelection = QGet_QuestLogSelection()
    local FinishedQuests = {};
    local q, level, questTag, isHeader, isCollapsed, isComplete = QGet_QuestLogTitle(id);
    QSelect_QuestLogEntry(id);
    local count =  QGet_NumQuestLeaderBoards();
    local questText, objectiveText = QGet_QuestLogQuestText();
    local Done = true;
    for obj = 1, count do
        local desc, typ, done = QGet_QuestLogLeaderBoard(obj);
        if not done then
            Done = nil;
        end
    end
    QSelect_QuestLogEntry(prevQuestLogSelection);
    if (Done and Questie:getQuestHash(q, level, objectiveText) == questHash) then
        local ret = {};
        ret["questHash"] = questHash;
        ret["name"] = q;
        ret["level"] = level;
        return ret;
    end
    return nil;
end
---------------------------------------------------------------------------------------------------
--Race, Class and Profession filter functions
---------------------------------------------------------------------------------------------------
RaceBitIndexTable = {
    ['human'] = 1,
    ['orc'] = 2,
    ['dwarf'] = 3,
    ['nightelf'] = 4,
    ['night elf'] = 4,
    ['scourge'] = 5,
    ['undead'] = 5,
    ['tauren'] = 6,
    ['gnome'] = 7,
    ['troll'] = 8,
    ['goblin'] = 9
};
ClassBitIndexTable = {
    ['warrior'] = 1,
    ['paladin'] = 2,
    ['hunter'] = 3,
    ['rogue'] = 4,
    ['priest'] = 5,
    ['shaman'] = 7,
    ['mage'] = 8,
    ['warlock'] = 9,
    ['druid'] = 11
};
---------------------------------------------------------------------------------------------------
function unpackBinary(val)
    ret = {};
    for q=0,16 do
        if bit.band(bit.rshift(val,q), 1) == 1 then
            table.insert(ret, true);
        else
            table.insert(ret, false);
        end
    end
    return ret;
end
---------------------------------------------------------------------------------------------------
function checkRequirements(class, race, dbClass, dbRace)
    local valid = true;
    if race and dbRace and not (dbRace == 0) then
        local racemap = unpackBinary(dbRace);
        valid = racemap[RaceBitIndexTable[strlower(race)]];
    end
    if class and dbClass and valid and not (dbRace == 0)then
        local classmap = unpackBinary(dbClass);
        valid = classmap[ClassBitIndexTable[strlower(class)]];
    end
    return valid;
end
---------------------------------------------------------------------------------------------------
function Questie:GetAvailableQuestHashes(mapFileName, levelFrom, levelTo)
    local mapid =  -1;
    if(QuestieZones[mapFileName]) then
        c = QuestieZones[mapFileName][4];
        z = QuestieZones[mapFileName][5];
    end
    local class = UnitClass("Player");
    local race = UnitRace("Player");
    local hashes = {};
    for l = 0,100 do
        if QuestieZoneLevelMap[c] and QuestieZoneLevelMap[c][z] then
            local content = QuestieZoneLevelMap[c][z][l];
            if content then
                for v, locationMeta in pairs(content) do
                    local qdata = QuestieHashMap[v];
                    if (qdata) then
                        local stop = false;
                        local questLevel = qdata.questLevel;
                        for x in string.gfind(questLevel, "%d+") do questLevel = x; end
                        questLevel = tonumber(questLevel);
                        if QuestieConfig.minLevelFilter and questLevel < levelFrom then
                            stop = true;
                        end
                        if QuestieConfig.maxLevelFilter and qdata.level > levelTo then
                            stop = true;
                        end
                        if (not stop) then
                            local requiredQuest = qdata['rq'];
                            local requiredRaces = qdata['rr'];
                            local requiredClasses = qdata['rc'];
                            local requiredSkill = qdata['rs'];
                            local valid = not QuestieSeenQuests[requiredQuest];
                            if(requiredQuest) then valid = QuestieSeenQuests[requiredQuest]; end
                            valid = valid and (requiredSkill == nil or QuestieConfig.showProfessionQuests);
                            if valid then valid = valid and checkRequirements(class, race, requiredClasses,requiredRaces); end
                            if valid and not QuestieHandledQuests[requiredQuest] and not QuestieSeenQuests[v] then
                                hashes[v] = locationMeta;
                            end
                        end
                    end
                end
            end
        end
    end
    return hashes;
end
---------------------------------------------------------------------------------------------------
--End of filter functions
---------------------------------------------------------------------------------------------------
