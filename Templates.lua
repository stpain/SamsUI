

local name, addon = ...




--[[
    the buttons used in the main menu from the top bar
]]
SamsUiTopBarMainMenuButtonMixin = {}

function SamsUiTopBarMainMenuButtonMixin:SetText(text)
    self.text:SetText(text)
end

function SamsUiTopBarMainMenuButtonMixin:SetIconAtlas(atlas)
    self.icon:SetAtlas(atlas)
end

function SamsUiTopBarMainMenuButtonMixin:OnLoad()
    self:SetAlpha(0)
end

function SamsUiTopBarMainMenuButtonMixin:OnShow()
    self.anim:Play()
end

function SamsUiTopBarMainMenuButtonMixin:OnHide()
    self:SetAlpha(0)
end

function SamsUiTopBarMainMenuButtonMixin:OnMouseDown()
    if self.func then
        self.func()
    end
end









--[[
    an insecure button template used for dropdown menus where the player can use an item listed
]]
SamsUiTopBarInsecureMacroMenuButtonMixin = {}

function SamsUiTopBarInsecureMacroMenuButtonMixin:SetItem(item)
    self.link:SetText(item.link)
    self.count:SetText(item.count)
    self.icon:SetTexture(item.icon)

    self:SetAttribute("macrotext1", string.format("/use %s", item.name))
end


function SamsUiTopBarInsecureMacroMenuButtonMixin:OnShow()
    self.anim:Play()
end

function SamsUiTopBarInsecureMacroMenuButtonMixin:OnHide()
    self:SetAlpha(0)
end

function SamsUiTopBarInsecureMacroMenuButtonMixin:OnEnter()
    
    if self.itemLink then
        GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
        GameTooltip:SetHyperlink(self.itemLink)
        GameTooltip:Show()
    end
end

function SamsUiTopBarInsecureMacroMenuButtonMixin:OnLeave()
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
end

function SamsUiTopBarInsecureMacroMenuButtonMixin:OnLoad()
    --self:SetAlpha(0)
end

function SamsUiTopBarInsecureMacroMenuButtonMixin:OnMouseDown()
    if self.func then
        self.func()
    end
end








--[[
    button used for the top bar for dropdown menus ???
]]
SamsUiTopBarDropdownMenuButtonMixin = {}

function SamsUiTopBarDropdownMenuButtonMixin:OnLoad()

end

function SamsUiTopBarDropdownMenuButtonMixin:OnShow()

end

function SamsUiTopBarDropdownMenuButtonMixin:SetText(text)
    self.text:SetText(text)
end








--[[
    mixin for an inset style button used to show info
]]
SamsUiTopBarInsetButtonMixin = {}

function SamsUiTopBarInsetButtonMixin:OnLoad()

end

function SamsUiTopBarInsetButtonMixin:OnShow()

end

function SamsUiTopBarInsetButtonMixin:SetText(text)
    self.text:SetText(text)
end








--[[
    the menu buttons for the config panel menu
]]
SamsUiConfigPanelMenuButtonMixin = {}
function SamsUiConfigPanelMenuButtonMixin:OnLoad()

end


function SamsUiConfigPanelMenuButtonMixin:OnClick()

    if self.func then
        self.func()
    end
end


function SamsUiConfigPanelMenuButtonMixin:SetDataBinding(binding, height)

    self:SetHeight(height)

    if binding.panelName then
        self.text:SetText(binding.panelName)
    end

    self.func = binding.func;
end


function SamsUiConfigPanelMenuButtonMixin:ResetDataBinding()

end






---this is the listview template mixin
SamsUiListviewMixin = CreateFromMixins(CallbackRegistryMixin);
SamsUiListviewMixin:GenerateCallbackEvents(
    {
        "OnSelectionChanged",
    }
);

function SamsUiListviewMixin:OnLoad()

    ---these values are set in the xml frames KeyValues, it allows us to reuse code by setting listview item values in xml
    if type(self.itemTemplate) ~= "string" then
        error("self.itemTemplate name not set or not of type string")
        return;
    end
    if type(self.frameType) ~= "string" then
        error("self.frameType not set or not of type string")
        return;
    end
    if type(self.elementHeight) ~= "number" then
        error("self.elementHeight not set or not of type number")
        return;
    end

    CallbackRegistryMixin.OnLoad(self)

    self.DataProvider = CreateDataProvider();
    self.scrollView = CreateScrollBoxListLinearView();
    self.scrollView:SetDataProvider(self.DataProvider);

    ---height is defined in the xml keyValues
    local height = self.elementHeight;
    self.scrollView:SetElementExtent(height);

    self.scrollView:SetElementInitializer(self.frameType, self.itemTemplate, GenerateClosure(self.OnElementInitialize, self));
    self.scrollView:SetElementResetter(GenerateClosure(self.OnElementReset, self));

    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.scrollView);
    self.selectionBehavior:RegisterCallback("OnSelectionChanged", self.OnElementSelectionChanged, self);

    self.scrollView:SetPadding(5, 5, 5, 5, 1);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", 0, 4),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 4, -4),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, anchorsWithBar, anchorsWithoutBar);
end

function SamsUiListviewMixin:OnElementInitialize(element, elementData, isNew)
    if isNew then
        element:OnLoad();
    end

    local height = self.elementHeight;

    element:SetDataBinding(elementData, height);
    --element:RegisterCallback("OnMouseDown", self.OnElementClicked, self);

end

function SamsUiListviewMixin:OnElementReset(element)
    --element:UnregisterCallback("OnMouseDown", self);

    element:ResetDataBinding()
end

function SamsUiListviewMixin:OnElementClicked(element)
    self.selectionBehavior:Select(element);
end


function SamsUiListviewMixin:OnElementSelectionChanged(elementData, selected)
    --DevTools_Dump({ self.selectionBehavior:GetSelectedElementData() })

    local element = self.scrollView:FindFrame(elementData);

    if element then
        element:SetSelected(selected);
    end

    if selected then
        self:TriggerEvent("OnSelectionChanged", elementData, selected);
    end
end







--[[
    the database view row template used in the config panel 
]]
SamsUiConfigPanelDatabaseControlListviewItemTemplateMixin = {}
function SamsUiConfigPanelDatabaseControlListviewItemTemplateMixin:OnLoad()

end


function SamsUiConfigPanelDatabaseControlListviewItemTemplateMixin:SetDataBinding(binding, height)

    self:SetHeight(height)

    for k, v in pairs(binding) do
        if self[k] then
            self[k]:SetText(v)
        end
    end

    local tradeskillInfo = "";
    if binding.profession1 then
        if binding.profession1 == "Engineering" then
            tradeskillInfo = CreateAtlasMarkup("Mobile-Enginnering", 20, 20)
        else
            tradeskillInfo = CreateAtlasMarkup(string.format("Mobile-%s", binding.profession1), 20, 20)
        end
    end
    tradeskillInfo = tradeskillInfo.." "
    if binding.profession2 then
        if binding.profession2 == "Engineering" then
            tradeskillInfo = tradeskillInfo..CreateAtlasMarkup("Mobile-Enginnering", 20, 20)
        else
            tradeskillInfo = tradeskillInfo..CreateAtlasMarkup(string.format("Mobile-%s", binding.profession2), 20, 20)
        end
    end
    self.tradeskills:SetText(tradeskillInfo)

    self.delete:SetScript("OnClick", function()
        binding.deleteFunc(nil, binding.name)
    end)
end


function SamsUiConfigPanelDatabaseControlListviewItemTemplateMixin:ResetDataBinding()

end